import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory temporary;
  late Directory root;
  late Directory source;
  late Directory destination;
  late LocalReviewResumeSettings settings;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('ac10-store-test-');
    temporary = Directory(await temporary.resolveSymbolicLinks());
    root = await Directory(path.join(temporary.path, 'sessions')).create();
    source = await Directory(path.join(temporary.path, 'source')).create();
    destination =
        await Directory(path.join(temporary.path, 'destination')).create();
    await File(path.join(source.path, 'original')).writeAsString('original');
    settings = LocalReviewResumeSettings(
      sourceRootPath: source.path,
      destinationParentPath: destination.path,
      projectName: 'Projet original',
      folderName: 'conversion',
    );
  });

  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  LocalReviewSessionStore store(
          {LocalReviewSessionStoreLimits? limits,
          LocalReviewSessionWriteCheckpoint? checkpoint}) =>
      LocalReviewSessionStore(
          rootPath: root.path,
          limits: limits ?? const LocalReviewSessionStoreLimits(),
          checkpoint: checkpoint);

  Map<String, Object?> changedResumeBudget(
      String group, String field, Object? value,
      {bool remove = false}) {
    final body =
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>;
    final limits = body[group] as Map<String, dynamic>;
    if (remove) {
      limits.remove(field);
    } else {
      limits[field] = value;
    }
    return body;
  }

  LocalReviewResumeSettings segmentedSettings() => LocalReviewResumeSettings(
      sourceRootPath: source.path,
      destinationParentPath: destination.path,
      projectName: settings.projectName,
      folderName: settings.folderName,
      writeLimits: const NativeWriteLimits(maxMutations: 512));

  test('segmented store preserves 280 candidates without partial disk records',
      () async {
    final reviewSet = _pairSet(countPerMap: 140);
    final created = await store()
        .create(reviewSet: reviewSet, resumeSettings: segmentedSettings());
    final loaded = (await store().load(reviewSet.sessionId))!;
    expect(loaded.reviewSet.segments.keys, [1, 8]);
    expect(loaded.reviewSet.activeCandidates, hasLength(280));
    expect(loaded.toJson(), created.toJson());
    expect(
        loaded.canonicalHash,
        canonicalHashOf(loaded.toJson(),
            limits: const LocalReviewSessionStoreLimits().jsonLimits));
    expect(
        (await root.list().toList())
            .where((f) => f.path.endsWith('.session.json')),
        hasLength(1));
  });

  for (final rewind in [true, false]) {
    test(
        'segmented store CAS refuses ${rewind ? 'a lower' : 'an equal changed'} child revision despite global progress',
        () async {
      ConverterAssetReviewSet edit(
          ConverterAssetReviewSet set, int mapId, String name) {
        final child = set.segments[mapId]!;
        final candidate = child.activeCandidates.single;
        final edited = child.editMetadata(
            candidateId: candidate.candidateId,
            expectedCandidateHash: candidate.canonicalHash,
            expectedSessionHash: child.canonicalHash,
            name: name);
        return set.replaceSegment(
            sourceMapId: mapId,
            next: edited,
            expectedSetHash: set.canonicalHash,
            expectedSegmentHash: child.canonicalHash);
      }

      final seed = _pairSet();
      final reviewed = edit(seed, 1, 'Saved first map');
      final created = await store()
          .create(reviewSet: reviewed, resumeSettings: segmentedSettings());
      var alternative = rewind ? seed : edit(seed, 1, 'Conflicting first map');
      alternative = edit(alternative, 8, 'Other map progress');
      if (rewind) {
        alternative = edit(alternative, 8, 'Further other map progress');
      }
      expect(alternative.revision, greaterThan(reviewed.revision));
      await expectLater(
          store().compareAndSwap(
              reviewSet: alternative,
              resumeSettings: segmentedSettings(),
              expectedStoredRevision: created.storedRevision,
              expectedCanonicalHash: created.canonicalHash),
          _error('session.store.domain_revision'));
      expect(
          (await store().load(reviewed.sessionId))!.toJson(), created.toJson());
    });
  }

  test(
      'segmented store CAS changes one segment and retains the other history exactly',
      () async {
    final original = _pairSet();
    final first = original.segments[1]!;
    final secondJson = original.segments[8]!.toJson();
    final created = await store()
        .create(reviewSet: original, resumeSettings: segmentedSettings());
    final candidate = first.activeCandidates.single;
    final edited = first.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: first.canonicalHash,
        name: 'Correction carte 1');
    final next = original.replaceSegment(
        sourceMapId: 1,
        next: edited,
        expectedSetHash: original.canonicalHash,
        expectedSegmentHash: first.canonicalHash);
    final saved = await store().compareAndSwap(
        reviewSet: next,
        resumeSettings: segmentedSettings(),
        expectedStoredRevision: created.storedRevision,
        expectedCanonicalHash: created.canonicalHash);
    expect(saved.reviewSet.segments[1]!.toJson(), edited.toJson());
    expect(saved.reviewSet.segments[8]!.toJson(), secondJson);
    await expectLater(
        store().compareAndSwap(
            reviewSet: original,
            resumeSettings: segmentedSettings(),
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        _error('session.store.conflict'));
    expect((await store().load(original.sessionId))!.toJson(), saved.toJson());
  });

  test(
      'segmented store refuses a larger embedded admission budget before writing',
      () async {
    await expectLater(
        store().create(
            reviewSet: _pairSet(countPerMap: 140), resumeSettings: settings),
        _error('session.store.document'));
    expect(await root.list().toList(), isEmpty);
  });

  test(
      'segmented store applies caller JSON bounds to the full envelope before writing',
      () async {
    await expectLater(
        store(
                limits: const LocalReviewSessionStoreLimits(
                    jsonLimits: ContractLimits(maxTextCodeUnits: 1000)))
            .create(reviewSet: _pairSet(), resumeSettings: segmentedSettings()),
        _error('session.store.quota'));
    expect(await root.list().toList(), isEmpty);
  });

  test('segmented store refuses version 1 and preserves its bytes', () async {
    final created = await store()
        .create(reviewSet: _pairSet(), resumeSettings: segmentedSettings());
    final file = await _sessionFile(root);
    final old = jsonEncode({...created.toJson(), 'version': 1});
    await file.writeAsString(old);
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.document'));
    expect(await file.readAsString(), old);
  });

  test(
      'shared reference survives review disk reopen and protects source storage',
      () async {
    final shared = await Directory('${temporary.path}/shared').create();
    final withShared = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        supplementalRootPaths: [shared.path],
        sharedSourceFiles: [
          for (var index = 0; index < 610; index++)
            ConverterSharedSourceFile(
                relativePath:
                    index == 609 ? 'Game.exe' : 'Graphics/Pictures/$index.png',
                referenceRootPath: shared.path,
                fileId: ConverterId('shared-$index'),
                sha256: Sha256Hash('a' * 64))
        ],
        destinationParentPath: destination.path,
        projectName: settings.projectName,
        folderName: settings.folderName);
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: withShared);
    final loaded = (await store().load(created.reviewSet.sessionId))!;
    expect(loaded.resumeSettings.supplementalRootPaths, [shared.path]);
    expect(loaded.resumeSettings.sharedSourceFiles.length, 610);
    expect(loaded.canonicalHash, created.canonicalHash);
    final nested = LocalReviewSessionStore(rootPath: '${shared.path}/sessions');
    await expectLater(
        nested.create(
            reviewSet: _reviewSet(_session()), resumeSettings: withShared),
        _error('session.store.overlap'));
    final previous = {...created.toJson(), 'version': 5};
    expect(() => StoredReviewSession.fromJson(previous),
        _error('session.store.document'));
  });

  for (final world in [false, true]) {
    test('plan budget resume survives exact disk reopen world=$world',
        () async {
      final limits = world
          ? sourceCatalogStudyWriteLimitsFor(383)
          : const NativeWriteLimits(
              planJsonLimits: ContractLimits(maxTextCodeUnits: 200000));
      final custom = LocalReviewResumeSettings(
          sourceRootPath: source.path,
          destinationParentPath: destination.path,
          projectName: settings.projectName,
          folderName: settings.folderName,
          writeLimits: limits);
      final created = await store().create(
          reviewSet: _reviewSet(_session(), writeLimits: limits),
          resumeSettings: custom);
      final loaded = (await store().load(created.reviewSet.sessionId))!;
      expect(loaded.resumeSettings.toJson(), custom.toJson());
      expect(loaded.resumeSettings.writeLimits.planJsonLimits.maxTextCodeUnits,
          limits.planJsonLimits.maxTextCodeUnits);
      expect(loaded.canonicalHash, created.canonicalHash);
    });
  }

  test('plan budget store refuses prior version 6', () {
    final stored = StoredReviewSession(
        reviewSet: _reviewSet(_session()),
        resumeSettings: settings,
        storedRevision: 1);
    expect(
        () => StoredReviewSession.fromJson({...stored.toJson(), 'version': 6}),
        _error('session.store.document'));
  });

  test('shared source store emits breaking version 8', () {
    final stored = StoredReviewSession(
        reviewSet: _reviewSet(_session()),
        resumeSettings: settings,
        storedRevision: 1);
    expect(stored.toJson()['version'], 8);
  });

  test('aggregate image budget resume survives exact disk reopen', () async {
    final custom = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        destinationParentPath: destination.path,
        projectName: settings.projectName,
        folderName: settings.folderName,
        writeLimits: const NativeWriteLimits(maxTotalImagePixels: 33554432));
    final created = await store().create(
        reviewSet: _reviewSet(_session(), writeLimits: custom.writeLimits),
        resumeSettings: custom);
    final loaded = (await store().load(created.reviewSet.sessionId))!;
    expect(loaded.resumeSettings.writeLimits.maxTotalImagePixels, 33554432);
    expect(loaded.resumeSettings.writeLimits.maxImagePixels, 16777216);
    expect(loaded.resumeSettings.toJson(), custom.toJson());
    expect(loaded.canonicalHash, created.canonicalHash);
    expect(loaded.toJson()['version'], 8);
  });

  test('aggregate image budget resume boundaries alter envelope hashes', () {
    StoredReviewSession envelope(int total) => StoredReviewSession(
        reviewSet: _reviewSet(_session()),
        storedRevision: 1,
        resumeSettings: LocalReviewResumeSettings(
            sourceRootPath: source.path,
            destinationParentPath: destination.path,
            projectName: settings.projectName,
            folderName: settings.folderName,
            writeLimits: NativeWriteLimits(maxTotalImagePixels: total)));
    for (final total in [1, 16777216, 33554432]) {
      final row = envelope(total);
      expect(
          LocalReviewResumeSettings.fromJson(row.resumeSettings.toJson())
              .writeLimits
              .maxTotalImagePixels,
          total);
    }
    expect(envelope(16777216).canonicalHash,
        isNot(envelope(33554432).canonicalHash));
  });

  test('aggregate image budget resume refuses missing required total', () {
    expect(
        () => LocalReviewResumeSettings.fromJson(changedResumeBudget(
            'writeLimits', 'maxTotalImagePixels', null,
            remove: true)),
        _error('session.store.document'));
  });

  test('aggregate image budget store rejects prior version without rewriting',
      () async {
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    final file = await _sessionFile(root);
    final prior = jsonEncode({...created.toJson(), 'version': 3});
    await file.writeAsString(prior);
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.document'));
    expect(await file.readAsString(), prior);
  });

  for (final total in [null, true, 0, -1, 41943041, 2.5, '2']) {
    test('aggregate image budget resume refuses invalid total $total', () {
      expect(
          () => LocalReviewResumeSettings.fromJson(
              changedResumeBudget('writeLimits', 'maxTotalImagePixels', total)),
          _error('session.store.document'));
    });
  }

  test('draft JSON budget resume survives exact disk reopen', () async {
    final custom = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        destinationParentPath: destination.path,
        projectName: settings.projectName,
        folderName: settings.folderName,
        writeLimits:
            const NativeWriteLimits(maxTotalDraftJsonBytes: 134217728));
    final created = await store().create(
        reviewSet: _reviewSet(_session(), writeLimits: custom.writeLimits),
        resumeSettings: custom);
    final loaded = (await store().load(created.reviewSet.sessionId))!;
    expect(loaded.resumeSettings.writeLimits.maxTotalDraftJsonBytes, 134217728);
    expect(loaded.resumeSettings.toJson(), custom.toJson());
    expect(loaded.canonicalHash, created.canonicalHash);
  });

  test('draft JSON budget resume preserves both admitted boundaries', () {
    for (final budget in [1, 67108864, 268435456]) {
      final custom = LocalReviewResumeSettings(
          sourceRootPath: source.path,
          destinationParentPath: destination.path,
          projectName: settings.projectName,
          folderName: settings.folderName,
          writeLimits: NativeWriteLimits(maxTotalDraftJsonBytes: budget));
      final loaded = LocalReviewResumeSettings.fromJson(custom.toJson());
      expect(loaded.writeLimits.maxTotalDraftJsonBytes, budget);
    }
  });

  test('draft JSON budget resume envelope hashes distinguish limits', () {
    StoredReviewSession envelope(int budget) => StoredReviewSession(
        reviewSet: _reviewSet(_session()),
        storedRevision: 1,
        resumeSettings: LocalReviewResumeSettings(
            sourceRootPath: source.path,
            destinationParentPath: destination.path,
            projectName: settings.projectName,
            folderName: settings.folderName,
            writeLimits: NativeWriteLimits(maxTotalDraftJsonBytes: budget)));
    expect(envelope(67108864).canonicalHash,
        isNot(envelope(134217728).canonicalHash));
  });

  test('draft JSON budget resume refuses missing required field', () {
    expect(
        () => LocalReviewResumeSettings.fromJson(changedResumeBudget(
            'writeLimits', 'maxTotalDraftJsonBytes', null,
            remove: true)),
        _error('session.store.document'));
  });

  for (final invalid in [null, true, 0, -1, 268435457, 2.5, '2']) {
    test('draft JSON budget resume refuses invalid value $invalid', () {
      expect(
          () => LocalReviewResumeSettings.fromJson(changedResumeBudget(
              'writeLimits', 'maxTotalDraftJsonBytes', invalid)),
          _error('session.store.document'));
    });
  }

  test('connection quota resume survives exact disk reopen', () async {
    final custom = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        destinationParentPath: destination.path,
        projectName: settings.projectName,
        folderName: settings.folderName,
        normalizationLimits:
            const SourceNormalizationLimits(maxConnections: 2));
    final created = await store().create(
        reviewSet: _reviewSet(_session(), writeLimits: custom.writeLimits),
        resumeSettings: custom);
    final loaded = (await store().load(created.reviewSet.sessionId))!;
    expect(loaded.resumeSettings.normalizationLimits.maxConnections, 2);
    expect(loaded.resumeSettings.toJson(), custom.toJson());
    expect(loaded.canonicalHash, created.canonicalHash);
  });

  test('connection quota resume preserves both admitted boundaries', () {
    for (final quota in [1, 16384, 65536]) {
      final custom = LocalReviewResumeSettings(
          sourceRootPath: source.path,
          destinationParentPath: destination.path,
          projectName: settings.projectName,
          folderName: settings.folderName,
          normalizationLimits:
              SourceNormalizationLimits(maxConnections: quota));
      final loaded = LocalReviewResumeSettings.fromJson(custom.toJson());
      expect(loaded.normalizationLimits.maxConnections, quota);
    }
  });

  test('connection quota resume envelope hashes distinguish limits', () {
    StoredReviewSession envelope(int quota) => StoredReviewSession(
        reviewSet: _reviewSet(_session()),
        storedRevision: 1,
        resumeSettings: LocalReviewResumeSettings(
            sourceRootPath: source.path,
            destinationParentPath: destination.path,
            projectName: settings.projectName,
            folderName: settings.folderName,
            normalizationLimits:
                SourceNormalizationLimits(maxConnections: quota)));
    expect(envelope(2).canonicalHash, isNot(envelope(3).canonicalHash));
  });

  test('connection quota resume refuses missing required field', () {
    expect(
        () => LocalReviewResumeSettings.fromJson(changedResumeBudget(
            'normalizationLimits', 'maxConnections', null,
            remove: true)),
        _error('session.store.document'));
  });

  for (final invalid in [null, true, 0, -1, 65537, 2.5, '2']) {
    test('connection quota resume refuses invalid value $invalid', () {
      expect(
          () => LocalReviewResumeSettings.fromJson(changedResumeBudget(
              'normalizationLimits', 'maxConnections', invalid)),
          _error('session.store.document'));
    });
  }

  test('create and reopen preserve exact review history and envelope',
      () async {
    final initial = _session();
    final reviewed = initial.decide(
        candidateId: ConverterId('tree'),
        expectedCandidateHash: initial.activeCandidates.single.canonicalHash,
        expectedSessionHash: initial.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    final undone = reviewed.undo(expectedSessionHash: reviewed.canonicalHash);
    final created = await store()
        .create(reviewSet: _reviewSet(undone), resumeSettings: settings);
    final reopened = await store().load(undone.sessionId);
    expect(created.storedRevision, 1);
    expect(reopened, isNotNull);
    expect(reopened!.reviewSet.segments[1]!.toJson(), undone.toJson());
    expect(reopened.reviewSet.segments[1]!.canRedo, isTrue);
    expect(reopened.resumeSettings.toJson(), settings.toJson());
    expect(reopened.toJson(), created.toJson());
    expect(reopened.canonicalHash, canonicalHashOf(reopened.toJson()));
    expect(await File(path.join(source.path, 'original')).readAsString(),
        'original');
  });

  test('create refuses existing session without overwriting it', () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    await expectLater(
        store()
            .create(reviewSet: _reviewSet(session), resumeSettings: settings),
        _error('session.store.exists'));
    expect((await store().load(session.sessionId))!.canonicalHash,
        created.canonicalHash);
  });

  test('CAS keeps stored revision separate from the domain revision', () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    final renamed = session.editMetadata(
        candidateId: ConverterId('tree'),
        expectedCandidateHash: session.activeCandidates.single.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Arbre corrigé');
    final approved = renamed.decide(
        candidateId: ConverterId('tree'),
        expectedCandidateHash: renamed.activeCandidates.single.canonicalHash,
        expectedSessionHash: renamed.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    final saved = await store().compareAndSwap(
        reviewSet: _reviewSet(approved),
        resumeSettings: settings,
        expectedStoredRevision: created.storedRevision,
        expectedCanonicalHash: created.canonicalHash);
    expect(saved.storedRevision, 2);
    expect(saved.reviewSet.segments[1]!.revision, 3);
    expect((await store().load(session.sessionId))!.toJson(), saved.toJson());
  });

  test('metadata-only CAS advances envelope revision and hash', () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    final changed = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        destinationParentPath: destination.path,
        projectName: 'Autre nom',
        folderName: 'conversion',
        allowFirstFrameAutotiles: true);
    final saved = await store().compareAndSwap(
        reviewSet: _reviewSet(session),
        resumeSettings: changed,
        expectedStoredRevision: created.storedRevision,
        expectedCanonicalHash: created.canonicalHash);
    expect(saved.reviewSet.canonicalHash, created.reviewSet.canonicalHash);
    expect(saved.storedRevision, 2);
    expect(saved.canonicalHash, isNot(created.canonicalHash));
    await expectLater(
        store().compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        _error('session.store.conflict'));
  });

  test('CAS rejects exact revision with a different envelope hash', () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    await expectLater(
        store().compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: Sha256Hash('0' * 64)),
        _error('session.store.conflict'));
    expect((await store().load(session.sessionId))!.canonicalHash,
        created.canonicalHash);
  });

  test('CAS rejects a lower domain revision and a changed source context',
      () async {
    final session = _session();
    final renamed = session.editMetadata(
        candidateId: ConverterId('tree'),
        expectedCandidateHash: session.activeCandidates.single.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Arbre corrigé');
    final created = await store()
        .create(reviewSet: _reviewSet(renamed), resumeSettings: settings);
    await expectLater(
        store().compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        _error('session.store.domain_revision'));
    final otherSource = AssetReviewSession.create(
      sessionId: session.sessionId,
      logicalProjectNamespace: session.logicalProjectNamespace,
      sourceSnapshotHash: Sha256Hash('f' * 64),
      selectedSourceMapIds: session.selectedSourceMapIds,
      outputMode: session.outputMode,
      proposalGenerationHash: session.proposalGenerationHash,
      candidates: [
        AssetCandidate.fromJson({
          ...session.activeCandidates.single.toJson(),
          'sourceSnapshotHash': 'f' * 64,
        })
      ],
    );
    final changed = otherSource.editMetadata(
        candidateId: ConverterId('tree'),
        expectedCandidateHash:
            otherSource.activeCandidates.single.canonicalHash,
        expectedSessionHash: otherSource.canonicalHash,
        name: 'Arbre corrigé');
    await expectLater(
        store().compareAndSwap(
            reviewSet: _reviewSet(changed),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        _error('session.store.source_changed'));
  });

  test('two same-isolate instances cannot overwrite a concurrent CAS',
      () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    Future<Object> save(String name) async {
      try {
        return await store().compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: LocalReviewResumeSettings(
                sourceRootPath: source.path,
                destinationParentPath: destination.path,
                projectName: name,
                folderName: 'conversion'),
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash);
      } on LocalReviewSessionStoreFailure catch (error) {
        return error;
      }
    }

    final results =
        await Future.wait([save('Première fenêtre'), save('Deuxième fenêtre')]);
    expect(results.whereType<StoredReviewSession>().length, 1);
    expect(results.whereType<LocalReviewSessionStoreFailure>().single.code,
        'session.store.conflict');
    expect((await store().load(session.sessionId))!.storedRevision, 2);
  });

  test('different session IDs cannot concurrently exceed the store quota',
      () async {
    final firstBeforePublish = Completer<void>();
    final secondFinished = Completer<void>();
    Future<Object> create(String id, {bool pause = false}) async {
      try {
        return await store(
          limits: const LocalReviewSessionStoreLimits(maxSessions: 1),
          checkpoint: pause
              ? (stage, _) async {
                  if (stage == LocalReviewSessionWriteStage.beforePublish) {
                    firstBeforePublish.complete();
                    await secondFinished.future.timeout(
                      const Duration(seconds: 5),
                      onTimeout: () {},
                    );
                  }
                }
              : null,
        ).create(reviewSet: _reviewSet(_session(id)), resumeSettings: settings);
      } on LocalReviewSessionStoreFailure catch (error) {
        return error;
      }
    }

    final first = create('quota:first', pause: true);
    await firstBeforePublish.future.timeout(const Duration(seconds: 10));
    final second = create('quota:second').whenComplete(secondFinished.complete);
    final results = await Future.wait([first, second]);
    expect(results.whereType<StoredReviewSession>().length, 1);
    expect(results.whereType<LocalReviewSessionStoreFailure>().single.code,
        'session.store.quota');
    final saved = results.whereType<StoredReviewSession>().single;
    final listed = await store(
      limits: const LocalReviewSessionStoreLimits(maxSessions: 1),
    ).list();
    expect(listed.single.canonicalHash, saved.canonicalHash);
    expect((await store().load(saved.reviewSet.sessionId))!.canonicalHash,
        saved.canonicalHash);
  });

  test('failure before publication preserves the previous canonical file',
      () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    final interrupted = store(checkpoint: (stage, _) {
      if (stage == LocalReviewSessionWriteStage.beforePublish) {
        throw StateError('controlled interruption');
      }
    });
    await expectLater(
        interrupted.compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        throwsA(isA<StateError>()));
    expect((await store().load(session.sessionId))!.toJson(), created.toJson());
    expect(
        (await root.list().toList())
            .where((file) => file.path.endsWith('.tmp')),
        isEmpty);
  });

  test('two processes cannot publish the same expected stored version',
      () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    final script = File(path.join(temporary.path, 'cas_child.dart'));
    await script.writeAsString(_casChildScript);
    final children = <_CasChild>[];
    try {
      for (final name in ['Premier processus', 'Second processus']) {
        children.add(await _CasChild.start(
            script.path, root.path, session.sessionId.value, name));
      }
      await Future.wait(children.map((child) => child.ready.future))
          .timeout(const Duration(seconds: 40));
      for (final child in children) {
        child.process.stdin.writeln('publish');
        await child.process.stdin.flush();
      }
      final outcomes =
          await Future.wait(children.map((child) => child.result.future))
              .timeout(const Duration(seconds: 40));
      expect(outcomes.where((value) => value == 'saved').length, 1);
      expect(
          outcomes.where((value) => value == 'session.store.conflict').length,
          1);
      for (final child in children) {
        expect(
            await child.process.exitCode.timeout(const Duration(seconds: 5)), 0,
            reason: child.errorOutput.toString());
      }
      final loaded = (await store().load(session.sessionId))!;
      expect(loaded.storedRevision, created.storedRevision + 1);
      expect(loaded.resumeSettings.projectName,
          anyOf('Premier processus', 'Second processus'));
    } finally {
      for (final child in children) {
        await child.terminateOwnedIfRunning();
      }
    }
  }, timeout: const Timeout(Duration(seconds: 100)));

  test('two processes creating different IDs keep the global store quota',
      () async {
    final script = File(path.join(temporary.path, 'quota_child.dart'));
    await script.writeAsString(_quotaChildScript);
    final children = <_CasChild>[];
    try {
      for (final (id, mode) in [
        ('quota:first', 'pause'),
        ('quota:second', 'free')
      ]) {
        final seed = File(path.join(temporary.path, '$mode.json'));
        await seed.writeAsString(jsonEncode(StoredReviewSession(
          reviewSet: _reviewSet(_session(id)),
          resumeSettings: settings,
          storedRevision: 1,
        ).toJson()));
        children.add(
            await _CasChild.start(script.path, root.path, seed.path, mode));
      }
      await Future.wait(children.map((child) => child.ready.future))
          .timeout(const Duration(seconds: 40));
      children.first.process.stdin.writeln('create');
      await children.first.process.stdin.flush();
      await children.first.paused.future.timeout(const Duration(seconds: 10));
      children.last.process.stdin.writeln('create');
      await children.last.process.stdin.flush();
      await children.last.result.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => 'waiting-for-store-lock',
      );
      children.first.process.stdin.writeln('publish');
      await children.first.process.stdin.flush();
      final outcomes =
          await Future.wait(children.map((child) => child.result.future))
              .timeout(const Duration(seconds: 20));
      expect(outcomes.where((value) => value == 'saved').length, 1);
      expect(
          outcomes.where((value) => value == 'session.store.quota').length, 1);
      for (final child in children) {
        expect(
            await child.process.exitCode.timeout(const Duration(seconds: 5)), 0,
            reason: child.errorOutput.toString());
      }
      expect(
        await store(
          limits: const LocalReviewSessionStoreLimits(maxSessions: 1),
        ).list(),
        hasLength(1),
      );
    } finally {
      for (final child in children) {
        await child.terminateOwnedIfRunning();
      }
    }
  }, timeout: const Timeout(Duration(seconds: 100)));

  test('explicit policy and limits round trip without duplicate maps or mode',
      () async {
    final custom = LocalReviewResumeSettings(
      sourceRootPath: source.path,
      destinationParentPath: destination.path,
      projectName: 'Limites locales',
      folderName: 'conversion',
      allowFirstFrameAutotiles: true,
      sourceScanPolicy: SourceScanPolicy(
          limits: const SourceScanLimits(maxEntries: 17, maxDepth: 4),
          excludedSegments: ['.git', '.env', 'saves']),
      normalizationLimits: const SourceNormalizationLimits(
          maxMaps: 3, maxEvents: 7, maxCommands: 13),
      writeLimits: const NativeWriteLimits(maxArtifacts: 4, maxMutations: 20),
    );
    final created = await store().create(
        reviewSet: _reviewSet(_session(), writeLimits: custom.writeLimits),
        resumeSettings: custom);
    final loaded = (await store().load(created.reviewSet.sessionId))!;
    expect(loaded.resumeSettings.toJson(), custom.toJson());
    expect(loaded.resumeSettings.sourceScanPolicy.canonicalHash,
        custom.sourceScanPolicy.canonicalHash);
    expect(loaded.resumeSettings.normalizationLimits.maxEvents, 7);
    expect(loaded.resumeSettings.writeLimits.maxMutations, 20);
    expect(loaded.resumeSettings.toJson().containsKey('selectedSourceMapIds'),
        isFalse);
    expect(
        loaded.resumeSettings.toJson().containsKey('assetOutputMode'), isFalse);
  });

  test(
      'profile and dependency receipts preserve exact hashes without native locators',
      () async {
    final session = _session();
    final locator = session.activeCandidates.single.parts.single.locator;
    final original = LiteralDependencyDecision(
      sourceSnapshotHash: session.sourceSnapshotHash,
      selectionHash: _selectionHash(session),
      locator: locator,
      targetSourceMapId: 2,
      decision: LiteralDependencyDisposition.excludeStudy,
    );
    final receipt = LocalReviewDependencyDecision.fromDecision(original);
    final acknowledgement = LocalReviewProfileAcknowledgement(
      sourceSnapshotHash: session.sourceSnapshotHash,
      profileEvidenceHash: Sha256Hash('e' * 64),
      humanConfirmed: true,
      reason: 'Étude explicite du profil observé',
    );
    final withReceipts = LocalReviewResumeSettings(
      sourceRootPath: source.path,
      destinationParentPath: destination.path,
      projectName: settings.projectName,
      folderName: settings.folderName,
      profileAcknowledgement: acknowledgement,
      dependencyDecisions: [receipt],
    );
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: withReceipts);
    final loaded = (await store().load(session.sessionId))!;
    expect(loaded.resumeSettings.toJson(), withReceipts.toJson());
    expect(loaded.resumeSettings.profileAcknowledgement!.toJson(),
        acknowledgement.toJson());
    expect(loaded.resumeSettings.dependencyDecisions.single.locatorHash,
        canonicalHashOf(locator.toJson()));
    expect(receipt.toJson().keys.toSet(), {
      'sourceSnapshotHash',
      'selectionHash',
      'locatorHash',
      'targetSourceMapId',
      'decision'
    });
    expect(jsonEncode(receipt.toJson()), isNot(contains('Data/Map001.rxdata')));
    expect(loaded.canonicalHash, created.canonicalHash);
  });

  test('foreign source or selection receipts are refused before publication',
      () async {
    final session = _session();
    for (final receipt in [
      LocalReviewDependencyDecision(
          sourceSnapshotHash: Sha256Hash('f' * 64),
          selectionHash: _selectionHash(session),
          locatorHash: Sha256Hash('e' * 64),
          targetSourceMapId: 2,
          decision: LiteralDependencyDisposition.excludeStudy),
      LocalReviewDependencyDecision(
          sourceSnapshotHash: session.sourceSnapshotHash,
          selectionHash: Sha256Hash('f' * 64),
          locatorHash: Sha256Hash('e' * 64),
          targetSourceMapId: 2,
          decision: LiteralDependencyDisposition.excludeStudy),
    ]) {
      final invalid = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        destinationParentPath: destination.path,
        projectName: settings.projectName,
        folderName: settings.folderName,
        dependencyDecisions: [receipt],
      );
      await expectLater(
          store()
              .create(reviewSet: _reviewSet(session), resumeSettings: invalid),
          _error('session.store.context'));
    }
    final invalidAcknowledgement = LocalReviewResumeSettings(
      sourceRootPath: source.path,
      destinationParentPath: destination.path,
      projectName: settings.projectName,
      folderName: settings.folderName,
      profileAcknowledgement: LocalReviewProfileAcknowledgement(
          sourceSnapshotHash: Sha256Hash('f' * 64),
          profileEvidenceHash: Sha256Hash('e' * 64),
          humanConfirmed: true,
          reason: 'Profil source étranger'),
    );
    await expectLater(
        store().create(
            reviewSet: _reviewSet(session),
            resumeSettings: invalidAcknowledgement),
        _error('session.store.context'));
    expect(await store().load(session.sessionId), isNull);
  });

  test(
      'unknown credential fields are rejected and no credentials are serialized',
      () async {
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    final json = created.toJson();
    expect(json.keys.toSet(),
        {'kind', 'version', 'storedRevision', 'reviewSet', 'resumeSettings'});
    expect(json['resumeSettings'] is Map, isTrue);
    final file = await _sessionFile(root);
    final hostile = {...json, 'apiKey': 'sk-session-secret-lure'};
    await file.writeAsString(jsonEncode(hostile));
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.document'));
    expect(
        () => LocalReviewResumeSettings.fromJson({
              ...settings.toJson(),
              'provider': {'authorization': 'sk-session-secret-lure'},
            }),
        throwsA(isA<LocalReviewSessionStoreFailure>()));
    expect(jsonEncode(json), isNot(contains('sk-session-secret-lure')));
  });

  test('unsupported envelope versions and malformed JSON are not reset',
      () async {
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    final file = await _sessionFile(root);
    final unsupported = jsonEncode({...created.toJson(), 'version': 42});
    await file.writeAsString(unsupported);
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.document'));
    expect(await file.readAsString(), unsupported);
    await file.writeAsString('{"broken":');
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.document'));
    expect(await file.readAsString(), '{"broken":');
  });

  test(
      'load and list preserve sessions while source and target are unavailable',
      () async {
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    await source.delete(recursive: true);
    await destination.delete(recursive: true);
    expect((await store().load(created.reviewSet.sessionId))!.toJson(),
        created.toJson());
    expect((await store().list()).single.toJson(), created.toJson());
  });

  test('list is deterministic and bounded', () async {
    final first = await store().create(
        reviewSet: _reviewSet(_session('session:z')), resumeSettings: settings);
    final second = await store().create(
        reviewSet: _reviewSet(_session('session:a')), resumeSettings: settings);
    expect((await store().list()).map((item) => item.reviewSet.sessionId.value),
        [second.reviewSet.sessionId.value, first.reviewSet.sessionId.value]);
    await expectLater(
        store(limits: const LocalReviewSessionStoreLimits(maxSessions: 1))
            .list(),
        _error('session.store.quota'));
  });

  test('directory entry quotas include unrelated files without reading them',
      () async {
    await File(path.join(root.path, 'unrelated-one')).writeAsString('one');
    await File(path.join(root.path, 'unrelated-two')).writeAsString('two');
    await expectLater(
        store(
                limits:
                    const LocalReviewSessionStoreLimits(maxDirectoryEntries: 1))
            .list(),
        _error('session.store.quota'));
    expect(await File(path.join(root.path, 'unrelated-one')).readAsString(),
        'one');
  });

  test('invalid resume fields and store limits are refused before writing',
      () async {
    for (final json in [
      {...settings.toJson(), 'sourceRootPath': '../source'},
      {...settings.toJson(), 'destinationParentPath': '/tmp/../target'},
      {...settings.toJson(), 'folderName': '../overwrite'},
      {...settings.toJson(), 'projectName': ''},
      {...settings.toJson(), 'allowFirstFrameAutotiles': 'yes'},
    ]) {
      expect(() => LocalReviewResumeSettings.fromJson(json),
          throwsA(isA<LocalReviewSessionStoreFailure>()));
    }
    await expectLater(
        store(limits: const LocalReviewSessionStoreLimits(maxFileBytes: 0))
            .create(
                reviewSet: _reviewSet(_session()), resumeSettings: settings),
        _error('session.store.limits'));
    expect(await root.list().toList(), isEmpty);
  });

  test('read byte quotas reject the file before parsing', () async {
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    await expectLater(
        store(limits: const LocalReviewSessionStoreLimits(maxFileBytes: 16))
            .load(created.reviewSet.sessionId),
        _error('session.store.quota'));
  });

  test('list applies an aggregate byte budget across stored sessions',
      () async {
    await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    await expectLater(
        store(
                limits:
                    const LocalReviewSessionStoreLimits(maxTotalReadBytes: 16))
            .list(),
        _error('session.store.quota'));
  });

  test('excessive JSON depth and mismatched session identity are rejected',
      () async {
    final created = await store()
        .create(reviewSet: _reviewSet(_session()), resumeSettings: settings);
    final file = await _sessionFile(root);
    await file.writeAsString('${'[' * 1000}0${']' * 1000}');
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.quota'));
    final foreign = StoredReviewSession(
        reviewSet: _reviewSet(_session('another-session')),
        resumeSettings: settings,
        storedRevision: 1);
    await file.writeAsString(jsonEncode(foreign.toJson()));
    await expectLater(store().load(created.reviewSet.sessionId),
        _error('session.store.identity'));
  });

  test('write quotas do not publish a partial session', () async {
    await expectLater(
        store(limits: const LocalReviewSessionStoreLimits(maxFileBytes: 16))
            .create(
                reviewSet: _reviewSet(_session()), resumeSettings: settings),
        _error('session.store.quota'));
    expect(await store().load(ConverterId('session:original')), isNull);
  });

  test('session and lock symlinks cannot redirect filesystem access', () async {
    final session = _session();
    await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    final file = await _sessionFile(root);
    final outside = File(path.join(temporary.path, 'outside'));
    await file.rename(outside.path);
    await Link(file.path).create(outside.path);
    await expectLater(
        store().load(session.sessionId), _error('session.store.path'));
    await Link(file.path).delete();
    await outside.rename(file.path);
    final locks = (await root.list().toList())
        .where((file) =>
            path.basename(file.path) ==
            '${canonicalHashOf(session.sessionId.value).value}.lock')
        .toList();
    expect(locks, hasLength(1));
    await locks.single.delete();
    await Link(locks.single.path).create(path.join(source.path, 'original'));
    final created = (await store().load(session.sessionId))!;
    await expectLater(
        store().compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        _error('session.store.path'));
    expect(await File(path.join(source.path, 'original')).readAsString(),
        'original');
  });

  test('store roots under source or target are rejected without source writes',
      () async {
    final nested = await Directory(path.join(source.path, 'sessions')).create();
    await expectLater(
        LocalReviewSessionStore(rootPath: nested.path).create(
            reviewSet: _reviewSet(_session()), resumeSettings: settings),
        _error('session.store.overlap'));
    expect(await nested.list().toList(), isEmpty);
    await expectLater(
        LocalReviewSessionStore(rootPath: destination.path).create(
            reviewSet: _reviewSet(_session()), resumeSettings: settings),
        _error('session.store.overlap'));
    expect(await File(path.join(source.path, 'original')).readAsString(),
        'original');
  });

  test('a root replaced by a symlink is refused before publication', () async {
    final session = _session();
    final created = await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    String? sourceSentinel;
    final replaced = store(checkpoint: (stage, temporaryPath) async {
      if (stage == LocalReviewSessionWriteStage.beforePublish) {
        await root.rename('${root.path}.owned');
        await Link(root.path).create(source.path);
        sourceSentinel = path.join(source.path, path.basename(temporaryPath));
        await File(sourceSentinel!).writeAsString('source sentinel');
      }
    });
    await expectLater(
        replaced.compareAndSwap(
            reviewSet: _reviewSet(session),
            resumeSettings: settings,
            expectedStoredRevision: created.storedRevision,
            expectedCanonicalHash: created.canonicalHash),
        _error('session.store.path'));
    expect(await File(path.join(source.path, 'original')).readAsString(),
        'original');
    expect(await File(sourceSentinel!).readAsString(), 'source sentinel');
    expect(await source.list().length, 2);
  });

  test('session filenames use a digest rather than business ID text', () async {
    final session = _session('session:namespace.with-punctuation');
    await store()
        .create(reviewSet: _reviewSet(session), resumeSettings: settings);
    final file = await _sessionFile(root);
    expect(path.basename(file.path), matches(r'^[a-f0-9]{64}\.session\.json$'));
    expect(path.basename(file.path), isNot(contains('namespace')));
  });
}

