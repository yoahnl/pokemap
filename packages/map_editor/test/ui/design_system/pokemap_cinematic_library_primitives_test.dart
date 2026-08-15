import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('family tabs expose selection and switch by pointer', (
    tester,
  ) async {
    var selected = PokeMapCinematicLibraryMode.inGame;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PokeMapCinematicFamilyTabs(
              selected: selected,
              inGameLabel: 'Cinématiques in-game',
              presentationLabel: 'Cinématiques de présentation',
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Cinématiques in-game'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Cinématiques de présentation'));
    await tester.pump();

    expect(selected, PokeMapCinematicLibraryMode.presentation);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Cinématiques de présentation'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('breadcrumb activates folders and keeps current folder inert', (
    tester,
  ) async {
    var activated = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapCinematicBreadcrumb(
            semanticLabel: 'Chemin du dossier',
            items: [
              PokeMapCinematicBreadcrumbItem(
                label: 'Toutes les cinématiques',
                onPressed: () => activated = 'root',
              ),
              PokeMapCinematicBreadcrumbItem(
                label: 'Introductions',
                onPressed: () => activated = 'introductions',
              ),
              const PokeMapCinematicBreadcrumbItem(label: 'Chapitre 1'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Introductions'));
    expect(activated, 'introductions');
    expect(find.text('Chapitre 1'), findsOneWidget);
  });

  testWidgets('library state surfaces keep actions disabled while loading', (
    tester,
  ) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              const PokeMapCinematicLibraryStateSurface(
                state: PokeMapCinematicLibraryState.loading,
                title: 'Chargement',
                description: 'Chargement des cinématiques…',
                actionLabel: 'Réessayer',
              ),
              PokeMapCinematicLibraryStateSurface(
                state: PokeMapCinematicLibraryState.error,
                title: 'Impossible de charger',
                description: 'Le catalogue reste intact.',
                actionLabel: 'Réessayer',
                onAction: () => retries += 1,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(PokeMapCinematicSkeletonTile), findsNWidgets(3));
    await tester.tap(find.widgetWithText(PokeMapButton, 'Réessayer').last);
    expect(retries, 1);
  });
}
