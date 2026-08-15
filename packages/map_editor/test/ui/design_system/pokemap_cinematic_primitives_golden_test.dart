import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/cinematic/pokemap_cinematic_primitives_preview.dart';

import '../../support/narrative_studio_capture_fonts.dart';

const _fontFamily = 'PokeMapCinematicPrimitivesCapture';

void main() {
  setUpAll(() async {
    await loadNarrativeStudioCaptureFonts(textFamilies: const [_fontFamily]);
  });

  final previews = <({String name, Size size, Widget Function() build})>[
    (
      name: 'library',
      size: const Size(1000, 520),
      build: pokeMapCinematicLibraryPrimitivesPreview,
    ),
    (
      name: 'canvas_layers',
      size: const Size(1200, 680),
      build: pokeMapCinematicCanvasLayerPrimitivesPreview,
    ),
    (
      name: 'timeline_media',
      size: const Size(1200, 700),
      build: pokeMapCinematicTimelineMediaPrimitivesPreview,
    ),
  ];
  final themes = <({String name, ThemeData theme})>[
    (name: 'light', theme: _captureTheme(PokeMapTheme.light())),
    (name: 'dark', theme: _captureTheme(PokeMapTheme.dark())),
  ];

  for (final preview in previews) {
    for (final theme in themes) {
      testWidgets('${preview.name} matches ${theme.name} golden', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(preview.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.theme,
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('cinematic-primitives-golden'),
                child: preview.build(),
              ),
            ),
          ),
        );
        await tester.pump();

        await expectLater(
          find.byKey(const ValueKey('cinematic-primitives-golden')),
          matchesGoldenFile(
            'goldens/design_system/cinematic/${preview.name}_${theme.name}.png',
          ),
        );
      });
    }
  }
}

ThemeData _captureTheme(ThemeData theme) {
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: _fontFamily),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: _fontFamily),
  );
}
