import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_server/bootstrap.dart';
import 'package:dukansathi_server/runtime/genkit_runtime.dart';
import 'package:dukansathi_server/flows/retail_assistant.dart';
import 'package:dukansathi_server/shared/services/admin_service.dart';
import 'package:dukansathi_server/core/database.dart';
import 'package:dukansathi_server/tools/inventory_tools.dart';
import 'package:dukansathi_server/tools/approval_tools.dart';
import 'package:dukansathi_server/tools/billing_tools.dart';
import 'package:dukansathi_server/tools/analytics_tools.dart';
import 'package:dukansathi_server/tools/customer_tools.dart' as cust;
import 'package:dukansathi_server/shared/services/invoice_pdf_generator.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// ─── API RATE LIMITING SYSTEM ────────────────────────────────────────────────
class RateLimitRule {
  final int maxRequests;
  final Duration window;

  const RateLimitRule({required this.maxRequests, required this.window});
}

class RateLimiter {
  // Store the request timestamps: IP -> Map<PathPrefix/Category, List<DateTime>>
  final Map<String, Map<String, List<DateTime>>> _requests = {};

  // Rate limit rules for different path prefixes
  final Map<String, RateLimitRule> _rules = {
    '/api/transcribe': const RateLimitRule(maxRequests: 10, window: Duration(minutes: 1)),
    '/api/chat': const RateLimitRule(maxRequests: 20, window: Duration(minutes: 1)),
    '/api/runAction': const RateLimitRule(maxRequests: 20, window: Duration(minutes: 1)),
    'default': const RateLimitRule(maxRequests: 60, window: Duration(minutes: 1)),
  };

  bool isAllowed(String ip, String path, DateTime now) {
    // Find matching rule
    final ruleKey = _rules.keys.firstWhere(
      (prefix) => prefix != 'default' && path.startsWith(prefix),
      orElse: () => 'default',
    );
    final rule = _rules[ruleKey]!;

    _requests.putIfAbsent(ip, () => {});
    final ipRequests = _requests[ip]!;
    ipRequests.putIfAbsent(ruleKey, () => []);
    
    final timestamps = ipRequests[ruleKey]!;

    // Clean up outdated timestamps
    final cutoff = now.subtract(rule.window);
    timestamps.removeWhere((t) => t.isBefore(cutoff));

    if (timestamps.length >= rule.maxRequests) {
      return false;
    }

    timestamps.add(now);
    return true;
  }

