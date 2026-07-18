import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project dialogue declared outcomes', () {
    test('round-trips declared outcomes and defaults legacy JSON to empty', () {
      final legacy = ProjectManifest.fromJson(_projectJson());
      expect(legacy.dialogues.single.declaredOutcomes, isEmpty);

      final manifest = ProjectManifest.fromJson(
        _projectJson(
          declaredOutcomes: [
            {'id': 'accepted', 'label': 'Accepter'},
            {'id': 'refused', 'label': 'Refuser'},
          ],
        ),
      );

      expect(
        manifest.dialogues.single.declaredOutcomes
            .map((outcome) => (outcome.id, outcome.label)),
        [('accepted', 'Accepter'), ('refused', 'Refuser')],
      );
      expect(
        ProjectManifest.fromJson(manifest.toJson())
            .dialogues
            .single
            .declaredOutcomes,
        manifest.dialogues.single.declaredOutcomes,
      );
    });

    test('rejects blank or duplicate declared outcome ids and blank labels',
        () {
      for (final outcomes in <List<Map<String, Object?>>>[
        [
          {'id': '   ', 'label': 'Accepter'},
        ],
        [
          {'id': 'accepted', 'label': 'Accepter'},
          {'id': ' accepted ', 'label': 'Encore'},
        ],
        [
          {'id': 'accepted', 'label': '   '},
        ],
        [
          {'id': 'completed', 'label': 'Terminé'},
        ],
      ]) {
        final manifest = ProjectManifest.fromJson(
          _projectJson(declaredOutcomes: outcomes),
        );

        expect(
          () => ProjectValidator.validate(manifest),
          throwsA(isA<ValidationException>()),
          reason: '$outcomes',
        );
      }
    });
  });
}

Map<String, Object?> _projectJson({
  List<Map<String, Object?>>? declaredOutcomes,
}) {
  return {
    'name': 'Dialogue outcomes test',
    'version': 'v1',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'dialogues': [
      {
        'id': 'dialogue_intro',
        'name': 'Introduction',
        'relativePath': 'dialogues/intro.yarn',
        if (declaredOutcomes != null) 'declaredOutcomes': declaredOutcomes,
      },
    ],
  };
}
