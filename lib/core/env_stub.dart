abstract class EnvLoader {
  dynamic load();
  String? get(String key);
}

EnvLoader getLoader() => throw UnsupportedError('Cannot create a loader without dart:html or dart:io');
