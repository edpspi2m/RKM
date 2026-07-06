import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Tampilan kosong/error yang rapi & smooth, pengganti Text polos di tengah layar.
/// Dipakai untuk state error (gagal load) maupun state kosong (data belum ada).
class StatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const StatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  factory StatePlaceholder.error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return StatePlaceholder(
      icon: Icons.cloud_off_rounded,
      title: 'Gagal memuat data',
      message: message,
      actionLabel: onRetry != null ? 'Coba Lagi' : null,
      onAction: onRetry,
      isError: true,
    );
  }

  factory StatePlaceholder.empty({
    required String title,
    String? message,
  }) {
    return StatePlaceholder(
      icon: Icons.inbox_outlined,
      title: title,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isError ? AppColors.error : AppColors.textSecondary;

    return TweenAnimationBuilder<double>(
      key: ValueKey(title + (message ?? '')),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: accent),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
