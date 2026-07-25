import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SaveCompatibilityEvaluator Phase 0 matrix', () {
    final evaluator = SaveCompatibilityEvaluator();

    test('C-011 accepts matching identity and format', () {
      expect(
        evaluator.evaluate(
          save: _saveDescriptor(),
          game: _identity(),
        ),
        const SaveCompatibilityDecision.accept(),
      );
    });

    test('C-012 rejects a different game', () {
      expect(
        evaluator.evaluate(
          save: _saveDescriptor(gameId: 'games.example.other'),
          game: _identity(),
        ),
        const SaveCompatibilityDecision.reject(
          SaveCompatibilityCode.saveGameMismatch,
        ),
      );
    });

    test('C-013 rejects a different compatibility id', () {
      expect(
        evaluator.evaluate(
          save: _saveDescriptor(compatibilityId: 'campaign-v0'),
          game: _identity(),
        ),
        const SaveCompatibilityDecision.reject(
          SaveCompatibilityCode.saveCompatibilityMismatch,
        ),
      );
    });

    test('C-014 rejects a future save format', () {
      expect(
        evaluator.evaluate(
          save: _saveDescriptor(saveFormat: 2),
          game: _identity(),
        ),
        const SaveCompatibilityDecision.reject(
          SaveCompatibilityCode.saveFormatFuture,
        ),
      );
    });

    test('C-015 requests an available migration chain', () {
      expect(
        evaluator.evaluate(
          save: _saveDescriptor(saveFormat: 0),
          game: _identity(),
          migrationChainAvailable: true,
        ),
        const SaveCompatibilityDecision.migrate(
          SaveCompatibilityCode.saveMigrationRequired,
        ),
      );
    });

    test('C-016 rejects a missing migration chain', () {
      expect(
        evaluator.evaluate(
          save: _saveDescriptor(saveFormat: 0),
          game: _identity(),
          migrationChainAvailable: false,
        ),
        const SaveCompatibilityDecision.reject(
          SaveCompatibilityCode.saveMigrationUnavailable,
        ),
      );
    });
  });
}

GameIdentity _identity() => GameIdentity(
      gameId: 'games.example.complete',
      gameVersion: '1.2.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'campaign-v1',
    );

SaveCompatibilityDescriptor _saveDescriptor({
  String gameId = 'games.example.complete',
  int saveFormat = 1,
  String compatibilityId = 'campaign-v1',
}) =>
    SaveCompatibilityDescriptor(
      gameId: gameId,
      saveFormat: saveFormat,
      compatibilityId: compatibilityId,
    );
