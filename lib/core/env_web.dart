import 'package:dotenv/dotenv.dart';
import 'env_stub.dart';

class EnvLoaderImpl implements EnvLoader {
  final DotEnv _env = DotEnv(includePlatformEnvironment: false);

  @override
  DotEnv load() => _env;

  @override
  String? get(String key) => _env[key];
}

EnvLoader getLoader() => EnvLoaderImpl();
