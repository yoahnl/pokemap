import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_story_playback.dart';

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
      cinematics: [
        for (final policy in CinematicActorCompletionPolicy.values)
          CinematicAsset.fromJson({
            'id': policy.name,
            'title': policy.name,
            'mapId': 'room',
            'actorCompletionPolicy': policy.name,
            'requiredActors': [
              {'actorId': 'hero'},
            ],
            'movementTargets': [
              {'targetId': 'east', 'label': 'East'},
              {'targetId': 'south', 'label': 'South'},
            ],
            'stageContext': {
              'actorBindings': [
                {'actorId': 'hero', 'kind': 'player'},
              ],
              'stagePoints': [
                {'id': 'east', 'label': 'East', 'x': 8, 'y': 4},
                {'id': 'south', 'label': 'South', 'x': 8, 'y': 6},
              ],
              'movementTargetBindings': [
                for (final id in ['east', 'south'])
                  {'targetId': id, 'kind': 'stagePoint', 'sourceId': id},
              ],
            },
            'timeline': {
              'steps': [
                for (final id in ['east', 'south'])
                  {
                    'id': id,
                    'kind': 'actorMove',
                    'actorId': 'hero',
                    'targetId': id,
                    'durationMs': 1000,
                    'metadata': {
                      'actor.movementMode': 'walk',
                      'actor.pathMode': 'direct',
                    },
                  },
              ],
            },
          }),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'raster-tiles',
          name: 'Grass',
          relativePath: 'actors.png',
        ),
      ],
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
        layers: [
          (grass.map.layers.single as SmartTileLayer).copyWith(
            field: SmartTileField.cell(
              semanticCells: [
                for (var i = 0; i < 144; i++) i ~/ 12 == 4 ? 1 : 0,
              ],
            ),
          ),
        ],
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
      party: const PlayerParty(),
    );
    final session = await SpatialExplorationSession.load(
      bundle('room'),
      loadMap: (id) async => bundle(id),
      presentationStateProvider: () => state,
    );
    addTearDown(session.dispose);
    expect(session.bundle.map.entities, isEmpty);
    expect(session.frames(0), isNot(contains('party-companion')));
    state = state.copyWith(
      party: PlayerParty(members: [member('one', 'clockbird', 'bronze')]),
    );
    session.storyActive.value = true;
    expect(session.frames(.05), isNot(contains('party-companion')));
    expect(session.companionCharacterId, 'bird');
    session.storyActive.value = false;
    session.movement.setInput(x: 1, z: 0);
    for (var i = 0; i < 15; i++) {
      session.frames(.05);
    }
    final frame = session.frames(0)['party-companion']!;
    expect(frame.x, closeTo(session.movement.x - 1, .000001));
    expect(frame.z, session.movement.z);
    expect(session.companionCharacterId, 'bird');
    final companionCellX = session.companionPosition!.x.floor();
    final reaction = session.rasterAnimationElapsedMsForCell(
      'room',
      'grass',
      companionCellX,
      4,
      5000,
    );
    expect(
      reaction,
      greaterThan(0),
      reason:
          'The companion must replay grass after the hero reaction has ended.',
    );
    expect(reaction, lessThan(200));
    session.setLifecyclePaused(true);
    expect(session.frames(1)['party-companion']!.x, frame.x);
    expect(
      session.rasterAnimationElapsedMsForCell(
        'room',
        'grass',
        companionCellX,
        4,
        5000,
      ),
      reaction,
    );
    session.setLifecyclePaused(false);
    session.movement.releaseInput();
    session.storyActive.value = true;
    expect(session.frames(.1)['party-companion']!.x, frame.x);
    session.storyActive.value = false;
    expect(session.frames(0)['party-companion']!.x, frame.x);
    state = state.copyWith(
      playerPosition: GridPos(
        x: session.movement.x.floor(),
        y: session.movement.z.floor(),
      ),
      playerSpatialPosition: PlayerSpatialPosition(
        x: session.movement.x,
        z: session.movement.z,
      ),
    );
    final story = SpatialStoryPlayback(
      session: session,
      readGameState: () => state,
      writeGameState: (value) => state = value,
    );
    session.storyInputLocked = true;
    expect(session.frames(.1), contains('party-companion'));
    session.storyInputLocked = false;
    session.interactionActive.value = true;
    final beforeDialogue = session.companionPosition!;
    expect(session.frames(.5)['party-companion']!.x, beforeDialogue.x);
    expect(session.companionPosition!.z, beforeDialogue.z);
    session.interactionActive.value = false;
    for (final mode in ['restoreInitial', 'cancel', 'keepFinal']) {
      final initialCompanion = session.companionPosition!;
      final initialPlayer = state.playerSpatialPosition!;
      final completed = story.playCinematic(
        SceneRuntimePlanIntent.playCinematic(
          cinematicId: mode == 'cancel' ? 'keepFinal' : mode,
        ),
        'companion-test',
      );
      final rejected = mode == 'cancel'
          ? expectLater(completed, throwsStateError)
          : null;
      var previous = initialCompanion;
      for (var i = 0; i < (mode == 'cancel' ? 10 : 40); i++) {
        final visuals = session.frames(.05);
        final companion = visuals['party-companion'];
        expect(companion, isNotNull, reason: '$mode frame $i');
        final current = session.companionPosition!;
        if (story.cinematics.isPlaying) {
          expect(
            (current.x - previous.x).abs() + (current.z - previous.z).abs(),
            lessThan(.3),
          );
        }
        previous = current;
        if (i == 5) {
          session.setLifecyclePaused(true);
          final paused = session.companionPosition!;
          expect(session.frames(.5)['party-companion']!.x, paused.x);
          expect(session.companionPosition!.z, paused.z);
          session.setLifecyclePaused(false);
        }
      }
      if (mode == 'cancel') {
        story.cancel();
        expect(session.frames(0), contains('party-companion'));
        await rejected;
      } else {
        expect(await completed, 'completed');
      }
      final visuals = session.frames(0);
      expect(
        visuals.keys.where((key) => key == 'party-companion'),
        hasLength(1),
      );
      if (mode != 'keepFinal') {
        expect(session.companionPosition!.x, initialCompanion.x);
        expect(session.companionPosition!.z, initialCompanion.z);
        expect(state.playerSpatialPosition, initialPlayer);
      } else {
        expect(session.companionPosition!.x, 8);
        expect(session.companionPosition!.z, closeTo(5, .000001));
      }
    }
    story.dispose();
    session.heroStoryPose = null;
    session.onPresentationFrame = null;
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
      expect(session.companionCharacterId, isNull);
      expect(session.frames(0), isNot(contains('party-companion')));
      state = state.copyWith(party: PlayerParty(members: state.party.members.reversed.toList()));
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
