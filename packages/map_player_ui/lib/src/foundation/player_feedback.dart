import 'dart:async';
import 'dart:collection';

import '../preferences/player_preferences.dart';

enum PlayerFeedbackSound {
  select,
  confirm,
  dialogue,
  notification,
  battleImpact,
  victory,
  error,
}

enum PlayerFeedbackHaptic { selection, lightImpact, success, error }

class PlayerFeedbackEvent {
  const PlayerFeedbackEvent({
    required this.id,
    this.sound,
    this.haptic,
  });

  final String id;
  final PlayerFeedbackSound? sound;
  final PlayerFeedbackHaptic? haptic;
}

abstract interface class PlayerFeedbackPort {
  Future<void> playSound(PlayerFeedbackSound sound, double volume);

  Future<void> performHaptic(PlayerFeedbackHaptic haptic);
}

/// Applique les préférences globales à des feedbacks déclaratifs et dédupliqués.
class PlayerFeedbackController {
  PlayerFeedbackController({
    required this.port,
    this.maxRememberedEvents = 64,
  }) : assert(maxRememberedEvents > 0);

  final PlayerFeedbackPort port;
  final int maxRememberedEvents;
  final Queue<String> _eventOrder = Queue<String>();
  final Set<String> _eventIds = <String>{};

  Future<void> handle(
    PlayerFeedbackEvent event,
    PlayerPreferences preferences,
  ) async {
    if (_eventIds.contains(event.id)) {
      return;
    }
    _eventIds.add(event.id);
    _eventOrder.addLast(event.id);
    while (_eventOrder.length > maxRememberedEvents) {
      _eventIds.remove(_eventOrder.removeFirst());
    }

    final operations = <Future<void>>[];
    final sound = event.sound;
    final effectsVolume =
        (preferences.masterVolume * preferences.effectsVolume).clamp(0.0, 1.0);
    if (sound != null && effectsVolume > 0) {
      operations.add(port.playSound(sound, effectsVolume));
    }
    final haptic = event.haptic;
    if (haptic != null && preferences.hapticsEnabled) {
      operations.add(port.performHaptic(haptic));
    }
    try {
      await Future.wait(operations);
    } catch (_) {
      // Un périphérique audio/haptique indisponible ne doit jamais interrompre
      // la session joueur.
    }
  }
}
