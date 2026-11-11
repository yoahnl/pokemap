import 'package:avelune_studio/features/presentations/application/presentation_field_input.dart';
import 'package:avelune_studio/features/presentations/application/presentation_pose_projection.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  late Set<String> invalid;
  setUp(() async {
    owner = await PresentationWorkspaceOwnerFixture.create();
    invalid = owner.sessions.invalidFieldsFor(owner.asset.id);
  });
  tearDown(() => owner.dispose());

  PresentationTextClip title() => owner.clip('title.clip') as PresentationTextClip;

  bool patchTitle(Map<String, Object?> values) =>
      owner.controller.patchClip('title.clip', values);

  bool commitPose(
    String key,
    String text, {
    required PresentationPose pose,
    bool orientationOverride = false,
    double factor = 1,
  }) => commitPresentationPoseField(
    invalid,
    key,
    title(),
    key,
    text,
    pose: pose,
    orientationOverride: orientationOverride,
    portrait: false,
    apply: patchTitle,
    factor: factor,
  );

  test(
    'choosing the Player font clears the family and keeps the other style values',
    () async {
      expect(title().style.fontFamily, 'Helvetica Neue');
      expect(patchTitle(presentationFontFamilyPatch(title(), 'Georgia')), isTrue);
      expect(title().style.fontFamily, 'Georgia');
      final cleared = presentationFontFamilyPatch(title(), '')['style']! as Map;
      expect(cleared, containsPair('fontFamily', null));
      expect(cleared, containsPair('fontSize', 64.0));
      expect(patchTitle(presentationFontFamilyPatch(title(), '')), isTrue);
      expect(title().style.fontFamily, isNull);
      expect(title().style.fontSize, 64);
      expect(title().style.colorHex, '#FFF8E7');

      expect(await owner.controller.save(), isTrue);
      final saved = (await owner.reread(owner.asset.id)).tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == 'title.clip') as PresentationTextClip;
      expect(saved.style.fontFamily, isNull);
      expect(saved.style.weight, PresentationTextWeight.bold);
    },
  );

  test(
    'rotation is typed in degrees and stored in turns on the whole trajectory',
    () async {
      expect(
        commitPose(
          'rotationTurns',
          '90',
          pose: PresentationPose.trajectory,
          factor: presentationRotationDegreeFactor,
        ),
        isTrue,
      );
      expect(title().from.rotationTurns, closeTo(.25, 1e-9));
      expect(title().to.rotationTurns, closeTo(.25, 1e-9));
      expect(
        presentationPoseFieldValue(
          title(),
          'from',
          'rotationTurns',
          0,
          factor: presentationRotationDegreeFactor,
        ),
        closeTo(90, 1e-9),
      );

      expect(
        commitPose('translateX', '0,5', pose: PresentationPose.end),
        isTrue,
      );
      expect(title().to.translateX, .5);
      expect(title().from.translateX, 0);

      expect(
        commitPose('translateX', '-0.2', pose: PresentationPose.trajectory),
        isTrue,
      );
      expect(title().from.translateX, -.2);
      expect(title().to.translateX, -.2);

      expect(await owner.controller.save(), isTrue);
      final saved = (await owner.reread(owner.asset.id)).tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == 'title.clip') as PresentationTextClip;
      expect(saved.to.rotationTurns, closeTo(.25, 1e-9));
      expect(saved.to.translateX, -.2);
    },
  );

  test('an invalid pose value is flagged and leaves the clip untouched', () {
    final before = owner.asset;
    expect(
      commitPose('scaleX', 'grand', pose: PresentationPose.trajectory),
      isFalse,
    );
    expect(invalid, {'scaleX'});
    expect(owner.asset, same(before));
    expect(commitPose('scaleX', '2', pose: PresentationPose.start), isTrue);
    expect(invalid, isEmpty);
    expect(title().from.scaleX, 2);
    expect(title().to.scaleX, 1);
  });

  test('an orientation override reads its own pose with the field fallback', () {
    expect(
      presentationPoseFieldValue(
        title(),
        'landscapeCompositionOverride',
        'opacity',
        1,
      ),
      1,
    );
    expect(
      commitPose(
        'opacity',
        '0.4',
        pose: PresentationPose.trajectory,
        orientationOverride: true,
      ),
      isTrue,
      reason: owner.controller.error,
    );
    expect(title().landscapeCompositionOverride?.opacity, .4);
    expect(title().from.opacity, 1);
    expect(title().to.opacity, 1);
    expect(
      presentationPoseFieldValue(
        title(),
        'landscapeCompositionOverride',
        'opacity',
        1,
      ),
      .4,
    );
  });
}
