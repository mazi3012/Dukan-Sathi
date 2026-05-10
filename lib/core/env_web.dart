import 'env_stub.dart';

class EnvLoaderImpl implements EnvLoader {
  @override
  dynamic load() => null;

  @override
  String? get(String key) => null;
}

EnvLoader getLoader() => EnvLoaderImpl();
