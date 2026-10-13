import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  late Directory root;
  late Directory output;
  late LiteralTileFixture fixture;
  late ConverterWorkflow original;
  late ConverterWorkflow restored;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ac16-original-recipe-');
    output = Directory(await Directory('${root.path}/output')
        .create()
        .then((d) => d.resolveSymbolicLinks()));
    fixture =
        await LiteralTileFixture.create(sourceRootPath: '${root.path}/source');
    original = ConverterWorkflow();
    restored = ConverterWorkflow();
  });
  tearDown(() async {
    await original.dispose();
    await restored.dispose();
    await root.delete(recursive: true);
  });

  Future<PreparedStudy> prepare(
      {String? parentPath,
      NativeWriteLimits writeLimits = sourceCatalogStudyWriteLimits}) async {
    final snapshot = await original.scanSource(ConverterSourceSelection(
        rootPath: fixture.sourceRootPath!,
        logicalProjectNamespace: ConverterId('original-ac16')));
    original.updateSettings(ConverterStudySettings(
        projectName: 'Original offline study',
        parentPath: parentPath ?? output.path,
        folderName: 'original-study',
        selectedSourceMapIds: [1],
        writeLimits: writeLimits,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason:
                'Original literal fixture without Scripts or Pokemon assets.')));
    return original.prepareStudy();
  }

  ConverterStudyPlanRecipe connectionRecipe(int maxConnections,
      {NativeWriteLimits writeLimits = const NativeWriteLimits()}) {
    final sourceHash = Sha256Hash('1' * 64);
    final profileHash = Sha256Hash('2' * 64);
    final settings = ConverterStudySettings(
        projectName: 'Original connection quota study',
        parentPath: output.path,
        folderName: 'original-study',
        selectedSourceMapIds: [1],
        writeLimits: writeLimits,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: sourceHash,
            profileEvidenceHash: profileHash,
            humanConfirmed: true,
            reason: 'Original bounded recipe fixture'),
        normalizationLimits:
            SourceNormalizationLimits(maxConnections: maxConnections));
    return ConverterStudyPlanRecipe(
        sessionId: ConverterId('original-connection-recipe'),
        sessionRevision: 3,
        sourceSelection: ConverterSourceSelection(
            rootPath: fixture.sourceRootPath!,
            logicalProjectNamespace: ConverterId('original-connection-quota')),
        settings: settings,
        sourceSnapshotHash: sourceHash,
        profileEvidenceHash: profileHash,
        settingsHash: settings.canonicalHash,
        nativeDraftHash: Sha256Hash('3' * 64),
        preparationHash: Sha256Hash('4' * 64),
        previewPlanHash: Sha256Hash('5' * 64),
        approvedPlanHash: Sha256Hash('6' * 64),
        targetCapabilitiesHash: Sha256Hash('7' * 64),
        rulesHash: Sha256Hash('8' * 64),
        converterVersion: 'original-quota-fixture');
  }

  Map<String, Object?> changedConnectionQuota(Object? value,
      {bool remove = false}) {
    final body =
        jsonDecode(connectionRecipe(2).encode()) as Map<String, dynamic>;
    body.remove('canonicalHash');
    final settings = body['settings'] as Map<String, dynamic>;
    final normalization =
        settings['normalizationLimits'] as Map<String, dynamic>;
    if (remove) {
      normalization.remove('maxConnections');
    } else {
      normalization['maxConnections'] = value;
    }
    body['settingsHash'] = canonicalHashOf(settings).value;
    return {
      ...body,
      'canonicalHash':
          canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
              .value
    };
  }

  Map<String, Object?> changedDraftBudget(Object? value,
      {bool remove = false, int? version}) {
    final body =
        jsonDecode(connectionRecipe(2).encode()) as Map<String, dynamic>;
    body.remove('canonicalHash');
    if (version != null) body['version'] = version;
    final settings = body['settings'] as Map<String, dynamic>;
    final write = settings['writeLimits'] as Map<String, dynamic>;
    if (remove) {
      write.remove('maxTotalDraftJsonBytes');
    } else {
      write['maxTotalDraftJsonBytes'] = value;
    }
    body['settingsHash'] = canonicalHashOf(settings).value;
    return {
      ...body,
      'canonicalHash':
          canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
              .value
    };
  }

  test('draft JSON budget recipe roundtrip preserves the exact custom limit',
      () {
    for (final budget in [1, 67108864, 268435456]) {
      final recipe = connectionRecipe(2,
          writeLimits: NativeWriteLimits(maxTotalDraftJsonBytes: budget));
      final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
      expect(decoded.settings.writeLimits.maxTotalDraftJsonBytes, budget);
      expect(decoded.settings.canonicalHash, recipe.settings.canonicalHash);
      expect(decoded.canonicalHash, recipe.canonicalHash);
    }
  });

  test('draft JSON budget settings and recipe hashes distinguish limits', () {
    final two = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(maxTotalDraftJsonBytes: 2));
    final three = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(maxTotalDraftJsonBytes: 3));
    expect(two.settings.canonicalHash, isNot(three.settings.canonicalHash));
    expect(two.canonicalHash, isNot(three.canonicalHash));
  });

  test('draft JSON budget recipe emits version 2', () {
    expect(connectionRecipe(2).toJson()['version'], 2);
  });

  test('draft JSON budget recipe refuses a resigned version 1', () {
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            changedDraftBudget(67108864, version: 1)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'workflow.recipe.invalid')));
  });

  test('draft JSON budget recipe refuses a resigned missing field', () {
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            changedDraftBudget(null, remove: true)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'workflow.recipe.invalid')));
  });

  for (final invalid in [null, true, 0, -1, 268435457, 2.5, '2']) {
    test('draft JSON budget recipe refuses resigned invalid value $invalid',
        () {
      expect(
          () => ConverterStudyPlanRecipe.fromJson(changedDraftBudget(invalid)),
          throwsA(isA<ConverterWorkflowFailure>()
              .having((error) => error.code, 'code', 'workflow.recipe.invalid')));
    });
  }

  test('draft JSON budget survives fresh workflow restore without approval',
      () async {
    final prepared = await prepare(
        writeLimits:
            const NativeWriteLimits(maxTotalDraftJsonBytes: 134217728));
    final recipe = ConverterStudyPlanRecipe.decode(
        original.exportStudyPlanRecipe().encode());
    expect(recipe.settings.writeLimits.maxTotalDraftJsonBytes, 134217728);
    final fresh = await restored.restoreStudyPlanRecipe(recipe);
    expect(restored.state.settings!.writeLimits.maxTotalDraftJsonBytes,
        134217728);
    expect(fresh.preparationHash, prepared.preparationHash);
    expect(fresh.previewPlan!.canonicalHash, recipe.previewPlanHash);
    expect(fresh.nativeDraft!.canonicalHash, recipe.nativeDraftHash);
    expect(restored.state.approval, isNull);
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('connection quota recipe roundtrip preserves the exact custom limit',
      () {
    for (final quota in [1, 2, 16384, 65536]) {
      final recipe = connectionRecipe(quota);
      final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
      expect(decoded.settings.normalizationLimits.maxConnections, quota);
      expect(decoded.settings.canonicalHash, recipe.settings.canonicalHash);
      expect(decoded.canonicalHash, recipe.canonicalHash);
    }
  });

  test('connection quota settings and recipe hashes distinguish limits', () {
    final two = connectionRecipe(2);
    final three = connectionRecipe(3);
    expect(two.settings.canonicalHash, isNot(three.settings.canonicalHash));
    expect(two.canonicalHash, isNot(three.canonicalHash));
  });

  test('connection quota recipe refuses a resigned missing field', () {
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            changedConnectionQuota(null, remove: true)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'workflow.recipe.invalid')));
  });

  for (final invalid in [null, true, 0, -1, 65537, 2.5, '2']) {
    test('connection quota recipe refuses resigned invalid value $invalid', () {
      expect(
          () => ConverterStudyPlanRecipe.fromJson(
              changedConnectionQuota(invalid)),
          throwsA(isA<ConverterWorkflowFailure>().having(
              (error) => error.code,
              'code',
              invalid is int
                  ? 'workflow.invalid_limits'
                  : 'workflow.recipe.invalid')));
    });
  }

  test('REL03 restored recipe recomposes the exact plan without saved approval',
      () async {
    final prepared = await prepare();
    original.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final recipe = original.exportStudyPlanRecipe();
    final decoded = ConverterStudyPlanRecipe.fromJson(recipe.toJson());
    expect(decoded.canonicalHash, recipe.canonicalHash);
    expect(restored.canRestoreStudyPlanRecipe, isTrue);
    final fresh = await restored.restoreStudyPlanRecipe(decoded);
    expect(fresh.preparationHash, prepared.preparationHash);
    expect(fresh.previewPlan!.canonicalHash, recipe.previewPlanHash);
    expect(fresh.nativeDraft!.canonicalHash, recipe.nativeDraftHash);
    expect(fresh.sessionRevision, recipe.sessionRevision);
    expect(restored.state.approval, isNull);
    expect(await output.list().toList(), isEmpty);
    final approval = restored.approvePrepared(
        sessionRevision: fresh.sessionRevision,
        preparationHash: fresh.preparationHash,
        humanConfirmed: true);
    expect(approval.approvedPlanHash, recipe.approvedPlanHash);
  }, skip: !Platform.isMacOS);

  test('unknown saved human approval and altered hashes are rejected',
      () async {
    await prepare();
    final recipe = original.exportStudyPlanRecipe();
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            {...recipe.toJson(), 'approvedByHuman': true}),
        throwsA(isA<ConverterWorkflowFailure>()));
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            {...recipe.toJson(), 'nativeDraftHash': '0' * 64}),
        throwsA(isA<ConverterWorkflowFailure>()));
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('changed source invalidates restore before exposing a prepared plan',
      () async {
    await prepare();
    final recipe = original.exportStudyPlanRecipe();
    await File('${fixture.sourceRootPath}/README.md')
        .writeAsString('Changed original fixture');
    await expectLater(
        restored.restoreStudyPlanRecipe(recipe),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.source_changed')));
    expect(restored.state.prepared, isNull);
    expect(restored.state.approval, isNull);
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('restore refuses used and disposed workflows', () async {
    await prepare();
    final recipe = original.exportStudyPlanRecipe();
    await expectLater(
        original.restoreStudyPlanRecipe(recipe),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.recipe.not_fresh')));
    await restored.dispose();
    await expectLater(
        restored.restoreStudyPlanRecipe(recipe),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.disposed')));
  }, skip: !Platform.isMacOS);

  test('restore locks identity while a fresh worker is active', () async {
    await prepare();
    final recipe = original.exportStudyPlanRecipe();
    await restored.dispose();
    final entered = Completer<void>();
    final release = Completer<void>();
    restored = ConverterWorkflow(checkpoint: (phase, jobId, revision) async {
      if (phase == ConverterWorkflowPhase.scan) {
        entered.complete();
        await release.future;
      }
    });
    final pending = restored.restoreStudyPlanRecipe(recipe);
    await entered.future.timeout(const Duration(seconds: 10));
    expect(restored.canRestoreStudyPlanRecipe, isFalse);
    await expectLater(
        restored.restoreStudyPlanRecipe(recipe),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.busy')));
    restored.cancelCurrentJob();
    release.complete();
    await expectLater(pending, throwsA(isA<ConverterWorkflowFailure>()));
    expect(restored.state.approval, isNull);
  }, skip: !Platform.isMacOS);
  test(
      'resigned altered recipe is rejected after fresh composition without exposing a draft',
      () async {
    await prepare();
    final recipe = original.exportStudyPlanRecipe();
    final body = Map<String, Object?>.from(recipe.toJson())
      ..remove('canonicalHash');
    body['nativeDraftHash'] = '0' * 64;
    final altered = ConverterStudyPlanRecipe.fromJson({
      ...body,
      'canonicalHash':
          canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
              .value
    });
    final observed = <PreparedStudy>[];
    final subscription = restored.events.listen((e) {
      if (e.state.prepared != null) observed.add(e.state.prepared!);
    });
    try {
      await expectLater(
          restored.restoreStudyPlanRecipe(altered),
          throwsA(isA<ConverterWorkflowFailure>()
              .having((e) => e.code, 'code', 'workflow.recipe.stale')));
      expect(restored.state.prepared, isNull);
      expect(restored.state.approval, isNull);
      expect(observed, isEmpty);
      expect(await output.list().toList(), isEmpty);
    } finally {
      await subscription.cancel();
    }
  }, skip: !Platform.isMacOS);

  test(
      'recipe retains custom budgets scan policy dependency locators and review seed',
      () async {
    fixture = await LiteralTileFixture.create(
        sourceRootPath: fixture.sourceRootPath!,
        maps: [
          LiteralFixtureMap(id: 1, warpParameters: [
            [0, 8, 1, 1, 2, 0]
          ]),
          LiteralFixtureMap(id: 8)
        ]);
    final snapshot = await original.scanSource(ConverterSourceSelection(
        rootPath: fixture.sourceRootPath!,
        logicalProjectNamespace: ConverterId('original-ac16'),
        policy: SourceScanPolicy(
            limits: const SourceScanLimits(maxEntries: 128),
            excludedSegments: ['.env', '.git'])));
    ConverterStudySettings settings(
            {List<LiteralDependencyDecision> decisions = const [],
            AssetReviewSession? review}) =>
        ConverterStudySettings(
            projectName: 'Original dependency study',
            parentPath: output.path,
            folderName: 'original-study',
            selectedSourceMapIds: [1],
            profileAcknowledgement: SourceStudyAcknowledgement(
                sourceSnapshotHash: snapshot.canonicalHash,
                profileEvidenceHash: snapshot.profile.evidenceHash,
                humanConfirmed: true,
                reason: 'Original dependency fixture'),
            dependencyDecisions: decisions,
            reviewSession: review,
            normalizationLimits: const SourceNormalizationLimits(maxMaps: 4),
            writeLimits:
                const NativeWriteLimits(maxArtifacts: 16, maxMutations: 96));
    original.updateSettings(settings());
    final initial = await original.prepareStudy();
    final dependency = initial.composition.dependencies.single;
    final decision = LiteralDependencyDecision(
        sourceSnapshotHash: snapshot.canonicalHash,
        selectionHash: literalSelectionHash(initial.normalizedSource, [1]),
        locator: dependency.locator,
        targetSourceMapId: 8,
        decision: LiteralDependencyDisposition.excludeStudy);
    original.updateSettings(
        settings(decisions: [decision], review: initial.reviewSession));
    final prepared = await original.prepareStudy();
    final recipe = ConverterStudyPlanRecipe.fromJson(
        original.exportStudyPlanRecipe().toJson());
    final fresh = await restored.restoreStudyPlanRecipe(recipe);
    expect(fresh.preparationHash, prepared.preparationHash);
    expect(fresh.settings.canonicalHash, prepared.settings.canonicalHash);
    expect(fresh.settings.dependencyDecisions.single.locator.toJson(),
        decision.locator.toJson());
    expect(restored.state.source!.policy.limits.maxEntries, 128);
  }, skip: !Platform.isMacOS);

  test('shared plan store is bounded exclusive and outside the source',
      () async {
    await prepare();
    final recipe = original.exportStudyPlanRecipe();
    const store = LocalStudyPlanStore();
    final planPath = '${root.path}/study-plan.json';
    await store.writeNew(recipe, planPath);
    expect((await File(planPath).stat()).mode & 0x1ff, 0x180);
    expect((await store.read(planPath)).canonicalHash, recipe.canonicalHash);
    await expectLater(store.writeNew(recipe, planPath),
        throwsA(isA<ConverterWorkflowFailure>()));
    await expectLater(
        store.writeNew(recipe, '${fixture.sourceRootPath}/plan.json'),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.recipe.source_overlap')));
    await Link('${root.path}/linked-plan.json').create(planPath);
    await expectLater(store.read('${root.path}/linked-plan.json'),
        throwsA(isA<ConverterWorkflowFailure>()));
    await File('${root.path}/large-plan.json')
        .writeAsString('x' * (ConverterStudyPlanRecipe.maxFileBytes + 1));
    await expectLater(
        store.read('${root.path}/large-plan.json'),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.recipe.quota')));
    expect(await File('${fixture.sourceRootPath}/plan.json').exists(), isFalse);
  }, skip: !Platform.isMacOS);

  test('plan store excludes native destination across tmp canonical aliases',
      () async {
    final alias = await Directory('/tmp').createTemp('ac16-plan-alias-');
    try {
      await prepare(parentPath: alias.path);
      final recipe = original.exportStudyPlanRecipe();
      final canonical = await alias.resolveSymbolicLinks();
      final native = await Directory('$canonical/original-study').create();
      await expectLater(
          const LocalStudyPlanStore()
              .writeNew(recipe, '${native.path}/plan.json'),
          throwsA(isA<ConverterWorkflowFailure>().having(
              (e) => e.code, 'code', 'workflow.recipe.destination_overlap')));
      expect(await native.list().toList(), isEmpty);
    } finally {
      await alias.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);

  test(
      'read-only verifier reopens native output and detects an altered retained asset',
      () async {
    final prepared = await prepare();
    final approval = original.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final result = await original.writeApproved(approval);
    const verifier = NativeStudyVerifier();
    final before = await _treeBytes(result.projectPath);
    final verified = await verifier.verify(
        projectPath: result.projectPath, allowedParentPath: output.path);
    expect(verified.verified, isTrue);
    expect(verified.playableCertified, isFalse);
    expect(verified.nativeRevision, result.receipt.nativeRevision);
    expect(await _treeBytes(result.projectPath), before);
    final blob = (await Directory('${result.projectPath}/assets/.pokemap-store')
            .list(recursive: true)
            .toList())
        .whereType<File>()
        .first;
    final originalBytes = await blob.readAsBytes();
    var loads = 0;
    final alteringVerifier = NativeStudyVerifier(snapshotLoadProfileSink: (_) {
      if (++loads == 3) blob.writeAsBytesSync([...originalBytes, 1]);
    });
    await expectLater(
        alteringVerifier.verify(
            projectPath: result.projectPath, allowedParentPath: output.path),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'native.verify.failed')));
    expect(loads, 3);
    await blob.writeAsBytes(originalBytes);
    final image =
        (await Directory('${result.projectPath}/assets/studio').list().toList())
            .whereType<File>()
            .first;
    await image.writeAsBytes([1, 2, 3]);
    await expectLater(
        verifier.verify(
            projectPath: result.projectPath, allowedParentPath: output.path),
        throwsA(isA<ConverterWorkflowFailure>()));
  }, skip: !Platform.isMacOS);
  test('read-only verifier honors cancellation at the final snapshot boundary',
      () async {
    final prepared = await prepare();
    final approval = original.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final result = await original.writeApproved(approval);
    final cancellation = ScanCancellation();
    var loads = 0;
    final verifier = NativeStudyVerifier(snapshotLoadProfileSink: (_) {
      if (++loads == 3) cancellation.cancel();
    });
    await expectLater(
        verifier.verify(
            projectPath: result.projectPath,
            allowedParentPath: output.path,
            cancellation: cancellation),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.cancelled')));
    expect(loads, 3);
  }, skip: !Platform.isMacOS);
}

Future<Map<String, List<int>>> _treeBytes(String root) async => {
      await for (final entry
          in Directory(root).list(recursive: true, followLinks: false))
        if (entry is File)
          entry.path.substring(root.length + 1): await entry.readAsBytes()
    };
