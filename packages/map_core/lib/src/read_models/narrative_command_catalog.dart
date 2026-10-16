import '../models/narrative_command_descriptor.dart';
import '../models/scene_interactive_command.dart';
import '../models/scene_consequence.dart';

abstract final class NarrativeCommandIds {
  static const setFact = 'setFact';
  static const setMapEventInstanceBoolean = 'setMapEventInstanceBoolean';
  static const markEventConsumed = 'markEventConsumed';
  static const completeStoryStep = 'completeStoryStep';
  static const giveItem = 'giveItem';
  static const giveItemGift = 'giveItemGift';
  static const takeItem = 'takeItem';
  static const giveMoney = 'giveMoney';
  static const grantRailCurrency = 'grantRailCurrency';
  static const grantRailStamp = 'grantRailStamp';
  static const givePokemon = 'givePokemon';
  static const giveConfiguredStarter = 'giveConfiguredStarter';
  static const warp = 'warp';
  static const wait = 'wait';
  static const waitForActorRoutes = 'waitForActorRoutes';
  static const worldTone = 'worldTone';
  static const playSoundEffect = 'playSoundEffect';
  static const actorRoute = 'actorRoute';
  static const actorVisibility = 'actorVisibility';
  static const openShop = 'openShop';
  static const openHeal = 'openHeal';
  static const openPc = 'openPc';
  static const openRegionalMap = 'openRegionalMap';
  static const openPartyTrade = 'openPartyTrade';
  static const dialogue = 'dialogue';
  static const trainerBattle = 'trainerBattle';
  static const staticEncounter = 'staticEncounter';
  static const cinematic = 'cinematic';
  static const healParty = 'healParty';
  static const awardBadge = 'awardBadge';
  static const unlockFieldAbility = 'unlockFieldAbility';
  static const finishGame = 'finishGame';
  static const setNpcPresence = 'setNpcPresence';
  static const setPauseMenuEntryVisibility =
      'setPauseMenuEntryVisibility';
  static const moveNpc = 'moveNpc';
  static const movePlatform = 'movePlatform';
  static const playCharacterAnimation = 'playCharacterAnimation';
  static const playModelAnimation = 'playModelAnimation';
  static const railJourney = 'railJourney';

  static String forConsequence(SceneConsequence consequence) => consequence.kind.name;

  static String forInteractiveCommand(SceneInteractiveCommand command) =>
      command is SceneGiveItemInteractiveCommand ? giveItemGift : command.kind.name;
}

final class NarrativeCommandCatalog {
  NarrativeCommandCatalog._(this.commands);

