import 'dart:typed_data';

/// Pure fallback stub that avoids compilation warnings on all platforms.
Future<dynamic> savePdfFile(Uint8List bytes, String filename) async {
  throw UnsupportedError('PDF file helper is not supported on this platform.');
}
