import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  const types = [
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];
  for (final highContrast in [false, true]) {
    testWidgets(
        'all types retain readable labels and distinct icons, contrast $highContrast',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        locale: const Locale('fr'),
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: PlayerMenuThemeScope(
            child: Scaffold(
                body: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final type in types) PlayerPokemonTypeBadge(type: type),
            ])),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final icons = <IconData>{};
      final colors = <Color>{};
      for (final type in types) {
        final badge = find.byKey(ValueKey('pokemon-type-$type'));
        final box =
            tester.widget<DecoratedBox>(badge).decoration as BoxDecoration;
        final text = tester.widget<Text>(
            find.descendant(of: badge, matching: find.byType(Text)));
        final icon = tester.widget<Icon>(
            find.descendant(of: badge, matching: find.byType(Icon)));
        final fg = text.style!.color!.computeLuminance();
        final bg = box.color!.computeLuminance();
        final ratio =
            (fg > bg ? fg + .05 : bg + .05) / (fg > bg ? bg + .05 : fg + .05);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: type);
        icons.add(icon.icon!);
        colors.add(box.color!);
      }
      expect(icons.length, types.length);
      if (!highContrast) expect(colors.length, types.length);
      expect(find.text('FEU'), findsOneWidget);
      expect(find.text('EAU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'compact move badge exposes its localized type without visible text',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      locale: const Locale('fr'),
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      home: const PlayerMenuThemeScope(
        child:
            Center(child: PlayerPokemonTypeBadge(type: 'fire', compact: true)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('FEU'), findsOneWidget);
    expect(find.text('FEU'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
