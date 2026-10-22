import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_fit/main.dart';
import 'package:room_fit/room_editor.dart';

/// flutter_test verifies foundation debug vars before tearDowns run, so the
/// platform override is cleared inside the test body via try/finally.
Future<void> _onPlatform(
  WidgetTester tester,
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform renders editor in native shell', (tester) async {
      await _onPlatform(tester, platform, () async {
        await tester.pumpWidget(const RoomFitApp());
        expect(find.byType(AdaptiveShell), findsOneWidget);
        expect(find.byType(RoomEditor), findsOneWidget);
        expect(find.byKey(const Key('roomCanvas')), findsOneWidget);
        expect(find.textContaining('Room 4000 × 3000 mm'), findsOneWidget);
        expect(
          find.textContaining('not building-code or accessibility'),
          findsWidgets,
        );
        if (platform == TargetPlatform.iOS) {
          expect(find.byType(CupertinoNavigationBar), findsOneWidget);
          expect(find.byType(CupertinoButton), findsWidgets);
        } else {
          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(OutlinedButton), findsWidgets);
        }
      });
    });
  }

  testWidgets('custom furniture rotates, nudges, and undoes', (tester) async {
    await _onPlatform(tester, TargetPlatform.android, () async {
      await tester.pumpWidget(const RoomFitApp());
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-0')), 'My shelf');
      await tester.enterText(find.byKey(const Key('field-1')), '700');
      await tester.enterText(find.byKey(const Key('field-2')), '300');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Selected My shelf · 700 × 300 mm'),
        findsOneWidget,
      );

      await tester.tap(find.text('Rotate 90°'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Selected My shelf · 300 × 700 mm'),
        findsOneWidget,
      );

      await tester.tap(find.text('Nudge right'));
      await tester.pumpAndSettle();
      expect(find.textContaining('at 200, 100 mm'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('at 100, 100 mm'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No furniture yet'), findsOneWidget);
    });
  });

  testWidgets('room size and opening entry reject invalid values', (
    tester,
  ) async {
    await _onPlatform(tester, TargetPlatform.android, () async {
      await tester.pumpWidget(const RoomFitApp());
      await tester.tap(find.text('Room size'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-0')), '5000');
      await tester.enterText(find.byKey(const Key('field-1')), '3500');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Room 5000 × 3500 mm'), findsOneWidget);

      // Out-of-range value must be refused and leave the plan untouched.
      await tester.tap(find.text('Room size'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-0')), '0');
      await tester.enterText(find.byKey(const Key('field-1')), '3500');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Room 5000 × 3500 mm'), findsOneWidget);

      await tester.tap(find.text('Add opening'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('roomCanvas')), findsOneWidget);
    });
  });

  testWidgets('catalog adds a scaled footprint', (tester) async {
    await _onPlatform(tester, TargetPlatform.windows, () async {
      await tester.pumpWidget(const RoomFitApp());
      await tester.tap(find.text('Catalog'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('catalog-queen_bed')),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('catalog-queen_bed')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Selected Queen Bed · 1520 × 2030 mm'),
        findsOneWidget,
      );
    });
  });
}
