import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../providers/pro_provider.dart';
import '../providers/settings_provider.dart';
import 'premium_page.dart';
import 'appearance_page.dart';
import 'wallets_page.dart';

import '../providers/currency_provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(currencyProvider);
    final isProAsync = ref.watch(proProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (settings) {
            return Stack(
              children: [
                // Background Elements
                Positioned(
                  top: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'assets/images/cat_top_right.png',
                      width: 120,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ),
                ),

                // Top Content
                Column(
                  children: [
                    const SizedBox(height: 16),
                    // Header: Membership Pill
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          const Spacer(),

                          // Membership Pill
                          isProAsync.when(
                            data: (isPro) => GestureDetector(
                              onTap: isPro
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PremiumPage(),
                                        ),
                                      );
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pastelRed.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.card_membership,
                                      size: 20,
                                      color: isPro
                                          ? AppColors.textDark
                                          : AppColors.pastelRed,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isPro ? 'Life member' : 'Join member 20%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPro
                                            ? AppColors.textDark
                                            : AppColors.pastelRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Draggable Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.7,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Main Container
                        Container(
                          margin: const EdgeInsets.only(top: 25),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFDF5),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              top: 40,
                              left: 16,
                              right: 16,
                              bottom: 100,
                            ),
                            children: [
                              // SECTION: CUSTOM
                              _buildSectionHeader(
                                'Custom',
                                color: AppColors.pastelRed,
                              ),

                              // Membership
                              _buildModernSettingItem(
                                context,
                                icon: Icons.card_giftcard,
                                iconColor: AppColors.pastelOrange,
                                title: 'Membership',
                                subtitle: 'Unlock all features',
                                trailing: const Text(
                                  '20% off',
                                  style: TextStyle(
                                    color: AppColors.pastelRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PremiumPage(),
                                    ),
                                  );
                                },
                              ),

                              // Dark Theme
                              _buildModernSettingItem(
                                context,
                                icon: Icons.dark_mode,
                                iconColor: AppColors.textDark,
                                title: 'Dark theme setting',
                                subtitle: 'Switch to dark theme',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AppearancePage(),
                                    ),
                                  );
                                },
                              ),

                              // Language
                              _buildModernSettingItem(
                                context,
                                icon: Icons.language,
                                iconColor: Colors.grey,
                                title: 'Switch language',
                                subtitle: _getLanguageName(
                                  settings.locale.languageCode,
                                ),
                                onTap: () =>
                                    _showLanguageDialog(context, ref, settings),
                              ),

                              // Monthly Start Date
                              _buildModernSettingItem(
                                context,
                                icon: Icons.calendar_month,
                                iconColor: AppColors.textDark,
                                title: 'Monthly start date',
                                subtitle:
                                    '${settings.monthlyStartDate}${_getDaySuffix(settings.monthlyStartDate)} day of each month',
                                onTap: () => _showStartDateDialog(
                                  context,
                                  ref,
                                  settings,
                                ),
                              ),

                              // First day of week
                              _buildModernSettingItem(
                                context,
                                icon: Icons.calendar_today,
                                iconColor: AppColors.textDark,
                                title: 'First day of the week',
                                subtitle: _getDayName(settings.firstDayOfWeek),
                                onTap: () => _showWeekStartDialog(
                                  context,
                                  ref,
                                  settings,
                                ),
                              ),

                              // Currency
                              _buildModernSettingItem(
                                context,
                                icon: Icons.monetization_on,
                                iconColor: AppColors.textDark,
                                title: 'Currency symbol',
                                subtitle:
                                    'Display the currency symbol before the amount',
                                trailing: Text(
                                  currencySymbol,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () => _showCurrencyDialog(context, ref),
                              ),

                              // Comma Separator
                              _buildModernSettingItem(
                                context,
                                icon: Icons.format_quote,
                                iconColor: AppColors.textDark,
                                title: 'Comma separator',
                                subtitle: 'Show the comma currency separator',
                                trailing: Switch(
                                  value: settings.useCommaSeparator,
                                  onChanged: (val) {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .setCommaSeparator(val);
                                  },
                                  activeTrackColor: AppColors.pastelRed,
                                ),
                                onTap: () {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setCommaSeparator(
                                        !settings.useCommaSeparator,
                                      );
                                },
                              ),

                              // Fingerprint
                              _buildModernSettingItem(
                                context,
                                icon: Icons.fingerprint,
                                iconColor: AppColors.textDark,
                                title: 'Fingerprint lock',
                                subtitle:
                                    'Need to enter fingerprint when open app',
                                trailing: Switch(
                                  value: settings.isBiometricEnabled,
                                  onChanged: (val) async {
                                    await _handleBiometricToggle(
                                      context,
                                      ref,
                                      val,
                                    );
                                  },
                                  activeTrackColor: AppColors.pastelRed,
                                ),
                                onTap: () async {
                                  await _handleBiometricToggle(
                                    context,
                                    ref,
                                    !settings.isBiometricEnabled,
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // SECTION: MANAGEMENT
                              _buildSectionHeader(
                                'Management',
                                color: AppColors.pastelRed,
                              ),

                              _buildModernSettingItem(
                                context,
                                icon: Icons.category,
                                iconColor: AppColors.textDark,
                                title: 'Record category management',
                                subtitle:
                                    'Add, modify and sort record categories',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CategoriesPage(),
                                    ),
                                  );
                                },
                              ),

                              _buildModernSettingItem(
                                context,
                                icon: Icons.book,
                                iconColor: AppColors.textDark,
                                title: 'Ledger',
                                subtitle: 'Manage the ledgers',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const WalletsPage(),
                                    ),
                                  );
                                },
                              ),

                              _buildModernSettingItem(
                                context,
                                icon: Icons.autorenew,
                                iconColor: AppColors.textDark,
                                title: 'Recurring record',
                                subtitle: 'Automatic recurring record',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.work,
                                iconColor: AppColors.textDark,
                                title: 'Reimburse',
                                subtitle: 'Manage the reimbursement',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.star,
                                iconColor: AppColors.textDark,
                                title: 'Bookmarks',
                                subtitle: 'Manage the bookmarks',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.pie_chart,
                                iconColor: AppColors.textDark,
                                title: 'Budget',
                                subtitle: 'Manage the category budgets',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.exit_to_app,
                                iconColor: AppColors.textDark,
                                title: 'Bill Export',
                                subtitle:
                                    'The bill will be exported to a csv format file',
                                onTap: () {},
                              ),

                              const SizedBox(height: 24),

                              // SECTION: ABOUT US
                              _buildSectionHeader(
                                'About Us',
                                color: AppColors.pastelRed,
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.thumb_up,
                                iconColor: AppColors.textDark,
                                title: 'Rate',
                                subtitle: 'Rate us on the Play Store!',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.lock,
                                iconColor: AppColors.textDark,
                                title: 'Privacy Policy',
                                subtitle:
                                    'See the privacy policy for more information.',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.info,
                                iconColor: AppColors.textDark,
                                title: 'About',
                                subtitle: 'Version 1.0.0',
                                onTap: () {},
                              ),
                              _buildModernSettingItem(
                                context,
                                icon: Icons.logout,
                                iconColor: AppColors.textDark,
                                title: 'Logout',
                                subtitle: 'Sign out from current account',
                                onTap: () async {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .signOut();
                                },
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Peeking Cat
                        Positioned(
                          top: 0,
                          child: Image.asset(
                            'assets/images/cat_peek.png',
                            width: 60,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: const Icon(Icons.pets, size: 20),
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    Color color = AppColors.pastelRed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 0),
      child: Text(
        title,
        style: TextStyle(
          color: color, // Header color from image
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModernSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.grey, size: 24),
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
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  // --- Logic Helpers ---

  String _getLanguageName(String code) {
    switch (code) {
      case 'ms':
        return 'Bahasa Melayu';
      case 'id':
        return 'Bahasa Indonesia';
      default:
        return 'English';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    // day is 1-7
    if (day < 1 || day > 7) return 'Sunday';
    return days[day - 1];
  }

  Future<void> _handleBiometricToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (value) {
      // Trying to enable
      final authService = ref.read(authServiceProvider);
      final canCheck = await authService.isBiometricAvailable();
      if (!canCheck) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biometric authentication is not available on this device.',
              ),
            ),
          );
        }
        return;
      }

      final authenticated = await authService.authenticate();
      if (authenticated) {
        await notifier.setBiometricEnabled(true);
      }
    } else {
      // Disable
      await notifier.setBiometricEnabled(false);
    }
  }

  // --- Dialogs ---

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        backgroundColor: const Color(0xFFFFFDF5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile(context, ref, 'English', 'en', settings),
            _buildRadioTile(context, ref, 'Bahasa Melayu', 'ms', settings),
            _buildRadioTile(context, ref, 'Bahasa Indonesia', 'id', settings),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(
    BuildContext context,
    WidgetRef ref,
    String label,
    String code,
    SettingsState settings,
  ) {
    final currentCode = settings.locale.languageCode;
    return RadioListTile<String>(
      title: Text(label),
      value: code,
      // ignore: deprecated_member_use
      groupValue: currentCode,
      activeColor: AppColors.pastelRed,
      // ignore: deprecated_member_use
      onChanged: (val) {
        if (val != null) {
          ref.read(settingsProvider.notifier).setLocale(val);
          Navigator.pop(context);
        }
      },
    );
  }

  void _showStartDateDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Monthly Start Date'),
        backgroundColor: const Color(0xFFFFFDF5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: 28,
            itemBuilder: (context, index) {
              final day = index + 1;
              return ListTile(
                title: Text('$day${_getDaySuffix(day)}'),
                selected: settings.monthlyStartDate == day,
                selectedColor: AppColors.pastelRed,
                onTap: () {
                  ref.read(settingsProvider.notifier).setMonthlyStartDate(day);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showWeekStartDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select First Day of Week'),
        backgroundColor: const Color(0xFFFFFDF5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDayTile(context, ref, 'Monday', 1, settings),
            _buildDayTile(context, ref, 'Sunday', 7, settings),
            _buildDayTile(context, ref, 'Saturday', 6, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(
    BuildContext context,
    WidgetRef ref,
    String label,
    int day,
    SettingsState settings,
  ) {
    return ListTile(
      title: Text(label),
      selected: settings.firstDayOfWeek == day,
      selectedColor: AppColors.pastelRed,
      onTap: () {
        ref.read(settingsProvider.notifier).setFirstDayOfWeek(day);
        Navigator.pop(context);
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref) {
    const currencies = ['\$', '€', '£', '¥', 'RM', 'Rp', '₹'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFDF5),
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
