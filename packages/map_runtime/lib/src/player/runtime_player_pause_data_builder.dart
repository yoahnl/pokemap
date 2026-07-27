import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import '../application/runtime_pokemon_evolution_loader.dart';
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
  }) async {
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

    return immutableRuntimePlayerPauseDetails(
      <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
        RuntimePlayerPauseSection.party: _buildParty(
          gameState,
          speciesById,
          locale: locale,
          isFrench: isFrench,
        ),
        RuntimePlayerPauseSection.bag: _buildBag(
          gameState,
          isFrench: isFrench,
          targets: bagTargets,
          evolutionItemIds: evolutionItemIds,
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

  RuntimePlayerPauseDetailSnapshot _buildBag(
    GameState gameState, {
    required bool isFrench,
    required List<RuntimePlayerBagPartyTargetSnapshot> targets,
    required Set<String> evolutionItemIds,
  }) {
    final entries =
        gameState.bag.entries.where((entry) => entry.quantity > 0).map((entry) {
      final effect =
          const PlayerItemEffectRegistry.mvp().effectFor(entry.itemId);
      final isKeyItem = effect?.kind == PlayerItemEffectKind.keyItem ||
          _isKeyItemCategory(entry.categoryId);
      final isEvolutionItem = evolutionItemIds.contains(entry.itemId);
      final targetKind = effect?.kind == PlayerItemEffectKind.restorePp
          ? RuntimePlayerBagUseTargetKind.partyMove
          : RuntimePlayerBagUseTargetKind.partyMember;
      final unavailableReason = isKeyItem
          ? (isFrench
              ? 'Cet objet clé s’utilise automatiquement et '
                  'n’est pas consommé.'
              : 'This key item is used automatically and is not consumed.')
          : switch (effect?.kind) {
              PlayerItemEffectKind.healHp ||
              PlayerItemEffectKind.cureStatus ||
              PlayerItemEffectKind.revive when targets.isEmpty =>
                isFrench
                    ? 'Aucun Pokémon ne peut être ciblé.'
                    : 'No Pokémon can be targeted.',
              PlayerItemEffectKind.restorePp
                  when !targets.any((target) => target.moves.isNotEmpty) =>
                isFrench
                    ? 'Aucune capacité ne peut être ciblée.'
                    : 'No move can be targeted.',
              PlayerItemEffectKind.ballMetadata => isFrench
                  ? 'Cet objet s’utilise uniquement en combat.'
                  : 'This item can only be used in battle.',
              null when !isEvolutionItem => isFrench
                  ? 'Cet objet n’a pas d’effet utilisable ici.'
                  : 'This item has no usable effect here.',
              _ => null,
            };
      return RuntimePlayerDetailEntrySnapshot(
        id: 'bag.${entry.categoryId}.${entry.itemId}',
        title: _humanize(entry.itemId),
        subtitle: _humanize(entry.categoryId),
        trailingLabel: '×${entry.quantity}',
        bagAction: RuntimePlayerBagItemActionSnapshot(
          itemTargetId: entry.itemId,
          targetKind: targetKind,
          isEnabled: unavailableReason == null,
          unavailableReason: unavailableReason,
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

  bool _isKeyItemCategory(String categoryId) {
    final normalized = categoryId.trim().toLowerCase().replaceAll('_', '-');
    return normalized == 'key-item' ||
        normalized == 'key-items' ||
        normalized == 'important-items';
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
    final result = <_RuntimeSpeciesPresentation>[];
    try {
      if (!await speciesDirectory.exists()) {
        return const <_RuntimeSpeciesPresentation>[];
      }
      await for (final entity in speciesDirectory.list(followLinks: false)) {
        final presentation = await _readSpeciesPresentation(entity);
        if (presentation != null) result.add(presentation);
      }
    } on FileSystemException {
      return const <_RuntimeSpeciesPresentation>[];
    }
    result.sort((left, right) {
      final leftDex = left.nationalDex ?? 1 << 30;
      final rightDex = right.nationalDex ?? 1 << 30;
      final byDex = leftDex.compareTo(rightDex);
      return byDex != 0 ? byDex : left.id.compareTo(right.id);
    });
    return List<_RuntimeSpeciesPresentation>.unmodifiable(result);
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
      );
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}

final class _RuntimeSpeciesPresentation {
  const _RuntimeSpeciesPresentation({
    required this.id,
    required this.nationalDex,
    required this.names,
    required this.types,
    required this.enabled,
    required this.baseStats,
  });

  final String id;
  final int? nationalDex;
  final Map<String, String> names;
  final List<String> types;
  final bool enabled;
  final Map<String, dynamic>? baseStats;

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
