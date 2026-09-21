import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import '../support/presentation_controller_fixture.dart';

void main() {
  late PresentationControllerFixture f;
  late PresentationWorkspaceController c;
  setUp(() async {
    f = await PresentationControllerFixture.create();
    c = f.controller;
  });
  tearDown(() async {
    await f.dispose();
  });
  test(
    'create no disk write, grouped canonical intent, undo redo save and reopen',
    () async {
      final before = await f.files.file('project.json').readAsBytes();
      expect(await c.create(title: 'Introduction'), true, reason: c.error);
      expect(await f.files.file('project.json').readAsBytes(), before);
      final id = c.activeId!;
      expect(
        c.applyBatch([
          PresentationCommand('presentationTrack.create', {
            'track': {
              'id': 'markers',
              'label': 'Repères',
              'kind': 'marker',
              'clips': [],
            },
          }),
          PresentationCommand('presentationClip.create', {
            'trackId': 'markers',
            'clip': encodePresentationClip(
              PresentationMarkerClip(
                id: 'middle',
                startUs: 6000000,
                label: 'Milieu',
              ),
            ),
          }),
        ]),
        true,
        reason: c.error,
      );
      expect(c.active!.asset.tracks.single.clips.single.id, 'middle');
      c.undo();
      expect(c.active!.asset.tracks, isEmpty);
      c.redo();
      expect(c.active!.asset.tracks.single.clips.single.id, 'middle');
      c.flushEdits = () => c.rename('Titre encore focalisé');
      expect(await c.save(), true, reason: c.error);
      c.flushEdits = null;
      expect(
        (await f.port.inner.load(id)).asset.title,
        'Titre encore focalisé',
      );
      expect(c.active!.dirty, false);
    },
  );
  test(
    'failed grouped edit rolls back all commands and accepts correction',
    () async {
      await c.create(title: 'Test');
      final before = c.active!.asset;
      expect(
        c.applyBatch([
          PresentationCommand('presentationTrack.create', {
            'track': {
              'id': 'markers',
              'label': 'Repères',
              'kind': 'marker',
              'clips': [],
            },
          }),
          PresentationCommand('presentationClip.create', {
            'trackId': 'missing',
            'clip': encodePresentationClip(
              PresentationMarkerClip(
                id: 'middle',
                startUs: 6000000,
                label: 'Milieu',
              ),
            ),
          }),
        ]),
        false,
      );
      expect(c.active!.asset, before);
      expect(c.rename('Corrigé'), true);
      expect(c.error, isNull);
      c.flushEdits = () => false;
      expect(await c.save(), false);
      expect((await f.files.readManifest()).presentationCinematics, isEmpty);
      c.flushEdits = () => true;
      expect(await c.save(), true, reason: c.error);
    },
  );
  test('one shared draft, late opening cannot overwrite B', () async {
    await c.create(title: 'A');
    final a = c.activeId!;
    await c.save();
    await c.create(title: 'B');
    final b = c.activeId!;
    await c.save();
    await c.open(a);
    c.rename('Draft A');
    await c.open(b);
    await c.open(a);
    expect(c.active!.asset.title, 'Draft A');
    c.dispose();
    final other = PresentationWorkspaceController(
      f.narrative,
      f.port,
      changed: () {},
    );
    addTearDown(other.dispose);
    f.port.delayedId = a;
    f.port.loadGate = Completer<void>();
    final loading = other.open(a);
    await Future<void>.delayed(Duration.zero);
    expect(await other.open(b), true);
    f.port.loadGate!.complete();
    expect(await loading, false);
    expect(other.activeId, b);
  });
  test(
    'editing during save remains dirty and next save does not lose current text',
    () async {
      await c.create(title: 'Snapshot');
      f.port.publishGate = Completer<void>();
      final saved = c.save();
      await Future<void>.delayed(Duration.zero);
      expect(c.rename('Texte ultérieur'), true);
      f.port.publishGate!.complete();
      expect(await saved, true, reason: c.error);
      expect(c.active!.asset.title, 'Texte ultérieur');
      expect(c.active!.dirty, true);
      expect((await f.port.inner.load(c.activeId!)).asset.title, 'Snapshot');
      expect(await c.save(), true, reason: c.error);
      expect(c.active!.dirty, false);
    },
  );
  test(
    'unpublished duplicates have unique identities and do not replace original',
    () async {
      await c.create(title: 'Titre', templateId: 'titleIdentity');
      final original = c.active!.asset;
      expect(await c.duplicate(original.id), true, reason: c.error);
      final first = c.activeId;
      expect(await c.duplicate(original.id), true, reason: c.error);
      expect(c.activeId, isNot(first));
      expect(c.entries.length, 3);
      expect(c.assetFor(original.id), original);
      expect((await f.files.readManifest()).presentationCinematics, isEmpty);
    },
  );
  test('duplicate preserves canonical track hold policy', () async {
    await c.create(title: 'Musique en attente');
    expect(
      c.apply('presentationTrack.create', {
        'track': {
          'id': 'audio',
          'label': 'Musique',
          'kind': 'audio',
          'holdPolicy': 'ambientContinues',
          'clips': [],
        },
      }),
      true,
      reason: c.error,
    );
    final id = c.activeId!;
    expect(await c.duplicate(id), true, reason: c.error);
    expect(
      c.active!.asset.tracks.single.holdPolicy,
      PresentationHoldTrackPolicy.ambientContinues,
    );
  });
  test(
    'folder move stays in draft and participates in undo and publication',
    () async {
      await c.create(title: 'À classer');
      await c.save();
      final id = c.activeId!;
      final folder = await c.createFolder('Ouvertures');
      expect(folder, isNotNull, reason: c.error);
      expect(c.setFolder(id, folder), true, reason: c.error);
      expect(c.active!.dirty, true);
      expect((await f.port.inner.load(id)).entry!.folderId, isNull);
      c.undo();
      expect(c.active!.dirty, false);
      c.redo();
      expect(c.active!.folderId, folder);
      expect(await c.save(), true, reason: c.error);
      expect((await f.port.inner.load(id)).entry!.folderId, folder);
      expect(c.setFolder(id, null), true);
      expect(await c.save(), true, reason: c.error);
      expect((await f.port.inner.load(id)).entry!.folderId, isNull);
    },
  );
  test(
    'duplicate shares staged sources safely until both drafts are published',
    () async {
      await c.create(title: 'Image en préparation');
      final source = f.files.file('image.png');
      await source.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1cAAAAASUVORK5CYII=',
        ),
      );
      final media = await c.importMedia(
        sourcePath: source.path,
        label: 'Image',
        kind: ProjectMediaKind.image,
      );
      expect(media, isNotNull, reason: c.error);
      final a = c.activeId!;
      expect(await c.duplicate(a), true, reason: c.error);
      final b = c.activeId!;
      expect(await c.save(a), true, reason: c.error);
      expect(c.activeId, b);
      expect(await c.save(b), true, reason: c.error);
      expect((await f.files.readManifest()).presentationCinematics.length, 2);
      expect(
        (await f.port.inner.load(b)).projection.mediaCatalog.entries.length,
        1,
      );
    },
  );
}
