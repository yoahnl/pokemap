import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_timeline_panel.dart';

void main() {
  testWidgets('supports additive selection and keyboard edit intents', (
    tester,
  ) async {
    final controller = CinematicTimelineEditingController();
    var duplicateCount = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicTimelinePanel(
          controller: controller,
          onDuplicateSelection: () async {
            duplicateCount++;
          },
          child: const Text('Timeline'),
        ),
      ),
    );
    controller.select('one');
    controller.select('two', additive: true);
    await tester.pump();

    expect(controller.selectedStepIds, {'one', 'two'});
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    expect(duplicateCount, 1);
  });

  test('tracks collapse lock mute and solo independently', () {
    final controller = CinematicTimelineEditingController();
    controller.toggleCollapsed('audio');
    controller.toggleLocked('audio');
    controller.toggleMuted('audio');
    controller.toggleSolo('audio');

    expect(
      controller.trackStates['audio'],
      const CinematicTimelineTrackState(
        isCollapsed: true,
        isLocked: true,
        isMuted: true,
        isSolo: true,
      ),
    );
  });
}
