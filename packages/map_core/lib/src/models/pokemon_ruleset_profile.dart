enum PokemonTypeChartPolicy { mainlineModernV1 }

enum PokemonExperiencePolicy { pokeMapSimpleV1 }

enum PokemonCapturePolicy { pokeMapMvpV1 }

enum PokemonMoveMachinePolicy { authoredConsumabilityV1 }

enum PokemonCriticalHitPolicy { mainlineGen9 }

enum PokemonSpeedTiePolicy { mainlineGen9SeededRandom }

enum PokemonFriendshipPolicy { mainline0255V1 }

enum PokemonEvolutionPolicy { pokeMapBetaV1 }

enum PokemonDisabledFeature { breeding, doubleBattles, modernGimmicks, online }

final class PokemonRulesetReference {
  const PokemonRulesetReference({
    required this.profileId,
    required this.schemaVersion,
  });

  final String profileId;
  final int schemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'profileId': profileId,
    'schemaVersion': schemaVersion,
  };

  @override
  bool operator ==(Object other) =>
      other is PokemonRulesetReference &&
      other.profileId == profileId &&
      other.schemaVersion == schemaVersion;

  @override
  int get hashCode => Object.hash(profileId, schemaVersion);
}

final class PokemonRulesetMechanics {
  const PokemonRulesetMechanics._({
    required this.reference,
    required this.typeChart,
    required this.maxLevel,
    required this.experience,
    required this.capture,
    required this.moveMachine,
    required this.criticalHit,
    required this.speedTie,
    required this.friendship,
    required this.evolution,
    required this.disabledFeatures,
  });

  static const PokemonRulesetMechanics pokeMapBetaV1 =
      PokemonRulesetMechanics._(
        reference: PokemonRulesetProfile.pokeMapBetaV1Reference,
        typeChart: PokemonTypeChartPolicy.mainlineModernV1,
        maxLevel: 100,
        experience: PokemonExperiencePolicy.pokeMapSimpleV1,
        capture: PokemonCapturePolicy.pokeMapMvpV1,
        moveMachine: PokemonMoveMachinePolicy.authoredConsumabilityV1,
        criticalHit: PokemonCriticalHitPolicy.mainlineGen9,
        speedTie: PokemonSpeedTiePolicy.mainlineGen9SeededRandom,
        friendship: PokemonFriendshipPolicy.mainline0255V1,
        evolution: PokemonEvolutionPolicy.pokeMapBetaV1,
        disabledFeatures: <PokemonDisabledFeature>{
          PokemonDisabledFeature.breeding,
          PokemonDisabledFeature.doubleBattles,
          PokemonDisabledFeature.modernGimmicks,
          PokemonDisabledFeature.online,
        },
      );

  final PokemonRulesetReference reference;
  final PokemonTypeChartPolicy typeChart;
  final int maxLevel;
  final PokemonExperiencePolicy experience;
  final PokemonCapturePolicy capture;
  final PokemonMoveMachinePolicy moveMachine;
  final PokemonCriticalHitPolicy criticalHit;
  final PokemonSpeedTiePolicy speedTie;
  final PokemonFriendshipPolicy friendship;
  final PokemonEvolutionPolicy evolution;
  final Set<PokemonDisabledFeature> disabledFeatures;
}

final class PokemonRulesetProfile {
  const PokemonRulesetProfile._({
    required this.schemaVersion,
    required this.profileId,
    required this.typeChartId,
    required this.maxLevel,
    required this.experiencePolicyId,
    required this.capturePolicyId,
    required this.moveMachinePolicyId,
    required this.criticalHitPolicyId,
    required this.speedTiePolicyId,
    required this.friendshipPolicyId,
    required this.evolutionPolicyId,
    required this.disabledFeatures,
  });

