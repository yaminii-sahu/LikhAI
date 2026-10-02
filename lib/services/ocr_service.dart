import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import '../models/ocr_response.dart';

class OcrService {
  static Future<OcrResponse> processImage(
    XFile image, {
    String language = 'auto',
    String? title,
  }) async {
    return await ApiService.processHandwritingImage(
      image: image,
      language: language,
      title: title,
    );
  }
}