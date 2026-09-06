import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import '../application/runtime_pokemon_evolution_loader.dart';
import '../application/dialogue_portrait_resolver.dart';
import '../application/runtime_item_catalog_loader.dart';
import '../application/runtime_battle_combatant_seed_builder.dart';
import '../application/runtime_move_catalog_loader.dart';
import '../application/runtime_move_machine_loader.dart';
import 'runtime_player_pause_data.dart';
import 'runtime_bag_item_icon_resolver.dart';
import 'runtime_regional_map_builder.dart';
import 'runtime_pokemon_summary.dart';
import 'runtime_pokemon_summary_media_resolver.dart';

/// Builds player-facing pause data from the runtime's live state.
///
/// This projection deliberately stays in `map_runtime`: embedding hosts only
/// render snapshots and never inspect project JSON or save internals.
final class RuntimePlayerPauseDataBuilder {
  const RuntimePlayerPauseDataBuilder();

  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
      build({
    required GameState gameState,
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String locale,
    String? uiLocale,
    bool mapEnabled = false,
    List<ProjectMapEntry> projectMaps = const <ProjectMapEntry>[],
    ProjectRegionalMapCatalog? regionalMap,
    ItemCatalogSnapshot? itemCatalog,
    int? playtimeSeconds,
    String? currencyLabel,
    List<BadgeDefinition>? projectBadges,
    List<ProjectCharacterEntry> projectCharacters = const [],
    DialoguePortraitLookup? portraitLookup,
  }) async {
    final resolvedItemCatalog = itemCatalog ??
        await const RuntimeItemCatalogLoader().loadSnapshot(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
        );
    final speciesCatalog = await _loadSpeciesCatalog(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final species = speciesCatalog.entries;
    final speciesById = <String, _RuntimeSpeciesPresentation>{
      for (final entry in species) entry.id: entry,
    };
    // Un projet sans catalogue d'attaques doit dégrader la fiche, pas empêcher
    // l'ouverture du menu pause : le chargeur lève quand la clé est absente.
    RuntimeMoveCatalog? moveCatalog;
    try {
      moveCatalog = await RuntimeMoveCatalogLoader().load(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
      );
    } on Object {
      moveCatalog = null;
    }
    final isFrench = (uiLocale ?? locale).toLowerCase().startsWith('fr');
    final evolutionItemIds = await _loadEvolutionItemIds(
      gameState,
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final moveMachines = await _loadMoveMachineAvailability(
      gameState,
      speciesById,
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      itemCatalog: resolvedItemCatalog,
    );
    final heldItemOptions = _buildHeldItemOptions(
      gameState,
      resolvedItemCatalog,
    );
    final mediaResolver = RuntimePokemonSummaryMediaResolver(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final pokedex = pokemonConfig.enabled
        ? await _buildPokedex(
            gameState,
            species,
            locale: locale,
            isFrench: isFrench,
            mediaResolver: mediaResolver,
            catalogInvalid: speciesCatalog.invalid,
          )
        : null;
    final profile = await _buildProfile(
      gameState,
      projectRootDirectory: projectRootDirectory,
      isFrench: isFrench,
      playtimeSeconds: playtimeSeconds,
      projectMaps: projectMaps,
      projectBadges: projectBadges,
      projectCharacters: projectCharacters,
      portraitLookup: portraitLookup,
      pokedex: speciesCatalog.invalid ? null : pokedex,
      currencyLabel: currencyLabel,
    );

    final party = await _buildParty(
      gameState,
      speciesById,
      locale: locale,
      isFrench: isFrench,
      itemCatalog: resolvedItemCatalog,
      heldItemOptions: heldItemOptions,
      moveCatalog: moveCatalog,
      mediaResolver: mediaResolver,
    );
    final bagTargets =
        _buildBagTargets(party, isFrench: isFrench, moveMachines: moveMachines);
    final iconResolver = RuntimeBagItemIconResolver(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final icons = Map.fromEntries(await Future.wait(
      gameState.bag.entries.where((entry) => entry.quantity > 0).map(
            (entry) async => MapEntry(
                entry.itemId,
                resolvedItemCatalog.definitionFor(entry.itemId) == null
                    ? null
                    : await iconResolver.resolve(entry.itemId)),
          ),
    ));
    return immutableRuntimePlayerPauseDetails(
      <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
        RuntimePlayerPauseSection.profile: profile,
        RuntimePlayerPauseSection.party: party,
        RuntimePlayerPauseSection.bag: _buildBag(
          gameState,
          isFrench: isFrench,
          targets: bagTargets,
          iconPaths: icons,
          currencyLabel: currencyLabel,
          speciesById: speciesById,
          moveCatalog: moveCatalog,
          evolutionItemIds: evolutionItemIds,
          moveMachines: moveMachines,
          itemCatalog: resolvedItemCatalog,
        ),
        if (pokedex != null) RuntimePlayerPauseSection.pokedex: pokedex,
        if (mapEnabled)
          RuntimePlayerPauseSection.map:
              await const RuntimeRegionalMapBuilder().build(
            gameState: gameState,
            projectMaps: projectMaps,
            catalog: regionalMap,
            projectRootDirectory: projectRootDirectory,
            locale: uiLocale ?? locale,
          ),
      },
    );
  }

  Future<RuntimePlayerPauseDetailSnapshot> _buildProfile(
    GameState gameState, {
    required String projectRootDirectory,
    required bool isFrench,
    required int? playtimeSeconds,
    required List<ProjectMapEntry> projectMaps,
    required List<BadgeDefinition>? projectBadges,
    required List<ProjectCharacterEntry> projectCharacters,
    required DialoguePortraitLookup? portraitLookup,
    required RuntimePlayerPauseDetailSnapshot? pokedex,
    required String? currencyLabel,
  }) async {
    final trainer = gameState.trainerProfile;
    final badges = <RuntimePlayerProfileBadgeSnapshot>[];
    for (final id in trainer.badgeIds) {
      final definition =
          projectBadges?.where((badge) => badge.id == id).firstOrNull;
      badges.add(RuntimePlayerProfileBadgeSnapshot(
        id: id,
        label:
            definition?.label ?? (isFrench ? 'Badge obtenu' : 'Earned badge'),
        iconFilePath: await _profileBadgeIcon(
          definition?.iconRelativePath,
          projectRootDirectory,
        ),
      ));
    }
    final currentMap = projectMaps
        .where((entry) => entry.id == gameState.currentMapId)
        .firstOrNull;
    final character = projectCharacters
        .where((entry) => entry.id == trainer.avatarCharacterId)
        .firstOrNull;
    final locationName = currentMap?.name.trim();
    final dexEntries = pokedex?.entries;
    final profile = RuntimePlayerProfileSnapshot(
      playerName: trainer.name,
      currentMapId: gameState.currentMapId,
      locationName:
          locationName == null || locationName.isEmpty ? null : locationName,
      money: trainer.money,
      currencyLabel: currencyLabel,
      playtimeSeconds: playtimeSeconds,
      avatarCharacterId: trainer.avatarCharacterId,
      pronounSet: trainer.pronounSet,
      portraits: character?.portraits ?? const [],
      portraitFilePath: character == null || character.portraits.isEmpty
          ? null
          : portraitLookup
              ?.call(
                  characterId: character.id,
                  portraitStateId: character.portraits.first.portraitStateId)
              ?.absoluteFilePath,
      badgeIds: trainer.badgeIds,
      badges: badges,
      pokedex: dexEntries == null
          ? null
          : RuntimePlayerPokedexProgressSnapshot(
              seen: dexEntries
                  .where((entry) =>
                      entry.pokedexEntry!.knowledge !=
                      RuntimePlayerPokedexKnowledge.unknown)
                  .length,
              caught: dexEntries
                  .where((entry) =>
                      entry.pokedexEntry!.knowledge ==
                      RuntimePlayerPokedexKnowledge.caught)
                  .length,
              total: dexEntries.length,
            ),
    );
    final seconds = profile.playtimeSeconds;
    final minutes = seconds == null ? null : seconds ~/ 60;
    return RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.profile,
      title: isFrench ? 'Profil' : 'Profile',
      profile: profile,
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'profile.name',
          title: isFrench ? 'Dresseur' : 'Trainer',
          subtitle: profile.playerName,
        ),
        if (profile.locationName case final location?)
          RuntimePlayerDetailEntrySnapshot(
            id: 'profile.location',
            title: isFrench ? 'Lieu' : 'Location',
            subtitle: location,
          ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'profile.playtime',
          title: isFrench ? 'Temps de jeu' : 'Play time',
          subtitle: minutes == null
              ? '—'
              : '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}',
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'profile.money',
          title: isFrench ? 'Argent' : 'Money',
          subtitle: '${profile.money}',
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'profile.badges',
          title: 'Badges',
          subtitle: profile.badgeTotal == null
              ? '${profile.badgeIds.length}'
              : '${profile.badgeIds.length} / ${profile.badgeTotal}',
        ),
        if (profile.pokedex case final progress?) ...[
          RuntimePlayerDetailEntrySnapshot(
            id: 'profile.pokedex.seen',
            title: isFrench ? 'Pokémon vus' : 'Pokémon seen',
            subtitle: '${progress.seen} / ${progress.total}',
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'profile.pokedex.caught',
            title: isFrench ? 'Pokémon capturés' : 'Pokémon caught',
            subtitle: '${progress.caught} / ${progress.total}',
          ),
        ],
      ],
    );
  }

