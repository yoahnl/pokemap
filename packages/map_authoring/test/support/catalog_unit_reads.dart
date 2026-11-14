import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class CatalogUnitReads {
  CatalogUnitReads(this.root);

  final Directory root;
  final _objects = <String, Map<String, Object?>>{};

  Future<Map<String, int>> count(Future<void> Function() action) async {
    await for (final entity
        in Directory('${root.path}/catalog/objects').list(recursive: true)) {
      if (entity is File && !_objects.containsKey(entity.path)) {
        _objects[entity.path] = Map<String, Object?>.from(
            jsonDecode(await entity.readAsString()) as Map);
      }
    }
    final reads = <String, int>{};
    final outside = Zone.current;
    await IOOverrides.runZoned(action, createFile: (path) {
      final object = _objects[path];
      if (object != null && object['type'] == 'unit') {
        final label = catalogUnitLabel(object['key']);
        reads[label] = (reads[label] ?? 0) + 1;
      }
      return outside.run(() => File(path));
    });
    return reads;
  }
}

String catalogUnitLabel(Object? key) {
  final id = (key as Map)['id'] as String;
  final decoded = id.startsWith('[') ? jsonDecode(id) : null;
  if (decoded is List && decoded.length >= 2) {
    final kind = decoded.first as String;
    if (kind == 'projectDefinition') return 'projectDefinition:${decoded[1]}';
    if (kind == 'metadataDocument') return decoded[1] as String;
    return kind;
  }
  return id;
}
