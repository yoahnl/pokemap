import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectEncounterTable authored conditions', () {
    test('legacy JSON keeps the historical per-step chance and no conditions',
        () {
      final table = ProjectEncounterTable.fromJson(
        <String, dynamic>{
          'id': 'legacy_walk',
          'name': 'Legacy Walk',
          'encounterKind': 'walk',
          'entries': const <Object?>[],
          'tags': const <Object?>[],
        },
      );

      expect(table.chancePerStep, defaultEncounterChancePerStep);
      expect(table.conditions, isEmpty);
    });

    test('round-trips an authored rate and typed activation conditions', () {
      final table = ProjectEncounterTable(
        id: 'surf_after_badge',
        name: 'Surf after badge',
        encounterKind: EncounterKind.surf,
        chancePerStep: 0.35,
        conditions: <ScriptCondition>[
          ScriptConditionFactory.badgeOwned('badge_lysa'),
          ScriptConditionFactory.fieldAbilityUnlocked(FieldAbility.surf),
        ],
      );

      final restored = ProjectEncounterTable.fromJson(table.toJson());

      expect(restored.chancePerStep, 0.35);
      expect(restored.conditions, hasLength(2));
      expect(
        restored.conditions.first.params[ScriptConditionParams.badgeId],
        'badge_lysa',
      );
      expect(
        restored.conditions.last.params[ScriptConditionParams.ability],
        FieldAbility.surf.name,
      );
    });

    test('project validation rejects rates outside the probability range', () {
      final project = ProjectManifest(
        name: 'Invalid encounter rate',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'invalid_rate',
            name: 'Invalid rate',
            encounterKind: EncounterKind.walk,
            chancePerStep: 1.1,
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('chancePerStep'),
          ),
        ),
      );
    });
  });
}
