import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../saves/hub_save_store.dart';
import '../saves/save_storage_diagnostic.dart';
import '../session/save_read_handle.dart';
import 'hub_session_checkpoint_committer.dart';

/// Keeps runtime save operations behind the game-scoped Hub store.
final class HubPlayerSaveGateway implements PlayerSaveGateway {
  HubPlayerSaveGateway({
    required this.store,
    HubSessionCheckpointCommitter? checkpointCommitter,
  }) : _checkpointCommitter =
            checkpointCommitter ?? HubSessionCheckpointCommitter(store: store);

  final HubSaveStore store;
  final HubSessionCheckpointCommitter _checkpointCommitter;

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
    if (!read.canContinue || envelope == null) return null;
    return hubSaveReadHandle(envelope);
  }

  @override
  Future<void> commit(GameSessionCheckpointCommit request) {
    return _checkpointCommitter.commit(request);
  }

  PlayerSaveSummary _summary(SaveSlotRead read) {
    final envelope = read.envelope;
    return PlayerSaveSummary(
      address: read.address,
      updatedAt: envelope?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      playTimeSeconds: envelope?.playTimeSeconds ?? 0,
      status: envelope?.status ?? SaveStatus.active,
      canContinue: read.canContinue && envelope != null,
      safeUnavailableReason: read.canContinue && envelope != null
          ? null
          : _safeReason(read.status),
    );
  }
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
