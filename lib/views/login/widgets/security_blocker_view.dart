import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class SecurityBlockerView extends StatelessWidget {
  final String reason;
  final VoidCallback onRetry;

  const SecurityBlockerView({super.key, required this.reason, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Akses Ditolak',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reason, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
