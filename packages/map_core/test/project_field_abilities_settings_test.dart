import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('legacy settings omit field ability activation', () {
    expect(
      ProjectSettings.fromJson({}).toJson(),
      isNot(contains('fieldAbilities')),
    );
  });

  test('disabled non-Surf field abilities survive native serialization', () {
    final settings = ProjectSettings.fromJson({
      'fieldAbilities': {
        'disabledAbilities': ['dive', 'rock_smash'],
      },
    });
    expect(settings.toJson()['fieldAbilities'], {
      'disabledAbilities': ['dive', 'rock_smash'],
    });
  });

  test('empty field ability policy is omitted', () {
    final settings = ProjectSettings.fromJson({
      'fieldAbilities': {'disabledAbilities': <String>[]},
    });
    expect(settings.toJson(), isNot(contains('fieldAbilities')));
  });

  for (final config in <Map<String, dynamic>>[
    {
      'disabledAbilities': ['surf'],
    },
    {
      'disabledAbilities': ['dive', 'dive'],
    },
    {
      'disabledAbilities': ['future'],
    },
    {
      'disabledAbilities': ['rockSmash'],
    },
    {
      'disabledAbilities': [1],
    },
    {'disabledAbilities': null},
    {'disabledAbilities': 'dive'},
    {'enabled': false},
  ]) {
    test('rejects malformed field ability policy $config', () {
      expect(
        () => ProjectSettings.fromJson({'fieldAbilities': config}),
        throwsFormatException,
      );
    });
  }
  test(
    'Surf has one activation authority with profile-specific legacy defaults',
    () {
      expect(
        isProjectFieldAbilityEnabled(
          const ProjectSettings(),
          FieldAbility.surf,
        ),
        isTrue,
      );
      expect(
        isProjectFieldAbilityEnabled(
          const ProjectSettings(dimension: ProjectDimension.threeD),
          FieldAbility.surf,
        ),
        isFalse,
      );
      for (final dimension in ProjectDimension.values) {
        for (final enabled in [true, false]) {
          expect(
            isProjectFieldAbilityEnabled(
              ProjectSettings(
                dimension: dimension,
                surf: ProjectSurfSettings(enabled: enabled),
              ),
              FieldAbility.surf,
            ),
            enabled,
          );
        }
      }
    },
  );

  for (final ability in FieldAbility.values.where(
    (a) => a != FieldAbility.surf,
  )) {
    test('${ability.name} preserves default activation in both profiles', () {
      for (final dimension in ProjectDimension.values) {
        expect(
          isProjectFieldAbilityEnabled(
            ProjectSettings(dimension: dimension),
            ability,
          ),
          isTrue,
        );
        final disabled = ProjectFieldAbilitiesSettings(
          disabledAbilities: [ability],
        );
        final settings = ProjectSettings(
          dimension: dimension,
          fieldAbilities: disabled,
        );
        expect(isProjectFieldAbilityEnabled(settings, ability), isFalse);
        expect(
          isProjectFieldAbilityEnabled(
            ProjectSettings.fromJson(settings.toJson()),
            ability,
          ),
          isFalse,
        );
      }
    });
  }

  test(
    'activation capability protects restrictions without changing legacy packages',
    () {
      const base = ProjectManifest(name: 'CS', maps: [], tilesets: []);
      expect(
        FieldAbilityActivationCapabilities.capabilityId,
        'gameplay.field-ability-activation@1',
      );
      expect(
        FieldAbilityActivationCapabilities.requiresCapability(base),
        isFalse,
      );
      expect(
        FieldAbilityActivationCapabilities.requiresCapability(
          base.copyWith(
            settings: ProjectSettings(
              fieldAbilities: ProjectFieldAbilitiesSettings(
                disabledAbilities: [FieldAbility.dive],
              ),
            ),
          ),
        ),
        isTrue,
      );
      expect(
        FieldAbilityActivationCapabilities.requiresCapability(
          base.copyWith(
            settings: const ProjectSettings(
              fieldAbilities: ProjectFieldAbilitiesSettings.empty(),
            ),
          ),
        ),
        isFalse,
      );
    },
  );
  test('activation settings preserve independent Surf and audio contracts', () {
    final source = ProjectSettings.fromJson({
      'surf': {
        'enabled': true,
        'requiresKnownMove': false,
        'accessMode': 'always',
        'speedCellsPerSecond': 5.0,
      },
      'audio': {
        'cues': {
          'ui.confirm': {'source': 'silent', 'gain': 1.0},
        },
      },
    });
    final policy = ProjectFieldAbilitiesSettings(
      disabledAbilities: [FieldAbility.dive],
    );
    final changed = source.copyWith(fieldAbilities: policy);
    final restored = ProjectSettings.fromJson(changed.toJson());
    expect(restored.fieldAbilities, policy);
    expect(restored.surf, source.surf);
    expect(restored.audio, source.audio);
    expect(() => policy.disabledAbilities.clear(), throwsUnsupportedError);
  });
  test(
    'v8 2D manifests persist CS and audio without changing their format',
    () {
      const legacy = ProjectManifest(
        name: 'Protected 2D',
        version: ProjectVersion.v8,
        maps: [],
        tilesets: [],
      );
      final existing = ProjectManifest.fromJson(legacy.toJson());
      expect(existing.settings.dimension, ProjectDimension.twoD);
      expect(existing.settings.fieldAbilities, isNull);
      expect(existing.settings.audio, isNull);
      final modified = existing.copyWith(
        settings: existing.settings.copyWith(
          fieldAbilities: ProjectFieldAbilitiesSettings(
            disabledAbilities: [FieldAbility.dive],
          ),
          audio: ProjectAudioSettings(
            cues: {
              ProjectSoundCue.uiConfirm: ProjectSoundBinding(
                source: ProjectSoundSource.silent,
              ),
            },
          ),
        ),
      );
      final restored = ProjectManifest.fromJson(modified.toJson());
      expect(restored.version, ProjectVersion.v8);
      expect(restored.settings.dimension, ProjectDimension.twoD);
      expect(restored.settings.spatialCamera, isNull);
      expect(
        isProjectFieldAbilityEnabled(restored.settings, FieldAbility.dive),
        isFalse,
      );
      expect(
        isProjectFieldAbilityEnabled(restored.settings, FieldAbility.surf),
        isTrue,
      );
      expect(restored.settings.audio, modified.settings.audio);
      expect(restored.maps, existing.maps);
      expect(restored.pokemon, existing.pokemon);
      expect(
        () => ProjectManifest.fromJson(
          modified.copyWith(version: ProjectVersion.v9).toJson(),
        ),
        throwsFormatException,
      );
    },
  );
}
