import '../models/narrative_command_descriptor.dart';

abstract final class NarrativeCommandIds {
  static const setFact = 'setFact';
  static const markEventConsumed = 'markEventConsumed';
  static const completeStoryStep = 'completeStoryStep';
  static const giveItem = 'giveItem';
  static const takeItem = 'takeItem';
  static const giveMoney = 'giveMoney';
  static const givePokemon = 'givePokemon';
  static const giveConfiguredStarter = 'giveConfiguredStarter';
  static const warp = 'warp';
  static const openShop = 'openShop';
  static const openHeal = 'openHeal';
  static const openPc = 'openPc';
  static const dialogue = 'dialogue';
  static const trainerBattle = 'trainerBattle';
  static const staticEncounter = 'staticEncounter';
  static const cinematic = 'cinematic';
  static const healParty = 'healParty';
  static const awardBadge = 'awardBadge';
  static const unlockFieldAbility = 'unlockFieldAbility';
  static const finishGame = 'finishGame';
  static const setNpcPresence = 'setNpcPresence';
  static const moveNpc = 'moveNpc';
  static const playCharacterAnimation = 'playCharacterAnimation';
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
      List<NarrativeCommandParameterDescriptor> parameters,
    ) =>
        NarrativeCommandDescriptor(
          id: id,
          label: label,
          description: 'Interaction runtime attendue avec résultat explicite.',
          backend: NarrativeCommandBackend.interactiveRuntimeCommand,
          capabilities: supported,
          fgLotId: lot,
          wireId: 'SceneInteractiveCommand.$id',
          parameters: parameters,
          isAwaitable: true,
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
      interactive(NarrativeCommandIds.warp, 'Téléporter', 'FG-090', [
        _parameter(
          'destinationMapId',
          'Map',
          NarrativeCommandParameterKind.map,
        ),
        _parameter('warpId', 'Warp', NarrativeCommandParameterKind.warp),
      ]),
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
        ],
      ),
      interactive(
        NarrativeCommandIds.openPc,
        'Ouvrir le PC',
        'FG-091',
        const [],
      ),
      interactive(NarrativeCommandIds.moveNpc, 'Déplacer un PNJ', 'FG-092', [
        _parameter('npcRef', 'PNJ', NarrativeCommandParameterKind.npc),
        _parameter('warpId', 'Destination', NarrativeCommandParameterKind.warp),
      ]),
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
