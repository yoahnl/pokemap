import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('timeline ruler exposes duration and playhead semantically', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: PokeMapCinematicTimelineRuler(
              duration: Duration(seconds: 12),
              playhead: Duration(seconds: 4),
              pixelsPerSecond: 80,
              semanticLabel: 'Règle temporelle',
            ),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Règle temporelle')),
    );
    expect(semantics.label, contains('00:04'));
    expect(semantics.label, contains('00:12'));
    expect(
      tester.getSize(find.byType(PokeMapCinematicTimelineRuler)).width,
      960,
    );
  });

  testWidgets('viewport ruler keeps a bounded paint surface for long media', (
    tester,
  ) async {
    var seekX = -1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: PokeMapCinematicTimelineViewportRuler(
              duration: const Duration(minutes: 15),
              playhead: const Duration(minutes: 8),
              pixelsPerSecond: 120,
              scrollOffset: 57000,
              width: 720,
              semanticLabel: 'Règle virtualisée',
              onSeekAtX: (value) => seekX = value,
            ),
          ),
        ),
      ),
    );

    final ruler = find.byType(PokeMapCinematicTimelineViewportRuler);
    expect(tester.getSize(ruler).width, 720);
    expect(tester.getSemantics(ruler).label, contains('08:00'));

    await tester.tapAt(tester.getTopLeft(ruler) + const Offset(240, 12));
    expect(seekX, closeTo(240, 0.1));
  });

  testWidgets('clip owns width selection status and trim handles', (
    tester,
  ) async {
    var activations = 0;
    var startDelta = 0.0;
    var endDelta = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: PokeMapCinematicTimelineClip(
              label: 'Ouverture',
              duration: const Duration(milliseconds: 2500),
              pixelsPerSecond: 100,
              selected: true,
              tone: PokeMapTone.cinematic,
              onPressed: () => activations += 1,
              startTrimLabel: 'Rogner le début',
              endTrimLabel: 'Rogner la fin',
              onStartTrim: (value) => startDelta += value,
              onEndTrim: (value) => endDelta += value,
            ),
          ),
        ),
      ),
    );

    final clip = find.byType(PokeMapCinematicTimelineClip);
    expect(tester.getSize(clip).width, 250);
    expect(
      tester.getSemantics(clip).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Ouverture'));
    await tester.drag(
      find.bySemanticsLabel('Rogner le début'),
      const Offset(24, 0),
    );
    await tester.drag(
      find.bySemanticsLabel('Rogner la fin'),
      const Offset(-24, 0),
    );

    expect(activations, 1);
    expect(startDelta, greaterThan(0));
    expect(endDelta, lessThan(0));
  });

  testWidgets('pending and error clips expose explicit non-color states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: Row(
            children: [
              PokeMapCinematicTimelineClip(
                label: 'Import en cours',
                duration: Duration(seconds: 2),
                pixelsPerSecond: 90,
                state: PokeMapCinematicTimelineClipState.pending,
                stateLabel: 'En attente',
              ),
              PokeMapCinematicTimelineClip(
                label: 'Vidéo manquante',
                duration: Duration(seconds: 2),
                pixelsPerSecond: 90,
                state: PokeMapCinematicTimelineClipState.error,
                stateLabel: 'Erreur média',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Erreur média'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('track row hosts waveform or thumbnails without owning content', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: const Scaffold(
          body: PokeMapCinematicTrackRow(
            label: 'Musique',
            icon: Icons.music_note_rounded,
            child: PokeMapCinematicStripHost(
              semanticLabel: 'Forme d’onde de la musique',
              child: Text('waveform'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Musique'), findsOneWidget);
    expect(find.text('waveform'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(PokeMapCinematicStripHost)).label,
      contains('Forme d’onde de la musique'),
    );
    semantics.dispose();
  });
}
