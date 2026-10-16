import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main() {
  for (final emptyRegion in [false, true]) {
    testWidgets(
      'changing region invalidates the old Fly ticket ${emptyRegion ? 'without another destination' : 'before preparing its visible destination'}',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const initial = GameState(
          saveId: 'fly-region',
          currentMapId: 'source',
          playerPosition: GridPos(x: 1, y: 1),
        );
        var state = initial;
        final transfers = <String>[];
        final prepareB = Completer<void>();
        addTearDown(() {
          if (!prepareB.isCompleted) prepareB.complete();
        });
        final map = MapData(
          id: 'source',
          name: 'Source',
          size: const GridSize(width: 8, height: 8),
        );
        FlyActionTicket ticket(String id) => FlyActionTicket(
          evaluation: CanUseFly(
            pointId: id,
            partyIndex: 0,
            arrival: FlyArrival(
              mapId: id,
              entityId: 'arrival',
              position: const GridPos(x: 3, y: 4),
              facing: EntityFacing.west,
            ),
          ),
          gameState: state,
          sourceMap: map,
          targetMap: map,
          catalog: ProjectRegionalMapCatalog(),
          issuedAtStateRevision: 1,
        );
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => state,
          commitAndSave: (_) async => fail('Fly does not save automatically.'),
          setInputLocked: (_) {},
          loadRecoveryCaps: (_) async => throw StateError('No healing'),
        );
        addTearDown(controller.dispose);
        final open = controller.openRegionalMap(
          request: const OpenRegionalMapService(interactionId: 'player.map'),
          detail: RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.map,
            title: 'Carte',
            regionalMap: RuntimePlayerRegionMapSnapshot(
              regions: [
                RuntimePlayerRegionSnapshot(
                  id: 'first',
                  label: 'Région A',
                  points: const [
                    RuntimePlayerMapPointSnapshot(
                      id: 'townA',
                      label: 'Ville A',
                      status: RuntimePlayerMapPointStatus.current,
                    ),
                  ],
                ),
                RuntimePlayerRegionSnapshot(
                  id: 'second',
                  label: 'Région B',
                  points: [
                    if (!emptyRegion)
                      const RuntimePlayerMapPointSnapshot(
                        id: 'townB',
                        label: 'Ville B',
                        status: RuntimePlayerMapPointStatus.discovered,
                      ),
                  ],
                ),
              ],
            ),
          ),
          prepareFly: (id) async {
            if (id == 'townB') await prepareB.future;
            return (ticket: ticket(id), reason: null);
          },
          applyFly: (ticket) async {
            transfers.add(ticket.evaluation.pointId);
            state = state.copyWith(
              currentMapId: ticket.evaluation.arrival.mapId,
              playerPosition: ticket.evaluation.arrival.position,
              playerMovementMode: MovementMode.walk,
            );
            return true;
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: PokeMapPlayerTheme.dark(),
            home: StreamBuilder<RuntimeWorldServiceSnapshot?>(
              stream: controller.worldServiceSnapshots,
              initialData: controller.worldServiceSnapshot,
              builder: (_, snapshot) => snapshot.data == null
                  ? const SizedBox()
                  : PlayerRegionalMapOverlay(
                      snapshot: snapshot.data!,
                      onCommand: controller.dispatchWorldService,
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('region-row-townA')));
        await tester.pumpAndSettle();
        final oldRevision = controller.worldServiceSnapshot!.revision;
        expect(
          controller.worldServiceSnapshot!.isActionEnabled(
            RuntimeWorldServiceAction.confirm,
          ),
          isTrue,
        );
        await tester.tap(find.byKey(const ValueKey('region-map-region')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('region-choice-second')));
        await tester.pump();
        expect(find.text('Région B'), findsWidgets);
        final oldConfirm = await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.confirm,
            snapshotRevision: oldRevision,
          ),
        );
        expect(oldConfirm.status, RuntimeWorldServiceCommandStatus.stale);
        expect(transfers, isEmpty);
        expect(state, initial);
        expect(
          controller.worldServiceSnapshot!.isActionEnabled(
            RuntimeWorldServiceAction.confirm,
          ),
          isFalse,
        );
        if (emptyRegion) {
          expect(
            (controller.worldServiceSnapshot!.content
                    as RuntimeRegionalMapServiceContent)
                .selectedPointId,
            isNull,
          );
          expect(
            find.byKey(const ValueKey('regional-map-fly-confirm')),
            findsNothing,
          );
          await controller.dispatchWorldService(
            RuntimeWorldServiceCommand(
              action: RuntimeWorldServiceAction.close,
              snapshotRevision: controller.worldServiceSnapshot!.revision,
            ),
          );
        } else {
          expect(
            find.byKey(const ValueKey('region-row-townB')),
            findsOneWidget,
          );
          prepareB.complete();
          await tester.pumpAndSettle();
          expect(find.text('Voler vers Ville B ?'), findsOneWidget);
          expect(find.text('Voler vers Ville A ?'), findsNothing);
          expect(
            (controller.worldServiceSnapshot!.content
                    as RuntimeRegionalMapServiceContent)
                .selectedPointId,
            'townB',
          );
          await tester.tap(
            find.byKey(const ValueKey('regional-map-fly-confirm')),
          );
          await tester.pumpAndSettle();
          expect(transfers, ['townB']);
          expect(state.currentMapId, 'townB');
        }
        expect((await open).status, PlayerServiceRuntimeStatus.completed);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final size in [const Size(1000, 700), const Size(360, 640)]) {
    testWidgets('contextual map reuses regional view and closes at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final commands = <RuntimeWorldServiceCommand>[];
      final snapshot = RuntimeWorldServiceSnapshot(
        revision: 7,
        request: const OpenRegionalMapService(interactionId: 'wall.map'),
        stage: RuntimeWorldServiceStage.active,
        content: RuntimeRegionalMapServiceContent(
          selectedPointId: 'route10',
          message: 'Voler vers ce lieu ?',
          detail: RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.map,
            title: 'Carte',
            regionalMap: RuntimePlayerRegionMapSnapshot(
              regions: [
                RuntimePlayerRegionSnapshot(
                  id: 'kanto',
                  label: 'Kanto',
                  points: const [
                    RuntimePlayerMapPointSnapshot(
                      id: 'route10',
                      label: 'Route 10',
                      status: RuntimePlayerMapPointStatus.current,
                      u: .6,
                      v: .2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: const [
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.select,
          ),
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.confirm,
          ),
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.close,
          ),
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.cancel,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: PlayerRegionalMapOverlay(
            snapshot: snapshot,
            onCommand: commands.add,
            controlProfile: PlayerControlProfile.standard
                .rebind(
                  device: PlayerControlDevice.keyboard,
                  control: RuntimeInputControl.secondary,
                  inputId: 'keyQ',
                )
                .profile,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RuntimePlayerRegionMap), findsOneWidget);
      expect(find.text('Kanto'), findsWidgets);
      expect(find.text('Route 10'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('regional-map-fly-confirm')));
      expect(commands.single.action, RuntimeWorldServiceAction.confirm);
      expect(commands.single.snapshotRevision, 7);
      commands.clear();
      await tester.tap(find.byKey(const ValueKey('regional-map-close')));
      expect(commands.single.action, RuntimeWorldServiceAction.close);
      expect(commands.single.snapshotRevision, 7);
      commands.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(commands, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      expect(commands.single.action, RuntimeWorldServiceAction.cancel);
      expect(commands.single.snapshotRevision, 7);
      expect(tester.takeException(), isNull);
    });
  }
}
