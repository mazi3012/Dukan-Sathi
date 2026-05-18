import 'dart:typed_data';
import 'pdf_file_helper_stub.dart'
    if (dart.library.io) 'pdf_file_helper_io.dart';

Future<dynamic> savePdfToTemp(Uint8List bytes, String filename) async {
  return savePdfFile(bytes, filename);
}
