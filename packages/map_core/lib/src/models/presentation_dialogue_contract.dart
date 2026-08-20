/// Contrat canonique des dialogues qui pilotent Presentation — BETA-CIN-068.
///
/// Ce fichier FIGE le vocabulaire et les invariants du lot CIN-V2 avant toute
/// modification de schéma ou de runtime. Il ne contient aucune exécution :
/// les tickets BETA-CIN-069→086 implémentent chacun leur part et viennent
/// consommer CES types — pas en redéclarer d'autres.
///
/// ## Propriété (la frontière qui interdit un second moteur de scénario)
///
/// - **Presentation possède** : médias, calques, clips, repères et le temps.
/// - **Scene possède** : dialogues, choix, saisies, variables et branches.
/// - Un repère (`PresentationMarkerClip` de genre `interactionCue`) référence
///   un nœud Scene awaitable ; la référence (`awaitableNodeId`) est portée
///   par SCENE, jamais par le clip Presentation. Aucun nouveau track Dialogue
///   ou Prompt n'entre dans Presentation.
/// - Le contrat ne spécialise jamais Presentation avec l'identité joueur ni
///   la pré-session : aucun nom, avatar ou starter ne traverse cette
///   frontière — l'interpolation (BETA-CIN-071) vit côté Scene.
///
/// ## interactionHold n'est pas une pause
///
/// `interactionHold` gèle la narration : playhead, clips de timeline et
/// effets ponctuels s'arrêtent. Les pistes ambiantes explicitement
/// autorisées par la politique authorée (musique en boucle, vidéo de fond,
/// animations ambiantes) continuent. La pause utilisateur et le background
/// lifecycle sont des états DISTINCTS : eux suspendent tout.
///
/// ## Responsive
///
/// Composition native 16:9 et 9:16 ; variantes média facultatives avec
/// fallback vers l'unique version disponible ; la musique est UNIQUE et
/// partagée entre orientations — jamais de variante d'orientation audio.
library;

/// Issue terminale d'un cue d'interaction — l'union que BETA-CIN-070 scelle.
///
/// Un cue produit EXACTEMENT UN outcome (exact-once) ; tout callback tardif
/// est ignoré avec [PresentationDialogueContractViolation.staleCueCallback].
/// Les cibles de saut se résolvent par IDENTITÉ de repère, jamais par offset
/// brut authoré à la main.
enum PresentationInteractionOutcomeKind {
  /// Reprendre la timeline là où le cue l'a suspendue.
  continueTimeline('continue'),

  /// Sauter vers un repère cible, identifié par son id de marker.
  seekMarker('seekMarker'),

  /// Rejouer depuis un repère déjà franchi — la confirmation négative du
  /// parcours de référence. Consomme le budget anti-boucle.
  repeatFromMarker('repeatFromMarker'),

  /// Terminer la Presentation proprement et rendre la main au graphe Scene.
  stop('stop'),

  /// L'interaction a été annulée (skip, disposal, changement de projet).
  cancelled('cancelled'),

  /// L'interaction a échoué — fail-closed, diagnostic typé, aucun état
  /// partiel commis.
  failed('failed');

  const PresentationInteractionOutcomeKind(this.wireName);

  /// Nom canonique sérialisé — figé, les quatre transports le partagent.
  final String wireName;
}

/// Les états du player Presentation dialogué — le diagramme exigé par le
/// ticket : lecture, cue, hold, réponse, branche, reprise, stop, skip,
/// erreur, background et disposal.
enum PresentationDialoguePlaybackState {
  /// Lecture : la timeline avance, les cues à venir s'arment.
  playing,

  /// Un cue vient d'être franchi : la narration se fige, le nœud Scene
  /// awaitable référencé est résolu.
  cueSuspended,

  /// Le gel narratif pendant que Scene attend le joueur. Les pistes
  /// ambiantes autorisées continuent (BETA-CIN-077).
  interactionHold,

  /// La réponse du joueur est validée : l'outcome est produit et appliqué
  /// exactement une fois.
  responseApplying,

