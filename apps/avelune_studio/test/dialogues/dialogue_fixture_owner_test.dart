import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dialogue_workspace_owner_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui09_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'UI09 fixture opens editable canonical conversation, portrait and dirty consumer',
    () async {
      final fixture = await DialogueWorkspaceOwnerFixture.create();
      addTearDown(fixture.dispose);
      final scenes = SceneWorkspaceController(
        fixture.workspace,
        LocalSceneAdapter(
          session: fixture.source.session,
          mapAdapter: fixture.maps,
        ),
        narrative: fixture.narrative,
        changed: () {},
      );
      addTearDown(scenes.dispose);
      final dialogues = DialogueWorkspaceController(
        fixture.narrative,
        fixture.port,
        changed: () {},
        sceneDrafts: () => scenes.scenes,
      );
      addTearDown(dialogues.dispose);
      expect(await dialogues.open(ui09DialogueId), isTrue);
      expect(dialogues.active!.readOnlyReason, isNull);
      expect(dialogues.active!.document.nodes.length, 3);
      expect(await fixture.port.readPortrait('guide', 'neutral'), isNotEmpty);
      expect(scenes.open(Ui06SceneFixture.sceneId), isTrue);
      expect(
        scenes.active!.rename('Rencontre au guichet — brouillon conservé'),
        isTrue,
      );
      expect(scenes.dirty, isTrue);
      expect(dialogues.dirty, isFalse);
    },
    timeout: _slow,
  );
}

const _slow = Timeout(Duration(minutes: 3));
