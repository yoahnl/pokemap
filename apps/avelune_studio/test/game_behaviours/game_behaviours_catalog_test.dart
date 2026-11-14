import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import '../pokemon/pokemon_scoped_save_counting_reader.dart';

Future<void> _until(bool Function() done) async {
  for (var attempt = 0; attempt < 400 && !done(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

bool _indexUnit(String key) =>
    key == 'catalogMetadata:publication-shell' ||
    key == 'workspaceState:narrativeEventDocuments' ||
    key == 'workspaceState:narrativeTitleIndex' ||
    key.startsWith('workspaceState:["narrativeTitles","narrativeEvents",') ||
    key.startsWith('workspaceState:["narrativeTitles","facts",') ||
    key == 'workspaceState:narrativeFactUsersIndex' ||
    key.startsWith('workspaceState:["narrativeFactUsers",') ||
    key == 'workspaceState:mapDirectoryIndex' ||
    key.startsWith('workspaceState:["mapDirectory",');

void main() {
  test('Tout le jeu lists every behaviour from index pages only', () async {
    final session = await openGameMemoryCatalog(unrelated: 300);
    final maps = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    addTearDown(maps.dispose);
    await maps.initialize();
    final story = MapBuilderStoryBinding(
      maps: maps,
      changed: () {},
      view: () => null,
    );
    final source = MapBuilderStoryBehaviourSource(story);
    final reader = CountingReader();
    final behaviours = GameBehavioursController(
      port: LocalNarrativeIndexAdapter(session, reader: reader),
      source: () => source,
      changed: () {},
    );

    await behaviours.open();
    await _until(() => behaviours.facts.ready);

    expect(reader.definitions, isEmpty);
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(reader.unitKeys.where((key) => !_indexUnit(key)), isEmpty);
    expect(
      reader.unitKeys.where((key) => key.contains('"narrativeEvents"')),
      hasLength(3),
    );
    final rows = behaviours.rows;
    expect(rows, hasLength(301));
    expect(rows.where((row) => row.withoutMap), hasLength(300));
    final talk = rows.singleWhere((row) => row.id == memoryTalkEvent);
    expect((talk.name, talk.mapName), ('Parler à Léo', 'Bourg'));
    expect(behaviours.summary(talk)?.conditions.items, hasLength(1));

    reader.clear();
    behaviours.group(GameBehaviourGrouping.fact);
    await _until(() => behaviours.usages.ready);

    expect(reader.definitions, isEmpty);
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(reader.unitKeys.where((key) => !_indexUnit(key)), isEmpty);
    final met = behaviours.groups().firstWhere(
      (group) => group.label == 'Rencontre',
    );
    expect(met.rows.map((row) => row.id), [memoryTalkEvent]);

    reader.clear();
    expect(await behaviours.reach(memoryTalkEvent, (_) async => true), isTrue);
    expect(reader.definitions, isEmpty);
    expect(reader.unitKeys.where((key) => !_indexUnit(key)), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
