import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/cinematic/pokemap_cinematic_primitives_preview.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  final themes = <ThemeData>[PokeMapTheme.light(), PokeMapTheme.dark()];
  final sizes = <Size>[
    const Size(800, 720),
    const Size(1280, 800),
    const Size(1920, 1080),
  ];
  final previews = <Widget Function()>[
    pokeMapCinematicLibraryPrimitivesPreview,
    pokeMapCinematicCanvasLayerPrimitivesPreview,
    pokeMapCinematicTimelineMediaPrimitivesPreview,
  ];

  for (var themeIndex = 0; themeIndex < themes.length; themeIndex++) {
    for (final size in sizes) {
      for (
        var previewIndex = 0;
        previewIndex < previews.length;
        previewIndex++
      ) {
        testWidgets(
          'preview $previewIndex renders in theme $themeIndex at ${size.width.toInt()}px',
          (tester) async {
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));

            await tester.pumpWidget(
              MaterialApp(
                theme: themes[themeIndex],
                home: Scaffold(body: previews[previewIndex]()),
              ),
            );

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'interactive primitives support English at 200 percent text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                PokeMapCinematicFamilyTabs(
                  selected: PokeMapCinematicLibraryMode.inGame,
                  inGameLabel: 'In-game cinematics',
                  presentationLabel: 'Presentation cinematics',
                  onChanged: (_) {},
                ),
                PokeMapCinematicWorkspaceToolbar(
                  backLabel: 'Back to library',
                  title: 'Opening cinematic',
                  contextLabel: 'Presentation cinematic',
                  onBack: () {},
                  status: const PokeMapCinematicDocumentStatus(
                    state: PokeMapCinematicDocumentState.saved,
                    label: 'Saved',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Presentation cinematics'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    },
  );

  testWidgets('disabled family tabs expose disabled semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: const Scaffold(
          body: PokeMapCinematicFamilyTabs(
            selected: PokeMapCinematicLibraryMode.inGame,
            inGameLabel: 'Cinématiques in-game',
            presentationLabel: 'Cinématiques de présentation',
            onChanged: null,
          ),
        ),
      ),
    );

    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Cinématiques in-game'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    semantics.dispose();
  });
}
