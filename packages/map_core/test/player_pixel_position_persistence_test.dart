import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('exact 2D sprite position survives both save projections', () {
    const position = PixelOffset(x: 98, y: 190);
    const state = GameState(
      saveId: 'pixel-save',
      playerPosition: GridPos(x: 3, y: 6),
      playerPixelPosition: position,
    );
    expect(
      gameStateFromStrictSaveJson(
        strictGameStateSaveJson(state),
      ).playerPixelPosition,
      position,
    );
    final restored = SaveData.fromJson(saveDataFromGameState(state).toJson());
    expect(gameStateFromSaveData(restored).playerPixelPosition, position);
  });
}
