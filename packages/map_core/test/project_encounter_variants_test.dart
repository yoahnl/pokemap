import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('conditional encounter variants survive project JSON round trip', () {
    final table = ProjectEncounterTable.fromJson({
      'id': 'route',
      'name': 'Route',
      'encounterKind': 'walk',
      'variants': [
        {
          'id': 'morning',
          'name': 'Morning',
          'priority': 2,
          'timeWindows': [
            {'startMinute': 240, 'endMinute': 600},
          ],
          'conditions': [ScriptConditionFactory.flagIsSet('edition').toJson()],
          'entries': [
            {'speciesId': 'sentret', 'minLevel': 2, 'maxLevel': 4, 'weight': 5},
          ],
        },
      ],
    });
    expect(table.toJson()['variants'], hasLength(1));
    expect(ProjectEncounterTable.fromJson(table.toJson()), table);
  });
  final valid = ProjectEncounterTable(
    id: 'route',
    name: 'Route',
    encounterKind: EncounterKind.walk,
    variants: [
      ProjectEncounterVariant(
        id: 'morning',
        name: 'Morning',
        conditions: [
          ScriptConditionFactory.factEquals(
            'edition',
            const NarrativeValue.string('heartgold'),
          ),
        ],
        timeWindows: [
          const LocalTimeWindow(startMinute: 240, endMinute: 600),
        ],
        entries: [
          const ProjectEncounterEntry(
            speciesId: 'sentret',
            minLevel: 2,
            maxLevel: 4,
          ),
        ],
      ),
    ],
  );
  ProjectManifest project(ProjectEncounterTable table) => ProjectManifest(
    name: 'Test',
    maps: [],
    tilesets: [],
    encounterTables: [table],
    facts: [
      NarrativeFactDefinition(
        id: 'edition',
        label: 'Edition',
        initialValue: const NarrativeValue.string('heartgold'),
      ),
    ],
  );
  test(
    'valid variants permit an empty fallback and include all dependencies',
    () {
      expect(() => ProjectValidator.validate(project(valid)), returnsNormally);
      expect(valid.allEntries.single.speciesId, 'sentret');
    },
  );
  for (final window in [
    const LocalTimeWindow(startMinute: -1, endMinute: 2),
    const LocalTimeWindow(startMinute: 2, endMinute: 1441),
    const LocalTimeWindow(startMinute: 240, endMinute: 240),
  ]) {
    test('invalid time window $window is rejected', () {
      expect(
        () => ProjectValidator.validate(
          project(
            valid.copyWith(
              variants: [
                valid.variants.single.copyWith(timeWindows: [window]),
              ],
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  }
  test(
    'invalid variant identities, empty entries, levels and references reject',
    () {
      final variant = valid.variants.single;
      for (final variants in [
        [variant, variant],
        [variant.copyWith(id: ' ')],
        [variant.copyWith(name: '')],
        [variant.copyWith(entries: [])],
        [
          variant.copyWith(
            entries: [variant.entries.single.copyWith(weight: 0)],
          ),
        ],
        [
          variant.copyWith(
            entries: [variant.entries.single.copyWith(minLevel: 5)],
          ),
        ],
        [
          variant.copyWith(
            conditions: [
              ScriptConditionFactory.factEquals(
                'unknown',
                const NarrativeValue.string('heartgold'),
              ),
            ],
          ),
        ],
        [
          variant.copyWith(
            conditions: [
              ScriptConditionFactory.factEquals(
                'edition',
                NarrativeValue.integer(1),
              ),
            ],
          ),
        ],
      ]) {
        expect(
          () => ProjectValidator.validate(
            project(valid.copyWith(variants: variants)),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );
}
