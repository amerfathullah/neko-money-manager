import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../transactions/presentation/pages/transactions_list_page.dart';
import '../../../transactions/presentation/pages/transaction_page.dart';
import '../../../assets/presentation/pages/assets_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../assets/presentation/pages/add_edit_asset_page.dart';

import '../widgets/custom_bottom_nav.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pages = [
      const HomePage(),
      const TransactionsListPage(),
      const AssetsPage(),
      const SettingsPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine FAB action and visibility based on index
    VoidCallback? onFabPressed;
    if (_currentIndex == 0) {
      onFabPressed = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TransactionPage()),
        );
      };
    } else if (_currentIndex == 2) {
      onFabPressed = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddEditAssetPage()),
        );
      };
    }

    return Scaffold(
      extendBody: true, // Important for floating nav
      body: PageView(
        controller: _pageController,
        // physics: const NeverScrollableScrollPhysics(), // Enable swipe
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      floatingActionButton: onFabPressed != null
          ? FloatingActionButton(
              onPressed: onFabPressed,
              backgroundColor: AppColors.pastelOrange,
              child: const Icon(Icons.add, color: AppColors.textDark),
            )
          : null,
    );
  }
}
