import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('connected cinematic capability follows authored coordinates and dynamic origins', () {
    const map = MapData(id: 'map', name: 'Map', size: GridSize(width: 8, height: 8));
    final neighbor = map.copyWith(id: 'neighbor', connections: [
      const MapConnection(direction: MapConnectionDirection.west, targetMapId: 'map'),
    ]);
    bool requires(double x, double y, {String? origin, bool connected = true}) =>
        SpatialGameplayCapabilities.requiresConnectedCinematics(
          ProjectManifest(name: 'Game', maps: [], tilesets: [], cinematics: [
            CinematicAsset(id: 'movie', title: 'Movie', mapId: 'map',
              timeline: CinematicTimeline(),
              stageContext: CinematicStageContext(stagePoints: [
                CinematicStagePoint(id: 'point', label: 'Point', x: x, y: y,
                    relativeToActorId: origin),
              ])),
          ]), maps: [map, if (connected) neighbor]);
    expect(requires(4.5, 4.5), isFalse);
    expect(requires(8.5, 4.5), isTrue);
    expect(requires(-.5, 4.5), isTrue);
    expect(requires(0, 0, origin: 'guide'), isFalse);
    expect(requires(-1, 0, origin: 'guide'), isTrue);
    expect(requires(-1, 0, origin: 'guide', connected: false), isFalse);
  });

  test('presentation cinematics use the pre-session profile in 3D', () {
    final node = SceneNode(
      id: 'opening',
      kind: SceneNodeKind.presentationCinematic,
      payload: ScenePresentationCinematicPayload(
        presentationCinematicId: 'welcome',
      ),
    );
    expect(SpatialGameplayCapabilities.supportsSceneNode(
        SceneExecutionProfile.preSession, node), isTrue);
    expect(SpatialGameplayCapabilities.supportsSceneNode(
        SceneExecutionProfile.world, node), isFalse);
  });

  test('spatial profile accepts existing facing and emote contracts', () {
    expect(
      SpatialGameplayCapabilities.cinematicStepKinds,
      contains(CinematicTimelineStepKind.actorEmote),
    );
    expect(
      SpatialGameplayCapabilities.supportsSceneNode(
        SceneExecutionProfile.world,
        SceneNode(
          id: 'direction',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource.playerFacing(
              direction: EntityFacing.west,
            ),
          ),
        ),
      ),
      isTrue,
    );
  });

  bool supports(SceneNodePayload payload) =>
      SpatialGameplayCapabilities.supportsSceneNode(
        SceneExecutionProfile.world,
        SceneNode(id: 'node', kind: payload.kind, payload: payload),
      );

  test(
    'the profile keeps production export closed and exact condition sources',
    () {
      expect(SpatialGameplayCapabilities.capabilityId, 'map3d.gameplay@1');
      expect(SpatialGameplayCapabilities.productionExportEnabled, false);
      expect(SpatialGameplayCapabilities.conditionSources, {
        SceneConditionSourceKind.playerFacing,
        SceneConditionSourceKind.integerComparison,
        SceneConditionSourceKind.inventoryItem,
        SceneConditionSourceKind.badge,
        SceneConditionSourceKind.fact,
        SceneConditionSourceKind.factLikeStoryFlag,
        SceneConditionSourceKind.storyStepCompletion,
        SceneConditionSourceKind.consumedEvent,
        SceneConditionSourceKind.trainerDefeated,
        SceneConditionSourceKind.partyState,
      });
      for (final kind in SceneConditionSourceKind.values.where(
        (kind) => kind != SceneConditionSourceKind.newGameDraft,
      )) {
        final source = switch (kind) {
          SceneConditionSourceKind.integerComparison => SceneConditionSource.integerComparison(
            left: SceneIntegerOperand.literal(1), right: SceneIntegerOperand.literal(1), comparison: NarrativeFactOperator.equals),
          SceneConditionSourceKind.partyState =>
            SceneConditionSource.partyCanReceivePokemon(),
          SceneConditionSourceKind.playerFacing => SceneConditionSource(
            sourceKind: kind,
            sourceId: EntityFacing.north.name,
            operator: SceneConditionOperator.isTrue,
          ),
          SceneConditionSourceKind.playerAtEntityAnchor ||
          SceneConditionSourceKind.mapEventInstanceBoolean =>
            SceneConditionSource(
              sourceKind: kind,
              sourceId: 'source',
              mapId: 'map',
              key: kind == SceneConditionSourceKind.mapEventInstanceBoolean
                  ? 'enabled'
                  : null,
              operator: SceneConditionOperator.isTrue,
            ),
          SceneConditionSourceKind.pokedexCaughtCount =>
            SceneConditionSource.pokedexCaughtAtLeast(
              range: PokedexSpeciesRange(
                firstNationalDex: 1,
                lastNationalDex: 151,
              ),
              minimum: 1,
            ),
          _ => SceneConditionSource(
            sourceKind: kind,
            sourceId: 'source',
            operator: SceneConditionOperator.isTrue,
          ),
        };
        expect(
          supports(SceneConditionPayload(conditionSource: source)),
          SpatialGameplayCapabilities.conditionSources.contains(kind),
          reason: kind.name,
        );
      }
    },
  );

  test('only typed supported commands may be executed', () {
    expect(
      supports(
        SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact', value: true),
        ),
      ),
      true,
    );
    expect(
      supports(
        SceneActionPayload.interactive(SceneInteractiveCommand.openHeal()),
      ),
      true,
    );
    expect(
      supports(
        SceneActionPayload.interactive(
          SceneInteractiveCommand.openShop(shopId: 'shop'),
        ),
      ),
      true,
    );
    expect(
      supports(
        SceneActionPayload.interactive(SceneInteractiveCommand.openPc()),
      ),
      true,
    );
    expect(
      supports(
        SceneActionPayload.interactive(
          SceneInteractiveCommand.moveNpc(
            mapId: 'map',
            entityId: 'npc',
            warpId: 'warp',
          ),
        ),
      ),
      false,
    );
    expect(supports(SceneActionPayload(actionKind: 'giveMoney')), false);
    expect(supports(SceneConditionPayload(conditionDraft: 'script()')), false);
  });

  test('world cinematics are qualified and unknown battle types rejected', () {
    expect(supports(SceneCinematicPayload(cinematicId: 'movie')), true);
    for (final kind in ['wild', 'trainer', 'static', 'unsupported']) {
      expect(
        supports(SceneBattlePayload(battleKind: kind)),
        kind != 'unsupported',
      );
    }
  });

  test(
    'empty 3D maps stay exploration while map gameplay selects the profile',
    () {
      const project = ProjectManifest(
        name: 'Spatial',
        maps: [],
        tilesets: [],
        pokemon: ProjectPokemonConfig(
          enabled: false,
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 2, height: 2),
      );
      expect(
        SpatialGameplayCapabilities.requiresGameplay(project, maps: [map]),
        false,
      );
      for (final entity in [
        const MapEntity(
          id: 'object',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 0, y: 0),
        ),
        const MapEntity(
          id: 'visual',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 0),
          editorVisual: MapEntityEditorVisual(elementId: 'element'),
        ),
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 0, y: 0),
          npc: MapEntityNpcData(
            visibilityRule: const MapEntityNpcVisibilityRule(
              mode: MapEntityNpcVisibilityMode.hiddenWhen,
              predicate: MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.storyFlagSet,
                refId: 'fact',
              ),
            ),
          ),
        ),
      ]) {
        expect(
          SpatialGameplayCapabilities.requiresGameplay(
            project,
            maps: [
              map,
              map.copyWith(id: 'other', entities: [entity]),
            ],
          ),
          true,
        );
      }
      expect(
        SpatialGameplayCapabilities.requiresGameplay(
          project.copyWith(
            facts: [NarrativeFactDefinition(id: 'quest', label: 'Quest')],
          ),
        ),
        true,
      );
      expect(
        SpatialGameplayCapabilities.requiresGameplay(
          project,
          maps: [
            map.copyWith(
              triggers: [
                const MapTrigger(
                  id: 'area',
                  type: TriggerType.event,
                  area: MapRect(
                    pos: GridPos(x: 0, y: 0),
                    size: GridSize(width: 1, height: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
        true,
      );
    },
  );
}
