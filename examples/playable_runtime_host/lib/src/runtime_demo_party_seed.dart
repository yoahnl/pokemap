import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const kRuntimeDemoSeedLevel = 25;
const kRuntimeDemoSeedCurrentHp = 60;
const kRuntimeDemoSeedSaveId = 'runtime-host-demo-save';
const kRuntimeDemoMaxPartySize = 6;
const _runtimeDemoSeedBagEntries = <BagEntry>[
  BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
  BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
  BagEntry(itemId: 'super-potion', categoryId: 'medicine', quantity: 6),
  BagEntry(itemId: 'hyper-potion', categoryId: 'medicine', quantity: 6),
];
const _preferredRuntimeDemoSpeciesIds = <String>[
  'squirtle',
  'carapuce',
  'mew',
  'dratini'
];
const _avoidRuntimeDemoSpeciesIds = <String>{
  'abra',
};

class RuntimeDemoPartySeed {
  const RuntimeDemoPartySeed({
    required this.members,
  });

  final List<RuntimeDemoPartyPokemonSeed> members;
}

class RuntimeDemoPartyPokemonSeed {
  const RuntimeDemoPartyPokemonSeed({
    required this.speciesId,
    required this.abilityId,
    required this.gender,
    required this.level,
    required this.currentHp,
    required this.knownMoveIds,
  });

  final String speciesId;
  final String abilityId;
  final String? gender;
  final int level;
  final int currentHp;
  final List<String> knownMoveIds;
}

class RuntimePartyBuilderPokemonOption {
  const RuntimePartyBuilderPokemonOption({
    required this.speciesId,
    required this.displayName,
    required this.abilityId,
    required this.gender,
    required this.availableMoveIds,
    required this.suggestedMoveIds,
    required this.moveDiagnostics,
  });

  final String speciesId;
  final String displayName;
  final String abilityId;
  final String? gender;
  final List<String> availableMoveIds;
  final List<String> suggestedMoveIds;
  final Map<String, RuntimeBattleMoveBridgeDiagnostics> moveDiagnostics;

  List<RuntimeBattleMoveBridgeDiagnostics> get filteredMoveDiagnostics {
    final diagnostics = moveDiagnostics.values
        .where((diagnostic) => !diagnostic.runtimeBridgeable)
        .toList(growable: false);
    return List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(diagnostics);
  }

  List<String> get filteredMoveIds {
    return List<String>.unmodifiable(
      filteredMoveDiagnostics.map((diagnostic) => diagnostic.moveId),
    );
  }

  String get label {
    if (displayName.trim().isEmpty || displayName == speciesId) {
      return speciesId;
    }
    return '$displayName ($speciesId)';
  }
}

SaveData buildRuntimeHostLaunchDemoSaveData({
  required String mapId,
  required RuntimeDemoPartySeed seed,
}) {
  return SaveData(
    saveId: kRuntimeDemoSeedSaveId,
    currentMapId: mapId,
    party: PlayerParty(
      members: seed.members
          .map(
            (member) => PlayerPokemon(
              speciesId: member.speciesId,
              natureId: 'hardy',
              abilityId: member.abilityId,
              gender: member.gender,
              level: member.level,
              knownMoveIds: member.knownMoveIds,
              currentHp: member.currentHp,
            ),
          )
          .toList(growable: false),
    ),
    trainerProfile: const TrainerProfile(name: 'Demo'),
    bag: const Bag(entries: _runtimeDemoSeedBagEntries),
  );
}

Future<List<RuntimePartyBuilderPokemonOption>>
    loadRuntimeHostPartyBuilderOptions({
  required String projectFilePath,
  int suggestedLevel = kRuntimeDemoSeedLevel,
}) async {
  final projectFile = File(projectFilePath);
  final projectJson =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  final projectRootUri = projectFile.parent.uri;
  final pokemonConfig = _readPokemonConfig(projectJson);
  final speciesJsonEntries = await _readSpeciesEntries(
    projectRootUri: projectRootUri,
    speciesDir: pokemonConfig.speciesDir,
  );
  final moveCatalog = await _tryReadMoveCatalog(
    projectRootUri.resolve(pokemonConfig.movesCatalogPath),
  );

  final options = <RuntimePartyBuilderPokemonOption>[];
  for (final speciesEntry in speciesJsonEntries) {
    final option = await _tryBuildPartyBuilderOption(
      projectRootUri: projectRootUri,
      pokemonConfig: pokemonConfig,
      speciesEntry: speciesEntry,
      suggestedLevel: suggestedLevel,
      moveCatalog: moveCatalog,
    );
    if (option != null) {
      options.add(option);
    }
  }

  options.sort((left, right) {
    final byName = left.displayName
        .toLowerCase()
        .compareTo(right.displayName.toLowerCase());
    if (byName != 0) {
      return byName;
    }
    return left.speciesId.compareTo(right.speciesId);
  });
  return List<RuntimePartyBuilderPokemonOption>.unmodifiable(options);
}

