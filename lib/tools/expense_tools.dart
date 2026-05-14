import 'package:schemantic/schemantic.dart';
import '../core/database.dart';
import '../runtime/genkit_runtime.dart';
import 'analytics_tools.dart';

final logExpense = ai.defineTool<Map<String, dynamic>, String>(
  name: 'logExpense',
  description: 'Log a shop expense (e.g., rent, electricity, repairs).',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'description': {
          'type': 'string',
          'description': 'Description of the expense',
        },
        'amount': {
          'type': 'number',
          'description': 'Expense amount in rupees',
        },
        'category': {
          'type': 'string',
          'description': 'Category (e.g., Utility, Rent, Maintenance, Salary)',
        },
      },
      'required': ['description', 'amount', 'category'],
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      
      await supabase.from('expenses').insert({
        'shop_id': shopId,
        'description': input['description'],
        'amount': input['amount'],
        'category': input['category'],
        'timestamp': DateTime.now().toIso8601String(),
      });

      return '✅ Expense logged: ₹${input['amount']} for ${input['description']} (${input['category']}).';
    } catch (e) {
      return 'Error logging expense: $e';
    }
  },
);

final getExpenses = ai.defineTool<Map<String, dynamic>, String>(
  name: 'getExpenses',
  description: 'Retrieve a summary and list of expenses. Can filter by category or time period.',
  inputSchema: SchemanticType.from<Map<String, dynamic>>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'category': {
          'type': 'string',
          'description': 'Optional category to filter by (e.g., Utility, Rent)',
        },
      },
    },
    parse: (json) => Map<String, dynamic>.from(json as Map),
  ),
  fn: (input, context) async {
    try {
      final userIdentifier = context.context?['userIdentifier'] as String?;
      if (userIdentifier == null) return 'Error: User context missing.';
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      final category = input['category'] as String?;
      
      var queryBuilder = supabase.from('expenses').select().eq('shop_id', shopId);
      
      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('category', '%$category%');
      }

      final response = await queryBuilder.order('timestamp', ascending: false);
      final expenses = response as List<dynamic>;

      if (expenses.isEmpty) {
        return 'No expenses found' + (category != null ? ' for category "$category".' : '.');
      }

      double total = 0;
      final buffer = StringBuffer();
      buffer.writeln('📋 *Expense Report${category != null ? " ($category)" : ""}*');
      
      for (final expRow in expenses) {
        final exp = Map<String, dynamic>.from(expRow as Map);
        final amount = (exp['amount'] as num).toDouble();
        total += amount;
        final date = DateTime.parse(exp['timestamp'].toString()).toLocal();
        final dateStr = '${date.day}/${date.month}/${date.year}';
        buffer.writeln('• ${exp['category']}: ₹$amount - ${exp['description']} ($dateStr)');
      }
      
      buffer.writeln('\n💰 *Total: ₹$total*');
      return buffer.toString();
    } catch (e) {
      return 'Error retrieving expenses: $e';
    }
  },
);
