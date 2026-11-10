import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_narrative_fixture.dart';

void main() {
  CinematicMapModel model() => CinematicMapModel(
    spatialNarrativeCinematic(),
    spatialNarrativeProject(),
    spatialNarrativeMap(),
  );

  test(
    '3D actor origin uses feet while authored stage points remain unchanged',
    () {
      final spatial = model();
      final npc = spatial.actors.actorById('chief')!.position;
      expect((npc.x, npc.y), (13.5, 7.5));
      final hero = spatial.actors.actorById('hero')!.position;
      expect((hero.x, hero.y), (8.5, 9.5));
      final twoD = CinematicMapModel(
        spatial.asset,
        spatial.project,
        spatial.map.copyWith(spatialScene: null),
      );
      expect(twoD.actors.actorById('chief')!.position.y, 7);
      expect(spatial.map.entities.single.pos, const GridPos(x: 13, y: 7));
      final fromTarget = CinematicMapModel(
        spatial.asset.copyWith(
          stageContext: CinematicStageContext(
            backdropMode: spatial.asset.stageContext!.backdropMode,
            actorBindings: spatial.asset.stageContext!.actorBindings,
            movementTargetBindings:
                spatial.asset.stageContext!.movementTargetBindings,
            stagePoints: spatial.asset.stageContext!.stagePoints,
            manualPaths: spatial.asset.stageContext!.manualPaths,
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'hero',
                kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                targetId: 'arrival',
              ),
              spatial.asset.stageContext!.initialPlacements.last,
            ],
          ),
        ),
        spatial.project,
        spatial.map,
      );
      final targetOrigin = fromTarget.actors.actorById('hero')!.position;
      expect((targetOrigin.x, targetOrigin.y), (13.5, 9.5));
    },
  );

  test(
    'authored path previews every terrain cell from start to destination',
    () {
      final source = model();
      final cells = cinematicPreviewCells(source);
      expect(cells, {(8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9)});
      final original = source.map.toJson();
      cinematicPreviewCells(source);
      expect(source.map.toJson(), original);
    },
  );

  test('sprite preview timing respects authored frame durations and loop', () {
    const frames = [
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16),
        durationMs: 100,
      ),
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 16, y: 0, width: 16, height: 16),
        durationMs: 200,
      ),
    ];
    expect(studioCinematicCharacterFrame(frames, 100, loop: true), frames[1]);
    expect(studioCinematicCharacterFrame(frames, 300, loop: true), frames[0]);
    expect(studioCinematicCharacterFrame(frames, 900, loop: false), frames[1]);
  });
}