  Future<String?> _profileBadgeIcon(String? rawPath, String projectRoot) async {
    final relative = rawPath?.trim().replaceAll('\\', '/');
    if (relative == null ||
        relative.isEmpty ||
        p.posix.isAbsolute(relative) ||
        p.windows.isAbsolute(relative) ||
        p.posix.split(relative).contains('..') ||
        Uri.tryParse(relative)?.hasScheme == true) {
      return null;
    }
    try {
      final root = await Directory(projectRoot).resolveSymbolicLinks();
      final file = File(p.join(root, relative));
      if (!await file.exists()) return null;
      final resolved = await file.resolveSymbolicLinks();
      return p.isWithin(root, resolved) ? resolved : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<RuntimePlayerPauseDetailSnapshot> _buildParty(
    GameState gameState,
    Map<String, _RuntimeSpeciesPresentation> speciesById, {
    required String locale,
    required bool isFrench,
    required ItemCatalogSnapshot itemCatalog,
    required List<RuntimePlayerHeldItemOptionSnapshot> heldItemOptions,
    required RuntimePokemonSummaryMediaResolver mediaResolver,
    RuntimeMoveCatalog? moveCatalog,
  }) async {
    final mediaIdentities = {
      for (final pokemon in gameState.party.members)
        pokemon: RuntimePokemonMediaIdentity(
          speciesId: pokemon.speciesId,
          formId: pokemon.formId.trim().isEmpty ? null : pokemon.formId,
          defaultFormId: speciesById[pokemon.speciesId]?.defaultFormId,
          gender: pokemon.gender,
          isShiny: pokemon.isShiny,
          mediaRef: speciesById[pokemon.speciesId]?.mediaRef,
        ),
    };
    final mediaEntries = await Future.wait(
      mediaIdentities.entries.map((entry) async => MapEntry(
            entry.key,
            await mediaResolver.resolve(entry.value),
          )),
    );
    final media = Map.fromEntries(mediaEntries);
    final summaryBuilder = runtimePokemonSummaryBuilderFor(
      locale: locale,
      speciesLabelFor: (speciesId) =>
          speciesById[speciesId]?.nameFor(locale) ?? _humanize(speciesId),
      calculatedStatsFor: (pokemon) =>
          speciesById[pokemon.speciesId]?.calculatedStatsFor(pokemon),
      itemLabelFor: (itemId) => itemCatalog.definitionFor(itemId)?.displayName,
      moveFor: moveCatalog?.lookup,
      mediaIdentityFor: (pokemon) => mediaIdentities[pokemon]!,
      mediaFor: (pokemon) => media[pokemon]!,
      typeIdsFor: (pokemon) =>
          speciesById[pokemon.speciesId]?.types ?? const [],
    );
    final entries = <RuntimePlayerDetailEntrySnapshot>[];
    for (var index = 0; index < gameState.party.members.length; index++) {
      final pokemon = gameState.party.members[index];
      final species = speciesById[pokemon.speciesId];
      final persistedHpFloor = pokemon.currentHp > 0 ? pokemon.currentHp : 1;
      final calculatedMaxHp = species?.maxHpFor(pokemon);
      final maxHp =
          calculatedMaxHp == null || calculatedMaxHp < persistedHpFloor
              ? persistedHpFloor
              : calculatedMaxHp;
      final currentHp = pokemon.currentHp.clamp(0, maxHp);
      final moveCount = pokemon.knownMoveIds.length;
      final status = pokemon.statusId.trim();
      final speciesLabel =
          species?.nameFor(locale) ?? _humanize(pokemon.speciesId);
      final nickname = pokemon.nickname.trim();
      final origin = pokemon.provenance?.kind;
      final provenanceMap = pokemon.provenance?.mapId.trim() ?? '';
      final heldItemId = pokemon.heldItemId.trim();
      final currentHeldItemLabel = heldItemId.isEmpty
          ? null
          : itemCatalog.definitionFor(heldItemId)?.displayName ??
              (isFrench ? 'Objet tenu inconnu' : 'Unknown held item');
      final availableHeldItems = heldItemOptions
          .where((option) => option.itemTargetId != heldItemId)
          .toList(growable: false);
      final subtitle = isFrench
          ? <String>[
              if (nickname.isNotEmpty) speciesLabel,
              'Niv. ${pokemon.level}',
              'PV $currentHp/$maxHp',
              if (status.isNotEmpty) _humanize(status),
              '$moveCount capacité${moveCount > 1 ? 's' : ''}',
              'Amitié ${pokemon.friendship}/255',
              if (origin != null && origin != PlayerPokemonOriginKind.unknown)
                _playerPokemonOriginLabel(origin, isFrench: true),
              if (provenanceMap.isNotEmpty) _humanize(provenanceMap),
            ].join(' · ')
          : <String>[
              if (nickname.isNotEmpty) speciesLabel,
              'Lv. ${pokemon.level}',
              'HP $currentHp/$maxHp',
              if (status.isNotEmpty) _humanize(status),
              '$moveCount move${moveCount == 1 ? '' : 's'}',
              'Friendship ${pokemon.friendship}/255',
              if (origin != null && origin != PlayerPokemonOriginKind.unknown)
                _playerPokemonOriginLabel(origin, isFrench: false),
              if (provenanceMap.isNotEmpty) _humanize(provenanceMap),
            ].join(' · ');
      entries.add(
        RuntimePlayerDetailEntrySnapshot(
          id: _partyTargetId(pokemon, index),
          title: nickname.isEmpty ? speciesLabel : nickname,
          subtitle: subtitle,
          trailingLabel:
              index == 0 ? (isFrench ? 'En tête' : 'Lead') : '#${index + 1}',
          progress: maxHp <= 0 ? 0 : currentHp / maxHp,
          heldItemAction:
              currentHeldItemLabel == null && availableHeldItems.isEmpty
                  ? null
                  : RuntimePlayerHeldItemActionSnapshot(
                      partyTargetId: _partyTargetId(pokemon, index),
                      currentItemLabel: currentHeldItemLabel,
                      options: availableHeldItems,
                    ),
          pokemonSummary: summaryBuilder.build(
            pokemon,
            targetId: _partyTargetId(pokemon, index),
          ),
        ),
      );
    }
    return RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.party,
      title: isFrench ? 'Équipe' : 'Party',
      entries: entries,
      emptyMessage: isFrench
          ? 'Aucun Pokémon dans l’équipe.'
          : 'There are no Pokémon in the party.',
    );
  }

  List<RuntimePlayerHeldItemOptionSnapshot> _buildHeldItemOptions(
    GameState gameState,
    ItemCatalogSnapshot itemCatalog,
  ) {
    final options = <RuntimePlayerHeldItemOptionSnapshot>[];
    for (final entry
        in gameState.bag.entries.where((entry) => entry.quantity > 0)) {
      final resolution = resolveRuntimeHeldItemEffect(
        itemCatalog: itemCatalog,
        itemId: entry.itemId,
      );
      if (resolution.status != RuntimeHeldItemSupportStatus.supported) continue;
      final definition = itemCatalog.definitionFor(entry.itemId);
      if (definition == null) continue;
      options.add(
        RuntimePlayerHeldItemOptionSnapshot(
          itemTargetId: definition.id,
          label: definition.displayName,
        ),
      );
    }
    return List<RuntimePlayerHeldItemOptionSnapshot>.unmodifiable(options);
  }

  RuntimePlayerPauseDetailSnapshot _buildBag(
    GameState gameState, {
    required bool isFrench,
    required List<RuntimePlayerBagPartyTargetSnapshot> targets,
    required Set<String> evolutionItemIds,
    required _RuntimeMoveMachineAvailability moveMachines,
    required ItemCatalogSnapshot itemCatalog,
    required Map<String, String?> iconPaths,
    required String? currencyLabel,
    required Map<String, _RuntimeSpeciesPresentation> speciesById,
    required RuntimeMoveCatalog? moveCatalog,
  }) {
    final resolver = ItemCapabilityResolver(itemCatalog);
    final entries = gameState.bag.entries
        .where((entry) => entry.quantity > 0)
        .toList(growable: false)
        .asMap()
        .entries
        .map((indexedEntry) {
      final entry = indexedEntry.value;
      final definition = resolver.definitionFor(entry.itemId);
      final capability = resolver.resolveUse(
        itemId: entry.itemId,
        context: ProjectItemUseContext.overworld,
      );
      final effect = capability.use?.effect;
      final isKeyItem = definition?.tags.contains('key-item') ?? false;
      final isEvolutionItem = evolutionItemIds.contains(entry.itemId);
      final isMoveMachine = moveMachines.itemIds.contains(entry.itemId);
      final targetKind = isMoveMachine
          ? RuntimePlayerBagUseTargetKind.partyMoveReplacement
          : effect is ProjectItemRestorePpEffectDefinition
              ? RuntimePlayerBagUseTargetKind.partyMove
              : RuntimePlayerBagUseTargetKind.partyMember;
      var usability = resolver.classifyUse(
        itemId: entry.itemId,
        context: ProjectItemUseContext.overworld,
      );
      if (isKeyItem) {
        usability = ItemUsabilityState.passive;
      } else if (isMoveMachine || isEvolutionItem) {
        usability = !isMoveMachine ||
                moveMachines.compatibleItemIds.contains(entry.itemId)
            ? ItemUsabilityState.usable
            : ItemUsabilityState.unavailableInContext;
      } else if (capability.isAvailable &&
          !_isSupportedOverworldEffect(effect)) {
        usability = ItemUsabilityState.unsupportedCapability;
      } else if (capability.isAvailable &&
          effect is ProjectItemRestorePpEffectDefinition &&
          !targets.any((target) => target.moves.isNotEmpty)) {
        usability = ItemUsabilityState.unavailableInContext;
      } else if (capability.isAvailable && targets.isEmpty) {
        usability = ItemUsabilityState.unavailableInContext;
      }
      final unavailableReason = _bagUnavailableReason(
        usability,
        isFrench: isFrench,
        isKeyItem: isKeyItem,
        isMoveMachine: isMoveMachine,
      );
      return RuntimePlayerDetailEntrySnapshot(
        id: 'bag.${entry.itemId}',
        title: definition?.displayName ?? _humanize(entry.itemId),
        subtitle: definition == null
            ? (isFrench ? 'Définition invalide' : 'Invalid definition')
            : _bagPocketLabel(definition.pocketId, isFrench: isFrench),
        trailingLabel: '×${entry.quantity}',
        bagItem: RuntimePlayerBagItemSnapshot(
          itemId: entry.itemId,
          quantity: entry.quantity,
          sortOrder: indexedEntry.key,
          pocketId: definition?.pocketId,
          description: definition?.description,
          iconFilePath: iconPaths[entry.itemId],
        ),
        bagAction: RuntimePlayerBagItemActionSnapshot(
          itemTargetId: entry.itemId,
          targetKind: targetKind,
          usability: usability,
          isEnabled: usability == ItemUsabilityState.usable,
          unavailableReason: unavailableReason,
          learnedMoveLabel: definition?.machine == null
              ? null
              : moveCatalog?.lookup(definition!.machine!.moveId)?.name ??
                  _humanize(definition!.machine!.moveId),
          unavailablePartyTargetReasons: _unavailableBagTargets(
            gameState,
            itemId: entry.itemId,
            use: capability.use,
            isMoveMachine: isMoveMachine,
            moveMachines: moveMachines,
            speciesById: speciesById,
            moveCatalog: moveCatalog,
            isFrench: isFrench,
          ),
          eligiblePartyTargetIds: isMoveMachine
              ? moveMachines.eligiblePartyTargetIdsFor(entry.itemId)
              : null,
        ),
      );
    }).toList(growable: false);
    return RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: isFrench ? 'Sac' : 'Bag',
      entries: entries,
      bagTargets: targets,
      bagMoney: gameState.trainerProfile.money,
      bagCurrencyLabel: currencyLabel,
      bagPockets: [
        for (final pocketId
            in itemCatalog.definitions.map((item) => item.pocketId).toSet())
          RuntimePlayerBagPocketSnapshot(
            id: pocketId,
            label: _bagPocketLabel(pocketId, isFrench: isFrench),
          ),
      ],
      emptyMessage:
          isFrench ? 'Le sac est vide.' : 'There are no items in the bag.',
    );
  }

