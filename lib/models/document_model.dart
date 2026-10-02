class DocumentModel {
  final String id;
  final String title;
  final String? originalImagePath;
  final String? processedImagePath;
  final String rawText;
  final String cleanedText;
  final String editedText;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String processingStatus; // 'completed', 'processing', 'failed'
  final double confidence;
  final double qualityScore;
  final List<String> lowConfidenceWords;

  DocumentModel({
    required this.id,
    required this.title,
    this.originalImagePath,
    this.processedImagePath,
    required this.rawText,
    required this.cleanedText,
    required this.editedText,
    this.language = 'en',
    required this.createdAt,
    required this.updatedAt,
    this.processingStatus = 'completed',
    this.confidence = 0.9,
    this.qualityScore = 1.0,
    this.lowConfidenceWords = const [],
  });

  DocumentModel copyWith({
    String? id,
    String? title,
    String? originalImagePath,
    String? processedImagePath,
    String? rawText,
    String? cleanedText,
    String? editedText,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? processingStatus,
    double? confidence,
    double? qualityScore,
    List<String>? lowConfidenceWords,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      rawText: rawText ?? this.rawText,
      cleanedText: cleanedText ?? this.cleanedText,
      editedText: editedText ?? this.editedText,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processingStatus: processingStatus ?? this.processingStatus,
      confidence: confidence ?? this.confidence,
      qualityScore: qualityScore ?? this.qualityScore,
      lowConfidenceWords: lowConfidenceWords ?? this.lowConfidenceWords,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalImagePath': originalImagePath,
      'processedImagePath': processedImagePath,
      'rawText': rawText,
      'cleanedText': cleanedText,
      'editedText': editedText,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'processingStatus': processingStatus,
      'confidence': confidence,
      'qualityScore': qualityScore,
      'lowConfidenceWords': lowConfidenceWords,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final rawWords = json['lowConfidenceWords'];
    final words = <String>[];
    if (rawWords is List) {
      for (final w in rawWords) {
        words.add(w.toString());
      }
    }

    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Document',
      originalImagePath: json['originalImagePath'] as String?,
      processedImagePath: json['processedImagePath'] as String?,
      rawText: json['rawText'] as String? ?? '',
      cleanedText: json['cleanedText'] as String? ?? '',
      editedText: json['editedText'] as String? ?? (json['cleanedText'] as String? ?? ''),
      language: json['language'] as String? ?? 'en',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      processingStatus: json['processingStatus'] as String? ?? 'completed',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 1.0,
      lowConfidenceWords: words,
    );
  }
}

