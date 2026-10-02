import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/config/api_config.dart';
import '../core/utils/image_optimizer.dart';
import '../models/ocr_response.dart';

class ApiService {
  /// Uploads and digitizes an image using the FastAPI backend with safe mobile optimization,
  /// dev-only benchmark logging, and cancellation capability.
  static Future<OcrResponse> processHandwritingImage({
    required XFile image,
    String language = 'auto',
    String? title,
    bool preprocess = true,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final clientStartTime = DateTime.now();

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl/process');

      // 1. Optimize working copy for OCR upload without modifying original file
      final prepStartTime = DateTime.now();
      final uploadBytes = await ImageOptimizer.prepareWorkingBytesForOcr(image);
      final prepTimeSec = DateTime.now().difference(prepStartTime).inMilliseconds / 1000.0;

      if (uploadBytes.isEmpty) {
        return OcrResponse.failure('Image file is empty or unreadable.');
      }

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          uploadBytes,
          filename: image.name.isNotEmpty ? image.name : 'handwritten_note.jpg',
        ),
      );

      request.fields['language'] = language;
      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }
      request.fields['preprocess'] = preprocess.toString();

      // 2. Stream multipart request with stage timeout (75 seconds)
      final uploadStartTime = DateTime.now();
      debugPrint('[LIKH OCR] Upload started to $uri (${(uploadBytes.length / 1024).toStringAsFixed(1)} KB)...');

      final streamedResponse = await httpClient.send(request).timeout(
        const Duration(seconds: 75),
        onTimeout: () {
          throw TimeoutException('Request timed out while processing image.');
        },
      );

      final uploadDurationSec = DateTime.now().difference(uploadStartTime).inMilliseconds / 1000.0;
      final responseBody = await streamedResponse.stream.bytesToString();
      final totalClientSec = DateTime.now().difference(clientStartTime).inMilliseconds / 1000.0;

      debugPrint('[LIKH OCR Benchmark]');
      debugPrint(' - Client Preparation: ${prepTimeSec.toStringAsFixed(2)}s');
      debugPrint(' - Upload & Inference: ${uploadDurationSec.toStringAsFixed(2)}s');
      debugPrint(' - Total Client Time:  ${totalClientSec.toStringAsFixed(2)}s');

      if (streamedResponse.statusCode != 200) {
        try {
          final errJson = jsonDecode(responseBody);
          final serverError = errJson['message'] ?? errJson['error'];
          if (serverError != null && serverError.toString().isNotEmpty) {
            return OcrResponse.failure(serverError.toString());
          }
        } catch (_) {}

        return OcrResponse.failure(
          'Unable to process handwriting right now. Please try again.',
        );
      }

      final Map<String, dynamic> data = jsonDecode(responseBody);
      final response = OcrResponse.fromJson(data);

      if (response.success) {
        debugPrint('[LIKH OCR Benchmark] Server reported: ${response.processingTime.toStringAsFixed(2)}s server time');
      }

      return response;
    } on TimeoutException {
      return OcrResponse.failure(
        'Processing timed out. The handwriting recognition service took too long to respond.',
      );
    } on http.ClientException catch (e) {
      debugPrint('[LIKH OCR Error] Connection failure: $e');
      return OcrResponse.failure(
        'Unable to connect to the handwriting service. Please check your network and verify the backend is online.',
      );
    } catch (e) {
      debugPrint('[LIKH OCR Error] Unexpected exception: $e');
      return OcrResponse.failure(
        'Unable to process handwriting right now. Please try again.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Pings backend health
  static Future<bool> isServerOnline() async {
    return await ApiConfig.testConnection();
  }
}