  bool _isSupportedOverworldEffect(ProjectItemEffectDefinition? effect) {
    return effect is ProjectItemHealHpEffectDefinition ||
        effect is ProjectItemCureStatusEffectDefinition ||
        effect is ProjectItemReviveEffectDefinition ||
        effect is ProjectItemRestorePpEffectDefinition;
  }

  String? _bagUnavailableReason(
    ItemUsabilityState usability, {
    required bool isFrench,
    required bool isKeyItem,
    required bool isMoveMachine,
  }) {
    return switch (usability) {
      ItemUsabilityState.usable => null,
      ItemUsabilityState.passive => isKeyItem
          ? isFrench
              ? 'Cet objet clé s’utilise automatiquement et n’est pas consommé.'
              : 'This key item is used automatically and is not consumed.'
          : isFrench
              ? 'Cet objet est passif et ne s’utilise pas depuis le sac.'
              : 'This item is passive and cannot be used from the bag.',
      ItemUsabilityState.unavailableInContext => isMoveMachine
          ? isFrench
              ? 'Aucun Pokémon de l’équipe n’est compatible.'
              : 'No party Pokémon is compatible.'
          : isFrench
              ? 'Cet objet n’est pas utilisable dans ce contexte.'
              : 'This item cannot be used in this context.',
      ItemUsabilityState.invalidDefinition => isFrench
          ? 'La définition de cet objet est invalide ou absente.'
          : 'This item definition is invalid or missing.',
      ItemUsabilityState.unsupportedCapability => isFrench
          ? 'Cette capacité d’objet n’est pas encore prise en charge.'
          : 'This item capability is not supported yet.',
    };
  }

