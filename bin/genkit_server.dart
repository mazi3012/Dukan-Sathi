import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';
import 'package:dukansathi_new/services/admin_service.dart';
import 'package:dukansathi_new/core/database.dart';
import 'package:dukansathi_new/models/product.dart';
import 'package:dukansathi_new/tools/inventory_tools.dart';
import 'package:dukansathi_new/tools/approval_tools.dart';
import 'package:dukansathi_new/tools/billing_tools.dart';
import 'package:dukansathi_new/tools/analytics_tools.dart';
import 'package:dukansathi_new/services/invoice_pdf_generator.dart';
import 'package:genkit/genkit.dart';

Future<void> main(List<String> arguments) async {
  // Initialize all tools and flows
  initializeBackend();
  
  // Get port from environment or use default
  final port = int.tryParse(Platform.environment['PORT'] ?? '3100') ?? 3100;
  
  // Create a simple HTTP server for Genkit reflection API
  final server = await HttpServer.bind('localhost', port);
  
  print('🚀 Genkit Reflection Server Started!');
  print('');
  print('✅ Server is running on port $port');
  print('');
  print('🔗 Access URLs:');
  print('   http://localhost:$port - Genkit UI');
  print('   http://localhost:$port/api/listActions - List all actions');
  print('   http://localhost:$port/api/runAction - Run an action');
  print('   http://localhost:$port/api/admin/roles - Admin: List all roles ✨ NEW');
  print('   http://localhost:$port/api/admin/permissions - Admin: List permissions ✨ NEW');
  print('   http://localhost:$port/api/admin/users - Admin: List users ✨ NEW');
  print('   http://localhost:$port/api/admin/audit-log - Admin: Audit logs ✨ NEW');
  print('');
  print('🎯 Example Flows:');
  print('   • POST to /api/runAction');
  print('   • Body: {"key":"/flow/retailAssistantFlow","input":"What is the price of atta?"}');
  print('');
  print('👨‍💼 Admin API Examples:');
  print('   • curl http://localhost:$port/api/admin/roles');
  print('   • curl http://localhost:$port/api/admin/users');
  print('   • curl http://localhost:$port/api/admin/permissions');
  print('');
  print('🔧 Tools Available:');
  print('   • checkInventory');
  print('   • browseCatalogTool');
  print('   • createDraftInvoice');
  print('   • businessInsightsTool ✨ Analytics');
  print('   • proposeProducts ✨ Product Management');
  print('   • requestProductDeletion ✨ Human approval delete flow');
  print('');
  print('💬 Telegram Bot: @Sathiaibeta_bot');
  print('');
  print('Press Ctrl+C to stop.');
  print('');

  // ─── WEB CHAT SESSION (mirrors Telegram Chat class) ─────────────────────
  final Map<String, WebChatSession> webSessions = {};

  // Handle incoming HTTP requests
  server.listen((HttpRequest request) async {
    // Add CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = 200
        ..close();
      return;
    }

    try {
      if (request.method == 'GET' && request.uri.path == '/') {
        // Serve dashboard overview
        try {
          final file = File('public/index.html');
          if (file.existsSync()) {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write(file.readAsStringSync())
              ..close();
          } else {
            // Fallback to JSON API info
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({
                'status': 'running',
                'genkit_version': '0.12.1',
                'ai_provider': aiProvider,
                'model': modelId,
                'endpoints': {
                  'listActions': '/api/listActions',
                  'runAction': '/api/runAction',
                },
                'flows': ['/flow/retailAssistantFlow'],
                'tools': ['checkInventory', 'browseCatalogTool', 'createDraftInvoice', 'businessInsightsTool', 'proposeProducts', 'requestProductDeletion'],
                'admin_endpoints': {
                  'roles': '/api/admin/roles',
                  'users': '/api/admin/users',
                  'permissions': '/api/admin/permissions',
                  'audit_log': '/api/admin/audit-log',
                },
              }))
              ..close();
          }
        } catch (e) {
          request.response
            ..statusCode = 500
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'Failed to load dashboard: $e'}))
            ..close();
        }
      } else if (request.method == 'GET' && request.uri.path == '/api/listActions') {
        // Return list of available actions
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'actions': [
              {
                'name': 'retailAssistantFlow',
                'type': 'flow',
                'key': '/flow/retailAssistantFlow',
                'description': 'Retail assistant AI flow',
                'input_schema': {'type': 'string'},
                'output_schema': {'type': 'string'},
              },
              {
                'name': 'checkInventory',
                'type': 'tool',
                'key': '/tool/checkInventory',
                'description': 'Check product inventory and prices',
              },
              {
                'name': 'createDraftInvoice',
                'type': 'tool',
                'key': '/tool/createDraftInvoice',
                'description': 'Create a draft invoice',
              },
              {
                'name': 'browseCatalogTool',
                'type': 'tool',
                'key': '/tool/browseCatalogTool',
                'description': 'Browse product catalog by category',
              },
              {
                'name': 'businessInsightsTool',
                'type': 'tool',
                'key': '/tool/businessInsightsTool',
                'description': 'Get business analytics (revenue, orders, approval metrics)',
              },
              {
                'name': 'proposeProducts',
                'type': 'tool',
                'key': '/tool/proposeProducts',
                'description': 'Propose new products for inventory approval',
              },
              {
                'name': 'requestProductDeletion',
                'type': 'tool',
                'key': '/tool/requestProductDeletion',
                'description': 'Request approval before deleting products',
              },
            ],
          }))
          ..close();
      } else if (request.method == 'POST' && request.uri.path.startsWith('/api/runAction')) {
        // Handle POST requests to run actions
        var body = await utf8.decodeStream(request);
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final key = data['key'] as String?;
          final input = data['input'] as String?;
          
          if (key == '/flow/retailAssistantFlow' && input != null) {
            // Run the retail assistant flow
            final result = await retailAssistantFlow(input);
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({
                'result': result,
                'telemetry': {'status': 'success'},
              }))
              ..close();
          } else {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': 'Invalid action key or input'}))
              ..close();
          }
        } catch (e) {
          request.response
            ..statusCode = 500
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': e.toString()}))
            ..close();
        }
      } else if (request.method == 'POST' && request.uri.path == '/api/chat') {
        // ─── SMART CHAT ENDPOINT (mirrors Telegram bot capabilities) ─────
        var body = await utf8.decodeStream(request);
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final input = (data['input'] as String?)?.trim() ?? '';
          final sessionId = (data['sessionId'] as String?) ?? 'default';
          final shopId = (data['shopId'] as String?);
          final userId = (data['userId'] as String?);

          if (input.isEmpty) {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': 'Input is required'}))
              ..close();
            return;
          }

          // Get or create session
          final session = webSessions.putIfAbsent(sessionId, () => WebChatSession());

          final result = await session.processMessage(input, shopId: shopId, userId: userId);

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(result))
            ..close();
        } catch (e) {
          request.response
            ..statusCode = 500
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': e.toString()}))
            ..close();
        }
      } else if (request.method == 'GET' && request.uri.path == '/api/get-draft') {
        // ─── GET DRAFT DETAILS ──────────────────────────────────────────
        final approvalId = request.uri.queryParameters['approvalId'];
        if (approvalId == null) {
          request.response..statusCode = 400..close();
          return;
        }
        final draft = await getApprovalDetails(approvalId);
        request.response
          ..statusCode = draft != null ? 200 : 404
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(draft ?? {'error': 'Draft not found'}))
          ..close();
      } else if (request.method == 'GET' && request.uri.path == '/api/download-invoice') {
        // ─── DOWNLOAD INVOICE PDF ───────────────────────────────────────
        final approvalId = request.uri.queryParameters['approvalId'];
        if (approvalId == null) {
          request.response..statusCode = 400..write('Missing approvalId')..close();
          return;
        }
        try {
          final result = await getApprovalDetails(approvalId);
          if (result == null || result['approval_status'] != 'APPROVED') {
            request.response..statusCode = 404..write('Not approved or not found')..close();
            return;
          }
          final invoiceNumber = 'INV-${approvalId.substring(0, 13).replaceAll('-', '').toUpperCase()}';
          final pdf = await InvoicePdfGenerator.generateApprovedInvoicePdf(
            approvalId: approvalId,
            invoiceNumber: invoiceNumber,
          );
          final bytes = await pdf.file.readAsBytes();
          
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType('application', 'pdf')
            ..headers.add('Content-Disposition', 'attachment; filename="invoice_$invoiceNumber.pdf"')
            ..add(bytes)
            ..close();
            
          try { pdf.file.deleteSync(); } catch (_) {}
        } catch (e) {
          request.response..statusCode = 500..write(e.toString())..close();
        }
      } else if (request.method == 'POST' && request.uri.path == '/api/update-draft') {
        // ─── UPDATE DRAFT (GST, DISCOUNT, PAYMENT) ──────────────────────
        var body = await utf8.decodeStream(request);
        String currentType = 'unknown';
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final approvalId = data['approvalId']?.toString();
          if (approvalId == null) throw Exception("Missing approvalId");
          
          final type = data['type']?.toString() ?? 'unknown';
          currentType = type;
          
          Map<String, dynamic> result;
          if (type == 'gst') {
            final gstType = data['gstType']?.toString();
            if (gstType == null) throw Exception("Missing gstType");
            result = await switchGstType(approvalId: approvalId, newGstType: gstType);
          } else if (type == 'discount') {
            final dType = data['discountType']?.toString();
            final dVal = (data['discountValue'] as num?)?.toDouble();
            if (dType == null || dVal == null) throw Exception("Missing discount parameters");
            result = await updateDraftDiscount(
              approvalId: approvalId,
              discountType: dType,
              discountValue: dVal,
            );
          } else if (type == 'payment') {
            final pStatus = data['paymentStatus']?.toString();
            if (pStatus == null) throw Exception("Missing paymentStatus");
            result = await updateDraftPaymentStatus(
              approvalId: approvalId,
              paymentStatus: pStatus,
              amountPaid: (data['amountPaid'] as num?)?.toDouble(),
            );
          } else if (type == 'edit_item') {
            final productId = data['productId']?.toString();
            final quantity = (data['quantity'] as num?)?.toInt();
            final unitPrice = (data['unitPrice'] as num?)?.toDouble();
            if (productId == null || quantity == null) throw Exception("Missing productId or quantity for edit_item");
            result = await updateDraftItem(
              approvalId: approvalId,
              productId: productId,
              newQuantity: quantity,
              newUnitPrice: unitPrice,
            );
          } else {
            result = {'success': false, 'error': 'Invalid update type: $type'};
          }

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(result))
            ..close();
        } catch (e) {
          request.response..statusCode = 500..write("Server Error ($currentType): ${e.toString()}")..close();
        }
      } else if (request.method == 'POST' && request.uri.path == '/api/approve-draft') {
        // ─── APPROVE DRAFT ──────────────────────────────────────────────
        var body = await utf8.decodeStream(request);
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final approvalId = data['approvalId'] as String;
          final reviewedBy = data['userId'] ?? 'web-user';
          
          final result = await approveDraftInvoice(approvalId: approvalId, reviewedBy: reviewedBy);
          
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(result))
            ..close();
        } catch (e) {
          request.response..statusCode = 500..write(e.toString())..close();
        }
      } else if (request.method == 'POST' && request.uri.path == '/api/verify-code') {
        // ─── MAGIC CODE LOGIN VERIFICATION ──────────────────────────────
        var body = await utf8.decodeStream(request);
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final code = (data['code'] as String?)?.trim() ?? '';

          if (code.isEmpty || code.length != 6) {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': false, 'error': 'Invalid code format'}))
              ..close();
            return;
          }

          // Look up code in login_codes table
          final codeRow = await supabase
              .from('login_codes')
              .select('id, user_id, expires_at, used')
              .eq('code', code)
              .eq('used', false)
              .maybeSingle();

          if (codeRow == null) {
            request.response
              ..statusCode = 401
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': false, 'error': 'Invalid or expired code'}))
              ..close();
            return;
          }

          // Check expiry
          final expiresAt = DateTime.parse(codeRow['expires_at'] as String);
          if (DateTime.now().toUtc().isAfter(expiresAt)) {
            // Delete expired code
            await supabase.from('login_codes').delete().eq('id', codeRow['id']);
            request.response
              ..statusCode = 401
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': false, 'error': 'Code has expired. Send /login again in Telegram.'}))
              ..close();
            return;
          }

          final userId = codeRow['user_id'] as String;

          // Mark code as used
          await supabase.from('login_codes').update({'used': true}).eq('id', codeRow['id']);

          // Get user info and shop
          final userRow = await supabase
              .from('users')
              .select('id, full_name, telegram_id, email')
              .eq('id', userId)
              .single();

          // Get shop info
          final shopRow = await supabase
              .from('shops')
              .select('id, name, business_type, state')
              .eq('owner_id', userId)
              .eq('onboarding_completed', true)
              .maybeSingle();

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'success': true,
              'user': {
                'id': userRow['id'],
                'full_name': userRow['full_name'],
                'telegram_id': userRow['telegram_id'],
                'email': userRow['email'],
              },
              'shop': shopRow != null ? {
                'id': shopRow['id'],
                'name': shopRow['name'],
                'business_type': shopRow['business_type'],
                'state': shopRow['state'],
              } : null,
            }))
            ..close();
        } catch (e) {
          request.response
            ..statusCode = 500
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'success': false, 'error': e.toString()}))
            ..close();
        }
      } else if (request.method == 'GET' && request.uri.path == '/api/session') {
        // ─── SESSION VALIDATION ─────────────────────────────────────────
        try {
          final userId = request.uri.queryParameters['userId'] ?? '';
          if (userId.isEmpty) {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': false, 'error': 'Missing userId'}))
              ..close();
            return;
          }

          final userRow = await supabase
              .from('users')
              .select('id, full_name, email')
              .eq('id', userId)
              .maybeSingle();

          if (userRow == null) {
            request.response
              ..statusCode = 401
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': false, 'error': 'Invalid session'}))
              ..close();
            return;
          }

          final shopRow = await supabase
              .from('shops')
              .select('id, name, business_type, state')
              .eq('owner_id', userId)
              .eq('onboarding_completed', true)
              .maybeSingle();

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'success': true,
              'user': userRow,
              'shop': shopRow,
            }))
            ..close();
        } catch (e) {
          request.response
            ..statusCode = 500
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'success': false, 'error': e.toString()}))
            ..close();
        }
      } else if (request.uri.path.startsWith('/api/admin/')) {
        // Handle admin API endpoints
        try {
          final adminService = AdminService(supabase);
          final path = request.uri.path;
          
          // Admin routes
          if (request.method == 'GET' && path == '/api/admin/roles') {
            final roles = await adminService.getRoles();
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': true, 'data': roles}))
              ..close();
          } else if (request.method == 'GET' && path == '/api/admin/permissions') {
            final perms = await adminService.getPermissions();
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': true, 'data': perms}))
              ..close();
          } else if (request.method == 'GET' && path == '/api/admin/users') {
            final users = await adminService.getAdminUsers();
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': true, 'data': users}))
              ..close();
          } else if (request.method == 'GET' && path.startsWith('/api/admin/users/')) {
            final userId = path.split('/').last;
            final user = await adminService.getAdminUserById(userId);
            if (user != null) {
              request.response
                ..statusCode = 200
                ..headers.contentType = ContentType.json
                ..write(jsonEncode({'success': true, 'data': user}))
                ..close();
            } else {
              request.response
                ..statusCode = 404
                ..headers.contentType = ContentType.json
                ..write(jsonEncode({'success': false, 'error': 'User not found'}))
                ..close();
            }
          } else if (request.method == 'GET' && path == '/api/admin/audit-log') {
            final logs = await adminService.getAuditLog();
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': true, 'data': logs}))
              ..close();
          } else {
            request.response
              ..statusCode = 404
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': false, 'error': 'Admin endpoint not found'}))
              ..close();
          }
        } catch (e) {
          request.response
            ..statusCode = 500
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'success': false, 'error': e.toString()}))
            ..close();
        }
      } else {
        request.response
          ..statusCode = 404
          ..headers.contentType = ContentType.text
          ..write('Not Found')
          ..close();
      }
    } catch (e) {
      request.response
        ..statusCode = 500
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': e.toString()}))
        ..close();
    }
  });
  
  // Handle shutdown
  final signal = ProcessSignal.sigterm;
  signal.watch().listen((_) {
    print('\n👋 Shutting down Genkit server...');
    server.close();
    exit(0);
  });
}

