import 'package:schemantic/schemantic.dart';
import '../core/database.dart';
import '../runtime/genkit_runtime.dart';

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
          'description': 'Category (e.g., Utility, Rent, Maintenance, Salary). Defaults to "General" if not specified.',
        },
      },
      'required': ['description', 'amount'],
      'additionalProperties': false,
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
        'category': input['category'] ?? 'General',
        'timestamp': DateTime.now().toIso8601String(),
      });

      return '✅ Expense logged: ₹${input['amount']} for ${input['description']} (${input['category']}).';
    } catch (e) {
      return 'Error logging expense: $e';
    }
  },
);

final getExpenses = ai.defineTool<Map<String, dynamic>, Map<String, dynamic>>(
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
      if (userIdentifier == null) {
        return {'status': 'error', 'message': 'User context missing.'};
      }
      
      final shopId = (context.context?['shopId'] as String?) ?? await getShopIdForUser(userIdentifier);
      final category = input['category'] as String?;
      
      var queryBuilder = supabase.from('expenses').select('id, amount, category, description, timestamp').eq('shop_id', shopId);
      
      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('category', '%$category%');
      }
 
      final response = await queryBuilder.order('timestamp', ascending: false);
      final expenses = response as List<dynamic>;
 
      if (expenses.isEmpty) {
        return {
          'status': 'no_expenses',
          'expenses': [],
          'total': 0.0,
          'category': category,
          'message': 'No expenses found${category != null ? ' for category "$category".' : '.'}',
        };
      }
 
      final expenseList = expenses.map((expRow) {
        final exp = Map<String, dynamic>.from(expRow as Map);
        final amount = (exp['amount'] as num).toDouble();
        final date = DateTime.parse(exp['timestamp'].toString()).toLocal();
        final dateStr = '${date.day}/${date.month}/${date.year}';
        return {
          'id': exp['id'],
          'amount': amount,
          'category': exp['category'],
          'description': exp['description'],
          'date': dateStr,
        };
      }).toList();

      final total = expenseList.fold<double>(0.0, (sum, e) => sum + (e['amount'] as double));
 
      return {
        'status': 'success',
        'expenses': expenseList,
        'total': total,
        'category': category,
        'message': '📋 Expense Report${category != null ? " ($category)" : ""}\nTotal: ₹$total',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error retrieving expenses: $e'};
    }
  },
);
