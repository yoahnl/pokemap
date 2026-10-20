import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final verifyWrite =
      Platform.environment['AVELUNE_STANDARD_DOOR_VERIFY_WRITE'] == '1';
  final supplementalRoots =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((path) => path.isNotEmpty)
          .toList();
  test('automatic conversion projects real progression doors and their returns',
      () async {
    final elapsed = Stopwatch()..start();
    void progress(String stage) {
      if (verifyWrite) {
        stdout.writeln(jsonEncode({
          'stage': stage,
          'elapsedMs': elapsed.elapsedMilliseconds,
        }));
      }
    }
    progress('source');
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {10, 14, 142, 241, 256, 257},
        supplementalRoots: supplementalRoots);
    final source = fixture.source;
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final programs =
        sourceRoutedDoorPrograms(source: source, analysis: analysis);
    for (final location in [(10, 26), (256, 2), (257, 3)]) {
      final event = analysis.eventAt(location.$1, location.$2)!;
      expect(programs, contains(event.identity), reason: '$location');
    }
    final temporary =
        await Directory.systemTemp.createTemp('standard-progression-doors-');
    addTearDown(() => temporary.delete(recursive: true));
    final limits =
        sourceCatalogStudyWriteLimitsFor(6, includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: source.selectedSourceMapIds,
            projectName: 'Standard progression doors',
            parentPath: temporary.path,
            folderName: 'converted',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final composed = await literal([
      for (final dependency in probe.dependencies)
        if (!source.selectedSourceMapIds.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy),
    ]);
    expect(composed.draft, isNotNull,
        reason: composed.diagnostics.map((value) => value.toJson()).toString());
    progress('encounters');
    final encounters = verifyWrite
        ? await NativeEncounterCatalogQualification.prepareAutomatic(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: source.selectedSourceMapIds)
        : null;
    progress('semantics');
    final semantic = await SourceSemanticStudyComposer(
            includeNativeSurfTraversal: encounters != null)
        .compose(
            source: source,
            base: composed,
            files: fixture.files,
            limits: limits);
    expect(semantic, isNotNull);
    progress('events');
    final events =
        await SourceEventStudyComposer(nativeEncounterQualification: encounters)
            .compose(
                source: source,
                base: semantic!,
                files: fixture.files,
                limits: limits);
    expect(events, isNotNull);
    final rows =
        (events!.projection.semanticEvidence['events'] as List).cast<Map>();
    final locations = [(10, 26), (14, 1), (256, 2), (257, 3)];
    for (final location in locations) {
      final event = analysis.eventAt(location.$1, location.$2)!;
      final row = rows
          .singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(row['status'], 'adaptedStaticSemantics',
          reason: '$location: ${row['gaps']}');
    }
    final cave = analysis.eventAt(241, 1)!;
    final caveRow =
        rows.singleWhere((row) => row['sourceIdentity'] == cave.identity.value);
    expect(caveRow['status'], 'quarantinedWholeEvent');
    expect(caveRow['gaps'], contains('sourceCommandUnqualified'));
    final animation = semantic.mutations.singleWhere(
        (mutation) => mutation.actionId == 'smart_tile.animation.upsert');
    final changedAnimation = NativeMutation(
        operationId: animation.operationId,
        actionId: animation.actionId,
        sourceEntityIds: animation.sourceEntityIds,
        targetEntityIds: animation.targetEntityIds,
        parameters: {
          ...animation.parameters,
          'animation': {
            ...animation.parameters['animation'] as Map,
            'name': 'Unattested animation',
          }
        },
        limits: limits);
    final altered = NativeProjectDraft(
        source: source,
        projectName: semantic.projectName,
        parentPath: semantic.parentPath,
        folderName: semantic.folderName,
        sourceRootPath: semantic.sourceRootPath,
        mapIds: semantic.mapIds,
        artifacts: semantic.artifacts,
        sourceArtifacts: semantic.sourceArtifacts,
        compositionEvidence: semantic.compositionEvidence,
        mutations: [
          for (final mutation in semantic.mutations)
            mutation.operationId == animation.operationId
                ? changedAnimation
                : mutation
        ],
        limits: limits);
    final mapsById = {
      for (final mutation in semantic.mutations
          .where((mutation) => mutation.actionId == 'map.save'))
        (mutation.parameters['map'] as Map)['id'] as String: MapData.fromJson(
            Map<String, dynamic>.from(mutation.parameters['map'] as Map)),
    };
    for (final mutation in semantic.mutations
        .where((mutation) => mutation.actionId == 'gameplay_zone.create')) {
      final id = mutation.parameters['mapId'] as String;
      mapsById[id] = addGameplayZoneToMap(mapsById[id]!,
          zone: MapGameplayZone.fromJson(
              Map<String, dynamic>.from(mutation.parameters['zone'] as Map)));
    }
    final gymDoor = analysis.eventAt(10, 26)!;
    final healthy = await const SourceEventExecutionContextResolver()
        .readRoutedTransfers(
            source: source,
            base: semantic,
            nativeMaps: {
              for (final entry in semantic.mapIds.entries)
                entry.key: mapsById[entry.value]!
            },
            files: fixture.files,
            programs: {gymDoor.identity: programs[gymDoor.identity]!},
            analysis: analysis,
            limits: limits);
    expect(healthy[gymDoor.identity]!.isQualified, isTrue,
        reason: healthy[gymDoor.identity]!.refusals.toString());
    final refused = await const SourceEventExecutionContextResolver()
        .readRoutedTransfers(
            source: source,
            base: altered,
            nativeMaps: {
              for (final entry in semantic.mapIds.entries)
                entry.key: mapsById[entry.value]!
            },
            files: fixture.files,
            programs: {gymDoor.identity: programs[gymDoor.identity]!},
            analysis: analysis,
            limits: limits);
    expect(refused[gymDoor.identity]!.refusals,
        contains('sourceExecutionBaseUnsupported'));
    final output = Platform.environment['AVELUNE_STANDARD_DOOR_RECEIPT'];
    if (!verifyWrite) {
      if (output != null) {
        expect(File(output).isAbsolute, isTrue);
        await File(output).writeAsString(jsonEncode({
          'kind': 'standardProgressionDoorsProjectionQualification',
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'profileHash': analysis.profile.canonicalHash.value,
          'sourceMapIds': source.selectedSourceMapIds,
          'eventStates': [
            for (final row in rows)
              {
                'locator': row['locator'],
                'status': row['status'],
                'gaps': row['gaps'],
              }
          ],
          'newlyQualifiedLocations': [
            for (final location in locations)
              {'mapId': location.$1, 'eventId': location.$2}
          ],
          'sourceEventSummary': {
            'qualified':
                events.projection.semanticEvidence['qualifiedEventCount'],
            'quarantined':
                events.projection.semanticEvidence['quarantinedEventCount'],
          },
          'excludedCaveEvent': {
            'mapId': 241,
            'eventId': 1,
            'gaps': caveRow['gaps']
          },
          'healthyGrassContextQualified': true,
          'alteredGrassAnimationRefused': true,
          'nativeWriteVerified': false,
          'strictReopenCertified': false,
          'playerTraversalCertified': false,
          'deliveredProjectModified': false,
          'sourceScriptsExecuted': 0,
        }));
      }
      return;
    }
    stdout.writeln(
        'Qualifying full catalog and disk write for the selected Kanto maps');
    final cancellation = ScanCancellation();
    final deadline = Timer(const Duration(minutes: 9), cancellation.cancel);
    addTearDown(() {
      deadline.cancel();
      cancellation.cancel();
    });
    progress('catalogs');
    final catalogs = await SourceCatalogStudyComposer(
            nativeEncounterQualification: encounters,
            nativeTrainerQualification: events.trainerQualification,
            nativeTrainerCatalog: events.pokemonGiftCatalog,
            includeNativeEncounterConsumers: encounters != null)
        .compose(
            source: source,
            base: events.draft,
            files: fixture.files,
            limits: limits,
            cancellation: cancellation);
    expect(catalogs, isNotNull);
    final draft = catalogs!.draft;
    progress('approval');
    final approval = approveNativeFixtureDraft(draft);
    progress('writer');
    final receipt = await NativeProjectWriter(
      preparationCheckpoint: (stage, status) =>
          progress('prepare.${stage.name}.${status.done}'),
      checkpoint: (stage, _, __) => progress('write.${stage.name}'),
    ).write(
        approval.plan, approval.context, draft,
        limits: limits, cancellation: cancellation);
    expect(receipt.verified, isTrue);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    progress('reopen');
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final loaded = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(loaded.loadDiagnostics, isEmpty);
      expect(loaded.manifest.maps, hasLength(6));
      expect(
          loaded.manifest.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == gymDoor.identity.value),
          hasLength(3));
      if (output != null) {
        expect(File(output).isAbsolute, isTrue);
        await File(output).writeAsString(jsonEncode({
          'kind': 'standardProgressionDoorsQualification',
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'profileHash': analysis.profile.canonicalHash.value,
          'sourceMapIds': source.selectedSourceMapIds,
          'newlyQualifiedLocations': [
            for (final location in locations)
              {'mapId': location.$1, 'eventId': location.$2}
          ],
          'sourceEventSummary': {
            'qualified':
                events.projection.semanticEvidence['qualifiedEventCount'],
            'quarantined':
                events.projection.semanticEvidence['quarantinedEventCount']
          },
          'excludedCaveEvent': {
            'mapId': 241,
            'eventId': 1,
            'gaps': caveRow['gaps']
          },
          'alteredGrassAnimationRefused': true,
          'healthyGrassContextQualified': true,
          'nativeWriteVerified': receipt.verified,
          'strictReopenDiagnostics': loaded.loadDiagnostics.length,
          'mapCount': loaded.manifest.maps.length,
          'playerTraversalCertified': false,
          'deliveredProjectModified': false,
          'sourceScriptsExecuted': 0,
        }));
      }
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  },
      timeout: Timeout(Duration(minutes: verifyWrite ? 10 : 3)),
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);
}
