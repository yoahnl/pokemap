import 'package:avelune_studio/features/presentations/application/presentation_track_commands.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  setUp(() async => owner = await PresentationWorkspaceOwnerFixture.create());
  tearDown(() => owner.dispose());

  PresentationTrack track(String id) =>
      owner.asset.tracks.singleWhere((track) => track.id == id);

  bool apply(PresentationTimelineClipCommand command) =>
      owner.controller.apply(command.actionId, command.parameters);

  test('a track edit renames it and changes its hold policy on disk', () async {
    final title = track('title.track');
    expect(
      apply(
        presentationTrackUpdateCommand(
          owner.asset,
          title,
          label: 'Titre animé',
          holdPolicy: 'ambientContinues',
        ),
      ),
      isTrue,
      reason: owner.controller.error,
    );
    expect(track('title.track').label, 'Titre animé');
    expect(
      track('title.track').holdPolicy,
      PresentationHoldTrackPolicy.ambientContinues,
    );
    expect(track('title.track').clips, title.clips);

    expect(await owner.controller.save(), isTrue);
    final saved = (await owner.reread(owner.asset.id)).tracks.singleWhere(
      (track) => track.id == 'title.track',
    );
    expect(saved.label, 'Titre animé');
    expect(saved.holdPolicy, PresentationHoldTrackPolicy.ambientContinues);
  });

  test('moving a track stays inside the track list', () {
    final first = track('landscape.track'), last = track('title.track');
    expect(presentationTrackMoveCommand(owner.asset, first, -1), isNull);
    expect(presentationTrackMoveCommand(owner.asset, last, 1), isNull);

    final down = presentationTrackMoveCommand(owner.asset, first, 1)!;
    expect(down.parameters['insertionIndex'], 1);
    expect(apply(down), isTrue, reason: owner.controller.error);
    expect(owner.asset.tracks.map((track) => track.id), [
      'title.track',
      'landscape.track',
    ]);
  });

  test('a refused timeline command reports a banner and sends nothing', () {
    final sent = <PresentationTimelineClipCommand>[];
    final editing = owner.sessions.forAsset(owner.asset);
    expect(editing.hasClipboard, isFalse);

    final refusal = runPresentationTimelineCommand(
      () => editing.paste(atUs: 0),
      sent.add,
    );
    expect(refusal, startsWith('Opération refusée : '));
    expect(refusal, contains('clipboard is empty'));
    expect(sent, isEmpty);

    editing.selectClip('title.clip');
    expect(
      runPresentationTimelineCommand(editing.duplicateSelection, sent.add),
      isNull,
    );
    expect(sent.single.actionId, isNotEmpty);
  });
}
