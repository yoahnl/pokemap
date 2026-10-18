import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

import 'native_project_writer.dart';
import 'converter_workflow.dart';
import 'converter_asset_review_set.dart';
import 'literal_tile_composer.dart';
import 'supplemented_source_tree.dart';

final class LocalReviewSessionStoreLimits {
  const LocalReviewSessionStoreLimits({
    this.maxFileBytes = 8388608,
    this.maxTotalReadBytes = 33554432,
    this.maxSessions = 128,
    this.maxDirectoryEntries = 1024,
    this.jsonLimits = const ContractLimits(),
  });

  final int maxFileBytes;
  final int maxTotalReadBytes;
  final int maxSessions;
  final int maxDirectoryEntries;
  final ContractLimits jsonLimits;
}

final class LocalReviewDependencyDecision {
  factory LocalReviewDependencyDecision({
    required Sha256Hash sourceSnapshotHash,
    required Sha256Hash selectionHash,
    required Sha256Hash locatorHash,
    required int? targetSourceMapId,
    required LiteralDependencyDisposition decision,
  }) {
    _requireStore(targetSourceMapId == null
            ? decision != LiteralDependencyDisposition.include
            : targetSourceMapId > 0 && targetSourceMapId <= 2147483647,
        'session.store.document', 'Invalid dependency target.');
    return LocalReviewDependencyDecision._(sourceSnapshotHash, selectionHash,
        locatorHash, targetSourceMapId, decision);
  }

  const LocalReviewDependencyDecision._(
      this.sourceSnapshotHash,
      this.selectionHash,
      this.locatorHash,
      this.targetSourceMapId,
      this.decision);

  factory LocalReviewDependencyDecision.fromDecision(
          LiteralDependencyDecision decision) =>
      LocalReviewDependencyDecision(
        sourceSnapshotHash: decision.sourceSnapshotHash,
        selectionHash: decision.selectionHash,
        locatorHash: canonicalHashOf(decision.locator.toJson()),
        targetSourceMapId: decision.targetSourceMapId,
        decision: decision.decision,
      );

  factory LocalReviewDependencyDecision.fromJson(Object? input) =>
      _readDocument(() {
        final json = _object(input);
        _keys(json, const {
          'sourceSnapshotHash',
          'selectionHash',
          'locatorHash',
          'targetSourceMapId',
          'decision'
        });
        return LocalReviewDependencyDecision(
          sourceSnapshotHash: Sha256Hash(_string(json['sourceSnapshotHash'])),
          selectionHash: Sha256Hash(_string(json['selectionHash'])),
          locatorHash: Sha256Hash(_string(json['locatorHash'])),
          targetSourceMapId: json['targetSourceMapId'] == null
              ? null
              : _integer(json['targetSourceMapId']),
          decision: LiteralDependencyDisposition.values
              .byName(_string(json['decision'])),
        );
      });

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash selectionHash;
  final Sha256Hash locatorHash;
  final int? targetSourceMapId;
  final LiteralDependencyDisposition decision;

  Map<String, Object?> toJson() => Map.unmodifiable({
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'selectionHash': selectionHash.value,
        'locatorHash': locatorHash.value,
        'targetSourceMapId': targetSourceMapId,
        'decision': decision.name,
      });
}

final class LocalReviewProfileAcknowledgement {
  factory LocalReviewProfileAcknowledgement({
    required Sha256Hash sourceSnapshotHash,
    required Sha256Hash profileEvidenceHash,
    required bool humanConfirmed,
    required String reason,
  }) {
    _requireStore(
        reason.length <= 1024 &&
            !reason.contains('\u0000') &&
            (!humanConfirmed || reason.trim().isNotEmpty),
        'session.store.document',
        'Invalid profile acknowledgement.');
    return LocalReviewProfileAcknowledgement._(
        sourceSnapshotHash, profileEvidenceHash, humanConfirmed, reason.trim());
  }

  const LocalReviewProfileAcknowledgement._(this.sourceSnapshotHash,
      this.profileEvidenceHash, this.humanConfirmed, this.reason);

  factory LocalReviewProfileAcknowledgement.fromJson(Object? input) =>
      _readDocument(() {
        final json = _object(input);
        _keys(json, const {
          'sourceSnapshotHash',
          'profileEvidenceHash',
          'humanConfirmed',
          'reason'
        });
        return LocalReviewProfileAcknowledgement(
          sourceSnapshotHash: Sha256Hash(_string(json['sourceSnapshotHash'])),
          profileEvidenceHash: Sha256Hash(_string(json['profileEvidenceHash'])),
          humanConfirmed: _boolean(json['humanConfirmed']),
          reason: _string(json['reason']),
        );
      });

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash profileEvidenceHash;
  final bool humanConfirmed;
  final String reason;

  Map<String, Object?> toJson() => Map.unmodifiable({
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileEvidenceHash': profileEvidenceHash.value,
        'humanConfirmed': humanConfirmed,
        'reason': reason,
      });
}