// ─── WEB CHAT SESSION ──────────────────────────────────────────────────────────
// Mirrors the Telegram bot's Chat class for feature parity.

const String _webSystemPrompt =
  "You are Dukan Sathi Pro, a premium AI retail shop assistant. CRITICAL RULES: "
  "1. NEVER make up, guess, or hallucinate product names, prices, stock, or any data. ONLY use real data from tool responses. "
  "2. If inventory/catalog is empty, say so plainly — never invent sample products. "
  "3. No narration (never say 'I am checking' or 'Let me look up'). Use tools silently, output final result only. "
  "4. If you create a draft invoice, ALWAYS include the Approval ID. "
  "5. customerId, customerName, and customerState are OPTIONAL — do NOT ask for them; call the tool immediately. "
  "6. For specific product lookups, use checkInventory. For full product lists, use browseCatalogTool. "
  "7. For business analytics (revenue, orders, approval status), use businessInsightsTool. "
  "8. Present analytics in clear format: 'Total Revenue: ₹X | Orders: Y | Approved: Z'. "
  "9. For product deletion, use deleteProduct. "
  "10. For shop expenses, use logExpense to record and getExpenses to retrieve. "
  "11. Always reply concisely in a friendly, professional manner.";

DateTime _nowIst() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
String _twoDigits(int v) => v.toString().padLeft(2, '0');
String _fmtTime(DateTime d) {
  var h = d.hour; final m = _twoDigits(d.minute); final p = h >= 12 ? 'PM' : 'AM';
  h = h % 12; if (h == 0) h = 12;
  return '${_twoDigits(h)}:$m $p';
}
String _fmtDate(DateTime d) => '${d.year}-${_twoDigits(d.month)}-${_twoDigits(d.day)}';
String _fmtPrice(double p) => p == p.roundToDouble() ? p.toInt().toString() : p.toStringAsFixed(2);

