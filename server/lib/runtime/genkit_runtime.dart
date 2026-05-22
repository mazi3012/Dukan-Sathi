import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_openai/genkit_openai.dart';

final DotEnv _env = DotEnv(includePlatformEnvironment: true);

void _loadDotEnv() {
  if (File('.env').existsSync()) {
    _env.load(['.env']);
  }
}

String? _envValue(String key) {
  final fromPlatform = Platform.environment[key];
  if (fromPlatform != null && fromPlatform.trim().isNotEmpty) {
    return fromPlatform.trim();
  }

  final fromDotEnv = _env[key];
  if (fromDotEnv != null && fromDotEnv.trim().isNotEmpty) {
    return fromDotEnv.trim();
  }

  return null;
}

String? getEnv(String key) => _envValue(key);

// ─── Lazy initialization — avoids top-level crash before main() runs ─────────
Genkit? _genkitInstance;

Genkit _createGenkit() {
  _loadDotEnv();

  final groqApiKey = _envValue('GROQ_API_KEY');
  if (groqApiKey == null || groqApiKey.isEmpty) {
    throw StateError(
      'Missing required GROQ API key. Please set GROQ_API_KEY in the environment.',
    );
  }

  final defaultModel =
      _envValue('MODEL_ID') ?? 'meta-llama/llama-4-scout-17b-16e-instruct';

  return Genkit(
    plugins: [
      openAI(
        apiKey: groqApiKey,
        baseUrl: 'https://api.groq.com/openai/v1',
        models: [
          CustomModelDefinition(
            name: defaultModel,
            info: ModelInfo(
              label: 'Groq Custom Model',
              supports: {
                'multiturn': true,
                'tools': true,
                'systemRole': true,
              },
            ),
          ),
        ],
      ),
    ],
  );
}

/// Call this once from main() before accessing [ai]
void initializeGenkit() {
  _genkitInstance = _createGenkit();
}

Genkit get ai {
  if (_genkitInstance == null) {
    throw StateError('Genkit not initialized. Call initializeGenkit() first.');
  }
  return _genkitInstance!;
}

bool get isGroq => _envValue('GROQ_API_KEY') != null;

String get modelId =>
    _envValue('MODEL_ID') ??
    (isGroq
        ? 'meta-llama/llama-4-scout-17b-16e-instruct'
        : 'gemini-3.1-flash-lite-preview');

String get aiProvider => isGroq ? 'Groq via OpenAI Plugin' : 'Google GenAI SDK';

dynamic appModel([String? override]) {
  final String mId =
      (override == null || override.trim().isEmpty) ? modelId : override.trim();
  if (isGroq) {
    return openAI.model(mId);
  }
  return googleAI.gemini(mId);
}
