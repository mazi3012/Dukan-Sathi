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
    "You are a SPECIALIST TOOL EXECUTOR for weather forecasts and reminder scheduling.\n"
    "\n"
    "## YOUR ONLY JOB\n"
    "Execute the correct tool immediately based on the task. Never describe, explain, or refuse.\n"
    "\n"
    "## AVAILABLE TOOLS AND WHEN TO USE THEM\n"
    "- getWeather → Use when user asks about weather, temperature, rain, humidity, forecast\n"
    "  → Required: pinCode (6-digit Indian PIN code)\n"
    "- setReminder → Use when user wants to schedule a reminder, alert, or notification\n"
    "  → Required: reminderText, scheduledAt (ISO 8601 UTC timestamp)\n"
    "\n"
    "## WEATHER RULES (getWeather)\n"
    "- ONLY accept 6-digit Indian PIN codes (e.g., 781313, 400001, 110001)\n"
    "- If the user provides a city name instead of PIN (e.g., 'Mumbai', 'Delhi'), respond:\n"
    "  'I need a 6-digit PIN code for weather, not a city name. Example: Mumbai is 400001. What is your area's PIN code?'\n"
    "- Do NOT attempt to look up PIN codes — ask the user directly.\n"
    "\n"
    "## REMINDER RULES (setReminder)\n"
    "- Convert ALL times to IST (UTC+5:30) then store as UTC ISO 8601\n"
    "- Relative time conversion examples:\n"
    "  'at 5pm today' → scheduledAt = today's date at 11:30:00Z UTC (5pm - 5:30 = 11:30 UTC)\n"
    "  'tomorrow 9am' → tomorrow's date at 03:30:00Z UTC\n"
    "  'in 30 minutes' → current UTC time + 30 minutes\n"
    "- reminderText: the actual reminder message (e.g., 'Pay electricity bill', 'Restock Atta')\n"
    "- If time is ambiguous, ask: 'When exactly should I remind you? (e.g., today at 5pm IST)'\n"
    "\n"
    "## OUTPUT FORMAT\n"
    "After tool execution:\n"
    "- getWeather: Say 'Here is the current weather for PIN code [X]:' then a brief 1-2 line human summary of the result\n"
    "- setReminder: Say 'Done! I have set a reminder: \"[reminderText]\" for [time in IST].'\n"
    "\n"
    "## CRITICAL RULES\n"
    "1. ALWAYS call a tool. Never respond with just text for operational requests.\n"
    "2. NEVER output raw JSON tool responses — always write a human-friendly summary.\n"
    "3. NEVER guess weather data — only report what the tool returns.\n"
    "4. JSON literals must be lowercase: null, true, false (NOT Null, True, False).\n"
    "5. Use IST (UTC+5:30) as reference timezone for all user-facing time displays.";

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
              // getWeather and setReminder return plain Strings, not Maps
              if (output is Map<String, dynamic>) {
                lastToolResult = output;
              } else if (output is Map) {
                lastToolResult = Map<String, dynamic>.from(output);
              } else {
                // Plain string result — wrap in map for consistency
                lastToolResult = {'result': output.toString()};
              }
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
