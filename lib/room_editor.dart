import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'adaptive.dart';
import 'furniture_catalog.dart';
import 'fit_feedback.dart';
import 'room_geometry.dart';

// ponytail: single room, rectangular footprints, fit-to-view zoom only;
// multi-layout persistence is issue #6, pan-while-zoomed lands when touch
// users need it (wrap canvas in InteractiveViewer then).
class RoomEditor extends StatefulWidget {
  const RoomEditor({super.key});

  @override
  State<RoomEditor> createState() => _RoomEditorState();
}

class _Snapshot {
  _Snapshot(this.plan, this.names);
  final RoomPlan plan;
  final List<String> names;
}

class _RoomEditorState extends State<RoomEditor> {
  static const int gridMm = 100;
  static const List<int> clearanceTargets = [600, 750, 900];

  RoomPlan plan = RoomPlan(width: 4000, height: 3000);
  List<String> names = const [];
  final List<_Snapshot> _history = [];
  int? _selected;
  double _zoom = 1;
  bool _snap = true;
  int _targetIndex = 1;

  // Drag bookkeeping: baseline pointer + piece origin so sub-grid deltas
  // accumulate instead of rounding to zero, plus one undo entry per gesture.
  MmPoint? _dragPointerStart;
  MmPoint? _dragPieceStart;
  _Snapshot? _dragSnapshot;

  bool get _ios =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  bool get _windows => defaultTargetPlatform == TargetPlatform.windows;

  /// Platform-native dialog presentation: ContentDialog on Windows,
  /// Cupertino sheets on iOS, Material dialogs elsewhere.
  Future<T?> _dialog<T>(WidgetBuilder builder) => _windows
      ? fluent.showDialog<T>(context: context, builder: builder)
      : _ios
      ? showCupertinoDialog<T>(context: context, builder: builder)
      : showDialog<T>(context: context, builder: builder);

