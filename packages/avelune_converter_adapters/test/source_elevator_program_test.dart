import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_evidence.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final supplemental = Platform
          .environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS']
          ?.split('|') ??
      const <String>[];
  const limits = NativeWriteLimits(
      maxArtifacts: 256,
      maxMutations: 4096,
      maxTotalArtifactBytes: 268435456,
      maxTotalImagePixels: 33554432,
      jsonLimits:
          ContractLimits(maxNodes: 4000000, maxTextCodeUnits: 16777216));
  final selection = {
    38,
    40,
    173,
    174,
    176,
    177,
    ...List.generate(12, (i) => 213 + i)
  };

  group('complete native elevator family', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    late SourceEventStudyComposition events;
    late Map<ConverterId, SourceElevatorProgram> programs;
    late Directory temporary;
    late NativeProjectDraft base;
    late Map<int, MapData> maps;
    late Map<ConverterId, SourceEventExecutionContext> contexts;
    late Map<String, SourceEventSoundBinding> sounds;
    late Map<String, SourceEventCharacterBinding> characters;
    late MapInstanceRetentionPolicy retention;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: selection, supplementalRoots: supplemental);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      programs = sourceElevatorPrograms(source: source, analysis: analysis);
      temporary = await Directory.systemTemp.createTemp('elevator-complete-');
      analysis = SourceEventAnalysis(
          profile: analysis.profile,
          events: analysis.events
              .where((event) => programs.containsKey(event.identity))
              .toList(),
          diagnostics: []);
      final resolver = SourceSemanticResolver.forProject(source);
      maps = {
        for (final ir in source.maps)
          ir.map.sourceMapId: MapData(
              id: 'elevator_${ir.map.sourceMapId}',
              name: ir.map.name,
              size: GridSize(width: ir.map.width, height: ir.map.height),
              layers: [
                MapLayer.collision(
                    id: 'collision_${ir.map.sourceMapId}',
                    name: 'Source',
                    collisions: SourceCollisionProjection.resolve(
                            cells: [
                          for (var y = 0; y < ir.map.height; y++)
                            for (var x = 0; x < ir.map.width; x++)
                              resolver.cellAt(ir.map.sourceMapId, x, y)
                        ],
                            resolver: resolver,
                            mapSize: GridSize(
                                width: ir.map.width, height: ir.map.height))
                        .fullyBlockedCells)
              ])
      };
      base = NativeProjectDraft(
          source: source,
          projectName: 'Complete source elevators',
          parentPath: temporary.path,
          folderName: 'logic',
          mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
          artifacts: [],
          compositionEvidence: const {'sourceSemantics': {}},
          mutations: [
            for (final entry in maps.entries)
              NativeMutation(
                  operationId: ConverterId('map_${entry.key}'),
                  actionId: 'map.save',
                  sourceEntityIds: [source.mapIdentity(entry.key)],
                  targetEntityIds: [ConverterId(entry.value.id)],
                  parameters: {
                    'mapId': entry.value.id,
                    'map': entry.value.toJson()
                  },
                  limits: limits)
          ],
          limits: limits);
      contexts = await const SourceEventExecutionContextResolver()
          .readTransfers(
              source: source,
              base: base,
              nativeMaps: maps,
              files: files,
              programs: const {},
              elevatorPrograms: programs,
              analysis: analysis,
              limits: limits);
      for (final entry in contexts.entries) {
        expect(entry.value.isQualified, true,
            reason: '${entry.key}: ${entry.value.refusals}');
      }
      final contextProofPath =
          Platform.environment['AVELUNE_ELEVATOR_CONTEXT_PROOF'];
      if (contextProofPath != null) {
        int bytes(Object? value) => utf8.encode(jsonEncode(value)).length;
        final contextRows = <Map<String, Object?>>[];
        for (final entry in contexts.entries) {
          final context = entry.value.toJson();
          contextRows.add({
            'identity': entry.key.value,
            'byteLength': bytes(context),
            'keys': {for (final key in context.keys) key: bytes(context[key])},
            'proofKeys': {
              for (final key in (context['proof'] as Map).keys)
                key: bytes((context['proof'] as Map)[key])
            }
          });
        }
        final selected = contexts.values.first.toJson();
        await File(contextProofPath).writeAsString(
            jsonEncode({
              'encoding': 'utf8 canonical compact json',
              'sourceMapCount': source.maps.length,
              'contexts': contextRows,
              'selectedContext': selected
            }),
            flush: true);
      }
      retention = await sourceEventMapRetentionPolicy(
          source: source,
          files: files,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
      sounds = {
        for (final name in [
          'Entering Door',
          'Exit Door',
          'Elevator moving',
          'Elevator end'
        ])
          name: await const SourceEventSoundResolver()
              .read(source: source, files: files, name: name, limits: limits)
      };
      characters = {};
      for (final event in analysis.events) {
        for (final page in event.pages) {
          final graphic = page.graphic!;
          if (graphic.characterName.isEmpty) continue;
          final key = sourceEventCharacterBindingKey(
              characterName: graphic.characterName,
              pattern: graphic.pattern,
              direction: graphic.direction);
          if (characters.containsKey(key)) continue;
          final imported = await const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: files,
              charsetName: graphic.characterName,
              sourcePattern: graphic.pattern,
              sourceDirection: graphic.direction,
              limits: limits);
          characters[key] = imported.binding;
        }
      }
      final projection = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: maps,
          elevatorPrograms: programs,
          elevatorContexts: contexts,
          retentionPolicy: retention,
          soundBindings: sounds,
          characterBindings: characters,
          staticDoorPrograms: const {},
          routedDoorPrograms: const {},
          stairPrograms: const {},
          limits: limits);
      events = SourceEventStudyComposition(draft: base, projection: projection);
    });
    tearDownAll(() async {
      if (temporary.existsSync()) await temporary.delete(recursive: true);
    });

    SceneAsset sceneFor(SourceElevatorProgram program, [int page = 0]) =>
        events.projection.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
                program.eventIdentity.value &&
            scene.metadata['sourcePageIndex'] == '$page');

    test('all 19 entries, 3 exits and 3 controllers are admitted atomically',
        () {
      expect(programs, hasLength(34));
      final evidence =
          (events.projection.semanticEvidence['events'] as List).cast<Map>();
      for (final program in programs.values) {
        final row = evidence.singleWhere(
            (row) => row['sourceIdentity'] == program.eventIdentity.value);
        expect(row['gaps'], isEmpty,
            reason: '${program.sourceMapId}/${program.sourceEventId}: $row');
        if (program.role != SourceElevatorRole.actor) {
          expect(buildSceneRuntimePlan(sceneFor(program)).plan, isNotNull);
        }
      }
      for (final program in programs.values
          .where((program) => program.role == SourceElevatorRole.actor)) {
        final entity = events
            .projection.nativeMaps[program.sourceMapId]!.entities
            .singleWhere((entity) =>
                entity.properties['sourceEventIdentity'] ==
                program.eventIdentity.value);
        expect(entity.pos, GridPos(x: program.event.x, y: program.event.y));
        expect(entity.size, const GridSize(width: 1, height: 1));
        expect(entity.blocksMovement, true);
        expect(entity.properties[mapEntityCollisionWidthProperty], '1');
        expect(entity.properties[mapEntityCollisionHeightProperty], '1');
        expect(entity.properties[mapEntityCollisionOffsetXProperty], '0');
        expect(entity.properties[mapEntityCollisionOffsetYProperty], '0');
      }
      expect(
          events.projection.facts
              .where((fact) => fact.valueKind == NarrativeValueKind.integer),
          hasLength(2));
      for (final variable in [10, 11]) {
        final key =
            'source:${source.snapshot.logicalProjectNamespace.value}:variable:$variable';
        expect(
            events.projection.facts.where((fact) =>
                fact.description == 'Persistent source boolean: $key'),
            isEmpty);
        expect(
            events.projection.facts
                .singleWhere((fact) =>
                    fact.id == sourceEventIntegerVariableBindingId('source:${source.snapshot.logicalProjectNamespace.value}:variable:$variable'))
                .valueKind,
            NarrativeValueKind.integer);
      }
    });

    test('elevator writers and readers share canonical generic integer identities', () {
      final ids = {for (final variable in [10, 11]) sourceEventIntegerVariableBindingId(
        'source:${source.snapshot.logicalProjectNamespace.value}:variable:$variable')};
      final integer = events.projection.facts.where((fact) => fact.valueKind == NarrativeValueKind.integer);
      expect(integer.map((fact) => fact.id).toSet(), ids);
      expect(integer.map((fact) => fact.initialValue), everyElement(NarrativeValue.integer(0)));
      final actions = events.projection.scenes.expand((scene) => scene.graph.nodes)
          .map((node) => node.payload).whereType<SceneActionPayload>()
          .map((payload) => payload.consequence).whereType<SceneSetFactConsequence>();
      expect(actions.where((action) => action.narrativeValue.kind == NarrativeValueKind.integer)
          .map((action) => action.factId).toSet(), ids);
      final readers = events.projection.scenes.expand((scene) => scene.graph.nodes)
          .map((node) => node.payload).whereType<SceneConditionPayload>()
          .map((payload) => payload.conditionSource).whereType<SceneConditionSource>()
          .where((condition) => condition.expectedFactValue?.kind == NarrativeValueKind.integer);
      expect(readers.map((condition) => condition.sourceId).toSet(), {
        sourceEventIntegerVariableBindingId('source:${source.snapshot.logicalProjectNamespace.value}:variable:10'),
      });
    });

    test(
        'all 34 complete execution contexts restore exactly from shared evidence',
        () {
      final evidence = events.projection.semanticEvidence;
      final encoded = (evidence['elevatorPrograms'] as List)
          .cast<Map>()
          .map((entry) =>
              Map<String, Object?>.from(entry['executionContext'] as Map))
          .toList();
      final tables =
          Map<String, Object?>.from(evidence['executionContextTables'] as Map);
      final restored = SourceEventEvidenceEncoding.restoreContexts(
          encoded, tables,
          limits: limits);
      final originals = programs.values
          .map((program) => contexts[program.eventIdentity]!.toJson())
          .toList();
      expect(canonicalJsonOf(restored, limits: limits.jsonLimits),
          canonicalJsonOf(originals, limits: limits.jsonLimits));
      final broken = jsonDecode(jsonEncode(tables)) as Map<String, dynamic>;
      (broken['nativeBindings'] as Map).clear();
      expect(
          () => SourceEventEvidenceEncoding.restoreContexts(encoded, broken,
              limits: limits),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'events.evidence.binding')));
      expect(
          events.projection.artifacts
              .every((artifact) => artifact.bytes.length <= 1048576),
          true);
    });

    test(
        'caller omission, missing contexts, sound and actor binding refuse the complete family',
        () {
      final identity = programs.keys.first;
      final omitted = SourceEventAnalysis(
          profile: analysis.profile,
          events: analysis.events
              .where((event) => event.identity != identity)
              .toList(),
          diagnostics: []);
      expect(
          sourceElevatorPrograms(source: source, analysis: omitted), isEmpty);
      expect(
          sourceElevatorPrograms(
              source: source,
              analysis: SourceEventAnalysis(
                  profile: analysis.profile,
                  events: [analysis.eventAt(38, 3)!],
                  diagnostics: [])),
          isEmpty);
      final result = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: maps,
          elevatorPrograms: programs,
          staticDoorPrograms: const {},
          routedDoorPrograms: const {},
          stairPrograms: const {},
          limits: limits);
      expect(
          result.scenes.where((scene) => programs.keys
              .map((id) => id.value)
              .contains(scene.metadata['sourceEventIdentity'])),
          isEmpty);
    });

    for (final missing in [
      'context',
      'ownerContext',
      'sound',
      'character',
      'retention',
      'map'
    ]) {
      test('$missing refuses all 34 source-bound family members', () {
        final first = programs.values.first;
        final changedContexts =
            Map<ConverterId, SourceEventExecutionContext>.of(contexts);
        if (missing == 'context') changedContexts.remove(first.eventIdentity);
        if (missing == 'ownerContext') {
          changedContexts[first.eventIdentity] = contexts.entries
              .firstWhere((entry) =>
                  entry.key != first.eventIdentity &&
                  programs[entry.key]!.sourceMapId == first.sourceMapId)
              .value;
        }
        final result = const SourceEventProjector().project(
            source: source,
            analysis: analysis,
            nativeMaps: missing == 'map'
                ? {...maps, 40: maps[40]!.copyWith(name: 'Foreign')}
                : maps,
            elevatorPrograms: programs,
            elevatorContexts: changedContexts,
            soundBindings: missing == 'sound' ? {} : sounds,
            characterBindings: missing == 'character' ? {} : characters,
            retentionPolicy: missing == 'retention' ? null : retention,
            staticDoorPrograms: const {},
            routedDoorPrograms: const {},
            stairPrograms: const {},
            limits: limits);
        expect(result.scenes, isEmpty);
        expect(result.facts, isEmpty);
        expect(result.nativeMaps.values.expand((map) => map.warps), isEmpty);
      });
    }

    test(
        'all 19 entries and all 19 return destinations execute through native scene plans',
        () async {
      final facts = events.projection.facts;
      final writer = NarrativeFactRuntimeWriter(
          NarrativeFactRuntimeResolver.fromFacts(facts));
      final currentFact = facts.singleWhere(
          (fact) => fact.id == sourceEventIntegerVariableBindingId('source:${source.snapshot.logicalProjectNamespace.value}:variable:10'));
      final targetFact = facts.singleWhere(
          (fact) => fact.id == sourceEventIntegerVariableBindingId('source:${source.snapshot.logicalProjectNamespace.value}:variable:11'));
      Future<GameState> run(SceneAsset scene, GameState before,
          {int? choice}) async {
        var state = before;
        final queued = <SceneConsequence>[];
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (intent) {
                  final condition = intent.conditionSource!;
                  final actual = state.narrativeFactRuntimeState
                          .valueFor(condition.sourceId) ??
                      facts
                          .singleWhere((fact) => fact.id == condition.sourceId)
                          .initialValue;
                  return actual.matches(
                          condition.factOperator!, condition.expectedFactValue!)
                      ? 'true'
                      : 'false';
                },
                showDialogue: (_) => 'choice_$choice',
                startBattle: (_) => throw StateError('No battle'),
                playCinematic: (_) => throw StateError('No cinematic'),
                applyConsequence: (consequence) {
                  queued.add(consequence);
                  return 'completed';
                },
                executeInteractiveCommand: (intent) {
                  final command = intent.interactiveCommand!;
                  if (command is SceneWarpInteractiveCommand) {
                    final map = events.projection.nativeMaps.values.singleWhere(
                        (map) => map.id == command.destinationMapId);
                    final warp = map.warps
                        .singleWhere((warp) => warp.id == command.warpId);
                    state = state.copyWith(
                        currentMapId: map.id, playerPosition: warp.targetPos);
                  }
                  return 'completed';
                })).execute(buildSceneRuntimePlan(scene).plan!);
        expect(result.status, SceneRuntimeExecutionStatus.completed,
            reason: result.message);
        for (final consequence in queued.whereType<SceneSetFactConsequence>()) {
          state = writer
              .setFactValue(
                  gameState: state,
                  factId: consequence.factId,
                  value: consequence.narrativeValue)
              .gameState;
        }
        return GameState.fromJson(
            jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
      }

      for (final entry in programs.values
          .where((program) => program.role == SourceElevatorRole.door)) {
        var state = GameState(
            saveId: 'source-elevator-roundtrip',
            currentMapId: maps[entry.sourceMapId]!.id,
            playerPosition: GridPos(x: entry.event.x, y: entry.event.y));
        state = await run(sceneFor(entry), state);
        expect(state.currentMapId, maps[entry.cabinMapId]!.id);
        expect(state.playerPosition, const GridPos(x: 4, y: 7));
        expect(state.narrativeFactRuntimeState.valueFor(currentFact.id),
            NarrativeValue.integer(entry.floor!));
        final controller = programs.values.singleWhere((program) =>
            program.sourceMapId == entry.cabinMapId &&
            program.role == SourceElevatorRole.controller);
        final exit = programs.values.singleWhere((program) =>
            program.sourceMapId == entry.cabinMapId &&
            program.role == SourceElevatorRole.exit);
        state = await run(sceneFor(controller), state, choice: 0);
        expect(state.narrativeFactRuntimeState.valueFor(targetFact.id),
            NarrativeValue.integer(entry.maximumFloor));
        final destination = programs.values.singleWhere((program) =>
            program.role == SourceElevatorRole.door &&
            program.cabinMapId == entry.cabinMapId &&
            program.floor == entry.maximumFloor);
        state = await run(sceneFor(exit), state);
        expect(state.currentMapId, maps[destination.sourceMapId]!.id);
        expect(state.playerPosition,
            GridPos(x: destination.event.x, y: destination.event.y));
        final exitCommands = sceneFor(exit)
            .graph
            .nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((node) => node.interactiveCommand)
            .whereType<SceneWarpInteractiveCommand>();
        expect(
            exitCommands
                .where((command) =>
                    command.destinationMapId == state.currentMapId &&
                    events.projection.nativeMaps[destination.sourceMapId]!.warps
                            .singleWhere((warp) => warp.id == command.warpId)
                            .targetPos ==
                        state.playerPosition)
                .single
                .arrivalCollisionOwnerEntityId,
            isNotNull);
        state = await run(sceneFor(destination), state);
        state = await run(sceneFor(controller), state,
            choice: entry.maximumFloor - entry.floor!);
        state = await run(sceneFor(exit), state);
        expect(state.currentMapId, maps[entry.sourceMapId]!.id);
        expect(
            state.playerPosition, GridPos(x: entry.event.x, y: entry.event.y));
      }
    });

    test('all exit destinations restore the attested final tone on completed and blocked warps',
        () async {
      final facts = events.projection.facts;
      final currentFact = facts.singleWhere(
          (fact) => fact.id == sourceEventIntegerVariableBindingId('source:${source.snapshot.logicalProjectNamespace.value}:variable:10'));
      var paths = 0;
      for (final program in programs.values
          .where((program) => program.role == SourceElevatorRole.exit)) {
        final warps = sourceElevatorNodes(program.event)
            .whereType<SourceWarpNode>()
            .toList();
        final revealed = program.event.pages.single.body.nodes.last as SourceToneNode;
        for (final floor in [0, ...List.generate(program.maximumFloor, (i) => i + 1),
          program.maximumFloor + 1]) {
          final destination = floor < 1 || floor > program.maximumFloor
              ? warps.last
              : warps[program.maximumFloor - floor];
          for (final outcome in ['completed', 'blocked']) {
            var mapId = maps[program.sourceMapId]!.id;
            var position = GridPos(x: program.event.x, y: program.event.y);
            final tones = <SceneWorldToneInteractiveCommand>[];
            final transfers = <SceneWarpInteractiveCommand>[];
            final result = await SceneRuntimeExecutor(
                callbacks: SceneRuntimeExecutionCallbacks(
                    evaluateCondition: (intent) {
                      final condition = intent.conditionSource!;
                      expect(condition.sourceId, currentFact.id);
                      return NarrativeValue.integer(floor).matches(
                              condition.factOperator!, condition.expectedFactValue!)
                          ? 'true'
                          : 'false';
                    },
                    showDialogue: (_) => throw StateError('No dialogue'),
                    startBattle: (_) => throw StateError('No battle'),
                    playCinematic: (_) => throw StateError('No cinematic'),
                    applyConsequence: (_) => throw StateError('No fact mutation'),
                    executeInteractiveCommand: (intent) {
                      final command = intent.interactiveCommand!;
                      if (command is SceneWorldToneInteractiveCommand) tones.add(command);
                      if (command is SceneWarpInteractiveCommand) {
                        transfers.add(command);
                        if (outcome == 'completed') {
                          final map = events.projection.nativeMaps.values.singleWhere(
                              (map) => map.id == command.destinationMapId);
                          mapId = map.id;
                          position = map.warps.singleWhere(
                              (warp) => warp.id == command.warpId).targetPos;
                        }
                        return outcome;
                      }
                      return 'completed';
                    })).execute(buildSceneRuntimePlan(sceneFor(program)).plan!);
            expect(result.status, SceneRuntimeExecutionStatus.completed);
            expect(transfers, hasLength(1));
            expect(transfers.single.destinationMapId, maps[destination.targetSourceMapId]!.id);
            expect(tones, hasLength(2), reason: '${program.sourceMapId}/$floor/$outcome');
            expect([tones.last.red, tones.last.green, tones.last.blue, tones.last.gray,
              tones.last.durationMs], [revealed.red, revealed.green, revealed.blue,
              revealed.gray, revealed.durationMs]);
            expect(mapId, maps[outcome == 'completed'
                ? destination.targetSourceMapId : program.sourceMapId]!.id);
            expect(position, outcome == 'completed'
                ? GridPos(x: destination.x, y: destination.y)
                : GridPos(x: program.event.x, y: program.event.y));
            paths++;
          }
        }
      }
      expect(paths, 50);
    });

    test(
        'actual composer writer regenerates policy and strict reopening retains integer facts',
        () async {
      Future<LiteralTileComposition> literal(
              List<LiteralDependencyDecision> decisions) =>
          const LiteralTileComposer().compose(
              source: source,
              files: files,
              selectedSourceMapIds: selection.toList()..sort(),
              projectName: 'Complete elevators',
              parentPath: temporary.path,
              folderName: 'elevators',
              dependencyDecisions: decisions,
              limits: limits);
      final probe = await literal([]);
      final tiles = await literal([
        for (final dependency in probe.dependencies)
          if (!selection.contains(dependency.targetSourceMapId))
            LiteralDependencyDecision(
                sourceSnapshotHash: source.snapshot.canonicalHash,
                selectionHash: probe.selectionHash,
                locator: dependency.locator,
                targetSourceMapId: dependency.targetSourceMapId,
                decision: LiteralDependencyDisposition.excludeStudy)
      ]);
      expect(tiles.draft, isNotNull, reason: tiles.diagnostics.toString());
      final semantic = await const SourceSemanticStudyComposer()
          .compose(source: source, base: tiles, files: files, limits: limits);
      final actualEvents = (await const SourceEventStudyComposer().compose(
          source: source, base: semantic!, files: files, limits: limits))!;
      expect(
          actualEvents.draft.mutations.any(
              (mutation) => mutation.actionId == 'event_v2.record_upsert_batch'),
          true);
      final familyEvidence =
          (actualEvents.projection.semanticEvidence['events'] as List)
              .cast<Map>();
      for (final program in programs.values) {
        expect(
            familyEvidence.singleWhere((row) =>
                row['sourceIdentity'] == program.eventIdentity.value)['gaps'],
            isEmpty);
      }
      final changedEvidence =
          jsonDecode(jsonEncode(actualEvents.draft.compositionEvidence))
              as Map<String, dynamic>;
      final changedPrograms = ((changedEvidence['sourceEvents']
          as Map)['projection'] as Map)['elevatorPrograms'] as List;
      ((changedPrograms.first as Map)['presentationPolicy']
          as Map)['sourceShakeReproduced'] = true;
      final original = actualEvents.draft;
      final changed = NativeProjectDraft(
          source: original.source,
          projectName: original.projectName,
          parentPath: original.parentPath,
          folderName: original.folderName,
          sourceRootPath: original.sourceRootPath,
          defaultMapWidth: original.defaultMapWidth,
          defaultMapHeight: original.defaultMapHeight,
          mapIds: original.mapIds,
          artifacts: original.artifacts,
          sourceArtifacts: original.sourceArtifacts,
          mutations: original.mutations,
          compositionEvidence: changedEvidence,
          limits: limits);
      final changedApproval = approveNativeFixtureDraft(changed);
      await expectLater(
          NativeProjectWriter().write(
              changedApproval.plan, changedApproval.context, changed,
              limits: limits),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code',
                  'native.semantics.regeneration')
              .having((error) => error.stagingPath, 'stagingPath', isNull)));
      final approval = approveNativeFixtureDraft(actualEvents.draft);
      final receipt = await NativeProjectWriter().write(
          approval.plan, approval.context, actualEvents.draft,
          limits: limits);
      expect(receipt.verified, true);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final loaded = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(loaded.loadDiagnostics, isEmpty);
        expect(
            loaded.manifest.facts
                .where((fact) => fact.valueKind == NarrativeValueKind.integer),
            hasLength(2));
        expect(
            loaded.manifest.scenes.where((scene) => programs.keys.any(
                (id) => id.value == scene.metadata['sourceEventIdentity'])),
            hasLength(44));
        final panels = loaded.manifest.characters.where((character) =>
            character.name.startsWith('OBJ_FRLG_Elevator · pattern'));
        expect(panels, isNotEmpty);
        expect(panels.every((character) => character.frameHeight == 3), true);
        expect(loaded.maps, hasLength(18));
        final proofPath = Platform.environment['AVELUNE_ELEVATOR_WRITER_PROOF'];
        if (proofPath != null) {
          await File(proofPath).writeAsString(
              jsonEncode({
                'kind': 'completeSourceElevatorNativeWriterProof',
                'sourceSnapshotHash': source.snapshot.canonicalHash.value,
                'normalizationHash': source.canonicalHash.value,
                'draftHash': actualEvents.draft.canonicalHash.value,
                'projectionHash': canonicalHashOf(
                        actualEvents.projection.semanticEvidence,
                        limits: limits.jsonLimits)
                    .value,
                'nativeRevision': receipt.nativeRevision,
                'receiptVerified': receipt.verified,
                'published': receipt.published,
                'fixtureProjectPath': receipt.projectPath,
                'fixtureDeletedAfterTest': true,
                'strictLoadDiagnostics': loaded.loadDiagnostics
                    .map((diagnostic) => diagnostic.toString())
                    .toList(),
                'manifestHash': canonicalHashOf(loaded.manifest.toJson(),
                        limits: limits.jsonLimits)
                    .value,
                'mapHashes': {
                  for (final entry in receipt.mapHashes.entries)
                    entry.key: entry.value.value
                },
                'assetHashes': {
                  for (final entry in receipt.assetHashes.entries)
                    entry.key: entry.value.value
                },
                'policyTamperRejectedBeforeStage': true,
                'family': [
                  for (final program in programs.values)
                    {
                      'sourceMapId': program.sourceMapId,
                      'sourceEventId': program.sourceEventId,
                      'identity': program.eventIdentity.value,
                      'role': program.role.name,
                      'floor': program.floor
                    }
                ],
                'integerFacts': [
                  for (final fact in loaded.manifest.facts.where(
                      (fact) => fact.valueKind == NarrativeValueKind.integer))
                    fact.toJson()
                ],
                'nativeFamilySceneCount': 44,
                'nativePanelCharacters': [
                  for (final character in panels)
                    {
                      'id': character.id,
                      'frameWidth': character.frameWidth,
                      'frameHeight': character.frameHeight
                    }
                ],
                'sourceProgramPlaybackQualified': false,
                'visiblePlayerQualification': false
              }),
              flush: true);
        }
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    },
        timeout: const Timeout(Duration(minutes: 25)),
        skip: Platform.environment['AVELUNE_ELEVATOR_WRITER_TEST'] != '1'
            ? 'Requires canonical JSON chunk transport dependency'
            : false);

    test(
        'all finite choices preserve defaults, cancellation, intermediate writes and final sound under 100 steps',
        () async {
      final facts = events.projection.facts;
      final writer = NarrativeFactRuntimeWriter(
          NarrativeFactRuntimeResolver.fromFacts(facts));
      final integer = facts
          .where((fact) => fact.valueKind == NarrativeValueKind.integer)
          .toList();
      String variableId(int variable) => integer
          .singleWhere(
              (fact) => fact.id == sourceEventIntegerVariableBindingId('source:${source.snapshot.logicalProjectNamespace.value}:variable:$variable'))
          .id;
      final traces = <Map<String, Object?>>[];
      for (final cabin in [40, 177, 224]) {
        final program = programs.values.singleWhere((program) =>
            program.sourceMapId == cabin &&
            program.role == SourceElevatorRole.controller);
        final plan = buildSceneRuntimePlan(sceneFor(program)).plan!;
        for (var floor = 1; floor <= program.maximumFloor; floor++) {
          for (var choice = 0; choice <= program.maximumFloor; choice++) {
            var state = writer
                .setFactValue(
                    gameState: const GameState(saveId: 'finite-elevator'),
                    factId: variableId(10),
                    value: NarrativeValue.integer(floor))
                .gameState;
            final writes = <SceneSetFactConsequence>[];
            final commands = <SceneInteractiveCommand>[];
            final executed = await SceneRuntimeExecutor(
                callbacks: SceneRuntimeExecutionCallbacks(
                    evaluateCondition: (intent) {
                      final condition = intent.conditionSource!;
                      final actual = state.narrativeFactRuntimeState
                              .valueFor(condition.sourceId) ??
                          facts
                              .singleWhere(
                                  (fact) => fact.id == condition.sourceId)
                              .initialValue;
                      return actual.matches(condition.factOperator!,
                              condition.expectedFactValue!)
                          ? 'true'
                          : 'false';
                    },
                    showDialogue: (intent) {
                      expect(intent.choicePolicies.single.defaultOutcomeId,
                          'choice_${program.maximumFloor - floor}');
                      expect(
                          intent.choicePolicies.single.cancellation.outcomeId,
                          'choice_${program.maximumFloor}');
                      return 'choice_$choice';
                    },
                    startBattle: (_) =>
                        throw StateError('No battle belongs to an elevator'),
                    playCinematic: (_) =>
                        throw StateError('No cinematic belongs to an elevator'),
                    applyConsequence: (consequence) {
                      writes.add(consequence as SceneSetFactConsequence);
                      return 'completed';
                    },
                    executeInteractiveCommand: (intent) {
                      commands.add(intent.interactiveCommand!);
                      return 'completed';
                    })).execute(plan);
            expect(executed.status, SceneRuntimeExecutionStatus.completed,
                reason: executed.message);
            expect(executed.trace.length, lessThanOrEqualTo(100));
            final target = program.maximumFloor - choice;
            expect(
                writes
                    .where((write) => write.factId == variableId(11))
                    .map((write) => write.narrativeValue.intValue),
                [choice, target]);
            final floors = writes
                .where((write) => write.factId == variableId(10))
                .map((write) => write.narrativeValue.intValue)
                .toList();
            expect(
                floors,
                target == 0
                    ? isEmpty
                    : [
                        for (var step = floor + (target > floor ? 1 : -1);
                            target > floor ? step <= target : step >= target;
                            step += target > floor ? 1 : -1)
                          step
                      ]);
            expect(commands.whereType<SceneActorRouteInteractiveCommand>(),
                hasLength(floors.length * 3));
            final actors = programs.values
                .where((member) =>
                    member.sourceMapId == cabin &&
                    member.role == SourceElevatorRole.actor)
                .toList()
              ..sort((a, b) => a.sourceEventId.compareTo(b.sourceEventId));
            final expectedOwners = [
              for (final actor in actors)
                events.projection.nativeMaps[cabin]!.entities
                    .singleWhere((entity) =>
                        entity.properties['sourceEventIdentity'] ==
                        actor.eventIdentity.value)
                    .id
            ];
            final routes = commands
                .whereType<SceneActorRouteInteractiveCommand>()
                .toList();
            expect(routes.map((route) => route.target.entityId), [
              for (var step = 0; step < floors.length; step++) ...expectedOwners
            ]);
            for (final route in routes) {
              expect(route.target.kind, SceneActorTargetKind.entity);
              expect(route.target.mapId, maps[cabin]!.id);
              expect(route.skippable, false);
              expect(route.steps.whereType<SceneActorMoveStep>(), isEmpty);
              expect(
                  route.steps
                      .whereType<SceneActorWaitStep>()
                      .map((step) => step.durationMs),
                  List.filled(6, 100));
              expect(
                  route.steps
                      .whereType<SceneActorFaceStep>()
                      .map((step) => step.direction),
                  [
                    for (var repeat = 0; repeat < 2; repeat++)
                      ...target > floor
                          ? [
                              EntityFacing.west,
                              EntityFacing.east,
                              EntityFacing.south
                            ]
                          : [
                              EntityFacing.east,
                              EntityFacing.west,
                              EntityFacing.south
                            ]
                  ]);
            }
            expect(
                commands.last, isA<ScenePlaySoundEffectInteractiveCommand>());
            expect(commands.last.toJson()['mediaAssetId'],
                sounds['Elevator end']!.mediaId);
            if (target == 0 || target == floor) expect(commands, hasLength(1));
            for (final write in writes) {
              state = writer
                  .setFactValue(
                      gameState: state,
                      factId: write.factId,
                      value: write.narrativeValue)
                  .gameState;
            }
            expect(state.narrativeFactRuntimeState.valueFor(variableId(10)),
                NarrativeValue.integer(target == 0 ? floor : target));
            traces.add({
              'cabin': cabin,
              'floor': floor,
              'choiceIndex': choice,
              'target': target,
              'intermediateFloors': floors,
              'nativeSteps': executed.trace.length,
              'orderedNativeFactWrites':
                  writes.map((write) => write.toJson()).toList(),
              'finalVariable10': state.narrativeFactRuntimeState
                  .valueFor(variableId(10))!
                  .toJson(),
              'finalVariable11': state.narrativeFactRuntimeState
                  .valueFor(variableId(11))!
                  .toJson(),
              'actorRouteCount': routes.length,
              'actorRouteOwnerIds':
                  routes.map((route) => route.target.entityId).toSet().toList(),
              'finalCueMediaId': commands.last.toJson()['mediaAssetId'],
              'nativeConsequencesCommitted': 'afterSceneExecution'
            });
          }
        }
      }
      final path = Platform.environment['AVELUNE_ELEVATOR_EXECUTION_PROOF'];
      if (path != null) {
        await File(path).writeAsString(jsonEncode(traces), flush: true);
      }
    });
  },
      timeout: const Timeout(Duration(minutes: 4)),
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);
}
