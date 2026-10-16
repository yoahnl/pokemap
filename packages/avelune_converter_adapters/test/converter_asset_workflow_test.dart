import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/original_asset_fixture.dart';
import 'support/literal_tile_fixture.dart';

void main() {
  late _AssetWorkflow harness;
  setUp(() async => harness = await _AssetWorkflow.create());
  tearDown(() async => harness.close());

  test('segmented review retains 280 candidates under explicit total budget',
      () async {
    final root = await Directory.systemTemp.createTemp('ac15-segmented-');
    final output = await Directory('${root.path}/destination').create();
    final workflow = ConverterWorkflow();
    addTearDown(() async {
      await workflow.dispose();
      await root.delete(recursive: true);
    });
    final raster = image.Image(width: 256, height: 1792, numChannels: 4);
    for (var y = 0; y < raster.height; y++) {
      for (var x = 0; x < raster.width; x++) {
        raster.setPixelRgba(x, y, x % 251, y % 241, (x + y) % 239, 255);
      }
    }
    final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/source',
        tilesets: [
          LiteralFixtureTileset(
              id: 1, metadataTileCount: 832, png: image.encodePng(raster))
        ],
        maps: [
          for (final id in [1, 8])
            LiteralFixtureMap(id: id, width: 140, height: 1, layers: [
              List.generate(140, (index) => 384 + index),
              List.filled(140, 0),
              List.filled(140, 0),
            ])
        ]);
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: fixture.sourceRootPath!,
        logicalProjectNamespace: ConverterId('segmented-workflow')));
    workflow.updateSettings(ConverterStudySettings(
        projectName: 'Segmented resources',
        parentPath: output.path,
        folderName: 'output',
        selectedSourceMapIds: const [1, 8],
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason: 'Original controlled fixture'),
        writeLimits: const NativeWriteLimits(maxMutations: 512)));
    final prepared = await workflow.prepareStudy();
    expect(prepared.assetCandidates, hasLength(280));
    expect(prepared.reviewSet!.segments.keys, [1, 8]);
    expect(
        prepared.reviewSet!.segments.values
            .map((s) => s.activeCandidates.length),
        [140, 140]);
    expect(prepared.reviewSet!.limits.maxTotalCandidates, 512);
    expect(
        prepared.assetProposalDiagnostics
            .where((d) => d.code == 'asset.proposal.quota'),
        isEmpty);
    expect(prepared.canApprove, isTrue);
    workflow.updateSettings(ConverterStudySettings(
        projectName: 'Segmented resources',
        parentPath: output.path,
        folderName: 'output',
        selectedSourceMapIds: const [1, 8],
        profileAcknowledgement: prepared.settings.profileAcknowledgement,
        writeLimits: const NativeWriteLimits(maxMutations: 256)));
    final bounded = await workflow.prepareStudy();
    expect(bounded.reviewSet, isNull);
    expect(bounded.assetCandidates, isEmpty);
    expect(bounded.assetProposalDiagnostics.map((d) => d.code),
        contains('asset.proposal.quota'));
  });

  test(
      'guided terrain review publishes a native paintable path through workflow',
      () async {
    await harness.close();
    harness = await _AssetWorkflow.create(includeTerrainPixels: true);
    final initial =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    var session = harness.seed(initial);
    final source =
        initial.assetProposalsByMap!.values.first.sourceImages.single;
    final original = harness.fixture.terrainCandidate();
    final manual = AssetCandidate.fromJson({
      ...original.toJson(),
      'logicalProjectNamespace': session.logicalProjectNamespace.value,
      'sourceSnapshotHash': session.sourceSnapshotHash.value,
      'terrainLayout': null,
      'sources': [source.toJson()],
      'parts': [
        for (final part in original.parts)
          {...part.toJson(), 'sourceFileId': source.fileId.value}
      ]
    });
    session = session.createManualCandidate(
        candidate: manual, expectedSessionHash: session.canonicalHash);
    session = session.configureTerrainLayout(
        candidateId: manual.candidateId,
        expectedCandidateHash: manual.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        layout: AssetTerrainLayout.cardinal3x3);
    final current = session.activeCandidates.singleWhere(
        (candidate) => candidate.candidateId == manual.candidateId);
    session = session.decide(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        session: AssetReviewSession.fromJson(session.toJson()));
    expect(prepared.canApprove, isTrue);
    expect(prepared.nativeDraft!.mutations.map((entry) => entry.actionId),
        contains('smart_tile.preset.publish'));
    final result =
        await harness.workflow.writeApproved(harness.approve(prepared));
    final verification = await const NativeStudyVerifier().verify(
        projectPath: result.projectPath,
        allowedParentPath: await harness.output.resolveSymbolicLinks());
    expect(verification.nativeRevision, result.publication.nativeRevision);
    await harness.expectSourceUnchanged();
  });

  test('AC-10 initial preparation creates an exact durable review seed',
      () async {
    final prepared = await harness.prepare();
    expect(prepared.reviewSet, isNotNull);
    expect(prepared.reviewSet!.segments.keys, [1, 8, 12, 20, 21]);
    expect(prepared.assetProposalsByMap!.values.expand((p) => p.candidates),
        hasLength(21));
    expect(
        prepared.assetProposalsByMap!.values
            .expand((p) => p.candidates)
            .every((c) => c.parts.length == 1),
        isTrue);
    expect(
        prepared.assetProposalsByMap!.values
            .expand((p) => p.placementClaims.values)
            .expand((c) => c),
        hasLength(27));
    expect(prepared.reviewSet!.segments[1]!.baseProposalHashes, {
      for (final candidate in prepared.assetProposalsByMap![1]!.candidates)
        candidate.candidateId: candidate.canonicalHash,
    });
    expect(prepared.reviewSet!.seedOutputMode, AssetOutputMode.sharedAtlas);
    expect(prepared.reviewSet!.activeDecisions.decisions, isEmpty);
    expect(prepared.settings.toJson().containsKey('assetReviews'), isFalse);
    expect(harness.stages, isEmpty);
  });

  test('AC-10 corrected geometry survives preparation and native readback',
      () async {
    final literal =
        await harness.prepare(mode: AssetOutputMode.standaloneObjects);
    var session = harness.groupMap(harness.seed(literal), 1);
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
    final publishedParent = await harness.output.resolveSymbolicLinks();
    expect(result.receipt.verified, isTrue);
    expect(result.published, isTrue);
    expect(result.receipt.published, isFalse);
    expect(result.playableCertified, isFalse);
    expect(
        result.projectPath, '$publishedParent/${prepared.settings.folderName}');
    expect(result.publication.projectPath, result.projectPath);
    expect(await Directory(result.receipt.projectPath).exists(), isFalse);
    expect(await Directory(result.receipt.stagingRoot).exists(), isTrue);
    expect(
        await Directory(result.receipt.stagingRoot).list().toList(), isEmpty);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [publishedParent], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.projectPath);
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
    final tree = session.activeCandidates.first;
    final house = session.activeCandidates[1];
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
              offsetX: 32,
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
        harness.prepare(
            reviewSet: ConverterAssetReviewSet.create(
                sessionId: literal.reviewSet!.sessionId,
                logicalProjectNamespace:
                    literal.reviewSet!.logicalProjectNamespace,
                sourceSnapshotHash: literal.sourceSnapshotHash,
                normalizedSourceHash: literal.normalizedSource.canonicalHash,
                selectedSourceMapIds: literal.settings.selectedSourceMapIds,
                proposalSourceMapIds: literal.reviewSet!.proposalSourceMapIds,
                segments: {...literal.reviewSet!.segments, 1: forged},
                limits: literal.reviewSet!.limits)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.review_set.stale')));
    expect(harness.stages, isEmpty);
  });

  test('fresh source rejects a resigned seed with missing valid claims',
      () async {
    final prepared = await harness.prepare();
    final original = prepared.reviewSet!;
    final entry = original.segments.entries.firstWhere((e) => e
        .value.frame.placementClaims.values
        .any((claims) => claims.length > 1));
    final child = entry.value;
    final repeated = child.frame.placementClaims.entries
        .firstWhere((e) => e.value.length > 1);
    final forged = AssetReviewSession.create(
        sessionId: child.sessionId,
        logicalProjectNamespace: child.logicalProjectNamespace,
        sourceSnapshotHash: child.sourceSnapshotHash,
        selectedSourceMapIds: child.selectedSourceMapIds,
        outputMode: child.outputMode,
        proposalGenerationHash: child.proposalGenerationHash,
        candidates: child.activeCandidates,
        placementClaims: {
          ...child.frame.placementClaims,
          repeated.key: repeated.value.take(1).toList()
        },
        sourceMaps: prepared.normalizedSource.maps,
        limits: child.limits);
    final altered = ConverterAssetReviewSet.create(
        sessionId: original.sessionId,
        logicalProjectNamespace: original.logicalProjectNamespace,
        sourceSnapshotHash: original.sourceSnapshotHash,
        normalizedSourceHash: original.normalizedSourceHash,
        selectedSourceMapIds: original.selectedSourceMapIds,
        proposalSourceMapIds: original.proposalSourceMapIds,
        segments: {...original.segments, entry.key: forged},
        limits: original.limits);
    await expectLater(
        harness.prepare(reviewSet: altered),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.review_set.stale')));
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
    expect(prepared.reviewSet!.seedOutputMode, AssetOutputMode.sharedAtlas);
    expect(prepared.reviewSet!.outputMode, AssetOutputMode.standaloneObjects);
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
    expect(
        prepared.reviewSet!.segments[1]!.canonicalHash, session.canonicalHash);
  });

  test('unreviewed proposals leave the literal draft unchanged', () async {
    final prepared = await harness.prepare();
    expect(prepared.assetProposalsByMap!.values.expand((p) => p.candidates),
        isNotEmpty);
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
    expect(prepared.assetProposalsByMap!.values.expand((p) => p.candidates),
        isNotEmpty);
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
    final session = harness.groupMap(harness.seed(literal), 1);
    final tree = session.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        session: harness.decide(session, tree));
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
    final publishedParent = await harness.output.resolveSymbolicLinks();
    expect(result.receipt.verified, isTrue);
    expect(result.published, isTrue);
    expect(result.receipt.published, isFalse);
    expect(result.playableCertified, isFalse);
    expect(
        result.projectPath, '$publishedParent/${prepared.settings.folderName}');
    expect(result.publication.projectPath, result.projectPath);
    expect(await Directory(result.receipt.projectPath).exists(), isFalse);
    expect(await Directory(result.receipt.stagingRoot).exists(), isTrue);
    expect(
        await Directory(result.receipt.stagingRoot).list().toList(), isEmpty);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [publishedParent], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.projectPath);
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

  test(
      'aggregate image budget rejects literal baseline before approval',
      () async {
    await expectLater(
        harness.prepare(
            limits: const NativeWriteLimits(
                maxImagePixels: 65536, maxTotalImagePixels: 65535)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'literal.quota.image')));
    expect(harness.workflow.state.prepared, isNull);
    expect(harness.workflow.state.approval, isNull);
    expect(harness.stages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
    await harness.expectSourceUnchanged();
  });

  test('aggregate image budget permits combined retained images at exact total',
      () async {
    const limits =
        NativeWriteLimits(maxImagePixels: 65536, maxTotalImagePixels: 137216);
    final initial = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, limits: limits);
    final session = harness.groupMap(harness.seed(initial), 1);
    final tree = session.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects,
        limits: limits,
        session: harness.decide(session, tree));
    expect(prepared.canApprove, isTrue);
    expect(prepared.nativeDraft!.sourceArtifacts, isNotEmpty);
    expect(prepared.settings.writeLimits.maxImagePixels, 65536);
    expect(prepared.settings.writeLimits.maxTotalImagePixels, 137216);
    expect(() => prepared.nativeDraft!.validateResourceBudget(limits: limits),
        returnsNormally);
    expect(harness.stages, isEmpty);
    expect(await harness.output.list().toList(), isEmpty);
    await harness.expectSourceUnchanged();
  });

  test('combined literal and witness pixels are refused before approval',
      () async {
    const limits = NativeWriteLimits(maxTotalImagePixels: 71680);
    final prepared = await harness.prepare(
        mode: AssetOutputMode.standaloneObjects, limits: limits);
    final session = harness.groupMap(harness.seed(prepared), 1);
    final tree = session.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 1));
    await expectLater(
      harness.prepare(
          mode: AssetOutputMode.standaloneObjects,
          limits: limits,
          session: harness.decide(session, tree)),
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
    final seed = harness.groupMap(harness.seed(literal, mapId: 8), 8);
    final house = seed.activeCandidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 8));
    var session = harness.decide(seed, house, category: AssetCategory.building);
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
    final proposal = literal.reviewSet!.segments[1]!.activeCandidates.first;
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
    final proposal = literal.reviewSet!.segments[1]!.activeCandidates.first;
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
  ConverterAssetReviewSet? _currentSet;

  static Future<_AssetWorkflow> create(
      {bool includeTerrainPixels = false}) async {
    final root =
        await Directory.systemTemp.createTemp('ac08-original-workflow-');
    final output = await Directory('${root.path}/output').create();
    final fixture = await OriginalAssetFixture.create(
        includeTerrainPixels: includeTerrainPixels,
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
      ConverterAssetReviewSet? reviewSet,
      String projectName = 'Original asset library study',
      String folderName = 'original-library',
      NativeWriteLimits limits = const NativeWriteLimits()}) {
    final snapshot = workflow.state.snapshot!;
    var nextSet = reviewSet;
    if (session != null) {
      nextSet = _currentSet!;
      if (nextSet.outputMode != session.outputMode) {
        nextSet = nextSet.changeOutputMode(
            outputMode: session.outputMode,
            expectedSetHash: nextSet.canonicalHash);
      }
      final entry = nextSet.segments.entries
          .singleWhere((e) => e.value.sessionId == session.sessionId);
      nextSet = nextSet.replaceSegment(
          sourceMapId: entry.key,
          next: session,
          expectedSetHash: nextSet.canonicalHash,
          expectedSegmentHash: entry.value.canonicalHash);
    }
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
      reviewSet: nextSet,
      writeLimits: limits,
    ));
    return workflow.prepareStudy().then((prepared) {
      _currentSet = prepared.reviewSet;
      return prepared;
    });
  }

  AssetReviewSession seed(PreparedStudy prepared, {int mapId = 1}) {
    _currentSet = prepared.reviewSet!;
    return _currentSet!.segments[mapId]!;
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

  AssetReviewSession groupMap(AssetReviewSession session, int mapId) {
    final candidates = session.activeCandidates
        .where((candidate) =>
            candidate.parts.every((part) => part.locator.mapId == mapId))
        .toList()
      ..sort((a, b) {
        final x = session.frame.placementClaims[a.candidateId]!.single;
        final y = session.frame.placementClaims[b.candidateId]!.single;
        var order = x.sourceZ.compareTo(y.sourceZ);
        if (order == 0) order = x.y.compareTo(y.y);
        if (order == 0) order = x.x.compareTo(y.x);
        return order;
      });
    return session.unionCandidates(
        candidateId: ConverterId('review-manual-map-group-$mapId'),
        expectedSessionHash: session.canonicalHash,
        inputs: [
          for (final candidate in candidates)
            AssetUnionInput(
                candidateId: candidate.candidateId,
                expectedCandidateHash: candidate.canonicalHash,
                offsetX: session.frame.placementClaims[candidate.candidateId]!
                        .single.x *
                    32,
                offsetY: session.frame.placementClaims[candidate.candidateId]!
                        .single.y *
                    32),
        ],
        name: 'Groupe manuel carte $mapId',
        category: AssetCategory.unclassified);
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
