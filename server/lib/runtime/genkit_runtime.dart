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
  return _envValue('NVIDIA_API_KEY') ?? _envValue('OPENROUTER_API_KEY') ?? _envValue('GROQ_API_KEY');
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

  return Genkit(
    plugins: [
      openAI(
        apiKey: apiKey,
        baseUrl: baseUrl,
        models: [
          CustomModelDefinition(
            name: 'meta/llama-3.3-70b-instruct',
            info: ModelInfo(
              label: 'Llama 3.3 70B (Nvidia)',
              supports: {'multiturn': true, 'tools': true, 'systemRole': true},
            ),
          ),
          CustomModelDefinition(
            name: 'deepseek/deepseek-v4-flash:free',
            info: ModelInfo(
              label: 'DeepSeek V4 Flash (Free)',
              supports: {'multiturn': true, 'tools': true, 'systemRole': true},
            ),
          ),
          CustomModelDefinition(
            name: 'llama-3.3-70b-versatile',
            info: ModelInfo(
              label: 'Llama 3.3 70B',
              supports: {'multiturn': true, 'tools': true, 'systemRole': true},
            ),
          ),
          CustomModelDefinition(
            name: 'llama-3.1-8b-instant',
            info: ModelInfo(
              label: 'Llama 3.1 8B',
              supports: {'multiturn': true, 'tools': true, 'systemRole': true},
            ),
          ),
          if (defaultModel != 'llama-3.3-70b-versatile' && 
              defaultModel != 'llama-3.1-8b-instant' && 
              defaultModel != 'deepseek/deepseek-v4-flash:free' &&
              defaultModel != 'meta/llama-3.3-70b-instruct')
            CustomModelDefinition(
              name: defaultModel,
              info: ModelInfo(
                label: 'Custom OpenAI Model',
                supports: {'multiturn': true, 'tools': true, 'systemRole': true},
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
