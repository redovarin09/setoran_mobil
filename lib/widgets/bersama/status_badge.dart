import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isLunas = status == 'Lunas';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLunas ? AppColors.successLight : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLunas ? '✓ Lunas' : '⚠ Kurang',
        style: TextStyle(
          color: isLunas ? AppColors.success : AppColors.danger,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
