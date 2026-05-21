import 'package:schemantic/schemantic.dart';
import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

final checkCustomerDue = ai.defineTool<Map<String, dynamic>, String>(
  name: 'checkCustomerDue',
  description: 'Check how much a specific customer owes (their current balance) and list their recent unpaid invoices.',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'customerName': {
          'type': 'string',
          'description': 'Name of the customer',
        },
      },
      'required': ['customerName'],
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      final customerName = input['customerName'] as String;
      
      final customerRes = await supabase
          .from('customers')
          .select('id, name, current_balance')
          .eq('shop_id', shopId)
          .ilike('name', '%$customerName%')
          .maybeSingle();

      if (customerRes == null) {
        return 'No customer found matching "$customerName".';
      }

      final customerData = Map<String, dynamic>.from(customerRes as Map);
      final balance = (customerData['current_balance'] as num?)?.toDouble() ?? 0.0;
      final customerId = customerData['id'] as String;
      final exactName = customerData['name'] as String;

      if (balance <= 0) {
        return '💳 $exactName — No dues. Account is clear.';
      }

      final salesRes = await supabase
          .from('sales')
          .select('id, invoice_number, due_amount, amount_paid, payment_status, timestamp')
          .eq('shop_id', shopId)
          .eq('customer_id', customerId)
          .gt('due_amount', 0)
          .order('timestamp', ascending: false)
          .limit(5);

      final buffer = StringBuffer();
      buffer.writeln('💳 $exactName — Total Due: ₹$balance\n');

      final sales = salesRes as List<dynamic>;
      if (sales.isEmpty) {
        buffer.writeln('No specific unpaid invoices found.');
      } else {
        buffer.writeln('Recent unpaid invoices:');
        for (final saleRow in sales) {
          final sale = Map<String, dynamic>.from(saleRow as Map);
          final invNumber = sale['invoice_number'] as String;
          final due = (sale['due_amount'] as num).toDouble();
          final amountPaid = (sale['amount_paid'] as num?)?.toDouble() ?? 0.0;
          final status = sale['payment_status'] as String;
          
          final date = DateTime.parse(sale['timestamp'].toString()).toLocal();
          final dateStr = '${date.day}/${date.month}/${date.year}';
          
          String extraInfo = '';
          if (status == 'PARTIAL') {
            extraInfo = ' (Partial, ₹$amountPaid paid)';
          } else {
            extraInfo = ' (Unpaid)';
          }
          
          buffer.writeln('• $invNumber — ₹$due$extraInfo — $dateStr');
        }
      }

      return buffer.toString();
    } catch (e) {
      return 'Error checking customer due: $e';
    }
  },
);

final listCustomersDue = ai.defineTool<Map<String, dynamic>, String>(
  name: 'listCustomersDue',
  description: 'List all customers who have outstanding dues/balances.',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {},
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      
      final customersRes = await supabase
          .from('customers')
          .select('id, name, current_balance')
          .eq('shop_id', shopId)
          .gt('current_balance', 0)
          .order('current_balance', ascending: false);

      final customers = customersRes as List<dynamic>;
      if (customers.isEmpty) {
        return 'No customers have outstanding dues.';
      }

      double totalDues = 0;
      final buffer = StringBuffer();
      
      for (final row in customers) {
        final data = Map<String, dynamic>.from(row as Map);
        final name = data['name'] as String;
        final balance = (data['current_balance'] as num).toDouble();
        totalDues += balance;
        buffer.writeln('• $name — ₹$balance');
      }
      
      final header = '📋 Customers with Dues (Total: ₹$totalDues)\n\n';
      return header + buffer.toString();
    } catch (e) {
      return 'Error listing customers with dues: $e';
    }
  },
);

final recordPayment = ai.defineTool<Map<String, dynamic>, String>(
  name: 'recordPayment',
  description: 'Record a payment made by a customer to settle their dues/balance.',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'customerName': {
          'type': 'string',
          'description': 'Name of the customer',
        },
        'amount': {
          'type': 'number',
          'description': 'Amount paid by the customer',
        },
        'paymentMethod': {
          'type': 'string',
          'description': 'Payment method (e.g., cash, UPI, bank)',
        },
      },
      'required': ['customerName', 'amount'],
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      final customerName = input['customerName'] as String;
      final amount = (input['amount'] as num).toDouble();
      final paymentMethod = (input['paymentMethod'] as String?) ?? 'cash';
      
      if (amount <= 0) {
        return 'Amount must be greater than zero.';
      }

      final customerRes = await supabase
          .from('customers')
          .select('id, name, current_balance')
          .eq('shop_id', shopId)
          .ilike('name', '%$customerName%')
          .maybeSingle();

      if (customerRes == null) {
        return 'No customer found matching "$customerName".';
      }

      final customerData = Map<String, dynamic>.from(customerRes as Map);
      final customerId = customerData['id'] as String;
      final exactName = customerData['name'] as String;
      final currentBalance = (customerData['current_balance'] as num?)?.toDouble() ?? 0.0;

      // Update customer balance
      final newBalance = currentBalance - amount;
      
      await supabase.from('customers').update({
        'current_balance': newBalance < 0 ? 0 : newBalance, // Prevent negative balance
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', customerId);

      // Record payment
      await supabase.from('payments').insert({
        'shop_id': shopId,
        'customer_id': customerId,
        'amount': amount,
        'payment_method': paymentMethod,
        'recorded_by': 'AI Assistant',
      });

      return '✅ Recorded ₹$amount payment from $exactName via $paymentMethod.\nNew balance: ₹${newBalance < 0 ? 0 : newBalance}';
    } catch (e) {
      return 'Error recording payment: $e';
    }
  },
);
