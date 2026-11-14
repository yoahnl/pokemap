import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_usages.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/storyline_trame_fixture.dart';

void main() {
  test('journal actions publish on a working catalog and undo cleanly',
      () async {
    final qa = await Directory('/Users/karim/Library/Caches/AveluneQA/c6')
        .create(recursive: true);
    final fixture = await NarrativeTitleFixture.create(
        at: await qa.createTemp('catalog-journal-'), project: trameProject(0));
    addTearDown(fixture.close);
    await fixture.prepare();
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final initial = await _definitions(fixture);
    final journal = {
      'title': {'fallback': 'Réveil'},
      'text': {'fallback': 'Une longue journée commence.'},
    };
    final clue = {
      'id': 'gate',
      'factId': 'fact_fact_0',
      'text': {'fallback': 'Le portail est ouvert.'},
    };
    final operations = <(String, Map<String, Object?>)>[
      (
        'storyline.milestone.set_journal',
        {
          'storylineId': 'main',
          'chapterId': 'act_1',
          'stepId': 'wake_up',
          'journal': journal,
        }
      ),
      (
        'storyline.clues.set',
        {
          'storylineId': 'main',
          'clues': [clue],
        }
      ),
    ];
    expect(
        await CatalogNarrativeUsages.readFactUsers(
            await fixture.snapshot(), 'fact_fact_0'),
        isA<CatalogNarrativeUsageEntries>()
            .having((read) => read.entries, 'entries', isEmpty));
    final receipts = <String>[];
    for (final (index, (action, parameters)) in operations.indexed) {
      final snapshot = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      expect(snapshot.availableProjectDocuments, isNull, reason: action);
      expect(snapshot.manifest.facts.map((fact) => fact.id),
          contains('fact_fact_0'));
      receipts.add(await fixture.apply(action, parameters, 'journal-$index'));
    }
    expect(
        await CatalogNarrativeUsages.readFactUsers(
            await fixture.snapshot(), 'fact_fact_0'),
        isA<CatalogNarrativeUsageEntries>()
            .having((read) => read.entries, 'entries', [
          {'kind': 'storyline', 'id': 'main', 'role': 'read'}
        ]));

    await fixture.reattach();
    final edited = await _definitions(fixture);
    expect(edited['facts'], initial['facts']);
    final storyline = StorylineAsset.fromJson(edited['storylines']!['main']!);
    expect(storyline.chapters.single.steps.single.journal?.toJson(), journal);
    expect([for (final item in storyline.journalClues) item.toJson()], [clue]);

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
