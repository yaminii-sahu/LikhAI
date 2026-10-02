import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/pdf_service.dart';
import '../widgets/likh_components.dart';
import 'editor_screen.dart';
import 'pdf_preview_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel document;
  final String language;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.language,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wordCount = document.editedText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    final confColor = document.confidence >= 0.88
        ? AppColors.success
        : (document.confidence >= 0.70 ? AppColors.primary : AppColors.warning);
    final confLabel = document.confidence >= 0.88
        ? 'High Accuracy'
        : (document.confidence >= 0.70 ? 'Digitized' : 'Review Needed');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: AppLocale.text(language, 'Edit', 'संपादित करें'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditorScreen(
                    document: document,
                    language: language,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: AppLocale.text(language, 'Share PDF', 'PDF साझा करें'),
            icon: const Icon(Icons.share_rounded),
            onPressed: () => PdfService.shareDocumentPdf(document),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Metadata Card
                LikhCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocale.text(language, 'Created', 'बनाया गया')}: ${_formatDate(document.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          LikhBadge(
                            label: confLabel,
                            color: confColor,
                            icon: Icons.verified_rounded,
                          ),
                          LikhBadge(
                            label: document.language.toUpperCase(),
                            color: AppColors.primary,
                            icon: Icons.language_rounded,
                          ),
                          LikhBadge(
                            label: '$wordCount ${AppLocale.text(language, 'words', 'शब्द')}',
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            icon: Icons.text_snippet_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Extracted / Edited Text Preview Header
                LikhSectionHeader(
                  title: AppLocale.text(language, 'Digitized Content', 'डिजिटल सामग्री'),
                  actionLabel: AppLocale.text(language, 'Open in Editor', 'संपादक में खोलें'),
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(
                          document: document,
                          language: language,
                        ),
                      ),
                    );
                  },
                ),

                // Content Container
                LikhCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 18,
                  child: SelectableText(
                    document.editedText.isNotEmpty
                        ? document.editedText
                        : AppLocale.text(language, 'Empty document text.', 'खाली दस्तावेज़ टेक्स्ट।'),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: LikhButton(
                        variant: LikhButtonVariant.outline,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditorScreen(
                                document: document,
                                language: language,
                              ),
                            ),
                          );
                        },
                        icon: Icons.edit_note_rounded,
                        label: AppLocale.text(language, 'Edit Text', 'संपादित करें'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: LikhButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPreviewScreen(
                                document: document,
                                language: language,
                              ),
                            ),
                          );
                        },
                        icon: Icons.picture_as_pdf_rounded,
                        label: AppLocale.text(language, 'View PDF', 'PDF देखें'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
