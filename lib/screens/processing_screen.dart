import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/api_service.dart';
import '../widgets/likh_logo.dart';
import 'editor_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final XFile image;
  final String language;
  final String? documentTitle;
  final bool preprocess;

  const ProcessingScreen({
    super.key,
    required this.image,
    this.language = 'English',
    this.documentTitle,
    this.preprocess = true,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  String? _errorMessage;
  bool _isProcessing = false;
  bool _isCancelled = false;
  http.Client? _activeHttpClient;

  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle breathing pulse / glow animation for the LIKH AI sparkle icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startDigitizationProcess();
  }

  @override
  void dispose() {
    _isCancelled = true;
    _pulseController.dispose();
    _activeHttpClient?.close();
    super.dispose();
  }

  void _cancelProcessing() {
    _isCancelled = true;
    _activeHttpClient?.close();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _startDigitizationProcess() async {
    if (_isProcessing) return;

    _isProcessing = true;
    _isCancelled = false;
    _activeHttpClient = http.Client();

    setState(() {
      _errorMessage = null;
    });

    try {
      final title = widget.documentTitle ??
          'Handwritten Note ${DateTime.now().day}/${DateTime.now().month}';

      final response = await ApiService.processHandwritingImage(
        image: widget.image,
        language: widget.language,
        title: title,
        preprocess: widget.preprocess,
        client: _activeHttpClient,
      );

      if (!mounted || _isCancelled) return;

      if (!response.success) {
        setState(() {
          _errorMessage = response.error ?? 'Unknown error occurred during digitization.';
        });
        return;
      }

      final doc = DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        originalImagePath: widget.image.path.isNotEmpty ? widget.image.path : response.originalImageUrl,
        processedImagePath: response.processedImageUrl,
        rawText: response.rawText,
        cleanedText: response.cleanedText,
        editedText: response.cleanedText.isNotEmpty ? response.cleanedText : response.rawText,
        language: response.language,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        processingStatus: 'completed',
        confidence: response.confidence,
        qualityScore: response.qualityScore,
        lowConfidenceWords: response.lowConfidenceSegments.map((s) => s.text).toList(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(
            language: widget.language,
            document: doc,
          ),
        ),
      );
    } catch (_) {
      if (!mounted || _isCancelled) return;
      setState(() {
        _errorMessage = AppLocale.text(
          widget.language,
          "Unable to connect to the handwriting service. Please try again.",
          "हस्तलेखन सेवा से कनेक्ट करने में असमर्थ। कृपया पुनः प्रयास करें।",
        );
      });
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: _errorMessage != null
                  ? _buildErrorView(theme, isDark)
                  : _buildMinimalLoadingView(theme, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalLoadingView(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing LIKH AI Official Logo Mark with gentle breathing glow
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: LikhLogoMark(
                size: 88,
                animateGlow: true,
                glowAnimation: _glowAnimation,
              ),
            );
          },
        ),

        const SizedBox(height: 36),

        // Minimal Header Text
        Text(
          AppLocale.text(
            widget.language,
            'LIKH AI is Digitizing...',
            'LIKH AI डिजिटाइज़ कर रहा है...',
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        // Minimal Subtitle Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocale.text(
              widget.language,
              'Your handwriting is being converted to clean digital text',
              'आपकी लिखावट को साफ़ डिजिटल टेक्स्ट में बदला जा रहा है',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Subdued cancel button
        TextButton(
          onPressed: _cancelProcessing,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            AppLocale.text(widget.language, 'Cancel', 'रद्द करें'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocale.text(
            widget.language,
            'Unable to Process Handwriting',
            'हस्तलेखन संसाधित करने में असमर्थ',
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withAlpha(64)),
          ),
          child: Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocale.text(widget.language, 'Cancel', 'रद्द करें')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startDigitizationProcess,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocale.text(widget.language, 'Retry', 'पुनः प्रयास')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
