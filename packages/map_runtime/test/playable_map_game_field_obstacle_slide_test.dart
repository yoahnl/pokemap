import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeTilesetImageLoader;

import '../../map_gameplay/test/support/moving_platform_fixture.dart';
import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a pushed boulder crosses ice by ticks while the player advances once',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final game = await _load(onMovement: movements.add);
      _press(game, RuntimeInputControl.right);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 3, y: 2));
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
      expect(game.canCapturePlayerCheckpoint, isFalse);
      game.update(.125);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 3, y: 2));
      game.update(.125);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 4, y: 2));
      await _frames(game, 16);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 8, y: 2));
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(movements, hasLength(1));
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      expect(game.canCapturePlayerCheckpoint, isTrue);
      await _frames(game, 8);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 8, y: 2));
    },
  );

  test(
    'live blockers stop the boulder and suppress held and buffered movement',
    () async {
      final game = await _load(
        entities: const [
          MapEntity(
            id: 'wall',
            kind: MapEntityKind.npc,
            npc: MapEntityNpcData(),
            pos: GridPos(x: 6, y: 2),
            blocksMovement: true,
          ),
        ],
      );
      _press(game, RuntimeInputControl.right);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.menu),
        ),
        isTrue,
      );
      game.setPlayerMovementMode(MovementMode.surf);
      expect(game.playerMovementMode, MovementMode.walk);
      await _frames(game, 16);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 5, y: 2));
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(
          RuntimeInputControl.right,
          isRepeat: true,
        ),
      );
      await _frames(game, 4);
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      _press(game, RuntimeInputControl.down);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      await _frames(game, 2);
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 3));
    },
  );

  test(
    'save and load refuse active boulder motion then restore a stationary pose',
    () async {
      final repository = _Repository();
      final game = await _load(repository: repository);
      _press(game, RuntimeInputControl.right);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.saves, 0);
      expect(repository.loads, 0);
      await _frames(game, 16);
      expect(await game.saveGame(), isTrue);
      expect(repository.saves, 1);
      final restored = await _load(
        initialState: gameStateFromStrictSaveJson(
          strictGameStateSaveJson(repository.state!),
        ),
      );
      await _frames(restored, 12);
      expect(
        restored.debugMapEntityPosition('boulder'),
        const GridPos(x: 8, y: 2),
      );
      expect(restored.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(restored.canCapturePlayerCheckpoint, isTrue);
      expect(await game.loadGame(), isTrue);
      await _frames(game, 12);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 8, y: 2));
    },
  );

  test(
    'ordinary Strength preserves a held direction across key repeats',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final base = _bundle();
      final game = await _load(
        bundle: base.copyWith(map: base.map.copyWith(gameplayZones: [])),
        onMovement: movements.add,
      );
      _press(game, RuntimeInputControl.right);
      game.update(.125);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(
          RuntimeInputControl.right,
          isRepeat: true,
        ),
      );
      game.update(.125);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 4, y: 2));
      expect(movements, hasLength(2));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      await _frames(game, 4);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 4, y: 2));
    },
  );

  test(
    'ordinary Strength preserves held sprint while retaining traversal guards',
    () async {
      final base = _bundle();
      final game = await _load(
        bundle: base.copyWith(
          map: base.map.copyWith(gameplayZones: []),
          tilesetAbsolutePathsById: const {'runner': '/tmp/boulder-runner.png'},
          characterAnimationAbsolutePathsByAssetId: const {
            'runner-run': '/tmp/boulder-runner-run.png',
          },
          manifest: base.manifest.copyWith(
            settings: base.manifest.settings.copyWith(
              defaultPlayerCharacterId: 'runner',
            ),
            characters: [
              ProjectCharacterEntry(
                id: 'runner',
                name: 'Runner',
                tilesetId: 'runner',
                animations: [
                  for (final direction in EntityFacing.values)
                    CharacterAnimation(
                      state: CharacterAnimationState.run,
                      direction: direction,
                      sourceAssetId: 'runner-run',
                      frames: const [
                        CharacterAnimationFrame(
                          source: TilesetSourceRect(
                            x: 0,
                            y: 0,
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        imageLoader: (paths, {transparentColorByTilesetId = const {}}) async =>
            {
              'runner': await runtimeTilesetImage(const [ui.Color(0xFF22AA44)]),
              'character-animation:runner-run': await runtimeTilesetImage(
                const [ui.Color(0xFF22AA44)],
              ),
            },
      );
      expect(game.inputAuthoritySnapshot.sprintAllowed, isTrue);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.sprint),
      );
      expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
      _press(game, RuntimeInputControl.right);
      expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
      expect(game.canCapturePlayerCheckpoint, isFalse);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.menu),
        ),
        isTrue,
      );
      game.setPlayerMovementMode(MovementMode.surf);
      expect(game.playerMovementMode, MovementMode.walk);
      game.update(.125);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 4, y: 2));
      expect(game.inputAuthoritySnapshot.sprintAccepted, isTrue);
      game.setExternalInputLock(
        RuntimeExternalInputLock.pauseMenu,
        locked: true,
      );
      expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.sprint),
      );
      game.setExternalInputLock(
        RuntimeExternalInputLock.pauseMenu,
        locked: false,
      );
      await _frames(game, 4);
      expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
    },
  );

  test(
    'a generic ice puzzle permits a deliberate second push after its stop',
    () async {
      final game = await _load(
        entities: const [
          MapEntity(
            id: 'stop',
            kind: MapEntityKind.npc,
            npc: MapEntityNpcData(),
            pos: GridPos(x: 7, y: 2),
            blocksMovement: true,
          ),
        ],
      );
      _press(game, RuntimeInputControl.right);
      await _frames(game, 16);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 6, y: 2));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      for (final control in [
        RuntimeInputControl.down,
        for (var x = 0; x < 4; x++) RuntimeInputControl.right,
        RuntimeInputControl.up,
      ]) {
        _press(game, control);
        game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
        await _frames(game, 2);
      }
      expect(game.debugPlayerGridPosition, const GridPos(x: 6, y: 2));
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 6, y: 1));
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    },
  );

  for (final owner in [
    RuntimeExternalInputLock.pauseMenu,
    RuntimeExternalInputLock.lifecycle,
  ]) {
    test(
      '${owner.name} suspends boulder continuation and resumes its pose',
      () async {
        final game = await _load();
        _press(game, RuntimeInputControl.right);
        game.setExternalInputLock(owner, locked: true);
        await _frames(game, 8);
        expect(
          game.debugMapEntityPosition('boulder'),
          const GridPos(x: 3, y: 2),
        );
        expect(game.canCapturePlayerCheckpoint, isFalse);
        game.setExternalInputLock(owner, locked: false);
        await _frames(game, 16);
        expect(
          game.debugMapEntityPosition('boulder'),
          const GridPos(x: 8, y: 2),
        );
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      },
    );
  }

  test('runtime removal clears swept reservations and a fresh restore has no inertia', () async {
    final game = await _load();
    _press(game, RuntimeInputControl.right);
    game.update(.125);
    final state = game.gameStateSnapshot;
    expect(
      game.debugScriptedNpcDynamicBlockedCells(),
      contains(const GridPos(x: 3, y: 2)),
    );
    game.onRemove();
    expect(
      game.debugScriptedNpcDynamicBlockedCells(),
      isNot(contains(const GridPos(x: 3, y: 2))),
    );
    final restored = await _load(
      initialState: gameStateFromStrictSaveJson(strictGameStateSaveJson(state)),
    );
    await _frames(restored, 16);
    expect(
      restored.debugMapEntityPosition('boulder'),
      const GridPos(x: 3, y: 2),
    );
    expect(restored.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
    expect(restored.canCapturePlayerCheckpoint, isTrue);
  });

  test('a moving NPC reservation stops the next boulder step', () async {
    final base = _bundle(
      entities: const [
        MapEntity(
          id: 'walker',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 4, y: 1),
          blocksMovement: true,
          npc: MapEntityNpcData(
            characterId: 'walker-character',
            movement: MapEntityNpcMovementConfig(
              mode: MapEntityNpcMovementMode.fixedRoute,
              loop: false,
              pauseDurationMs: 100,
              stepDurationMs: 1000,
              routeSteps: [
                MapEntityNpcRouteStep.move(direction: EntityFacing.south),
              ],
            ),
          ),
        ),
      ],
    );
    final game = await _load(
      bundle: base.copyWith(
        manifest: base.manifest.copyWith(
          characters: const [
            ProjectCharacterEntry(
              id: 'walker-character',
              name: 'Walker',
              tilesetId: 'walker-sheet',
            ),
          ],
        ),
      ),
    );
    game.update(.101);
    expect(
      game.debugScriptedNpcDynamicBlockedCells(),
      contains(const GridPos(x: 4, y: 2)),
    );
    _press(game, RuntimeInputControl.right);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    game.update(.25);
    expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 3, y: 2));
    await _frames(game, 8);
    expect(game.debugMapEntityPosition('walker'), const GridPos(x: 4, y: 2));
    expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 3, y: 2));
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
  });

  test(
    'an autonomous NPC waits for the boulder swept source reservation',
    () async {
      final base = _bundle(
        entities: const [
          MapEntity(
            id: 'walker',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 1),
            blocksMovement: true,
            npc: MapEntityNpcData(
              characterId: 'walker-character',
              movement: MapEntityNpcMovementConfig(
                mode: MapEntityNpcMovementMode.fixedRoute,
                loop: false,
                pauseDurationMs: 100,
                stepDurationMs: 100,
                routeSteps: [
                  MapEntityNpcRouteStep.move(direction: EntityFacing.south),
                ],
              ),
            ),
          ),
        ],
      );
      final game = await _load(
        bundle: base.copyWith(
          manifest: base.manifest.copyWith(
            characters: const [
              ProjectCharacterEntry(
                id: 'walker-character',
                name: 'Walker',
                tilesetId: 'walker-sheet',
              ),
            ],
          ),
        ),
      );
      _press(game, RuntimeInputControl.right);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      game.update(.25);
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 4, y: 2));
      expect(
        game.debugScriptedNpcDynamicBlockedCells(),
        contains(const GridPos(x: 3, y: 2)),
      );
      game.update(.125);
      expect(game.debugMapEntityPosition('walker'), const GridPos(x: 3, y: 1));
      await _frames(game, 16);
      expect(game.debugMapEntityPosition('walker'), const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 8, y: 2));
    },
  );

  for (final closesOnRoute in [false, true]) {
    test(
      'the live open prop pose controls boulder collision closedOnRoute=$closesOnRoute',
      () async {
        final fixture = MovingPlatformFixture();
        final closed = closesOnRoute
            ? const PixelOffset(x: 160, y: 64)
            : const PixelOffset(x: 160, y: 128);
        final open = closesOnRoute
            ? const PixelOffset(x: 160, y: 128)
            : const PixelOffset(x: 160, y: 64);
        final map = fixture.map.copyWith(
          layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
          movingPlatforms: [],
          gameplayZones: const [_ice],
          entities: _bundle().map.entities,
          placedElements: [
            MapPlacedElement(
              id: 'gate-art',
              layerId: 'magma',
              elementId: 'platform-0',
              pos: GridPos(x: closed.x ~/ 32, y: closed.y ~/ 32),
              applyCollision: false,
              properties: const {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
              },
            ),
          ],
          movingProps: [
            MovingPropDefinition(
              id: 'gate',
              placedElementId: 'gate-art',
              closedPositionPx: closed,
              openPositionPx: open,
              collisionRect: const PixelRect(
                leftPx: 0,
                topPx: 0,
                widthPx: 32,
                heightPx: 32,
              ),
            ),
          ],
        );
        final game = await _load(
          bundle: RuntimeMapBundle(
            map: map,
            manifest: fixture.project.copyWith(
              maps: const [
                ProjectMapEntry(
                  id: 'gym',
                  name: 'Gym',
                  relativePath: 'maps/gym.json',
                ),
              ],
            ),
            projectRootDirectory: '/tmp/boulder-slide-runtime',
            tilesetAbsolutePathsById: const {},
          ),
          initialState: _state().copyWith(
            currentMapId: 'gym',
            mapInstanceWorldState: MapInstanceWorldState(
              instancesByMapId: {
                'gym': MapInstanceRuntimeState(
                  instanceId: 'gym-instance',
                  strengthActive: true,
                ),
              },
            ),
            movingPropWorldState: const MovingPropWorldState.empty().withProp(
              mapId: 'gym',
              propId: 'gate',
              state: MovingPropState.open,
            ),
          ),
        );
        _press(game, RuntimeInputControl.right);
        await _frames(game, 16);
        expect(game.debugMovingPropPosition('gate'), open);
        expect(
          game.debugMapEntityPosition('boulder'),
          GridPos(x: closesOnRoute ? 8 : 4, y: 2),
        );
        expect(await game.saveGame(), isTrue);
        expect(await game.loadGame(), isTrue);
        expect(
          game.debugMapEntityPosition('boulder'),
          GridPos(x: closesOnRoute ? 8 : 4, y: 2),
        );
      },
    );
  }

  for (final ice in [false, true]) {
    test(
      'an autonomous trainer waits for boulder stability before spotting the player ice=$ice',
      () async {
        final base = _bundle(
          entities: const [
            MapEntity(
              id: 'trainer',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 5),
              blocksMovement: true,
              npc: MapEntityNpcData(
                characterId: 'trainer-character',
                trainerId: 'trainer',
                lineOfSightRange: 4,
                facing: EntityFacing.east,
                movement: MapEntityNpcMovementConfig(
                  mode: MapEntityNpcMovementMode.fixedRoute,
                  loop: false,
                  pauseDurationMs: 100,
                  stepDurationMs: 100,
                  routeSteps: [
                    MapEntityNpcRouteStep.face(direction: EntityFacing.north),
                  ],
                ),
              ),
            ),
          ],
        );
        final game = await _load(
          bundle: base.copyWith(
            map: base.map.copyWith(
              gameplayZones: ice ? base.map.gameplayZones : [],
            ),
            manifest: base.manifest.copyWith(
              characters: const [
                ProjectCharacterEntry(
                  id: 'trainer-character',
                  name: 'Trainer',
                  tilesetId: 'trainer-sheet',
                ),
              ],
              trainers: const [
                ProjectTrainerEntry(
                  id: 'trainer',
                  name: 'Trainer',
                  trainerClass: 'Hiker',
                  team: [
                    ProjectTrainerPokemonEntry(speciesId: 'machop', level: 20),
                  ],
                ),
              ],
            ),
          ),
        );
        _press(game, RuntimeInputControl.right);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        );
        game.update(.125);
        expect(
          game.debugMapEntityPosition('boulder'),
          const GridPos(x: 3, y: 2),
        );
        await _frames(game, ice ? 5 : 0);
        game.update(.25);
        expect(
          game.debugMapEntityPosition('boulder'),
          GridPos(x: ice ? 8 : 3, y: 2),
        );
        expect(
          game
              .gameStateSnapshot
              .mapInstanceWorldState
              .instancesByMapId['ice']!
              .npcPoses['trainer']
              ?.facing,
          EntityFacing.north,
        );
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
        expect(game.canCapturePlayerCheckpoint, isTrue);
      },
    );
  }

  for (final supportOnRoute in [false, true]) {
    test(
      'a saved platform support pose controls terrain collision onRoute=$supportOnRoute',
      () async {
        final fixture = MovingPlatformFixture();
        final map = fixture.map.copyWith(
          layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 25)],
          gameplayZones: const [_ice],
          entities: _bundle().map.entities,
        );
        final platforms = fixture.state.withPlatform(
          mapId: 'gym',
          platformId: 'bridge',
          pose: MovingPlatformPose(
            leftPx: 160,
            topPx: supportOnRoute ? 64 : 96,
            quarterTurns: 0,
          ),
        );
        final game = await _load(
          bundle: RuntimeMapBundle(
            map: map,
            manifest: fixture.project.copyWith(
              maps: const [
                ProjectMapEntry(
                  id: 'gym',
                  name: 'Gym',
                  relativePath: 'maps/gym.json',
                ),
              ],
            ),
            projectRootDirectory: '/tmp/boulder-slide-runtime',
            tilesetAbsolutePathsById: const {},
          ),
          initialState: _state().copyWith(
            currentMapId: 'gym',
            movingPlatformWorldState: platforms,
            mapInstanceWorldState: MapInstanceWorldState(
              instancesByMapId: {
                'gym': MapInstanceRuntimeState(
                  instanceId: 'gym-instance',
                  strengthActive: true,
                ),
              },
            ),
          ),
        );
        _press(game, RuntimeInputControl.right);
        await _frames(game, 16);
        expect(
          game.debugMapEntityPosition('boulder'),
          GridPos(x: supportOnRoute ? 8 : 4, y: 2),
        );
        expect(game.gameStateSnapshot.movingPlatformWorldState, platforms);
      },
    );
  }

  test('the first push warp waits for the boulder then a return resets the map instance', () async {
    final base = _bundle();
    final manifest = base.manifest.copyWith(
      maps: const [
        ProjectMapEntry(id: 'ice', name: 'Ice', relativePath: 'maps/ice.json'),
        ProjectMapEntry(
          id: 'next',
          name: 'Next',
          relativePath: 'maps/next.json',
        ),
      ],
    );
    final bundle = base.copyWith(
      manifest: manifest,
      map: base.map.copyWith(
        warps: const [
          MapWarp(
            id: 'exit',
            pos: GridPos(x: 2, y: 2),
            targetMapId: 'next',
            targetPos: GridPos(x: 1, y: 2),
          ),
        ],
      ),
    );
    final next = base.copyWith(
      manifest: manifest,
      map: base.map.copyWith(
        id: 'next',
        name: 'Next',
        entities: [],
        gameplayZones: [],
        warps: const [
          MapWarp(
            id: 'back',
            pos: GridPos(x: 2, y: 2),
            targetMapId: 'ice',
            targetPos: GridPos(x: 1, y: 2),
          ),
        ],
      ),
    );
    final game = await _load(bundle: bundle, otherMaps: {'next': next});
    final original = game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
      'ice',
    )!;
    _press(game, RuntimeInputControl.right);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    game.update(.25);
    expect(game.gameStateSnapshot.currentMapId, 'ice');
    expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 4, y: 2));
    await _until(
      game,
      () =>
          game.gameStateSnapshot.currentMapId == 'next' &&
          !game.debugIsMapActivationDispatchInFlight &&
          game.inputAuthoritySnapshot.acceptsOverworldInput,
    );
    _press(game, RuntimeInputControl.right);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    await _until(
      game,
      () =>
          game.gameStateSnapshot.currentMapId == 'ice' &&
          !game.debugIsMapActivationDispatchInFlight &&
          game.inputAuthoritySnapshot.acceptsOverworldInput,
    );
    expect(game.debugMapEntityPosition('boulder'), const GridPos(x: 2, y: 2));
    final restored = game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
      'ice',
    )!;
    expect(restored, isNot(original));
    expect(
      game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(restored),
      isFalse,
    );
  });

  for (final foreground in [false, true]) {
    testWidgets(
      'mounted slide paints intermediate boulder pixels foreground=$foreground',
      (tester) async {
        await tester.runAsync(() async {
          final base = _bundle();
          final bundle = base.copyWith(
            tilesetAbsolutePathsById: const {'entity': '/tmp/boulder-rock.png'},
            manifest: base.manifest.copyWith(
              tilesets: const [
                ProjectTilesetEntry(
                  id: 'entity',
                  name: 'Rock',
                  relativePath: 'rock.png',
                ),
              ],
              elements: const [
                ProjectElementEntry(
                  id: 'rock',
                  name: 'Rock',
                  tilesetId: 'entity',
                  categoryId: 'nature',
                  frames: [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                  ],
                ),
              ],
            ),
            map: base.map.copyWith(
              entities: [
                base.map.entities.single.copyWith(
                  editorVisual: MapEntityEditorVisual(
                    elementId: 'rock',
                    renderInForeground: foreground,
                  ),
                ),
              ],
            ),
          );
          final game = await _load(
            bundle: bundle,
            tester: tester,
            imageLoader:
                (paths, {transparentColorByTilesetId = const {}}) async => {
                  'entity': await runtimeTilesetImage(const [
                    ui.Color(0xFF22AA44),
                  ]),
                },
          );
          final layer = game.world.children
              .whereType<MapLayersComponent>()
              .singleWhere(
                (layer) =>
                    layer.renderPass ==
                    (foreground
                        ? MapLayerRenderPass.foreground
                        : MapLayerRenderPass.background),
              );
          _press(game, RuntimeInputControl.right);
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          );
          var pixels = await _renderLayer(layer);
          expect(await pixelAt(pixels, 80, 80), rgba(34, 170, 68, 255));
          pixels.dispose();
          game.update(.125);
          pixels = await _renderLayer(layer);
          expect(await pixelAt(pixels, 96, 80), rgba(34, 170, 68, 255));
          expect(await pixelAt(pixels, 72, 80), rgba(0, 0, 0, 0));
          pixels.dispose();
          game.update(.125);
          expect(
            game.debugMapEntityPosition('boulder'),
            const GridPos(x: 4, y: 2),
          );
          game.update(.125);
          pixels = await _renderLayer(layer);
          expect(await pixelAt(pixels, 128, 80), rgba(34, 170, 68, 255));
          pixels.dispose();
          game.setExternalInputLock(
            RuntimeExternalInputLock.gameCompletion,
            locked: true,
          );
          pixels = await _renderLayer(layer);
          expect(await pixelAt(pixels, 120, 80), rgba(0, 0, 0, 0));
          expect(await pixelAt(pixels, 144, 80), rgba(34, 170, 68, 255));
          pixels.dispose();
          await _frames(game, 16);
          expect(
            game.debugMapEntityPosition('boulder'),
            const GridPos(x: 4, y: 2),
          );
        });
      },
    );
  }

  testWidgets(
    'the public mounted session checkpoints, pauses and completes from a stable boulder pose',
    (tester) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('boulder-player-');
        addTearDown(() => root.delete(recursive: true));
        final data = Directory('${root.path}/data/pokemon');
        await Directory('${data.path}/catalogs').create(recursive: true);
        await Directory('${data.path}/species').create(recursive: true);
        await Directory('${data.path}/learnsets').create(recursive: true);
        const sourceRoot =
            '../../examples/playable_runtime_host/golden_battle_slice/data/pokemon';
        final moves = jsonDecode(
          await File('$sourceRoot/catalogs/moves.json').readAsString(),
        ) as Map<String, dynamic>;
        final strength = Map<String, dynamic>.from(
          (moves['entries'] as List).first as Map,
        );
        strength['id'] = 'strength';
        strength['pp'] = 15;
        await File('${data.path}/catalogs/moves.json').writeAsString(
          jsonEncode({
            ...moves,
            'entries': [strength],
          }),
        );
        final species = jsonDecode(
          await File('$sourceRoot/species/004-sparkitten.json').readAsString(),
        ) as Map<String, dynamic>;
        species['id'] = 'machop';
        species['slug'] = 'machop';
        species['abilities'] = {'primary': 'guts'};
        await File('${data.path}/species/machop.json')
            .writeAsString(jsonEncode(species));
        await File('$sourceRoot/learnsets/sparkitten.json')
            .copy('${data.path}/learnsets/sparkitten.json');
        final base = _bundle();
        final bundle = base.copyWith(
          projectRootDirectory: root.path,
          map: base.map.copyWith(
            gameplayZones: [
              _ice,
              const MapGameplayZone(
                id: 'second-ice',
                name: 'Second ice',
                kind: GameplayZoneKind.movementEffect,
                area: MapRect(
                  pos: GridPos(x: 2, y: 4),
                  size: GridSize(width: 1, height: 3),
                ),
                movementEffect: MovementEffectZonePayload(),
              ),
            ],
            entities: [
              ...base.map.entities,
              base.map.entities.single.copyWith(
                id: 'second-boulder',
                pos: const GridPos(x: 2, y: 3),
              ),
            ],
          ),
        );
        final identity = GameIdentity(
          gameId: 'org.example.boulder',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v1,
          saveFormat: 1,
          compatibilityId: 'boulder-v1',
        );
        final createdAt = DateTime.utc(2026, 10, 20);
        final initialSave = const GameStateSaveEnvelopeMapper().create(
          identity: identity,
          profileId: 'player',
          slotId: 'slot',
          saveId: _state().saveId,
          createdAt: createdAt,
          updatedAt: createdAt,
          status: SaveStatus.active,
          playTimeSeconds: 0,
          gameState: _state(),
        );
        late PlayableMapGame game;
        final runtime = PlayableMapGameSessionRuntime(
          descriptor: GameSessionDescriptor(
            sessionId: 'boulder-session',
            sessionToken: 'secret',
            identity: identity,
            profileId: 'player',
            slotId: 'slot',
            launchMode: GameSessionLaunchMode.continueGame,
            installedVersionHandle: 'fixture',
            saveReadHandle: 'save',
            runtimeApiVersion: '1.0.0',
            grantedCapabilities: const {'map.v1'},
            locale: 'fr-FR',
            accessibility: const GameSessionAccessibilityOptions(),
          ),
          projectFilePath: () async => '${root.path}/project.json',
          initialSave: () async => initialSave,
          preloadedInitialMap: ({
            required projectFilePath,
            required descriptor,
            required initialSave,
          }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
          mountGame: (mounted) async {
            game = mounted;
            game.onGameResize(Vector2(640, 480));
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: GameWidget(game: game),
              ),
            );
            await game.loaded;
            await tester.pump();
          },
          unmountGame: (_) async => tester.pumpWidget(const SizedBox.shrink()),
          now: () => DateTime.utc(2026, 10, 21),
        );
        addTearDown(runtime.dispose);
        await runtime.load((_) {});
        await runtime.resume();
        await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
        runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        );
        game.update(0);
        runtime.handleInput(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        );
        expect(await runtime.captureCheckpoint(), isNull);
        await runtime.setInputLock(
          RuntimeExternalInputLock.lifecycle,
          locked: true,
        );
        await runtime.pause();
        await _frames(game, 4);
        expect(
          game.debugMapEntityPosition('boulder'),
          const GridPos(x: 3, y: 2),
        );
        expect(await runtime.captureCheckpoint(), isNull);
        await runtime.setInputLock(
          RuntimeExternalInputLock.lifecycle,
          locked: false,
        );
        await runtime.resume();
        await _frames(game, 16);
        final checkpoint = await runtime.captureCheckpoint();
        expect(checkpoint, isNotNull);
        final saved = gameStateFromStrictSaveJson(checkpoint!.state);
        final instance = saved.mapInstanceWorldState.instanceRef('ice')!;
        expect(
          saved.mapInstanceWorldState.fieldObstaclePosition(
            instance,
            'boulder',
          ),
          const GridPos(x: 8, y: 2),
        );
        final events = <GameSessionAdapterEvent>[];
        final subscription = runtime.events.listen(events.add);
        addTearDown(subscription.cancel);
        runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        );
        game.update(0);
        runtime.handleInput(
          const RuntimeInputEvent.release(RuntimeInputControl.down),
        );
        expect(
          game.debugMapEntityPosition('second-boulder'),
          const GridPos(x: 2, y: 4),
        );
        expect(await runtime.captureCheckpoint(), isNull);
        await runtime.emitCompletion(
          const GameCompletionRequest(
            endingId: 'boulder-ending',
            outcome: GameCompletionOutcome.completed,
            result: GameResultSnapshot(title: 'Fin', summary: 'Puzzle terminé'),
            credits: GameCreditsSnapshot(
              title: 'Glace',
              author: 'PokeMap',
              endingLabel: 'Fin',
            ),
            destination: GameCompletionDestination.hub,
            allowPostGameContinue: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(events.whereType<GameSessionCompleted>(), hasLength(1));
        final completed = gameStateFromStrictSaveJson(
          events
              .whereType<GameSessionCompleted>()
              .single
              .completion
              .finalCheckpoint
              .state,
        );
        expect(
          completed.mapInstanceWorldState.fieldObstaclePosition(
            instance,
            'second-boulder',
          ),
          const GridPos(x: 2, y: 4),
        );
        await _frames(game, 8);
        expect(
          game.debugMapEntityPosition('second-boulder'),
          const GridPos(x: 2, y: 4),
        );
        expect(
          game.inputAuthoritySnapshot.externalLocks,
          contains(RuntimeExternalInputLock.gameCompletion),
        );
      });
    },
  );
}

