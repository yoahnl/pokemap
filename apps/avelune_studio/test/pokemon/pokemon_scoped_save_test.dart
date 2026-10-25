import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_transaction.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  final counts = <String, int>{};
  for (final nativeJson in [false, true]) {
    for (final unrelated in [
      0,
      const bool.fromEnvironment('AVELUNE_LOCAL_900') ? 900 : 9,
    ]) {
      test(
        'real Studio ${nativeJson ? 'native JSON' : 'catalog'} saves and reopen ignore $unrelated unrelated same-field documents',
        () async {
          final fixture = await _Fixture.open(
            unrelated,
            nativeJson: nativeJson,
            configuredNewGame: nativeJson,
          );
          addTearDown(fixture.close);
          final originalRaw = nativeJson
              ? jsonDecode(
                  await File('${fixture.root.path}/project.json')
                      .readAsString(),
                ) as Map
              : null;
          final commerce = PokemonCommerceController(
            fixture.commerce,
            changed: () {},
          );
          final combat = PokemonCombatController(
            fixture.combat,
            changed: () {},
          );
          addTearDown(commerce.dispose);
          addTearDown(combat.dispose);
          final opening = Stopwatch()..start();
          await commerce.load();
          await combat.load();
          debugPrint(
            'POKEMON_OPEN_DEBUG unrelated=$unrelated controllerLoadMs=${opening.elapsedMilliseconds}',
          );
          var trainerBefore = combat.snapshot!.project.trainers.firstWhere(
            (value) => value.id == 'selected-trainer',
          );
          var rulesetBefore = combat.snapshot!.project.pokemon.ruleset;
          for (var attempt = 0; attempt < 2; attempt++) {
            final watch = Stopwatch();
            commerce.selectItem(commerce.snapshot!.catalog!.entries.single);
            commerce.editItem(
              (value) => value.copyWith(displayName: 'Item $attempt'),
            );
            fixture.reader.clear();
            watch
              ..reset()
              ..start();
            expect(await commerce.save(), isTrue, reason: commerce.error);
            fixture.expectScoped('item/$attempt', watch, counts);
            expect(commerce.snapshot!.referencesComplete, isFalse);

            commerce.selectShop(
              commerce.snapshot!.shops.firstWhere(
                (value) => value.id == 'selected-shop',
              ),
            );
            commerce.editShop(
              (value) => value.copyWith(label: 'Shop $attempt'),
            );
            fixture.reader.clear();
            watch
              ..reset()
              ..start();
            expect(await commerce.save(), isTrue, reason: commerce.error);
            fixture.expectScoped('shop/$attempt', watch, counts);

            fixture.reader.clear();
            watch
              ..reset()
              ..start();
            expect(
              await commerce.saveBagCapacity(
                commerce.snapshot!.project.bagCapacity,
                ProjectBagCapacity(
                  pockets: {
                    'items': BagPocketCapacity(maxDistinctItems: attempt + 1),
                  },
                ),
              ),
              isTrue,
              reason: commerce.error,
            );
            fixture.expectScoped('bag/$attempt', watch, counts);

            combat.selectTable(
              combat.snapshot!.project.encounterTables.firstWhere(
                (value) => value.id == 'selected-table',
              ),
            );
            combat.editTable((value) => value.copyWith(name: 'Table $attempt'));
            fixture.reader.clear();
            watch
              ..reset()
              ..start();
            expect(await combat.save(_index), isTrue, reason: combat.error);
            fixture.expectScoped('table/$attempt', watch, counts);

            fixture.reader.clear();
            final trainerAfter = trainerBefore.copyWith(
              name: 'Trainer $attempt',
            );
            watch
              ..reset()
              ..start();
            await fixture.combat.saveTrainer(trainerBefore, trainerAfter);
            trainerBefore = trainerAfter;
            fixture.expectScoped('trainer/$attempt', watch, counts);
            if (nativeJson) {
              final rulesetAfter = attempt == 0
                  ? PokemonRulesetProfile.pokeMapBetaV1
                  : PokemonRulesetProfile.standardV1;
              fixture.reader.clear();
              watch
                ..reset()
                ..start();
              await fixture.combat.setRuleset(rulesetBefore, rulesetAfter);
              rulesetBefore = rulesetAfter;
              fixture.expectScoped('ruleset/$attempt', watch, counts);
            }
          }
          final coldMaps = LocalMapWorkspaceAdapter(reader: fixture.reader);
          final coldCommerce = LocalPokemonCommerceAdapter(
            session: fixture.session,
            mapAdapter: coldMaps,
            reader: fixture.reader,
          );
          final coldCombat = LocalPokemonCombatAdapter(
            session: fixture.session,
            mapAdapter: coldMaps,
            reader: fixture.reader,
          );
          final savedCommerce = await coldCommerce.load();
          final savedCombat = await coldCombat.load();
          expect(savedCommerce.catalog!.entries.single.displayName, 'Item 1');
          expect(
            savedCommerce.shops
                .firstWhere((value) => value.id == 'selected-shop')
                .label,
            'Shop 1',
          );
          expect(
            savedCommerce
                .project
                .bagCapacity
                .pockets['items']!
                .maxDistinctItems,
            2,
          );
          expect(
            savedCombat.project.encounterTables
                .firstWhere((value) => value.id == 'selected-table')
                .name,
            'Table 1',
          );
          expect(
            savedCombat.project.trainers
                .firstWhere((value) => value.id == 'selected-trainer')
                .name,
            'Trainer 1',
          );
          expect(savedCombat.project.trainers.length, unrelated + 1);
          expect(
            savedCombat.project.pokemon.ruleset,
            PokemonRulesetProfile.standardV1,
          );
          if (originalRaw != null) {
            final savedRaw = jsonDecode(
              await File('${fixture.root.path}/project.json').readAsString(),
            ) as Map;
            for (final field in [
              'maps',
              'tilesets',
              'characters',
              'facts',
              'newGame',
              'settings',
              'futureRoot',
            ]) {
              expect(savedRaw[field], originalRaw[field], reason: field);
            }
            expect((savedRaw['pokemon'] as Map)['futurePokemon'], true);
            for (final field in ['shops', 'trainers', 'encounterTables']) {
              final original = (originalRaw[field] as List).cast<Map>();
              final saved = (savedRaw[field] as List).cast<Map>();
              for (final row in original) {
                final after = saved.singleWhere(
                  (value) => value['id'] == row['id'],
                );
                expect(after['futureDocument'], row['futureDocument']);
                if ((row['id'] as String).startsWith('unused-')) {
                  expect(after, row);
                }
              }
            }
          }
          expect(
            await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
                .readAsString(),
            'unrelated legacy history',
          );
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    }
  }

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

  test('item title saves leave configured New Game avatars and initial Facts untouched', () async {
    final unrelated = const bool.fromEnvironment('AVELUNE_LOCAL_900') ? 900 : 9;
    final fixture = await _Fixture.open(unrelated, configuredNewGame: true);
    addTearDown(fixture.close);
    final commerce = PokemonCommerceController(
      fixture.commerce,
      changed: () {},
    );
    addTearDown(commerce.dispose);
    await commerce.load();
    final before = commerce.snapshot!.project.newGame;
    commerce.selectItem(commerce.snapshot!.catalog!.entries.single);
    commerce.editItem(
      (value) => value.copyWith(displayName: 'Updated with New Game'),
    );
    fixture.reader.clear();
    expect(await commerce.save(), isTrue, reason: commerce.error);
    expect(
      fixture.reader.definitions.where((id) => id.startsWith('unused-')),
      isEmpty,
    );
    expect(
      fixture.reader.unitKeys.where(
        (key) => key.contains('foreign-hero') || key.contains('hero-avatar'),
      ),
      isEmpty,
    );
    expect(
      fixture.reader.paths.where(
        (path) => path.startsWith('maps/') || path.startsWith('assets/'),
      ),
      isEmpty,
    );
    expect((await fixture.commerce.load()).project.newGame, before);
    expect(
      (await fixture.maps.resourceBaseline(fixture.session)).manifest.newGame,
      before,
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
    'scoped deletes preserve selected drafts and never load global references',
    () async {
      final fixture = await _Fixture.open(0);
      addTearDown(fixture.close);
      final controller = PokemonCombatController(
        fixture.combat,
        changed: () {},
      );
      addTearDown(controller.dispose);
      await controller.load();
      final before = controller.snapshot!;
      controller.selectTable(before.project.encounterTables.single);
      controller.snapshot = PokemonCombatSnapshot(
        project: before.project,
        maps: const [],
        referencesComplete: true,
      );
      final head = File(
        '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
      );
      final bytes = await head.readAsBytes();
      fixture.reader.clear();
      expect(await controller.deleteSelected(), isFalse);
      expect(controller.table!.current, before.project.encounterTables.single);
      expect(controller.error, contains('catalog.mutation_scope_required'));
      expect(await head.readAsBytes(), bytes);
      expect(
        fixture.reader.paths.where((path) => path.startsWith('maps/')),
        isEmpty,
      );
      await expectLater(
        fixture.combat.deleteTrainer(before.project.trainers.single),
        throwsA(
          isA<AuthoringPlanException>().having(
            (failure) => failure.code,
            'code',
            'catalog.mutation_scope_required',
          ),
        ),
      );
      expect(await head.readAsBytes(), bytes);
    },
  );

  for (final nativeJson in [false, true]) {
    test(
      'new ${nativeJson ? 'native JSON' : 'catalog'} canonical documents append and normalized item values stay coherent',
      () async {
        final fixture = await _Fixture.open(0, nativeJson: nativeJson);
        addTearDown(fixture.close);
        final controller = PokemonCommerceController(
          fixture.commerce,
          changed: () {},
        );
        addTearDown(controller.dispose);
        await controller.load();
        expect(controller.createItem('new-item'), isTrue);
        controller.editItem(
          (value) => value.copyWith(displayName: ' New item '),
        );
        expect(await controller.save(), isTrue, reason: controller.error);
        expect(controller.item!.displayName, 'New item');
        expect(controller.dirty, isFalse);
        expect(controller.createShop('new-shop'), isTrue);
        expect(await controller.save(), isTrue, reason: controller.error);
        const table = ProjectEncounterTable(
          id: 'new-table',
          name: 'New',
          encounterKind: EncounterKind.walk,
        );
        const trainer = ProjectTrainerEntry(
          id: 'new-trainer',
          name: 'New',
          trainerClass: 'Trainer',
        );
        await fixture.combat.saveTable(null, table);
        await fixture.combat.saveTrainer(null, trainer);
        final reopened = await fixture.combat.load();
        expect(reopened.project.encounterTables.map((value) => value.id), [
          'selected-table',
          'new-table',
        ]);
        expect(reopened.project.trainers.map((value) => value.id), [
          'selected-trainer',
          'new-trainer',
        ]);
        final commerce = await fixture.commerce.load();
        expect(commerce.catalog!.entries.map((value) => value.id), [
          'item',
          'new-item',
        ]);
        expect(commerce.shops.map((value) => value.id), [
          'selected-shop',
          'new-shop',
        ]);
      },
    );
  }

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

  test(
    'recovered publication is verified before Studio acknowledges success',
    () async {
      final fixture = await _Fixture.open(0);
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

  test(
    'stale before values preserve the local controller draft and external item',
    () async {
      final fixture = await _Fixture.open(0);
      addTearDown(fixture.close);
      final controller = PokemonCommerceController(
        fixture.commerce,
        changed: () {},
      );
      addTearDown(controller.dispose);
      await controller.load();
      controller.selectItem(controller.snapshot!.catalog!.entries.single);
      controller.editItem((value) => value.copyWith(displayName: 'Draft'));
      final external = controller.snapshot!.catalog!.copyWith(
        entries: [
          controller.snapshot!.catalog!.entries.single.copyWith(
            displayName: 'External',
          ),
        ],
      );
      final file = File('${fixture.root.path}/data/items.json');
      await file.writeAsString(jsonEncode(encodeProjectItemCatalog(external)));
      final bytes = await file.readAsBytes();
      expect(await controller.save(), isFalse);
      expect(controller.item!.displayName, 'Draft');
      expect(controller.dirty, isTrue);
      expect(await file.readAsBytes(), bytes);
    },
  );
}

const _index = PokemonWorkspaceIndex(
  enabled: true,
  entries: [
    PokemonSpeciesSummary(
      id: 'species',
      name: 'Species',
      nationalDex: 1,
      generation: 1,
      types: [],
      formIds: [],
      mediaRelativePath: '',
      enabled: true,
      relativePath: 'species.json',
    ),
  ],
  moves: PokemonMovesCatalogView(entries: [], relativePath: 'moves.json'),
  types: [],
  items: {},
);

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