  /// L'outcome demande un déplacement de timeline (seekMarker,
  /// repeatFromMarker) : la cible se résout par identité de repère.
  branching,

  /// La timeline redémarre après un continue ou une branche résolue.
  resuming,

  /// Fin propre demandée par un outcome stop ou la fin naturelle de la
  /// timeline : handoff explicite vers la suite du graphe Scene.
  stopped,

  /// Le joueur a sauté la Presentation : aucune ancienne exécution ne
  /// reprend jamais.
  skipped,

  /// Erreur typée fail-closed : diagnostic stable, aucune mutation partielle.
  failedState,

  /// Background lifecycle : TOUT est suspendu, pistes ambiantes comprises —
  /// la différence structurelle avec [interactionHold].
  backgrounded,

  /// Ressources libérées. État terminal absolu : aucune transition n'en
  /// sort, aucun callback tardif n'y ressuscite quoi que ce soit.
  disposed,
}

/// Le diagramme d'état exécutable : les seules transitions légales.
///
/// Les tickets d'implémentation (BETA-CIN-072/073/077) doivent pouvoir
/// rejouer chacune de leurs transitions contre cette table ; une transition
/// absente d'ici est un bug de conception, pas un cas à rajouter en douce.
const Map<PresentationDialoguePlaybackState,
        Set<PresentationDialoguePlaybackState>>
    presentationDialogueLegalTransitions =
    <PresentationDialoguePlaybackState,
        Set<PresentationDialoguePlaybackState>>{
  PresentationDialoguePlaybackState.playing: {
    PresentationDialoguePlaybackState.cueSuspended,
    PresentationDialoguePlaybackState.stopped,
    PresentationDialoguePlaybackState.skipped,
    PresentationDialoguePlaybackState.failedState,
    PresentationDialoguePlaybackState.backgrounded,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.cueSuspended: {
    PresentationDialoguePlaybackState.interactionHold,
    PresentationDialoguePlaybackState.failedState,
    PresentationDialoguePlaybackState.skipped,
    PresentationDialoguePlaybackState.backgrounded,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.interactionHold: {
    PresentationDialoguePlaybackState.responseApplying,
    PresentationDialoguePlaybackState.failedState,
    PresentationDialoguePlaybackState.skipped,
    PresentationDialoguePlaybackState.backgrounded,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.responseApplying: {
    PresentationDialoguePlaybackState.resuming,
    PresentationDialoguePlaybackState.branching,
    PresentationDialoguePlaybackState.stopped,
    PresentationDialoguePlaybackState.failedState,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.branching: {
    PresentationDialoguePlaybackState.resuming,
    PresentationDialoguePlaybackState.failedState,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.resuming: {
    PresentationDialoguePlaybackState.playing,
    PresentationDialoguePlaybackState.failedState,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.stopped: {
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.skipped: {
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.failedState: {
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.backgrounded: {
    PresentationDialoguePlaybackState.playing,
    PresentationDialoguePlaybackState.cueSuspended,
    PresentationDialoguePlaybackState.interactionHold,
    PresentationDialoguePlaybackState.disposed,
  },
  PresentationDialoguePlaybackState.disposed:
      <PresentationDialoguePlaybackState>{},
};

/// L'état que chaque outcome impose immédiatement après [
/// PresentationDialoguePlaybackState.responseApplying] — la moitié métier du
/// diagramme : un saut passe TOUJOURS par la branche (c'est là que la cible
/// se résout par identité de repère et que la fenêtre de rejeu des effets
/// ponctuels se calcule), un continue reprend, un stop rend la main, une
/// annulation saute, un échec échoue.
const Map<PresentationInteractionOutcomeKind,
        PresentationDialoguePlaybackState>
    presentationOutcomeMandatoryNextState =
    <PresentationInteractionOutcomeKind, PresentationDialoguePlaybackState>{
  PresentationInteractionOutcomeKind.continueTimeline:
      PresentationDialoguePlaybackState.resuming,
  PresentationInteractionOutcomeKind.seekMarker:
      PresentationDialoguePlaybackState.branching,
  PresentationInteractionOutcomeKind.repeatFromMarker:
      PresentationDialoguePlaybackState.branching,
  PresentationInteractionOutcomeKind.stop:
      PresentationDialoguePlaybackState.stopped,
  PresentationInteractionOutcomeKind.cancelled:
      PresentationDialoguePlaybackState.skipped,
  PresentationInteractionOutcomeKind.failed:
      PresentationDialoguePlaybackState.failedState,
};

/// Les violations typées, toutes fail-closed : diagnostic stable, aucune
/// mutation partielle du draft ni de la timeline.
enum PresentationDialogueContractViolation {
  /// Le cue référence un repère qui n'existe pas dans l'asset.
  unknownMarkerReference,

  /// L'`awaitableNodeId` vise un nœud Scene qui n'est pas awaitable
  /// (ni Yarn/Dialogue, ni interaction structurée).
  nonAwaitableSceneNode,

  /// La chaîne de références forme un cycle à l'authoring.
  cyclicReference,

  /// L'outcome désigne un port ou un repère inconnu.
  unknownOutcomePort,

  /// Le budget de transitions anti-boucle est épuisé : la lecture s'arrête
  /// avec ce diagnostic plutôt que de boucler indéfiniment.
  transitionBudgetExhausted,

  /// Un callback d'un cue déjà résolu, sauté ou disposé arrive en retard :
  /// il est ignoré et tracé, jamais appliqué.
  staleCueCallback,

  /// Un deuxième outcome pour le même cue : l'exact-once refuse.
  duplicateOutcome,
}

/// Politique de gel d'une piste pendant [interactionHold] — authorée,
/// jamais devinée (BETA-CIN-077).
enum PresentationHoldTrackPolicy {
  /// La piste gèle avec la narration — le défaut de toute piste.
  frozen,

  /// La piste ambiante continue pendant le hold. Réservé aux boucles
  /// explicitement autorisées ; un effet ponctuel ne boucle JAMAIS par
  /// défaut et ne peut donc pas continuer.
  ambientContinues,
}

/// Attribution d'un invariant du contrat à son package propriétaire : le
/// test qui le protège vit LÀ, et nulle part ailleurs.
final class PresentationDialogueInvariantOwner {
  const PresentationDialogueInvariantOwner({
    required this.invariant,
    required this.ownerPackage,
    required this.deliveredBy,
  });

  final String invariant;
  final String ownerPackage;

  /// Le ticket du lot qui livre le test propriétaire.
  final String deliveredBy;
}

/// La carte des invariants : qui prouve quoi, décidé ici une fois.
const List<PresentationDialogueInvariantOwner>
    presentationDialogueInvariantOwners = <PresentationDialogueInvariantOwner>[
  PresentationDialogueInvariantOwner(
    invariant: 'Le diagramme d’état et les outcomes sont exhaustifs et purs',
    ownerPackage: 'packages/map_core',
    deliveredBy: 'BETA-CIN-068',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'La référence cue→nœud awaitable est validée fail-closed '
        '(absente, incompatible, cyclique) et portée par Scene',
    ownerPackage: 'packages/map_core',
    deliveredBy: 'BETA-CIN-069',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'Un cue produit exactement un outcome ; les callbacks tardifs '
        'sont ignorés ; les corrélations d’exécution sont préservées',
    ownerPackage: 'packages/map_runtime',
    deliveredBy: 'BETA-CIN-070',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'L’interpolation est déterministe, snapshotée par révision, '
        'et aucune valeur saisie ne fuit vers la config projet ni les logs',
    ownerPackage: 'packages/map_core',
    deliveredBy: 'BETA-CIN-071',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'Le runner Scene existant exécute le nœud awaitable — aucun '
        'interpréteur parallèle, aucune réentrance non bornée',
    ownerPackage: 'packages/map_runtime',
    deliveredBy: 'BETA-CIN-072',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'seek/repeat ne rejoue jamais un effet ponctuel déjà consommé '
        'hors de la fenêtre rejouée ; le budget anti-boucle arrête proprement',
    ownerPackage: 'packages/map_runtime',
    deliveredBy: 'BETA-CIN-073',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'PresentationFrame.audio est consommé sous l’autorité unique '
        'du mixer runtime ; zéro handle actif après sortie',
    ownerPackage: 'packages/map_runtime',
    deliveredBy: 'BETA-CIN-076',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'interactionHold gèle la narration, les pistes ambiantes '
        'autorisées continuent, la pause et le background suspendent tout',
    ownerPackage: 'packages/map_runtime',
    deliveredBy: 'BETA-CIN-077',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'La boîte de dialogue riche pagine au-dessus du frame '
        'Presentation, captions et accessibilité comprises',
    ownerPackage: 'packages/map_player_ui',
    deliveredBy: 'BETA-CIN-074',
  ),
  PresentationDialogueInvariantOwner(
    invariant: 'La liaison repère→dialogue s’authore sans code et se valide '
        'fail-closed à l’export',
    ownerPackage: 'packages/map_editor',
    deliveredBy: 'BETA-CIN-079',
  ),
];

/// Une étape de la fixture contractuelle : l'état atteint et, si l'étape
/// résout un cue, l'outcome qui l'a produite.
final class PresentationDialogueFixtureStep {
  const PresentationDialogueFixtureStep(
    this.state, {
    this.outcome,
    this.note = '',
  });

  final PresentationDialoguePlaybackState state;
  final PresentationInteractionOutcomeKind? outcome;
  final String note;
}

/// La fixture contractuelle du parcours de référence « Noir/Blanc » :
/// pages de dialogue, choix d'avatar, confirmation négative (Non → retour à
/// la saisie → Oui → suite), saisie du nom, interpolation, montage autonome
/// puis handoff monde. Chaque implémentation du lot doit pouvoir dérouler
/// SES transitions contre cette séquence — elle est la preuve d'état que le
/// diagramme couvre le parcours réel, y compris le retour en arrière.
const List<PresentationDialogueFixtureStep>
    presentationDialogueReferenceFixture = <PresentationDialogueFixtureStep>[
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
    note: 'ouverture : la timeline joue, pages de dialogue à venir',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.cueSuspended,
    note: 'cue « pages » : le repère référence le nœud Yarn paginé',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.interactionHold,
    note: 'le joueur lit ; les boucles ambiantes continuent',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.responseApplying,
    outcome: PresentationInteractionOutcomeKind.continueTimeline,
    note: 'pages terminées',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.resuming,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.cueSuspended,
    note: 'cue « avatar » : interaction structurée choice',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.interactionHold,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.responseApplying,
    outcome: PresentationInteractionOutcomeKind.continueTimeline,
    note: 'avatar choisi, résultat lié au brouillon côté Scene',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.resuming,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.cueSuspended,
    note: 'cue « nom » : interaction structurée text',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.interactionHold,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.responseApplying,
    outcome: PresentationInteractionOutcomeKind.continueTimeline,
    note: 'nom saisi',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.resuming,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.cueSuspended,
    note: 'cue « confirmation » : le nom interpolé est relu au joueur',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.interactionHold,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.responseApplying,
    outcome: PresentationInteractionOutcomeKind.repeatFromMarker,
    note: 'confirmation NÉGATIVE : rejouer depuis le repère de la saisie',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.branching,
    note: 'cible résolue par identité de repère, budget anti-boucle décompté',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.resuming,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.cueSuspended,
    note: 'cue « nom », second passage',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.interactionHold,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.responseApplying,
    outcome: PresentationInteractionOutcomeKind.continueTimeline,
    note: 'nouveau nom saisi',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.resuming,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.cueSuspended,
    note: 'cue « confirmation », second passage',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.interactionHold,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.responseApplying,
    outcome: PresentationInteractionOutcomeKind.continueTimeline,
    note: 'confirmation POSITIVE',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.resuming,
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.playing,
    note: 'montage autonome : plus aucun cue, la timeline déroule seule',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.stopped,
    note: 'fin naturelle : handoff explicite vers le graphe Scene, puis '
        'le monde',
  ),
  PresentationDialogueFixtureStep(
    PresentationDialoguePlaybackState.disposed,
  ),
];
