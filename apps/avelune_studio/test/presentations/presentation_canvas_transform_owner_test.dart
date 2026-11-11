import 'dart:ui';

import 'package:avelune_studio/features/presentations/application/presentation_canvas_transform.dart';
import 'package:avelune_studio/features/presentations/application/presentation_pose_projection.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  setUp(() async {
    owner = await PresentationWorkspaceOwnerFixture.create();
  });
  tearDown(() => owner.dispose());

  const bounds = Rect.fromLTWH(400, 200, 300, 120);
  const canvas = Size(1280, 720);
  final corners = [
    bounds.topLeft,
    bounds.topRight,
    bounds.bottomRight,
    bounds.bottomLeft,
  ];

  PresentationCanvasGestureUpdate drag(
    PresentationCanvasGesture gesture,
    Offset start,
    Offset point,
  ) => presentationCanvasGestureUpdate(
    owner.asset,
    owner.clip('title.clip'),
    gesture: gesture,
    start: start,
    point: point,
    initialBounds: bounds,
    canvasSize: canvas,
    pose: PresentationPose.trajectory,
    orientationOverride: false,
    portrait: false,
  );

  PresentationVisualComposition composition(
    PresentationCinematicAsset asset,
    String key,
  ) => presentationPose(
    asset.tracks
        .expand((track) => track.clips)
        .singleWhere((clip) => clip.id == 'title.clip'),
    key,
  );

  void expectOtherClipsUnchanged(
    PresentationCinematicAsset before,
    PresentationCinematicAsset after,
  ) {
    for (final track in before.tracks) {
      for (final clip in track.clips) {
        if (clip.id == 'title.clip') continue;
        expect(
          after.tracks
              .expand((t) => t.clips)
              .singleWhere((c) => c.id == clip.id),
          clip,
        );
      }
    }
  }

  test('real scale handle preview cancel and one undo', () {
    final original = owner.asset;
    final anchor = bounds.bottomRight + const Offset(5, 4);
    final gesture = presentationCanvasGestureAt(
      anchor,
      bounds: bounds,
      corners: corners,
    );
    expect(gesture, PresentationCanvasGesture.scale);

    final preview = drag(gesture, anchor, anchor + const Offset(88, 25));
    expect(preview.error, isNull);
    expect(preview.projection, isNotNull);
    expect(owner.asset, same(original));
    final committed = presentationCanvasCommittedPatch(
      preview.patch,
      const Offset(88, 25),
    )!;

    expect(owner.controller.patchClip('title.clip', committed), isTrue);
    final from = composition(owner.asset, 'from');
    expect(from.scaleX, from.scaleY);
    expect(from.scaleX, isNot(1.0));
    expect(from.translateX, composition(original, 'from').translateX);
    expectOtherClipsUnchanged(original, owner.asset);

    owner.controller.undo();
    expect(owner.asset, original);
    expect(owner.controller.canUndo, isFalse);

    final cancelled = drag(gesture, anchor, anchor + const Offset(40, 10));
    expect(cancelled.patch, isNotNull);
    expect(owner.asset, same(original));
    expect(
      presentationCanvasCommittedPatch(cancelled.patch, Offset.zero),
      isNull,
    );
    expect(presentationCanvasCommittedPatch(null, const Offset(4, 4)), isNull);
  });

  test('real rotate handle preview cancel and one undo', () {
    final original = owner.asset;
    final anchor = bounds.topCenter - const Offset(0, 22) + const Offset(6, 3);
    final gesture = presentationCanvasGestureAt(
      anchor,
      bounds: bounds,
      corners: corners,
    );
    expect(gesture, PresentationCanvasGesture.rotate);

    final preview = drag(
      gesture,
      anchor,
      bounds.centerRight + const Offset(60, 0),
    );
    expect(preview.error, isNull);
    expect(owner.asset, same(original));
    expect(owner.controller.patchClip('title.clip', preview.patch!), isTrue);
    final from = composition(owner.asset, 'from');
    expect(from.rotationTurns, isNot(0.0));
    expect(from.translateX, composition(original, 'from').translateX);
    expectOtherClipsUnchanged(original, owner.asset);

    owner.controller.undo();
    expect(owner.asset, original);
    expect(owner.controller.canUndo, isFalse);
  });

  test('gesture kind depends on the handle radius around the selection', () {
    expect(
      presentationCanvasGestureAt(
        bounds.topCenter - const Offset(0, 22) + const Offset(14, 0),
        bounds: bounds,
        corners: corners,
      ),
      PresentationCanvasGesture.move,
    );
    expect(
      presentationCanvasGestureAt(
        bounds.topLeft + const Offset(13, 0),
        bounds: bounds,
        corners: corners,
      ),
      PresentationCanvasGesture.scale,
    );
    expect(
      presentationCanvasGestureAt(bounds.topLeft, corners: corners),
      PresentationCanvasGesture.move,
    );
  });

  test('pose changes normalise translation and clamp scale', () {
    final identity = PresentationVisualComposition.identity;
    final move = presentationCanvasPoseChanges(
      gesture: PresentationCanvasGesture.move,
      pose: identity,
      start: const Offset(100, 100),
      point: const Offset(228, 172),
      initialBounds: bounds,
      canvasSize: canvas,
    );
    expect(move['translateX'], closeTo(.1, 1e-9));
    expect(move['translateY'], closeTo(.1, 1e-9));
    final shrink = presentationCanvasPoseChanges(
      gesture: PresentationCanvasGesture.scale,
      pose: identity,
      start: bounds.center + const Offset(1000, 0),
      point: bounds.center + const Offset(.001, 0),
      initialBounds: bounds,
      canvasSize: canvas,
    );
    expect(shrink['scaleX'], closeTo(.01, 1e-12));
    final grow = presentationCanvasPoseChanges(
      gesture: PresentationCanvasGesture.scale,
      pose: identity,
      start: bounds.center + const Offset(1, 0),
      point: bounds.center + const Offset(1000, 0),
      initialBounds: bounds,
      canvasSize: canvas,
    );
    expect(grow['scaleY'], 100);
    final turn = presentationCanvasPoseChanges(
      gesture: PresentationCanvasGesture.rotate,
      pose: identity,
      start: bounds.center + const Offset(10, 0),
      point: bounds.center + const Offset(0, 10),
      initialBounds: bounds,
      canvasSize: canvas,
    );
    expect(turn['rotationTurns'], closeTo(.25, 1e-9));
  });

  test('a projection the codec refuses is reported and never committed', () {
    final original = owner.asset;
    final refused = presentationCanvasGestureUpdate(
      owner.asset,
      owner.clip('title.clip'),
      gesture: PresentationCanvasGesture.move,
      start: Offset.zero,
      point: const Offset(10, 10),
      initialBounds: bounds,
      canvasSize: Size.zero,
      pose: PresentationPose.start,
      orientationOverride: false,
      portrait: false,
    );
    expect(refused.error, startsWith('Transformation refusée'));
    expect(refused.patch, isNull);
    expect(
      presentationCanvasCommittedPatch(refused.patch, const Offset(10, 10)),
      isNull,
    );
    expect(owner.asset, same(original));
  });
}
