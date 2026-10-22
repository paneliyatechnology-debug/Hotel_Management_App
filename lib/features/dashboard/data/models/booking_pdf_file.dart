import 'dart:typed_data';

class BookingPdfFile {
  final Uint8List bytes;
  final String fileName;
  final String url;

  const BookingPdfFile({
    required this.bytes,
    required this.fileName,
    required this.url,
  });
}
