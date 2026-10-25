import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_render_3d/src/spatial_actor_occlusion.dart';

import 'support/spatial_smart_tile_fixture.dart';

import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'landing starts exactly one grass reaction and none during the jump',
    () async {
      final session = await _session();
      int elapsed() =>
          session.rasterAnimationElapsedMsForCell('field', 'grass', 4, 5, 5000);
      session.movement.setInput(x: 0, z: 1);
      session.frames(.05);
      session.movement.releaseInput();
      expect(session.movement.isJumping, isTrue);
      while (session.movement.isJumping) {
        expect(elapsed(), 0);
        session.frames(.05);
      }
      expect(session.movement.z.floor(), 5);
      expect(elapsed(), 0);
      session.frames(.05);
      expect(elapsed(), 50);
      session.setLifecyclePaused(true);
      session.frames(.5);
      expect(elapsed(), 50);
      session.setLifecyclePaused(false);
      session.frames(.05);
      expect(elapsed(), 100);
      session.frames(.05);
      expect(elapsed(), 150);
      session.frames(.05);
      expect(elapsed(), 0);
      for (var i = 0; i < 5; i++) {
        session.frames(.05);
        expect(elapsed(), 0);
      }
    },
  );

  test(
    'companion landing replays grass after the hero without airborne reactions',
    () async {
      final session = await _session(companion: true);
      int elapsed() =>
          session.rasterAnimationElapsedMsForCell('field', 'grass', 4, 5, 5000);
      session.movement.setInput(x: 0, z: 1);
      var sawCompanionJump = false;
      var landed = false;
      for (var i = 0; i < 100; i++) {
        final previous = session.companionPosition;
        session.frames(.05);
        final current = session.companionPosition;
        if (current?.airborne == true) sawCompanionJump = true;
        if (previous?.airborne == true &&
            current != null &&
            !current.airborne &&
            current.z.floor() == 5) {
          landed = true;
          session.movement.releaseInput();
          expect(elapsed(), 0);
          session.frames(.05);
          expect(elapsed(), 50);
          break;
        }
      }
      expect(sawCompanionJump, isTrue);
      expect(landed, isTrue);
      session.frames(.05);
      expect(elapsed(), 100);
    },
  );
  test(
    'displayed hero and NPC poses drive independent occlusion occupancy',
    () async {
      final session = await _session(occlusion: true);
      ({bool active, int elapsedMs}) at(int x) =>
          session.actorOcclusionStateForCell('field', 'grass', x, 5, 5000);
      session.frames(0);
      final plan = SpatialActorOcclusionPlan(
        session.bundle.map,
        session.bundle.manifest,
      );
      List<SpatialActorOcclusionVisual> visibleContacts() => plan.resolve(
        5000,
        stateForCell: (layer, x, y, time) =>
            session.actorOcclusionStateForCell('field', layer, x, y, time),
      );
      SpatialActorOcclusionVisual contact(int x) =>
          visibleContacts().firstWhere((v) => v.visual.cellX == x);
      final fixedContact = contact(4);
      expect((fixedContact.x, fixedContact.z), (4.5, 6.125));
      expect(at(4), (active: true, elapsedMs: 200));
      expect(at(5), (active: true, elapsedMs: 200));
      session.heroStoryPose = () => const SpatialCinematicActorPose(
        x: 4.5625,
        z: 5.0625,
        facing: EntityFacing.south,
      );
      session.frames(0);
      expect(
        (contact(4).x, contact(4).y, contact(4).z),
        (fixedContact.x, fixedContact.y, fixedContact.z),
      );
      expect(at(4), (active: true, elapsedMs: 200));
      session.heroStoryPose = () => const SpatialCinematicActorPose(
        x: 5.5,
        z: 5.5,
        facing: EntityFacing.south,
      );
      session.frames(.05);
      expect(at(4).active, isFalse);
      expect(visibleContacts().where((v) => v.visual.cellX == 4), isEmpty);
      expect((contact(5).x, contact(5).z), (5.5, 6.125));
      expect(at(5), (active: true, elapsedMs: 0));
      session.heroStoryPose = () => const SpatialCinematicActorPose(
        x: 5.5625,
        z: 5.0625,
        facing: EntityFacing.south,
      );
      session.frames(.05);
      expect((contact(5).x, contact(5).z), (5.5, 6.125));
      expect(at(5), (active: true, elapsedMs: 50));
      session.setLifecyclePaused(true);
      session.frames(.5);
      expect((contact(5).x, contact(5).z), (5.5, 6.125));
      expect(at(5), (active: true, elapsedMs: 50));
      session.setLifecyclePaused(false);
      session.heroStoryPose = () => const SpatialCinematicActorPose(
        x: 5.5,
        z: 5.5,
        facing: EntityFacing.south,
        liftCells: 1,
      );
      session.frames(.05);
      expect(at(5).active, isTrue);
      expect(at(5).elapsedMs, greaterThanOrEqualTo(200));
      session.entityIsPresent = (_, _) => false;
      session.frames(.05);
      expect(at(5).active, isFalse);
      expect(visibleContacts(), isEmpty);
      expect(
        session
            .actorOcclusionStateForCell('missing', 'grass', 5, 5, 5000)
            .active,
        isFalse,
      );
    },
  );
}

