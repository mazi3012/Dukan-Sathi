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
import 'package:schemantic/schemantic.dart';

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
You are **Dukan Sathi** 🤖 — an intelligent AI assistant for Indian small business shopkeepers.
Your role is to classify the user's intent and either reply directly (for greetings/advice) or route the request to a specialist agent (for shop database actions).

## SPECIALIST AGENTS AVAILABLE FOR ROUTING
${registry.getRoutingManifestMinimal()}

## ROUTING RULE
If the user's request requires shop database actions, logs, reports, weather forecast, or reminders (e.g. checking stock, sales, creating bills, customer dues, logging expenses/payments), you MUST route it.
To route, output a 1-line friendly acknowledgment, followed immediately by the route JSON block:
{"route": {"<AGENT_ID>": "<Task description in plain English>"}}

Example:
User: "what is my total revenue this month"
Response: Checking your revenue! 📊
{"route": {"finance": "Get total business revenue and analytics for this month"}}

Example:
User: "bill Rahul 2 soaps"
Response: Creating the invoice right away!
{"route": {"billing": "Create draft invoice for customer Rahul with items: 2 soaps"}}

Example:
User: "whats the weather now"
Response: Checking the forecast!
{"route": {"utility": "Get weather forecast for current location"}}

## DIRECT RESPONSE RULE
For greetings, casual conversation, general advice, simple math, or capability questions, reply directly in natural language (Hindi, English, or Hinglish as appropriate). Do NOT output any JSON.

Example:
User: "Hi!"
Response: Hello! 👋 I am Dukan Sathi. How can I help you manage your shop today?

