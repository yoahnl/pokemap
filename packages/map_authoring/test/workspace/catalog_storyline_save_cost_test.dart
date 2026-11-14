import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/storyline_trame_fixture.dart';

void main() {
  test('one storyline save rewrites its own unit whatever the project size',
      () async {
    final small = await _measure(0);
    final large = await _measure(300);
    printOnFailure(jsonEncode([
      for (final work in large)
        {'action': work.action, 'writes': work.writes, 'reads': work.unitReads}
    ]));
    for (final (save, smallWork) in small.indexed) {
      final largeWork = large[save];
      expect(largeWork.writes, ['projectDefinition:storylines', 'storylines'],
          reason: largeWork.action);
      expect(largeWork.writes, smallWork.writes, reason: largeWork.action);
      expect(largeWork.unitReads, smallWork.unitReads,
          reason: largeWork.action);
      expect(
          largeWork.unitReads.keys.toSet().difference(const {
            'projectDefinition:storylines',
            'projectDefinition:facts',
            'projectDefinition:scenes',
            'storylines',
            'scenes',
            'metadataField',
            'other',
          }),
          isEmpty,
          reason: largeWork.action);
      expect(largeWork.unitReads.containsKey('projectDefinition:scenes'),
          largeWork.action.endsWith('attach_scene'),
          reason: largeWork.action);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

typedef _Work = ({
  String action,
  List<String> writes,
  Map<String, int> unitReads,
});

Future<List<_Work>> _measure(int unrelated) async {
  final fixture =
      await NarrativeTitleFixture.create(project: trameProject(unrelated));
  try {
    final objects = <String, Map<String, Object?>>{};
    Future<void> index() async {
      await for (final entity
          in Directory('${fixture.root.path}/catalog/objects')
              .list(recursive: true)) {
        if (entity is File && !objects.containsKey(entity.path)) {
          objects[entity.path] = Map<String, Object?>.from(
              jsonDecode(await entity.readAsString()) as Map);
        }
      }
    }

    final work = <_Work>[];
    for (final (action, parameters) in <(String, Map<String, Object?>)>[
      (
        'storyline.upsert',
        {'storyline': trameStoryline().copyWith(title: 'Main renamed').toJson()}
      ),
      (
        'storyline.milestone.attach_scene',
        {
          'storylineId': 'main',
          'chapterId': 'act_1',
          'stepId': 'wake_up',
          'sceneId': 'scene_town'
        }
      ),
    ]) {
      await index();
      final before = await _units(fixture);
      final read = <String, int>{};
      final outside = Zone.current;
      await IOOverrides.runZoned(
          () => fixture.apply(action, parameters, 'measure-$action'),
          createFile: (path) {
        final object = objects[path];
        if (object != null && object['type'] == 'unit') {
          final field = _field(object['key']);
          read[field] = (read[field] ?? 0) + 1;
        }
        return outside.run(() => File(path));
      });
      final after = await _units(fixture);
      work.add((
        action: action,
        writes: [
          for (final entry in after.entries)
            if (before[entry.key] != entry.value) _label(entry.key)
        ]..sort(),
        unitReads: read,
      ));
    }
    return work;
  } finally {
    await fixture.close();
  }
}

Future<Map<String, String>> _units(NarrativeTitleFixture fixture) async => {
      for (final unit in await (await fixture.snapshot()).readAllUnits())
        jsonEncode(unit.key.toJson()): jsonEncode(unit.payload)
    };

String _label(String key) => _field(jsonDecode(key));

String _field(Object? key) {
  final id = (key as Map)['id'] as String;
  final decoded = id.startsWith('[') ? jsonDecode(id) : null;
  if (decoded is List && decoded.length >= 2) {
    final kind = decoded.first as String;
    if (kind == 'projectDefinition') return 'projectDefinition:${decoded[1]}';
    if (kind == 'metadataDocument') return decoded[1] as String;
    return kind;
  }
  return 'other';
}
