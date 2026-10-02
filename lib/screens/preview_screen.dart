import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../widgets/likh_components.dart';
import 'processing_screen.dart';

class PreviewScreen extends StatefulWidget {
  final XFile image;
  final String language;
  final String? documentTitle;

  const PreviewScreen({
    super.key,
    required this.image,
    required this.language,
    this.documentTitle,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _autoPreprocess = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.image.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.text(
            widget.language,
            'Review Handwriting Image',
            'हस्तलिखित छवि की समीक्षा',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Image preview container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _imageBytes != null
                              ? InteractiveViewer(
                                  minScale: 0.8,
                                  maxScale: 4.0,
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    AppLocale.text(
                                      widget.language,
                                      'Failed to load image',
                                      'छवि लोड करने में विफल',
                                    ),
                                    style: TextStyle(
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preprocessing toggle card
                  LikhCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocale.text(
                                  widget.language,
                                  'AI Image Preprocessing',
                                  'AI छवि प्रीप्रोसेसिंग',
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppColors.textDark : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocale.text(
                                  widget.language,
                                  'Enhance contrast, denoise & deskew before OCR',
                                  'OCR से पहले कंट्रास्ट बढ़ाएँ और शोर कम करें',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoPreprocess,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _autoPreprocess = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action button: Digitize with AI
                  LikhButton(
                    width: double.infinity,
                    height: 52,
                    label: AppLocale.text(
                      widget.language,
                      'Digitize with AI',
                      'AI से डिजिटाइज़ करें',
                    ),
                    icon: Icons.document_scanner_rounded,
                    onPressed: _imageBytes == null
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProcessingScreen(
                                  image: widget.image,
                                  language: widget.language,
                                  documentTitle: widget.documentTitle,
                                  preprocess: _autoPreprocess,
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
