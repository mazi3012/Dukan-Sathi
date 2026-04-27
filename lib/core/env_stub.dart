import 'package:dotenv/dotenv.dart';

abstract class EnvLoader {
  DotEnv load();
  String? get(String key);
}

EnvLoader getLoader() => throw UnsupportedError('Cannot create a loader without dart:html or dart:io');