final class LocalReviewResumeSettings {
  factory LocalReviewResumeSettings({
    required String sourceRootPath,
    List<String> supplementalRootPaths = const [],
    List<ConverterSharedSourceFile> sharedSourceFiles = const [],
    required String destinationParentPath,
    required String projectName,
    required String folderName,
    SourceInterpretationProfile? interpretationProfile,
    bool allowFirstFrameAutotiles = false,
    LocalReviewProfileAcknowledgement? profileAcknowledgement,
    List<LocalReviewDependencyDecision> dependencyDecisions = const [],
    List<SourceImageBinding> imageBindings = const [],
    List<SourceEventAdaptation> sourceAdaptations = const [],
    List<SourceMissingItemBinding> missingItemBindings = const [],
    SourceScanPolicy? sourceScanPolicy,
    SourceNormalizationLimits normalizationLimits =
        const SourceNormalizationLimits(),
    NativeWriteLimits writeLimits = const NativeWriteLimits(),
  }) =>
      _readDocument(() {
        final selection = ConverterSourceSelection(
            rootPath: _absolutePath(sourceRootPath),
            supplementalRootPaths: supplementalRootPaths,
            logicalProjectNamespace: ConverterId('review-resume-roots'));
        final source = selection.rootPath;
        final shared = selection.supplementalRootPaths;
        final provenance =
            validateSupplementalProvenance(sharedSourceFiles, shared);
        final destination = _absolutePath(destinationParentPath);
        _requireStore(
            projectName.trim().isNotEmpty &&
                projectName.length <= 256 &&
                !projectName.contains('\u0000') &&
                folderName.isNotEmpty &&
                folderName.length <= 255 &&
                folderName.trim() == folderName &&
                folderName != '.' &&
                folderName != '..' &&
                !folderName.endsWith('.') &&
                !RegExp(r'[\\/<>:"|?*\x00-\x1f]').hasMatch(folderName) &&
                !RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
                        caseSensitive: false)
                    .hasMatch(folderName),
            'session.store.document',
            'Invalid saved project name or folder.');
        _requireStore(
            dependencyDecisions.length <= 2048 &&
                dependencyDecisions
                        .map((item) =>
                            '${item.locatorHash.value}:${item.targetSourceMapId}')
                        .toSet()
                        .length ==
                    dependencyDecisions.length,
            'session.store.document',
            'Dependency receipts must be unique and bounded.');
        writeLimits.validate();
        final bindings = SourceImageBinding.canonicalize(imageBindings);
        _boundedNumbers(
            _normalizationJson(normalizationLimits), _normalizationCeilings);
        return LocalReviewResumeSettings._(
            source,
            shared,
            provenance,
            destination,
            projectName.trim(),
            folderName,
            allowFirstFrameAutotiles,
            profileAcknowledgement,
            interpretationProfile,
            List.unmodifiable(dependencyDecisions),
            bindings,
            SourceEventAdaptation.canonicalize(sourceAdaptations),
        SourceMissingItemBinding.canonicalize(missingItemBindings),
            sourceScanPolicy ?? SourceScanPolicy(),
            normalizationLimits,
            writeLimits);
      });

  const LocalReviewResumeSettings._(
      this.sourceRootPath,
      this.supplementalRootPaths,
      this.sharedSourceFiles,
      this.destinationParentPath,
      this.projectName,
      this.folderName,
      this.allowFirstFrameAutotiles,
      this.profileAcknowledgement,
      this.interpretationProfile,
      this.dependencyDecisions,
      this.imageBindings,
      this.sourceAdaptations,
      this.missingItemBindings,
      this.sourceScanPolicy,
      this.normalizationLimits,
      this.writeLimits);

  factory LocalReviewResumeSettings.fromJson(Object? input) =>
      _readDocument(() {
        final json = _object(input);
        _keys(json, const {
          'sourceRootPath',
          'supplementalRootPaths',
          'sharedSourceFiles',
          'destinationParentPath',
          'projectName',
          'folderName',
          'allowFirstFrameAutotiles',
          'profileAcknowledgement',
          'interpretationProfile',
          'dependencyDecisions',
          'imageBindings',
          'sourceAdaptations',
          'missingItemBindings',
          'sourceScanPolicy',
          'normalizationLimits',
          'writeLimits'
        });
        final dependencies = _list(json['dependencyDecisions']);
        _requireStore(dependencies.length <= 2048, 'session.store.quota',
            'Too many dependency receipts.');
        return LocalReviewResumeSettings(
          interpretationProfile: json['interpretationProfile'] == null ? null : SourceInterpretationProfile.fromJson(json['interpretationProfile']),
          sourceRootPath: _string(json['sourceRootPath']),
          supplementalRootPaths:
              _list(json['supplementalRootPaths']).map(_string).toList(),
          sharedSourceFiles: _list(json['sharedSourceFiles'])
              .map(ConverterSharedSourceFile.fromJson)
              .toList(),
          destinationParentPath: _string(json['destinationParentPath']),
          projectName: _string(json['projectName']),
          folderName: _string(json['folderName']),
          allowFirstFrameAutotiles: _boolean(json['allowFirstFrameAutotiles']),
          profileAcknowledgement: json['profileAcknowledgement'] == null
              ? null
              : LocalReviewProfileAcknowledgement.fromJson(
                  json['profileAcknowledgement']),
          dependencyDecisions:
              dependencies.map(LocalReviewDependencyDecision.fromJson).toList(),
          missingItemBindings: _list(json['missingItemBindings']).map(SourceMissingItemBinding.fromJson).toList(),
          sourceAdaptations: _list(json['sourceAdaptations']).map(SourceEventAdaptation.fromJson).toList(),
          imageBindings: _list(json['imageBindings'])
              .map(SourceImageBinding.fromJson)
              .toList(),
          sourceScanPolicy: _readScanPolicy(json['sourceScanPolicy']),
          normalizationLimits:
              _readNormalizationLimits(json['normalizationLimits']),
          writeLimits: _readWriteLimits(json['writeLimits']),
        );
      });

  final String sourceRootPath;
  final List<String> supplementalRootPaths;
  final List<ConverterSharedSourceFile> sharedSourceFiles;
  final String destinationParentPath;
  final String projectName;
  final String folderName;
  final bool allowFirstFrameAutotiles;
  final LocalReviewProfileAcknowledgement? profileAcknowledgement;
  final SourceInterpretationProfile? interpretationProfile;
  final List<LocalReviewDependencyDecision> dependencyDecisions;
  final List<SourceImageBinding> imageBindings;
  final List<SourceEventAdaptation> sourceAdaptations;
  final List<SourceMissingItemBinding> missingItemBindings;
  final SourceScanPolicy sourceScanPolicy;
  final SourceNormalizationLimits normalizationLimits;
  final NativeWriteLimits writeLimits;

  Map<String, Object?> toJson() => _immutableObject({
        'sourceRootPath': sourceRootPath,
        'supplementalRootPaths': supplementalRootPaths,
        'sharedSourceFiles':
            sharedSourceFiles.map((file) => file.toJson()).toList(),
        'destinationParentPath': destinationParentPath,
        'projectName': projectName,
        'folderName': folderName,
        'allowFirstFrameAutotiles': allowFirstFrameAutotiles,
        'profileAcknowledgement': profileAcknowledgement?.toJson(),
        'interpretationProfile': interpretationProfile?.toJson(),
        'dependencyDecisions':
            dependencyDecisions.map((item) => item.toJson()).toList(),
        'imageBindings': imageBindings.map((item) => item.toJson()).toList(),
        'sourceAdaptations': sourceAdaptations.map((item) => item.toJson()).toList(),
        'missingItemBindings': missingItemBindings.map((item) => item.toJson()).toList(),
        'sourceScanPolicy': {
          'limits': sourceScanPolicy.limits.toJson(),
          'excludedSegments': sourceScanPolicy.excludedSegments
        },
        'normalizationLimits': _normalizationJson(normalizationLimits),
        'writeLimits': _writeLimitsJson(writeLimits),
      });
}

