import 'package:flutter/foundation.dart';

/// Contrôles runtime réellement supportés aujourd'hui, indépendamment de la
/// source physique (clavier, manette, boutons tactiles).
///
/// Le but reste volontairement petit:
/// - directions digitales pour le déplacement/navigation;
/// - action primaire pour confirmer/interagir;
/// - action secondaire pour revenir/annuler quand le flow le supporte.
///
/// On n'ouvre pas ici un framework d'inputs générique avec axes analogiques,
/// macros ou mapping produit complet. Ce seam sert uniquement à arrêter de
/// lier le gameplay runtime aux `LogicalKeyboardKey`.
enum RuntimeInputControl {
  up,
  down,
  left,
  right,
  primary,
  secondary,
}

enum RuntimeInputEventPhase {
  press,
  release,
}

@immutable
final class RuntimeInputEvent {
  const RuntimeInputEvent._({
    required this.control,
    required this.phase,
    required this.isRepeat,
  });

  const RuntimeInputEvent.press(
    RuntimeInputControl control, {
    bool isRepeat = false,
  }) : this._(
          control: control,
          phase: RuntimeInputEventPhase.press,
          isRepeat: isRepeat,
        );

  const RuntimeInputEvent.release(RuntimeInputControl control)
      : this._(
          control: control,
          phase: RuntimeInputEventPhase.release,
          isRepeat: false,
        );

  final RuntimeInputControl control;
  final RuntimeInputEventPhase phase;
  final bool isRepeat;

  bool get isPress => phase == RuntimeInputEventPhase.press;
  bool get isRelease => phase == RuntimeInputEventPhase.release;

  @override
  bool operator ==(Object other) {
    return other is RuntimeInputEvent &&
        other.control == control &&
        other.phase == phase &&
        other.isRepeat == isRepeat;
  }

  @override
  int get hashCode => Object.hash(control, phase, isRepeat);

  @override
  String toString() {
    return 'RuntimeInputEvent(control: $control, phase: $phase, isRepeat: $isRepeat)';
  }
}
