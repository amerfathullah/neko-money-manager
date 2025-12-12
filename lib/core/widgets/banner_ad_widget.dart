import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/pro_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Use test unit ID
    // Android: ca-app-pub-3940256099942544/6300978111
    // iOS: ca-app-pub-3940256099942544/2934735716
    // We can detecting platform, but for now lets use a safe Android test ID as default or check Platform.io
    // Since we are developing for Android mainly as per previous logs (or generic), I'll add platform check.
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(proProvider);

    return isProAsync.when(
      data: (isPro) {
        if (kIsWeb || isPro)
          return const SizedBox.shrink(); // No ad for Pro users or Web

        if (_bannerAd == null && !_isAdLoaded) {
          _bannerAd = BannerAd(
            adUnitId:
                'ca-app-pub-3940256099942544/6300978111', // Test Banner ID
            size: AdSize.banner,
            request: const AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (_) {
                setState(() {
                  _isAdLoaded = true;
                });
              },
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
                debugPrint('Ad failed to load: $error');
              },
            ),
          )..load();
        }

        if (_isAdLoaded && _bannerAd != null) {
          return SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
        }
        return const SizedBox.shrink(); // No placeholder needed
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
