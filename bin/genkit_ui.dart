import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';

Future<void> main(List<String> arguments) async {
    // Initialize all tools and flows. If credentials are missing, keep UI up
    // so users can still access diagnostics and setup instructions.
    var backendReady = true;
    String? backendInitError;
    try {
        initializeBackend();
    } catch (e) {
        backendReady = false;
        backendInitError = e.toString();
    }
  
  final port = int.tryParse(Platform.environment['PORT'] ?? '4000') ?? 4000;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  
  print('');
  print('🚀 Genkit UI Dashboard');
  print('');
  print('✅ Open in your browser:');
  print('   http://localhost:$port');
  print('');
  print('📊 Dashboard shows:');
    print('   • Models: $aiProvider ($modelId)');
  print('   • Flows: retailAssistantFlow');
    print('   • Tools: checkInventory, browseCatalogTool, createDraftInvoice, businessInsightsTool');
  print('   • Trace history');
  print('');
  print('Press Ctrl+C to stop.');
  print('');
  
  server.listen((HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/') {
        // Serve the HTML UI
                final html = getGenkitHTML(
                    backendReady: backendReady,
                    backendInitError: backendInitError,
                );
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
                if (!backendReady) {
                    request.response
                        ..statusCode = 503
                        ..headers.contentType = ContentType.json
                        ..write(jsonEncode({
                            'error': 'Backend not initialized. Configure MODEL_ID and GOOGLE_API_KEY (or GEMINI_API_KEY), then restart server.',
                            'details': backendInitError,
                        }))
                        ..close();
                    return;
                }

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

String getGenkitHTML({
    required bool backendReady,
    String? backendInitError,
}) {
    final banner = backendReady
            ? ''
            : '''
        <div style="background:#7f1d1d;border:1px solid #b91c1c;color:#fecaca;padding:12px;border-radius:8px;margin-bottom:20px;">
            <strong>Backend Unavailable:</strong> Configure <code>MODEL_ID</code> and <code>GOOGLE_API_KEY</code> (or <code>GEMINI_API_KEY</code>), then restart.
            <div style="margin-top:8px;font-size:12px;opacity:.9;">${backendInitError ?? 'Initialization failed.'}</div>
        </div>
    ''';

  return '''<!DOCTYPE html>
<html>
<head>
    <title>Genkit Control Center - Dukan Sathi</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap');

        :root {
            --bg: #f6f4ed;
            --panel: #fffdf7;
            --ink: #1d2730;
            --muted: #5f6b75;
            --line: #d9d2c3;
            --brand: #0d9488;
            --brand-2: #f97316;
            --ok-bg: #ddf7e8;
            --ok-ink: #106b3f;
            --err-bg: #ffe4e1;
            --err-ink: #9f1239;
            --soft-shadow: 0 10px 30px rgba(17, 24, 39, 0.08);
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            color: var(--ink);
            font-family: 'IBM Plex Sans', sans-serif;
            background:
                radial-gradient(circle at 15% 10%, #ffd7a7 0%, transparent 28%),
                radial-gradient(circle at 85% 20%, #baf2ea 0%, transparent 30%),
                linear-gradient(180deg, #fffef9 0%, var(--bg) 100%);
            min-height: 100vh;
        }

        .shell {
            max-width: 1200px;
            margin: 0 auto;
            padding: 28px 18px 36px;
        }

        .hero {
            background: linear-gradient(135deg, #0f766e 0%, #115e59 50%, #7c2d12 100%);
            color: #fefce8;
            border-radius: 20px;
            padding: 24px;
            box-shadow: var(--soft-shadow);
        }

        .hero-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .hero h1 {
            margin: 0;
            font-family: 'Space Grotesk', sans-serif;
            font-size: 1.9rem;
            letter-spacing: 0.4px;
        }

        .hero p {
            margin: 10px 0 0;
            opacity: 0.95;
        }

        .status-pill {
            border: 1px solid rgba(254, 252, 232, 0.35);
            background: rgba(254, 252, 232, 0.16);
            border-radius: 999px;
            padding: 7px 12px;
            font-size: 0.9rem;
            font-weight: 600;
        }

        .grid {
            margin-top: 18px;
            display: grid;
            gap: 14px;
            grid-template-columns: repeat(12, 1fr);
        }

        .panel {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 14px;
            box-shadow: var(--soft-shadow);
            padding: 16px;
        }

        .panel h3 {
            margin: 0 0 10px;
            font-family: 'Space Grotesk', sans-serif;
            font-size: 1.05rem;
        }

        .span-4 { grid-column: span 4; }
        .span-5 { grid-column: span 5; }
        .span-7 { grid-column: span 7; }
        .span-12 { grid-column: span 12; }

        .kv {
            display: grid;
            grid-template-columns: 140px 1fr;
            font-size: 0.94rem;
            gap: 6px 10px;
        }

        .k { color: var(--muted); }
        .v { font-weight: 600; word-break: break-word; }

        .chips {
            display: flex;
            flex-wrap: wrap;
            gap: 7px;
        }

        .chip {
            font-size: 0.84rem;
            border-radius: 999px;
            padding: 6px 10px;
            border: 1px solid var(--line);
            background: #f9f7f0;
            font-weight: 600;
        }

        .chip.brand { background: #dbf5f2; border-color: #8cd8d0; color: #0f766e; }
        .chip.orange { background: #ffedd5; border-color: #fdba74; color: #9a3412; }
        .chip.blue { background: #dbeafe; border-color: #93c5fd; color: #1d4ed8; }

        .prompt-area {
            display: grid;
            gap: 10px;
        }

        textarea {
            width: 100%;
            min-height: 118px;
            resize: vertical;
            border-radius: 12px;
            border: 1px solid var(--line);
            padding: 12px;
            font-size: 0.96rem;
            font-family: 'IBM Plex Sans', sans-serif;
            background: #fff;
            color: var(--ink);
        }

        .row {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        button {
            border: 0;
            cursor: pointer;
            border-radius: 10px;
            font-weight: 700;
            font-family: 'Space Grotesk', sans-serif;
            letter-spacing: 0.2px;
            transition: transform 120ms ease, opacity 120ms ease;
        }

        button:hover { transform: translateY(-1px); }
        button:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }

        .btn-main {
            background: linear-gradient(135deg, var(--brand) 0%, #0f766e 100%);
            color: #ecfeff;
            padding: 10px 14px;
        }

        .btn-ghost {
            background: #fff;
            color: #0f172a;
            border: 1px solid var(--line);
            padding: 10px 14px;
        }

        .preset {
            background: #fff;
            border: 1px dashed #b8ab93;
            color: #1e293b;
            padding: 8px 10px;
            font-size: 0.83rem;
        }

        .result-box {
            border: 1px solid var(--line);
            border-radius: 12px;
            background: #fff;
            padding: 12px;
            min-height: 84px;
            max-height: 340px;
            overflow: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 0.84rem;
        }

        .meta {
            font-size: 0.82rem;
            color: var(--muted);
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        .list {
            margin: 0;
            padding-left: 18px;
            color: #35414b;
            font-size: 0.92rem;
        }

        .list li { margin: 4px 0; }

        .table-wrap { overflow: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.9rem;
        }

        th, td {
            border-bottom: 1px solid var(--line);
            text-align: left;
            padding: 9px 10px;
            vertical-align: top;
        }

        th {
            background: #f4efe4;
            color: #4f5a66;
            position: sticky;
            top: 0;
            z-index: 1;
        }

        .ok { background: var(--ok-bg); color: var(--ok-ink); border-radius: 999px; padding: 3px 8px; font-size: 0.8rem; font-weight: 700; }
        .err { background: var(--err-bg); color: var(--err-ink); border-radius: 999px; padding: 3px 8px; font-size: 0.8rem; font-weight: 700; }

        @media (max-width: 980px) {
            .span-4, .span-5, .span-7 { grid-column: span 12; }
            .kv { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="shell">
        <section class="hero">
            <div class="hero-top">
                <h1>Genkit Control Center</h1>
                <div class="status-pill">Backend: ${backendReady ? 'Ready' : 'Needs Setup'}</div>
            </div>
            <p>No-code friendly dashboard for running flows, exploring tools, and checking setup in one place.</p>
        </section>

        $banner

        <section class="grid">
            <article class="panel span-4">
                <h3>System Settings</h3>
                <div class="kv">
                    <div class="k">Provider</div><div class="v">$aiProvider</div>
                    <div class="k">Model</div><div class="v">$modelId</div>
                    <div class="k">Flow</div><div class="v">retailAssistantFlow</div>
                    <div class="k">Action API</div><div class="v">POST /api/runAction</div>
                </div>
            </article>

            <article class="panel span-4">
                <h3>Available Options</h3>
                <div class="chips" style="margin-bottom:8px;">
                    <span class="chip brand">checkInventory</span>
                    <span class="chip brand">browseCatalogTool</span>
                    <span class="chip brand">createDraftInvoice</span>
                    <span class="chip brand">businessInsightsTool</span>
                </div>
                <div class="chips">
                    <span class="chip orange">Catalog Browsing</span>
                    <span class="chip orange">Price and Stock</span>
                    <span class="chip orange">Draft Billing</span>
                    <span class="chip orange">Revenue Insights</span>
                </div>
            </article>

            <article class="panel span-4">
                <h3>No-Code Quick Guide</h3>
                <ol class="list">
                    <li>Pick a preset or write your question.</li>
                    <li>Click Run Flow to test instantly.</li>
                    <li>See output, status, and trace history below.</li>
                    <li>Use Action Explorer to inspect connected actions.</li>
                </ol>
            </article>

            <article class="panel span-7">
                <h3>Flow Playground</h3>
                <div class="prompt-area">
                    <textarea id="input" placeholder="Example: What item do you sell?"></textarea>
                    <div class="row">
                        <button class="btn-main" id="runBtn" onclick="runFlow()">Run Flow</button>
                        <button class="btn-ghost" onclick="clearPrompt()">Clear</button>
                        <button class="preset" onclick="setPrompt('What item do you sell?')">Catalog</button>
                        <button class="preset" onclick="setPrompt('What is the price of aashirvaad atta?')">Price</button>
                        <button class="preset" onclick="setPrompt('How many aashirvaad atta do we have?')">Stock</button>
                        <button class="preset" onclick="setPrompt('Show total revenue for shop_001')">Analytics</button>
                    </div>
                    <div class="meta">
                        <div>Run Key: /flow/retailAssistantFlow</div>
                        <div id="runMeta">Idle</div>
                    </div>
                    <div id="result" class="result-box">Run output will appear here.</div>
                </div>
            </article>

            <article class="panel span-5">
                <h3>Setup Checklist</h3>
                <ul class="list">
                    <li>MODEL_ID configured</li>
                    <li>GOOGLE_API_KEY or GEMINI_API_KEY configured</li>
                    <li>SUPABASE_URL and SUPABASE_ANON_KEY configured</li>
                    <li>TELEGRAM_BOT_TOKEN configured</li>
                </ul>
                <div style="margin-top:10px;" id="healthBadge">
                    ${backendReady ? '<span class="ok">Backend Healthy</span>' : '<span class="err">Backend Not Ready</span>'}
                </div>
            </article>

            <article class="panel span-6">
                <h3>Action Explorer</h3>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Key</th>
                                <th>Description</th>
                            </tr>
                        </thead>
                        <tbody id="actionsTable">
                            <tr><td colspan="3">Loading actions...</td></tr>
                        </tbody>
                    </table>
                </div>
            </article>

            <article class="panel span-6">
                <h3>Trace History</h3>
                <div class="table-wrap">
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
                            <tr><td colspan="4">No traces yet.</td></tr>
                        </tbody>
                    </table>
                </div>
            </article>
        </section>
    </div>

    <script>
        function setPrompt(text) {
            document.getElementById('input').value = text;
            document.getElementById('input').focus();
        }

        function clearPrompt() {
            document.getElementById('input').value = '';
            document.getElementById('result').textContent = 'Run output will appear here.';
            document.getElementById('runMeta').textContent = 'Idle';
        }

        async function loadActions() {
            const table = document.getElementById('actionsTable');
            try {
                const res = await fetch('/api/listActions');
                const data = await res.json();
                const actions = data.actions || [];
                if (!actions.length) {
                    table.innerHTML = '<tr><td colspan="3">No actions found.</td></tr>';
                    return;
                }

                table.innerHTML = actions.map(action => {
                    return '<tr>' +
                        '<td>' + escapeHtml(action.name || '-') + '</td>' +
                        '<td>' + escapeHtml(action.key || '-') + '</td>' +
                        '<td>' + escapeHtml(action.description || '-') + '</td>' +
                    '</tr>';
                }).join('');
            } catch (e) {
                table.innerHTML = '<tr><td colspan="3">Could not load actions: ' + escapeHtml(e.message) + '</td></tr>';
            }
        }

        async function runFlow() {
            const input = document.getElementById('input').value.trim();
            if (!input) {
                alert('Please enter a message first.');
                return;
            }

            const result = document.getElementById('result');
            const runBtn = document.getElementById('runBtn');
            const runMeta = document.getElementById('runMeta');
            const started = performance.now();
            runBtn.disabled = true;
            runMeta.textContent = 'Running...';
            result.textContent = 'Running flow...';

            try {
                const res = await fetch('/api/runAction', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ key: '/flow/retailAssistantFlow', input: input })
                });
                const data = await res.json();
                const elapsed = Math.round(performance.now() - started);

                if (res.ok) {
                    result.textContent = (data.result || '').toString();
                    runMeta.textContent = 'Completed in ' + elapsed + ' ms';
                    addTrace('retailAssistantFlow', 'flow', 'success');
                } else {
                    result.textContent = 'Error: ' + (data.error || 'Unknown error');
                    runMeta.textContent = 'Failed in ' + elapsed + ' ms';
                    addTrace('retailAssistantFlow', 'flow', 'failed');
                }
            } catch (e) {
                result.textContent = 'Error: ' + e.message;
                runMeta.textContent = 'Request failed';
                addTrace('retailAssistantFlow', 'flow', 'failed');
            } finally {
                runBtn.disabled = false;
            }
        }

        function addTrace(name, type, status) {
            const tbody = document.getElementById('traces');
            const row = tbody.querySelector('td[colspan]');
            if (row) {
                row.parentElement.remove();
            }

            const statusClass = status === 'success' ? 'ok' : 'err';
            const tr = document.createElement('tr');
            tr.innerHTML = '<td>' + escapeHtml(name) + '</td>' +
                '<td>' + escapeHtml(type) + '</td>' +
                '<td><span class="' + statusClass + '">' + escapeHtml(status) + '</span></td>' +
                '<td>' + new Date().toLocaleTimeString() + '</td>';
            tbody.insertBefore(tr, tbody.firstChild);
        }

        function escapeHtml(text) {
            return String(text)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('"', '&quot;')
                .replaceAll("'", '&#039;');
        }

        document.getElementById('input').addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
                runFlow();
            }
        });

        loadActions();
    </script>
</body>
</html>''';
}
