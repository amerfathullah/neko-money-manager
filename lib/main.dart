import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/splash_screen.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'features/settings/presentation/pages/lock_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();

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
  bool _isLocked = false;
  // Track if we have already checked initial lock state to avoid locking on first launch if undesired,
  // though usually we want to lock on launch if enabled.
  bool _initialized = false;

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background
      final settingsAsync = ref.read(settingsProvider);
      if (settingsAsync.value?.isBiometricEnabled ?? false) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // Initial check when settings are loaded
    settingsAsync.whenData((settings) {
      if (!_initialized) {
        if (settings.isBiometricEnabled) {
          // Lock on startup if enabled
          Future.microtask(() {
            if (mounted && !_initialized) {
              setState(() {
                _isLocked = true;
                _initialized = true;
              });
            }
          });
        } else {
          _initialized = true;
        }
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          LockScreen(
            onUnlock: () {
              setState(() {
                _isLocked = false;
              });
            },
          ),
      ],
    );
  }
}
