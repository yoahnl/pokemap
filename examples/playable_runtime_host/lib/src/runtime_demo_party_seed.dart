import 'dart:convert';
import 'dart:io';

const kRuntimeDemoSeedLevel = 25;
const kRuntimeDemoSeedCurrentHp = 60;
const kRuntimeDemoSeedSaveId = 'runtime-host-demo-save';
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
  });

  final String speciesDir;
  final String learnsetsDir;
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
    );
  }

  final speciesDir =
      (pokemon['speciesDir'] as String?)?.trim() ?? 'data/pokemon/species';
  final learnsetsDir =
      (pokemon['learnsetsDir'] as String?)?.trim() ?? 'data/pokemon/learnsets';

  return _RuntimeHostPokemonConfig(
    speciesDir: speciesDir,
    learnsetsDir: learnsetsDir,
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
}) async {
  final speciesJson = speciesEntry.json;
  final learnsetId = _readLearnsetId(speciesJson, speciesEntry.id);
  final learnsetJson = await _tryReadJsonMap(
    projectRootUri.resolve('${pokemonConfig.learnsetsDir}/$learnsetId.json'),
  );
  if (learnsetJson == null) {
    return null;
  }

  final knownMoveIds = _deriveKnownMoveIds(
    learnsetJson,
    level: kRuntimeDemoSeedLevel,
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

  final unique = <String>[];
  final seen = <String>{};
  for (final moveId in ordered) {
    final trimmed = moveId.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    unique.add(trimmed);
  }

  if (unique.length <= 4) {
    return List<String>.unmodifiable(unique);
  }
  return List<String>.unmodifiable(unique.sublist(unique.length - 4));
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
