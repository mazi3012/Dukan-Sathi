import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _apiUrlKey = 'ds_api_url_override';
  static const String defaultProdUrl = 'https://dukan-sathi-pro.onrender.com';
  static const String defaultDevUrl = 'http://localhost:3100';

  static String _currentApiUrl = kDebugMode ? defaultDevUrl : defaultProdUrl;

  static String get apiUrl => _currentApiUrl;

  /// Initializes the config by reading from SharedPreferences or dart environment defines.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_apiUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _currentApiUrl = savedUrl;
        debugPrint('[AppConfig] Using saved API URL override: $_currentApiUrl');
        return;
      }
    } catch (e) {
      debugPrint('[AppConfig] Error reading saved API URL: $e');
    }

    const envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      _currentApiUrl = envUrl;
      debugPrint('[AppConfig] Using --dart-define API URL: $_currentApiUrl');
      return;
    }

    _currentApiUrl = kDebugMode ? defaultDevUrl : defaultProdUrl;
    debugPrint('[AppConfig] Using default API URL: $_currentApiUrl');
  }

  /// Sets and persists a custom API URL override.
  static Future<void> setApiUrl(String url) async {
    _currentApiUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url.isEmpty) {
        await prefs.remove(_apiUrlKey);
      } else {
        await prefs.setString(_apiUrlKey, url);
      }
      debugPrint('[AppConfig] Updated saved API URL override to: $_currentApiUrl');
    } catch (e) {
      debugPrint('[AppConfig] Error saving API URL: $e');
    }
  }

  /// Resolves the API path with the current configured base URL.
  static Uri getApiUri(String path) {
    if (kIsWeb) {
      final baseUri = Uri.base;
      if (baseUri.host == 'localhost' || baseUri.host == '127.0.0.1') {
        return Uri.parse('http://localhost:3100').resolve(path);
      }
      return baseUri.resolve(path);
    }
    
    return Uri.parse(_currentApiUrl).resolve(path);
  }
}
