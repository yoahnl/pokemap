import 'dart:async';

import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  setUp(() async => owner = await PresentationWorkspaceOwnerFixture.create());
  tearDown(() => owner.dispose());

  Future<List<String>> savedTitles() async => [
    for (final asset
        in (await owner.fixture.source.readManifest()).presentationCinematics)
      asset.title,
  ];

  test(
    'a second creation started while one is pending is refused and only one presentation reaches disk',
    () async {
      final titlesBefore = await savedTitles();
      final gate = Completer<void>();
      owner.port.gate = gate.future;

      final first = owner.controller.create(title: 'Première');
      expect(owner.controller.busy, isTrue);
      expect(await owner.controller.create(title: 'Seconde'), isFalse);
      expect(owner.controller.error, isNull);
      expect(owner.controller.busy, isTrue);

      gate.complete();
      expect(await first, isTrue, reason: owner.controller.error);
      expect(owner.controller.active!.asset.title, 'Première');
      expect(
        owner.controller.entries.where((asset) => asset.title == 'Seconde'),
        isEmpty,
      );
      expect(await owner.controller.save(), isTrue);

      final titlesAfter = await savedTitles();
      expect(titlesAfter.length, titlesBefore.length + 1);
      expect(titlesAfter.where((title) => title == 'Première'), hasLength(1));
      expect(titlesAfter, isNot(contains('Seconde')));
    },
  );

  test('a failed creation releases the guard for the next one', () async {
    final gate = Completer<void>();
    owner.port.gate = gate.future;
    final failing = owner.controller.create(title: 'Échec');
    gate.completeError(StateError('Disque indisponible'));
    expect(await failing, isFalse);
    expect(owner.controller.error, contains('Disque indisponible'));

    owner.port.gate = null;
    expect(await owner.controller.create(title: 'Reprise'), isTrue);
    expect(owner.controller.active!.asset.title, 'Reprise');
  });

  test('sequential creations are still accepted', () async {
    expect(await owner.controller.create(title: 'Un'), isTrue);
    final firstId = owner.controller.activeId;
    expect(await owner.controller.create(title: 'Deux'), isTrue);
    expect(owner.controller.activeId, isNot(firstId));
    expect(
      owner.controller.entries.map((asset) => asset.title),
      containsAll(['Un', 'Deux']),
    );
  });
}
