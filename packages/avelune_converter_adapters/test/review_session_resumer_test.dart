import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/original_asset_fixture.dart';

void main() {
  test('segmented resume keeps edits and approvals of both maps independently',
      () async {
    final harness = await _ResumeHarness.create(selected: [1, 8]);
    final initial = await harness.prepare();
    var reviewed = initial.reviewSet!;
    for (final mapId in [1, 8]) {
      final child = reviewed.segments[mapId]!;
      final candidate = child.activeCandidates.first;
      final named = child.editMetadata(
          candidateId: candidate.candidateId,
          expectedCandidateHash: candidate.canonicalHash,
          expectedSessionHash: child.canonicalHash,
          name: 'Carte $mapId revue',
          category: AssetCategory.nature);
      final current = named.activeCandidates.first;
      final approved = named.decide(
          candidateId: current.candidateId,
          expectedCandidateHash: current.canonicalHash,
          expectedSessionHash: named.canonicalHash,
          action: ReviewAction.approve,
          humanConfirmed: true);
      reviewed = reviewed.replaceSegment(
          sourceMapId: mapId,
          next: approved,
          expectedSetHash: reviewed.canonicalHash,
          expectedSegmentHash: child.canonicalHash);
    }
    final stored = await harness.save(initial, reviewSet: reviewed);
    final fresh = harness.newWorkflow();
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored, workflow: fresh);
    expect(prepared.reviewSet!.toJson(), reviewed.toJson());
    expect(prepared.reviewSet!.segments.keys, [1, 8]);
    expect(prepared.approvedCandidateHashes, hasLength(2));
    expect(prepared.assetLibrary!.candidateBindings, hasLength(2));
    expect(fresh.state.approval, isNull);
    await harness.expectSavedUnchanged(stored);
    await harness.expectSourceUnchanged();
    expect(harness.writeStages, isEmpty);
  }, skip: !Platform.isMacOS);

  test(
      'segmented resume regenerates the seed mode before restoring a global mode change',
      () async {
    final harness = await _ResumeHarness.create(selected: [1, 8]);
    final initial = await harness.prepare();
    final set = initial.reviewSet!;
    final changed = set.changeOutputMode(
        outputMode: AssetOutputMode.sharedAtlas,
        expectedSetHash: set.canonicalHash);
    expect(changed.seedOutputMode, AssetOutputMode.standaloneObjects);
    final stored = await harness.save(initial, reviewSet: changed);
    final fresh = await ConverterReviewSessionResumer.resume(
        stored: stored, workflow: harness.newWorkflow());
    expect(fresh.reviewSet!.toJson(), changed.toJson());
    expect(fresh.settings.assetOutputMode, AssetOutputMode.sharedAtlas);
    expect(fresh.reviewSet!.seedOutputMode, AssetOutputMode.standaloneObjects);
    expect(fresh.approvedCandidateHashes, isEmpty);
    await harness.expectSavedUnchanged(stored);
    await harness.expectSourceUnchanged();
  }, skip: !Platform.isMacOS);

  test('AC-10 resumes exact review history in two fresh workflows', () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final reviewed = harness.approveCandidate(initial.reviewSet!);
    final stored = await harness.save(initial, reviewSet: reviewed);
    await harness.first.dispose();

    for (var iteration = 0; iteration < 2; iteration++) {
      final fresh = harness.newWorkflow();
      final reopened = await harness.store.load(stored.reviewSet.sessionId);
      final prepared = await ConverterReviewSessionResumer.resume(
          stored: reopened!, workflow: fresh);
      expect(prepared.reviewSet!.toJson(), reviewed.toJson());
      expect(prepared.assetCandidates.map((candidate) => candidate.toJson()),
          reviewed.activeCandidates.map((candidate) => candidate.toJson()));
      expect(
          prepared.approvedCandidateHashes, reviewed.approvedCandidateHashes);
      expect(prepared.assetLibrary!.candidateBindings, hasLength(1));
      expect(fresh.state.approval, isNull);
      expect(fresh.state.result, isNull);
      expect(fresh.state.isBusy, isFalse);
      await harness.expectSavedUnchanged(stored);
      await fresh.dispose();
    }
    await harness.expectSourceUnchanged();
    expect(harness.writeStages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('AC-10 resumes saved corrections with expired object approval',
      () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final approved = harness.approveCandidate(initial.reviewSet!);
    final stored = await harness.save(initial, reviewSet: approved);
    final candidate = approved.activeCandidates.singleWhere(
        (c) => approved.approvedCandidateHashes.containsKey(c.candidateId));
    final selectedMapId = approved.segments.entries
        .firstWhere((e) => e.value.activeCandidates
            .any((c) => c.candidateId == candidate.candidateId))
        .key;
    final segment = approved.segments[selectedMapId]!;
    final editedSegment = segment.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: segment.canonicalHash,
        name: 'Arbre corrigé après sauvegarde');
    final edited = approved.replaceSegment(
        sourceMapId: selectedMapId,
        next: editedSegment,
        expectedSetHash: approved.canonicalHash,
        expectedSegmentHash: segment.canonicalHash);
    final saved = await harness.store.compareAndSwap(
        reviewSet: edited,
        resumeSettings: stored.resumeSettings,
        expectedStoredRevision: stored.storedRevision,
        expectedCanonicalHash: stored.canonicalHash);
    final fresh = harness.newWorkflow();
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: saved, workflow: fresh);
    expect(saved.storedRevision, 2);
    expect(prepared.reviewSet!.canonicalHash, edited.canonicalHash);
    expect(
        prepared.assetCandidates
            .singleWhere((c) => c.candidateId == candidate.candidateId)
            .name,
        'Arbre corrigé après sauvegarde');
    expect(prepared.approvedCandidateHashes, isEmpty);
    expect(prepared.assetLibrary, isNull);
    expect(fresh.state.approval, isNull);
    await harness.expectSavedUnchanged(saved);
    await harness.expectSourceUnchanged();
  }, skip: !Platform.isMacOS);

  test('AC-10 keeps the undo cursor and the redo branch after reopening',
      () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final reviewed = harness.approveCandidate(initial.reviewSet!);
    final mapId = reviewed.segments.keys.first;
    final segment = reviewed.segments[mapId]!;
    final undone = reviewed.replaceSegment(
        sourceMapId: mapId,
        next: segment.undo(expectedSessionHash: segment.canonicalHash),
        expectedSetHash: reviewed.canonicalHash,
        expectedSegmentHash: segment.canonicalHash);
    final stored = await harness.save(initial, reviewSet: undone);
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored, workflow: harness.newWorkflow());
    final resumed = prepared.reviewSet!;
    expect(resumed.toJson(), undone.toJson());
    final resumedSegment = resumed.segments[mapId]!;
    final redone = resumed.replaceSegment(
        sourceMapId: mapId,
        next: resumedSegment.redo(
            expectedSessionHash: resumedSegment.canonicalHash),
        expectedSetHash: resumed.canonicalHash,
        expectedSegmentHash: resumedSegment.canonicalHash);
    expect(redone.activeCandidates.map((candidate) => candidate.toJson()),
        reviewed.activeCandidates.map((candidate) => candidate.toJson()));
    expect(
        redone.activeDecisions.decisions.map((decision) => decision.toJson()),
        reviewed.activeDecisions.decisions
            .map((decision) => decision.toJson()));
    expect(redone.approvedCandidateHashes, reviewed.approvedCandidateHashes);
    expect(redone.revision, greaterThan(resumed.revision));
    await harness.expectSavedUnchanged(stored);
  }, skip: !Platform.isMacOS);

  test(
      'AC-10 rescans a reselected identical source without rewriting saved paths',
      () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final stored = await harness.save(initial);
    final relocated = '${harness.root.path}/reselected-source';
    for (final entry in harness.fixture.sourceBytes.entries) {
      final file = File('$relocated/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: true);
    }
    await Directory(harness.sourcePath)
        .rename('${harness.root.path}/old-source');
    final fresh = harness.newWorkflow();
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored, workflow: fresh, sourceRootPath: relocated);
    expect(prepared.sourceSnapshotHash, stored.reviewSet.sourceSnapshotHash);
    expect(fresh.state.source!.rootPath, relocated);
    expect(fresh.state.source!.logicalProjectNamespace,
        stored.reviewSet.logicalProjectNamespace);
    expect(stored.resumeSettings.sourceRootPath, harness.sourcePath);
    await harness.expectSavedUnchanged(stored);
  }, skip: !Platform.isMacOS);

  test('AC-10 reuses the exact persisted scan and normalization policies',
      () async {
    final policy = SourceScanPolicy(excludedSegments: [
      ...SourceScanPolicy().excludedSegments,
      'scratch',
    ]);
    final harness = await _ResumeHarness.create(policy: policy);
    final ignored = File('${harness.sourcePath}/scratch/ignored.bin');
    await ignored.parent.create();
    await ignored.writeAsBytes([1, 3, 7]);
    await harness.scan();
    final initial = await harness.prepare(
        normalizationLimits: const SourceNormalizationLimits(maxMaps: 10),
        writeLimits: const NativeWriteLimits(maxMutations: 64));
    final stored = await harness.save(initial);
    final fresh = harness.newWorkflow();
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored, workflow: fresh);
    expect(fresh.state.source!.policy.canonicalHash, policy.canonicalHash);
    expect(prepared.sourceSnapshotHash, initial.sourceSnapshotHash);
    expect(prepared.settings.normalizationLimits.maxMaps, 10);
    expect(prepared.settings.writeLimits.maxMutations, 64);
    expect(
        fresh.state.snapshot!.entries
            .any((entry) => entry.relativePath.startsWith('scratch/')),
        isFalse);
    await harness.expectSavedUnchanged(stored);
  }, skip: !Platform.isMacOS);

  for (final disposition in [
    LiteralDependencyDisposition.include,
    LiteralDependencyDisposition.excludeStudy
  ]) {
    test('AC-10 rebinds ${disposition.name} to the actual fresh dependency',
        () async {
      final harness = await _ResumeHarness.create(maps: [
        LiteralFixtureMap(id: 1),
        LiteralFixtureMap(id: 8, warpParameters: [
          [0, 1, 1, 0, 2, 0]
        ]),
      ], selected: [
        8
      ]);
      final unresolved = await harness.prepare();
      final decision = harness.decision(
          unresolved, unresolved.composition.dependencies.single, disposition);
      final initial = await harness.prepare(decisions: [decision]);
      final stored = await harness.save(initial);
      final prepared = await ConverterReviewSessionResumer.resume(
          stored: stored, workflow: harness.newWorkflow());
      final rebound = prepared.settings.dependencyDecisions.single;
      final freshDependency = prepared.composition.dependencies.single;
      expect(rebound.locator.toJson(), freshDependency.locator.toJson());
      expect(rebound.canonicalHash, decision.canonicalHash);
      expect(prepared.composition.includedSourceMapIds,
          disposition == LiteralDependencyDisposition.include ? [1] : isEmpty);
      expect(prepared.reviewSet!.canonicalHash, stored.reviewSet.canonicalHash);
      await harness.expectSavedUnchanged(stored);
      await harness.expectSourceUnchanged();
    }, skip: !Platform.isMacOS);
  }

  test('AC-10 discovers nested included dependencies within the saved scope',
      () async {
    final harness = await _ResumeHarness.create(maps: [
      LiteralFixtureMap(id: 1, warpParameters: [
        [0, 2, 1, 0, 2, 0]
      ]),
      LiteralFixtureMap(id: 2),
      LiteralFixtureMap(id: 8, warpParameters: [
        [0, 1, 1, 0, 2, 0]
      ]),
    ], selected: [
      8
    ]);
    final unresolved = await harness.prepare();
    final first = harness.decision(
        unresolved,
        unresolved.composition.dependencies.single,
        LiteralDependencyDisposition.include);
    final intermediate = await harness.prepare(decisions: [first]);
    final second = harness.decision(
        intermediate,
        intermediate.composition.dependencies
            .singleWhere((d) => d.targetSourceMapId == 2),
        LiteralDependencyDisposition.excludeStudy);
    final initial = await harness.prepare(decisions: [first, second]);
    final stored = await harness.save(initial);
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored, workflow: harness.newWorkflow());
    expect(
        prepared.settings.dependencyDecisions
            .map((item) => item.canonicalHash)
            .toSet(),
        {first.canonicalHash, second.canonicalHash});
    expect(prepared.composition.selectedSourceMapIds, [8]);
    expect(prepared.composition.includedSourceMapIds, [1]);
    expect(prepared.composition.nativeMaps, hasLength(2));
    expect(prepared.reviewSet!.canonicalHash, stored.reviewSet.canonicalHash);
    await harness.expectSavedUnchanged(stored);
  }, skip: !Platform.isMacOS);

  for (final field in ['locatorHash', 'targetSourceMapId']) {
    test(
        'AC-10 rejects a foreign dependency $field without losing saved review',
        () async {
      final harness = await _ResumeHarness.create(maps: [
        LiteralFixtureMap(id: 1),
        LiteralFixtureMap(id: 8, warpParameters: [
          [0, 1, 1, 0, 2, 0]
        ]),
      ], selected: [
        8
      ]);
      final unresolved = await harness.prepare();
      final decision = harness.decision(
          unresolved,
          unresolved.composition.dependencies.single,
          LiteralDependencyDisposition.excludeStudy);
      final initial = await harness.prepare(decisions: [decision]);
      final receipt = LocalReviewDependencyDecision.fromDecision(decision);
      final foreign = LocalReviewDependencyDecision.fromJson({
        ...receipt.toJson(),
        field: field == 'locatorHash'
            ? canonicalHashOf('foreign locator').value
            : 12,
      });
      final stored = await harness.save(initial, dependencies: [foreign]);
      await expectLater(
          ConverterReviewSessionResumer.resume(
              stored: stored, workflow: harness.newWorkflow()),
          _throwsResume('workflow.resume.dependency_stale'));
      await harness.expectSavedUnchanged(stored);
      await harness.expectSourceUnchanged();
      expect(harness.writeStages, isEmpty);
    }, skip: !Platform.isMacOS);
  }

  for (final variant in ['missing', 'foreign']) {
    test(
        'AC-10 rejects a $variant profile acknowledgement without resetting review',
        () async {
      final harness = await _ResumeHarness.create();
      final initial = await harness.prepare();
      final ack = harness.acknowledgement(initial);
      final stored = await harness.save(initial,
          acknowledgement: variant == 'missing'
              ? null
              : LocalReviewProfileAcknowledgement.fromJson({
                  ...ack.toJson(),
                  'profileEvidenceHash':
                      canonicalHashOf('foreign profile').value,
                }),
          overrideAcknowledgement: true);
      await expectLater(
          ConverterReviewSessionResumer.resume(
              stored: stored, workflow: harness.newWorkflow()),
          _throwsResume('workflow.resume.profile_ack'));
      await harness.expectSavedUnchanged(stored);
    }, skip: !Platform.isMacOS);
  }

  test(
      'AC-10 rejects changed source bytes and leaves the stored document exact',
      () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final stored = await harness.save(initial);
    final readme = File('${harness.sourcePath}/README.md');
    await readme.writeAsBytes([
      ...harness.fixture.sourceBytes['README.md']!,
      ...utf8.encode('changed\n'),
    ], flush: true);
    await expectLater(
        ConverterReviewSessionResumer.resume(
            stored: stored, workflow: harness.newWorkflow()),
        _throwsResume('workflow.resume.source_stale'));
    await harness.expectSavedUnchanged(stored);
    expect(harness.writeStages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('AC-10 retains a readable session when the source becomes inaccessible',
      () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final stored = await harness.save(initial);
    await Directory(harness.sourcePath)
        .rename('${harness.root.path}/unavailable-source');
    await expectLater(
        ConverterReviewSessionResumer.resume(
            stored: stored, workflow: harness.newWorkflow()),
        throwsA(isA<ConverterWorkflowFailure>()));
    await harness.expectSavedUnchanged(stored);
    expect(harness.writeStages, isEmpty);
  }, skip: !Platform.isMacOS);

  test(
      'AC-10 asks for a new destination after it is created and retains review',
      () async {
    final harness = await _ResumeHarness.create();
    final initial = await harness.prepare();
    final stored = await harness.save(initial);
    final destination = await Directory(
            '${harness.output.path}/${stored.resumeSettings.folderName}')
        .create();
    final sentinel = File('${destination.path}/untouched');
    await sentinel.writeAsBytes([2, 5, 9]);
    await expectLater(
        ConverterReviewSessionResumer.resume(
            stored: stored, workflow: harness.newWorkflow()),
        _throwsResume('native.destination.exists'));
    await harness.expectSavedUnchanged(stored);
    expect(await sentinel.readAsBytes(), [2, 5, 9]);
    await harness.expectSourceUnchanged();
  }, skip: !Platform.isMacOS);
  test(
      'AC-10 resumes include and exclude after an explicit new destination choice',
      () async {
    final harness = await _ResumeHarness.create(maps: [
      LiteralFixtureMap(id: 1),
      LiteralFixtureMap(id: 2),
      LiteralFixtureMap(id: 8, warpParameters: [
        [0, 1, 1, 0, 2, 0],
        [0, 2, 1, 0, 2, 0],
      ]),
    ], selected: [
      8
    ]);
    final unresolved = await harness.prepare();
    final decisions = unresolved.composition.dependencies
        .map((dependency) => harness.decision(
            unresolved,
            dependency,
            dependency.targetSourceMapId == 1
                ? LiteralDependencyDisposition.include
                : LiteralDependencyDisposition.excludeStudy))
        .toList();
    final initial = await harness.prepare(decisions: decisions);
    final reviewed = harness.approveCandidate(initial.reviewSet!);
    final stored = await harness.save(initial, reviewSet: reviewed);
    final destination = await Directory(
            '${harness.output.path}/${stored.resumeSettings.folderName}')
        .create();
    final sentinel = File('${destination.path}/untouched');
    await sentinel.writeAsBytes([2, 5, 9]);
    await expectLater(
        ConverterReviewSessionResumer.resume(
            stored: stored, workflow: harness.newWorkflow()),
        _throwsResume('native.destination.exists'));
    final newParent =
        await Directory('${harness.root.path}/chosen-destination').create();
    final fresh = harness.newWorkflow();
    final prepared = await ConverterReviewSessionResumer.resume(
        stored: stored,
        workflow: fresh,
        destinationParentPath: newParent.path,
        folderName: 'explicitly-chosen-new-folder',
        projectName: 'Reprise nommée explicitement');
    expect(prepared.settings.parentPath, newParent.path);
    expect(prepared.settings.folderName, 'explicitly-chosen-new-folder');
    expect(prepared.settings.projectName, 'Reprise nommée explicitement');
    expect(
        prepared.settings.dependencyDecisions
            .map((item) => item.canonicalHash)
            .toSet(),
        decisions.map((item) => item.canonicalHash).toSet());
    expect(prepared.composition.includedSourceMapIds, [1]);
    expect(prepared.reviewSet!.canonicalHash, reviewed.canonicalHash);
    expect(prepared.settings.profileAcknowledgement.sourceSnapshotHash,
        stored.resumeSettings.profileAcknowledgement!.sourceSnapshotHash);
    expect(prepared.settings.profileAcknowledgement.profileEvidenceHash,
        stored.resumeSettings.profileAcknowledgement!.profileEvidenceHash);
    expect(prepared.settings.allowFirstFrameAutotiles,
        stored.resumeSettings.allowFirstFrameAutotiles);
    expect(fresh.state.source!.policy.canonicalHash,
        stored.resumeSettings.sourceScanPolicy.canonicalHash);
    expect(fresh.state.approval, isNull);
    expect(fresh.state.result, isNull);
    expect(await sentinel.readAsBytes(), [2, 5, 9]);
    expect(await newParent.list().toList(), isEmpty);
    await harness.expectSavedUnchanged(stored);
    await harness.expectSourceUnchanged();
    expect(harness.writeStages, isEmpty);
  }, skip: !Platform.isMacOS);
}

