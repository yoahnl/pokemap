import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('save override takes precedence over the project default', () {
    final state = const PlayerPauseMenuState.empty().setActionVisibility(
      ProjectPauseActionId.pokedex,
      visible: false,
    );

    expect(
      state.isActionVisible(
        ProjectPauseActionId.pokedex,
        projectDefaultVisibility: true,
      ),
      isFalse,
    );
    expect(
      state.isActionVisible(
        ProjectPauseActionId.bag,
        projectDefaultVisibility: false,
      ),
      isFalse,
    );
  });

  test('Resume cannot be hidden or overridden', () {
    expect(
      const PlayerPauseMenuState.empty().isActionVisible(
        ProjectPauseActionId.resume,
        projectDefaultVisibility: false,
      ),
      isTrue,
    );
    expect(
      () => const PlayerPauseMenuState.empty().setActionVisibility(
        ProjectPauseActionId.resume,
        visible: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => PlayerPauseMenuState.fromJson(<String, dynamic>{
        'visibilityOverrides': <String, dynamic>{'resume': false},
      }),
      throwsArgumentError,
    );
  });

  test('SaveData round-trip preserves isolated per-save overrides', () {
    final first = SaveData(
      saveId: 'first',
      pauseMenuState: const PlayerPauseMenuState.empty().setActionVisibility(
        ProjectPauseActionId.pokedex,
        visible: false,
      ),
    );
    const second = SaveData(saveId: 'second');

    final restored = SaveData.fromJson(
      jsonDecode(jsonEncode(first.toJson())) as Map<String, dynamic>,
    );

    expect(restored.pauseMenuState, first.pauseMenuState);
    expect(second.pauseMenuState, const PlayerPauseMenuState.empty());
    expect(
      () => PlayerPauseMenuState.fromJson(<String, dynamic>{
        'visibilityOverrides': <String, dynamic>{'missing': true},
      }),
      throwsFormatException,
    );
  });
}
