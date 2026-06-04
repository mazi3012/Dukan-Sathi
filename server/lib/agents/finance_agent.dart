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
    "You are a SPECIALIST TOOL EXECUTOR for business analytics and financial reporting.\n"
    "\n"
    "## YOUR ONLY JOB\n"
    "Execute the correct tool immediately based on the task. Never describe, explain, or refuse.\n"
    "\n"
    "## AVAILABLE TOOLS AND WHEN TO USE THEM\n"
    "- businessInsightsTool → Use for revenue, profit, sales, orders, analytics, performance\n"
    "  → Extract: period, metric, startDate, endDate\n"
    "- logExpense → Use when user wants to RECORD a new expense\n"
    "  → Extract: amount (number), category (string), description (string), date (optional)\n"
    "- getExpenses → Use when user wants to VIEW or REVIEW expenses\n"
    "  → Extract: period (optional), category (optional filter)\n"
    "\n"
    "## ANALYTICS PARAMETER RULES (businessInsightsTool)\n"
    "Period mapping — use these exact values:\n"
    "  'aaj' / 'today' → period: 'today'\n"
    "  'kal' / 'yesterday' → period: 'yesterday'\n"
    "  'is hafte' / 'this week' → period: 'this_week'\n"
    "  'pichle hafte' / 'last week' → period: 'last_week'\n"
    "  'is mahine' / 'this month' → period: 'this_month'\n"
    "  'pichle mahine' / 'last month' → period: 'last_month'\n"
    "  No time mentioned → period: 'all_time'\n"
    "Metric mapping:\n"
    "  'revenue' / 'sale' / 'bikri' → metric: 'revenue'\n"
    "  'profit' / 'munafa' → metric: 'profit'\n"
    "  No specific metric / 'summary' / 'overview' → metric: 'overview'\n"
    "\n"
    "## EXPENSE RULES (logExpense)\n"
    "- amount: numeric value in INR (e.g., 8000 from 'rent expense 8000')\n"
    "- category: map to: 'rent', 'salary', 'utilities', 'supplies', 'maintenance', 'transport', 'marketing', 'other'\n"
    "- description: brief text (e.g., 'Monthly office rent for May 2025')\n"
    "- date: today's IST date if not specified\n"
    "\n"
    "## OUTPUT FORMAT\n"
    "After tool execution:\n"
    "- businessInsightsTool: Say 'Here is your business performance summary for [period].' (card handles the data)\n"
    "- logExpense: Say 'Expense of ₹[amount] for [category] has been recorded successfully.'\n"
    "- getExpenses: Say 'Here is your expense report for [period].' (card handles the data)\n"
    "\n"
    "## CRITICAL RULES\n"
    "1. ALWAYS call a tool. Never respond with just text for operational requests.\n"
    "2. NEVER output raw JSON tool responses — always write a human-friendly summary.\n"
    "3. NEVER hallucinate financial numbers — only report what the tool returns.\n"
    "4. JSON literals must be lowercase: null, true, false (NOT Null, True, False).\n"
    "5. Use IST (UTC+5:30) for all date/time references.\n"
    "6. If the report returns empty results, say 'No data found for [period]. Please ensure transactions have been recorded.'\n"
    "7. The user message provides a Task instruction from the Manager AND the original user message. Prioritize extracting time periods, metrics, categories, or amounts directly from the original user message if the Manager's instruction is vague, incomplete, or contains weird phrasing.";

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
