/// Spoke C: Business Finance & Insights Sub-Agent
///
/// STRICT SILENT EXECUTOR — handles analytics, revenue reports, expense logging and tracking.
/// This agent wraps the existing analytics/expense tool functions WITHOUT modifying them.

import 'package:genkit/genkit.dart';

import 'agent_contracts.dart';
import 'agent_registry.dart';
import '../runtime/genkit_runtime.dart';

class FinanceAgent extends SubAgent {
  @override
  String get id => 'finance';

  @override
  String get displayName => 'Business Finance & Insights Agent';

  @override
  String get description =>
      'Handles business analytics (revenue, profit, sales summaries), '
      'expense logging, and expense report retrieval. Use this agent when the user '
      'asks about revenue, sales, profit, earnings, business performance, orders, '
      'expenses, spending, rent, salary, or any financial summary.';

  @override
  List<String> get toolNames => [
    'businessInsightsTool',
    'logExpense',
    'getExpenses',
  ];

  /// Sub-agent system prompt: STRICT TOOL EXECUTOR, NO CONVERSATION
  static const String _systemPrompt =
    "You are a TOOL EXECUTOR for business analytics and financial reporting.\n"
    "STRICT RULES:\n"
    "1. You receive a task description. Execute the appropriate tool IMMEDIATELY.\n"
    "2. Return ONLY the tool's structured result.\n"
    "3. If parameters are missing, say exactly what is missing.\n"
    "4. NEVER generate greetings, apologies, narrative, or suggestions.\n"
    "5. NEVER hallucinate financial numbers. If a tool returns empty results, return them as-is.\n"
    "6. You have access to ONLY: businessInsightsTool, logExpense, getExpenses.\n"
    "7. ANALYTICS RULES: Default the 'period' to 'all_time' unless the user specifies "
    "'today', 'yesterday', 'this week', 'last week', 'this month', or 'last month'. "
    "Default the 'metric' to 'overview' unless user explicitly asks for profit, revenue, or approval_status.\n"
    "8. EXPENSE RULES: When logging expenses, extract the 'amount', 'category' (e.g., rent, salary, supplies), "
    "and 'description' from the task. For retrieving expenses, pass the time period.\n"
    "9. JSON COMPLIANCE: Use lowercase 'null', 'true', 'false'. NEVER use Python-style capitalized literals.\n"
    "10. Use India Standard Time for all date-based queries.";

  @override
  Future<AgentResponse> execute(AgentRequest request) async {
    final stopwatch = Stopwatch()..start();
    print('[FinanceAgent] Executing task: "${request.taskDescription}"');

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

      print('[FinanceAgent] Completed in ${stopwatch.elapsedMilliseconds}ms');

      // Extract tool results and build response
      CardPayload? card;
      Map<String, dynamic>? lastToolResult;

      for (final msg in response.messages) {
        for (final part in msg.content) {
          if (part.isToolRequest) {
            print('[FinanceAgent] Tool call: ${part.toolRequest?.name}');
          }
          if (part.isToolResponse) {
            final name = part.toolResponse?.name;
            final output = part.toolResponse?.output;
            print('[FinanceAgent] Tool response: $name');

            if (output != null) {
              lastToolResult = output is Map<String, dynamic>
                  ? output
                  : (output is Map ? Map<String, dynamic>.from(output) : {'result': output});

              // Map tool outputs to card types
              if (name == 'businessInsightsTool') {
                card = CardPayload(type: 'analytics_summary', data: {'data': output});
              } else if (name == 'getExpenses') {
                card = CardPayload(type: 'expense_report', data: {'data': output});
              }
              // logExpense doesn't produce a card — just a confirmation
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
      print('[FinanceAgent] Error: $e');
      return AgentResponse.toolFailed(e.toString());
    }
  }
}
