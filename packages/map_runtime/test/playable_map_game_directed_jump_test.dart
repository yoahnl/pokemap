import 'dart:io';

import 'package:image/image.dart' as image;

import '../../map_gameplay/test/support/border_jump_fixture.dart';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

const _a = GridPos(x: 2, y: 1);
const _b = GridPos(x: 2, y: 2);
const _c = GridPos(x: 2, y: 3);

({MapData map, ProjectManifest project}) _nativeFixture() {
  final base = BorderJumpFixture(
    points: const [GridPos(x: 2, y: 2), GridPos(x: 3, y: 2)],
  );
  final definition = base.revision.definition;
  final revision = BorderBlueprintRevision(
    revision: base.revision.revision,
    definition: BorderBlueprintPublishedDefinition(
      name: definition.name,
      previewSeed: definition.previewSeed,
      template: definition.template,
      primitives: definition.primitives,
      defaults: definition.defaults,
      sortOrder: definition.sortOrder,
      jumpBehavior: BorderJumpBehavior(
        side: BorderLineSide.primary,
        durationMs: 500,
        peakHeightPx: 24,
      ),
    ),
  );
  final project = base.project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 7,
      records: [
        BorderBlueprintRecord(
          id: base.feature.blueprintId,
          draft: base.project.borderCatalog.records.single.draft,
          latestPublished: revision,
        ),
      ],
      visualSnapshots: base.project.borderCatalog.visualSnapshots,
    ),
  );
  final feature = base.feature;
  final resolved = resolveLedgeLineBorderWithEvidence(
    BorderResolutionRequest(
      mapSize: base.map.size,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: feature.blueprintId,
      blueprintRevision: revision,
      feature: feature,
      visualSnapshots: project.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    ),
  );
  expect(resolved.result.canApply, isTrue);
  return (
    map: base.map.copyWith(
      id: 'jump',
      layers: [
        MapLayer.border(
          id: 'original-borders',
          name: 'Borders',
          content: BorderLayerContent(
            formatVersion: 4,
            features: [
              BorderFeature(
                id: feature.id,
                name: feature.name,
                blueprintId: feature.blueprintId,
                seed: feature.seed,
                geometry: feature.geometry,
                lineSide: feature.lineSide,
                overrides: feature.overrides,
                keepOutRegions: feature.keepOutRegions,
                materialization: resolved.result.materialization,
              ),
            ],
          ),
        ),
        MapLayer.tile(
          id: 'objects',
          name: 'Objects',
          cells: List.filled(144, 0),
        ),
      ],
    ),
    project: project,
  );
}

MapData _map({
  String id = 'jump',
  List<MapWarp> warps = const [],
  List<MapPlacedElement> placed = const [],
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  final fixture = _nativeFixture();
  return fixture.map.copyWith(
    id: id,
    layers: id == 'jump'
        ? fixture.map.layers
        : [
            MapLayer.tile(
              id: 'objects',
              name: 'Objects',
              cells: List.filled(144, 0),
            ),
          ],
    warps: warps,
    placedElements: placed,
    entities: entities,
    triggers: triggers,
  );
}

RuntimeMapBundle _bundle(
  MapData map, {
  List<ProjectElementEntry> elements = const [],
  ProjectManifest? manifest,
  String root = '/tmp/jump-consumer',
  bool bicycle = false,
}) {
  final fixture = _nativeFixture();
  final base =
      manifest ??
      fixture.project.copyWith(
        name: 'Border jump consumer',
        maps: const [
          ProjectMapEntry(
            id: 'jump',
            name: 'Jump',
            relativePath: 'maps/jump.json',
          ),
          ProjectMapEntry(
            id: 'next',
            name: 'Next',
            relativePath: 'maps/next.json',
          ),
        ],
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
      );
  return RuntimeMapBundle(
    manifest: base.copyWith(
      borderCatalog: fixture.project.borderCatalog,
      tilesets: fixture.project.tilesets,
      elementCategories: fixture.project.elementCategories,
      elements: [...fixture.project.elements, ...elements],
      settings: bicycle ? base.settings.copyWith(defaultPlayerCharacterId: 'bike-player') : base.settings,
      characters: [
        if (bicycle) ProjectCharacterEntry(id: 'bike-player', name: 'Cycliste',
          tilesetId: 'original-atlas', animations: [
            for (final state in [CharacterAnimationState.bicycleIdle, CharacterAnimationState.bicycle])
              for (final direction in EntityFacing.values) CharacterAnimation(state: state, direction: direction,
                sourceAssetId: 'cycle', frames: [const CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32), durationMs: 100)]),
          ]),
        ProjectCharacterEntry(
          id: 'leader-character',
          name: 'Leader',
          tilesetId: 'original-atlas',
          frameWidth: 1,
          frameHeight: 1,
        ),
      ],
    ),
    map: map,
    projectRootDirectory: root,
    tilesetAbsolutePathsById: const {},
    characterAnimationAbsolutePathsByAssetId: bicycle ? {'cycle': '$root/cycle.png'} : {},
  );
}