Future<RuntimeDemoPartySeed?> buildRuntimeHostLaunchDemoPartySeed({
  required bool seedDemoPokemon,
  required String projectFilePath,
}) async {
  if (!seedDemoPokemon) {
    return null;
  }

  final projectFile = File(projectFilePath);
  final projectJson =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  final projectRootUri = projectFile.parent.uri;
  final pokemonConfig = _readPokemonConfig(projectJson);
  final speciesJsonEntries = await _readSpeciesEntries(
    projectRootUri: projectRootUri,
    speciesDir: pokemonConfig.speciesDir,
  );
  if (speciesJsonEntries.isEmpty) {
    throw StateError(
      'Impossible de preparer un Pokemon de demo: aucune espece locale disponible.',
    );
  }

  final orderedSpecies = _orderDemoSpeciesEntries(speciesJsonEntries);
  final moveCatalog = await _tryReadMoveCatalog(
    projectRootUri.resolve(pokemonConfig.movesCatalogPath),
  );
  final members = <RuntimeDemoPartyPokemonSeed>[];
  final selectedSpeciesIds = <String>{};
  for (final speciesEntry in orderedSpecies) {
    if (!selectedSpeciesIds.add(speciesEntry.id)) {
      continue;
    }
    final member = await _tryBuildPartySeedMember(
      projectRootUri: projectRootUri,
      pokemonConfig: pokemonConfig,
      speciesEntry: speciesEntry,
      moveCatalog: moveCatalog,
    );
    if (member == null) {
      continue;
    }
    members.add(member);
    if (members.length >= 2) {
      break;
    }
  }

  if (members.isEmpty) {
    throw StateError(
      'Impossible de preparer un Pokemon de demo utilisable: aucune attaque locale exploitable.',
    );
  }

  return RuntimeDemoPartySeed(
    members: List<RuntimeDemoPartyPokemonSeed>.unmodifiable(members),
  );
}

List<_RuntimeHostSpeciesJsonEntry> _orderDemoSpeciesEntries(
  List<_RuntimeHostSpeciesJsonEntry> entries,
) {
  final ordered = List<_RuntimeHostSpeciesJsonEntry>.from(entries);
  ordered.sort((left, right) {
    final leftRank = _runtimeDemoSpeciesRank(left);
    final rightRank = _runtimeDemoSpeciesRank(right);
    if (leftRank != rightRank) {
      return leftRank.compareTo(rightRank);
    }
    return left.id.compareTo(right.id);
  });
  return List<_RuntimeHostSpeciesJsonEntry>.unmodifiable(ordered);
}

int _runtimeDemoSpeciesRank(_RuntimeHostSpeciesJsonEntry entry) {
  final normalizedId = entry.id.toLowerCase();
  final preferredIndex = _preferredRuntimeDemoSpeciesIds.indexOf(normalizedId);
  if (entry.isEnabledInProject && preferredIndex >= 0) {
    return preferredIndex;
  }
  if (entry.isEnabledInProject &&
      !_avoidRuntimeDemoSpeciesIds.contains(normalizedId)) {
    return 100;
  }
  if (entry.isEnabledInProject) {
    return 200;
  }
  if (!_avoidRuntimeDemoSpeciesIds.contains(normalizedId)) {
    return 300;
  }
  return 400;
}

class _RuntimeHostPokemonConfig {
  const _RuntimeHostPokemonConfig({
    required this.speciesDir,
    required this.learnsetsDir,
    required this.movesCatalogPath,
  });

  final String speciesDir;
  final String learnsetsDir;
  final String movesCatalogPath;
}

class _RuntimeHostSpeciesJsonEntry {
  const _RuntimeHostSpeciesJsonEntry({
    required this.id,
    required this.isEnabledInProject,
    required this.json,
  });

  final String id;
  final bool isEnabledInProject;
  final Map<String, dynamic> json;
}

