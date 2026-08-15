import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Presentation cinematic ownership', () {
    test('keeps v6 projects without Presentation data readable', () {
      final manifest = ProjectManifest.fromJson(_projectJson(version: 'v6'));

      expect(manifest.version, ProjectVersion.v6);
      expect(manifest.presentationCinematics, isEmpty);
      expect(manifest.toJson(), isNot(contains('presentationCinematics')));
      expect(ProjectManifest.fromJson(manifest.toJson()), manifest);
    });

    test('rejects the Presentation field on a v6 project', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._projectJson(version: 'v6'),
          'presentationCinematics': <Object?>[],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('cinematic_v2_project_v7_required'),
              contains(r'$.presentationCinematics'),
              contains('actual=v6'),
            ),
          ),
        ),
      );
    });

    test('round-trips Presentation data only under project v7', () {
      final source = ProjectManifest(
        name: 'Presentation project',
        version: ProjectVersion.v7,
        maps: const [],
        tilesets: const [],
        presentationCinematics: [_presentation('opening')],
      );

      final json =
          jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(json['version'], 'v7');
      expect(json['presentationCinematics'], hasLength(1));
      expect(decoded.version, ProjectVersion.v7);
      expect(decoded.presentationCinematics, source.presentationCinematics);
      expect(decoded.toJson(), source.toJson());
    });

    test('keeps world and Presentation cinematic families disjoint', () {
      final manifest = ProjectManifest(
        name: 'Two cinematic families',
        version: ProjectVersion.v7,
        maps: const [],
        tilesets: const [],
        cinematics: [_worldCinematic()],
        presentationCinematics: [_presentation('opening')],
      );

      final decoded = ProjectManifest.fromJson(manifest.toJson());

      expect(decoded.cinematics.single.id, 'world_intro');
      expect(decoded.presentationCinematics.single.id, 'opening');
      expect(decoded.cinematics.single, isA<CinematicAsset>());
      expect(
        decoded.presentationCinematics.single,
        isA<PresentationCinematicAsset>(),
      );
    });

    test('rejects duplicate Presentation cinematic ids', () {
      final duplicate = encodePresentationCinematicAsset(
        _presentation('opening'),
      );

      expect(
        () => ProjectManifest.fromJson({
          ..._projectJson(version: 'v7'),
          'presentationCinematics': [duplicate, duplicate],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'ProjectManifest contains duplicate presentation cinematic id '
              '"opening"',
            ),
          ),
        ),
      );
    });

    test('rejects an unknown future project version before decoding', () {
      expect(
        () => ProjectManifest.fromJson(_projectJson(version: 'v8')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('project_version_unsupported'),
              contains('actual=v8'),
            ),
          ),
        ),
      );
    });

    test('project validation accepts both canonical manifest generations', () {
      final v6 = ProjectManifest(
        name: 'V6 project',
        version: ProjectVersion.v6,
        maps: const [],
        tilesets: const [],
      );
      final v7 = ProjectManifest(
        name: 'V7 project',
        version: ProjectVersion.v7,
        maps: const [],
        tilesets: const [],
        presentationCinematics: [_presentation('opening')],
      );

      expect(() => ProjectValidator.validate(v6), returnsNormally);
      expect(() => ProjectValidator.validate(v7), returnsNormally);
    });

    test('project validation rejects Presentation data in an in-memory v6', () {
      final invalid = ProjectManifest(
        name: 'Invalid V6 project',
        version: ProjectVersion.v6,
        maps: const [],
        tilesets: const [],
        presentationCinematics: [_presentation('opening')],
      );

      expect(
        () => ProjectValidator.validate(invalid),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'cinematic_v2_project_v7_required',
          ),
        ),
      );
    });

    test('project validation rejects duplicate in-memory Presentation ids', () {
      final duplicate = ProjectManifest(
        name: 'Duplicate project',
        version: ProjectVersion.v7,
        maps: const [],
        tilesets: const [],
        presentationCinematics: [
          _presentation('opening'),
          _presentation('opening'),
        ],
      );

      expect(
        () => ProjectValidator.validate(duplicate),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('Duplicate Presentation cinematic ID: opening'),
          ),
        ),
      );
    });

    test('keeps map documents restricted to v6', () {
      expect(
        () => MapData.fromJson(<String, dynamic>{
          'id': 'map',
          'name': 'Map',
          'version': 'v7',
          'size': <String, int>{'width': 1, 'height': 1},
          'layers': <Object?>[],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_v6_map_required'),
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _projectJson({required String version}) =>
    <String, dynamic>{
      'name': 'Project',
      'version': version,
      'maps': <Object?>[],
      'tilesets': <Object?>[],
      'pokemon': const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ).toJson(),
    };

PresentationCinematicAsset _presentation(String id) =>
    PresentationCinematicAsset(
      id: id,
      title: 'Opening',
      durationUs: 1_000_000,
    );

CinematicAsset _worldCinematic() => CinematicAsset(
      id: 'world_intro',
      title: 'World intro',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'wait',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 100,
          ),
        ],
      ),
    );
