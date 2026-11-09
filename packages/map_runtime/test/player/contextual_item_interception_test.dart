import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final spatial in [false, true]) {
    test(
      'false contextual condition preserves normal party healing spatial=$spatial',
      () async {
        var state = const GameState(
          saveId: 'potion-context',
          currentMapId: 'map',
          party: PlayerParty(
            members: [
              PlayerPokemon(
                individualId: 'lead',
                speciesId: 'lead',
                natureId: 'hardy',
                abilityId: 'natural',
                currentHp: 10,
              ),
            ],
          ),
          bag: Bag(entries: [BagEntry(itemId: 'potion', quantity: 2)]),
        );
        final project = ProjectManifest(
          name: 'Potion',
          maps: [],
          tilesets: [],
          facts: [NarrativeFactDefinition(id: 'ready', label: 'Ready')],
        );
        final map = MapData(
          id: 'map',
          name: 'Map',
          version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
          size: const GridSize(width: 8, height: 8),
          spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
          mapMetadata: MapMetadata(
            contextualItemUses: [
              ContextualItemUseRule(
                id: 'guarded',
                itemId: 'potion',
                sceneId: 'secret',
                conditionExpression: NarrativeEventConditionExpression.leaf(
                  NarrativeEventCondition.fact('ready', true),
                ),
              ),
            ],
          ),
        );
        final ids = contextualItemUseIds(
          map: map,
          project: project,
          state: state,
        );
        expect(ids, isEmpty);
        final details = await const RuntimePlayerPauseDataBuilder().build(
          gameState: state,
          projectRootDirectory: '/unavailable-contextual-catalogue',
          pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ),
          locale: 'fr',
          itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
          contextualItemIds: ids,
        );
        final bag = details[RuntimePlayerPauseSection.bag]!;
        final action = bag.entries.single.bagAction!;
        expect(action.targetKind, RuntimePlayerBagUseTargetKind.partyMember);
        var writes = 0;
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => state,
          commitAndSave: (next) async {
            writes++;
            state = next;
          },
          setInputLocked: (_) {},
          loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
            maxHpByPartyIndex: {0: 30},
          ),
          itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
        );
        addTearDown(controller.dispose);
        controller.setContextualItemUseConsumer(
          (item, current) =>
              selectContextualItemUse(
                map: map,
                project: project,
                state: current,
                itemId: item.id,
              ) is ContextualItemUseNoMatch
              ? RuntimeContextualItemUseDisposition.noMatch
              : RuntimeContextualItemUseDisposition.refused,
        );
        final result = await controller.useBagItemOutsideBattle(
          RuntimePlayerPauseCommand.useBagItem(
            itemTargetId: action.itemTargetId,
            partyTargetId: bag.bagTargets.single.targetId,
          ),
        );
        expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
        expect(writes, 1);
        expect(state.party.members.single.currentHp, 30);
        expect(state.bag.entries.single.quantity, 1);
      },
    );
  }
  for (final disposition in RuntimeContextualItemUseDisposition.values) {
    test('contextual $disposition only falls back on no match', () async {
      const state = GameState(
        saveId: 'context',
        bag: Bag(entries: [BagEntry(itemId: 'rope', quantity: 2)]),
      );
      var normalCalls = 0;
      var contextualCalls = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (_) async => fail('interception must not consume'),
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) async => throw StateError('no party'),
        itemCatalog: ItemCatalogSnapshot.fromCatalog(
          ProjectItemCatalog(
            schemaVersion: 1,
            entries: const [
              ProjectItemDefinition(
                id: 'rope',
                displayName: 'Corde',
                pocketId: 'items',
                uses: [
                  ProjectItemUseDefinition(
                    contexts: {ProjectItemUseContext.overworld},
                    target: ProjectItemTargetKind.world,
                    consumption: ProjectItemConsumptionPolicy.onApplied,
                    effect: ProjectItemEffectDefinition.escapeRope(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      addTearDown(controller.dispose);
      controller.setEscapeRopeConsumer((_, _) async {
        normalCalls++;
        return true;
      });
      controller.setContextualItemUseConsumer((_, _) async {
        contextualCalls++;
        return disposition;
      });
      final result = await controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'rope'),
      );
      expect(contextualCalls, 1);
      expect(
        normalCalls,
        disposition == RuntimeContextualItemUseDisposition.noMatch ? 1 : 0,
      );
      expect(
        result.resumeGameplay,
        disposition == RuntimeContextualItemUseDisposition.reserved,
      );
      expect(result.status, switch (disposition) {
        RuntimeContextualItemUseDisposition.noMatch ||
        RuntimeContextualItemUseDisposition.reserved =>
          RuntimePlayerPauseCommandStatus.accepted,
        RuntimeContextualItemUseDisposition.cancelled ||
        RuntimeContextualItemUseDisposition.refused =>
          RuntimePlayerPauseCommandStatus.unavailable,
      });
    });
  }
}
