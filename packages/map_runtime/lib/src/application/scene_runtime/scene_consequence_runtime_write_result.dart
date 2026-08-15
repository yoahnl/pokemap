import 'package:map_core/map_core.dart';

enum SceneConsequenceRuntimeWriteStatus {
  applied,
  failed,
}

enum SceneConsequenceRuntimeWriteErrorCode {
  unknownFact,
  ambiguousFact,
  invalidFactRuntimeKey,
  factTypeMismatch,
  unknownMap,
  unknownEvent,
  unknownStoryStep,
  ambiguousStoryStep,
  missingItemReference,
  invalidQuantity,
  insufficientItemQuantity,
  invalidMoneyAmount,
  missingPokemonSpeciesReference,
  missingPokemonFormReference,
  invalidPokemonLevel,
  invalidPokemonCurrentHp,
  invalidPokemonDefinition,
  missingPokemonGrantOperationId,
  missingStarterOptionReference,
  unknownStarterOption,
  ambiguousStarterOption,
  missingPartyRecoveryCaps,
  missingBadgeReference,
  unknownBadge,
  ambiguousBadge,
  partyFull,
  gameAlreadyCompleted,
  unknownNpc,
}

final class SceneConsequenceRuntimeWriteResult {
  SceneConsequenceRuntimeWriteResult._({
    required this.status,
    required this.gameState,
    required List<SceneConsequence> appliedConsequences,
    this.gameCompletion,
    this.errorCode,
    this.message,
    this.failedConsequence,
  }) : appliedConsequences =
            List<SceneConsequence>.unmodifiable(appliedConsequences);

  SceneConsequenceRuntimeWriteResult.applied({
    required GameState gameState,
    required List<SceneConsequence> appliedConsequences,
    SceneFinishGameConsequence? gameCompletion,
  }) : this._(
          status: SceneConsequenceRuntimeWriteStatus.applied,
          gameState: gameState,
          appliedConsequences: appliedConsequences,
          gameCompletion: gameCompletion,
        );

  SceneConsequenceRuntimeWriteResult.failed({
    required GameState gameState,
    required SceneConsequenceRuntimeWriteErrorCode errorCode,
    required String message,
    required SceneConsequence failedConsequence,
    required List<SceneConsequence> appliedConsequences,
  }) : this._(
          status: SceneConsequenceRuntimeWriteStatus.failed,
          gameState: gameState,
          errorCode: errorCode,
          message: message,
          failedConsequence: failedConsequence,
          appliedConsequences: appliedConsequences,
        );

  final SceneConsequenceRuntimeWriteStatus status;
  final GameState gameState;
  final List<SceneConsequence> appliedConsequences;
  final SceneFinishGameConsequence? gameCompletion;
  final SceneConsequenceRuntimeWriteErrorCode? errorCode;
  final String? message;
  final SceneConsequence? failedConsequence;

  bool get success => status == SceneConsequenceRuntimeWriteStatus.applied;
}
