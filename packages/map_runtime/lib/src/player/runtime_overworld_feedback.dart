part of 'runtime_player_feedback.dart';

enum RuntimeOverworldFeedback implements RuntimePlayerFeedback {
  fishingInterrupted('La pêche a été interrompue.'),
  fishingCasting('Lancer de la ligne…'),
  fishingWaiting('La ligne est dans l’eau… Retour pour annuler.'),
  fishingBite('Ça mord !'),
  fishingNoBite('Pas de touche…'),
  fishingEncounterUnavailable('Le combat de pêche n’est plus disponible.'),
  fishingCancelled('Pêche annulée.'),
  fieldActionChanged('Cette action n’est plus disponible.'),
  fieldCrossingUnavailable('La traversée n’est plus disponible.'),
  fieldFlashUsed('Votre Pokémon utilise Flash ! Cette zone est éclairée.'),
  fieldCutUsed('Votre Pokémon utilise Coupe !'),
  fieldStrengthActive(
    'Force est active sur cette carte. Avancez vers un rocher pour le pousser.',
  ),
  fieldRockSmashUsed('Votre Pokémon utilise Éclate-Roc !'),
  fieldDivePassageUnavailable('Le passage de Plongée n’est plus disponible.'),
  waterRequiresSurf(
    'On ne peut pas aller sur l’eau sans un Pokémon ayant Surf.',
  ),
  underwaterRequiresDive('Ce terrain sous-marin nécessite Plongée.'),
  diveRequiresUnderwater('La plongée est réservée au terrain sous-marin.'),
  incompatibleMovementTerrain(
    'Ce terrain comporte des modes de déplacement incompatibles.',
  ),
  surfMissingPokemon('Il semble possible de pouvoir surfer sur l\'eau.'),
  surfLocked(
    'Un Pokémon de votre équipe connaît Surf, mais vous n\'avez pas encore l\'autorisation de l\'utiliser.',
  ),
  surfConfirm('Voulez-vous surfer ?'),
  yes('Oui'),
  no('Non'),
  narrativePending('Résultat narratif en attente.'),
  narrativeUnavailable('Évènement impossible.'),
  narrativeResultUnavailable('Résultat narratif impossible.'),
  cannotEndGame('Fin de partie impossible.'),
  giftFailed('Don du Pokémon impossible.'),
  transitionFailed('Transition impossible.'),
  transitionPassageMissing('Transition impossible (warp introuvable)'),
  invalidMapConnection('Connection invalid'),
  mapConnectionBlocked('Connection blocked'),
  sceneUnavailable('Scene V1 impossible.'),
  sceneCannotContinue('La scène ne peut pas continuer.'),
  dialogueMissing('Le dialogue est introuvable.'),
  mapPassageUnavailable('Le passage est momentanément indisponible.'),
  teleportFailed('La téléportation a échoué.'),
  neighboringMapTransferFailed('Le passage vers la carte voisine a échoué.'),
  contactUnavailable('Contact indisponible.'),
  puzzleSceneRequired('Ce puzzle nécessite une scène active.'),
  fieldMoveCut('Coupe'),
  fieldMoveStrength('Force'),
  fieldMoveRockSmash('Éclate-Roc'),
  fieldMoveWaterfall('Cascade'),
  fieldMoveWhirlpool('Tourbillon'),
  fieldObstacleCutConfirm(
    'Cet arbre peut être coupé. Voulez-vous utiliser Coupe ?',
  ),
  fieldObstacleStrengthConfirm(
    'Ce rocher peut être poussé. Voulez-vous utiliser Force ?',
  ),
  fieldObstacleRockSmashConfirm(
    'Ce rocher peut être brisé. Voulez-vous utiliser Éclate-Roc ?',
  ),
  fieldObstacleCutMissing(
    'Cet arbre bloque le passage. Un Pokémon apte à utiliser Coupe est nécessaire.',
  ),
  fieldObstacleStrengthMissing(
    'Ce rocher bloque le passage. Un Pokémon apte à utiliser Force est nécessaire.',
  ),
  fieldObstacleRockSmashMissing(
    'Ce rocher bloque le passage. Un Pokémon apte à utiliser Éclate-Roc est nécessaire.',
  ),
  fieldObstacleMoveLocked(
    'Un Pokémon de votre équipe connaît {move}, mais vous n’avez pas encore l’autorisation de l’utiliser.',
  ),
  fieldObstacleStrengthReady(
    'Force est active. Avancez vers ce rocher pour le pousser.',
  ),
  fieldTraversalConfirm(
    'Voulez-vous utiliser {move} pour traverser ce passage ?',
  ),
  fieldTraversalMoveMissing(
    'Un Pokémon apte à utiliser {move} est nécessaire.',
  ),
  fieldTraversalMoveLocked(
    'Vous n’avez pas encore l’autorisation d’utiliser {move}.',
  ),
  fieldTraversalSurfRequired(
    'Vous devez utiliser Surf avant de traverser ce passage.',
  ),
  fieldTraversalWrongDirection(
    'Placez-vous dans le sens du passage pour le traverser.',
  ),
  fieldTraversalObstructed('Le passage ou sa sortie est occupé.'),
  fieldTraversalWaterRequired('Ce passage doit se trouver sur l’eau.'),
  fieldDiveConfirmDown(
    'Voulez-vous utiliser Plongée pour descendre sous l’eau ?',
  ),
  fieldDiveConfirmUp(
    'Voulez-vous utiliser Plongée pour remonter à la surface ?',
  ),
  fieldDiveDisabled('Plongée est désactivée dans ce projet.'),
  fieldDiveMoveMissing('Un Pokémon apte à utiliser Plongée est nécessaire.'),
  fieldDiveMoveLocked(
    'Vous n’avez pas encore l’autorisation d’utiliser Plongée.',
  ),
  fieldDiveSurfRequired('Utilisez Surf pour plonger depuis la surface.'),
  fieldDiveObstructed('L’arrivée ou le point de retour de Plongée est occupé.'),
  fieldDiveDestinationUnavailable(
    'Ce point de Plongée n’est pas relié à une arrivée disponible.',
  ),
  fieldFlashConfirm(
    'Cette zone est sombre. Voulez-vous utiliser Flash pour l’éclairer ?',
  ),
  fieldFlashMoveMissing(
    'Cette zone est sombre. Un Pokémon apte à utiliser Flash est nécessaire.',
  ),
  fieldFlashMoveLocked(
    'Un Pokémon connaît Flash, mais vous n’avez pas encore l’autorisation de l’utiliser.',
  ),
  headbuttMoveMissing('Un Pokémon apte à utiliser Coud’Boule est nécessaire.'),
  headbuttTreeConsumed('Cet arbre ne cache plus de Pokémon pour le moment.'),
  headbuttWrongPosition(
    'Placez-vous à pied devant cet arbre pour utiliser Coud’Boule.',
  ),
  headbuttMapUnsupported(
    'Les rencontres sur un objet sont disponibles sur les cartes 2D.',
  ),
  headbuttUnavailable('Cet arbre ne permet pas de rencontre pour le moment.'),
  headbuttConfirm('Voulez-vous utiliser Coud’Boule sur cet arbre ?'),
  interactiveEncounterEmpty('Aucun Pokémon ne se manifeste…'),
  interactiveEncounterUnavailable('Cette rencontre n’est plus disponible.'),
  repelExpired('L’effet de la Repousse s’est dissipé.'),
  repelRenew('Voulez-vous utiliser une autre Repousse identique ?'),
  repelRenewed('La Repousse est de nouveau active.'),
  repelStockUnavailable('Cette Repousse n’est plus disponible.'),
  repelProgressSaveFailed('La progression n’a pas pu être sauvegardée.'),
  spatialNeighborUnavailable('Impossible d’afficher une carte voisine.'),
  spatialInteractionUnavailable(
    'Impossible d’ouvrir ce passage ou ce dialogue.',
  ),
  movingPlatformUnavailable('La plate-forme ne peut pas être déplacée.'),
  entranceAnimationMissing('Cette entrée ne possède pas d’animation.'),
  entranceAnimationUnavailable('L’animation de cette entrée est indisponible.'),
  elementAnimationUpdateFailed('L’animation n’a pas pu être mise à jour.'),
  spatialSceneTextInputUnsupported(
    'La saisie de texte en scène n’est pas disponible en 3D.',
  ),
  spatialSceneRegionalMapUnsupported(
    'La carte régionale en scène n’est pas disponible en 3D.',
  ),
  sceneRewardCalendarUnavailable(
    'Le calendrier de cette récompense est indisponible. Rouvrez le jeu puis réessayez.',
  );

  const RuntimeOverworldFeedback(this.fallbackText);

  @override
  final String fallbackText;
}

typedef RuntimeOverworldFeedbackFormatter = String Function(
  RuntimeOverworldFeedback feedback, [
  Map<String, Object> arguments,
]);

String fallbackRuntimeOverworldFeedback(
  RuntimeOverworldFeedback feedback, [
  Map<String, Object> arguments = const {},
]) => feedback.resolve(null, 'fr', arguments);
