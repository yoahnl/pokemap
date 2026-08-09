import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('edits a menu label and restores the localized default', (
    tester,
  ) async {
    ProjectMenuLabelsProfile? value;

    await tester.pumpWidget(
      _app(
        ProjectMenuLabelsEditor(
          profile: const ProjectMenuLabelsProfile(),
          onChanged: (next) => value = next,
        ),
      ),
    );

    final pokedex = find.byKey(const ValueKey<String>('menu-label-pokedex'));
    await tester.enterText(pokedex, 'Carnet');
    expect(value?.pokedex, 'Carnet');

    await tester.enterText(pokedex, '');
    expect(value, isNull);
  });

  testWidgets('shows current project labels and localized fallbacks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ProjectMenuLabelsEditor(
          profile: const ProjectMenuLabelsProfile(
            pauseTitle: 'Interlude',
            pokedex: 'Carnet',
          ),
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Interlude'), findsOneWidget);
    expect(find.text('Carnet'), findsOneWidget);
    expect(find.text('Par défaut : Pokédex'), findsOneWidget);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.dark(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
