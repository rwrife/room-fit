import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_fit/main.dart';

void main() {
  testWidgets('root shell renders offline home copy', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(const RoomFitApp());

    expect(find.text('Room Fit'), findsOneWidget);
    expect(
      find.textContaining('Check clearances before you haul anything.'),
      findsOneWidget,
    );
    // Planning-aid disclaimer must always be visible on the home screen.
    expect(
      find.textContaining('planning aids, not building-code'),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS renders the Cupertino navigation idiom', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(const RoomFitApp());

    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Windows and Android shell resolve through AdaptiveShell', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(const RoomFitApp());

      // Both idiom families can coexist (Cupertino widgets sit inside a
      // MaterialApp), so identity here is the shell, not any single widget.
      expect(find.byType(AdaptiveShell), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