Future<void> _writeBorderFrames(Directory root) async {
  final project = _nativeFixture().project;
  var index = 0;
  for (final primitive
      in project
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition
          .primitives) {
    final frame = image.Image(width: 32, height: 32, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final opaque = switch (primitive.authoredOrientation) {
          BorderPrimitiveOrientation.north => y < 16,
          BorderPrimitiveOrientation.south => y >= 16,
          BorderPrimitiveOrientation.east => x >= 16,
          BorderPrimitiveOrientation.west => x < 16,
          BorderPrimitiveOrientation.legacyAxis => false,
        };
        frame.setPixelRgba(x, y, x * 7, y * 7, index * 50, opaque ? 255 : 0);
      }
    }
    final snapshot = project.borderCatalog.visualSnapshots.firstWhere(
      (value) => value.id == primitive.visualSnapshotId,
    );
    final file = File(
      '${root.path}/${snapshot.frames.single.relativeAssetPath}',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(image.encodePng(frame));
    index++;
  }
}

final class _Game extends PlayableMapGame {
  _Game({
    required super.bundle,
    required super.saveRepository,
    super.runtimeMapBundleLoader,
    super.beforeNarrativeAuthorityPreparation,
    super.overworldSfxPlayer,
    PixelOffset? pixelPosition,
    bool bicycle = false,
  }) : super(
         projectFilePath: '${bundle.projectRootDirectory}/project.json',
         initialMapActivationReason: pixelPosition == null
             ? MapActivationReason.initialBoot
             : MapActivationReason.saveRestore,
         initialGameState: GameState(
           saveId: 'jump',
           currentMapId: 'jump',
           playerPosition: _a,
           playerPixelPosition: pixelPosition,
           playerFacing: EntityFacing.south,
           playerMovementMode: bicycle ? MovementMode.bicycle : MovementMode.walk,
           repelState: bicycle ? RepelState.active(itemId: 'repel', steps: 8) : const RepelState.empty(),
         ),
       );

  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loaded = true;
  }
}

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
  Future<void> delete() async {
    state = null;
  }
}

Future<_Game> _load({
  MapData? map,
  _Repository? repository,
  List<ProjectElementEntry> elements = const [],
  ProjectManifest? manifest,
  Future<void> Function(NarrativeEventOccurrence)? beforeAuthority,
  PixelOffset? pixelPosition,
  OverworldSfxPlayer? overworldSfxPlayer,
  bool bicycle = false,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'border-jump-runtime-original-',
  );
  addTearDown(() => root.delete(recursive: true));
  await _writeBorderFrames(root);
  if (bicycle) {
    await File('${root.path}/cycle.png').writeAsBytes(image.encodePng(image.Image(width: 128, height: 128)));
  }
  final game = _Game(
    bundle: _bundle(
      map ?? _map(),
      elements: elements,
      manifest: manifest,
      root: root.path,
      bicycle: bicycle,
    ),
    bicycle: bicycle,
    saveRepository: repository ?? _Repository(),
    beforeNarrativeAuthorityPreparation: beforeAuthority,
    pixelPosition: pixelPosition,
    overworldSfxPlayer: overworldSfxPlayer ?? _JumpSounds(),
    runtimeMapBundleLoader:
        ({required projectFilePath, required mapId}) async => _bundle(
          _map(
            id: mapId,
            warps: const [
              MapWarp(
                id: 'arrival',
                pos: GridPos(x: 1, y: 1),
                targetMapId: 'jump',
                targetPos: _a,
              ),
            ],
          ),
          root: root.path,
        ),
  );
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await _pump(game, () => !game.debugIsMapActivationDispatchInFlight);
  game.update(0);
  return game;
}

