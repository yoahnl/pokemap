import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

class StudioPlaytestSession implements GameSaveRepository {
  GameState? _state;

  bool get hasSave => _state != null;

  @override
  Future<void> save(GameState state) async =>
      _state = GameState.fromJson(state.toJson());

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => hasSave;

  @override
  Future<void> delete() async => _state = null;
}
