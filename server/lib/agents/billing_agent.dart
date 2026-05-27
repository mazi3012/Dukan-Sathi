/// Spoke B: Billing & Customer Ledger Sub-Agent
///
/// STRICT SILENT EXECUTOR — handles invoice drafting, customer dues, payments, and lookups.
/// This agent wraps the existing billing/customer tool functions WITHOUT modifying them.

import 'package:genkit/genkit.dart';

import 'agent_contracts.dart';
import 'agent_registry.dart';
import '../runtime/genkit_runtime.dart';

class BillingAgent extends SubAgent {
  @override
  String get id => 'billing';

  @override
  String get displayName => 'Billing & Customer Ledger Agent';

  @override
  String get description =>
      'Handles invoice creation (drafting bills), customer due/balance checks, '
      'listing all customers with outstanding dues, recording payments, '
      'and looking up past invoices. Use this agent when the user mentions '
      'bills, invoices, customer dues, payments, balances, or outstanding amounts.';

  @override
  List<String> get toolNames => [
    'createDraftInvoice',
    'checkCustomerDue',
    'listCustomersDue',
    'recordPayment',
    'invoiceLookup',
  ];

  /// Sub-agent system prompt: STRICT TOOL EXECUTOR, NO CONVERSATION
  static const String _systemPrompt =
    "You are a TOOL EXECUTOR for billing, invoicing, and customer ledger operations.\n"
    "STRICT RULES:\n"
    "1. You receive a task description. Execute the appropriate tool IMMEDIATELY.\n"
    "2. Return ONLY the tool's structured result.\n"
    "3. If parameters are missing, say exactly what is missing.\n"
    "4. NEVER generate greetings, apologies, narrative, or suggestions.\n"
    "5. NEVER hallucinate financial data. If a tool returns empty results, return them as-is.\n"
    "6. You have access to ONLY: createDraftInvoice, checkCustomerDue, listCustomersDue, recordPayment, invoiceLookup.\n"
    "7. INVOICE RULES: If a customer name is mentioned, pass it as 'customerName'. ALWAYS pass the raw user prompt as 'userPrompt'. "
    "Parse product names and quantities into 'requestedItems' map (e.g., {'soap': 2, 'oil': 1}). "
    "Leave optional fields (customerState, discountType, discountValue, paymentStatus, amountPaid) as null unless explicitly specified.\n"
    "8. JSON COMPLIANCE: Use lowercase 'null', 'true', 'false'. NEVER use Python-style capitalized literals.\n"
    "9. Use India Standard Time for all date-based queries.";

  @override
  Future<AgentResponse> execute(AgentRequest request) async {
    final stopwatch = Stopwatch()..start();
    print('[BillingAgent] Executing task: "${request.taskDescription}"');

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

      print('[BillingAgent] Completed in ${stopwatch.elapsedMilliseconds}ms');

      // Extract tool results and build response
      CardPayload? card;
      Map<String, dynamic>? lastToolResult;

      for (final msg in response.messages) {
        for (final part in msg.content) {
          if (part.isToolRequest) {
            print('[BillingAgent] Tool call: ${part.toolRequest?.name}');
          }
          if (part.isToolResponse) {
            final name = part.toolResponse?.name;
            final output = part.toolResponse?.output;
            print('[BillingAgent] Tool response: $name');

            if (output != null) {
              lastToolResult = output is Map<String, dynamic>
                  ? output
                  : (output is Map ? Map<String, dynamic>.from(output) : {'result': output});

              // Map tool outputs to card types
              if (name == 'createDraftInvoice') {
                card = CardPayload(type: 'invoice', data: {'draft': output});
              } else if (name == 'checkCustomerDue') {
                card = CardPayload(type: 'customer_due_detail', data: {'data': output});
              } else if (name == 'listCustomersDue') {
                card = CardPayload(type: 'customer_dues_list', data: {'data': output});
              } else if (name == 'recordPayment') {
                card = CardPayload(type: 'payment_confirmation', data: {'data': output});
              } else if (name == 'invoiceLookup') {
                card = CardPayload(type: 'invoice_lookup', data: {'data': output});
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
      print('[BillingAgent] Error: $e');
      return AgentResponse.toolFailed(e.toString());
    }
  }
}
