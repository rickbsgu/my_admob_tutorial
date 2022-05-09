// Copyright 2022 Aphorica, Inc
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
import 'package:flutter/material.dart';
import 'package:admob_ads_in_flutter/ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:admob_ads_in_flutter/app_theme.dart';

class NativeRoute extends StatefulWidget {
  @override
  _NativeRouteState createState() => _NativeRouteState();
}

class _NativeRouteState extends State<NativeRoute> {
  static List<int> adIXs = [1, 3];
  final List<String> _items = <String>[
    'Apple',
    'Orange',
    'Banana',
    'Plum',
    'Grapes',
    'Tangerine'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (BuildContext context, int ix) {
              return Container(
                child: ListTile(
                  title: Text(_items[ix]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
