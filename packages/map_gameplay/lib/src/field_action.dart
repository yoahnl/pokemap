import 'package:map_core/map_core.dart';

/// Contrat commun des actions terrain : évaluer, confirmer, muter.
///
/// BETA-SYS-002. Surf existait sous forme dédiée et fonctionnait, mais chaque
/// étape de son parcours était un cas particulier du runtime. Ce fichier en
/// extrait le contrat, avec une exigence qui n'était pas tenue : une commande
/// périmée doit être refusable PAR CONSTRUCTION, pas par vigilance.
///
/// La logique reste pure — ni Flame, ni Flutter, ni Yarn. Le runtime la mappe
/// vers du dialogue, de l'animation et de la mutation ; l'authoring appelle
/// exactement les mêmes fonctions pour sa preview, ce qui rend la parité
/// structurelle au lieu d'être une coïncidence à tester.

/// Capacités terrain signées pour la bêta.
///
/// FG-121 à FG-128 sont explicitement DEFERRED. Le contrat les accepte en
/// entrée et rend [FieldActionUnsupported] : mieux vaut un verdict nommé qu'une
/// capacité silencieusement inerte, qui passerait pour implémentée.
const Set<FieldAbility> betaSignedFieldAbilities = <FieldAbility>{
  FieldAbility.surf,
};

/// Verdict d'une tentative d'action terrain.
///
/// Chaque cas est une décision métier distincte que le runtime mappe vers une
/// action UX (dialogue, notification, changement de mode).
sealed class FieldActionEvaluation {
  const FieldActionEvaluation();
}

/// La capacité n'est pas signée pour la bêta.
class FieldActionUnsupported extends FieldActionEvaluation {
  const FieldActionUnsupported(this.ability);

  final FieldAbility ability;
}

/// La cellule cible n'est pas de l'eau — ce n'est pas un cas Surf.
class NotWater extends FieldActionEvaluation {
  const NotWater();
}

/// Le joueur est déjà en mode surf — pas de re-déclenchement.
class AlreadySurfing extends FieldActionEvaluation {
  const AlreadySurfing();
}

/// Aucun Pokémon de l'équipe ne connaît Surf ou n'est en état de l'utiliser.
class MissingSurfCapablePokemon extends FieldActionEvaluation {
  const MissingSurfCapablePokemon();
}

/// Un Pokémon connaît Surf, mais la capacité n'est pas débloquée
/// côté progression (badge, scénario, etc.).
class SurfNotUnlocked extends FieldActionEvaluation {
  const SurfNotUnlocked();
}

/// Toutes les conditions sont réunies — proposer l'action au joueur.
class CanPromptSurf extends FieldActionEvaluation {
  const CanPromptSurf();
}

/// Évalue une tentative d'action terrain sur une cellule cible.
///
/// C'est l'étape « évaluation » du contrat, et le SEUL endroit où le verdict se
/// décide. Le runtime et la preview d'authoring passent tous les deux par ici.
FieldActionEvaluation evaluateFieldAction({
  required FieldAbility ability,
  required GameState gameState,
  required bool isTargetWater,
}) {
  if (!betaSignedFieldAbilities.contains(ability)) {
    return FieldActionUnsupported(ability);
  }
  if (!isTargetWater) {
    return const NotWater();
  }
  if (gameState.playerMovementMode == fieldActionMovementMode(ability)) {
    return const AlreadySurfing();
  }
  if (!partyHasUsableFieldMove(gameState.party, ability)) {
    return const MissingSurfCapablePokemon();
  }
  if (!gameState.progression.unlockedFieldAbilities.contains(ability)) {
    return const SurfNotUnlocked();
  }
  return const CanPromptSurf();
}

/// Mode de mouvement que l'action installe quand elle est appliquée.
MovementMode fieldActionMovementMode(FieldAbility ability) {
  return switch (ability) {
    FieldAbility.surf => MovementMode.surf,
    // Les capacités DEFERRED n'installent aucun mode : elles ne peuvent pas
    // être appliquées, `evaluateFieldAction` les refuse en amont.
    FieldAbility.cut ||
    FieldAbility.strength ||
    FieldAbility.flash ||
    FieldAbility.rockSmash ||
    FieldAbility.waterfall ||
    FieldAbility.dive =>
      MovementMode.walk,
  };
}

/// Vérifie si au moins un Pokémon de l'équipe connaît [ability]
/// et est en état de l'utiliser (non K.O.).
bool partyHasUsableFieldMove(PlayerParty party, FieldAbility ability) {
  return party.members.any((pokemon) =>
      !pokemon.isFainted && pokemon.knownMoveIds.contains(ability.moveId));
}

