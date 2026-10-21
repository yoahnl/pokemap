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
  test(
      'source early delivery composes its complete autorun and addressed clerk',
      () async {
    const selected = {10, 12};
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: selected,
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((s) => s.isNotEmpty)
                .toList());
    final temporary =
        await Directory.systemTemp.createTemp('early-delivery-real-');
    addTearDown(() => temporary.delete(recursive: true));
    final limits = sourceCatalogStudyWriteLimitsFor(selected.length,
        includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: fixture.source,
            files: fixture.files,
            selectedSourceMapIds: selected.toList(),
            projectName: 'Original early delivery',
            parentPath: temporary.path,
            folderName: 'bounded',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final d in probe.dependencies)
        if (!selected.contains(d.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: fixture.source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: d.locator,
              targetSourceMapId: d.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: fixture.source,
        base: base,
        files: fixture.files,
        limits: limits);
    expect(semantic, isNotNull);
    final events = await const SourceEventStudyComposer().compose(
        source: fixture.source,
        base: semantic!,
        files: fixture.files,
        limits: limits);
    expect(events, isNotNull);
    final p = events!.projection;
    final row = (p.semanticEvidence['events'] as List).cast<Map>().singleWhere(
        (e) => e['locator']['mapId'] == 12 && e['locator']['eventId'] == 22);
    expect(row['status'], 'adaptedStaticSemantics');
    expect(row['gaps'], isEmpty);
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    final sourceEvent = analysis.eventAt(12, 22)!;
    final clerk = p.nativeMaps[12]!.entities.singleWhere((e) =>
        e.properties['sourceEventIdentity'] ==
        analysis.eventAt(12, 2)!.identity.value);
    final scene = p.scenes.singleWhere((s) =>
        s.metadata['sourceEventIdentity'] == sourceEvent.identity.value &&
        s.metadata['sourcePageIndex'] == '0');
    final cinematics = scene.graph.nodes
        .where((n) => n.payload is SceneCinematicPayload)
        .map((n) => p.cinematics.singleWhere(
            (c) => c.id == (n.payload as SceneCinematicPayload).cinematicId));
    expect(cinematics, hasLength(1));
    expect(cinematics.single.stageContext!.actorBindings.single.mapEntityId,
        clerk.id);
    expect(cinematics.single.timeline.steps.single.kind,
        CinematicTimelineStepKind.actorEmote);
    final routes = scene.graph.nodes
        .map((n) => n.payload)
        .whereType<SceneActionPayload>()
        .map((n) => n.interactiveCommand)
        .whereType<SceneActorRouteInteractiveCommand>()
        .toList();
    expect(routes, hasLength(4));
    expect(routes.where((route) => route.target.entityId == clerk.id),
        hasLength(2));
    expect(
        scene.graph.nodes
            .map((n) => n.payload)
            .whereType<SceneActionPayload>()
            .map((n) => n.interactiveCommand)
            .whereType<SceneGiveItemInteractiveCommand>(),
        hasLength(1));
  },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: root == null || snapshot == null || profile == null
          ? 'Requires explicit original source, immutable snapshot and interpretation profile.'
          : false);
}
