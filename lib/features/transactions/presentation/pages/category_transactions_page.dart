import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../widgets/transaction_timeline.dart';

class CategoryTransactionsPage extends StatelessWidget {
  final String categoryName;
  final List<TransactionModel> transactions;

  final String currencySymbol;
  final bool useComma;

  const CategoryTransactionsPage({
    super.key,
    required this.categoryName,
    required this.transactions,
    required this.currencySymbol,
    required this.useComma,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: TransactionTimeline(
        transactions: transactions,
        currencySymbol: currencySymbol,
        useComma: useComma,
        shrinkWrap: false,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
      ),
    );
  }
}
