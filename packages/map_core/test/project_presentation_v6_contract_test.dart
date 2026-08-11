import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation V6', () {
    test('accepts and preserves the complete visual contract', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 6,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'typography': <String, dynamic>{
          'display': <String, dynamic>{
            'fallbackFamilies': <String>['sans-serif'],
            'glyphCoverage': <String>[],
            'metrics': <String, dynamic>{
              'sizeScale': 1.25,
              'weight': 700,
              'lineHeight': 1.1,
              'letterSpacing': 0.5,
            },
          },
        },
        'surfacePalettes': <String, dynamic>{
          'title': <String, dynamic>{
            'surface': '#102030',
            'text': '#FFFFFF',
            'accent': '#63E6FF',
          },
        },
        'windows': <String, dynamic>{
          'styles': <Object?>[
            <String, dynamic>{
              'id': 'default',
              'fillToken': 'surface',
              'borderToken': 'outline',
              'borderWidth': 1,
              'cornerRadius': 16,
              'contentPadding': 24,
              'shadowElevation': 8,
              'shape': 'cutCorner',
              'fillOpacity': 0.8,
            },
          ],
          'defaultStyleId': 'default',
          'pauseMenuStyleId': 'default',
          'dialogueStyleId': 'default',
          'pauseBackdropOpacity': 0.7,
        },
      });

      expect(validateProjectPresentationProfile(profile), isEmpty);
      expect(profile.toJson()['surfacePalettes'], isNotNull);
      expect(
        ((profile.toJson()['typography']! as Map)['display']! as Map)[
          'metrics'
        ],
        isNotNull,
      );
      expect(
        (((profile.toJson()['windows']! as Map)['styles']! as List).single
            as Map)['shape'],
        'cutCorner',
      );
    });

    test('rejects V6-only fields smuggled into a V5 document', () {
      Map<String, dynamic> source() => <String, dynamic>{
        'schemaVersion': 5,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
      };

      expect(
        () => ProjectPresentationProfile.fromJson(
          source()
            ..['surfacePalettes'] = <String, dynamic>{
              'title': <String, dynamic>{'surface': '#102030'},
            },
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProjectPresentationProfile.fromJson(
          source()
            ..['typography'] = <String, dynamic>{
              'display': <String, dynamic>{
                'metrics': <String, dynamic>{'sizeScale': 1.2},
              },
            },
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProjectPresentationProfile.fromJson(
          source()
            ..['windows'] = <String, dynamic>{
              'styles': <Object?>[
                <String, dynamic>{'id': 'default', 'shape': 'rounded'},
              ],
            },
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('migrates V5 with pixel-compatible visual defaults', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 5,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'typography': <String, dynamic>{
          'body': <String, dynamic>{
            'fallbackFamilies': <String>['sans-serif'],
          },
        },
        'windows': <String, dynamic>{
          'styles': <Object?>[
            <String, dynamic>{
              'id': 'default',
              'fillToken': 'surface',
              'borderToken': 'outline',
              'borderWidth': 1,
              'cornerRadius': 16,
              'contentPadding': 24,
              'shadowElevation': 8,
            },
          ],
          'defaultStyleId': 'default',
          'pauseMenuStyleId': 'default',
          'dialogueStyleId': 'default',
          'pauseBackdropOpacity': 0.7,
        },
      });

      expect(profile.schemaVersion, 6);
      expect(profile.surfacePalettes, isNull);
      expect(profile.typography?.body.metrics, isNull);
      expect(
        profile.windows?.styles.single.shape,
        ProjectWindowShape.rounded,
      );
      expect(profile.windows?.styles.single.fillOpacity, 1);
    });

    test('validates every typography metric boundary and non-finite value', () {
      Iterable<String> codes(ProjectTypographyMetricsProfile metrics) =>
          validateProjectPresentationProfile(
            ProjectPresentationProfile(
              typography: ProjectTypographyProfile(
                display: ProjectTypographyRoleProfile(metrics: metrics),
              ),
            ),
          ).map((diagnostic) => diagnostic.code);

      expect(
        codes(
          const ProjectTypographyMetricsProfile(
            sizeScale: projectTypographyMinSizeScale,
            weight: 300,
            lineHeight: projectTypographyMinLineHeight,
            letterSpacing: projectTypographyMinLetterSpacing,
          ),
        ),
        isEmpty,
      );
      expect(
        codes(
          const ProjectTypographyMetricsProfile(
            sizeScale: projectTypographyMaxSizeScale,
            weight: 800,
            lineHeight: projectTypographyMaxLineHeight,
            letterSpacing: projectTypographyMaxLetterSpacing,
          ),
        ),
        isEmpty,
      );
      expect(
        codes(
          const ProjectTypographyMetricsProfile(
            sizeScale: projectTypographyMinSizeScale - .01,
            weight: 200,
            lineHeight: projectTypographyMinLineHeight - .01,
            letterSpacing: projectTypographyMinLetterSpacing - .01,
          ),
        ),
        containsAll(<String>{
          'typographySizeScaleOutOfRange',
          'typographyWeightUnsupported',
          'typographyLineHeightOutOfRange',
          'typographyLetterSpacingOutOfRange',
        }),
      );
      expect(
        codes(
          const ProjectTypographyMetricsProfile(
            sizeScale: double.nan,
            lineHeight: double.infinity,
            letterSpacing: double.negativeInfinity,
          ),
        ),
        containsAll(<String>{
          'typographySizeScaleOutOfRange',
          'typographyLineHeightOutOfRange',
          'typographyLetterSpacingOutOfRange',
        }),
      );
    });

    test('validates palettes and resolves them by player surface role', () {
      const title = ProjectSurfacePaletteProfile(
        surface: '#102030',
        text: '#FFFFFF',
        accent: '#63E6FF',
      );
      const dialogue = ProjectSurfacePaletteProfile(
        surface: '#FFF8E7',
        text: '#17202A',
      );
      const palettes = ProjectPresentationSurfacePalettesProfile(
        title: title,
        dialogue: dialogue,
      );

      expect(
        palettes.resolve(ProjectPresentationSurfaceRole.titlePrompt),
        title,
      );
      expect(
        palettes.resolve(ProjectPresentationSurfaceRole.dialogue),
        dialogue,
      );
      expect(
        palettes.resolve(ProjectPresentationSurfaceRole.overworldHud),
        isNull,
      );
      expect(
        validateProjectPresentationProfile(
          const ProjectPresentationProfile(surfacePalettes: palettes),
        ),
        isEmpty,
      );

      final invalid = validateProjectPresentationProfile(
        const ProjectPresentationProfile(
          surfacePalettes: ProjectPresentationSurfacePalettesProfile(
            battle: ProjectSurfacePaletteProfile(
              surface: '#FFFFFF',
              text: '#FFFFFE',
              accent: 'red',
            ),
          ),
        ),
      ).map((diagnostic) => diagnostic.code);
      expect(
        invalid,
        containsAll(<String>{
          'surfacePaletteColorInvalid',
          'surfacePaletteTextContrastInsufficient',
        }),
      );
    });

    test('validates fill opacity and role-specific window shapes', () {
      ProjectPresentationWindowsProfile windows(
        ProjectWindowShape shape, {
        double opacity = 1,
      }) => ProjectPresentationWindowsProfile(
        styles: <ProjectWindowStyleProfile>[
          ProjectWindowStyleProfile(
            id: 'visual',
            fillToken: 'surface',
            borderToken: 'outline',
            borderWidth: 1,
            cornerRadius: 16,
            contentPadding: 16,
            shadowElevation: 4,
            shape: shape,
            fillOpacity: opacity,
          ),
        ],
        defaultStyleId: 'visual',
        pauseMenuStyleId: 'visual',
        dialogueStyleId: 'visual',
        battleStyleId: 'visual',
        pauseBackdropOpacity: .7,
      );

      expect(
        validateProjectPresentationProfile(
          ProjectPresentationProfile(
            windows: windows(ProjectWindowShape.speech),
          ),
        ).map((diagnostic) => diagnostic.code),
        contains('windowSpeechShapeRoleUnsupported'),
      );
      expect(
        validateProjectPresentationProfile(
          ProjectPresentationProfile(
            windows: windows(ProjectWindowShape.capsule),
          ),
        ).map((diagnostic) => diagnostic.code),
        contains('windowCapsuleShapeRoleUnsupported'),
      );
      expect(
        validateProjectPresentationProfile(
          ProjectPresentationProfile(
            windows: windows(ProjectWindowShape.rounded, opacity: .34),
          ),
        ).map((diagnostic) => diagnostic.code),
        contains('windowFillOpacityOutOfRange'),
      );
      expect(
        validateProjectPresentationProfile(
          ProjectPresentationProfile(
            windows: windows(
              ProjectWindowShape.rounded,
              opacity: double.nan,
            ),
          ),
        ).map((diagnostic) => diagnostic.code),
        contains('windowFillOpacityOutOfRange'),
      );
    });
  });
}
