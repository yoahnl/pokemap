import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const tool = ProjectItemDefinition(
  id: 'custom_tool',
  displayName: 'Outil',
  pocketId: 'custom',
  tags: {'key-item'},
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.world,
      consumption: ProjectItemConsumptionPolicy.never,
      effect: ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.oldRod,
      ),
    ),
  ],
);

void main() {
  for (final available in [false, true]) {
    test(
      'fishing reserves before resume and never waits for battle: supported=$available',
      () async {
        const state = GameState(
          saveId: 'fishing',
          bag: Bag(entries: [BagEntry(itemId: 'custom_tool', quantity: 1)]),
        );
        var commits = 0, reservations = 0, locks = 0;
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => state,
          commitAndSave: (_) async => commits++,
          setInputLocked: (_) => locks++,
          loadRecoveryCaps: (_) async => throw StateError('no party request'),
          itemCatalog: ItemCatalogSnapshot.fromCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: [tool]),
          ),
        );
        addTearDown(controller.dispose);
        if (available) {
          controller.setFishingConsumer((item, snapshot) {
            expect(item, tool);
            expect(snapshot, state);
            reservations++;
            return null;
          });
        }
        final result = await controller.useBagItemOutsideBattle(
          const RuntimePlayerPauseCommand.useBagItem(
            itemTargetId: 'custom_tool',
          ),
        );
        expect(
          result.status,
          available
              ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
        );
        expect(result.resumeGameplay, available);
        if (!available) {
          expect(
            result.safeMessage,
            'La pêche nécessite un runtime compatible.',
          );
        }
        expect(reservations, available ? 1 : 0);
        expect(commits, 0);
        expect(locks, 0);
        expect(state.bag.entries.single.quantity, 1);
      },
    );
  }
}
