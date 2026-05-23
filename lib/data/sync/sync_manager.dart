import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint, kIsWeb;
import '../../core/services/connectivity_service.dart';
import '../../core/database.dart';
import '../local/local_database.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  final LocalDatabase _localDb = LocalDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  
  bool _isSyncing = false;
  final ValueNotifier<bool> syncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  
  SyncManager._init() {
    // Listen for connectivity changes and trigger auto-sync
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        triggerSync();
      }
    });
    // On web, drain any stale sync queue items since web writes directly to Supabase
    if (kIsWeb) {
      _drainStaleWebQueue();
    } else {
      // Check pending count on start
      updatePendingCount();
    }
  }

  /// Drain stale sync queue on web — these items were queued before the
  /// web fast-path was added. Web repositories now write directly to
  /// Supabase, so these queue items are duplicates / stale.
  Future<void> _drainStaleWebQueue() async {
    try {
      await _localDb.clearTable('sync_queue');
      pendingCountNotifier.value = 0;
      debugPrint('[SyncManager] Web: cleared stale sync queue.');
    } catch (e) {
      debugPrint('[SyncManager] Web: failed to clear stale queue: $e');
    }
  }

  bool get isSyncing => _isSyncing;

  Future<void> updatePendingCount() async {
    final count = await _localDb.count('sync_queue');
    pendingCountNotifier.value = count;
  }

  /// Queues an operation locally and schedules synchronization
  Future<void> queueOperation({
    required String tableName,
    required String action,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _localDb.insert('sync_queue', {
      'table_name': tableName,
      'action': action,
      'record_id': recordId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
    
    await updatePendingCount();
    
    // Trigger sync if online
    if (_connectivity.isOnline) {
      triggerSync();
    }
  }

  /// Clears the entire sync queue. Used when resetting data or on web startup.
  Future<void> clearSyncQueue() async {
    await _localDb.clearTable('sync_queue');
    await updatePendingCount();
    debugPrint('[SyncManager] Sync queue cleared.');
  }

  /// Iterates and uploads queued database operations to Supabase in order
  Future<void> triggerSync() async {
    // On web, repositories write directly to Supabase — skip queue processing
    if (kIsWeb) {
      await _drainStaleWebQueue();
      return;
    }
    if (_isSyncing || !_connectivity.isOnline) return;
    
    _isSyncing = true;
    syncingNotifier.value = true;
    debugPrint('[SyncManager] Starting background synchronization...');

    try {
      while (true) {
        // Retrieve the oldest queued operation to ensure sequence safety (FIFO)
        final operations = await _localDb.queryAll(
          'sync_queue',
          orderBy: 'id ASC',
          limit: 1,
        );

        if (operations.isEmpty) {
          debugPrint('[SyncManager] No pending items in sync queue.');
          break;
        }

        final op = operations.first;
        final queueId = op['id'] as int;
        final tableName = op['table_name'] as String;
        final action = op['action'] as String;
        final recordId = op['record_id'] as String;
        final payload = jsonDecode(op['payload'] as String) as Map<String, dynamic>;
        final retryCount = (op['retry_count'] as num?)?.toInt() ?? 0;

        final success = await _syncRecordToCloud(tableName, action, recordId, payload);
        
        if (success) {
          // Remove successfully synced item from database
          await _localDb.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [queueId],
          );
          await updatePendingCount();
          debugPrint('[SyncManager] Synced $action on $tableName (ID: $recordId)');
        } else {
          final nextRetries = retryCount + 1;
          if (nextRetries >= 5) {
            // Drop poisoned record after 5 consecutive failures to prevent permanent queue lock
            debugPrint('[SyncManager] Sync permanently failed for record $recordId on $tableName after 5 attempts. Skipping.');
            await _localDb.delete(
              'sync_queue',
              where: 'id = ?',
              whereArgs: [queueId],
            );
            await updatePendingCount();
            continue; // Continue to next record in the queue
          } else {
            // Update retry count and pause queue processing until next connectivity change
            await _localDb.update(
              'sync_queue',
              {'retry_count': nextRetries},
              where: 'id = ?',
              whereArgs: [queueId],
            );
            debugPrint('[SyncManager] Sync failed for record $recordId (Attempt $nextRetries/5). Pausing queue processing.');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[SyncManager] Error during sync: $e');
    } finally {
      _isSyncing = false;
      syncingNotifier.value = false;
      await updatePendingCount();
      debugPrint('[SyncManager] Synchronization cycle completed.');
    }
  }

  Future<bool> _syncRecordToCloud(
    String tableName,
    String action,
    String recordId,
    Map<String, dynamic> payload,
  ) async {
    try {
      if (action == 'ADJUST_STOCK') {
        final delta = payload['delta'] as int;
        await supabase.rpc('adjust_product_stock', params: {
          'p_id': recordId,
          'p_delta': delta,
        });
      } else if (action == 'INSERT' || action == 'UPDATE') {
        // Fetch existing remote record to check for newer updates (Conflict Resolution)
        try {
          final remoteRecord = await supabase
              .from(tableName)
              .select('updated_at')
              .eq('id', recordId)
              .maybeSingle();

          if (remoteRecord != null && remoteRecord['updated_at'] != null) {
            final serverUpdatedAt = DateTime.parse(remoteRecord['updated_at'] as String);

            // Extract local updated_at timestamp from payload
            final localTimeStr = payload['updated_at'] ?? payload['timestamp'] ?? payload['created_at'];
            if (localTimeStr != null) {
              final localUpdatedAt = DateTime.parse(localTimeStr as String);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                debugPrint('[SyncManager] Conflict resolved: Remote record is newer than offline local record for ID: $recordId on $tableName ($serverUpdatedAt vs $localUpdatedAt). Skipping local overwrite.');
                return true; // Skipping is considered success as conflict has been resolved
              }
            }
          }
        } catch (dbErr) {
          // If the select fails (e.g. table doesn't have updated_at column), we log and proceed with standard upsert
          debugPrint('[SyncManager] Sync query for conflict resolution failed (possibly column missing): $dbErr. Proceeding with standard upsert.');
        }

        await supabase.from(tableName).upsert(payload);
      } else if (action == 'DELETE') {
        await supabase.from(tableName).delete().eq('id', recordId);
      }
      return true;
    } catch (e) {
      debugPrint('[SyncManager] Sync network update failed: $e');
      return false;
    }
  }
}