  Future<_RuntimeMoveMachineAvailability> _loadMoveMachineAvailability(
    GameState gameState,
    Map<String, _RuntimeSpeciesPresentation> speciesById, {
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required ItemCatalogSnapshot itemCatalog,
  }) async {
    final loader = RuntimeMoveMachineLoader();
    final itemIds = <String>{};
    final compatibleItemIds = <String>{};
    final eligiblePartyTargetIdsByItemId = <String, Set<String>>{};
    final requiresMoveReplacementTargetIds = <String>{};
    for (final entry
        in gameState.bag.entries.where((entry) => entry.quantity > 0)) {
      try {
        final machine = itemCatalog.definitionFor(entry.itemId)?.machine;
        if (machine == null) continue;
        itemIds.add(entry.itemId);
        for (final partyEntry in gameState.party.members.asMap().entries) {
          final pokemon = partyEntry.value;
          final candidate =
              await loader.learnsetLoader.loadMoveMachineCandidate(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            itemId: entry.itemId,
            moveId: machine.moveId,
            machineKind: machine.kind.name,
            consumable: machine.consumable,
            speciesRef: speciesById[pokemon.speciesId]?.learnsetRef ??
                pokemon.speciesId,
            fallbackSpeciesId: pokemon.speciesId,
          );
          if (candidate != null &&
              !pokemon.knownMoveIds.contains(candidate.moveId)) {
            final preview = const PokemonMoveMachineService().apply(
              gameState,
              ruleset: pokemonConfig.ruleset,
              partyIndex: partyEntry.key,
              candidate: candidate,
              decision: const PokemonMoveMachineDecision.learn(),
              itemCatalog: itemCatalog,
            );
            if (preview.status ==
                PokemonMoveMachineUseStatus.replacementRequired) {
              requiresMoveReplacementTargetIds
                  .add(_partyTargetId(pokemon, partyEntry.key));
            }
            compatibleItemIds.add(entry.itemId);
            eligiblePartyTargetIdsByItemId
                .putIfAbsent(entry.itemId, () => <String>{})
                .add(_partyTargetId(pokemon, partyEntry.key));
          }
        }
      } on Object {
        // One malformed optional machine stays disabled without hiding the bag.
      }
    }
    return _RuntimeMoveMachineAvailability(
      itemIds: itemIds,
      compatibleItemIds: compatibleItemIds,
      requiresMoveReplacementTargetIds: requiresMoveReplacementTargetIds,
      eligiblePartyTargetIdsByItemId: eligiblePartyTargetIdsByItemId,
    );
  }