final class StoredReviewSession {
  factory StoredReviewSession({
    required ConverterAssetReviewSet reviewSet,
    required LocalReviewResumeSettings resumeSettings,
    required int storedRevision,
    LocalReviewSessionStoreLimits limits =
        const LocalReviewSessionStoreLimits(),
  }) =>
      _readDocument(() {
        _validateLimits(limits);
        _requireStore(storedRevision > 0 && storedRevision <= 2147483647,
            'session.store.document', 'Invalid stored session revision.');
        final admitted = ConverterAssetReviewSet.fromJson(reviewSet.toJson(),
            admissionLimits:
                converterAssetReviewSetLimitsFor(resumeSettings.writeLimits));
        _validateContext(admitted, resumeSettings);
        final result = StoredReviewSession._(
            admitted, resumeSettings, storedRevision, limits.jsonLimits);
        _requireStore(
            utf8
                    .encode(canonicalJsonOf(result.toJson(),
                        limits: limits.jsonLimits))
                    .length <=
                limits.maxFileBytes,
            'session.store.quota',
            'Stored session byte budget exceeded.');
        return result;
      });

  StoredReviewSession._(this.reviewSet, this.resumeSettings,
      this.storedRevision, this._jsonLimits);

  factory StoredReviewSession.fromJson(Object? input,
          {LocalReviewSessionStoreLimits limits =
              const LocalReviewSessionStoreLimits()}) =>
      _readDocument(() {
        _validateLimits(limits);
        final json =
            _object(_immutableObject(input, limits: limits.jsonLimits));
        _keys(json, const {
          'kind',
          'version',
          'storedRevision',
          'reviewSet',
          'resumeSettings'
        });
        _requireStore(
            json['kind'] == 'localReviewSession' && json['version'] == 10,
            'session.store.document',
            'Unsupported stored review document.');
        final settings =
            LocalReviewResumeSettings.fromJson(json['resumeSettings']);
        return StoredReviewSession(
          reviewSet: ConverterAssetReviewSet.fromJson(json['reviewSet'],
              admissionLimits:
                  converterAssetReviewSetLimitsFor(settings.writeLimits)),
          resumeSettings: settings,
          storedRevision: _integer(json['storedRevision']),
          limits: limits,
        );
      });

  final ConverterAssetReviewSet reviewSet;
  final LocalReviewResumeSettings resumeSettings;
  final int storedRevision;
  final ContractLimits _jsonLimits;

  Map<String, Object?> toJson() => Map.unmodifiable({
        'kind': 'localReviewSession',
        'version': 10,
        'storedRevision': storedRevision,
        'reviewSet': reviewSet.toJson(),
        'resumeSettings': resumeSettings.toJson(),
      });

  late final Sha256Hash canonicalHash =
      canonicalHashOf(toJson(), limits: _jsonLimits);
}

enum LocalReviewSessionWriteStage { temporaryFlushed, beforePublish, published }

typedef LocalReviewSessionWriteCheckpoint = FutureOr<void> Function(
    LocalReviewSessionWriteStage stage, String temporaryPath);

final class LocalReviewSessionStoreFailure implements Exception {
  const LocalReviewSessionStoreFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

final class LocalReviewSessionStore {
  LocalReviewSessionStore({
    required this.rootPath,
    this.limits = const LocalReviewSessionStoreLimits(),
    this.checkpoint,
  });

  final String rootPath;
  final LocalReviewSessionStoreLimits limits;
  final LocalReviewSessionWriteCheckpoint? checkpoint;

  Future<StoredReviewSession?> load(ConverterId sessionId) async {
    _validateLimits(limits);
    return _io(() async {
      final root = await _root();
      return root == null ? null : _load(root, sessionId);
    });
  }