  Duration getRetryAfter(String ip, String path, DateTime now) {
    final ruleKey = _rules.keys.firstWhere(
      (prefix) => prefix != 'default' && path.startsWith(prefix),
      orElse: () => 'default',
    );
    final rule = _rules[ruleKey]!;
    
    final timestamps = _requests[ip]?[ruleKey] ?? [];
    if (timestamps.isEmpty) return Duration.zero;

    final oldest = timestamps.first;
    final nextAvailable = oldest.add(rule.window);
    final diff = nextAvailable.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}

Future<void> main(List<String> arguments) async {
  print('--- Genkit Server Initializing ---');
  try {
    initializeGenkit();
    print('✅ Genkit initialized successfully');
  } catch (e) {
    print('❌ FATAL: Could not initialize Genkit: $e');
    exit(1);
  }
  try {
    initializeBackend();
  } catch (e) {
    print('❌ Error during initializeBackend: $e');
  }
  
  // Get port from environment or use default
  final port = int.tryParse(Platform.environment['PORT'] ?? '3100') ?? 3100;
  
  // Create a simple HTTP server for Genkit reflection API
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  
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
  print('');
  print('Press Ctrl+C to stop.');
  print('');


  // ─── WEB CHAT SESSION ──────────────────────────────────────────────────
  final Map<String, WebChatSession> webSessions = {};
  
  // Rate limiter instance
  final rateLimiter = RateLimiter();

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

    // Apply Rate Limiting
    final ip = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final path = request.uri.path;
    final now = DateTime.now();

    if (!rateLimiter.isAllowed(ip, path, now)) {
      final retryAfter = rateLimiter.getRetryAfter(ip, path, now).inSeconds;
      request.response
        ..statusCode = 429
        ..headers.contentType = ContentType.json
        ..headers.add('Retry-After', retryAfter.toString())
        ..write(jsonEncode({
          'error': 'Too Many Requests',
          'message': 'Rate limit exceeded. Please try again in $retryAfter seconds.',
          'retry_after_seconds': retryAfter
        }))
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
            // Run the retail assistant flow with context
            final userId = data['userId']?.toString() ?? 'web-user';
            final result = await retailAssistantFlow(input, context: {'userIdentifier': userId});
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
        // ─── SMART CHAT ENDPOINT ────────────────────────────────────────
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

      } else if (request.method == 'POST' && request.uri.path == '/api/transcribe') {
        // ─── WHISPER TRANSCRIPTION ENDPOINT ───────────────────────────
        try {
          final bytes = await request.fold<List<int>>([], (p, e) => p..addAll(e));
          if (bytes.isEmpty) {
            request.response..statusCode = 400..write('No audio data received')..close();
            return;
          }

          final groqKey = getEnv('GROQ_API_KEY');
          if (groqKey == null || groqKey.isEmpty) {
            request.response..statusCode = 500..write('GROQ_API_KEY not configured')..close();
            return;
          }

          print('🎙️ Transcribing audio (${bytes.length} bytes)...');

          final groqReq = http.MultipartRequest(
            'POST', 
            Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions')
          );
          groqReq.headers['Authorization'] = 'Bearer $groqKey';
          
          // Determine mime type or default to m4a
          final mimeType = lookupMimeType('audio.m4a', headerBytes: bytes.take(10).toList()) ?? 'audio/m4a';
          final mediaType = MediaType.parse(mimeType);

          groqReq.files.add(http.MultipartFile.fromBytes(
            'file', 
            bytes, 
            filename: 'audio.${mediaType.subtype}',
            contentType: mediaType,
          ));
          groqReq.fields['model'] = 'whisper-large-v3';

          final streamedResponse = await groqReq.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);
            final text = result['text'] as String? ?? '';
            print('✅ Transcribed: "$text"');
            
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'text': text}))
              ..close();
          } else {
            print('❌ Groq Transcription Error: ${response.body}');
            request.response
              ..statusCode = response.statusCode
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': 'Transcription failed', 'details': response.body}))
              ..close();
          }
        } catch (e) {
          print('❌ Server Error during transcription: $e');
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
      } else if (request.method == 'POST' && request.uri.path == '/api/approve-batch') {
        // ─── APPROVE PRODUCT BATCH ───────────────────────────────────────
        var body = await utf8.decodeStream(request);
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final batchId = data['batchId'] as String;
          final reviewedBy = data['userId'] ?? 'web-user';
          
          final result = await approveProductBatch(batchId: batchId, reviewedBy: reviewedBy);
          
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(result))
            ..close();
        } catch (e) {
          request.response..statusCode = 500..write(e.toString())..close();
        }
      } else if (request.method == 'GET' && request.uri.path == '/api/get-batch') {
        // ─── GET BATCH DETAILS ───────────────────────────────────────────
        final batchId = request.uri.queryParameters['batchId'];
        if (batchId == null) {
          request.response..statusCode = 400..close();
          return;
        }
        final batch = await supabase.from('draft_product_batches').select().eq('id', batchId).maybeSingle();
        request.response
          ..statusCode = batch != null ? 200 : 404
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(batch))
          ..close();
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
// Web chat session handler.

