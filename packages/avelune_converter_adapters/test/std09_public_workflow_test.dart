import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart' show literalFixtureHash;
import 'support/std09_original_source_fixture.dart';

void main() {
  final enabled = Platform.isMacOS &&
      Platform.environment['AVELUNE_STD09_CORPUS_ROOT'] != null &&
      Platform.environment['AVELUNE_STD09_ENGINE_ARCHIVE'] != null;
  test(
      'STD09 public preparation quarantines a missing picture without hiding audio siblings',
      () async {
    final root =
        await Directory.systemTemp.createTemp('std09-missing-picture-');
    final workflow = ConverterWorkflow();
    try {
      final source = await Std09OriginalSourceFixture.create(
          '${root.path}/source',
          namespace: 'std09-negative-original',
          missingPicture: true);
      final output = await Directory('${root.path}/output').create();
      final snapshot = await workflow.scanSource(ConverterSourceSelection(
          rootPath: source.root,
          logicalProjectNamespace: ConverterId(source.namespace)));
      workflow.updateSettings(ConverterStudySettings(
          contentScope: ConverterContentScope.full,
          interpretationProfile: source.profile,
          projectName: source.namespace,
          parentPath: output.path,
          folderName: 'converted',
          selectedSourceMapIds: const [41, 83],
          profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason: 'Original missing-media negative qualification.')));
      final prepared = await workflow.prepareStudy();
      final evidence =
          prepared.nativeDraft!.compositionEvidence['sourceEvents'] as Map;
      final projection = evidence['projection'] as Map;
      final events = (projection['events'] as List).cast<Map>();
      final picture = events.singleWhere((event) =>
          (event['locator'] as Map)['mapId'] == 83 &&
          (event['locator'] as Map)['eventId'] == 11);
      expect(picture['status'], 'quarantinedWholeEvent',
          reason: jsonEncode(picture));
      expect(picture['gaps'], isNotEmpty);
      final audio = events.singleWhere((event) =>
          (event['locator'] as Map)['mapId'] == 83 &&
          (event['locator'] as Map)['eventId'] == 13);
      expect(audio['status'], 'adaptedStaticSemantics',
          reason: jsonEncode(audio));
      expect(await Directory('${output.path}/converted').exists(), isFalse);
    } finally {
      await workflow.dispose();
      await root.delete(recursive: true);
    }
  }, skip: !enabled, timeout: const Timeout(Duration(minutes: 6)));
  for (final namespace in ['std09-amber-original', 'std09-cobalt-original']) {
    test(
        'STD09 public conversion preserves the qualified original corpus $namespace',
        () async {
      final requested = Platform.environment['AVELUNE_STD09_CORPUS_ROOT'];
      if (requested != null) {
        expect(await Directory('$requested/$namespace').exists(), isFalse,
            reason: 'Qualification requires a fresh evidence directory.');
      }
      final root = requested == null
          ? await Directory.systemTemp.createTemp('$namespace-')
          : await Directory('$requested/$namespace').create(recursive: true);
      final source = await Std09OriginalSourceFixture.create(
          '${root.path}/source',
          namespace: namespace);
      final output = await Directory('${root.path}/output').create();
      final workflow = ConverterWorkflow();
      final restored = ConverterWorkflow();
      try {
        final snapshot = await workflow.scanSource(ConverterSourceSelection(
            rootPath: source.root,
            logicalProjectNamespace: ConverterId(namespace)));
        expect(snapshot.state, SourceScanState.complete);
        workflow.updateSettings(ConverterStudySettings(
            contentScope: ConverterContentScope.full,
            interpretationProfile: source.profile,
            projectName: namespace,
            parentPath: output.path,
            folderName: 'converted',
            selectedSourceMapIds: const [41, 83],
            profileAcknowledgement: SourceStudyAcknowledgement(
                sourceSnapshotHash: snapshot.canonicalHash,
                profileEvidenceHash: snapshot.profile.evidenceHash,
                humanConfirmed: true,
                reason:
                    'Original synthetic qualification source, no source scripts executed.')));
        final prepared = await workflow.prepareStudy();
        stdout
            .writeln(jsonEncode({'namespace': namespace, 'stage': 'prepared'}));
        expect(prepared.canApprove, isTrue,
            reason: jsonEncode(prepared.previewPlan?.findings
                .map((value) => value.toJson())
                .toList()));
        final evidence =
            prepared.nativeDraft!.compositionEvidence['sourceEvents'] as Map;
        final projection = evidence['projection'] as Map;
        final events = (projection['events'] as List).cast<Map>();
        for (final id in [1, 2, 3, 4, 5, 6, 8]) {
          final event = events.singleWhere((event) =>
              (event['locator'] as Map)['mapId'] == 41 &&
              (event['locator'] as Map)['eventId'] == id);
          expect(event['status'], 'adaptedStaticSemantics',
              reason: jsonEncode(event));
          expect(event['pages'], isNotEmpty);
        }
        final opaque = events.singleWhere((event) =>
            (event['locator'] as Map)['mapId'] == 41 &&
            (event['locator'] as Map)['eventId'] == 7);
        expect(opaque['status'], 'quarantinedWholeEvent');
        expect(opaque['gaps'], isNotEmpty);
        expect(
            (opaque['pages'] as List)
                .cast<Map>()
                .map((page) => page['nativeEventId']),
            everyElement(isNull));
        final recipe = ConverterStudyPlanRecipe.decode(
            workflow.exportStudyPlanRecipe().encode());
        final reopened = await restored.restoreStudyPlanRecipe(recipe);
        stdout
            .writeln(jsonEncode({'namespace': namespace, 'stage': 'replayed'}));
        expect(reopened.preparationHash, prepared.preparationHash);
        expect(reopened.nativeDraft!.canonicalHash,
            prepared.nativeDraft!.canonicalHash);
        final approval = workflow.approvePrepared(
            sessionRevision: prepared.sessionRevision,
            preparationHash: prepared.preparationHash,
            humanConfirmed: true);
        final published = await workflow.writeApproved(approval);
        stdout.writeln(
            jsonEncode({'namespace': namespace, 'stage': 'published'}));
        expect(published.published, isTrue);
        expect(published.receipt.verified, isTrue);
        const startService = ConverterPlayableStartService();
        final startChoices = await startService.inspect(
            projectPath: published.projectPath, allowedRootPath: output.path);
        final mapId = prepared.nativeDraft!.mapIds[41]!;
        final startMap =
            startChoices.maps.singleWhere((map) => map.id == mapId);
        expect(startMap.spawns, isNotEmpty);
        expect(startChoices.species.map((species) => species.id),
            containsAll(['arbok', 'rattata']));
        final startReceipt = await startService.apply(
            projectPath: published.projectPath,
            allowedRootPath: output.path,
            expectedRevision: startChoices.revision,
            mapId: mapId,
            spawnId: startMap.spawns.first.id,
            starterSpeciesIds: const ['arbok', 'rattata']);
        final handles = WorkspaceHandleStore();
        const reader = LocalProjectFileReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [output.path], fileReader: reader);
        final opener = ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles);
        final opened = await opener.openProject(published.projectPath);
        try {
          final project = await ProjectSnapshotLoader(handles: handles).load(
              opened.projectHandle,
              policy: ProjectSnapshotLoadPolicy.strict);
          expect(project.loadDiagnostics, isEmpty);
          expect(project.manifest.eventRegistry!.records, isNotEmpty);
          expect(project.manifest.scenes, isNotEmpty);
          expect(project.itemCatalog!.entries, isNotEmpty);
          expect(project.manifest.trainers, isNotEmpty);
          expect(project.manifest.newGame.enabled, isTrue);
          final reference = {
            'kind': 'std09OriginalPublicWorkflow',
            'namespace': namespace,
            'projectPath': published.projectPath,
            'sourceSnapshotHash': snapshot.canonicalHash.value,
            'nativeDraftHash': prepared.nativeDraft!.canonicalHash.value,
            'startMapId': mapId,
            'presentationMapId': prepared.nativeDraft!.mapIds[83],
            'startSpawnId': startMap.spawns.first.id,
            'newGameAdaptation': 'ConverterPlayableStartService',
            'sourceBootstrapParity': false,
            'engineProvenance': source.engineProvenance,
            'startRevision': startReceipt.finalRevision,
            'starterSpeciesIds': ['arbok', 'rattata'],
            'anchors': {
              'guide': {'sourceMapId': 41, 'sourceEventId': 1, 'x': 2, 'y': 3},
              'keyDonor': {
                'sourceMapId': 41,
                'sourceEventId': 2,
                'x': 4,
                'y': 2
              },
              'passage': {
                'sourceMapId': 41,
                'sourceEventId': 3,
                'x': 6,
                'y': 2
              },
              'parallelOwner': {
                'sourceMapId': 41,
                'sourceEventId': 4,
                'x': 6,
                'y': 1
              },
              'gift': {'sourceMapId': 41, 'sourceEventId': 5, 'x': 3, 'y': 5},
              'trainer': {
                'sourceMapId': 41,
                'sourceEventId': 6,
                'x': 8,
                'y': 5
              },
              'presentation': {
                'sourceMapId': 83,
                'sourceEventId': 11,
                'x': 4,
                'y': 2
              },
              'presentationClear': {
                'sourceMapId': 83,
                'sourceEventId': 12,
                'x': 6,
                'y': 2
              },
            },
            'nativeEntities': [
              for (final map in project.maps)
                for (final entity in map.entities)
                  if (entity.properties.containsKey('sourceEventIdentity'))
                    {
                      'mapId': map.id,
                      'entityId': entity.id,
                      'sourceIdentity':
                          entity.properties['sourceEventIdentity'],
                      'x': entity.pos.x,
                      'y': entity.pos.y
                    },
            ],
            'writerVerified': published.receipt.verified,
            'strictReopenVerified': true,
            'sourceEvents': events,
            'sourceScriptsExecuted': 0,
            'playerTraversalVerified': false,
            'iphoneVerified': false,
          };
          if (requested != null) {
            await File('${root.path}/reference.json').writeAsString(
                '${const JsonEncoder.withIndent('  ').convert(reference)}\n');
          }
          stdout.writeln(jsonEncode({
            'kind': reference['kind'],
            'namespace': namespace,
            'projectPath': published.projectPath,
            'strictReopenVerified': true,
            'sourceEventCount': events.length,
          }));
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
        for (final entry in source.sourceHashes.entries) {
          expect(
              literalFixtureHash(
                  await File('${source.root}/${entry.key}').readAsBytes()),
              entry.value,
              reason: entry.key);
        }
      } finally {
        await restored.dispose();
        await workflow.dispose();
        if (requested == null) await root.delete(recursive: true);
      }
    }, skip: !enabled, timeout: const Timeout(Duration(minutes: 6)));
  }
}
