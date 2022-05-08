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

import 'package:admob_ads_in_flutter/app_theme.dart';
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
  static const int AD_OPEN_INTERVAL = 2;
  static const String PLEASE_WAIT_STRING = 'Please wait...';
  static const String LETS_GET_STARTED_STRING = 'Let\'s get started!';
  static const String NUM_RUNS_KEY = 'num-invokes';
  final Future<bool> _theFuture = _initGoogleMobileAds();

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
    if (_prefs == null)
      return;

    int numRuns = _numRuns;
    if (++numRuns > AD_OPEN_INTERVAL) numRuns = 0;
    _prefs!.setInt(NUM_RUNS_KEY, numRuns);
  }

  bool get _allowOpenAd {
    return _prefs != null && _numRuns == 0;
  }
  ///
  /// end OpenAd control
  ///

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
        });

        _openAd = ad;
        _openAd!.show();
      }, onAdFailedToLoad: (err) {
        print('OpenAd failed to load: ${err.toString()}');
      }),
      orientation: AppOpenAd.orientationPortrait,
    );
  }

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
                      print('===> building home route');
                      if (_allowOpenAd) {
                        _buttonEnabled = false;
                        WidgetsBinding.instance
                            ?.addPostFrameCallback((_) async {
                          await loadOpenAd();
                        });
                      }
                      _bumpNumRuns();
                      return ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 48.0,
                            vertical: 12.0,
                          ),
                          child: Text(_buttonString),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Theme.of(context).colorScheme.secondary,
                        ),
                        onPressed: _buttonEnabled
                            ? () {
                                Navigator.of(context).pushNamed('/game');
                              }
                            : null,
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

  static void printInitStatus(InitializationStatus initStatus) {
    List<MapEntry<String, AdapterStatus>> entries =
        initStatus.adapterStatuses.entries.toList();
    for (MapEntry entry in entries)
      print(' ======> initStatusKey ${entry.key}: ${entry.value.description}');
  }

  ///
  /// Prevent multiple inits
  /// Should only happen on first instantiation of widget
  /// (we have to wait for it, though, so that's the FutureBuilder's job)
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