ConverterAssetReviewSet _pairSet({int countPerMap = 1}) {
  final template = _session().activeCandidates.single.toJson();
  final children = <int, AssetReviewSession>{};
  for (final mapId in [1, 8]) {
    final candidates = <AssetCandidate>[];
    for (var index = 0; index < countPerMap; index++) {
      final body = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
      body['candidateId'] = 'map-$mapId-seed-$index';
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

ConverterAssetReviewSet _reviewSet(AssetReviewSession session,
    {NativeWriteLimits writeLimits = const NativeWriteLimits()}) {
  final frame = session.frames.first;
  final seed = AssetReviewSession.create(
      sessionId: session.sessionId,
      logicalProjectNamespace: session.logicalProjectNamespace,
      sourceSnapshotHash: session.sourceSnapshotHash,
      selectedSourceMapIds: session.selectedSourceMapIds,
      outputMode: frame.outputMode,
      proposalGenerationHash: session.proposalGenerationHash,
      candidates: frame.candidates,
      placementClaims: frame.placementClaims,
      limits: session.limits);
  final set = ConverterAssetReviewSet.create(
      sessionId: session.sessionId,
      logicalProjectNamespace: session.logicalProjectNamespace,
      sourceSnapshotHash: session.sourceSnapshotHash,
      normalizedSourceHash: Sha256Hash('e' * 64),
      selectedSourceMapIds: session.selectedSourceMapIds,
      proposalSourceMapIds: [1],
      segments: {1: seed},
      limits: converterAssetReviewSetLimitsFor(writeLimits));
  return session.canonicalHash == seed.canonicalHash
      ? set
      : set.replaceSegment(
          sourceMapId: 1,
          next: session,
          expectedSetHash: set.canonicalHash,
          expectedSegmentHash: seed.canonicalHash);
}

Matcher _error(String code) => throwsA(isA<LocalReviewSessionStoreFailure>()
    .having((value) => value.code, 'code', code));

Sha256Hash _selectionHash(AssetReviewSession session) => canonicalHashOf({
      'kind': 'literalSelection',
      'version': 1,
      'sourceSnapshotHash': session.sourceSnapshotHash.value,
      'logicalProjectNamespace': session.logicalProjectNamespace.value,
      'selectedSourceMapIds': session.selectedSourceMapIds.toList()..sort(),
    });

Future<File> _sessionFile(Directory root) async =>
    File((await root.list().toList())
        .singleWhere((entry) => entry.path.endsWith('.session.json'))
        .path);

AssetReviewSession _session([String id = 'session:original']) =>
    AssetReviewSession.create(
      sessionId: ConverterId(id),
      logicalProjectNamespace: ConverterId('original-project'),
      sourceSnapshotHash: Sha256Hash('a' * 64),
      selectedSourceMapIds: [1],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: Sha256Hash('b' * 64),
      candidates: [
        AssetCandidate.fromJson({
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
        })
      ],
    );

final class _CasChild {
  _CasChild(this.process, this.processIdentity) {
    process.exitCode.then((_) => exited = true);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line == 'ready') {
        ready.complete();
      } else if (line == 'paused') {
        paused.complete();
      } else if (line == 'saved' ||
          line == 'session.store.conflict' ||
          line == 'session.store.quota') {
        result.complete(line);
      }
    }, onDone: () {
      if (!ready.isCompleted) {
        ready.completeError(StateError(errorOutput.toString()));
      }
      if (!result.isCompleted) {
        result.completeError(StateError(errorOutput.toString()));
      }
    });
    process.stderr.transform(utf8.decoder).listen(errorOutput.write);
  }

  final Process process;
  final String processIdentity;
  bool exited = false;
  final Completer<void> ready = Completer<void>();
  final Completer<void> paused = Completer<void>();
  final Completer<String> result = Completer<String>();
  final StringBuffer errorOutput = StringBuffer();

  static Future<_CasChild> start(
      String script, String root, String sessionId, String projectName) async {
    final process = await Process.start('dart', [
      '--packages=${path.join(Directory.current.path, '.dart_tool', 'package_config.json')}',
      script,
      root,
      sessionId,
      projectName,
    ]);
    return _CasChild(process, await _identity(process.pid));
  }

  Future<void> terminateOwnedIfRunning() async {
    if (!exited &&
        processIdentity.isNotEmpty &&
        await _identity(process.pid) == processIdentity) {
      process.kill(ProcessSignal.sigterm);
    }
    await process.exitCode.timeout(const Duration(seconds: 5));
  }

  static Future<String> _identity(int pid) async {
    final result = await Process.run(
        '/bin/ps', ['-p', '$pid', '-o', 'uid=,lstart=,command=']);
    return (result.stdout as String).trim();
  }
}

