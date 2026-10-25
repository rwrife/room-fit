import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_fit/adaptive.dart';

void main() {
  // Golden rasterization is stable on Linux. Windows CI still runs the
  // platform widget and interaction tests in widget_test.dart.
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform native action golden', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(200, 80);
      tester.view.devicePixelRatio = 1;
      try {
        final button = Center(
          child: AdaptiveButton(label: 'Room size', onPressed: () {}),
        );
        await tester.pumpWidget(switch (platform) {
          TargetPlatform.iOS => CupertinoApp(
            home: CupertinoPageScaffold(child: button),
          ),
          TargetPlatform.windows => fluent.FluentApp(home: button),
          _ => MaterialApp(home: Scaffold(body: button)),
        });
        await expectLater(
          find.byType(AdaptiveButton),
          matchesGoldenFile('goldens/${platform.name}_action.png'),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    }, skip: Platform.isWindows);
  }
}
