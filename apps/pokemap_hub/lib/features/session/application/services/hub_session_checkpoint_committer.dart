import 'dart:isolate';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/saves/domain/repositories/save_repository_interface.dart';

/// Exécuteur du travail CPU pur du committer (canonicalisation + SHA-256).
typedef HubCheckpointWorkerRunner = Future<T> Function<T>(T Function() work);

Future<T> _runCheckpointWorker<T>(T Function() work) => Isolate.run(work);

enum HubSessionCheckpointErrorCode {
  identityMismatch,
  invalidCompletion,
  verificationFailed,
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
    HubCheckpointWorkerRunner workerRunner = _runCheckpointWorker,
  }) : _workerRunner = workerRunner;

  final SaveRepositoryInterface store;
  final SaveEnvelopeCodec codec;
  final HubCheckpointWorkerRunner _workerRunner;

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
    // La création d'enveloppe canonicalise et hache l'état complet : c'était
    // le principal hitch UI de chaque checkpoint. Le travail est pur (état
    // JSON + identité, tous copiables), donc il part en isolate.
    final envelope = await _createEnvelopeOffloaded(
      runner: _workerRunner,
      codec: codec,
      identity: descriptor.identity,
      profileId: descriptor.profileId,
      slotId: descriptor.slotId,
      checkpoint: request.checkpoint,
      status: request.status,
      completedAt: request.completedAt,
    );
    try {
      final confirmed = await store.writeVerified(envelope);
      _verifyConfirmed(confirmed, envelope);
    } on HubSessionCheckpointException {
      rethrow;
    } catch (error) {
      throw HubSessionCheckpointException(
        HubSessionCheckpointErrorCode.writeFailed,
        'The checkpoint could not be committed atomically.',
        cause: error,
      );
    }
  }

  /// Construit le closure d'offload dans une portée statique : un closure
  /// créé dans `commit` capturerait `this` (donc `store` et ses hooks non
  /// envoyables) lors du passage à l'isolate.
  static Future<SaveEnvelope> _createEnvelopeOffloaded({
    required HubCheckpointWorkerRunner runner,
    required SaveEnvelopeCodec codec,
    required GameIdentity identity,
    required String profileId,
    required String slotId,
    required GameSessionCheckpoint checkpoint,
    required SaveStatus status,
    required DateTime? completedAt,
  }) {
    return runner(
      () => codec.create(
        identity: identity,
        profileId: profileId,
        slotId: slotId,
        saveId: checkpoint.saveId,
        createdAt: checkpoint.createdAt,
        updatedAt: checkpoint.updatedAt,
        status: status,
        completedAt: completedAt,
        playTimeSeconds: checkpoint.playTimeSeconds,
        state: checkpoint.state,
      ),
    );
  }

  static void _verifyConfirmed(SaveEnvelope confirmed, SaveEnvelope envelope) {
    if (confirmed.address != envelope.address ||
        confirmed.checksum != envelope.checksum ||
        confirmed.status != envelope.status ||
        confirmed.completedAt != envelope.completedAt) {
      throw const HubSessionCheckpointException(
        HubSessionCheckpointErrorCode.verificationFailed,
        'The confirmed checkpoint does not match the proposed generation.',
      );
    }
  }
}
