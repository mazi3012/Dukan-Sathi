import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

final SchemanticType<Map<String, dynamic>> businessInsightsInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'shopId': {'type': 'string'},
      'metric': {
        'type': 'string',
        'enum': ['overview', 'revenue', 'approval_status', 'time_period'],
        'description': 'Type of analytics to retrieve',
      },
    },
    'required': [],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final businessInsightsTool = ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'businessInsightsTool',
  description:
      'Get comprehensive business analytics including total revenue, approval status breakdown, order metrics, and financial insights. Supports: overview (all metrics), revenue (sales data), approval_status (pending/approved/rejected breakdown), time_period (recent trends)',
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
      // Fetch all draft approvals for the shop
      final approvals = await supabase
          .from('draft_approvals')
          .select('approval_id, proposed_total, approval_status, created_at, reviewed_at')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      final records = approvals as List<dynamic>;
      
      if (records.isEmpty) {
        return {
          'status': 'success',
          'message': 'No invoices found',
          'total_revenue': 0.0,
          'total_orders': 0,
          'pending_revenue': 0.0,
          'approved_count': 0,
          'pending_count': 0,
          'rejected_count': 0,
          'average_order_value': 0.0,
        };
      }

      // Calculate metrics
      var totalRevenue = 0.0;
      var totalPendingRevenue = 0.0;
      var totalRejectedRevenue = 0.0;
      var approvedCount = 0;
      var pendingCount = 0;
      var rejectedCount = 0;

      for (final record in records) {
        final data = Map<String, dynamic>.from(record as Map);
        final amount = (data['proposed_total'] as num?)?.toDouble() ?? 0.0;
        final status = data['approval_status'] as String?;

        if (status == 'APPROVED') {
          totalRevenue += amount;
          approvedCount++;
        } else if (status == 'PENDING') {
          totalPendingRevenue += amount;
          pendingCount++;
        } else if (status == 'REJECTED') {
          totalRejectedRevenue += amount;
          rejectedCount++;
        }
      }

      final totalOrders = records.length;
      final averageOrderValue = totalOrders > 0 ? totalRevenue / approvedCount : 0.0;

      // Return comprehensive analytics
      return {
        'status': 'success',
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'approved_count': approvedCount,
        'pending_count': pendingCount,
        'rejected_count': rejectedCount,
        'pending_revenue': totalPendingRevenue,
        'rejected_revenue': totalRejectedRevenue,
        'average_order_value': averageOrderValue > 0 ? averageOrderValue : 0.0,
        'approval_rate': totalOrders > 0 ? (approvedCount / totalOrders * 100).toStringAsFixed(1) : '0.0',
        'currency': 'INR',
      };
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
