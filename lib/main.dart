import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'features/onboarding/presentation/pages/splash_screen.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'features/common/data/default_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize local database
  await DatabaseService.database;
  // Seed default data on first launch
  await DefaultDataService.ensureDefaults();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const ProviderScope(child: NekoApp()));
}

class NekoApp extends StatelessWidget {
  const NekoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        return MaterialApp(
          title: 'Neko Money Manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          builder: (context, child) {
            return AppLifecycleManager(child: child ?? const SizedBox());
          },
        );
      },
    );
  }
}

class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleManager> createState() =>
      _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
