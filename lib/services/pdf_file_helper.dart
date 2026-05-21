import 'dart:typed_data';
// Conditional import: dart:html is only available on Web, dart:io on native
import 'pdf_file_helper_stub.dart'
    if (dart.library.io) 'pdf_file_helper_io.dart'
    if (dart.library.html) 'pdf_file_helper_web.dart';

/// Saves or triggers download of a PDF file.
/// - On Mobile/Desktop: writes to a temp file and returns the File.
/// - On Web: triggers browser download and returns null.
Future<dynamic> savePdfToTemp(Uint8List bytes, String filename) async {
  return savePdfFile(bytes, filename);
}
