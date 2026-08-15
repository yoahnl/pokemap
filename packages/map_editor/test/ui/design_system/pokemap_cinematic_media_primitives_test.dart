import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('visual slots distinguish orientations and expose fallback', (
    tester,
  ) async {
    final actions = <PokeMapCinematicMediaOrientation>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: PokeMapCinematicMediaSlot(
                  orientation: PokeMapCinematicMediaOrientation.landscape,
                  title: 'Version paysage',
                  state: PokeMapCinematicMediaSlotState.ready,
                  sourceLabel: 'ouverture-16x9.png',
                  actionLabel: 'Remplacer la version paysage',
                  onAction: () =>
                      actions.add(PokeMapCinematicMediaOrientation.landscape),
                ),
              ),
              Expanded(
                child: PokeMapCinematicMediaSlot(
                  orientation: PokeMapCinematicMediaOrientation.portrait,
                  title: 'Version portrait',
                  state: PokeMapCinematicMediaSlotState.ready,
                  sourceLabel: 'ouverture-16x9.png',
                  fallbackLabel: 'Fallback paysage',
                  actionLabel: 'Choisir une version portrait',
                  onAction: () =>
                      actions.add(PokeMapCinematicMediaOrientation.portrait),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Version paysage'), findsOneWidget);
    expect(find.text('Version portrait'), findsOneWidget);
    expect(find.text('Fallback paysage'), findsOneWidget);
    await tester.tap(find.text('Choisir une version portrait'));
    expect(actions, [PokeMapCinematicMediaOrientation.portrait]);
  });

  testWidgets('importing slot exposes progress and cancellable operation', (
    tester,
  ) async {
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapCinematicMediaSlot(
            orientation: PokeMapCinematicMediaOrientation.shared,
            title: 'Musique partagée',
            state: PokeMapCinematicMediaSlotState.importing,
            sourceLabel: 'theme-ouverture.ogg',
            statusLabel: 'Import 42 %',
            progress: 0.42,
            cancelLabel: 'Annuler l’import',
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.byType(PokeMapProgressBar), findsOneWidget);
    expect(find.text('Import 42 %'), findsOneWidget);
    await tester.tap(find.text('Annuler l’import'));
    expect(cancelled, isTrue);
  });

  testWidgets('unavailable media states remain explicit without color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: Column(
            children: [
              PokeMapCinematicMediaSlot(
                orientation: PokeMapCinematicMediaOrientation.landscape,
                title: 'Image manquante',
                state: PokeMapCinematicMediaSlotState.missing,
                statusLabel: 'Fichier introuvable',
              ),
              PokeMapCinematicMediaSlot(
                orientation: PokeMapCinematicMediaOrientation.portrait,
                title: 'Vidéo corrompue',
                state: PokeMapCinematicMediaSlotState.corrupt,
                statusLabel: 'Réimportation requise',
              ),
              PokeMapCinematicMediaSlot(
                orientation: PokeMapCinematicMediaOrientation.shared,
                title: 'Codec non supporté',
                state: PokeMapCinematicMediaSlotState.unsupported,
                statusLabel: 'Choisissez un autre format',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Fichier introuvable'), findsOneWidget);
    expect(find.text('Réimportation requise'), findsOneWidget);
    expect(find.text('Choisissez un autre format'), findsOneWidget);
    expect(find.byIcon(Icons.link_off_rounded), findsWidgets);
    expect(find.byIcon(Icons.broken_image_outlined), findsWidgets);
    expect(find.byIcon(Icons.block_rounded), findsWidgets);
  });

  testWidgets('catalog card preserves selection and pointer activation', (
    tester,
  ) async {
    var activations = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapCinematicMediaCatalogCard(
            title: 'Montagnes',
            metadata: 'PNG · 3840 × 2160',
            preview: const Icon(Icons.image_outlined),
            selected: true,
            onPressed: () => activations += 1,
          ),
        ),
      ),
    );

    final card = find.byType(PokeMapCinematicMediaCatalogCard);
    expect(
      tester.getSemantics(card).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.tap(card);
    expect(activations, 1);
  });
}
