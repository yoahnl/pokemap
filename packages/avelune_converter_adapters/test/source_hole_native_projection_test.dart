import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

Map<int, MapData> _maps(NormalizedSourceProject source) => {
      for (final ir in source.maps)
        ir.map.sourceMapId: MapData(
          id: 'hole_map_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Collision',
                collisions: List.filled(ir.map.width * ir.map.height, false))
          ],
        ),
    };

NativeProjectDraft _base(
        NormalizedSourceProject source, Map<int, MapData> maps) =>
    NativeProjectDraft(
      source: source,
      projectName: 'Original holes',
      parentPath: Directory.systemTemp.path,
      folderName: 'hole-context',
      mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
      artifacts: [],
      compositionEvidence: const {'sourceSemantics': {}},
      mutations: [
        for (final entry in maps.entries)
          NativeMutation(
            operationId: ConverterId('hole_map_${entry.key}'),
            actionId: 'map.save',
            sourceEntityIds: [source.mapIdentity(entry.key)],
            targetEntityIds: [ConverterId(entry.value.id)],
            parameters: {'mapId': entry.value.id, 'map': entry.value.toJson()},
          ),
      ],
    );

List<SceneInteractiveCommand> _walk(SceneAsset scene,
    {bool blocked = false, SceneInteractiveCommandKind? blockedKind}) {
  final nodes = {for (final node in scene.graph.nodes) node.id: node};
  var id = scene.graph.startNodeId;
  final commands = <SceneInteractiveCommand>[];
  final visited = <String>{};
  while (true) {
    expect(visited.add(id), true);
    final payload = nodes[id]!.payload;
    if (payload is SceneEndPayload) return commands;
    final command =
        payload is SceneActionPayload ? payload.interactiveCommand : null;
    if (command != null) commands.add(command);
    final fail = command is SceneWarpInteractiveCommand && blocked ||
        command?.kind == blockedKind &&
            commands.where((entry) => entry.kind == blockedKind).length == 1;
    final port = fail ? 'blocked' : 'completed';
    id = scene.graph.edges
        .singleWhere((edge) => edge.fromNodeId == id && edge.fromPortId == port)
        .toNodeId;
    expect(visited.length, lessThan(30));
  }
}

