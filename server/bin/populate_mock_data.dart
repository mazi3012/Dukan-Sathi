import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
  final url = env['SUPABASE_URL'] ?? '';
  final serviceKey = env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || serviceKey.isEmpty) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY is missing!');
    exit(1);
  }

  final client = SupabaseClient(url, serviceKey);
  final uuid = const Uuid();

  // Find all shops
  final shopsRes = await client.from('shops').select('id, name');
  if (shopsRes.isEmpty) {
    print('No shops found to populate.');
    exit(1);
  }

  for (final shop in shopsRes) {
    final shopId = shop['id'] as String;
    final shopName = shop['name'] as String;

    print('\n=======================================');
    print('Populating mock data for Shop: $shopName ($shopId)');

    // 1. Check if products exist, otherwise insert
    final prodCount = await client.from('products').select('id').eq('shop_id', shopId).limit(1);
    if (prodCount.isEmpty) {
      print('Inserting mock products...');
      final mockProducts = [
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Aashirvaad Atta 5kg',
          'price': 260.0,
          'cost_price': 210.0,
          'stock_quantity': 50,
          'category': 'Grocery',
          'gst_rate': 5.0,
          'metadata': {'brand': 'ITC', 'unit': '5kg'},
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Fortune Mustard Oil 1L',
          'price': 175.0,
          'cost_price': 145.0,
          'stock_quantity': 35,
          'category': 'Grocery',
          'gst_rate': 5.0,
          'metadata': {'brand': 'Fortune', 'unit': '1L'},
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Dettol Liquid Handwash 200ml',
          'price': 99.0,
          'cost_price': 78.0,
          'stock_quantity': 80,
          'category': 'Personal Care',
          'gst_rate': 18.0,
          'metadata': {'brand': 'Reckitt', 'unit': '200ml'},
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Maggi Noodles 12-Pack',
          'price': 168.0,
          'cost_price': 138.0,
          'stock_quantity': 120,
          'category': 'Grocery',
          'gst_rate': 18.0,
          'metadata': {'brand': 'Nestle', 'unit': 'Pack of 12'},
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Amul Butter 500g',
          'price': 275.0,
          'cost_price': 230.0,
          'stock_quantity': 25,
          'category': 'Dairy',
          'gst_rate': 12.0,
          'metadata': {'brand': 'Amul', 'unit': '500g'},
        },
      ];

      for (final p in mockProducts) {
        try {
          await client.from('products').insert(p);
          print('  Inserted product: ${p['name']}');
        } catch (e) {
          print('  Failed to insert product ${p['name']}: $e');
        }
      }
    } else {
      print('Products already exist.');
    }

    // 2. Check if customers exist, otherwise insert
    final custCount = await client.from('customers').select('id').eq('shop_id', shopId).limit(1);
    final List<String> customerIds = [];
    if (custCount.isEmpty) {
      print('Inserting mock customers...');
      final mockCustomers = [
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Rahul Sharma',
          'phone': '9876543210',
          'current_balance': 450.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Priya Patel',
          'phone': '8765432109',
          'current_balance': 1200.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'name': 'Amit Kumar',
          'phone': '7654321098',
          'current_balance': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];

      for (final c in mockCustomers) {
        try {
          await client.from('customers').insert(c);
          customerIds.add(c['id'] as String);
          print('  Inserted customer: ${c['name']}');
        } catch (e) {
          print('  Failed to insert customer ${c['name']}: $e');
        }
      }
    } else {
      print('Customers already exist.');
      try {
        final existing = await client.from('customers').select('id').eq('shop_id', shopId).limit(3);
        customerIds.addAll(existing.map((e) => e['id'] as String));
      } catch (e) {
        print('  Failed to query existing customers: $e');
      }
    }

    // 3. Check if expenses exist, otherwise insert
    List<dynamic> expCount = [];
    try {
      expCount = await client.from('expenses').select('id').eq('shop_id', shopId).limit(1);
    } catch (e) {
      print('  Failed to check expenses: $e');
    }
    if (expCount.isEmpty) {
      print('Inserting mock expenses...');
      final mockExpenses = [
        {
          'shop_id': shopId,
          'description': 'Shop Monthly Rent',
          'amount': 8500.0,
          'category': 'Rent',
          'timestamp': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
        {
          'shop_id': shopId,
          'description': 'Electricity Bill',
          'amount': 1850.0,
          'category': 'Utility',
          'timestamp': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
        {
          'shop_id': shopId,
          'description': 'Tea & Snacks for staff',
          'amount': 350.0,
          'category': 'General',
          'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];

      for (final ex in mockExpenses) {
        try {
          await client.from('expenses').insert(ex);
          print('  Inserted expense: ${ex['description']}');
        } catch (e) {
          print('  Failed to insert expense ${ex['description']}: $e');
        }
      }
    } else {
      print('Expenses already exist.');
    }

    // 4. Check if sales exist, otherwise insert some sales
    final saleCount = await client.from('sales').select('id').eq('shop_id', shopId).limit(1);
    if (saleCount.isEmpty && customerIds.isNotEmpty) {
      print('Inserting mock sales/invoices...');
      final mockSales = [
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'invoice_number': 'INV-1001',
          'customer_id': customerIds[0],
          'customer_name': 'Rahul Sharma',
          'amount': 500.0,
          'subtotal_after_discount': 450.0,
          'due_amount': 450.0,
          'amount_paid': 50.0,
          'payment_status': 'PARTIAL',
          'payment_method': 'cash',
          'status': 'COMPLETED',
          'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'invoice_number': 'INV-1002',
          'customer_id': customerIds[1],
          'customer_name': 'Priya Patel',
          'amount': 1500.0,
          'subtotal_after_discount': 1200.0,
          'due_amount': 1200.0,
          'amount_paid': 300.0,
          'payment_status': 'PARTIAL',
          'payment_method': 'UPI',
          'status': 'COMPLETED',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': uuid.v4(),
          'shop_id': shopId,
          'invoice_number': 'INV-1003',
          'customer_id': customerIds[2],
          'customer_name': 'Amit Kumar',
          'amount': 380.0,
          'subtotal_after_discount': 380.0,
          'due_amount': 0.0,
          'amount_paid': 380.0,
          'payment_status': 'PAID',
          'payment_method': 'UPI',
          'status': 'COMPLETED',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];

      for (final s in mockSales) {
        try {
          await client.from('sales').insert(s);
          print('  Inserted sale: ${s['invoice_number']}');
        } catch (e) {
          print('  Failed to insert sale ${s['invoice_number']}: $e');
        }
      }
    } else {
      print('Sales already exist.');
    }
  }

  print('\nMock data population complete! 🎉');
}
