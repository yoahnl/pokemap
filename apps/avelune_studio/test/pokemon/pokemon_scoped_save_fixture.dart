import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'pokemon_scoped_save_counting_reader.dart';

final class ScopedSaveFixture {
  ScopedSaveFixture(
    this.root,
    this.session,
    this.reader,
    this.maps, {
    this.closeSession,
  });
  final Directory root;
  final ProjectSession session;
  final CountingReader reader;
  final LocalMapWorkspaceAdapter maps;
  final Future<void> Function()? closeSession;
  LocalPokemonCommerceAdapter get commerce => LocalPokemonCommerceAdapter(
    session: session,
    mapAdapter: maps,
    reader: reader,
  );
  LocalPokemonCombatAdapter get combat => LocalPokemonCombatAdapter(
    session: session,
    mapAdapter: maps,
    reader: reader,
  );

  static Future<ScopedSaveFixture> open(
    int unrelated, {
    bool configuredNewGame = false,
    bool spatial = false,
    bool nativeJson = false,
  }) async {
    final creation = Stopwatch()..start();
    final temporary = await Directory.systemTemp.createTemp(
      'pokemon-scoped-save-',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    final project = ProjectManifest(
      name: 'Scoped Pokemon',
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      maps: [
        if (configuredNewGame)
          const ProjectMapEntry(
            id: 'start',
            name: 'Start',
            relativePath: 'maps/start.json',
          ),
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'unused-map-$i',
            name: 'Unused',
            relativePath: 'maps/$i.json',
          ),
      ],
      tilesets: [
        if (configuredNewGame)
          const ProjectTilesetEntry(
            id: 'foreign-hero-sheet',
            name: 'Hero',
            relativePath: 'assets/foreign-hero.png',
          ),
      ],
      characters: [
        if (configuredNewGame)
          const ProjectCharacterEntry(
            id: 'hero-avatar',
            name: 'Hero',
            tilesetId: 'foreign-hero-sheet',
          ),
      ],
      settings: ProjectSettings(
        dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
        spatialCamera: spatial ? SpatialCameraProfile() : null,
        defaultPlayerCharacterId: configuredNewGame ? 'hero-avatar' : null,
      ),
      newGame: configuredNewGame
          ? ProjectNewGameConfig(
              enabled: true,
              startMapId: 'start',
              playerAvatarCharacterIds: const ['hero-avatar'],
              initialFactValues: {
                for (var i = 0; i < unrelated; i++)
                  'unused-fact-$i': const NarrativeValue.boolean(false),
              },
            )
          : const ProjectNewGameConfig(),
      facts: [
        if (configuredNewGame)
          for (var i = 0; i < unrelated; i++)
            NarrativeFactDefinition(id: 'unused-fact-$i', label: 'Fact $i'),
      ],
      pokemon: const ProjectPokemonConfig(
        catalogFiles: {'items': 'data/items.json'},
        ruleset: PokemonRulesetProfile.standardV1,
      ),
      trainers: [
        const ProjectTrainerEntry(
          id: 'selected-trainer',
          name: 'Selected',
          trainerClass: 'Trainer',
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectTrainerEntry(
            id: 'unused-trainer-$i',
            name: 'Unused',
            trainerClass: 'Trainer',
          ),
      ],
      shops: [
        const ShopDefinition(id: 'selected-shop', label: 'Selected'),
        for (var i = 0; i < unrelated; i++)
          ShopDefinition(id: 'unused-shop-$i', label: 'Unused'),
      ],
      encounterTables: [
        const ProjectEncounterTable(
          id: 'selected-table',
          name: 'Selected',
          encounterKind: EncounterKind.walk,
          entries: [
            ProjectEncounterEntry(
              speciesId: 'species',
              minLevel: 5,
              maxLevel: 5,
            ),
          ],
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectEncounterTable(
            id: 'unused-table-$i',
            name: 'Unused',
            encounterKind: EncounterKind.walk,
            entries: const [],
          ),
      ],
    );
    if (nativeJson) {
      final raw = project.toJson();
      raw['futureRoot'] = {
        'opaque': [3, 1, 2],
      };
      (raw['pokemon'] as Map)['futurePokemon'] = true;
      (raw['newGame'] as Map)['futureNewGame'] = true;
      for (final field in ['shops', 'trainers', 'encounterTables']) {
        for (final value in (raw[field] as List).cast<Map>()) {
          value['futureDocument'] = {'keep': value['id']};
        }
      }
      await File('${root.path}/project.json').writeAsString(jsonEncode(raw));
    } else {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
        store: store,
        projectId: 'pokemon-scoped',
        project: project,
      );
    }
    final file = File('${root.path}/data/items.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(
        encodeProjectItemCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'item',
                displayName: 'Item',
                pocketId: 'items',
              ),
            ],
          ),
        ),
      ),
    );
    final sessionPort = nativeJson ? LocalProjectSessionAdapter() : null;
    final session = sessionPort == null
        ? ProjectSession(
            sessionId: root.path,
            name: project.name,
            directoryPath: root.path,
            storage: ProjectSessionStorage.workingCatalog,
          )
        : await sessionPort.open(root.path);
    final legacyHistory = File('${root.path}/.pokemap/authoring/history.jsonl');
    await legacyHistory.parent.create(recursive: true);
    await legacyHistory.writeAsString('unrelated legacy history');
    final reader = CountingReader();
    final maps = LocalMapWorkspaceAdapter(reader: reader);
    if (nativeJson) {
      await maps.loadProject(session);
    } else {
      await maps.loadCatalog(session);
    }
    debugPrint(
      'POKEMON_SETUP_DEBUG unrelated=$unrelated elapsedMs=${creation.elapsedMilliseconds}',
    );
    return ScopedSaveFixture(
      root,
      session,
      reader,
      maps,
      closeSession: sessionPort == null
          ? null
          : () => sessionPort.close(session),
    );
  }

  void expectScoped(String action, Stopwatch watch, Map<String, int> counts) {
    watch.stop();
    debugPrint(
      'POKEMON_SAVE_DEBUG storage=${session.storage.name} action=$action elapsedUs=${watch.elapsedMicroseconds} metadataReads=${reader.definitions.length} allReads=${reader.paths.length}',
    );
    final baselineCount = counts.putIfAbsent(
      '${session.storage.name}/$action',
      () => reader.definitions.length,
    );
    expect(
      reader.definitions.length,
      baselineCount,
      reason: 'Same scoped metadata work for $action',
    );
    if (session.storage == ProjectSessionStorage.manifest) {
      expect(
        reader.paths.length,
        counts.putIfAbsent(
          'manifest/$action/allReads',
          () => reader.paths.length,
        ),
        reason: 'Same native shared-document reads for $action',
      );
    }
    expect(reader.definitions.where((id) => id.startsWith('unused-')), isEmpty);
    expect(
      [...reader.paths, ...reader.probes].where(
        (path) =>
            path.startsWith('maps/') ||
            path.startsWith('assets/') ||
            path.endsWith('history.jsonl') ||
            path.endsWith('idempotency.jsonl'),
      ),
      isEmpty,
    );
  }

  Future<void> close() async {
    await closeSession?.call();
    await root.delete(recursive: true);
  }
}
