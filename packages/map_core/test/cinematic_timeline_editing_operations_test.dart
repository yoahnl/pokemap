import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cinematic timeline editing', () {
    test('moves a multi-selection while preserving ids and relative order', () {
      final asset = _asset(6);

      final result = moveCinematicTimelineSteps(
        asset,
        stepIds: const {'step_1', 'step_3'},
        insertionIndex: 5,
      );

      expect(result.cinematic.timeline.steps.map((step) => step.id), [
        'step_0',
        'step_2',
        'step_4',
        'step_1',
        'step_3',
        'step_5',
      ]);
      expect(result.idRewrites, isEmpty);
      expect(result.previousCinematic, asset);
    });

    test('duplicates selection with fresh deterministic ids only', () {
      final result = duplicateCinematicTimelineSteps(
        _asset(3),
        stepIds: const {'step_0', 'step_1'},
      );

      expect(result.cinematic.timeline.steps.map((step) => step.id), [
        'step_0',
        'step_1',
        'step_0_copy',
        'step_1_copy',
        'step_2',
      ]);
      expect(result.idRewrites, {
        'step_0': 'step_0_copy',
        'step_1': 'step_1_copy',
      });
    });

    test('copy paste and delete are deterministic and atomic at 1000 steps',
        () {
      final asset = _asset(1000);
      final clipboard = copyCinematicTimelineSteps(
        asset,
        stepIds: const {'step_10', 'step_500', 'step_999'},
      );
      final restored = CinematicTimelineClipboard.fromJson(clipboard.toJson());

      final pasted = pasteCinematicTimelineSteps(
        asset,
        clipboard: restored,
        insertionIndex: 0,
      );
      final deleted = deleteCinematicTimelineSteps(
        pasted.cinematic,
        stepIds: pasted.idRewrites.values.toSet(),
      );

      expect(pasted.cinematic.timeline.steps, hasLength(1003));
      expect(deleted.cinematic, asset);
      expect(asset.timeline.steps, hasLength(1000));
    });

    test('rejects unknown ids before changing anything', () {
      final asset = _asset(3);
      expect(
        () => deleteCinematicTimelineSteps(
          asset,
          stepIds: const {'step_0', 'missing'},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(asset.timeline.steps, hasLength(3));
    });
  });
}

CinematicAsset _asset(int count) => CinematicAsset(
      id: 'timeline',
      title: 'Timeline',
      timeline: CinematicTimeline(
        steps: [
          for (var index = 0; index < count; index++)
            CinematicTimelineStep(
              id: 'step_$index',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
              metadata: {'index': '$index'},
            ),
        ],
      ),
    );
