import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';
import 'support/native_writer_fixture.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshotPath = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profilePath = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final supplementalRoots =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((path) => path.isNotEmpty)
          .toList();
  test(
      'automatic Kanto starter choices compose under closed source qualification',
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
    const selectedMapIds = {9};
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
    final deadline = Timer(const Duration(minutes: 7), cancellation.cancel);
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
    for (final expected in [
      (4, 'bulbasaur', 1),
      (5, 'squirtle', 3),
      (6, 'charmander', 2)
    ]) {
      final row =
          rows.singleWhere((row) => row['locator']['eventId'] == expected.$1);
      expect(row['status'], 'adaptedStaticSemantics',
          reason: '${expected.$1}: ${row['gaps']}');
      expect(row['gaps'], isEmpty);
      final metadata = row['nativeStarterChoice'] as Map;
      expect(metadata['nativeSpeciesId'], expected.$2);
      expect(metadata['program']['level'], 5);
      expect(metadata['program']['choiceVariableId'], 29);
      expect(metadata['program']['choiceValue'], expected.$3);
      final scenes = projection.scenes
          .where((scene) =>
              scene.metadata['sourceEventIdentity'] ==
              source.eventIdentity(9, expected.$1).value)
          .toList();
      expect(scenes, hasLength(4));
      await _exerciseStarterGraph(
          projection, scenes, expected.$2, expected.$3, source, expected.$1);
    }
    final publicationProject = ProjectManifest(
        name: 'Starter publication',
        tilesets: const [],
        maps: [
          for (final map in projection.nativeMaps.values)
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        facts: projection.facts,
        scenes: projection.scenes,
        eventRegistry: projection.registry,
        characters: [
          for (final mutation
              in expandNativeMutationBatches(events.draft, limits))
            if (mutation.actionId == 'characterStudio.character.create')
              ProjectCharacterEntry(
                  id: mutation.targetEntityIds.first.value,
                  name: mutation.parameters['name'] as String,
                  tilesetId: mutation.parameters['tilesetId'] as String,
                  frameWidth: mutation.parameters['frameWidth'] as int,
                  frameHeight: mutation.parameters['frameHeight'] as int)
        ]);
    for (final scene in projection.scenes.where((scene) => ['4', '5', '6'].any(
        (eventId) =>
            scene.metadata['sourceEventIdentity'] ==
            source.eventIdentity(9, int.parse(eventId)).value))) {
      expect(
          diagnoseSceneAgainstProject(scene, publicationProject, mapsById: {
            for (final map in projection.nativeMaps.values) map.id: map
          }).diagnostics.where((diagnostic) =>
              diagnostic.code == SceneDiagnosticCode.commandInvalidActorTarget),
          isEmpty);
    }
    progress('starterGraphsVerified');
    final export = Platform.environment['AVELUNE_STARTER_EXPORT'];
    if (export != null) {
      final directory = Directory('$export.artifacts');
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
      await File(export).writeAsString(jsonEncode({
        'kind': 'boundedAutomaticStarterChoiceComposition',
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'maps': {
          for (final entry in projection.nativeMaps.entries)
            '${entry.key}': entry.value.toJson()
        },
        'events': rows,
        'scenes': projection.scenes.map((scene) => scene.toJson()).toList(),
        'facts': projection.facts.map((fact) => fact.toJson()).toList(),
        'registry': projection.registry.toJson(),
        'dialogues':
            projection.dialogues.map((dialogue) => dialogue.toJson()).toList(),
        'dialogueSources': projection.dialogueSources,
        'mutations': [
          for (var index = 0; index < events.draft.mutations.length; index++)
            events.draft.mutations[index].toJson(index)
        ],
        'artifacts': artifacts,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      }));
    }
    if (Platform.environment['AVELUNE_VERIFY_NATIVE_WRITER'] == '1') {
      progress('catalogSelectedMaps');
      expect(events.pokemonGiftCatalog, isNotNull);
      final catalogs = await SourceCatalogStudyComposer(
              nativeTrainerCatalog: events.pokemonGiftCatalog)
          .compose(
              source: source,
              base: events.draft,
              files: fixture.files,
              limits: limits,
              cancellation: cancellation);
      expect(catalogs, isNotNull);
      progress('writeSelectedMaps');
      final approval = approveNativeFixtureDraft(catalogs!.draft);
      NativePreparationStage? lastPreparationStage;
      final receipt = await NativeProjectWriter(
              checkpoint: (stage, _, __) => progress('writer_${stage.name}'),
              preparationCheckpoint: (stage, _) {
                if (stage != lastPreparationStage) {
                  lastPreparationStage = stage;
                  progress('prepare_${stage.name}');
                }
              })
          .write(approval.plan, approval.context, catalogs.draft,
              limits: limits, cancellation: cancellation);
      expect(receipt.verified, isTrue);
      final qaOutput = Platform.environment['AVELUNE_STARTER_QA_OUTPUT'];
      if (qaOutput != null) {
        expect(File(qaOutput).isAbsolute, isTrue);
        expect(await Directory(qaOutput).exists(), isFalse);
        await Directory(receipt.projectPath).rename(qaOutput);
      }
      progress('writerVerified');
    }
    progress('complete');
  },
      skip: root == null || snapshotPath == null || profilePath == null
          ? 'Requires original source.'
          : false,
      timeout: const Timeout(Duration(minutes: 8)));
}

