@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_actor_overlay.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';

void main() {
  late CinematicWorkspaceOwnerFixture owner;
  late CinematicWorkspaceController controller;
  setUp(() async {
    owner = await CinematicWorkspaceOwnerFixture.create();
    controller = owner.controller;
    await owner.open();
  });
  tearDown(() => owner.dispose());

  test('preview directions map to map facings with south as the fallback', () {
    expect(cinematicActorFacing(CinematicActorPreviewDirection.north), EntityFacing.north);
    expect(cinematicActorFacing(CinematicActorPreviewDirection.west), EntityFacing.west);
    expect(cinematicActorFacing(CinematicActorPreviewDirection.unknown), EntityFacing.south);
  });

  test('the active custom animation picks the clip of its direction or a generic one', () {
    const character = ProjectCharacterEntry(
      id: 'guide',
      name: 'Guide',
      tilesetId: 'guide_sheet',
      customAnimations: [
        CharacterCustomAnimationClip(
          definitionId: 'wave',
          direction: EntityFacing.north,
          sourceAssetId: 'wave_north',
        ),
        CharacterCustomAnimationClip(definitionId: 'wave', sourceAssetId: 'wave_any'),
        CharacterCustomAnimationClip(
          definitionId: 'bow',
          direction: EntityFacing.east,
          sourceAssetId: 'bow_east',
        ),
      ],
    );
    CharacterCustomAnimationRuntimeCommand command(
      String definitionId, [
      EntityFacing? direction,
    ]) => CharacterCustomAnimationRuntimeCommand(
      actorId: 'chief',
      definitionId: definitionId,
      direction: direction,
    );

    expect(
      cinematicActorCustomClip(character, command('wave'), EntityFacing.north)?.sourceAssetId,
      'wave_north',
    );
    expect(
      cinematicActorCustomClip(character, command('wave'), EntityFacing.south)?.sourceAssetId,
      'wave_any',
    );
    expect(
      cinematicActorCustomClip(
        character,
        command('bow', EntityFacing.east),
        EntityFacing.west,
      )?.sourceAssetId,
      'bow_east',
    );
    expect(cinematicActorCustomClip(character, command('bow'), EntityFacing.west), isNull);
    expect(cinematicActorCustomClip(character, null, EntityFacing.north), isNull);
    expect(cinematicActorCustomClip(null, command('wave'), EntityFacing.north), isNull);
  });

  test('a jumping actor is drawn above its ground row by the lift of the frame', () async {
    final jump = controller.addJump(
      'hero',
      'destination',
      afterStepId: 'opening',
      heightCells: 2,
    )!;
    final model = CinematicMapModel(
      controller.active!.asset,
      controller.projectWith(controller.active!.asset),
      await owner.loadMap('jardin'),
    );
    controller.preparePreview(
      actorDisplay: model.actors,
      resolvedTargets: model.targets,
      stageBounds: model.bounds,
    );
    final transport = controller.transport;
    final item = transport.plan!.timelineItems.singleWhere((i) => i.stepId == jump);

    transport.seek(item.startMs);
    final ground = transport.frame!.actorPoseById('hero')!;
    expect(cinematicActorLiftedRow(ground.y!, ground.liftCells), ground.y);

    transport.seek((item.startMs + item.endMs) ~/ 2);
    final top = transport.frame!.actorPoseById('hero')!;
    expect(top.liftCells, closeTo(2, .01));
    expect(cinematicActorLiftedRow(top.y!, top.liftCells), closeTo(top.y! - 2, .01));
    expect(cinematicActorLiftedRow(top.y!, top.liftCells), lessThan(top.y!));
  });
}
