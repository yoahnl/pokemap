import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  setUp(() async => owner = await PresentationWorkspaceOwnerFixture.create());
  tearDown(() => owner.dispose());

  PresentationTimelineEditingController editing() =>
      owner.sessions.forAsset(owner.asset);

  String trackOf(String clipId) => owner.asset.tracks
      .singleWhere((track) => track.clips.any((clip) => clip.id == clipId))
      .id;

  bool drag(
    String clipId,
    PresentationTimelineDragKind kind,
    int deltaUs, {
    String? targetTrackId,
  }) {
    final timeline = editing()..beginDrag(clipId: clipId, kind: kind);
    timeline.updateDrag(deltaUs: deltaUs, targetTrackId: targetTrackId);
    final command = timeline.finishDrag();
    return owner.controller.apply(command.actionId, command.parameters);
  }

  test(
    'a move past the end is clamped to the document bounds on the Studio path',
    () async {
      expect(owner.clip('title.clip').durationUs, 10000000);
      expect(
        drag('title.clip', PresentationTimelineDragKind.move, 5000000),
        isTrue,
        reason: owner.controller.error,
      );
      expect(owner.clip('title.clip').startUs, 2000000);
      expect(owner.clip('title.clip').endUs, owner.asset.durationUs);

      expect(
        drag('title.clip', PresentationTimelineDragKind.move, -9000000),
        isTrue,
      );
      expect(owner.clip('title.clip').startUs, 0);

      expect(
        drag('title.clip', PresentationTimelineDragKind.trimEnd, 8000000),
        isTrue,
      );
      expect(owner.clip('title.clip').endUs, owner.asset.durationUs);

      expect(await owner.controller.save(), isTrue);
      final saved = (await owner.reread(owner.asset.id)).tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == 'title.clip');
      expect(saved.startUs, 0);
      expect(saved.durationUs, owner.asset.durationUs);
    },
  );

  test(
    'a move onto an incompatible track keeps the clip on its track and leaves the document untouched',
    () {
      final marker = owner.controller.addMarker(timeUs: 1000000)!;
      final markerTrack = trackOf(marker);
      final before = owner.asset;

      final timeline = editing()
        ..beginDrag(clipId: 'title.clip', kind: PresentationTimelineDragKind.move)
        ..updateDrag(deltaUs: 0, targetTrackId: markerTrack);
      expect(timeline.finishDrag, throwsStateError);
      expect(owner.asset, same(before));
      expect(trackOf('title.clip'), 'title.track');

      final forced = PresentationTimelineClipCommand(
        actionId: 'presentationClip.batch',
        parameters: {
          'cinematicId': before.id,
          'operations': [
            {
              'kind': 'edit',
              'clipId': 'title.clip',
              'targetTrackId': markerTrack,
              'startUs': 0,
              'durationUs': 10000000,
            },
          ],
        },
      );
      expect(
        owner.controller.apply(forced.actionId, forced.parameters),
        isFalse,
      );
      expect(owner.controller.error, isNotNull);
      expect(owner.asset, same(before));
      expect(trackOf('title.clip'), 'title.track');
    },
  );

  test(
    'an incompatible target with a time delta only applies the time change',
    () {
      final marker = owner.controller.addMarker(timeUs: 1000000)!;
      final markerTrack = trackOf(marker);
      expect(
        drag(
          'title.clip',
          PresentationTimelineDragKind.move,
          1000000,
          targetTrackId: markerTrack,
        ),
        isTrue,
      );
      expect(trackOf('title.clip'), 'title.track');
      expect(owner.clip('title.clip').startUs, 1000000);
    },
  );
}
