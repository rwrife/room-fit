import 'package:flutter_test/flutter_test.dart';
import 'package:room_fit/room_geometry.dart';

void main() {
  group('MmRect and units', () {
    test('versioned RoomPlan round-trips via JSON', () {
      final original = RoomPlan(
        width: 3600,
        height: 4800,
        furniture: [MmRect(200, 200, 900, 600), MmRect(1500, 1500, 1200, 800)],
        openings: [
          Opening(
            wall: Wall.north,
            offset: 300,
            span: 900,
            kind: OpeningKind.door,
            hingeAtEnd: true,
          ),
          Opening(
            wall: Wall.east,
            offset: 1000,
            span: 1200,
            kind: OpeningKind.window,
          ),
        ],
      );

      final json = original.toJson();
      expect(json['version'], equals(1));
      final decoded = RoomPlan.fromJson(json);

      expect(decoded.width, equals(original.width));
      expect(decoded.height, equals(original.height));
      expect(decoded.furniture.length, equals(2));
      expect(decoded.furniture.first.x, equals(200));
      expect(decoded.furniture.first.width, equals(900));
      expect(decoded.openings.length, equals(2));
      expect(decoded.openings.first.kind, equals(OpeningKind.door));
      expect(decoded.openings.first.hingeAtEnd, isTrue);
    });

    test('bad dimensions throw ArgumentError', () {
      expect(() => MmRect(0, 0, 0, 100), throwsArgumentError);
      expect(() => MmRect(0, 0, 100, -5), throwsArgumentError);
      expect(() => RoomPlan(width: 0, height: 1000), throwsArgumentError);
    });

    test('touching edges do not count as overlap', () {
      final a = MmRect(0, 0, 1000, 1000);
      final rightNeighbor = MmRect(1000, 0, 500, 500);
      final bottomNeighbor = MmRect(0, 1000, 500, 500);
      final interior = MmRect(500, 500, 1000, 1000);

      expect(a.overlaps(rightNeighbor), isFalse);
      expect(a.overlaps(bottomNeighbor), isFalse);
      expect(a.overlaps(interior), isTrue);
    });

    test(
      'metric/imperial conversions round-trip within millimeter precision',
      () {
        expect(inchesToMm(1.0), 25);
        expect(inchesToMm(36.0), 914);
        expect(mmToInches(254), closeTo(10.0, 0.001));
      },
    );
  });

  group('RoomPlan conflict diagnostics', () {
    test('wall boundary intersections are reported', () {
      final plan = RoomPlan(
        width: 3000,
        height: 4000,
        furniture: [MmRect(-10, 100, 500, 500), MmRect(2600, 100, 500, 500)],
      );
      expect(plan.conflicts, contains('Furniture 0 intersects room wall'));
      expect(plan.conflicts, contains('Furniture 1 intersects room wall'));
    });

    test('overlapping furniture pieces are reported', () {
      final plan = RoomPlan(
        width: 3000,
        height: 4000,
        furniture: [
          MmRect(500, 500, 1000, 1000),
          MmRect(1200, 800, 1000, 1000),
        ],
      );
      expect(plan.conflicts, contains('Furniture 0 and 1 overlap'));
    });

    test('corner door swing detects intrusion and clears clear placement', () {
      final door = Opening(
        wall: Wall.north,
        offset: 0,
        span: 900,
        kind: OpeningKind.door,
      );

      final blockingPlan = RoomPlan(
        width: 3000,
        height: 3000,
        openings: [door],
        furniture: [MmRect(200, 200, 600, 600)],
      );
      expect(
        blockingPlan.conflicts,
        contains('Furniture 0 blocks door 0 swing'),
      );

      final clearPlan = RoomPlan(
        width: 3000,
        height: 3000,
        openings: [door],
        furniture: [MmRect(1000, 0, 800, 800)],
      );
      expect(clearPlan.conflicts, isEmpty);
    });

    test('door swing at wall end honors hingeAtEnd', () {
      final door = Opening(
        wall: Wall.west,
        offset: 0,
        span: 800,
        kind: OpeningKind.door,
        hingeAtEnd: true,
      );
      final plan = RoomPlan(
        width: 3000,
        height: 3000,
        openings: [door],
        furniture: [MmRect(100, 100, 500, 500)],
      );
      expect(plan.conflicts, contains('Furniture 0 blocks door 0 swing'));
    });

    test('invalid door span extending past opposite wall throws', () {
      expect(
        () => RoomPlan(
          width: 1000,
          height: 1000,
          openings: [
            Opening(
              wall: Wall.north,
              offset: 0,
              span: 1200,
              kind: OpeningKind.door,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Walkway approximation', () {
    test('narrow walkway through furniture corridor is constrained', () {
      // 3000x2000 room with two furniture islands leaving a 600mm central slot.
      // Top island: y from 0 to 700. Bottom island: y from 1300 to 2000.
      // Slot: y in (700, 1300) -> 600mm width.
      final plan = RoomPlan(
        width: 3000,
        height: 2000,
        furniture: [MmRect(500, 0, 1000, 700), MmRect(500, 1300, 1000, 700)],
      );

      final width = plan.approximateWalkwayMm(
        const MmPoint(100, 1000),
        const MmPoint(2900, 1000),
        cellMm: 50,
      );

      expect(width, isNotNull);
      // Theoretical maximum clearance is 600mm; sampled corridor within 100mm.
      expect(width!, greaterThan(450));
      expect(width, lessThanOrEqualTo(650));
    });

    test('completely blocked corridor returns null', () {
      final plan = RoomPlan(
        width: 2000,
        height: 2000,
        furniture: [
          MmRect(900, 0, 200, 2000), // Wall-to-wall divider
        ],
      );
      final width = plan.approximateWalkwayMm(
        const MmPoint(100, 1000),
        const MmPoint(1900, 1000),
        cellMm: 50,
      );
      expect(width, isNull);
    });
  });
}
