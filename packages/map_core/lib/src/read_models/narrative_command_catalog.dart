import '../models/narrative_command_descriptor.dart';
import '../models/scene_interactive_command.dart';
import '../models/scene_consequence.dart';

abstract final class NarrativeCommandIds {
  static const calculateIntegerFacts = 'calculateIntegerFacts';
  static const adjustMoney = 'adjustMoney';
  static const inputIntegerToFact = 'inputIntegerToFact';
  static const tryPayMoney = 'tryPayMoney';
  static const inputTextToFact = 'inputTextToFact';
  static const setFact = 'setFact';
  static const adjustIntegerFact = 'adjustIntegerFact';
  static const setMapEventInstanceBoolean = 'setMapEventInstanceBoolean';
  static const markEventConsumed = 'markEventConsumed';
  static const completeStoryStep = 'completeStoryStep';
  static const giveItem = 'giveItem';
  static const giveItemGift = 'giveItemGift';
  static const claimPeriodicReward = 'claimPeriodicReward';
  static const takeItem = 'takeItem';
  static const giveMoney = 'giveMoney';
  static const grantRailCurrency = 'grantRailCurrency';
  static const grantRailStamp = 'grantRailStamp';
  static const givePokemon = 'givePokemon';
  static const markPokemonSeen = 'markPokemonSeen';
  static const setNpcPose = 'setNpcPose';
  static const givePokemonFromCatalog = 'givePokemonFromCatalog';
  static const receivePokemonFromCatalog = 'receivePokemonFromCatalog';
  static const giveConfiguredStarter = 'giveConfiguredStarter';
  static const warp = 'warp';
  static const wait = 'wait';
  static const waitForActorRoutes = 'waitForActorRoutes';
  static const worldTone = 'worldTone';
  static const worldPresentation = 'worldPresentation';
  static const playSoundEffect = 'playSoundEffect';
  static const stopSoundEffects = 'stopSoundEffects';
  static const playMusicEffect = 'playMusicEffect';
  static const sceneMusic = 'sceneMusic';
  static const actorRoute = 'actorRoute';
  static const actorVisibility = 'actorVisibility';
  static const openImagePuzzle = 'openImagePuzzle';
  static const openCrafting = 'openCrafting';
  static const openShop = 'openShop';
  static const openHeal = 'openHeal';
  static const whiteOut = 'whiteOut';
  static const openPc = 'openPc';
  static const openRegionalMap = 'openRegionalMap';
  static const openPartyTrade = 'openPartyTrade';
  static const openNpcTrade = 'openNpcTrade';
  static const dialogue = 'dialogue';
  static const trainerBattle = 'trainerBattle';
  static const staticEncounter = 'staticEncounter';
  static const cinematic = 'cinematic';
  static const healParty = 'healParty';
  static const awardBadge = 'awardBadge';
  static const unlockFieldAbility = 'unlockFieldAbility';
  static const finishGame = 'finishGame';
  static const setNpcPresence = 'setNpcPresence';
  static const setPlayerAvatar = 'setPlayerAvatar';
  static const setPauseMenuEntryVisibility =
      'setPauseMenuEntryVisibility';
  static const moveNpc = 'moveNpc';
  static const movePlatform = 'movePlatform';
  static const setPropState = 'setPropState';
  static const playCharacterAnimation = 'playCharacterAnimation';
  static const playModelAnimation = 'playModelAnimation';
  static const railJourney = 'railJourney';

  static String forConsequence(SceneConsequence consequence) => consequence.kind.name;

  static String forInteractiveCommand(SceneInteractiveCommand command) =>
      command is SceneGiveItemInteractiveCommand ? giveItemGift :
      command is SceneOpenPartyTradeInteractiveCommand && command.npcOffer != null
          ? openNpcTrade : command.kind.name;
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

