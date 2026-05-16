import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    await _flutterTts.setLanguage("en-IN");

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint("TTS Error: $msg");
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Clean text to make it human language friendly for TTS
    String cleanText = text;
    // Remove markdown symbols (asterisks, hashes, backticks, tildes, brackets)
    cleanText = cleanText.replaceAll(RegExp(r'[*#_~`\[\]]'), '');
    // Remove emojis
    cleanText = cleanText.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}]', unicode: true), '');
    // Replace markdown links with just the link text if any (the above regex handles brackets, but let's be safe)
    cleanText = cleanText.trim();
    
    if (cleanText.isEmpty) return;
    
    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }
}
