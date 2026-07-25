import 'game_identity.dart';
import 'save_envelope.dart';

enum SaveCompatibilityDisposition { accept, migrate, reject }

enum SaveCompatibilityCode {
  saveGameMismatch,
  saveCompatibilityMismatch,
  saveFormatFuture,
  saveMigrationRequired,
  saveMigrationUnavailable,
  migrationFailed,
}

final class SaveCompatibilityDecision {
  const SaveCompatibilityDecision.accept()
      : disposition = SaveCompatibilityDisposition.accept,
        code = null;

  const SaveCompatibilityDecision.migrate(this.code)
      : disposition = SaveCompatibilityDisposition.migrate;

  const SaveCompatibilityDecision.reject(this.code)
      : disposition = SaveCompatibilityDisposition.reject;

  final SaveCompatibilityDisposition disposition;
  final SaveCompatibilityCode? code;

  bool get isAccepted => disposition == SaveCompatibilityDisposition.accept;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveCompatibilityDecision &&
          disposition == other.disposition &&
          code == other.code;

  @override
  int get hashCode => Object.hash(disposition, code);
}

final class SaveCompatibilityEvaluator {
  const SaveCompatibilityEvaluator();

  SaveCompatibilityDecision evaluate({
    required SaveCompatibilityDescriptor save,
    required GameIdentity game,
    bool migrationChainAvailable = false,
  }) {
    if (save.gameId != game.gameId) {
      return const SaveCompatibilityDecision.reject(
        SaveCompatibilityCode.saveGameMismatch,
      );
    }
    if (save.compatibilityId != game.compatibilityId) {
      return const SaveCompatibilityDecision.reject(
        SaveCompatibilityCode.saveCompatibilityMismatch,
      );
    }
    if (save.saveFormat > game.saveFormat) {
      return const SaveCompatibilityDecision.reject(
        SaveCompatibilityCode.saveFormatFuture,
      );
    }
    if (save.saveFormat < game.saveFormat) {
      return migrationChainAvailable
          ? const SaveCompatibilityDecision.migrate(
              SaveCompatibilityCode.saveMigrationRequired,
            )
          : const SaveCompatibilityDecision.reject(
              SaveCompatibilityCode.saveMigrationUnavailable,
            );
    }
    return const SaveCompatibilityDecision.accept();
  }
}