void main() {
  final root = Platform.environment['AVELUNE_HOLE_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_HOLE_SOURCE_SNAPSHOT'];
  final supplemental =
      (Platform.environment['AVELUNE_HOLE_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((path) => path.isNotEmpty)
          .toList();
  group('original source hole native projection', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late Map<int, MapData> maps;
    late Map<ConverterId, SourceHoleNativeProgram> programs;
    late Map<ConverterId, SourceEventExecutionContext> contexts;
    late MapInstanceRetentionPolicy retention;
    late Map<String, SourceEventSoundBinding> sounds;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {203, 204, 361, 362, 363, 364, 365, 366},
          supplementalRoots: supplemental);
      source = fixture.source;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      maps = _maps(source);
      programs = sourceHoleNativePrograms(source: source, analysis: analysis);
      contexts = await const SourceEventExecutionContextResolver()
          .readTransfers(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: fixture.files,
              programs: const {},
              holePrograms: programs,
              analysis: analysis);
      retention = await sourceEventMapRetentionPolicy(
          source: source,
          files: fixture.files,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
      sounds = {
        for (final name in ['Falling Object', 'Landing Object'])
          name: await const SourceEventSoundResolver()
              .read(source: source, files: fixture.files, name: name),
      };
    });
    SourceEventProjection project(
            {bool keepPrograms = true,
            bool keepContext = true,
            bool keepRetention = true,
            bool keepSounds = true,
            Map<int, MapData>? suppliedMaps}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: analysis,
            nativeMaps: suppliedMaps ?? maps,
            staticDoorPrograms: const {},
            routedDoorPrograms: const {},
            stairPrograms: const {},
            holePrograms: keepPrograms ? programs : const {},
            holeContexts: keepContext ? contexts : const {},
            retentionPolicy: keepRetention ? retention : null,
            soundBindings: keepSounds ? sounds : const {});

    test('seventeen Dotted Hole programs become exact native scenes', () {
      expect(programs, hasLength(18));
      final qualified = programs.values
          .where((program) => contexts[program.eventIdentity]!.isQualified)
          .toList();
      expect(qualified, hasLength(17),
          reason: programs.values
              .map((program) =>
                  '${program.sourceMapId}/${program.sourceEventId}: ${contexts[program.eventIdentity]!.refusals}')
              .join('; '));
      final result = project();
      for (final program in qualified) {
        expect(
            result.scenes.where((scene) =>
                scene.metadata['sourceEventIdentity'] ==
                program.eventIdentity.value),
            hasLength(1),
            reason: (result.semanticEvidence['events'] as List)
                .cast<Map>()
                .singleWhere((row) =>
                    row['sourceIdentity'] == program.eventIdentity.value)
                .toString());
        final scene = result.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
            program.eventIdentity.value);
        final commands = _walk(scene);
        expect(commands.map((command) => command.kind.name), [
          'actorVisibility',
          'playSoundEffect',
          'wait',
          'wait',
          'warp',
          'actorVisibility',
          'playSoundEffect'
        ]);
        final hidden = commands.first as SceneActorVisibilityInteractiveCommand;
        expect(hidden.visible, false);
        expect(hidden.target.mapId, maps[program.sourceMapId]!.id);
        final shown = commands[5] as SceneActorVisibilityInteractiveCommand;
        expect(shown.visible, true);
        expect(shown.target.mapId, maps[program.warp.targetSourceMapId]!.id);
        expect(
            commands
                .whereType<SceneWaitInteractiveCommand>()
                .map((command) => command.durationMs),
            [200, 400]);
        final warp = commands.whereType<SceneWarpInteractiveCommand>().single;
        expect(warp.destinationMapId, maps[program.warp.targetSourceMapId]!.id);
        expect(warp.presentation!.mode, SceneWarpPresentationMode.fade);
        final arrival = result.nativeMaps[program.warp.targetSourceMapId]!.warps
            .singleWhere((arrival) => arrival.id == warp.warpId);
        expect(
            [arrival.pos.x, arrival.pos.y], [program.warp.x, program.warp.y]);
        expect(
            commands
                .whereType<ScenePlaySoundEffectInteractiveCommand>()
                .map((command) => command.volume),
            [0.384, 0.384]);
      }
    });
    test(
        'Victory Road hole remains refused by the source pressure-rock controller',
        () {
      final event = analysis.eventAt(204, 19)!;
      expect(contexts[event.identity]!.refusals,
          contains('sourceParallelEventUnsupported'));
      final result = project();
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value),
          isEmpty);
      final evidence = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(evidence['gaps'], contains('sourceParallelEventUnsupported'));
    });
    test(
        '85 native executor paths preserve visibility and transfer failure outcomes',
        () async {
      final result = project();
      var executedPaths = 0;
      for (final program in programs.values
          .where((program) => contexts[program.eventIdentity]!.isQualified)) {
        final scene = result.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
            program.eventIdentity.value);
        final plan = buildSceneRuntimePlan(scene);
        expect(plan.plan, isNotNull);
        final record = result.registry.records.singleWhere(
            (record) => record.definitionOrNull?.sceneId == scene.id);
        expect(record.definitionOrNull!.source.kind,
            NarrativeEventSourceKind.triggerEnter);
        expect(record.enabledOrNull, true);
        for (final failure in ['none', 'hide', 'fall', 'warp', 'land']) {
          var currentMapId = maps[program.sourceMapId]!.id;
          var visible = true;
          var soundCount = 0;
          var transferred = false;
          final executed = await SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
            evaluateCondition: (_) =>
                throw StateError('No condition in a hole'),
            showDialogue: (_) => throw StateError('No dialogue in a hole'),
            startBattle: (_) => throw StateError('No battle in a hole'),
            playCinematic: (_) => throw StateError('No cinematic in a hole'),
            applyConsequence: (_) =>
                throw StateError('No state mutation in a hole'),
            executeInteractiveCommand: (intent) {
              final command = intent.interactiveCommand!;
              if (command is SceneActorVisibilityInteractiveCommand) {
                expect(command.target.mapId, currentMapId);
                if (failure == 'hide' && !command.visible) return 'blocked';
                visible = command.visible;
              } else if (command is ScenePlaySoundEffectInteractiveCommand) {
                soundCount++;
                  if (failure == 'fall' && soundCount == 1 ||
                      failure == 'land' && soundCount == 2) {
                    return 'blocked';
                  }
                if (soundCount == 2) expect(visible, true);
              } else if (command is SceneWarpInteractiveCommand) {
                if (failure == 'warp') return 'blocked';
                currentMapId = command.destinationMapId;
                transferred = true;
              }
              return 'completed';
            },
          )).execute(plan.plan!);
          expect(executed.status, SceneRuntimeExecutionStatus.completed,
              reason: executed.message);
          expect(visible, true);
          expect(transferred, failure == 'none' || failure == 'land');
          expect(
              currentMapId,
              transferred
                  ? maps[program.warp.targetSourceMapId]!.id
                  : maps[program.sourceMapId]!.id);
          expect(executed.trace.length, lessThan(15));
          executedPaths++;
        }
      }
      expect(executedPaths, 85);
    });
    test('blocked transfer restores source visibility before ending', () {
      final result = project();
      for (final program in programs.values
          .where((program) => contexts[program.eventIdentity]!.isQualified)) {
        final scene = result.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
            program.eventIdentity.value);
        final commands = _walk(scene, blocked: true);
        final shown = commands.last as SceneActorVisibilityInteractiveCommand;
        expect(shown.visible, true);
        expect(shown.target.mapId, maps[program.sourceMapId]!.id);
        expect(commands.whereType<ScenePlaySoundEffectInteractiveCommand>(),
            hasLength(1));
      }
    });
    test(
        'blocked hiding or falling sound restores source visibility before ending',
        () {
      final result = project();
      for (final program in programs.values
          .where((program) => contexts[program.eventIdentity]!.isQualified)) {
        final scene = result.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
            program.eventIdentity.value);
        for (final blockedKind in [
          SceneInteractiveCommandKind.actorVisibility,
          SceneInteractiveCommandKind.playSoundEffect
        ]) {
          final commands = _walk(scene, blockedKind: blockedKind);
          expect(commands.whereType<SceneWarpInteractiveCommand>(), isEmpty);
          final shown = commands.last as SceneActorVisibilityInteractiveCommand;
          expect(shown.visible, true);
          expect(shown.target.mapId, maps[program.sourceMapId]!.id);
        }
      }
    });
    for (final missing in ['programs', 'context', 'retention', 'sounds']) {
      test('missing $missing keeps the entire hole disabled', () {
        final result = project(
            keepPrograms: missing != 'programs',
            keepContext: missing != 'context',
            keepRetention: missing != 'retention',
            keepSounds: missing != 'sounds');
        expect(
            result.scenes.where((scene) => programs.containsKey(
                ConverterId(scene.metadata['sourceEventIdentity']!))),
            isEmpty);
      });
    }
    test('changed native map invalidates the execution capability', () {
      final changed = {
        ...maps,
        204: maps[204]!.copyWith(name: 'Altered binding')
      };
      final result = project(suppliedMaps: changed);
      expect(
          result.scenes.where((scene) => programs.containsKey(
              ConverterId(scene.metadata['sourceEventIdentity']!))),
          isEmpty);
    });
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
