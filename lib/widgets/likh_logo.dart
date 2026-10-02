import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Official LIKH AI Brand Logo System
/// Supports dedicated LIGHT and DARK mode variants matching the Figma design reference:
///
/// LIGHT MODE (Left variant):
/// - Dark navy rounded-square logo mark
/// - Cream/off-white handwriting symbol
/// - Orange horizontal strokes
/// - Dark navy 'LIKH' lettering
/// - Orange 'AI' superscript
/// - Tagline: "Your handwriting. Digitized."
///
/// DARK MODE (Right variant):
/// - Cream/off-white rounded-square logo mark
/// - Dark navy handwriting symbol
/// - Orange horizontal strokes
/// - White/cream 'LIKH' lettering
/// - Orange 'AI' superscript
/// - Tagline: "Your handwriting. Digitized."

enum LikhLogoVariant { light, dark, auto }

/// Vector Logo Mark Squircle
class LikhLogoMark extends StatelessWidget {
  final double size;
  final LikhLogoVariant variant;
  final bool animateGlow;
  final Animation<double>? glowAnimation;
  final Color? customBackground;
  final Color? customStroke;
  final Color? customBars;

  const LikhLogoMark({
    super.key,
    this.size = 48,
    this.variant = LikhLogoVariant.auto,
    this.animateGlow = false,
    this.glowAnimation,
    this.customBackground,
    this.customStroke,
    this.customBars,
  });

  const LikhLogoMark.light({
    super.key,
    this.size = 48,
    this.animateGlow = false,
    this.glowAnimation,
    this.customBackground,
    this.customStroke,
    this.customBars,
  }) : variant = LikhLogoVariant.light;

  const LikhLogoMark.dark({
    super.key,
    this.size = 48,
    this.animateGlow = false,
    this.glowAnimation,
    this.customBackground,
    this.customStroke,
    this.customBars,
  }) : variant = LikhLogoVariant.dark;

  bool _isDarkMode(BuildContext context) {
    if (variant == LikhLogoVariant.dark) return true;
    if (variant == LikhLogoVariant.light) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    // Exact color mapping from the Figma reference:
    // LIGHT: Dark Navy container + Cream 'L' stroke + Orange bars
    // DARK: Cream/Off-white container + Dark Navy 'L' stroke + Orange bars
    final bgColor = customBackground ??
        (isDark ? AppColors.surfaceLight : AppColors.brandNavy);
    final strokeColor = customStroke ??
        (isDark ? AppColors.brandNavy : AppColors.surfaceLight);
    final barsColor = customBars ?? AppColors.primary;

    Widget mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(50)
              : Colors.black.withAlpha(20),
          width: size * 0.02,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withAlpha(isDark ? 50 : 25),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _LikhMarkPainter(
          strokeColor: strokeColor,
          barsColor: barsColor,
        ),
      ),
    );

    if (animateGlow && glowAnimation != null) {
      return AnimatedBuilder(
        animation: glowAnimation!,
        builder: (context, child) {
          final val = glowAnimation!.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((35 + val * 65).round()),
                  blurRadius: size * (0.3 + val * 0.4),
                  spreadRadius: size * (0.05 + val * 0.15),
                ),
              ],
            ),
            child: child,
          );
        },
        child: mark,
      );
    }

    return mark;
  }
}

class _LikhMarkPainter extends CustomPainter {
  final Color strokeColor;
  final Color barsColor;

  _LikhMarkPainter({
    required this.strokeColor,
    required this.barsColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw signature handwriting 'L' stroke on the left
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(w * 0.30, h * 0.24);
    path.lineTo(w * 0.30, h * 0.68);
    path.quadraticBezierTo(w * 0.30, h * 0.76, w * 0.38, h * 0.76);
    path.lineTo(w * 0.52, h * 0.76);

    canvas.drawPath(path, strokePaint);

    // 2. Draw 3 orange horizontal digitizing strokes on the right
    final barPaint = Paint()
      ..color = barsColor
      ..style = PaintingStyle.fill;

    final barThickness = h * 0.09;
    final barRadius = Radius.circular(barThickness / 2);

    final barStartX = w * 0.52;
    final barEndX = w * 0.78;
    final barWidth = barEndX - barStartX;

    // Top Bar
    final bar1Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barStartX + w * 0.04, h * 0.28, barWidth - w * 0.04, barThickness),
      barRadius,
    );
    canvas.drawRRect(bar1Rect, barPaint);

