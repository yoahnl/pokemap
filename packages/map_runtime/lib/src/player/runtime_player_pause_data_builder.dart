import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import '../application/runtime_pokemon_evolution_loader.dart';
import '../application/runtime_item_catalog_loader.dart';
import '../application/runtime_battle_combatant_seed_builder.dart';
import '../application/runtime_move_machine_loader.dart';
import 'runtime_player_pause_data.dart';

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
    bool mapEnabled = false,
    List<ProjectMapEntry> projectMaps = const <ProjectMapEntry>[],
    ItemCatalogSnapshot? itemCatalog,
  }) async {
    final resolvedItemCatalog = itemCatalog ??
        await const RuntimeItemCatalogLoader().loadSnapshot(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
        );
    final species = await _loadSpeciesCatalog(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final speciesById = <String, _RuntimeSpeciesPresentation>{
      for (final entry in species) entry.id: entry,
    };
    final isFrench = locale.toLowerCase().startsWith('fr');
    final bagTargets = _buildBagTargets(
      gameState,
      speciesById,
      locale: locale,
      isFrench: isFrench,
    );
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

    return immutableRuntimePlayerPauseDetails(
      <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
        RuntimePlayerPauseSection.party: _buildParty(
          gameState,
          speciesById,
          locale: locale,
          isFrench: isFrench,
          itemCatalog: resolvedItemCatalog,
          heldItemOptions: heldItemOptions,
        ),
        RuntimePlayerPauseSection.bag: _buildBag(
          gameState,
          isFrench: isFrench,
          targets: bagTargets,
          evolutionItemIds: evolutionItemIds,
          moveMachines: moveMachines,
          itemCatalog: resolvedItemCatalog,
        ),
        if (pokemonConfig.enabled)
          RuntimePlayerPauseSection.pokedex: _buildPokedex(
            gameState,
            species,
            locale: locale,
            isFrench: isFrench,
          ),
        if (mapEnabled)
          RuntimePlayerPauseSection.map: _buildMap(
            gameState,
            projectMaps,
            isFrench: isFrench,
          ),
      },
    );
  }

  RuntimePlayerPauseDetailSnapshot _buildMap(
    GameState gameState,
    List<ProjectMapEntry> projectMaps, {
    required bool isFrench,
  }) {
    final locations = projectRuntimeMapLocations(
      maps: projectMaps,
      gameState: gameState,
    );
    return RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.map,
      title: isFrench ? 'Carte' : 'Map',
      message: isFrench
          ? 'Carte consultable uniquement : le voyage rapide sera ajouté '
              'avec la mécanique Vol.'
          : 'View-only map: fast travel will be added with the Fly mechanic.',
      entries: locations.map((location) {
        final isCurrent = location.status == RuntimeMapLocationStatus.current;
        final isDiscovered =
            location.status == RuntimeMapLocationStatus.discovered;
        return RuntimePlayerDetailEntrySnapshot(
          id: 'map.${location.mapId}',
          title: location.displayName.isEmpty
              ? switch (location.status) {
                  RuntimeMapLocationStatus.current =>
                    isFrench ? 'Zone actuelle' : 'Current area',
                  RuntimeMapLocationStatus.discovered =>
                    isFrench ? 'Zone découverte' : 'Discovered area',
                  RuntimeMapLocationStatus.unknown => '???',
                }
              : location.displayName,
          subtitle: switch (location.status) {
            RuntimeMapLocationStatus.current =>
              isFrench ? 'Position actuelle' : 'Current location',
            RuntimeMapLocationStatus.discovered =>
              isFrench ? 'Zone découverte' : 'Discovered area',
            RuntimeMapLocationStatus.unknown =>
              isFrench ? 'Zone non découverte' : 'Undiscovered area',
          },
          trailingLabel: isCurrent
              ? (isFrench ? 'Ici' : 'Here')
              : isDiscovered
                  ? (isFrench ? 'Connue' : 'Known')
                  : (isFrench ? 'Inconnue' : 'Unknown'),
        );
      }).toList(growable: false),
      emptyMessage: isFrench
          ? 'Aucune zone n’est disponible sur cette carte.'
          : 'No area is available on this map.',
    );
  }

  RuntimePlayerPauseDetailSnapshot _buildParty(
    GameState gameState,
    Map<String, _RuntimeSpeciesPresentation> speciesById, {
    required String locale,
    required bool isFrench,
    required ItemCatalogSnapshot itemCatalog,
    required List<RuntimePlayerHeldItemOptionSnapshot> heldItemOptions,
  }) {
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
          id: 'party.$index',
          title: nickname.isEmpty ? speciesLabel : nickname,
          subtitle: subtitle,
          trailingLabel:
              index == 0 ? (isFrench ? 'En tête' : 'Lead') : '#${index + 1}',
          progress: maxHp <= 0 ? 0 : currentHp / maxHp,
          heldItemAction:
              currentHeldItemLabel == null && availableHeldItems.isEmpty
                  ? null
                  : RuntimePlayerHeldItemActionSnapshot(
                      partyTargetId: 'party.$index',
                      currentItemLabel: currentHeldItemLabel,
                      options: availableHeldItems,
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
  }) {
    final resolver = ItemCapabilityResolver(itemCatalog);
    final entries =
        gameState.bag.entries.where((entry) => entry.quantity > 0).map((entry) {
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
            : _humanize(definition.pocketId),
        trailingLabel: '×${entry.quantity}',
        bagAction: RuntimePlayerBagItemActionSnapshot(
          itemTargetId: entry.itemId,
          targetKind: targetKind,
          usability: usability,
          isEnabled: usability == ItemUsabilityState.usable,
          unavailableReason: unavailableReason,
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
            compatibleItemIds.add(entry.itemId);
            eligiblePartyTargetIdsByItemId
                .putIfAbsent(entry.itemId, () => <String>{})
                .add('party.${partyEntry.key}');
          }
        }
      } on Object {
        // One malformed optional machine stays disabled without hiding the bag.
      }
    }
    return _RuntimeMoveMachineAvailability(
      itemIds: itemIds,
      compatibleItemIds: compatibleItemIds,
      eligiblePartyTargetIdsByItemId: eligiblePartyTargetIdsByItemId,
    );
  }

  Future<Set<String>> _loadEvolutionItemIds(
    GameState gameState, {
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    final itemIds = <String>{};
    final loadedSpeciesIds = <String>{};
    final loader = RuntimePokemonEvolutionLoader();
    for (final pokemon in gameState.party.members) {
      if (!loadedSpeciesIds.add(pokemon.speciesId)) continue;
      try {
        final candidates = await loader.loadItemUseCandidates(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          sourceSpeciesId: pokemon.speciesId,
        );
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
    GameState gameState,
    Map<String, _RuntimeSpeciesPresentation> speciesById, {
    required String locale,
    required bool isFrench,
  }) {
    return gameState.party.members.asMap().entries.map((entry) {
      final index = entry.key;
      final pokemon = entry.value;
      final species = speciesById[pokemon.speciesId];
      final persistedHpFloor = pokemon.currentHp > 0 ? pokemon.currentHp : 1;
      final calculatedMaxHp = species?.maxHpFor(pokemon);
      final maxHp =
          calculatedMaxHp == null || calculatedMaxHp < persistedHpFloor
              ? persistedHpFloor
              : calculatedMaxHp;
      final currentHp = pokemon.currentHp.clamp(0, maxHp);
      return RuntimePlayerBagPartyTargetSnapshot(
        targetId: 'party.$index',
        label: species?.nameFor(locale) ?? _humanize(pokemon.speciesId),
        subtitle: isFrench
            ? 'Niv. ${pokemon.level} · PV $currentHp/$maxHp'
            : 'Lv. ${pokemon.level} · HP $currentHp/$maxHp',
        moves: pokemon.knownMoveIds.map((moveId) {
          final currentPp = pokemon.currentPpByMoveId?[moveId];
          return RuntimePlayerBagMoveTargetSnapshot(
            targetId: moveId,
            label: _humanize(moveId),
            subtitle: currentPp == null
                ? null
                : (isFrench
                    ? 'PP actuels : $currentPp'
                    : 'Current PP: $currentPp'),
          );
        }).toList(growable: false),
      );
    }).toList(growable: false);
  }

  RuntimePlayerPauseDetailSnapshot _buildPokedex(
    GameState gameState,
    List<_RuntimeSpeciesPresentation> species, {
    required String locale,
    required bool isFrench,
  }) {
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
    final entries = <RuntimePlayerDetailEntrySnapshot>[];
    for (final entry in species.where((entry) => entry.enabled)) {
      final isCaught = caught.contains(entry.id);
      final isSeen = seen.contains(entry.id);
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

  Future<List<_RuntimeSpeciesPresentation>> _loadSpeciesCatalog({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    if (!pokemonConfig.enabled) return const <_RuntimeSpeciesPresentation>[];
    final speciesDirectory = _resolveProjectDirectory(
      projectRootDirectory,
      pokemonConfig.speciesDir,
    );
    if (speciesDirectory == null) {
      return const <_RuntimeSpeciesPresentation>[];
    }
    try {
      if (!await speciesDirectory.exists()) {
        return const <_RuntimeSpeciesPresentation>[];
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
      for (final file in files) {
        final stat = await file.stat();
        signatureBuffer
          ..write(file.path)
          ..write('|')
          ..write(stat.modified.microsecondsSinceEpoch)
          ..write('|')
          ..write(stat.size)
          ..write(';');
      }
      final signature = signatureBuffer.toString();
      final cached = _speciesCatalogByDirectory[speciesDirectory.path];
      if (cached != null && cached.signature == signature) {
        return cached.catalog;
      }
      final presentations = await Future.wait(
        files.map(_readSpeciesPresentation),
      );
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
      final catalog = List<_RuntimeSpeciesPresentation>.unmodifiable(result);
      _speciesCatalogByDirectory[speciesDirectory.path] =
          _CachedSpeciesCatalog(signature: signature, catalog: catalog);
      return catalog;
    } on FileSystemException {
      return const <_RuntimeSpeciesPresentation>[];
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
      );
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}

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
  final List<_RuntimeSpeciesPresentation> catalog;
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
  });

  final String id;
  final int? nationalDex;
  final Map<String, String> names;
  final List<String> types;
  final bool enabled;
  final Map<String, dynamic>? baseStats;
  final String? learnsetRef;

  String nameFor(String locale) {
    final normalized = locale.toLowerCase().split(RegExp('[-_]')).first;
    return names[normalized] ??
        names['en'] ??
        names['fr'] ??
        (names.isEmpty ? _humanize(id) : names.values.first);
  }

  int? maxHpFor(PlayerPokemon pokemon) {
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
      return const PokemonStatCalculator()
          .calculate(
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
          )
          .maxHp;
    } on Object {
      return null;
    }
  }
}

final class _RuntimeMoveMachineAvailability {
  _RuntimeMoveMachineAvailability({
    required Set<String> itemIds,
    required Set<String> compatibleItemIds,
    required Map<String, Set<String>> eligiblePartyTargetIdsByItemId,
  })  : itemIds = Set<String>.unmodifiable(itemIds),
        compatibleItemIds = Set<String>.unmodifiable(compatibleItemIds),
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
