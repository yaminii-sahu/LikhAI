import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageOptimizer {
  /// Maximum dimension (width or height) for OCR image processing copy.
  /// 1920px retains razor-sharp handwriting ink strokes while preventing
  /// multi-megabyte payloads from freezing network transmission and OCR inference.
  static const int maxOcrDimension = 1920;

  /// Optimizes a mobile photo specifically for OCR upload.
  /// The original image on disk is NEVER overwritten or altered.
  static Future<Uint8List> prepareWorkingBytesForOcr(XFile file) async {
    final rawBytes = await file.readAsBytes();
    if (rawBytes.isEmpty) return rawBytes;

    // If image is already reasonably lightweight (< 1.5 MB), skip client re-encoding
    if (rawBytes.length < 1500 * 1024) {
      if (kDebugMode) {
        print('[ImageOptimizer] Working copy size: ${(rawBytes.length / 1024).toStringAsFixed(1)} KB (optimal)');
      }
      return rawBytes;
    }

    try {
      final startTime = DateTime.now();
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: maxOcrDimension,
      );
      final frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return rawBytes;
      }

      final optimized = byteData.buffer.asUint8List();
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      if (kDebugMode) {
        final origMb = (rawBytes.length / (1024 * 1024)).toStringAsFixed(2);
        final optKb = (optimized.length / 1024).toStringAsFixed(1);
        print('[ImageOptimizer] Optimized working copy: ${origMb}MB -> ${optKb}KB in ${durationMs}ms');
      }

      return optimized;
    } catch (e) {
      if (kDebugMode) {
        print('[ImageOptimizer] Notice: Downscale fallback to raw bytes: $e');
      }
      return rawBytes;
    }
  }
}
