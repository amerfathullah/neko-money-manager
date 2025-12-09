import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../providers/pro_provider.dart';
import 'premium_page.dart';
import 'appearance_page.dart';
import 'wallets_page.dart';
import 'profile_page.dart';
import 'backup_page.dart';
import '../providers/currency_provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        systemOverlayStyle: Theme.of(context).brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        children: [
          _buildSectionHeader('MEMBERSHIP'),
          Consumer(
            builder: (context, ref, child) {
              final isProAsync = ref.watch(proProvider);
              return isProAsync.when(
                data: (isPro) => _buildSettingItem(
                  context,
                  icon: Icons.star_border_rounded, // or stars_rounded
                  title: isPro ? 'Pro Member' : 'Upgrade to Pro',
                  subtitle: isPro ? 'Ads Removed' : 'Remove Ads',
                  iconColor: isPro ? AppColors.income : null,
                  onTap: () {
                    if (!isPro) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PremiumPage(),
                        ),
                      );
                    }
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('PREFERENCES'),
          _buildSettingItem(
            context,
            icon: Icons.category_outlined,
            title: 'Categories',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CategoriesPage()),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallets',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WalletsPage()),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.color_lens_outlined,
            title: 'Appearance',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AppearancePage()),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final currencyAsync = ref.watch(currencyProvider);
              return _buildSettingItem(
                context,
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: currencyAsync.asData?.value ?? '\$',
                onTap: () => _showCurrencyDialog(context, ref),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('ACCOUNT'),
          _buildSettingItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.cloud_upload_outlined,
            title: 'Backup & Restore',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BackupPage()),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              // Navigation back to login is handled by AuthWidget stream
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).cardColor, // Use theme card color
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref) {
    const currencies = ['\$', '€', '£', '¥', 'RM', 'Rp', '₹'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final symbol = currencies[index];
              return ListTile(
                title: Text(symbol, style: const TextStyle(fontSize: 18)),
                onTap: () {
                  ref.read(currencyProvider.notifier).setCurrency(symbol);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