const String _webSystemPrompt =
  "You are Dukan Sathi Pro — the AI brain of a smart retail shop management system built for Indian small business owners.\n\n"

  "## YOUR IDENTITY\n"
  "- Professional, concise assistant for shop owners in India\n"
  "- Respond in the same language the user writes in (Hindi or English)\n"
  "- NEVER hallucinate numbers, inventory, or customer data\n"
  "- Do NOT narrate your actions (never say 'I am checking...' — just give results)\n\n"

  "## GOLDEN RULE\n"
  "ALWAYS call a tool to answer factual questions. NEVER generate financial numbers, stock counts, or customer balances from memory.\n\n"

  "## YOUR TOOLS — USE THEM PRECISELY\n"
  "1. checkInventory(productName) → Check stock & price of a specific product\n"
  "2. browseCatalogTool(category?) → List all products, optionally filtered by category\n"
  "3. createDraftInvoice(requestedItems, customerName?, paymentStatus?) → Create a GST invoice draft — REQUIRES HUMAN APPROVAL before finalizing\n"
  "4. proposeProducts(products[]) → Add new products to inventory — REQUIRES HUMAN APPROVAL\n"
  "5. requestProductDeletion(productName) → Delete a product — REQUIRES HUMAN APPROVAL\n"
  "6. businessInsightsTool(period?) → Revenue, profit, orders analytics. Default period='all_time'. Use period='today' when user says 'today'\n"
  "7. logExpense(description, amount, category?) → Log a shop expense immediately. Default category='General'\n"
  "8. getExpenses(category?) → Show expense report, optionally filtered by category\n"
  "9. checkCustomerDue(customerName) → Check a specific customer's outstanding balance\n"
  "10. listCustomersDue() → Show all customers with pending dues\n"
  "11. recordPayment(customerName, amount, paymentMethod?) → Record a customer payment\n"
  "12. invoiceLookup(invoiceNumber?, customerName?, paymentStatus?) → Find past invoices by number, customer, or status\n"
  "13. getWeather(location?) → Get current weather. Default to shop's city if not specified\n\n"

  "## TOOL SELECTION RULES (follow strictly)\n"
  "- 'make a bill / create invoice / bill karo' → createDraftInvoice\n"
  "- 'add product / naya item / add item / new stock' → proposeProducts\n"
  "- 'delete / remove product' → requestProductDeletion\n"
  "- 'revenue / sales / profit / kitna kamaya / orders / analytics' → businessInsightsTool\n"
  "- 'show products / catalog / kya hai hamare paas' → browseCatalogTool\n"
  "- '[product name] kitna hai / price / stock' → checkInventory\n"
  "- 'who owes me / all dues / sabka due' → listCustomersDue\n"
  "- '[customer] ka due / balance / owes' → checkCustomerDue\n"
  "- '[customer] ne pay kiya / paid / payment liya' → recordPayment\n"
  "- 'log expense / I spent / rent diya / salary / I paid' → logExpense\n"
  "- 'show expenses / mera kharcha' → getExpenses\n"
  "- 'find invoice / invoice dhundho / search invoice' → invoiceLookup\n"
  "- 'weather / mausam' → getWeather\n\n"

  "## RESPONSE FORMAT\n"
  "- Keep responses SHORT (2-3 sentences max for confirmations)\n"
  "- Always show currency as ₹ for Indian Rupees\n"
  "- For draft/approval actions: confirm what was created and say 'pending human approval'\n"
  "- For errors: explain clearly what went wrong and suggest a fix\n"
  "- Always include Approval/Batch IDs when returning draft results\n\n"

  "## CONTEXT (injected at runtime)\n"
  "- All monetary values are in Indian Rupees (INR)\n"
  "- Do NOT ask for Shop ID or User ID — they are already in your context\n"
  "- DEFAULT analytics period to 'all_time' unless user specifies 'today', 'this week', or 'this month'";

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

  // ─── INTENT DETECTION ──────────────────────────────────────────────────
  bool _isTimeIntent(String n) => n.contains('what time') || n.contains('current time') || n.contains('time now');
  bool _isDateIntent(String n) => n.contains('what is the date') || n.contains('today\'s date') || n.contains('current date') || n.contains('what day');
  bool _isCatalogIntent(String n) => n.contains('what item') || n.contains('what items') || n.contains('catalog') || n.contains('catelog') || n.contains('list product') ||
      n.contains('show product') || n.contains('show item') || n.contains('what do you have') || n.contains('what do we have') ||
      n.contains('items do we have') || n.contains('items do you have') || n.contains('our product') || n.contains('our inventory') ||
      n.contains('show inventory') || n.contains('view product') || n.contains('what do you sell') || n.contains('what do we sell') ||
      n.contains('browse') || n.contains('product list') || n.contains('item list') || n.contains('all products') || n.contains('all items');
  bool _isAddProductIntent(String n) => n.contains('add product') || n.contains('add a product') || n.contains('add a new product') || 
      n.contains('add item') || n.contains('add a new item') || n.contains('new product') ||
      n.contains('new item') || n.contains('create product') || n.contains('add service') ||
      n.contains('add these') || n.contains('bulk add') || n.contains('upload');
  bool _isInventoryIntent(String n) => n.contains('stock') || n.contains('inventory') || n.contains('price') || n.contains('how many') || n.contains('quantity');
  bool _isBillingIntent(String n) => n.contains('bill') || n.contains('invoice') || n.contains('draft');
  bool _isAnalyticsIntent(String n) => n.contains('revenue') || n.contains('sales') || n.contains('sale') || n.contains('analytics') || n.contains('insight') ||
      n.contains('profit') || n.contains('earnings') || n.contains('orders') || n.contains('total sales') || n.contains('how much money');
  bool _isExpenseIntent(String n) => n.contains('expense') || n.contains('spent') || n.contains('bill paid') || n.contains('cost') || n.contains('party') || n.contains('tea') || n.contains('rent') || n.contains('salary');

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
    final pattern = RegExp(r'(\d+)\s*x?\s+([a-z0-9][a-z0-9\s\-()\/]*?)(?=\s*(?:and|with|plus|,|;|\.|$))', caseSensitive: false);
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

  List<Map<String, dynamic>> _parseAddProductRequest(String input) {
    final text = input.toLowerCase().trim();
    // Example: "Add product: Det Soap, price 48, category General, stock 150, gst 18%"
    // We look for name, price, category, stock/quantity, gst
    
    final products = <Map<String, dynamic>>[];
    
    // Split by newlines or list markers if it looks like a list
    final lines = text.split(RegExp(r'\n|(?=\-)'));
    
    for (var line in lines) {
      String oldLine;
      do {
        oldLine = line;
        line = line.replaceAll(RegExp(r'^\s*[\-\*•]\s*|^(add|create|new)\s+(a\s+)?(new\s+)?(product|item|service|stock|inventory)\s*[:\-]?\s*|^(or product|or item|or)\s*', caseSensitive: false), '').trim();
      } while (line != oldLine);
      
      if (line.isEmpty) continue;
      
      // Try to parse key-value pairs or delimited format
      final product = <String, dynamic>{};
      
      // Check for delimited format: "Name | Price | Category | Stock"
      if (line.contains('|')) {
        final parts = line.split('|').map((p) => p.trim()).toList();
        if (parts.isNotEmpty) product['name'] = parts[0];
        if (parts.length > 1) product['price'] = double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        if (parts.length > 2) product['category'] = parts[2];
        if (parts.length > 3) product['stock_quantity'] = int.tryParse(parts[3].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      } else {
        // Try to find Name
        final nameMatch = RegExp(r'^([^,:]+)').firstMatch(line);
        if (nameMatch != null) product['name'] = nameMatch.group(1)!.trim();
        
        // Find Price
        final priceMatch = RegExp(r'(?:price|at|rs\.?|₹)\s*[:\-]?\s*(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(line);
        if (priceMatch != null) product['price'] = double.tryParse(priceMatch.group(1)!);
        
        // Find Category
        final catMatch = RegExp(r'category\s*[:\-]?\s*([a-z0-9\s]+)', caseSensitive: false).firstMatch(line);
        if (catMatch != null) product['category'] = catMatch.group(1)!.trim();
        
        // Find Stock
        final stockMatch = RegExp(r'(?:stock|qty|quantity)\s*[:\-]?\s*(\d+)', caseSensitive: false).firstMatch(line);
        if (stockMatch != null) product['stock_quantity'] = int.tryParse(stockMatch.group(1)!);
        
        // Find GST
        final gstMatch = RegExp(r'gst\s*[:\-]?\s*(\d+)', caseSensitive: false).firstMatch(line);
        if (gstMatch != null) product['gst_rate'] = double.tryParse(gstMatch.group(1)!);
      }
      
      if (product.containsKey('name') && product['name']!.toString().isNotEmpty) {
        // Defaults
        product['price'] ??= 0.0;
        product['category'] ??= 'General';
        product['stock_quantity'] ??= 0;
        products.add(product);
      }
    }
    
    return products;
  }

  // ─── MAIN MESSAGE HANDLER ─────────────────────────────────────────────
  Future<Map<String, dynamic>> processMessage(String input, {String? shopId, String? userId}) async {
    if (shopId != null) _currentShopId = shopId;
    if (userId != null) _currentUserId = userId;

    if (_currentShopId == null) {
      return {'text': '⚠️ Shop context not found. Please ensure you are logged in.'};
    }

    final n = input.toLowerCase().trim();

    // Fast-path: time/date queries don't need AI
    if (_isTimeIntent(n)) {
      final now = _nowIst();
      final text = 'The current time is ${_fmtTime(now)} IST.';
      _addToHistory(input, text);
      return {'text': text};
    }
    if (_isDateIntent(n)) {
      final now = _nowIst();
      final text = "Today's date is ${_fmtDate(now)} IST.";
      _addToHistory(input, text);
      return {'text': text};
    }

    // All other intents → let the AI pick the right tool
    _history.add(Message(role: Role.user, content: [TextPart(text: input)]));

    try {
      final response = await ai.generate(
        model: appModel(),
        messages: [
          Message(role: Role.system, content: [
            TextPart(text: '$_webSystemPrompt\n\nCurrent IST: ${_fmtDate(_nowIst())} ${_fmtTime(_nowIst())}'),
          ]),
          ..._history,
        ],
        // Pass ALL tools so the AI can pick the right one for any query
        toolNames: [
          'checkInventory',
          'browseCatalogTool',
          'createDraftInvoice',
          'proposeProducts',
          'requestProductDeletion',
          'businessInsightsTool',
          'logExpense',
          'getExpenses',
          'checkCustomerDue',
          'listCustomersDue',
          'recordPayment',
          'invoiceLookup',
          'getWeather',
          'setReminder',
        ],
        context: {
          'userIdentifier': userIdentifier,
          'shopId': _currentShopId,
        },
      );

      // Log tool calls for observability and parse executed cards
      Map<String, dynamic>? executedCard;
      for (final msg in response.messages) {
        for (final part in msg.content) {
          if (part is ToolRequestPart) {
            print('[AI Tool Call] ${part.toolRequest.name} | Input: ${part.toolRequest.input}');
          }
          if (part is ToolResponsePart) {
            print('[AI Tool Response] ${part.toolResponse.name} | Output: ${part.toolResponse.output}');
            final name = part.toolResponse.name;
            final output = part.toolResponse.output;
            if (output != null) {
              if (name == 'businessInsightsTool') {
                executedCard = {
                  'type': 'analytics_summary',
                  'data': output,
                };
              } else if (name == 'listCustomersDue') {
                executedCard = {
                  'type': 'customer_dues_list',
                  'data': output,
                };
              } else if (name == 'checkCustomerDue') {
                executedCard = {
                  'type': 'customer_due_detail',
                  'data': output,
                };
              } else if (name == 'getExpenses') {
                executedCard = {
                  'type': 'expense_report',
                  'data': output,
                };
              } else if (name == 'invoiceLookup') {
                executedCard = {
                  'type': 'invoice_lookup',
                  'data': output,
                };
              } else if (name == 'browseCatalogTool') {
                executedCard = {
                  'type': 'product_catalog',
                  'data': output,
                };
              } else if (name == 'recordPayment') {
                executedCard = {
                  'type': 'payment_confirmation',
                  'data': output,
                };
              } else if (name == 'createDraftInvoice') {
                executedCard = {
                  'type': 'invoice',
                  'draft': output,
                };
              } else if (name == 'proposeProducts') {
                executedCard = {
                  'type': 'batch',
                  'products': output['products'] ?? output['proposed_products'] ?? [],
                  'batchId': output['batchId'],
                  'status': 'PENDING',
                };
              }
            }
          }
        }
      }

      final reply = response.text.trim();
      _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
      return {
        'text': reply,
        if (executedCard != null) 'card': executedCard,
      };
    } catch (e) {
      print('[processMessage] Error: $e');
      return {'text': 'Sorry, something went wrong: ${e.toString().split('\n').first}'};
    }
  }

  void _addToHistory(String input, String reply) {
    _history.add(Message(role: Role.user, content: [TextPart(text: input)]));
    _history.add(Message(role: Role.model, content: [TextPart(text: reply)]));
  }
}

