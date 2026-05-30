/// Spoke D: Utility & Lifestyle Sub-Agent
///
/// STRICT SILENT EXECUTOR — handles weather forecasts, reminders, and general utility tasks.
/// This agent wraps the existing utility tool functions WITHOUT modifying them.

import 'package:genkit/genkit.dart';

import 'agent_contracts.dart';
import 'agent_registry.dart';
import '../runtime/genkit_runtime.dart';

class UtilityAgent extends SubAgent {
  @override
  String get id => 'utility';

  @override
  String get displayName => 'Utility & Lifestyle Agent';

  @override
  String get description =>
      'Handles weather forecasts (by Indian PIN code) and reminder scheduling. '
      'Use this agent when the user asks about weather, temperature, rain, '
      'forecasts, or wants to set/schedule reminders and alerts.';

  @override
  List<String> get toolNames => [
    'getWeather',
    'setReminder',
  ];

  /// Sub-agent system prompt: STRICT TOOL EXECUTOR, NO CONVERSATION
  static const String _systemPrompt =
    "You are a TOOL EXECUTOR for utility and lifestyle operations.\n"
    "STRICT RULES:\n"
    "1. You receive a task description. Execute the appropriate tool IMMEDIATELY.\n"
    "2. After executing the tool, write a brief, friendly, one-sentence summary of the action for the shopkeeper (e.g., 'Here is the weather forecast for your area.'). Do NOT output raw JSON in your text response.\n"
    "3. If parameters are missing, say exactly what is missing.\n"
    "4. NEVER generate greetings, apologies, narrative, or suggestions.\n"
    "5. NEVER hallucinate data. If a tool returns empty results, state that clearly.\n"
    "6. You have access to ONLY: getWeather, setReminder.\n"
    "7. WEATHER RULES: The user must provide a 6-digit Indian PIN code. If the user provides a city name instead, ask for their PIN code.\n"
    "8. REMINDER RULES: Parse the reminder text and time from the task. Convert relative times (e.g., '30 minutes', 'tomorrow 9am') to ISO 8601 UTC timestamps. Use India Standard Time (IST, UTC+5:30) as the reference timezone.\n"
    "9. JSON COMPLIANCE: Use lowercase 'null', 'true', 'false'. NEVER use Python-style capitalized literals.\n"
    "10. Use India Standard Time for all date-based queries.";

  @override
  Future<AgentResponse> execute(AgentRequest request) async {
    final stopwatch = Stopwatch()..start();
    print('[UtilityAgent] Executing task: "${request.taskDescription}"');

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

      print('[UtilityAgent] Completed in ${stopwatch.elapsedMilliseconds}ms');

      // Extract tool results and build response
      Map<String, dynamic>? lastToolResult;

      for (final msg in response.messages) {
        for (final part in msg.content) {
          if (part.isToolRequest) {
            print('[UtilityAgent] Tool call: ${part.toolRequest?.name}');
          }
          if (part.isToolResponse) {
            final name = part.toolResponse?.name;
            final output = part.toolResponse?.output;
            print('[UtilityAgent] Tool response: $name');

            if (output != null) {
              lastToolResult = output is Map<String, dynamic>
                  ? output
                  : (output is Map ? Map<String, dynamic>.from(output) : {'result': output});
            }
          }
        }
      }

      return AgentResponse.success(
        summary: response.text.trim(),
        toolResult: lastToolResult,
      );
    } catch (e) {
      print('[UtilityAgent] Error: $e');
      return AgentResponse.toolFailed(e.toString());
    }
  }
}
