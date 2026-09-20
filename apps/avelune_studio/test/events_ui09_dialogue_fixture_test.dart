import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui09_dialogue_fixture.dart';
import 'support/ui09_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'UI09 fixture opens editable canonical conversation, portrait and dirty consumer',
    () async {
      final fixture = await Ui09DialogueFixture.create();
      addTearDown(fixture.dispose);
      final maps = MapWorkspaceController(fixture.source.session, fixture.maps);
      await maps.initialize();
      addTearDown(maps.dispose);
      final narrative = NarrativeWorkspaceController(
        maps,
        LocalNarrativeAdapter(
          session: fixture.source.session,
          mapAdapter: fixture.maps,
        ),
        () {},
        (_, _) async {},
      );
      addTearDown(narrative.dispose);
      final scenes = SceneWorkspaceController(
        maps,
        fixture.scenes,
        narrative: narrative,
        changed: () {},
      );
      addTearDown(scenes.dispose);
      final dialogues = DialogueWorkspaceController(
        narrative,
        fixture.port,
        changed: () {},
        sceneDrafts: () => scenes.scenes,
      );
      addTearDown(dialogues.dispose);
      expect(await dialogues.open(ui09DialogueId), isTrue);
      expect(dialogues.active!.readOnlyReason, isNull);
      expect(dialogues.active!.document.nodes.length, 3);
      expect(await fixture.port.readPortrait('guide', 'neutral'), isNotEmpty);
      expect(fixture.dirtyConsumer(scenes), isTrue);
      expect(scenes.dirty, isTrue);
      expect(dialogues.dirty, isFalse);
    },
  );
}
