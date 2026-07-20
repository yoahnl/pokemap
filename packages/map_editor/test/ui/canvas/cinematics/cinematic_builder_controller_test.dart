import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_builder_controller.dart';

void main() {
  test('keeps local selection for the same asset and resets on asset switch',
      () {
    final controller = CinematicBuilderController(asset: _asset('first'));
    addTearDown(controller.dispose);

    controller
      ..selectedStepId = 'step_a'
      ..timelineProbeTimeMs = 420
      ..timelineProbeSnapHint = CinematicTimelineProbeSnapHint.blockStart
      ..selectedStagePointId = 'point_a'
      ..addStagePointMode = true;

    controller.synchronize(_asset('first'));
    expect(controller.selectedStepId, 'step_a');
    expect(controller.timelineProbeTimeMs, 420);

    controller.synchronize(_asset('second'));
    expect(controller.selectedStepId, isNull);
    expect(controller.timelineProbeTimeMs, isNull);
    expect(controller.timelineProbeSnapHint, isNull);
    expect(controller.selectedStagePointId, isNull);
    expect(controller.addStagePointMode, isFalse);
  });

  test('drops only a selected step that disappeared from the current asset',
      () {
    final controller = CinematicBuilderController(asset: _asset('first'));
    addTearDown(controller.dispose);
    controller
      ..selectedStepId = 'step_a'
      ..selectedStagePointId = 'point_a';

    controller.synchronize(_asset('first', includeStep: false));

    expect(controller.selectedStepId, isNull);
    expect(controller.selectedStagePointId, 'point_a');
  });
}

CinematicAsset _asset(String id, {bool includeStep = true}) => CinematicAsset(
      id: id,
      title: id,
      timeline: CinematicTimeline(
        steps: [
          if (includeStep)
            CinematicTimelineStep(
              id: 'step_a',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
        ],
      ),
    );