Future<SpatialExplorationSession> _session({
  bool companion = false,
  bool occlusion = false,
}) async {
  final root = await Directory.systemTemp.createTemp('grass-landing-');
  addTearDown(() => root.delete(recursive: true));
  final image = '${root.path}/actors.png';
  await File(image)
      .writeAsBytes(img.encodePng(img.Image(width: 64, height: 32)));
  final grass = spatialRasterGrassFixture();
  final characters = [
    for (final id in ['hero', 'companion'])
      ProjectCharacterEntry(
        id: id,
        name: id,
        tilesetId: 'unused',
        frameWidth: 1,
        frameHeight: 1,
        animations: [
          for (final facing in EntityFacing.values)
            for (final state in [
              CharacterAnimationState.idle,
              CharacterAnimationState.walk,
            ])
              CharacterAnimation(
                state: state,
                direction: facing,
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
              ),
        ],
      ),
  ];
  final project = grass.project.copyWith(
    settings: const ProjectSettings(
      dimension: ProjectDimension.threeD,
      tileWidth: 32,
      tileHeight: 32,
      defaultPlayerCharacterId: 'hero',
    ),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'raster-tiles',
        name: 'Grass',
        relativePath: 'actors.png',
      ),
    ],
    characters: characters,
    smartTileCatalog: occlusion
        ? ProjectSmartTileCatalog(
            atlases: grass.project.smartTileCatalog.atlases,
            animations: grass.project.smartTileCatalog.animations,
            materials: [
              grass.project.smartTileCatalog.materials.single.copyWith(
                pathSurfaceKind: PathSurfaceKind.tallGrass,
              ),
            ],
            presets: [
              for (final p in grass.project.smartTileCatalog.presets)
                p.copyWith(
                  rules: [
                    for (final r in p.rules)
                      r.copyWith(
                        candidates: [
                          for (final c in r.candidates)
                            c.copyWith(
                              parts: [
                                for (final v in c.parts)
                                  v.copyWith(
                                    channel:
                                        SmartTileRenderChannel.actorOcclusion,
                                    offsetUnit: SmartTileOffsetUnit.pixel,
                                    offsetX: -16,
                                    offsetY: 20,
                                    footprintWidth: 2,
                                    footprintHeight: 2,
                                  ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          )
        : grass.project.smartTileCatalog,
    partyCompanion: ProjectPartyCompanionConfig(
      enabled: companion,
      mappings: const [
        PartyCompanionVisual(
          speciesId: 'bird',
          formId: 'normal',
          characterId: 'companion',
        ),
      ],
    ),
  );
  final map = grass.map.copyWith(
    entities: occlusion
        ? [
            MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 5, y: 5),
              npc: const MapEntityNpcData(characterId: 'hero'),
            ),
          ]
        : const [],
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(
          x: 4.5,
          z: occlusion
              ? 5.5
              : companion
              ? 2.5
              : 3.5,
        ),
        ledges: [
          SpatialLedge(
            id: 'drop',
            x: 4,
            z: 3,
            direction: SpatialRampDirection.south,
            distance: 2,
            durationMs: 400,
            height: .65,
          ),
        ],
      ),
    ),
  );
  final state = GameState(
    saveId: 'save',
    currentMapId: 'field',
    party: PlayerParty(
      members: [
        PlayerPokemon(
          individualId: 'one',
          speciesId: 'bird',
          formId: 'normal',
          natureId: 'hardy',
          abilityId: 'natural',
          currentHp: 10,
        ),
      ],
    ),
  );
  final session = await SpatialExplorationSession.load(
    RuntimeMapBundle(
      manifest: project,
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: {'raster-tiles': image},
      characterAnimationAbsolutePathsByAssetId: {'actors': image},
    ),
    presentationStateProvider: () => state,
  );
  addTearDown(session.dispose);
  return session;
}