    // Middle Bar
    final bar2Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barStartX, h * 0.44, barWidth, barThickness),
      barRadius,
    );
    canvas.drawRRect(bar2Rect, barPaint);

    // Bottom Bar (slightly indented)
    final bar3Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barStartX + w * 0.08, h * 0.60, barWidth - w * 0.08, barThickness),
      barRadius,
    );
    canvas.drawRRect(bar3Rect, barPaint);
  }

  @override
  bool shouldRepaint(covariant _LikhMarkPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor || oldDelegate.barsColor != barsColor;
  }
}

/// Official LIKH AI Wordmark
/// "LIKH" (Dark Navy in Light Mode, White/Cream in Dark Mode) + Orange "AI"
class LikhWordmark extends StatelessWidget {
  final double fontSize;
  final LikhLogoVariant variant;
  final Color? customTextColor;
  final Color? customAiColor;

  const LikhWordmark({
    super.key,
    this.fontSize = 24,
    this.variant = LikhLogoVariant.auto,
    this.customTextColor,
    this.customAiColor,
  });

  const LikhWordmark.light({
    super.key,
    this.fontSize = 24,
    this.customTextColor,
    this.customAiColor,
  }) : variant = LikhLogoVariant.light;

  const LikhWordmark.dark({
    super.key,
    this.fontSize = 24,
    this.customTextColor,
    this.customAiColor,
  }) : variant = LikhLogoVariant.dark;

  bool _isDarkMode(BuildContext context) {
    if (variant == LikhLogoVariant.dark) return true;
    if (variant == LikhLogoVariant.light) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final mainColor = customTextColor ?? (isDark ? AppColors.textDark : AppColors.textLight);
    final aiColor = customAiColor ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIKH',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: mainColor,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 4),
        Transform.translate(
          offset: Offset(0, -fontSize * 0.12),
          child: Text(
            'AI',
            style: TextStyle(
              fontSize: fontSize * 0.48,
              fontWeight: FontWeight.w800,
              color: aiColor,
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Unified LIKH AI Brand Logo
/// Automatically or explicitly selects Light or Dark mode logo variant.
/// Tagline is strictly: "Your handwriting. Digitized."
class LikhBrandLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final LikhLogoVariant variant;
  final bool isVertical;
  final bool showTagline;
  final String tagline;

  const LikhBrandLogo({
    super.key,
    this.markSize = 42,
    this.fontSize = 22,
    this.variant = LikhLogoVariant.auto,
    this.isVertical = false,
    this.showTagline = false,
    this.tagline = 'Your handwriting. Digitized.',
  });

  const LikhBrandLogo.light({
    super.key,
    this.markSize = 42,
    this.fontSize = 22,
    this.isVertical = false,
    this.showTagline = false,
    this.tagline = 'Your handwriting. Digitized.',
  }) : variant = LikhLogoVariant.light;

  const LikhBrandLogo.dark({
    super.key,
    this.markSize = 42,
    this.fontSize = 22,
    this.isVertical = false,
    this.showTagline = false,
    this.tagline = 'Your handwriting. Digitized.',
  }) : variant = LikhLogoVariant.dark;

  bool _isDarkMode(BuildContext context) {
    if (variant == LikhLogoVariant.dark) return true;
    if (variant == LikhLogoVariant.light) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final tagColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LikhLogoMark(
            size: markSize,
            variant: variant,
          ),
          SizedBox(height: markSize * 0.28),
          LikhWordmark(
            fontSize: fontSize,
            variant: variant,
          ),
          if (showTagline) ...[
            const SizedBox(height: 5),
            Text(
              tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize * 0.50,
                fontWeight: FontWeight.w500,
                color: tagColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LikhLogoMark(
          size: markSize,
          variant: variant,
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LikhWordmark(
              fontSize: fontSize,
              variant: variant,
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                tagline,
                style: TextStyle(
                  fontSize: fontSize * 0.48,
                  fontWeight: FontWeight.w500,
                  color: tagColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Backwards compatibility alias for LikhBrandLogo
typedef LikhLogo = LikhBrandLogo;
typedef LikhAiLogo = LikhBrandLogo;

