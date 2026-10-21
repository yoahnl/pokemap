import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshotPath = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profilePath = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final supplementalRoots =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((path) => path.isNotEmpty)
          .toList();
  test('automatic Kanto Pokedex rewards preserve Flash gate and Everstone',
      () async {
    final elapsed = Stopwatch()..start();
    void progress(String stage) => stdout.writeln(jsonEncode({
          'stage': stage,
          'elapsedMs': elapsed.elapsedMilliseconds,
        }));
    final sourceRoot = root!;
    final sourceSnapshotPath = snapshotPath!;
    final oracleProfilePath = profilePath!;
    for (final path in [sourceRoot, sourceSnapshotPath, oracleProfilePath]) {
      expect(File(path).isAbsolute, isTrue);
    }
    final baselinePath = Platform
            .environment['AVELUNE_PROGRESSION_BLOCKERS_BASELINE'] ??
        '${File(sourceSnapshotPath).parent.path}/source-event-qualification.json';
    expect(File(baselinePath).isAbsolute, isTrue);
    final baseline = jsonDecode(await File(baselinePath).readAsString()) as Map;
    const selectedMapIds = {27, 75, 102};
    progress('readSelectedSourceMaps');
    final fixture = await readExternalOriginalSource(
        sourceRoot, sourceSnapshotPath,
        selectedMapIds: selectedMapIds, supplementalRoots: supplementalRoots);
    final source = fixture.source;
    expect(source.selectedSourceMapIds.toSet(), selectedMapIds);
    expect(baseline['sourceSnapshotHash'], source.snapshot.canonicalHash.value);
    final temporary =
        await Directory.systemTemp.createTemp('random-giver-real-map-');
    addTearDown(() => temporary.delete(recursive: true));
    final outputParent = temporary.path;
    final cancellation = ScanCancellation();
    final deadline = Timer(const Duration(minutes: 5), cancellation.cancel);
    addTearDown(() {
      deadline.cancel();
      cancellation.cancel();
    });
    final limits = sourceCatalogStudyWriteLimitsFor(selectedMapIds.length,
        includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: selectedMapIds.toList(),
            projectName: 'Kanto progression source qualification',
            parentPath: outputParent,
            folderName: 'bounded',
            dependencyDecisions: decisions,
            limits: limits,
            cancellation: cancellation);
    progress('literalSelectedMaps');
    final probe = await literal([]);
    final composed = await literal([
      for (final dependency in probe.dependencies)
        if (!selectedMapIds.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy),
    ]);
    expect(composed.draft, isNotNull,
        reason: jsonEncode(
            composed.diagnostics.map((value) => value.toJson()).toList()));
    progress('semanticSelectedMaps');
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: source,
        base: composed,
        files: fixture.files,
        limits: limits,
        cancellation: cancellation);
    expect(semantic, isNotNull);
    progress('eventSelectedMaps');
    final events = await const SourceEventStudyComposer().compose(
        source: source,
        base: semantic!,
        files: fixture.files,
        limits: limits,
        cancellation: cancellation);
    expect(events, isNotNull);
    final projection = events!.projection;
    final rows = (projection.semanticEvidence['events'] as List).cast<Map>();
    for (final location in [(75, 3), (102, 10)]) {
      final row = rows.singleWhere((row) =>
          row['locator']['mapId'] == location.$1 &&
          row['locator']['eventId'] == location.$2);
      expect(row['status'], 'adaptedStaticSemantics',
          reason: '$location: ${row['gaps']}');
      final scenes = projection.scenes
          .where((scene) =>
              scene.metadata['sourceEventIdentity'] ==
              source.eventIdentity(location.$1, location.$2).value)
          .toList();
      expect(scenes, hasLength(2));
      final conditions = scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneConditionPayload>()
          .map((node) => node.conditionSource)
          .whereType<SceneConditionSource>();
      expect(
          conditions
              .where((node) => node.pokedexMinimumCaughtCount != null)
              .single
              .pokedexMinimumCaughtCount,
          location.$1 == 75 ? 10 : 20);
      final grants = scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((node) => node.interactiveCommand)
          .whereType<SceneGiveItemInteractiveCommand>();
      expect(grants, hasLength(1));
      await _exerciseReward(projection, scenes, grants.single.itemId,
          location.$1 == 75 ? 10 : 20, location.$1 == 75);
      if (location.$1 == 75) {
        expect(
            projection.itemCatalog!.entries
                .singleWhere((item) => item.id == grants.single.itemId)
                .machine,
            const ProjectMoveMachineItemDefinition(
                moveId: 'flash',
                kind: ProjectMoveMachineKind.hm,
                consumable: false));
      }
    }
    final flash = rows.singleWhere((row) =>
        row['locator']['mapId'] == 75 && row['locator']['eventId'] == 3);
    expect((flash['nativePokedexReward'] as Map)['nativeExecutionQualified'],
        isTrue);
    final exportPath = Platform.environment['AVELUNE_POKEDEX_REWARD_EXPORT'];
    if (exportPath != null) {
      final directory = Directory('$exportPath.artifacts');
      await directory.create(recursive: true);
      final artifacts = <Map<String, Object?>>[];
      for (final artifact in events.draft.artifacts) {
        final file = File('${directory.path}/${artifact.rawSha256.value}');
        await file.writeAsBytes(artifact.bytes);
        artifacts.add({
          'handle': artifact.handle,
          'path': file.path,
          'sha256': artifact.rawSha256.value,
          'reference': artifact.reference.toJson()
        });
      }
      await File(exportPath).writeAsString(jsonEncode({
        'kind': 'boundedAutomaticPokedexRewardComposition',
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'maps': {
          for (final entry in projection.nativeMaps.entries)
            '${entry.key}': entry.value.toJson()
        },
        'events': rows,
        'scenes': projection.scenes.map((v) => v.toJson()).toList(),
        'facts': projection.facts.map((v) => v.toJson()).toList(),
        'registry': projection.registry.toJson(),
        'dialogues': projection.dialogues.map((v) => v.toJson()).toList(),
        'dialogueSources': projection.dialogueSources,
        'mutations': [
          for (var i = 0; i < events.draft.mutations.length; i++)
            events.draft.mutations[i].toJson(i)
        ],
        'artifacts': artifacts,
        'scriptsExecuted': 0,
        'aiCalls': 0,
      }));
    }
    for (final location in [(75, 3), (102, 10), (27, 31)]) {
      final row = rows.singleWhere((row) =>
          row['locator']['mapId'] == location.$1 &&
          row['locator']['eventId'] == location.$2);
      expect(row['status'], 'adaptedStaticSemantics',
          reason: '${location.$1}/${location.$2}: ${row['gaps']}');
      expect(row['gaps'], isEmpty);
    }
    if (Platform.environment['AVELUNE_VERIFY_NATIVE_WRITER'] == '1') {
      progress('catalogSelectedMaps');
      final catalogs = await SourceCatalogStudyComposer(
              nativeTrainerCatalog: NativePsdkCatalogManifest.builtin())
          .compose(
              source: source,
              base: events.draft,
              files: fixture.files,
              limits: limits,
              cancellation: cancellation);
      expect(catalogs, isNotNull);
      progress('writeSelectedMaps');
      final approval = approveNativeFixtureDraft(catalogs!.draft);
      final receipt = await const NativeProjectWriter().write(
          approval.plan, approval.context, catalogs.draft,
          limits: limits, cancellation: cancellation);
      expect(receipt.verified, isTrue);
      progress('writerVerified');
    }
    progress('complete');
  },
      timeout: const Timeout(Duration(minutes: 6)),
      skip: root == null || snapshotPath == null || profilePath == null
          ? 'Requires explicit external source, snapshot and oracle profile paths.'
          : false);
}

