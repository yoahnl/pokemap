import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final ineligible in [false, true]) {
    test(
        'trainer medicine ${ineligible ? 'ineligible' : 'unknown'} refuses start before authoring attachment',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final project = await fixture.project();
      await fixture.write(
          'project.json',
          project.copyWith(trainers: const [
            ProjectTrainerEntry(
                id: 'trainer',
                name: 'Trainer',
                trainerClass: 'Fixture',
                battleItems: {
                  'medicine': 1
                },
                team: [
                  ProjectTrainerPokemonEntry(speciesId: 'bulbasaur', level: 5)
                ]),
          ]).toJson());
      await fixture.write(
          project.pokemon.catalogFiles['items']!,
          ProjectItemCatalog(schemaVersion: 1, entries: [
            if (ineligible)
              const ProjectItemDefinition(
                  id: 'medicine',
                  displayName: 'Medicine',
                  pocketId: 'medicine'),
          ]).toJson());
      const service = ConverterPlayableStartService();
      final inspection = await service.inspect(
          projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
      final before = await fixture.contents(includeLocalState: true);
      await expectLater(
          service.apply(
              projectPath: fixture.root.path,
              allowedRootPath: fixture.root.path,
              expectedRevision: inspection.revision,
              mapId: 'map_start',
              spawnId: 'start',
              starterSpeciesIds:
                  inspection.species.take(2).map((value) => value.id).toList()),
          throwsA(isA<ValidationException>().having(
              (error) => error.code,
              'code',
              ineligible
                  ? 'trainer.battle_item_ineligible'
                  : 'trainer.battle_item_unknown')));
      expect(await fixture.contents(includeLocalState: true), before);
    });
  }
  test(
      'inspects an existing canonical empty-party start without Pokemon catalogs or mutations',
      () async {
    final fixture = await _Fixture.emptyCanonical();
    addTearDown(fixture.dispose);
    final before = await fixture.contents(includeLocalState: true);
    final inspected = await const ConverterPlayableStartService().inspect(
        projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
    expect(inspected.configured, isTrue);
    expect(inspected.existingNewGame, isTrue);
    expect(inspected.resumable, isFalse);
    expect(inspected.species, isEmpty);
    expect(await fixture.contents(includeLocalState: true), before);
    await expectLater(
        const ConverterPlayableStartService().apply(
            projectPath: fixture.root.path,
            allowedRootPath: fixture.root.path,
            expectedRevision: inspected.revision,
            mapId: 'intro',
            spawnId: 'entry',
            starterSpeciesIds: const []),
        _error('playable_start.already_authored'));
    expect(await fixture.contents(includeLocalState: true), before);
  });
  test(
      'rejects invalid existing start references without changing a portable project',
      () async {
    final fixture = await _Fixture.emptyCanonical();
    addTearDown(fixture.dispose);
    final project = await fixture.project();
    final original = project.newGame.toJson();
    for (final replacement in [
      {...original, 'startMapId': 'missing'},
      {...original, 'startSpawnId': 'missing'},
      {...original, 'preSessionSceneId': 'missing'},
      {
        ...original,
        'initialRecoveryPoint': {
          'mapId': 'home',
          'position': {'x': 2, 'y': 1},
          'facing': 'south'
        }
      },
    ]) {
      await fixture.write(
          'project.json',
          project
              .copyWith(newGame: ProjectNewGameConfig.fromJson(replacement))
              .toJson());
      final before = await fixture.contents(includeLocalState: true);
      await expectLater(
          const ConverterPlayableStartService().inspect(
              projectPath: fixture.root.path,
              allowedRootPath: fixture.root.path),
          throwsA(anything));
      expect(await fixture.contents(includeLocalState: true), before);
    }
  });
  test(
      'recognizes an existing direct empty-party start without a pre-session scene',
      () async {
    final fixture = await _Fixture.emptyCanonical();
    addTearDown(fixture.dispose);
    final project = await fixture.project();
    await fixture.write(
        'project.json',
        project
            .copyWith(
                newGame: ProjectNewGameConfig.fromJson(
                    {...project.newGame.toJson(), 'preSessionSceneId': null}))
            .toJson());
    final before = await fixture.contents(includeLocalState: true);
    final inspected = await const ConverterPlayableStartService().inspect(
        projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
    expect(inspected.existingNewGame, isTrue);
    expect(inspected.species, isEmpty);
    expect(await fixture.contents(includeLocalState: true), before);
  });
  test('declares a native start with a genuine starter selection', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final original = await fixture.project();
    await fixture.write(
        'project.json',
        original.copyWith(trainers: const [
          ProjectTrainerEntry(
              id: 'trainer',
              name: 'Trainer',
              trainerClass: 'Fixture',
              battleItems: {
                'full-heal': 1
              },
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'bulbasaur', level: 5)
              ]),
        ]).toJson());
    await fixture.write(
        original.pokemon.catalogFiles['items']!,
        ProjectItemCatalog(schemaVersion: 1, entries: [
          mvpItemCatalog.entries.singleWhere((item) => item.id == 'full-heal'),
        ]).toJson());
    const service = ConverterPlayableStartService();
    final before = await fixture.contents();
    final inspection = await service.inspect(
        projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
    expect(await fixture.contents(), before);
    expect(inspection.configured, isFalse);
    expect(inspection.avatars.single.id, 'player');
    expect(inspection.maps.single.spawns.single.id, 'start');
    expect(inspection.species.length, greaterThanOrEqualTo(2));
    final ids = inspection.species.take(2).map((entry) => entry.id).toList();
    final receipt = await service.apply(
        projectPath: fixture.root.path,
        allowedRootPath: fixture.root.path,
        expectedRevision: inspection.revision,
        mapId: 'map_start',
        spawnId: 'start',
        starterSpeciesIds: ids);
    expect(receipt.newGameReceipt.actionId, 'campaign.new_game.update');
    expect(receipt.preSessionReceipt.actionId, 'scene.preSession.create');
    final project = await fixture.project();
    expect(project.newGame.initialParty, isEmpty);
    expect(
        project.newGame.starterOptions.map((entry) => entry.pokemon.speciesId),
        ids);
    expect(project.newGame.playerAvatarCharacterIds, ['player']);
    final scene = project.scenes.single;
    expect(scene.executionProfile, SceneExecutionProfile.preSession);
    expect(buildSceneRuntimePlan(scene).canBuild, isTrue);
    final interactions = scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.preSessionInteraction)
        .whereType<ScenePreSessionInteractionSpec>();
    final avatarChoice = interactions.singleWhere((entry) =>
        entry.resultBinding?.field ==
        ScenePreSessionDraftField.avatarCharacterId);
    expect(avatarChoice.options.single.label.fallbackText, 'Player');
    expect(avatarChoice.options.single.label.fallbackText,
        isNot(avatarChoice.options.single.id));
    expect(
        interactions.any((entry) =>
            entry.resultBinding?.field ==
            ScenePreSessionDraftField.starterOptionId),
        isTrue);
    final draft = NewGameDraft.start(
        draftId: 'draft',
        projectRevision: receipt.finalRevision,
        slotId: 'slot',
        config: project.newGame);
    expect(draft.starterOptionId, isNull);
    for (final option in project.newGame.starterOptions) {
      expect(option.pokemon.currentHp, greaterThan(1));
      expect(option.pokemon.abilityId, isNot('unknown'));
      expect(option.pokemon.knownMoveIds, isNotEmpty);
      expect(option.pokemon.currentPpByMoveId!.values.every((pp) => pp > 0),
          isTrue);
      final selected = draft
          .apply(NewGameDraftCommand.selectStarter(
              expectedRevision: draft.revision, starterOptionId: option.id))
          .draft;
      final ready = selected
          .apply(NewGameDraftCommand.selectAvatar(
              expectedRevision: selected.revision, avatarCharacterId: 'player'))
          .draft;
      final commit = commitNewGameDraft(
          journal: NewGameSeedCommitJournal.empty(),
          operationId: 'commit-${option.id}',
          currentProjectRevision: receipt.finalRevision,
          expectedDraftRevision: ready.revision,
          draft: ready);
      expect(commit.status, NewGameSeedCommitStatus.committed);
      final state = createNewGameStateFromSeed(
          project: project,
          startMap: fixture.map,
          seed: commit.seed!,
          currentProjectRevision: receipt.finalRevision,
          tileWidthPx: 32,
          tileHeightPx: 32);
      expect(state.party.members.single.speciesId, option.pokemon.speciesId);
    }
    final reread = await service.inspect(
        projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
    expect(reread.configured, isTrue);
    expect(reread.revision, receipt.finalRevision);
  });

  test(
      'refuses stale revisions and invalid selections without changing content',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    const service = ConverterPlayableStartService();
    final inspection = await service.inspect(
        projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
    final ids = inspection.species.take(2).map((entry) => entry.id).toList();
    final before = await fixture.contents();
    for (final selection in [
      (
        revision: 'sha256:${'0' * 64}',
        map: 'map_start',
        spawn: 'start',
        species: ids,
        level: 5
      ),
      (
        revision: inspection.revision,
        map: 'missing',
        spawn: 'start',
        species: ids,
        level: 5
      ),
      (
        revision: inspection.revision,
        map: 'map_start',
        spawn: 'missing',
        species: ids,
        level: 5
      ),
      (
        revision: inspection.revision,
        map: 'map_start',
        spawn: 'start',
        species: ['missing', ids.first],
        level: 5
      ),
      (
        revision: inspection.revision,
        map: 'map_start',
        spawn: 'start',
        species: ids,
        level: 101
      ),
      (
        revision: inspection.revision,
        map: 'map_start',
        spawn: 'start',
        species: [ids.first],
        level: 5
      ),
    ]) {
      await expectLater(
          service.apply(
              projectPath: fixture.root.path,
              allowedRootPath: fixture.root.path,
              expectedRevision: selection.revision,
              mapId: selection.map,
              spawnId: selection.spawn,
              starterSpeciesIds: selection.species,
              starterLevel: selection.level),
          throwsA(isA<ConverterPlayableStartException>()));
      expect(await fixture.contents(), before);
    }
  });

  test('refuses disabled catalogs and a project outside the explicit root',
      () async {
    final fixture = await _Fixture.create(enabled: false);
    addTearDown(fixture.dispose);
    const service = ConverterPlayableStartService();
    await expectLater(
        service.inspect(
            projectPath: fixture.root.path, allowedRootPath: fixture.root.path),
        _error('playable_start.catalog_disabled'));
    final outside =
        await Directory.systemTemp.createTemp('playable_start_outside');
    addTearDown(() => outside.delete(recursive: true));
    await expectLater(
        service.inspect(
            projectPath: fixture.root.path, allowedRootPath: outside.path),
        throwsA(anything));
  });

  test(
      'resumes an identical partial start regardless of starter selection order',
      () async {
    final complete = await _Fixture.create();
    final partial = await _Fixture.create();
    addTearDown(complete.dispose);
    addTearDown(partial.dispose);
    const service = ConverterPlayableStartService();
    final initial = await service.inspect(
        projectPath: complete.root.path, allowedRootPath: complete.root.path);
    final ids = initial.species.take(2).map((entry) => entry.id).toList();
    await service.apply(
        projectPath: complete.root.path,
        allowedRootPath: complete.root.path,
        expectedRevision: initial.revision,
        mapId: 'map_start',
        spawnId: 'start',
        starterSpeciesIds: ids);
    final config = ProjectNewGameConfig.fromJson({
      ...(await complete.project()).newGame.toJson(),
      'preSessionSceneId': null,
    });
    final digest =
        sha256.convert(utf8.encode(jsonEncode(config.toJson()))).toString();
    final first = await _canonicalApply(partial, 'campaign.new_game.update',
        {'newGame': config.toJson()}, 'converter-start-$digest-new-game');
    final inspection = await service.inspect(
        projectPath: partial.root.path, allowedRootPath: partial.root.path);
    expect(inspection.resumable, isTrue);
    expect(inspection.configured, isFalse);
    final before = await partial.contents();
    await expectLater(
        service.apply(
            projectPath: partial.root.path,
            allowedRootPath: partial.root.path,
            expectedRevision: inspection.revision,
            mapId: 'map_start',
            spawnId: 'start',
            starterSpeciesIds: ids,
            starterLevel: 6),
        _error('playable_start.already_authored'));
    expect(await partial.contents(), before);
    final resumed = await service.apply(
        projectPath: partial.root.path,
        allowedRootPath: partial.root.path,
        expectedRevision: inspection.revision,
        mapId: 'map_start',
        spawnId: 'start',
        starterSpeciesIds: ids.reversed.toList());
    expect(resumed.resumed, isTrue);
    expect(resumed.newGameReceipt.receiptId, first.receiptId);
    expect((await partial.project()).newGame.starterOptions,
        (await complete.project()).newGame.starterOptions);
    expect((await partial.project()).scenes, hasLength(1));
  });

  test('refuses an authored start and unresolved native catalog references',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    const service = ConverterPlayableStartService();
    final project = await fixture.project();
    await fixture.write(
        'project.json',
        project
            .copyWith(newGame: const ProjectNewGameConfig(playerName: 'Author'))
            .toJson());
    final inspection = await service.inspect(
        projectPath: fixture.root.path, allowedRootPath: fixture.root.path);
    final before = await fixture.contents();
    await expectLater(
        service.apply(
            projectPath: fixture.root.path,
            allowedRootPath: fixture.root.path,
            expectedRevision: inspection.revision,
            mapId: 'map_start',
            spawnId: 'start',
            starterSpeciesIds:
                inspection.species.take(2).map((entry) => entry.id).toList()),
        _error('playable_start.already_authored'));
    expect(await fixture.contents(), before);
    final first = inspection.species.first.id;
    await File('${fixture.root.path}/data/pokemon/learnsets/$first.json')
        .delete();
    await expectLater(
        service.inspect(
            projectPath: fixture.root.path, allowedRootPath: fixture.root.path),
        _error('playable_start.catalog_invalid'));
  });
}

