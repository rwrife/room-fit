import 'dart:math' as math;

/// All coordinates and dimensions are integer millimetres. Origin is the
/// room's north-west corner; +x points east, +y points south.
class MmPoint {
  const MmPoint(this.x, this.y);
  final int x;
  final int y;
}

class MmRect {
  MmRect(this.x, this.y, this.width, this.height) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Rectangle dimensions must be positive');
    }
  }

  final int x;
  final int y;
  final int width;
  final int height;
  int get right => x + width;
  int get bottom => y + height;

  /// Touching edges do not count as overlap.
  bool overlaps(MmRect other) =>
      x < other.right &&
      right > other.x &&
      y < other.bottom &&
      bottom > other.y;

  double distanceTo(MmPoint point) {
    final dx = math.max(math.max(x - point.x, point.x - right), 0);
    final dy = math.max(math.max(y - point.y, point.y - bottom), 0);
    return math.sqrt(dx * dx + dy * dy);
  }
}

enum Wall { north, east, south, west }

enum OpeningKind { door, window }

/// Offset runs from west to east on horizontal walls and north to south on
/// vertical walls. Door swings inward through a quarter circle whose radius
/// equals the opening span; hingeAtEnd places the hinge at the larger offset.
class Opening {
  Opening({
    required this.wall,
    required this.offset,
    required this.span,
    required this.kind,
    this.hingeAtEnd = false,
  }) {
    if (offset < 0 || span <= 0) {
      throw ArgumentError(
        'Opening offset must be nonnegative and span positive',
      );
    }
    if (kind == OpeningKind.window && hingeAtEnd) {
      throw ArgumentError('Windows have no hinge');
    }
  }

  final Wall wall;
  final int offset;
  final int span;
  final OpeningKind kind;
  final bool hingeAtEnd;

  /// Distance from point to inward door swing sector; zero inside the sector.
  double distanceToSwing(MmPoint point, int roomWidth, int roomHeight) {
    if (kind != OpeningKind.door) return double.infinity;
    final hinge = offset + (hingeAtEnd ? span : 0);
    final along = hingeAtEnd ? -1 : 1;
    final (u, v) = switch (wall) {
      Wall.north => ((point.x - hinge) * along, point.y),
      Wall.south => ((point.x - hinge) * along, roomHeight - point.y),
      Wall.west => ((point.y - hinge) * along, point.x),
      Wall.east => ((point.y - hinge) * along, roomWidth - point.x),
    };
    final cu = math.max(u, 0);
    final cv = math.max(v, 0);
    final length = math.sqrt(cu * cu + cv * cv);
    final scale = length > span ? span / length : 1.0;
    final du = u - cu * scale;
    final dv = v - cv * scale;
    return math.sqrt(du * du + dv * dv);
  }

  /// Axis-aligned bounding box of the swing; used only for a cheap rejection.
  MmRect swingBounds(int roomWidth, int roomHeight) {
    final hinge = offset + (hingeAtEnd ? span : 0);
    final start = hingeAtEnd ? hinge - span : hinge;
    return switch (wall) {
      Wall.north => MmRect(start, 0, span, span),
      Wall.south => MmRect(start, roomHeight - span, span, span),
      Wall.west => MmRect(0, start, span, span),
      Wall.east => MmRect(roomWidth - span, start, span, span),
    };
  }
}

class RoomPlan {
  static const schemaVersion = 1;

