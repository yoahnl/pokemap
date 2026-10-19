import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';

import '../../map_gameplay/test/support/moving_platform_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real ticks slide after release with fixed direction then stop on normal ground', () async {
    final movements = <RuntimeCommittedMovement>[];
    final game = await _load(
      onMovement: movements.add,
      entities: const [
        MapEntity(
          id: 'sign',
          kind: MapEntityKind.sign,
          pos: GridPos(x: 3, y: 2),
          blocksMovement: false,
          sign: MapEntitySignData(plainText: 'Glissade prioritaire.'),
        ),
      ],
    );
    final initialEncounterChecks = game.debugEncounterCheckCount;
    _press(game, RuntimeInputControl.right);
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
    expect(game.debugIsPlayerStepping, isTrue);
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.down),
    );
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.menu),
      ),
      isTrue,
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    expect(game.dialoguePresentationListenable.value, isNull);
    game.setPlayerMovementMode(MovementMode.surf);
    expect(game.playerMovementMode, MovementMode.walk);
    game.update(.5);
    expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
    expect(game.debugIsPlayerStepping, isTrue);
    await _frames(game, 12);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 2));
    expect(game.debugIsPlayerStepping, isFalse);
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    expect(movements.map((value) => value.movement.toCell), [
      for (var x = 2; x <= 8; x++) GridPos(x: x, y: 2),
    ]);
    expect(movements.map((value) => value.movement.kind), [
      CommittedMovementKind.walk,
      for (var index = 0; index < 6; index++) CommittedMovementKind.forced,
    ]);
    await _frames(game, 4);
    expect(movements, hasLength(7));
    expect(game.debugEncounterCheckCount, initialEncounterChecks + 7);
  });

  test(
    'a generic ice puzzle stops at obstacles and rearms for deliberate turns',
    () async {
      final game = await _load(
        entities: const [
          MapEntity(
            id: 'east-wall',
            kind: MapEntityKind.npc,
            npc: MapEntityNpcData(),
            pos: GridPos(x: 7, y: 2),
            blocksMovement: true,
          ),
          MapEntity(
            id: 'south-wall',
            kind: MapEntityKind.npc,
            npc: MapEntityNpcData(),
            pos: GridPos(x: 6, y: 7),
            blocksMovement: true,
          ),
          MapEntity(
            id: 'west-wall',
            kind: MapEntityKind.npc,
            npc: MapEntityNpcData(),
            pos: GridPos(x: 1, y: 6),
            blocksMovement: true,
          ),
          MapEntity(
            id: 'north-wall',
            kind: MapEntityKind.npc,
            npc: MapEntityNpcData(),
            pos: GridPos(x: 2, y: 3),
            blocksMovement: true,
          ),
        ],
      );
      for (final (control, destination) in [
        (RuntimeInputControl.right, const GridPos(x: 6, y: 2)),
        (RuntimeInputControl.down, const GridPos(x: 6, y: 6)),
        (RuntimeInputControl.left, const GridPos(x: 2, y: 6)),
        (RuntimeInputControl.up, const GridPos(x: 2, y: 4)),
        (RuntimeInputControl.right, const GridPos(x: 8, y: 4)),
      ]) {
        _press(game, control);
        await _frames(game, 12);
        expect(game.debugPlayerGridPosition, destination);
        expect(game.debugIsPlayerStepping, isFalse);
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
        await _frames(game, 4);
        expect(game.debugPlayerGridPosition, destination);
        game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
      }
    },
  );

  for (final owner in [
    RuntimeExternalInputLock.pauseMenu,
    RuntimeExternalInputLock.lifecycle,
  ]) {
    test(
      '${owner.name} suspends automatic ticks and resumes coherent slide',
      () async {
        final game = await _load();
        _press(game, RuntimeInputControl.right);
        game.setExternalInputLock(owner, locked: true);
        await _frames(game, 5);
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
        expect(game.debugIsPlayerStepping, isFalse);
        game.setExternalInputLock(owner, locked: false);
        await _frames(game, 12);
        expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 2));
        expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      },
    );
  }

  test('save and load reject active inertia then restore stable position without stale direction', () async {
    final repository = _Repository();
    final game = await _load(repository: repository);
    _press(game, RuntimeInputControl.right);
    expect(await game.saveGame(), isFalse);
    expect(await game.loadGame(), isFalse);
    expect(repository.saves, 0);
    expect(repository.loads, 0);
    await _frames(game, 12);
    expect(await game.saveGame(), isTrue);
    expect(repository.saves, 1);
    expect(repository.state!.playerPosition, const GridPos(x: 8, y: 2));
    _press(game, RuntimeInputControl.down);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.down),
    );
    await _frames(game, 2);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 3));
    expect(await game.loadGame(), isTrue);
    await _frames(game, 12);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 2));
    expect(game.debugIsPlayerStepping, isFalse);
    final restored = await _load(
      initialState: gameStateFromStrictSaveJson(
        strictGameStateSaveJson(repository.state!),
      ),
    );
    await _frames(restored, 12);
    expect(restored.debugPlayerGridPosition, const GridPos(x: 8, y: 2));
    expect(restored.debugIsPlayerStepping, isFalse);
  });

  test('teleport during suspension discards the old direction', () async {
    final game = await _load();
    _press(game, RuntimeInputControl.right);
    game.setExternalInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
    await _frames(game, 2);
    game.debugSetPlayerStateForTest(
      position: const GridPos(x: 5, y: 5),
      facing: Direction.south,
    );
    game.setExternalInputLock(
      RuntimeExternalInputLock.lifecycle,
      locked: false,
    );
    await _frames(game, 12);
    expect(game.debugPlayerGridPosition, const GridPos(x: 5, y: 5));
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
  });

  test('a warp on the sliding route keeps normal transfer authority and clears inertia', () async {
    final game = await _load(
      warps: const [
        MapWarp(
          id: 'exit',
          pos: GridPos(x: 4, y: 2),
          targetMapId: 'next',
          targetPos: GridPos(x: 2, y: 2),
        ),
      ],
    );
    _press(game, RuntimeInputControl.right);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    await _until(
      game,
      () =>
          game.gameStateSnapshot.currentMapId == 'next' &&
          !game.debugIsMapActivationDispatchInFlight,
    );
    await _frames(game, 12);
    expect(game.gameStateSnapshot.currentMapId, 'next');
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
  });

  test(
    'a solid NPC stops the real sliding route without repeated bumps',
    () async {
      final movements = <RuntimeCommittedMovement>[];
      final game = await _load(
        entities: const [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 2),
            blocksMovement: true,
            npc: MapEntityNpcData(),
          ),
        ],
        onMovement: movements.add,
      );
      _press(game, RuntimeInputControl.right);
      await _frames(game, 12);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('npc'), const GridPos(x: 4, y: 2));
      expect(movements, hasLength(2));
      await _frames(game, 12);
      expect(movements, hasLength(2));
    },
  );

  test(
    'a solid terrain tile stops slide through canonical collision',
    () async {
      final fixture = MovingPlatformFixture();
      final map = fixture.map.copyWith(
        movingPlatforms: [],
        placedElements: [],
        gameplayZones: const [_slide],
        layers: [
          MapLayer.tile(
            id: 'magma',
            name: 'Terrain',
            palette: const [
              TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0),
            ],
            cells: [
              for (var index = 0; index < 100; index++) index == 24 ? 1 : 0,
            ],
          ),
        ],
      );
      final game = await _load(
        bundle: _platformBundle(fixture, map),
        initialState: const GameState(
          saveId: 'terrain-slide',
          currentMapId: 'gym',
          playerPosition: GridPos(x: 1, y: 2),
        ),
      );
      _press(game, RuntimeInputControl.right);
      await _frames(game, 12);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    },
  );

  test(
    'active Strength never turns automatic slide into a boulder push',
    () async {
      final game = await _load(
        entities: const [
          MapEntity(
            id: 'rock',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 4, y: 2),
            blocksMovement: true,
            fieldObstacle: MapEntityFieldObstacleData(
              kind: FieldObstacleKind.strengthBoulder,
            ),
          ),
        ],
        initialState: GameState(
          saveId: 'strength-slide',
          currentMapId: 'ice',
          playerPosition: const GridPos(x: 1, y: 2),
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              'ice': MapInstanceRuntimeState(
                instanceId: 'ice-instance',
                strengthActive: true,
              ),
            },
          ),
        ),
      );
      final scope = game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
        'ice',
      )!;
      expect(
        game.gameStateSnapshot.mapInstanceWorldState.isStrengthActive(scope),
        isTrue,
      );
      _press(game, RuntimeInputControl.right);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      await _frames(game, 12);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('rock'), const GridPos(x: 4, y: 2));
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(
          RuntimeInputControl.right,
          isRepeat: true,
        ),
      );
      await _frames(game, 12);
      expect(game.debugMapEntityPosition('rock'), const GridPos(x: 4, y: 2));
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down, isRepeat: true),
      );
      await _frames(game, 2);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      _press(game, RuntimeInputControl.down);
      await _frames(game, 12);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 7));
      expect(game.debugMapEntityPosition('rock'), const GridPos(x: 4, y: 2));
    },
  );

  test(
    'ordinary ground keeps its existing direction repeat behavior',
    () async {
      final game = await _load(
        initialState: const GameState(
          saveId: 'normal-repeat',
          currentMapId: 'ice',
          playerPosition: GridPos(x: 8, y: 2),
        ),
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down, isRepeat: true),
      );
      game.update(0);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      await _frames(game, 2);
      expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 3));
    },
  );

  test(
    'an already moving autonomous NPC keeps its reserved landing during slide',
    () async {
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
        initialState: GameState(
          saveId: 'autonomous-slide',
          currentMapId: 'ice',
          playerPosition: const GridPos(x: 1, y: 2),
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              'ice': MapInstanceRuntimeState(instanceId: 'ice-instance'),
            },
          ),
        ),
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
      expect(game.debugMapEntityPosition('walker'), const GridPos(x: 4, y: 1));
      expect(
        game.debugScriptedNpcDynamicBlockedCells(),
        contains(const GridPos(x: 4, y: 2)),
      );
      _press(game, RuntimeInputControl.right);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      expect(
        game.debugScriptedNpcDynamicBlockedCells(),
        contains(const GridPos(x: 4, y: 2)),
      );
      game.update(.5);
      game.update(.5);
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
      expect(game.debugMapEntityPosition('walker'), const GridPos(x: 4, y: 2));
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    },
  );

  testWidgets(
    'production session checkpoints reject inertia and lifecycle pause resumes safely',
    (tester) async {
      await tester.runAsync(() async {
        final identity = GameIdentity(
          gameId: 'org.example.ice-slide',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v1,
          saveFormat: 1,
          compatibilityId: 'ice-slide-v1',
        );
        final createdAt = DateTime.utc(2026, 10, 20);
        final save = const GameStateSaveEnvelopeMapper().create(
          identity: identity,
          profileId: 'player',
          slotId: 'slot',
          saveId: '123e4567-e89b-42d3-a456-426614174002',
          createdAt: createdAt,
          updatedAt: createdAt,
          status: SaveStatus.active,
          playTimeSeconds: 0,
          gameState: const GameState(
            saveId: '123e4567-e89b-42d3-a456-426614174002',
            currentMapId: 'ice',
            playerPosition: GridPos(x: 1, y: 2),
          ),
        );
        late PlayableMapGame game;
        final runtime = PlayableMapGameSessionRuntime(
          descriptor: GameSessionDescriptor(
            sessionId: 'ice-slide-session',
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
          projectFilePath: () async => '/tmp/slide-runtime/project.json',
          initialSave: () async => save,
          preloadedInitialMap: ({
            required projectFilePath,
            required descriptor,
            required initialSave,
          }) async => RuntimeInitialMapPreloadResult(bundle: _bundle()),
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
        expect(await runtime.captureCheckpoint(), isNotNull);
        expect(
          runtime.handleInput(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          ),
          isTrue,
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
        await expectLater(runtime.pause(), completes);
        expect(await runtime.captureCheckpoint(), isNull);
        await runtime.setInputLock(
          RuntimeExternalInputLock.lifecycle,
          locked: false,
        );
        await runtime.resume();
        await _frames(game, 12);
        expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 2));
        final checkpoint = await runtime.captureCheckpoint();
        expect(checkpoint, isNotNull);
        expect(
          gameStateFromStrictSaveJson(checkpoint!.state).playerPosition,
          const GridPos(x: 8, y: 2),
        );
        final events = <GameSessionAdapterEvent>[];
        final subscription = runtime.events.listen(events.add);
        addTearDown(subscription.cancel);
        runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.left),
        );
        game.update(0);
        runtime.handleInput(
          const RuntimeInputEvent.release(RuntimeInputControl.left),
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 7, y: 2));
        expect(await runtime.captureCheckpoint(), isNull);
        await runtime.emitCompletion(
          const GameCompletionRequest(
            endingId: 'ice-ending',
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
        final finalCheckpoint = events
            .whereType<GameSessionCompleted>()
            .single
            .completion
            .finalCheckpoint;
        expect(
          gameStateFromStrictSaveJson(finalCheckpoint.state).playerPosition,
          const GridPos(x: 7, y: 2),
        );
        expect(
          game.inputAuthoritySnapshot.externalLocks,
          contains(RuntimeExternalInputLock.gameCompletion),
        );
        await _frames(game, 4);
        expect(game.debugPlayerGridPosition, const GridPos(x: 7, y: 2));
      });
    },
  );

  test('a saved live prop pose blocks slide at its current position', () async {
    final fixture = MovingPlatformFixture();
    final map = fixture.map.copyWith(
      layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
      movingPlatforms: [],
      gameplayZones: const [_slide],
      movingProps: [
        MovingPropDefinition(
          id: 'gate',
          placedElementId: 'gate-art',
          closedPositionPx: const PixelOffset(x: 192, y: 64),
          openPositionPx: const PixelOffset(x: 128, y: 64),
          collisionRect: const PixelRect(
            leftPx: 0,
            topPx: 0,
            widthPx: 32,
            heightPx: 32,
          ),
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'gate-art',
          layerId: 'magma',
          elementId: 'platform-0',
          pos: const GridPos(x: 6, y: 2),
          applyCollision: false,
          properties: const {
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
          },
        ),
      ],
    );
    final bundle = _platformBundle(fixture, map);
    final game = await _load(
      bundle: bundle,
      initialState: GameState(
        saveId: 'prop-slide',
        currentMapId: 'gym',
        playerPosition: const GridPos(x: 1, y: 2),
        movingPropWorldState: const MovingPropWorldState.empty().withProp(
          mapId: 'gym',
          propId: 'gate',
          state: MovingPropState.open,
        ),
      ),
    );
    _press(game, RuntimeInputControl.right);
    await _frames(game, 12);
    expect(
      game.debugMovingPropPosition('gate'),
      const PixelOffset(x: 128, y: 64),
    );
    expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
  });

  test(
    'a live moved platform control retains its authority and stops slide',
    () async {
      final fixture = MovingPlatformFixture();
      final definition = MovingPlatformDefinition.fromJson({
        ...fixture.definition.toJson(),
        'controls': [
          {
            'id': 'button',
            'cell': {'x': 0, 'y': 0},
            'motion': 'forward',
          },
        ],
      });
      final map = fixture.map.copyWith(
        layers: [MovingPlatformFixture.terrain('magma', blockedIndex: 99)],
        movingPlatforms: [definition],
        gameplayZones: const [_slide],
      );
      final state = fixture.state.withPlatform(
        mapId: 'gym',
        platformId: 'bridge',
        pose: MovingPlatformPose(leftPx: 128, topPx: 64, quarterTurns: 0),
      );
      final game = await _load(
        bundle: _platformBundle(fixture, map),
        initialState: GameState(
          saveId: 'platform-slide',
          currentMapId: 'gym',
          playerPosition: const GridPos(x: 1, y: 2),
          movingPlatformWorldState: state,
        ),
      );
      _press(game, RuntimeInputControl.right);
      await _until(
        game,
        () =>
            game.gameStateSnapshot.movingPlatformWorldState
                .platform('gym', 'bridge')!
                .leftPx ==
            160,
      );
      await _frames(game, 12);
      expect(game.debugPlayerGridPosition, const GridPos(x: 5, y: 2));
      expect(
        game.gameStateSnapshot.movingPlatformWorldState
            .platform('gym', 'bridge')!
            .leftPx,
        160,
      );
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    },
  );

  test('Event V2 arrival dialogue suspends slide then resumes through remaining cells', () async {
    final base = _bundle();
    final bundle = base.copyWith(
      map: base.map.copyWith(
        triggers: const [
          MapTrigger(
            id: 'arrival',
            name: 'Arrival',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 2),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      ),
      manifest: base.manifest.copyWith(
        dialogues: const [
          ProjectDialogueEntry(
            id: 'arrival',
            name: 'Arrival',
            relativePath: 'dialogues/arrival.yarn',
          ),
        ],
        facts: [NarrativeFactDefinition(id: 'arrived', label: 'Arrived')],
        scenes: [_dialogueScene()],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          legacyClaims: const [],
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-3000-7000-8000-000000000126',
                name: 'Arrival',
                source: NarrativeEventSourceRef.triggerEnter('ice', 'arrival'),
                conditions: const [],
                sceneId: 'arrival',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
        ),
      ),
    );
    final game = await _load(bundle: bundle);
    game.setDialogueTextSpeed(RuntimeDialogueTextSpeed.instant);
    _press(game, RuntimeInputControl.right);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    await _until(game, () => game.dialoguePresentationListenable.value != null);
    expect(
      game.inputAuthorityListenable.value.context,
      RuntimeInputContext.dialogue,
    );
    expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
    await _frames(game, 8);
    expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 2));
    for (
      var count = 0;
      count < 3 && game.dialoguePresentationListenable.value != null;
      count++
    ) {
      final snapshot = game.dialoguePresentationListenable.value!;
      game.dispatchDialoguePresentationCommand(
        DialogueAdvanceCommand(snapshotRevision: snapshot.revision),
      );
      await _frames(game, 2);
    }
    await _until(
      game,
      () =>
          game
              .gameStateSnapshot
              .narrativeFactRuntimeState
              .overridesByFactId['arrived'] ==
          true,
    );
    await _frames(game, 12);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 2));
    expect(game.inputAuthorityListenable.value.acceptsOverworldInput, isTrue);
  });
}

