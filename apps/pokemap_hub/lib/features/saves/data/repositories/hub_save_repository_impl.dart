import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/saves/domain/entities/save_profile.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_slot_metadata.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';

enum SaveWriteStage {
  afterTemporaryFlushed,
  afterTemporaryVerified,
  afterCurrentStagedAsBackup,
  afterPreviousBackupRemoved,
  afterBackupPromoted,
  afterCurrentPromoted,
  afterCurrentConfirmed,
}

typedef SaveWriteFaultHook = Future<void> Function(SaveWriteStage stage);

final class SaveMigrationSnapshot {
  const SaveMigrationSnapshot._({
    required this.address,
    required this.sourceGameVersion,
    required this.sourceSaveId,
    required this.primaryFile,
    required this.backupFile,
  });

  final SaveSlotAddress address;
  final String sourceGameVersion;
  final String sourceSaveId;
  final File primaryFile;
  final File backupFile;
}

final class SaveMigrationResult {
  const SaveMigrationResult({
    required this.envelope,
    required this.snapshot,
  });

  final SaveEnvelope envelope;
  final SaveMigrationSnapshot snapshot;
}

/// App-private, game-scoped save storage rooted under PokeMap support data.
final class HubSaveStore {
  HubSaveStore({
    required this.supportRoot,
    required this.identity,
    this.codec = const SaveEnvelopeCodec(),
    this.compatibilityEvaluator = const SaveCompatibilityEvaluator(),
    this.faultHook,
  });

  final Directory supportRoot;
  final GameIdentity identity;
  final SaveEnvelopeCodec codec;
  final SaveCompatibilityEvaluator compatibilityEvaluator;
  final SaveWriteFaultHook? faultHook;

  static final Map<String, Future<void>> _slotQueues = <String, Future<void>>{};
  static int _nonce = 0;

  Future<void> write(SaveEnvelope envelope) async {
    await writeVerified(envelope);
  }

  /// Atomically writes and returns the exact generation confirmed on disk.
  Future<SaveEnvelope> writeVerified(SaveEnvelope envelope) async {
    _assertAddressScope(envelope.address);
    final validated = codec.decode(
      codec.encode(envelope),
      expectedAddress: envelope.address,
      acceptedSaveFormats: <int>{identity.saveFormat},
    );
    final compatibility = compatibilityEvaluator.evaluate(
      save: validated.compatibility,
      game: identity,
    );
    if (!compatibility.isAccepted) {
      throw SaveStorageException(
        SaveStorageErrorCode.invalidEnvelope,
        'Save is not compatible with the active game identity: '
        '${compatibility.code?.name}.',
      );
    }
    final slot = (await _safeSlotDirectory(envelope.address, create: true))!;
    return _queueSlot<SaveEnvelope>(
      slot.path,
      () => _withFileLock<SaveEnvelope>(
        slot,
        () => _writeLocked(slot, validated),
      ),
    );
  }

  Future<SaveSlotRead> read(
    SaveSlotAddress address, {
    bool migrationChainAvailable = false,
  }) async {
    _assertAddressScope(address);
    final slot = await _safeSlotDirectory(address, create: false);
    if (slot == null) {
      return SaveSlotRead(
        address: address,
        status: SaveSlotReadStatus.missing,
        diagnostics: const <SaveStorageDiagnostic>[
          SaveStorageDiagnostic(
            SaveStorageDiagnosticCode.missing,
            'No save exists for this slot.',
          ),
        ],
      );
    }
    return _queueSlot<SaveSlotRead>(
      slot.path,
      () => _withFileLock<SaveSlotRead>(
        slot,
        () => _readLocked(
          slot,
          address,
          migrationChainAvailable: migrationChainAvailable,
        ),
      ),
    );
  }

