// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/// # AppOpenAd implementation
/// This version adds an _AppOpenAd_ that opens a full page ad when the
/// app opens.  To make it a little more interesting, I've added a counter
/// so that it only opens every AD_OPEN_INTERVAL times (you can change this).
///
/// It's a little more involved, because we need to keep track of the
/// number of opens (runs), and we need to control the main button state
/// and text.  I'm using SharedPreferences to keep track of the current
/// run number so it persists between invocations.
///
/// To see it work, run the app and then hit 'SKIP THIS LEVEL' for all of the images
/// and dismiss the interstitial ad.  After AD_OPEN_INTERVAL times of the full
/// sequence, the _AppOpenAd_ should show.
///
/// I've also changed how GoogleAds is initialized: in the initial version, the
/// initializer gets called on every build.  It should only get called once, but
/// when it does get called, it should control the FutureBuilder, so we can't
/// do it in the main() function if we want it to do that.
///

import 'package:admob_ads_in_flutter/app_theme.dart';
import 'package:admob_ads_in_flutter/banner_ad_svc.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:admob_ads_in_flutter/ad_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRoute extends StatefulWidget {
  @override
  _HomeRouteState createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  static const int AD_OPEN_INTERVAL = 3;
  static const String PLEASE_WAIT_STRING = 'Please wait...';
  static const String LETS_GET_STARTED_STRING = 'Let\'s get started!';
  static const String NUM_RUNS_KEY = 'num-runs';
  final Future<bool> _theFuture = _initServices();

  static bool _adsInitialized = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _buttonEnabled = !_allowOpenAd;
      });
    });
  }

  static SharedPreferences? _prefs;

  ///
  /// beg button enabled state and string control
  ///
  String __buttonString = LETS_GET_STARTED_STRING;
  bool __buttonEnabled = false;

  bool get _buttonEnabled => __buttonEnabled;
  String get _buttonString => __buttonString;

  set _buttonEnabled(bool enabled) {
    __buttonString = enabled ? LETS_GET_STARTED_STRING : PLEASE_WAIT_STRING;
    __buttonEnabled = enabled;
  }

  //
  // end button enabled state and string control
  // begin OpenAd control
  //
  AppOpenAd? _openAd;

  int get _numRuns => _prefs!.getInt(NUM_RUNS_KEY) ?? 0;

  void _bumpNumRuns() {
    if (_prefs == null) return;

    int numRuns = _numRuns;
    if (++numRuns > AD_OPEN_INTERVAL) numRuns = 0;
    _prefs!.setInt(NUM_RUNS_KEY, numRuns);
  }

  bool get _allowOpenAd {
    return _prefs != null && _numRuns == 0;
  }

  Future<void> loadOpenAd() async {
    AppOpenAd.load(
      adUnitId: AdHelper.openAdUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(onAdLoaded: (ad) {
        ad.fullScreenContentCallback =
            FullScreenContentCallback(onAdDismissedFullScreenContent: (_) {
          setState(() {
            _buttonEnabled = true;
          });
          ad.dispose();
          _openAd = null;
        });

        _openAd = ad;
        _openAd!.show();
      }, onAdFailedToLoad: (err) {
        print('OpenAd failed to load: ${err.toString()}');
      }),
      orientation: AppOpenAd.orientationPortrait,
    );
  }

  ///
  /// end openAdControl
  ///

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: FutureBuilder<bool>(
        future: _theFuture,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Awesome Drawing Quiz!",
                  style: TextStyle(
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                ),
                if (snapshot.hasData)
                  Builder(
                    builder: (BuildContext context) {
                      /**/
                      if (_allowOpenAd) {
                        _buttonEnabled = false;
                        WidgetsBinding.instance
                            ?.addPostFrameCallback((_) async {
                          await loadOpenAd();
                        });
                      }
                      _bumpNumRuns();
                    /**/
                      return Column(
                        children: [
                          ElevatedButton(
                            child: Container(
                              width: 230,
                              height: 38,
                              child: Text(_buttonString),
                              alignment: Alignment.center,
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: _buttonEnabled
                                ? () {
                                    Navigator.of(context)
                                        .pushNamed('/game');
                                  }
                                : null,
                          ),
                          if (_buttonEnabled) ElevatedButton(
                            child: Container(
                              width: 230,
                              height: 38,
                              alignment: Alignment.center,
                              child: Text("Ads in ListView"),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/listview');
                            },
                          ),
                        ],
                      );
                    },
                  )
                else if (snapshot.hasError)
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  )
                else
                  const SizedBox(
                    child: CircularProgressIndicator(),
                    width: 48,
                    height: 48,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  ///
  /// Initialize the shared preferences _and_
  /// GooleMobileAds - return a single future
  /// for FutureBuilder
  static Future<bool> _initServices() async {
    _prefs = await SharedPreferences.getInstance();
    bool adInit = await _initGoogleMobileAds();
    BannerAdSvc.instance.loadAd();
            // don't wait for it - we'll check for it where we need it.

    return adInit;
  }

  ///
  /// Status output for MobileAds.instance.initialize()
  static void printInitStatus(InitializationStatus initStatus) {
    List<MapEntry<String, AdapterStatus>> entries =
        initStatus.adapterStatuses.entries.toList();
    for (MapEntry entry in entries)
      print(' ======> initStatusKey ${entry.key}: ${entry.value.description}');
  }

  ///
  /// Prevent multiple inits of MobileAds -
  /// Should only be initialized once in entire app
  ///
  static Future<bool> _initGoogleMobileAds() {
    // FutureBuilder does not like a Future<void>...

    Completer<bool> completer = Completer<bool>();
    if (!_adsInitialized) {
      print(' ====> calling initializing ads...');
      MobileAds.instance.initialize().then((InitializationStatus initStatus) {
        _adsInitialized = true;
        print(' ====> ads initialized');
        printInitStatus(initStatus);
        completer.complete(true);
      });
    } else {
      print(' ====> repeat initializing call - ignored');
      completer.complete(true);
    }

    return completer.future;
  }
}
