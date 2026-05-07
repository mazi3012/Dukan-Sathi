import 'package:schemantic/schemantic.dart';
import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

final invoiceLookup = ai.defineTool<Map<String, dynamic>, String>(
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
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = await getShopIdForUser(userIdentifier);
      final invoiceNumber = input['invoiceNumber'] as String?;
      final customerName = input['customerName'] as String?;
      final paymentStatus = input['paymentStatus'] as String?;
      
      var query = supabase.from('sales').select().eq('shop_id', shopId);
      
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
        return 'No invoices found matching your criteria.';
      }

      final buffer = StringBuffer();
      buffer.writeln('🧾 Invoice Lookup Results:\n');
      
      for (final row in sales) {
        final sale = Map<String, dynamic>.from(row as Map);
        final invNum = sale['invoice_number'] as String;
        final cName = sale['customer_name'] as String? ?? 'Unknown';
        final total = (sale['amount'] as num).toDouble();
        final status = sale['payment_status'] as String;
        final date = DateTime.parse(sale['timestamp'].toString()).toLocal();
        final dateStr = '${date.day}/${date.month}/${date.year}';
        
        buffer.writeln('• $invNum ($dateStr)');
        buffer.writeln('  Customer: $cName');
        buffer.writeln('  Total: ₹$total | Status: $status');
        if (status == 'PARTIAL' || status == 'UNPAID') {
           final due = (sale['due_amount'] as num).toDouble();
           buffer.writeln('  Due: ₹$due');
        }
        buffer.writeln('');
      }

      return buffer.toString().trim();
    } catch (e) {
      return 'Error looking up invoices: $e';
    }
  },
);