void _jump(_Game game) {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.down),
    ),
    isTrue,
  );
  game.update(0);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.down),
  );
}

Future<void> _pump(_Game game, bool Function() done) async {
  final elapsed = Stopwatch()..start();
  while (elapsed.elapsed < const Duration(seconds: 2)) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Runtime did not settle: ${game.debugFlowPhaseName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bicycle uses native ledge path without extra EX00 or Repel steps', () async {
    final game = await _load(bicycle: true);
    addTearDown(game.onRemove);
    expect(game.playerMovementMode, MovementMode.bicycle);
    final player = game.world.children.whereType<PlayerComponent>().single;
    _jump(game);
    expect(game.debugPlayerGridPosition, _c);
    expect(player.debugStepAnimationState, CharacterAnimationState.bicycle);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 8);
    expect(game.lastCommittedMovement, isNull);
    game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.down));
    game.update(.5);
    expect(game.debugIsPlayerStepping, isFalse);
    expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.overworld);
    expect(player.debugAnimationSource?.imageId, characterAnimationRuntimeImageId('cycle'));
    expect(game.lastCommittedMovement, isNull);
    expect(game.playerMovementMode, MovementMode.bicycle);
    game.update(.2);
    expect(game.debugPlayerGridPosition, _c);
    expect(game.gameStateSnapshot.repelState.remainingSteps, 8);
  });

  test(
    'jump sound starts once on admission and never on blocked movement',
    () async {
      final sound = _JumpSounds();
      final game = await _load(overworldSfxPlayer: sound);
      expect(sound.starts, 0);
      _jump(game);
      expect(sound.starts, 1);
      game.update(.25);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      game.update(.25);
      expect(sound.starts, 1);
      game.onRemove();
      expect(sound.disposals, 1);

      final blockedSound = _JumpSounds();
      final blocked = await _load(
        overworldSfxPlayer: blockedSound,
        map: _map(
          entities: const [
            MapEntity(id: 'blocker', kind: MapEntityKind.npc, pos: _c),
          ],
        ),
      );
      addTearDown(blocked.onRemove);
      _jump(blocked);
      expect(blocked.debugPlayerGridPosition, _a);
      expect(blockedSound.starts, 0);
    },
  );

  test('jump reserves logical landing and blocks all input and checkpoints for the animation', () async {
    final repository = _Repository();
    final game = await _load(repository: repository);
    addTearDown(game.onRemove);
    final from = game.debugPlayerWorldTopLeft;
    _jump(game);
    expect(game.debugPlayerGridPosition, _c);
    expect(game.debugPlayerWorldTopLeft, from);
    expect(game.debugIsPlayerStepping, isTrue);
    expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.blocked);
    for (final control in RuntimeInputControl.values) {
      expect(
        game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
        isTrue,
        reason: control.name,
      );
    }
    expect(await game.saveGame(), isFalse);
    expect(await game.loadGame(), isFalse);
    expect(repository.saves, 0);
    expect(repository.loads, 0);
    game.update(.25);
    expect(game.debugPlayerWorldTopLeft.y, closeTo(from.y + 32, .000001));
    expect(game.debugRenderedPlayerFootCell, _b);
    expect(game.debugEncounterCheckCount, 0);
    game.update(.25);
    expect(game.debugPlayerWorldTopLeft.y, closeTo(from.y + 64, .000001));
    expect(game.debugIsPlayerStepping, isFalse);
    expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.overworld);
    expect(game.inputAuthoritySnapshot.sprintAccepted, isFalse);
    game.update(.2);
    expect(game.debugPlayerGridPosition, _c);
    expect(await game.saveGame(), isTrue);
    expect(repository.saves, 1);
    expect(repository.state!.playerPosition, _c);
  });

  test('plain landing checks encounters exactly once after animation without intermediate step', () async {
    final game = await _load();
    addTearDown(game.onRemove);
    _jump(game);
    game.update(.49);
    expect(game.debugEncounterCheckCount, 0);
    game.update(.01);
    expect(game.debugEncounterCheckCount, 1);
    game.update(2);
    game.update(2);
    expect(game.debugEncounterCheckCount, 1);
    expect(game.debugPlayerGridPosition, _c);
  });

  test(
    'jump hides and refuses spatial touch interactions at logical landing',
    () async {
      final game = await _load(
        map: _map(
          entities: const [
            MapEntity(
              id: 'sign',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 2, y: 4),
              sign: MapEntitySignData(plainText: 'Read me'),
            ),
          ],
        ),
      );
      addTearDown(game.onRemove);
      _jump(game);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      expect(game.overworldInteractionSnapshot.tapAction, isNull);
      game.update(.5);
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      expect(game.dispatchOverworldInteraction(request), isTrue);
    },
  );

  test('landing warp activates once after animation and intermediate warp is skipped', () async {
    final game = await _load(
      map: _map(
        warps: const [
          MapWarp(
            id: 'intermediate',
            pos: _b,
            targetMapId: 'wrong',
            targetPos: _a,
          ),
          MapWarp(
            id: 'landing',
            pos: _c,
            targetMapId: 'next',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );
    addTearDown(game.onRemove);
    final activations = game.debugCompletedMapActivationDispatchCount;
    _jump(game);
    game.update(.49);
    expect(game.debugHasPendingMapTransition, isFalse);
    expect(game.gameStateSnapshot.currentMapId, 'jump');
    game.update(.01);
    await _pump(
      game,
      () =>
          game.gameStateSnapshot.currentMapId == 'next' &&
          !game.debugIsMapActivationDispatchInFlight &&
          game.debugFlowPhaseName == 'overworld',
    );
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugCompletedMapActivationDispatchCount, activations + 1);
    game.update(1);
    expect(game.debugCompletedMapActivationDispatchCount, activations + 1);
  });

  test('placed arrival notification is deferred and intermediate behavior is skipped', () async {
    final game = await _load(
      elements: const [
        ProjectElementEntry(
          id: 'notice',
          name: 'Notice',
          tilesetId: 'original-atlas',
          categoryId: 'original-modules',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
      ],
      map: _map(
        placed: [
          for (final (pos, message) in [(_b, 'Intermediate'), (_c, 'Landed')])
            MapPlacedElement(
              id: message,
              elementId: 'notice',
              layerId: 'objects',
              pos: pos,
              behaviors: [
                MapPlacedElementBehavior(
                  id: 'enter',
                  enabled: true,
                  trigger: MapPlacedElementTriggerType.onEnter,
                  triggerScope: MapPlacedElementTriggerScope.oncePerEnter,
                  effect: MapPlacedElementEffect(
                    type: MapPlacedElementEffectType.showMessage,
                    message: message,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
    addTearDown(game.onRemove);
    _jump(game);
    game.update(.49);
    expect(game.debugNotificationText, isNull);
    game.update(.01);
    await _pump(game, () => game.debugNotificationText != null);
    expect(game.debugNotificationText, 'Landed');
    expect(game.debugPlayerGridPosition, _c);
  });

  for (final cell in [_c, const GridPos(x: 3, y: 3)]) {
    test(
      'active followed NPC cannot reserve landing contact cell $cell while jumping',
      () async {
        final game = await _load(
          map: _map(
            entities: const [
              MapEntity(
                id: 'leader',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 5, y: 3),
                npc: MapEntityNpcData(
                  displayName: 'Leader',
                  characterId: 'leader-character',
                ),
              ),
            ],
          ),
          pixelPosition: const PixelOffset(x: 76, y: 32),
        );
        addTearDown(game.onRemove);
        expect(
          game.gameStateSnapshot.playerPixelPosition,
          const PixelOffset(x: 76, y: 32),
        );
        _jump(game);
        expect(
          game.gameStateSnapshot.playerPixelPosition,
          const PixelOffset(x: 76, y: 96),
        );
        expect(game.debugPlayerGridPosition, _c);
        expect(game.debugIsPlayerStepping, isTrue);
        expect(game.debugStartScenarioFollow('leader'), isTrue);
        expect(game.debugScenarioFollowLeaderId, 'leader');
        final status = game.startScriptedNpcMove(
          entityId: 'leader',
          destination: cell,
        );
        expect(
          status.state,
          ScriptedEntityMovementState.failed,
          reason: 'landing footprint $cell',
        );
        game.update(.1);
        expect(game.debugNpcGridPosition('leader'), const GridPos(x: 5, y: 3));
      },
    );
  }

  test(
    'unrelated NPC cannot enter the adjacent cell of the landing contact',
    () async {
      final game = await _load(
        map: _map(
          entities: const [
            MapEntity(
              id: 'leader',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 5, y: 3),
              npc: MapEntityNpcData(
                displayName: 'Leader',
                characterId: 'leader-character',
              ),
            ),
          ],
        ),
        pixelPosition: const PixelOffset(x: 76, y: 32),
      );
      addTearDown(game.onRemove);
      _jump(game);
      expect(game.debugHasActiveScenarioFollow, isFalse);
      expect(
        game
            .startScriptedNpcMove(
              entityId: 'leader',
              destination: const GridPos(x: 3, y: 3),
            )
            .state,
        ScriptedEntityMovementState.failed,
      );
      expect(
        game
            .startScriptedNpcMove(
              entityId: 'leader',
              destination: const GridPos(x: 6, y: 3),
            )
            .state,
        ScriptedEntityMovementState.moving,
      );
      game.update(.25);
      expect(game.debugNpcGridPosition('leader'), const GridPos(x: 5, y: 3));
    },
  );

  test(
    'followed 2x2 NPC cannot overlap landing from an outside anchor',
    () async {
      final game = await _load(
        map: _map(
          entities: const [
            MapEntity(
              id: 'leader',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 5, y: 3),
              size: GridSize(width: 2, height: 2),
              npc: MapEntityNpcData(
                displayName: 'Leader',
                characterId: 'leader-character',
              ),
            ),
          ],
        ),
      );
      addTearDown(game.onRemove);
      _jump(game);
      expect(game.debugStartScenarioFollow('leader'), isTrue);
      expect(
        game
            .startScriptedNpcMove(
              entityId: 'leader',
              destination: const GridPos(x: 1, y: 2),
            )
            .state,
        ScriptedEntityMovementState.failed,
      );
    },
  );

  test(
    'landing enumeration preserves full contact even for activeFollowLeader',
    () async {
      final game = await _load(
        map: _map(
          entities: const [
            MapEntity(
              id: 'leader',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 5, y: 3),
              npc: MapEntityNpcData(
                displayName: 'Leader',
                characterId: 'leader-character',
              ),
            ),
          ],
        ),
        pixelPosition: const PixelOffset(x: 76, y: 32),
      );
      addTearDown(game.onRemove);
      _jump(game);
      expect(game.debugStartScenarioFollow('leader'), isTrue);
      expect(
        game.debugScriptedNpcDynamicBlockedCells(ignoreEntityId: 'leader'),
        containsAll([_c, const GridPos(x: 3, y: 3)]),
      );
      game.update(.25);
      expect(game.debugRenderedPlayerFootCell, _b);
      expect(
        game.debugScriptedNpcDynamicBlockedCells(ignoreEntityId: 'leader'),
        containsAll([_c, const GridPos(x: 3, y: 3)]),
      );
    },
  );

  test(
    'dispose invalidates pending landing callback without dispatching effects',
    () async {
      final game = await _load();
      _jump(game);
      expect(game.debugIsPlayerStepping, isTrue);
      game.update(.1);
      game.onRemove();
      game.update(1);
      expect(game.debugEncounterCheckCount, 0);
      expect(game.debugIsPlayerStepping, isFalse);
    },
  );

  test(
    'map activation cancels an obsolete jump before its landing consequences',
    () async {
      final game = await _load();
      addTearDown(game.onRemove);
      _jump(game);
      expect(game.debugIsPlayerStepping, isTrue);
      game.update(.1);
      var completed = false;
      final warp = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.warp(
              destinationMapId: 'next',
              warpId: 'arrival',
            ),
          )
          .whenComplete(() => completed = true);
      await _pump(game, () => completed);
      expect(await warp, 'completed');
      game.update(1);
      expect(game.debugEncounterCheckCount, 0);
      expect(game.debugScriptedNpcDynamicBlockedCells(), isNot(contains(_c)));
      expect(
        game.debugScriptedNpcDynamicBlockedCells(),
        isNot(contains(const GridPos(x: 3, y: 3))),
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(
        game.inputAuthoritySnapshot.context,
        RuntimeInputContext.overworld,
      );
    },
  );

  test(
    'only final Event V2 trigger is dispatched once after the jump settles',
    () async {
      const intermediateEvent = 'evt_019abcde-3000-7000-8000-000000000001';
      const landingEvent = 'evt_019abcde-3000-7000-8000-000000000002';
      final prepared = <NarrativeEventSourceRef>[];
      final manifest = ProjectManifest(
        name: 'Jump V2',
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
        maps: const [
          ProjectMapEntry(
            id: 'jump',
            name: 'Jump',
            relativePath: 'maps/jump.json',
          ),
        ],
        tilesets: const [],
        facts: [
          for (final name in ['intermediate', 'landing'])
            NarrativeFactDefinition(id: 'fact.$name', label: name),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          legacyClaims: const [],
          records: [
            for (final (name, id) in [
              ('intermediate', intermediateEvent),
              ('landing', landingEvent),
            ])
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: id,
                  name: name,
                  source: NarrativeEventSourceRef.triggerEnter('jump', name),
                  sceneId: 'scene.$name',
                  conditions: const [],
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
          ],
        ),
        scenes: [
          for (final name in ['intermediate', 'landing'])
            SceneAsset(
              id: 'scene.$name',
              name: name,
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'fact',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.consequence(
                      SceneConsequence.setFact(
                        factId: 'fact.$name',
                        value: true,
                      ),
                    ),
                  ),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'start-fact',
                    fromNodeId: 'start',
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
            ),
        ],
      );
      final game = await _load(
        manifest: manifest,
        map: _map(
          triggers: [
            for (final (name, pos) in [('intermediate', _b), ('landing', _c)])
              MapTrigger(
                id: name,
                name: name,
                type: TriggerType.event,
                area: MapRect(
                  pos: pos,
                  size: const GridSize(width: 1, height: 1),
                ),
              ),
          ],
        ),
        beforeAuthority: (occurrence) async {
          if (occurrence.source.kind == NarrativeEventSourceKind.triggerEnter) {
            prepared.add(occurrence.source);
          }
        },
      );
      addTearDown(game.onRemove);
      _jump(game);
      game.update(.49);
      await Future<void>.delayed(Duration.zero);
      expect(prepared, isEmpty);
      game.update(.01);
      await _pump(
        game,
        () =>
            game
                    .gameStateSnapshot
                    .narrativeFactRuntimeState
                    .overridesByFactId['fact.landing'] ==
                true &&
            !game.debugIsNarrativeSpatialDispatchInFlight,
      );
      for (var i = 0; i < 10; i++) {
        game.update(.1);
        await Future<void>.delayed(Duration.zero);
      }
      expect(prepared, [
        NarrativeEventSourceRef.triggerEnter('jump', 'landing'),
      ]);
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId['fact.intermediate'],
        isNot(isTrue),
      );
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(landingEvent),
      );
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(intermediateEvent)),
      );
    },
  );
}

final class _JumpSounds implements OverworldSfxPlayer {
  int starts = 0;
  int disposals = 0;

  @override
  Future<void> playJump() async => starts++;

  @override
  Future<void> playCut() async {}

  @override
  Future<void> dispose() async => disposals++;
}
