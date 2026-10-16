import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';
import 'support/source_external_warp_variant.dart';

const _transfers = [
  (100, 6),
  (100, 7),
  (100, 13),
  (166, 1),
  (205, 2),
  (205, 4)
];

NativeProjectDraft _base(
        NormalizedSourceProject source, Map<int, MapData> maps) =>
    NativeProjectDraft(
        source: source,
        projectName: 'Closed transfer context',
        parentPath: Directory.systemTemp.path,
        folderName: 'closed-transfers',
        mapIds: {
          for (final entry in maps.entries) entry.key: entry.value.id
        },
        artifacts: const [],
        mutations: [
          for (final entry in maps.entries)
            NativeMutation(
                operationId: ConverterId('map_${entry.key}'),
                actionId: 'map.save',
                sourceEntityIds: const [],
                targetEntityIds: [
                  ConverterId(entry.value.id)
                ],
                parameters: {
                  'mapId': entry.value.id,
                  'map': entry.value.toJson()
                })
        ]);

SourceEventDefinition _withPage(SourceEventDefinition event, int index,
        {SourceEventBlock? body,
        bool missingRaw = false,
        bool missingGraphic = false}) =>
    SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x,
        y: event.y,
        locator: event.locator,
        pages: [
          for (final (i, page) in event.pages.indexed)
            if (i != index)
              page
            else
              SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: missingGraphic ? null : page.graphic,
                  body: body ?? page.body,
                  rawDataRef: missingRaw ? null : page.rawDataRef,
                  diagnostics: page.diagnostics)
        ]);

