import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../pokemon/pokemon_scoped_save_counting_reader.dart';

String _event(int index) =>
    'evt_019abcde-0002-7000-8000-${index.toString().padLeft(12, '0')}';

NarrativeEventRecord _talk(int index, String name, String map, String npc) =>
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: _event(index),
        name: name,
        source: NarrativeEventSourceRef.entityInteract(map, npc),
        conditions: const [],
        priority: 0,
        order: index,
      ),
    );

MapData _map(String id, String name, List<MapEntity> entities) => MapData(
  id: id,
  name: name,
  size: const GridSize(width: 4, height: 4),
  layers: const [],
  entities: entities,
);

MapEntity _npc(String id, String name, {String? character}) => MapEntity(
  id: id,
  name: name,
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(displayName: name, characterId: character),
);

Future<ProjectSession> _open() async {
  final temporary = await Directory.systemTemp.createTemp('behaviour_dir_');
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root.path),
    projectId: 'behaviour-directory',
    project: ProjectManifest(
      name: 'Annuaire',
      maps: const [
        ProjectMapEntry(id: 'town', name: 'Bourg', relativePath: 'maps/t.json'),
        ProjectMapEntry(
          id: 'cave',
          name: 'Grotte',
          relativePath: 'maps/c.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas',
          relativePath: 'assets/atlas.png',
        ),
      ],
      characters: const [
        ProjectCharacterEntry(id: 'char_leo', name: 'Léo', tilesetId: 'atlas'),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          _talk(1, 'Saluer Léo', 'town', 'leo_town'),
          _talk(2, 'Retrouver Léo', 'cave', 'leo_cave'),
          _talk(3, 'Parler au mineur', 'cave', 'miner'),
          _talk(4, 'Parler au fantôme', 'cave', 'ghost'),
        ],
        legacyClaims: const [],
      ),
    ),
  );
  final maps = {
    't': _map('town', 'Bourg', [
      _npc('leo_town', 'Léo au bourg', character: 'char_leo'),
    ]),
    'c': _map('cave', 'Grotte', [
      _npc('leo_cave', 'Léo dans la grotte', character: 'char_leo'),
      _npc('miner', 'Mineur'),
    ]),
  };
  for (final entry in maps.entries) {
    final file = File('${root.path}/maps/${entry.key}.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(entry.value.toJson()));
  }
  final sessions = LocalProjectSessionAdapter();
  final session = await sessions.open(root.path);
  addTearDown(() => sessions.close(session));
  expect(session.storage, ProjectSessionStorage.workingCatalog);
  return session;
}

Future<void> _until(bool Function() done) async {
  for (var attempt = 0; attempt < 400 && !done(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

void main() {
  test('Tout le jeu names elements of every map, groups them by character and '
      'flags an element deleted from its map, from index pages only', () async {
    final session = await _open();
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
    await _until(() => behaviours.directory.ready);

    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(reader.definitions, isEmpty);
    final directoryUnits = reader.unitKeys
        .where((key) => key.contains('apDirectory'))
        .toList();
    expect(directoryUnits, [
      'workspaceState:mapDirectoryIndex',
      'workspaceState:["mapDirectory","cave"]',
      'workspaceState:["mapDirectory","town"]',
    ]);
    final rows = {for (final row in behaviours.rows) row.name: row};
    expect(rows['Retrouver Léo']!.elementName, 'Léo dans la grotte');
    expect(rows['Retrouver Léo']!.characterId, 'char_leo');
    expect(rows['Parler au mineur']!.elementName, 'Mineur');
    expect(rows['Parler au mineur']!.elementMissing, isFalse);
    final ghost = rows['Parler au fantôme']!;
    expect((ghost.elementMissing, ghost.toRepair), (true, true));
    expect(rows['Saluer Léo']!.elementMissing, isFalse);

    reader.clear();
    behaviours.group(GameBehaviourGrouping.character);
    await _until(() => behaviours.characters.ready);

    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(
      reader.unitKeys.where((key) => key.contains('apDirectory')),
      isEmpty,
    );
    final groups = behaviours.groups();
    expect(
      [
        for (final group in groups)
          (
            group.kind,
            group.label,
            (group.rows.map((row) => row.name).toList()..sort()).join(' | '),
          ),
      ],
      [
        (GameBehaviourGroupKind.character, 'Léo', 'Retrouver Léo | Saluer Léo'),
        (GameBehaviourGroupKind.character, 'Mineur', 'Parler au mineur'),
        (GameBehaviourGroupKind.withoutCharacter, null, 'Parler au fantôme'),
      ],
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
