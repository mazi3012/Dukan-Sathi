import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';
import 'package:dukansathi_new/models/product.dart';
import 'package:dukansathi_new/tools/analytics_tools.dart';
import 'package:dukansathi_new/tools/billing_tools.dart';
import 'package:dukansathi_new/tools/inventory_tools.dart';
import 'package:genkit/genkit.dart';
import 'package:teledart/teledart.dart' as tg;

final Map<int, Chat> activeSessions = {};

const String _systemPrompt =
  "You are the AI brain for Dukan Sathi Pro. Shop ID is 'shop_001'. CRITICAL RULES: 1. No narration (never say 'I am checking' or 'Using tool'). 2. Use tools silently. 3. Output final result only. 4. For specific items use checkInventory. 5. If the user asks for a list of products or what you sell, use browseCatalogTool. 6. If the user asks for total sales or analytics, use businessInsightsTool.";

final checkInventoryTool = checkInventory;
final catalogTool = browseCatalog;
final createDraftInvoiceTool = createDraftInvoice;
final analyticsTool = businessInsightsTool;

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

  bool _isInventoryIntent(String input) {
    final normalized = input.toLowerCase();
    return normalized.contains('stock') ||
        normalized.contains('inventory') ||
        normalized.contains('price') ||
        normalized.contains('how many') ||
        normalized.contains('quantity') ||
        normalized.contains('left') ||
        normalized.contains('available') ||
        normalized.contains('have');
  }

  bool _isCatalogIntent(String input) {
    final normalized = input.toLowerCase();
    return normalized.contains('what do you sell') ||
      normalized.contains('what item do you sell') ||
      normalized.contains('what items do you sell') ||
        normalized.contains('catalog') ||
        normalized.contains('list products') ||
        normalized.contains('show products') ||
        normalized.contains('show items') ||
      normalized.contains('available products') ||
      normalized.contains('what do you have') ||
      normalized.contains('what items') ||
      normalized.contains('items do you have');
  }

  String? _extractCategory(String input) {
    final normalized = input.toLowerCase();
    final categories = <String>['staples', 'snacks', 'beverages', 'dairy'];
    for (final category in categories) {
      if (normalized.contains(category)) {
        return category[0].toUpperCase() + category.substring(1);
      }
    }
    return null;
  }

  String _extractInventoryQuery(String input) {
    var normalized = input.toLowerCase();
    final noisePhrases = <String>[
      'what is the price of',
      'price of',
      'how many',
      'do we have',
      'we have',
      'in stock',
      'stock of',
      'quantity of',
      'available',
      'please',
    ];
    for (final phrase in noisePhrases) {
      normalized = normalized.replaceAll(phrase, ' ');
    }
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  String _formatInventoryReply(List<Product> products) {
    if (products.isEmpty) {
      return 'Not in inventory.';
    }
    if (products.length == 1) {
      final p = products.first;
      return '${p.name}: ₹${_formatPrice(p.price)}, stock ${p.stockQuantity} units.';
    }
    final lines = products.take(3).map((p) =>
        '${p.name}: ₹${_formatPrice(p.price)}, stock ${p.stockQuantity} units.');
    return lines.join('\n');
  }

  String _formatCatalogReply(Map<String, dynamic> payload) {
    final message = payload['message']?.toString() ?? '';
    final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    if (items.isEmpty) {
      return message.isEmpty ? 'Our catalog is currently being updated.' : message;
    }

    final lines = items.take(20).map((p) =>
        '${p.name}: ₹${_formatPrice(p.price)}, stock ${p.stockQuantity} units.');
    return lines.join('\n');
  }

  List<String> _selectToolNames(String input) {
    final normalized = input.toLowerCase();
    if (normalized.contains('what do you sell') ||
        normalized.contains('what item do you sell') ||
        normalized.contains('what items do you sell') ||
        normalized.contains('catalog') ||
        normalized.contains('list products') ||
        normalized.contains('show products') ||
        normalized.contains('show items') ||
        normalized.contains('what do you have')) {
      return ['browseCatalogTool'];
    }
    if (normalized.contains('bill') ||
        normalized.contains('invoice') ||
        normalized.contains('draft')) {
      return ['createDraftInvoice'];
    }
    if (normalized.contains('total sales') ||
        normalized.contains('revenue') ||
        normalized.contains('analytics') ||
        normalized.contains('insight')) {
      return ['businessInsightsTool'];
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

    if (_isCatalogIntent(input)) {
      final payload = await browseCatalogTool({
        'category': _extractCategory(input),
      });
      final reply = _formatCatalogReply(payload);
      _history.add(
        Message(role: Role.user, content: [TextPart(text: input)]),
      );
      _history.add(
        Message(role: Role.model, content: [TextPart(text: reply)]),
      );
      return reply;
    }

    if (_isInventoryIntent(input)) {
      final query = _extractInventoryQuery(input);
      final products = await findInventoryProducts(query.isEmpty ? input : query);
      final reply = _formatInventoryReply(products);
      _history.add(
        Message(role: Role.user, content: [TextPart(text: input)]),
      );
      _history.add(
        Message(role: Role.model, content: [TextPart(text: reply)]),
      );
      return reply;
    }

    _history.add(
      Message(role: Role.user, content: [TextPart(text: input)]),
    );

    final selectedTools = _selectToolNames(input)
        .where((tool) => tools.contains(tool))
        .toList();

    Future<dynamic> runGenerate() {
      return ai.generate(
        model: appModel(model),
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
      response = await runGenerate();
    } catch (e) {
      final error = e.toString();
      if (error.contains('Multiple tools are supported only when they are all search tools') ||
          error.contains('INVALID_ARGUMENT')) {
        response = await ai.generate(
          model: appModel(model),
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
  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load(['.env']);
  }
  final modelId = Platform.environment['MODEL_ID'] ??
      env['MODEL_ID'] ??
      'gemini-3.1-flash-lite-preview';
  final token = Platform.environment['TELEGRAM_BOT_TOKEN'] ??
      env['TELEGRAM_BOT_TOKEN'];

  initializeBackend();

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
        model: modelId,
        tools: [
          checkInventoryTool.name,
          catalogTool.name,
          createDraftInvoiceTool.name,
          analyticsTool.name,
        ],
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
