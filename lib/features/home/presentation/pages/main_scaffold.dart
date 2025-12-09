import 'package:flutter/material.dart';

import 'home_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../transactions/presentation/pages/transactions_list_page.dart';
import '../../../transactions/presentation/pages/transaction_page.dart';
import '../../../assets/presentation/pages/assets_page.dart';
import '../../../../core/constants/app_colors.dart';

import '../widgets/custom_bottom_nav.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const TransactionsListPage(),
      const AssetsPage(),
      const SettingsPage(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating nav
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TransactionPage(),
                  ),
                );
              },
              backgroundColor: AppColors.pastelOrange,
              child: const Icon(Icons.add, color: AppColors.textDark),
            )
          : null,
      // Adjust floating action button location to not overlap with bottom nav if needed
      // With extendBody, it might overlap. Standard layout usually puts FAB above or docked.
      // Since CustomBottomNav has margin bottom 24, we might want FAB higher up or standard.
    );
  }
}
