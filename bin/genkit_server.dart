import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';

Future<void> main(List<String> arguments) async {
  // Initialize all tools and flows
  initializeBackend();
  
  // Get port from environment or use default
  final port = int.tryParse(Platform.environment['PORT'] ?? '3100') ?? 3100;
  
  // Create a simple HTTP server for Genkit reflection API
  final server = await HttpServer.bind('localhost', port);
  
  print('');
  print('🚀 Genkit Reflection Server Started!');
  print('');
  print('✅ Server is running on port $port');
  print('');
  print('🔗 Access URLs:');
  print('   http://localhost:$port - Genkit UI');
  print('   http://localhost:$port/api/listActions - List all actions');
  print('   http://localhost:$port/api/runAction - Run an action');
  print('');
  print('🎯 Example Flows:');
  print('   • POST to /api/runAction');
  print('   • Body: {"key":"/flow/retailAssistantFlow","input":"What is the price of atta?"}');
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
        // Serve Genkit UI info
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
          }))
          ..close();
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
