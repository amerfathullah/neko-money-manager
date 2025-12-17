import 'package:flutter/material.dart';
import '../../../../features/categories/data/models/category.dart';
import '../../data/models/transaction_model.dart';
import '../widgets/transactions_list_widgets.dart';
import '../../../../core/theme/app_theme_colors.dart';

class TransactionChartPage extends StatelessWidget {
  final String title;
  final bool isExpense;
  final List<TransactionModel> transactions;
  final String currencySymbol;
  final bool useComma;
  final List<Category> categories;

  const TransactionChartPage({
    super.key,
    required this.title,
    required this.isExpense,
    required this.transactions,
    required this.currencySymbol,
    required this.useComma,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        backgroundColor: themeColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: themeColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: TransactionChartSection(
          title: title,
          isExpense: isExpense,
          transactions: transactions,
          currencySymbol: currencySymbol,
          useComma: useComma,
          categories: categories,
          showForwardButton:
              false, // Ensure this parameter is added to the widget
        ),
      ),
    );
  }
}
