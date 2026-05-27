import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  group('PokeMapTheme and PokeMapColorTokens Tests', () {
    test(
        'PokeMapTheme.light() creates a ThemeData brightness light with tokens',
        () {
      final theme = PokeMapTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);

      final tokens = theme.extension<PokeMapColorTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.backgroundApp, const Color(0xFFF5F8FC));
      expect(tokens.chromeBackground, const Color(0xFFF1F5FB));
      expect(tokens.contentSurface, const Color(0xFFFFFFFF));
      expect(tokens.textPrimary, const Color(0xFF13213A));
      expect(tokens.mapAccent, const Color(0xFF22A06B));
    });

    test('PokeMapTheme.dark() creates a ThemeData brightness dark with tokens',
        () {
      final theme = PokeMapTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);

      final tokens = theme.extension<PokeMapColorTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.backgroundApp, const Color(0xFF00040C));
      expect(tokens.chromeBackground, const Color(0xFF00040C));
      expect(tokens.topBarBackground, const Color(0xFF030D18));
      expect(tokens.contentSurface, const Color(0xFF091421));
      expect(tokens.cardSurface, const Color(0xFF0D1928));
      expect(tokens.surfaceBase, const Color(0xFF091421));
      expect(tokens.textPrimary, const Color(0xFFF1F5FB));
      expect(tokens.brandPrimary, const Color(0xFF5488EC));
      expect(tokens.mapAccent, const Color(0xFF47D16C));
    });

    test(
        'Light and Dark color tokens are not accidentally identical for major surfaces',
        () {
      const light = PokeMapColorTokens.light;
      const dark = PokeMapColorTokens.dark;

      expect(light.backgroundApp, isNot(dark.backgroundApp));
      expect(light.surfaceBase, isNot(dark.surfaceBase));
      expect(light.textPrimary, isNot(dark.textPrimary));
      expect(light.brandPrimary, isNot(dark.brandPrimary));
      expect(light.mapAccent, isNot(dark.mapAccent));
    });

    testWidgets('BuildContext.pokeMapColors resolves from MaterialApp Theme',
        (tester) async {
      late PokeMapColorTokens resolvedColors;

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                resolvedColors = context.pokeMapColors;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolvedColors, isNotNull);
      expect(resolvedColors.backgroundApp, const Color(0xFFF5F8FC));
      expect(resolvedColors.contentSurface, const Color(0xFFFFFFFF));
    });

    testWidgets(
        'BuildContext.pokeMapColors falls back correctly with MacosTheme (Dark)',
        (tester) async {
      late PokeMapColorTokens resolvedColors;

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: Builder(
            builder: (context) {
              resolvedColors = context.pokeMapColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedColors, isNotNull);
      expect(resolvedColors.backgroundApp, const Color(0xFF00040C));
      expect(resolvedColors.textPrimary, const Color(0xFFF1F5FB));
    });

    testWidgets(
        'BuildContext.pokeMapColors falls back correctly with MediaQuery (Light/Dark)',
        (tester) async {
      late PokeMapColorTokens resolvedColorsLight;
      late PokeMapColorTokens resolvedColorsDark;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: Builder(
            builder: (context) {
              resolvedColorsLight = context.pokeMapColors;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: Builder(
            builder: (context) {
              resolvedColorsDark = context.pokeMapColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedColorsLight.backgroundApp, const Color(0xFFF5F8FC));
      expect(resolvedColorsDark.backgroundApp, const Color(0xFF00040C));
    });

    testWidgets(
        'PokeMapMacosCompatibilityBridge maps dark/light Material Theme to MacosTheme brightness',
        (tester) async {
      late Brightness macosBrightness;

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: PokeMapMacosCompatibilityBridge(
            child: Builder(
              builder: (context) {
                macosBrightness = MacosTheme.brightnessOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(macosBrightness, Brightness.dark);
    });
  });
}
