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
