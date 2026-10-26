import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'room_geometry.dart';

/// One owned collection of named room layouts. Decode fully before replacing it.
class LayoutBook {
  static const version = 1;
  static const maxBytes = 1024 * 1024;
  LayoutBook(List<NamedLayout> layouts, this.active)
    : layouts = List.unmodifiable(layouts) {
    if (layouts.isEmpty ||
        active < 0 ||
        active >= layouts.length ||
        layouts.length > 100 ||
        layouts.map((e) => e.name).toSet().length != layouts.length) {
      throw const FormatException('Invalid layouts or active selection');
    }
  }

  final List<NamedLayout> layouts;
  final int active;
  NamedLayout get current => layouts[active];

  Map<String, Object> toJson() => {
    'version': version,
    'active': active,
    'layouts': [for (final layout in layouts) layout.toJson()],
  };

  Uint8List encode() {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
    if (bytes.length > maxBytes) throw const FormatException('Plan too large');
    return bytes;
  }

  factory LayoutBook.decode(List<int> bytes) {
    if (bytes.length > maxBytes) throw const FormatException('Plan too large');
    try {
      final data = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (data is! Map<String, dynamic> ||
          data['version'] != version ||
          data['active'] is! int ||
          data['layouts'] is! List ||
          (data['layouts'] as List).isEmpty ||
          (data['layouts'] as List).length > 100) {
        throw const FormatException('Unsupported or invalid layout schema');
      }
      return LayoutBook([
        for (final value in data['layouts'] as List)
          NamedLayout.fromJson(value),
      ], data['active'] as int);
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('Invalid layout data: $e');
    }
  }
}

class NamedLayout {
  NamedLayout(this.name, this.plan, List<String> names)
    : names = List.unmodifiable(names) {
    if (name.trim().isEmpty ||
        name.length > 80 ||
        names.length != plan.furniture.length ||
        names.any((n) => n.trim().isEmpty || n.length > 80)) {
      throw const FormatException('Invalid layout or furniture names');
    }
  }

  final String name;
  final RoomPlan plan;
  final List<String> names;
  Map<String, Object> toJson() => {
    'name': name,
    'plan': plan.toJson(),
    'names': names,
  };

  factory NamedLayout.fromJson(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['name'] is! String ||
        value['plan'] is! Map<String, dynamic> ||
        value['names'] is! List ||
        (value['names'] as List).any((n) => n is! String)) {
      throw const FormatException('Invalid named layout');
    }
    return NamedLayout(
      value['name'] as String,
      RoomPlan.fromJson(value['plan'] as Map<String, dynamic>),
      (value['names'] as List).cast<String>(),
    );
  }
}

/// Atomic replacement in private app storage. Failed writes leave old save intact.
class LayoutStore {
  LayoutStore(this.file);
  final File file;

  static Future<LayoutStore> inAppStorage() async => LayoutStore(
    File(
      '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}room-fit-layouts.json',
    ),
  );

  Future<LayoutBook?> load() async {
    final backup = File('${file.path}.backup');
    if (!await file.exists() && await backup.exists()) {
      await backup.rename(file.path);
    }
    if (!await file.exists()) return null;
    if (await file.length() > LayoutBook.maxBytes) {
      throw const FormatException('Plan too large');
    }
    return LayoutBook.decode(await file.readAsBytes());
  }

  Future<void> save(LayoutBook book) async {
    final temp = File('${file.path}.pending');
    final backup = File('${file.path}.backup');
    try {
      await temp.writeAsBytes(book.encode(), flush: true);
      if (Platform.isWindows && await file.exists()) {
        // ponytail: Dart cannot atomically rename over an existing Windows
        // file. Keep prior save recoverable until replacement is installed.
        if (await backup.exists()) await backup.delete();
        await file.rename(backup.path);
      }
      await temp.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }
}