Future<AuthoringReceipt> _canonicalApply(_Fixture fixture, String actionId,
    Map<String, Object?> parameters, String operation) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.root.path], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(fixture.root.path);
  final api =
      LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
  try {
    await api.attachProject(
        projectRootPath: fixture.root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final before = await snapshots.load(opened.projectHandle);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: operation,
            parameters: parameters));
    return (await api.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: operation))
        .receipt;
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
  }
}

Matcher _error(String code) => throwsA(isA<ConverterPlayableStartException>()
    .having((error) => error.code, 'code', code));

final class _Fixture {
  _Fixture(this.root, this.map);
  final Directory root;
  final MapData map;

  static Future<_Fixture> emptyCanonical() async {
    final root =
        await Directory.systemTemp.createTemp('existing-canonical-start-');
    const map = MapData(
        id: 'intro',
        name: 'Intro',
        size: GridSize(width: 3, height: 3),
        entities: [
          MapEntity(
              id: 'entry',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 1, y: 1),
              spawn: MapEntitySpawnData(
                  role: EntitySpawnRole.playerStart,
                  facing: EntityFacing.east)),
        ]);
    const recovery =
        MapData(id: 'home', name: 'Home', size: GridSize(width: 2, height: 2));
    const config = ProjectNewGameConfig(
        enabled: true,
        startMapId: 'intro',
        startSpawnId: 'entry',
        initialRecoveryPoint: ProjectNewGameRecoveryPoint(
            mapId: 'home',
            position: GridPos(x: 0, y: 1),
            facing: EntityFacing.south));
    const manifest = ProjectManifest(
        name: 'Existing entry',
        maps: [
          ProjectMapEntry(
              id: 'intro', name: 'Intro', relativePath: 'maps/intro.json'),
          ProjectMapEntry(
              id: 'home', name: 'Home', relativePath: 'maps/home.json'),
        ],
        tilesets: [],
        newGame: config);
    final project = const SceneActions().createPreSessionScene(manifest,
        maps: [map, recovery],
        sceneId: 'declared-identity',
        name: 'Identity',
        templateId: 'identitySetup',
        setAsEntrypoint: true);
    final fixture = _Fixture(root, map);
    await fixture.write('project.json', project.toJson());
    await fixture.write('maps/intro.json', map.toJson());
    await fixture.write('maps/home.json', recovery.toJson());
    return fixture;
  }

  static Future<_Fixture> create({bool enabled = true}) async {
    final root =
        await Directory.systemTemp.createTemp('converter_playable_start');
    final bundle = NativePsdkTrainerBundle.builtin();
    final config = ProjectPokemonConfig(
        enabled: enabled,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {
          'items': 'data/pokemon/catalogs/items.json',
          for (final entry in bundle.catalogs.entries)
            entry.key: 'data/pokemon/catalogs/${entry.key}.json',
        });
    const map = MapData(
        id: 'map_start',
        name: 'Start',
        version: ProjectVersion.v8,
        size: GridSize(width: 5, height: 5),
        layers: [
          MapLayer.tile(id: 'ground', name: 'Ground', cells: [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
          ])
        ],
        entities: [
          MapEntity(
              id: 'start',
              name: 'Start',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 2, y: 2),
              blocksMovement: false,
              spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart))
        ]);
    final project = ProjectManifest(
        name: 'Conversion',
        version: ProjectVersion.v8,
        maps: const [
          ProjectMapEntry(
              id: 'map_start', name: 'Start', relativePath: 'maps/start.json')
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'player_tiles',
              name: 'Player',
              relativePath: 'assets/player.png')
        ],
        characters: const [
          ProjectCharacterEntry(
              id: 'player', name: 'Player', tilesetId: 'player_tiles')
        ],
        pokemon: config,
        settings: const ProjectSettings(
            tileWidth: 32, tileHeight: 32, defaultPlayerCharacterId: 'player'));
    final fixture = _Fixture(root, map);
    await fixture.write('project.json', project.toJson());
    await fixture.write('maps/start.json', map.toJson());
    await fixture.write('data/pokemon/catalogs/items.json',
        const ProjectItemCatalog(schemaVersion: 1, entries: []).toJson());
    for (final entry in bundle.catalogs.entries) {
      await fixture.write(
          config.catalogFiles[entry.key]!, entry.value.toJson());
    }
    for (final species in bundle.speciesById.values) {
      await fixture.write(
          '${config.speciesDir}/${species.id}.json', species.toJson());
    }
    for (final learnset in bundle.learnsetsBySpeciesId.values) {
      await fixture.write('${config.learnsetsDir}/${learnset.speciesId}.json',
          learnset.toJson());
    }
    for (final evolution in bundle.evolutionsBySpeciesId.values) {
      await fixture.write('${config.evolutionsDir}/${evolution.speciesId}.json',
          evolution.toJson());
    }
    for (final media in bundle.mediaBySpeciesId.values) {
      await fixture.write(
          '${config.mediaDir}/${media.speciesId}.json', media.toJson());
      for (final variant in media.variants.values) {
        for (final asset in [
          variant.frontStatic,
          variant.backStatic,
          variant.frontShinyStatic,
          variant.backShinyStatic,
          variant.icon,
          variant.party,
          variant.overworld,
          variant.portrait,
          variant.cry
        ]) {
          if (asset != null && asset.isNotEmpty) {
            final file =
                File('${root.path}/${asset.replaceFirst(RegExp(r'^\./'), '')}');
            await file.parent.create(recursive: true);
            await file.writeAsBytes([1]);
          }
        }
      }
    }
    await File('${root.path}/assets/player.png').writeAsBytes([1]);
    return fixture;
  }

  Future<void> write(String path, Object json) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(json));
  }

  Future<ProjectManifest> project() async => ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>);
  Future<Map<String, String>> contents(
          {bool includeLocalState = false}) async =>
      {
        for (final file in await root
            .list(recursive: true)
            .where((entry) => entry is File)
            .cast<File>()
            .toList())
          if (includeLocalState || !file.path.contains('/.pokemap/'))
            file.path: base64Encode(await file.readAsBytes())
      };
  Future<void> dispose() => root.delete(recursive: true);
}
