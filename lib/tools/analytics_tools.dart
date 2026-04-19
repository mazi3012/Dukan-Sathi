import 'package:schemantic/schemantic.dart';

import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

final SchemanticType<Map<String, dynamic>> businessInsightsInputSchema =
    SchemanticType.from<Map<String, dynamic>>(
  jsonSchema: {
    'type': 'object',
    'properties': {
      'shopId': {'type': 'string'},
    },
    'required': ['shopId'],
    'additionalProperties': false,
  },
  parse: (json) => Map<String, dynamic>.from(json as Map),
);

final businessInsightsTool = ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'businessInsightsTool',
  description:
      'Use this ONLY for calculating total sales, revenue, or business analytics.',
  inputSchema: businessInsightsInputSchema,
  fn: (input, context) async {
    final shopId = (input['shopId'] as String?)?.trim() ?? '';
    if (shopId.isEmpty) {
      return {
        'total_revenue': 0.0,
        'invoice_count': 0,
      };
    }

    final rows = await supabase
        .from('draft_invoices')
        .select('total_amount')
        .eq('shop_id', shopId);

    final invoices = rows as List<dynamic>;
    final invoiceCount = invoices.length;
    if (invoices.isEmpty) {
      return {
        'total_revenue': 0.0,
        'invoice_count': 0,
      };
    }

    var totalRevenue = 0.0;

    for (final invoice in invoices) {
      final record = Map<String, dynamic>.from(invoice as Map);
      totalRevenue += (record['total_amount'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'total_revenue': totalRevenue,
      'invoice_count': invoiceCount,
    };
  },
);
