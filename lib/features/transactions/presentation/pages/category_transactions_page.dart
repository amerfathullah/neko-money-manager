import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../widgets/transactions_list_widgets.dart';

class CategoryTransactionsPage extends StatelessWidget {
  final String categoryName;
  final List<TransactionModel> transactions;

  const CategoryTransactionsPage({
    super.key,
    required this.categoryName,
    required this.transactions,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: TransactionListSection(transactions: transactions),
      ),
    );
  }
}
