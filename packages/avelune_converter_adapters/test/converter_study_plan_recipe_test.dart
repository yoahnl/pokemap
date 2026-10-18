import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/original_asset_fixture.dart';

void main() {
  late Directory root;
  late Directory output;
  late LiteralTileFixture fixture;
  late ConverterWorkflow original;
  late ConverterWorkflow restored;

  setUp(() async {
    root = await Directory('/private/tmp').createTemp('ac16-original-recipe-');
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
      List<String> supplementalRootPaths = const [],
      NativeWriteLimits writeLimits = sourceCatalogStudyWriteLimits}) async {
    final snapshot = await original.scanSource(ConverterSourceSelection(
        rootPath: fixture.sourceRootPath!,
        supplementalRootPaths: supplementalRootPaths,
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
      {NativeWriteLimits writeLimits = const NativeWriteLimits(), SourceInterpretationProfile? interpretationProfile}) {
    final sourceHash = Sha256Hash('1' * 64);
    final profileHash = Sha256Hash('2' * 64);
    final settings = ConverterStudySettings(
        interpretationProfile: interpretationProfile,
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

  test(
      'recipe roundtrip binds explicit draft aggregate nodes in settings identity',
      () {
    final inherited = connectionRecipe(2);
    final explicit = connectionRecipe(
      2,
      writeLimits: const NativeWriteLimits(maxDraftEvidenceJsonNodes: 4096),
    );
    for (final recipe in [inherited, explicit]) {
      final reopened = ConverterStudyPlanRecipe.decode(recipe.encode());
      expect(
        reopened.settings.writeLimits.maxDraftEvidenceJsonNodes,
        recipe.settings.writeLimits.maxDraftEvidenceJsonNodes,
      );
      expect(reopened.canonicalHash, recipe.canonicalHash);
      expect(reopened.settings.canonicalHash, recipe.settingsHash);
    }
    expect(explicit.settingsHash, isNot(inherited.settingsHash));
    expect(explicit.canonicalHash, isNot(inherited.canonicalHash));
    final stale = {...explicit.toJson(), 'version': 10};
    expect(
      () => ConverterStudyPlanRecipe.fromJson(stale),
      throwsA(isA<ConverterWorkflowFailure>()),
    );
    final priorSettings =
        jsonDecode(explicit.encode()) as Map<String, dynamic>;
    priorSettings.remove('canonicalHash');
    final settings = priorSettings['settings'] as Map<String, dynamic>;
    settings['version'] = 7;
    priorSettings['settingsHash'] = canonicalHashOf(settings).value;
    priorSettings['canonicalHash'] = canonicalHashOf(
      priorSettings,
      limits: ConverterStudyPlanRecipe.jsonLimits,
    ).value;
    expect(
      () => ConverterStudyPlanRecipe.fromJson(priorSettings),
      throwsA(isA<ConverterWorkflowFailure>()),
    );
  });

  test(
    'recipe rejects resigned invalid or missing draft aggregate node budget',
    () {
      for (final invalid in [0, -1, 16000001, '4096', 4096.5, true]) {
        final body =
            jsonDecode(connectionRecipe(2).encode()) as Map<String, dynamic>;
        body.remove('canonicalHash');
        final settings = body['settings'] as Map<String, dynamic>;
        (settings['writeLimits'] as Map)['maxDraftEvidenceJsonNodes'] = invalid;
        body['settingsHash'] = canonicalHashOf(settings).value;
        body['canonicalHash'] = canonicalHashOf(
          body,
          limits: ConverterStudyPlanRecipe.jsonLimits,
        ).value;
        expect(
          () => ConverterStudyPlanRecipe.fromJson(body),
          throwsA(isA<ConverterWorkflowFailure>()),
        );
      }
      final body =
          jsonDecode(connectionRecipe(2).encode()) as Map<String, dynamic>;
      body.remove('canonicalHash');
      final settings = body['settings'] as Map<String, dynamic>;
      (settings['writeLimits'] as Map).remove('maxDraftEvidenceJsonNodes');
      body['settingsHash'] = canonicalHashOf(settings).value;
      body['canonicalHash'] = canonicalHashOf(
        body,
        limits: ConverterStudyPlanRecipe.jsonLimits,
      ).value;
      expect(
        () => ConverterStudyPlanRecipe.fromJson(body),
        throwsA(isA<ConverterWorkflowFailure>()),
      );
    },
  );

  test(
    'explicit draft aggregate nodes survive cold preparation restore',
    () async {
      final prepared = await prepare(
        writeLimits: const NativeWriteLimits(
          maxDraftEvidenceJsonNodes: 2000000,
        ),
      );
      final recipe = ConverterStudyPlanRecipe.decode(
        original.exportStudyPlanRecipe().encode(),
      );
      final fresh = await restored.restoreStudyPlanRecipe(recipe);
      expect(fresh.settings.writeLimits.maxDraftEvidenceJsonNodes, 2000000);
      expect(fresh.preparationHash, prepared.preparationHash);
      expect(fresh.nativeDraft!.canonicalHash, recipe.nativeDraftHash);
      expect(restored.state.approval, isNull);
      expect(await output.list().toList(), isEmpty);
    },
    skip: !Platform.isMacOS,
  );

  test('selected interpretation is persisted and invalidates the exact recipe hash', () {
    final literal = connectionRecipe(2);
    final selected = connectionRecipe(2, interpretationProfile: syntheticSourceInterpretationProfile);
    final reopened = ConverterStudyPlanRecipe.fromJson(jsonDecode(selected.encode()));
    expect(reopened.settings.interpretationProfile!.canonicalHash, syntheticSourceInterpretationProfile.canonicalHash);
    expect(reopened.canonicalHash, selected.canonicalHash);
    expect(selected.canonicalHash, isNot(literal.canonicalHash));
    expect(selected.settingsHash, isNot(literal.settingsHash));
  });

  for (final initiallyShared in [false, true]) {
    for (final afterApproval in [false, true]) {
      test(
          'constant bytes cannot change source origin shared=$initiallyShared approved=$afterApproval',
          () async {
        final shared =
            await Directory('${root.path}/shared/PBS').create(recursive: true);
        final primary = await Directory('${fixture.sourceRootPath!}/PBS')
            .create(recursive: true);
        final referenceFile = File('${shared.path}/items.txt');
        final primaryFile = File('${primary.path}/items.txt');
        await referenceFile
            .writeAsString('1,POTION,Potion,1,300,Heals HP,1,1,0');
        if (!initiallyShared) await referenceFile.copy(primaryFile.path);
        final selection = ConverterSourceSelection(
            rootPath: fixture.sourceRootPath!,
            supplementalRootPaths: [shared.parent.path],
            logicalProjectNamespace: ConverterId('constant-origin-source'));
        final snapshot = await original.scanSource(selection);
        original.updateSettings(ConverterStudySettings(
            projectName: 'Origin-bound study',
            parentPath: output.path,
            folderName: 'origin-bound-study',
            selectedSourceMapIds: [1],
            profileAcknowledgement: SourceStudyAcknowledgement(
                sourceSnapshotHash: snapshot.canonicalHash,
                profileEvidenceHash: snapshot.profile.evidenceHash,
                humanConfirmed: true,
                reason: 'Controlled original source.')));
        StudyApproval? approval;
        if (afterApproval) {
          final prepared = await original.prepareStudy();
          approval = original.approvePrepared(
              sessionRevision: prepared.sessionRevision,
              preparationHash: prepared.preparationHash,
              humanConfirmed: true);
        }
        if (initiallyShared) {
          await referenceFile.copy(primaryFile.path);
        } else {
          await primaryFile.delete();
        }
        final fresh = await restored.scanSource(selection);
        expect(fresh.canonicalHash, snapshot.canonicalHash);
        expect(original.state.sharedSourceFiles.isNotEmpty, initiallyShared);
        expect(restored.state.sharedSourceFiles.isNotEmpty, !initiallyShared);
        await expectLater(
            afterApproval
                ? original.writeApproved(approval!)
                : original.prepareStudy(),
            throwsA(isA<ConverterWorkflowFailure>().having(
                (error) => error.code,
                'code',
                'workflow.source_provenance_changed')));
        expect(original.state.approval, isNull);
        expect(original.state.result, isNull);
        expect(await Directory('${output.path}/origin-bound-study').exists(),
            isFalse);
      }, skip: !Platform.isMacOS);
    }
  }

  for (final afterApproval in [false, true]) {
    test(
        'constant media bytes cannot move between references approved=$afterApproval',
        () async {
      final first = await Directory('${root.path}/reference-first').create();
      final second = await Directory('${root.path}/reference-second').create();
      for (final reference in [first, second]) {
        await Directory('${reference.path}/Graphics/Pictures')
            .create(recursive: true);
      }
      final media = File('${second.path}/Graphics/Pictures/witness.png');
      await media.writeAsString('original non-rendered media');
      final prepared =
          await prepare(supplementalRootPaths: [first.path, second.path]);
      final snapshot = original.state.snapshot!;
      final recipe = original.exportStudyPlanRecipe();
      expect(recipe.toJson()['version'], 11);
      expect(recipe.sourceSelection.supplementalRootPaths,
          [first.path, second.path]);
      expect(recipe.sharedSourceFiles.single.referenceRootPath, second.path);
      StudyApproval? approval;
      if (afterApproval) {
        approval = original.approvePrepared(
            sessionRevision: prepared.sessionRevision,
            preparationHash: prepared.preparationHash,
            humanConfirmed: true);
      }
      await media.copy('${first.path}/Graphics/Pictures/witness.png');
      final fresh = await restored.scanSource(recipe.sourceSelection);
      expect(fresh.canonicalHash, snapshot.canonicalHash);
      await expectLater(
          afterApproval
              ? original.writeApproved(approval!)
              : original.prepareStudy(),
          throwsA(isA<ConverterWorkflowFailure>().having((error) => error.code,
              'code', 'workflow.source_provenance_changed')));
      expect(original.state.approval, isNull);
      expect(original.state.result, isNull);
    }, skip: !Platform.isMacOS);
  }

  test('cold recipe rejects the same bytes acquired from another priority',
      () async {
    final first =
        await Directory('${root.path}/reference-first/Graphics/Pictures')
            .create(recursive: true);
    final second =
        await Directory('${root.path}/reference-second/Graphics/Pictures')
            .create(recursive: true);
    final media = await File('${second.path}/witness.png')
        .writeAsString('original non-rendered bytes');
    await prepare(supplementalRootPaths: [
      first.parent.parent.path,
      second.parent.parent.path
    ]);
    final recipe = original.exportStudyPlanRecipe();
    await media.copy('${first.path}/witness.png');
    await expectLater(
        restored.restoreStudyPlanRecipe(recipe),
        throwsA(isA<ConverterWorkflowFailure>().having((error) => error.code,
            'code', 'workflow.source_provenance_changed')));
    expect(restored.state.prepared, isNull);
    expect(restored.state.approval, isNull);
  }, skip: !Platform.isMacOS);

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

  Map<String, Object?> changedImageTotal(Object? value,
      {bool remove = false, int? version}) {
    final body =
        jsonDecode(connectionRecipe(2).encode()) as Map<String, dynamic>;
    body.remove('canonicalHash');
    if (version != null) body['version'] = version;
    final settings = body['settings'] as Map<String, dynamic>;
    final write = settings['writeLimits'] as Map<String, dynamic>;
    if (remove) {
      write.remove('maxTotalImagePixels');
    } else {
      write['maxTotalImagePixels'] = value;
    }
    body['settingsHash'] = canonicalHashOf(settings).value;
    return {
      ...body,
      'canonicalHash':
          canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
              .value
    };
  }

  ConverterStudyPlanRecipe pairRecipe(ConverterAssetReviewSet reviewSet) {
    final settings = ConverterStudySettings(
        projectName: 'Original segmented recipe',
        parentPath: output.path,
        folderName: 'original-study',
        selectedSourceMapIds: [1, 8],
        assetOutputMode: reviewSet.outputMode,
        reviewSet: reviewSet,
        writeLimits: const NativeWriteLimits(maxMutations: 512),
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: reviewSet.sourceSnapshotHash,
            profileEvidenceHash: Sha256Hash('2' * 64),
            humanConfirmed: true,
            reason: 'Original segmented recipe fixture'));
    return ConverterStudyPlanRecipe(
        sessionId: ConverterId('segmented-study'),
        sessionRevision: 3,
        sourceSelection: ConverterSourceSelection(
            rootPath: fixture.sourceRootPath!,
            logicalProjectNamespace: reviewSet.logicalProjectNamespace),
        settings: settings,
        sourceSnapshotHash: reviewSet.sourceSnapshotHash,
        profileEvidenceHash: Sha256Hash('2' * 64),
        settingsHash: settings.canonicalHash,
        nativeDraftHash: Sha256Hash('3' * 64),
        preparationHash: Sha256Hash('4' * 64),
        previewPlanHash: Sha256Hash('5' * 64),
        approvedPlanHash: Sha256Hash('6' * 64),
        targetCapabilitiesHash: Sha256Hash('7' * 64),
        rulesHash: Sha256Hash('8' * 64),
        converterVersion: 'original-segmented-codec');
  }

  test('segmented recipe keeps both full reviews and their compact identity',
      () {
    final reviewSet = _recipePairSet();
    final recipe = pairRecipe(reviewSet);
    final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
    expect(decoded.settings.reviewSet!.toJson(), reviewSet.toJson());
    expect(decoded.settings.canonicalHash, recipe.settingsHash);
    expect(decoded.canonicalHash, recipe.canonicalHash);
    expect((recipe.toJson()['settings'] as Map)['version'], 8);
    expect(
        (recipe.toJson()['settings'] as Map)['reviewSet'], reviewSet.toJson());
  });

  test('cold recipe restores explicit shared reference and actual provenance',
      () async {
    final shared = await Directory('${root.path}/shared').create();
    await Directory('${shared.path}/PBS').create();
    await File('${shared.path}/PBS/items.txt')
        .writeAsString('1,POTION,Potion,1,300,Heals HP,1,1,0');
    await prepare(supplementalRootPaths: [shared.path]);
    final recipe = original.exportStudyPlanRecipe();
    final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
    expect(decoded.toJson()['version'], 11);
    expect(decoded.sourceSelection.supplementalRootPaths, [shared.path]);
    expect(decoded.sharedSourceFiles.single.relativePath, 'PBS/items.txt');
    expect(decoded.sharedSourceFiles.single.referenceRootPath, shared.path);
    final prepared = await restored.restoreStudyPlanRecipe(decoded);
    expect(prepared.preparationHash, recipe.preparationHash);
    expect(restored.state.sharedSourceFiles.single.toJson(),
        recipe.sharedSourceFiles.single.toJson());
    expect(await File('${fixture.sourceRootPath}/PBS/items.txt').exists(),
        isFalse);
    original.approvePrepared(
        sessionRevision: original.state.revision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    await original.scanSource(ConverterSourceSelection(
        rootPath: fixture.sourceRootPath!,
        logicalProjectNamespace: ConverterId('original-ac16')));
    expect(original.state.approval, isNull);
    expect(original.state.prepared, isNull);
  });

  test('shared reference protects preparation destination and plan storage',
      () async {
    final shared = await Directory('${root.path}/shared').create();
    await expectLater(
        prepare(parentPath: shared.path, supplementalRootPaths: [shared.path]),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'native.source.overlap')));
    await prepare(supplementalRootPaths: [shared.path]);
    final recipe = original.exportStudyPlanRecipe();
    await expectLater(
        const LocalStudyPlanStore()
            .writeNew(recipe, '${shared.path}/plan.json'),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.recipe.source_overlap')));
    expect(await File('${shared.path}/plan.json').exists(), isFalse);
    final old = {...recipe.toJson(), 'version': 6};
    expect(() => ConverterStudyPlanRecipe.fromJson(old),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('publication exposes exact shared source provenance outside native data',
      () async {
    final shared = await Directory('${root.path}/shared').create();
    await Directory('${shared.path}/PBS').create();
    await File('${shared.path}/PBS/items.txt')
        .writeAsString('1,POTION,Potion,1,300,Heals HP,1,1,0');
    final prepared = await prepare(supplementalRootPaths: [shared.path]);
    final approval = original.approvePrepared(
        sessionRevision: original.state.revision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final result = await original.writeApproved(approval);
    expect(result.published, isTrue);
    expect(result.sharedSourceFiles.single.toJson(),
        original.state.sharedSourceFiles.single.toJson());
    expect(result.sourceProvenanceReceipt['sourceSelectionHash'],
        original.state.source!.canonicalHash.value);
    final files = result.sourceProvenanceReceipt['sharedSourceFiles'] as List;
    expect((files.single as Map)['relativePath'], 'PBS/items.txt');
    expect((files.single as Map)['referenceRootPath'], shared.path);
    expect(await File('${fixture.sourceRootPath}/PBS/items.txt').exists(),
        isFalse);
    await for (final entry in Directory(result.projectPath)
        .list(recursive: true, followLinks: false)) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      expect((await entry.readAsString()).contains(shared.path), isFalse);
    }
  });

  test('segmented recipe rejects a resigned larger embedded set budget', () {
    final recipe = pairRecipe(_recipePairSet());
    final body = jsonDecode(recipe.encode()) as Map<String, dynamic>;
    body.remove('canonicalHash');
    final settings = body['settings'] as Map<String, dynamic>;
    (settings['writeLimits'] as Map<String, dynamic>)['maxMutations'] = 256;
    final identity = Map<String, Object?>.from(settings)..remove('reviewSet');
    identity['reviewSetHash'] = recipe.settings.reviewSet!.canonicalHash.value;
    body['settingsHash'] = canonicalHashOf(identity).value;
    body['canonicalHash'] =
        canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
            .value;
    expect(() => ConverterStudyPlanRecipe.fromJson(body),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('segmented recipe rejects changed content inside the other map', () {
    final recipe = pairRecipe(_recipePairSet());
    final body = jsonDecode(recipe.encode()) as Map<String, dynamic>;
    final reviewSet = (body['settings'] as Map)['reviewSet'] as Map;
    final row = (reviewSet['segments'] as List).last as Map;
    final child = row['session'] as Map;
    final candidates = child['candidateVersions'] as Map;
    (candidates.values.first as Map)['name'] = 'Changed second map';
    body.remove('canonicalHash');
    body['canonicalHash'] =
        canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
            .value;
    expect(() => ConverterStudyPlanRecipe.fromJson(body),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('segmented recipe refuses a resigned version 2 without a legacy reader',
      () {
    final body = jsonDecode(pairRecipe(_recipePairSet()).encode())
        as Map<String, dynamic>;
    body.remove('canonicalHash');
    body['version'] = 2;
    body['canonicalHash'] =
        canonicalHashOf(body, limits: ConverterStudyPlanRecipe.jsonLimits)
            .value;
    expect(() => ConverterStudyPlanRecipe.fromJson(body),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('segmented recipe retains the portable 4 MiB UTF8 byte bound', () {
    final reviewSet = _recipePairSet(uncertainty: '漢' * 1000, countPerMap: 12);
    expect(utf8.encode(canonicalJsonOf(reviewSet.toJson())).length,
        greaterThan(ConverterStudyPlanRecipe.maxFileBytes));
    expect(
        () => pairRecipe(reviewSet),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((e) => e.code, 'code', 'workflow.recipe.quota')));
  });

  test(
      'segmented portable recipe restores approved reviews in a fresh workflow',
      () async {
    fixture = (await OriginalAssetFixture.create(
            sourceRootPath: fixture.sourceRootPath!))
        .literalFixture;
    final snapshot = await original.scanSource(ConverterSourceSelection(
        rootPath: fixture.sourceRootPath!,
        logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace));
    ConverterStudySettings settings({ConverterAssetReviewSet? reviewSet}) =>
        ConverterStudySettings(
            projectName: 'Original portable pair',
            parentPath: output.path,
            folderName: 'original-study',
            selectedSourceMapIds: [1, 8],
            assetOutputMode: AssetOutputMode.standaloneObjects,
            reviewSet: reviewSet,
            writeLimits: const NativeWriteLimits(maxMutations: 512),
            profileAcknowledgement: SourceStudyAcknowledgement(
                sourceSnapshotHash: snapshot.canonicalHash,
                profileEvidenceHash: snapshot.profile.evidenceHash,
                humanConfirmed: true,
                reason: 'Original pair without external assets'));
    original.updateSettings(settings());
    final initial = await original.prepareStudy();
    var reviewed = initial.reviewSet!;
    for (final mapId in reviewed.segments.keys) {
      final child = reviewed.segments[mapId]!;
      final candidate = child.activeCandidates.first;
      final named = child.editMetadata(
          candidateId: candidate.candidateId,
          expectedCandidateHash: candidate.canonicalHash,
          expectedSessionHash: child.canonicalHash,
          name: 'Reviewed map $mapId',
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
    original.updateSettings(settings(reviewSet: reviewed));
    final prepared = await original.prepareStudy();
    final recipe = ConverterStudyPlanRecipe.decode(
        original.exportStudyPlanRecipe().encode());
    final fresh = await restored.restoreStudyPlanRecipe(recipe);
    expect(fresh.reviewSet!.toJson(), reviewed.toJson());
    expect(
        fresh.nativeDraft!.canonicalHash, prepared.nativeDraft!.canonicalHash);
    expect(fresh.preparationHash, prepared.preparationHash);
    expect(fresh.approvedCandidateHashes, reviewed.approvedCandidateHashes);
    expect(fresh.approvedCandidateHashes, hasLength(2));
    expect(restored.state.approval, isNull);
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('plan budget recipe and resume preserve default custom and world limits',
      () {
    final policies = [
      const NativeWriteLimits(),
      const NativeWriteLimits(
          jsonLimits: ContractLimits(maxTextCodeUnits: 4000)),
      const NativeWriteLimits(
          jsonLimits: ContractLimits(maxTextCodeUnits: 4000),
          planJsonLimits: ContractLimits(
              maxDepth: 8,
              maxNodes: 300,
              maxStringCodeUnits: 500,
              maxTextCodeUnits: 6000)),
      sourceCatalogStudyWriteLimitsFor(1),
      sourceCatalogStudyWriteLimitsFor(383),
    ];
    final hashes = <Sha256Hash>{};
    for (final limits in policies) {
      final recipe = connectionRecipe(2, writeLimits: limits);
      final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
      expect(decoded.toJson(), recipe.toJson());
      expect(decoded.settings.writeLimits.planJsonLimits.maxTextCodeUnits,
          limits.planJsonLimits.maxTextCodeUnits);
      expect(decoded.settings.writeLimits.jsonLimits.maxTextCodeUnits,
          limits.jsonLimits.maxTextCodeUnits);
      hashes.add(recipe.settings.canonicalHash);
      final resume = LocalReviewResumeSettings(
          sourceRootPath: fixture.sourceRootPath!,
          destinationParentPath: output.path,
          projectName: 'Original plan policy',
          folderName: 'plan-policy',
          writeLimits: limits);
      final restored = LocalReviewResumeSettings.fromJson(resume.toJson());
      expect(restored.toJson(), resume.toJson());
      expect(restored.writeLimits.planJsonLimits.maxTextCodeUnits,
          limits.planJsonLimits.maxTextCodeUnits);
    }
    expect(hashes, hasLength(policies.length));
  });

  for (final legacy in ['recipe', 'settings', 'missing-plan']) {
    test('plan budget rejects resigned legacy $legacy', () {
      final recipe = connectionRecipe(2);
      final body = jsonDecode(recipe.encode()) as Map<String, Object?>;
      body.remove('canonicalHash');
      if (legacy == 'recipe') body['version'] = 7;
      final settings = body['settings'] as Map<String, Object?>;
      if (legacy == 'settings') settings['version'] = 4;
      if (legacy == 'missing-plan') {
        (settings['writeLimits'] as Map).remove('planJsonLimits');
      }
      body['settingsHash'] = canonicalHashOf(settings).value;
      expect(
          () => ConverterStudyPlanRecipe.fromJson({
                ...body,
                'canonicalHash': canonicalHashOf(body,
                        limits: ConverterStudyPlanRecipe.jsonLimits)
                    .value
              }),
          throwsA(isA<ConverterWorkflowFailure>().having(
              (error) => error.code, 'code', 'workflow.recipe.invalid')));
    });
  }

  test('world aggregate plan budget is explicit and bound into the recipe', () {
    final recipe =
        connectionRecipe(2, writeLimits: sourceCatalogStudyWriteLimitsFor(383));
    final settings = recipe.toJson()['settings'] as Map;
    final write = settings['writeLimits'] as Map;
    expect(write['planJsonLimits'], {
      'maxDepth': 64,
      'maxNodes': 4000000,
      'maxStringCodeUnits': 1048576,
      'maxTextCodeUnits': 25165824,
    });
    expect(settings['version'], 8);
    expect(recipe.toJson()['version'], 11);
  });

  test('aggregate image budget recipe preserves explicit boundaries and hashes',
      () {
    for (final total in [1, 16777216, 33554432]) {
      final recipe = connectionRecipe(2,
          writeLimits: NativeWriteLimits(maxTotalImagePixels: total));
      final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
      expect(decoded.settings.writeLimits.maxTotalImagePixels, total);
      expect(decoded.settings.writeLimits.maxImagePixels, 16777216);
      expect(decoded.settings.canonicalHash, recipe.settings.canonicalHash);
      expect(decoded.canonicalHash, recipe.canonicalHash);
      expect((recipe.toJson()['settings'] as Map)['version'], 8);
    }
    final low = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(maxTotalImagePixels: 16777216));
    final high = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(maxTotalImagePixels: 33554432));
    expect(low.settings.canonicalHash, isNot(high.settings.canonicalHash));
    expect(low.canonicalHash, isNot(high.canonicalHash));
  });

  test('aggregate image budget recipe refuses missing required total', () {
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            changedImageTotal(null, remove: true)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'workflow.recipe.invalid')));
  });

  test('aggregate image budget recipe refuses resigned prior version 4', () {
    expect(
        () => ConverterStudyPlanRecipe.fromJson(
            changedImageTotal(16777216, version: 4)),
        throwsA(isA<ConverterWorkflowFailure>()
            .having((error) => error.code, 'code', 'workflow.recipe.invalid')));
  });

  for (final value in [null, true, 0, -1, 41943041, 2.5, '2']) {
    test('aggregate image budget recipe refuses resigned invalid total $value',
        () {
      expect(
          () => ConverterStudyPlanRecipe.fromJson(changedImageTotal(value)),
          throwsA(isA<ConverterWorkflowFailure>().having(
              (error) => error.code, 'code', 'workflow.recipe.invalid')));
    });
  }

  test('aggregate image budget survives fresh restore without approval',
      () async {
    final prepared = await prepare(
        writeLimits: const NativeWriteLimits(maxTotalImagePixels: 33554432));
    final recipe = ConverterStudyPlanRecipe.decode(
        original.exportStudyPlanRecipe().encode());
    final fresh = await restored.restoreStudyPlanRecipe(recipe);
    expect(restored.state.settings!.writeLimits.maxTotalImagePixels, 33554432);
    expect(fresh.settings.writeLimits.maxImagePixels, 16777216);
    expect(fresh.preparationHash, prepared.preparationHash);
    expect(fresh.nativeDraft!.canonicalHash, recipe.nativeDraftHash);
    expect(restored.state.approval, isNull);
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

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

  test('an imported recipe preserves its explicit aggregate text quota', () {
    final recipe = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(
            jsonLimits: ContractLimits(maxTextCodeUnits: 4194304)));
    final decoded = ConverterStudyPlanRecipe.decode(recipe.encode());
    expect(decoded.settings.writeLimits.jsonLimits.maxTextCodeUnits, 4194304);
    expect(decoded.settings.canonicalHash, recipe.settings.canonicalHash);
    expect(decoded.canonicalHash, recipe.canonicalHash);
  });

  test('draft JSON budget settings and recipe hashes distinguish limits', () {
    final two = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(maxTotalDraftJsonBytes: 2));
    final three = connectionRecipe(2,
        writeLimits: const NativeWriteLimits(maxTotalDraftJsonBytes: 3));
    expect(two.settings.canonicalHash, isNot(three.settings.canonicalHash));
    expect(two.canonicalHash, isNot(three.canonicalHash));
  });

  test('ordered source recipe emits breaking version 11', () {
    expect(connectionRecipe(2).toJson()['version'], 11);
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
          throwsA(isA<ConverterWorkflowFailure>().having(
              (error) => error.code, 'code', 'workflow.recipe.invalid')));
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
    expect(
        restored.state.settings!.writeLimits.maxTotalDraftJsonBytes, 134217728);
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

  for (final dynamicTransfer in [false, true]) {
  test(
      'recipe retains custom budgets scan policy dependency locators and review seed dynamic=$dynamicTransfer',
      () async {
    fixture = await LiteralTileFixture.create(
        sourceRootPath: fixture.sourceRootPath!,
        maps: [
          LiteralFixtureMap(id: 1, warpParameters: [
            [dynamicTransfer ? 1 : 0, 8, 1, 1, 2, 0]
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
            ConverterAssetReviewSet? review}) =>
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
            reviewSet: review,
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
        targetSourceMapId: dynamicTransfer ? null : 8,
        decision: LiteralDependencyDisposition.excludeStudy);
    original.updateSettings(
        settings(decisions: [decision], review: initial.reviewSet));
    final prepared = await original.prepareStudy();
    final recipe = ConverterStudyPlanRecipe.fromJson(
        original.exportStudyPlanRecipe().toJson());
    final fresh = await restored.restoreStudyPlanRecipe(recipe);
    expect(fresh.preparationHash, prepared.preparationHash);
    expect(fresh.settings.canonicalHash, prepared.settings.canonicalHash);
    expect(fresh.settings.dependencyDecisions.single.locator.toJson(),
        decision.locator.toJson());
    expect(fresh.settings.dependencyDecisions.single.targetSourceMapId,
        dynamicTransfer ? isNull : 8);
    expect(restored.state.source!.policy.limits.maxEntries, 128);
  }, skip: !Platform.isMacOS);
  }

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

ConverterAssetReviewSet _recipePairSet(
    {int countPerMap = 1, String uncertainty = ''}) {
  final template = _recipeCandidate().toJson();
  final children = <int, AssetReviewSession>{};
  for (final mapId in [1, 8]) {
    final candidates = <AssetCandidate>[];
    for (var index = 0; index < countPerMap; index++) {
      final body = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
      body['candidateId'] = 'map-$mapId-seed-$index';
      if (uncertainty.isNotEmpty) {
        body['uncertainties'] = List.filled(64, uncertainty);
      }
      final part = (body['parts'] as List).single as Map<String, dynamic>;
      (part['locator'] as Map<String, dynamic>)['mapId'] = mapId;
      (part['locator'] as Map<String, dynamic>)['file'] =
          "Data/Map${mapId.toString().padLeft(3, '0')}.rxdata";
      candidates.add(AssetCandidate.fromJson(body));
    }
    children[mapId] = AssetReviewSession.create(
        sessionId: ConverterId('pair-map-$mapId'),
        logicalProjectNamespace: ConverterId('original-project'),
        sourceSnapshotHash: Sha256Hash('a' * 64),
        selectedSourceMapIds: [1, 8],
        outputMode: AssetOutputMode.standaloneObjects,
        proposalGenerationHash: Sha256Hash(mapId == 1 ? 'b' * 64 : 'c' * 64),
        candidates: candidates);
  }
  return ConverterAssetReviewSet.create(
      sessionId: ConverterId('pair-review'),
      logicalProjectNamespace: ConverterId('original-project'),
      sourceSnapshotHash: Sha256Hash('a' * 64),
      normalizedSourceHash: Sha256Hash('e' * 64),
      selectedSourceMapIds: [1, 8],
      proposalSourceMapIds: [1, 8],
      segments: children,
      limits: converterAssetReviewSetLimitsFor(
          const NativeWriteLimits(maxMutations: 512)));
}

AssetCandidate _recipeCandidate() => AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': 'tree',
      'revision': 1,
      'logicalProjectNamespace': 'original-project',
      'sourceSnapshotHash': 'a' * 64,
      'sources': [
        {
          'fileId': 'image-original',
          'contentHash': 'c' * 64,
          'pixelWidth': 32,
          'pixelHeight': 32
        }
      ],
      'name': 'Arbre original',
      'category': 'nature',
      'state': 'needsReview',
      'parts': [
        {
          'partId': 'part-original',
          'sourceFileId': 'image-original',
          'sourceRect': {'x': 0, 'y': 0, 'width': 32, 'height': 32},
          'destinationOffset': {'x': 0, 'y': 0},
          'sourceLayer': 0,
          'sourcePriority': 0,
          'quarterTurns': 0,
          'reflected': false,
          'locator': {
            'file': 'Data/Map001.rxdata',
            'mapId': 1,
            'eventId': null,
            'pageIndex': null,
            'commandIndex': null,
            'tileId': 384,
            'line': null
          }
        }
      ],
      'canvasSize': {'width': 32, 'height': 32},
      'anchor': {
        'unit': 'pixel',
        'x': 16,
        'y': 32,
        'convention': 'bottomCenter'
      },
      'integrationMode': 'libraryOnly',
      'outputMode': 'standaloneObjects',
      'evidence': <Object?>[],
      'uncertainties': <String>[],
      'approvedRevision': null,
    });