const _casChildScript = '''
import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<void> main(List<String> arguments) async {
  final store = LocalReviewSessionStore(rootPath: arguments[0]);
  final current = (await store.load(ConverterId(arguments[1])))!;
  stdout.writeln('ready');
  await stdout.flush();
  await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
  final settings = LocalReviewResumeSettings.fromJson({
    ...current.resumeSettings.toJson(), 'projectName': arguments[2],
  });
  try {
    await store.compareAndSwap(reviewSet: current.reviewSet, resumeSettings: settings,
      expectedStoredRevision: current.storedRevision,
      expectedCanonicalHash: current.canonicalHash);
    stdout.writeln('saved');
  } on LocalReviewSessionStoreFailure catch (error) {
    stdout.writeln(error.code);
  }
  await stdout.flush();
}
''';

const _quotaChildScript = '''
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';

Future<void> main(List<String> arguments) async {
  final seed = StoredReviewSession.fromJson(
    jsonDecode(await File(arguments[1]).readAsString()));
  final commands = StreamIterator(stdin.transform(utf8.decoder)
    .transform(const LineSplitter()));
  stdout.writeln('ready');
  await stdout.flush();
  await commands.moveNext();
  final store = LocalReviewSessionStore(rootPath: arguments[0],
    limits: const LocalReviewSessionStoreLimits(maxSessions: 1),
    checkpoint: arguments[2] == 'pause' ? (stage, _) async {
      if (stage == LocalReviewSessionWriteStage.beforePublish) {
        stdout.writeln('paused');
        await stdout.flush();
        await commands.moveNext();
      }
    } : null);
  try {
    await store.create(reviewSet: seed.reviewSet, resumeSettings: seed.resumeSettings);
    stdout.writeln('saved');
  } on LocalReviewSessionStoreFailure catch (error) {
    stdout.writeln(error.code);
  }
  await commands.cancel();
  await stdout.flush();
}
''';
