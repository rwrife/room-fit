import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:room_fit/adaptive.dart';
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
  // Tall surface so every control row is on screen; the chrome scrolls on
  // short phone windows.
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
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
        } else if (platform == TargetPlatform.windows) {
          expect(find.byType(fluent.NavigationView), findsOneWidget);
          expect(find.byType(fluent.PageHeader), findsOneWidget);
          expect(find.byType(fluent.Button), findsWidgets);
          // Windows must not render Material chrome or Cupertino chrome.
          expect(find.byType(Scaffold), findsNothing);
          expect(find.byType(CupertinoNavigationBar), findsNothing);
        } else {
          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(OutlinedButton), findsWidgets);
          expect(find.byType(fluent.NavigationView), findsNothing);
        }
      });
    });
  }

  for (final width in [360.0, 768.0, 1280.0]) {
    for (final platform in [
      TargetPlatform.iOS,
      TargetPlatform.android,
      TargetPlatform.windows,
    ]) {
      testWidgets('$platform action layout at ${width.toInt()} px', (
        tester,
      ) async {
        await _onPlatform(tester, platform, () async {
          // Drive the breakpoint from the real layout constraint instead of
          // the window size, since each shell adds its own padding.
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: AdaptiveActions(
                    children: const [Text('Room size'), Text('Catalog')],
                  ),
                ),
              ),
            ),
          );
          final rail = find.byWidgetPredicate(
            (w) => w.key == const Key('adaptiveActionsRail'),
          );
          final wrap = find.byWidgetPredicate(
            (w) => w.key == const Key('adaptiveActionsWrap'),
          );
          if (width < AdaptiveActions.tabletBreakpoint) {
            expect(rail, findsOneWidget);
            expect(wrap, findsNothing);
          } else {
            expect(wrap, findsOneWidget);
            expect(rail, findsNothing);
          }
          expect(tester.takeException(), isNull);
        });
      });
    }
  }

  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform measurement dialog uses native controls', (
      tester,
    ) async {
      await _onPlatform(tester, platform, () async {
        await tester.pumpWidget(const RoomFitApp());
        await tester.tap(find.text('Room size'));
        await tester.pumpAndSettle();
        if (platform == TargetPlatform.iOS) {
          expect(find.byType(CupertinoAlertDialog), findsOneWidget);
          expect(find.byType(CupertinoTextField), findsNWidgets(2));
        } else if (platform == TargetPlatform.windows) {
          expect(find.byType(fluent.ContentDialog), findsOneWidget);
          expect(find.byType(fluent.TextBox), findsNWidgets(2));
        } else {
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.byType(TextField), findsNWidgets(2));
        }
        await tester.enterText(find.byKey(const Key('field-0')), '5000');
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Room 5000 × 3000 mm'), findsOneWidget);
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

  testWidgets('Tab cycles selection, overlap warns, target is selectable', (
    tester,
  ) async {
    await _onPlatform(tester, TargetPlatform.windows, () async {
      await tester.pumpWidget(const RoomFitApp());
      expect(find.textContaining('No fit warnings'), findsOneWidget);
      expect(find.textContaining('Sampled walkway ~'), findsOneWidget);
      expect(find.textContaining('(approx.)'), findsOneWidget);

      for (final name in ['Shelf A', 'Shelf B']) {
        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('field-0')), name);
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
      }

      expect(
        find.textContaining(
          'Selected Shelf B · 900 × 600 mm (~35.4 × 23.6 in)',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Overlap — Furniture 0 and 1 overlap (approximate)',
        ),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.textContaining('Selected Shelf A'), findsOneWidget);

      await tester.tap(find.text('900 mm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sampled walkway ~'), findsOneWidget);
    });
  });
}
