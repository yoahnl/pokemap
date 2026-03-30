import 'package:map_core/map_core.dart';

/// Résultat de l'évaluation d'une tentative d'utilisation de Surf.
///
/// Chaque cas correspond à une décision métier distincte que le runtime
/// peut mapper vers une action (dialogue, notification, changement de mode).
sealed class SurfAttemptEvaluation {
  const SurfAttemptEvaluation();
}

/// La cellule cible n'est pas de l'eau — ce n'est pas un cas Surf.
class NotWater extends SurfAttemptEvaluation {
  const NotWater();
}

/// Le joueur est déjà en mode surf — pas de re-déclenchement.
class AlreadySurfing extends SurfAttemptEvaluation {
  const AlreadySurfing();
}

/// Aucun Pokémon de l'équipe ne connaît Surf ou n'est en état de l'utiliser.
class MissingSurfCapablePokemon extends SurfAttemptEvaluation {
  const MissingSurfCapablePokemon();
}

/// Un Pokémon connaît Surf, mais la capacité n'est pas débloquée
/// côté progression (badge, scénario, etc.).
class SurfNotUnlocked extends SurfAttemptEvaluation {
  const SurfNotUnlocked();
}

/// Toutes les conditions sont réunies — proposer Surf au joueur.
class CanPromptSurf extends SurfAttemptEvaluation {
  const CanPromptSurf();
}

/// Évalue si le joueur peut utiliser Surf sur une cellule cible.
///
/// Logique pure : ne dépend ni de Flame, ni de Flutter, ni de Yarn.
/// Le résultat est un [SurfAttemptEvaluation] que le runtime mappera
/// vers l'action UX appropriée.
SurfAttemptEvaluation evaluateSurfAttempt({
  required SaveData saveData,
  required bool isTargetWater,
  required MovementMode currentMovementMode,
}) {
  if (!isTargetWater) {
    return const NotWater();
  }
  if (currentMovementMode == MovementMode.surf) {
    return const AlreadySurfing();
  }
  if (!partyHasUsableFieldMove(saveData.party, 'surf')) {
    return const MissingSurfCapablePokemon();
  }
  if (!saveData.progression.unlockedFieldAbilities
      .contains(FieldAbility.surf)) {
    return const SurfNotUnlocked();
  }
  return const CanPromptSurf();
}

/// Vérifie si au moins un Pokémon de l'équipe connaît [moveId]
/// et est en état de l'utiliser (non K.O.).
bool partyHasUsableFieldMove(PlayerParty party, String moveId) {
  return party.members
      .any((pokemon) => !pokemon.isFainted && pokemon.knownMoveIds.contains(moveId));
}
