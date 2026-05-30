/// Master Manager Agent — The Hub of the Multi-Agent System
///
/// This is the PRIMARY conversational interface. It:
/// 1. Maintains personality and conversational memory
/// 2. Classifies user intent using LLM (not keywords)
/// 3. Delegates operational tasks to sub-agents via AgentRequest envelopes
/// 4. Synthesizes sub-agent responses into a unified, friendly reply
/// 5. Falls back to the legacy WebChatSession for unhandled cases (Phase 1 safety)

import 'dart:async';
import 'dart:convert';
import 'package:genkit/genkit.dart';

import 'agent_contracts.dart';
import 'agent_registry.dart';
import '../runtime/genkit_runtime.dart';

class MasterManager {
  final AgentRegistry registry;
  final List<Message> _conversationHistory = [];
  String? _currentShopId;
  String? _currentUserId;

  /// Legacy fallback function — in Phase 1, unhandled cases fall through here.
  /// This is the existing WebChatSession.processMessage() wrapped as a function reference.
  final Future<Map<String, dynamic>> Function(String input, {String? shopId, String? userId})? legacyFallback;

  MasterManager({
    required this.registry,
    this.legacyFallback,
  });

  // ─── MANAGER'S PERSONALITY PROMPT ─────────────────────────────────────
  String get _managerSystemPrompt => '''
You are **Dukan Sathi** — the AI assistant for Indian small business shopkeepers.

## YOUR PERSONALITY
- Warm, professional, and concise — like a trusted business partner
- Respond in the same language the user writes in (Hindi, English, or Hinglish)
- Keep replies SHORT (2-3 sentences for confirmations, slightly longer for explanations)
- Show currency as ₹ for Indian Rupees
- Use India Standard Time (IST) for dates and times

## YOUR ROLE
You are the MANAGER. You do NOT execute tools directly.
Instead, you classify what the shopkeeper needs and delegate to specialist agents.

## AVAILABLE SPECIALIST AGENTS
${registry.getRoutingManifest()}

## HOW TO RESPOND

**Step 1: Classify the intent.**
Determine if this is:
a) Casual conversation (greetings, help, jokes, questions about yourself) → Reply directly
b) An operational task → Delegate to the appropriate agent(s)

**Step 2: For operational tasks, output a JSON routing block:**
```json
{"route": {"agentId": "task description for that agent"}}
```

Examples:
- User: "Make a bill for Rahul with 3 Dettol soaps"
  → {"route": {"billing": "Create draft invoice for customer Rahul with items: 3 Dettol soaps. Pass raw user prompt."}}

- User: "How much stock of Atta do I have?"
  → {"route": {"retail": "Check inventory stock for product 'Atta'"}}

- User: "Bill Rahul 2 soaps and also tell me today's revenue"
  → {"route": {"billing": "Create draft invoice for customer Rahul with 2 soaps", "finance": "Get business analytics for period 'today'"}}

- User: "Hi! How are you?"
  → Just reply naturally. No routing needed.

**Step 3: If you route to agents, ALSO include a brief natural language acknowledgment.**
Write a 1-line natural prefix like "Sure, let me handle that for you!" BEFORE the JSON block.

## CRITICAL RULES
1. NEVER execute tools yourself. You are the conversational layer only.
2. NEVER hallucinate data. If you don't know, say so.
3. For compound requests, route to MULTIPLE agents in a single JSON block.
4. ALWAYS include enough detail in the task description so the sub-agent can execute without ambiguity.
''';

