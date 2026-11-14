import 'package:avelune_studio/platform/playtest/studio_spatial_playtest_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../../packages/map_runtime/test/session/spatial_exploration_game_session_runtime_test.dart'
    as fixtures;
import 'studio_spatial_gameplay_playtest_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSpatialPlaytest);

  tearDown(tearDownSpatialPlaytest);

  testWidgets(
    'spatial playtest fills the scene under the toolbar Column loose width',
    (tester) async {
      final host = (await tester.runAsync(prepare))!;
      await tester.runAsync(() async {
        await host.runtime.load((_) {});
        await host.runtime.gameplayReady;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 40),
                Expanded(
                  child: StudioSpatialPlaytestView(runtime: host.runtime),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final sceneSize = tester.getSize(find.byType(SpatialExplorationView));
      final surfaceSize = tester.getSize(find.byType(Scaffold));
      expect(sceneSize.width, surfaceSize.width);
      expect(sceneSize.height, surfaceSize.height - 40);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('scene pointer restores movement focus after editing a setting', (
    tester,
  ) async {
    final host = (await tester.runAsync(prepare))!;
    await tester.runAsync(() async {
      await host.runtime.load((_) {});
      await host.runtime.gameplayReady;
    });
    final settingsFocus = FocusNode();
    addTearDown(settingsFocus.dispose);
    var sceneTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: StudioSpatialPlaytestView(
                  runtime: host.runtime,
                  sceneBuilder: (_) => GestureDetector(
                    key: const ValueKey('interactive-scene'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => sceneTaps++,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  key: const ValueKey('visual-setting'),
                  focusNode: settingsFocus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('visual-setting')));
    await tester.pump();
    expect(settingsFocus.hasFocus, isTrue);
    final movement = host.runtime.session!.movement;
    final startZ = movement.z;
    await tester.tap(find.byKey(const ValueKey('interactive-scene')));
    await tester.pump();
    expect(sceneTaps, 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    host.runtime.session!.frames(.3);
    expect(movement.z, greaterThan(startZ));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    expect(movement.inputDirection, (x: 0, z: 1));
    await tester.tap(find.byKey(const ValueKey('visual-setting')));
    await tester.pump();
    expect(settingsFocus.hasFocus, isTrue);
    expect(movement.inputDirection, (x: 0, z: 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(movement.inputDirection, (x: 0, z: 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Studio keyboard runs model Event V2 and save restores final pose',
    (tester) async {
      bundle = fixtures.animatedDoorBundle(bundle);
      final host = (await tester.runAsync(prepare))!;
      await tester.runAsync(() async {
        await host.runtime.load((_) {});
        await host.runtime.gameplayReady;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudioSpatialPlaytestView(
              runtime: host.runtime,
              sceneBuilder: (_) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        host
            .runtime
            .overworldInteractionSnapshot!
            .primaryAction!
            .request
            .targetKind,
        RuntimeOverworldInteractionTargetKind.modelInstance,
      );
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.enter),
      );
      await tester.runAsync(
        () => fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => active,
        ),
      );
      await tester.runAsync(() async {
        await expectLater(host.save(), throwsStateError);
      });
      await tester.runAsync(() async => host.runtime.session!.frames(.5));
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.escape),
      );
      await tester.runAsync(() async {
        await fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => !active,
        );
        await fixtures.waitForValue(
          host.runtime.inputAuthority,
          (value) => value.context == RuntimeInputContext.overworld,
        );
      });
      expect(host.runtime.gameStateSnapshot.trainerProfile.money, 0);
      expect(
        host.runtime.gameStateSnapshot.spatialWorldState,
        const SpatialWorldState.empty(),
      );
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.enter),
      );
      await tester.runAsync(
        () => fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => active,
        ),
      );
      await tester.runAsync(() async => host.runtime.session!.frames(2));
      await tester.runAsync(() async {
        await fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => !active,
        );
        await fixtures.waitForValue(
          host.runtime.inputAuthority,
          (value) => value.context == RuntimeInputContext.overworld,
        );
        await Future<void>.delayed(Duration.zero);
        expect(await host.save(), isTrue);
      });
      expect(saves.hasSave, isTrue);
      final state = host.runtime.gameStateSnapshot;
      expect(state.trainerProfile.money, 25);
      expect(
        state.spatialWorldState.modelState('field', 'door')!.normalizedTime,
        1,
      );
      expect(
        state.spatialWorldState.modelState('field', 'door')!.blocksMovement,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(host.dispose);
      final restored = (await tester.runAsync(() => prepare(restore: true)))!;
      await tester.runAsync(() async {
        await restored.runtime.load((_) {});
        await restored.runtime.gameplayReady;
      });
      expect(
        restored.runtime.gameStateSnapshot.spatialWorldState,
        state.spatialWorldState,
      );
      expect(restored.runtime.gameStateSnapshot.trainerProfile.money, 25);
      restored.runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(restored.runtime.gameStateSnapshot.trainerProfile.money, 25);
    },
  );
}
