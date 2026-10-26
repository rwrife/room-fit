import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:room_fit/layout_store.dart';
import 'package:room_fit/room_geometry.dart';

void main() {
  test('LayoutBook encode and decode round-trips correctly', () {
    final original = LayoutBook([
      NamedLayout(
        'Living Room',
        RoomPlan(
          width: 4500,
          height: 3200,
          furniture: [MmRect(100, 200, 900, 600)],
        ),
        const ['Coffee Table'],
      ),
      NamedLayout('Bedroom', RoomPlan(width: 3800, height: 3000), const []),
    ], 0);

    final bytes = original.encode();
    final decoded = LayoutBook.decode(bytes);

    expect(decoded.layouts.length, 2);
    expect(decoded.active, 0);
    expect(decoded.current.name, 'Living Room');
    expect(decoded.current.plan.width, 4500);
    expect(decoded.current.names, ['Coffee Table']);
    expect(decoded.layouts[1].name, 'Bedroom');
  });

  test('LayoutBook decode rejects bad schema and duplicate layout names', () {
    // Bad version
    expect(
      () => LayoutBook.decode(const [
        123,
        34,
        118,
        101,
        114,
        115,
        105,
        111,
        110,
        34,
        58,
        57,
        57,
        125,
      ]), // {"version":99}
      throwsFormatException,
    );
    // Duplicate layout names
    expect(
      () => LayoutBook([
        NamedLayout('Plan A', RoomPlan(width: 4000, height: 3000), const []),
        NamedLayout('Plan A', RoomPlan(width: 4000, height: 3000), const []),
      ], 0),
      throwsFormatException,
    );
    // Malformed JSON
    expect(
      () => LayoutBook.decode(const [123, 34, 118, 101, 114, 115]),
      throwsFormatException,
    );
  });

  test(
    'untrusted import rejects malformed furniture without touching save',
    () async {
      final dir = await Directory.systemTemp.createTemp('layout_import_test');
      try {
        final store = LayoutStore(
          File('${dir.path}${Platform.pathSeparator}save.json'),
        );
        final existing = LayoutBook([
          NamedLayout('Safe', RoomPlan(width: 4000, height: 3000), const []),
        ], 0);
        await store.save(existing);
        final invalid = existing.toJson();
        ((invalid['layouts'] as List).first as Map)['plan'] = {
          'version': 1,
          'widthMm': -1,
          'heightMm': 3000,
          'furniture': [],
          'openings': [],
        };
        expect(
          () => LayoutBook.decode(utf8.encode(jsonEncode(invalid))),
          throwsFormatException,
        );
        expect((await store.load())!.current.name, 'Safe');
        expect((await store.load())!.current.plan.width, 4000);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'LayoutStore atomic write replaces file safely and cleans pending',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'layout_store_test',
      );
      try {
        final store = LayoutStore(
          File('${tempDir.path}${Platform.pathSeparator}save.json'),
        );
        expect(await store.load(), isNull);

        final book = LayoutBook([
          NamedLayout('Default', RoomPlan(width: 4000, height: 3000), const []),
        ], 0);

        await store.save(book);
        expect(await store.file.exists(), isTrue);

        final loaded = await store.load();
        expect(loaded, isNotNull);
        expect(loaded!.layouts.first.name, 'Default');
        expect(File('${store.file.path}.pending').existsSync(), isFalse);
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );
}
