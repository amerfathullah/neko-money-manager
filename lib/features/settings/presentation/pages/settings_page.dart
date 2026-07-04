import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../categories/presentation/pages/categories_page.dart';

import '../providers/settings_provider.dart';
import 'appearance_page.dart';
import 'ledgers_page.dart';
import '../../../transactions/presentation/pages/reimbursements_page.dart';
import '../../../transactions/presentation/pages/bookmarks_page.dart';

import '../providers/currency_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currencyAsync = ref.watch(currencyProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: themeColors.background, // Cream background
      appBar: AppBar(
        backgroundColor: themeColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: themeColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: themeColors.text),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100, // Extra padding for bottom nav bar
            ),
            children: [
              // SECTION: CUSTOM
              _buildSectionHeader('Custom', color: primaryColor),

              // Dark Theme
              _buildModernSettingItem(
                context,
                icon: Icons.dark_mode,
                iconColor: themeColors.text,
                title: 'Dark theme setting',
                subtitle: 'Switch to dark theme',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AppearancePage(),
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
                subtitle: _getLanguageName(settings.locale.languageCode),
                onTap: () => _showLanguageDialog(context, ref, settings),
              ),

              // Monthly Start Date
              _buildModernSettingItem(
                context,
                icon: Icons.calendar_month,
                iconColor: themeColors.text,
                title: 'Monthly start date',
                subtitle:
                    '${settings.monthlyStartDate}${_getDaySuffix(settings.monthlyStartDate)} day of each month',
                onTap: () => _showStartDateDialog(context, ref, settings),
              ),

              // First day of week
              _buildModernSettingItem(
                context,
                icon: Icons.calendar_today,
                iconColor: themeColors.text,
                title: 'First day of the week',
                subtitle: _getDayName(settings.firstDayOfWeek),
                onTap: () => _showWeekStartDialog(context, ref, settings),
              ),

              // Currency
              _buildModernSettingItem(
                context,
                icon: Icons.monetization_on,
                iconColor: themeColors.text,
                title: 'Currency symbol',
                subtitle: 'Display the currency symbol before the amount',
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
                iconColor: themeColors.text,
                title: 'Comma separator',
                subtitle: 'Show the comma currency separator',
                trailing: Switch(
                  value: settings.useCommaSeparator,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setCommaSeparator(val);
                  },
                  activeTrackColor: primaryColor,
                ),
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setCommaSeparator(!settings.useCommaSeparator);
                },
              ),

              const SizedBox(height: 24),

              // SECTION: MANAGEMENT
              _buildSectionHeader('Management', color: primaryColor),

              _buildModernSettingItem(
                context,
                icon: Icons.category,
                iconColor: themeColors.text,
                title: 'Record category management',
                subtitle: 'Add, modify and sort record categories',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoriesPage(),
                    ),
                  );
                },
              ),

              _buildModernSettingItem(
                context,
                icon: Icons.book,
                iconColor: themeColors.text,
                title: 'Ledger',
                subtitle: 'Manage the ledgers',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LedgersPage(),
                    ),
                  );
                },
              ),

              _buildModernSettingItem(
                context,
                icon: Icons.autorenew,
                iconColor: themeColors.text,
                title: 'Recurring record',
                subtitle: 'Automatic recurring record',
                onTap: () {},
              ),
              _buildModernSettingItem(
                context,
                icon: Icons.work,
                iconColor: themeColors.text,
                title: 'Reimburse',
                subtitle: 'Manage the reimbursement',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReimbursementsPage(),
                    ),
                  );
                },
              ),
              _buildModernSettingItem(
                context,
                icon: Icons.star,
                iconColor: themeColors.text,
                title: 'Bookmarks',
                subtitle: 'Manage the bookmarks',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BookmarksPage(),
                    ),
                  );
                },
              ),
              _buildModernSettingItem(
                context,
                icon: Icons.pie_chart,
                iconColor: themeColors.text,
                title: 'Budget',
                subtitle: 'Manage the category budgets',
                onTap: () {},
              ),
              _buildModernSettingItem(
                context,
                icon: Icons.exit_to_app,
                iconColor: themeColors.text,
                title: 'Bill Export',
                subtitle: 'The bill will be exported to a csv format file',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // SECTION: ABOUT US
              _buildSectionHeader('About Us', color: primaryColor),
              _buildModernSettingItem(
                context,
                icon: Icons.thumb_up,
                iconColor: themeColors.text,
                title: 'Rate',
                subtitle: 'Rate us on the Play Store!',
                onTap: () {},
              ),
              _buildModernSettingItem(
                context,
                icon: Icons.lock,
                iconColor: themeColors.text,
                title: 'Privacy Policy',
                subtitle: 'See the privacy policy for more information.',
                onTap: () {},
              ),
              _buildModernSettingItem(
                context,
                icon: Icons.info,
                iconColor: themeColors.text,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
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
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColors.textSubtle,
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
        backgroundColor: Theme.of(context).extension<AppThemeColors>()!.surface,
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
      activeColor: Theme.of(context).primaryColor,
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
        backgroundColor: Theme.of(context).extension<AppThemeColors>()!.surface,
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
                selectedColor: Theme.of(context).primaryColor,
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
        backgroundColor: Theme.of(context).extension<AppThemeColors>()!.surface,
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
      selectedColor: Theme.of(context).primaryColor,
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
        backgroundColor: Theme.of(context).extension<AppThemeColors>()!.surface,
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
