import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';
import 'package:dukansathi_new/services/admin_service.dart';
import 'package:dukansathi_new/core/database.dart';

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
  print('   • createDraftInvoice');
  print('');
  print('💬 Telegram Bot: @Sathiaibeta_bot');
  print('');
  print('Press Ctrl+C to stop.');
  print('');
  
  // Handle incoming HTTP requests
  server.listen((HttpRequest request) async {
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
                'tools': ['checkInventory', 'createDraftInvoice'],
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
                'key': '/flow/retailAssistantFlow',
                'description': 'Retail assistant AI flow',
                'input_schema': {'type': 'string'},
                'output_schema': {'type': 'string'},
              },
              {
                'name': 'checkInventory',
                'key': '/tool/checkInventory',
                'description': 'Check product inventory and prices',
              },
              {
                'name': 'createDraftInvoice',
                'key': '/tool/createDraftInvoice',
                'description': 'Create a draft invoice',
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
