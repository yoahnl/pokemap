import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import 'native_project_writer.dart';

typedef NativePublicationCheckpoint = FutureOr<void> Function(
    NativePublicationStage stage);
typedef NativePublicationContextReader = Future<PlanContext> Function();
typedef NativePublicationSourceVerifier = Future<void> Function();

enum NativePublicationStage {
  journalCreated,
  beforeStage,
  stageCreated,
  beforeCreation,
  creationCompleted,
  nativeSealed,
  publishIntentDurable,
  promotedBeforeReceipt,
  receiptCommitted,
}

enum NativePublicationRecoveryState {
  incomplete,
  prepared,
  published,
  conflict,
  corrupt,
}

final class NativePublicationPolicy {
  NativePublicationPolicy({
    required List<String> allowedParentRoots,
    required List<String> sourceRoots,
    this.minimumFreeBytes = 0,
    List<String> protectedRoots = const [
      '/System',
      '/Library',
      '/Applications',
      '/usr',
      '/bin',
      '/sbin',
      '/etc',
      '/dev',
      '/proc',
      '/sys',
      '/private/etc',
    ],
  })  : allowedParentRoots = List.unmodifiable(allowedParentRoots),
        sourceRoots = List.unmodifiable(sourceRoots),
        protectedRoots = List.unmodifiable(protectedRoots);

  final List<String> allowedParentRoots;
  final List<String> sourceRoots;
  final List<String> protectedRoots;
  final int minimumFreeBytes;

  Map<String, Object?> toJson() => {
        'allowedParentRoots': allowedParentRoots,
        'sourceRoots': sourceRoots,
        'protectedRoots': protectedRoots,
        if (minimumFreeBytes != 0) 'minimumFreeBytes': minimumFreeBytes,
      };
}

final class NativePublicationLimits {
  const NativePublicationLimits({
    this.maxFiles = 32768,
    this.maxDepth = 32,
    this.maxFileBytes = 536870912,
    this.maxTotalBytes = 2147483648,
    this.maxJournalBytes = 4194304,
    this.maxJournalRecords = 4096,
  });
  final int maxFiles;
  final int maxDepth;
  final int maxFileBytes;
  final int maxTotalBytes;
  final int maxJournalBytes;
  final int maxJournalRecords;
}

final class NativePublicationException implements Exception {
  const NativePublicationException(
    this.code,
    this.message, {
    this.journalPath,
    this.destinationPath,
    this.promotionMayHaveOccurred = false,
  });
  final String code;
  final String message;
  final String? journalPath;
  final String? destinationPath;
  final bool promotionMayHaveOccurred;
  @override
  String toString() => '$code: $message';
}

final class NativePublicationReceipt {
  NativePublicationReceipt._({
    required this.projectPath,
    required this.journalPath,
    required this.nativeRevision,
    required this.draftHash,
    required this.inventoryHash,
  });
  final String projectPath;
  final String journalPath;
  final String nativeRevision;
  final Sha256Hash draftHash;
  final Sha256Hash inventoryHash;
  String get destinationPath => projectPath;
  bool get published => true;
}

final class NativePublicationRecovery {
  NativePublicationRecovery._(this.state, this.journalPath, this.receipt);
  final NativePublicationRecoveryState state;
  final String journalPath;
  final NativePublicationReceipt? receipt;
}

final class NativeProjectPublication {
  const NativeProjectPublication({this.checkpoint, this.reservationCheckpoint});
  final NativePublicationCheckpoint? checkpoint;
  final FutureOr<void> Function(String journalPath, String destinationPath)?
      reservationCheckpoint;

