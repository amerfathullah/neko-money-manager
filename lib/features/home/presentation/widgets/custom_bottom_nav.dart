import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColors.background, // Cream background
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.pastelOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIcon(
            icon: Icons.receipt_long, // Record (Home)
            label: 'Record',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
            color: AppColors.pastelOrange,
          ),
          _NavIcon(
            icon: Icons.bar_chart, // Report/Transactions
            label: 'Bills',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
            color: AppColors.pastelBlue,
          ),
          _NavIcon(
            icon: Icons.account_balance_wallet, // Assets
            label: 'Asset',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
            color: AppColors.pastelRed,
          ),
          _NavIcon(
            icon: Icons.settings, // Settings
            label: 'Setting',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
            color: AppColors.pastelPurple,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isSelected
        ? (isDark ? color.withValues(alpha: 0.2) : color)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected
                    ? themeColors.text
                    : themeColors.text.withValues(alpha: 0.4),
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: themeColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
