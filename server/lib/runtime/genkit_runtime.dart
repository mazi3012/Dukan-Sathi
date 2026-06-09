import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_openai/genkit_openai.dart';

final DotEnv _env = DotEnv(includePlatformEnvironment: true);

void _loadDotEnv() {
  if (File('.env').existsSync()) {
    _env.load(['.env']);
  } else if (File('../.env').existsSync()) {
    _env.load(['../.env']);
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

String? _getApiKey() {
  // Priority: NVIDIA (free) > OpenRouter > Groq
  // NOTE: GROQ_API_KEY is intentionally excluded from the LLM provider chain
  // because it's used separately for Whisper transcription only.
  return _envValue('NVIDIA_API_KEY') ?? _envValue('OPENROUTER_API_KEY');
}

bool get isNvidia {
  final key = _getApiKey() ?? '';
  return key.startsWith('nvapi-');
}

bool get isOpenRouter {
  final key = _getApiKey() ?? '';
  return key.startsWith('sk-or-');
}

bool get isGroq {
  final key = _getApiKey() ?? '';
  return key.isNotEmpty && !key.startsWith('sk-or-') && !key.startsWith('nvapi-');
}

// ─── Lazy initialization — avoids top-level crash before main() runs ─────────
Genkit? _genkitInstance;

Genkit _createGenkit() {
  _loadDotEnv();

  final apiKey = _getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    throw StateError(
      'Missing required API key. Please set NVIDIA_API_KEY, GROQ_API_KEY or OPENROUTER_API_KEY in the environment.',
    );
  }

  final rawModel = _envValue('MODEL_ID') ?? _envValue('OPENROUTER_MODEL_ID');
  final defaultModel = (rawModel != null && rawModel.isNotEmpty && !rawModel.contains('llama-4-scout'))
      ? rawModel
      : (isNvidia
          ? 'meta/llama-3.3-70b-instruct'
          : (isOpenRouter ? 'deepseek/deepseek-v4-flash:free' : 'llama-3.3-70b-versatile'));

  final baseUrl = isNvidia
      ? 'https://integrate.api.nvidia.com/v1'
      : (isOpenRouter 
          ? 'https://openrouter.ai/api/v1' 
          : 'https://api.groq.com/openai/v1');

  print('[GenkitRuntime] Provider: ${isNvidia ? "NVIDIA" : (isOpenRouter ? "OpenRouter" : "Groq")}');
  print('[GenkitRuntime] Model: $defaultModel');
  print('[GenkitRuntime] Base URL: $baseUrl');

  // All known free models across providers
  final knownModels = <String>{
    // NVIDIA free models
    'meta/llama-3.3-70b-instruct',
    'meta/llama-3.1-70b-instruct',
    'meta/llama-3.1-8b-instruct',
    'meta/llama-4-maverick-17b-128e-instruct',
    'deepseek-ai/deepseek-v4-flash',
    'google/gemma-4-31b-it',
    'qwen/qwen3.5-122b-a10b',
    'nvidia/nemotron-3-super-120b-a12b',
    // OpenRouter free models
    'deepseek/deepseek-v4-flash:free',
    // Groq models
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  };

  // Always include the defaultModel
  knownModels.add(defaultModel);

  return Genkit(
    plugins: [
      openAI(
        apiKey: apiKey,
        baseUrl: baseUrl,
        models: knownModels.map((name) => CustomModelDefinition(
          name: name,
          info: ModelInfo(
            label: name,
            supports: {'multiturn': true, 'tools': true, 'systemRole': true},
          ),
        )).toList(),
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

String get modelId {
  final raw = _envValue('MODEL_ID') ?? _envValue('OPENROUTER_MODEL_ID');
  if (raw != null && raw.isNotEmpty && !raw.contains('llama-4-scout')) {
    return raw;
  }
  if (isNvidia) return 'meta/llama-3.3-70b-instruct';
  return isOpenRouter ? 'deepseek/deepseek-v4-flash:free' : (isGroq ? 'llama-3.3-70b-versatile' : 'gemini-1.5-flash');
}

String get aiProvider {
  if (isNvidia) return 'NVIDIA via OpenAI Plugin';
  if (isOpenRouter) return 'OpenRouter via OpenAI Plugin';
  return isGroq ? 'Groq via OpenAI Plugin' : 'Google GenAI SDK';
}

dynamic appModel([String? override]) {
  final String mId =
      (override == null || override.trim().isEmpty) ? modelId : override.trim();
  if (isNvidia || isOpenRouter || isGroq) {
    return openAI.model(mId);
  }
  return googleAI.gemini(mId);
}