  /// Small helper text without assuming a Material Theme ancestor (Fluent
  /// apps on Windows have no Material Theme widget above the root).
  TextStyle? _smallText(BuildContext context) => _windows
      ? fluent.FluentTheme.of(context).typography.body?.copyWith(fontSize: 12)
      : _ios
      ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 12)
      : Theme.of(context).textTheme.bodySmall;

  void _commit(RoomPlan next, List<String> nextNames) {
    setState(() {
      _history.add(_Snapshot(plan, names));
      plan = next;
      names = nextNames;
      if (_selected != null && _selected! >= names.length) _selected = null;
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      final previous = _history.removeLast();
      plan = previous.plan;
      names = previous.names;
      if (_selected != null && _selected! >= names.length) _selected = null;
    });
  }

  RoomPlan _copy({
    int? width,
    int? height,
    List<MmRect>? furniture,
    List<Opening>? openings,
  }) => RoomPlan(
    width: width ?? plan.width,
    height: height ?? plan.height,
    furniture: furniture ?? plan.furniture,
    openings: openings ?? plan.openings,
  );

  int _positioned(int value) =>
      _snap ? (value / gridMm).round() * gridMm : value;

  void _place(String name, MmRect rect) {
    _commit(_copy(furniture: [...plan.furniture, rect]), [...names, name]);
    setState(() => _selected = names.length - 1);
  }

  void _moveCommitted(int index, int x, int y) {
    final old = plan.furniture[index];
    final updated = List<MmRect>.of(plan.furniture);
    updated[index] = MmRect(
      _positioned(x),
      _positioned(y),
      old.width,
      old.height,
    );
    _commit(_copy(furniture: updated), names);
  }

  void _rotateSelected() {
    if (_selected == null) return;
    final updated = List<MmRect>.of(plan.furniture);
    final old = updated[_selected!];
    updated[_selected!] = MmRect(old.x, old.y, old.height, old.width);
    _commit(_copy(furniture: updated), names);
  }

  void _removeSelected() {
    if (_selected == null) return;
    final updated = List<MmRect>.of(plan.furniture)..removeAt(_selected!);
    final nextNames = List<String>.of(names)..removeAt(_selected!);
    _commit(_copy(furniture: updated), nextNames);
    setState(() => _selected = null);
  }

  void _selectAt(Offset local, double scale) {
    final x = (local.dx / scale).round();
    final y = (local.dy / scale).round();
    int? hit;
    for (var i = plan.furniture.length - 1; i >= 0; i--) {
      final r = plan.furniture[i];
      if (x >= r.x && x < r.right && y >= r.y && y < r.bottom) {
        hit = i;
        break;
      }
    }
    setState(() => _selected = hit);
  }

  void _dragStart(Offset local, Offset global, double scale) {
    _selectAt(local, scale);
    if (_selected == null) return;
    final r = plan.furniture[_selected!];
    _dragPointerStart = MmPoint(global.dx.round(), global.dy.round());
    _dragPieceStart = MmPoint(r.x, r.y);
    _dragSnapshot = _Snapshot(plan, names);
  }

  void _dragUpdate(Offset global, double scale) {
    if (_selected == null || _dragPointerStart == null) return;
    final dx = ((global.dx - _dragPointerStart!.x) / scale).round();
    final dy = ((global.dy - _dragPointerStart!.y) / scale).round();
    final updated = List<MmRect>.of(plan.furniture);
    final old = updated[_selected!];
    updated[_selected!] = MmRect(
      _positioned(_dragPieceStart!.x + dx),
      _positioned(_dragPieceStart!.y + dy),
      old.width,
      old.height,
    );
    setState(() => plan = _copy(furniture: updated));
  }

  void _dragEnd() {
    if (_dragSnapshot != null) {
      setState(() => _history.add(_dragSnapshot!));
    }
    _dragPointerStart = null;
    _dragPieceStart = null;
    _dragSnapshot = null;
  }

  Future<List<String>?> _fields(
    String title,
    List<String> labels,
    List<String> initial,
  ) => _dialog<List<String>>(
    (context) => _MeasurementDialog(
      title: title,
      labels: labels,
      initial: initial,
      ios: _ios,
      windows: _windows,
    ),
  );

  // Controllers belong to dialog route; route disposal follows exit animation.
  // No controller is disposed while a TextField remains in a transition.

  void _error(String message) {
    if (!mounted) return;
    if (_ios) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid measurement'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (_windows) {
      _dialog<void>(
        (context) => fluent.ContentDialog(
          title: const Text('Invalid measurement'),
          content: Text(message),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  int? _positive(String value, {int min = 1}) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < min || parsed > 100000) return null;
    return parsed;
  }

  Future<void> _editRoom() async {
    final values = await _fields(
      'Room size (mm)',
      const ['Width (mm)', 'Depth (mm)'],
      ['${plan.width}', '${plan.height}'],
    );
    if (values == null || !mounted) return;
    final width = _positive(values[0]);
    final height = _positive(values[1]);
    if (width == null || height == null) {
      _error('Enter positive dimensions up to 100000 mm.');
      return;
    }
    try {
      _commit(_copy(width: width, height: height), names);
    } on ArgumentError catch (e) {
      _error('$e');
    }
  }

  Future<void> _customPiece() async {
    final values = await _fields(
      'Custom furniture',
      const ['Name', 'Width (mm)', 'Depth (mm)'],
      const ['', '900', '600'],
    );
    if (values == null || !mounted) return;
    final width = _positive(values[1]);
    final depth = _positive(values[2]);
    if (values[0].trim().isEmpty || width == null || depth == null) {
      _error('Enter a name and positive dimensions up to 100000 mm.');
      return;
    }
    _place(values[0].trim(), MmRect(gridMm, gridMm, width, depth));
  }

  Future<void> _addOpening() async {
    final values = await _fields(
      'Wall opening (mm)',
      const [
        'Wall (north/east/south/west)',
        'Offset (mm)',
        'Span (mm)',
        'Kind (door/window)',
      ],
      const ['north', '500', '800', 'door'],
    );
    if (values == null || !mounted) return;
    final wall = Wall.values
        .where((w) => w.name == values[0].trim().toLowerCase())
        .firstOrNull;
    final kind = OpeningKind.values
        .where((k) => k.name == values[3].trim().toLowerCase())
        .firstOrNull;
    final offset = _positive(values[1], min: 0);
    final span = _positive(values[2]);
    if (wall == null || kind == null || offset == null || span == null) {
      _error('Use a valid wall and kind, offset >= 0, and positive span.');
      return;
    }
    try {
      _commit(
        _copy(
          openings: [
            ...plan.openings,
            Opening(wall: wall, offset: offset, span: span, kind: kind),
          ],
        ),
        names,
      );
    } on ArgumentError catch (e) {
      _error('$e');
    }
  }

  Future<void> _addFromCatalog() async {
    final item = await _dialog<FurnitureCatalogItem>(
      (context) => _ios
          ? CupertinoAlertDialog(
              title: const Text('Add furniture'),
              content: SizedBox(
                height: 320,
                child: ListView(
                  children: [
                    for (final entry in FurnitureCatalog.items)
                      CupertinoListTile(
                        key: Key('catalog-${entry.id}'),
                        title: Text(
                          '${entry.name} · ${entry.widthMm} × ${entry.depthMm} mm',
                        ),
                        onTap: () => Navigator.pop(context, entry),
                      ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            )
          : _windows
          ? fluent.ContentDialog(
              title: const Text('Add furniture'),
              content: SizedBox(
                height: 360,
                child: ListView(
                  children: [
                    for (final entry in FurnitureCatalog.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: fluent.Button(
                          key: Key('catalog-${entry.id}'),
                          onPressed: () => Navigator.pop(context, entry),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${entry.name} · ${entry.widthMm} × ${entry.depthMm} mm',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                fluent.Button(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            )
          : AlertDialog(
              title: const Text('Add furniture'),
              content: SizedBox(
                height: 360,
                width: 360,
                child: ListView(
                  children: [
                    for (final entry in FurnitureCatalog.items)
                      ListTile(
                        key: Key('catalog-${entry.id}'),
                        title: Text(
                          '${entry.name} · ${entry.widthMm} × ${entry.depthMm} mm',
                        ),
                        onTap: () => Navigator.pop(context, entry),
                      ),
                  ],
                ),
              ),
            ),
    );
    if (item != null && mounted) {
      _place(item.name, item.toRect(x: gridMm, y: gridMm));
    }
  }

  Widget _action(String label, VoidCallback? onPressed) =>
      AdaptiveButton(label: label, onPressed: onPressed);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undo();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (names.isEmpty) return KeyEventResult.ignored;
      final direction = HardwareKeyboard.instance.isShiftPressed ? -1 : 1;
      var next = _selected == null ? 0 : _selected! + direction;
      next = next % names.length;
      if (next < 0) next = names.length - 1;
      setState(() => _selected = next);
      return KeyEventResult.handled;
    }
    if (_selected == null) return KeyEventResult.ignored;
    final coarse = HardwareKeyboard.instance.isShiftPressed;
    final step = coarse ? 100 : (_snap ? gridMm : 10);
    final (dx, dy) = switch (event.logicalKey.keyId) {
      _ when event.logicalKey == LogicalKeyboardKey.arrowLeft => (-step, 0),
      _ when event.logicalKey == LogicalKeyboardKey.arrowRight => (step, 0),
      _ when event.logicalKey == LogicalKeyboardKey.arrowUp => (0, -step),
      _ when event.logicalKey == LogicalKeyboardKey.arrowDown => (0, step),
      _ => (0, 0),
    };
    if (dx != 0 || dy != 0) {
      final r = plan.furniture[_selected!];
      _moveCommitted(_selected!, r.x + dx, r.y + dy);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _removeSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final feedback = FitFeedback.evaluate(
      plan,
      targetMm: clearanceTargets[_targetIndex],
    );
    return Focus(
      autofocus: true,
      canRequestFocus: true,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdaptiveActions(
                    children: [
                      _action('Room size', _editRoom),
                      _action('Add opening', _addOpening),
                      _action('Catalog', _addFromCatalog),
                      _action('Custom', _customPiece),
                      _action(
                        'Undo',
                        _history.isEmpty || _dragSnapshot != null
                            ? null
                            : _undo,
                      ),
                      _action('Snap ${_snap ? 'on' : 'off'}', () {
                        setState(() => _snap = !_snap);
                      }),
                      _action('Zoom out', () {
                        setState(() => _zoom = math.max(0.4, _zoom / 1.25));
                      }),
                      _action('Zoom in', () {
                        setState(() => _zoom = math.min(4, _zoom * 1.25));
                      }),
                    ],
                  ),
                  Padding(
                    key: const Key('clearanceRow'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Semantics(
                      container: true,
                      label: 'Clearance target',
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Clearance target', style: _smallText(context)),
                          for (var i = 0; i < clearanceTargets.length; i++)
                            _action(
                              '${clearanceTargets[i]} mm',
                              () => setState(() => _targetIndex = i),
                            ),
                          Text(
                            'Sampled walkway '
                            '${feedback.walkwayMm == null ? 'unreachable' : '~${feedback.walkwayMm} mm (approx.)'}',
                            key: const Key('walkwayReadout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      'Room ${plan.width} × ${plan.height} mm · tap or drag furniture · '
                      'arrows nudge, Shift+arrow 100 mm, Ctrl+Z undo, Delete removes. '
                      'Planning aid only — not building-code or accessibility compliance.',
                      style: _smallText(context),
                    ),
                  ),
                  if (_selected != null)
                    Padding(
                      key: const Key('selectionRow'),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Selected ${names[_selected!]} · '
                        '${plan.furniture[_selected!].width} × ${plan.furniture[_selected!].height} mm '
                        '(~${mmToInches(plan.furniture[_selected!].width).toStringAsFixed(1)} × '
                        '${mmToInches(plan.furniture[_selected!].height).toStringAsFixed(1)} in) '
                        'at ${plan.furniture[_selected!].x}, ${plan.furniture[_selected!].y} mm',
                      ),
                    ),
                  SizedBox(
                    height: 56,
                    child: feedback.warnings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No fit warnings. Approximate — not a code check.',
                              ),
                            ),
                          )
                        : ListView(
                            key: const Key('fitWarnings'),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              for (final warning in feedback.warnings)
                                Text(
                                  '⚠ $warning',
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                  ),
                  if (_selected != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _action('Rotate 90°', _rotateSelected),
                        _action('Remove', _removeSelected),
                        _action('Nudge left', () {
                          final r = plan.furniture[_selected!];
                          _moveCommitted(_selected!, r.x - 100, r.y);
                        }),
                        _action('Nudge right', () {
                          final r = plan.furniture[_selected!];
                          _moveCommitted(_selected!, r.x + 100, r.y);
                        }),
                        _action('Nudge up', () {
                          final r = plan.furniture[_selected!];
                          _moveCommitted(_selected!, r.x, r.y - 100);
                        }),
                        _action('Nudge down', () {
                          final r = plan.furniture[_selected!];
                          _moveCommitted(_selected!, r.x, r.y + 100);
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fit = math.max(
                  0.01,
                  math.min(
                    (constraints.maxWidth - 24) / plan.width,
                    (constraints.maxHeight - 24) / plan.height,
                  ),
                );
                return ClipRect(
                  child: Center(
                    child: Transform.scale(
                      scale: _zoom,
                      child: SizedBox(
                        width: plan.width * fit,
                        height: plan.height * fit,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) =>
                              _selectAt(details.localPosition, fit),
                          onPanStart: (details) => _dragStart(
                            details.localPosition,
                            details.globalPosition,
                            fit,
                          ),
                          onPanUpdate: (details) =>
                              _dragUpdate(details.globalPosition, fit * _zoom),
                          onPanEnd: (_) => _dragEnd(),
                          onPanCancel: _dragEnd,
                          child: CustomPaint(
                            key: const Key('roomCanvas'),
                            painter: RoomPainter(
                              plan,
                              _selected,
                              fit,
                              feedback,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 52,
            child: names.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No furniture yet — use Catalog or Custom.'),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < names.length; i++)
                          Semantics(
                            button: true,
                            selected: i == _selected,
                            label:
                                '${names[i]}, ${plan.furniture[i].width} by '
                                '${plan.furniture[i].height} millimetres, at '
                                '${plan.furniture[i].x}, '
                                '${plan.furniture[i].y} millimetres',
                            child: _action(
                              'Select ${names[i]}',
                              () => setState(() => _selected = i),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementDialog extends StatefulWidget {
  const _MeasurementDialog({
    required this.title,
    required this.labels,
    required this.initial,
    required this.ios,
    required this.windows,
  });

  final String title;
  final List<String> labels;
  final List<String> initial;
  final bool ios;
  final bool windows;

  @override
  State<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<_MeasurementDialog> {
  late final List<TextEditingController> controllers = [
    for (final value in widget.initial) TextEditingController(text: value),
  ];

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputs = [
      for (var i = 0; i < widget.labels.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: KeyedSubtree(
            key: Key('field-$i'),
            child: AdaptiveTextField(
              label: widget.labels[i],
              controller: controllers[i],
            ),
          ),
        ),
    ];
    void apply() =>
        Navigator.pop(context, [for (final c in controllers) c.text]);
    if (widget.ios) {
      return CupertinoAlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          height: math.min(300, widget.labels.length * 70.0),
          child: SingleChildScrollView(child: Column(children: inputs)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(onPressed: apply, child: const Text('Apply')),
        ],
      );
    }
    if (widget.windows) {
      return fluent.ContentDialog(
        title: Text(widget.title),
        content: SizedBox(
          height: math.min(300, widget.labels.length * 70.0),
          child: SingleChildScrollView(child: Column(children: inputs)),
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          fluent.FilledButton(onPressed: apply, child: const Text('Apply')),
        ],
      );
    }
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        height: math.min(300, widget.labels.length * 70.0),
        child: SingleChildScrollView(child: Column(children: inputs)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: apply, child: const Text('Apply')),
      ],
    );
  }
}

class RoomPainter extends CustomPainter {
  RoomPainter(this.plan, this.selected, this.scale, this.feedback);

  final RoomPlan plan;
  final int? selected;
  final double scale;
  final FitFeedback feedback;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF4F8FA),
    );
    final outline = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < plan.furniture.length; i++) {
      final r = plan.furniture[i];
      final box = Rect.fromLTWH(
        r.x * scale,
        r.y * scale,
        r.width * scale,
        r.height * scale,
      );
      canvas.drawRect(
        box,
        Paint()
          ..color = feedback.conflictItems.contains(i)
              ? const Color(0xFFE06C75)
              : i == selected
              ? const Color(0xFF237C9A)
              : const Color(0xFF8FBC94),
      );
      canvas.drawRect(box, outline);
      _paintDimensions(canvas, box, r);
    }
    for (final opening in plan.openings) {
      final start = opening.offset * scale;
      final end = (opening.offset + opening.span) * scale;
      final (a, b) = switch (opening.wall) {
        Wall.north => (Offset(start, 0), Offset(end, 0)),
        Wall.south => (Offset(start, size.height), Offset(end, size.height)),
        Wall.west => (Offset(0, start), Offset(0, end)),
        Wall.east => (Offset(size.width, start), Offset(size.width, end)),
      };
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = opening.kind == OpeningKind.door
              ? const Color(0xFFD35400)
              : const Color(0xFF0077B6)
          ..strokeWidth = 5,
      );
    }
    canvas.drawRect(Offset.zero & size, outline);
    _label(canvas, '${plan.width} mm', Offset(size.width / 2 - 32, 4));
    _label(canvas, '${plan.height} mm', const Offset(4, 4));
  }

  void _paintDimensions(Canvas canvas, Rect box, MmRect footprint) {
    if (box.width < 50 || box.height < 28) return;
    _label(
      canvas,
      '${footprint.width} × ${footprint.height} mm',
      box.topLeft + const Offset(4, 4),
    );
  }

  void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF102027),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(RoomPainter old) =>
      old.plan != plan ||
      old.selected != selected ||
      old.scale != scale ||
      old.feedback.targetMm != feedback.targetMm;
}