const _ice = MapGameplayZone(
  id: 'ice',
  name: 'Ice',
  kind: GameplayZoneKind.movementEffect,
  area: MapRect(pos: GridPos(x: 3, y: 2), size: GridSize(width: 5, height: 1)),
  movementEffect: MovementEffectZonePayload(),
);

RuntimeMapBundle _bundle({
  List<MapEntity> entities = const [],
}) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/boulder-slide-runtime',
  tilesetAbsolutePathsById: const {},
  manifest: const ProjectManifest(
    name: 'Generic boulder puzzle',
    tilesets: [],
    settings: ProjectSettings(tileWidth: 32, tileHeight: 32, displayScale: 1),
    maps: [
      ProjectMapEntry(id: 'ice', name: 'Ice', relativePath: 'maps/ice.json'),
    ],
  ),
  map: MapData(
    id: 'ice',
    name: 'Ice',
    size: const GridSize(width: 10, height: 8),
    layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
    gameplayZones: const [_ice],
    entities: [
      const MapEntity(
        id: 'boulder',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 2),
        blocksMovement: true,
        fieldObstacle: MapEntityFieldObstacleData(
          kind: FieldObstacleKind.strengthBoulder,
        ),
      ),
      ...entities,
    ],
  ),
);

GameState _state() => GameState(
  saveId: '123e4567-e89b-42d3-a456-426614174002',
  currentMapId: 'ice',
  playerPosition: const GridPos(x: 1, y: 2),
  playerFacing: EntityFacing.east,
  party: const PlayerParty(
    members: [
      PlayerPokemon(
        speciesId: 'machop',
        natureId: 'hardy',
        abilityId: 'guts',
        level: 20,
        currentHp: 30,
        knownMoveIds: ['strength'],
      ),
    ],
  ),
  progression: const PlayerProgression(
    unlockedFieldAbilities: [FieldAbility.strength],
  ),
  mapInstanceWorldState: MapInstanceWorldState(
    instancesByMapId: {
      'ice': MapInstanceRuntimeState(
        instanceId: 'ice-instance',
        strengthActive: true,
      ),
    },
  ),
);