  Future<NativePublicationJob> begin(
    ConversionPlan plan,
    PlanContext context,
    NativeProjectDraft draft, {
    required NativePublicationPolicy policy,
    NativePublicationLimits limits = const NativePublicationLimits(),
    ScanCancellation? cancellation,
  }) async {
    _platform();
    _limits(limits);
    _cancel(cancellation);
    _admit(plan, context);
    _absolute(draft.parentPath);
    final parent = await Directory(draft.parentPath).resolveSymbolicLinks();
    final destination = path.join(parent, _component(draft.folderName));
    await _policy(policy, parent, destination);
    final declaredSource = draft.sourceRootPath;
    if (declaredSource != null) {
      _absolute(declaredSource);
      final canonicalSource =
          await Directory(declaredSource).resolveSymbolicLinks();
      if (_within(canonicalSource, parent) ||
          _within(canonicalSource, destination) ||
          _within(destination, canonicalSource)) {
        throw const NativePublicationException('publication.source.overlap',
            'Publication must not overlap the draft source tree');
      }
      var covered = false;
      for (final root in policy.sourceRoots) {
        if (_within(
            await Directory(root).resolveSymbolicLinks(), canonicalSource)) {
          covered = true;
        }
      }
      if (!covered) {
        throw const NativePublicationException('publication.source.binding',
            'Publication policy must cover the declared draft source tree');
      }
    }
    final parentFd = _os.openDirectory(parent);
    int? controlFd;
    _Journal? journal;
    try {
      _os.requireLocal(parentFd);
      _absent(parentFd, draft.folderName);
      final estimatedBytes = _estimate(draft, limits);
      final availableBytes = _os.availableBytes(parentFd);
      if (availableBytes < max(estimatedBytes, policy.minimumFreeBytes)) {
        throw const NativePublicationException('publication.space.insufficient',
            'Destination free space is below the bounded publication estimate');
      }
      final jobId = List.generate(20, (_) => Random.secure().nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      final controlName = '.avelune-converter-job-$jobId';
      final stageName = '.avelune-converter-stage-$jobId';
      _os.mkdir(parentFd, controlName);
      controlFd = _os.openDirectoryAt(parentFd, controlName);
      _os.sync(parentFd);
      final journalPath = path.join(parent, controlName, 'journal.jsonl');
      journal = _Journal.create(controlFd, journalPath, limits);
      final header = <String, Object?>{
        'jobId': jobId,
        'parent': parent,
        'parentIdentity': _os.stat(parentFd).identity,
        'controlName': controlName,
        'controlIdentity': _os.stat(controlFd).identity,
        'stageName': stageName,
        'folderName': draft.folderName,
        'draftHash': draft.canonicalHash.value,
        'planHash': plan.canonicalHash.value,
        'sourceSnapshotHash': plan.sourceSnapshotHash.value,
        'targetProfileHash': plan.targetProfileHash.value,
        'rulesHash': plan.rulesHash.value,
        'decisionsHash': plan.decisionsHash.value,
        'decisionRevision': plan.decisionRevision,
        'converterVersion': plan.converterVersion,
        'policyHash': canonicalHashOf(policy.toJson()).value,
        'estimatedBytes': estimatedBytes,
        'availableBytesObserved': availableBytes,
      };
      journal.append('reserved', header);
      final job = NativePublicationJob._(plan, draft, policy, limits,
          checkpoint, header, parentFd, controlFd, journal);
      await reservationCheckpoint?.call(journalPath, destination);
      await checkpoint?.call(NativePublicationStage.journalCreated);
      return job;
    } catch (error) {
      journal?.close();
      if (controlFd != null) _os.close(controlFd);
      _os.close(parentFd);
      throw _exception(error, journalPath: journal?.path);
    }
  }

  Future<NativePublicationRecovery> reconcile({
    required String journalPath,
    required NativePublicationPolicy policy,
    NativePublicationLimits limits = const NativePublicationLimits(),
  }) async {
    _platform();
    _limits(limits);
    _absolute(journalPath);
    if (path.basename(journalPath) != 'journal.jsonl') {
      throw const NativePublicationException(
          'publication.journal.invalid', 'A publication journal is required');
    }
    final controlRoot = path.dirname(journalPath);
    final parent = path.dirname(controlRoot);
    final controlName = _component(path.basename(controlRoot));
    if (!RegExp(r'^\.avelune-converter-job-[a-f0-9]{40}$')
        .hasMatch(controlName)) {
      throw const NativePublicationException(
          'publication.journal.invalid', 'Journal ownership is unavailable');
    }
    await _policy(policy, parent, parent, checkOverlap: false);
    final parentFd = _os.openDirectory(parent);
    int? controlFd;
    _Journal? journal;
    try {
      controlFd = _os.openDirectoryAt(parentFd, controlName);
      journal = _Journal.open(controlFd, journalPath, limits);
      final header = journal.records.first['payload'] as Map<String, Object?>;
      _validateHeader(header, parent, controlName, parentFd, controlFd, policy);
      final job = NativePublicationJob._(null, null, policy, limits, checkpoint,
          header, parentFd, controlFd, journal);
      final recovery = await job._recover();
      await job.close();
      journal = null;
      controlFd = null;
      return recovery;
    } catch (error) {
      journal?.close();
      if (controlFd != null) _os.close(controlFd);
      _os.close(parentFd);
      if (error is NativePublicationException &&
          error.code == 'publication.journal.busy') {
        rethrow;
      }
      return NativePublicationRecovery._(
          NativePublicationRecoveryState.corrupt, journalPath, null);
    }
  }
}

final class NativePublicationJob {
  NativePublicationJob._(
      this._plan,
      this._draft,
      this._policyValue,
      this._limitsValue,
      this._checkpoint,
      this._header,
      this._parentFd,
      this._controlFd,
      this._journal);
  final ConversionPlan? _plan;
  final NativeProjectDraft? _draft;
  final NativePublicationPolicy _policyValue;
  final NativePublicationLimits _limitsValue;
  final NativePublicationCheckpoint? _checkpoint;
  final Map<String, Object?> _header;
  final int _parentFd;
  final int _controlFd;
  final _Journal _journal;
  bool _closed = false;
  bool _promoted = false;
  String get journalPath => _journal.path;
  String get _parent => _header['parent'] as String;
  String get _folder => _header['folderName'] as String;
  String get _stageName => _header['stageName'] as String;
  String get _stageRoot => path.join(_parent, _stageName);
  String get _projectPath => path.join(_stageRoot, _folder);
  String get destinationPath => path.join(_parent, _folder);

  Future<String> createStaging() async {
    _live();
    if (_journal.records.length != 1) {
      throw const NativePublicationException(
          'publication.stage.state', 'Staging can only be reserved once');
    }
    await _guard();
    _absent(_parentFd, _folder);
    _journal.append('stageIntent', {});
    await _checkpoint?.call(NativePublicationStage.beforeStage);
    await _guard();
    _absent(_parentFd, _folder);
    _os.mkdir(_parentFd, _stageName);
    final stageFd = _os.openDirectoryAt(_parentFd, _stageName);
    try {
      _os.sync(_parentFd);
      _journal.append('stageCreated', {'identity': _os.stat(stageFd).identity});
    } finally {
      _os.close(stageFd);
    }
    await _checkpoint?.call(NativePublicationStage.stageCreated);
    return _stageRoot;
  }

  Future<void> recordWriteCheckpoint(
      NativeWriteStage stage, String? stagingRoot, String? projectPath) async {
    _live();
    if (stage == NativeWriteStage.beforeStage) return;
    if (stagingRoot != _stageRoot || projectPath != _projectPath) {
      throw const NativePublicationException('publication.stage.binding',
          'Writer checkpoint differs from its reserved staging');
    }
    if (stage == NativeWriteStage.beforeCreation) {
      _journal.append('creationIntent', {});
      await _checkpoint?.call(NativePublicationStage.beforeCreation);
    } else if (stage == NativeWriteStage.afterCreation) {
      _journal.append('creationCompleted', {});
      await _checkpoint?.call(NativePublicationStage.creationCompleted);
    }
  }

