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

import 'package:admob_ads_in_flutter/ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:admob_ads_in_flutter/app_theme.dart';
import 'package:admob_ads_in_flutter/drawing.dart';
import 'package:admob_ads_in_flutter/drawing_painter.dart';
import 'package:admob_ads_in_flutter/quiz_manager.dart';
import 'package:admob_ads_in_flutter/banner_ad_svc.dart';
import 'package:flutter/material.dart';

class GameRoute extends StatefulWidget {
  @override
  _GameRouteState createState() => _GameRouteState();
}

class _GameRouteState extends State<GameRoute> implements QuizEventListener {
  late int _level;

  late Drawing _drawing;

  late String _clue;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  late RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  @override
  void initState() {
    super.initState();

    QuizManager.instance
      ..listener = this
      ..startGame();

    _loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    'Level $_level/5',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          String _answer = '';

                          return AlertDialog(
                            title: const Text('Enter your answer'),
                            content: TextField(
                              autofocus: true,
                              onChanged: (value) {
                                _answer = value;
                              },
                            ),
                            actions: [
                              TextButton(
                                child: Text('submit'.toUpperCase()),
                                onPressed: () {
                                  Navigator.pop(context);
                                  QuizManager.instance.checkAnswer(_answer);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Text(
                        _clue,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Card(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: DrawingPainter(
                              drawing: _drawing,
                            ),
                          ),
                        )
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                ],
              ),
            ),
            if (BannerAdSvc.instance.isBannerAdReady)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: BannerAdSvc.instance.ad.size.width.toDouble(),
                  height: BannerAdSvc.instance.ad.size.height.toDouble(),
                  child: AdWidget(ad: BannerAdSvc.instance.ad),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: ButtonBar(
          alignment: MainAxisAlignment.start,
          children: [
            TextButton(
              child: Text('Skip this level'.toUpperCase()),
              onPressed: () {
                QuizManager.instance.nextLevel();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return /*!QuizManager.instance.isHintUsed &&*/ _isRewardedAdReady
        ? FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        title: Text('Need a hint?'),
                        content: Text('Watch an Ad to get a hint...'),
                        actions: [
                          TextButton(
                              child: Text('ok'.toUpperCase()),
                              onPressed: () {
                                Navigator.pop(context);
                                _rewardedAd?.show(
                                    onUserEarnedReward: (_, reward) {
                                  QuizManager.instance.useHint();
                                });
                              })
                        ]);
                  });
            },
            label: Text('Hint'),
            icon: Icon(Icons.card_giftcard),
          )
        : null;
  }

  void _moveToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
          _interstitialAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
            _moveToHome();
          });

          _isInterstitialAdReady = true;
        }, onAdFailedToLoad: (err) {
          print('Failed to laod an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        }));
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
            setState(() {
              _isRewardedAdReady = false;
            });
            _loadRewardedAd();
          });

          setState(() {
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();

    QuizManager.instance.listener = null;

    super.dispose();
  }

  @override
  void onWrongAnswer() {
    _showSnackBar('Wrong answer!');
  }

  @override
  void onNewLevel(int level, Drawing drawing, String clue) {
    setState(() {
      _level = level;
      _drawing = drawing;
      _clue = clue;
    });

    if (level > 3 && !_isInterstitialAdReady) _loadInterstitialAd();
  }

  @override
  void onLevelCleared() {
    _showSnackBar('Is done!!');
  }

  @override
  void onGameOver(int correctAnswers) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game over!'),
          content: Text('Score: $correctAnswers/5'),
          actions: [
            TextButton(
              child: Text('close'.toUpperCase()),
              onPressed: () {
                if (_isInterstitialAdReady)
                  _interstitialAd?.show();
                else
                  _moveToHome();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void onClueUpdated(String clue) {
    setState(() {
      _clue = clue;
    });

    _showSnackBar('You\'ve got one more clue!');
  }
}