Future<_Game> _load({
  RuntimeMapBundle? bundle,
  List<MapEntity> entities = const [],
  GameState? initialState,
  _Repository? repository,
  WidgetTester? tester,
  RuntimeTilesetImageLoader? imageLoader,
  Map<String, RuntimeMapBundle> otherMaps = const {},
  void Function(RuntimeCommittedMovement)? onMovement,
}) async {
  final initialBundle = bundle ?? _bundle(entities: entities);
  final game = _Game(
    bundle: initialBundle,
    projectFilePath: '/tmp/boulder-slide-runtime/project.json',
    initialMapActivationReason: MapActivationReason.saveRestore,
    initialGameState: initialState ?? _state(),
    saveRepository: repository ?? _Repository(),
    runtimeTilesetImageLoader: imageLoader,
    onCommittedMovement: onMovement,
    runtimePlayerPokemonProgressionCatalogLoader:
        ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async => const RuntimePlayerPokemonProgressionCatalogs(
          speciesById: {
            'machop': PlayerPokemonHydrationSpecies(
              id: 'machop',
              baseStats: PokemonBaseStats(
                hp: 70,
                attack: 80,
                defense: 50,
                specialAttack: 35,
                specialDefense: 35,
                speed: 35,
              ),
              primaryAbilityId: 'guts',
              abilityIds: ['guts'],
              growthRateId: 'medium_fast',
            ),
          },
          maxPpByMoveId: {'strength': 15},
        ),
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => otherMaps[mapId] ?? initialBundle,
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  if (tester == null) {
    await game.onLoad();
  } else {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    await game.loaded;
    await tester.pump();
  }
  await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
  game.update(0);
  return game;
}

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0);
}

Future<void> _frames(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(.25);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 240; tick++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Runtime did not settle: ${game.debugFlowPhaseName}');
}

final class _Game extends PlayableMapGame {
  _Game({
    required super.bundle,
    required super.projectFilePath,
    required super.initialGameState,
    required super.initialMapActivationReason,
    required super.saveRepository,
    super.onCommittedMovement,
    super.runtimeMapBundleLoader,
    super.runtimePlayerPokemonProgressionCatalogLoader,
    super.runtimeTilesetImageLoader,
  });

  bool _loaded = false;
  @override
  bool get isLoaded => _loaded;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loaded = true;
  }
}

Future<ui.Image> _renderLayer(MapLayersComponent layer) {
  final recorder = ui.PictureRecorder();
  layer.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(320, 256);
}

final class _Repository implements GameSaveRepository {
  GameState? state;
  int saves = 0;
  int loads = 0;
  @override
  Future<void> save(GameState value) async {
    saves++;
    state = value;
  }

  @override
  Future<GameState?> load() async {
    loads++;
    return state;
  }

  @override
  Future<bool> exists() async => state != null;
  @override
  Future<void> delete() async => state = null;
}
