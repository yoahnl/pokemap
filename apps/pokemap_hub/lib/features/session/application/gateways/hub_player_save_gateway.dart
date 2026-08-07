import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';
import 'package:pokemap_hub/features/session/domain/entities/save_read_handle.dart';
import 'package:pokemap_hub/features/session/application/services/hub_session_checkpoint_committer.dart';
import 'package:pokemap_hub/features/saves/domain/repositories/save_repository_interface.dart';

/// Keeps runtime save operations behind the game-scoped Hub store.
final class HubPlayerSaveGateway implements PlayerSaveGateway {
  HubPlayerSaveGateway({
    required this.store,
    HubSessionCheckpointCommitter? checkpointCommitter,
  }) : _checkpointCommitter =
            checkpointCommitter ?? HubSessionCheckpointCommitter(store: store);

  final SaveRepositoryInterface store;
  final HubSessionCheckpointCommitter _checkpointCommitter;
  final Map<_CheckpointCommitKey, Future<void>> _pendingCommits =
      <_CheckpointCommitKey, Future<void>>{};

  @override
  GameIdentity get identity => store.identity;

  @override
  Future<PlayerSaveSummary?> readLatestSummary() async {
    final latest = await store.findContinue();
    return latest == null ? null : _summary(latest);
  }

  @override
  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address) async {
    final read = await store.read(address);
    return read.status == SaveSlotReadStatus.missing ? null : _summary(read);
  }

  @override
  Future<String?> openReadHandle(SaveSlotAddress address) async {
    final read = await store.read(address);
    final envelope = read.envelope;
    if (!_canContinue(read, envelope)) return null;
    return hubSaveReadHandle(envelope!);
  }

  @override
  Future<void> commit(GameSessionCheckpointCommit request) {
    final descriptor = request.descriptor;
    final key = (
      identity: descriptor.identity,
      address: SaveSlotAddress(
        gameId: descriptor.identity.gameId,
        profileId: descriptor.profileId,
        slotId: descriptor.slotId,
      ),
      checkpoint: request.checkpoint,
      status: request.status,
      completedAt: request.completedAt,
    );
    final active = _pendingCommits[key];
    if (active != null) return active;

    late final Future<void> tracked;
    tracked = _checkpointCommitter.commit(request).whenComplete(() {
      if (identical(_pendingCommits[key], tracked)) {
        _pendingCommits.remove(key);
      }
    });
    _pendingCommits[key] = tracked;
    return tracked;
  }

  PlayerSaveSummary _summary(SaveSlotRead read) {
    final envelope = read.envelope;
    final canContinue = _canContinue(read, envelope);
    return PlayerSaveSummary(
      address: read.address,
      updatedAt: envelope?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      playTimeSeconds: envelope?.playTimeSeconds ?? 0,
      status: envelope?.status ?? SaveStatus.active,
      canContinue: canContinue,
      safeUnavailableReason: canContinue
          ? null
          : envelope?.status == SaveStatus.completed
              ? 'This ending does not allow post-game continuation.'
              : _safeReason(read.status),
    );
  }
}

bool _canContinue(SaveSlotRead read, SaveEnvelope? envelope) {
  if (!read.canContinue || envelope == null) return false;
  if (envelope.status != SaveStatus.completed) return true;
  return gameStateAllowsPostGameContinue(envelope.state);
}

String _safeReason(SaveSlotReadStatus status) => switch (status) {
      SaveSlotReadStatus.migrationRequired =>
        'This save must be migrated before it can be loaded.',
      SaveSlotReadStatus.incompatible =>
        'This save is not compatible with the installed game version.',
      SaveSlotReadStatus.corrupt =>
        'This save is damaged and could not be recovered from its backup.',
      SaveSlotReadStatus.missing => 'No save exists in this slot.',
      SaveSlotReadStatus.valid ||
      SaveSlotReadStatus.recoveredFromBackup =>
        'This save is temporarily unavailable.',
    };

typedef _CheckpointCommitKey = ({
  GameIdentity identity,
  SaveSlotAddress address,
  GameSessionCheckpoint checkpoint,
  SaveStatus status,
  DateTime? completedAt,
});
