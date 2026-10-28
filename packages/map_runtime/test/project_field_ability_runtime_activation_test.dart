import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' as flash;
import 'playable_map_game_fly_test.dart' as fly;
import 'playable_map_game_dive_test.dart' as dive;
import 'playable_map_game_waterfall_test.dart' as waterfall;
import 'playable_map_game_whirlpool_test.dart' as whirlpool;

ProjectFieldAbilitiesSettings disabled(FieldAbility ability) =>
    ProjectFieldAbilitiesSettings(disabledAbilities: [ability]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final ability in [
    FieldAbility.flash,
    FieldAbility.waterfall,
    FieldAbility.whirlpool,
    FieldAbility.dive,
  ]) {
    testWidgets(
      'disabled ${ability.name} hides its native action without changing saved progression',
      (tester) async {
        await tester.runAsync(() async {
          final policy = disabled(ability);
          final game = switch (ability) {
            FieldAbility.flash => await flash.mountFlash(
              tester,
              fieldAbilities: policy,
            ),
            FieldAbility.waterfall => await waterfall.mountWaterfall(
              tester,
              fieldAbilities: policy,
            ),
            FieldAbility.whirlpool => await whirlpool.mountWhirlpool(
              tester,
              fieldAbilities: policy,
            ),
            FieldAbility.dive => await dive.mountDive(
              tester,
              fieldAbilities: policy,
            ),
            _ => throw StateError('Unexpected fixture'),
          };
          expect(game.overworldInteractionSnapshot.primaryAction, isNull);
          final before = game.gameStateSnapshot;
          await flash.press(game, RuntimeInputControl.primary);
          expect(game.gameStateSnapshot, before);
          expect(game.debugFlowPhaseName, 'overworld');
        });
      },
    );
  }

  testWidgets(
    'disabled Fly is unavailable through the real regional map service',
    (tester) async {
      await tester.runAsync(() async {
        final mounted = await fly.mountFly(
          tester,
          save: flash.MemorySave(),
          fieldAbilities: disabled(FieldAbility.fly),
        );
        final opening = (await mounted.game.openPlayerRegionalMap())!;
        final controller = mounted.controller;
        final before = mounted.game.gameStateSnapshot;
        final result = await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.select,
            targetId: 'town',
            snapshotRevision: controller.worldServiceSnapshot!.revision,
          ),
        );
        expect(result.status, RuntimeWorldServiceCommandStatus.unavailable);
        expect(mounted.game.gameStateSnapshot, before);
        await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.close,
            snapshotRevision: controller.worldServiceSnapshot!.revision,
          ),
        );
        expect(await opening.completed, RuntimeRegionalMapClosing.closed);
      });
    },
  );

  testWidgets(
    'disabling Dive preserves native saved ascent and Continue mode',
    (tester) async {
      await tester.runAsync(() async {
        final save = flash.MemorySave();
        final game = await dive.mountDive(tester, save: save);
        await dive.confirmDive(game);
        expect(game.gameStateSnapshot.currentMapId, 'deep');
        expect(await game.saveGame(), isTrue);
        final restored = (await save.load())!;
        final cold = await dive.mountDive(
          tester,
          restored: restored,
          fieldAbilities: disabled(FieldAbility.dive),
        );
        expect(cold.playerMovementMode, MovementMode.dive);
        await dive.confirmDive(cold);
        expect(cold.gameStateSnapshot.currentMapId, 'sea');
        expect(cold.playerMovementMode, MovementMode.surf);
      });
    },
  );
  testWidgets(
    'disabling Flash preserves saved illumination on a fresh runtime',
    (tester) async {
      await tester.runAsync(() async {
        final game = await flash.mountFlash(tester);
        final state = game.gameStateSnapshot;
        final scope = state.mapInstanceWorldState.instanceRef('cave')!;
        final restored = GameState.fromJson(
          state
              .copyWith(
                mapInstanceWorldState: state.mapInstanceWorldState
                    .illuminateZone(scope, 'dark'),
              )
              .toJson(),
        );
        final cold = await flash.mountFlash(
          tester,
          restored: restored,
          fieldAbilities: disabled(FieldAbility.flash),
        );
        expect(
          cold.gameStateSnapshot.mapInstanceWorldState.isZoneIlluminated(
            scope,
            'dark',
          ),
          isTrue,
        );
        expect(
          cold.gameStateSnapshot.progression.unlockedFieldAbilities,
          contains(FieldAbility.flash),
        );
        expect(cold.overworldInteractionSnapshot.primaryAction, isNull);
      });
    },
  );
}