  Future<Set<String>> _loadEvolutionItemIds(
    GameState gameState, {
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    final ownedItemIds = gameState.bag.entries
        .where((entry) => entry.quantity > 0)
        .map((entry) => entry.itemId)
        .toSet();
    if (ownedItemIds.isEmpty) return const <String>{};
    final itemIds = <String>{};
    final loadedSpeciesIds = <String>{};
    final loader = RuntimePokemonEvolutionLoader();
    for (final pokemon in gameState.party.members) {
      if (!loadedSpeciesIds.add(pokemon.speciesId)) continue;
      try {
        final candidates = <PokemonEvolutionCandidate>[];
        for (final itemId in ownedItemIds) {
          candidates.addAll(await loader.loadItemUseCandidates(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            sourceSpeciesId: pokemon.speciesId,
            itemId: itemId,
          ));
        }
        itemIds.addAll(
          candidates
              .where(
                (candidate) => candidate.isEligible(
                  pokemon,
                  trigger: PokemonEvolutionTrigger.itemUse(
                    candidate.condition.itemId!,
                  ),
                ),
              )
              .map((candidate) => candidate.condition.itemId!),
        );
      } on Object {
        // Pause data remains available when optional evolution data is absent.
      }
    }
    return Set<String>.unmodifiable(itemIds);
  }

  List<RuntimePlayerBagPartyTargetSnapshot> _buildBagTargets(
    RuntimePlayerPauseDetailSnapshot party, {
    required bool isFrench,
    required _RuntimeMoveMachineAvailability moveMachines,
  }) {
    return party.entries.map((entry) {
      final summary = entry.pokemonSummary!;
      return RuntimePlayerBagPartyTargetSnapshot(
        targetId: entry.id,
        label: summary.displayLabel,
        pokemonSummary: summary,
        requiresMoveReplacement:
            moveMachines.requiresMoveReplacementTargetIds.contains(entry.id),
        subtitle: isFrench
            ? 'Niv. ${summary.level} · PV ${summary.currentHp}/${summary.maxHp}'
            : 'Lv. ${summary.level} · HP ${summary.currentHp}/${summary.maxHp}',
        moves: summary.moves.map((move) {
          return RuntimePlayerBagMoveTargetSnapshot(
            targetId: move.moveId,
            label: move.label,
            subtitle: move.currentPp == null
                ? null
                : 'PP ${move.currentPp}/${move.maxPp ?? '—'}',
          );
        }).toList(growable: false),
      );
    }).toList(growable: false);
  }

  Map<String, String> _unavailableBagTargets(
    GameState gameState, {
    required String itemId,
    required ProjectItemUseDefinition? use,
    required bool isMoveMachine,
    required _RuntimeMoveMachineAvailability moveMachines,
    required Map<String, _RuntimeSpeciesPresentation> speciesById,
    required RuntimeMoveCatalog? moveCatalog,
    required bool isFrench,
  }) {
    final reasons = <String, String>{};
    for (final entry in gameState.party.members.asMap().entries) {
      final pokemon = entry.value;
      final targetId = _partyTargetId(pokemon, entry.key);
      if (isMoveMachine) {
        if (!moveMachines
            .eligiblePartyTargetIdsFor(itemId)
            .contains(targetId)) {
          reasons[targetId] = isFrench
              ? 'Incompatible avec cette capacité.'
              : 'Cannot learn this move.';
        }
        continue;
      }
      if (use == null || !_isSupportedOverworldEffect(use.effect)) continue;
      final maxHp = speciesById[pokemon.speciesId]?.maxHpFor(pokemon);
      if (maxHp == null) continue;
      final maxPpByMoveId = <String, int>{
        for (final moveId in pokemon.knownMoveIds)
          if (moveCatalog?.lookup(moveId) case final move?) moveId: move.pp,
      };
      final moves = use.target == ProjectItemTargetKind.partyMove
          ? pokemon.knownMoveIds.cast<String?>()
          : <String?>[null];
      final applications = moves
          .map((moveId) => applyPlayerItemEffect(
                pokemon,
                use: use,
                maxHp: maxHp,
                moveId: moveId,
                maxPpByMoveId: maxPpByMoveId,
              ))
          .toList(growable: false);
      if (applications.any((result) => result.isApplied)) continue;
      final hasNoEffect = applications
          .any((result) => result.failure == PlayerItemUseFailure.noEffect);
      reasons[targetId] = hasNoEffect
          ? (isFrench
              ? 'Cet objet n’aurait aucun effet.'
              : 'This item would have no effect.')
          : (isFrench
              ? 'Cet objet ne convient pas à cette cible.'
              : 'This item cannot be used on this target.');
    }
    return reasons;
  }

  Future<RuntimePlayerPauseDetailSnapshot> _buildPokedex(
    GameState gameState,
    List<_RuntimeSpeciesPresentation> species, {
    required String locale,
    required bool isFrench,
    required RuntimePokemonSummaryMediaResolver mediaResolver,
    required bool catalogInvalid,
  }) async {
    if (catalogInvalid) {
      return RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
        emptyMessage: isFrench
            ? 'Le catalogue du Pokédex ne peut pas être lu. Vérifiez la configuration du jeu.'
            : 'The Pokédex catalog could not be read. Check the game configuration.',
      );
    }
    final caught = <String>{
      ...gameState.progression.caughtSpeciesIds,
      ...gameState.party.members.map((pokemon) => pokemon.speciesId),
      ...gameState.pokemonStorage.storedPokemon
          .map((pokemon) => pokemon.speciesId),
    };
    final seen = <String>{
      ...gameState.progression.seenSpeciesIds,
      ...caught,
    };
    RuntimePokemonMediaIdentity identityFor(
            _RuntimeSpeciesPresentation entry) =>
        RuntimePokemonMediaIdentity(
          speciesId: entry.id,
          formId: entry.defaultFormId,
          defaultFormId: entry.defaultFormId,
          mediaRef: entry.mediaRef,
        );
    final revealed = species
        .where((entry) => entry.enabled && seen.contains(entry.id))
        .toList(growable: false);
    final mediaById = <String, RuntimePokemonSummaryMediaSnapshot>{};
    for (var offset = 0; offset < revealed.length; offset += 16) {
      mediaById.addEntries(await Future.wait(revealed.skip(offset).take(16).map(
            (entry) async => MapEntry(
              entry.id,
              await mediaResolver.resolve(identityFor(entry)),
            ),
          )));
    }
    final entries = <RuntimePlayerDetailEntrySnapshot>[];
    for (final entry in species.where((entry) => entry.enabled)) {
      final isCaught = caught.contains(entry.id);
      final isSeen = seen.contains(entry.id);
      final identity = isSeen ? identityFor(entry) : null;
      final media =
          mediaById[entry.id] ?? const RuntimePokemonSummaryMediaSnapshot();
      final knowledge = isFrench
          ? (isCaught ? 'Capturé' : (isSeen ? 'Vu' : 'Inconnu'))
          : (isCaught ? 'Caught' : (isSeen ? 'Seen' : 'Unknown'));
      final dexLabel = entry.nationalDex == null
          ? '---'
          : entry.nationalDex.toString().padLeft(3, '0');
      entries.add(
        RuntimePlayerDetailEntrySnapshot(
          id: entry.id,
          title: isSeen ? entry.nameFor(locale) : '???',
          subtitle: <String>[
            '#$dexLabel',
            knowledge,
            if (isSeen && entry.types.isNotEmpty)
              entry.types.map(_humanize).join(' / '),
          ].join(' · '),
          trailingLabel: isCaught ? '●' : (isSeen ? '○' : null),
          pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
            knowledge: isCaught
                ? RuntimePlayerPokedexKnowledge.caught
                : isSeen
                    ? RuntimePlayerPokedexKnowledge.seen
                    : RuntimePlayerPokedexKnowledge.unknown,
            nationalDex: entry.nationalDex,
            identity: identity,
            media: media,
            description: isSeen ? entry.description : null,
            typeIds: isSeen ? entry.types : const [],
          ),
        ),
      );
    }
    return RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.pokedex,
      title: 'Pokédex',
      entries: entries,
      emptyMessage: isFrench
          ? 'Aucune espèce n’est disponible dans ce projet.'
          : 'No species are available in this project.',
    );
  }

  Future<_RuntimeSpeciesCatalog> _loadSpeciesCatalog({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    if (!pokemonConfig.enabled) return const _RuntimeSpeciesCatalog();
    final speciesDirectory = _resolveProjectDirectory(
      projectRootDirectory,
      pokemonConfig.speciesDir,
    );
    if (speciesDirectory == null) {
      return const _RuntimeSpeciesCatalog(invalid: true);
    }
    try {
      if (!await speciesDirectory.exists()) {
        _speciesCatalogByDirectory.remove(speciesDirectory.path);
        return const _RuntimeSpeciesCatalog(invalid: true);
      }
      final files = <File>[];
      await for (final entity in speciesDirectory.list(followLinks: false)) {
        if (entity is File &&
            p.extension(entity.path).toLowerCase() == '.json') {
          files.add(entity);
        }
      }
      files.sort((left, right) => left.path.compareTo(right.path));
      // Le catalogue complet était relu et re-parsé séquentiellement à chaque
      // ouverture du menu pause (et après chaque usage d'objet du sac). La
      // signature (chemin, mtime, taille) de chaque fichier garantit qu'une
      // édition des données sur disque invalide le cache.
      final signatureBuffer = StringBuffer();
      for (var offset = 0;
          offset < files.length;
          offset += _speciesCatalogBatchSize) {
        final batch = files
            .skip(offset)
            .take(_speciesCatalogBatchSize)
            .toList(growable: false);
        final stats = await Future.wait(batch.map((file) => file.stat()));
        for (var index = 0; index < batch.length; index++) {
          signatureBuffer
            ..write(batch[index].path)
            ..write('|')
            ..write(stats[index].modified.microsecondsSinceEpoch)
            ..write('|')
            ..write(stats[index].size)
            ..write(';');
        }
      }
      final signature = signatureBuffer.toString();
      final cached = _speciesCatalogByDirectory.remove(speciesDirectory.path);
      if (cached != null && cached.signature == signature) {
        _speciesCatalogByDirectory[speciesDirectory.path] = cached;
        return cached.catalog;
      }
      final presentations = <_RuntimeSpeciesPresentation?>[];
      for (var offset = 0;
          offset < files.length;
          offset += _speciesCatalogBatchSize) {
        presentations.addAll(await Future.wait(files
            .skip(offset)
            .take(_speciesCatalogBatchSize)
            .map(_readSpeciesPresentation)));
      }
      final result = <_RuntimeSpeciesPresentation>[
        for (final presentation in presentations)
          if (presentation != null) presentation,
      ];
      result.sort((left, right) {
        final leftDex = left.nationalDex ?? 1 << 30;
        final rightDex = right.nationalDex ?? 1 << 30;
        final byDex = leftDex.compareTo(rightDex);
        return byDex != 0 ? byDex : left.id.compareTo(right.id);
      });
      final catalog = _RuntimeSpeciesCatalog(
        entries: List<_RuntimeSpeciesPresentation>.unmodifiable(result),
        invalid: presentations.any((entry) => entry == null) ||
            result.map((entry) => entry.id).toSet().length != result.length,
      );
      if (!catalog.invalid) {
        _speciesCatalogByDirectory[speciesDirectory.path] =
            _CachedSpeciesCatalog(signature: signature, catalog: catalog);
        while (_speciesCatalogByDirectory.length > _speciesCatalogCacheLimit) {
          _speciesCatalogByDirectory
              .remove(_speciesCatalogByDirectory.keys.first);
        }
      }
      return catalog;
    } on FileSystemException {
      _speciesCatalogByDirectory.remove(speciesDirectory.path);
      return const _RuntimeSpeciesCatalog(invalid: true);
    }
  }

  Future<_RuntimeSpeciesPresentation?> _readSpeciesPresentation(
    FileSystemEntity entity,
  ) async {
    if (entity is! File || p.extension(entity.path).toLowerCase() != '.json') {
      return null;
    }
    try {
      final decoded = jsonDecode(await entity.readAsString());
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      final id = json['id'];
      if (id is! String || id.trim().isEmpty) return null;
      final rawNames = json['names'];
      final names = <String, String>{};
      if (rawNames is Map) {
        for (final entry in rawNames.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key is String && value is String && value.trim().isNotEmpty) {
            names[key.toLowerCase()] = value.trim();
          }
        }
      }
      final rawTyping = json['typing'];
      final rawTypes = rawTyping is Map ? rawTyping['types'] : null;
      final types = rawTypes is List
          ? rawTypes
              .whereType<String>()
              .map((type) => type.trim())
              .where((type) => type.isNotEmpty)
              .toList(growable: false)
          : const <String>[];
      final rawBaseStats = json['baseStats'];
      final baseStats =
          rawBaseStats is Map ? Map<String, dynamic>.from(rawBaseStats) : null;
      final rawClassification = json['classification'];
      final enabled = rawClassification is! Map ||
          rawClassification['isEnabledInProject'] != false;
      return _RuntimeSpeciesPresentation(
        id: id.trim(),
        nationalDex:
            json['nationalDex'] is int ? json['nationalDex'] as int : null,
        names: names,
        types: types,
        enabled: enabled,
        baseStats: baseStats,
        learnsetRef: _readNestedString(json, 'refs', 'learnset'),
        mediaRef: _readNestedString(json, 'refs', 'media'),
        defaultFormId: _readNestedString(json, 'forms', 'formId'),
        description: _readNestedString(json, 'dexContent', 'flavorText'),
      );
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}

const _speciesCatalogBatchSize = 32;
const _speciesCatalogCacheLimit = 4;

/// Cache process-level du catalogue d'espèces présenté par le menu pause,
/// clé = dossier, validé par la signature stat de ses fichiers.
final Map<String, _CachedSpeciesCatalog> _speciesCatalogByDirectory =
    <String, _CachedSpeciesCatalog>{};

final class _CachedSpeciesCatalog {
  const _CachedSpeciesCatalog({
    required this.signature,
    required this.catalog,
  });

  final String signature;
  final _RuntimeSpeciesCatalog catalog;
}

final class _RuntimeSpeciesCatalog {
  const _RuntimeSpeciesCatalog({this.entries = const [], this.invalid = false});

  final List<_RuntimeSpeciesPresentation> entries;
  final bool invalid;
}

final class _RuntimeSpeciesPresentation {
  const _RuntimeSpeciesPresentation({
    required this.id,
    required this.nationalDex,
    required this.names,
    required this.types,
    required this.enabled,
    required this.baseStats,
    required this.learnsetRef,
    required this.mediaRef,
    required this.defaultFormId,
    required this.description,
  });

  final String id;
  final int? nationalDex;
  final Map<String, String> names;
  final List<String> types;
  final bool enabled;
  final Map<String, dynamic>? baseStats;
  final String? learnsetRef;
  final String? mediaRef;
  final String? defaultFormId;
  final String? description;

  String nameFor(String locale) {
    final normalized = locale.toLowerCase().split(RegExp('[-_]')).first;
    return names[normalized] ??
        names['en'] ??
        names['fr'] ??
        (names.isEmpty ? _humanize(id) : names.values.first);
  }

  int? maxHpFor(PlayerPokemon pokemon) => calculatedStatsFor(pokemon)?.maxHp;

  PokemonCalculatedStats? calculatedStatsFor(PlayerPokemon pokemon) {
    final stats = baseStats;
    if (stats == null) return null;
    final hp = stats['hp'];
    final attack = stats['atk'];
    final defense = stats['def'];
    final specialAttack = stats['spa'];
    final specialDefense = stats['spd'];
    final speed = stats['spe'];
    if (hp is! int ||
        attack is! int ||
        defense is! int ||
        specialAttack is! int ||
        specialDefense is! int ||
        speed is! int) {
      return null;
    }
    try {
      return const PokemonStatCalculator().calculate(
        baseStats: PokemonBaseStats(
          hp: hp,
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        ),
        ivs: pokemon.ivs,
        evs: pokemon.evs,
        level: pokemon.level,
        naturePolicy: PokemonNatureStatPolicy.canonical,
        natureId: pokemon.natureId,
      );
    } on Object {
      return null;
    }
  }
}

final class _RuntimeMoveMachineAvailability {
  _RuntimeMoveMachineAvailability({
    required Set<String> itemIds,
    required Set<String> compatibleItemIds,
    required Set<String> requiresMoveReplacementTargetIds,
    required Map<String, Set<String>> eligiblePartyTargetIdsByItemId,
  })  : itemIds = Set<String>.unmodifiable(itemIds),
        compatibleItemIds = Set<String>.unmodifiable(compatibleItemIds),
        requiresMoveReplacementTargetIds =
            Set.unmodifiable(requiresMoveReplacementTargetIds),
        eligiblePartyTargetIdsByItemId = Map<String, Set<String>>.unmodifiable(
          eligiblePartyTargetIdsByItemId.map(
            (itemId, targetIds) => MapEntry(
              itemId,
              Set<String>.unmodifiable(targetIds),
            ),
          ),
        );

  final Set<String> itemIds;
  final Set<String> compatibleItemIds;
  final Set<String> requiresMoveReplacementTargetIds;
  final Map<String, Set<String>> eligiblePartyTargetIdsByItemId;

  Set<String> eligiblePartyTargetIdsFor(String itemId) =>
      eligiblePartyTargetIdsByItemId[itemId] ?? const <String>{};
}

String? _readNestedString(
  Map<String, dynamic> json,
  String objectKey,
  String valueKey,
) {
  final rawObject = json[objectKey];
  if (rawObject is! Map) return null;
  final rawValue = rawObject[valueKey];
  if (rawValue is! String || rawValue.trim().isEmpty) return null;
  return rawValue.trim();
}

String _partyTargetId(PlayerPokemon pokemon, int index) {
  final individualId = pokemon.individualId.trim();
  return individualId.isEmpty ? 'party.$index' : 'pokemon.$individualId';
}

Directory? _resolveProjectDirectory(String projectRoot, String relativePath) {
  final normalizedRelative = relativePath.trim().replaceAll('\\', '/');
  if (normalizedRelative.isEmpty ||
      p.isAbsolute(normalizedRelative) ||
      p.split(normalizedRelative).contains('..')) {
    return null;
  }
  final normalizedRoot = p.normalize(p.absolute(projectRoot));
  final resolved = p.normalize(p.join(normalizedRoot, normalizedRelative));
  if (resolved != normalizedRoot && !p.isWithin(normalizedRoot, resolved)) {
    return null;
  }
  return Directory(resolved);
}

String _bagPocketLabel(String pocketId, {required bool isFrench}) =>
    switch (pocketId) {
      'medicine' => isFrench ? 'Soins' : 'Medicine',
      'items' => isFrench ? 'Objets' : 'Items',
      'balls' => 'Balls',
      'held-items' => isFrench ? 'Objets tenus' : 'Held items',
      'evolution-items' => isFrench ? 'Objets d’évolution' : 'Evolution items',
      'machines' => isFrench ? 'CT/CS' : 'TMs/HMs',
      'key-items' => isFrench ? 'Objets clés' : 'Key items',
      'battle-items' => isFrench ? 'Objets de combat' : 'Battle items',
      _ => _humanize(pocketId),
    };

String _humanize(String value) {
  final words = value
      .trim()
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return value;
  return words
      .map(
        (word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _playerPokemonOriginLabel(
  PlayerPokemonOriginKind kind, {
  required bool isFrench,
}) =>
    switch (kind) {
      PlayerPokemonOriginKind.captured => isFrench ? 'Capturé' : 'Captured',
      PlayerPokemonOriginKind.gift => isFrench ? 'Cadeau' : 'Gift',
      PlayerPokemonOriginKind.starter => 'Starter',
      PlayerPokemonOriginKind.trade => isFrench ? 'Échange' : 'Trade',
      PlayerPokemonOriginKind.scripted => isFrench ? 'Événement' : 'Event',
      PlayerPokemonOriginKind.unknown => isFrench ? 'Inconnue' : 'Unknown',
    };
