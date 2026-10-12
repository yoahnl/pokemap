import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:test/test.dart';

import 'support/original_asset_fixture.dart';

void main() {
  late _AssetWorkflow harness;
  setUp(() async => harness = await _AssetWorkflow.create());
  tearDown(() async => harness.close());

  test('AC-10 initial preparation creates an exact durable review seed',
      () async {
    final prepared = await harness.prepare();
    expect(prepared.reviewSession, isNotNull);
    expect(prepared.reviewSession!.baseProposalHashes, {
      for (final candidate in prepared.assetProposals!.candidates)
        candidate.candidateId: candidate.canonicalHash,
    });
    expect(prepared.reviewSession!.frames.first.outputMode,
        AssetOutputMode.sharedAtlas);
    expect(prepared.reviewSession!.activeDecisions.decisions, isEmpty);
    expect(prepared.settings.toJson().containsKey('assetReviews'), isFalse);
    expect(harness.stages, isEmpty);
  });

  test('AC-10 corrected geometry survives preparation and native readback',
      () async {
    final literal =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    var session = harness.seed(literal);
    final tree = session.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    session = session.editMetadata(
        candidateId: tree.candidateId,
        expectedCandidateHash: tree.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Arbre corrigé',
        category: AssetCategory.nature);
    final named = session.activeCandidates
        .singleWhere((c) => c.candidateId == tree.candidateId);
    final parts = named.parts.take(5).map((p) => p.toJson()).toList();
    session = session.changeGeometry(
        candidateId: named.candidateId,
        expectedCandidateHash: named.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        geometry: AssetReviewGeometry(
            parts: parts,
            canvasWidth: 64,
            canvasHeight: 96,
            anchorX: 16,
            anchorY: 96,
            anchorConvention: AnchorConvention.explicit));
    final corrected = session.activeCandidates
        .singleWhere((c) => c.candidateId == tree.candidateId);
    session = session.decide(
        candidateId: corrected.candidateId,
        expectedCandidateHash: corrected.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    final reloaded = AssetReviewSession.fromJson(session.toJson());
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, session: reloaded);
    final current = prepared.assetCandidates
        .singleWhere((c) => c.candidateId == tree.candidateId);
    expect(current.parts.map((p) => p.toJson()), parts);
    expect(current.name, 'Arbre corrigé');
    expect(current.anchor.x, 16);
    expect(prepared.assetLibrary!.candidateBindings, hasLength(1));
    expect(prepared.composition.nativeMaps, literal.composition.nativeMaps);
    final result =
        await harness.workflow.writeApproved(harness.approve(prepared));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [result.receipt.stagingRoot], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      expect(native.manifest.elements, hasLength(1));
      for (final map in literal.composition.nativeMaps.values) {
        expect(native.mapById(map.id), map);
      }
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    await harness.expectSourceUnchanged();
  });

  test('AC-10 metadata correction expires approval without losing the object',
      () async {
    final literal =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    var session = harness.seed(literal);
    final candidate = session.activeCandidates.first;
    session = harness.decide(session, candidate,
        name: 'Objet approuvé', category: AssetCategory.nature);
    final first = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, session: session);
    final oldApproval = harness.approve(first);
    final approved = session.activeCandidates
        .singleWhere((c) => c.candidateId == candidate.candidateId);
    session = session.editMetadata(
        candidateId: approved.candidateId,
        expectedCandidateHash: approved.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Objet à revalider');
    final second = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, session: session);
    expect(
        second.assetCandidates
            .singleWhere((c) => c.candidateId == candidate.candidateId)
            .name,
        'Objet à revalider');
    expect(second.approvedCandidateHashes, isEmpty);
    expect(second.assetLibrary, isNull);
    await expectLater(harness.workflow.writeApproved(oldApproval),
        throwsA(isA<ConverterWorkflowFailure>()));
    expect(harness.stages, isEmpty);
  });

  test('AC-10 union exports current children without historical decisions',
      () async {
    final literal =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    var session = harness.seed(literal);
    final tree = session.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    final house = session.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 8));
    session = harness.decide(session, tree);
    final parent = session.activeCandidates
        .singleWhere((c) => c.candidateId == tree.candidateId);
    session = session.unionCandidates(
        expectedSessionHash: session.canonicalHash,
        candidateId: ConverterId('review-union'),
        inputs: [
          AssetUnionInput(
              candidateId: parent.candidateId,
              expectedCandidateHash: parent.canonicalHash,
              offsetX: 0,
              offsetY: 0),
          AssetUnionInput(
              candidateId: house.candidateId,
              expectedCandidateHash: house.canonicalHash,
              offsetX: 64,
              offsetY: 0),
        ],
        name: 'Groupe corrigé',
        category: AssetCategory.object);
    final union = session.activeCandidates
        .singleWhere((c) => c.candidateId.value == 'review-union');
    session = session.decide(
        candidateId: union.candidateId,
        expectedCandidateHash: union.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, session: session);
    expect(prepared.assetCandidates.map((c) => c.candidateId),
        isNot(contains(tree.candidateId)));
    expect(prepared.assetCandidates.map((c) => c.candidateId),
        contains(union.candidateId));
    expect(prepared.reviewDecisions.decisions.map((d) => d.candidateId),
        isNot(contains(tree.candidateId)));
    expect(prepared.assetLibrary!.candidateBindings, hasLength(1));
    expect(prepared.canApprove, isTrue);
    harness.approve(prepared);
  });

  test('AC-10 fresh source rejects a session with a different generation',
      () async {
    final literal = await harness.prepare();
    final seed = harness.seed(literal);
    final forged = AssetReviewSession.fromJson({
      ...seed.toJson(),
      'proposalGenerationHash': '0' * 64,
    });
    await expectLater(
        harness.prepare(session: forged),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.review_session.stale')));
    expect(harness.stages, isEmpty);
  });

  test(
      'AC-10 output mode changes retain corrections and reattest the seed mode',
      () async {
    final literal = await harness.prepare();
    var session = harness.seed(literal);
    final candidate = session.activeCandidates.first;
    session = session.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Correction conservée',
        category: AssetCategory.object);
    session = session.changeOutputMode(
        expectedSessionHash: session.canonicalHash,
        outputMode: AssetOutputMode.standaloneObjects);
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, session: session);
    expect(
        prepared.assetCandidates
            .singleWhere((c) => c.candidateId == candidate.candidateId)
            .name,
        'Correction conservée');
    expect(prepared.reviewSession!.frames.first.outputMode,
        AssetOutputMode.sharedAtlas);
    expect(
        prepared.reviewSession!.outputMode, AssetOutputMode.standaloneObjects);
    expect(prepared.approvedCandidateHashes, isEmpty);
    expect(prepared.composition.nativeMaps, literal.composition.nativeMaps);
  });

  test('AC-10 a destination rename does not discard source-bound review',
      () async {
    final literal = await harness.prepare();
    var session = harness.seed(literal);
    final candidate = session.activeCandidates.first;
    session = session.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Nom conservé',
        category: AssetCategory.nature);
    final prepared = await harness.prepare(
        session: session,
        projectName: 'Projet renommé',
        folderName: 'another-destination');
    expect(
        prepared.assetCandidates
            .singleWhere((c) => c.candidateId == candidate.candidateId)
            .name,
        'Nom conservé');
    expect(prepared.settings.projectName, 'Projet renommé');
    expect(prepared.settings.folderName, 'another-destination');
    expect(prepared.reviewSession!.canonicalHash, session.canonicalHash);
  });

  test('unreviewed proposals leave the literal draft unchanged', () async {
    final prepared = await harness.prepare();
    expect(prepared.assetProposals!.candidates, isNotEmpty);
    expect(
        prepared.assetCandidates
            .every((c) => c.state == CandidateState.needsReview),
        isTrue);
    expect(prepared.approvedCandidateHashes, isEmpty);
    expect(prepared.reviewDecisions.decisions, isEmpty);
    expect(prepared.assetLibrary, isNull);
    expect(prepared.nativeDraft!.canonicalHash,
        prepared.composition.draft!.canonicalHash);
    expect(prepared.canApprove, isTrue);
    expect(harness.stages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
    await harness.expectSourceUnchanged();
  });

  test('valid wider native budgets retain bounded local recognition', () async {
    final prepared = await harness.prepare(
        limits: const NativeWriteLimits(
      maxTotalArtifactBytes: 134217728,
      jsonLimits: ContractLimits(maxNodes: 2000000, maxTextCodeUnits: 8388608),
    ));
    expect(prepared.canApprove, isTrue);
    expect(prepared.assetProposals!.candidates, isNotEmpty);
    expect(
        prepared.assetProposalDiagnostics
            .any((d) => d.code == 'asset.proposal.limits'),
        isFalse);
    expect(prepared.nativeDraft!.canonicalHash,
        prepared.composition.draft!.canonicalHash);
  });

  test(
      'approved standalone objects enter the native library without changing maps',
      () async {
    final literal =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    final tree = literal.assetProposals!.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        session: harness.decide(harness.seed(literal), tree));
    expect(prepared.canApprove, isTrue);
    expect(prepared.assetLibrary!.canExport, isTrue);
    expect(prepared.assetLibrary!.candidateBindings, hasLength(1));
    expect(
        prepared.assetCandidates
            .singleWhere((c) => c.candidateId == tree.candidateId)
            .name,
        'Arbre original');
    expect(prepared.nativeDraft!.sourceArtifacts, isNotEmpty);
    expect(prepared.composition.compositionHash,
        literal.composition.compositionHash);
    expect(prepared.composition.nativeMaps, literal.composition.nativeMaps);
    expect(prepared.nativeDraft!.compositionEvidence['composition'],
        literal.composition.draft!.compositionEvidence['composition']);
    expect(
        prepared.previewPlan!.operations
            .where((o) => o.sourceEntityIds.contains(tree.candidateId))
            .every((o) => o.domain == OperationDomain.assets),
        isTrue);
    final approval = harness.approve(prepared);
    final result = await harness.workflow.writeApproved(approval);
    expect(result.receipt.verified, isTrue);
    expect(result.published, isFalse);
    expect(result.playableCertified, isFalse);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [result.receipt.stagingRoot], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      for (final map in prepared.composition.nativeMaps.values) {
        expect(native.mapById(map.id), map);
      }
      expect(
          native.manifest.elements.map((e) => e.id),
          contains(
              prepared.assetLibrary!.candidateBindings.single.nativeElementId));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    await harness.expectSourceUnchanged();
  });

  test('combined literal and witness pixels are refused before approval',
      () async {
    const limits = NativeWriteLimits(maxImagePixels: 71680);
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, limits: limits);
    final tree = prepared.assetProposals!.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    await expectLater(
      harness.prepare(
          mode: AssetOutputMode.standaloneObjects,
          limits: limits,
          session: harness.decide(harness.seed(prepared), tree)),
      throwsA(isA<ConverterWorkflowFailure>()
          .having((e) => e.code, 'code', 'native.quota.image')),
    );
    expect(harness.workflow.state.prepared, isNull);
    expect(harness.workflow.state.approval, isNull);
    expect(harness.stages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
  });

  test(
      'disjoint mixed-priority groups require a fresh explicit standalone choice',
      () async {
    final literal = await harness.prepare();
    final house = literal.assetProposals!.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 8));
    var session = harness.decide(harness.seed(literal), house,
        category: AssetCategory.building);
    final blocked = await harness.prepare(session: session);
    expect(
        blocked.assetLibrary!.diagnostics.any((d) => d.blocksExport), isTrue);
    expect(blocked.nativeDraft, isNull);
    expect(blocked.canApprove, isFalse);
    expect(harness.stages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
    expect(
        () => harness.prepare(
            mode: AssetOutputMode.standaloneObjects, session: session),
        throwsA(isA<ConverterWorkflowFailure>()));
    session = session.changeOutputMode(
        expectedSessionHash: session.canonicalHash,
        outputMode: AssetOutputMode.standaloneObjects);
    final fresh = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, session: session);
    expect(fresh.approvedCandidateHashes, isEmpty);
    final freshHouse = session.activeCandidates
        .singleWhere((c) => c.candidateId == house.candidateId);
    final approved = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        session: harness.decide(session, freshHouse,
            category: AssetCategory.building));
    expect(approved.canApprove, isTrue);
    expect(approved.composition.nativeMaps, literal.composition.nativeMaps);
    expect(
        approved.assetCandidates
            .singleWhere((c) => c.candidateId == freshHouse.candidateId)
            .parts
            .map((p) => p.sourcePriority)
            .toSet(),
        {0, 2});
  });

  test('keep literal is an explicit decision with no library consumption',
      () async {
    final literal = await harness.prepare();
    final proposal = literal.assetProposals!.candidates.first;
    final prepared = await harness.prepare(
        session: harness.decide(harness.seed(literal), proposal,
            action: ReviewAction.keepLiteral));
    expect(prepared.reviewDecisions.decisions.single.action,
        ReviewAction.keepLiteral);
    expect(prepared.assetLibrary, isNull);
    expect(prepared.nativeDraft!.canonicalHash,
        literal.nativeDraft!.canonicalHash);
    expect(prepared.approvedCandidateHashes, isEmpty);
    expect(
        prepared.assetCandidates
            .singleWhere((c) => c.candidateId == proposal.candidateId)
            .state,
        CandidateState.keepLiteral);
    harness.approve(prepared);
  });

  test('editing a reviewed name or invalidating the UI revokes exact approval',
      () async {
    final literal =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    final proposal = literal.assetProposals!.candidates.first;
    final first = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        session: harness.decide(harness.seed(literal), proposal));
    final approval = harness.approve(first);
    harness.workflow.invalidatePrepared();
    expect(harness.workflow.state.prepared, isNull);
    expect(harness.workflow.state.approval, isNull);
    await expectLater(harness.workflow.writeApproved(approval),
        throwsA(isA<ConverterWorkflowFailure>()));
    final second = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        session: harness.decide(harness.seed(literal), proposal,
            name: 'Arbre renommé'));
    expect(second.preparationHash, isNot(first.preparationHash));
    expect(second.reviewDecisions.canonicalHash,
        isNot(first.reviewDecisions.canonicalHash));
    expect(second.assetLibrary!.compositionHash,
        isNot(first.assetLibrary!.compositionHash));
    expect(
        second.composition.compositionHash, first.composition.compositionHash);
    expect(harness.stages, isEmpty);
  });
}