Future<void> _exerciseStarterGraph(
    SourceEventProjection projection,
    List<SceneAsset> scenes,
    String species,
    int choiceValue,
    NormalizedSourceProject source,
    int eventId) async {
  final namespace = source.snapshot.logicalProjectNamespace.value;
  final offer =
      scenes.singleWhere((scene) => scene.metadata['sourcePageIndex'] == '1');
  final gifts = offer.graph.nodes
      .map((node) => node.payload)
      .whereType<SceneActionPayload>()
      .map((node) => node.interactiveCommand)
      .whereType<SceneReceivePokemonFromCatalogInteractiveCommand>()
      .toList();
  expect(gifts, hasLength(1));
  expect(gifts.single.speciesId, species);
  expect(gifts.single.level, 5);
  expect(offer.graph.nodes.where((node) => node.payload is SceneBattlePayload),
      isEmpty);
  for (final scenario in ['yes', 'no', 'cancel', 'close', 'noCapacity']) {
    var state = const GameState(saveId: 'starter-graph');
    final calls = <String>[];
    final facts = <String, Object?>{};
    final poses = <SceneSetNpcPoseConsequence>[];
    var attempts = 0;
    final callbacks = SceneRuntimeExecutionCallbacks(
        evaluateCondition: (_) =>
            throw StateError('Offer has no condition branch.'),
        showDialogue: (intent) {
          if (intent.expectedOutcomes.isEmpty) return 'completed';
          calls.add('choice');
          return switch (scenario) {
            'no' => 'choice_1',
            'cancel' => intent.choicePolicies.single.cancellation.outcomeId!,
            'close' => 'completed',
            _ => 'choice_0',
          };
        },
        startBattle: (_) =>
            throw StateError('No battle is injected by starter choice.'),
        playCinematic: (_) =>
            throw StateError('No source picture cinematic is fabricated.'),
        applyConsequence: (consequence) {
          switch (consequence) {
            case SceneMarkPokemonSeenConsequence():
              state = markSpeciesSeenInGameState(state, consequence.speciesId);
              calls.add('seen');
            case SceneSetFactConsequence():
              facts[consequence.factId] = consequence.narrativeValue.toJson();
            case SceneSetNpcPoseConsequence():
              poses.add(consequence);
            default:
              throw StateError('Unexpected starter effect ${consequence.kind}');
          }
          return 'completed';
        },
        executeInteractiveCommand: (intent) {
          final command = intent.interactiveCommand!;
          if (command is SceneReceivePokemonFromCatalogInteractiveCommand) {
            attempts++;
            return scenario == 'noCapacity' ? 'noCapacity' : 'party';
          }
          expect(
              command is SceneActorRouteInteractiveCommand ||
                  command is SceneActorVisibilityInteractiveCommand,
              isTrue);
          return 'completed';
        });
    await SceneRuntimeExecutor(callbacks: callbacks)
        .execute(buildSceneRuntimePlan(offer).plan!);
    expect(calls.indexOf('seen'), lessThan(calls.indexOf('choice')));
    expect(state.progression.seenSpeciesIds, [species]);
    expect(state.progression.caughtSpeciesIds, isEmpty);
    expect(attempts, scenario == 'yes' || scenario == 'noCapacity' ? 1 : 0);
    if (scenario == 'yes') {
      final foreign = switch (eventId) {
        4 => [6, 14, 17, 18],
        5 => [4, 14, 18, 19],
        6 => [5, 14, 17, 19],
        _ => throw StateError('Unknown source fixture')
      };
      expect(facts, {
        for (final target in [eventId, ...foreign])
          sourceEventFactBindingId(
              'source:$namespace:map:9:event:$target:self:A'): true,
        sourceEventFactBindingId('source:$namespace:switch:75'): false,
        sourceEventIntegerVariableBindingId('source:$namespace:variable:29'):
            choiceValue,
      });
      final expectedTargets = foreign.skip(1).map((target) => projection
          .nativeMaps[9]!.entities
          .singleWhere((entity) =>
              entity.properties['sourceEventIdentity'] ==
              source.eventIdentity(9, target).value)
          .id);
      expect(poses.map((pose) => pose.entityId), expectedTargets);
      expect(poses, hasLength(3));
      expect(
          poses.map((pose) => '${pose.x},${pose.y}'),
          species == 'bulbasaur'
              ? ['14,4', '14,4', '14,4']
              : ['5,4', '14,4', '14,4']);
      expect(poses.every((pose) => pose.facing == null), isTrue);
    } else {
      expect(facts, isEmpty, reason: scenario);
      expect(poses, isEmpty, reason: scenario);
    }
  }
}
