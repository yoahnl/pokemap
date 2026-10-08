import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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
        SceneConditionSourceKind.inventoryItem,
        SceneConditionSourceKind.fact,
        SceneConditionSourceKind.factLikeStoryFlag,
        SceneConditionSourceKind.storyStepCompletion,
        SceneConditionSourceKind.consumedEvent,
      });
      for (final kind in SceneConditionSourceKind.values.where(
        (kind) => kind != SceneConditionSourceKind.newGameDraft,
      )) {
        expect(
          supports(
            SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: kind,
                sourceId: 'source',
                operator: SceneConditionOperator.isTrue,
              ),
            ),
          ),
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
