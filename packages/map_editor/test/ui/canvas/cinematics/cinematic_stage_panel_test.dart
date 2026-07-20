import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_storyboard_strip.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('owns a stable stage boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicStagePanel(child: Text('Stage child')),
      ),
    );

    expect(find.byKey(CinematicStagePanel.surfaceKey), findsOneWidget);
    expect(find.text('Stage child'), findsOneWidget);
  });

  testWidgets('opens storyboard without resizing the stage child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: SizedBox(
          width: 800,
          height: 500,
          child: CinematicStagePanel(
            cinematic: CinematicAsset(
              id: 'intro',
              title: 'Intro',
              timeline: CinematicTimeline(),
            ),
            child: const SizedBox.expand(
              key: ValueKey('stage-child'),
            ),
          ),
        ),
      ),
    );
    final before = tester.getSize(find.byKey(const ValueKey('stage-child')));

    expect(find.byKey(CinematicStoryboardStrip.stripKey), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('cinematic-storyboard-toggle')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CinematicStoryboardStrip.stripKey), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('stage-child'))), before);
  });
}