  static const int currentSchemaVersion = 1;
  static const String canonicalProfileId = 'pokemap-beta-v1';
  static const String canonicalTypeChartId = 'mainline-modern-v1';
  static const String canonicalExperiencePolicyId = 'pokemap-simple-exp-v1';
  static const String canonicalCapturePolicyId = 'pokemap-capture-mvp-v1';
  static const String canonicalMoveMachinePolicyId =
      'authored-consumability-v1';
  static const String canonicalCriticalHitPolicyId = 'mainline-gen9-critical';
  static const String canonicalSpeedTiePolicyId = 'mainline-gen9-seeded-random';
  static const String canonicalFriendshipPolicyId = 'mainline-0-255-v1';
  static const String canonicalEvolutionPolicyId = 'pokemap-beta-evolution-v1';
  static const List<String> canonicalDisabledFeatures = <String>[
    'breeding',
    'double-battles',
    'modern-gimmicks',
    'online',
  ];
  static const PokemonRulesetReference pokeMapBetaV1Reference =
      PokemonRulesetReference(
        profileId: canonicalProfileId,
        schemaVersion: currentSchemaVersion,
      );

  static const PokemonRulesetProfile pokeMapBetaV1 = PokemonRulesetProfile._(
    schemaVersion: currentSchemaVersion,
    profileId: canonicalProfileId,
    typeChartId: canonicalTypeChartId,
    maxLevel: 100,
    experiencePolicyId: canonicalExperiencePolicyId,
    capturePolicyId: canonicalCapturePolicyId,
    moveMachinePolicyId: canonicalMoveMachinePolicyId,
    criticalHitPolicyId: canonicalCriticalHitPolicyId,
    speedTiePolicyId: canonicalSpeedTiePolicyId,
    friendshipPolicyId: canonicalFriendshipPolicyId,
    evolutionPolicyId: canonicalEvolutionPolicyId,
    disabledFeatures: canonicalDisabledFeatures,
  );

