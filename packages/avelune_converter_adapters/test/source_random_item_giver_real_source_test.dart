import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
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
  test('automatic Kanto Fly giver retains random movement and one-time reward',
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
    const selectedMapIds = {125};
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
    final giver = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze()
        .eventAt(125, 11)!;
    final entity = projection.nativeMaps[125]!.entities.singleWhere((entity) =>
        entity.properties['sourceEventIdentity'] == giver.identity.value);
    expect(entity.npc!.movement.routeSteps,
        const [MapEntityNpcRouteStep.randomMove()]);
    expect(entity.npc!.movement.loop, isTrue);
    final scenes = projection.scenes
        .where((scene) =>
            scene.metadata['sourceEventIdentity'] == giver.identity.value)
        .toList();
    expect(scenes, hasLength(2));
    expect(
        scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.interactiveCommand)
            .whereType<SceneGiveItemInteractiveCommand>(),
        hasLength(1));
    final fly = projection.itemCatalog!.entries
        .singleWhere((item) => item.displayName == 'HM02');
    expect(
        fly.machine,
        const ProjectMoveMachineItemDefinition(
            moveId: 'fly', kind: ProjectMoveMachineKind.hm, consumable: false));
    final exportPath = Platform.environment['AVELUNE_RANDOM_GIVER_EXPORT'];
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
        'kind': 'boundedAutomaticRandomGiverComposition',
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
    for (final location in [(125, 11)]) {
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
