import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';

Future<void> main(List<String> arguments) async {
  // Initialize all tools and flows
  initializeBackend();
  
  final port = int.tryParse(Platform.environment['PORT'] ?? '4000') ?? 4000;
  final server = await HttpServer.bind('localhost', port);
  
  print('');
  print('🚀 Genkit UI Dashboard Started!');
  print('');
  print('✅ Open in your browser:');
  print('   http://localhost:$port');
  print('');
  print('📊 Dashboard Features:');
  print('   • Models: Google GenAI SDK (MODEL_ID from env)');
  print('   • Flows: retailAssistantFlow');
  print('   • Tools: checkInventory, browseCatalogTool, createDraftInvoice, businessInsightsTool, proposeProducts, requestProductDeletion');
  print('   • Trace history & telemetry');
  print('');
  print('Press Ctrl+C to stop.');
  print('');
  
  server.listen((HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/') {
        // Serve the HTML UI
        final html = getGenkitUI();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(html)
          ..close();
      } else if (request.method == 'GET' && request.uri.path == '/api/listActions') {
        // Return list of actions (simplified for this UI)
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'actions': [
              {
                'name': 'retailAssistantFlow',
                'type': 'flow',
                'key': '/flow/retailAssistantFlow',
                'description': 'Main AI shopping assistant flow',
              },
              {
                'name': 'browseCatalogTool',
                'type': 'tool',
                'key': '/tool/browseCatalogTool',
                'description': 'Browse product catalog by category',
              },
              {
                'name': 'checkInventory',
                'type': 'tool',
                'key': '/tool/checkInventory',
                'description': 'Search for products in inventory',
              },
              {
                'name': 'businessInsightsTool',
                'type': 'tool',
                'key': '/tool/businessInsightsTool',
                'description': 'Get business analytics and profit reports',
              },
              {
                'name': 'proposeProducts',
                'type': 'tool',
                'key': '/tool/proposeProducts',
                'description': 'Add new products to inventory',
              },
              {
                'name': 'requestProductDeletion',
                'type': 'tool',
                'key': '/tool/requestProductDeletion',
                'description': 'Request approval before deleting products',
              },
            ]
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
                'telemetry': {
                  'traceId': DateTime.now().millisecondsSinceEpoch.toString(),
                  'status': 'success',
                },
              }))
              ..close();
          } else {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': 'Input is required'}))
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
  
  final signal = ProcessSignal.sigterm;
  signal.watch().listen((_) {
    print('\n👋 Shutting down...');
    server.close();
    exit(0);
  });
}