  RoomPlan({
    required this.width,
    required this.height,
    List<MmRect> furniture = const [],
    List<Opening> openings = const [],
  }) : furniture = List.unmodifiable(furniture),
       openings = List.unmodifiable(openings) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Room dimensions must be positive');
    }
    for (final opening in this.openings) {
      final wallLength = switch (opening.wall) {
        Wall.north || Wall.south => width,
        Wall.east || Wall.west => height,
      };
      if (opening.offset + opening.span > wallLength) {
        throw ArgumentError('Opening extends beyond its wall');
      }
      if (opening.kind == OpeningKind.door &&
          opening.span >
              (opening.wall == Wall.north || opening.wall == Wall.south
                  ? height
                  : width)) {
        throw ArgumentError('Door swing extends beyond opposite wall');
      }
    }
  }

  final int width;
  final int height;
  final List<MmRect> furniture;
  final List<Opening> openings;

  Map<String, Object> toJson() => {
    'version': schemaVersion,
    'widthMm': width,
    'heightMm': height,
    'furniture': [
      for (final item in furniture)
        {
          'xMm': item.x,
          'yMm': item.y,
          'widthMm': item.width,
          'heightMm': item.height,
        },
    ],
    'openings': [
      for (final item in openings)
        {
          'wall': item.wall.name,
          'offsetMm': item.offset,
          'spanMm': item.span,
          'kind': item.kind.name,
          'hingeAtEnd': item.hingeAtEnd,
        },
    ],
  };

  factory RoomPlan.fromJson(Map<String, dynamic> json) {
    if (json['version'] != schemaVersion) {
      throw FormatException('Unsupported room schema version');
    }
    int number(Map<String, dynamic> source, String key) {
      final value = source[key];
      if (value is! int) throw FormatException('Invalid $key');
      return value;
    }

    List<Map<String, dynamic>> objects(String key) {
      final value = json[key];
      if (value is! List ||
          value.any((item) => item is! Map<String, dynamic>)) {
        throw FormatException('Invalid $key');
      }
      return value.cast<Map<String, dynamic>>();
    }

    try {
      return RoomPlan(
        width: number(json, 'widthMm'),
        height: number(json, 'heightMm'),
        furniture: [
          for (final item in objects('furniture'))
            MmRect(
              number(item, 'xMm'),
              number(item, 'yMm'),
              number(item, 'widthMm'),
              number(item, 'heightMm'),
            ),
        ],
        openings: [
          for (final item in objects('openings'))
            Opening(
              wall: Wall.values.byName(item['wall'] as String),
              offset: number(item, 'offsetMm'),
              span: number(item, 'spanMm'),
              kind: OpeningKind.values.byName(item['kind'] as String),
              hingeAtEnd: item['hingeAtEnd'] == false
                  ? false
                  : item['hingeAtEnd'] == true
                  ? true
                  : throw const FormatException('Invalid hingeAtEnd'),
            ),
        ],
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid room plan: $error');
    }
  }

  /// Diagnostics, not building-code or accessibility compliance findings.
  List<String> get conflicts {
    final results = <String>[];
    for (var i = 0; i < openings.length; i++) {
      for (var j = i + 1; j < openings.length; j++) {
        final a = openings[i];
        final b = openings[j];
        if (a.wall == b.wall &&
            a.offset < b.offset + b.span &&
            b.offset < a.offset + a.span) {
          results.add('Openings $i and $j overlap');
        }
      }
    }
    for (var i = 0; i < furniture.length; i++) {
      final piece = furniture[i];
      if (piece.x < 0 ||
          piece.y < 0 ||
          piece.right > width ||
          piece.bottom > height) {
        results.add('Furniture $i intersects room wall');
      }
      for (var j = 0; j < i; j++) {
        if (piece.overlaps(furniture[j])) {
          results.add('Furniture $j and $i overlap');
        }
      }
      for (var j = 0; j < openings.length; j++) {
        final opening = openings[j];
        if (opening.kind == OpeningKind.door &&
            piece.overlaps(opening.swingBounds(width, height)) &&
            _rectIntersectsSwing(piece, opening)) {
          results.add('Furniture $i blocks door $j swing');
        }
      }
    }
    return results;
  }

  bool _rectIntersectsSwing(MmRect rect, Opening door) {
    final hinge = door.offset + (door.hingeAtEnd ? door.span : 0);
    final along = door.hingeAtEnd ? -1 : 1;
    final (hx, hy, sx, sy) = switch (door.wall) {
      Wall.north => (hinge, 0, along, 1),
      Wall.south => (hinge, height, along, -1),
      Wall.west => (0, hinge, 1, along),
      Wall.east => (width, hinge, -1, along),
    };
    final u0 = (rect.x - hx) * sx;
    final u1 = (rect.right - hx) * sx;
    final v0 = (rect.y - hy) * sy;
    final v1 = (rect.bottom - hy) * sy;
    final minU = math.max(0, math.min(u0, u1));
    final minV = math.max(0, math.min(v0, v1));
    final maxU = math.max(u0, u1);
    final maxV = math.max(v0, v1);
    return maxU > 0 &&
        maxV > 0 &&
        minU * minU + minV * minV < door.span * door.span;
  }

  double _clearance(MmPoint p) {
    if (p.x < 0 || p.y < 0 || p.x >= width || p.y >= height) return 0;
    var distance = math
        .min(math.min(p.x, width - p.x), math.min(p.y, height - p.y))
        .toDouble();
    for (final piece in furniture) {
      distance = math.min(distance, piece.distanceTo(p));
    }
    for (final opening in openings) {
      distance = math.min(distance, opening.distanceToSwing(p, width, height));
    }
    return distance;
  }

  /// Widest 4-connected sampled route, in mm; null if no sampled route.
  /// ponytail: sample centres can miss sub-cell obstructions; lower cellMm for
  /// closer estimates, never use this planning aid for code compliance.
  int? approximateWalkwayMm(MmPoint from, MmPoint to, {int cellMm = 50}) {
    if (cellMm <= 0) throw ArgumentError.value(cellMm, 'cellMm');
    final cols = (width + cellMm - 1) ~/ cellMm;
    final rows = (height + cellMm - 1) ~/ cellMm;
    if (cols * rows > 40000) {
      throw ArgumentError('Grid exceeds 40000 cells; increase cellMm');
    }
    if (_clearance(from) <= 0 || _clearance(to) <= 0) return null;
    final start = (from.y ~/ cellMm) * cols + from.x ~/ cellMm;
    final end = (to.y ~/ cellMm) * cols + to.x ~/ cellMm;
    final clearances = List<double>.generate(cols * rows, (index) {
      final x = index % cols;
      final y = index ~/ cols;
      return _clearance(
        MmPoint(
          math.min(x * cellMm + cellMm ~/ 2, width - 1),
          math.min(y * cellMm + cellMm ~/ 2, height - 1),
        ),
      );
    });
    bool reachable(int widthMm) {
      final radius = widthMm / 2;
      if (clearances[start] <= 0 ||
          clearances[end] <= 0 ||
          clearances[start] < radius ||
          clearances[end] < radius) {
        return false;
      }
      final visited = List<bool>.filled(cols * rows, false);
      final queue = <int>[start];
      visited[start] = true;
      for (var cursor = 0; cursor < queue.length; cursor++) {
        final current = queue[cursor];
        if (current == end) return true;
        final x = current % cols;
        final y = current ~/ cols;
        for (final next in [
          if (x > 0) current - 1,
          if (x + 1 < cols) current + 1,
          if (y > 0) current - cols,
          if (y + 1 < rows) current + cols,
        ]) {
          if (!visited[next] &&
              clearances[next] > 0 &&
              clearances[next] >= radius) {
            visited[next] = true;
            queue.add(next);
          }
        }
      }
      return false;
    }

    if (!reachable(0)) return null;
    var low = 0;
    var high = math.min(width, height);
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (reachable(mid)) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }
}

int inchesToMm(double inches) {
  if (!inches.isFinite) throw ArgumentError.value(inches, 'inches');
  return (inches * 25.4).round();
}

double mmToInches(int mm) => mm / 25.4;