  Future<void> saveProfile(SaveProfile profile) async {
    profile.validate();
    final profileDirectory = await _safeProfileDirectory(
      profile.profileId,
      create: true,
    );
    final target = File(p.join(profileDirectory!.path, 'profile.json'));
    await _rejectLink(target.path);
    final temporary = File('${target.path}.tmp.$pid.${_nonce++}');
    try {
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(profile.toJson()),
        flush: true,
      );
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
    } catch (error) {
      if (await temporary.exists()) await temporary.delete();
      throw SaveStorageException(
        SaveStorageErrorCode.ioFailure,
        'Failed to persist profile metadata.',
        cause: error,
      );
    }
  }

  Future<List<SaveProfile>> listProfiles() async {
    final gameDirectory = await _safeGameDirectory(create: false);
    if (gameDirectory == null) return const <SaveProfile>[];
    final profiles = <SaveProfile>[];
    await for (final entity in gameDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final profileId = p.basename(entity.path);
      try {
        GameIdentity.validateLocalId(profileId, path: r'$.profileId');
        final metadata = File(p.join(entity.path, 'profile.json'));
        if (!await metadata.exists()) continue;
        final decoded = jsonDecode(await metadata.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        profiles.add(SaveProfile.fromJson(decoded));
      } catch (_) {
        // Invalid profile metadata remains on disk for diagnostics/repair.
      }
    }
    profiles.sort((left, right) => left.profileId.compareTo(right.profileId));
    return List<SaveProfile>.unmodifiable(profiles);
  }

  Future<void> deleteProfile(String profileId) async {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    final profile = await _safeProfileDirectory(profileId, create: false);
    if (profile == null) return;
    await _queueSlot<void>(
      profile.path,
      () => _withFileLock<void>(
        profile,
        () => profile.delete(recursive: true),
      ),
    );
  }

  Future<void> saveSlotMetadata({
    required String profileId,
    required SaveSlotMetadata metadata,
  }) async {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    metadata.validate();
    final slot = await _safeSlotDirectory(
      SaveSlotAddress(
        gameId: identity.gameId,
        profileId: profileId,
        slotId: metadata.slotId,
      ),
      create: true,
    );
    final target = File(p.join(slot!.path, 'slot.json'));
    await _rejectLink(target.path);
    final temporary = File('${target.path}.tmp.$pid.${_nonce++}');
    try {
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata.toJson()),
        flush: true,
      );
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
    } catch (error) {
      if (await temporary.exists()) await temporary.delete();
      throw SaveStorageException(
        SaveStorageErrorCode.ioFailure,
        'Failed to persist slot metadata.',
        cause: error,
      );
    }
  }

  Future<List<SaveSlotMetadata>> listSlotMetadata({
    required String profileId,
  }) async {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    final profile = await _safeProfileDirectory(profileId, create: false);
    if (profile == null) return const <SaveSlotMetadata>[];
    final result = <SaveSlotMetadata>[];
    await for (final entity in profile.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final file = File(p.join(entity.path, 'slot.json'));
      try {
        await _rejectLink(file.path);
        if (!await file.exists()) continue;
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        final metadata = SaveSlotMetadata.fromJson(decoded);
        if (metadata.slotId != p.basename(entity.path)) continue;
        result.add(metadata);
      } catch (_) {
        // Invalid metadata remains available for diagnostics and repair.
      }
    }
    result.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return List<SaveSlotMetadata>.unmodifiable(result);
  }

  Future<List<SaveSlotSummary>> listSlots({
    required String profileId,
  }) async {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    final profile = await _safeProfileDirectory(profileId, create: false);
    if (profile == null) return const <SaveSlotSummary>[];
    final summaries = <SaveSlotSummary>[];
    await for (final entity in profile.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final slotId = p.basename(entity.path);
      try {
        GameIdentity.validateLocalId(slotId, path: r'$.slotId');
        final result = await read(
          SaveSlotAddress(
            gameId: identity.gameId,
            profileId: profileId,
            slotId: slotId,
          ),
        );
        summaries.add(
          SaveSlotSummary(
            address: result.address,
            status: result.status,
            updatedAt: result.envelope?.updatedAt,
            playTimeSeconds: result.envelope?.playTimeSeconds,
          ),
        );
      } catch (_) {
        // Non-slot directories and hostile entries are ignored, never followed.
      }
    }
    summaries.sort((left, right) {
      final byRecency = switch ((left.updatedAt, right.updatedAt)) {
        (final leftDate?, final rightDate?) => rightDate.compareTo(leftDate),
        (null, DateTime()) => 1,
        (DateTime(), null) => -1,
        (null, null) => 0,
      };
      return byRecency != 0
          ? byRecency
          : left.address.slotId.compareTo(right.address.slotId);
    });
    return List<SaveSlotSummary>.unmodifiable(summaries);
  }

  Future<SaveSlotRead?> findContinue({String? profileId}) async {
    final candidates = <SaveSlotRead>[];
    final profileIds = <String>[];
    if (profileId != null) {
      GameIdentity.validateLocalId(profileId, path: r'$.profileId');
      profileIds.add(profileId);
    } else {
      final game = await _safeGameDirectory(create: false);
      if (game != null) {
        await for (final entity in game.list(followLinks: false)) {
          if (entity is! Directory) continue;
          final candidate = p.basename(entity.path);
          try {
            GameIdentity.validateLocalId(candidate, path: r'$.profileId');
            profileIds.add(candidate);
          } on SaveContractException {
            // Invalid directories cannot become player profiles.
          }
        }
      }
    }
    for (final id in profileIds) {
      final profile = await _safeProfileDirectory(id, create: false);
      if (profile == null) continue;
      await for (final entity in profile.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final slotId = p.basename(entity.path);
        try {
          final result = await read(
            SaveSlotAddress(
              gameId: identity.gameId,
              profileId: id,
              slotId: slotId,
            ),
          );
          if (result.canContinue) candidates.add(result);
        } catch (_) {
          // Invalid directory names cannot participate in Continue.
        }
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((left, right) {
      final byRecency =
          right.envelope!.updatedAt.compareTo(left.envelope!.updatedAt);
      if (byRecency != 0) return byRecency;
      final byProfile =
          left.address.profileId.compareTo(right.address.profileId);
      return byProfile != 0
          ? byProfile
          : left.address.slotId.compareTo(right.address.slotId);
    });
    return candidates.first;
  }

  Future<void> deleteSlot(SaveSlotAddress address) async {
    _assertAddressScope(address);
    final slot = await _safeSlotDirectory(address, create: false);
    if (slot == null) return;
    await _queueSlot<void>(
      slot.path,
      () => _withFileLock<void>(slot, () async {
        await slot.delete(recursive: true);
      }),
    );
  }

  Future<SaveMigrationResult> migrate({
    required SaveSlotAddress address,
    required SaveMigrationEngine engine,
    required String newSaveId,
    required DateTime updatedAt,
  }) async {
    _assertAddressScope(address);
    final sourceRead = await read(address);
    final source = sourceRead.envelope;
    if (source == null ||
        source.gameId != identity.gameId ||
        source.compatibilityId != identity.compatibilityId ||
        source.saveFormat >= identity.saveFormat ||
        !engine.hasChain(
          fromFormat: source.saveFormat,
          toFormat: identity.saveFormat,
        )) {
      throw SaveMigrationException(
        SaveMigrationErrorCode.chainUnavailable,
        'No trusted migration chain is available for this save.',
      );
    }

    final slot = (await _safeSlotDirectory(address, create: true))!;
    return _queueSlot<SaveMigrationResult>(
      slot.path,
      () => _withFileLock<SaveMigrationResult>(slot, () async {
        final snapshot = await _createMigrationSnapshot(
          slot: slot,
          source: source,
        );
        final migrated = engine.migrate(
          source: source,
          targetIdentity: identity,
          newSaveId: newSaveId,
          updatedAt: updatedAt,
        );
        await _writeLocked(slot, migrated, allowMigrationSource: true);
        return SaveMigrationResult(envelope: migrated, snapshot: snapshot);
      }),
    );
  }

  Future<void> restoreMigrationSnapshot(
    SaveMigrationSnapshot snapshot,
  ) async {
    _assertAddressScope(snapshot.address);
    final slot = (await _safeSlotDirectory(snapshot.address, create: false))!;
    final snapshotsRoot = p.join(slot.path, 'migration-snapshots');
    final snapshotResolved = await snapshot.primaryFile.resolveSymbolicLinks();
    final rootResolved = await Directory(snapshotsRoot).resolveSymbolicLinks();
    if (!p.isWithin(rootResolved, snapshotResolved)) {
      throw const SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Migration snapshot is outside the expected slot.',
      );
    }
    final restored = await _decodeCandidate(
      snapshot.primaryFile,
      snapshot.address,
    );
    final compatibility = compatibilityEvaluator.evaluate(
      save: restored.compatibility,
      game: identity,
    );
    if (!compatibility.isAccepted) {
      throw SaveStorageException(
        SaveStorageErrorCode.invalidEnvelope,
        'Snapshot is incompatible with the rollback game identity.',
      );
    }
    await _queueSlot<void>(
      slot.path,
      () => _withFileLock<void>(
        slot,
        () => _writeLocked(
          slot,
          restored,
          allowIncompatibleCurrent: true,
        ),
      ),
    );
  }

  Future<SaveMigrationSnapshot> _createMigrationSnapshot({
    required Directory slot,
    required SaveEnvelope source,
  }) async {
    final snapshots =
        (await _safeChildDirectory(slot, 'migration-snapshots', create: true))!;
    final version = (await _safeChildDirectory(
      snapshots,
      source.gameVersion,
      create: true,
    ))!;
    final directory = (await _safeChildDirectory(
      version,
      source.saveId,
      create: true,
    ))!;
    final primary = File(p.join(directory.path, 'save.json'));
    final backup = File(p.join(directory.path, 'save.backup.json'));
    for (final file in <File>[primary, backup]) {
      await _rejectLink(file.path);
    }
    if (!await primary.exists()) {
      await primary.writeAsString(codec.encode(source), flush: true);
    }
    final verified = await _decodeCandidate(primary, source.address);
    if (verified.checksum != source.checksum) {
      throw const SaveStorageException(
        SaveStorageErrorCode.invalidEnvelope,
        'Pre-migration snapshot does not match the source save.',
      );
    }
    final liveBackup = File(p.join(slot.path, 'save.backup.json'));
    if (!await backup.exists() && await _isValid(liveBackup, source.address)) {
      await liveBackup.copy(backup.path);
    }
    return SaveMigrationSnapshot._(
      address: source.address,
      sourceGameVersion: source.gameVersion,
      sourceSaveId: source.saveId,
      primaryFile: primary,
      backupFile: backup,
    );
  }

  Future<SaveEnvelope> _writeLocked(
    Directory slot,
    SaveEnvelope envelope, {
    bool allowMigrationSource = false,
    bool allowIncompatibleCurrent = false,
  }) async {
    final current = File(p.join(slot.path, 'save.json'));
    final backup = File(p.join(slot.path, 'save.backup.json'));
    final nextBackup = File(p.join(slot.path, 'save.backup.json.next'));
    final temporary = File(p.join(slot.path, 'save.json.tmp.$pid.${_nonce++}'));
    for (final file in <File>[current, backup, nextBackup, temporary]) {
      await _rejectLink(file.path);
    }

    try {
      final handle = await temporary.open(mode: FileMode.write);
      try {
        await handle.writeFrom(codec.encodeUtf8(envelope));
        await handle.flush();
      } finally {
        await handle.close();
      }
      await _fault(SaveWriteStage.afterTemporaryFlushed);
      codec.decode(
        await temporary.readAsString(),
        expectedAddress: envelope.address,
        acceptedSaveFormats: <int>{identity.saveFormat},
      );
      await _fault(SaveWriteStage.afterTemporaryVerified);

      var rotateCurrent = false;
      if (await current.exists()) {
        try {
          final currentEnvelope =
              await _decodeCandidate(current, envelope.address);
          final currentCompatibility = compatibilityEvaluator.evaluate(
            save: currentEnvelope.compatibility,
            game: identity,
            migrationChainAvailable: allowMigrationSource,
          );
          rotateCurrent = allowIncompatibleCurrent ||
              currentCompatibility.isAccepted ||
              (allowMigrationSource &&
                  currentCompatibility.disposition ==
                      SaveCompatibilityDisposition.migrate);
          if (!rotateCurrent) {
            throw SaveStorageException(
              SaveStorageErrorCode.invalidEnvelope,
              'Refusing to overwrite an incompatible current save.',
            );
          }
        } on SaveStorageException {
          rethrow;
        } catch (_) {
          await _quarantine(slot, current);
        }
      }
      if (rotateCurrent) {
        if (await nextBackup.exists()) await nextBackup.delete();
        await current.rename(nextBackup.path);
        await _fault(SaveWriteStage.afterCurrentStagedAsBackup);
        if (await backup.exists()) await backup.delete();
        await _fault(SaveWriteStage.afterPreviousBackupRemoved);
        await nextBackup.rename(backup.path);
      }
      await _fault(SaveWriteStage.afterBackupPromoted);
      await temporary.rename(current.path);
      await _fault(SaveWriteStage.afterCurrentPromoted);
      final confirmed = codec.decode(
        await current.readAsString(),
        expectedAddress: envelope.address,
        acceptedSaveFormats: <int>{identity.saveFormat},
      );
      if (confirmed.checksum != envelope.checksum) {
        throw const SaveStorageException(
          SaveStorageErrorCode.invalidEnvelope,
          'The confirmed save does not match the proposed generation.',
        );
      }
      await _fault(SaveWriteStage.afterCurrentConfirmed);
      return confirmed;
    } catch (error) {
      await _restoreAnyValidCurrent(
        slot: slot,
        address: envelope.address,
        temporary: temporary,
      );
      throw SaveStorageException(
        SaveStorageErrorCode.writeInterrupted,
        'Atomic save write was interrupted; a valid generation was retained.',
        cause: error,
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<SaveSlotRead> _readLocked(
    Directory slot,
    SaveSlotAddress address, {
    required bool migrationChainAvailable,
  }) async {
    final diagnostics = <SaveStorageDiagnostic>[];
    final candidates = <(File, SaveSlotSource)>[
      (File(p.join(slot.path, 'save.json')), SaveSlotSource.current),
      (
        File(p.join(slot.path, 'save.backup.json.next')),
        SaveSlotSource.pendingBackup,
      ),
      (File(p.join(slot.path, 'save.backup.json')), SaveSlotSource.backup),
    ];
    for (final candidate in candidates) {
      final file = candidate.$1;
      await _rejectLink(file.path);
      if (!await file.exists()) continue;
      SaveEnvelope envelope;
      try {
        envelope = await _decodeCandidate(file, address);
      } catch (error) {
        if (candidate.$2 == SaveSlotSource.current) {
          diagnostics.add(
            const SaveStorageDiagnostic(
              SaveStorageDiagnosticCode.primaryCorrupt,
              'The primary save is corrupt and was quarantined.',
            ),
          );
        }
        await _quarantine(slot, file);
        continue;
      }
      final compatibility = compatibilityEvaluator.evaluate(
        save: envelope.compatibility,
        game: identity,
        migrationChainAvailable: migrationChainAvailable,
      );
      switch (compatibility.disposition) {
        case SaveCompatibilityDisposition.accept:
          final recovered = candidate.$2 != SaveSlotSource.current;
          if (recovered) {
            diagnostics.add(
              const SaveStorageDiagnostic(
                SaveStorageDiagnosticCode.backupUsed,
                'A valid backup is available; promotion requires confirmation.',
              ),
            );
          }
          return SaveSlotRead(
            address: address,
            status: recovered
                ? SaveSlotReadStatus.recoveredFromBackup
                : SaveSlotReadStatus.valid,
            envelope: envelope,
            source: candidate.$2,
            diagnostics: List<SaveStorageDiagnostic>.unmodifiable(diagnostics),
          );
        case SaveCompatibilityDisposition.migrate:
          return SaveSlotRead(
            address: address,
            status: SaveSlotReadStatus.migrationRequired,
            envelope: envelope,
            source: candidate.$2,
            diagnostics: const <SaveStorageDiagnostic>[
              SaveStorageDiagnostic(
                SaveStorageDiagnosticCode.saveMigrationRequired,
                'This save requires a trusted engine migration.',
              ),
            ],
          );
        case SaveCompatibilityDisposition.reject:
          return SaveSlotRead(
            address: address,
            status: SaveSlotReadStatus.incompatible,
            envelope:
                compatibility.code == SaveCompatibilityCode.saveGameMismatch
                    ? null
                    : envelope,
            source: candidate.$2,
            diagnostics: <SaveStorageDiagnostic>[
              _compatibilityDiagnostic(compatibility.code!),
            ],
          );
      }
    }
    return SaveSlotRead(
      address: address,
      status: diagnostics.isEmpty
          ? SaveSlotReadStatus.missing
          : SaveSlotReadStatus.corrupt,
      diagnostics: diagnostics.isEmpty
          ? const <SaveStorageDiagnostic>[
              SaveStorageDiagnostic(
                SaveStorageDiagnosticCode.missing,
                'No save exists for this slot.',
              ),
            ]
          : List<SaveStorageDiagnostic>.unmodifiable(diagnostics),
    );
  }

  Future<SaveEnvelope> _decodeCandidate(
    File file,
    SaveSlotAddress address,
  ) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic> || decoded['saveFormat'] is! int) {
      throw const FormatException('Invalid save candidate.');
    }
    final format = decoded['saveFormat']! as int;
    final envelope = codec.decodeJson(
      decoded,
      acceptedSaveFormats: <int>{format},
    );
    if (envelope.profileId != address.profileId ||
        envelope.slotId != address.slotId) {
      throw const SaveContractException(
        SaveContractErrorCode.addressMismatch,
        'Save profile/slot does not match its storage address.',
      );
    }
    return envelope;
  }

  Future<void> _restoreAnyValidCurrent({
    required Directory slot,
    required SaveSlotAddress address,
    required File temporary,
  }) async {
    final current = File(p.join(slot.path, 'save.json'));
    if (await _isValid(current, address)) return;
    for (final source in <File>[
      File(p.join(slot.path, 'save.backup.json.next')),
      File(p.join(slot.path, 'save.backup.json')),
    ]) {
      if (await _isValid(source, address)) {
        if (await current.exists()) await _quarantine(slot, current);
        await source.copy(current.path);
        return;
      }
    }
    if (await _isValid(temporary, address)) {
      if (await current.exists()) await _quarantine(slot, current);
      await temporary.copy(current.path);
    }
  }

  Future<bool> _isValid(File file, SaveSlotAddress address) async {
    if (!await file.exists()) return false;
    try {
      await _decodeCandidate(file, address);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _quarantine(Directory slot, File file) async {
    if (!await file.exists()) return;
    final quarantine = Directory(p.join(slot.path, 'quarantine'));
    await quarantine.create(recursive: true);
    final name =
        '${p.basename(file.path)}.${DateTime.now().toUtc().microsecondsSinceEpoch}'
        '.corrupt';
    await file.rename(p.join(quarantine.path, name));
  }

  Future<T> _withFileLock<T>(
    Directory slot,
    Future<T> Function() action,
  ) async {
    final lockFile = File(p.join(slot.path, '.save.lock'));
    await _rejectLink(lockFile.path);
    final handle = await lockFile.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
      return await action();
    } finally {
      await handle.unlock();
      await handle.close();
    }
  }

  Future<T> _queueSlot<T>(
    String key,
    Future<T> Function() action,
  ) async {
    final previous = _slotQueues[key] ?? Future<void>.value();
    final completer = Completer<void>();
    _slotQueues[key] = completer.future;
    try {
      await previous.catchError((_) {});
      return await action();
    } finally {
      completer.complete();
      if (identical(_slotQueues[key], completer.future)) {
        _slotQueues.remove(key);
      }
    }
  }

  Future<void> _fault(SaveWriteStage stage) async {
    final hook = faultHook;
    if (hook != null) await hook(stage);
  }

  void _assertAddressScope(SaveSlotAddress address) {
    if (address.gameId != identity.gameId) {
      throw SaveStorageException(
        SaveStorageErrorCode.outOfScope,
        'Address ${address.gameId} is outside ${identity.gameId}.',
      );
    }
  }

  Future<Directory?> _safeSlotDirectory(
    SaveSlotAddress address, {
    required bool create,
  }) async {
    final profile = await _safeProfileDirectory(
      address.profileId,
      create: create,
    );
    if (profile == null) return null;
    return _safeChildDirectory(profile, address.slotId, create: create);
  }

  Future<Directory?> _safeProfileDirectory(
    String profileId, {
    required bool create,
  }) async {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    final game = await _safeGameDirectory(create: create);
    if (game == null) return null;
    return _safeChildDirectory(game, profileId, create: create);
  }

  Future<Directory?> _safeGameDirectory({required bool create}) async {
    GameIdentity.validateGameId(identity.gameId);
    final root = await _safeSupportRoot(create: create);
    if (root == null) return null;
    final saves = await _safeChildDirectory(root, 'saves', create: create);
    if (saves == null) return null;
    return _safeChildDirectory(saves, identity.gameId, create: create);
  }

  Future<Directory?> _safeSupportRoot({required bool create}) async {
    if (!await supportRoot.exists()) {
      if (!create) return null;
      await supportRoot.create(recursive: true);
    }
    if (await FileSystemEntity.isLink(supportRoot.path)) {
      throw const SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Support root must not be a symbolic link.',
      );
    }
    return supportRoot;
  }

  Future<Directory?> _safeChildDirectory(
    Directory parent,
    String name, {
    required bool create,
  }) async {
    final child = Directory(p.join(parent.path, name));
    final type = await FileSystemEntity.type(child.path, followLinks: false);
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Unsafe save path component "$name".',
      );
    }
    if (type == FileSystemEntityType.notFound) {
      if (!create) return null;
      await child.create();
    }
    final rootResolved = await supportRoot.resolveSymbolicLinks();
    final childResolved = await child.resolveSymbolicLinks();
    if (childResolved != rootResolved &&
        !p.isWithin(rootResolved, childResolved)) {
      throw SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Resolved save path escapes the PokeMap support root.',
      );
    }
    return child;
  }

  Future<void> _rejectLink(String path) async {
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Save file path is a symbolic link: $path',
      );
    }
  }
}

SaveStorageDiagnostic _compatibilityDiagnostic(
  SaveCompatibilityCode code,
) =>
    switch (code) {
      SaveCompatibilityCode.saveGameMismatch => const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveGameMismatch,
          'Save belongs to another game.',
        ),
      SaveCompatibilityCode.saveCompatibilityMismatch =>
        const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveCompatibilityMismatch,
          'Save compatibility identifier does not match this game.',
        ),
      SaveCompatibilityCode.saveFormatFuture => const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveFormatFuture,
          'Save was written by a future unsupported format.',
        ),
      SaveCompatibilityCode.saveMigrationRequired =>
        const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationRequired,
          'Save requires migration.',
        ),
      SaveCompatibilityCode.saveMigrationUnavailable =>
        const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationUnavailable,
          'No migration chain is available for this save.',
        ),
      SaveCompatibilityCode.migrationFailed => const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationUnavailable,
          'Save migration failed.',
        ),
    };
