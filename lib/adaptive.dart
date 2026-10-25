import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

/// Platform-native application shell.
///
/// Screens supply [title] and [body] once; this widget chooses the host
/// platform idiom (UX strategy A): Cupertino on iOS/iPadOS, Material 3 on
/// Android, Fluent on Windows. Keep platform selection here rather than
/// spreading `defaultTargetPlatform` checks through feature screens.
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
    if (platform == TargetPlatform.windows) {
      return fluent.NavigationView(
        content: fluent.ScaffoldPage(
          header: fluent.PageHeader(title: Text(title)),
          content: Padding(padding: const EdgeInsets.all(16), child: body),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: body),
    );
  }
}

/// Command bar for editor actions.
///
/// Phones (narrow than the 768 logical px tablet breakpoint) get a
/// horizontally scrollable rail so touch targets stay full size; tablets and
/// desktop windows wrap the same controls onto extra rows.
class AdaptiveActions extends StatelessWidget {
  const AdaptiveActions({super.key, required this.children});

  final List<Widget> children;

  static const double tabletBreakpoint = 768;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final padded = [
        for (final child in children)
          Padding(padding: const EdgeInsets.all(2), child: child),
      ];
      if (constraints.maxWidth < tabletBreakpoint) {
        return SingleChildScrollView(
          key: const Key('adaptiveActionsRail'),
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: padded),
        );
      }
      return Wrap(key: const Key('adaptiveActionsWrap'), children: padded);
    },
  );
}

/// Thin action-button dispatcher: Cupertino button on iOS, Fluent button on
/// Windows, Material 3 outlined button on Android. All variants keep a
/// 44-logical-px minimum touch target.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoButton(
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    if (platform == TargetPlatform.windows) {
      return SizedBox(
        height: 44,
        child: fluent.Button(
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label),
          ),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Semantics(label: label, child: Text(label)),
      ),
    );
  }
}

/// Native text input used by every measurement dialog.
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoTextField(controller: controller, placeholder: label);
    }
    if (platform == TargetPlatform.windows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: fluent.FluentTheme.of(context).typography.body),
          fluent.TextBox(controller: controller, placeholder: label),
        ],
      );
    }
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }
}
