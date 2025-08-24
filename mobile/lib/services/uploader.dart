import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as p;
import '../services/api_client.dart';
import '../core/media/image_compressor.dart';

class Uploader {
  final Dio _dio = ApiClient().dio;

  Future<void> uploadImageForCrop(
      String filePath,
      int cropId, {
        bool isMain = false,
        void Function(int sent, int total)? onProgress,
      }) async {
    // compress on-device
    final Uint8List bytes = await ImageCompressor.compressFile(
      filePath,
      minWidth: 1280,
      minHeight: 1280,
      quality: 70,
    );

    final fileName = p.basename(filePath).replaceAll(
      RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false),
      '.jpg',
    );

    final form = FormData.fromMap({
      'crop_id': cropId.toString(),
      'is_main': isMain.toString(), // FastAPI Form(bool) accepts "true"/"false"
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    await _dio.post('/media/upload', data: form, onSendProgress: onProgress);
  }
}
