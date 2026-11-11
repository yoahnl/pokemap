import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  setUp(() async => owner = await PresentationWorkspaceOwnerFixture.create());
  tearDown(() => owner.dispose());

  Set<String> clipIds(PresentationCinematicAsset asset) => {
    for (final track in asset.tracks)
      for (final clip in track.clips) clip.id,
  };

  test(
    'deleting the selected clips removes them in one undoable step',
    () async {
      final before = owner.asset;
      expect(owner.controller.deleteClips(const <String>{}), isFalse);
      expect(owner.asset, same(before));

      owner.controller.flushEdits = () => false;
      expect(owner.controller.deleteClips({'title.clip'}), isFalse);
      expect(owner.asset, same(before));
      owner.controller.flushEdits = null;

      expect(
        owner.controller.deleteClips({'title.clip', 'landscape.clip'}),
        isTrue,
        reason: owner.controller.error,
      );
      expect(clipIds(owner.asset), isEmpty);
      owner.controller.undo();
      expect(clipIds(owner.asset), {'title.clip', 'landscape.clip'});
      owner.controller.redo();

      expect(await owner.controller.save(), isTrue);
      expect(clipIds(await owner.reread(before.id)), isEmpty);
    },
  );

  test(
    'an added clip becomes the only selection and the playhead jumps to its start',
    () {
      final lease = Object();
      owner.sessions.bindPreview(
        lease,
        bind: (_) {},
        prepare: (_, {required portrait}) async {},
        release: () async {},
      );
      final transport = owner.sessions.transport;
      final editing = owner.sessions.forAsset(owner.asset)
        ..selectClip('title.clip');
      owner.sessions.installPreview(lease, owner.asset, portrait: false);
      transport.seek(4000000);

      final text = owner.controller.addText(timeUs: transport.timeUs)!;
      transport.seek(9000000);
      owner.sessions.revealAddedClip(lease, owner.asset, text, portrait: false);
      expect(editing.selectedClipIds, {text});
      expect(transport.asset, same(owner.asset));
      expect(transport.timeUs, 4000000);

      transport.seek(owner.asset.durationUs);
      final marker = owner.controller.addMarker(timeUs: transport.timeUs)!;
      owner.sessions.revealAddedClip(
        lease,
        owner.asset,
        marker,
        portrait: false,
      );
      expect(editing.selectedClipIds, {marker});
      expect(owner.clip(marker).startUs, 0);
      expect(transport.timeUs, 0);
    },
  );

  test(
    'a document ticket goes stale after an edit or when another document opens',
    () async {
      final ticket = owner.controller.documentTicket!;
      expect(ticket.id, owner.asset.id);
      expect(owner.controller.holdsDocument(ticket), isTrue);

      expect(
        owner.controller.patchClip('title.clip', {'text': 'Nouveau titre'}),
        isTrue,
      );
      expect(owner.controller.holdsDocument(ticket), isFalse);

      final fresh = owner.controller.documentTicket!;
      expect(owner.controller.holdsDocument(fresh), isTrue);
      expect(await owner.controller.create(title: 'Autre'), isTrue);
      expect(owner.controller.holdsDocument(fresh), isFalse);
      expect(await owner.controller.open(fresh.id), isTrue);
      expect(owner.controller.holdsDocument(fresh), isTrue);
    },
  );
}
