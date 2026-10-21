import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final supplementalRoots =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((value) => value.isNotEmpty)
          .toList();
  final enabled = root != null && snapshot != null && profile != null;

  group('complete original progression maps with remote source context', () {
    const selected = {6, 9, 10, 12, 202};
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceEventProjection projection;

    setUpAll(() async {
      final elapsed = Stopwatch()..start();
      void progress(String stage) => stdout.writeln(jsonEncode({
            'stage': stage,
            'elapsedMs': elapsed.elapsedMilliseconds,
          }));
      progress('readCompleteOriginalProgressionMaps');
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: selected, supplementalRoots: supplementalRoots);
      source = fixture.source;
      expect(source.selectedSourceMapIds.toSet(), selected);
      expect(source.maps.map((map) => map.map.sourceMapId).toSet(), selected);
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      for (final map in source.maps) {
        expect(
            analysis.events
                .where((event) => event.sourceMapId == map.map.sourceMapId)
                .map((event) => event.sourceEventId)
                .toSet(),
            map.map.events.map((event) => event.sourceEventId).toSet());
      }
      expect(
          source.maps
              .singleWhere((map) => map.map.sourceMapId == 202)
              .map
              .events
              .singleWhere((event) => event.sourceEventId == 9)
              .pages
              .any((page) => page.triggerCode == 4),
          isTrue);
      stdout.writeln(jsonEncode({
        'stage': 'completeSourceContextCensus',
        'maps': [
          for (final map in source.maps)
            {
              'mapId': map.map.sourceMapId,
              'eventCount': map.map.events.length,
              'autorunPageCount': map.map.events
                  .expand((event) => event.pages)
                  .where((page) => page.triggerCode == 3)
                  .length,
              'parallelPageCount': map.map.events
                  .expand((event) => event.pages)
                  .where((page) => page.triggerCode == 4)
                  .length,
            }
        ],
      }));
      final temporary =
          await Directory.systemTemp.createTemp('progression-context-real-');
      addTearDown(() => temporary.delete(recursive: true));
      final cancellation = ScanCancellation();
      final deadline = Timer(const Duration(minutes: 8), cancellation.cancel);
      addTearDown(() {
        deadline.cancel();
        cancellation.cancel();
      });
      final limits = sourceCatalogStudyWriteLimitsFor(selected.length,
          includeNativeCatalog: true);
      Future<LiteralTileComposition> literal(
              List<LiteralDependencyDecision> decisions) =>
          const LiteralTileComposer().compose(
              source: source,
              files: fixture.files,
              selectedSourceMapIds: selected.toList(),
              projectName: 'Original progression execution context',
              parentPath: temporary.path,
              folderName: 'bounded',
              dependencyDecisions: decisions,
              limits: limits,
              cancellation: cancellation);
      progress('literalCompleteProgressionMaps');
      final probe = await literal([]);
      final base = await literal([
        for (final dependency in probe.dependencies)
          if (!selected.contains(dependency.targetSourceMapId))
            LiteralDependencyDecision(
                sourceSnapshotHash: source.snapshot.canonicalHash,
                selectionHash: probe.selectionHash,
                locator: dependency.locator,
                targetSourceMapId: dependency.targetSourceMapId,
                decision: LiteralDependencyDisposition.excludeStudy),
      ]);
      expect(base.draft, isNotNull,
          reason: jsonEncode(
              base.diagnostics.map((value) => value.toJson()).toList()));
      progress('semanticCompleteProgressionMaps');
      final semantic = await const SourceSemanticStudyComposer().compose(
          source: source,
          base: base,
          files: fixture.files,
          limits: limits,
          cancellation: cancellation);
      expect(semantic, isNotNull);
      progress('automaticProgressionEventComposition');
      final events = await const SourceEventStudyComposer().compose(
          source: source,
          base: semantic!,
          files: fixture.files,
          limits: limits,
          cancellation: cancellation);
      expect(events, isNotNull);
      projection = events!.projection;
      expect(projection.nativeMaps.keys.toSet(), selected);
      progress('automaticProgressionEventCompositionFinished');
    });

    Map evidence(int mapId, int eventId) =>
        (projection.semanticEvidence['events'] as List).cast<Map>().singleWhere(
            (row) =>
                row['locator']['mapId'] == mapId &&
                row['locator']['eventId'] == eventId);

    SceneAsset firstScene(int mapId, int eventId) =>
        projection.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] ==
                analysis.eventAt(mapId, eventId)!.identity.value &&
            scene.metadata['sourcePageIndex'] == '0');

    List<SceneActorRouteInteractiveCommand> routes(SceneAsset scene) =>
        scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.interactiveCommand)
            .whereType<SceneActorRouteInteractiveCommand>()
            .toList();

    test('Professor parcel retains four executable pages and all six masks',
        () {
      final row = evidence(9, 1);
      expect(row['status'], 'partiallyAdapted', reason: '${row['gaps']}');
      expect(row['gaps'], isEmpty);
      final program = row['nativeOakParcel'] as Map;
      expect(program['unsupportedPageIndices'], [4, 5]);
      expect(program['allSourcePageMasksRequired'], isTrue);
      expect(program['staticSemanticsQualified'], isFalse);
      expect(projection.staticSemanticsQualified, isFalse);
      final identity = analysis.eventAt(9, 1)!.identity.value;
      final actor = projection.nativeMaps[9]!.entities.singleWhere(
          (entity) => entity.properties['sourceEventIdentity'] == identity);
      expect(actor.presentation!.variants, hasLength(6));
      final records = projection.registry.records
          .where((record) =>
              record.definitionOrNull?.source ==
              NarrativeEventSourceRef.entityInteract(
                  projection.nativeMaps[9]!.id, actor.id))
          .toList();
      expect(records, hasLength(4));
      expect(records.every((record) => record.enabledOrNull == true), isTrue);
      final sceneIds =
          records.map((record) => record.definitionOrNull!.sceneId).toSet();
      expect(
          projection.scenes
              .where((scene) => sceneIds.contains(scene.id))
              .map((scene) => scene.metadata['sourcePageIndex'])
              .toSet(),
          {'0', '1', '2', '3'});
    });

    test('starter preparation is admitted with complete remote map context',
        () {
      final row = evidence(9, 8);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      expect(row['gaps'], isEmpty);
      expect(row['nativeActorPreparation'], isA<Map>());
      expect(routes(firstScene(9, 8)), hasLength(4));
    });

    test('parcel delivery addresses its clerk and publishes its native gift',
        () {
      final row = evidence(12, 22);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      expect(row['gaps'], isEmpty);
      final scene = firstScene(12, 22);
      final clerk = projection.nativeMaps[12]!.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] ==
          analysis.eventAt(12, 2)!.identity.value);
      final publishedRoutes = routes(scene);
      expect(publishedRoutes, hasLength(4));
      expect(
          publishedRoutes.where((route) => route.target.entityId == clerk.id),
          hasLength(2));
      expect(
          scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneActionPayload>()
              .map((payload) => payload.interactiveCommand)
              .whereType<SceneGiveItemInteractiveCommand>(),
          hasLength(1));
      final cinematics = scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneCinematicPayload>()
          .map((payload) => projection.cinematics
              .singleWhere((clip) => clip.id == payload.cinematicId))
          .toList();
      expect(cinematics, hasLength(1));
      expect(cinematics.single.stageContext!.actorBindings.single.mapEntityId,
          clerk.id);
      expect(cinematics.single.timeline.steps.single.kind,
          CinematicTimelineStepKind.actorEmote);
    });

    test(
        'unsafe remote parallel remains quarantined without executable records',
        () {
      final row = evidence(202, 9);
      expect(row['status'], 'quarantinedWholeEvent');
      expect(row['gaps'], isNotEmpty);
      expect(
          (row['pages'] as List)
              .cast<Map>()
              .every((page) => page['nativeEventId'] == null),
          isTrue);
      final identity = analysis.eventAt(202, 9)!.identity.value;
      expect(
          projection.scenes.where(
              (scene) => scene.metadata['sourceEventIdentity'] == identity),
          isEmpty);
      final actorIds = projection.nativeMaps[202]!.entities
          .where(
              (entity) => entity.properties['sourceEventIdentity'] == identity)
          .map((entity) => entity.id)
          .toSet();
      expect(
          projection.registry.records.where((record) =>
              record.enabledOrNull == true &&
              actorIds.contains(
                  record.definitionOrNull?.source.toJson()['entityId'])),
          isEmpty);
    });
  },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: enabled
          ? false
          : 'Requires immutable original source, snapshot and interpretation profile.');
}
