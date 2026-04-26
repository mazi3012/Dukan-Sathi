import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

const String _istTimeZone = 'Asia/Kolkata';

DateTime _utcNow() => DateTime.now().toUtc();

DateTime _toIst(DateTime instant) => instant.toUtc().add(const Duration(hours: 5, minutes: 30));

DateTime _startOfDayIst(DateTime instant) {
  final ist = _toIst(instant);
  return DateTime.utc(ist.year, ist.month, ist.day).subtract(const Duration(hours: 5, minutes: 30));
}

DateTime _endOfDayIst(DateTime instant) => _startOfDayIst(instant).add(const Duration(days: 1));

DateTime _startOfWeekIst(DateTime instant) {
  final ist = _toIst(instant);
  final startOfDay = DateTime.utc(ist.year, ist.month, ist.day);
  return startOfDay.subtract(Duration(days: startOfDay.weekday - DateTime.monday, hours: 5, minutes: 30));
}

DateTime _endOfWeekIst(DateTime instant) => _startOfWeekIst(instant).add(const Duration(days: 7));

DateTime _startOfMonthIst(DateTime instant) {
  final ist = _toIst(instant);
  return DateTime.utc(ist.year, ist.month).subtract(const Duration(hours: 5, minutes: 30));
}

DateTime _endOfMonthIst(DateTime instant) {
  final ist = _toIst(instant);
  return DateTime.utc(ist.year, ist.month + 1).subtract(const Duration(hours: 5, minutes: 30));
}

DateTime? _parseDateOnly(String? input) {
  if (input == null || input.trim().isEmpty) {
    return null;
  }

  final normalized = input.trim().toLowerCase();
  if (normalized == 'today') return _startOfDayIst(_utcNow());
  if (normalized == 'yesterday') return _startOfDayIst(_utcNow().subtract(const Duration(days: 1)));
  if (normalized == 'this week') return _startOfWeekIst(_utcNow());
  if (normalized == 'last week') return _startOfWeekIst(_utcNow().subtract(const Duration(days: 7)));
  if (normalized == 'this month') return _startOfMonthIst(_utcNow());
  if (normalized == 'last month') {
    final previousMonth = DateTime.utc(_utcNow().year, _utcNow().month - 1);
    return _startOfMonthIst(previousMonth);
  }

  final parsed = DateTime.tryParse(input);
  if (parsed == null) {
    return null;
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day).subtract(const Duration(hours: 5, minutes: 30));
}

Map<String, DateTime>? _resolveDateRange(Map<String, dynamic> input) {
  final fromDate = _parseDateOnly(input['fromDate'] as String?);
  final toDate = _parseDateOnly(input['toDate'] as String?);
  final period = (input['period'] as String?)?.trim().toLowerCase();

  if (fromDate != null || toDate != null) {
    final start = fromDate ?? _startOfDayIst(_utcNow());
    final end = toDate != null ? _endOfDayIst(toDate) : _endOfDayIst(_utcNow());
    return {'from': start, 'to': end};
  }

  if (period == null || period.isEmpty || period == 'all_time' || period == 'all time') {
    return null;
  }

  switch (period) {
    case 'today':
      return {'from': _startOfDayIst(_utcNow()), 'to': _endOfDayIst(_utcNow())};
    case 'yesterday':
      final yesterday = _utcNow().subtract(const Duration(days: 1));
      return {'from': _startOfDayIst(yesterday), 'to': _endOfDayIst(yesterday)};
    case 'this_week':
    case 'week':
      return {'from': _startOfWeekIst(_utcNow()), 'to': _endOfWeekIst(_utcNow())};
    case 'last_week':
      final lastWeek = _utcNow().subtract(const Duration(days: 7));
      return {'from': _startOfWeekIst(lastWeek), 'to': _endOfWeekIst(lastWeek)};
    case 'this_month':
    case 'month':
      return {'from': _startOfMonthIst(_utcNow()), 'to': _endOfMonthIst(_utcNow())};
    case 'last_month':
      final lastMonth = DateTime.utc(_utcNow().year, _utcNow().month - 1);
      return {'from': _startOfMonthIst(lastMonth), 'to': _endOfMonthIst(lastMonth)};
    default:
      return null;
  }
}

