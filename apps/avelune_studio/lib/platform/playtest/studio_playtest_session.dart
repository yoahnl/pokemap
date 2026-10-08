import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

class StudioPlaytestSession implements GameSaveRepository {
  GameState? _state;
  SaveEnvelope? _spatialSave;

  bool get hasSave => _state != null || _spatialSave != null;
  SaveEnvelope? get spatialSave => _spatialSave;

  SaveEnvelope spatialEnvelope({
    required GameIdentity identity,
    required GameSessionCheckpoint checkpoint,
    SaveStatus status = SaveStatus.active,
    DateTime? completedAt,
  }) => const GameStateSaveEnvelopeMapper().create(
    identity: identity,
    profileId: 'studio',
    slotId: 'test',
    saveId: checkpoint.saveId,
    createdAt: checkpoint.createdAt,
    updatedAt: checkpoint.updatedAt,
    status: status,
    completedAt: completedAt,
    playTimeSeconds: checkpoint.playTimeSeconds,
    gameState: gameStateFromStrictSaveJson(
      Map<String, dynamic>.from(checkpoint.state),
    ),
  );

  Future<void> saveSpatialCheckpoint({
    required GameIdentity identity,
    required GameSessionCheckpoint checkpoint,
    SaveStatus status = SaveStatus.active,
    DateTime? completedAt,
  }) async => _spatialSave = spatialEnvelope(
    identity: identity,
    checkpoint: checkpoint,
    status: status,
    completedAt: completedAt,
  );

  @override
  Future<void> save(GameState state) async =>
      _state = GameState.fromJson(state.toJson());

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => hasSave;

  @override
  Future<void> delete() async {
    _state = null;
    _spatialSave = null;
  }
}
