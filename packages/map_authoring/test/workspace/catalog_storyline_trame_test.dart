import 'dart:convert';

import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_usages.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/storyline_trame_fixture.dart';

void main() {
  test('trame actions publish on a working catalog and undo cleanly', () async {
    final fixture =
        await NarrativeTitleFixture.create(project: trameProject(0));
    addTearDown(fixture.close);
    await fixture.prepare();
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final initial = await _definitions(fixture);
    final attachScene = {
      'storylineId': 'main',
      'chapterId': 'act_2',
      'stepId': 'leave_town',
      'sceneId': 'scene_gate',
    };
    final operations = <(String, Map<String, Object?>)>[
      (
        'storyline.chapter.create',
        {'storylineId': 'main', 'chapterId': 'act_2', 'title': 'Act 2'}
      ),
      (
        'storyline.milestone.create',
        {
          'storylineId': 'main',
          'chapterId': 'act_2',
          'stepId': 'leave_town',
          'title': 'Leave town'
        }
      ),
      (
        'storyline.milestone.rename',
        {
          'storylineId': 'main',
          'chapterId': 'act_2',
          'stepId': 'leave_town',
          'title': 'Leave the town'
        }
      ),
      ('storyline.milestone.attach_scene', attachScene),
      ('storyline.milestone.detach_scene', attachScene),
      (
        'storyline.milestone.move',
        {
          'storylineId': 'main',
          'chapterId': 'act_2',
          'stepId': 'leave_town',
          'targetChapterId': 'act_1',
          'targetIndex': 0
        }
      ),
      (
        'storyline.milestone.set_archived',
        {
          'storylineId': 'main',
          'chapterId': 'act_1',
          'stepId': 'leave_town',
          'archived': true
        }
      ),
      (
        'storyline.chapter.rename',
        {'storylineId': 'main', 'chapterId': 'act_2', 'title': 'Finale'}
      ),
      (
        'storyline.chapter.set_archived',
        {'storylineId': 'main', 'chapterId': 'act_2', 'archived': true}
      ),
    ];
    final receipts = <String>[];
    for (final (index, (action, parameters)) in operations.indexed) {
      final snapshot = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      expect(snapshot.manifest.scenes.map((scene) => scene.id),
          action.endsWith('attach_scene') ? ['scene_gate'] : isEmpty);
      expect(
          snapshot.availableProjectDocuments,
          action.endsWith('attach_scene')
              ? {
                  'scenes': {'scene_gate'}
                }
              : null);
      final head = (await fixture.snapshot()).root;
      receipts.add(await fixture.apply(action, parameters, 'trame-$index'));
      expect((await fixture.snapshot()).root, isNot(head), reason: action);
      if (action == 'storyline.milestone.create') {
        expect(await fixture.titles('facts'), contains('Leave town'));
        expect(
            await CatalogNarrativeUsages.readFactUsers(
                await fixture.snapshot(), 'fact_leave_town'),
            isA<CatalogNarrativeUsageEntries>()
                .having((read) => read.entries, 'entries', [
              {'kind': 'storyline', 'id': 'main', 'role': 'read'}
            ]));
      }
    }
    final history =
        await fixture.api.history(fixture.opened.projectHandle, limit: 50);
    expect([
      for (final entry in history['entries'] as List)
        if (entry['entryId'] case final String id when receipts.contains(id)) id
    ], hasLength(operations.length));

    await fixture.reattach();
    final edited = await _definitions(fixture);
    final storyline = StorylineAsset.fromJson(edited['storylines']!['main']!);
    expect(
        storyline.chapters
            .map((chapter) => (chapter.id, chapter.title, chapter.status)),
        [
          ('act_1', 'Act 1', null),
          ('act_2', 'Finale', StorylineStatus.archived),
        ]);
    final moved = storyline.chapters.first.steps.first;
    expect((moved.id, moved.title, moved.status),
        ('leave_town', 'Leave the town', StorylineStatus.archived));
    expect(moved.sceneLinkIds, isEmpty);
    expect(storyline.chapters.first.steps.last.sceneLinkIds, isEmpty);
    expect(edited['facts']!['fact_leave_town']!['label'], 'Leave the town');

    for (final (index, receipt) in receipts.reversed.indexed) {
      await fixture.undo(receipt, 'undo-$index');
    }
    expect(await _definitions(fixture), initial);
    final units = await (await fixture.snapshot()).readAllUnits();
    expect(_derived(units), _derived(CatalogDerivableIndexes.expected(units)));
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<Map<String, Map<String, Map<String, dynamic>>>> _definitions(
    NarrativeTitleFixture fixture) async {
  final result = <String, Map<String, Map<String, dynamic>>>{};
  for (final unit in await (await fixture.snapshot()).readAllUnits()) {
    final value = unit.payload['value'];
    if (value is Map &&
        const {'storylines', 'facts'}.contains(value['field'])) {
      final definition = Map<String, dynamic>.from(value['definition'] as Map);
      result.putIfAbsent(
              value['field'] as String, () => {})[definition['id'] as String] =
          definition;
    }
  }
  return result;
}

Map<String, String> _derived(Iterable<CatalogDefinitionUnit> units) => {
      for (final unit in units)
        if (CatalogDerivableIndexes.all.any((index) => index.owns(unit.key)))
          jsonEncode(unit.key.toJson()): jsonEncode(unit.payload)
    };