class WebChatSession {
  final List<Message> _history = [];
  String? _currentShopId;
  String? _currentUserId;
  String get userIdentifier => _currentUserId ?? 'web-user';
  String? get shopId => _currentShopId;

  // ─── INTENT DETECTION (same as Telegram bot) ───────────────────────────
  bool _isTimeIntent(String n) => n.contains('what time') || n.contains('current time') || n.contains('time now');
  bool _isDateIntent(String n) => n.contains('what is the date') || n.contains('today\'s date') || n.contains('current date') || n.contains('what day');
  bool _isCatalogIntent(String n) => n.contains('what item') || n.contains('what items') || n.contains('catalog') || n.contains('list product') ||
      n.contains('show product') || n.contains('show item') || n.contains('what do you have') || n.contains('what do we have') ||
      n.contains('items do we have') || n.contains('items do you have') || n.contains('our product') || n.contains('our inventory') ||
      n.contains('show inventory') || n.contains('view product') || n.contains('what do you sell') || n.contains('what do we sell');
  bool _isInventoryIntent(String n) => n.contains('stock') || n.contains('inventory') || n.contains('price') || n.contains('how many') || n.contains('quantity');
  bool _isBillingIntent(String n) => n.contains('bill') || n.contains('invoice') || n.contains('draft');
  bool _isAnalyticsIntent(String n) => n.contains('revenue') || n.contains('sales') || n.contains('analytics') || n.contains('insight') ||
      n.contains('profit') || n.contains('earnings') || n.contains('orders') || n.contains('total sales');
  bool _isExpenseIntent(String n) => n.contains('expense') || n.contains('spent') || n.contains('bill paid') || n.contains('cost');

