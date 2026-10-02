import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/likh_components.dart';
import '../widgets/likh_logo.dart';
import 'new_document_screen.dart';
import 'preview_screen.dart';
import 'editor_screen.dart';
import 'pdf_preview_screen.dart';
import 'document_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String language;

  const HomeScreen({
    super.key,
    required this.language,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DocumentModel> _recentDocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentDocuments();
  }

  Future<void> _loadRecentDocuments() async {
    final docs = await StorageService.getDocuments();
    if (mounted) {
      setState(() {
        _recentDocs = docs.take(4).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (image == null || !mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            image: image,
            language: widget.language,
          ),
        ),
      ).then((_) => _loadRecentDocuments());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocale.text(widget.language, 'Could not access image', 'छवि तक पहुँच नहीं हो सकी')}: $e',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _loadRecentDocuments,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              children: [
                // Top App Bar / Brand Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const LikhBrandLogo(
                      markSize: 42,
                      fontSize: 22,
                      showTagline: true,
                      tagline: 'Your handwriting. Digitized.',
                    ),
                    LikhBadge(
                      label: widget.language,
                      color: AppColors.primary,
                      icon: Icons.language_rounded,
                      fontSize: 12,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Figma Make Hero Banner Card
                LikhCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  gradient: isDark ? AppColors.heroDarkGradient : AppColors.heroLightGradient,
                  borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const LikhBadge(
                            label: 'AI-POWERED OCR',
                            icon: Icons.document_scanner_rounded,
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                          Text(
                            'LIKH AI v1.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocale.text(
                          widget.language,
                          'Transform handwriting into\nclean, structured digital text.',
                          'हस्तलेखन को साफ़ और\nसंरचित डिजिटल टेक्स्ट में बदलें।',
                        ),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.25,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocale.text(
                          widget.language,
                          'Capture notes, meeting minutes, or formulas. Get instant AI cleanup, full editing tools, and print-ready PDF export.',
                          'नोट्स, मीटिंग मिनट्स या फ़ॉर्मूले कैप्चर करें। तुरंत AI सफ़ाई, संपादन उपकरण और प्रिंट-रेडी PDF निर्यात प्राप्त करें।',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          LikhButton(
                            label: AppLocale.text(widget.language, 'Scan Document', 'दस्तावेज़ स्कैन करें'),
                            icon: Icons.document_scanner_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NewDocumentScreen(
                                    language: widget.language,
                                  ),
                                ),
                              ).then((_) => _loadRecentDocuments());
                            },
                          ),
                          LikhButton(
                            label: AppLocale.text(widget.language, 'New Blank Note', 'नया खाली नोट'),
                            icon: Icons.edit_note_rounded,
                            variant: LikhButtonVariant.outline,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NewDocumentScreen(
                                    language: widget.language,
                                  ),
                                ),
                              ).then((_) => _loadRecentDocuments());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Capture Options Row
                Row(
                  children: [
                    Expanded(
                      child: _QuickCaptureCard(
                        icon: Icons.camera_alt_rounded,
                        title: AppLocale.text(widget.language, 'Camera Capture', 'कैमरा कैप्चर'),
                        subtitle: AppLocale.text(widget.language, 'Snap handwriting directly', 'सीधे लिखावट की तस्वीर लें'),
                        badgeLabel: 'Instant OCR',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _QuickCaptureCard(
                        icon: Icons.photo_library_rounded,
                        title: AppLocale.text(widget.language, 'Import Image', 'छवि आयात करें'),
                        subtitle: AppLocale.text(widget.language, 'Upload JPG, PNG or WebP', 'JPG, PNG या WebP अपलोड करें'),
                        badgeLabel: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent Documents Header
                LikhSectionHeader(
                  title: AppLocale.text(widget.language, 'Recent Documents', 'हाल के दस्तावेज़'),
                  actionLabel: _recentDocs.isNotEmpty
                      ? AppLocale.text(widget.language, 'View All', 'सभी देखें')
                      : null,
                  onAction: _recentDocs.isNotEmpty
                      ? () {
                          // Switch to documents tab via default navigation host or push screen
                        }
                      : null,
                ),

                // Recent Documents List or Empty State
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_recentDocs.isEmpty)
                  LikhCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: EmptyState(
                      icon: Icons.description_outlined,
                      title: AppLocale.text(widget.language, 'No documents yet', 'अभी तक कोई दस्तावेज़ नहीं'),
                      message: AppLocale.text(
                        widget.language,
                        'Capture handwritten notes or upload an image to begin digitizing with LIKH AI.',
                        'शुरू करने के लिए हस्तलिखित नोट्स कैप्चर करें या एक छवि अपलोड करें।',
                      ),
                      buttonLabel: AppLocale.text(widget.language, 'Scan First Note', 'पहला नोट स्कैन करें'),
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewDocumentScreen(language: widget.language),
                          ),
                        ).then((_) => _loadRecentDocuments());
                      },
                    ),
                  )
                else
                  ..._recentDocs.map((doc) {
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
                        ).then((_) => _loadRecentDocuments());
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditorScreen(
                              language: widget.language,
                              document: doc,
                            ),
                          ),
                        ).then((_) => _loadRecentDocuments());
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
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocale.text(widget.language, 'Delete Document', 'दस्तावेज़ हटाएं')),
                            content: Text(
                              AppLocale.text(
                                widget.language,
                                'Are you sure you want to delete "${doc.title}"?',
                                'क्या आप "${doc.title}" को हटाना चाहते हैं?',
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
                          _loadRecentDocuments();
                        }
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCaptureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final VoidCallback onTap;

  const _QuickCaptureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LikhCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              LikhBadge(
                label: badgeLabel,
                fontSize: 10,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