  // ─── MAIN ENTRY POINT ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> processMessage(
    String input, {
    String? shopId,
    String? userId,
  }) async {
    if (shopId != null) _currentShopId = shopId;
    if (userId != null) _currentUserId = userId;

    final effectiveShopId = _currentShopId ?? '';
    final effectiveUserId = _currentUserId ?? 'web-user';

    if (effectiveShopId.isEmpty) {
      return {'text': '⚠️ Shop context not found. Please ensure you are logged in.'};
    }

    final stopwatch = Stopwatch()..start();
    print('[MasterManager] Processing: "$input"');

    try {
      // Step 1: Ask the Manager LLM to classify intent
      final routingDecision = await _classifyIntent(input, effectiveShopId, effectiveUserId);

      if (routingDecision == null) {
        // Classification failed — fall back to legacy system
        print('[MasterManager] Classification failed, falling back to legacy system');
        return await _fallbackToLegacy(input, shopId: shopId, userId: userId);
      }

      // Step 2: Handle chitchat directly
      if (routingDecision.isChitchat) {
        final reply = routingDecision.chitchatReply ?? "I'm here to help! Ask me anything about your shop.";
        _addToHistory(input, reply);
        print('[MasterManager] Chitchat handled in ${stopwatch.elapsedMilliseconds}ms');
        return {'text': reply};
      }

      // Step 3: Dispatch to sub-agents
      if (routingDecision.requiresAgents) {
        final results = await _dispatchToAgents(routingDecision, effectiveShopId, effectiveUserId);
        final synthesized = _synthesizeResponse(results, routingDecision);
        _addToHistory(input, synthesized['text'] as String? ?? '');
        print('[MasterManager] Multi-agent dispatch completed in ${stopwatch.elapsedMilliseconds}ms');
        return synthesized;
      }

      // Step 4: No agents matched — fall back to legacy
      print('[MasterManager] No agents matched, falling back to legacy system');
      return await _fallbackToLegacy(input, shopId: shopId, userId: userId);
    } catch (e) {
      print('[MasterManager] Error: $e');
      // On any error, safely fall back to legacy
      return await _fallbackToLegacy(input, shopId: shopId, userId: userId);
    }
  }

  // ─── INTENT CLASSIFICATION (LLM-powered) ──────────────────────────────
  Future<RoutingDecision?> _classifyIntent(String input, String shopId, String userId) async {
    try {
      // Keep conversation history lean
      if (_conversationHistory.length > 10) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 10);
      }

      final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} IST';

      final messages = [
        Message(role: Role.system, content: [
          TextPart(text: '$_managerSystemPrompt\n\nCurrent IST: $timeStr'),
        ]),
        ..._conversationHistory,
        Message(role: Role.user, content: [TextPart(text: input)]),
      ];

      final response = await ai.generate(
        model: appModel(),
        messages: messages,
        toolNames: [],  // Manager has NO tools — it only routes
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Manager classification timed out'),
      );

      final reply = response.text.trim();
      print('[MasterManager] LLM classification response: ${reply.substring(0, reply.length > 200 ? 200 : reply.length)}...');

      // Try to extract JSON routing block from the response
      final jsonMatch = RegExp(r'\{[\s]*"route"[\s]*:[\s]*\{[^}]+\}[\s]*\}').firstMatch(reply);

      if (jsonMatch != null) {
        try {
          final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          final routeMap = parsed['route'] as Map<String, dynamic>?;

          if (routeMap != null && routeMap.isNotEmpty) {
            final agentTasks = <String, String>{};
            for (final entry in routeMap.entries) {
              final agentId = entry.key.toString();
              final task = entry.value.toString();
              // Only add if the agent actually exists in the registry
              if (registry.getAgent(agentId) != null) {
                agentTasks[agentId] = task;
              } else {
                print('[MasterManager] Warning: LLM routed to unknown agent "$agentId", skipping');
              }
            }

            if (agentTasks.isNotEmpty) {
              // Extract the natural language prefix (everything before the JSON block)
              final naturalPrefix = reply.substring(0, jsonMatch.start).trim();
              return RoutingDecision(agentTasks: agentTasks, chitchatReply: naturalPrefix.isNotEmpty ? naturalPrefix : null);
            }
          }
        } catch (e) {
          print('[MasterManager] Failed to parse routing JSON: $e');
        }
      }

      // No JSON routing found — this is a chitchat/direct response
      return RoutingDecision(isChitchat: true, chitchatReply: reply);
    } catch (e) {
      print('[MasterManager] Classification error: $e');
      return null; // Will trigger legacy fallback
    }
  }

  // ─── PARALLEL AGENT DISPATCH ──────────────────────────────────────────
  Future<Map<String, AgentResponse>> _dispatchToAgents(
    RoutingDecision decision,
    String shopId,
    String userId,
  ) async {
    final results = <String, AgentResponse>{};

    // Dispatch all agents in parallel using Future.wait
    final futures = <String, Future<AgentResponse>>{};
    for (final entry in decision.agentTasks.entries) {
      final agent = registry.getAgent(entry.key);
      if (agent != null) {
        final request = AgentRequest(
          taskDescription: entry.value,
          originalUserInput: decision.chitchatReply ?? entry.value,
          shopId: shopId,
          userId: userId,
        );
        futures[entry.key] = agent.execute(request);
      }
    }

    // Wait for all to complete
    final entries = futures.entries.toList();
    final responses = await Future.wait(entries.map((e) => e.value));
    for (var i = 0; i < entries.length; i++) {
      results[entries[i].key] = responses[i];
    }

    return results;
  }

  // ─── RESPONSE SYNTHESIS ───────────────────────────────────────────────
  Map<String, dynamic> _synthesizeResponse(
    Map<String, AgentResponse> results,
    RoutingDecision decision,
  ) {
    final textParts = <String>[];
    Map<String, dynamic>? firstCard;

    // Add the Manager's natural prefix if available
    if (decision.chitchatReply != null && decision.chitchatReply!.isNotEmpty) {
      textParts.add(decision.chitchatReply!);
    }

    for (final entry in results.entries) {
      final agentId = entry.key;
      final response = entry.value;
      final agent = registry.getAgent(agentId);

      switch (response.status) {
        case AgentStatus.success:
          if (response.summaryForManager != null && response.summaryForManager!.isNotEmpty) {
            final trimmedSummary = response.summaryForManager!.trim();
            if (trimmedSummary.startsWith('{') || trimmedSummary.startsWith('[')) {
              if (response.card != null) {
                final cardType = response.card!.type;
                if (cardType == 'invoice') {
                  textParts.add("I have drafted the invoice for your review. Please see the details below.");
                } else if (cardType == 'batch') {
                  textParts.add("I have prepared the bulk product proposal. You can review and import the products below.");
                } else if (cardType == 'analytics_summary') {
                  textParts.add("Here is the business performance and insights summary:");
                } else if (cardType == 'customer_dues_list') {
                  textParts.add("Here are the customers with outstanding dues:");
                } else if (cardType == 'customer_due_detail') {
                  textParts.add("Here are the outstanding dues details for the customer:");
                } else if (cardType == 'expense_report') {
                  textParts.add("Here is the requested business expense report:");
                } else if (cardType == 'invoice_lookup') {
                  textParts.add("I found the requested invoice. Please review the details below:");
                } else if (cardType == 'product_catalog') {
                  textParts.add("Here is the product catalog matching your query:");
                } else if (cardType == 'payment_confirmation') {
                  textParts.add("I have successfully recorded the payment transaction:");
                } else {
                  textParts.add("I have successfully processed your request:");
                }
              } else {
                textParts.add("I have successfully processed your request.");
              }
            } else {
              textParts.add(trimmedSummary);
            }
          }
          // Use the first card from any successful agent
          if (firstCard == null && response.card != null) {
            firstCard = response.card!.toJson();
          }
          break;

        case AgentStatus.errorMissingParams:
          textParts.add(
            "I need a bit more information to complete that: ${response.missingFields?.join(', ') ?? 'some details are missing'}. "
            "Could you provide those?"
          );
          break;

        case AgentStatus.errorToolFailed:
          textParts.add(
            "I ran into an issue while processing your request with the ${agent?.displayName ?? agentId}. "
            "Please try again or rephrase your request."
          );
          break;

        case AgentStatus.errorNotMyDomain:
          // Silently skip — the Manager handles this
          break;
      }
    }

    final finalText = textParts.isNotEmpty
        ? textParts.join('\n\n')
        : "I've processed your request.";

    return {
      'text': finalText,
      if (firstCard != null) 'card': firstCard,
    };
  }

  // ─── LEGACY FALLBACK (Phase 1 safety net) ─────────────────────────────
  Future<Map<String, dynamic>> _fallbackToLegacy(
    String input, {
    String? shopId,
    String? userId,
  }) async {
    if (legacyFallback != null) {
      print('[MasterManager] Delegating to legacy WebChatSession.processMessage()');
      return await legacyFallback!(input, shopId: shopId, userId: userId);
    }

    // If no legacy fallback is available, return a generic error
    return {
      'text': "I'm sorry, I couldn't process that request right now. Please try again.",
    };
  }

  // ─── HISTORY MANAGEMENT ───────────────────────────────────────────────
  void _addToHistory(String input, String reply) {
    _conversationHistory.add(Message(role: Role.user, content: [TextPart(text: input)]));
    _conversationHistory.add(Message(role: Role.model, content: [TextPart(text: reply)]));
  }

  /// Clear conversation history (called when user clears chat)
  void clearHistory() {
    _conversationHistory.clear();
  }
}
