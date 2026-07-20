import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_storyboard_strip.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('shows derived shots and previews a preset before applying', (
    tester,
  ) async {
    CinematicBlockingPresetPreview? applied;
    final cinematic = CinematicAsset(
      id: 'arrival',
      title: 'Arrival',
      mapId: 'port',
      timeline: CinematicTimeline(steps: [
        CinematicTimelineStep(
          id: 'marker',
          kind: CinematicTimelineStepKind.marker,
          label: 'Plan du quai',
        ),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: CinematicStoryboardStrip(
            cinematic: cinematic,
            onApplyPreset: (preview) async {
              applied = preview;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(CinematicStoryboardStrip.stripKey), findsOneWidget);
    expect(find.textContaining('Plan du quai'), findsOneWidget);
    expect(find.text('port'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-blocking-presets-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-blocking-preset-fadeTransition'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('3 blocs seront ajoutés'), findsOneWidget);
    expect(applied, isNull);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-blocking-preset-apply')),
    );
    await tester.pumpAndSettle();

    expect(applied?.kind, CinematicBlockingPresetKind.fadeTransition);
    expect(applied?.proposedSteps, hasLength(3));
  });

  testWidgets('surfaces incompatibility instead of partially applying', (
    tester,
  ) async {
    var applyCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: CinematicStoryboardStrip(
            cinematic: CinematicAsset(
              id: 'empty',
              title: 'Empty',
              timeline: CinematicTimeline(),
            ),
            onApplyPreset: (_) async {
              applyCount++;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-blocking-presets-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-blocking-preset-npcEntrance')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Preset incompatible'), findsOneWidget);
    final button = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('cinematic-blocking-preset-apply')),
    );
    expect(button.onPressed, isNull);
    expect(applyCount, 0);
  });
}
