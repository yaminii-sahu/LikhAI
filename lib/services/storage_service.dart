import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';

class StorageService {
  static const String _documentsKey = 'likh_ai_documents_v2';
  static const String _themeKey = 'app_theme_mode';
  static const String _langKey = 'app_language';
  static const String _autoSaveKey = 'auto_save_docs';
  static const String _aiSuggestionsKey = 'ai_suggestions_enabled';

  // In-memory cache for fast responsive access
  static List<DocumentModel> _cache = [];
  static bool _isLoaded = false;

  /// Loads all stored documents from persistent SharedPreferences
  static Future<List<DocumentModel>> getDocuments() async {
    if (_isLoaded) {
      return List.unmodifiable(_cache);
    }

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_documentsKey) ?? [];

    _cache = [];
    for (final item in rawList) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        _cache.add(DocumentModel.fromJson(map));
      } catch (e) {
        debugPrint('[StorageService] Error parsing document entry: $e');
      }
    }

    _cache.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _isLoaded = true;
    return List.unmodifiable(_cache);
  }

  /// Search stored documents by query
  static Future<List<DocumentModel>> searchDocuments(String query) async {
    final docs = await getDocuments();
    if (query.trim().isEmpty) return docs;
    final q = query.trim().toLowerCase();
    return docs.where((d) {
      return d.title.toLowerCase().contains(q) ||
          d.editedText.toLowerCase().contains(q) ||
          d.rawText.toLowerCase().contains(q);
    }).toList();
  }

  /// Save or add a new document
  static Future<void> saveDocument(DocumentModel document) async {
    await getDocuments();
    final index = _cache.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      _cache[index] = document;
    } else {
      _cache.insert(0, document);
    }
    await _persist();
  }

  /// Update an existing document
  static Future<void> updateDocument(DocumentModel document) async {
    await saveDocument(document);
  }

  /// Delete document by ID and clean up local image files to avoid orphan files
  static Future<void> deleteDocument(String id) async {
    await getDocuments();
    final docIndex = _cache.indexWhere((d) => d.id == id);
    if (docIndex >= 0) {
      final doc = _cache[docIndex];
      // Clean up files if not on web
      if (!kIsWeb) {
        if (doc.originalImagePath != null) {
          _safeDeleteFile(doc.originalImagePath!);
        }
        if (doc.processedImagePath != null) {
          _safeDeleteFile(doc.processedImagePath!);
        }
      }
      _cache.removeAt(docIndex);
      await _persist();
    }
  }

  /// Clear all saved documents and local files
  static Future<void> clearAll() async {
    await getDocuments();
    if (!kIsWeb) {
      for (final doc in _cache) {
        if (doc.originalImagePath != null) {
          _safeDeleteFile(doc.originalImagePath!);
        }
        if (doc.processedImagePath != null) {
          _safeDeleteFile(doc.processedImagePath!);
        }
      }
    }
    _cache.clear();
    await _persist();
  }

  static void _safeDeleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _cache.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_documentsKey, encoded);
  }

  // --- Settings Persistence ---

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'English';
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  static Future<bool> getAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSaveKey) ?? true;
  }

  static Future<void> setAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, value);
  }

  static Future<bool> getAiSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiSuggestionsKey) ?? true;
  }

  static Future<void> setAiSuggestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiSuggestionsKey, value);
  }
}
