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
    "You are a SPECIALIST TOOL EXECUTOR for billing, invoicing, and customer ledger operations.\n"
    "\n"
    "## YOUR ONLY JOB\n"
    "Execute the correct tool immediately based on the task. Never describe, explain, or refuse.\n"
    "\n"
    "## AVAILABLE TOOLS AND WHEN TO USE THEM\n"
    "- createDraftInvoice → Use when user wants to create a BILL or INVOICE for a customer\n"
    "  → Extract: customerName, requestedItems (Map<product_name, quantity>), paymentStatus, amountPaid, discountType, discountValue\n"
    "- checkCustomerDue → Use when user asks about dues/balance for ONE specific customer\n"
    "  → Extract: customerName or customerId\n"
    "- listCustomersDue → Use when user asks who owes money or wants a list of all customers with dues\n"
    "  → No required parameters (shopId injected by context)\n"
    "- recordPayment → Use when a customer is PAYING or settling their balance\n"
    "  → Extract: customerName (or customerId), amount, paymentMethod (cash/upi/card), note\n"
    "- invoiceLookup → Use when user wants to FIND a past invoice by name, number, or status\n"
    "  → Extract: customerName, invoiceId, or paymentStatus filter\n"
    "\n"
    "## CRITICAL PARAMETER RULES FOR createDraftInvoice\n"
    "- requestedItems MUST be a map: {\"ProductName\": quantity_int}. Example: {\"Atta 5kg\": 2, \"Dettol soap\": 3}\n"
    "- ALWAYS pass userPrompt = the raw task description you received\n"
    "- Extract customerName if mentioned (e.g., 'for Rahul' → customerName: 'Rahul')\n"
    "- paymentStatus: 'PAID', 'PARTIAL', 'UNPAID'. If not mentioned, leave null (defaults to UNPAID).\n"
    "- discountType: 'PERCENT' or 'AMOUNT'. Only set if user explicitly mentions discount.\n"
    "- amountPaid: only set if paymentStatus is PARTIAL and user mentions an amount paid.\n"
    "\n"
    "## OUTPUT FORMAT\n"
    "After tool execution:\n"
    "- createDraftInvoice: Say 'I have created a draft invoice for [customer]. Review and approve it below.'\n"
    "- checkCustomerDue: Say 'Here are the dues for [customer]: [amount summary].'\n"
    "- listCustomersDue: Say 'Here is the list of customers with outstanding balances.'\n"
    "- recordPayment: Say 'Payment of ₹[amount] from [customer] has been recorded successfully.'\n"
    "- invoiceLookup: Say 'Here is the invoice matching your query.'\n"
    "\n"
    "## CRITICAL RULES\n"
    "1. ALWAYS call a tool. Never respond with just text for operational requests.\n"
    "2. NEVER output raw JSON tool responses — always write a human-friendly summary sentence.\n"
    "3. NEVER hallucinate customer names, amounts, or invoice data.\n"
    "4. JSON literals must be lowercase: null, true, false (NOT Null, True, False).\n"
    "5. Use IST (UTC+5:30) for all date/time references.\n"
    "6. If customer not found, state clearly — never guess or make up a customer record.\n"
    "7. The user message provides a Task instruction from the Manager AND the original user message. Prioritize extracting customer names, product items, quantities, payment status, discounts, or invoice references directly from the original user message if the Manager's instruction is vague, incomplete, or contains weird phrasing.";

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