void main() {
  final root = Platform.environment['AVELUNE_EXTERNAL_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_EXTERNAL_SOURCE_SNAPSHOT'];
  group('closed original external transfer projection', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceFilePort files;
    late Map<int, MapData> maps;
    late SourceExternalWarpBinding binding;
    late SourceEventExecutionContext context;
    late MapInstanceRetentionPolicy retention;
    late SourceEventSoundBinding sound;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      final resolver = SourceSemanticResolver.forProject(source);
      maps = {
        for (final ir in source.maps)
          ir.map.sourceMapId: MapData(
              id: 'native_${ir.map.sourceMapId}',
              name: ir.map.name,
              size: GridSize(width: ir.map.width, height: ir.map.height),
              layers: [
                MapLayer.collision(
                    id: 'collision_${ir.map.sourceMapId}',
                    name: 'Collision',
                    collisions: List.generate(
                        ir.map.width * ir.map.height,
                        (index) => analysis.events.any((event) =>
                            event.sourceMapId == ir.map.sourceMapId &&
                            event.x == index % ir.map.width &&
                            event.y == index ~/ ir.map.width &&
                            resolver
                                    .resolveConnectionEntryTile(resolver.cellAt(
                                        event.sourceMapId, event.x, event.y))
                                    .status ==
                                SourcePassageStatus.blocked)))
              ])
      };
      final base = _base(source, maps);
      context = await const SourceEventExecutionContextResolver()
          .read(source: source, base: base, nativeMaps: maps, files: files);
      expect(context.isQualified, true, reason: context.refusals.toString());
      retention = await sourceEventMapRetentionPolicy(
          source: source, files: files, nativeMapIds: base.mapIds);
      binding = (await const SourceExternalWarpBindingResolver().read(
          source: source,
          analysis: analysis,
          files: files,
          policy:
              SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState))!;
      sound = await const SourceEventSoundResolver()
          .read(source: source, files: files, name: 'Exit Door');
    });
    SourceEventProjection project(
            {SourceExternalWarpBinding? external,
            SourceEventAnalysis? analyzed,
            Map<int, MapData>? nativeMaps,
            SourceEventExecutionContext? execution,
            bool withSound = true,
            bool withRetention = true,
            bool withContext = true}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: analyzed ?? analysis,
            nativeMaps: nativeMaps ?? maps,
            externalWarpBinding: external,
            soundBindings: withSound ? {'Exit Door': sound} : {},
            executionContext: withContext ? execution ?? context : null,
            retentionPolicy: withRetention ? retention : null,
            limits: const NativeWriteLimits(
                maxMutations: 2048, maxArtifacts: 1024));
    Map row(SourceEventProjection result, (int, int) pair) =>
        (result.semanticEvidence['events'] as List).cast<Map>().singleWhere(
            (row) =>
                row['sourceIdentity'] ==
                source.eventIdentity(pair.$1, pair.$2).value);
    SceneAsset scene(SourceEventProjection result, (int, int) pair, int page) =>
        result.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
                source.eventIdentity(pair.$1, pair.$2).value &&
            scene.metadata['sourcePageIndex'] == '$page');
    void quarantined(
        SourceEventProjection result, (int, int) pair, String gap) {
      expect(row(result, pair)['status'], 'quarantinedWholeEvent');
      expect(row(result, pair)['gaps'], contains(gap));
      expect(
          result.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] ==
              source.eventIdentity(pair.$1, pair.$2).value),
          isEmpty);
    }

    SourceEventAnalysis replace(SourceEventDefinition event) =>
        SourceEventAnalysis(
            profile: analysis.profile,
            diagnostics: analysis.diagnostics,
            events: [
              for (final original in analysis.events)
                original.identity == event.identity ? event : original
            ]);
    test(
        'six original programs become native warps with exact target and artwork',
        () {
      final result = project(external: binding);
      final rows = (result.semanticEvidence['events'] as List).cast<Map>();
      for (final pair in _transfers) {
        final id = source.eventIdentity(pair.$1, pair.$2).value;
        final row = rows.singleWhere((row) => row['sourceIdentity'] == id);
        expect(row['status'], 'adaptedStaticSemantics',
            reason: '$pair ${row['gaps']}');
        final scene = result.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] == id &&
            scene.metadata['sourcePageIndex'] == '0');
        final native = scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((action) => action.interactiveCommand)
            .whereType<SceneWarpInteractiveCommand>()
            .single;
        final program =
            binding.programs[source.eventIdentity(pair.$1, pair.$2)]!;
        expect(native.destinationMapId, maps[program.targetSourceMapId]!.id);
        expect(native.presentation!.mode.name, program.presentation.name);
        expect(native.presentation!.illustrationElementId,
            binding.illustrations[program.illustrationName]?.id);
      }
    });
    test(
        'folded Exit Door sound precedes each typed warp on completed and blocked ports',
        () async {
      final result = project(external: binding);
      for (final port in ['completed', 'blocked']) {
        for (final pair in _transfers) {
          final trace = <SceneInteractiveCommand>[];
          final execution = await SceneRuntimeExecutor(
                  callbacks: SceneRuntimeExecutionCallbacks(
                      evaluateCondition: (_) =>
                          throw StateError('Unexpected source branch'),
                      showDialogue: (_) =>
                          throw StateError('No synthetic warp dialogue'),
                      startBattle: (_) => throw StateError('No battle'),
                      playCinematic: (_) => throw StateError('No cinematic'),
                      applyConsequence: (_) =>
                          throw StateError('No synthetic source fact'),
                      executeInteractiveCommand: (intent) {
                        final command = intent.interactiveCommand!;
                        trace.add(command);
                        return command is SceneWarpInteractiveCommand
                            ? port
                            : 'completed';
                      }))
              .execute(buildSceneRuntimePlan(scene(result, pair, 0)).plan!);
          expect(execution.status, SceneRuntimeExecutionStatus.completed);
          expect(trace.map((command) => command.kind), [
            SceneInteractiveCommandKind.playSoundEffect,
            SceneInteractiveCommandKind.warp
          ]);
          final audio = trace.first as ScenePlaySoundEffectInteractiveCommand;
          expect(audio.mediaAssetId, sound.mediaId);
          expect(audio.volume, sound.gainForVolume(80));
          final warp = trace.last as SceneWarpInteractiveCommand;
          final program =
              binding.programs[source.eventIdentity(pair.$1, pair.$2)]!;
          final arrival = result.nativeMaps[program.targetSourceMapId]!.warps
              .singleWhere((w) => w.id == warp.warpId);
          expect(arrival.pos, GridPos(x: program.x, y: program.y));
          expect(arrival.targetPos, arrival.pos);
          expect(arrival.triggerMode, MapWarpTriggerMode.sceneOnly);
          expect(warp.transition, SceneWarpTransition.none);
        }
      }
    });
    test(
        'arrival autoruns retain player routes, barriers and instance-local TempA after completion',
        () async {
      final result = project(external: binding);
      for (final pair in [(100, 7), (100, 13)]) {
        final nativeScene = scene(result, pair, 1);
        final record = result.registry.records
            .map((r) => r.definitionOrNull)
            .whereType<NarrativeEventDefinition>()
            .singleWhere((d) => d.sceneId == nativeScene.id);
        expect(record.source.kind, NarrativeEventSourceKind.entityAutorun);
        expect(jsonEncode(record.conditionExpression.toJson()),
            contains('mapEventInstanceBoolean'));
        final trace = <String>[];
        await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) => 'true',
                showDialogue: (_) => throw StateError('No dialogue'),
                startBattle: (_) => throw StateError('No battle'),
                playCinematic: (_) => throw StateError('No cinematic'),
                executeInteractiveCommand: (intent) {
                  trace.add(intent.interactiveCommand!.kind.name);
                  return 'completed';
                },
                applyConsequence: (consequence) {
                  final local =
                      consequence as SceneSetMapEventInstanceBooleanConsequence;
                  expect(local.mapId, maps[100]!.id);
                  expect(local.key, 'A');
                  expect(local.value, true);
                  expect(trace, ['actorRoute', 'waitForActorRoutes']);
                  trace.add('TempA');
                  return 'completed';
                })).execute(buildSceneRuntimePlan(nativeScene).plan!);
        expect(trace, ['actorRoute', 'waitForActorRoutes', 'TempA']);
      }
      expect(
          result.facts.where((fact) => fact.label.contains('temp')), isEmpty);
    });
    for (final absent in ['binding', 'sound', 'retention', 'context']) {
      test(
          'missing $absent quarantines all six transfers without activating dependent content',
          () {
        final result = project(
            external: absent == 'binding' ? null : binding,
            withSound: absent != 'sound',
            withRetention: absent != 'retention',
            withContext: absent != 'context');
        for (final pair in _transfers) {
          quarantined(
              result,
              pair,
              switch (absent) {
                'binding' => 'sourceExternalWarpBindingsMissing',
                'sound' => 'sourceSoundBindingMissing',
                'retention' => 'sourceMapInstanceRetentionMissing',
                _ => 'sourceExecutionContextUnknown'
              });
        }
      });
    }
    for (final forgery in ['destination', 'missingRaw', 'arrivalProgram']) {
      test('forged $forgery cannot borrow a fully attested external binding',
          () {
        final original = analysis.eventAt(100, 7)!;
        final node = original.pages.first.body.nodes.single as SourceWarpNode;
        final changed = switch (forgery) {
          'destination' => _withPage(original, 0,
              body: SourceEventBlock(
                  span: original.pages.first.body.span,
                  nodes: [
                    SourceWarpNode(node.span,
                        targetSourceMapId: node.targetSourceMapId,
                        x: node.x + 1,
                        y: node.y,
                        direction: node.direction,
                        fade: node.fade,
                        originalProgram: node.originalProgram)
                  ])),
          'missingRaw' => _withPage(original, 0, missingRaw: true),
          _ => _withPage(original, 1,
              body: SourceEventBlock(
                  span: original.pages[1].body.span, nodes: []))
        };
        quarantined(project(external: binding, analyzed: replace(changed)),
            (100, 7), 'sourceExternalWarpBindingsMissing');
      });
    }
    for (final invalid in ['collision', 'footprint', 'truncated', 'absent']) {
      test('fresh execution context still refuses $invalid at the real arrival',
          () async {
        final map = maps[205]!;
        final layers = map.layers.whereType<CollisionLayer>().toList();
        final entity = MapEntity(
            id: 'arrival_cover',
            name: 'Occupied arrival',
            kind: MapEntityKind.custom,
            pos: const GridPos(x: 2, y: 13),
            size: const GridSize(width: 2, height: 1),
            blocksMovement: true);
        if (invalid == 'footprint') {
          expect(resolveEntityCollisionCells(entity),
              contains(const GridPos(x: 3, y: 13)));
        }
        final changed = map.copyWith(
            entities: invalid == 'footprint' ? [entity] : const [],
            layers: invalid == 'absent'
                ? const []
                : [
                    for (final layer in layers)
                      layer.copyWith(
                          collisions: invalid == 'truncated'
                              ? layer.collisions
                                  .take(layer.collisions.length - 1)
                                  .toList()
                              : List.generate(
                                  layer.collisions.length,
                                  (i) => invalid == 'collision' &&
                                          i == 13 * map.size.width + 3
                                      ? true
                                      : layer.collisions[i]))
                  ]);
        final native = {...maps, 205: changed};
        final fresh = await const SourceEventExecutionContextResolver().read(
            source: source,
            base: _base(source, native),
            nativeMaps: native,
            files: files);
        expect(fresh.isQualified, true, reason: fresh.refusals.toString());
        quarantined(
            project(external: binding, nativeMaps: native, execution: fresh),
            (100, 6),
            'sourceExternalWarpArrivalUnqualified');
      });
    }
    for (final pair in [
      (100, 7, 'pbCaveEntrance', 'pbCaveEntrance; unknown_call'),
      (166, 1, 'pbCaveExit', 'pbCaveExit; unknown_call')
    ]) {
      test(
          'freshly reattested ${pair.$3} unknown suffix remains wholly quarantined',
          () async {
        final changed = await reattestExternalWarpLiteral(
            source, files, pair.$1, pair.$3, pair.$4);
        expect(changed.source.canPlan, true);
        expect(changed.source.snapshot.canonicalHash,
            isNot(source.snapshot.canonicalHash));
        final analyzed = SourceEventAnalyzer.forProject(changed.source,
                profile: SourceEventProfile.kantoForProject(changed.source))
            .analyze();
        final event = analyzed.eventAt(pair.$1, pair.$2)!;
        expect(event.isQuarantined, true);
        final freshBinding = await const SourceExternalWarpBindingResolver()
            .read(
                source: changed.source,
                analysis: analyzed,
                files: changed.files,
                policy: SourceExternalWarpPolicy
                    .nativeTransitionsWithoutEscapeState);
        expect(freshBinding!.programs.containsKey(event.identity), false);
        final projected = const SourceEventProjector().project(
            source: changed.source,
            analysis: analyzed,
            nativeMaps: maps,
            externalWarpBinding: freshBinding,
            executionContext: context,
            retentionPolicy: retention,
            soundBindings: {'Exit Door': sound},
            limits: const NativeWriteLimits(maxMutations: 2048));
        quarantined(
            projected, (pair.$1, pair.$2), 'sourceExternalWarpBindingsMissing');
      });
    }
    for (final reverse in [false, true]) {
      test(
          'review duplicate valid and forged identity order $reverse is refused atomically',
          () {
        final valid = analysis.eventAt(100, 7)!;
        final forged = _withPage(valid, 0, missingRaw: true);
        final duplicate = SourceEventAnalysis(
            profile: analysis.profile,
            diagnostics: analysis.diagnostics,
            events: [
              for (final e in analysis.events)
                if (e.identity != valid.identity) e,
              ...reverse ? [valid, forged] : [forged, valid]
            ]);
        expect(
            () => project(external: binding, analyzed: duplicate),
            throwsA(isA<NativeWriteException>().having(
                (error) => error.code, 'code', 'events.source.binding')));
      });
    }
    for (final target in [false, true]) {
      for (final version in [ProjectVersion.v6, ProjectVersion.v9]) {
        test(
            'review source or target spatial $target/${version.name} is refused explicitly',
            () {
          final id = target ? 205 : 100;
          final map = maps[id]!;
          final native = {
            ...maps,
            id: map.copyWith(
                version: version,
                spatialScene: MapSpatialScene(
                    width: map.size.width, depth: map.size.height))
          };
          quarantined(project(external: binding, nativeMaps: native), (100, 6),
              'sourceExternalWarpSpatialUnsupported');
        });
      }
    }
    for (final missing in ['graphic', 'pages']) {
      test(
          'review malformed external arrival owner $missing cannot crash or become active',
          () {
        final original = analysis.eventAt(100, 7)!;
        final forged = missing == 'graphic'
            ? _withPage(original, 0, missingGraphic: true)
            : SourceEventDefinition(
                sourceMapId: original.sourceMapId,
                sourceEventId: original.sourceEventId,
                sourceFileId: original.sourceFileId,
                identity: original.identity,
                name: original.name,
                x: original.x,
                y: original.y,
                locator: original.locator,
                pages: []);
        final result = project(external: binding, analyzed: replace(forged));
        quarantined(result, (100, 7), 'sourceExternalWarpBindingsMissing');
        expect(row(result, (166, 1))['status'], 'adaptedStaticSemantics');
      });
    }
    test(
        'all other events on the two dependency maps remain whole-event quarantined',
        () {
      final result = project(external: binding);
      final rows = (result.semanticEvidence['events'] as List).cast<Map>();
      for (final event in analysis.events.where((event) =>
          const {166, 205}.contains(event.sourceMapId) &&
          !_transfers.contains((event.sourceMapId, event.sourceEventId)))) {
        final id = event.identity.value;
        expect(rows.singleWhere((row) => row['sourceIdentity'] == id)['status'],
            'quarantinedWholeEvent',
            reason: '${event.sourceMapId}:${event.sourceEventId}');
        expect(rows.singleWhere((row) => row['sourceIdentity'] == id)['gaps'],
            contains('sourceExternalMapScopeExcluded'));
        expect(
            result.scenes
                .where((scene) => scene.metadata['sourceEventIdentity'] == id),
            isEmpty);
        expect(
            result.nativeMaps[event.sourceMapId]!.entities.where(
                (entity) => entity.properties['sourceEventIdentity'] == id),
            isEmpty);
      }
    });
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
