import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likh_ai/models/document_model.dart';
import 'package:likh_ai/models/ocr_response.dart';
import 'package:likh_ai/services/storage_service.dart';
import 'package:likh_ai/core/config/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DocumentModel Tests', () {
    test('serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final doc = DocumentModel(
        id: 'test_123',
        title: 'Physics Chapter 1 Notes',
        rawText: 'Speed = Dist / Time',
        cleanedText: 'Speed = Distance / Time',
        editedText: 'Speed = Distance / Time (Edited)',
        language: 'en',
        createdAt: now,
        updatedAt: now,
        confidence: 0.95,
      );

      final json = doc.toJson();
      final restored = DocumentModel.fromJson(json);

      expect(restored.id, 'test_123');
      expect(restored.title, 'Physics Chapter 1 Notes');
      expect(restored.rawText, 'Speed = Dist / Time');
      expect(restored.cleanedText, 'Speed = Distance / Time');
      expect(restored.editedText, 'Speed = Distance / Time (Edited)');
      expect(restored.confidence, 0.95);
      expect(restored.language, 'en');
    });

    test('copyWith works correctly', () {
      final doc = DocumentModel(
        id: '1',
        title: 'Original Title',
        rawText: 'Raw',
        cleanedText: 'Clean',
        editedText: 'Edited',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = doc.copyWith(title: 'New Title', editedText: 'New Content');
      expect(updated.title, 'New Title');
      expect(updated.editedText, 'New Content');
      expect(updated.id, '1');
    });
  });

  group('OcrResponse Tests', () {
    test('parses backend json response correctly', () {
      final json = {
        'success': true,
        'title': 'Test Meeting',
        'raw_text': 'Meeting at 10 AM',
        'cleaned_text': 'Meeting at 10:00 AM.',
        'language': 'en',
        'confidence': 0.98,
        'processing_time': 1.45,
        'warnings': ['Minor noise detected'],
        'original_image_url': 'http://127.0.0.1:8000/uploads/orig.png',
        'processed_image_url': 'http://127.0.0.1:8000/uploads/proc.png',
        'quality_score': 0.88,
        'passes_performed': 2,
        'low_confidence_segments': [
          {'text': 'Meeting', 'confidence': 0.55}
        ],
      };

      final response = OcrResponse.fromJson(json);
      expect(response.success, true);
      expect(response.title, 'Test Meeting');
      expect(response.rawText, 'Meeting at 10 AM');
      expect(response.cleanedText, 'Meeting at 10:00 AM.');
      expect(response.confidence, 0.98);
      expect(response.processingTime, 1.45);
      expect(response.warnings.length, 1);
      expect(response.qualityScore, 0.88);
      expect(response.passesPerformed, 2);
      expect(response.lowConfidenceSegments.length, 1);
      expect(response.lowConfidenceSegments.first.text, 'Meeting');
      expect(response.lowConfidenceSegments.first.confidence, 0.55);
      expect(response.originalImageUrl, 'http://127.0.0.1:8000/uploads/orig.png');
    });

    test('failure constructor sets success false', () {
      final response = OcrResponse.failure('Server down');
      expect(response.success, false);
      expect(response.error, 'Server down');
    });
  });

  group('StorageService Tests', () {
    test('save, retrieve, search, and delete documents', () async {
      final doc1 = DocumentModel(
        id: 'doc_1',
        title: 'Chemistry Lab Report',
        rawText: 'H2O test',
        cleanedText: 'H2O test report',
        editedText: 'H2O test report',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final doc2 = DocumentModel(
        id: 'doc_2',
        title: 'Grocery List',
        rawText: 'Milk, Eggs, Bread',
        cleanedText: 'Milk, Eggs, Bread',
        editedText: 'Milk, Eggs, Bread',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await StorageService.saveDocument(doc1);
      await StorageService.saveDocument(doc2);

      final allDocs = await StorageService.getDocuments();
      expect(allDocs.length, 2);

      // Search by title
      final searchResults = await StorageService.searchDocuments('Chemistry');
      expect(searchResults.length, 1);
      expect(searchResults.first.title, 'Chemistry Lab Report');

      // Search by content
      final contentResults = await StorageService.searchDocuments('Milk');
      expect(contentResults.length, 1);
      expect(contentResults.first.id, 'doc_2');

      // Delete
      await StorageService.deleteDocument('doc_1');
      final remaining = await StorageService.getDocuments();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'doc_2');
    });
  });

  group('ApiConfig Tests', () {
    test('sets and resets custom backend url', () async {
      await ApiConfig.setBaseUrl('http://192.168.1.50:8000');
      final custom = await ApiConfig.getBaseUrl();
      expect(custom, 'http://192.168.1.50:8000');

      await ApiConfig.resetBaseUrl();
      final def = await ApiConfig.getBaseUrl();
      expect(def, ApiConfig.defaultBaseUrl);
    });
  });
}
