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
  static const openPc = 'openPc';
  static const dialogue = 'dialogue';
  static const trainerBattle = 'trainerBattle';
  static const staticEncounter = 'staticEncounter';
  static const cinematic = 'cinematic';
  static const healParty = 'healParty';
  static const awardBadge = 'awardBadge';
  static const unlockFieldAbility = 'unlockFieldAbility';
  static const setNpcPresence = 'setNpcPresence';
}

final class NarrativeCommandCatalog {
  NarrativeCommandCatalog._(this.commands);

  factory NarrativeCommandCatalog.canonical() {
    const supported = NarrativeCommandCapabilities.supported();
    NarrativeCommandCapabilities unsupported(String reason) =>
        NarrativeCommandCapabilities(
          model: NarrativeCommandCapabilityStatus.unsupported,
          editor: NarrativeCommandCapabilityStatus.unsupported,
          runtime: NarrativeCommandCapabilityStatus.unsupported,
          reason: reason,
        );
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
          _parameter('eventId', 'Event', NarrativeCommandParameterKind.event),
        ],
      ),
      consequence(
        NarrativeCommandIds.completeStoryStep,
        'Terminer une étape',
        'FG-082',
        [
          _parameter('stepId', 'Étape', NarrativeCommandParameterKind.storyStep)
        ],
      ),
      consequence(NarrativeCommandIds.giveItem, 'Donner un objet', 'FG-083', [
        _parameter('itemId', 'Objet', NarrativeCommandParameterKind.item),
        _parameter(
            'quantity', 'Quantité', NarrativeCommandParameterKind.integer),
      ]),
      consequence(NarrativeCommandIds.takeItem, 'Retirer un objet', 'FG-083', [
        _parameter('itemId', 'Objet', NarrativeCommandParameterKind.item),
        _parameter(
            'quantity', 'Quantité', NarrativeCommandParameterKind.integer),
      ]),
      consequence(
          NarrativeCommandIds.giveMoney, 'Donner de l’argent', 'FG-084', [
        _parameter('amount', 'Montant', NarrativeCommandParameterKind.integer),
      ]),
      consequence(
          NarrativeCommandIds.givePokemon, 'Donner un Pokémon', 'FG-085', [
        _parameter(
            'speciesId', 'Espèce', NarrativeCommandParameterKind.species),
        _parameter('level', 'Niveau', NarrativeCommandParameterKind.integer),
      ]),
      consequence(
        NarrativeCommandIds.giveConfiguredStarter,
        'Donner un starter configuré',
        'FG-085',
        [
          _parameter('starterOptionId', 'Starter',
              NarrativeCommandParameterKind.starter)
        ],
      ),
      interactive(NarrativeCommandIds.warp, 'Téléporter', 'FG-086', [
        _parameter(
            'destinationMapId', 'Map', NarrativeCommandParameterKind.map),
        _parameter('warpId', 'Warp', NarrativeCommandParameterKind.warp),
      ]),
      interactive(
          NarrativeCommandIds.openShop, 'Ouvrir une boutique', 'FG-087', [
        _parameter('shopId', 'Boutique', NarrativeCommandParameterKind.shop),
      ]),
      interactive(
          NarrativeCommandIds.openPc, 'Ouvrir le PC', 'FG-088', const []),
      node(
        NarrativeCommandIds.dialogue,
        'Jouer un dialogue',
        'SceneNode.yarnDialogue',
        'FG-089',
        _parameter(
            'dialogueId', 'Dialogue', NarrativeCommandParameterKind.dialogue),
      ),
      node(
        NarrativeCommandIds.trainerBattle,
        'Lancer un combat de Dresseur',
        'SceneNode.battle.trainer',
        'FG-090',
        _parameter(
            'trainerId', 'Dresseur', NarrativeCommandParameterKind.trainer),
      ),
      node(
        NarrativeCommandIds.staticEncounter,
        'Lancer une rencontre statique',
        'SceneNode.battle.static',
        'FG-090',
        _parameter(
            'speciesId', 'Espèce', NarrativeCommandParameterKind.species),
      ),
      node(
        NarrativeCommandIds.cinematic,
        'Jouer une cinématique',
        'SceneNode.cinematic',
        'FG-091',
        _parameter('cinematicId', 'Cinématique',
            NarrativeCommandParameterKind.cinematic),
      ),
      for (final entry in [
        (
          NarrativeCommandIds.healParty,
          'Soigner l’équipe',
          'FG-092',
          'Aucune SceneConsequence canonique healParty n’est encore prouvée.',
        ),
        (
          NarrativeCommandIds.awardBadge,
          'Donner un badge',
          'FG-092',
          'Le contrat de progression Badge n’est pas encore livré.',
        ),
        (
          NarrativeCommandIds.unlockFieldAbility,
          'Débloquer une capacité terrain',
          'FG-092',
          'Le contrat Field Ability n’est pas encore livré.',
        ),
        (
          NarrativeCommandIds.setNpcPresence,
          'Modifier la présence d’un PNJ',
          'FG-092',
          'Utiliser Fact + WorldRule ; aucun override persistant parallèle.',
        ),
      ])
        NarrativeCommandDescriptor(
          id: entry.$1,
          label: entry.$2,
          description: entry.$4,
          backend: NarrativeCommandBackend.sceneConsequence,
          capabilities: unsupported(entry.$4),
          fgLotId: entry.$3,
          wireId: 'unsupported.${entry.$1}',
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
  NarrativeCommandParameterKind kind,
) =>
    NarrativeCommandParameterDescriptor(id: id, label: label, kind: kind);
