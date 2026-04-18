import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/flows/retail_assistant.dart';
import 'package:teledart/teledart.dart';

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

  final bot = TeleDart(token, Event(''));
  bot.onMessage().listen((message) async {
    final text = message.text?.trim();
    if (text == null || text.isEmpty) {
      return;
    }

    final reply = await retailAssistantFlow(text);
    await bot.sendMessage(message.chat.id, reply);
  });

  bot.start();
}
