import 'package:avelune_studio/presentation/features/pokemon/pokemon_ui_parts.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required VoidCallback onCreate,
}) => tester.pumpWidget(
  MaterialApp(
    theme: studioTheme(),
    home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: size,
            child: PokemonEmptyState(
              title: 'Aucune table de rencontres',
              description: 'Créez une table pour choisir les Pokémon sauvages, leurs niveaux et leur fréquence.',
              action: StudioButton(
                label: 'Créer une table',
                onPressed: onCreate,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(PokemonEmptyState),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

void main() {
  testWidgets(
    'large text in a short pane scrolls to the action instead of overflowing',
    (tester) async {
      var created = 0;
      await _pump(
        tester,
        size: const Size(340, 160),
        onCreate: () => created++,
      );
      expect(tester.takeException(), isNull);
      expect(_position(tester).maxScrollExtent, greaterThan(0));
      final action = find.text('Créer une table');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      expect(created, 1);
    },
  );

  testWidgets('a roomy pane keeps the empty state centred without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, size: const Size(600, 1000), onCreate: () {});
    expect(tester.takeException(), isNull);
    expect(_position(tester).maxScrollExtent, 0);
    final pane = tester.getCenter(find.byType(PokemonEmptyState));
    final content = tester.getRect(
      find
          .descendant(
            of: find.byType(PokemonEmptyState),
            matching: find.byType(Column),
          )
          .first,
    );
    expect(content.center.dy, closeTo(pane.dy, 1));
    expect(content.height, lessThan(1000));
  });
}
