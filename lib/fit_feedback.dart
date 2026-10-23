import 'room_geometry.dart';

/// Snapshot of live fit and clearance diagnostics for one plan and target.
///
/// Every walkway figure is an approximation from grid sampling. These are
/// planning aids, never building-code or accessibility compliance findings.
class FitFeedback {
  const FitFeedback({
    required this.conflicts,
    required this.conflictItems,
    required this.warnings,
    required this.walkwayMm,
    required this.cellMm,
    required this.targetMm,
  });

  /// Raw diagnostics straight from [RoomPlan.conflicts].
  final List<String> conflicts;

  /// Furniture indexes touched by a conflict; drives canvas highlighting.
  final Set<int> conflictItems;

  /// User-facing warning lines. Walkway lines always say "approx.".
  final List<String> warnings;

  /// Widest sampled approximate walkway across the room centre, in mm;
  /// null when no sampled route exists.
  final int? walkwayMm;

  /// Sampling grid used for [walkwayMm].
  final int cellMm;

  /// User-selected clearance target, in mm.
  final int targetMm;

  bool get hasConflicts => conflicts.isNotEmpty;

  /// Sample cell grown from [baseCellMm] until the grid fits the
  /// 40000-cell cap enforced by [RoomPlan.approximateWalkwayMm].
  static int fitCellMm(RoomPlan plan, int baseCellMm) {
    if (baseCellMm <= 0) throw ArgumentError('baseCellMm must be positive');
    var cell = baseCellMm;
    while (((plan.width + cell - 1) ~/ cell) *
            ((plan.height + cell - 1) ~/ cell) >
        40000) {
      cell *= 2;
    }
    return cell;
  }

  factory FitFeedback.evaluate(
    RoomPlan plan, {
    required int targetMm,
    int baseCellMm = 50,
  }) {
    if (targetMm <= 0) {
      throw ArgumentError.value(targetMm, 'targetMm', 'must be positive');
    }
    final conflicts = plan.conflicts;
    final itemPattern = RegExp(r'Furniture (\d+)(?: and (\d+))?');
    final conflictItems = <int>{
      for (final conflict in conflicts)
        for (final match in itemPattern.allMatches(conflict)) ...[
          int.parse(match.group(1)!),
          if (match.group(2) != null) int.parse(match.group(2)!),
        ],
    };

    final warnings = <String>[
      for (final conflict in conflicts)
        switch (conflict) {
          _
              when conflict.contains('overlap') &&
                  conflict.startsWith('Openings') =>
            'Openings clash — $conflict',
          _ when conflict.contains('overlap') =>
            'Overlap — $conflict (approximate)',
          _ when conflict.contains('intersects room wall') =>
            'Over the wall — $conflict',
          _ when conflict.contains('blocks door') => 'Door swing — $conflict',
          _ => conflict,
        },
    ];

    final cellMm = fitCellMm(plan, baseCellMm);
    // Probe inset so entry/exit cells are not glued to the side walls, which
    // would cap every measured walkway at roughly one cell width.
    final inset = plan.width ~/ 4;
    final startX = inset.clamp(0, plan.width - 1);
    final midY = plan.height ~/ 2;
    final walkwayMm = plan.approximateWalkwayMm(
      MmPoint(startX, midY),
      MmPoint(plan.width - 1 - startX, midY),
      cellMm: cellMm,
    );
    if (walkwayMm == null) {
      warnings.add('No sampled left-to-right walkway found');
    } else if (walkwayMm < targetMm) {
      warnings.add(
        'Approx. sampled walkway $walkwayMm mm below $targetMm mm target',
      );
    }

    return FitFeedback(
      conflicts: conflicts,
      conflictItems: conflictItems,
      warnings: warnings,
      walkwayMm: walkwayMm,
      cellMm: cellMm,
      targetMm: targetMm,
    );
  }
}
