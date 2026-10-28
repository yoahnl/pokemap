import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/installation/application/game_installation_message.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';

void main() {
  test('explains conflicting releases without blaming the Player version', () {
    final message = gameInstallationMessage(
      const GameInstallationDiagnostic(
        code: GameInstallationErrorCode.releaseConflict,
        stage: GameInstallStage.checkingCompatibility,
        gameVersion: '0.1.3',
        retryable: false,
        repairSuggested: false,
      ),
    );
    expect(message, contains('0.1.3'));
    expect(message, contains('contenu différent'));
    expect(message, contains('version plus récente du jeu'));
    expect(message, contains('sauvegardes sont conservés'));
    expect(message, isNot(contains('GameInstallationException')));
    expect(message, isNot(contains('checkingCompatibility')));
  });

  test('explains every failure instead of a generic fallback', () {
    for (final code in GameInstallationErrorCode.values) {
      final message = gameInstallationMessage(
        GameInstallationDiagnostic(
          code: code,
          stage: GameInstallStage.smokeLoading,
          retryable: true,
          repairSuggested: false,
        ),
      );
      expect(
        message,
        isNot('L’installation n’a pas pu être terminée.'),
        reason: code.name,
      );
    }
  });

  test('reassures that a failed install keeps the current game', () {
    for (final code in [
      GameInstallationErrorCode.extractionFailed,
      GameInstallationErrorCode.smokeFailed,
      GameInstallationErrorCode.savePreparationFailed,
    ]) {
      final message = gameInstallationMessage(
        GameInstallationDiagnostic(
          code: code,
          stage: GameInstallStage.smokeLoading,
          retryable: true,
          repairSuggested: false,
        ),
      );
      expect(message, contains('ton jeu actuel'), reason: code.name);
      expect(message, contains('sauvegardes'), reason: code.name);
    }
  });

  test('keeps installation failure messages free from internal details', () {
    for (final code in GameInstallationErrorCode.values) {
      final message = gameInstallationMessage(
        GameInstallationDiagnostic(
          code: code,
          stage: GameInstallStage.inspecting,
          retryable: false,
          repairSuggested: false,
        ),
      );
      expect(message, isNotEmpty);
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('null')));
    }
  });
}
