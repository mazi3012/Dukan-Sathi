import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

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

Genkit _createGenkit() {
	if (File('.env').existsSync()) {
		_env.load(['.env']);
	}

	final apiKey = _envValue('GOOGLE_API_KEY') ?? _envValue('GEMINI_API_KEY');
	if (apiKey == null || apiKey.isEmpty) {
		throw StateError(
			'Google GenAI SDK requires GOOGLE_API_KEY or GEMINI_API_KEY.',
		);
	}

	return Genkit(
		plugins: [
			googleAI(apiKey: apiKey),
		],
	);
}

final Genkit ai = _createGenkit();
final String modelId =
	_envValue('MODEL_ID') ?? 'gemini-3.1-flash-lite-preview';
final String aiProvider = 'Google GenAI SDK';

dynamic appModel([String? override]) {
	return googleAI.gemini((override == null || override.trim().isEmpty)
			? modelId
			: override.trim());
}
