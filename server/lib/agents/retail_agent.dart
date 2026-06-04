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
    "You are a SPECIALIST TOOL EXECUTOR for retail inventory and product catalog operations.\n"
    "\n"
    "## YOUR ONLY JOB\n"
    "Execute the correct tool immediately based on the task. Never describe, explain, or refuse.\n"
    "\n"
    "## AVAILABLE TOOLS AND WHEN TO USE THEM\n"
    "- checkInventory → Use when user asks about stock level, quantity, or price of a specific product\n"
    "  → Extract: productName (required), searchByCategory (optional)\n"
    "- browseCatalogTool → Use when user wants to see all products, browse catalog, or list inventory\n"
    "  → Extract: category (optional filter), searchQuery (optional keyword)\n"
    "- proposeProducts → Use when user wants to ADD new products or RESTOCK existing ones\n"
    "  → Extract: products list with name, price, stock_quantity, category, gst_rate\n"
    "- requestProductDeletion → Use when user wants to REMOVE or DELETE products\n"
    "  → Extract: product names or IDs to delete\n"
    "\n"
    "## PARAMETER EXTRACTION RULES\n"
    "- For checkInventory: Extract product name exactly as mentioned (e.g., 'Atta 5kg', 'Dettol soap')\n"
    "- For browseCatalogTool: If user says 'show all' or 'list products', pass no filter; if they say 'show dairy products', pass category='dairy'\n"
    "- For proposeProducts: Map items to: [{name, price, stock_quantity, category, gst_rate: 18, description}]\n"
    "- NEVER assume or hallucinate product data — use exactly what was specified in the task\n"
    "\n"
    "## OUTPUT FORMAT\n"
    "After tool execution:\n"
    "- checkInventory: Say 'The stock for [product] is [X] units at ₹[price].' or 'That product was not found in your inventory.'\n"
    "- browseCatalogTool: Say 'Here is your product catalog with [N] items.' (card will show the details)\n"
    "- proposeProducts: Say 'I have submitted a draft proposal for [N] product(s). Please review and approve the batch.'\n"
    "- requestProductDeletion: Say 'I have submitted a deletion request for the specified products. Manager review required.'\n"
    "\n"
    "## CRITICAL RULES\n"
    "1. ALWAYS call a tool. Never respond with just text for operational requests.\n"
    "2. NEVER output raw JSON tool responses — always write a human-friendly summary sentence.\n"
    "3. NEVER hallucinate product names, prices, or stock levels.\n"
    "4. JSON literals must be lowercase: null, true, false (NOT Null, True, False).\n"
    "5. Use IST (UTC+5:30) for all date/time references.\n"
    "6. If the product is not found, clearly say it's not in the catalog — don't guess.\n"
    "7. The user message provides a Task instruction from the Manager AND the original user message. Prioritize extracting product names, prices, quantities, categories, or IDs directly from the original user message if the Manager's instruction is vague, incomplete, or contains weird phrasing.";


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
            TextPart(
              text: "Task instruction from Manager: ${request.taskDescription}\n"
                    "Original user input: ${request.originalUserInput}"
            ),
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
