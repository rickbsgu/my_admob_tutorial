import 'package:admob_ads_in_flutter/ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

///
/// Because we're using the banner ad in multiple places, we need to
/// factor it out.
class BannerAdSvc {
  static BannerAdSvc? _instance;
  static BannerAdSvc get instance {
    return _instance ??= BannerAdSvc._();
  }

  BannerAdSvc._();

  Future<bool> loadAd() {
    Completer<bool> completer = Completer<bool>();
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _isBannerAdReady = true;
          completer.complete(true);
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
          completer.completeError(err);
        },
      ),
    );

    _bannerAd.load();
    return completer.future;
  }

  void dispose() {
    _bannerAd.dispose();
  }

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  bool get isBannerAdReady => _isBannerAdReady;
  BannerAd get ad => _bannerAd;
}