final class _AssetWorkflow {
  _AssetWorkflow(
      this.root, this.output, this.fixture, this.workflow, this.stages);
  final Directory root, output;
  final OriginalAssetFixture fixture;
  final ConverterWorkflow workflow;
  final List<NativeWriteStage> stages;

  static Future<_AssetWorkflow> create() async {
    final root =
        await Directory.systemTemp.createTemp('ac08-original-workflow-');
    final output = await Directory('${root.path}/output').create();
    final fixture = await OriginalAssetFixture.create(
        sourceRootPath: '${root.path}/source');
    final stages = <NativeWriteStage>[];
    final workflow = ConverterWorkflow(
        nativeWriteCheckpoint: (stage, stagingRoot, projectPath) {
      stages.add(stage);
    });
    await workflow.scanSource(ConverterSourceSelection(
        rootPath: fixture.literalFixture.sourceRootPath!,
        logicalProjectNamespace: ConverterId('original-asset-workflow')));
    return _AssetWorkflow(root, output, fixture, workflow, stages);
  }

  Future<PreparedStudy> prepare(
      {AssetOutputMode mode = AssetOutputMode.sharedAtlas,
      AssetReviewSession? session,
      String projectName = 'Original asset library study',
      String folderName = 'original-library',
      NativeWriteLimits limits = const NativeWriteLimits()}) {
    final snapshot = workflow.state.snapshot!;
    workflow.updateSettings(ConverterStudySettings(
      projectName: projectName,
      parentPath: output.path,
      folderName: folderName,
      selectedSourceMapIds: const [1, 8, 12, 20, 21],
      profileAcknowledgement: SourceStudyAcknowledgement(
          sourceSnapshotHash: snapshot.canonicalHash,
          profileEvidenceHash: snapshot.profile.evidenceHash,
          humanConfirmed: true,
          reason: 'Original controlled fixture; study only.'),
      assetOutputMode: mode,
      reviewSession: session,
      writeLimits: limits,
    ));
    return workflow.prepareStudy();
  }

