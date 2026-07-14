import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectValidator Fact runtime keys', () {
    test('accepts unique Fact IDs aliases and runtime keys', () {
      final project = _project([
        NarrativeFactDefinition(id: 'fact_a', label: 'A'),
        NarrativeFactDefinition(
          id: 'fact_b',
          label: 'B',
          legacyFlagName: 'legacy_b',
        ),
      ]);

      expect(() => ProjectValidator.validate(project), returnsNormally);
    });

    test('rejects duplicate Fact IDs', () {
      final project = _project([
        NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
        NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
      ]);

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate aliases', () {
      final project = _project([
        NarrativeFactDefinition(
          id: 'fact_a',
          label: 'A',
          legacyFlagName: 'legacy_shared',
        ),
        NarrativeFactDefinition(
          id: 'fact_b',
          label: 'B',
          legacyFlagName: 'legacy_shared',
        ),
      ]);

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects an alias equal to another Fact ID', () {
      final project = _project([
        NarrativeFactDefinition(id: 'fact_a', label: 'A'),
        NarrativeFactDefinition(
          id: 'fact_b',
          label: 'B',
          legacyFlagName: 'fact_a',
        ),
      ]);

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectManifest _project(List<NarrativeFactDefinition> facts) {
  return ProjectManifest(
    name: 'Fact validator project',
    maps: const [],
    tilesets: const [],
    facts: facts,
  );
}
