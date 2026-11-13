import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_transaction.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {

  test(
    'scoped Pokemon edits preserve the execution profile of a 3D project',
    () async {
      final fixture = await _Fixture.open(0, spatial: true);
      addTearDown(fixture.close);
      final before = await fixture.combat.load();
      final commerce = await fixture.commerce.load();
      await fixture.combat.saveTable(
        before.project.encounterTables.single,
        before.project.encounterTables.single.copyWith(name: 'Spatial table'),
      );
      await fixture.combat.saveTrainer(
        before.project.trainers.single,
        before.project.trainers.single.copyWith(name: 'Spatial trainer'),
      );
      await fixture.commerce.saveShop(
        commerce.shops.single,
        commerce.shops.single.copyWith(label: 'Spatial shop'),
      );
      await fixture.commerce.saveBagCapacity(
        commerce.project.bagCapacity,
        const ProjectBagCapacity(
          pockets: {'items': BagPocketCapacity(maxDistinctItems: 5)},
        ),
      );
      await fixture.combat.setRuleset(
        before.project.pokemon.ruleset,
        PokemonRulesetProfile.pokeMapBetaV1,
      );
      final after = await fixture.maps.resourceBaseline(fixture.session);
      expect(after.manifest.version, ProjectVersion.v9);
      expect(after.manifest.settings.dimension, ProjectDimension.threeD);
      expect(after.manifest.settings.spatialCamera, isNotNull);
      expect(
        (await fixture.combat.load()).project.trainers.single.name,
        'Spatial trainer',
      );
    },
  );

  test('first save works without a preloaded map workspace', () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final adapter = LocalPokemonCommerceAdapter(
      session: fixture.session,
      mapAdapter: LocalMapWorkspaceAdapter(reader: fixture.reader),
      reader: fixture.reader,
    );
    final before = (await adapter.load()).catalog!.entries.single;
    await adapter.saveItem(before, before.copyWith(displayName: 'Autonomous'));
    expect(
      (await adapter.load()).catalog!.entries.single.displayName,
      'Autonomous',
    );
  });

  for (final nativeJson in [false, true]) {
    test(
      'recovered ${nativeJson ? 'native JSON' : 'catalog'} publication is verified before Studio acknowledges success',
      () async {
        final fixture = await _Fixture.open(
          0,
          nativeJson: nativeJson,
          configuredNewGame: nativeJson,
        );
        addTearDown(fixture.close);
        var injected = false;
        final adapter = LocalPokemonCommerceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          reader: fixture.reader,
          faultInjector: (checkpoint) {
            if (!injected &&
                checkpoint.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted) {
              injected = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        final before = (await adapter.load()).shops.single;
        await adapter.saveShop(before, before.copyWith(label: 'Recovered'));
        expect(injected, isTrue);
        expect((await adapter.load()).shops.single.label, 'Recovered');
      },
    );
  }

  test('concurrent HEAD publication after verification does not merge across catalog generations', () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final transaction = LocalPokemonTransaction(
      session: fixture.session,
      mapAdapter: fixture.maps,
      reader: fixture.reader,
    );
    const after = ProjectBagCapacity(
      pockets: {'items': BagPocketCapacity(maxDistinctItems: 3)},
    );
    final head = File(
      '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
    );
    final initialHead = await head.readAsBytes();
    final before = await fixture.maps.resourceBaseline(fixture.session);
    late List<int> savedHead;
    final warning = await transaction.run(
      actionId: 'bag.capacity.set',
      parameters: after.toJson(),
      allowedStorageKeys: (_) => {'project.json'},
      validateBefore: (_) {},
      validateAfter: (snapshot) {
        expect(snapshot.manifest.bagCapacity, after);
        savedHead = head.readAsBytesSync();
        head.writeAsBytesSync(initialHead);
      },
    );
    expect(warning, contains('Enregistrement confirmé'));
    expect(warning, contains('le projet a changé'));
    expect(
      (await fixture.maps.resourceBaseline(fixture.session))
          .manifest
          .bagCapacity,
      before.manifest.bagCapacity,
    );
    await head.writeAsBytes(savedHead);
    expect((await fixture.commerce.load()).project.bagCapacity, after);
  });

}

final class _Fixture {
  _Fixture(
    this.root,
    this.session,
    this.reader,
    this.maps, {
    this.closeSession,
  });
  final Directory root;
  final ProjectSession session;
  final _CountingReader reader;
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

  static Future<_Fixture> open(
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
    final reader = _CountingReader();
    final maps = LocalMapWorkspaceAdapter(reader: reader);
    if (nativeJson) {
      await maps.loadProject(session);
    } else {
      await maps.loadCatalog(session);
    }
    debugPrint(
      'POKEMON_SETUP_DEBUG unrelated=$unrelated elapsedMs=${creation.elapsedMilliseconds}',
    );
    return _Fixture(
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

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final local = const LocalProjectFileReader();
  final paths = <String>[];
  final probes = <String>[];
  final definitions = <String>[];
  final unitKeys = <String>[];
  void clear() {
    paths.clear();
    probes.clear();
    definitions.clear();
    unitKeys.clear();
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      local.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    probes.add(relativePath);
    return local.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  void _record(String path, List<int> bytes) {
    if (path.startsWith('catalog/objects/')) {
      final json = jsonDecode(utf8.decode(bytes)) as Map;
      if (json['type'] == 'unit') {
        final key = json['key'] as Map;
        unitKeys.add('${key['kind']}:${key['id']}');
        final payload = json['payload'] as Map;
        if (payload['section'] == r'$projectDefinition') {
          final definition = (payload['value'] as Map)['definition'] as Map;
          definitions.add(definition['id'] as String);
        }
      }
    }
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    final bytes = await local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    _record(relativePath, bytes);
    return bytes;
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}
