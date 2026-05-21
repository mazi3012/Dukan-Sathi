import 'dart:io';
import 'dart:typed_data';

Future<File> savePdfFile(Uint8List bytes, String filename) async {
  final tempDir = await Directory.systemTemp.createTemp('dukansathi_invoice_');
  final file = File('${tempDir.path}/$filename.pdf');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