  Future<NativePublicationReceipt> publish({
    required NativeWriteReceipt stagedReceipt,
    required NativePublicationContextReader readCurrentContext,
    required NativePublicationSourceVerifier verifySourceUnchanged,
    ScanCancellation? cancellation,
  }) async {
    _live();
    int? stageFd;
    int? projectFd;
    try {
      _cancel(cancellation);
      if (_plan == null ||
          _draft == null ||
          stagedReceipt.draftHash.value != _header['draftHash'] ||
          stagedReceipt.stagingRoot != _stageRoot ||
          stagedReceipt.projectPath != _projectPath ||
          _journal.records
              .any((record) => record['state'] == 'publishIntent')) {
        throw const NativePublicationException('publication.receipt.binding',
            'Verified writer receipt does not belong to this publication');
      }
      await _guard();
      _absent(_parentFd, _folder);
      _admit(_plan, await readCurrentContext());
      await verifySourceUnchanged();
      _cancel(cancellation);
      stageFd = _os.openDirectoryAt(_parentFd, _stageName);
      _requireStageIdentity(stageFd);
      projectFd = _os.openDirectoryAt(stageFd, _folder);
      await _revision(_projectPath, _stageRoot, stagedReceipt.nativeRevision,
          assets: stagedReceipt.assetHashes,
          borderSnapshotFiles: stagedReceipt.borderSnapshotFiles);
      final inventory = _inventory(projectFd, _limitsValue,
          sync: true, cancellation: cancellation);
      _os.sync(stageFd);
      final seal = <String, Object?>{
        'projectIdentity': _os.stat(projectFd).identity,
        'nativeRevision': stagedReceipt.nativeRevision,
        'inventory': inventory,
        'inventoryHash':
            canonicalHashOf(inventory, limits: _jsonLimits(_limitsValue)).value,
        'assetHashes': {
          for (final entry in stagedReceipt.assetHashes.entries)
            entry.key: entry.value.value
        },
        'borderSnapshotFiles': {
          for (final entry in stagedReceipt.borderSnapshotFiles.entries)
            entry.key: entry.value.toJson()
        },
      };
      _journal.append('sealed', seal);
      await _checkpoint?.call(NativePublicationStage.nativeSealed);
      _admit(_plan, await readCurrentContext());
      await verifySourceUnchanged();
      _cancel(cancellation);
      await _guard();
      _absent(_parentFd, _folder);
      _journal.append('publishIntent', {});
      await _checkpoint?.call(NativePublicationStage.publishIntentDurable);
      _cancel(cancellation);
      _admit(_plan, await readCurrentContext());
      await verifySourceUnchanged();
      await _guard();
      _verifyInventory(projectFd, seal, _limitsValue);
      await _revision(_projectPath, _stageRoot, stagedReceipt.nativeRevision,
          assets: stagedReceipt.assetHashes,
          borderSnapshotFiles: stagedReceipt.borderSnapshotFiles);
      _admit(_plan, await readCurrentContext());
      await verifySourceUnchanged();
      _verifyInventory(projectFd, seal, _limitsValue);
      _guardSynchronous();
      _requireStageIdentity(stageFd);
      if (_os.statAt(stageFd, _folder)?.identity !=
          _os.stat(projectFd).identity) {
        throw const NativePublicationException('publication.native.changed',
            'The staging project was replaced before promotion');
      }
      _cancel(cancellation);
      _os.renameExclusive(stageFd, _folder, _parentFd, _folder);
      _promoted = true;
      await _checkpoint?.call(NativePublicationStage.promotedBeforeReceipt);
      _os.sync(stageFd);
      _os.sync(_parentFd);
      _journal.append('published', {'inventoryHash': seal['inventoryHash']});
      final receipt = _receipt(seal);
      await _checkpoint?.call(NativePublicationStage.receiptCommitted);
      return receipt;
    } catch (error) {
      throw _exception(error,
          journalPath: journalPath,
          destinationPath: destinationPath,
          promoted: _promoted);
    } finally {
      if (projectFd != null) _os.close(projectFd);
      if (stageFd != null) _os.close(stageFd);
    }
  }

  Future<NativePublicationRecovery> _recover() async {
    await _guard(checkOverlap: false);
    final sealRecord =
        _journal.records.where((record) => record['state'] == 'sealed');
    final intent =
        _journal.records.any((record) => record['state'] == 'publishIntent');
    final destination = _os.statAt(_parentFd, _folder);
    final stage = _os.statAt(_parentFd, _stageName);
    if (destination == null) {
      if (sealRecord.isEmpty || stage == null) {
        return NativePublicationRecovery._(
            NativePublicationRecoveryState.incomplete, journalPath, null);
      }
      final seal = sealRecord.single['payload'] as Map<String, Object?>;
      final stageFd = _os.openDirectoryAt(_parentFd, _stageName);
      try {
        _requireStageIdentity(stageFd);
        final projectFd = _os.openDirectoryAt(stageFd, _folder);
        try {
          _verifyInventory(projectFd, seal, _limitsValue);
          await _revision(
              _projectPath, _stageRoot, seal['nativeRevision'] as String,
              assets: _sealAssets(seal),
              borderSnapshotFiles: _sealBorderSnapshotFiles(seal));
          _verifyInventory(projectFd, seal, _limitsValue);
        } finally {
          _os.close(projectFd);
        }
      } finally {
        _os.close(stageFd);
      }
      return NativePublicationRecovery._(
          NativePublicationRecoveryState.prepared, journalPath, null);
    }
    if (!intent || sealRecord.isEmpty || destination.kind != 0x4000) {
      return NativePublicationRecovery._(
          NativePublicationRecoveryState.conflict, journalPath, null);
    }
    final seal = sealRecord.single['payload'] as Map<String, Object?>;
    if (destination.identity != seal['projectIdentity']) {
      return NativePublicationRecovery._(
          NativePublicationRecoveryState.conflict, journalPath, null);
    }
    final needsReceipt =
        !_journal.records.any((record) => record['state'] == 'published');
    final fd = _os.openDirectoryAt(_parentFd, _folder);
    try {
      _verifyInventory(fd, seal, _limitsValue);
      await _revision(
          destinationPath, _parent, seal['nativeRevision'] as String,
          assets: _sealAssets(seal),
          borderSnapshotFiles: _sealBorderSnapshotFiles(seal));
      _verifyInventory(fd, seal, _limitsValue);
      if (stage != null) {
        final stageFd = _os.openDirectoryAt(_parentFd, _stageName);
        try {
          _requireStageIdentity(stageFd);
          if (_os.statAt(stageFd, _folder) != null) {
            return NativePublicationRecovery._(
                NativePublicationRecoveryState.conflict, journalPath, null);
          }
          if (needsReceipt) {
            _guardRecoveryWrites();
            _os.sync(stageFd);
          }
        } finally {
          _os.close(stageFd);
        }
      }
      if (needsReceipt) {
        _guardRecoveryWrites();
        _os.sync(_parentFd);
        _journal.repairTail();
        _journal.append('published', {'inventoryHash': seal['inventoryHash']});
      }
      return NativePublicationRecovery._(
          NativePublicationRecoveryState.published,
          journalPath,
          _receipt(seal));
    } finally {
      _os.close(fd);
    }
  }

  NativePublicationReceipt _receipt(Map<String, Object?> seal) =>
      NativePublicationReceipt._(
          projectPath: destinationPath,
          journalPath: journalPath,
          nativeRevision: seal['nativeRevision'] as String,
          draftHash: Sha256Hash(_header['draftHash'] as String),
          inventoryHash: Sha256Hash(seal['inventoryHash'] as String));

  Future<void> _guard({bool checkOverlap = true}) async {
    _live();
    await _policy(_policyValue, _parent, destinationPath,
        checkOverlap: checkOverlap);
    if (await Directory(_parent).resolveSymbolicLinks() != _parent ||
        _os.stat(_parentFd).identity != _header['parentIdentity']) {
      throw const NativePublicationException(
          'publication.parent.changed', 'Publication parent identity changed');
    }
    final current = _os.openDirectory(_parent);
    try {
      if (_os.stat(current).identity != _header['parentIdentity'] ||
          _os.statAt(_parentFd, _header['controlName'] as String)?.identity !=
              _header['controlIdentity']) {
        throw const NativePublicationException('publication.parent.changed',
            'Publication parent or journal directory was replaced');
      }
    } finally {
      _os.close(current);
    }
  }