_RuntimeHostPokemonConfig _readPokemonConfig(Map<String, dynamic> projectJson) {
  final pokemon = projectJson['pokemon'];
  if (pokemon is! Map<String, dynamic>) {
    return const _RuntimeHostPokemonConfig(
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      movesCatalogPath: 'data/pokemon/catalogs/moves.json',
    );
  }

  final speciesDir =
      (pokemon['speciesDir'] as String?)?.trim() ?? 'data/pokemon/species';
  final learnsetsDir =
      (pokemon['learnsetsDir'] as String?)?.trim() ?? 'data/pokemon/learnsets';
  final catalogFiles = pokemon['catalogFiles'];
  final movesCatalogPath =
      (catalogFiles is Map ? catalogFiles['moves'] as String? : null)?.trim();

  return _RuntimeHostPokemonConfig(
    speciesDir: speciesDir,
    learnsetsDir: learnsetsDir,
    movesCatalogPath: movesCatalogPath == null || movesCatalogPath.isEmpty
        ? 'data/pokemon/catalogs/moves.json'
        : movesCatalogPath,
  );
}

Future<List<_RuntimeHostSpeciesJsonEntry>> _readSpeciesEntries({
  required Uri projectRootUri,
  required String speciesDir,
}) async {
  final speciesDirectory = Directory.fromUri(
    projectRootUri.resolve('$speciesDir/'),
  );
  if (!await speciesDirectory.exists()) {
    throw StateError(
      'Impossible de preparer un Pokemon de demo: dossier species introuvable.',
    );
  }

  final entries = <_RuntimeHostSpeciesJsonEntry>[];
  await for (final entity in speciesDirectory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) {
      continue;
    }
    final json = await _tryReadJsonMap(entity.uri);
    if (json == null) {
      continue;
    }
    final declaredId = (json['id'] as String?)?.trim();
    if (declaredId == null || declaredId.isEmpty) {
      continue;
    }
    final classification = (json['classification'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    entries.add(
      _RuntimeHostSpeciesJsonEntry(
        id: declaredId,
        isEnabledInProject:
            (classification['isEnabledInProject'] as bool?) ?? true,
        json: json,
      ),
    );
  }
  entries.sort((left, right) => left.id.compareTo(right.id));
  return List<_RuntimeHostSpeciesJsonEntry>.unmodifiable(entries);
}

Future<Map<String, dynamic>> _readJsonMap(Uri fileUri) async {
  final file = File.fromUri(fileUri);
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('JSON project Pokemon invalide.');
  }
  return decoded;
}

Future<Map<String, dynamic>?> _tryReadJsonMap(Uri fileUri) async {
  try {
    return await _readJsonMap(fileUri);
  } on FormatException {
    return null;
  } on FileSystemException {
    return null;
  } on StateError {
    return null;
  }
}

Future<RuntimeDemoPartyPokemonSeed?> _tryBuildPartySeedMember({
  required Uri projectRootUri,
  required _RuntimeHostPokemonConfig pokemonConfig,
  required _RuntimeHostSpeciesJsonEntry speciesEntry,
  required Map<String, PokemonMove>? moveCatalog,
}) async {
  final speciesJson = speciesEntry.json;
  final learnsetId = _readLearnsetId(speciesJson, speciesEntry.id);
  final learnsetJson = await _tryReadJsonMap(
    projectRootUri.resolve('${pokemonConfig.learnsetsDir}/$learnsetId.json'),
  );
  if (learnsetJson == null) {
    return null;
  }

  final knownMoveIds = _deriveSuggestedMoveIds(
    learnsetJson,
    level: kRuntimeDemoSeedLevel,
    moveCatalog: moveCatalog,
  );
  if (knownMoveIds.isEmpty) {
    return null;
  }

  return RuntimeDemoPartyPokemonSeed(
    speciesId: speciesEntry.id,
    abilityId: _readPrimaryAbilityId(speciesJson) ?? 'unknown',
    gender: _resolveSeedGender(speciesJson, speciesEntry.id),
    level: kRuntimeDemoSeedLevel,
    currentHp: kRuntimeDemoSeedCurrentHp,
    knownMoveIds: knownMoveIds,
  );
}