  factory NarrativeCommandCatalog.canonical() {
    const supported = NarrativeCommandCapabilities.supported();
    NarrativeCommandDescriptor consequence(
      String id,
      String label,
      String lot,
      List<NarrativeCommandParameterDescriptor> parameters,
    ) =>
        NarrativeCommandDescriptor(
          id: id,
          label: label,
          description: 'Effet persistant atomique de Scene.',
          backend: NarrativeCommandBackend.sceneConsequence,
          capabilities: supported,
          fgLotId: lot,
          wireId: 'SceneConsequence.$id',
          parameters: parameters,
          isPersistent: true,
        );
    NarrativeCommandDescriptor interactive(
      String id,
      String label,
      String lot,
      List<NarrativeCommandParameterDescriptor> parameters, {
      String? wireId,
      bool isPersistent = false,
    }
    ) =>
        NarrativeCommandDescriptor(
          id: id,
          label: label,
          description: 'Interaction runtime attendue avec résultat explicite.',
          backend: NarrativeCommandBackend.interactiveRuntimeCommand,
          capabilities: supported,
          fgLotId: lot,
          wireId: wireId ?? 'SceneInteractiveCommand.$id',
          parameters: parameters,
          isAwaitable: true,
      isPersistent: isPersistent,
        );
    NarrativeCommandDescriptor node(
      String id,
      String label,
      String wire,
      String lot,
      NarrativeCommandParameterDescriptor parameter,
    ) =>
        NarrativeCommandDescriptor(
          id: id,
          label: label,
          description: 'Orchestration portée par un nœud Scene dédié.',
          backend: NarrativeCommandBackend.dedicatedSceneNode,
          capabilities: supported,
          fgLotId: lot,
          wireId: wire,
          parameters: [parameter],
          isAwaitable: true,
        );

    return NarrativeCommandCatalog._([
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.setMapEventInstanceBoolean,
        label: 'Définir un booléen de cette instance',
        description: 'État booléen capturé pour le propriétaire logique d’une instance de carte.',
        backend: NarrativeCommandBackend.sceneConsequence,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.unsupported,
          runtime: NarrativeCommandCapabilityStatus.unsupported,
          reason: 'Contrat d’instance logique ; formulaire guidé et exécution de programme complet non qualifiés, aucun support 3D annoncé.'),
        fgLotId: 'FG-081',
        wireId: 'SceneConsequence.setMapEventInstanceBoolean',
        parameters: [
          _parameter('mapId', 'Carte', NarrativeCommandParameterKind.map),
          _parameter('eventId', 'Propriétaire logique', NarrativeCommandParameterKind.mapEntityReference),
          _parameter('key', 'Clé locale', NarrativeCommandParameterKind.text),
          _parameter('value', 'Valeur', NarrativeCommandParameterKind.boolean),
        ],
        isPersistent: true,
      ),
      consequence(NarrativeCommandIds.setFact, 'Définir un Fact', 'FG-080', [
        _parameter('factId', 'Fact', NarrativeCommandParameterKind.fact),
        _parameter('value', 'Valeur', NarrativeCommandParameterKind.boolean),
      ]),
      consequence(
        NarrativeCommandIds.markEventConsumed,
        'Marquer un Event consommé',
        'FG-081',
        [
          _parameter('mapId', 'Map', NarrativeCommandParameterKind.map),
          _parameter('eventId', 'Event', NarrativeCommandParameterKind.event),
        ],
      ),
      consequence(
        NarrativeCommandIds.completeStoryStep,
        'Terminer une étape',
        'FG-082',
        [
          _parameter(
            'stepId',
            'Étape',
            NarrativeCommandParameterKind.storyStep,
          ),
        ],
      ),
      consequence(NarrativeCommandIds.giveItem, 'Donner un objet', 'FG-083', [
        _parameter('itemId', 'Objet', NarrativeCommandParameterKind.item),
        _parameter(
          'quantity',
          'Quantité',
          NarrativeCommandParameterKind.integer,
        ),
      ]),
      interactive(
        NarrativeCommandIds.giveItemGift,
        'Remettre un objet avec reprise',
        'FG-083',
        [
          _parameter('itemId', 'Objet', NarrativeCommandParameterKind.item),
          _parameter(
            'quantity',
            'Quantité',
            NarrativeCommandParameterKind.integer,
          ),
        ],
        wireId: 'SceneInteractiveCommand.giveItem',
      ),
      consequence(NarrativeCommandIds.takeItem, 'Retirer un objet', 'FG-083', [
        _parameter('itemId', 'Objet', NarrativeCommandParameterKind.item),
        _parameter(
          'quantity',
          'Quantité',
          NarrativeCommandParameterKind.integer,
        ),
      ]),
      consequence(
        NarrativeCommandIds.giveMoney,
        'Donner de l’argent',
        'FG-084',
        [
          _parameter(
            'amount',
            'Montant',
            NarrativeCommandParameterKind.integer,
          ),
        ],
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.grantRailCurrency,
        label: 'Donner des jetons ferroviaires',
        description: 'Crédite une monnaie ferroviaire sémantique.',
        backend: NarrativeCommandBackend.sceneConsequence,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.unsupported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'En attente du raccord authoring du lot ferroviaire.',
        ),
        fgLotId: 'FG-080',
        wireId: 'SceneConsequence.grantRailCurrency',
        parameters: [
          _parameter(
            'semanticCurrencyId',
            'Monnaie ferroviaire',
            NarrativeCommandParameterKind.text,
          ),
          _parameter(
            'amount',
            'Montant',
            NarrativeCommandParameterKind.integer,
          ),
        ],
        isPersistent: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.grantRailStamp,
        label: 'Donner un tampon ferroviaire',
        description: 'Attribue un tampon de progression ferroviaire.',
        backend: NarrativeCommandBackend.sceneConsequence,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.unsupported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'En attente du raccord authoring du lot ferroviaire.',
        ),
        fgLotId: 'FG-080',
        wireId: 'SceneConsequence.grantRailStamp',
        parameters: [
          _parameter(
            'stampId',
            'Tampon ferroviaire',
            NarrativeCommandParameterKind.text,
          ),
        ],
        isPersistent: true,
      ),
      consequence(
        NarrativeCommandIds.givePokemon,
        'Donner un Pokémon',
        'FG-085',
        [
          _parameter(
            'speciesId',
            'Espèce',
            NarrativeCommandParameterKind.species,
          ),
          _parameter(
            'formId',
            'Forme',
            NarrativeCommandParameterKind.speciesForm,
          ),
          _parameter('level', 'Niveau', NarrativeCommandParameterKind.integer),
        ],
      ),
      consequence(
        NarrativeCommandIds.giveConfiguredStarter,
        'Donner un starter configuré',
        'FG-085',
        [
          _parameter(
            'starterOptionId',
            'Starter',
            NarrativeCommandParameterKind.starter,
          ),
        ],
      ),
      consequence(
        NarrativeCommandIds.healParty,
        'Soigner l’équipe',
        'FG-085',
        const [],
      ),
      consequence(NarrativeCommandIds.awardBadge, 'Donner un badge', 'FG-089', [
        _parameter('badgeId', 'Badge', NarrativeCommandParameterKind.badge),
      ]),
      consequence(
        NarrativeCommandIds.unlockFieldAbility,
        'Débloquer une capacité terrain',
        'FG-089',
        [
          _parameter(
            'abilityId',
            'Capacité terrain',
            NarrativeCommandParameterKind.fieldAbility,
          ),
        ],
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.finishGame,
        label: 'Terminer le jeu',
        description:
            'Enregistre la fin, affiche le résultat et applique la politique postgame.',
        backend: NarrativeCommandBackend.sceneConsequence,
        capabilities: supported,
        fgLotId: 'FG-147',
        wireId: 'SceneConsequence.finishGame',
        parameters: [
          _parameter(
            'endingName',
            'Nom de cette fin',
            NarrativeCommandParameterKind.text,
          ),
          _parameter(
            'outcome',
            'Issue de la partie',
            NarrativeCommandParameterKind.completionOutcome,
          ),
          _parameter(
            'resultTitle',
            'Titre du résultat',
            NarrativeCommandParameterKind.text,
          ),
          _parameter(
            'resultTitleEn',
            'Titre du résultat (anglais)',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'resultSummary',
            'Résumé du résultat',
            NarrativeCommandParameterKind.text,
          ),
          _parameter(
            'resultSummaryEn',
            'Résumé du résultat (anglais)',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'includeCredits',
            'Afficher des crédits',
            NarrativeCommandParameterKind.boolean,
          ),
          _parameter(
            'creditsTitle',
            'Titre des crédits',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'creditsTitleEn',
            'Titre des crédits (anglais)',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'creditsAuthor',
            'Auteur',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'creditsEndingLabel',
            'Libellé de fin',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'creditsEndingLabelEn',
            'Libellé de fin (anglais)',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'creditsSkippable',
            'Crédits skippables',
            NarrativeCommandParameterKind.boolean,
            required: false,
          ),
          _parameter(
            'postGamePolicy',
            'Après la fin',
            NarrativeCommandParameterKind.postGamePolicy,
          ),
        ],
        isPersistent: true,
      ),
      consequence(
        NarrativeCommandIds.setNpcPresence,
        'Modifier la présence d’un PNJ',
        'FG-092',
        [
          _parameter('npcRef', 'PNJ', NarrativeCommandParameterKind.npc),
          _parameter(
            'present',
            'Présent sur la map',
            NarrativeCommandParameterKind.boolean,
          ),
        ],
      ),
      consequence(
        NarrativeCommandIds.setPauseMenuEntryVisibility,
        'Afficher ou masquer une entrée du menu pause',
        'FG-160',
        [
          _parameter(
            'actionId',
            'Entrée du menu',
            NarrativeCommandParameterKind.pauseMenuAction,
          ),
          _parameter(
            'visible',
            'Visibilité',
            NarrativeCommandParameterKind.boolean,
          ),
        ],
      ),
      interactive(NarrativeCommandIds.warp, 'Téléporter', 'FG-090', [
        _parameter(
          'destinationMapId',
          'Carte de destination',
          NarrativeCommandParameterKind.map,
        ),
        _parameter('warpId', 'Point d’arrivée', NarrativeCommandParameterKind.warp),
        _parameter(
          'arrivalFacing',
          'Direction à l’arrivée',
          NarrativeCommandParameterKind.characterDirection,
          required: false,
        ),
        _parameter(
          'transition',
          'Transition',
          NarrativeCommandParameterKind.warpTransition,
          required: false,
        ),
        _parameter('presentationMode', 'Présentation du passage',
          NarrativeCommandParameterKind.warpPresentationMode, required: false),
        _parameter('illustrationElementId', 'Illustration',
          NarrativeCommandParameterKind.visualElementReference, required: false),
        _parameter('fadeOutMs', 'Fondu noir (ms)', NarrativeCommandParameterKind.integer, required: false),
        _parameter('transferDelayMs', 'Préparation avant passage (ms)', NarrativeCommandParameterKind.integer, required: false),
        _parameter('revealMs', 'Révélation (ms)', NarrativeCommandParameterKind.integer, required: false),
        _parameter('illustrationHoldMs', 'Maintien illustration (ms)', NarrativeCommandParameterKind.integer, required: false),
        _parameter('illustrationFadeMs', 'Fondu illustration (ms)', NarrativeCommandParameterKind.integer, required: false),
      ]),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.waitForActorRoutes,
        label: 'Attendre les déplacements',
        description: 'Attend la fin des routes forcées actives sur la carte 2D choisie, sans durée arbitraire.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Disponible dans le Player 2D ; aucun support 3D.',
        ),
        fgLotId: 'FG-092',
        wireId: 'SceneInteractiveCommand.waitForActorRoutes',
        parameters: [_parameter('mapId', 'Carte', NarrativeCommandParameterKind.map)],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.wait,
        label: 'Attendre',
        description: 'Attend une durée dans un monde 2D sans déplacer ni désigner un acteur.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Disponible dans le Player 2D ; aucun support 3D.',
        ),
        fgLotId: 'FG-092',
        wireId: 'SceneInteractiveCommand.wait',
        parameters: [
          _parameter('durationMs', 'Durée (ms)', NarrativeCommandParameterKind.integer),
        ],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.worldTone,
        label: 'Changer le ton du monde',
        description:
            'Programme un effet transitoire et termine après sa programmation.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Disponible dans le Player 2D ; aucun support 3D.',
        ),
        fgLotId: 'FG-093',
        wireId: 'SceneInteractiveCommand.worldTone',
        parameters: [
          _parameter('red', 'Rouge', NarrativeCommandParameterKind.number),
          _parameter('green', 'Vert', NarrativeCommandParameterKind.number),
          _parameter('blue', 'Bleu', NarrativeCommandParameterKind.number),
          _parameter('gray', 'Gris', NarrativeCommandParameterKind.number),
          _parameter(
            'durationMs',
            'Durée (ms)',
            NarrativeCommandParameterKind.integer,
          ),
        ],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.playSoundEffect,
        label: 'Jouer un effet sonore',
        description:
            'Démarre un effet sonore transitoire et termine après son démarrage.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Disponible dans le Player 2D ; aucun support 3D.',
        ),
        fgLotId: 'FG-093',
        wireId: 'SceneInteractiveCommand.playSoundEffect',
        parameters: [
          _parameter(
            'mediaAssetId',
            'Effet sonore',
            NarrativeCommandParameterKind.soundMediaReference,
          ),
          _parameter('volume', 'Volume', NarrativeCommandParameterKind.number),
        ],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.actorRoute,
        label: 'Déplacer un acteur',
        description: 'Exécute une route finie et termine après ses étapes. L’option « Personnage à quitter » reste PARTIAL jusqu’à qualification des consommateurs et formulaires.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Formulaire guidé 2D dans Studio ; exécution dans le Player 2D ; aucun support 3D.',
        ),
        fgLotId: 'FG-092',
        wireId: 'SceneInteractiveCommand.actorRoute',
        parameters: [
          _parameter(
            'target',
            'Acteur',
            NarrativeCommandParameterKind.actorTarget,
          ),
          _parameter(
            'steps',
            'Étapes',
            NarrativeCommandParameterKind.actorRouteSteps,
          ),
          _parameter(
            'skippable',
            'Ignorer les déplacements bloqués',
            NarrativeCommandParameterKind.boolean,
            required: false,
          ),
        ],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.actorVisibility,
        label: 'Afficher ou masquer un acteur',
        description: 'Change la visibilité sans modifier les collisions.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Formulaire guidé 2D dans Studio ; exécution dans le Player 2D ; aucun support 3D.',
        ),
        fgLotId: 'FG-092',
        wireId: 'SceneInteractiveCommand.actorVisibility',
        parameters: [
          _parameter('mapId', 'Carte', NarrativeCommandParameterKind.map),
          _parameter(
            'targetKind',
            'Acteur',
            NarrativeCommandParameterKind.actorTargetKind,
          ),
          _parameter(
            'entityId',
            'Acteur de la carte',
            NarrativeCommandParameterKind.actorEntityReference,
            required: false,
          ),
          _parameter(
            'visible',
            'Visible',
            NarrativeCommandParameterKind.boolean,
          ),
        ],
        isAwaitable: true,
      ),
      interactive(
        NarrativeCommandIds.openShop,
        'Ouvrir une boutique',
        'FG-091',
        [_parameter('shopId', 'Boutique', NarrativeCommandParameterKind.shop)],
      ),
      interactive(
        NarrativeCommandIds.openHeal,
        'Ouvrir un service de soin',
        'FG-071',
        [
          _parameter(
            'requiresConfirmation',
            'Demander confirmation',
            NarrativeCommandParameterKind.boolean,
          ),
          _parameter(
            'displayEntityId',
            'Affichage des boules de soin',
            NarrativeCommandParameterKind.mapEntityReference,
            required: false,
          ),
        ],
      ),
      interactive(
        NarrativeCommandIds.openPc,
        'Ouvrir le PC',
        'FG-091',
        const [],
      ),
      interactive(
        NarrativeCommandIds.openRegionalMap,
        'Afficher la carte régionale',
        'FG-164',
        const [],
      ),
      interactive(
        NarrativeCommandIds.openPartyTrade,
        'Échanger deux Pokémon de l’équipe',
        'FG-055',
        const [],
        isPersistent: true,
      ),
      interactive(
        NarrativeCommandIds.movePlatform,
        'Déplacer une plateforme',
        'FG-120',
        [
          _parameter(
            'platformRef',
            'Plateforme',
            NarrativeCommandParameterKind.movingPlatform,
          ),
          _parameter(
            'motion',
            'Mouvement',
            NarrativeCommandParameterKind.movingPlatformMotion,
          ),
        ],
      ),
      interactive(NarrativeCommandIds.moveNpc, 'Déplacer un PNJ', 'FG-092', [
        _parameter('npcRef', 'PNJ', NarrativeCommandParameterKind.npc),
        _parameter('warpId', 'Destination', NarrativeCommandParameterKind.warp),
      ]),
      interactive(
        NarrativeCommandIds.playModelAnimation,
        'Jouer une animation de décor 3D',
        'FG-093',
        [
          _parameter('mapId', 'Carte', NarrativeCommandParameterKind.map),
          _parameter(
            'instanceId',
            'Décor placé',
            NarrativeCommandParameterKind.modelInstance,
          ),
          _parameter(
            'animationIndex',
            'Animation du décor',
            NarrativeCommandParameterKind.modelAnimation,
          ),
          _parameter(
            'speed',
            'Vitesse de lecture',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
          _parameter(
            'blocksMovementAfter',
            'Passage après l’animation',
            NarrativeCommandParameterKind.boolean,
            required: false,
          ),
        ],
      ),
      interactive(
        NarrativeCommandIds.playCharacterAnimation,
        'Jouer une animation de personnage',
        'CHS-046',
        [
          _parameter('actorId', 'Acteur', NarrativeCommandParameterKind.actor),
          _parameter(
            'definitionId',
            'Animation',
            NarrativeCommandParameterKind.customAnimationDefinition,
          ),
          _parameter(
            'direction',
            'Direction',
            NarrativeCommandParameterKind.characterDirection,
            required: false,
          ),
          _parameter(
            'playbackKind',
            'Lecture',
            NarrativeCommandParameterKind.customAnimationPlayback,
          ),
          _parameter(
            'repeatCount',
            'Répétitions',
            NarrativeCommandParameterKind.integer,
            required: false,
          ),
          _parameter(
            'durationMs',
            'Durée',
            NarrativeCommandParameterKind.integer,
            required: false,
          ),
        ],
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.railJourney,
        label: 'Piloter un voyage ferroviaire',
        description: 'Cycle ferroviaire persistant et transactionnel.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: supported,
        fgLotId: 'FG-080',
        wireId: 'SceneInteractiveCommand.railJourney',
        parameters: [
          _parameter(
            'commandId',
            'Commande',
            NarrativeCommandParameterKind.text,
          ),
          _parameter(
            'journeyId',
            'Voyage',
            NarrativeCommandParameterKind.railJourney,
          ),
          _parameter(
            'operation',
            'Opération',
            NarrativeCommandParameterKind.railJourneyOperation,
          ),
          _parameter(
            'direction',
            'Direction',
            NarrativeCommandParameterKind.railJourneyDirection,
            required: false,
          ),
          _parameter(
            'advanceEvent',
            'Étape',
            NarrativeCommandParameterKind.railJourneyAdvanceEvent,
            required: false,
          ),
          _parameter(
            'doorSide',
            'Côté de porte',
            NarrativeCommandParameterKind.railJourneyDoorSide,
            required: false,
          ),
        ],
        isPersistent: true,
        isAwaitable: true,
      ),
      node(
        NarrativeCommandIds.dialogue,
        'Jouer un dialogue',
        'SceneNode.yarnDialogue',
        'FG-089',
        _parameter(
          'dialogueId',
          'Dialogue',
          NarrativeCommandParameterKind.dialogue,
        ),
      ),
      node(
        NarrativeCommandIds.trainerBattle,
        'Lancer un combat de Dresseur',
        'SceneNode.battle.trainer',
        'FG-090',
        _parameter(
          'trainerId',
          'Dresseur',
          NarrativeCommandParameterKind.trainer,
        ),
      ),
      node(
        NarrativeCommandIds.staticEncounter,
        'Lancer une rencontre statique',
        'SceneNode.battle.static',
        'FG-090',
        _parameter(
          'staticEncounterId',
          'Rencontre statique',
          NarrativeCommandParameterKind.staticEncounter,
        ),
      ),
      node(
        NarrativeCommandIds.cinematic,
        'Jouer une cinématique',
        'SceneNode.cinematic',
        'FG-091',
        _parameter(
          'cinematicId',
          'Cinématique',
          NarrativeCommandParameterKind.cinematic,
        ),
      ),
    ]);
  }

  final List<NarrativeCommandDescriptor> commands;

  NarrativeCommandDescriptor? byId(String id) {
    for (final command in commands) {
      if (command.id == id) return command;
    }
    return null;
  }

  List<NarrativeCommandDescriptor> get publishable => commands
      .where((command) => command.isPublishable)
      .toList(growable: false);
}

NarrativeCommandParameterDescriptor _parameter(
  String id,
  String label,
  NarrativeCommandParameterKind kind, {
  bool required = true,
}) =>
    NarrativeCommandParameterDescriptor(
      id: id,
      label: label,
      kind: kind,
      required: required,
    );
