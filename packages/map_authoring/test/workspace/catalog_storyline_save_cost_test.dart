import 'dart:convert';

import 'package:test/test.dart';

import '../support/catalog_unit_reads.dart';
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
            'publication-shell',
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
    final counter = CatalogUnitReads(fixture.root);
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
      final before = await _units(fixture);
      final read = await counter
          .count(() => fixture.apply(action, parameters, 'measure-$action'));
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

String _label(String key) => catalogUnitLabel(jsonDecode(key));
