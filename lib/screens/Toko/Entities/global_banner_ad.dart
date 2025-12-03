import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// 📌 Usaremos la constante del Ad Unit ID de tu main.dart
const String globalBannerAdUnitId = 'ca-app-pub-9552343552775183/8528790922';

class GlobalBannerAdWidget extends StatefulWidget {
  const GlobalBannerAdWidget({super.key});

  @override
  State<GlobalBannerAdWidget> createState() => _GlobalBannerAdWidgetState();
}

class _GlobalBannerAdWidgetState extends State<GlobalBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (_bannerAd != null) return;

    _bannerAd = BannerAd(
      adUnitId: globalBannerAdUnitId,
      size: AdSize.fullBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() { _isAdLoaded = true; });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() { _isAdLoaded = false; });
          _bannerAd = null;
        },
        onAdOpened: (ad) => print('AD_ACTION: Banner abierto.'),
        onAdClosed: (ad) => print('AD_ACTION: Banner cerrado.'),
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Display the loaded ad widget
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