/// Autorisation délivrée quand le joueur est invité à confirmer une action.
///
/// Elle porte la révision d'état au moment de l'invitation. Sans ce jeton, la
/// confirmation ne pouvait rien vérifier : le runtime n'avait qu'un booléen
/// « une confirmation Surf est en attente », donc tout ce qui se passait entre
/// l'invitation et le « oui » du joueur — un Pokémon empoisonné qui tombe K.O.,
/// un déplacement, un chargement de sauvegarde — était invisible au commit.
class FieldActionTicket {
  const FieldActionTicket({
    required this.ability,
    required this.targetCell,
    required this.issuedAtStateRevision,
  });

  final FieldAbility ability;
  final GridPos targetCell;
  final int issuedAtStateRevision;
}

/// Pourquoi une confirmation a été refusée.
enum FieldActionRefusal {
  /// L'état du jeu a changé depuis l'invitation.
  staleStateRevision,

  /// La cible confirmée n'est pas celle qui a été proposée.
  targetChanged,

  /// L'état a changé de telle sorte que l'action n'est plus proposable.
  noLongerAvailable,
}

/// Décision de l'étape « mutation » du contrat.
sealed class FieldActionCommit {
  const FieldActionCommit();
}

/// L'action s'applique et installe [movementMode].
class FieldActionApplied extends FieldActionCommit {
  const FieldActionApplied(this.movementMode);

  final MovementMode movementMode;
}

/// L'action est refusée, sans mutation.
class FieldActionRefused extends FieldActionCommit {
  const FieldActionRefused(this.refusal, {this.evaluation});

  final FieldActionRefusal refusal;

  /// Verdict recalculé, quand le refus vient de l'état et non du jeton.
  final FieldActionEvaluation? evaluation;
}

/// Décide si une confirmation peut muter l'état.
///
/// Trois barrières, dans cet ordre, et la troisième est celle qui compte le
/// plus : le verdict est RECALCULÉ sur l'état courant. Une équipe dont le seul
/// nageur est tombé K.O. entre l'invitation et le « oui » ne peut donc pas
/// surfer, même si la révision n'avait pas bougé — c'est la même barrière qui
/// couvre la commande périmée et le Pokémon K.O., au lieu de deux vigilances
/// distinctes à ne pas oublier.
FieldActionCommit commitFieldAction({
  required FieldActionTicket ticket,
  required GameState gameState,
  required int currentStateRevision,
  required GridPos confirmedTargetCell,
  required bool isTargetWater,
}) {
  if (ticket.issuedAtStateRevision != currentStateRevision) {
    return const FieldActionRefused(FieldActionRefusal.staleStateRevision);
  }
  if (ticket.targetCell != confirmedTargetCell) {
    return const FieldActionRefused(FieldActionRefusal.targetChanged);
  }
  final evaluation = evaluateFieldAction(
    ability: ticket.ability,
    gameState: gameState,
    isTargetWater: isTargetWater,
  );
  if (evaluation is! CanPromptSurf) {
    return FieldActionRefused(
      FieldActionRefusal.noLongerAvailable,
      evaluation: evaluation,
    );
  }
  return FieldActionApplied(fieldActionMovementMode(ticket.ability));
}

/// Mode de mouvement après un pas effectivement commis.
///
/// C'est la SORTIE de l'action, et elle n'existait pas : rien n'appelait le
/// retour à la marche en production, donc un joueur ayant surfé une fois
/// continuait de surfer sur la terre ferme pour le reste de la partie. La règle
/// de mouvement, elle, ne bloque que l'ENTRÉE dans l'eau sans Surf.
///
/// Le retour est automatique et sans invitation, comme dans la série
/// principale : on ne demande pas au joueur s'il veut poser le pied sur la
/// plage. L'entrée, elle, reste soumise à confirmation.
MovementMode resolveMovementModeAfterStep({
  required MovementMode currentMode,
  required bool isWaterCell,
}) {
  if (currentMode == MovementMode.surf && !isWaterCell) {
    return MovementMode.walk;
  }
  return currentMode;
}

/// Mode de mouvement qu'une PREVIEW d'authoring doit supposer.
///
/// Volontairement OPTIMISTE, et il faut le dire parce que ça se voit dans les
/// verdicts : une analyse de portée symbolique ne connaît que les capacités
/// débloquées, pas l'équipe. Elle ne peut donc pas appliquer la condition
/// « un Pokémon non K.O. connaît la capacité » que le runtime, lui, exige.
///
/// La preview répond donc « atteignable si la capacité est débloquée », ce qui
/// est plus permissif que le runtime. C'est le bon choix pour un validateur de
/// contenu — il ne doit pas déclarer une zone inatteignable à cause d'une équipe
/// de test — mais ça n'est PAS l'équivalence, et un test l'épingle comme
/// divergence assumée plutôt que de laisser croire à une parité totale.
MovementMode optimisticPreviewMovementMode({
  required Set<FieldAbility> unlockedFieldAbilities,
}) {
  return unlockedFieldAbilities.contains(FieldAbility.surf)
      ? MovementMode.surf
      : MovementMode.walk;
}
