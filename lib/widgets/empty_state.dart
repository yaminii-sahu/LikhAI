import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'likh_components.dart';
import 'likh_logo.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final bool useBrandLogo;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.useBrandLogo = true,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (useBrandLogo)
              const LikhLogoMark(size: 64)
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon ?? Icons.description_outlined,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              LikhButton(
                label: buttonLabel!,
                icon: Icons.add_rounded,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
