import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    // Check pending count on start
    updatePendingCount();
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

  /// Iterates and uploads queued database operations to Supabase in order
  Future<void> triggerSync() async {
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
