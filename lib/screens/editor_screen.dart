import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../widgets/likh_components.dart';
import 'pdf_preview_screen.dart';

class EditorScreen extends StatefulWidget {
  final String language;
  final DocumentModel document;

  const EditorScreen({
    super.key,
    required this.language,
    required this.document,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  late TabController _tabController;
  late DocumentModel _currentDoc;

  bool _hasUnsavedChanges = false;
  final List<String> _undoHistory = [];
  int _historyIndex = -1;
  bool _showProcessedImage = false;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.document;
    _titleController = TextEditingController(text: _currentDoc.title);
    _textController = TextEditingController(text: _currentDoc.editedText);
    _tabController = TabController(length: 3, vsync: this);

    _pushHistory(_currentDoc.editedText);

    _textController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() => _hasUnsavedChanges = true);
      }
    });

    _titleController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() => _hasUnsavedChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _pushHistory(String text) {
    if (_historyIndex >= 0 && _historyIndex < _undoHistory.length - 1) {
      _undoHistory.removeRange(_historyIndex + 1, _undoHistory.length);
    }
    _undoHistory.add(text);
    _historyIndex = _undoHistory.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _textController.text = _undoHistory[_historyIndex];
    }
  }

  void _redo() {
    if (_historyIndex < _undoHistory.length - 1) {
      _historyIndex++;
      _textController.text = _undoHistory[_historyIndex];
    }
  }

  Future<void> _saveDocument() async {
    final updated = _currentDoc.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Untitled Document',
      editedText: _textController.text,
      updatedAt: DateTime.now(),
    );

    await StorageService.saveDocument(updated);

    if (mounted) {
      setState(() {
        _currentDoc = updated;
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.text(
              widget.language,
              'Document saved successfully ✓',
              'दस्तावेज़ सफलतापूर्वक सहेजा गया ✓',
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocale.text(
            widget.language,
            'Copied to clipboard',
            'क्लिपबोर्ड पर कॉपी किया गया',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      final current = _textController.text;
      final sel = _textController.selection;
      String newText;
      if (sel.isValid) {
        newText = current.replaceRange(sel.start, sel.end, data.text!);
      } else {
        newText = current + data.text!;
      }
      _textController.text = newText;
      _pushHistory(newText);
    }
  }

  void _selectWordInEditor(String word) {
    final text = _textController.text;
    final index = text.toLowerCase().indexOf(word.toLowerCase());
    if (index != -1) {
      _textController.selection = TextSelection(
        baseOffset: index,
        extentOffset: index + word.length,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected "$word" in editor'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  void _openPdfPreview() async {
    final updated = _currentDoc.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Untitled Document',
      editedText: _textController.text,
      updatedAt: DateTime.now(),
    );
    await StorageService.saveDocument(updated);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            document: updated,
            language: widget.language,
          ),
        ),
      );
    }
  }

  int get _wordCount {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Widget _buildImageWidget(String? path) {
    if (path == null || path.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              AppLocale.text(
                widget.language,
                'No handwriting image available',
                'कोई हस्तलिखित छवि उपलब्ध नहीं है',
              ),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
        ),
      );
    }

    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
          ),
        );
      }
    }

    return const Center(
      child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
    );
  }

  Widget _buildImageViewerPanel(bool isDark) {
    final currentPath = _showProcessedImage && _currentDoc.processedImagePath != null
        ? _currentDoc.processedImagePath
        : _currentDoc.originalImagePath;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Interactive Zoom/Pan area
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 4.0,
                minScale: 0.8,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildImageWidget(currentPath),
                  ),
                ),
              ),
            ),
            // Floating controls top right
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black87 : Colors.white).withAlpha(220),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentDoc.processedImagePath != null) ...[
                      Text(
                        _showProcessedImage ? 'Processed' : 'Original',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _showProcessedImage,
                        onChanged: (val) {
                          setState(() => _showProcessedImage = val);
                        },
                      ),
                    ] else
                      const Text(
                        'Original Note',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            // Floating hint bottom
            Positioned(
              bottom: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch_rounded, size: 12, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      'Pinch / Scroll to zoom',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowConfidenceWordBar() {
    final words = _currentDoc.lowConfidenceWords;
    if (words.isEmpty && _currentDoc.confidence >= 0.75) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                AppLocale.text(
                  widget.language,
                  'Review uncertain words from messy handwriting:',
                  'कठिन हस्तलेखन के अनिश्चित शब्दों की समीक्षा करें:',
                ),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          if (words.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: words.take(12).map((w) {
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    w,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  avatar: const Icon(Icons.search, size: 12),
                  onPressed: () => _selectWordInEditor(w),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final String label;
    final Color badgeColor;
    final IconData badgeIcon;

    if (confidence >= 0.88) {
      label = AppLocale.text(widget.language, 'High Confidence', 'उच्च सटीकता');
      badgeColor = AppColors.success;
      badgeIcon = Icons.verified_rounded;
    } else if (confidence >= 0.70) {
      label = AppLocale.text(widget.language, 'Medium Confidence', 'मध्यम सटीकता');
      badgeColor = AppColors.primary;
      badgeIcon = Icons.check_circle_outline_rounded;
    } else {
      label = AppLocale.text(widget.language, 'Review Needed', 'समीक्षा आवश्यक');
      badgeColor = AppColors.warning;
      badgeIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 13, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: AppLocale.text(
                      widget.language,
                      'Document Title...',
                      'दस्तावेज़ शीर्षक...',
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Authentic Confidence badge (High, Medium, Review Needed)
              _buildConfidenceBadge(_currentDoc.confidence),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$_wordCount ${AppLocale.text(widget.language, 'words', 'शब्द')}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  ${_textController.text.length} ${AppLocale.text(widget.language, 'chars', 'अक्षर')}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  ${_currentDoc.language.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasUnsavedChanges)
                Text(
                  AppLocale.text(widget.language, 'Unsaved changes', 'असहेजे गए परिवर्तन'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorField() {
    return Column(
      children: [
        // Quick Action Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => _copyToClipboard(_textController.text),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: Text(AppLocale.text(widget.language, 'Copy', 'कॉपी')),
              ),
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste_rounded, size: 15),
                label: Text(AppLocale.text(widget.language, 'Paste', 'पेस्ट')),
              ),
              TextButton.icon(
                onPressed: () {
                  _textController.clear();
                  _pushHistory('');
                },
                icon: const Icon(Icons.clear_all_rounded, size: 15),
                label: Text(AppLocale.text(widget.language, 'Clear', 'साफ़')),
              ),
              const Spacer(),
              IconButton(
                tooltip: AppLocale.text(widget.language, 'Undo', 'पूर्ववत'),
                icon: const Icon(Icons.undo_rounded, size: 18),
                onPressed: _historyIndex > 0 ? _undo : null,
              ),
              IconButton(
                tooltip: AppLocale.text(widget.language, 'Redo', 'पुनः करें'),
                icon: const Icon(Icons.redo_rounded, size: 18),
                onPressed: _historyIndex < _undoHistory.length - 1 ? _redo : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 15, height: 1.6),
              decoration: InputDecoration(
                hintText: AppLocale.text(
                  widget.language,
                  'Type or edit digitized text here...',
                  'यहाँ डिजिटाइज़ किए गए टेक्स्ट को टाइप या संपादित करें...',
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawOcrTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocale.text(
                  widget.language,
                  'Raw Unedited OCR Result',
                  'असंपादित मूल OCR परिणाम',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(_currentDoc.rawText),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(AppLocale.text(widget.language, 'Copy', 'कॉपी')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _currentDoc.rawText.isNotEmpty
                      ? _currentDoc.rawText
                      : AppLocale.text(
                          widget.language,
                          'No raw OCR text available.',
                          'कोई मूल OCR टेक्स्ट उपलब्ध नहीं है।',
                        ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: LikhButton(
              variant: LikhButtonVariant.outline,
              onPressed: _saveDocument,
              icon: Icons.save_rounded,
              label: AppLocale.text(widget.language, 'Save Document', 'दस्तावेज़ सहेजें'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LikhButton(
              onPressed: _openPdfPreview,
              icon: Icons.picture_as_pdf_rounded,
              label: AppLocale.text(widget.language, 'Preview PDF', 'PDF देखें'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Desktop Keyboard shortcuts mapping
    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveDocument,
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
      const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
      const SingleActivator(LogicalKeyboardKey.keyP, control: true): _openPdfPreview,
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocale.text(widget.language, 'Document Editor', 'दस्तावेज़ संपादक'),
            ),
            actions: [
              IconButton(
                tooltip: 'Save (Ctrl+S)',
                icon: Icon(
                  Icons.save_rounded,
                  color: _hasUnsavedChanges ? AppColors.primary : null,
                ),
                onPressed: _saveDocument,
              ),
              IconButton(
                tooltip: 'Preview PDF (Ctrl+P)',
                icon: const Icon(Icons.picture_as_pdf_rounded),
                onPressed: _openPdfPreview,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Wide Screen: Tablet Landscape / Desktop Split View (>= 768px)
                if (constraints.maxWidth >= 768) {
                  return Row(
                    children: [
                      // Left Pane: Handwriting Image View
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image_outlined, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocale.text(
                                      widget.language,
                                      'Handwritten Source',
                                      'हस्तलिखित स्रोत',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildImageViewerPanel(isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Vertical Divider
                      VerticalDivider(
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      // Right Pane: Rich Document Editor
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildDocumentHeader(isDark),
                            _buildLowConfidenceWordBar(),
                            Expanded(child: _buildEditorField()),
                            _buildBottomBar(),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Mobile Screen (< 768px): Tabbed interface
                return Column(
                  children: [
                    _buildDocumentHeader(isDark),
                    _buildLowConfidenceWordBar(),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          text: AppLocale.text(widget.language, 'Editor', 'संपादक'),
                        ),
                        Tab(
                          icon: const Icon(Icons.image_outlined, size: 18),
                          text: AppLocale.text(widget.language, 'Original Note', 'मूल छवि'),
                        ),
                        Tab(
                          icon: const Icon(Icons.history_edu_rounded, size: 18),
                          text: AppLocale.text(widget.language, 'Raw OCR', 'मूल OCR'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEditorField(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildImageViewerPanel(isDark),
                          ),
                          _buildRawOcrTab(isDark),
                        ],
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