Matcher _throwsResume(String code) => throwsA(isA<ConverterWorkflowFailure>()
    .having((error) => error.code, 'code', code));

final class _ResumeHarness {
  _ResumeHarness(this.root, this.output, this.fixture, this.selected,
      this.policy, this.first, this.store, this.workflows, this.writeStages);

  final Directory root, output;
  final LiteralTileFixture fixture;
  final List<int> selected;
  final SourceScanPolicy policy;
  final ConverterWorkflow first;
  final LocalReviewSessionStore store;
  final List<ConverterWorkflow> workflows;
  final List<NativeWriteStage> writeStages;
  String get sourcePath => fixture.sourceRootPath!;

  static Future<_ResumeHarness> create(
      {List<LiteralFixtureMap>? maps,
      List<int> selected = const [1, 8, 12, 20, 21],
      SourceScanPolicy? policy}) async {
    final root = await Directory.systemTemp.createTemp('ac10-resume-');
    final output = await Directory('${root.path}/output').create();
    final fixture = maps == null
        ? (await OriginalAssetFixture.create(
                sourceRootPath: '${root.path}/source'))
            .literalFixture
        : await LiteralTileFixture.create(
            sourceRootPath: '${root.path}/source', maps: maps);
    final stages = <NativeWriteStage>[];
    final first = ConverterWorkflow(nativeWriteCheckpoint: (stage, _, __) {
      stages.add(stage);
    });
    final harness = _ResumeHarness(
        root,
        output,
        fixture,
        selected,
        policy ?? SourceScanPolicy(),
        first,
        LocalReviewSessionStore(rootPath: '${root.path}/sessions'),
        [first],
        stages);
    addTearDown(() async {
      for (final workflow in harness.workflows) {
        await workflow.dispose();
      }
      await root.delete(recursive: true);
    });
    await harness.scan();
    return harness;
  }

