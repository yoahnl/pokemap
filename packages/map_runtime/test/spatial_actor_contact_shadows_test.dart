import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final sample in [
    (
      global: false,
      hero: null,
      npc: null,
      expectedHero: false,
      expectedNpc: false,
    ),
    (
      global: true,
      hero: null,
      npc: null,
      expectedHero: true,
      expectedNpc: true,
    ),
    (
      global: true,
      hero: false,
      npc: null,
      expectedHero: false,
      expectedNpc: true,
    ),
    (
      global: false,
      hero: null,
      npc: true,
      expectedHero: false,
      expectedNpc: true,
    ),
    (
      global: false,
      hero: true,
      npc: false,
      expectedHero: true,
      expectedNpc: false,
    ),
  ]) {
    test(
      'spatial actor contact shadows resolve project and resource $sample',
      () async {
        final root = await Directory.systemTemp.createTemp('actor-contact-');
        addTearDown(() => root.delete(recursive: true));
        final path = '${root.path}/actors.png';
        await File(path)
            .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
        ProjectCharacterEntry character(String id, bool? override) =>
            ProjectCharacterEntry.fromJson({
              'id': id,
              'name': id,
              'tilesetId': 'unused',
              'contactShadow': ?override,
              'animations': [
                for (final direction in EntityFacing.values)
                  CharacterAnimation(
                    state: CharacterAnimationState.walk,
                    direction: direction,
                    sourceAssetId: 'actors',
                    frames: const [
                      CharacterAnimationFrame(
                        source: TilesetSourceRect(
                          x: 0,
                          y: 0,
                          width: 32,
                          height: 32,
                        ),
                        durationMs: 100,
                      ),
                    ],
                  ).toJson(),
              ],
            });
        final project = ProjectManifest(
          name: 'Contact shadow inheritance',
          maps: const [],
          tilesets: const [],
          settings: ProjectSettings.fromJson({
            'dimension': 'threeD',
            'defaultPlayerCharacterId': 'hero',
            'actorContactShadowsByDefault': sample.global,
          }),
          characters: [
            character('hero', sample.hero),
            character('npc', sample.npc),
          ],
        );
        final session = await SpatialExplorationSession.load(
          RuntimeMapBundle(
            manifest: project,
            map: MapData(
              id: 'map',
              name: 'Map',
              size: const GridSize(width: 8, height: 8),
              entities: const [
                MapEntity(
                  id: 'person',
                  kind: MapEntityKind.npc,
                  pos: GridPos(x: 2, y: 3),
                  npc: MapEntityNpcData(characterId: 'npc'),
                ),
              ],
              spatialScene: MapSpatialScene(width: 8, depth: 8),
            ),
            projectRootDirectory: root.path,
            tilesetAbsolutePathsById: const {},
            characterAnimationAbsolutePathsByAssetId: {'actors': path},
          ),
        );
        addTearDown(session.dispose);
        final frames = session.frames(0);
        expect(frames['hero']!.contactShadow, sample.expectedHero);
        expect(frames['map:npc:person']!.contactShadow, sample.expectedNpc);
        expect(frames['map:npc:person']!.groundY, frames['map:npc:person']!.y);
        const pose = SpatialCinematicActorPose(
          x: 3.5,
          z: 4.5,
          facing: EntityFacing.south,
          liftCells: 1,
        );
        session.heroStoryPose = () => pose;
        session.npcStoryPose = (_) => pose;
        final lifted = session.frames(0);
        for (final id in ['hero', 'map:npc:person']) {
          expect(lifted[id]!.groundY, 0);
          expect(lifted[id]!.y, 1);
        }
        expect(lifted['hero']!.contactShadow, sample.expectedHero);
        expect(lifted['map:npc:person']!.contactShadow, sample.expectedNpc);
      },
    );
  }
}