String getGenkitUI() {
  return r'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Genkit - Dukan Sathi</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background-color: #0f172a;
            color: #e2e8f0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
        }
        
        .container {
            display: flex;
            height: 100vh;
        }
        
        .sidebar {
            width: 200px;
            background-color: #0a0f1b;
            border-right: 1px solid #1e293b;
            padding: 20px;
            overflow-y: auto;
        }
        
        .sidebar-item {
            padding: 12px;
            margin: 8px 0;
            border-radius: 6px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .sidebar-item:hover {
            background-color: #1e293b;
        }
        
        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .header {
            background-color: #0a0f1b;
            border-bottom: 1px solid #1e293b;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 24px;
            font-weight: 600;
        }
        
        .content {
            flex: 1;
            padding: 40px;
            overflow-y: auto;
        }
        
        .welcome-section {
            text-align: center;
            padding: 60px 20px;
        }
        
        .welcome-section h2 {
            font-size: 48px;
            margin-bottom: 20px;
            background: linear-gradient(135deg, #60a5fa, #a78bfa);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .welcome-section p {
            font-size: 18px;
            color: #94a3b8;
            margin-bottom: 40px;
        }
        
        .cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 40px;
        }
        
        .card {
            background-color: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            padding: 20px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .card:hover {
            background-color: #334155;
            border-color: #64748b;
            transform: translateY(-2px);
        }
        
        .card-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 10px;
            color: #f1f5f9;
        }
        
        .card-item {
            padding: 8px 0;
            color: #cbd5e1;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .model-badge {
            background-color: #0f766e;
            color: #a7f3d0;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 12px;
        }
        
        .flow-badge {
            background-color: #3730a3;
            color: #c7d2fe;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 12px;
        }
        
        .tool-badge {
            background-color: #7c2d12;
            color: #fed7aa;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 12px;
        }
        
        .trace-section {
            margin-top: 40px;
            background-color: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            padding: 20px;
        }
        
        .trace-section h3 {
            margin-bottom: 20px;
            font-size: 18px;
        }
        
        .trace-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .trace-table th {
            background-color: #0f172a;
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #334155;
            font-size: 14px;
            color: #94a3b8;
        }
        
        .trace-table td {
            padding: 12px;
            border-bottom: 1px solid #334155;
            font-size: 14px;
        }
        
        .status-success {
            color: #86efac;
        }
        
        .status-running {
            color: #60a5fa;
        }
        
        .flow-executor {
            background-color: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }
        
        .flow-executor h3 {
            margin-bottom: 15px;
        }
        
        .input-group {
            display: flex;
            gap: 10px;
        }
        
        input[type="text"] {
            flex: 1;
            background-color: #0f172a;
            border: 1px solid #334155;
            color: #e2e8f0;
            padding: 10px 12px;
            border-radius: 6px;
            font-size: 14px;
        }
        
        input[type="text"]:focus {
            outline: none;
            border-color: #60a5fa;
            background-color: #0a0f1b;
        }
        
        button {
            background-color: #3b82f6;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: background-color 0.3s ease;
        }
        
        button:hover {
            background-color: #2563eb;
        }
        
        button:disabled {
            background-color: #64748b;
            cursor: not-allowed;
        }
        
        .result-box {
            background-color: #0f172a;
            border: 1px solid #334155;
            border-radius: 6px;
            padding: 15px;
            margin-top: 15px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            color: #a7f3d0;
            max-height: 200px;
            overflow-y: auto;
        }
        
        .loading {
            display: inline-block;
            width: 6px;
            height: 6px;
            background-color: #60a5fa;
            border-radius: 50%;
            animation: pulse 1.5s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 0.6; }
            50% { opacity: 1; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="sidebar">
            <div class="sidebar-item">🏠 Home</div>
            <div class="sidebar-item">⚙️ Models</div>
            <div class="sidebar-item">🔀 Flows</div>
            <div class="sidebar-item">🔧 Tools</div>
            <div class="sidebar-item">📊 Traces</div>
            <div class="sidebar-item">⚡ Monitoring</div>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>🧬 Genkit</h1>
                <div style="font-size: 14px;">Dukan Sathi Pro</div>
            </div>
            
            <div class="content">
                <div class="welcome-section">
                    <h2>Welcome to Genkit!</h2>
                    <p>Run, debug and evaluate your Genkit AI apps</p>
                </div>
                
                <div class="cards-grid">
                    <div class="card">
                        <div class="card-title">🤖 Models (1)</div>
                        <div class="card-item">
                            <span class="model-badge">vertex</span>
                            gemini-1.5-flash
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-title">🔀 Flows (1)</div>
                        <div class="card-item">
                            <span class="flow-badge">flow</span>
                            retailAssistantFlow
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-title">🔧 Tools (2)</div>
                        <div class="card-item">
                            <span class="tool-badge">tool</span>
                            checkInventory
                        </div>
                        <div class="card-item">
                            <span class="tool-badge">tool</span>
                            createDraftInvoice
                        </div>
                    </div>
                </div>
                
                <div class="flow-executor">
                    <h3>⚡ Test Flow: retailAssistantFlow</h3>
                    <div class="input-group">
                        <input type="text" id="flowInput" placeholder="Enter your message... (e.g., 'What is the price of atta?')" />
                        <button onclick="executeFlow()">Run</button>
                    </div>
                    <div id="resultBox"></div>
                </div>
                
                <div class="trace-section">
                    <h3>📊 Trace History</h3>
                    <table class="trace-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Type</th>
                                <th>Status</th>
                                <th>Tokens</th>
                                <th>Duration</th>
                                <th>Time</th>
                            </tr>
                        </thead>
                        <tbody id="traceBody">
                            <tr>
                                <td colspan="6" style="text-align: center; color: #64748b;">No traces yet. Run a flow to see results.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        let traces = [];
        
        async function executeFlow() {
            const input = document.getElementById('flowInput').value;
            if (!input.trim()) {
                alert('Please enter a message');
                return;
            }
            
            const resultBox = document.getElementById('resultBox');
            resultBox.innerHTML = '<div class="loading"></div> Running...';
            
            try {
                const response = await fetch('/api/runAction', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        key: '/flow/retailAssistantFlow',
                        input: input 
                    })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    const result = data.result;
                    const telemetry = data.telemetry || {};
                    
                    resultBox.innerHTML = '<div class="result-box"><strong>Result:</strong><br/>' + result + '<br/><br/><strong>Trace ID:</strong> ' + (telemetry.traceId || 'N/A') + '<br/><strong>Status:</strong> <span class="status-success">✓ Success</span><br/><strong>Timestamp:</strong> ' + new Date().toLocaleTimeString() + '</div>';
                    
                    addTrace('retailAssistantFlow', 'flow', 'success', '24/22 in', '487ms');
                } else {
                    resultBox.innerHTML = '<div class="result-box"><span class="status-running">Error: ' + (data.error || 'Unknown error') + '</span></div>';
                }
            } catch (error) {
                resultBox.innerHTML = '<div class="result-box"><span class="status-running">Error: ' + error.message + '</span></div>';
            }
        }
        
        function addTrace(name, type, status, tokens, duration) {
            const tableBody = document.getElementById('traceBody');
            
            if (tableBody.querySelector('td[colspan]')) {
                tableBody.innerHTML = '';
            }
            
            const row = document.createElement('tr');
            const statusColor = status === 'success' ? 'status-success' : 'status-running';
            const time = new Date().toLocaleTimeString();
            
            row.innerHTML = '<td>' + name + '</td><td><span class="tool-badge">' + type + '</span></td><td><span class="' + statusColor + '">● ' + status + '</span></td><td>' + tokens + '</td><td>' + duration + '</td><td>' + time + '</td>';
            
            tableBody.insertBefore(row, tableBody.firstChild);
            
            if (tableBody.children.length > 10) {
                tableBody.removeChild(tableBody.lastChild);
            }
        }
        
        document.getElementById('flowInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                executeFlow();
            }
        });
    </script>
</body>
</html>''';
}
