import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/tools/billing_tools.dart';
import 'package:dukansathi_new/tools/inventory_tools.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_vertexai/genkit_vertexai.dart';
import 'package:teledart/teledart.dart' as tg;

final Map<int, Chat> activeSessions = {};

const String _systemPrompt =
    "You are the AI brain for Dukan Sathi Pro. The current shop ID is 'shop_001'. CRITICAL RULES: 1. DO NOT narrate your actions. Never say 'I am checking' or 'Using tool'. 2. Use tools silently. 3. Once the tool returns data, ONLY output the final result. 4. If asked to bill, use the draft invoice tool. 5. If an item is missing, say 'Not in inventory'.";

final checkInventoryTool = checkInventory;
final createDraftInvoiceTool = createDraftInvoice;

class Chat {
  Chat({
    required this.model,
    required this.tools,
    required this.systemPrompt,
  });

  final String model;
  final List<String> tools;
  final String systemPrompt;
  final List<Message> _history = [];

  List<String> _selectToolNames(String input) {
    final normalized = input.toLowerCase();
    if (normalized.contains('bill') ||
        normalized.contains('invoice') ||
        normalized.contains('draft')) {
      return ['createDraftInvoice'];
    }
    if (normalized.contains('stock') ||
        normalized.contains('inventory') ||
        normalized.contains('price') ||
        normalized.contains('item')) {
      return ['checkInventory'];
    }
    return <String>[];
  }

  Future<String> sendMessage(String? text) async {
    final input = (text ?? '').trim();
    if (input.isEmpty) {
      return '';
    }

    _history.add(
      Message(role: Role.user, content: [TextPart(text: input)]),
    );

    final selectedTools = _selectToolNames(input)
        .where((tool) => tools.contains(tool))
        .toList();

    Future<dynamic> runGenerate(String modelName) {
      return ai.generate(
        model: vertexAI.gemini(modelName),
        messages: [
          Message(
            role: Role.system,
            content: [TextPart(text: systemPrompt)],
          ),
          ..._history,
        ],
        toolNames: selectedTools,
      );
    }

    dynamic response;
    try {
      response = await runGenerate(model);
    } catch (e) {
      final error = e.toString();
      if (error.contains('NOT_FOUND') ||
          error.contains('does not have access') ||
          error.contains('not found')) {
        response = await runGenerate('gemini-2.5-flash');
      } else if (error.contains('Multiple tools are supported only when they are all search tools') ||
          error.contains('INVALID_ARGUMENT')) {
        response = await ai.generate(
          model: vertexAI.gemini('gemini-2.5-flash'),
          messages: [
            Message(
              role: Role.system,
              content: [TextPart(text: systemPrompt)],
            ),
            ..._history,
          ],
          toolNames: <String>[],
        );
      } else {
        rethrow;
      }
    }

    final reply = response.text.trim();
    _history.add(
      Message(role: Role.model, content: [TextPart(text: reply)]),
    );
    return reply;
  }
}

Future<void> main(List<String> arguments) async {
  initializeBackend();

  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load(['.env']);
  }
  final token = Platform.environment['TELEGRAM_BOT_TOKEN'] ??
      env['TELEGRAM_BOT_TOKEN'];

  if (token == null || token.isEmpty) {
    throw StateError('TELEGRAM_BOT_TOKEN is not set.');
  }

  final bot = tg.TeleDart(token, tg.Event(''));
  bot.onMessage().listen((message) async {
    final text = message.text?.trim();
    if (text == null || text.isEmpty) {
      return;
    }

    final chatId = message.chat.id;
    final session = activeSessions.putIfAbsent(
      chatId,
      () => Chat(
        model: 'gemini-3.1-flash-lite-preview',
        tools: [checkInventoryTool.name, createDraftInvoiceTool.name],
        systemPrompt: _systemPrompt,
      ),
    );

    try {
      final reply = await session.sendMessage(message.text);
      await bot.sendMessage(chatId, reply.isEmpty ? 'Not in inventory' : reply);
    } catch (e) {
      await bot.sendMessage(
        chatId,
        'Sorry, I could not process that right now. Please try again.',
      );
      stderr.writeln('telegram_bot error for chat $chatId: $e');
    }
  });

  bot.start();
}
