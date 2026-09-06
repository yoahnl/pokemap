import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('edits quests and profile overrides independently', (
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
    await tester.enterText(
      find.byKey(const ValueKey<String>('menu-label-quests')),
      'Journal',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('menu-label-profile')),
      'Dresseur',
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(value?.quests, 'Journal');
    expect(value?.profile, 'Dresseur');
    await tester.enterText(
      find.byKey(const ValueKey<String>('menu-label-quests')),
      '',
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(value?.quests, isNull);
    expect(value?.profile, 'Dresseur');
  });

  testWidgets('coalesces rapid label typing into one committed profile', (
    tester,
  ) async {
    final committed = <ProjectMenuLabelsProfile?>[];
    final previewed = <ProjectMenuLabelsProfile?>[];

    await tester.pumpWidget(
      _app(
        ProjectMenuLabelsEditor(
          profile: const ProjectMenuLabelsProfile(),
          onChanged: committed.add,
          onPreviewChanged: previewed.add,
        ),
      ),
    );

    final pokedex = find.byKey(const ValueKey<String>('menu-label-pokedex'));
    await tester.enterText(pokedex, 'C');
    await tester.enterText(pokedex, 'Ca');
    await tester.enterText(pokedex, 'Carnet');

    expect(previewed, hasLength(3));
    expect(previewed.last?.pokedex, 'Carnet');
    expect(committed, isEmpty);
    await tester.pump(const Duration(milliseconds: 349));
    expect(committed, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(committed, hasLength(1));
    expect(committed.single?.pokedex, 'Carnet');
  });

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
    await tester.pump(const Duration(milliseconds: 350));
    expect(value?.pokedex, 'Carnet');

    await tester.enterText(pokedex, '');
    await tester.pump(const Duration(milliseconds: 350));
    expect(value, isNull);
  });

  testWidgets('flushes a pending label when focus leaves the field', (
    tester,
  ) async {
    final committed = <ProjectMenuLabelsProfile?>[];

    await tester.pumpWidget(
      _app(
        Column(
          children: <Widget>[
            ProjectMenuLabelsEditor(
              profile: const ProjectMenuLabelsProfile(),
              onChanged: committed.add,
            ),
            const TextField(key: ValueKey<String>('outside-field')),
          ],
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('menu-label-pokedex')),
      'Carnet',
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(committed, isEmpty);

    await tester.tap(find.byKey(const ValueKey<String>('outside-field')));
    await tester.pump();

    expect(committed, hasLength(1));
    expect(committed.single?.pokedex, 'Carnet');
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
