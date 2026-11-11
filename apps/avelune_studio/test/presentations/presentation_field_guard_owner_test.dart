import 'dart:async';

import 'package:avelune_studio/features/presentations/application/presentation_field_input.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  late Set<String> invalid;
  setUp(() async {
    owner = await PresentationWorkspaceOwnerFixture.create();
    invalid = owner.sessions.invalidFieldsFor(owner.asset.id);
    owner.controller.flushEdits = () => presentationFieldsCommitted(invalid);
  });
  tearDown(() => owner.dispose());

  bool commitClipField(
    String label,
    String key,
    String text, {
    double factor = 1,
  }) => commitPresentationField(
    invalid,
    label,
    parsePresentationFieldText(text, key, numeric: true, factor: factor),
    (value) => owner.controller.patchClip(
      'title.clip',
      presentationFieldPatch(key, value),
    ),
  );

  test(
    'invalid focused duration blocks save and switching until corrected',
    () async {
      final before = owner.asset;
      final id = before.id;

      expect(
        commitClipField('Durée (s)', 'durationUs', '-2', factor: 1e6),
        isFalse,
      );
      expect(invalid, {'Durée (s)'});
      expect(owner.asset, same(before));
      expect(await owner.controller.save(), isFalse);
      expect(owner.port.writes, 0);
      expect(await owner.controller.create(title: 'Autre montage'), isFalse);
      expect(owner.controller.activeId, id);
      expect(await owner.controller.open(id), isFalse);
      expect(owner.asset, same(before));

      expect(
        commitClipField('Durée (s)', 'durationUs', '8', factor: 1e6),
        isTrue,
      );
      expect(invalid, isEmpty);
      expect(
        await owner.controller.save(),
        isTrue,
        reason: owner.controller.error,
      );
      expect(owner.port.writes, 1);
      expect(owner.controller.active!.dirty, isFalse);
      final saved = (await owner.reread(id)).tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == 'title.clip');
      expect(saved.durationUs, 8000000);
    },
  );

  test('numeric fields accept commas and refuse non finite text', () {
    expect(
      parsePresentationFieldText('1,5', 'startUs', numeric: true, factor: 1e6),
      1500000,
    );
    expect(parsePresentationFieldText('0,25', 'volume', numeric: true), .25);
    expect(parsePresentationFieldText('abc', 'volume', numeric: true), isNull);
    expect(
      parsePresentationFieldText('Infinity', 'volume', numeric: true),
      isNull,
    );
    expect(
      parsePresentationFieldText('Bonjour', 'text', numeric: false),
      'Bonjour',
    );
    expect(
      presentationFieldPatch(
        'fontSize',
        48.0,
        group: {'weight': 'bold'},
        groupKey: 'style',
      ),
      {
        'style': {'weight': 'bold', 'fontSize': 48.0},
      },
    );
    final kept = <String>{'Volume'};
    expect(commitPresentationField(kept, 'Volume', null, (_) => true), isFalse);
    expect(kept, {'Volume'});
  });

  test('document duration accepts decimal seconds and refuses zero', () async {
    expect(parsePresentationDocumentDurationUs('8,5'), 8500000);
    expect(parsePresentationDocumentDurationUs('0'), isNull);
    expect(parsePresentationDocumentDurationUs('-1'), isNull);
    final before = owner.asset;
    expect(
      commitPresentationField(
        invalid,
        presentationDocumentDurationField,
        parsePresentationDocumentDurationUs('0'),
        (_) => true,
      ),
      isFalse,
    );
    expect(await owner.controller.save(), isFalse);
    expect(
      commitPresentationField(
        invalid,
        presentationDocumentDurationField,
        parsePresentationDocumentDurationUs('14'),
        (durationUs) => owner.controller.apply(
          'presentationCinematic.update',
          presentationDurationUpdate(owner.asset, durationUs as int),
        ),
      ),
      isTrue,
      reason: owner.controller.error,
    );
    expect(invalid, isEmpty);
    expect(owner.asset.durationUs, 14000000);
    expect(owner.asset.title, before.title);
    expect(owner.asset.description, before.description);
  });

  test('transitions default to half a second capped by the clip', () {
    final clip = owner.clip('title.clip');
    expect(presentationTransitionPatch(clip, 'transitionIn', 'fade'), {
      'transitionIn': {'kind': 'fade', 'durationUs': 500000},
    });
    expect(presentationTransitionPatch(clip, 'transitionOut', 'none'), {
      'transitionOut': {'kind': 'none', 'durationUs': 0},
    });
    final short = PresentationTextClip(
      id: 'short',
      startUs: 0,
      durationUs: 200000,
      layerId: 'title',
      text: 'Bref',
    );
    expect(presentationTransitionPatch(short, 'transitionIn', 'slideLeft'), {
      'transitionIn': {'kind': 'slideLeft', 'durationUs': 200000},
    });
    expect(
      owner.controller.patchClip(
        'title.clip',
        presentationTransitionPatch(clip, 'transitionIn', 'fade'),
      ),
      isTrue,
      reason: owner.controller.error,
    );
  });

  test(
    'blank to image text canvas timeline save and reopen via controls',
    () async {
      final id = owner.asset.id;
      expect(
        owner.controller.patchClip(
          'title.clip',
          presentationFieldPatch('text', 'Horizon ✦ départ — été'),
        ),
        isTrue,
      );
      final editing = owner.sessions.forAsset(owner.asset);
      editing.configureAsset(owner.asset);
      editing.selectClip('title.clip');
      editing.beginDrag(
        clipId: 'title.clip',
        kind: PresentationTimelineDragKind.move,
      );
      editing.updateDrag(deltaUs: 1000000);
      final command = editing.finishDrag();
      expect(
        owner.controller.apply(command.actionId, command.parameters),
        isTrue,
        reason: owner.controller.error,
      );
      final moved = owner.clip('title.clip');
      expect(moved.startUs, greaterThan(0));
      expect(moved.durationUs, 10000000);

      expect(
        await owner.controller.save(),
        isTrue,
        reason: owner.controller.error,
      );
      expect(owner.controller.active!.dirty, isFalse);
      final reopened = await owner.reread(id);
      expect(reopened, owner.asset);
      final text = reopened.tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == 'title.clip');
      expect((text as PresentationTextClip).text, 'Horizon ✦ départ — été');
    },
  );

  test('a slow creation shows progress and blocks a second start', () async {
    final gate = Completer<void>();
    owner.port.gate = gate.future;
    final creating = owner.controller.create(title: 'Montage lent');
    await Future<void>.delayed(Duration.zero);
    expect(owner.controller.busy, isTrue);

    gate.complete();
    expect(await creating, isTrue, reason: owner.controller.error);
    expect(owner.controller.busy, isFalse);
    expect(owner.asset.title, 'Montage lent');
  });
}
