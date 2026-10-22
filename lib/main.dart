import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'room_editor.dart';

void main() {
  runApp(const RoomFitApp());
}

/// Root of Room Fit.
///
/// UX strategy A: every screen renders through [AdaptiveShell], which picks
/// the host platform's idiom (Cupertino on iOS/iPadOS, Material 3 on Android,
/// desktop-aware layout on Windows). Full Fluent controls and goldens land in
/// issue #5; until then, avoid one phone look on every platform.
class RoomFitApp extends StatelessWidget {
  const RoomFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const CupertinoApp(
        title: 'Room Fit',
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      );
    }
    return MaterialApp(
      title: 'Room Fit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AdaptiveShell(
    title: 'Room Fit',
    body: const Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Room sketch is a planning aid, not building-code or accessibility compliance.',
          ),
        ),
        Expanded(child: RoomEditor()),
      ],
    ),
  );
}

/// Platform-native application shell.
///
/// Screens supply [title] and [body] once; this widget decides the idiom.
/// Keep new behavior here (dialogs, buttons, navigation) instead of
/// scattering [defaultTargetPlatform] checks through the screens.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(title)),
        child: SafeArea(child: body),
      );
    }
    final desktop =
        platform == TargetPlatform.windows || platform == TargetPlatform.linux;
    // Desktop pointer input wants compact density; touch keeps the default.
    final theme = Theme.of(context)
        .copyWith(visualDensity: desktop ? VisualDensity.compact : null);
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          // Windows convention: leading actions, no up-button on the root page.
          automaticallyImplyLeading: !desktop,
        ),
        body: SafeArea(
          child: desktop
              ? Padding(padding: const EdgeInsets.all(24), child: body)
              : body,
        ),
      ),
    );
  }
}
