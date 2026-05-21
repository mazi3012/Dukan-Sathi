import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_openai/genkit_openai.dart';

final DotEnv _env = DotEnv(includePlatformEnvironment: true);

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

Genkit _createGenkit() {
	if (File('.env').existsSync()) {
		_env.load(['.env']);
	}

	final groqApiKey = _envValue('GROQ_API_KEY');
	if (groqApiKey != null && groqApiKey.isNotEmpty) {
		final defaultModel = _envValue('MODEL_ID') ?? 'meta-llama/llama-4-scout-17b-16e-instruct';
		return Genkit(
			plugins: [
				openAI(
					apiKey: groqApiKey,
					baseUrl: 'https://api.groq.com/openai/v1',
					models: [CustomModelDefinition(name: defaultModel)],
				),
			],
		);
	}

	final apiKey = _envValue('GOOGLE_API_KEY') ?? _envValue('GEMINI_API_KEY');
	if (apiKey == null || apiKey.isEmpty) {
		throw StateError(
			'Missing required API key. Please set GROQ_API_KEY, GOOGLE_API_KEY or GEMINI_API_KEY.',
		);
	}

	return Genkit(
		plugins: [
			googleAI(apiKey: apiKey),
		],
	);
}

final Genkit ai = _createGenkit();
final bool isGroq = _envValue('GROQ_API_KEY') != null;
final String modelId =
	_envValue('MODEL_ID') ?? (isGroq ? 'meta-llama/llama-4-scout-17b-16e-instruct' : 'gemini-3.1-flash-lite-preview');
final String aiProvider = isGroq ? 'Groq via OpenAI Plugin' : 'Google GenAI SDK';

dynamic appModel([String? override]) {
	final String mId = (override == null || override.trim().isEmpty) ? modelId : override.trim();
	if (isGroq) {
		return openAI.model(mId);
	}
	return googleAI.gemini(mId);
}
