import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentLayerContent JSON codec', () {
    test('decode null => emptyContent', () {
      final c = decodeEnvironmentLayerContent(null);
      expect(c, EnvironmentLayerContent.emptyContent);
    });

    test('decode map minimal => content vide', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{});
      expect(c.targetTileLayerId, isNull);
      expect(c.areas, isEmpty);
    });

    test('decode targetTileLayerId trimé', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'targetTileLayerId': '  decor  ',
      });
      expect(c.targetTileLayerId, 'decor');
    });

    test('decode targetTileLayerId null explicite => null', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'targetTileLayerId': null,
      });
      expect(c.targetTileLayerId, isNull);
    });

    test('decode targetTileLayerId whitespace => FormatException', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'targetTileLayerId': '   ',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'targetTileLayerId': '',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode areas absent/null => []', () {
      final a = decodeEnvironmentLayerContent(
        <String, dynamic>{'targetTileLayerId': 't'},
      );
      final b = decodeEnvironmentLayerContent(
        <String, dynamic>{'targetTileLayerId': 't', 'areas': null},
      );
      expect(a.areas, isEmpty);
      expect(b.areas, isEmpty);
    });

    test('decode area complète + paramsOverride + generatedPlacementIds', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'areas': [
          <String, dynamic>{
            'id': 'a1',
            'name': 'Zone A',
            'presetId': 'p1',
            'mask': <String, dynamic>{
              'width': 2,
              'height': 2,
              'cells': <bool>[true, false, true, false],
            },
            'seed': 7,
            'paramsOverride': <String, dynamic>{
              'density': 0.5,
              'variation': 0.5,
              'edgeDensity': 0.5,
              'minSpacingCells': 1,
            },
            'generatedPlacementIds': <String>['x1', 'x2'],
          },
        ],
      });
      expect(c.areas, hasLength(1));
      final a = c.areas.single;
      expect(a.id, 'a1');
      expect(a.presetId, 'p1');
      expect(a.mask.width, 2);
      expect(a.mask.height, 2);
      expect(a.paramsOverride, isNotNull);
      expect(a.generatedPlacementIds, ['x1', 'x2']);
    });

    test('encode content vide', () {
      final m =
          encodeEnvironmentLayerContent(EnvironmentLayerContent.emptyContent);
      expect(m, <String, dynamic>{'areas': <dynamic>[]});
    });

    test('encode content avec targetTileLayerId', () {
      final m = encodeEnvironmentLayerContent(
        EnvironmentLayerContent(
          targetTileLayerId: 'd1',
          areas: null,
        ),
      );
      expect(m['targetTileLayerId'], 'd1');
      expect(m['areas'], isEmpty);
    });

    test('roundtrip content complet', () {
      final original = EnvironmentLayerContent(
        targetTileLayerId: 't1',
        areas: [
          EnvironmentArea(
            id: 'z1',
            name: 'Z',
            presetId: 'preset',
            mask: EnvironmentAreaMask(
              width: 1,
              height: 1,
              cells: [true],
            ),
            seed: 1,
            paramsOverride: EnvironmentGenerationParams(
              density: 0.25,
              variation: 0.5,
              edgeDensity: 0.75,
              minSpacingCells: 0,
            ),
            generatedPlacementIds: ['g1'],
          ),
        ],
      );
      final round = decodeEnvironmentLayerContent(
          encodeEnvironmentLayerContent(original));
      expect(round, original);
    });

    test('json non-map rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(1),
        throwsA(isA<FormatException>()),
      );
    });

    test('areas non-list rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{'areas': 3}),
        throwsA(isA<FormatException>()),
      );
    });

    test('mask invalide rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'areas': [
            <String, dynamic>{
              'id': 'a',
              'name': 'b',
              'presetId': 'c',
              'mask': <String, dynamic>{
                'width': 1,
                'height': 1,
                'cells': <bool>[true, false],
              },
              'seed': 0,
            },
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    group('codec strict int', () {
      Map<String, dynamic> minimalAreaJson({
        required Object seed,
        Object? maskWidth,
        Object? maskHeight,
      }) =>
          <String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': maskWidth ?? 1,
                  'height': maskHeight ?? 1,
                  'cells': <bool>[true],
                },
                'seed': seed,
              },
            ],
          };

      test('decode seed double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(minimalAreaJson(seed: 1.5)),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode mask width double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(minimalAreaJson(
            seed: 0,
            maskWidth: 1.5,
          )),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode mask height double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(minimalAreaJson(
            seed: 0,
            maskHeight: 1.5,
          )),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode minSpacingCells double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'paramsOverride': <String, dynamic>{
                  'density': 0.5,
                  'variation': 0.5,
                  'edgeDensity': 0.5,
                  'minSpacingCells': 1.5,
                },
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode paramsOverride density hors plage => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'paramsOverride': <String, dynamic>{
                  'density': 2.0,
                  'variation': 0.5,
                  'edgeDensity': 0.5,
                  'minSpacingCells': 0,
                },
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('generatedPlacementIds et areas strict', () {
      test('generatedPlacementIds avec int => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'generatedPlacementIds': <Object>[1],
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('generatedPlacementIds string vide => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'generatedPlacementIds': <String>[''],
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('generatedPlacementIds doublon => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'generatedPlacementIds': <String>['x', 'x'],
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('areas item non-map => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': <Object>[1],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('areas duplicate area id => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'dup',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
              },
              <String, dynamic>{
                'id': 'dup',
                'name': 'b2',
                'presetId': 'c2',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[false],
                },
                'seed': 1,
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
