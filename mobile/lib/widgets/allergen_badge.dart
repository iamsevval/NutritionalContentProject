import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AllergenBadge extends StatelessWidget {
  final String allergen;

  const AllergenBadge({super.key, required this.allergen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dangerColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.dangerColor),
          const SizedBox(width: 6),
          Text(
            allergen,
            style: const TextStyle(
              color: AppTheme.dangerColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