  factory PokemonRulesetProfile.fromJson(Map<String, dynamic> json) {
    const requiredKeys = <String>{
      'schemaVersion',
      'profileId',
      'typeChartId',
      'maxLevel',
      'experiencePolicyId',
      'capturePolicyId',
      'moveMachinePolicyId',
      'criticalHitPolicyId',
      'speedTiePolicyId',
      'friendshipPolicyId',
      'evolutionPolicyId',
      'disabledFeatures',
    };
    final unknownKeys = json.keys.where((key) => !requiredKeys.contains(key));
    if (unknownKeys.isNotEmpty) {
      throw FormatException(
        'Pokemon ruleset contains unknown fields: ${unknownKeys.join(', ')}.',
      );
    }
    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        throw FormatException('Pokemon ruleset requires "$key".');
      }
    }

    final schemaVersion = _requiredInt(json, 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported Pokemon ruleset schemaVersion $schemaVersion; '
        'expected $currentSchemaVersion.',
      );
    }
    final profile = PokemonRulesetProfile._(
      schemaVersion: schemaVersion,
      profileId: _requiredString(json, 'profileId'),
      typeChartId: _requiredString(json, 'typeChartId'),
      maxLevel: _requiredInt(json, 'maxLevel'),
      experiencePolicyId: _requiredString(json, 'experiencePolicyId'),
      capturePolicyId: _requiredString(json, 'capturePolicyId'),
      moveMachinePolicyId: _requiredString(json, 'moveMachinePolicyId'),
      criticalHitPolicyId: _requiredString(json, 'criticalHitPolicyId'),
      speedTiePolicyId: _requiredString(json, 'speedTiePolicyId'),
      friendshipPolicyId: _requiredString(json, 'friendshipPolicyId'),
      evolutionPolicyId: _requiredString(json, 'evolutionPolicyId'),
      disabledFeatures: List<String>.unmodifiable(
        _requiredStrings(json, 'disabledFeatures')..sort(),
      ),
    );
    profile.requireSupported();
    return profile;
  }

  final int schemaVersion;
  final String profileId;
  final String typeChartId;
  final int maxLevel;
  final String experiencePolicyId;
  final String capturePolicyId;
  final String moveMachinePolicyId;
  final String criticalHitPolicyId;
  final String speedTiePolicyId;
  final String friendshipPolicyId;
  final String evolutionPolicyId;
  final List<String> disabledFeatures;

  PokemonRulesetReference get reference => PokemonRulesetReference(
    profileId: profileId,
    schemaVersion: schemaVersion,
  );

  PokemonRulesetMechanics get mechanics {
    requireSupported();
    return PokemonRulesetMechanics.pokeMapBetaV1;
  }

  void requireSupported() {
    _requirePolicy('profileId', profileId, canonicalProfileId);
    _requirePolicy('typeChartId', typeChartId, canonicalTypeChartId);
    if (maxLevel != 100) {
      throw FormatException(
        'Unsupported Pokemon ruleset maxLevel $maxLevel; expected 100.',
      );
    }
    _requirePolicy(
      'experiencePolicyId',
      experiencePolicyId,
      canonicalExperiencePolicyId,
    );
    _requirePolicy(
      'capturePolicyId',
      capturePolicyId,
      canonicalCapturePolicyId,
    );
    _requirePolicy(
      'moveMachinePolicyId',
      moveMachinePolicyId,
      canonicalMoveMachinePolicyId,
    );
    _requirePolicy(
      'criticalHitPolicyId',
      criticalHitPolicyId,
      canonicalCriticalHitPolicyId,
    );
    _requirePolicy(
      'speedTiePolicyId',
      speedTiePolicyId,
      canonicalSpeedTiePolicyId,
    );
    _requirePolicy(
      'friendshipPolicyId',
      friendshipPolicyId,
      canonicalFriendshipPolicyId,
    );
    _requirePolicy(
      'evolutionPolicyId',
      evolutionPolicyId,
      canonicalEvolutionPolicyId,
    );
    if (!_sameStrings(disabledFeatures, canonicalDisabledFeatures)) {
      throw FormatException(
        'Unsupported Pokemon ruleset disabledFeatures: $disabledFeatures.',
      );
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'profileId': profileId,
    'typeChartId': typeChartId,
    'maxLevel': maxLevel,
    'experiencePolicyId': experiencePolicyId,
    'capturePolicyId': capturePolicyId,
    'moveMachinePolicyId': moveMachinePolicyId,
    'criticalHitPolicyId': criticalHitPolicyId,
    'speedTiePolicyId': speedTiePolicyId,
    'friendshipPolicyId': friendshipPolicyId,
    'evolutionPolicyId': evolutionPolicyId,
    'disabledFeatures': disabledFeatures.toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is PokemonRulesetProfile &&
      other.schemaVersion == schemaVersion &&
      other.profileId == profileId &&
      other.typeChartId == typeChartId &&
      other.maxLevel == maxLevel &&
      other.experiencePolicyId == experiencePolicyId &&
      other.capturePolicyId == capturePolicyId &&
      other.moveMachinePolicyId == moveMachinePolicyId &&
      other.criticalHitPolicyId == criticalHitPolicyId &&
      other.speedTiePolicyId == speedTiePolicyId &&
      other.friendshipPolicyId == friendshipPolicyId &&
      other.evolutionPolicyId == evolutionPolicyId &&
      _sameStrings(other.disabledFeatures, disabledFeatures);

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    profileId,
    typeChartId,
    maxLevel,
    experiencePolicyId,
    capturePolicyId,
    moveMachinePolicyId,
    criticalHitPolicyId,
    speedTiePolicyId,
    friendshipPolicyId,
    evolutionPolicyId,
    Object.hashAll(disabledFeatures),
  );
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Pokemon ruleset "$key" must be an integer.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('Pokemon ruleset "$key" must be a nonblank string.');
  }
  return value;
}

List<String> _requiredStrings(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('Pokemon ruleset "$key" must be a string list.');
  }
  final result = <String>[];
  final seen = <String>{};
  for (final raw in value.cast<String>()) {
    final entry = raw.trim();
    if (entry.isEmpty || entry != raw || !seen.add(entry)) {
      throw FormatException(
        'Pokemon ruleset "$key" must contain unique nonblank strings.',
      );
    }
    result.add(entry);
  }
  return result;
}

void _requirePolicy(String field, String actual, String expected) {
  if (actual != expected) {
    throw FormatException(
      'Unsupported Pokemon ruleset $field "$actual"; expected "$expected".',
    );
  }
}

bool _sameStrings(Iterable<String> left, Iterable<String> right) {
  final leftValues = left.toList(growable: false)..sort();
  final rightValues = right.toList(growable: false)..sort();
  if (leftValues.length != rightValues.length) return false;
  for (var index = 0; index < leftValues.length; index += 1) {
    if (leftValues[index] != rightValues[index]) return false;
  }
  return true;
}
