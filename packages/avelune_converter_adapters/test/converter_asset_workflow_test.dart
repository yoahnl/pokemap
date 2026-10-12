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
        reviews: [harness.review(tree)]);
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
          reviews: [harness.review(tree)]),
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
    final blocked = await harness.prepare(
        reviews: [harness.review(house, category: AssetCategory.building)]);
    expect(
        blocked.assetLibrary!.diagnostics.any((d) => d.blocksExport), isTrue);
    expect(blocked.nativeDraft, isNull);
    expect(blocked.canApprove, isFalse);
    expect(harness.stages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
    await expectLater(
        harness.prepare(
            mode: AssetOutputMode.standaloneObjects,
            reviews: [harness.review(house)]),
        throwsA(isA<ConverterWorkflowFailure>()));
    final fresh =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    final freshHouse = fresh.assetProposals!.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 8));
    final approved = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        reviews: [
          harness.review(freshHouse, category: AssetCategory.building)
        ]);
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
        reviews: [harness.review(proposal, action: ReviewAction.keepLiteral)]);
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
        reviews: [harness.review(proposal)]);
    final approval = harness.approve(first);
    harness.workflow.invalidatePrepared();
    expect(harness.workflow.state.prepared, isNull);
    expect(harness.workflow.state.approval, isNull);
    await expectLater(harness.workflow.writeApproved(approval),
        throwsA(isA<ConverterWorkflowFailure>()));
    final second = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        reviews: [harness.review(proposal, name: 'Arbre renommé')]);
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
      List<ConverterAssetReview> reviews = const [],
      NativeWriteLimits limits = const NativeWriteLimits()}) {
    final snapshot = workflow.state.snapshot!;
    workflow.updateSettings(ConverterStudySettings(
      projectName: 'Original asset library study',
      parentPath: output.path,
      folderName: 'original-library',
      selectedSourceMapIds: const [1, 8, 12, 20, 21],
      profileAcknowledgement: SourceStudyAcknowledgement(
          sourceSnapshotHash: snapshot.canonicalHash,
          profileEvidenceHash: snapshot.profile.evidenceHash,
          humanConfirmed: true,
          reason: 'Original controlled fixture; study only.'),
      assetOutputMode: mode,
      assetReviews: reviews,
      writeLimits: limits,
    ));
    return workflow.prepareStudy();
  }

  ConverterAssetReview review(AssetCandidate candidate,
          {String name = 'Arbre original',
          AssetCategory category = AssetCategory.nature,
          ReviewAction action = ReviewAction.approve}) =>
      ConverterAssetReview(
          candidateId: candidate.candidateId,
          proposalHash: candidate.canonicalHash,
          name: name,
          category: category,
          action: action,
          humanConfirmed: true);

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
