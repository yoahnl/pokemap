import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  test('light and dark themes expose complete semantic player tokens', () {
    final light = PokeMapPlayerTheme.light();
    final dark = PokeMapPlayerTheme.dark();

    expect(light.extension<PokeMapPlayerColors>(), isNotNull);
    expect(dark.extension<PokeMapPlayerColors>(), isNotNull);
    expect(
      light.extension<PokeMapPlayerColors>()!.background,
      isNot(dark.extension<PokeMapPlayerColors>()!.background),
    );
    expect(
      PokeMapPlayerTheme.light(highContrast: true)
          .extension<PokeMapPlayerColors>()!
          .highContrast,
      isTrue,
    );
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(
      light.extension<PokeMapPlayerSemanticTheme>()!.titleSurface,
      light.extension<PokeMapPlayerColors>()!.surfaceElevated,
    );
    expect(
      light.extension<PokeMapPlayerSemanticTheme>()!.dialogueSurface,
      light.extension<PokeMapPlayerColors>()!.surfaceElevated,
    );
  });

  test('player text scale composes with the platform accessibility scale', () {
    const scaler = PlayerTextScaler(
      systemScaler: TextScaler.linear(1.4),
      preferenceScale: 1.25,
    );

    expect(scaler.scale(20), 35);
  });

  test('semantic typography keeps role-specific families and fallbacks', () {
    const typography = PokeMapPlayerTypography(
      displayFamily: 'Aube Display',
      displayFallback: <String>['sans-serif'],
      bodyFamily: 'Aube Body',
      bodyFallback: <String>['serif'],
      dialogueFamily: 'Aube Dialogue',
      dialogueFallback: <String>['sans-serif'],
      numbersFamily: 'Aube Numbers',
      numbersFallback: <String>['monospace'],
    );
    final theme = PokeMapPlayerTheme.withTypography(
      PokeMapPlayerTheme.light(),
      typography,
    );

    expect(theme.extension<PokeMapPlayerTypography>(), typography);
    expect(
      typography.displayStyle(const TextStyle()).fontFamily,
      'Aube Display',
    );
    expect(
      typography.dialogueStyle(const TextStyle()).fontFamilyFallback,
      <String>['sans-serif'],
    );
    expect(
      typography.numbersStyle(const TextStyle()).fontFamily,
      'Aube Numbers',
    );
  });

  test('project semantic theme resolves centrally and updates player tokens',
      () {
    final semantic = PokeMapPlayerSemanticTheme.tryFromHex(
      primary: '#003A44',
      onPrimary: '#FFFFFF',
      background: '#F4F7FB',
      surface: '#FFFFFF',
      surfaceElevated: '#EAF0F8',
      textPrimary: '#101827',
      textSecondary: '#526176',
      outline: '#65758B',
      success: '#16794B',
      warning: '#8A5100',
      danger: '#B4233C',
      titleSurface: '#D9F4F6',
      dialogueSurface: '#FFFFFF',
      menuSurface: '#EAF0F8',
      overworldHudSurface: '#FFFFFF',
      battleHudSurface: '#FFFFFF',
    );

    expect(semantic, isNotNull);
    final theme = PokeMapPlayerTheme.withSemanticTheme(
      PokeMapPlayerTheme.light(),
      semantic!,
    );
    expect(
      theme.extension<PokeMapPlayerColors>()!.primary,
      semantic.primary,
    );
    expect(
      theme.extension<PokeMapPlayerSemanticTheme>()!.titleSurface,
      semantic.titleSurface,
    );
    expect(theme.textTheme.headlineLarge?.color, semantic.textPrimary);
    expect(
      PokeMapPlayerSemanticTheme.tryFromHex(
        primary: 'navy',
        onPrimary: '#FFFFFF',
        background: '#F4F7FB',
        surface: '#FFFFFF',
        surfaceElevated: '#EAF0F8',
        textPrimary: '#101827',
        textSecondary: '#526176',
        outline: '#65758B',
        success: '#16794B',
        warning: '#8A5100',
        danger: '#B4233C',
        titleSurface: '#D9F4F6',
        dialogueSurface: '#FFFFFF',
        menuSurface: '#EAF0F8',
        overworldHudSurface: '#FFFFFF',
        battleHudSurface: '#FFFFFF',
      ),
      isNull,
    );
  });

  testWidgets('player panels consume their explicit semantic surface role',
      (tester) async {
    final semantic = PokeMapPlayerSemanticTheme.tryFromHex(
      primary: '#003A44',
      onPrimary: '#FFFFFF',
      background: '#F4F7FB',
      surface: '#FFFFFF',
      surfaceElevated: '#EAF0F8',
      textPrimary: '#101827',
      textSecondary: '#526176',
      outline: '#65758B',
      success: '#16794B',
      warning: '#8A5100',
      danger: '#B4233C',
      titleSurface: '#D9F4F6',
      dialogueSurface: '#FFFFFF',
      menuSurface: '#EAF0F8',
      overworldHudSurface: '#FFFFFF',
      battleHudSurface: '#FFFFFF',
    )!;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.withSemanticTheme(
          PokeMapPlayerTheme.light(),
          semantic,
        ),
        home: const Scaffold(
          body: PlayerPanel(
            role: PlayerPanelRole.battleHud,
            child: Text('Combat'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(PlayerPanel),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, semantic.battleHudSurface);
  });

  testWidgets('player action has a 48px target and visible keyboard focus',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerActionButton(
            label: 'Jouer',
            icon: Icons.play_arrow_rounded,
            autofocus: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(PlayerActionButton)).height,
        greaterThanOrEqualTo(48));
    final frame = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('player-action-focus-frame')),
    );
    final border = (frame.decoration! as BoxDecoration).border! as Border;
    expect(
      border.top.color,
      PokeMapPlayerTheme.dark().extension<PokeMapPlayerColors>()!.focus,
    );
    expect(border.top.width, 3);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
  });

  testWidgets('disabled action explains why it cannot be used', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.light(),
        home: const Scaffold(
          body: PlayerActionButton(
            label: 'Continuer',
            icon: Icons.play_circle_outline,
            disabledReason: 'Aucune sauvegarde disponible',
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(
        const ValueKey<String>('player-action-semantics-Continuer'),
      ),
    );
    expect(semantics.hint, contains('Aucune sauvegarde'));
  });
}
