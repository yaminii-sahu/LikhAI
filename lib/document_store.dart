// Compatibility bridge for older references to DocumentStore
import 'models/document_model.dart';
import 'services/storage_service.dart';

export 'models/document_model.dart';
export 'services/storage_service.dart';

class DocumentStore {
  static Future<List<DocumentModel>> get documents => StorageService.getDocuments();

  static Future<void> loadDocuments() async {
    await StorageService.getDocuments();
  }

  static Future<void> addDocument(DocumentModel document) async {
    await StorageService.saveDocument(document);
  }

  static Future<void> deleteDocument(String id) async {
    await StorageService.deleteDocument(id);
  }
}