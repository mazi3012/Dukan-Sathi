import 'dart:io';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_vertexai/genkit_vertexai.dart';

final DotEnv _env = DotEnv(includePlatformEnvironment: true);

bool _isLikelyManagedGcpRuntime() {
	const managedEnvKeys = [
		'K_SERVICE',
		'FUNCTION_TARGET',
		'GAE_SERVICE',
		'GCE_METADATA_HOST',
	];

	for (final key in managedEnvKeys) {
		final value = Platform.environment[key];
		if (value != null && value.trim().isNotEmpty) {
			return true;
		}
	}

	return false;
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

Genkit _createGenkit() {
	if (File('.env').existsSync()) {
		_env.load(['.env']);
	}

	final projectId = _envValue('GCLOUD_PROJECT') ??
		_envValue('GOOGLE_CLOUD_PROJECT') ??
		(() {
			final credentialsPath = _envValue('GOOGLE_APPLICATION_CREDENTIALS');
			if (credentialsPath == null) {
				return null;
			}
			final credentialsFile = File(credentialsPath);
			if (!credentialsFile.existsSync()) {
				return null;
			}
			try {
				final credentialsJson = jsonDecode(credentialsFile.readAsStringSync());
				if (credentialsJson is Map<String, dynamic>) {
					final value = credentialsJson['project_id'];
					if (value is String && value.trim().isNotEmpty) {
						return value.trim();
					}
				}
			} catch (_) {
				return null;
			}
			return null;
		}());

	if (projectId == null || projectId.isEmpty) {
		throw StateError(
			'Vertex AI requires GCLOUD_PROJECT, GOOGLE_CLOUD_PROJECT, or a GOOGLE_APPLICATION_CREDENTIALS file containing project_id.',
		);
	}

	final credentialsPath = _envValue('GOOGLE_APPLICATION_CREDENTIALS');
	if (!_isLikelyManagedGcpRuntime()) {
		if (credentialsPath == null || credentialsPath.isEmpty) {
			throw StateError(
				'Local runtime detected. Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON path to avoid metadata.google.internal auth failures.',
			);
		}

		if (!File(credentialsPath).existsSync()) {
			throw StateError(
				'GOOGLE_APPLICATION_CREDENTIALS points to a missing file: $credentialsPath',
			);
		}
	}

	return Genkit(
		plugins: [
			vertexAI(
				projectId: projectId,
				location: _envValue('GCLOUD_LOCATION') ?? 'us-central1',
			),
		],
	);
}

final Genkit ai = _createGenkit();
