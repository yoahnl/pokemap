import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/original_autotile_fixture.dart';

void main() {
  test('UX-01 real source analysis composition approval and native staging',
      () async {
    final harness = await _WorkflowHarness.create();
    final events = <ConverterWorkflowEvent>[];
    final subscription = harness.workflow.events.listen(events.add);
    try {
      final sourceBefore = await _diskHashes(harness.sourceRoot);
      final snapshot = await harness.workflow.scanSource(harness.selection);
      expect(snapshot.state, SourceScanState.complete);
      expect(snapshot.profile.state, SourceProfileState.observed);
      expect(snapshot.profile.version, '21.1');
      expect(harness.workflow.state.snapshot, same(snapshot));
      expect(harness.workflow.state.availableSourceMapIds, [1, 8]);
      expect(harness.workflow.state.isBusy, isFalse);
      expect(await harness.output.list().toList(), isEmpty);

      harness.workflow.updateSettings(harness.settings(snapshot));
      final prepared = await harness.workflow.prepareStudy();
      expect(prepared.sourceSnapshotHash, snapshot.canonicalHash);
      expect(prepared.profileEvidenceHash, snapshot.profile.evidenceHash);
      expect(prepared.normalizedSource.maps, hasLength(2));
      expect(prepared.normalizedSource.snapshot.profile.state,
          SourceProfileState.observed);
      expect(prepared.composition.selectedSourceMapIds, [1, 8]);
      expect(prepared.composition.includedSourceMapIds, isEmpty);
      expect(prepared.composition.nativeMaps, hasLength(2));
      expect(prepared.composition.layerProvenance, hasLength(6));
      expect(prepared.composition.playableCertified, isFalse);
      expect(prepared.previewPlan!.state, PlanState.draft);
      expect(prepared.previewPlan!.approvedByHuman, isFalse);
      expect(prepared.previewPlan!.requestedMode, ConversionMode.study);
      expect(prepared.previewPlan!.exampleOnly, isFalse);
      expect(prepared.canApprove, isTrue);
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);

      final approval = harness.workflow.approvePrepared(
          sessionRevision: prepared.sessionRevision,
          preparationHash: prepared.preparationHash,
          humanConfirmed: true);
      expect(approval.approvedPlan.state, PlanState.ready);
      expect(approval.approvedPlan.approvedByHuman, isTrue);
      expect(approval.approvedPlanHash, approval.approvedPlan.canonicalHash);
      expect(approval.approvedPlan.selectedSourceMapIds, [1, 8]);
      expect(approval.approvedPlan.dependencySourceMapIds, isEmpty);
      expect(approval.approvedPlan.operations, hasLength(5));
      expect(harness.nativeStages, isEmpty);

      final result = await harness.workflow.writeApproved(approval);
      expect(result.receipt.verified, isTrue);
      expect(result.receipt.published, isFalse);
      expect(result.published, isFalse);
      expect(result.playableCertified, isFalse);
      expect(result.sourceUnchanged, isTrue);
      expect(result.sourceSnapshotHash, snapshot.canonicalHash);
      expect(result.preparationHash, prepared.preparationHash);
      expect(result.approvedPlanHash, approval.approvedPlanHash);
      expect(
          result.receipt.draftHash, prepared.composition.draft!.canonicalHash);
      expect(harness.workflow.state.result, same(result));
      expect(harness.workflow.state.isBusy, isFalse);
      expect(harness.workflow.state.failure, isNull);
      expect(
          harness.nativeStages
              .where((stage) => stage == NativeWriteStage.stageCreated),
          hasLength(1));
      expect(await Directory(harness.destination).exists(), isFalse);

      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [result.receipt.stagingRoot], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(result.receipt.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(native.maps, hasLength(2));
        expect(native.loadDiagnostics, isEmpty);
        for (final map in prepared.composition.nativeMaps.values) {
          expect(native.mapById(map.id), map);
          expect(map.layers.whereType<TileLayer>(), hasLength(3));
          final path = native.manifest.maps
              .singleWhere((entry) => entry.id == map.id)
              .relativePath;
          expect(
              result.receipt.mapHashes[map.id],
              literalFixtureHash(
                  await File('${result.receipt.projectPath}/$path')
                      .readAsBytes()));
        }
        final tileset = native.manifest.tilesets.single;
        final source = tileset.source! as ProjectRegularAtlasTilesetSource;
        final original = harness
            .fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!;
        expect(
            native.resourceBytes('assetLogical:${source.assetId}'), original);
        expect(result.receipt.assetHashes[source.assetId],
            literalFixtureHash(original));
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      expect(await _diskHashes(harness.sourceRoot), sourceBefore);
      expect(
          events.any(
              (event) => event.kind == ConverterWorkflowEventKind.completed),
          isTrue);
    } finally {
      await subscription.cancel();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'preview without study acknowledgement never invents source confirmation',
      () async {
    final harness = await _WorkflowHarness.create(contradictoryProfile: true);
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      expect(snapshot.profile.state, SourceProfileState.requiresConfirmation);
      harness.workflow
          .updateSettings(harness.settings(snapshot, humanConfirmed: false));
      final preview = await harness.workflow.prepareStudy();
      expect(preview.composition.canWrite, isTrue);
      expect(preview.canApprove, isFalse);
      expect(preview.normalizedSource.snapshot.profile.state,
          SourceProfileState.requiresConfirmation);
      expect(preview.previewPlan!.approvedByHuman, isFalse);
      expect(preview.composition.playableCertified, isFalse);
      expect(() => harness.approve(preview),
          _throwsWorkflow('workflow.profile_ack'));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);

      final oldRevision = preview.sessionRevision;
      harness.workflow.updateSettings(harness.settings(snapshot));
      expect(harness.workflow.state.revision, greaterThan(oldRevision));
      expect(harness.workflow.state.prepared, isNull);
      final acknowledged = await harness.workflow.prepareStudy();
      expect(acknowledged.canApprove, isTrue);
      expect(acknowledged.normalizedSource.snapshot.profile.state,
          SourceProfileState.requiresConfirmation);
      expect(
          harness.approve(acknowledged).approvedPlan.approvedByHuman, isTrue);
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'AC-07 first frame consent changes the preparation and invalidates approval',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      final animatedSettings = harness.settings(snapshot);
      harness.workflow.updateSettings(animatedSettings);
      final first = await harness.workflow.prepareStudy();
      final approval = harness.approve(first);
      final studySettings =
          harness.settings(snapshot, allowFirstFrameAutotiles: true);
      expect(
          studySettings.canonicalHash, isNot(animatedSettings.canonicalHash));
      harness.workflow.updateSettings(studySettings);
      expect(harness.workflow.state.prepared, isNull);
      expect(harness.workflow.state.approval, isNull);
      await expectLater(harness.workflow.writeApproved(approval),
          _throwsWorkflow('workflow.stale_approval'));
      final second = await harness.workflow.prepareStudy();
      expect(second.preparationHash, isNot(first.preparationHash));
      expect(second.settings.allowFirstFrameAutotiles, isTrue);
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'AC-07 real workflow blocks unverified animation until exact first-frame consent',
      () async {
    final raster = OriginalAutotileFixture.standard();
    final harness = await _WorkflowHarness.create(maps: [
      LiteralFixtureMap(id: 1, layers: const [
        [79, 0, 0],
        [0, 0, 0],
        [0, 0, 0]
      ])
    ], tilesets: [
      LiteralFixtureTileset(id: 1, autotileNames: const ['OriginalWater'])
    ], autotilePngs: {
      'OriginalWater': raster.pngBytes
    });
    try {
      final before = await _diskHashes(harness.sourceRoot);
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow
          .updateSettings(harness.settings(snapshot, selected: [1]));
      final blocked = await harness.workflow.prepareStudy();
      expect(blocked.canApprove, isFalse);
      expect(
          blocked.composition.diagnostics.any((value) =>
              value.code == 'literal.autotile.animation_unverified' &&
              value.blocksPlanning),
          isTrue);
      expect(
          () => harness.approve(blocked), _throwsWorkflow('workflow.blocked'));
      expect(harness.nativeStages, isEmpty);
      harness.workflow.updateSettings(harness.settings(snapshot,
          selected: [1], allowFirstFrameAutotiles: true));
      final prepared = await harness.workflow.prepareStudy();
      expect(prepared.preparationHash, isNot(blocked.preparationHash));
      expect(prepared.canApprove, isTrue);
      expect(prepared.composition.autotiles.single.degraded, isTrue);
      expect(prepared.composition.autotiles.single.animationVerified, isFalse);
      final result =
          await harness.workflow.writeApproved(harness.approve(prepared));
      expect(result.receipt.verified, isTrue);
      expect(result.published, isFalse);
      expect(result.playableCertified, isFalse);
      final manifest = ProjectManifest.fromJson(jsonDecode(
          await File('${result.receipt.projectPath}/project.json')
              .readAsString()) as Map<String, dynamic>);
      final atlas = manifest.tilesets
          .singleWhere((value) =>
              value.id == prepared.composition.autotiles.single.nativeTilesetId)
          .source as ProjectRegularAtlasTilesetSource;
      expect(atlas.tileAnimations, isEmpty);
      expect(await _diskHashes(harness.sourceRoot), before);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  for (final foreign in ['snapshot', 'evidence']) {
    test('study acknowledgement refuses foreign $foreign hashes before writes',
        () async {
      final harness = await _WorkflowHarness.create();
      try {
        final snapshot = await harness.workflow.scanSource(harness.selection);
        expect(
            () => harness.workflow.updateSettings(harness.settings(snapshot,
                acknowledgementSnapshotHash:
                    foreign == 'snapshot' ? Sha256Hash('0' * 64) : null,
                acknowledgementEvidenceHash:
                    foreign == 'evidence' ? Sha256Hash('0' * 64) : null)),
            _throwsWorkflow('workflow.profile_ack'));
        expect(harness.workflow.state.prepared, isNull);
        expect(harness.workflow.state.approval, isNull);
        expect(harness.nativeStages, isEmpty);
        expect(await harness.output.list().toList(), isEmpty);
      } finally {
        await harness.close();
      }
    }, skip: !Platform.isMacOS);
  }

  test(
      'settings freeze caller collections and reject selection quota before copy',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      final selected = <int>[1, 8];
      final decisions = <LiteralDependencyDecision>[];
      final settings =
          harness.settings(snapshot, selected: selected, decisions: decisions);
      selected.clear();
      expect(settings.selectedSourceMapIds, [1, 8]);
      expect(
          () => settings.selectedSourceMapIds.add(120), throwsUnsupportedError);
      expect(
          () => settings.dependencyDecisions.clear(), throwsUnsupportedError);
      expect(() => harness.settings(snapshot, selected: _UnreadableIds(257)),
          _throwsWorkflow('workflow.quota.selection'));
      expect(
          () => SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason: '   '),
          _throwsWorkflow('workflow.profile_ack'));
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('real progress uses file counts and indeterminate normalized jobs',
      () async {
    late _WorkflowHarness harness;
    final phaseStates = <ConverterWorkflowState>[];
    harness =
        await _WorkflowHarness.create(checkpoint: (phase, jobId, revision) {
      final state = harness.workflow.state;
      expect(state.isBusy, isTrue);
      expect(state.jobId, jobId);
      expect(state.revision, revision);
      if (phase == ConverterWorkflowPhase.normalize ||
          phase == ConverterWorkflowPhase.compose) {
        phaseStates.add(state);
      }
    });
    final events = <ConverterWorkflowEvent>[];
    final subscription = harness.workflow.events.listen(events.add);
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      await Future<void>.delayed(Duration.zero);
      final scanProgress = events.where((event) =>
          event.kind == ConverterWorkflowEventKind.progress &&
          event.state.phase == ConverterWorkflowPhase.scan);
      expect(scanProgress, isNotEmpty);
      final progress =
          scanProgress.map((event) => event.state.progress!).toList();
      final regularFiles = snapshot.entries
          .where((entry) => entry.kind == SourceNodeKind.file)
          .length;
      expect(progress.last.unit, JobUnit.files);
      expect(progress.last.total, regularFiles);
      expect(progress.last.done, regularFiles);
      var done = 0;
      for (final event in scanProgress) {
        expect(event.state.job, isNull);
        expect(event.state.jobId, isNotNull);
        expect(event.state.progress!.done, greaterThanOrEqualTo(done));
        expect(event.state.progress!.total, regularFiles);
        done = event.state.progress!.done;
      }
      harness.workflow.updateSettings(harness.settings(snapshot));
      await harness.workflow.prepareStudy();
      expect(
          phaseStates.map((state) => state.phase),
          containsAll([
            ConverterWorkflowPhase.normalize,
            ConverterWorkflowPhase.compose
          ]));
      for (final state in phaseStates) {
        expect(state.progress!.total, isNull);
        expect(state.job!.session.sourceSnapshotHash, snapshot.canonicalHash);
        expect(state.job!.state, JobState.running);
      }
      expect(phaseStates.map((state) => state.jobId).toSet(), hasLength(2));
      expect(harness.workflow.state.isBusy, isFalse);
    } finally {
      await subscription.cancel();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'attempt job identities are distinct while preparation content stays stable',
      () async {
    final jobIds = <ConverterId>[];
    final harness = await _WorkflowHarness.create(
        checkpoint: (_, jobId, __) => jobIds.add(jobId));
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow.updateSettings(harness.settings(snapshot));
      jobIds.clear();
      final first = await harness.workflow.prepareStudy();
      final firstJobs = jobIds.toSet();
      jobIds.clear();
      final second = await harness.workflow.prepareStudy();
      expect(second.sessionRevision, first.sessionRevision);
      expect(second.preparationHash, first.preparationHash);
      expect(firstJobs, isNotEmpty);
      expect(jobIds.toSet().intersection(firstJobs), isEmpty);
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'attempt busy state clears terminal jobs and old progress before worker phases',
      () async {
    final harness = await _WorkflowHarness.create();
    final beginnings = <ConverterWorkflowState>[];
    var captureBeginning = false;
    final subscription = harness.workflow.events.listen((event) {
      if (captureBeginning &&
          event.kind == ConverterWorkflowEventKind.changed &&
          event.state.isBusy) {
        beginnings.add(event.state);
        captureBeginning = false;
      }
    });
    try {
      captureBeginning = true;
      final snapshot = await harness.workflow.scanSource(harness.selection);
      await Future<void>.delayed(Duration.zero);
      harness.workflow.updateSettings(harness.settings(snapshot));
      captureBeginning = true;
      final first = await harness.workflow.prepareStudy();
      await Future<void>.delayed(Duration.zero);
      captureBeginning = true;
      final second = await harness.workflow.prepareStudy();
      expect(second.preparationHash, first.preparationHash);
      await Future<void>.delayed(Duration.zero);
      expect(beginnings, hasLength(3));
      for (final beginning in beginnings) {
        expect(beginning.job, isNull);
        expect(beginning.jobId, isNull);
        expect(beginning.progress, isNull);
        expect(beginning.phase, isNull);
        expect(beginning.cancellationRequested, isFalse);
      }
    } finally {
      await subscription.cancel();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'scan cancellation on real acquired progress stops before every file is read',
      () async {
    final harness = await _WorkflowHarness.create();
    final progress = <JobProgress>[];
    var requested = false;
    final subscription = harness.workflow.events.listen((event) {
      if (event.kind == ConverterWorkflowEventKind.progress &&
          event.state.phase == ConverterWorkflowPhase.scan) {
        final value = event.state.progress!;
        progress.add(value);
        if (!requested && value.done > 0) {
          requested = true;
          harness.workflow.cancelCurrentJob();
        }
      }
    });
    try {
      for (var index = 0; index < 600; index++) {
        await File('${harness.sourceRoot}/Graphics/OriginalPayload$index.txt')
            .writeAsString('Original bounded cancellation payload $index\n');
      }
      final before = await _diskHashes(harness.sourceRoot);
      await expectLater(harness.workflow.scanSource(harness.selection),
          _throwsWorkflow('workflow.cancelled'));
      await Future<void>.delayed(Duration.zero);
      expect(requested, isTrue);
      expect(progress, isNotEmpty);
      expect(progress.last.total, before.length);
      expect(progress.map((item) => item.done).reduce((a, b) => a > b ? a : b),
          lessThan(before.length));
      expect(harness.workflow.state.failure!.code, 'workflow.cancelled');
      expect(harness.workflow.state.snapshot, isNull);
      expect(harness.workflow.state.isBusy, isFalse);
      expect(harness.nativeStages, isEmpty);
      expect(await _diskHashes(harness.sourceRoot), before);
      await _expectSourceClosed(harness.sourceRoot);
    } finally {
      await subscription.cancel();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('busy source worker rejects concurrent actions then cancels and retries',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var pause = true;
    final harness =
        await _WorkflowHarness.create(checkpoint: (phase, _, __) async {
      if (phase == ConverterWorkflowPhase.scan && pause) {
        pause = false;
        entered.complete();
        await release.future;
      }
    });
    try {
      final pending = harness.workflow.scanSource(harness.selection);
      final pendingFailure =
          expectLater(pending, _throwsWorkflow('workflow.cancelled'));
      await entered.future.timeout(const Duration(seconds: 10));
      expect(harness.workflow.state.isBusy, isTrue);
      expect(harness.workflow.state.snapshot, isNull);
      expect(harness.workflow.state.job, isNull);
      final cancelledJobId = harness.workflow.state.jobId;
      await expectLater(harness.workflow.scanSource(harness.selection),
          _throwsWorkflow('workflow.busy'));
      await expectLater(
          harness.workflow.prepareStudy(), _throwsWorkflow('workflow.busy'));
      expect(
          () => harness.workflow
              .updateSettings(harness.settings(harness.fixture.snapshot)),
          _throwsWorkflow('workflow.busy'));
      var heartbeat = false;
      await Future<void>.delayed(const Duration(milliseconds: 5), () {
        heartbeat = true;
      });
      expect(heartbeat, isTrue);
      harness.workflow.cancelCurrentJob();
      expect(harness.workflow.state.cancellationRequested, isTrue);
      expect(harness.workflow.state.isBusy, isTrue);
      release.complete();
      await pendingFailure;
      expect(harness.workflow.state.isBusy, isFalse);
      expect(harness.workflow.state.snapshot, isNull);
      expect(harness.workflow.state.result, isNull);
      expect(harness.workflow.state.failure!.code, 'workflow.cancelled');
      await _expectSourceClosed(harness.sourceRoot);
      final snapshot = await harness.workflow.scanSource(harness.selection);
      expect(snapshot.state, SourceScanState.complete);
      expect(harness.workflow.state.jobId, isNot(cancelledJobId));
      expect(harness.workflow.state.cancellationRequested, isFalse);
      expect(harness.workflow.state.failure, isNull);
      expect(harness.workflow.state.snapshot, same(snapshot));
      expect(harness.nativeStages, isEmpty);
    } finally {
      if (!release.isCompleted) release.complete();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'cancel composition preserves complete inventory and releases source files',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var pause = true;
    final harness =
        await _WorkflowHarness.create(checkpoint: (phase, _, __) async {
      if (phase == ConverterWorkflowPhase.compose && pause) {
        pause = false;
        entered.complete();
        await release.future;
      }
    });
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow.updateSettings(harness.settings(snapshot));
      final pending = harness.workflow.prepareStudy();
      final pendingFailure =
          expectLater(pending, _throwsWorkflow('workflow.cancelled'));
      await entered.future.timeout(const Duration(seconds: 10));
      harness.workflow.cancelCurrentJob();
      expect(harness.workflow.state.isBusy, isTrue);
      release.complete();
      await pendingFailure;
      expect(harness.workflow.state.snapshot, same(snapshot));
      expect(harness.workflow.state.prepared, isNull);
      expect(harness.workflow.state.result, isNull);
      expect(harness.nativeStages, isEmpty);
      await _expectSourceClosed(harness.sourceRoot);
      final retry = await harness.workflow.prepareStudy();
      expect(retry.canApprove, isTrue);
      expect(harness.workflow.state.prepared, same(retry));
      expect(harness.workflow.state.failure, isNull);
    } finally {
      if (!release.isCompleted) release.complete();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  for (final change in ['selection', 'name', 'destination']) {
    test('$change change invalidates the exact preparation and approval',
        () async {
      final harness = await _WorkflowHarness.create();
      try {
        final prepared = await harness.prepare();
        final approval = harness.approve(prepared);
        final snapshot = harness.workflow.state.snapshot!;
        harness.workflow.updateSettings(harness.settings(snapshot,
            selected: change == 'selection' ? [1] : [1, 8],
            projectName: change == 'name' ? 'Changed study name' : null,
            folderName: change == 'destination' ? 'another-new-folder' : null));
        expect(harness.workflow.state.revision,
            greaterThan(prepared.sessionRevision));
        expect(harness.workflow.state.snapshot, same(snapshot));
        expect(harness.workflow.state.prepared, isNull);
        expect(harness.workflow.state.approval, isNull);
        expect(harness.workflow.state.result, isNull);
        await expectLater(harness.workflow.writeApproved(approval),
            _throwsWorkflow('workflow.stale_approval'));
        expect(harness.nativeStages, isEmpty);
        expect(await harness.output.list().toList(), isEmpty);
        final next = await harness.workflow.prepareStudy();
        expect(next.preparationHash, isNot(prepared.preparationHash));
        expect(next.canApprove, isTrue);
      } finally {
        await harness.close();
      }
    }, skip: !Platform.isMacOS);
  }

  test('identical settings preserve a current preparation and approval',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final prepared = await harness.prepare();
      final approval = harness.approve(prepared);
      final revision = harness.workflow.state.revision;
      harness.workflow
          .updateSettings(harness.settings(harness.workflow.state.snapshot!));
      expect(harness.workflow.state.revision, revision);
      expect(harness.workflow.state.prepared, same(prepared));
      expect(harness.workflow.state.approval, same(approval));
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'dependency decisions bind the current selection and distinguish included maps',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow
          .updateSettings(harness.settings(snapshot, selected: [8]));
      final unresolved = await harness.workflow.prepareStudy();
      expect(unresolved.canApprove, isFalse);
      expect(unresolved.previewPlan, isNull);
      expect(unresolved.composition.dependencies.single.targetSourceMapId, 1);
      expect(
          unresolved.composition.diagnostics.any((diagnostic) =>
              diagnostic.code == 'literal.dependency.unresolved' &&
              diagnostic.blocksPlanning),
          isTrue);
      expect(() => harness.approve(unresolved),
          _throwsWorkflow('workflow.blocked'));
      final locator = unresolved.normalizedSource.maps
          .singleWhere((map) => map.map.sourceMapId == 8)
          .map
          .events
          .single
          .pages
          .single
          .commands
          .single
          .sourceLocator;
      LiteralDependencyDecision decision(
              LiteralDependencyDisposition disposition) =>
          LiteralDependencyDecision(
              sourceSnapshotHash: snapshot.canonicalHash,
              selectionHash:
                  literalSelectionHash(unresolved.normalizedSource, [8]),
              locator: locator,
              targetSourceMapId: 1,
              decision: disposition);
      harness.workflow.updateSettings(harness.settings(snapshot,
          selected: [8],
          decisions: [decision(LiteralDependencyDisposition.include)]));
      final included = await harness.workflow.prepareStudy();
      expect(included.canApprove, isTrue);
      expect(included.composition.selectedSourceMapIds, [8]);
      expect(included.composition.includedSourceMapIds, [1]);
      expect(included.composition.nativeMaps, hasLength(2));
      final oldApproval = harness.approve(included);
      expect(oldApproval.approvedPlan.selectedSourceMapIds, [8]);
      expect(oldApproval.approvedPlan.dependencySourceMapIds, [1]);

      harness.workflow.updateSettings(harness.settings(snapshot,
          selected: [8],
          decisions: [decision(LiteralDependencyDisposition.excludeStudy)]));
      expect(harness.workflow.state.prepared, isNull);
      expect(harness.workflow.state.approval, isNull);
      await expectLater(harness.workflow.writeApproved(oldApproval),
          _throwsWorkflow('workflow.stale_approval'));
      final excluded = await harness.workflow.prepareStudy();
      expect(excluded.canApprove, isTrue);
      expect(excluded.preparationHash, isNot(included.preparationHash));
      expect(excluded.composition.includedSourceMapIds, isEmpty);
      expect(excluded.composition.nativeMaps, hasLength(1));
      expect(excluded.composition.playableCertified, isFalse);
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'stale dependency decision keeps its precise cause and cannot be applied',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow
          .updateSettings(harness.settings(snapshot, selected: [8]));
      final unresolved = await harness.workflow.prepareStudy();
      final locator = unresolved.normalizedSource.maps
          .singleWhere((map) => map.map.sourceMapId == 8)
          .map
          .events
          .single
          .pages
          .single
          .commands
          .single
          .sourceLocator;
      harness.workflow.updateSettings(harness.settings(snapshot, selected: [
        8
      ], decisions: [
        LiteralDependencyDecision(
            sourceSnapshotHash: Sha256Hash('0' * 64),
            selectionHash:
                literalSelectionHash(unresolved.normalizedSource, [8]),
            locator: locator,
            targetSourceMapId: 1,
            decision: LiteralDependencyDisposition.include)
      ]));
      final blocked = await harness.workflow.prepareStudy();
      expect(blocked.canApprove, isFalse);
      expect(blocked.previewPlan, isNull);
      expect(blocked.composition.draft, isNull);
      expect(
          blocked.composition.diagnostics.any((diagnostic) =>
              diagnostic.code == 'literal.dependency.decision' &&
              diagnostic.blocksPlanning &&
              diagnostic.locator['file'] == locator.file),
          isTrue);
      expect(
          () => harness.approve(blocked), _throwsWorkflow('workflow.blocked'));
      expect(harness.workflow.state.prepared, same(blocked));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('approval rejects old revisions hashes and absent human confirmation',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final prepared = await harness.prepare();
      for (final invalid in ['revision', 'hash', 'human']) {
        expect(
            () => harness.workflow.approvePrepared(
                sessionRevision:
                    prepared.sessionRevision - (invalid == 'revision' ? 1 : 0),
                preparationHash: invalid == 'hash'
                    ? Sha256Hash('0' * 64)
                    : prepared.preparationHash,
                humanConfirmed: invalid != 'human'),
            _throwsWorkflow(invalid == 'human'
                ? 'workflow.approval_required'
                : 'workflow.stale_approval'));
      }
      expect(harness.workflow.state.approval, isNull);
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'approval from another workflow instance cannot authorize native effects',
      () async {
    final harness = await _WorkflowHarness.create();
    final other = ConverterWorkflow();
    try {
      final prepared = await harness.prepare();
      final snapshot = await other.scanSource(harness.selection);
      other.updateSettings(harness.settings(snapshot));
      final otherPrepared = await other.prepareStudy();
      final foreign = other.approvePrepared(
          sessionRevision: otherPrepared.sessionRevision,
          preparationHash: otherPrepared.preparationHash,
          humanConfirmed: true);
      harness.approve(prepared);
      await expectLater(harness.workflow.writeApproved(foreign),
          _throwsWorkflow('workflow.stale_approval'));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await other.dispose();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('double native application is busy and consumed approval cannot replay',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final harness =
        await _WorkflowHarness.create(nativeCheckpoint: (stage, _, __) async {
      if (stage == NativeWriteStage.beforeStage) {
        entered.complete();
        await release.future;
      }
    });
    try {
      final prepared = await harness.prepare();
      final approval = harness.approve(prepared);
      final pending = harness.workflow.writeApproved(approval);
      await entered.future.timeout(const Duration(seconds: 10));
      expect(harness.workflow.state.isBusy, isTrue);
      await expectLater(harness.workflow.writeApproved(approval),
          _throwsWorkflow('workflow.busy'));
      release.complete();
      final result = await pending;
      expect(result.receipt.verified, isTrue);
      await expectLater(harness.workflow.writeApproved(approval),
          _throwsWorkflow('workflow.stale_approval'));
      expect(
          harness.nativeStages
              .where((stage) => stage == NativeWriteStage.stageCreated),
          hasLength(1));
      expect(await harness.output.list().toList(), hasLength(1));
    } finally {
      if (!release.isCompleted) release.complete();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'cancel native write retains staging and requires fresh approval for retry',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    String? cancelledStage;
    var pause = true;
    final harness = await _WorkflowHarness.create(
        nativeCheckpoint: (stage, stagingRoot, _) async {
      if (stage == NativeWriteStage.afterBootstrap && pause) {
        pause = false;
        cancelledStage = stagingRoot;
        entered.complete();
        await release.future;
      }
    });
    try {
      final sourceBefore = await _diskHashes(harness.sourceRoot);
      final prepared = await harness.prepare();
      final approval = harness.approve(prepared);
      final pending = harness.workflow.writeApproved(approval);
      final pendingFailure =
          expectLater(pending, _throwsWorkflow('workflow.cancelled'));
      await entered.future.timeout(const Duration(seconds: 10));
      harness.workflow.cancelCurrentJob();
      expect(harness.workflow.state.isBusy, isTrue);
      release.complete();
      await pendingFailure;
      expect(harness.workflow.state.result, isNull);
      expect(harness.workflow.state.approval, isNull);
      expect(harness.workflow.state.failure!.stagingPath, cancelledStage);
      expect(await Directory(cancelledStage!).exists(), isTrue);
      expect(await Directory(harness.destination).exists(), isFalse);
      expect(await _diskHashes(harness.sourceRoot), sourceBefore);
      await _expectSourceClosed(harness.sourceRoot);
      await expectLater(harness.workflow.writeApproved(approval),
          _throwsWorkflow('workflow.stale_approval'));
      final retryApproval = harness.approve(harness.workflow.state.prepared!);
      final retry = await harness.workflow.writeApproved(retryApproval);
      expect(retry.receipt.verified, isTrue);
      expect(retry.receipt.stagingRoot, isNot(cancelledStage));
      expect(await Directory(cancelledStage!).exists(), isTrue);
      expect(await _diskHashes(harness.sourceRoot), sourceBefore);
    } finally {
      if (!release.isCompleted) release.complete();
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('inaccessible source failure clears stale data and a valid retry works',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      await harness.prepare();
      await expectLater(
          harness.workflow.scanSource(ConverterSourceSelection(
              rootPath: '${harness.root.path}/absent-source',
              logicalProjectNamespace:
                  ConverterId('original-workflow-fixture'))),
          throwsA(isA<ConverterWorkflowFailure>()));
      expect(harness.workflow.state.failure, isNotNull);
      expect(harness.workflow.state.failure!.message, isNotEmpty);
      expect(harness.workflow.state.snapshot, isNull);
      expect(harness.workflow.state.prepared, isNull);
      expect(harness.workflow.state.approval, isNull);
      expect(harness.workflow.state.result, isNull);
      final snapshot = await harness.workflow.scanSource(harness.selection);
      expect(snapshot.state, SourceScanState.complete);
      expect(harness.workflow.state.failure, isNull);
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('partial scan remains visible and cannot be prepared or approved',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(
          ConverterSourceSelection(
              rootPath: harness.sourceRoot,
              logicalProjectNamespace: ConverterId('original-workflow-fixture'),
              policy: SourceScanPolicy(
                  limits: const SourceScanLimits(maxFileBytes: 32))));
      expect(snapshot.state, isNot(SourceScanState.complete));
      expect(snapshot.diagnostics, isNotEmpty);
      expect(harness.workflow.state.snapshot, same(snapshot));
      expect(harness.workflow.state.failure!.code, 'workflow.incomplete');
      expect(
          () => harness.workflow.updateSettings(
              harness.settings(snapshot, humanConfirmed: false)),
          _throwsWorkflow('workflow.incomplete'));
      await expectLater(harness.workflow.prepareStudy(),
          _throwsWorkflow('workflow.incomplete'));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('missing required PNG produces an inspectable blocked preview',
      () async {
    final harness = await _WorkflowHarness.create(
        tilesets: [LiteralFixtureTileset(id: 1, imagePresent: false)]);
    try {
      final prepared = await harness.prepare();
      expect(prepared.canApprove, isFalse);
      expect(prepared.normalizedSource.canPlan, isFalse);
      expect(prepared.previewPlan, isNull);
      expect(
          prepared.normalizedSource.diagnostics
              .where((diagnostic) => diagnostic.blocksPlanning),
          isNotEmpty);
      expect(prepared.composition.draft, isNull);
      expect(
          () => harness.approve(prepared), _throwsWorkflow('workflow.blocked'));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('malformed PNG preserves the real failure and never creates a stage',
      () async {
    final harness = await _WorkflowHarness.create(tilesets: [
      LiteralFixtureTileset(id: 1, png: [1, 2, 3])
    ]);
    try {
      final sourceBefore = await _diskHashes(harness.sourceRoot);
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow.updateSettings(harness.settings(snapshot));
      await expectLater(harness.workflow.prepareStudy(),
          throwsA(isA<ConverterWorkflowFailure>()));
      expect(
          harness.workflow.state.failure!.code,
          anyOf(startsWith('native.'), startsWith('literal.'),
              startsWith('source.')));
      expect(harness.workflow.state.prepared, isNull);
      expect(harness.workflow.state.result, isNull);
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
      expect(await _diskHashes(harness.sourceRoot), sourceBefore);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'normalization quota is a blocked preview with its original source locator',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow.updateSettings(harness.settings(snapshot,
          normalizationLimits:
              const SourceNormalizationLimits(maxMetadataCells: 1024)));
      final prepared = await harness.workflow.prepareStudy();
      expect(prepared.canApprove, isFalse);
      expect(prepared.previewPlan, isNull);
      expect(
          prepared.normalizedSource.diagnostics.any((diagnostic) =>
              diagnostic.blocksPlanning &&
              diagnostic.locator.file == 'Data/Tilesets.rxdata'),
          isTrue);
      expect(
          () => harness.approve(prepared), _throwsWorkflow('workflow.blocked'));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('literal cell quota keeps its real code before native staging',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final snapshot = await harness.workflow.scanSource(harness.selection);
      harness.workflow.updateSettings(harness.settings(snapshot,
          writeLimits: const NativeWriteLimits(maxMapCells: 8)));
      await expectLater(harness.workflow.prepareStudy(),
          _throwsWorkflow('literal.quota.cells'));
      expect(harness.workflow.state.result, isNull);
      expect(harness.workflow.state.prepared, isNull);
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('source and settings preconditions refuse work without effects',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      await expectLater(harness.workflow.prepareStudy(),
          _throwsWorkflow('workflow.no_source'));
      final snapshot = await harness.workflow.scanSource(harness.selection);
      await expectLater(harness.workflow.prepareStudy(),
          _throwsWorkflow('workflow.no_settings'));
      harness.workflow
          .updateSettings(harness.settings(snapshot, selected: [120]));
      await expectLater(harness.workflow.prepareStudy(),
          _throwsWorkflow('workflow.selection.invalid'));
      expect(harness.nativeStages, isEmpty);
      expect(await harness.output.list().toList(), isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  for (final unsafe in ['existing', 'inside-source']) {
    test('$unsafe destination refuses preparation without filesystem mutations',
        () async {
      final harness = await _WorkflowHarness.create();
      try {
        if (unsafe == 'existing') {
          await Directory(harness.destination).create();
          await File('${harness.destination}/sentinel').writeAsString('owned');
        }
        final before = await _diskHashes(harness.root.path);
        final snapshot = await harness.workflow.scanSource(harness.selection);
        harness.workflow.updateSettings(harness.settings(snapshot,
            parentPath: unsafe == 'inside-source' ? harness.sourceRoot : null));
        await expectLater(harness.workflow.prepareStudy(),
            throwsA(isA<ConverterWorkflowFailure>()));
        expect(harness.workflow.state.prepared, isNull);
        expect(harness.nativeStages, isEmpty);
        expect(await _diskHashes(harness.root.path), before);
      } finally {
        await harness.close();
      }
    }, skip: !Platform.isMacOS);
  }

  for (final point in ['prepare', 'write']) {
    test('source hash drift before $point invalidates the admitted source',
        () async {
      final harness = await _WorkflowHarness.create();
      try {
        final snapshot = await harness.workflow.scanSource(harness.selection);
        harness.workflow.updateSettings(harness.settings(snapshot));
        PreparedStudy? prepared;
        StudyApproval? approval;
        if (point == 'write') {
          prepared = await harness.workflow.prepareStudy();
          approval = harness.approve(prepared);
        }
        final readme = File('${harness.sourceRoot}/README.md');
        final changed = await readme.readAsBytes();
        changed[0] = changed[0] == 79 ? 88 : 79;
        await readme.writeAsBytes(changed, flush: true);
        final sourceAfterExternalChange = await _diskHashes(harness.sourceRoot);
        await expectLater(
            point == 'write'
                ? harness.workflow.writeApproved(approval!)
                : harness.workflow.prepareStudy(),
            _throwsWorkflow('workflow.source_changed'));
        expect(harness.workflow.state.prepared, isNull);
        expect(harness.workflow.state.approval, isNull);
        expect(harness.workflow.state.result, isNull);
        expect(harness.nativeStages, isEmpty);
        expect(await harness.output.list().toList(), isEmpty);
        expect(
            await _diskHashes(harness.sourceRoot), sourceAfterExternalChange);
      } finally {
        await harness.close();
      }
    }, skip: !Platform.isMacOS);
  }

  test('source changed during native staging never returns a successful result',
      () async {
    late _WorkflowHarness harness;
    harness =
        await _WorkflowHarness.create(nativeCheckpoint: (stage, _, __) async {
      if (stage == NativeWriteStage.afterMutations) {
        await File('${harness.sourceRoot}/README.md')
            .writeAsString('Externally changed original source v21.1\n');
      }
    });
    try {
      final prepared = await harness.prepare();
      await expectLater(
          harness.workflow.writeApproved(harness.approve(prepared)),
          _throwsWorkflow('workflow.source_changed'));
      expect(harness.workflow.state.result, isNull);
      expect(harness.workflow.state.approval, isNull);
      expect(harness.workflow.state.failure!.stagingPath, isNotNull);
      expect(
          await Directory(harness.workflow.state.failure!.stagingPath!)
              .exists(),
          isTrue);
      expect(await Directory(harness.destination).exists(), isFalse);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'late destination collision preserves the destination and failed staging',
      () async {
    late _WorkflowHarness harness;
    harness =
        await _WorkflowHarness.create(nativeCheckpoint: (stage, _, __) async {
      if (stage == NativeWriteStage.afterBootstrap) {
        await Directory(harness.destination).create();
        await File('${harness.destination}/sentinel').writeAsString('owned');
      }
    });
    try {
      final sourceBefore = await _diskHashes(harness.sourceRoot);
      final prepared = await harness.prepare();
      await expectLater(
          harness.workflow.writeApproved(harness.approve(prepared)),
          throwsA(isA<ConverterWorkflowFailure>()));
      expect(harness.workflow.state.result, isNull);
      expect(harness.workflow.state.failure!.stagingPath, isNotNull);
      expect(await File('${harness.destination}/sentinel').readAsString(),
          'owned');
      expect(
          await Directory(harness.destination).list().toList(), hasLength(1));
      expect(
          await Directory(harness.workflow.state.failure!.stagingPath!)
              .exists(),
          isTrue);
      expect(await _diskHashes(harness.sourceRoot), sourceBefore);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);

  test('disposed workflow rejects new work without touching the source',
      () async {
    final harness = await _WorkflowHarness.create();
    try {
      final before = await _diskHashes(harness.sourceRoot);
      await harness.workflow.dispose();
      await expectLater(harness.workflow.scanSource(harness.selection),
          _throwsWorkflow('workflow.disposed'));
      expect(
          () => harness.workflow
              .updateSettings(harness.settings(harness.fixture.snapshot)),
          _throwsWorkflow('workflow.disposed'));
      await expectLater(harness.workflow.prepareStudy(),
          _throwsWorkflow('workflow.disposed'));
      expect(await _diskHashes(harness.sourceRoot), before);
      expect(harness.nativeStages, isEmpty);
    } finally {
      await harness.close();
    }
  }, skip: !Platform.isMacOS);
}

final class _WorkflowHarness {
  _WorkflowHarness(
      this.root, this.output, this.fixture, this.workflow, this.nativeStages);

  final Directory root;
  final Directory output;
  final LiteralTileFixture fixture;
  final ConverterWorkflow workflow;
  final List<NativeWriteStage> nativeStages;

  String get sourceRoot => fixture.sourceRootPath!;
  String get destination => '${output.path}/original-study-project';

  ConverterSourceSelection get selection => ConverterSourceSelection(
      rootPath: sourceRoot,
      logicalProjectNamespace: ConverterId('original-workflow-fixture'));

  Future<PreparedStudy> prepare() async {
    final snapshot = await workflow.scanSource(selection);
    workflow.updateSettings(settings(snapshot));
    return workflow.prepareStudy();
  }

  StudyApproval approve(PreparedStudy prepared) => workflow.approvePrepared(
      sessionRevision: prepared.sessionRevision,
      preparationHash: prepared.preparationHash,
      humanConfirmed: true);

  ConverterStudySettings settings(SourceSnapshot snapshot,
          {List<int> selected = const [1, 8],
          List<LiteralDependencyDecision> decisions = const [],
          bool humanConfirmed = true,
          bool allowFirstFrameAutotiles = false,
          String? reason,
          String? projectName,
          String? parentPath,
          String? folderName,
          Sha256Hash? acknowledgementSnapshotHash,
          Sha256Hash? acknowledgementEvidenceHash,
          SourceNormalizationLimits normalizationLimits =
              const SourceNormalizationLimits(),
          NativeWriteLimits writeLimits = const NativeWriteLimits()}) =>
      ConverterStudySettings(
        projectName: projectName ?? 'Controlled original workflow study',
        parentPath: parentPath ?? output.path,
        folderName: folderName ?? 'original-study-project',
        selectedSourceMapIds: selected,
        profileAcknowledgement: SourceStudyAcknowledgement(
          sourceSnapshotHash:
              acknowledgementSnapshotHash ?? snapshot.canonicalHash,
          profileEvidenceHash:
              acknowledgementEvidenceHash ?? snapshot.profile.evidenceHash,
          humanConfirmed: humanConfirmed,
          reason: reason ??
              (humanConfirmed
                  ? 'Controlled original fixture; study only, no production approval or gameplay certification.'
                  : ''),
        ),
        dependencyDecisions: decisions,
        allowFirstFrameAutotiles: allowFirstFrameAutotiles,
        normalizationLimits: normalizationLimits,
        writeLimits: writeLimits,
      );

  static Future<_WorkflowHarness> create({
    ConverterWorkflowCheckpoint? checkpoint,
    NativeWriteCheckpoint? nativeCheckpoint,
    List<LiteralFixtureMap>? maps,
    List<LiteralFixtureTileset>? tilesets,
    Map<String, List<int>> autotilePngs = const {},
    bool contradictoryProfile = false,
  }) async {
    final root =
        await Directory.systemTemp.createTemp('ac09-original-workflow-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/source',
        maps: maps ??
            [
              LiteralFixtureMap(id: 1),
              LiteralFixtureMap(id: 8, warpParameters: [
                [0, 1, 1, 0, 2, 0]
              ]),
            ],
        tilesets: tilesets,
        autotilePngs: autotilePngs,
        contradictoryProfile: contradictoryProfile,
      );
      final stages = <NativeWriteStage>[];
      final workflow = ConverterWorkflow(
          checkpoint: checkpoint,
          nativeWriteCheckpoint: (stage, stagingRoot, projectPath) async {
            stages.add(stage);
            await nativeCheckpoint?.call(stage, stagingRoot, projectPath);
          });
      return _WorkflowHarness(root, output, fixture, workflow, stages);
    } catch (_) {
      await root.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> close() async {
    await workflow.dispose();
    await root.delete(recursive: true);
  }
}

Future<Map<String, Sha256Hash>> _diskHashes(String root) async {
  final hashes = <String, Sha256Hash>{};
  await for (final entry
      in Directory(root).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      hashes[entry.path.substring(root.length + 1)] =
          literalFixtureHash(await entry.readAsBytes());
    }
  }
  return hashes;
}

Matcher _throwsWorkflow(String code) => throwsA(isA<ConverterWorkflowFailure>()
    .having((error) => error.code, 'code', code));

Future<void> _expectSourceClosed(String root) async {
  final receipt = await Process.run(
      '/usr/sbin/lsof', ['-a', '-p', pid.toString(), '+D', root, '-Ffn']);
  expect(receipt.exitCode, anyOf(0, 1));
  expect(
      receipt.stdout
          .toString()
          .split('\n')
          .where((line) => line.startsWith('n$root')),
      isEmpty);
}

final class _UnreadableIds extends ListBase<int> {
  _UnreadableIds(this.count);
  final int count;
  @override
  int get length => count;
  @override
  set length(int value) =>
      throw StateError('Quota must precede collection copy');
  @override
  int operator [](int index) =>
      throw StateError('Quota must precede collection read');
  @override
  void operator []=(int index, int value) =>
      throw StateError('Quota must precede collection write');
}
