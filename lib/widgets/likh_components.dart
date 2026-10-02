import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable Figma Make Design System Components for LIKH AI

enum LikhButtonVariant { primary, secondary, outline, text }

class LikhButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LikhButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const LikhButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = LikhButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;

    Color bgColor;
    Color fgColor;
    BorderSide? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case LikhButtonVariant.primary:
        bgColor = isDisabled ? (isDark ? const Color(0xFF332018) : const Color(0xFFF0CEBA)) : AppColors.primary;
        fgColor = Colors.white;
        border = null;
        if (!isDisabled) {
          shadows = [
            BoxShadow(
              color: AppColors.primary.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;
      case LikhButtonVariant.secondary:
        bgColor = isDark ? AppColors.cardDarkSecondary : AppColors.cardLightSecondary;
        fgColor = isDark ? AppColors.textDark : AppColors.textLight;
        border = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        );
        break;
      case LikhButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = isDark ? AppColors.textDark : AppColors.textLight;
        border = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        );
        break;
      case LikhButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        border = null;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border != null ? Border.fromBorderSide(border) : null,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Styled Card Container adhering to Figma squircle radius and borders
class LikhCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const LikhCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final borderCol = borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight);

    final decoration = BoxDecoration(
      color: gradient == null ? bg : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderCol, width: borderWidth),
      boxShadow: shadows ?? [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 30 : 8),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }
}

/// Pill Badge for status, formats, and categories
class LikhBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final double fontSize;

  const LikhBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: themeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: themeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: themeColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Squircle Icon Button
class LikhIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const LikhIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final fg = color ?? (isDark ? AppColors.textDark : AppColors.textLight);
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    Widget btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size * 0.32),
          child: Center(
            child: Icon(icon, size: size * 0.5, color: fg),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

/// Header for dashboard sections
class LikhSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LikhSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