  String _extractInventoryQuery(String input) {
    var n = input.toLowerCase();
    for (final p in ['what is the price of', 'price of', 'how many', 'do we have', 'we have', 'in stock', 'stock of', 'quantity of', 'available', 'please']) {
      n = n.replaceAll(p, ' ');
    }
    return n.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Map<String, int> _parseBillingItems(String input) {
    var text = input.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'^(please\s+)?(make|create|generate)\s+(a\s+)?(bill|invoice)\s*(for|with|to)?\s*'), '').replaceAll(RegExp(r'\.$'), '').trim();
    if (text.isEmpty) return {};
    final requested = <String, int>{};
    final pattern = RegExp(r'(\d+)\s*x?\s+([a-z0-9][a-z0-9\s\-()\/]*?)(?=(?:\s+(?:and|with|plus|,|;|\.|$))|$)', caseSensitive: false);
    for (final match in pattern.allMatches(text.replaceAll(RegExp(r'\s+'), ' ').trim())) {
      final qty = int.tryParse(match.group(1) ?? '');
      var name = match.group(2)?.trim() ?? '';
      name = name.replaceAll(RegExp(r'\b(he|she|they|customer|buyer|for|to|the|a|an|of|item|items|product|products)\b'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (qty != null && qty > 0 && name.isNotEmpty) requested[name] = (requested[name] ?? 0) + qty;
    }
    return requested;
  }

  String? _extractCustomerName(String input) {
    var text = input.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'^(please\s+)?(make|create|generate)\s+(a\s+)?(bill|invoice)\s*(for|with|to)?\s*'), '').replaceAll(RegExp(r'\.$'), '').trim();
    if (text.isEmpty) return null;
    final stopWords = {'he', 'she', 'they', 'customer', 'buyer', 'bought', 'want', 'for', 'to', 'the', 'a', 'an', 'of', 'item', 'items'};
    final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final nameTokens = <String>[];
    for (final token in tokens) {
      if (RegExp(r'^\d+$').hasMatch(token)) break;
      if (stopWords.contains(token)) break;
      nameTokens.add(token);
    }
    if (nameTokens.isEmpty) return null;
    return nameTokens.map((t) => t[0].toUpperCase() + t.substring(1)).join(' ');
  }

  // ─── MAIN MESSAGE HANDLER ─────────────────────────────────────────────
  Future<Map<String, dynamic>> processMessage(String input, {String? shopId, String? userId}) async {
    if (shopId != null) _currentShopId = shopId;
    if (userId != null) _currentUserId = userId;
    
    if (_currentShopId == null) {
      return {'text': '⚠️ Shop context not found. Please ensure you are logged in.'};
    }
    
    final n = input.toLowerCase().trim();

    // Time intent
    if (_isTimeIntent(n)) {
      final now = _nowIst();
      final text = 'The current time is ${_fmtTime(now)} IST.';
      _addToHistory(input, text);
      return {'text': text};
    }

    // Date intent
    if (_isDateIntent(n)) {
      final now = _nowIst();
      final text = "Today's date is ${_fmtDate(now)} IST.";
      _addToHistory(input, text);
      return {'text': text};
    }

    // Catalog intent → direct DB query, return structured card data
    if (_isCatalogIntent(n)) {
      try {
        final rows = await supabase
            .from('products')
            .select('id, shop_id, name, price, stock_quantity, category, cost_price')
            .eq('shop_id', shopId!)
            .limit(20);
        final products = (rows as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();

        if (products.isEmpty) {
          const text = '🏪 Your catalog is empty right now.\n\nTip: Say "Add product" to add your first product!';
          _addToHistory(input, text);
          return {'text': text};
        }

        final summary = '📦 Here are your products (${products.length}):';
        _addToHistory(input, summary);
        return {
          'text': summary,
          'card': {'type': 'inventory', 'items': products},
        };
      } catch (e) {
        return {'text': '⚠️ Could not load catalog: $e'};
      }
    }

    // Inventory (specific product lookup)
    if (_isInventoryIntent(n) && !_isBillingIntent(n)) {
      final query = _extractInventoryQuery(input);
      final products = await findInventoryProducts(query.isEmpty ? input : query, shopId!);
      if (products.isEmpty) {
        const text = 'That product is not in your inventory.';
        _addToHistory(input, text);
        return {'text': text};
      }
      final items = products.map((p) => {
        'name': p.name,
        'price': p.price,
        'stock_quantity': p.stockQuantity,
        'category': p.category,
      }).toList();
      final text = products.length == 1
          ? '${products.first.name}: ₹${_fmtPrice(products.first.price)}, ${products.first.stockQuantity} units in stock.'
          : '${products.length} products found:';
      _addToHistory(input, text);
      return {
        'text': text,
        'card': {'type': 'inventory', 'items': items},
      };
    }

    // Billing intent → direct tool call
    if (_isBillingIntent(n)) {
      final requestedItems = _parseBillingItems(input);
      if (requestedItems.isNotEmpty) {
        try {
          final customerName = _extractCustomerName(input);
          final result = await createDraftInvoiceRequest(
            input: {
              'requestedItems': requestedItems,
              if (customerName != null) 'customerName': customerName,
            },
            userIdentifier: userIdentifier,
          );
          final text = 'Draft invoice created! Approval ID: ${result['approvalId']}';
          _addToHistory(input, text);
          return {
            'text': text,
            'card': {'type': 'invoice', ...result},
          };
        } catch (e) {
          final text = e.toString().replaceFirst('Bad state: ', '').trim();
          _addToHistory(input, text);
          return {'text': text};
        }
      }
    }

    // Analytics intent → use AI with tools
    // Expense intent → use AI with tools
    // General conversation → use AI

    _history.add(Message(role: Role.user, content: [TextPart(text: input)]));

    final allTools = [
      'checkInventory',
      'browseCatalogTool',
      'createDraftInvoice',
      'businessInsightsTool',
      'proposeProducts',
      'requestProductDeletion',
      'getWeather',
      'setReminder',
      'logExpense',
      'getExpenses',
    ];

    try {
      final response = await ai.generate(
        model: appModel(),
        messages: [
          Message(role: Role.system, content: [
            TextPart(text: '$_webSystemPrompt\nCurrent IST: ${_fmtDate(_nowIst())} ${_fmtTime(_nowIst())}'),
          ]),
          ..._history,
        ],
        toolNames: allTools,
        context: {'userIdentifier': userIdentifier},
      );
      final reply = response.text.trim();
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return {'text': reply};
    } catch (e) {
      return {'text': 'Sorry, something went wrong: ${e.toString().split('\n').first}'};
    }
  }

  void _addToHistory(String input, String reply) {
    _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
    _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
  }
}
