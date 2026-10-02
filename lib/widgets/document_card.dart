import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import 'likh_components.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final String language;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPdf;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.language,
    required this.onTap,
    required this.onEdit,
    required this.onPdf,
    required this.onDelete,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = document.editedText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    final confidenceColor = document.confidence >= 0.88
        ? AppColors.success
        : (document.confidence >= 0.70 ? AppColors.primary : AppColors.warning);

    final confidenceLabel = document.confidence >= 0.88
        ? 'High Accuracy'
        : (document.confidence >= 0.70 ? 'Digitized' : 'Review Needed');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Signature Document Squircle Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Document metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(document.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          LikhBadge(
                            label: document.language.toUpperCase(),
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                          LikhBadge(
                            label: '$wordCount ${AppLocale.text(language, 'words', 'शब्द')}',
                            fontSize: 10,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          LikhBadge(
                            label: confidenceLabel,
                            fontSize: 10,
                            color: confidenceColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Popup Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  elevation: 6,
                  onSelected: (val) {
                    switch (val) {
                      case 'pdf':
                        onPdf();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(AppLocale.text(language, 'View PDF', 'PDF देखें')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(AppLocale.text(language, 'Edit Text', 'संपादित करें')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text(
                            AppLocale.text(language, 'Delete', 'हटाएं'),
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
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
