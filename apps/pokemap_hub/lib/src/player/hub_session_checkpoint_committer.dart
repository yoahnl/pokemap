import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../saves/hub_save_store.dart';

enum HubSessionCheckpointErrorCode {
  identityMismatch,
  invalidCompletion,
  writeFailed,
}

final class HubSessionCheckpointException implements Exception {
  const HubSessionCheckpointException(
    this.code,
    this.message, {
    this.cause,
  });

  final HubSessionCheckpointErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'HubSessionCheckpointException(${code.name}): $message';
}

/// Converts runtime proposals into checksummed, game-scoped envelopes.
///
/// This is the only Phase 4 bridge allowed to persist a session checkpoint.
/// The runtime receives only an acknowledgement and never a save path.
final class HubSessionCheckpointCommitter {
  const HubSessionCheckpointCommitter({
    required this.store,
    this.codec = const SaveEnvelopeCodec(),
  });

  final HubSaveStore store;
  final SaveEnvelopeCodec codec;

  Future<void> commit(GameSessionCheckpointCommit request) async {
    final descriptor = request.descriptor;
    if (descriptor.identity != store.identity) {
      throw const HubSessionCheckpointException(
        HubSessionCheckpointErrorCode.identityMismatch,
        'The checkpoint does not belong to this save store.',
      );
    }
    final isCompleted = request.status == SaveStatus.completed;
    if (isCompleted != (request.completedAt != null) ||
        (request.completedAt != null &&
            request.completedAt != request.checkpoint.updatedAt)) {
      throw const HubSessionCheckpointException(
        HubSessionCheckpointErrorCode.invalidCompletion,
        'Completion metadata does not match the final checkpoint.',
      );
    }
    final checkpoint = request.checkpoint;
    final envelope = codec.create(
      identity: descriptor.identity,
      profileId: descriptor.profileId,
      slotId: descriptor.slotId,
      saveId: checkpoint.saveId,
      createdAt: checkpoint.createdAt,
      updatedAt: checkpoint.updatedAt,
      status: request.status,
      completedAt: request.completedAt,
      playTimeSeconds: checkpoint.playTimeSeconds,
      state: checkpoint.state,
    );
    try {
      await store.write(envelope);
    } catch (error) {
      throw HubSessionCheckpointException(
        HubSessionCheckpointErrorCode.writeFailed,
        'The checkpoint could not be committed atomically.',
        cause: error,
      );
    }
  }
}
