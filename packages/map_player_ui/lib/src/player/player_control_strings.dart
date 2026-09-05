import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_control_profile.dart';

final class PlayerControlStrings {
  const PlayerControlStrings._(this._isFrench);

  factory PlayerControlStrings.of(BuildContext context) =>
      PlayerControlStrings._(
        Localizations.localeOf(context).languageCode == 'fr',
      );

  final bool _isFrench;

  String get title => _isFrench ? 'Commandes' : 'Controls';
  String get conflict => _isFrench
      ? 'Cette entrée est déjà utilisée.'
      : 'This input is already assigned.';
  String get reset => _isFrench ? 'Réinitialiser' : 'Reset';
  String get swapTouch => _isFrench ? 'Inverser A / B' : 'Swap A / B';

  String device(PlayerControlDevice device) => switch (device) {
        PlayerControlDevice.keyboard => _isFrench ? 'Clavier' : 'Keyboard',
        PlayerControlDevice.gamepad => _isFrench ? 'Manette' : 'Gamepad',
        PlayerControlDevice.touch => _isFrench ? 'Tactile' : 'Touch',
      };

  String control(RuntimeInputControl control) => switch (control) {
        RuntimeInputControl.up => _isFrench ? 'Haut' : 'Up',
        RuntimeInputControl.down => _isFrench ? 'Bas' : 'Down',
        RuntimeInputControl.left => _isFrench ? 'Gauche' : 'Left',
        RuntimeInputControl.right => _isFrench ? 'Droite' : 'Right',
        RuntimeInputControl.sprint => _isFrench ? 'Course' : 'Sprint',
        RuntimeInputControl.primary =>
          _isFrench ? 'Action principale' : 'Primary action',
        RuntimeInputControl.secondary =>
          _isFrench ? 'Action secondaire' : 'Secondary action',
        RuntimeInputControl.menu => 'Menu',
      };
}