const _slide = MapGameplayZone(
  id: 'ice',
  name: 'Ice',
  kind: GameplayZoneKind.movementEffect,
  area: MapRect(pos: GridPos(x: 2, y: 1), size: GridSize(width: 6, height: 6)),
  movementEffect: MovementEffectZonePayload(),
);

RuntimeMapBundle _bundle({
  String mapId = 'ice',
  List<MapEntity> entities = const [],
  List<MapWarp> warps = const [],
}) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/slide-runtime',
  tilesetAbsolutePathsById: const {},
  manifest: const ProjectManifest(
    name: 'Generic ice puzzle',
    tilesets: [],
    settings: ProjectSettings(tileWidth: 32, tileHeight: 32, displayScale: 1),
    maps: [
      ProjectMapEntry(id: 'ice', name: 'Ice', relativePath: 'maps/ice.json'),
      ProjectMapEntry(id: 'next', name: 'Next', relativePath: 'maps/next.json'),
    ],
  ),
  map: MapData(
    id: mapId,
    name: mapId,
    size: const GridSize(width: 10, height: 8),
    layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
    gameplayZones: const [_slide],
    entities: entities,
    warps: warps,
  ),
);

Future<_Game> _load({
  RuntimeMapBundle? bundle,
  List<MapEntity> entities = const [],
  List<MapWarp> warps = const [],
  _Repository? repository,
  GameState? initialState,
  void Function(RuntimeCommittedMovement)? onMovement,
}) async {
  final initialBundle = bundle ?? _bundle(entities: entities, warps: warps);
  final game = _Game(
    bundle: initialBundle,
    projectFilePath: '/tmp/slide-runtime/project.json',
    initialMapActivationReason: MapActivationReason.saveRestore,
    initialGameState:
        initialState ??
        const GameState(
          saveId: 'ice',
          currentMapId: 'ice',
          playerPosition: GridPos(x: 1, y: 2),
          playerFacing: EntityFacing.east,
        ),
    saveRepository: repository ?? _Repository(),
    onCommittedMovement: onMovement,
    dialogueSessionLoader: (_) async => DialogueSession.start([
      YarnNode(
        title: 'Start',
        steps: [YarnStepLine('La glace continue après le dialogue.')],
      ),
    ], 'Start')!,
    runtimeMapBundleLoader:
        ({required projectFilePath, required mapId}) async =>
            mapId == initialBundle.map.id
            ? initialBundle
            : initialBundle.copyWith(map: _bundle(mapId: mapId).map),
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
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
    game.update(.5);
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
    super.dialogueSessionLoader,
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

RuntimeMapBundle _platformBundle(MovingPlatformFixture fixture, MapData map) =>
    RuntimeMapBundle(
      projectRootDirectory: '/tmp/slide-runtime',
      tilesetAbsolutePathsById: const {},
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
    );

SceneAsset _dialogueScene() => SceneAsset(
  id: 'arrival',
  name: 'Arrival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(dialogueId: 'arrival'),
      ),
      SceneNode(
        id: 'fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'arrived', value: true),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-dialogue',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'dialogue-fact',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'fact',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'fact-end',
        fromNodeId: 'fact',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

final class _Repository implements GameSaveRepository {
  int saves = 0;
  int loads = 0;
  GameState? state;
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