## CRITICAL RESTRICTION
Do NOT output any other JSON format. Only output raw text or the `{"route": ...}` JSON block.
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

    // ─── Step 0: INSTANT local chitchat — no LLM needed ─────────────────
    final localReply = _tryLocalChitchat(input);
    if (localReply != null) {
      _addToHistory(input, localReply);
      print('[MasterManager] Local chitchat handled in ${stopwatch.elapsedMilliseconds}ms');
      return {'text': localReply};
    }

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
        final results = await _dispatchToAgents(routingDecision, effectiveShopId, effectiveUserId, input);
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

  // ─── INSTANT LOCAL CHITCHAT DETECTION ─────────────────────────────────
  /// Returns an instant reply for common greetings, help, identity questions,
  /// thanks, and farewells WITHOUT calling any LLM. Returns null if the input
  /// is NOT simple chitchat (i.e., it likely requires tool execution or routing).
  String? _tryLocalChitchat(String input) {
    final n = input.toLowerCase().trim();
    final wordCount = n.split(RegExp(r'\s+')).length;

    // ── Greetings ──
    final greetingPattern = RegExp(
      r'^(hi+|hello|hey|namaste|namaskar|hola|salaam|good\s*(morning|afternoon|evening|night)|howdy|yo|sup|kya\s*hal|kaise\s*ho|kem\s*cho)\b',
      caseSensitive: false,
    );
    if (greetingPattern.hasMatch(n) && wordCount <= 5) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final hour = now.hour;
      final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
      return '$greeting! 👋 I\'m Dukan Sathi, your shop assistant. How can I help you today?\n\n'
          'Here\'s what I can do:\n'
          '• 📦 Check inventory & stock\n'
          '• 🧾 Create invoices & bills\n'
          '• 📊 Show sales & revenue reports\n'
          '• 💰 Track customer dues & payments\n'
          '• 📝 Log expenses\n\n'
          'Just tell me what you need!';
    }

    // ── Help / Capabilities ──
    final helpPattern = RegExp(
      r'^(what\s+can\s+you\s+do|help|help\s+me|what\s+are\s+you|what\s+do\s+you\s+do|features|kya\s+kar\s+sakte|capabilities|how\s+to\s+use|options|commands|menu)',
      caseSensitive: false,
    );
    if (helpPattern.hasMatch(n) && wordCount <= 8) {
      return 'I\'m **Dukan Sathi**, your AI-powered shop management assistant! Here\'s everything I can help with:\n\n'
          '🧾 **Billing** — "Make a bill for Rahul with 2 soaps"\n'
          '📦 **Inventory** — "How much stock of Atta do I have?"\n'
          '📋 **Product Catalog** — "Show product list"\n'
          '📊 **Analytics** — "What is my total revenue?"\n'
          '💰 **Customer Dues** — "Who owes me money?"\n'
          '💳 **Payments** — "Record payment from Rahul ₹500"\n'
          '📝 **Expenses** — "Log rent expense ₹5000"\n\n'
          'Just type naturally — I understand Hindi, English, and Hinglish! 🇮🇳';
    }

    // ── Identity questions ──
    final identityPattern = RegExp(
      r'^(who\s+are\s+you|what\s+is\s+your\s+name|tum\s+kaun\s+ho|aap\s+kaun|your\s+name|apna\s+naam\s+batao|tell\s+me\s+about\s+yourself|introduce\s+yourself)',
      caseSensitive: false,
    );
    if (identityPattern.hasMatch(n) && wordCount <= 8) {
      return 'I\'m **Dukan Sathi** 🤖 — your AI-powered shop assistant built for Indian small business owners!\n\n'
          'I help you manage billing, inventory, sales analytics, customer dues, and expenses — all through simple conversation. '
          'Think of me as your trusted digital partner who never takes a day off! 💪';
    }

    // ── Thanks ──
    final thanksPattern = RegExp(
      r'^(thanks|thank\s*you|thankyou|dhanyawad|dhanyavaad|shukriya|bahut\s+accha|great|awesome|perfect|nice|ok\s+thanks|thx)',
      caseSensitive: false,
    );
    if (thanksPattern.hasMatch(n) && wordCount <= 5) {
      return 'You\'re welcome! 😊 Let me know if you need anything else.';
    }

    // ── Farewells ──
    final farewellPattern = RegExp(
      r'^(bye|goodbye|good\s*bye|see\s+you|alvida|chalo|ok\s+bye|tata|phir\s+milte|baad\s+mein)',
      caseSensitive: false,
    );
    if (farewellPattern.hasMatch(n) && wordCount <= 5) {
      return 'Goodbye! 👋 Your shop data is safe with me. Come back anytime you need help!';
    }

    // ── How are you / status ──
    final statusPattern = RegExp(
      r"^(how\s+are\s+you|how\s+r\s+u|kaisa\s+hai|kya\s+haal|whats\s+up|what'?s\s+up|aur\s+bata|all\s+good)",
      caseSensitive: false,
    );
    if (statusPattern.hasMatch(n) && wordCount <= 6) {
      return 'I\'m running great! ⚡ Ready to help you manage your shop. What would you like to do?';
    }

    // Not a simple chitchat — needs LLM classification
    return null;
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
        outputFormat: 'json',
        outputSchema: SchemanticType.from<Map<String, dynamic>>(
          jsonSchema: {
            'type': 'object',
            'properties': {
              'isChitchat': {
                'type': 'boolean',
                'description': 'True if the request is casual small talk, greetings, general advice, simple math, or capability questions. False if it requires querying the shop databases or taking database action (checking stock, sales, creating bills, dues, weather, reminders).',
              },
              'directReply': {
                'type': 'string',
                'description': 'The natural language reply if isChitchat is true. Set to empty string if false.',
              },
              'agentId': {
                'type': 'string',
                'description': 'The target agent ID ("retail", "billing", "finance", or "utility") if isChitchat is false. Set to empty string if true.',
              },
              'taskDescription': {
                'type': 'string',
                'description': 'Description of the task to perform in plain English if isChitchat is false. Set to empty string if true.',
              },
            },
            'required': ['isChitchat', 'directReply', 'agentId', 'taskDescription'],
          },
          parse: (json) => Map<String, dynamic>.from(json as Map),
        ),
        config: const {
          'temperature': 0.1,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Manager classification timed out'),
      );

      Map<String, dynamic>? data;
      if (response.output != null) {
        data = response.output;
      } else {
        final text = response.text.trim();
        print('[MasterManager] Warning: response.output was null, fallback to parsing response.text: $text');
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>?;
        }
      }

      if (data == null) {
        print('[MasterManager] Error: No valid JSON output structure found.');
        return null;
      }

      print('[MasterManager] LLM structured response: $data');

      final isChitchat = data['isChitchat'] == true;
      if (isChitchat) {
        final directReply = data['directReply']?.toString() ?? '';
        return RoutingDecision(isChitchat: true, chitchatReply: directReply);
      } else {
        final agentId = data['agentId']?.toString();
        final taskDescription = data['taskDescription']?.toString();
        if (agentId != null && agentId.isNotEmpty && taskDescription != null && taskDescription.isNotEmpty) {
          if (registry.getAgent(agentId) != null) {
            final directReplyStr = data['directReply']?.toString();
            return RoutingDecision(
              agentTasks: {agentId: taskDescription},
              chitchatReply: (directReplyStr != null && directReplyStr.isNotEmpty) ? directReplyStr : null,
            );
          } else {
            print('[MasterManager] Warning: LLM routed to unknown agent "$agentId", skipping');
          }
        }
      }

      return null;
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
    String originalUserInput,
  ) async {
    final results = <String, AgentResponse>{};

    // Dispatch all agents in parallel using Future.wait
    final futures = <String, Future<AgentResponse>>{};
    for (final entry in decision.agentTasks.entries) {
      final agent = registry.getAgent(entry.key);
      if (agent != null) {
        final request = AgentRequest(
          taskDescription: entry.value,
          originalUserInput: originalUserInput,  // ✅ Fixed: pass actual user input
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
