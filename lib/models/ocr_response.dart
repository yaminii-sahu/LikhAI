class LowConfidenceSegment {
  final String text;
  final double confidence;
  final List<dynamic>? box;

  LowConfidenceSegment({
    required this.text,
    required this.confidence,
    this.box,
  });

  factory LowConfidenceSegment.fromJson(Map<String, dynamic> json) {
    return LowConfidenceSegment(
      text: json['text'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      box: json['box'] as List<dynamic>?,
    );
  }
}

class OcrResponse {
  final bool success;
  final String title;
  final String rawText;
  final String cleanedText;
  final String language;
  final double confidence;
  final double processingTime;
  final List<String> warnings;
  final String? originalImageUrl;
  final String? processedImageUrl;
  final String? error;
  final String? cleanupMethod;
  final double qualityScore;
  final int passesPerformed;
  final List<LowConfidenceSegment> lowConfidenceSegments;

  OcrResponse({
    required this.success,
    this.title = '',
    this.rawText = '',
    this.cleanedText = '',
    this.language = 'en',
    this.confidence = 0.0,
    this.processingTime = 0.0,
    this.warnings = const [],
    this.originalImageUrl,
    this.processedImageUrl,
    this.error,
    this.cleanupMethod,
    this.qualityScore = 1.0,
    this.passesPerformed = 1,
    this.lowConfidenceSegments = const [],
  });

  factory OcrResponse.fromJson(Map<String, dynamic> json) {
    final rawWarns = json['warnings'];
    final warningsList = <String>[];
    if (rawWarns is List) {
      for (final w in rawWarns) {
        warningsList.add(w.toString());
      }
    }

    final rawSegments = json['low_confidence_segments'];
    final segmentsList = <LowConfidenceSegment>[];
    if (rawSegments is List) {
      for (final s in rawSegments) {
        if (s is Map<String, dynamic>) {
          segmentsList.add(LowConfidenceSegment.fromJson(s));
        }
      }
    }

    return OcrResponse(
      success: json['success'] as bool? ?? (json['status'] == 'success'),
      title: json['title'] as String? ?? '',
      rawText: json['raw_text'] as String? ?? (json['ocr_text'] as String? ?? ''),
      cleanedText: json['cleaned_text'] as String? ?? (json['text'] as String? ?? ''),
      language: json['language'] as String? ?? 'en',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      processingTime: (json['processing_time'] as num?)?.toDouble() ?? 0.0,
      warnings: warningsList,
      originalImageUrl: json['original_image_url'] as String?,
      processedImageUrl: json['processed_image_url'] as String?,
      error: json['error'] as String? ?? json['message'] as String?,
      cleanupMethod: json['cleanup_method'] as String?,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 1.0,
      passesPerformed: (json['passes_performed'] as num?)?.toInt() ?? 1,
      lowConfidenceSegments: segmentsList,
    );
  }

  factory OcrResponse.failure(String message) {
    return OcrResponse(
      success: false,
      error: message,
    );
  }
}