Future<RuntimePartyBuilderPokemonOption?> _tryBuildPartyBuilderOption({
  required Uri projectRootUri,
  required _RuntimeHostPokemonConfig pokemonConfig,
  required _RuntimeHostSpeciesJsonEntry speciesEntry,
  required int suggestedLevel,
  required Map<String, PokemonMove>? moveCatalog,
}) async {
  final speciesJson = speciesEntry.json;
  final learnsetId = _readLearnsetId(speciesJson, speciesEntry.id);
  final learnsetJson = await _tryReadJsonMap(
    projectRootUri.resolve('${pokemonConfig.learnsetsDir}/$learnsetId.json'),
  );
  if (learnsetJson == null) {
    return null;
  }

  final allMoveIds = _deriveAvailableMoveIds(
    learnsetJson,
    maxLevel: 100,
  );
  final moveDiagnostics = _inspectBattleBridgeMoves(
    allMoveIds,
    moveCatalog: moveCatalog,
  );
  final availableMoveIds = List<String>.unmodifiable(
    allMoveIds.where(
      (moveId) => moveDiagnostics[moveId]?.bridgeable ?? moveCatalog == null,
    ),
  );
  if (availableMoveIds.isEmpty) {
    return null;
  }

  final suggestedMoveIds = _deriveSuggestedMoveIds(
    learnsetJson,
    level: suggestedLevel.clamp(1, 100).toInt(),
    moveCatalog: moveCatalog,
  );

  return RuntimePartyBuilderPokemonOption(
    speciesId: speciesEntry.id,
    displayName: _readSpeciesDisplayName(speciesJson, speciesEntry.id),
    abilityId: _readPrimaryAbilityId(speciesJson) ?? 'unknown',
    gender: _resolveSeedGender(speciesJson, speciesEntry.id),
    availableMoveIds: availableMoveIds,
    suggestedMoveIds: suggestedMoveIds.isEmpty
        ? List<String>.unmodifiable(availableMoveIds.take(4))
        : suggestedMoveIds,
    moveDiagnostics: moveDiagnostics,
  );
}

String _readLearnsetId(
  Map<String, dynamic> speciesJson,
  String fallbackSpeciesId,
) {
  final refs = speciesJson['refs'];
  if (refs is Map<String, dynamic>) {
    final learnset = (refs['learnset'] as String?)?.trim();
    if (learnset != null && learnset.isNotEmpty) {
      return learnset;
    }
  }
  final legacy = (speciesJson['learnsetRef'] as String?)?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    return legacy;
  }
  return fallbackSpeciesId;
}

