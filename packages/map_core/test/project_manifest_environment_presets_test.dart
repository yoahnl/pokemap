import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentPaletteItem _item(String id) =>
    EnvironmentPaletteItem(elementId: id, weight: 1);

EnvironmentGenerationParams _params() => EnvironmentGenerationParams.standard();

EnvironmentPreset _ep(String id, {int sortOrder = 0}) => EnvironmentPreset(
      id: id,
      name: 'n_$id',
      templateId: 'tpl',
      palette: [_item('el_$id')],
      defaultParams: _params(),
      sortOrder: sortOrder,
    );

ProjectManifest _minimalManifest() {
  return ProjectManifest(
    name: 'Env5',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

void main() {
  group('ProjectManifest environmentPresets JSON', () {
    test('fromJson sans environmentPresets => []', () {
      final m = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'x',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[],
          'animations': <dynamic>[],
          'presets': <dynamic>[],
        },
      });
      expect(m.environmentPresets, isEmpty);
    });

    test('fromJson avec environmentPresets null => []', () {
      final m = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'x',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'environmentPresets': null,
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[],
          'animations': <dynamic>[],
          'presets': <dynamic>[],
        },
      });
      expect(m.environmentPresets, isEmpty);
    });

    test('fromJson avec environmentPresets complet => liste', () {
      final preset = _ep('p1', sortOrder: 3);
      final manifest = _minimalManifest().copyWith(
        environmentPresets: [preset],
      );
      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded.environmentPresets.length, 1);
      expect(decoded.environmentPresets.single.id, 'p1');
      expect(decoded.environmentPresets.single.sortOrder, 3);
    });

    test('toJson inclut environmentPresets', () {
      final preset = _ep('x');
      final j =
          _minimalManifest().copyWith(environmentPresets: [preset]).toJson();
      expect(j.containsKey('environmentPresets'), isTrue);
      expect(j['environmentPresets'], isA<List>());
    });

    test('JSON roundtrip avec un preset complet', () {
      final preset = EnvironmentPreset(
        id: 'full',
        name: 'Full',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'e1',
            weight: 2,
            collisionMode: EnvironmentCollisionMode.forceDisabled,
            tags: {'a', 'b'},
          ),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 0.25,
          variation: 0.5,
          edgeDensity: 0.75,
          minSpacingCells: 4,
        ),
        categoryId: 'cat',
        sortOrder: 7,
      );
      final m = _minimalManifest().copyWith(environmentPresets: [preset]);
      final back = ProjectManifest.fromJson(m.toJson());
      expect(back.environmentPresets.single, preset);
    });

    test('environmentPresets non-list => FormatException', () {
      expect(
        () => ProjectManifest.fromJson(<String, dynamic>{
          'name': 'x',
          'maps': <dynamic>[],
          'tilesets': <dynamic>[],
          'environmentPresets': 'bad',
          'surfaceCatalog': <String, dynamic>{
            'atlases': <dynamic>[],
            'animations': <dynamic>[],
            'presets': <dynamic>[],
          },
        }),
        throwsFormatException,
      );
    });

    test('environmentPresets avec item invalide => FormatException', () {
      expect(
        () => ProjectManifest.fromJson(<String, dynamic>{
          'name': 'x',
          'maps': <dynamic>[],
          'tilesets': <dynamic>[],
          'environmentPresets': <dynamic>[
            <String, dynamic>{'oops': true},
          ],
          'surfaceCatalog': <String, dynamic>{
            'atlases': <dynamic>[],
            'animations': <dynamic>[],
            'presets': <dynamic>[],
          },
        }),
        throwsFormatException,
      );
    });
  });

  group('project_manifest_environment_preset_operations', () {
    test('readProjectEnvironmentPresets retourne la liste', () {
      final p = _ep('a');
      final m = _minimalManifest().copyWith(environmentPresets: [p]);
      expect(readProjectEnvironmentPresets(m), m.environmentPresets);
    });

    test('hasProjectEnvironmentPresets false/true', () {
      expect(hasProjectEnvironmentPresets(_minimalManifest()), isFalse);
      expect(
        hasProjectEnvironmentPresets(
          _minimalManifest().copyWith(environmentPresets: [_ep('x')]),
        ),
        isTrue,
      );
    });

    test('findProjectEnvironmentPresetById trouve / trim / null', () {
      final m = _minimalManifest().copyWith(environmentPresets: [_ep('abc')]);
      expect(findProjectEnvironmentPresetById(m, '  abc  ')?.id, 'abc');
      expect(findProjectEnvironmentPresetById(m, '  '), isNull);
      expect(findProjectEnvironmentPresetById(m, 'nope'), isNull);
    });

    test('replaceProjectEnvironmentPresets remplace et ordre', () {
      final base = _minimalManifest().copyWith(
        environmentPresets: [_ep('a'), _ep('b')],
      );
      final next = replaceProjectEnvironmentPresets(
        base,
        [_ep('z', sortOrder: 9), _ep('y')],
      );
      expect(next.environmentPresets.map((e) => e.id).toList(), ['z', 'y']);
    });

    test('replaceProjectEnvironmentPresets refuse doublons', () {
      expect(
        () => replaceProjectEnvironmentPresets(
          _minimalManifest(),
          [_ep('x'), _ep('x')],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('upsert ajoute ou remplace même position', () {
      final a = _ep('a', sortOrder: 0);
      final b = _ep('b', sortOrder: 0);
      final m0 = _minimalManifest().copyWith(environmentPresets: [a, b]);

      final a2 = EnvironmentPreset(
        id: 'a',
        name: 'updated',
        templateId: 'tpl',
        palette: [_item('el_a')],
        defaultParams: _params(),
        sortOrder: 99,
      );
      final m1 = upsertProjectEnvironmentPreset(m0, a2);
      expect(m1.environmentPresets.map((e) => e.name).toList(),
          ['updated', 'n_b']);

      final c = _ep('c');
      final m2 = upsertProjectEnvironmentPreset(m1, c);
      expect(m2.environmentPresets.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('upsert refuse doublons préexistants dans le manifest', () {
      final corrupt = ProjectManifest(
        name: 'bad',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: ProjectSurfaceCatalog(),
        environmentPresets: [_ep('dup'), _ep('dup')],
      );
      expect(
        () => upsertProjectEnvironmentPreset(corrupt, _ep('z')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('remove supprime / inconnu no-op / id vide erreur', () {
      final m = _minimalManifest().copyWith(environmentPresets: [_ep('k')]);
      final removed = removeProjectEnvironmentPresetById(m, 'k');
      expect(removed.environmentPresets, isEmpty);

      final m2 = removeProjectEnvironmentPresetById(m, 'ghost');
      expect(m2.environmentPresets.single.id, 'k');

      expect(
        () => removeProjectEnvironmentPresetById(m, '   '),
        throwsArgumentError,
      );
    });

    test('clearProjectEnvironmentPresets vide la liste', () {
      final m = _minimalManifest().copyWith(environmentPresets: [_ep('u')]);
      final cleared = clearProjectEnvironmentPresets(m);
      expect(cleared.environmentPresets, isEmpty);
    });
  });
}
