import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_fresh_entry_binding.dart';
import 'package:avelune_converter_adapters/src/source_intro_binding.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
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
  Map<String, Object?>? evidence,
}) =>
    SourceEventProjection(
        nativeMaps: maps ?? p.nativeMaps,
        registry: p.registry,
        facts: facts ?? p.facts,
        scenes: p.scenes,
        cinematics: p.cinematics,
        dialogues: p.dialogues,
        dialogueSources: p.dialogueSources,
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
      final source = fixture.source;
      final texts = await const SourceIntroBindingResolver().readTextVariables(
          source: source, files: fixture.files, referencedVariableIds: {28});
      final maps = {
        for (final map in source.maps)
          map.map.sourceMapId: MapData(
              id: 'native_${map.map.sourceMapId}',
              name: map.map.name,
              size: GridSize(width: map.map.width, height: map.map.height),
              layers: [
                CollisionLayer(
                    id: 'collision',
                    name: 'Collision',
                    collisions:
                        List.filled(map.map.width * map.map.height, false))
              ])
      };
      projection = const SourceEventProjector().project(
          source: source,
          analysis: SourceEventAnalyzer.forProject(source,
                  profile: SourceEventProfile.forProject(source))
              .analyze(),
          nativeMaps: maps,
          textVariablePrograms: texts);
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
      final texts = await const SourceIntroBindingResolver().readTextVariables(
          source: larger, files: fixture.files, referencedVariableIds: {28});
      final maps = {
        ...projection.nativeMaps,
        6: MapData(
            id: 'native_6',
            name: 'Pallet Town',
            size: GridSize(
                width: larger.maps
                    .singleWhere((m) => m.map.sourceMapId == 6)
                    .map
                    .width,
                height: larger.maps
                    .singleWhere((m) => m.map.sourceMapId == 6)
                    .map
                    .height))
      };
      final otherProjection = const SourceEventProjector().project(
          source: larger,
          nativeMaps: maps,
          textVariablePrograms: texts,
          analysis: SourceEventAnalyzer.forProject(larger,
                  profile: SourceEventProfile.forProject(larger))
              .analyze());
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
    test(
        'builds canonical identity scene, empty game and original recovery before intro',
        () async {
      final before = canonicalHashOf({
        for (final m in projection.nativeMaps.entries)
          '${m.key}': m.value.toJson()
      });
      final binding = (await resolver.read(
          source: fixture.source,
          projection: projection,
          files: fixture.files))!;
      expect(binding.config.enabled, isTrue);
      expect(binding.config.startMapId, 'native_1');
      expect(binding.config.startingMoney, 3000);
      expect(binding.config.initialParty, isEmpty);
      expect(binding.config.initialBag, isEmpty);
      expect(binding.config.starterOptions, isEmpty);
      expect(
          binding.config.initialRecoveryPoint,
          const ProjectNewGameRecoveryPoint(
              mapId: 'native_2',
              position: GridPos(x: 0, y: 1),
              facing: EntityFacing.south));
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
        'fact.create',
        'entity.create',
        'scene.upsert',
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
          initialRecoveryMap: binding.nativeMaps[2],
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
          const PlayerRecoveryPoint(
              mapId: 'native_2',
              position: GridPos(x: 0, y: 1),
              facing: EntityFacing.south));
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
          canonicalHashOf({
            for (final m in projection.nativeMaps.entries)
              '${m.key}': m.value.toJson()
          }),
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
