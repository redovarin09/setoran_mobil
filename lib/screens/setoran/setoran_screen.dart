import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SetoranScreen extends StatelessWidget {
  const SetoranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Setoran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Setoran — Coming Soon',
          style: TextStyle(color: AppColors.textMedium),
        ),
      ),
    );
  }
}