String _readSpeciesDisplayName(
  Map<String, dynamic> speciesJson,
  String fallbackSpeciesId,
) {
  final names = speciesJson['names'];
  if (names is Map) {
    for (final locale in const <String>['fr', 'en']) {
      final value = names[locale];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    for (final value in names.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }

  final name = speciesJson['name'];
  if (name is String && name.trim().isNotEmpty) {
    return name.trim();
  }

  return fallbackSpeciesId;
}

String? _readPrimaryAbilityId(Map<String, dynamic> speciesJson) {
  final abilities = speciesJson['abilities'];
  if (abilities is! Map<String, dynamic>) {
    return null;
  }
  final primary = (abilities['primary'] as String?)?.trim();
  if (primary == null || primary.isEmpty) {
    return null;
  }
  return primary;
}

String? _resolveSeedGender(
  Map<String, dynamic> speciesJson,
  String speciesId,
) {
  final breeding = speciesJson['breeding'];
  final genderRatio =
      (breeding is Map<String, dynamic> ? breeding['genderRatio'] : null);
  if (genderRatio is! Map<String, dynamic>) {
    return null;
  }
  final maleRatio = (genderRatio['male'] as num?)?.toDouble() ?? 0.0;
  final femaleRatio = (genderRatio['female'] as num?)?.toDouble() ?? 0.0;
  final total = maleRatio + femaleRatio;
  if (total <= 0) {
    return 'genderless';
  }
  if (maleRatio > 0 && femaleRatio <= 0) {
    return 'male';
  }
  if (femaleRatio > 0 && maleRatio <= 0) {
    return 'female';
  }
  return _stableUnitInterval('demo-seed|$speciesId') < (maleRatio / total)
      ? 'male'
      : 'female';
}

double _stableUnitInterval(String seed) {
  var hash = 0;
  for (final codeUnit in seed.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return (hash % 10000) / 10000.0;
}

List<String> _deriveKnownMoveIds(
  Map<String, dynamic> learnsetJson, {
  required int level,
}) {
  final ordered = <String>[
    ..._readStringList(learnsetJson['startingMoves']),
    ..._readStringList(learnsetJson['relearnMoves']),
    ..._readLevelUpMoveIds(learnsetJson['levelUp'], level: level),
  ];

  final unique = _uniqueMoveIds(ordered);

  if (unique.length <= 4) {
    return List<String>.unmodifiable(unique);
  }
  return List<String>.unmodifiable(unique.sublist(unique.length - 4));
}

List<String> _deriveSuggestedMoveIds(
  Map<String, dynamic> learnsetJson, {
  required int level,
  required Map<String, PokemonMove>? moveCatalog,
}) {
  if (moveCatalog == null) {
    return _deriveKnownMoveIds(learnsetJson, level: level);
  }

  final bridgeableMoveIds = _filterBattleBridgeableMoveIds(
    _deriveAvailableMoveIds(learnsetJson, maxLevel: level),
    moveCatalog: moveCatalog,
  );
  if (bridgeableMoveIds.length <= 4) {
    return List<String>.unmodifiable(bridgeableMoveIds);
  }
  return List<String>.unmodifiable(
    bridgeableMoveIds.sublist(bridgeableMoveIds.length - 4),
  );
}

Future<Map<String, PokemonMove>?> _tryReadMoveCatalog(Uri fileUri) async {
  final json = await _tryReadJsonMap(fileUri);
  if (json == null) {
    return null;
  }
  final rawEntries = json['entries'];
  if (rawEntries is! List) {
    return null;
  }

  final entries = <String, PokemonMove>{};
  for (final rawEntry in rawEntries.whereType<Map>()) {
    try {
      final move = PokemonMove.fromJson(rawEntry.cast<String, dynamic>());
      entries[move.id] = move;
    } catch (_) {
      continue;
    }
  }

  if (entries.isEmpty) {
    return null;
  }
  return Map<String, PokemonMove>.unmodifiable(entries);
}

List<String> _filterBattleBridgeableMoveIds(
  List<String> moveIds, {
  required Map<String, PokemonMove>? moveCatalog,
}) {
  if (moveCatalog == null) {
    return List<String>.unmodifiable(moveIds);
  }

  final diagnostics = _inspectBattleBridgeMoves(
    moveIds,
    moveCatalog: moveCatalog,
  );
  final bridgeableMoveIds = moveIds
      .where((moveId) => diagnostics[moveId]?.bridgeable ?? false)
      .toList(growable: false);
  return List<String>.unmodifiable(bridgeableMoveIds);
}

Map<String, RuntimeBattleMoveBridgeDiagnostics> _inspectBattleBridgeMoves(
  List<String> moveIds, {
  required Map<String, PokemonMove>? moveCatalog,
}) {
  if (moveCatalog == null) {
    return const <String, RuntimeBattleMoveBridgeDiagnostics>{};
  }

  const bridge = RuntimeBattleMoveBridge();
  final diagnostics = <String, RuntimeBattleMoveBridgeDiagnostics>{};
  for (final moveId in moveIds) {
    final move = moveCatalog[moveId];
    if (move == null) {
      continue;
    }
    diagnostics[moveId] = bridge.inspectMove(
      move: move,
      combatantLabel: 'Le Pokémon de test',
    );
  }
  return Map<String, RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(
    diagnostics,
  );
}

List<String> _deriveAvailableMoveIds(
  Map<String, dynamic> learnsetJson, {
  required int maxLevel,
}) {
  return List<String>.unmodifiable(
    _uniqueMoveIds(<String>[
      ..._readStringList(learnsetJson['startingMoves']),
      ..._readStringList(learnsetJson['relearnMoves']),
      ..._readLevelUpMoveIds(learnsetJson['levelUp'], level: maxLevel),
    ]),
  );
}

List<String> _uniqueMoveIds(Iterable<String> ordered) {
  final unique = <String>[];
  final seen = <String>{};
  for (final moveId in ordered) {
    final trimmed = moveId.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    unique.add(trimmed);
  }
  return unique;
}

List<String> _readStringList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
}

List<String> _readLevelUpMoveIds(
  Object? raw, {
  required int level,
}) {
  if (raw is! List) {
    return const <String>[];
  }
  final moveIds = <String>[];
  for (final entry in raw.whereType<Map>()) {
    final levelUpEntry = entry.cast<String, dynamic>();
    final requiredLevel = (levelUpEntry['level'] as num?)?.toInt() ?? 0;
    final moveId = (levelUpEntry['moveId'] as String?)?.trim() ?? '';
    if (requiredLevel <= level && moveId.isNotEmpty) {
      moveIds.add(moveId);
    }
  }
  return List<String>.unmodifiable(moveIds);
}
