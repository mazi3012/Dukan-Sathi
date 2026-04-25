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
      
      final shopId = await getShopIdForUser(userIdentifier);
      
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