  Future<SourceSnapshot> scan() => first.scanSource(ConverterSourceSelection(
      rootPath: sourcePath,
      logicalProjectNamespace: ConverterId('ac10-resume-source'),
      policy: policy));

  ConverterWorkflow newWorkflow() {
    final fresh = ConverterWorkflow(nativeWriteCheckpoint: (stage, _, __) {
      writeStages.add(stage);
    });
    workflows.add(fresh);
    return fresh;
  }

  Future<PreparedStudy> prepare(
      {List<LiteralDependencyDecision> decisions = const [],
      SourceNormalizationLimits normalizationLimits =
          const SourceNormalizationLimits(),
      NativeWriteLimits writeLimits = const NativeWriteLimits()}) {
    final snapshot = first.state.snapshot!;
    first.updateSettings(ConverterStudySettings(
        projectName: 'Étude originale de reprise',
        parentPath: output.path,
        folderName: 'resumed-library',
        selectedSourceMapIds: selected,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason: 'Controlled original study source.'),
        dependencyDecisions: decisions,
        assetOutputMode: AssetOutputMode.standaloneObjects,
        normalizationLimits: normalizationLimits,
        writeLimits: writeLimits));
    return first.prepareStudy();
  }

  LocalReviewProfileAcknowledgement acknowledgement(PreparedStudy prepared) =>
      LocalReviewProfileAcknowledgement(
          sourceSnapshotHash: prepared.sourceSnapshotHash,
          profileEvidenceHash: prepared.profileEvidenceHash,
          humanConfirmed:
              prepared.settings.profileAcknowledgement.humanConfirmed,
          reason: prepared.settings.profileAcknowledgement.reason);

  Future<StoredReviewSession> save(PreparedStudy prepared,
          {ConverterAssetReviewSet? reviewSet,
          List<LocalReviewDependencyDecision>? dependencies,
          LocalReviewProfileAcknowledgement? acknowledgement,
          bool overrideAcknowledgement = false}) =>
      store.create(
          reviewSet: reviewSet ?? prepared.reviewSet!,
          resumeSettings: LocalReviewResumeSettings(
              sourceRootPath: sourcePath,
              destinationParentPath: output.path,
              projectName: prepared.settings.projectName,
              folderName: prepared.settings.folderName,
              allowFirstFrameAutotiles:
                  prepared.settings.allowFirstFrameAutotiles,
              profileAcknowledgement: overrideAcknowledgement
                  ? acknowledgement
                  : this.acknowledgement(prepared),
              dependencyDecisions: dependencies ??
                  prepared.settings.dependencyDecisions
                      .map(LocalReviewDependencyDecision.fromDecision)
                      .toList(),
              sourceScanPolicy: policy,
              normalizationLimits: prepared.settings.normalizationLimits,
              writeLimits: prepared.settings.writeLimits));

  LiteralDependencyDecision decision(
          PreparedStudy prepared,
          LiteralMapDependency dependency,
          LiteralDependencyDisposition disposition) =>
      LiteralDependencyDecision(
          sourceSnapshotHash: prepared.sourceSnapshotHash,
          selectionHash:
              literalSelectionHash(prepared.normalizedSource, selected),
          locator: dependency.locator,
          targetSourceMapId: dependency.targetSourceMapId!,
          decision: disposition);

  ConverterAssetReviewSet approveCandidate(ConverterAssetReviewSet reviewSet) {
    final entry = reviewSet.segments.entries
        .firstWhere((e) => e.value.activeCandidates.isNotEmpty);
    final session = entry.value;
    final candidate = session.activeCandidates.first;
    final named = session.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Arbre relu',
        category: AssetCategory.nature);
    final current = named.activeCandidates.first;
    final approved = named.decide(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: named.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    return reviewSet.replaceSegment(
        sourceMapId: entry.key,
        next: approved,
        expectedSetHash: reviewSet.canonicalHash,
        expectedSegmentHash: session.canonicalHash);
  }

  Future<void> expectSavedUnchanged(StoredReviewSession stored) async {
    final reopened = await store.load(stored.reviewSet.sessionId);
    expect(reopened!.toJson(), stored.toJson());
    expect(reopened.canonicalHash, stored.canonicalHash);
    expect(reopened.storedRevision, stored.storedRevision);
  }

  Future<void> expectSourceUnchanged() async {
    for (final entry in fixture.sourceBytes.entries) {
      expect(await File('$sourcePath/${entry.key}').readAsBytes(), entry.value);
    }
  }
}
