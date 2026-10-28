import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test(
      'activation-only CS persist in $dimension without gameplay enum values',
      () {
        final settings = ProjectSettings.fromJson({
          'dimension': dimension.name,
          'fieldAbilities': {
            'disabledAbilities': ['defog', 'rock_climb'],
          },
        });
        expect(settings.toJson()['fieldAbilities'], {
          'disabledAbilities': ['defog', 'rock_climb'],
        });
        expect(settings.fieldAbilities!.isEmpty, isFalse);
        expect(settings.fieldAbilities!.disabledAbilities, isEmpty);
        expect(FieldAbility.values, hasLength(9));
        expect(
          FieldAbility.values.map((a) => a.moveId),
          isNot(contains('defog')),
        );
        expect(
          FieldAbility.values.map((a) => a.moveId),
          isNot(contains('rock_climb')),
        );
      },
    );
  }
  test('activation-only restrictions preserve existing CS and Surf policy', () {
    final settings = ProjectSettings.fromJson({
      'surf': {'enabled': false},
      'fieldAbilities': {
        'disabledAbilities': ['defog', 'dive', 'rock_climb'],
      },
    });
    expect(settings.fieldAbilities!.disabledAbilities, {FieldAbility.dive});
    expect(isProjectFieldAbilityEnabled(settings, FieldAbility.surf), isFalse);
    expect(isProjectFieldAbilityEnabled(settings, FieldAbility.dive), isFalse);
    expect(settings.toJson()['fieldAbilities'], {
      'disabledAbilities': ['defog', 'dive', 'rock_climb'],
    });
  });
  test(
    'registry exposes eleven immutable descriptors with two configuration-only CS',
    () {
      expect(ProjectFieldAbilityRegistry.entries, hasLength(11));
      expect(
        ProjectFieldAbilityRegistry.entries.map((entry) => entry.id).toSet(),
        {
          ...FieldAbility.values.map((ability) => ability.moveId),
          'rock_climb',
          'defog',
        },
      );
      expect(
        ProjectFieldAbilityRegistry.entries
            .where((entry) => entry.activationOnly)
            .map((entry) => entry.id)
            .toSet(),
        {'rock_climb', 'defog'},
      );
      expect(ProjectFieldAbilityRegistry.find('rock_climb')!.label, 'Escalade');
      expect(ProjectFieldAbilityRegistry.find('defog')!.label, 'Anti-Brume');
      expect(ProjectFieldAbilityRegistry.find('whirlpool')!.label, 'Siphon');
      expect(
        () => ProjectFieldAbilityRegistry.entries.clear(),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'typed constructor and ID constructor preserve their shared existing contract',
    () {
      final typed = ProjectFieldAbilitiesSettings(
        disabledAbilities: [FieldAbility.dive, FieldAbility.cut],
      );
      final ids = ProjectFieldAbilitiesSettings.fromIds(['cut', 'dive']);
      expect(ids, typed);
      expect(ids.hashCode, typed.hashCode);
      expect(typed.disabledAbilityIds, {'cut', 'dive'});
      expect(
        const ProjectFieldAbilitiesSettings.empty(),
        ProjectFieldAbilitiesSettings.fromIds([]),
      );
    },
  );
  test(
    'ID sets are immutable snapshots and retain all restrictions in equality',
    () {
      final source = ['rock_climb', 'dive'];
      final value = ProjectFieldAbilitiesSettings.fromIds(source);
      source.clear();
      expect(value.disabledAbilityIds, {'rock_climb', 'dive'});
      expect(value.disabledAbilities, {FieldAbility.dive});
      expect(
        value,
        isNot(
          ProjectFieldAbilitiesSettings(disabledAbilities: [FieldAbility.dive]),
        ),
      );
      expect(() => value.disabledAbilityIds.clear(), throwsUnsupportedError);
      expect(() => value.disabledAbilities.clear(), throwsUnsupportedError);
    },
  );
  for (final ids in [
    ['surf'],
    ['rock_climb', 'rock_climb'],
    ['future'],
    ['rockClimb'],
    ['anti_brume'],
    ['defog '],
  ]) {
    test('ID constructor rejects noncanonical restrictions $ids', () {
      expect(
        () => ProjectFieldAbilitiesSettings.fromIds(ids),
        throwsFormatException,
      );
    });
  }
  test(
    'string resolver preserves Surf authority and activation-only defaults',
    () {
      final settings = ProjectSettings(
        surf: const ProjectSurfSettings(enabled: false),
        fieldAbilities: ProjectFieldAbilitiesSettings.fromIds(['rock_climb']),
      );
      expect(isProjectFieldAbilityIdEnabled(settings, 'surf'), isFalse);
      expect(isProjectFieldAbilityIdEnabled(settings, 'rock_climb'), isFalse);
      expect(isProjectFieldAbilityIdEnabled(settings, 'defog'), isTrue);
      expect(isProjectFieldAbilityIdEnabled(settings, 'dive'), isTrue);
      expect(
        () => isProjectFieldAbilityIdEnabled(settings, 'future'),
        throwsArgumentError,
      );
    },
  );
  test(
    'capability v2 is required only for the two new persisted restrictions',
    () {
      const base = ProjectManifest(name: 'CS11', maps: [], tilesets: []);
      for (final ids in <List<String>>[
        [],
        ['dive'],
        ['rock_climb'],
        ['defog'],
        ['dive', 'defog'],
      ]) {
        final project = base.copyWith(
          settings: ProjectSettings(
            fieldAbilities: ProjectFieldAbilitiesSettings.fromIds(ids),
          ),
        );
        expect(
          FieldAbilityActivationCapabilities.requiresCapability(project),
          ids.isNotEmpty,
        );
        expect(
          FieldAbilityActivationCapabilities.requiresExtendedCapability(
            project,
          ),
          ids.any((id) => id == 'rock_climb' || id == 'defog'),
        );
      }
    },
  );
  for (final id in ['rock_climb', 'defog']) {
    test(
      'activation-only $id does not enter the Scene gameplay ability namespace',
      () {
        final source = SceneConditionSource.partyCanUseFieldAbility(
          ability: FieldAbility.surf,
        ).toJson();
        source['value'] = id;
        expect(
          () => SceneConditionSource.fromJson(source),
          throwsFormatException,
        );
      },
    );
  }
}
