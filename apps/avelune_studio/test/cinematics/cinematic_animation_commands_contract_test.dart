
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController controller;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [CinematicAdapterFixture.asset('a')],
    );
    await f.writeManifest(
      (await f.readManifest()).copyWith(
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.single,
            ),
          ],
        ),
      ),
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    maps.project = (await f.readManifest());
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    controller = CinematicWorkspaceController(
      narrative,
      f.adapter(),
      changed: () {},
    );
    await controller.open('a');
  });
  tearDown(() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });
  test('animation uses canonical command, preserves unknown metadata and undoes repeat edit', () async {
    final actor = controller.addActor('Guide')!;
    final id = controller.addAnimation(
      CharacterCustomAnimationRuntimeCommand(
        actorId: actor,
        definitionId: 'wave',
      ),
      afterStepId: 'a.wait',
    )!;
    var step = controller.active!.asset.timeline.steps.last;
    expect(step.id, id);
    expect(
      cinematicCharacterCustomAnimationCommandOf(step)!.playback.kind,
      CharacterCustomAnimationPlaybackKind.once,
    );
    controller.edit(
      (asset) => asset.copyWith(
        timeline: CinematicTimeline(
          steps: [
            for (final s in asset.timeline.steps)
              if (s.id == id)
                CinematicTimelineStep.fromJson({
                  ...s.toJson(),
                  'metadata': {
                    ...s.metadata,
                    'pokemap.characterAnimation.future': 'retained',
                  },
                })
              else
                s,
          ],
        ),
      ),
    );
    expect(
      controller.updateAnimation(
        id,
        CharacterCustomAnimationRuntimeCommand(
          actorId: actor,
          definitionId: 'wave',
          playback: CharacterCustomAnimationPlayback.repeatCount(3),
        ),
      ),
      true,
    );
    step = controller.active!.asset.timeline.steps.last;
    expect(
      cinematicCharacterCustomAnimationCommandOf(step)!.playback.repeatCount,
      3,
    );
    expect(step.metadata['pokemap.characterAnimation.future'], 'retained');
    controller.undo();
    expect(
      cinematicCharacterCustomAnimationCommandOf(
        controller.active!.asset.timeline.steps.last,
      )!.playback.kind,
      CharacterCustomAnimationPlaybackKind.once,
    );
    controller.redo();
    expect(
      controller.updateAnimation(
        id,
        CharacterCustomAnimationRuntimeCommand(
          actorId: actor,
          definitionId: 'wave',
          direction: EntityFacing.south,
        ),
      ),
      false,
    );
    expect(
      cinematicCharacterCustomAnimationCommandOf(
        controller.active!.asset.timeline.steps.last,
      )!.playback.repeatCount,
      3,
    );
  });

  test(
    'two unpublished duplicates preserve distinct identities and first draft',
    () async {
      expect(await controller.duplicate('a'), true);
      final first = controller.activeId!;
      controller.rename('Premier brouillon');
      expect(await controller.duplicate('a'), true);
      final second = controller.activeId!;
      expect(second, isNot(first));
      expect(controller.session(first)!.asset.title, 'Premier brouillon');
      expect(controller.session(first)!.dirty, true);
      expect(controller.session(second)!.dirty, true);
      expect(controller.entries.map((e) => e.id).toSet().length, 3);
    },
  );
}
