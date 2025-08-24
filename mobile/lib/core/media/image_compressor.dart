import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  /// Compress to ~1280px and 60–80% quality. Returns JPEG bytes.
  static Future<Uint8List> compressFile(
      String path, {
        int minWidth = 1280,
        int minHeight = 1280,
        int quality = 70,
      }) async {
    final out = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (out == null) {
      throw Exception('Compression failed for $path');
    }
    return out;
  }
}
