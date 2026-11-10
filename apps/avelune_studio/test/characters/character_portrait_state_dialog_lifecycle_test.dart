import 'dart:async';

import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:avelune_studio/features/characters/coordination/character_studio_portrait_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const character = ProjectCharacterEntry(
    id: 'voyageuse',
    name: 'Voyageuse',
    tilesetId: 'voyageuse',
    frameWidth: 1,
    frameHeight: 1,
  );
  const project = ProjectManifest(
    name: 'Expressions',
    maps: [],
    tilesets: [],
    characters: [character],
  );

  test('portrait state creation retains normalized command and completed saving state', () async {
    final calls = <(String, Map<String, Object?>)>[];
    final controller = CharacterStudioController(
      project: () => project,
      mutate: (action, parameters) async {
        calls.add((action, parameters));
        return project;
      },
    );
    addTearDown(controller.dispose);
    expect(await controller.createPortraitState(' Neutre accentué '), isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.$1, 'characterStudio.portraitState.create');
    expect(calls.single.$2, {'displayName': 'Neutre accentué'});
    expect(controller.error, isNull);
    expect(controller.saving, isFalse);
  });

  test('pending portrait state prevents duplicate operation and refusal remains retryable', () async {
    final pending = Completer<ProjectManifest>();
    var calls = 0;
    final controller = CharacterStudioController(
      project: () => project,
      mutate: (_, _) {
        calls++;
        return calls == 1 ? pending.future : Future.value(project);
      },
    );
    addTearDown(controller.dispose);
    final opening = controller.createPortraitState('Neutre');
    expect(controller.saving, isTrue);
    expect(await controller.createPortraitState('Duplicate'), isFalse);
    expect(calls, 1);
    pending.completeError(StateError('portrait.refused'));
    expect(await opening, isFalse);
    expect(controller.error, contains('portrait.refused'));
    expect(controller.saving, isFalse);
    expect(await controller.createPortraitState('Neutre'), isTrue);
    expect(controller.error, isNull);
    expect(calls, 2);
  });
}
