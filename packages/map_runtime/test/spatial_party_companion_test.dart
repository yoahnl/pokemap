import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/spatial_smart_tile_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real party companion changes with team, pauses and traverses maps without NPC state', () async {
    final root = await Directory.systemTemp.createTemp(
      'spatial-party-companion-',
    );
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/actors.png';
    await File(path)
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final characters = [
      for (final id in ['hero', 'bird', 'flower', 'moth'])
        ProjectCharacterEntry(
          id: id,
          name: id,
          tilesetId: 'unused',
          frameWidth: 1,
          frameHeight: 1,
          animations: [
            for (final facing in EntityFacing.values)
              for (final motion in [
                CharacterAnimationState.idle,
                CharacterAnimationState.walk,
              ])
                CharacterAnimation(
                  state: motion,
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
    final grass = spatialRasterGrassFixture();
    final project = ProjectManifest(
      name: 'Generic companions',
      version: ProjectVersion.v9,
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
      ),
      maps: const [],
      tilesets: const [ProjectTilesetEntry(id: 'raster-tiles', name: 'Grass', relativePath: 'actors.png')],
      smartTileCatalog: grass.project.smartTileCatalog,
      characters: characters,
      partyCompanion: const ProjectPartyCompanionConfig(
        enabled: true,
        mappings: [
          PartyCompanionVisual(
            speciesId: 'clockbird',
            formId: 'bronze',
            characterId: 'bird',
          ),
          PartyCompanionVisual(
            speciesId: 'flower',
            formId: 'night',
            characterId: 'flower',
          ),
          PartyCompanionVisual(
            speciesId: 'moth',
            formId: 'snow',
            characterId: 'moth',
          ),
        ],
      ),
    );
    RuntimeMapBundle bundle(String id) => RuntimeMapBundle(
      manifest: project,
      map: MapData(
        id: id,
        name: id,
        version: ProjectVersion.v9,
        size: const GridSize(width: 12, height: 12),
        layers: [(grass.map.layers.single as SmartTileLayer).copyWith(
          field: SmartTileField.cell(semanticCells: [
            for (var i = 0; i < 144; i++) i ~/ 12 == 4 ? 1 : 0,
          ]),
        )],
        spatialScene: MapSpatialScene(
          width: 12,
          depth: 12,
          navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
        ),
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: {'raster-tiles': path},
      characterAnimationAbsolutePathsByAssetId: {'actors': path},
    );
    PlayerPokemon member(
      String individualId,
      String speciesId,
      String formId, {
      int hp = 10,
    }) => PlayerPokemon(
      individualId: individualId,
      speciesId: speciesId,
      formId: formId,
      natureId: 'hardy',
      abilityId: 'natural',
      currentHp: hp,
    );
    var state = GameState(
      saveId: 'save',
      currentMapId: 'room',
      party: PlayerParty(members: [member('one', 'clockbird', 'bronze')]),
    );
    final session = await SpatialExplorationSession.load(
      bundle('room'),
      loadMap: (id) async => bundle(id),
      presentationStateProvider: () => state,
    );
    addTearDown(session.dispose);
    expect(session.bundle.map.entities, isEmpty);
    expect(session.frames(0), isNot(contains('party-companion')));
    session.movement.setInput(x: 1, z: 0);
    for (var i = 0; i < 15; i++) {
      session.frames(.05);
    }
    final frame = session.frames(0)['party-companion']!;
    expect(frame.x, closeTo(session.movement.x - 1, .000001));
    expect(frame.z, session.movement.z);
    expect(session.companionCharacterId, 'bird');
    final companionCellX = session.companionPosition!.x.floor();
    final reaction = session.rasterAnimationElapsedMsForCell('room', 'grass', companionCellX, 4, 5000);
    expect(reaction, greaterThan(0), reason: 'The companion must replay grass after the hero reaction has ended.');
    expect(reaction, lessThan(200));
    session.setLifecyclePaused(true);
    expect(session.frames(1)['party-companion']!.x, frame.x);
    expect(session.rasterAnimationElapsedMsForCell('room', 'grass', companionCellX, 4, 5000), reaction);
    session.setLifecyclePaused(false);
    session.movement.releaseInput();
    session.storyActive.value = true;
    expect(session.frames(.1), isNot(contains('party-companion')));
    session.storyActive.value = false;
    expect(session.frames(0), isNot(contains('party-companion')));
    for (final next in [
      ('two', 'flower', 'night', 'flower'),
      ('three', 'moth', 'snow', 'moth'),
    ]) {
      state = state.copyWith(
        party: PlayerParty(
          members: [
            member('fainted', 'clockbird', 'bronze', hp: 0),
            member(next.$1, next.$2, next.$3),
          ],
        ),
      );
      session.frames(0);
      expect(session.companionCharacterId, next.$4);
      expect(session.companionPosition, isNull);
    }
    state = GameState.fromJson(state.toJson()).copyWith(
      currentMapId: 'second',
      playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 4),
    );
    await session.restoreGameState(state);
    expect(session.bundle.map.id, 'second');
    expect(session.frames(0), isNot(contains('party-companion')));
    session.movement.setInput(x: 0, z: 1);
    for (var i = 0; i < 15; i++) {
      session.frames(.05);
    }
    expect(session.frames(0), contains('party-companion'));
    expect(session.companionCharacterId, 'moth');
    expect(
      state.spatialWorldState.toJson(),
      const SpatialWorldState.empty().toJson(),
    );
    state = state.copyWith(party: const PlayerParty());
    expect(session.frames(0), isNot(contains('party-companion')));
  });
}
