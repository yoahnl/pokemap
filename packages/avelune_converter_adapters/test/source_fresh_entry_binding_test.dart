import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

final class _Changed implements SourceFilePort {
  _Changed(this.original, this.path);
  final ExternalOriginalFiles original;
  final String path;
  @override
  Future<List<int>> read(ConverterId id) async {
    final bytes = List<int>.from(await original.read(id));
    if (original.snapshot.entries
            .singleWhere((e) => e.fileId == id)
            .relativePath ==
        path) {
      bytes[0] ^= 1;
    }
    return bytes;
  }
}

SourceEventProjection _copy(
  SourceEventProjection p, {
  Map<int, MapData>? maps,
  List<NarrativeFactDefinition>? facts,
  NarrativeEventRegistry? registry,
  List<SceneAsset>? scenes,
  Map<String, String>? dialogueSources,
  Map<String, Object?>? evidence,
}) =>
    SourceEventProjection(
        nativeMaps: maps ?? p.nativeMaps,
        registry: registry ?? p.registry,
        facts: facts ?? p.facts,
        scenes: scenes ?? p.scenes,
        cinematics: p.cinematics,
        dialogues: p.dialogues,
        dialogueSources: dialogueSources ?? p.dialogueSources,
        worldRules: p.worldRules,
        itemCatalog: p.itemCatalog,
        artifacts: p.artifacts,
        mutations: p.mutations,
        semanticEvidence: evidence ?? p.semanticEvidence,
        staticSemanticsQualified: p.staticSemanticsQualified,
        allEnabledOriginalEventsHaveExecutionContext:
            p.allEnabledOriginalEventsHaveExecutionContext,
        retentionPolicy: p.retentionPolicy);

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  group('attested fresh native game binding', () {
    late ({
      NormalizedSourceProject source,
      ExternalOriginalFiles files
    }) fixture;
    late SourceEventProjection projection;
    const resolver = SourceFreshEntryBindingResolver();
    setUpAll(() async {
      fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {1, 2, 7},
          supplementalRoots:
              (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                      '')
                  .split('|')
                  .where((s) => s.isNotEmpty)
                  .toList());
      projection = await _composeProjection(fixture.source, fixture.files);
    });
    test(
        'fresh scene and spawn identities do not depend on the selected map batch',
        () async {
      final larger = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.source.snapshot,
          files: fixture.files,
          selectedMapIds: {1, 2, 6, 7},
          includeEventSystem: true,
          interpretationProfile: fixture.source.interpretationProfile);
      expect(larger.canonicalHash, isNot(fixture.source.canonicalHash));
      expect(sourceFreshEntryProgram(larger)!.programHash,
          sourceFreshEntryProgram(fixture.source)!.programHash);
      final otherProjection = await _composeProjection(larger, fixture.files);
      final first = (await resolver.read(
          source: fixture.source,
          projection: projection,
          files: fixture.files))!;
      final second = (await resolver.read(
          source: larger, projection: otherProjection, files: fixture.files))!;
      expect(second.config.startSpawnId, first.config.startSpawnId);
      expect(second.config.preSessionSceneId, first.config.preSessionSceneId);
      expect(second.config.playerAvatarCharacterIds,
          first.config.playerAvatarCharacterIds);
      expect(second.evidence['normalizationHash'], larger.canonicalHash.value);
      expect(second.evidence['normalizationHash'],
          isNot(first.evidence['normalizationHash']));
    });
    test('attests exact source stationary introduction and recovery cells', () {
      final oracle = SourceSemanticResolver.forProject(fixture.source);
      final observed = {
        for (final point in [(1, 0, 0), (2, 0, 1)])
          '${point.$1}': {
            'cell': oracle.cellAt(point.$1, point.$2, point.$3).toJson(),
            'profileHash': oracle.profile.canonicalHash.value,
            'directions': oracle
                .resolveCell(oracle.cellAt(point.$1, point.$2, point.$3))
                .directions
                .map((direction) => direction.toJson())
                .toList(),
          },
      };
      stdout.writeln(jsonEncode(
          {'kind': 'sourceFreshStationaryCells', 'cells': observed}));
      for (final point in [(1, 0, 0), (2, 0, 1)]) {
        final cell = oracle.cellAt(point.$1, point.$2, point.$3);
        expect(cell.stack.map((tile) => tile.tileId), [0, 0, 387]);
        expect(oracle.resolveCell(cell).blockedMask, 15);
      }
    });
    test('refuses a fresh home alias when its recovery event is not admitted',
        () async {
      final events = (projection.semanticEvidence['events'] as List)
          .cast<Map<String, Object?>>();
      final incomplete = _copy(projection, evidence: {
        ...projection.semanticEvidence,
        'events': [
          for (final event in events)
            if (event['nativeHomeRecovery'] == null) event
        ]
      });
      expect(
          await resolver.read(
              source: fixture.source,
              projection: incomplete,
              files: fixture.files),
          isNull);
    });
    test('refuses missing or disabled home recovery dependencies', () async {
      final sourceIdentity = fixture.source.eventIdentity(7, 9).value;
      final recovery = projection.scenes.singleWhere((scene) =>
          scene.metadata['sourceEventIdentity'] == sourceIdentity &&
          scene.metadata['sourcePageIndex'] == '2');
      final record = projection.registry.records.singleWhere(
          (record) => record.definitionOrNull?.sceneId == recovery.id);
      NarrativeEventRegistry registryWith(NarrativeEventRecord replacement) =>
          NarrativeEventRegistry(
              schemaVersion: projection.registry.schemaVersion,
              mode: projection.registry.mode,
              records: [
                for (final current in projection.registry.records)
                  current.id == record.id ? replacement : current
              ],
              legacyClaims: projection.registry.legacyClaims);
      final missingDialogue = recovery.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneYarnDialoguePayload>()
          .first
          .dialogueId;
      final wrongGuard = Map<String, dynamic>.from(record.toJson());
      final wrongCondition = NarrativeEventCondition.fact(
          sourceEventFactBindingId(
              'source:${fixture.source.snapshot.logicalProjectNamespace.value}:switch:1'),
          false);
      wrongGuard['definition'] = {
        ...record.definitionOrNull!.toJson(),
        'conditions': [wrongCondition.toJson()],
        'conditionExpression':
            NarrativeEventConditionExpression.leaf(wrongCondition).toJson()
      };
      final malformed = <String, SourceEventProjection>{
        'inactive event system': _copy(projection,
            registry: NarrativeEventRegistry(
                schemaVersion: projection.registry.schemaVersion,
                mode: EventSystemMode.legacyOnly,
                records: projection.registry.records,
                legacyClaims: projection.registry.legacyClaims)),
        'missing recovery scene': _copy(projection, scenes: [
          for (final scene in projection.scenes)
            if (scene.id != recovery.id) scene
        ]),
        'disabled recovery record': _copy(projection,
            registry: registryWith(NarrativeEventRecord.fromJson(
                {...record.toJson(), 'enabled': false}))),
        'wrong recovery marker guard': _copy(projection,
            registry: registryWith(NarrativeEventRecord.fromJson(wrongGuard))),
        'one-shot recovery record': _copy(projection,
            registry: registryWith(NarrativeEventRecord.fromJson({
              ...record.toJson(),
              'definition': {
                ...record.definitionOrNull!.toJson(),
                'reusePolicy': 'oneShot'
              }
            }))),
        'missing recovery dialogue': _copy(projection, dialogueSources: {
          for (final entry in projection.dialogueSources.entries)
            if (entry.key != missingDialogue) entry.key: entry.value
        }),
        'missing mother actor': _copy(projection, maps: {
          ...projection.nativeMaps,
          7: projection.nativeMaps[7]!.copyWith(entities: [
            for (final entity in projection.nativeMaps[7]!.entities)
              if (entity.properties['sourceEventIdentity'] != sourceIdentity)
                entity
          ])
        }),
        'orphaned recovery effects': _copy(projection, scenes: [
          for (final scene in projection.scenes)
            if (scene.id == recovery.id)
              SceneAsset.fromJson({
                ...scene.toJson(),
                'graph': {
                  ...scene.graph.toJson(),
                  'edges': [
                    for (final edge in scene.graph.edges)
                      if (edge.fromNodeId != scene.graph.startNodeId)
                        edge.toJson()
                  ]
                }
              })
            else
              scene
        ]),
      };
      for (final entry in malformed.entries) {
        expect(
            await resolver.read(
                source: fixture.source,
                projection: entry.value,
                files: fixture.files),
            isNull,
            reason: entry.key);
      }
      final valid = await resolver.read(
          source: fixture.source, projection: projection, files: fixture.files);
      expect(valid, isNotNull);
      expect(
          ((valid!.evidence['defeatRecovery'] as Map)['homeRecoveryAdmission']
              as Map)['allSourcePagesAdmitted'],
          isTrue);
    });
    test(
        'builds canonical identity scene, empty game and attested home recovery alias before intro',
        () async {
      final before = canonicalHashOf(jsonDecode(jsonEncode({
        for (final m in projection.nativeMaps.entries)
          '${m.key}': m.value.toJson()
      })));
      final binding = (await resolver.read(
          source: fixture.source,
          projection: projection,
          files: fixture.files))!;
      expect(binding.config.enabled, isTrue);
      expect(binding.config.startMapId, projection.nativeMaps[1]!.id);
      expect(binding.config.startingMoney, 3000);
      expect(binding.config.initialParty, isEmpty);
      expect(binding.config.initialBag, isEmpty);
      expect(binding.config.starterOptions, isEmpty);
      expect(
          binding.config.initialRecoveryPoint,
          ProjectNewGameRecoveryPoint(
              mapId: projection.nativeMaps[7]!.id,
              position: const GridPos(x: 9, y: 7),
              facing: EntityFacing.north));
      expect(binding.config.playerAvatarCharacterIds,
          binding.imports.map((i) => i.character.id));
      expect(binding.imports.map((i) => i.selectedOutfit), [1, 1]);
      expect(binding.artifacts, hasLength(6));
      expect(binding.config.preSessionSceneId, binding.scene.id);
      expect(binding.scene.executionProfile, SceneExecutionProfile.preSession);
      final interactions = binding.scene.graph.nodes
          .map((n) => n.payload)
          .whereType<SceneActionPayload>()
          .map((a) => a.preSessionInteraction)
          .whereType<ScenePreSessionInteractionSpec>();
      expect(interactions.map((i) => i.resultBinding?.field), [
        ScenePreSessionDraftField.playerName,
        ScenePreSessionDraftField.avatarCharacterId
      ]);
      expect(binding.mutations.last.actionId, 'campaign.new_game.update');
      expect(binding.mutations.map((m) => m.actionId), [
        for (final _ in binding.facts) 'fact.create',
        'entity.create',
        'scene.upsert',
        'campaign.defeat_recovery.update',
        'campaign.new_game.update'
      ]);
      expect(
          binding.importMutations
              .where((m) => m.actionId == 'characterStudio.character.create'),
          hasLength(2));
      expect(binding.importMutations.map((m) => m.operationId).toSet(),
          hasLength(binding.importMutations.length));
      expect(binding.nativeMaps[2], same(projection.nativeMaps[2]));
      expect(binding.nativeMaps[7], same(projection.nativeMaps[7]));
      expect(
          binding.startMap.entities
              .singleWhere((e) => e.id == binding.config.startSpawnId)
              .pos,
          const GridPos(x: 0, y: 0));
      final project = ProjectManifest(
          name: 'Fresh binding test',
          maps: [
            for (final map in binding.nativeMaps.values)
              ProjectMapEntry(
                  id: map.id,
                  name: map.name,
                  relativePath: 'maps/${map.id}.json')
          ],
          tilesets: [
            for (final avatar in binding.imports)
              for (final sheet in avatar.sheets)
                ProjectTilesetEntry(
                    id: sheet.tilesetId,
                    name: sheet.charsetName,
                    relativePath: 'assets/studio/${sheet.tilesetId}.png',
                    source: ProjectRegularAtlasTilesetSource(
                        assetId: sheet.assetId,
                        pixelWidth: 256,
                        pixelHeight: 256,
                        tileWidth: 32,
                        tileHeight: 32))
          ],
          characters: binding.imports.map((i) => i.character).toList(),
          facts: [...projection.facts, ...binding.facts],
          scenes: [binding.scene],
          newGame: binding.config,
          defeatRecovery: binding.defeatRecovery,
          settings: const ProjectSettings(tileWidth: 32, tileHeight: 32));
      final draft = NewGameDraft.start(
              draftId: 'fresh-native-test',
              projectRevision: 'fresh-v1',
              slotId: 'slot1',
              config: project.newGame)
          .apply(NewGameDraftCommand.selectAvatar(
              expectedRevision: 0,
              avatarCharacterId: binding.imports.first.character.id))
          .draft;
      final committed = commitNewGameDraft(
          journal: NewGameSeedCommitJournal.empty(),
          operationId: 'fresh-native-test',
          currentProjectRevision: 'fresh-v1',
          expectedDraftRevision: draft.revision,
          draft: draft);
      final seed = committed.receipt!.seed!;
      final game = createNewGameStateFromSeed(
          project: project,
          startMap: binding.startMap,
          initialRecoveryMap: binding.nativeMaps[7],
          seed: seed,
          currentProjectRevision: 'fresh-v1',
          tileWidthPx: 32,
          tileHeightPx: 32);
      expect(game.party.members, isEmpty);
      expect(game.pokemonStorage, const PokemonStorage());
      expect(game.bag.entries, isEmpty);
      expect(game.progression, const PlayerProgression());
      expect(game.trainerProfile.money, 3000);
      expect(game.playerPosition, const GridPos(x: 0, y: 0));
      expect(
          PlayerRecoveryPoint.tryRead(game),
          PlayerRecoveryPoint(
              mapId: projection.nativeMaps[7]!.id,
              position: const GridPos(x: 9, y: 7),
              facing: EntityFacing.north));
      expect(
          game.narrativeFactRuntimeState
              .valueFor(binding.defeatRecovery.recoveredFactId),
          NarrativeValue.boolean(false));
      expect(
          (binding.evidence['defeatRecovery']
              as Map)['sourceTechnicalMapExecuted'],
          isFalse);
      final freshId = binding.evidence['nativeEntryFactId'] as String;
      final regionId = binding.evidence['regionFactId'] as String;
      expect(game.narrativeFactRuntimeState.valueFor(freshId),
          NarrativeValue.boolean(true));
      expect(game.narrativeFactRuntimeState.valueFor(regionId),
          NarrativeValue.integer(1));
      final restored = GameState.fromJson(
          jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>);
      expect(PlayerRecoveryPoint.tryRead(restored),
          PlayerRecoveryPoint.tryRead(game));
      expect(
          restored.narrativeFactRuntimeState, game.narrativeFactRuntimeState);
      expect((binding.evidence['initialPcItemStorage'] as Map)['diagnostic'],
          'sourceInitialPcItemStorageUnsupported');
      expect((binding.evidence['initialPcItemStorage'] as Map)['sourceSymbols'],
          ['POTION']);
      expect((binding.evidence['initialPcItemStorage'] as Map)['addedToBag'],
          isFalse);
      expect(
          canonicalHashOf(jsonDecode(jsonEncode({
            for (final m in projection.nativeMaps.entries)
              '${m.key}': m.value.toJson()
          }))),
          before);
      final output = Platform.environment['AVELUNE_FRESH_BINDING_RECEIPT'];
      if (output != null) {
        await File(output).writeAsString(
            jsonEncode({
              'evidence': binding.evidence,
              'config': binding.config.toJson(),
              'scene': binding.scene.toJson(),
              'gameState': game.toJson(),
              'sourceScriptsExecuted': 0,
              'aiCalls': 0,
            }),
            flush: true);
      }
    });
    test('retains blocked native source cells for stationary autorun entry',
        () async {
      final maps = {...projection.nativeMaps};
      for (final id in [1, 2]) {
        final map = maps[id]!;
        maps[id] = map.copyWith(layers: [
          CollisionLayer(
              id: 'collision',
              name: 'Collision',
              collisions: List.filled(map.size.width * map.size.height, true))
        ]);
      }
      final binding = (await resolver.read(
          source: fixture.source,
          projection: _copy(projection, maps: maps),
          files: fixture.files))!;
      expect(binding.startMap.layers, maps[1]!.layers);
      expect(binding.nativeMaps[2], same(maps[2]));
      for (final cell
          in binding.evidence['stationaryEntryPlacements'] as List) {
        expect((cell as Map)['nativeCollisionAtCell'], [true]);
        expect(cell['collisionModified'], isFalse);
        expect(cell['movementRequiredBeforeScene'], isFalse);
      }
    });
    test('refuses a colliding region Fact of another type', () async {
      final regionId = sourceEventIntegerVariableBindingId(
          'source:${fixture.source.snapshot.logicalProjectNamespace.value}:variable:50');
      await expectLater(
          resolver.read(
              source: fixture.source,
              projection: _copy(projection, facts: [
                ...projection.facts,
                NarrativeFactDefinition(id: regionId, label: 'Foreign boolean')
              ]),
              files: fixture.files),
          throwsA(isA<ContractError>().having((e) => e.code, 'code',
              'source.fresh_entry.region_fact_invalid')));
    });
    test('refuses blocked home alias and a colliding recovery Fact', () async {
      final home = projection.nativeMaps[7]!;
      expect(
          await resolver.read(
              source: fixture.source,
              projection: _copy(projection, maps: {
                ...projection.nativeMaps,
                7: home.copyWith(layers: [
                  CollisionLayer(
                      id: 'blocked',
                      name: 'Collision',
                      collisions:
                          List.filled(home.size.width * home.size.height, true))
                ])
              }),
              files: fixture.files),
          isNull);
      final recoveredId = sourceEventFactBindingId(
          'source:${fixture.source.snapshot.logicalProjectNamespace.value}:switch:1');
      await expectLater(
          resolver.read(
              source: fixture.source,
              projection: _copy(projection, facts: [
                ...projection.facts,
                NarrativeFactDefinition(
                    id: recoveredId,
                    label: 'Foreign integer',
                    initialValue: NarrativeValue.integer(0))
              ]),
              files: fixture.files),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              'source.fresh_entry.recovery_fact_invalid')));
    });
    test('observes cancellation before any source binding', () async {
      final cancellation = ScanCancellation()..cancel();
      await expectLater(
          resolver.read(
              source: fixture.source,
              projection: projection,
              files: fixture.files,
              cancellation: cancellation),
          throwsA(isA<ContractError>()
              .having((e) => e.code, 'code', 'source.cancelled')));
    });
    test('rejects foreign projection identity before reading source files',
        () async {
      final bad = _copy(projection, evidence: {
        ...projection.semanticEvidence,
        'normalizationHash': 'foreign'
      });
      expect(
          await resolver.read(
              source: fixture.source, projection: bad, files: fixture.files),
          isNull);
    });
    test('rejects missing recovery map and blocking entity on stationary spawn',
        () async {
      expect(
          await resolver.read(
              source: fixture.source,
              projection: _copy(projection, maps: {
                for (final entry in projection.nativeMaps.entries)
                  if (entry.key != 2) entry.key: entry.value
              }),
              files: fixture.files),
          isNull);
      final start = projection.nativeMaps[1]!;
      expect(
          await resolver.read(
              source: fixture.source,
              projection: _copy(projection, maps: {
                ...projection.nativeMaps,
                1: start.copyWith(entities: [
                  ...start.entities,
                  const MapEntity(
                      id: 'blocker',
                      name: 'Blocker',
                      kind: MapEntityKind.custom,
                      pos: GridPos(x: 0, y: 0),
                      size: GridSize(width: 1, height: 1),
                      blocksMovement: true)
                ])
              }),
              files: fixture.files),
          isNull);
    });
    test('does not enable a fresh Fact whose project default was altered',
        () async {
      final fact = projection.facts
          .singleWhere((f) => f.description.contains(':nativeFreshEntry:'));
      expect(
          await resolver.read(
              source: fixture.source,
              projection: _copy(projection, facts: [
                for (final f in projection.facts)
                  if (f.id == fact.id)
                    NarrativeFactDefinition(
                        id: f.id,
                        label: f.label,
                        description: f.description,
                        initialValue: NarrativeValue.boolean(true))
                  else
                    f
              ]),
              files: fixture.files),
          isNull);
    });
    test('reuses an existing exact region Fact without duplicate creation',
        () async {
      final baseline = (await resolver.read(
          source: fixture.source,
          projection: projection,
          files: fixture.files))!;
      final bound = await resolver.read(
          source: fixture.source,
          projection: _copy(projection,
              facts: [...projection.facts, ...baseline.facts]),
          files: fixture.files);
      expect(bound!.facts, isEmpty);
      expect(
          bound.mutations.where((m) => m.actionId == 'fact.create'), isEmpty);
      expect(bound.config, baseline.config);
    });
    for (final file in [
      'PBS/metadata.txt',
      'Data/Scripts.rxdata',
      'Graphics/Characters/player_F_1.png'
    ]) {
      test('fails closed when attested $file bytes change', () async {
        await expectLater(
            resolver.read(
                source: fixture.source,
                projection: projection,
                files: _Changed(fixture.files, file)),
            throwsA(isA<ContractError>()
                .having((e) => e.code, 'code', contains('source_changed'))));
      });
    }
    test('does not bypass artifact or action quotas', () async {
      await expectLater(
          resolver.read(
              source: fixture.source,
              projection: projection,
              files: fixture.files,
              limits: const NativeWriteLimits(maxArtifacts: 1)),
          throwsA(isA<NativeWriteException>()));
      await expectLater(
          resolver.read(
              source: fixture.source,
              projection: projection,
              files: fixture.files,
              limits: const NativeWriteLimits(maxMutations: 1)),
          throwsA(isA<NativeWriteException>()));
    });
  },
      skip: enabled
          ? false
          : 'Requires immutable original Kanto source and profile.');
}

Future<SourceEventProjection> _composeProjection(
    NormalizedSourceProject source, ExternalOriginalFiles files) async {
  final temporary = await Directory.systemTemp.createTemp('fresh-binding-');
  try {
    final selected = source.maps.map((entry) => entry.map.sourceMapId).toSet();
    final limits = sourceCatalogStudyWriteLimitsFor(selected.length);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: files,
            selectedSourceMapIds: selected.toList(),
            projectName: 'Fresh binding',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!selected.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: base, files: files, limits: limits))!;
    return (await const SourceEventStudyComposer().compose(
            source: source, base: semantic, files: files, limits: limits))!
        .projection;
  } finally {
    await temporary.delete(recursive: true);
  }
}
