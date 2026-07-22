import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../views/kunjungan/potensial_get_view.dart';

class PotensialGetCard extends StatelessWidget {
  const PotensialGetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PotensialGetView()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.action.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.action.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.action.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.stars_outlined, color: AppColors.action),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('List Potensial Get', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Member yang belum pernah dikunjungi', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
