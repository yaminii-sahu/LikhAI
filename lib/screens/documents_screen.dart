import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import 'editor_screen.dart';
import 'pdf_preview_screen.dart';
import 'document_detail_screen.dart';
import 'new_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final String language;

  const DocumentsScreen({
    super.key,
    required this.language,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final docs = await StorageService.getDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        _applySearch();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _applySearch();
    });
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredDocs = List.from(_documents);
    } else {
      _filteredDocs = _documents.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.editedText.toLowerCase().contains(q) ||
            d.rawText.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _deleteDoc(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.text(widget.language, 'Delete Document', 'दस्तावेज़ हटाएं')),
        content: Text(
          AppLocale.text(
            widget.language,
            'Are you sure you want to permanently delete "${doc.title}"?',
            'क्या आप वास्तव में "${doc.title}" को स्थायी रूप से हटाना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocale.text(widget.language, 'Cancel', 'रद्द करें')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocale.text(widget.language, 'Delete', 'हटाएं')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteDocument(doc.id);
      await _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.text(widget.language, 'Documents', 'दस्तावेज़'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocale.text(
                    widget.language,
                    'Search documents by title or text...',
                    'शीर्षक या टेक्स्ट द्वारा दस्तावेज़ खोजें...',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

            // Document Count
            if (!_isLoading && _documents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filteredDocs.length} ${AppLocale.text(widget.language, 'documents', 'दस्तावेज़')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Document List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDocs.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadDocuments,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: EmptyState(
                              icon: Icons.description_outlined,
                              title: _documents.isEmpty
                                  ? AppLocale.text(
                                      widget.language,
                                      'No saved documents',
                                      'कोई सहेजे गए दस्तावेज़ नहीं',
                                    )
                                  : AppLocale.text(
                                      widget.language,
                                      'No results match your search',
                                      'आपकी खोज से कोई परिणाम नहीं मिला',
                                    ),
                              message: _documents.isEmpty
                                  ? AppLocale.text(
                                      widget.language,
                                      'Digitize your first handwritten note to see it here.',
                                      'यहाँ देखने के लिए अपना पहला हस्तलिखित नोट डिजिटाइज़ करें।',
                                    )
                                  : AppLocale.text(
                                      widget.language,
                                      'Try a different title or keyword.',
                                      'एक अलग शीर्षक या कीवर्ड का प्रयास करें।',
                                    ),
                              buttonLabel: _documents.isEmpty
                                  ? AppLocale.text(
                                      widget.language,
                                      'New Document',
                                      'नया दस्तावेज़',
                                    )
                                  : null,
                              onAction: _documents.isEmpty
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => NewDocumentScreen(
                                            language: widget.language,
                                          ),
                                        ),
                                      ).then((_) => _loadDocuments());
                                    }
                                  : null,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDocuments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = _filteredDocs[index];
                              return DocumentCard(
                                document: doc,
                                language: widget.language,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DocumentDetailScreen(
                                        document: doc,
                                        language: widget.language,
                                      ),
                                    ),
                                  ).then((_) => _loadDocuments());
                                },
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditorScreen(
                                        document: doc,
                                        language: widget.language,
                                      ),
                                    ),
                                  ).then((_) => _loadDocuments());
                                },
                                onPdf: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfPreviewScreen(
                                        document: doc,
                                        language: widget.language,
                                      ),
                                    ),
                                  );
                                },
                                onDelete: () => _deleteDoc(doc),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