Future<void> _exerciseReward(SourceEventProjection projection,
    List<SceneAsset> scenes, String itemId, int minimum, bool machine) async {
  final index = PokemonSpeciesIndex([
    for (var number = 1; number <= minimum; number++)
      PokemonSpeciesIndexEntry(
          id: 'caught_$number',
          nationalDex: number,
          primaryName: 'Species$number',
          types: const ['normal'],
          relativePath: '$number.json'),
    const PokemonSpeciesIndexEntry(
        id: 'foreign',
        nationalDex: 252,
        primaryName: 'Foreign',
        types: ['normal'],
        relativePath: 'foreign.json'),
  ]);
  final offer = scenes.singleWhere((scene) => scene.graph.nodes.any((node) =>
      node.payload is SceneConditionPayload &&
      (node.payload as SceneConditionPayload)
              .conditionSource
              ?.pokedexMinimumCaughtCount !=
          null));
  final after = scenes.singleWhere((scene) => scene.id != offer.id);
  for (final scenario in [
    'below',
    'enough',
    'no',
    'cancel',
    'close',
    'bagFull',
    if (machine) 'owned'
  ]) {
    var state = GameState(
        saveId: 'dex-reward',
        progression: PlayerProgression(caughtSpeciesIds: [
          for (var i = 1;
              i <= (scenario == 'below' ? minimum - 1 : minimum);
              i++)
            'caught_$i',
          'foreign'
        ]),
        bag: Bag(entries: [
          if (scenario == 'owned') BagEntry(itemId: itemId, quantity: 1)
        ]));
    final flags = <String, bool>{};
    var attempts = 0;
    SceneRuntimeExecutionCallbacks callbacks() =>
        SceneRuntimeExecutionCallbacks(
          evaluateCondition: (intent) {
            final source = intent.conditionSource!;
            final result = switch (source.sourceKind) {
              SceneConditionSourceKind.pokedexCaughtCount =>
                evaluateScenePokedexCaughtCondition(
                    source: source, gameState: state, speciesIndex: index),
              SceneConditionSourceKind.inventoryItem =>
                evaluateSceneInventoryCondition(
                    source: source, gameState: state),
              SceneConditionSourceKind.playerFacing =>
                source.sourceId == 'south',
              _ =>
                throw StateError('Unexpected condition ${source.sourceKind}'),
            };
            return result ? 'true' : 'false';
          },
          showDialogue: (intent) {
            if (intent.expectedOutcomes.isEmpty) return 'completed';
            return switch (scenario) {
              'no' => 'choice_1',
              'cancel' => intent.choicePolicies.single.cancellation.outcomeId!,
              'close' => 'completed',
              _ => 'choice_0',
            };
          },
          startBattle: (_) => throw StateError('No battle'),
          playCinematic: (_) => throw StateError('No cinematic'),
          applyConsequence: (consequence) {
            expect(consequence.kind, SceneConsequenceKind.setFact);
            final action = consequence as SceneSetFactConsequence;
            flags[action.factId] = action.value;
            return 'completed';
          },
          executeInteractiveCommand: (intent) {
            final command = intent.interactiveCommand!;
            if (command is SceneGiveItemInteractiveCommand) {
              attempts++;
              if (scenario == 'bagFull') return 'bagFull';
              final result = const BagOperations().give(BagGiveRequest(
                  bag: state.bag,
                  itemId: command.itemId,
                  quantity: command.quantity));
              expect(result.isSuccess, isTrue);
              state = state.copyWith(bag: result.bag);
              return 'received';
            }
            expect(
                command is SceneActorRouteInteractiveCommand ||
                    command is SceneWaitForActorRoutesInteractiveCommand,
                isTrue);
            return 'completed';
          },
        );
    await SceneRuntimeExecutor(callbacks: callbacks())
        .execute(buildSceneRuntimePlan(offer).plan!);
    final rewarded = scenario == 'enough' || scenario == 'owned';
    expect(attempts, scenario == 'enough' || scenario == 'bagFull' ? 1 : 0,
        reason: scenario);
    expect(
        state.bag.entries
            .where((entry) => entry.itemId == itemId)
            .fold<int>(0, (sum, entry) => sum + entry.quantity),
        rewarded ? 1 : 0,
        reason: scenario);
    expect(flags.values.where((value) => value),
        hasLength(rewarded ? (machine ? 2 : 1) : 0),
        reason: scenario);
    if (rewarded) {
      state = GameState.fromJson(state
          .copyWith(
              narrativeFactRuntimeState:
                  NarrativeFactRuntimeState(overridesByFactId: flags))
          .toJson());
      expect(state.narrativeFactRuntimeState.overridesByFactId, flags);
      await SceneRuntimeExecutor(callbacks: callbacks()).execute(
          buildSceneRuntimePlan(SceneAsset.fromJson(after.toJson())).plan!);
      expect(attempts, scenario == 'owned' ? 0 : 1);
    }
  }
}