  Future<List<StoredReviewSession>> list() async {
    _validateLimits(limits);
    return _io(() async {
      final root = await _root();
      return root == null ? const [] : _listStored(root);
    });
  }

  Future<StoredReviewSession> create({
    required ConverterAssetReviewSet reviewSet,
    required LocalReviewResumeSettings resumeSettings,
  }) async {
    _validateLimits(limits);
    final value = _admit(StoredReviewSession(
        reviewSet: reviewSet,
        resumeSettings: resumeSettings,
        storedRevision: 1,
        limits: limits));
    return _io(() async {
      final root = (await _root(forWrite: resumeSettings, create: true))!;
      return _withNamedLock(
          root,
          '.sessions',
          () => _withLock(root, reviewSet.sessionId, () async {
                _requireStore(
                    await _load(root, reviewSet.sessionId) == null,
                    'session.store.exists',
                    'This review session is already stored.');
                _requireStore(
                    (await _listStored(root)).length < limits.maxSessions,
                    'session.store.quota',
                    'Stored session count exceeded.');
                await _publish(root, value, expected: null);
                return value;
              }));
    });
  }

  Future<StoredReviewSession> compareAndSwap({
    required ConverterAssetReviewSet reviewSet,
    required LocalReviewResumeSettings resumeSettings,
    required int expectedStoredRevision,
    required Sha256Hash expectedCanonicalHash,
  }) async {
    _validateLimits(limits);
    _requireStore(
        expectedStoredRevision > 0 && expectedStoredRevision < 2147483647,
        'session.store.conflict',
        'Invalid expected stored revision.');
    return _io(() async {
      final root = await _root(forWrite: resumeSettings);
      _requireStore(root != null, 'session.store.conflict',
          'The saved session is unavailable.');
      return _withLock(root!, reviewSet.sessionId, () async {
        final current = await _load(root, reviewSet.sessionId);
        _requireStore(
            current != null &&
                current.storedRevision == expectedStoredRevision &&
                current.canonicalHash == expectedCanonicalHash,
            'session.store.conflict',
            'The stored session changed; reopen its current version.');
        final previous = current!.reviewSet;
        _requireStore(
            _reviewSourceContextHash(previous) ==
                _reviewSourceContextHash(reviewSet),
            'session.store.source_changed',
            'Use a new review set for a changed source context.');
        for (final entry in previous.segments.entries) {
          final next = reviewSet.segments[entry.key]!;
          _requireStore(
              next.revision >= entry.value.revision &&
                  (next.revision != entry.value.revision ||
                      next.canonicalHash == entry.value.canonicalHash),
              'session.store.domain_revision',
              'Review segment revisions must advance when segment content changes.');
        }
        _requireStore(
            reviewSet.revision >= previous.revision &&
                (reviewSet.revision != previous.revision ||
                    reviewSet.canonicalHash == previous.canonicalHash),
            'session.store.domain_revision',
            'Review revisions must advance when review content changes.');
        final value = _admit(StoredReviewSession(
            reviewSet: reviewSet,
            resumeSettings: resumeSettings,
            storedRevision: current.storedRevision + 1,
            limits: limits));
        await _publish(root, value, expected: current);
        return value;
      });
    });
  }

  StoredReviewSession _admit(StoredReviewSession value) {
    final checked =
        StoredReviewSession.fromJson(value.toJson(), limits: limits);
    _requireStore(
        utf8
                .encode(canonicalJsonOf(checked.toJson(),
                    limits: limits.jsonLimits))
                .length <=
            limits.maxFileBytes,
        'session.store.quota',
        'Stored session byte budget exceeded.');
    return checked;
  }

  Future<String?> _root(
      {LocalReviewResumeSettings? forWrite, bool create = false}) async {
    final requested = _absolutePath(rootPath);
    final type = await FileSystemEntity.type(requested, followLinks: false);
    _requireStore(
        type == FileSystemEntityType.directory ||
            type == FileSystemEntityType.notFound,
        'session.store.path',
        'The session root must be an ordinary directory.');
    final canonical = await _canonicalContextPath(requested);
    if (forWrite != null) await _separate(canonical, forWrite);
    if (type == FileSystemEntityType.notFound) {
      if (!create) return null;
      await Directory(requested).create(recursive: true);
    }
    await _guardRoot(canonical);
    if (forWrite != null) {
      await _private(canonical, '700');
      await _guardRoot(canonical);
    }
    return canonical;
  }

  Future<void> _guardRoot(String root) async {
    _requireStore(
        await FileSystemEntity.type(rootPath, followLinks: false) ==
                FileSystemEntityType.directory &&
            await Directory(rootPath).resolveSymbolicLinks() == root,
        'session.store.path',
        'The session root changed or became unavailable.');
  }

  Future<void> _separate(
      String root, LocalReviewResumeSettings settings) async {
    for (final selected in [
      settings.sourceRootPath,
      ...settings.supplementalRootPaths,
      settings.destinationParentPath
    ]) {
      final other = await _canonicalContextPath(selected);
      _requireStore(
          !path.equals(root, other) &&
              !path.isWithin(root, other) &&
              !path.isWithin(other, root),
          'session.store.overlap',
          'Session storage must be separate from source and native destination.');
    }
  }

  String _filePath(String root, ConverterId id) =>
      path.join(root, '${canonicalHashOf(id.value).value}.session.json');

