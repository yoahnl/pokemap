import 'dart:convert';

import 'package:map_core/map_core.dart';
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

  test('canonical chapter rename ignores unrelated Storyline definitions',
      () async {
    final counts = <Map<String, int>>[];
    for (final unrelated in [12, 24]) {
      final project = trameProject(unrelated);
      final fixture = await NarrativeTitleFixture.create(
        project: project.copyWith(storylines: [
          ...project.storylines,
          for (var i = 0; i < unrelated; i++)
            StorylineAsset(
                id: 'side_$i',
                title: 'Side story $i',
                type: StorylineType.sideQuest),
        ]),
      );
      try {
        final counter = CatalogUnitReads(fixture.root);
        final before = await _units(fixture);
        final reads = await counter.count(() => fixture.apply(
              'storyline.chapter.rename',
              {
                'storylineId': 'main',
                'chapterId': 'act_1',
                'title': 'Acte renommé'
              },
              'rename-chapter',
            ));
        final after = await _units(fixture);
        expect(after.keys, unorderedEquals(before.keys));
        final changed = [
          for (final entry in after.entries)
            if (before[entry.key] != entry.value) _label(entry.key),
        ];
        expect(changed,
            unorderedEquals(['projectDefinition:storylines', 'storylines']));
        final stories = [
          for (final entry in after.entries)
            if (_label(entry.key) == 'projectDefinition:storylines')
              StorylineAsset.fromJson(Map<String, dynamic>.from(
                (jsonDecode(entry.value) as Map)['value']['definition'] as Map,
              )),
        ];
        expect(stories, hasLength(unrelated + 1));
        expect(
            stories
                .singleWhere((story) => story.id == 'main')
                .chapters
                .single
                .title,
            'Acte renommé');
        counts.add(reads);
      } finally {
        await fixture.close();
      }
    }
    expect(counts.last, counts.first);
    expect(counts.last.keys, isNot(contains('projectDefinition:facts')));
  });
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
