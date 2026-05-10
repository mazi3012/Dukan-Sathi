import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'env_stub.dart';

class EnvLoaderImpl implements EnvLoader {
  final DotEnv _env = DotEnv(includePlatformEnvironment: true);

  @override
  dynamic load() {
    if (File('.env').existsSync()) {
      _env.load(['.env']);
    }
    return _env;
  }

  @override
  String? get(String key) => _env[key];
}

EnvLoader getLoader() => EnvLoaderImpl();
