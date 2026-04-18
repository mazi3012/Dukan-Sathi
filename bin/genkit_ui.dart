import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';

Future<void> main(List<String> arguments) async {
  // Initialize all tools and flows
  initializeBackend();
  
  final port = int.tryParse(Platform.environment['PORT'] ?? '4000') ?? 4000;
  final server = await HttpServer.bind('localhost', port);
  
  print('');
  print('🚀 Genkit UI Dashboard');
  print('');
  print('✅ Open in your browser:');
  print('   http://localhost:$port');
  print('');
  print('📊 Dashboard shows:');
  print('   • Models: Vertex AI (gemini-2.5-flash)');
  print('   • Flows: retailAssistantFlow');
  print('   • Tools: checkInventory, createDraftInvoice');
  print('   • Trace history');
  print('');
  print('Press Ctrl+C to stop.');
  print('');
  
  server.listen((HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/') {
        // Serve the HTML UI
        final html = getGenkitHTML();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(html)
          ..close();
      } else if (request.method == 'GET' && request.uri.path == '/api/listActions') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'actions': [
              {
                'name': 'retailAssistantFlow',
                'key': '/flow/retailAssistantFlow',
                'description': 'Dukan Sathi retail assistant',
              },
            ],
          }))
          ..close();
      } else if (request.method == 'POST' && request.uri.path == '/api/runAction') {
        var body = await utf8.decodeStream(request);
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final input = data['input'] as String?;
          
          if (input != null) {
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
              ..write(jsonEncode({'error': 'Input required'}))
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
          ..write('Not Found')
          ..close();
      }
    } catch (e) {
      request.response
        ..statusCode = 500
        ..write('Error')
        ..close();
    }
  });
  
  final signal = ProcessSignal.sigterm;
  signal.watch().listen((_) {
    print('\nShutting down...');
    server.close();
    exit(0);
  });
}

String getGenkitHTML() {
  return '''<!DOCTYPE html>
<html>
<head>
    <title>Genkit - Dukan Sathi</title>
    <style>
        body { 
            font-family: sans-serif; 
            background: #0f172a; 
            color: #e2e8f0;
            margin: 0;
            padding: 20px;
        }
        .header {
            background: #1e293b;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #334155;
        }
        .container {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background: #1e293b;
            border: 1px solid #334155;
            padding: 20px;
            border-radius: 8px;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            margin-right: 8px;
            margin-bottom: 8px;
        }
        .model-badge { background: #0f766e; color: #a7f3d0; }
        .tool-badge { background: #7c2d12; color: #fed7aa; }
        .flow-badge { background: #3730a3; color: #c7d2fe; }
        .executor {
            background: #1e293b;
            border: 1px solid #334155;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .executor h3 { margin-top: 0; }
        input[type="text"] {
            width: 70%;
            padding: 10px;
            background: #0f172a;
            border: 1px solid #334155;
            color: #e2e8f0;
            border-radius: 4px;
        }
        button {
            padding: 10px 20px;
            background: #3b82f6;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-weight: bold;
        }
        button:hover { background: #2563eb; }
        .result {
            background: #0f172a;
            border: 1px solid #334155;
            padding: 15px;
            border-radius: 4px;
            margin-top: 15px;
            font-family: monospace;
            font-size: 13px;
            color: #a7f3d0;
            white-space: pre-wrap;
            word-wrap: break-word;
            max-height: 300px;
            overflow-y: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: #1e293b;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #334155;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #334155;
        }
        th { background: #0f172a; font-weight: 600; }
        .success { color: #86efac; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧬 Genkit AI</h1>
        <p>Dukan Sathi Pro - Run, test & debug your AI flows</p>
    </div>
    
    <div class="container">
        <div class="card">
            <h3>Models (1)</h3>
            <div class="badge model-badge">vertex</div>
            gemini-2.5-flash
        </div>
        <div class="card">
            <h3>Flows (1)</h3>
            <div class="badge flow-badge">flow</div>
            retailAssistantFlow
        </div>
        <div class="card">
            <h3>Tools (2)</h3>
            <div class="badge tool-badge">tool</div> checkInventory<br/>
            <div class="badge tool-badge">tool</div> createDraftInvoice
        </div>
    </div>
    
    <div class="executor">
        <h3>Run Flow: retailAssistantFlow</h3>
        <input type="text" id="input" placeholder="Enter your message..." />
        <button onclick="run()">Execute</button>
        <div id="result"></div>
    </div>
    
    <div class="card">
        <h3>Trace History</h3>
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Time</th>
                </tr>
            </thead>
            <tbody id="traces">
                <tr><td colspan="4">No traces yet</td></tr>
            </tbody>
        </table>
    </div>
    
    <script>
        async function run() {
            const input = document.getElementById('input').value;
            if (!input.trim()) { alert('Enter message'); return; }
            
            const result = document.getElementById('result');
            result.innerHTML = '<div class="result">Running...</div>';
            
            try {
                const res = await fetch('/api/runAction', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ key: '/flow/retailAssistantFlow', input: input })
                });
                const data = await res.json();
                
                if (res.ok) {
                    result.innerHTML = '<div class="result">Result:\\n' + data.result + '\\n\\nStatus: SUCCESS</div>';
                    addTrace('retailAssistantFlow', 'flow', 'success');
                } else {
                    result.innerHTML = '<div class="result">Error: ' + (data.error || 'Unknown') + '</div>';
                }
            } catch (e) {
                result.innerHTML = '<div class="result">Error: ' + e.message + '</div>';
            }
        }
        
        function addTrace(name, type, status) {
            const tbody = document.getElementById('traces');
            const row = tbody.querySelector('td[colspan]');
            if (row) row.parentElement.remove();
            
            const tr = document.createElement('tr');
            tr.innerHTML = '<td>' + name + '</td><td>' + type + '</td><td class="success">✓ ' + status + '</td><td>' + new Date().toLocaleTimeString() + '</td>';
            tbody.insertBefore(tr, tbody.firstChild);
        }
        
        document.getElementById('input').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') run();
        });
    </script>
</body>
</html>''';
}
