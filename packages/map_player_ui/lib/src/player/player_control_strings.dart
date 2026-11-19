import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import 'player_control_profile.dart';

final class PlayerControlStrings {
  const PlayerControlStrings._(this._strings);

  factory PlayerControlStrings.of(BuildContext context) =>
      PlayerControlStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get title => _strings.optionsCategoryControls;
  String get conflict => _strings.controlsConflict;
  String get reset => _strings.controlsReset;
  String get swapTouch => _strings.controlsSwapTouch;

  String device(PlayerControlDevice device) => switch (device) {
    PlayerControlDevice.keyboard => _strings.controlsDeviceKeyboard,
    PlayerControlDevice.gamepad => _strings.controlsDeviceGamepad,
    PlayerControlDevice.touch => _strings.controlsDeviceTouch,
  };

  String control(RuntimeInputControl control) => switch (control) {
    RuntimeInputControl.up => _strings.controlsControlUp,
    RuntimeInputControl.down => _strings.controlsControlDown,
    RuntimeInputControl.left => _strings.controlsControlLeft,
    RuntimeInputControl.right => _strings.controlsControlRight,
    RuntimeInputControl.sprint => _strings.controlsControlSprint,
    RuntimeInputControl.primary => _strings.controlsControlPrimary,
    RuntimeInputControl.secondary => _strings.controlsControlSecondary,
    RuntimeInputControl.bicycle => _strings.controlsControlBicycle,
    RuntimeInputControl.menu => _strings.menu,
    RuntimeInputControl.previousTab => _strings.controlsControlPreviousTab,
    RuntimeInputControl.nextTab => _strings.controlsControlNextTab,
  };
}
