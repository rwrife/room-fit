import 'package:flutter_test/flutter_test.dart';
import 'package:room_fit/furniture_catalog.dart';

void main() {
  test('furniture catalog contains around 40 items across all categories', () {
    expect(FurnitureCatalog.items.length, greaterThanOrEqualTo(40));
    expect(FurnitureCatalog.items.length, lessThanOrEqualTo(50));
    expect(FurnitureCategory.values.length, equals(6));

    final categoriesSeen = <FurnitureCategory>{};
    final idsSeen = <String>{};
    for (final item in FurnitureCatalog.items) {
      expect(item.id, isNotEmpty);
      expect(item.name, isNotEmpty);
      expect(item.widthMm, greaterThan(0));
      expect(item.depthMm, greaterThan(0));
      expect(idsSeen.add(item.id), isTrue, reason: 'Duplicate id: ${item.id}');
      categoriesSeen.add(item.category);
    }
    expect(categoriesSeen, equals(FurnitureCategory.values.toSet()));
  });

  test('findById retrieves item or null', () {
    final queen = FurnitureCatalog.findById('queen_bed');
    expect(queen, isNotNull);
    expect(queen!.widthMm, equals(1520));
    expect(queen.depthMm, equals(2030));
    expect(queen.category, equals(FurnitureCategory.sleeping));

    expect(FurnitureCatalog.findById('does_not_exist'), isNull);
  });

  test('toRect handles orientation turns', () {
    final desk = FurnitureCatalog.findById('desk_standard')!;
    final r0 = desk.toRect(x: 100, y: 200, rotationTurns: 0);
    expect(r0.x, equals(100));
    expect(r0.y, equals(200));
    expect(r0.width, equals(1400));
    expect(r0.height, equals(700));

    final r1 = desk.toRect(x: 100, y: 200, rotationTurns: 1);
    expect(r1.width, equals(700));
    expect(r1.height, equals(1400));

    final r2 = desk.toRect(x: 0, y: 0, rotationTurns: 2);
    expect(r2.width, equals(1400));
    expect(r2.height, equals(700));
  });
}