    List<NarrativeCommandParameterDescriptor> operandParameters({
      bool random = false,
    }) => [
      _parameter(
        'operandSource',
        'Origine de la valeur',
        NarrativeCommandParameterKind.integerOperandSource,
      ),
      _parameter(
        'operandValue',
        'Valeur entière',
        NarrativeCommandParameterKind.integer,
      ),
      _parameter(
        'operandFactId',
        'Compteur source',
        NarrativeCommandParameterKind.fact,
      ),
      _parameter(
        'operandItemId',
        'Objet à compter',
        NarrativeCommandParameterKind.item,
      ),
      if (random) ...[
        _parameter(
          'randomMinimum',
          'Tirage minimum',
          NarrativeCommandParameterKind.integer,
        ),
        _parameter(
          'randomMaximum',
          'Tirage maximum',
          NarrativeCommandParameterKind.integer,
        ),
      ],
    ];
    return NarrativeCommandCatalog._([
      consequence(
        NarrativeCommandIds.calculateIntegerFacts,
        'Calculer des compteurs',
        'FG-088',
        [
          _parameter(
            'factIds',
            'Compteurs à modifier',
            NarrativeCommandParameterKind.integerFacts,
          ),
          _parameter(
            'operation',
            'Calcul',
            NarrativeCommandParameterKind.integerOperation,
          ),
          ...operandParameters(random: true),
          _parameter(
            'minimum',
            'Résultat minimum',
            NarrativeCommandParameterKind.integer,
          ),
          _parameter(
            'maximum',
            'Résultat maximum',
            NarrativeCommandParameterKind.integer,
          ),
          _parameter(
            'zeroDivisorPolicy',
            'Diviseur nul ou unité',
            NarrativeCommandParameterKind.integerZeroPolicy,
          ),
          _parameter(
            'boundaryPolicy',
            'Limites et opérations sans changement',
            NarrativeCommandParameterKind.integerBoundaryPolicy,
          ),
        ],
      ),
      consequence(
        NarrativeCommandIds.adjustMoney,
        'Modifier le solde',
        'FG-088',
        [
          _parameter(
            'operation',
            'Opération',
            NarrativeCommandParameterKind.moneyOperation,
          ),
          ...operandParameters(),
          _parameter(
            'minimum',
            'Solde minimum',
            NarrativeCommandParameterKind.integer,
          ),
          _parameter(
            'maximum',
            'Solde maximum',
            NarrativeCommandParameterKind.integer,
          ),
        ],
      ),
      interactive(
        NarrativeCommandIds.inputIntegerToFact,
        'Demander un nombre',
        'FG-088',
        [
          _parameter(
            'factId',
            'Compteur destination',
            NarrativeCommandParameterKind.fact,
          ),
          _parameter('prompt', 'Question', NarrativeCommandParameterKind.text),
          _parameter(
            'digits',
            'Nombre de chiffres',
            NarrativeCommandParameterKind.integer,
          ),
          _parameter(
            'minimum',
            'Valeur minimale',
            NarrativeCommandParameterKind.integer,
          ),
          _parameter(
            'maximum',
            'Valeur maximale',
            NarrativeCommandParameterKind.integer,
          ),
          _parameter(
            'initialValue',
            'Valeur initiale (vide : compteur actuel)',
            NarrativeCommandParameterKind.integer,
            required: false,
          ),
          _parameter(
            'allowCancel',
            'Autoriser l’annulation',
            NarrativeCommandParameterKind.boolean,
          ),
          _parameter('cancellationPolicy', 'Résultat après annulation', NarrativeCommandParameterKind.integerCancellationPolicy),
        ],
        isPersistent: true,
      ),
      interactive(
        NarrativeCommandIds.tryPayMoney,
        'Demander un paiement',
        'FG-088',
        [
          ...operandParameters(),
          _parameter(
            'confirmationPrompt',
            'Confirmation ({amount}, facultative)',
            NarrativeCommandParameterKind.text,
            required: false,
          ),
        ],
        isPersistent: true,
      ),
      interactive(NarrativeCommandIds.inputTextToFact, 'Demander un texte', 'FG-088', [
        _parameter('factId', 'Fact texte', NarrativeCommandParameterKind.fact,
          ),
        _parameter('prompt', 'Question', NarrativeCommandParameterKind.text),
        _parameter('confirmationPrompt', 'Question de confirmation ({value})', NarrativeCommandParameterKind.text,
          ),
        _parameter('minGraphemes', 'Longueur minimale', NarrativeCommandParameterKind.integer,
          ),
        _parameter('maxGraphemes', 'Longueur maximale', NarrativeCommandParameterKind.integer,
          ),
        _parameter('presetValues', 'Noms proposés (un par ligne)', NarrativeCommandParameterKind.text, required: false,
          ),
        _parameter('customChoiceLabel', 'Libellé du nom personnalisé', NarrativeCommandParameterKind.text, required: false,
          ),
        _parameter('presetChoicePrompt', 'Question du choix de nom', NarrativeCommandParameterKind.text, required: false,
          ),
      ], isPersistent: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.setMapEventInstanceBoolean,
        label: 'Définir un booléen de cette instance',
        description: 'Mémoire booléenne d’un élément de carte 2D : conservée à la sauvegarde tant que son instance existe, réinitialisée après éviction. Les états persistants du jeu restent distincts.',
        backend: NarrativeCommandBackend.sceneConsequence,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
        ),
        fgLotId: 'FG-081',
        wireId: 'SceneConsequence.setMapEventInstanceBoolean',
        parameters: [
          _parameter('mapId', 'Carte', NarrativeCommandParameterKind.map),
          _parameter('eventId', 'Propriétaire logique', NarrativeCommandParameterKind.mapEntityReference,
          ),
          _parameter('key', 'Clé locale', NarrativeCommandParameterKind.text),
          _parameter('value', 'Valeur', NarrativeCommandParameterKind.boolean),
        ],
        isPersistent: true,
      ),
      consequence(NarrativeCommandIds.setFact, 'Définir un Fact', 'FG-080', [
        _parameter('factId', 'Fact', NarrativeCommandParameterKind.fact),
        _parameter('value', 'Valeur', NarrativeCommandParameterKind.boolean),
      ]),
      consequence(NarrativeCommandIds.adjustIntegerFact, 'Modifier un compteur', 'FG-080', [
        _parameter('factId', 'Compteur', NarrativeCommandParameterKind.fact),
        _parameter('delta', 'Variation', NarrativeCommandParameterKind.integer,
          ),
        _parameter('minimum', 'Minimum', NarrativeCommandParameterKind.integer,
          ),
        _parameter('maximum', 'Maximum', NarrativeCommandParameterKind.integer,
          ),
        ],
      ),
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
      interactive(
        NarrativeCommandIds.receivePokemonFromCatalog,
        'Recevoir un Pokémon du catalogue',
        'FG-103',
        [
          _parameter('speciesId', 'Espèce', NarrativeCommandParameterKind.species,
          ),
          _parameter('formId', 'Forme', NarrativeCommandParameterKind.speciesForm,
          ),
          _parameter('level', 'Niveau', NarrativeCommandParameterKind.integer),
          _parameter('nicknamePolicy', 'Proposer un surnom', NarrativeCommandParameterKind.pokemonGiftNicknamePolicy,
          ),
          _parameter('nicknameMaxGraphemes', 'Longueur maximale du surnom', NarrativeCommandParameterKind.integer,
          ),
          _parameter('pokedexPresentationPolicy', 'Présenter le Pokédex', NarrativeCommandParameterKind.pokemonGiftPokedexPolicy,
          ),
          _parameter('moveIds', 'Capacités imposées', NarrativeCommandParameterKind.text, required: false,
          ),
          _parameter('isEgg', 'Recevoir un Œuf', NarrativeCommandParameterKind.boolean, required: false),
        ],
        isPersistent: true,
      ),
      consequence(NarrativeCommandIds.markPokemonSeen, 'Marquer un Pokémon comme vu', 'FG-161', [
        _parameter('speciesId', 'Espèce', NarrativeCommandParameterKind.species,
          ),
        ],
      ),
      consequence(
        NarrativeCommandIds.givePokemonFromCatalog,
        'Donner un Pokémon du catalogue',
        'FG-084',
        [
          _parameter('speciesId', 'Espèce', NarrativeCommandParameterKind.species,
          ),
          _parameter('formId', 'Forme', NarrativeCommandParameterKind.speciesForm,
          ),
          _parameter('level', 'Niveau', NarrativeCommandParameterKind.integer),
          _parameter('moveIds', 'Capacités imposées', NarrativeCommandParameterKind.text, required: false,
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
            'recordParty',
            'Enregistrer l’équipe dans le journal des victoires',
            NarrativeCommandParameterKind.boolean,
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
      consequence(NarrativeCommandIds.setNpcPose, 'Modifier la pose d’un PNJ', 'FG-092', [
        _parameter('npcRef', 'PNJ à variantes', NarrativeCommandParameterKind.mapEntityReference,
          ),
        _parameter('x', 'Colonne', NarrativeCommandParameterKind.integer, required: false,
          ),
        _parameter('y', 'Ligne', NarrativeCommandParameterKind.integer, required: false,
          ),
        _parameter('facing', 'Direction', NarrativeCommandParameterKind.characterDirection, required: false,
          ),
        ],
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
        NarrativeCommandIds.setPlayerAvatar,
        'Changer l’avatar du joueur',
        'FG-080',
        [
          _parameter(
            'characterId',
            'Avatar / costume',
            NarrativeCommandParameterKind.character,
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
        _parameter('warpId', 'Point d’arrivée', NarrativeCommandParameterKind.warp,
        ),
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
          NarrativeCommandParameterKind.warpPresentationMode, required: false,
        ),
        _parameter('illustrationElementId', 'Illustration',
          NarrativeCommandParameterKind.visualElementReference, required: false,
        ),
        _parameter('fadeOutMs', 'Fondu noir (ms)', NarrativeCommandParameterKind.integer, required: false,
        ),
        _parameter('transferDelayMs', 'Préparation avant passage (ms)', NarrativeCommandParameterKind.integer, required: false,
        ),
        _parameter('revealMs', 'Révélation (ms)', NarrativeCommandParameterKind.integer, required: false,
        ),
        _parameter('illustrationHoldMs', 'Maintien illustration (ms)', NarrativeCommandParameterKind.integer, required: false,
        ),
        _parameter('illustrationFadeMs', 'Fondu illustration (ms)', NarrativeCommandParameterKind.integer, required: false,
        ),
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
        parameters: [_parameter('mapId', 'Carte', NarrativeCommandParameterKind.map),
        ],
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
          _parameter('durationMs', 'Durée (ms)', NarrativeCommandParameterKind.integer,
          ),
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
        id: NarrativeCommandIds.worldPresentation,
        label: 'Images, ambiance, flash et secousse',
        description: 'Affiche et anime des images dans un cadre de référence explicite. Les effets de carte durent jusqu’au transfert ; les effets de scène se terminent avec la scène.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Player 2D ; images du catalogue de présentation, cadrage proportionnel, mélange normal.',
        ),
        fgLotId: 'FG-093',
        wireId: 'SceneInteractiveCommand.worldPresentation',
        parameters: [
          _parameter('operation', 'Effet', NarrativeCommandParameterKind.text),
          _parameter('visualSettings', 'Paramètres d’ambiance 3D', NarrativeCommandParameterKind.text, required: false),
          _parameter('scope', 'Durée de présence', NarrativeCommandParameterKind.text, required: false),
          _parameter('slotId', 'Emplacement', NarrativeCommandParameterKind.integer, required: false),
          _parameter('mediaAssetId', 'Image', NarrativeCommandParameterKind.text, required: false),
          for (final name in ['referenceWidth', 'referenceHeight', 'durationMs'])
            _parameter(name, name, NarrativeCommandParameterKind.integer, required: false),
          for (final name in ['x', 'y', 'scaleX', 'scaleY', 'opacity', 'red', 'green', 'blue', 'alpha', 'power', 'speed'])
            _parameter(name, name, NarrativeCommandParameterKind.number, required: false),
          _parameter('origin', 'Origine', NarrativeCommandParameterKind.text, required: false),
          _parameter('waitForCompletion', 'Attendre la fin', NarrativeCommandParameterKind.boolean, required: false),
        ],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.playSoundEffect,
        label: 'Jouer un effet sonore',
        description:
            'Joue un effet sonore et peut attendre sa fin réelle.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Lecture disponible en 2D et 3D ; attente optionnelle de la fin réelle.',
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
          _parameter('waitForCompletion', 'Attendre la fin', NarrativeCommandParameterKind.boolean, required: false),
        ],
        isAwaitable: true,
      ),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.sceneMusic,
        label: 'Musique et ambiance',
        description: 'Contrôle la musique ou l’ambiance de la scène ou de la carte. Mémorise et restaure les deux canaux ensemble. Le combat garde la priorité musicale.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Player 2D : canaux musique et ambiance, portée scène ou carte. Player 3D : canal musique, portée scène uniquement. Le combat suspend l’ambiance et garde la priorité musicale. La mémorisation conserve les descripteurs, sans position.',
        ),
        fgLotId: 'FG-093',
        wireId: 'SceneInteractiveCommand.sceneMusic',
        parameters: [
          _parameter(
            'operation',
            'Action musicale',
            NarrativeCommandParameterKind.sceneMusicOperation,
          ),
          _parameter('channel', 'Canal', NarrativeCommandParameterKind.sceneMusicChannel, required: false),
          _parameter('scope', 'Durée de vie', NarrativeCommandParameterKind.sceneMusicScope, required: false),
          _parameter(
            'mediaAssetId',
            'Musique en boucle',
            NarrativeCommandParameterKind.musicMediaReference,
            required: false,
          ),
          _parameter(
            'volume',
            'Volume',
            NarrativeCommandParameterKind.number,
            required: false,
          ),
          _parameter(
            'durationMs',
            'Durée du fondu (ms)',
            NarrativeCommandParameterKind.integer,
            required: false,
          ),
        ],
        isAwaitable: true,
      ),
      interactive(NarrativeCommandIds.stopSoundEffects, 'Arrêter les effets sonores', 'FG-093', [
        _parameter('scope', 'Durée de vie', NarrativeCommandParameterKind.sceneMusicScope),
      ]),
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.playMusicEffect,
        label: 'Jouer une fanfare',
        description:
            'Joue une fanfare, suspend la musique et la reprend à la fin. Peut attendre la fin réelle.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: const NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.supported,
          editor: NarrativeCommandCapabilityStatus.supported,
          runtime: NarrativeCommandCapabilityStatus.supported,
          reason: 'Lecture disponible en 2D et 3D ; attente optionnelle de la fin réelle.',
        ),
        fgLotId: 'FG-093',
        wireId: 'SceneInteractiveCommand.playMusicEffect',
        parameters: [
          _parameter(
            'mediaAssetId',
            'Fanfare',
            NarrativeCommandParameterKind.soundMediaReference,
          ),
          _parameter('volume', 'Volume', NarrativeCommandParameterKind.number),
          _parameter('fadeOutMs', 'Fondu de pause musique (ms)', NarrativeCommandParameterKind.integer,
          ),
          _parameter('fadeInMs', 'Fondu de reprise musique (ms)', NarrativeCommandParameterKind.integer,
          ),
          _parameter('waitForCompletion', 'Attendre la fin', NarrativeCommandParameterKind.boolean, required: false),
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
        NarrativeCommandIds.openImagePuzzle,
        'Ouvrir un puzzle d’image',
        'FG-082',
        [
          _parameter('puzzleId', 'Identité du puzzle', NarrativeCommandParameterKind.text),
          _parameter('imageResourceId', 'Image du puzzle', NarrativeCommandParameterKind.imageMediaReference),
          _parameter('rows', 'Lignes', NarrativeCommandParameterKind.integer),
          _parameter('columns', 'Colonnes', NarrativeCommandParameterKind.integer),
          _parameter('trayCapacity', 'Cases de réserve', NarrativeCommandParameterKind.integer),
          _parameter('allowReset', 'Autoriser le recommencement', NarrativeCommandParameterKind.boolean),
          _parameter('allowSwap', 'Autoriser les échanges', NarrativeCommandParameterKind.boolean),
          _parameter('layout', 'Disposition des pièces', NarrativeCommandParameterKind.imagePuzzleLayout),
        ],
        isPersistent: true,
      ),
      interactive(
        NarrativeCommandIds.openCrafting,
        'Ouvrir un atelier de fabrication',
        'FG-082',
        [
          _parameter('serviceId', 'Identité stable de l’atelier', NarrativeCommandParameterKind.text),
          _parameter('label', 'Nom de l’atelier', NarrativeCommandParameterKind.text),
          _parameter('recipes', 'Recettes', NarrativeCommandParameterKind.deferredCraftingRecipes),
          _parameter('maximumBatchQuantity', 'Quantité maximale par commande', NarrativeCommandParameterKind.integer),
          _parameter('requiredDayChanges', 'Changements de jour nécessaires', NarrativeCommandParameterKind.integer),
        ],
        isPersistent: true,
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
      NarrativeCommandDescriptor(
        id: NarrativeCommandIds.whiteOut,
        label: 'Défaite et retour au point de reprise',
        description: 'Déclare une défaite scénarisée : soigne l’équipe, applique la pénalité et rejoint le point de reprise à la fin réussie de la Scene. Une seule récupération par Scene. Disponible en 2D.',
        backend: NarrativeCommandBackend.interactiveRuntimeCommand,
        capabilities: supported,
        fgLotId: 'FG-093',
        wireId: 'SceneInteractiveCommand.whiteOut',
        parameters: const [],
        isAwaitable: true,
        isPersistent: true,
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
        NarrativeCommandIds.openNpcTrade,
        'Échanger avec un personnage',
        'FG-082',
        [
          _parameter('offerName', 'Nom de l’offre unique', NarrativeCommandParameterKind.text),
          _parameter('requestedSpeciesId', 'Pokémon demandé', NarrativeCommandParameterKind.species),
          _parameter('speciesId', 'Pokémon offert', NarrativeCommandParameterKind.species),
          _parameter('formId', 'Forme offerte', NarrativeCommandParameterKind.speciesForm),
          _parameter('nickname', 'Surnom offert', NarrativeCommandParameterKind.text, required: false),
          _parameter('level', 'Niveau offert', NarrativeCommandParameterKind.integer),
          _parameter('matchSelectedLevel', 'Reprendre le niveau du Pokémon choisi', NarrativeCommandParameterKind.boolean),
        ],
        wireId: 'SceneInteractiveCommand.openNpcTrade',
        isPersistent: true,
      ),
      interactive(
        NarrativeCommandIds.setPropState,
        'Déplacer des décors mobiles',
        'FG-082',
        [
          _parameter('mapId', 'Carte', NarrativeCommandParameterKind.map),
          _parameter('propIds', 'Décors à synchroniser', NarrativeCommandParameterKind.movingProps,
          ),
          _parameter('state', 'État souhaité', NarrativeCommandParameterKind.movingPropState,
          ),
          _parameter('durationMs', 'Durée du mouvement (ms)', NarrativeCommandParameterKind.integer,
          ),
        ],
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
      interactive(
        NarrativeCommandIds.claimPeriodicReward,
        'Recevoir un objet quotidien',
        'FG-083',
        [
          _parameter('rewardId', 'Identité stable de la récompense', NarrativeCommandParameterKind.text),
          _parameter('label', 'Nom de la récompense', NarrativeCommandParameterKind.text),
          _parameter('itemId', 'Objet', NarrativeCommandParameterKind.item),
          _parameter('quantity', 'Quantité', NarrativeCommandParameterKind.integer),
        ],
        isPersistent: true,
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
