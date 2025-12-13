import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';

class CustomKeypad extends StatelessWidget {
  final VoidCallback onBlackCheckTap;
  final VoidCallback onRedActionTap;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspaceTap;
  final bool isCalculationMode;

  const CustomKeypad({
    super.key,
    required this.onBlackCheckTap,
    required this.onRedActionTap,
    required this.onKeyTap,
    required this.onBackspaceTap,
    required this.isCalculationMode,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      children: [
        _buildRow(['1', '2', '3', '+'], themeColors),
        const SizedBox(height: 8),
        _buildRow(['4', '5', '6', '-'], themeColors),
        const SizedBox(height: 8),
        _buildRow(['7', '8', '9', 'BACK'], themeColors),
        const SizedBox(height: 8),
        _buildBottomRow(themeColors),
      ],
    );
  }

  Widget _buildRow(List<String> keys, AppThemeColors themeColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        return Expanded(child: _buildKey(key, themeColors));
      }).toList(),
    );
  }

  Widget _buildBottomRow(AppThemeColors themeColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildKey('0', themeColors)),
        Expanded(child: _buildKey('.', themeColors)),
        // Black Check Button
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: InkWell(
                onTap: onBlackCheckTap,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(Icons.check, size: 28, color: themeColors.text),
                ),
              ),
            ),
          ),
        ),
        // Red Action Button
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: InkWell(
                onTap: onRedActionTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.destructiveRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isCalculationMode ? Icons.drag_handle : Icons.check,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String key, AppThemeColors themeColors) {
    if (key == 'BACK') {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: InkWell(
            onTap: onBackspaceTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.arrow_back, size: 28, color: themeColors.text),
            ),
          ),
        ),
      );
    }

    bool isOperator = ['+', '-'].contains(key);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: InkWell(
          onTap: () => onKeyTap(key),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOperator
                  ? themeColors.inputBackground
                  : Colors.transparent,
            ),
            child: isOperator
                ? Icon(
                    key == '+' ? Icons.add : Icons.remove,
                    size: 28,
                    color: themeColors.text,
                  )
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeColors.text,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
