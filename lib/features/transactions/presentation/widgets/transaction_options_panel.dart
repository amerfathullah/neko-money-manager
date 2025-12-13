import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class TransactionOptionsPanel extends StatelessWidget {
  final DateTime selectedDate;
  final String ledgerName;
  final String assetName;
  final bool isReimburse;
  final bool isReimburseEnabled; // Add this
  final VoidCallback onDateTap;
  final VoidCallback onLedgerTap;
  final VoidCallback onAssetTap;
  final VoidCallback onReimburseTap;
  final VoidCallback onRemarkTap;

  const TransactionOptionsPanel({
    super.key,
    required this.selectedDate,
    required this.ledgerName,
    required this.assetName,
    required this.isReimburse,
    this.isReimburseEnabled = true, // Default to true
    required this.onDateTap,
    required this.onLedgerTap,
    required this.onAssetTap,
    required this.onReimburseTap,
    required this.onRemarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOptionButton(
          label: 'Date',
          icon: Icons.calendar_today,
          text: _formatDate(selectedDate),
          color: AppColors.pastelCyan, // Light Cyan
          iconColor: AppColors.textCyan,
          onTap: onDateTap,
        ),
        const SizedBox(height: 8),
        _buildOptionButton(
          label: 'Ledger',
          icon: Icons.book, // Replace with custom asset if available
          text: ledgerName,
          color: AppColors.pastelOrange, // Light Orange
          iconColor: AppColors.textOrange,
          onTap: onLedgerTap,
        ),
        const SizedBox(height: 8),
        _buildOptionButton(
          label: 'Asset',
          icon: Icons.account_balance_wallet,
          text: assetName, // Truncate if too long?
          color: AppColors.buttonBeige, // Slightly different Orange
          iconColor: AppColors.textDeepOrange,
          onTap: onAssetTap,
        ),
        const SizedBox(height: 8),
        _buildOptionButton(
          label: 'Reimburse',
          icon: Icons.work_outline,
          text: 'Reimburse',
          color: isReimburseEnabled
              ? AppColors.pastelPurpleLight
              : Colors.grey.shade200, // Light Purple or Grey if disabled
          iconColor: isReimburseEnabled
              ? AppColors.textPurple
              : Colors.grey, // Purple or Grey
          textColor: isReimburseEnabled ? null : Colors.grey,
          onTap: isReimburseEnabled
              ? onReimburseTap
              : () {}, // No-op if disabled
          isSelected: isReimburse,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return DateFormat('MMM dd').format(date);
  }

  Widget _buildOptionButton({
    required String label,
    IconData? icon,
    required String text,
    required Color color,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,

    bool isSelected = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: iconColor ?? Colors.black, width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 24, color: iconColor ?? Colors.black87),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
