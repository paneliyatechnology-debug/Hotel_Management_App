import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Shrinks ID / signature photos before multipart upload.
/// Phone camera and document scans are often several MB; the API (and nginx)
/// reject those with HTTP 413 while the website already sends smaller JPEGs.
class UploadImageCompressor {
  UploadImageCompressor._();

  static const int maxSide = 1280;
  static const int targetBytes = 180 * 1024;
  static const int minQuality = 40;
  static const int startQuality = 72;

  /// Returns JPEG bytes, or `null` when [bytes] cannot be decoded (caller keeps original).
  static Uint8List? toUploadJpeg(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        return null;
      }

      img.Image frame = img.bakeOrientation(decoded);
      final longest = frame.width > frame.height ? frame.width : frame.height;
      if (longest > maxSide) {
        if (frame.width >= frame.height) {
          frame = img.copyResize(
            frame,
            width: maxSide,
            interpolation: img.Interpolation.average,
          );
        } else {
          frame = img.copyResize(
            frame,
            height: maxSide,
            interpolation: img.Interpolation.average,
          );
        }
      }

      var quality = startQuality;
      var out = Uint8List.fromList(img.encodeJpg(frame, quality: quality));
      while (out.length > targetBytes && quality > minQuality) {
        quality -= 8;
        out = Uint8List.fromList(img.encodeJpg(frame, quality: quality));
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}