  AssetReviewSession seed(PreparedStudy prepared) {
    final proposals = prepared.assetProposals!;
    return AssetReviewSession.create(
        sessionId: ConverterId('original-review-session'),
        logicalProjectNamespace:
            prepared.normalizedSource.snapshot.logicalProjectNamespace,
        sourceSnapshotHash: prepared.sourceSnapshotHash,
        selectedSourceMapIds: prepared.settings.selectedSourceMapIds,
        outputMode: prepared.settings.assetOutputMode,
        proposalGenerationHash: canonicalHashOf({
          'kind': 'reviewProposalGeneration',
          'version': 1,
          'sourceSnapshotHash': proposals.sourceSnapshotHash.value,
          'normalizedSourceHash': proposals.normalizedSourceHash.value,
          'selectedSourceMapIds': prepared.settings.selectedSourceMapIds,
          'outputMode': prepared.settings.assetOutputMode.name,
          'candidateHashes':
              proposals.candidates.map((c) => c.canonicalHash.value).toList(),
          'placementClaims': {
            for (final e in proposals.placementClaims.entries)
              e.key.value: e.value.map((claim) => claim.toJson()).toList(),
          },
          'sourceImages':
              proposals.sourceImages.map((s) => s.toJson()).toList(),
          'diagnostics': proposals.diagnostics.map((d) => d.toJson()).toList(),
        }),
        candidates: proposals.candidates,
        placementClaims: proposals.placementClaims,
        sourceMaps: prepared.normalizedSource.maps);
  }

  AssetReviewSession decide(
      AssetReviewSession session, AssetCandidate candidate,
      {String name = 'Arbre original',
      AssetCategory category = AssetCategory.nature,
      ReviewAction action = ReviewAction.approve}) {
    final named = session.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: name,
        category: category);
    final current = named.activeCandidates
        .singleWhere((c) => c.candidateId == candidate.candidateId);
    return named.decide(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: named.canonicalHash,
        action: action,
        humanConfirmed: true);
  }

  StudyApproval approve(PreparedStudy prepared) => workflow.approvePrepared(
      sessionRevision: prepared.sessionRevision,
      preparationHash: prepared.preparationHash,
      humanConfirmed: true);

  Future<void> expectSourceUnchanged() async {
    for (final entry in fixture.literalFixture.sourceBytes.entries) {
      expect(
          await File('${fixture.literalFixture.sourceRootPath}/${entry.key}')
              .readAsBytes(),
          entry.value);
    }
  }

  Future<void> close() async {
    await workflow.dispose();
    await root.delete(recursive: true);
  }
}