double _safeNum(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

bool _withinRange(DateTime instant, DateTime from, DateTime to) {
  return !instant.isBefore(from) && instant.isBefore(to);
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

double? _extractCostPerUnit(Map<String, dynamic> product) {
  final metadata = _asMap(product['metadata']);
  if (metadata == null) {
    return null;
  }

  for (final key in ['cost_price', 'purchase_cost', 'buy_price', 'unit_cost']) {
    final candidate = metadata[key];
    if (candidate is num) return candidate.toDouble();
    if (candidate is String) {
      final parsed = double.tryParse(candidate.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (parsed != null) return parsed;
    }
  }

  return null;
}

final SchemanticType<Map<String, dynamic>> businessInsightsInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'shopId': {'type': 'string'},
      'metric': {
        'type': 'string',
        'enum': ['overview', 'revenue', 'profit', 'approval_status', 'time_period'],
        'description': 'Type of analytics to retrieve',
      },
      'period': {'type': 'string'},
      'fromDate': {'type': 'string'},
      'toDate': {'type': 'string'},
    },
    'required': [],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final businessInsightsTool = ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'businessInsightsTool',
  description:
      'Get comprehensive business analytics including revenue, profit, approval status, and date-range insights in IST. Supports: overview, revenue, profit, approval_status, and time_period.',
  inputSchema: businessInsightsInputSchema,
  fn: (input, context) async {
    final shopId = (input['shopId'] as String?) ?? await getShopIdForUser(context.context?['userIdentifier'] as String?);
    if (shopId.isEmpty) {
      return {
        'status': 'error',
        'message': 'No shop found for user',
        'total_revenue': 0.0,
        'total_orders': 0,
      };
    }

    try {
      final metric = (input['metric'] as String?)?.trim().toLowerCase() ?? 'overview';
      final range = _resolveDateRange(input);
      final from = range?['from'];
      final to = range?['to'];

      final approvals = await supabase
          .from('draft_approvals')
          .select('approval_id, proposed_total, approval_status, created_at, reviewed_at, sale_id, shop_id')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      final approvalRecords = (approvals as List<dynamic>)
          .map((record) => Map<String, dynamic>.from(record as Map))
          .where((record) {
            if (from == null || to == null) return true;
            final createdAt = _parseTimestamp(record['created_at']);
            return createdAt != null && _withinRange(createdAt, from, to);
          })
          .toList();

      final sales = await supabase
          .from('sales')
          .select('id, invoice_id, shop_id, amount, subtotal_after_discount, timestamp, status, payment_method')
          .eq('shop_id', shopId)
          .order('timestamp', ascending: false);

      final saleRecords = (sales as List<dynamic>)
          .map((record) => Map<String, dynamic>.from(record as Map))
          .where((record) {
            if (from == null || to == null) return true;
            final timestamp = _parseTimestamp(record['timestamp']);
            return timestamp != null && _withinRange(timestamp, from, to);
          })
          .toList();

      final invoiceIds = saleRecords
          .map((record) => record['invoice_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final invoiceItemMap = <String, List<Map<String, dynamic>>>{};
      if (invoiceIds.isNotEmpty) {
        final invoices = await supabase
            .from('draft_invoices')
            .select('id, items')
            .inFilter('id', invoiceIds);

        for (final row in invoices as List<dynamic>) {
          final data = Map<String, dynamic>.from(row as Map);
          final items = (data['items'] as List<dynamic>? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          final invoiceId = data['id']?.toString();
          if (invoiceId != null) {
            invoiceItemMap[invoiceId] = items;
          }
        }
      }

      final productIds = invoiceItemMap.values
          .expand((items) => items)
          .map((item) => item['productId']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final productCostMap = <String, double>{};
      if (productIds.isNotEmpty) {
        final products = await supabase
            .from('products')
            .select('id, cost_price, metadata')
            .inFilter('id', productIds);

        for (final row in products as List<dynamic>) {
          final data = Map<String, dynamic>.from(row as Map);
          final productId = data['id']?.toString();
          final costPerUnit = (data['cost_price'] as num?)?.toDouble() ?? _extractCostPerUnit(data);
          if (productId != null && costPerUnit != null && costPerUnit > 0) {
            productCostMap[productId] = costPerUnit;
          }
        }
      }

      double estimatedGrossProfit = 0.0;
      bool hasMissingCostBasis = false;
      final missingCostProducts = <String>{};

      for (final record in saleRecords) {
        final invoiceId = record['invoice_id']?.toString();
        final items = invoiceId == null
            ? const <Map<String, dynamic>>[]
            : invoiceItemMap[invoiceId] ?? const <Map<String, dynamic>>[];
        var cogs = 0.0;

        for (final item in items) {
          final productId = item['productId']?.toString();
          final quantity = _safeNum(item['quantity']).toInt();
          final costPerUnit = productId == null ? null : productCostMap[productId];

          if (costPerUnit == null) {
            hasMissingCostBasis = true;
            if (productId != null) {
              missingCostProducts.add(productId);
            }
            continue;
          }

          cogs += costPerUnit * quantity;
        }

        final revenueBasis = _safeNum(record['subtotal_after_discount'] ?? record['amount']);
        estimatedGrossProfit += revenueBasis - cogs;
      }

      int totalItemsSold = 0;
      int itemsWithCost = 0;
      for (final items in invoiceItemMap.values) {
        for (final item in items) {
          totalItemsSold += _safeNum(item['quantity']).toInt();
          final productId = item['productId']?.toString();
          if (productId != null && productCostMap.containsKey(productId)) {
            itemsWithCost += _safeNum(item['quantity']).toInt();
          }
        }
      }
      final costBasisCoverage = totalItemsSold > 0 ? (itemsWithCost / totalItemsSold) : 0.0;
      final isCompleteCostBasis = costBasisCoverage >= 0.99; // effectively 100%
      final isZeroCostBasis = costBasisCoverage <= 0.01; // effectively 0%

      final approvedCount = approvalRecords.where((record) => record['approval_status'] == 'APPROVED').length;
      final pendingCount = approvalRecords.where((record) => record['approval_status'] == 'PENDING').length;
      final rejectedCount = approvalRecords.where((record) => record['approval_status'] == 'REJECTED').length;
      final pendingRevenue = approvalRecords
          .where((record) => record['approval_status'] == 'PENDING')
          .fold<double>(0.0, (sum, record) => sum + _safeNum(record['proposed_total']));
      final rejectedRevenue = approvalRecords
          .where((record) => record['approval_status'] == 'REJECTED')
          .fold<double>(0.0, (sum, record) => sum + _safeNum(record['proposed_total']));
      final totalRevenue = saleRecords.fold<double>(0.0, (sum, record) => sum + _safeNum(record['amount']));

      final response = <String, dynamic>{
        'status': 'success',
        'metric': metric,
        'timezone': _istTimeZone,
        'period': input['period'] ?? 'all_time',
        'fromDate': from?.toIso8601String(),
        'toDate': to?.toIso8601String(),
        'total_revenue': totalRevenue,
        'total_orders': saleRecords.length,
        'approved_count': approvedCount,
        'pending_count': pendingCount,
        'rejected_count': rejectedCount,
        'pending_revenue': pendingRevenue,
        'rejected_revenue': rejectedRevenue,
        'average_order_value': saleRecords.isNotEmpty ? totalRevenue / saleRecords.length : 0.0,
        'currency': 'INR',
      };

      if (metric == 'profit' || metric == 'overview' || metric == 'time_period') {
        response['gross_profit'] = isCompleteCostBasis ? estimatedGrossProfit : null;
        response['gross_profit_estimate'] = isZeroCostBasis ? 0.0 : estimatedGrossProfit;
        response['gross_profit_status'] = isCompleteCostBasis ? 'complete' : (isZeroCostBasis ? 'no_cost_basis' : 'partial_cost_basis');
        response['cost_basis_coverage'] = costBasisCoverage;
        
        if (isZeroCostBasis) {
          response['gross_profit_message'] = 'Profit cannot be calculated because none of your products have cost data saved in their metadata.';
        } else if (!isCompleteCostBasis) {
          response['gross_profit_message'] = 'Gross profit is partially estimated (${(costBasisCoverage * 100).toStringAsFixed(1)}% coverage) because some products lack cost data.';
        } else {
          response['gross_profit_message'] = 'Gross profit calculated from finalized sales and complete cost records.';
        }
        
        if (missingCostProducts.isNotEmpty) {
          response['missing_cost_product_ids'] = missingCostProducts.toList();
        }
      }

      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to calculate analytics: $e',
        'total_revenue': 0.0,
        'total_orders': 0,
      };
    }
  },
);
