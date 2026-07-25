import '../models/game_state.dart';
import '../operations/game_state_persistence.dart';
import 'game_identity.dart';
import 'save_contract_exception.dart';
import 'save_envelope.dart';
import 'save_envelope_codec.dart';

/// Canonical bridge between runtime-owned [GameState] and save storage.
final class GameStateSaveEnvelopeMapper {
  const GameStateSaveEnvelopeMapper({
    this.codec = const SaveEnvelopeCodec(),
  });

  final SaveEnvelopeCodec codec;

  SaveEnvelope create({
    required GameIdentity identity,
    required String profileId,
    required String slotId,
    required String saveId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required SaveStatus status,
    required int playTimeSeconds,
    required GameState gameState,
    DateTime? completedAt,
    SaveOrigin? origin,
  }) {
    final scopedState = gameState.copyWith(saveId: saveId);
    return codec.create(
      identity: identity,
      profileId: profileId,
      slotId: slotId,
      saveId: saveId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      completedAt: completedAt,
      playTimeSeconds: playTimeSeconds,
      origin: origin,
      state: scopedState.toJson(),
    );
  }

  GameState restore(SaveEnvelope envelope) {
    if (envelope.state['saveId'] != envelope.saveId) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidIdentity,
        'GameState saveId must match its SaveEnvelope.',
        path: r'$.state.saveId',
      );
    }
    try {
      return normalizeLoadedGameState(
        GameState.fromJson(
          Map<String, dynamic>.from(envelope.state),
        ),
      );
    } catch (error) {
      if (error is SaveContractException) rethrow;
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        'SaveEnvelope state is not a valid GameState: $error',
        path: r'$.state',
      );
    }
  }
}
