import 'package:schemantic/schemantic.dart';
import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

final invoiceLookup = ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
  name: 'invoiceLookup',
  description: 'Look up past invoices by invoice number, customer name, or payment status (e.g., unpaid).',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'invoiceNumber': {
          'type': 'string',
          'description': 'Optional invoice number (e.g., INV-1234)',
        },
        'customerName': {
          'type': 'string',
          'description': 'Optional customer name to filter by',
        },
        'paymentStatus': {
          'type': 'string',
          'description': 'Optional status filter (PAID, UNPAID, PARTIAL)',
        },
      },
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) {
        return {'status': 'error', 'message': 'User context missing.'};
      }
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      final invoiceNumber = input['invoiceNumber'] as String?;
      final customerName = input['customerName'] as String?;
      final paymentStatus = input['paymentStatus'] as String?;
      
      var query = supabase.from('sales').select('id, invoice_number, customer_name, amount, payment_status, timestamp, due_amount').eq('shop_id', shopId);
      
      if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
        query = query.ilike('invoice_number', '%$invoiceNumber%');
      }
      if (customerName != null && customerName.isNotEmpty) {
        query = query.ilike('customer_name', '%$customerName%');
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        query = query.eq('payment_status', paymentStatus.toUpperCase());
      }
      
      final res = await query.order('timestamp', ascending: false).limit(5);
      final sales = res as List<dynamic>;

      if (sales.isEmpty) {
        return {
          'status': 'no_invoices',
          'invoices': [],
          'message': 'No invoices found matching your criteria.',
        };
      }

      final invoiceList = sales.map((row) {
        final sale = Map<String, dynamic>.from(row as Map);
        final date = DateTime.parse(sale['timestamp'].toString()).toLocal();
        final dateStr = '${date.day}/${date.month}/${date.year}';
        return {
          'id': sale['id'],
          'invoiceNumber': sale['invoice_number'] as String,
          'customerName': sale['customer_name'] as String? ?? 'Unknown',
          'total': (sale['amount'] as num).toDouble(),
          'paymentStatus': sale['payment_status'] as String,
          'dueAmount': (sale['due_amount'] as num?)?.toDouble() ?? 0.0,
          'date': dateStr,
        };
      }).toList();

      return {
        'status': 'success',
        'invoices': invoiceList,
        'message': '🧾 Found ${invoiceList.length} invoices matching criteria.',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error looking up invoices: $e'};
    }
  },
);
