import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'adaptive.dart';
import 'room_editor.dart';

void main() {
  runApp(const RoomFitApp());
}

/// Root of Room Fit.
///
/// UX strategy A: every screen renders through [AdaptiveShell], which picks
/// the host platform's idiom (Cupertino on iOS/iPadOS, Material 3 on Android,
/// Fluent on Windows). Keep platform selection at this boundary.
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
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return const fluent.FluentApp(
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
