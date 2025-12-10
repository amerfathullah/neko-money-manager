import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionOptionsPanel extends StatelessWidget {
  final DateTime selectedDate;
  final String ledgerName;
  final String assetName;
  final bool isReimburse;
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
          color: const Color(0xFFD0F4F7), // Light Cyan
          iconColor: const Color(0xFF2E5C5F),
          onTap: onDateTap,
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          label: 'Ledger',
          icon: Icons.book, // Replace with custom asset if available
          text: ledgerName,
          color: const Color(0xFFFFE5CC), // Light Orange
          iconColor: const Color(0xFFA65200),
          onTap: onLedgerTap,
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          label: 'Asset',
          icon: Icons.account_balance_wallet,
          text: assetName, // Truncate if too long?
          color: const Color(0xFFFFE0B2), // Slightly different Orange
          iconColor: const Color(0xFFE65100),
          onTap: onAssetTap,
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          label: 'Reimburse',
          icon: Icons.work_outline,
          text: 'Reimburse',
          color: const Color(0xFFF3E5F5), // Light Purple
          iconColor: const Color(0xFF7B1FA2),
          onTap: onReimburseTap,
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
          height: 48,
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
