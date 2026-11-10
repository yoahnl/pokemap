import 'package:avelune_studio/features/presentations/application/presentation_pose_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final clip = PresentationTextClip(
    id: 'title',
    layerId: 'heading',
    startUs: 0,
    durationUs: 1000000,
    text: 'Titre',
    from: PresentationVisualComposition(translateX: .1, scaleX: 2),
    to: PresentationVisualComposition(translateX: .8, scaleX: 4),
  );
  test(
    'pose and orientation resolve independent canonical keys with fallback',
    () {
      expect(
        presentationPoseKey(
          pose: PresentationPose.end,
          orientationOverride: false,
          portrait: false,
        ),
        'to',
      );
      expect(
        presentationPoseKey(
          pose: PresentationPose.end,
          orientationOverride: true,
          portrait: true,
        ),
        'portraitCompositionOverride',
      );
      expect(
        presentationPoseKey(
          pose: PresentationPose.start,
          orientationOverride: true,
          portrait: false,
        ),
        'landscapeCompositionOverride',
      );
      expect(presentationPose(clip, 'portraitCompositionOverride'), clip.from);
      expect(presentationPose(clip, 'to'), clip.to);
      final patch = presentationPosePatch(
        clip,
        {'translateX': .4},
        pose: PresentationPose.end,
        orientationOverride: true,
        portrait: true,
      );
      expect(patch.keys, ['portraitCompositionOverride']);
      expect((patch.values.single as Map)['translateX'], .4);
    },
  );
  test(
    'absolute trajectory edits apply both endpoints without changing source',
    () {
      final before = encodePresentationClip(clip);
      final patch = presentationPosePatch(
        clip,
        {'translateX': .3},
        pose: PresentationPose.trajectory,
        orientationOverride: false,
        portrait: false,
      );
      expect((patch['from'] as Map)['translateX'], .3);
      expect((patch['to'] as Map)['translateX'], .3);
      expect(encodePresentationClip(clip), before);
    },
  );
  test('gesture trajectory preserves endpoint deltas and scale ratios', () {
    final patch = presentationPosePatch(
      clip,
      {'translateX': .3, 'scaleX': 3},
      pose: PresentationPose.trajectory,
      orientationOverride: false,
      portrait: false,
      preserveTrajectoryDelta: true,
    );
    expect((patch['from'] as Map)['translateX'], .3);
    expect((patch['to'] as Map)['translateX'], closeTo(1, .000001));
    expect((patch['to'] as Map)['scaleX'], 6);
    expect(clip.to.translateX, .8);
    expect(clip.from.scaleX, 2);
  });
}
