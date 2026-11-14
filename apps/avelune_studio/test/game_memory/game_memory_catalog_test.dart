import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../pokemon/pokemon_scoped_save_counting_reader.dart';
import 'game_memory_catalog_fixture.dart';

Future<void> _until(bool Function() done) async {
  for (var attempt = 0; attempt < 200 && !done(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

void main() {
  test(
    'the memory reads index pages, not maps, scenes or unrelated facts',
    () async {
      final session = await openGameMemoryCatalog(unrelated: 300);
      final reader = CountingReader();
      final index = LocalNarrativeIndexAdapter(session, reader: reader);

      final titles = await index.titles(NarrativeTitleKind.facts);

      expect(titles, hasLength(303));
      expect(titles.first.title, 'Rencontre');
      expect(reader.definitions, isEmpty);
      expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
      expect(reader.unitKeys.toSet(), {
        'catalogMetadata:publication-shell',
        'workspaceState:narrativeEventDocuments',
        'workspaceState:narrativeTitleIndex',
        for (var page = 0; page < 3; page++)
          'workspaceState:["narrativeTitles","facts",$page]',
      });
      expect(
        reader.unitKeys.where((key) => key.contains('"narrativeTitles"')),
        hasLength(3),
      );

      reader.clear();
      final facts = await index.facts(['fact_coins', 'fact_met']);
      expect(facts.map((fact) => fact.label), ['Rencontre', 'Pièces']);
      expect(facts.last.initialValue, NarrativeValue.integer(3));
      expect(reader.definitions.toSet(), {'fact_coins', 'fact_met'});
      expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);

      reader.clear();
      final users = (await index.factUsers(['fact_met', 'fact_door']));
      expect(reader.definitions, isEmpty);
      expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
      expect(
        {for (final owner in users['fact_met']!.owners) owner},
        {
          const NarrativeOwner(
            kind: NarrativeOwnerKind.scene,
            id: 'gate',
            role: NarrativeFactRole.read,
          ),
          const NarrativeOwner(
            kind: NarrativeOwnerKind.worldRule,
            id: 'world_rule_door',
            role: NarrativeFactRole.read,
          ),
          const NarrativeOwner(
            kind: NarrativeOwnerKind.event,
            id: memoryTalkEvent,
            role: NarrativeFactRole.read,
          ),
        },
      );
      expect(
        users['fact_door']!.withRole(NarrativeFactRole.write).single.id,
        'gate',
      );
      expect(users['fact_met']!.notCovered, contains('maps'));

      final small = await openGameMemoryCatalog(unrelated: 2);
      final smallReader = CountingReader();
      await LocalNarrativeIndexAdapter(
        small,
        reader: smallReader,
      ).titles(NarrativeTitleKind.facts);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('an unprepared catalog and a manifest project are reported', () async {
    final unprepared = LocalNarrativeIndexAdapter(
      await openGameMemoryCatalog(prepared: false),
    );
    await expectLater(
      unprepared.titles(NarrativeTitleKind.facts),
      throwsA(
        isA<NarrativeIndexPreparationRequired>().having(
          (failure) => failure.scope,
          'scope',
          'narrativeTitles',
        ),
      ),
    );
    await expectLater(
      unprepared.factUsers(['fact_met']),
      throwsA(
        isA<NarrativeIndexPreparationRequired>().having(
          (failure) => failure.scope,
          'scope',
          'narrativeUsages',
        ),
      ),
    );

    final manifest = LocalNarrativeIndexAdapter(
      await openGameMemoryCatalog(prepared: false, catalog: false),
    );
    await expectLater(
      manifest.titles(NarrativeTitleKind.facts),
      throwsA(isA<NarrativeIndexUnavailable>()),
    );
  });

  test(
    'a renamed fact, a new fact and a new rule save through the story draft',
    () async {
      final session = await openGameMemoryCatalog(unrelated: 20);
      final adapter = LocalMapWorkspaceAdapter();
      final maps = MapWorkspaceController(session, adapter);
      addTearDown(maps.dispose);
      await maps.initialize();
      expect(maps.project!.facts, isEmpty);
      final story = MapBuilderStoryBinding(
        maps: maps,
        changed: () {},
        view: () => null,
        gateway: (draft, saved) => StoryPublicationGateway(
          draft: draft,
          facts: LocalWorldAdapter(session: session, mapAdapter: adapter),
          savedDialogues: saved,
        ),
      );
      final memory = GameMemoryController(
        port: LocalNarrativeIndexAdapter(session),
        staging: MapBuilderStoryMemory(story, editable: () => true),
        changed: () {},
      );
      addTearDown(memory.dispose);
      await memory.open();
      memory.reveal('fact_met');
      await _until(() => memory.details.containsKey('fact_met'));

      expect(memory.renameFact('fact_met', 'Rencontre avec Léo'), isTrue);
      final key = memory.createFact('Clé trouvée', NarrativeValueKind.boolean)!;
      await memory.rules.open();
      final rule = memory.rules.create(
        label: 'Léo part',
        condition: (
          factId: key,
          operator: NarrativeFactOperator.equals,
          value: const NarrativeValue.boolean(true),
        ),
        map: maps.project!.maps.first,
        character: (id: 'npc', name: 'Léo'),
        visible: false,
      )!;
      expect(story.dirty, isTrue);
      expect(story.canUndo, isTrue);

      expect(await story.save(), isTrue, reason: story.error);
      expect(story.dirty, isFalse);
      memory.sync();
      await _until(() => !memory.facts.loading);
      memory
        ..reveal('fact_met')
        ..reveal(key);
      await _until(
        () =>
            memory.details.containsKey('fact_met') &&
            memory.details.containsKey(key),
      );
      expect(
        memory.rows.firstWhere((row) => row.id == 'fact_met').label,
        'Rencontre avec Léo',
      );
      final created = memory.rows.firstWhere((row) => row.id == key);
      expect((created.label, created.unsaved), ('Clé trouvée', false));

      final reopened = LocalNarrativeIndexAdapter(session);
      final saved = await reopened.facts(['fact_met', key]);
      expect(saved.map((fact) => fact.label), [
        'Rencontre avec Léo',
        'Clé trouvée',
      ]);
      final titles = await reopened.titles(NarrativeTitleKind.facts);
      expect(titles.map((title) => title.id), contains(key));
      expect(
        titles.singleWhere((title) => title.id == 'fact_met').title,
        'Rencontre avec Léo',
      );
      final rules = await reopened.worldRules();
      final written = rules.singleWhere((value) => value.id == rule);
      expect(written.source.sourceId, key);
      expect(written.target.entityId, 'npc');
      expect(written.effect.kind, WorldRuleEffectKind.entityHidden);
      expect(rules.map((value) => value.id), contains('world_rule_door'));
      final owners = await reopened.elementOwners('town', 'npc');
      expect(owners.owners.map((owner) => owner.id), contains(rule));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