  void _requireStageIdentity(int fd) {
    final record =
        _journal.records.firstWhere((r) => r['state'] == 'stageCreated');
    if (_os.stat(fd).identity != (record['payload'] as Map)['identity']) {
      throw const NativePublicationException(
          'publication.stage.changed', 'Reserved staging identity changed');
    }
  }

  void _guardSynchronous() {
    if (Directory(_parent).resolveSymbolicLinksSync() != _parent ||
        _os.statAt(_parentFd, _header['controlName'] as String)?.identity !=
            _header['controlIdentity']) {
      throw const NativePublicationException('publication.parent.changed',
          'Publication parent or journal directory changed before promotion');
    }
    final current = _os.openDirectory(_parent);
    try {
      if (_os.stat(current).identity != _header['parentIdentity']) {
        throw const NativePublicationException('publication.parent.changed',
            'Publication parent changed before promotion');
      }
    } finally {
      _os.close(current);
    }
  }

  void _guardRecoveryWrites() {
    _guardSynchronous();
    final writeRoots = [destinationPath, _stageRoot, path.dirname(journalPath)];
    for (final selectedRoot in _policyValue.sourceRoots) {
      _absolute(selectedRoot);
      var existing = path.normalize(selectedRoot);
      final missing = <String>[];
      while (FileSystemEntity.typeSync(existing, followLinks: false) ==
          FileSystemEntityType.notFound) {
        missing.insert(0, _component(path.basename(existing)));
        existing = path.dirname(existing);
      }
      final canonicalExisting = Directory(existing).resolveSymbolicLinksSync();
      if (FileSystemEntity.typeSync(canonicalExisting, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const NativePublicationException('publication.source.overlap',
            'Recovery source roots must resolve to directories');
      }
      final canonical = path.joinAll([canonicalExisting, ...missing]);
      if (_within(canonical, _parent) ||
          writeRoots.any(
              (root) => _within(canonical, root) || _within(root, canonical))) {
        throw const NativePublicationException('publication.source.overlap',
            'Recovery writes and source trees must not overlap');
      }
    }
  }

  void _live() {
    if (_closed) {
      throw const NativePublicationException(
          'publication.job.closed', 'Publication job is closed');
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _journal.close();
    _os.close(_controlFd);
    _os.close(_parentFd);
  }
}

void _platform() {
  if (!Platform.isMacOS ||
      !const [Abi.macosArm64, Abi.macosX64].contains(Abi.current())) {
    throw const NativePublicationException('publication.platform.unsupported',
        'Durable exclusive publication requires macOS arm64 or x64');
  }
}

void _limits(NativePublicationLimits limits) {
  if (limits.maxFiles <= 0 ||
      limits.maxFiles > 32768 ||
      limits.maxDepth <= 0 ||
      limits.maxDepth > 64 ||
      limits.maxFileBytes <= 0 ||
      limits.maxFileBytes > 536870912 ||
      limits.maxTotalBytes <= 0 ||
      limits.maxTotalBytes > 2147483648 ||
      limits.maxJournalBytes <= 0 ||
      limits.maxJournalBytes > 16777216 ||
      limits.maxJournalRecords <= 0 ||
      limits.maxJournalRecords > 8192) {
    throw const NativePublicationException('publication.quota.invalid',
        'Publication limits are outside bounded supported values');
  }
}

ContractLimits _jsonLimits(NativePublicationLimits limits) => ContractLimits(
    maxDepth: 16,
    maxNodes: 524288,
    maxStringCodeUnits: 8192,
    maxTextCodeUnits: limits.maxJournalBytes);

void _absolute(String value) {
  if (!path.isAbsolute(value) ||
      value.contains('\u0000') ||
      value.split('/').contains('..') ||
      value.length > 4096) {
    throw const NativePublicationException('publication.path.invalid',
        'An absolute bounded path without traversal is required');
  }
}

String _component(String value) {
  if (value.isEmpty ||
      value == '.' ||
      value == '..' ||
      value.contains('/') ||
      value.contains('\\') ||
      value.contains('\u0000') ||
      utf8.encode(value).length > 255) {
    throw const NativePublicationException('publication.path.invalid',
        'A bounded direct path component is required');
  }
  return value;
}

bool _within(String root, String value) =>
    root == value || path.isWithin(root, value);

Future<void> _policy(
    NativePublicationPolicy policy, String parent, String destination,
    {bool checkOverlap = true}) async {
  _absolute(parent);
  _absolute(destination);
  if (parent == path.rootPrefix(parent) ||
      policy.allowedParentRoots.isEmpty ||
      policy.allowedParentRoots.length > 32 ||
      policy.sourceRoots.isEmpty ||
      policy.sourceRoots.length > 32 ||
      policy.protectedRoots.length > 64 ||
      policy.minimumFreeBytes < 0 ||
      policy.minimumFreeBytes > 9007199254740991) {
    throw const NativePublicationException('publication.destination.protected',
        'Publication requires narrow destination and source roots');
  }
  final allowed = <String>[];
  for (final root in policy.allowedParentRoots) {
    _absolute(root);
    final canonical = await Directory(root).resolveSymbolicLinks();
    if (canonical == path.rootPrefix(canonical)) {
      throw const NativePublicationException(
          'publication.destination.protected',
          'The filesystem root cannot authorize publication');
    }
    allowed.add(canonical);
  }
  if (!allowed.any((root) => _within(root, parent))) {
    throw const NativePublicationException(
        'publication.destination.outsideRoots',
        'Publication parent is outside authorized destination roots');
  }
  for (final root in policy.protectedRoots) {
    _absolute(root);
    final canonical = await Directory(root).exists()
        ? await Directory(root).resolveSymbolicLinks()
        : path.normalize(root);
    if (_within(canonical, parent) || _within(canonical, destination)) {
      throw const NativePublicationException(
          'publication.destination.protected',
          'Publication is forbidden in a protected location');
    }
  }
  if (checkOverlap) {
    for (final root in policy.sourceRoots) {
      _absolute(root);
      final canonical = await Directory(root).resolveSymbolicLinks();
      if (_within(canonical, parent) ||
          _within(canonical, destination) ||
          _within(destination, canonical)) {
        throw const NativePublicationException('publication.source.overlap',
            'Publication and source trees must not overlap');
      }
    }
  }
}

void _cancel(ScanCancellation? cancellation) {
  if (cancellation?.isCancelled ?? false) {
    throw const NativePublicationException(
        'publication.cancelled', 'Publication was cancelled before promotion');
  }
}

int _estimate(NativeProjectDraft draft, NativePublicationLimits limits) {
  final artifacts = [...draft.artifacts, ...draft.sourceArtifacts];
  final artifactBytes =
      artifacts.fold<int>(0, (sum, item) => sum + item.bytes.length);
  final metadataBytes = draft.validatedJsonByteLength;
  return artifactBytes * 3 +
      metadataBytes * 2 +
      limits.maxJournalBytes * 2 +
      4194304;
}

void _admit(ConversionPlan plan, PlanContext context) {
  try {
    admitPlan(plan, context);
  } catch (_) {
    throw const NativePublicationException('publication.admission',
        'The current approval context no longer admits the exact plan');
  }
}

void _absent(int parentFd, String name) {
  if (_os.statAt(parentFd, name) != null) {
    throw const NativePublicationException('publication.destination.exists',
        'Publication destination must remain absent');
  }
}

NativePublicationException _exception(Object error,
    {String? journalPath, String? destinationPath, bool promoted = false}) {
  final original = error is NativePublicationException ? error : null;
  return NativePublicationException(
      original?.code ?? 'publication.failed',
      original?.message ??
          'Publication could not complete; retained job requires review',
      journalPath: journalPath ?? original?.journalPath,
      destinationPath: destinationPath ?? original?.destinationPath,
      promotionMayHaveOccurred:
          promoted || (original?.promotionMayHaveOccurred ?? false));
}

Map<String, Sha256Hash> _sealAssets(Map<String, Object?> seal) => {
      for (final entry in (seal['assetHashes'] as Map).entries)
        entry.key as String: Sha256Hash(entry.value as String),
    };

Map<String, NativeBorderSnapshotReceipt> _sealBorderSnapshotFiles(
    Map<String, Object?> seal) {
  final input = seal['borderSnapshotFiles'];
  if (seal.length != 6 ||
      !const {
        'projectIdentity',
        'nativeRevision',
        'inventory',
        'inventoryHash',
        'assetHashes',
        'borderSnapshotFiles'
      }.containsAll(seal.keys) ||
      input is! Map) {
    throw const NativePublicationException('publication.journal.invalid',
        'Native seal must contain its exact Border snapshot receipts');
  }
  return Map.unmodifiable({
    for (final entry in input.entries)
      entry.key as String: NativeBorderSnapshotReceipt.fromJson(entry.value)
  });
}

Future<void> _revision(String projectPath, String allowedRoot, String expected,
    {required Map<String, Sha256Hash> assets,
    required Map<String, NativeBorderSnapshotReceipt>
        borderSnapshotFiles}) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [allowedRoot], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(projectPath);
  try {
    final snapshot = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    if (snapshot.revision != expected || snapshot.loadDiagnostics.isNotEmpty) {
      throw const NativePublicationException('publication.native.changed',
          'Fresh native revision differs from the verified writer receipt');
    }
    ProjectValidator.validate(snapshot.manifest,
        maps: snapshot.maps, itemCatalog: snapshot.itemCatalog);
    final catalog = AssetCatalog.fromJson(jsonDecode(
            utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
        as Map<String, dynamic>);
    final access = handles.resolveProject(opened.projectHandle);
    final snapshotPaths = {
      for (final visual in snapshot.manifest.borderCatalog.visualSnapshots)
        for (final frame in visual.frames) frame.relativeAssetPath
    };
    if (snapshotPaths.length != borderSnapshotFiles.length ||
        !snapshotPaths.containsAll(borderSnapshotFiles.keys)) {
      throw _nativeChanged();
    }
    for (final entry in borderSnapshotFiles.entries) {
      final logicalPath = entry.key;
      if (logicalPath.length > 4096 ||
          !logicalPath.startsWith('assets/borders/snapshots/') ||
          !logicalPath.endsWith('.png') ||
          logicalPath.contains(r'\') ||
          logicalPath.contains(':') ||
          logicalPath.codeUnits.any((unit) => unit < 0x20) ||
          logicalPath
              .split('/')
              .any((part) => part.isEmpty || part == '.' || part == '..')) {
        throw _nativeChanged();
      }
      final before = await access.readResourceIdentity(logicalPath);
      if (before == null || before.byteLength != entry.value.byteLength) {
        throw _nativeChanged();
      }
      final bytes = await access.readBytes(logicalPath);
      final after = await access.readResourceIdentity(logicalPath);
      if (before != after ||
          bytes.length != entry.value.byteLength ||
          sha256.convert(bytes).toString() != entry.value.sha256.value) {
        throw _nativeChanged();
      }
    }
    for (final entry in assets.entries) {
      final record = catalog.require(entry.key);
      for (final logicalPath in {
        record.logicalPath,
        assetBlobStorageKey(record.artifact)
      }) {
        final before = await access.readResourceIdentity(logicalPath);
        if (before == null || before.byteLength != record.artifact.byteLength) {
          throw _nativeChanged();
        }
        final bytes = await access.readBytes(logicalPath);
        final after = await access.readResourceIdentity(logicalPath);
        if (before != after ||
            bytes.length != before.byteLength ||
            sha256.convert(bytes).toString() != entry.value.value) {
          throw _nativeChanged();
        }
      }
    }
  } catch (error) {
    if (error is NativePublicationException) rethrow;
    throw _nativeChanged();
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
}

List<Map<String, Object?>> _inventory(
    int projectFd, NativePublicationLimits limits,
    {bool sync = false, ScanCancellation? cancellation}) {
  final entries = <Map<String, Object?>>[];
  var total = 0;
  void walk(int directoryFd, String prefix, int depth) {
    _cancel(cancellation);
    final names = _os.names(directoryFd, limits.maxFiles);
    for (final name in names) {
      _cancel(cancellation);
      final relative = prefix.isEmpty ? name : '$prefix/$name';
      if (depth >= limits.maxDepth ||
          entries.length >= limits.maxFiles ||
          relative.length > 4096) {
        throw const NativePublicationException('publication.quota.inventory',
            'Native inventory exceeds its entry, depth or path bound');
      }
      final before = _os.statAt(directoryFd, name);
      if (before == null || !const [0x4000, 0x8000].contains(before.kind)) {
        throw const NativePublicationException('publication.native.kind',
            'Only direct directories and regular files can be published');
      }
      if (before.kind == 0x4000) {
        final child = _os.openDirectoryAt(directoryFd, name);
        try {
          if (_os.stat(child).identity != before.identity) {
            throw _nativeChanged();
          }
          entries.add(
              {'path': relative, 'kind': 'directory', 'mode': before.mode});
          walk(child, relative, depth + 1);
          if (_os.statAt(directoryFd, name)?.identity != before.identity) {
            throw _nativeChanged();
          }
          if (sync) _os.sync(child);
        } finally {
          _os.close(child);
        }
      } else {
        if (before.links != 1) {
          throw const NativePublicationException('publication.native.hardlink',
              'Native files must not have aliases outside their owned project');
        }
        if (before.length > limits.maxFileBytes ||
            before.length > limits.maxTotalBytes - total) {
          throw const NativePublicationException('publication.quota.inventory',
              'Native inventory exceeds its byte bound');
        }
        final fd = _os.openFileAt(directoryFd, name);
        try {
          if (_os.stat(fd).token != before.token) throw _nativeChanged();
          final digest = _os.hashFile(fd, before.length, cancellation);
          if (_os.stat(fd).token != before.token ||
              _os.statAt(directoryFd, name)?.token != before.token) {
            throw _nativeChanged();
          }
          if (sync) _os.sync(fd, full: true);
          total += before.length;
          entries.add({
            'path': relative,
            'kind': 'file',
            'mode': before.mode,
            'bytes': before.length,
            'sha256': digest
          });
        } finally {
          _os.close(fd);
        }
      }
    }
    if (!_sameStrings(names, _os.names(directoryFd, limits.maxFiles))) {
      throw _nativeChanged();
    }
  }

  walk(projectFd, '', 0);
  if (sync) _os.sync(projectFd);
  return entries;
}

bool _sameStrings(List<String> left, List<String> right) =>
    left.length == right.length &&
    Iterable<int>.generate(left.length).every((i) => left[i] == right[i]);

NativePublicationException _nativeChanged() => const NativePublicationException(
    'publication.native.changed',
    'Native project changed after its durable seal');

void _verifyInventory(
    int fd, Map<String, Object?> seal, NativePublicationLimits limits) {
  final expected = seal['inventory'];
  final expectedHash = seal['inventoryHash'];
  if (expected is! List ||
      expectedHash is! String ||
      canonicalHashOf(expected, limits: _jsonLimits(limits)).value !=
          expectedHash ||
      canonicalHashOf(_inventory(fd, limits), limits: _jsonLimits(limits))
              .value !=
          expectedHash ||
      _os.stat(fd).identity != seal['projectIdentity']) {
    throw _nativeChanged();
  }
}

void _validateHeader(
    Map<String, Object?> header,
    String parent,
    String controlName,
    int parentFd,
    int controlFd,
    NativePublicationPolicy policy) {
  final id = header['jobId'];
  if (id is! String ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(id) ||
      header['parent'] != parent ||
      header['controlName'] != controlName ||
      controlName != '.avelune-converter-job-$id' ||
      header['stageName'] != '.avelune-converter-stage-$id' ||
      header['parentIdentity'] != _os.stat(parentFd).identity ||
      header['controlIdentity'] != _os.stat(controlFd).identity ||
      header['policyHash'] != canonicalHashOf(policy.toJson()).value) {
    throw const NativePublicationException('publication.journal.binding',
        'Publication journal differs from its filesystem ownership or policy');
  }
  _component(header['folderName'] as String);
  for (final key in [
    'draftHash',
    'planHash',
    'sourceSnapshotHash',
    'targetProfileHash',
    'rulesHash',
    'decisionsHash'
  ]) {
    Sha256Hash(header[key] as String);
  }
}

final class _Journal {
  _Journal._(this.fd, this.controlFd, this.path, this.limits);
  final int fd;
  final int controlFd;
  final String path;
  final NativePublicationLimits limits;
  final List<Map<String, Object?>> records = [];
  String _previous = '0' * 64;
  int _bytes = 0;
  bool _tail = false;
  bool _closed = false;

  static _Journal create(
      int controlFd, String path, NativePublicationLimits limits) {
    final fd = _os.createFile(controlFd, 'journal.jsonl');
    try {
      _os.lock(fd);
      return _Journal._(fd, controlFd, path, limits);
    } catch (_) {
      _os.close(fd);
      rethrow;
    }
  }

  static _Journal open(
      int controlFd, String path, NativePublicationLimits limits) {
    final fd = _os.openWritableAt(controlFd, 'journal.jsonl');
    try {
      _os.lock(fd);
      final journal = _Journal._(fd, controlFd, path, limits);
      final stat = _os.stat(fd);
      if (stat.kind != 0x8000 ||
          stat.links != 1 ||
          stat.length > limits.maxJournalBytes) {
        throw const NativePublicationException('publication.journal.invalid',
            'Journal is not a bounded owned regular file');
      }
      final bytes = _os.readFile(fd, stat.length);
      var offset = 0;
      for (var i = 0; i < bytes.length; i++) {
        if (bytes[i] != 10) continue;
        if (journal.records.length >= limits.maxJournalRecords) {
          throw const NativePublicationException(
              'publication.quota.journal', 'Journal record limit exceeded');
        }
        final line = utf8.decode(bytes.sublist(offset, i));
        final decoded = jsonDecode(line);
        if (decoded is! Map<String, dynamic> ||
            canonicalJsonOf(decoded, limits: _jsonLimits(limits)) != line ||
            decoded['kind'] != 'aveluneNativePublicationJournal' ||
            decoded['version'] != 2 ||
            decoded['sequence'] != journal.records.length ||
            decoded['previousHash'] != journal._previous ||
            decoded['payload'] is! Map<String, dynamic> ||
            !const [
              'reserved',
              'stageIntent',
              'stageCreated',
              'creationIntent',
              'creationCompleted',
              'sealed',
              'publishIntent',
              'published'
            ].contains(decoded['state'])) {
          throw const NativePublicationException('publication.journal.invalid',
              'Journal sequence or canonical record is invalid');
        }
        journal.records.add(Map<String, Object?>.from(decoded));
        journal._previous = sha256.convert(bytes.sublist(offset, i)).toString();
        offset = i + 1;
      }
      if (journal.records.isEmpty ||
          journal.records.first['state'] != 'reserved') {
        throw const NativePublicationException('publication.journal.invalid',
            'Journal does not contain its durable ownership header');
      }
      journal._bytes = offset;
      journal._tail = offset != bytes.length;
      return journal;
    } catch (_) {
      _os.close(fd);
      rethrow;
    }
  }

  void append(String state, Map<String, Object?> payload) {
    if (_tail || records.length >= limits.maxJournalRecords) {
      throw const NativePublicationException('publication.quota.journal',
          'Journal cannot append outside its durable bounded sequence');
    }
    final record = <String, Object?>{
      'kind': 'aveluneNativePublicationJournal',
      'version': 2,
      'sequence': records.length,
      'previousHash': _previous,
      'state': state,
      'payload': payload,
    };
    final content =
        utf8.encode(canonicalJsonOf(record, limits: _jsonLimits(limits)));
    if (content.length + 1 > limits.maxJournalBytes - _bytes) {
      throw const NativePublicationException('publication.quota.journal',
          'Publication journal byte bound exceeded');
    }
    _os.seek(fd, _bytes);
    _os.write(fd, [...content, 10]);
    _os.sync(controlFd);
    _os.sync(fd, full: true);
    _bytes += content.length + 1;
    _previous = sha256.convert(content).toString();
    records.add(record);
  }

  void repairTail() {
    if (!_tail) return;
    _os.truncate(fd, _bytes);
    _os.sync(fd, full: true);
    _tail = false;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _os.close(fd);
  }
}

final class _Stat {
  _Stat(ByteData data)
      : mode = data.getUint16(4, Endian.host),
        links = data.getUint16(6, Endian.host),
        length = data.getInt64(96, Endian.host),
        identity = '${data.getInt32(0, Endian.host)}:'
            '${data.getUint64(8, Endian.host)}:${data.getUint32(120, Endian.host)}',
        times = '${data.getInt64(48, Endian.host)}:${data.getInt64(56, Endian.host)}:'
            '${data.getInt64(64, Endian.host)}:${data.getInt64(72, Endian.host)}:'
            '${data.getInt64(80, Endian.host)}:${data.getInt64(88, Endian.host)}';
  final int mode;
  final int links;
  final int length;
  final String identity;
  final String times;
  int get kind => mode & 0xf000;
  String get token => '$identity:$mode:$links:$length:$times';
}

final _PublicationOs _os = _PublicationOs();

final class _PublicationOs {
  _PublicationOs() {
    final lib = DynamicLibrary.open('/usr/lib/libSystem.B.dylib');
    final suffix = Abi.current() == Abi.macosX64 ? r'$INODE64' : '';
    _open = lib.lookupFunction<
        Int32 Function(Pointer<Utf8>, Int32, VarArgs<(Uint32,)>),
        int Function(Pointer<Utf8>, int, int)>('open');
    _openat = lib.lookupFunction<
        Int32 Function(Int32, Pointer<Utf8>, Int32, VarArgs<(Uint32,)>),
        int Function(int, Pointer<Utf8>, int, int)>('openat');
    close =
        lib.lookupFunction<Int32 Function(Int32), int Function(int)>('close');
    _stat = lib.lookupFunction<Int32 Function(Int32, Pointer<Uint8>),
        int Function(int, Pointer<Uint8>)>('fstat$suffix');
    _statat = lib.lookupFunction<
        Int32 Function(Int32, Pointer<Utf8>, Pointer<Uint8>, Int32),
        int Function(
            int, Pointer<Utf8>, Pointer<Uint8>, int)>('fstatat$suffix');
    _statfs = lib.lookupFunction<Int32 Function(Int32, Pointer<Uint8>),
        int Function(int, Pointer<Uint8>)>('fstatfs');
    _mkdirat = lib.lookupFunction<Int32 Function(Int32, Pointer<Utf8>, Uint32),
        int Function(int, Pointer<Utf8>, int)>('mkdirat');
    _rename = lib.lookupFunction<
        Int32 Function(Int32, Pointer<Utf8>, Int32, Pointer<Utf8>, Uint32),
        int Function(
            int, Pointer<Utf8>, int, Pointer<Utf8>, int)>('renameatx_np');
    _fsync =
        lib.lookupFunction<Int32 Function(Int32), int Function(int)>('fsync');
    _fcntl = lib.lookupFunction<Int32 Function(Int32, Int32, VarArgs<(Int32,)>),
        int Function(int, int, int)>('fcntl');
    _flock = lib.lookupFunction<Int32 Function(Int32, Int32),
        int Function(int, int)>('flock');
    _read = lib.lookupFunction<IntPtr Function(Int32, Pointer<Uint8>, IntPtr),
        int Function(int, Pointer<Uint8>, int)>('read');
    _write = lib.lookupFunction<IntPtr Function(Int32, Pointer<Uint8>, IntPtr),
        int Function(int, Pointer<Uint8>, int)>('write');
    _seek = lib.lookupFunction<Int64 Function(Int32, Int64, Int32),
        int Function(int, int, int)>('lseek');
    _truncate = lib.lookupFunction<Int32 Function(Int32, Int64),
        int Function(int, int)>('ftruncate');
    _fdopendir = lib.lookupFunction<Pointer<Void> Function(Int32),
        Pointer<Void> Function(int)>('fdopendir$suffix');
    _readdir = lib.lookupFunction<Pointer<Uint8> Function(Pointer<Void>),
        Pointer<Uint8> Function(Pointer<Void>)>('readdir$suffix');
    _closedir = lib.lookupFunction<Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('closedir');
    _errno = lib.lookupFunction<Pointer<Int32> Function(),
        Pointer<Int32> Function()>('__error');
  }
  late final int Function(Pointer<Utf8>, int, int) _open;
  late final int Function(int, Pointer<Utf8>, int, int) _openat;
  late final int Function(int) close;
  late final int Function(int, Pointer<Uint8>) _stat;
  late final int Function(int, Pointer<Utf8>, Pointer<Uint8>, int) _statat;
  late final int Function(int, Pointer<Uint8>) _statfs;
  late final int Function(int, Pointer<Utf8>, int) _mkdirat;
  late final int Function(int, Pointer<Utf8>, int, Pointer<Utf8>, int) _rename;
  late final int Function(int) _fsync;
  late final int Function(int, int, int) _fcntl;
  late final int Function(int, int) _flock;
  late final int Function(int, Pointer<Uint8>, int) _read;
  late final int Function(int, Pointer<Uint8>, int) _write;
  late final int Function(int, int, int) _seek;
  late final int Function(int, int) _truncate;
  late final Pointer<Void> Function(int) _fdopendir;
  late final Pointer<Uint8> Function(Pointer<Void>) _readdir;
  late final int Function(Pointer<Void>) _closedir;
  late final Pointer<Int32> Function() _errno;
  static const _directoryFlags = 0x01000000 | 0x00100000 | 0x100;
  static const _fileFlags = 0x01000000 | 0x100 | 4;

  T _name<T>(String name, T Function(Pointer<Utf8>) operation) {
    final pointer = name.toNativeUtf8();
    try {
      return operation(pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  int openDirectory(String root) =>
      _fd(_name(root, (name) => _open(name, _directoryFlags, 0)));
  int openDirectoryAt(int parent, String name) => _fd(_name(
      _component(name), (value) => _openat(parent, value, _directoryFlags, 0)));
  int openFileAt(int parent, String name) => _fd(_name(
      _component(name), (value) => _openat(parent, value, _fileFlags, 0)));
  int openWritableAt(int parent, String name) => _fd(_name(
      _component(name), (value) => _openat(parent, value, _fileFlags | 2, 0)));
  int createFile(int parent, String name) => _fd(_name(
      _component(name),
      (value) =>
          _openat(parent, value, _fileFlags | 2 | 0x200 | 0x800, 0x180)));

  int _fd(int fd) {
    if (fd < 0) throw _io();
    return fd;
  }

  _Stat stat(int fd) {
    final bytes = calloc<Uint8>(144);
    try {
      if (_stat(fd, bytes) != 0) throw _io();
      return _Stat(ByteData.sublistView(bytes.asTypedList(144)));
    } finally {
      calloc.free(bytes);
    }
  }

  _Stat? statAt(int parent, String name) {
    final bytes = calloc<Uint8>(144);
    try {
      final result = _name(
          _component(name), (value) => _statat(parent, value, bytes, 0x20));
      if (result != 0) {
        if (_errno().value == 2) return null;
        throw _io();
      }
      return _Stat(ByteData.sublistView(bytes.asTypedList(144)));
    } finally {
      calloc.free(bytes);
    }
  }

  void mkdir(int parent, String name) {
    if (_name(_component(name), (value) => _mkdirat(parent, value, 0x1c0)) !=
        0) {
      throw _io();
    }
  }

  void lock(int fd) {
    if (_flock(fd, 2 | 4) != 0) {
      throw const NativePublicationException('publication.journal.busy',
          'Publication journal belongs to an active process');
    }
  }

  void requireLocal(int fd) {
    final bytes = calloc<Uint8>(2168);
    try {
      if (_statfs(fd, bytes) != 0) throw _io();
      final data = ByteData.sublistView(bytes.asTypedList(2168));
      final name = utf8.decode(bytes
          .asTypedList(2168)
          .sublist(72, 88)
          .takeWhile((byte) => byte != 0)
          .toList());
      if ((data.getUint32(64, Endian.host) & 0x1000) == 0 ||
          !const ['apfs', 'hfs'].contains(name)) {
        throw const NativePublicationException(
            'publication.filesystem.unsupported',
            'Durable publication requires a supported local macOS filesystem');
      }
    } finally {
      calloc.free(bytes);
    }
  }

  int availableBytes(int fd) {
    final bytes = calloc<Uint8>(2168);
    try {
      if (_statfs(fd, bytes) != 0) throw _io();
      final data = ByteData.sublistView(bytes.asTypedList(2168));
      final blockSize = data.getUint32(0, Endian.host);
      final blocks = data.getUint64(24, Endian.host);
      if (blockSize <= 0 || blocks > 9007199254740991 ~/ blockSize) {
        throw const NativePublicationException('publication.space.unavailable',
            'A bounded available-space observation is required');
      }
      return blocks * blockSize;
    } finally {
      calloc.free(bytes);
    }
  }

  void renameExclusive(
      int source, String name, int parent, String destination) {
    final result = _name(
        _component(name),
        (from) => _name(_component(destination),
            (to) => _rename(source, from, parent, to, 4)));
    if (result == 0) return;
    if (const [17, 66].contains(_errno().value)) {
      throw const NativePublicationException('publication.destination.exists',
          'Exclusive promotion refused an existing destination');
    }
    throw const NativePublicationException('publication.promotion.failed',
        'Exclusive promotion failed and requires reconciliation',
        promotionMayHaveOccurred: true);
  }

  void sync(int fd, {bool full = false}) {
    _retry(() => _fsync(fd));
    if (full) _retry(() => _fcntl(fd, 51, 0));
  }

  void seek(int fd, int offset) {
    if (_seek(fd, offset, 0) != offset) throw _io();
  }

  void truncate(int fd, int size) => _retry(() => _truncate(fd, size));

  void _retry(int Function() call) {
    while (call() < 0) {
      if (_errno().value != 4) throw _io();
    }
  }

  void write(int fd, List<int> bytes) {
    final buffer = calloc<Uint8>(bytes.length);
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      var offset = 0;
      while (offset < bytes.length) {
        final count = _write(fd, buffer + offset, bytes.length - offset);
        if (count < 0 && _errno().value == 4) continue;
        if (count <= 0) throw _io();
        offset += count;
      }
    } finally {
      calloc.free(buffer);
    }
  }

  List<int> readFile(int fd, int length) {
    seek(fd, 0);
    final bytes = BytesBuilder(copy: false);
    _readChunks(
        fd, length, (chunk) => bytes.add(Uint8List.fromList(chunk)), null);
    return bytes.takeBytes();
  }

  String hashFile(int fd, int length, ScanCancellation? cancellation) {
    final digest = _DigestSink();
    final sink = sha256.startChunkedConversion(digest);
    try {
      _readChunks(fd, length, sink.add, cancellation);
    } finally {
      sink.close();
    }
    return digest.value!.toString();
  }

  void _readChunks(int fd, int length, void Function(List<int>) accept,
      ScanCancellation? cancellation) {
    final buffer = calloc<Uint8>(65536);
    try {
      var consumed = 0;
      while (true) {
        _cancel(cancellation);
        final count = _read(fd, buffer, 65536);
        if (count < 0 && _errno().value == 4) continue;
        if (count < 0) throw _io();
        if (count == 0) break;
        consumed += count;
        if (consumed > length) throw _nativeChanged();
        accept(buffer.asTypedList(count));
      }
      if (consumed != length) throw _nativeChanged();
    } finally {
      calloc.free(buffer);
    }
  }

  List<String> names(int fd, int maximum) {
    final owned =
        _fd(_name('.', (value) => _openat(fd, value, _directoryFlags, 0)));
    final directory = _fdopendir(owned);
    if (directory == nullptr) {
      close(owned);
      throw _io();
    }
    try {
      final names = <String>[];
      while (true) {
        _errno().value = 0;
        final entry = _readdir(directory);
        if (entry == nullptr) {
          if (_errno().value != 0) throw _io();
          break;
        }
        final header = ByteData.sublistView(entry.asTypedList(21));
        final count = header.getUint16(18, Endian.host);
        if (count <= 0 ||
            count >= 1024 ||
            header.getUint16(16, Endian.host) <= 21 + count) {
          throw _io();
        }
        final name = utf8.decode((entry + 21).asTypedList(count));
        if (name == '.' || name == '..') continue;
        names.add(_component(name));
        if (names.length > maximum) {
          throw const NativePublicationException('publication.quota.inventory',
              'Directory inventory exceeds its bound');
        }
      }
      return names..sort();
    } finally {
      _closedir(directory);
    }
  }

  NativePublicationException _io() => const NativePublicationException(
      'publication.io', 'Owned publication filesystem operation failed');
}

final class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
