/// Spoke A: Retail & Inventory Sub-Agent
///
/// STRICT SILENT EXECUTOR — handles catalog, stock queries, product additions, and deletions.
/// This agent wraps the existing inventory tool functions WITHOUT modifying them.

import 'package:genkit/genkit.dart';

import 'agent_contracts.dart';
import 'agent_registry.dart';
import '../runtime/genkit_runtime.dart';

class RetailAgent extends SubAgent {
  @override
  String get id => 'retail';

  @override
  String get displayName => 'Retail & Inventory Agent';

  @override
  String get description =>
      'Handles inventory checks (stock levels, pricing), product catalog browsing, '
      'proposing new products for addition, and requesting product deletions. '
      'Use this agent when the user asks about products, stock, prices, catalog, '
      'or wants to add/remove items from their inventory.';

  @override
  List<String> get toolNames => [
    'checkInventory',
    'browseCatalogTool',
    'proposeProducts',
    'requestProductDeletion',
  ];

  /// Sub-agent system prompt: STRICT TOOL EXECUTOR, NO CONVERSATION
  static const String _systemPrompt =
    "You are a TOOL EXECUTOR for inventory and product catalog operations.\n"
    "STRICT RULES:\n"
    "1. You receive a task description. Execute the appropriate tool IMMEDIATELY.\n"
    "2. Return ONLY the tool's structured result.\n"
    "3. If parameters are missing, say exactly what is missing.\n"
    "4. NEVER generate greetings, apologies, narrative, or suggestions.\n"
    "5. NEVER hallucinate data. If a tool returns empty results, return them as-is.\n"
    "6. You have access to ONLY: checkInventory, browseCatalogTool, proposeProducts, requestProductDeletion.\n"
    "7. JSON COMPLIANCE: Use lowercase 'null', 'true', 'false'. NEVER use Python-style capitalized literals.\n"
    "8. Use India Standard Time for all date-based queries.";

  @override
  Future<AgentResponse> execute(AgentRequest request) async {
    final stopwatch = Stopwatch()..start();
    print('[RetailAgent] Executing task: "${request.taskDescription}"');

    try {
      final response = await ai.generate(
        model: appModel(),
        messages: [
          Message(role: Role.system, content: [TextPart(text: _systemPrompt)]),
          Message(role: Role.user, content: [
            TextPart(text: request.taskDescription),
          ]),
        ],
        toolNames: toolNames,
        context: {
          'userIdentifier': request.userId,
          'shopId': request.shopId,
        },
      );

      print('[RetailAgent] Completed in ${stopwatch.elapsedMilliseconds}ms');

      // Extract tool results and build response
      CardPayload? card;
      Map<String, dynamic>? lastToolResult;

      for (final msg in response.messages) {
        for (final part in msg.content) {
          if (part.isToolRequest) {
            print('[RetailAgent] Tool call: ${part.toolRequest?.name}');
          }
          if (part.isToolResponse) {
            final name = part.toolResponse?.name;
            final output = part.toolResponse?.output;
            print('[RetailAgent] Tool response: $name');
            
            if (output != null) {
              lastToolResult = output is Map<String, dynamic>
                  ? output
                  : (output is Map ? Map<String, dynamic>.from(output) : {'result': output});

              // Map tool outputs to card types
              if (name == 'browseCatalogTool') {
                card = CardPayload(type: 'product_catalog', data: {'data': output});
              } else if (name == 'proposeProducts') {
                final outputMap = lastToolResult;
                card = CardPayload(type: 'batch', data: {
                  'products': outputMap['products'] ?? outputMap['proposed_products'] ?? [],
                  'batchId': outputMap['batchId'],
                  'status': 'PENDING',
                });
              } else if (name == 'checkInventory') {
                // Inventory checks don't produce cards — just data
              }
            }
          }
        }
      }

      return AgentResponse.success(
        summary: response.text.trim(),
        toolResult: lastToolResult,
        card: card,
      );
    } catch (e) {
      print('[RetailAgent] Error: $e');
      return AgentResponse.toolFailed(e.toString());
    }
  }
}
