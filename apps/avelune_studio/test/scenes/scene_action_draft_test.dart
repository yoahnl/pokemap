import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final project = ProjectManifest(name: 'Actions', maps: [], tilesets: []);

  test(
    'wait defaults remain authorable and invalid duration blocks applying',
    () {
      final draft = SceneActionDraft(project: project, changed: () {});
      addTearDown(draft.dispose);
      draft.choose(NarrativeCommandIds.wait);
      expect(draft.values['durationMs'], '0');
      expect(draft.valid, isTrue);
      draft.changeParameter('durationMs', '-1');
      expect(draft.valid, isFalse);
      draft.changeParameter('durationMs', '2147483647');
      expect(draft.valid, isTrue);
      expect(draft.buildPayload(), isA<SceneActionPayload>());
    },
  );

  test(
    'an opaque unsupported action remains preserved until explicit choice',
    () {
      final original = SceneActionPayload(
        actionKind: 'opaque',
        parameters: const {'keep': 'metadata'},
      );
      final draft = SceneActionDraft(
        project: project,
        current: original,
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(draft.unsupported, isTrue);
      expect(draft.commandId, isNull);
      expect(draft.valid, isFalse);
      expect(draft.current, same(original));
      draft.choose(NarrativeCommandIds.wait);
      expect(draft.buildPayload(), isA<SceneActionPayload>());
      expect(draft.current, same(original));
    },
  );

  test('three dimensional projects do not expose two dimensional presentation commands', () {
    final draft = SceneActionDraft(
      project: project.copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ),
      changed: () {},
    );
    addTearDown(draft.dispose);
    final commands = draft.commands.map((command) => command.id).toSet();
    expect(commands, isNot(contains(NarrativeCommandIds.wait)));
    expect(commands, isNot(contains(NarrativeCommandIds.worldTone)));
    expect(commands, contains(NarrativeCommandIds.playModelAnimation));
  });

  test(
    'music operation changes clear stale media and restore operation defaults',
    () {
      final draft = SceneActionDraft(project: project, changed: () {});
      addTearDown(draft.dispose);
      draft.choose(NarrativeCommandIds.sceneMusic);
      draft.changeParameter('mediaAssetId', 'song');
      draft.changeParameter('channel', 'both');
      draft.changeParameter('operation', 'fadeOut');
      expect(draft.values['mediaAssetId'], isNull);
      expect(draft.values['volume'], isNull);
      expect(draft.values['durationMs'], '1000');
      expect(draft.values['channel'], 'music');
      draft.changeParameter('operation', 'play');
      expect(draft.values['durationMs'], isNull);
      expect(draft.values['volume'], '1');
    },
  );
}
