import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project presentation windows V5', () {
    test('round-trips role-specific semantic window styles', () {
      const windows = ProjectPresentationWindowsProfile(
        styles: <ProjectWindowStyleProfile>[
          ProjectWindowStyleProfile(
            id: 'default',
            fillToken: 'surface',
            borderToken: 'outline',
            borderWidth: 1,
            cornerRadius: 16,
            contentPadding: 24,
            shadowElevation: 8,
          ),
          ProjectWindowStyleProfile(
            id: 'pause',
            fillToken: 'menuSurface',
            borderToken: 'outline',
            borderWidth: 2,
            cornerRadius: 24,
            contentPadding: 16,
            shadowElevation: 12,
          ),
          ProjectWindowStyleProfile(
            id: 'dialogue',
            fillToken: 'dialogueSurface',
            borderToken: 'primary',
            borderWidth: 2,
            cornerRadius: 10,
            contentPadding: 20,
            shadowElevation: 4,
          ),
          ProjectWindowStyleProfile(
            id: 'battle',
            fillToken: 'battleHudSurface',
            borderToken: 'primary',
            borderWidth: 2,
            cornerRadius: 12,
            contentPadding: 16,
            shadowElevation: 4,
          ),
        ],
        defaultStyleId: 'default',
        pauseMenuStyleId: 'pause',
        dialogueStyleId: 'dialogue',
        battleStyleId: 'battle',
        pauseBackdropOpacity: .8,
      );
      const profile = ProjectPresentationProfile(windows: windows);

      final decoded = ProjectPresentationProfile.fromJson(profile.toJson());

      expect(decoded, profile);
      expect(decoded.schemaVersion, 5);
      expect(decoded.windows?.resolve(ProjectWindowRole.pauseMenu).id, 'pause');
      expect(
        decoded.windows?.resolve(ProjectWindowRole.dialogue).id,
        'dialogue',
      );
      expect(decoded.windows?.resolve(ProjectWindowRole.battle).id, 'battle');
      expect(
        decoded.configuredCategories,
        contains(ProjectPresentationCategory.theme),
      );
    });

    test('migrates V2 without windows to pixel-compatible V3 defaults', () {
      final source = <String, dynamic>{
        'schemaVersion': 2,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'theme': safeProjectSemanticTheme.toJson(),
      };

      final profile = ProjectPresentationProfile.fromJson(source);

      expect(profile.schemaVersion, 5);
      expect(profile.windows, isNull);
      expect(profile.toJson(), isNot(contains('windows')));
      expect(profile.effectiveWindows, legacyProjectPresentationWindows);
      expect(
        profile.effectiveWindows.resolve(ProjectWindowRole.pauseMenu).fillToken,
        'menuSurface',
      );
      expect(
        profile.effectiveWindows.resolve(ProjectWindowRole.dialogue).fillToken,
        'dialogueSurface',
      );
      expect(
        profile.effectiveWindows.resolve(ProjectWindowRole.battle).id,
        profile.effectiveWindows.defaultStyleId,
      );
    });

    test('migrates V1 without windows and keeps the legacy projection', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 1,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
      });

      expect(profile.schemaVersion, 5);
      expect(profile.windows, isNull);
      expect(profile.effectiveWindows, legacyProjectPresentationWindows);
    });

    test('accepts every inclusive numeric boundary', () {
      final minimum = _windows(
        style: _style(
          borderWidth: projectWindowMinBorderWidth,
          cornerRadius: projectWindowMinCornerRadius,
          contentPadding: projectWindowMinContentPadding,
          shadowElevation: projectWindowMinShadowElevation,
        ),
        backdrop: projectWindowMinBackdropOpacity,
      );
      final maximum = _windows(
        style: _style(
          borderWidth: projectWindowMaxBorderWidth,
          cornerRadius: projectWindowMaxCornerRadius,
          contentPadding: projectWindowMaxContentPadding,
          shadowElevation: projectWindowMaxShadowElevation,
        ),
        backdrop: projectWindowMaxBackdropOpacity,
      );

      expect(_windowRangeCodes(minimum), isEmpty);
      expect(_windowRangeCodes(maximum), isEmpty);
    });

    test('rejects values immediately outside every numeric boundary', () {
      final below = _windows(
        style: _style(
          borderWidth: projectWindowMinBorderWidth - 1,
          cornerRadius: projectWindowMinCornerRadius - 1,
          contentPadding: projectWindowMinContentPadding - 1,
          shadowElevation: projectWindowMinShadowElevation - 1,
        ),
        backdrop: projectWindowMinBackdropOpacity - .01,
      );
      final above = _windows(
        style: _style(
          borderWidth: projectWindowMaxBorderWidth + 1,
          cornerRadius: projectWindowMaxCornerRadius + 1,
          contentPadding: projectWindowMaxContentPadding + 1,
          shadowElevation: projectWindowMaxShadowElevation + 1,
        ),
        backdrop: projectWindowMaxBackdropOpacity + .01,
      );
      const expected = <String>{
        'windowBorderWidthOutOfRange',
        'windowCornerRadiusOutOfRange',
        'windowContentPaddingOutOfRange',
        'windowShadowElevationOutOfRange',
        'windowBackdropOpacityOutOfRange',
      };

      expect(_windowRangeCodes(below), containsAll(expected));
      expect(_windowRangeCodes(above), containsAll(expected));
    });

    test('rejects non-finite backdrop values', () {
      expect(
        _windowRangeCodes(_windows(backdrop: double.nan)),
        contains('windowBackdropOpacityOutOfRange'),
      );
      expect(
        _windowRangeCodes(_windows(backdrop: double.infinity)),
        contains('windowBackdropOpacityOutOfRange'),
      );
    });

    test('rejects zero and seventeen styles', () {
      final empty = _windows(styles: const <ProjectWindowStyleProfile>[]);
      final crowded = _windows(
        styles: <ProjectWindowStyleProfile>[
          for (var index = 0; index < 17; index++) _style(id: 'style-$index'),
        ],
      );

      expect(_codes(empty), contains('windowStyleCountOutOfRange'));
      expect(_codes(crowded), contains('windowStyleCountOutOfRange'));
    });

    test('rejects a border that disappears into its authored surface', () {
      final theme = safeProjectSemanticTheme.copyWith(outline: '#FFFFFF');
      final codes = validateProjectPresentationProfile(
        ProjectPresentationProfile(theme: theme, windows: _windows()),
      ).map((diagnostic) => diagnostic.code);

      expect(codes, contains('windowContrastInsufficient'));
    });

    test('preserves and rejects an unsupported future schema', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 99,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
      });

      expect(profile.schemaVersion, 99);
      expect(
        validateProjectPresentationProfile(
          profile,
        ).map((diagnostic) => diagnostic.code),
        contains('presentationVersionUnsupported'),
      );
    });

    test('rejects unknown tokens, invalid references and numeric bounds', () {
      const windows = ProjectPresentationWindowsProfile(
        styles: <ProjectWindowStyleProfile>[
          ProjectWindowStyleProfile(
            id: 'broken',
            fillToken: 'rawPink',
            borderToken: 'alsoRaw',
            borderWidth: 9,
            cornerRadius: 80,
            contentPadding: 2,
            shadowElevation: 30,
          ),
        ],
        defaultStyleId: 'missing',
        pauseMenuStyleId: 'broken',
        dialogueStyleId: 'broken',
        pauseBackdropOpacity: 1,
      );

      final diagnostics = validateProjectPresentationProfile(
        const ProjectPresentationProfile(windows: windows),
      );
      final codes = diagnostics.map((diagnostic) => diagnostic.code).toSet();

      expect(codes, contains('windowFillTokenUnsupported'));
      expect(codes, contains('windowBorderTokenUnsupported'));
      expect(codes, contains('windowBorderWidthOutOfRange'));
      expect(codes, contains('windowCornerRadiusOutOfRange'));
      expect(codes, contains('windowContentPaddingOutOfRange'));
      expect(codes, contains('windowShadowElevationOutOfRange'));
      expect(codes, contains('windowBackdropOpacityOutOfRange'));
      expect(codes, contains('windowStyleReferenceMissing'));
      expect(
        diagnostics.every(
          (diagnostic) =>
              diagnostic.category == ProjectPresentationCategory.theme,
        ),
        isTrue,
      );
    });

    test('rejects duplicate and unsafe style identifiers', () {
      const duplicate = ProjectWindowStyleProfile(
        id: 'Bad id',
        fillToken: 'surface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 16,
        contentPadding: 16,
        shadowElevation: 8,
      );
      const windows = ProjectPresentationWindowsProfile(
        styles: <ProjectWindowStyleProfile>[duplicate, duplicate],
        defaultStyleId: 'Bad id',
        pauseMenuStyleId: 'Bad id',
        dialogueStyleId: 'Bad id',
        pauseBackdropOpacity: .7,
      );

      final codes = validateProjectPresentationProfile(
        const ProjectPresentationProfile(windows: windows),
      ).map((diagnostic) => diagnostic.code);

      expect(codes, contains('windowStyleIdInvalid'));
      expect(codes, contains('windowStyleIdDuplicate'));
    });

    test('does not smuggle V3 windows through an older schema', () {
      final source = <String, dynamic>{
        'schemaVersion': 2,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'windows': legacyProjectPresentationWindows.toJson(),
      };

      expect(
        () => ProjectPresentationProfile.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('does not smuggle V5 battle styles through schema V4', () {
      final source = ProjectPresentationProfile(
        windows: _windows(battleStyleId: 'default'),
      ).toJson()..['schemaVersion'] = 4;

      expect(
        () => ProjectPresentationProfile.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

ProjectWindowStyleProfile _style({
  String id = 'default',
  int borderWidth = 1,
  int cornerRadius = 16,
  int contentPadding = 16,
  int shadowElevation = 8,
}) => ProjectWindowStyleProfile(
  id: id,
  fillToken: 'surface',
  borderToken: 'outline',
  borderWidth: borderWidth,
  cornerRadius: cornerRadius,
  contentPadding: contentPadding,
  shadowElevation: shadowElevation,
);

ProjectPresentationWindowsProfile _windows({
  ProjectWindowStyleProfile? style,
  List<ProjectWindowStyleProfile>? styles,
  double backdrop = .7,
  String? battleStyleId,
}) {
  final resolvedStyles =
      styles ?? <ProjectWindowStyleProfile>[style ?? _style()];
  return ProjectPresentationWindowsProfile(
    styles: resolvedStyles,
    defaultStyleId: resolvedStyles.isEmpty
        ? 'missing'
        : resolvedStyles.first.id,
    pauseMenuStyleId: resolvedStyles.isEmpty
        ? 'missing'
        : resolvedStyles.first.id,
    dialogueStyleId: resolvedStyles.isEmpty
        ? 'missing'
        : resolvedStyles.first.id,
    battleStyleId: battleStyleId,
    pauseBackdropOpacity: backdrop,
  );
}

Set<String> _codes(ProjectPresentationWindowsProfile windows) =>
    validateProjectPresentationProfile(
      ProjectPresentationProfile(windows: windows),
    ).map((diagnostic) => diagnostic.code).toSet();

Set<String> _windowRangeCodes(ProjectPresentationWindowsProfile windows) =>
    _codes(windows).where((code) => code.contains('OutOfRange')).toSet();
