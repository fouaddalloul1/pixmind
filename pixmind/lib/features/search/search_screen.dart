// search_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        title: const Text('البحث الذكي',
            style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text('شاشة البحث — قريباً',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