  Future<StoredReviewSession?> _load(String root, ConverterId id) async {
    await _guardRoot(root);
    final filePath = _filePath(root, id);
    final type = await FileSystemEntity.type(filePath, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    _requireStore(type == FileSystemEntityType.file, 'session.store.path',
        'Stored sessions must be ordinary files.');
    final value = await _readFile(File(filePath));
    await _guardRoot(root);
    _requireStore(value.reviewSet.sessionId == id, 'session.store.identity',
        'Stored session identity does not match its file.');
    return value;
  }

  Future<List<StoredReviewSession>> _listStored(String root) async {
    await _guardRoot(root);
    final files = <File>[];
    var entries = 0;
    var bytes = 0;
    await for (final entity in Directory(root).list(followLinks: false)) {
      _requireStore(++entries <= limits.maxDirectoryEntries,
          'session.store.quota', 'Session directory entry budget exceeded.');
      final name = path.basename(entity.path);
      if (!name.endsWith('.session.json')) continue;
      _requireStore(
          RegExp(r'^[a-f0-9]{64}\.session\.json$').hasMatch(name) &&
              await FileSystemEntity.type(entity.path, followLinks: false) ==
                  FileSystemEntityType.file,
          'session.store.path',
          'Invalid stored session filename or file type.');
      _requireStore(files.length < limits.maxSessions, 'session.store.quota',
          'Stored session count exceeded.');
      final length = (await entity.stat()).size;
      bytes += length;
      _requireStore(
          length <= limits.maxFileBytes && bytes <= limits.maxTotalReadBytes,
          'session.store.quota',
          'Stored session read budget exceeded.');
      files.add(File(entity.path));
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    final values = <StoredReviewSession>[];
    for (final file in files) {
      final value = await _readFile(file);
      _requireStore(
          file.path == _filePath(root, value.reviewSet.sessionId),
          'session.store.identity',
          'Stored session identity does not match its file.');
      values.add(value);
    }
    await _guardRoot(root);
    values.sort((a, b) =>
        a.reviewSet.sessionId.value.compareTo(b.reviewSet.sessionId.value));
    return List.unmodifiable(values);
  }

  Future<StoredReviewSession> _readFile(File file) async {
    _requireStore(
        await FileSystemEntity.type(file.path, followLinks: false) ==
            FileSystemEntityType.file,
        'session.store.path',
        'Stored session file changed.');
    final handle = await file.open();
    try {
      final length = await handle.length();
      _requireStore(length >= 0 && length <= limits.maxFileBytes,
          'session.store.quota', 'Stored session byte budget exceeded.');
      final bytes = await handle.read(length + 1);
      _requireStore(bytes.length == length && await handle.length() == length,
          'session.store.path', 'Stored session file changed during reading.');
      return _readDocument<StoredReviewSession>(() {
        final text = utf8.decode(bytes);
        _checkJsonDepth(text, limits.jsonLimits.maxDepth);
        return StoredReviewSession.fromJson(jsonDecode(text), limits: limits);
      });
    } finally {
      await handle.close();
    }
  }

  Future<T> _withLock<T>(
          String root, ConverterId id, Future<T> Function() action) =>
      _withNamedLock(root, canonicalHashOf(id.value).value, action);

  Future<T> _withNamedLock<T>(
          String root, String lockName, Future<T> Function() action) =>
      _serialize('$root:$lockName', () async {
        await _guardRoot(root);
        final lock = File(path.join(root, '$lockName.lock'));
        final type = await FileSystemEntity.type(lock.path, followLinks: false);
        _requireStore(
            type == FileSystemEntityType.file ||
                type == FileSystemEntityType.notFound,
            'session.store.path',
            'The session lock must be an ordinary file.');
        if (type == FileSystemEntityType.notFound) {
          try {
            await lock.create(exclusive: true);
          } on PathExistsException {
            _requireStore(
                await FileSystemEntity.type(lock.path, followLinks: false) ==
                    FileSystemEntityType.file,
                'session.store.path',
                'The session lock changed.');
          }
        }
        await _guardRoot(root);
        await _private(lock.path, '600');
        _requireStore(
            await FileSystemEntity.type(lock.path, followLinks: false) ==
                FileSystemEntityType.file,
            'session.store.path',
            'The session lock changed.');
        final handle = await lock.open(mode: FileMode.append);
        var locked = false;
        try {
          final elapsed = Stopwatch()..start();
          while (!locked) {
            try {
              await handle.lock(FileLock.exclusive);
              locked = true;
            } on FileSystemException catch (error) {
              if (![11, 35].contains(error.osError?.errorCode)) rethrow;
              _requireStore(
                  elapsed.elapsed < const Duration(seconds: 10),
                  'session.store.lock_timeout',
                  'Another process is saving this review session.');
              await Future<void>.delayed(const Duration(milliseconds: 20));
            }
          }
          await _guardRoot(root);
          return await action();
        } finally {
          if (locked) await handle.unlock();
          await handle.close();
        }
      });

  Future<void> _publish(String root, StoredReviewSession value,
      {required StoredReviewSession? expected}) async {
    final bytes =
        utf8.encode(canonicalJsonOf(value.toJson(), limits: limits.jsonLimits));
    _requireStore(bytes.length <= limits.maxFileBytes, 'session.store.quota',
        'Stored session byte budget exceeded.');
    await _guardRoot(root);
    await _separate(root, value.resumeSettings);
    final nonce = List.generate(
        6,
        (_) => Random.secure()
            .nextInt(4294967296)
            .toRadixString(16)
            .padLeft(8, '0')).join();
    final temporary = File(path.join(root, '.review-$nonce.tmp'));
    await temporary.create(exclusive: true);
    try {
      await _private(temporary.path, '600');
      await _guardRoot(root);
      final handle = await temporary.open(mode: FileMode.writeOnly);
      try {
        await handle.writeFrom(bytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      await checkpoint?.call(
          LocalReviewSessionWriteStage.temporaryFlushed, temporary.path);
      await checkpoint?.call(
          LocalReviewSessionWriteStage.beforePublish, temporary.path);
      await _guardRoot(root);
      await _separate(root, value.resumeSettings);
      final readback = await _readFile(temporary);
      _requireStore(
          readback.canonicalHash == value.canonicalHash,
          'session.store.path',
          'The temporary session changed before publication.');
      final current = await _load(root, value.reviewSet.sessionId);
      _requireStore(
          expected == null
              ? current == null
              : current?.canonicalHash == expected.canonicalHash,
          'session.store.conflict',
          'The stored session changed before publication.');
      await _guardRoot(root);
      await temporary.rename(_filePath(root, value.reviewSet.sessionId));
      await checkpoint?.call(
          LocalReviewSessionWriteStage.published, temporary.path);
    } finally {
      if (await FileSystemEntity.type(rootPath, followLinks: false) ==
              FileSystemEntityType.directory &&
          await Directory(rootPath).resolveSymbolicLinks() == root &&
          await FileSystemEntity.type(temporary.path, followLinks: false) ==
              FileSystemEntityType.file) {
        await temporary.delete();
      }
    }
  }
}

final Map<String, Future<void>> _pendingSaves = {};

Future<T> _serialize<T>(String key, Future<T> Function() action) async {
  final previous = _pendingSaves[key];
  final completion = Completer<void>();
  _pendingSaves[key] = completion.future;
  if (previous != null) await previous;
  try {
    return await action();
  } finally {
    completion.complete();
    if (identical(_pendingSaves[key], completion.future)) {
      _pendingSaves.remove(key);
    }
  }
}

Future<T> _io<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FileSystemException {
    throw const LocalReviewSessionStoreFailure('session.store.io',
        'Session storage is unavailable; reopen it to inspect the saved version.');
  }
}

Future<void> _private(String filePath, String mode) async {
  if (Platform.isMacOS || Platform.isLinux) {
    final result = await Process.run('/bin/chmod', [mode, filePath]);
    _requireStore(result.exitCode == 0, 'session.store.io',
        'Unable to make session storage private.');
  }
}

Future<String> _canonicalContextPath(String selected) async {
  final requested = _absolutePath(selected);
  var existing = requested;
  final suffix = <String>[];
  while (await FileSystemEntity.type(existing, followLinks: false) ==
      FileSystemEntityType.notFound) {
    final parent = path.dirname(existing);
    _requireStore(parent != existing, 'session.store.path',
        'The selected context cannot be resolved.');
    suffix.add(path.basename(existing));
    existing = parent;
  }
  final canonical = await Directory(existing).resolveSymbolicLinks();
  _requireStore(
      await FileSystemEntity.type(canonical, followLinks: false) ==
          FileSystemEntityType.directory,
      'session.store.path',
      'The selected context must be a directory.');
  return path.joinAll([canonical, ...suffix.reversed]);
}

Sha256Hash _reviewSourceContextHash(ConverterAssetReviewSet reviewSet) {
  final json = reviewSet.toJson();
  return canonicalHashOf({
    'sessionId': reviewSet.sessionId.value,
    'logicalProjectNamespace': reviewSet.logicalProjectNamespace.value,
    'sourceSnapshotHash': reviewSet.sourceSnapshotHash.value,
    'normalizedSourceHash': reviewSet.normalizedSourceHash.value,
    'selectedSourceMapIds': reviewSet.selectedSourceMapIds,
    'proposalSourceMapIds': reviewSet.proposalSourceMapIds,
    'limits': json['limits'],
    'segments': [
      for (final entry in reviewSet.segments.entries)
        {
          'sourceMapId': entry.key,
          'sessionId': entry.value.sessionId.value,
          'proposalGenerationHash': entry.value.proposalGenerationHash.value,
          'baseProposalHashes': {
            for (final base in entry.value.baseProposalHashes.entries)
              base.key.value: base.value.value,
          },
          'seedHash': entry.value.frames.first.canonicalHash.value,
          'limits': (_list(json['segments'])
                  .firstWhere((row) => _object(row)['sourceMapId'] == entry.key)
              as Map)['limits'],
        }
    ],
  });
}

void _validateContext(
    ConverterAssetReviewSet session, LocalReviewResumeSettings settings) {
  final selection = canonicalHashOf({
    'kind': 'literalSelection',
    'version': 1,
    'sourceSnapshotHash': session.sourceSnapshotHash.value,
    'logicalProjectNamespace': session.logicalProjectNamespace.value,
    'selectedSourceMapIds': session.selectedSourceMapIds.toList()..sort(),
  });
  _requireStore(
      settings.profileAcknowledgement == null ||
          settings.profileAcknowledgement!.sourceSnapshotHash ==
              session.sourceSnapshotHash,
      'session.store.context',
      'The profile acknowledgement belongs to another source.');
  for (final receipt in settings.dependencyDecisions) {
    _requireStore(
        receipt.sourceSnapshotHash == session.sourceSnapshotHash &&
            receipt.selectionHash == selection,
        'session.store.context',
        'A dependency receipt belongs to another source or map selection.');
  }
}

void _validateLimits(LocalReviewSessionStoreLimits limits) {
  for (final pair in [
    (limits.maxFileBytes, 16777216),
    (limits.maxTotalReadBytes, 134217728),
    (limits.maxSessions, 4096),
    (limits.maxDirectoryEntries, 16384),
    (limits.jsonLimits.maxDepth, 64),
    (limits.jsonLimits.maxNodes, 1000000),
    (limits.jsonLimits.maxStringCodeUnits, 1048576),
    (limits.jsonLimits.maxTextCodeUnits, 4194304)
  ]) {
    _requireStore(pair.$1 > 0 && pair.$1 <= pair.$2, 'session.store.limits',
        'Session storage limits must be positive and bounded.');
  }
}

void _checkJsonDepth(String text, int maxDepth) {
  var depth = 0;
  var quoted = false;
  var escaped = false;
  for (final unit in text.codeUnits) {
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (unit == 92) {
        escaped = true;
      } else if (unit == 34) {
        quoted = false;
      }
    } else if (unit == 34) {
      quoted = true;
    } else if (unit == 123 || unit == 91) {
      _requireStore(++depth <= maxDepth, 'session.store.quota',
          'Session JSON depth budget exceeded.');
    } else if (unit == 125 || unit == 93) {
      depth--;
    }
  }
}

T _readDocument<T>(T Function() read) {
  try {
    return read();
  } on LocalReviewSessionStoreFailure {
    rethrow;
  } on ConverterWorkflowFailure {
    throw const LocalReviewSessionStoreFailure(
        'session.store.document', 'Invalid source folder selection.');
  } on ContractError catch (error) {
    throw LocalReviewSessionStoreFailure(
        error.code.toLowerCase().contains('quota')
            ? 'session.store.quota'
            : 'session.store.document',
        'Invalid or excessive review session data.');
  } on FormatException {
    throw const LocalReviewSessionStoreFailure(
        'session.store.document', 'Invalid review session data.');
  } on ArgumentError {
    throw const LocalReviewSessionStoreFailure(
        'session.store.document', 'Invalid review session data.');
  } on NativeWriteException {
    throw const LocalReviewSessionStoreFailure(
        'session.store.document', 'Invalid saved writer limits.');
  }
}

void _requireStore(bool valid, String code, String message) {
  if (!valid) throw LocalReviewSessionStoreFailure(code, message);
}

Map<String, Object?> _object(Object? value) {
  _requireStore(value is Map && value.keys.every((key) => key is String),
      'session.store.document', 'Expected a bounded object.');
  return (value as Map).cast<String, Object?>();
}

List<Object?> _list(Object? value) {
  _requireStore(
      value is List, 'session.store.document', 'Expected a bounded list.');
  return (value as List).cast<Object?>();
}

String _string(Object? value) {
  _requireStore(
      value is String, 'session.store.document', 'Expected a string.');
  return value as String;
}

int _integer(Object? value) {
  _requireStore(value is int, 'session.store.document', 'Expected an integer.');
  return value as int;
}

bool _boolean(Object? value) {
  _requireStore(value is bool, 'session.store.document', 'Expected a boolean.');
  return value as bool;
}

void _keys(Map<String, Object?> object, Set<String> keys) {
  _requireStore(
      object.length == keys.length && object.keys.every(keys.contains),
      'session.store.document',
      'Unexpected or missing document fields.');
}

String _absolutePath(String value) {
  _requireStore(
      value.length <= 4096 &&
          path.isAbsolute(value) &&
          !value.contains('\u0000') &&
          !path.split(value).contains('..'),
      'session.store.document',
      'An absolute bounded path without traversal is required.');
  return path.normalize(value);
}

Map<String, Object?> _immutableObject(Object? input,
    {ContractLimits limits = const ContractLimits()}) {
  Object? freeze(Object? value) {
    if (value is List) return List<Object?>.unmodifiable(value.map(freeze));
    if (value is Map) {
      return Map<String, Object?>.unmodifiable(
          value.map((key, item) => MapEntry(key as String, freeze(item))));
    }
    return value;
  }

  return _object(freeze(jsonDecode(canonicalJsonOf(input, limits: limits))));
}

Map<String, Object?> _contractLimitsJson(ContractLimits value) => {
      'maxDepth': value.maxDepth,
      'maxNodes': value.maxNodes,
      'maxStringCodeUnits': value.maxStringCodeUnits,
      'maxTextCodeUnits': value.maxTextCodeUnits,
    };

ContractLimits _readContractLimits(Object? value) {
  final json = _object(value);
  _keys(json,
      const {'maxDepth', 'maxNodes', 'maxStringCodeUnits', 'maxTextCodeUnits'});
  return ContractLimits(
      maxDepth: _integer(json['maxDepth']),
      maxNodes: _integer(json['maxNodes']),
      maxStringCodeUnits: _integer(json['maxStringCodeUnits']),
      maxTextCodeUnits: _integer(json['maxTextCodeUnits']));
}

SourceScanPolicy _readScanPolicy(Object? value) {
  final json = _object(value);
  _keys(json, const {'limits', 'excludedSegments'});
  final numbers = _object(json['limits']);
  _keys(numbers, const {
    'maxEntries',
    'maxDepth',
    'maxFileBytes',
    'maxTotalBytes',
    'maxPathCodeUnits',
    'maxProbeBytes',
    'maxDiagnostics',
    'maxProfileEvidence',
    'maxTotalPathCodeUnits'
  });
  return SourceScanPolicy(
      limits: SourceScanLimits(
          maxEntries: _integer(numbers['maxEntries']),
          maxDepth: _integer(numbers['maxDepth']),
          maxFileBytes: _integer(numbers['maxFileBytes']),
          maxTotalBytes: _integer(numbers['maxTotalBytes']),
          maxPathCodeUnits: _integer(numbers['maxPathCodeUnits']),
          maxProbeBytes: _integer(numbers['maxProbeBytes']),
          maxDiagnostics: _integer(numbers['maxDiagnostics']),
          maxProfileEvidence: _integer(numbers['maxProfileEvidence']),
          maxTotalPathCodeUnits: _integer(numbers['maxTotalPathCodeUnits'])),
      excludedSegments: _list(json['excludedSegments']).map(_string).toList());
}

const _normalizationCeilings = {
  'maxMaps': 100000,
  'maxConnections': 65536,
  'maxTotalCells': 67108864,
  'maxEvents': 1000000,
  'maxCommands': 2000000,
  'maxParameterNodes': 4000000,
  'maxDiagnostics': 100000,
  'maxTotalBytes': 268435456,
  'maxMetadataCells': 8388608,
  'maxTotalIrNodes': 16000000,
  'maxTotalTextCodeUnits': 67108864,
  'maxDiagnosticTextCodeUnits': 4194304
};

Map<String, Object?> _normalizationJson(SourceNormalizationLimits value) => {
      'maxMaps': value.maxMaps,
      'maxConnections': value.maxConnections,
      'maxTotalCells': value.maxTotalCells,
      'maxEvents': value.maxEvents,
      'maxCommands': value.maxCommands,
      'maxParameterNodes': value.maxParameterNodes,
      'maxDiagnostics': value.maxDiagnostics,
      'maxTotalBytes': value.maxTotalBytes,
      'maxMetadataCells': value.maxMetadataCells,
      'maxTotalIrNodes': value.maxTotalIrNodes,
      'maxTotalTextCodeUnits': value.maxTotalTextCodeUnits,
      'maxDiagnosticTextCodeUnits': value.maxDiagnosticTextCodeUnits,
    };

void _boundedNumbers(Map<String, Object?> values, Map<String, int> ceilings) {
  _keys(values, ceilings.keys.toSet());
  for (final entry in ceilings.entries) {
    final value = _integer(values[entry.key]);
    _requireStore(value > 0 && value <= entry.value, 'session.store.document',
        'Invalid saved normalization limits.');
  }
}

SourceNormalizationLimits _readNormalizationLimits(Object? value) {
  final json = _object(value);
  _boundedNumbers(json, _normalizationCeilings);
  return SourceNormalizationLimits(
      maxMaps: _integer(json['maxMaps']),
      maxConnections: _integer(json['maxConnections']),
      maxTotalCells: _integer(json['maxTotalCells']),
      maxEvents: _integer(json['maxEvents']),
      maxCommands: _integer(json['maxCommands']),
      maxParameterNodes: _integer(json['maxParameterNodes']),
      maxDiagnostics: _integer(json['maxDiagnostics']),
      maxTotalBytes: _integer(json['maxTotalBytes']),
      maxMetadataCells: _integer(json['maxMetadataCells']),
      maxTotalIrNodes: _integer(json['maxTotalIrNodes']),
      maxTotalTextCodeUnits: _integer(json['maxTotalTextCodeUnits']),
      maxDiagnosticTextCodeUnits: _integer(json['maxDiagnosticTextCodeUnits']));
}

Map<String, Object?> _writeLimitsJson(NativeWriteLimits value) => {
      'maxArtifacts': value.maxArtifacts,
      'maxMutations': value.maxMutations,
      'maxArtifactBytes': value.maxArtifactBytes,
      'maxTotalArtifactBytes': value.maxTotalArtifactBytes,
      'maxTotalDraftJsonBytes': value.maxTotalDraftJsonBytes,
      'maxDraftEvidenceJsonNodes': value.maxDraftEvidenceJsonNodes,
      'maxImagePixels': value.maxImagePixels,
      'maxTotalImagePixels': value.maxTotalImagePixels,
      'maxMapCells': value.maxMapCells,
      'planJsonLimits': _contractLimitsJson(value.planJsonLimits),
      'jsonLimits': _contractLimitsJson(value.jsonLimits),
    };

NativeWriteLimits _readWriteLimits(Object? value) {
  final json = _object(value);
  _keys(json, const {
    'maxArtifacts',
    'maxMutations',
    'maxArtifactBytes',
    'maxTotalArtifactBytes',
    'maxTotalDraftJsonBytes',
    'maxDraftEvidenceJsonNodes',
    'maxImagePixels',
    'maxTotalImagePixels',
    'maxMapCells',
    'planJsonLimits',
    'jsonLimits'
  });
  return NativeWriteLimits(
      maxArtifacts: _integer(json['maxArtifacts']),
      maxMutations: _integer(json['maxMutations']),
      maxArtifactBytes: _integer(json['maxArtifactBytes']),
      maxTotalArtifactBytes: _integer(json['maxTotalArtifactBytes']),
      maxTotalDraftJsonBytes: _integer(json['maxTotalDraftJsonBytes']),
      maxDraftEvidenceJsonNodes: json['maxDraftEvidenceJsonNodes'] == null
          ? null
          : _integer(json['maxDraftEvidenceJsonNodes']),
      maxImagePixels: _integer(json['maxImagePixels']),
      maxTotalImagePixels: _integer(json['maxTotalImagePixels']),
      maxMapCells: _integer(json['maxMapCells']),
      planJsonLimits: _readContractLimits(json['planJsonLimits']),
      jsonLimits: _readContractLimits(json['jsonLimits']));
}
