import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'regional map keeps keyboard focus after asynchronous Fly updates',
    (tester) async {
      final session = await _mount(tester);
      expect(_focusedInside(PlayerRegionalMapOverlay), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(session.prepared, ['clairbois']);
      expect(session.content.selectedPointId, isNull);
      session.preparation.complete();
      await tester.pumpAndSettle();
      expect(session.content.selectedPointId, 'clairbois');
      expect(session.content.message, 'Voler vers Clairbois ?');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(session.service.worldServiceSnapshot, isNotNull);
      expect(session.content.selectedPointId, isNull);
      expect(session.content.message, isNull);
      expect(
        session.worldCommands.last.action,
        RuntimeWorldServiceAction.cancel,
      );
      expect(session.state, same(_initialState));
      expect(session.transfers, isEmpty);
      expect(_focusedInside(PlayerRegionalMapOverlay), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(session.service.worldServiceSnapshot, isNull);
      expect(session.snapshot.phase, RuntimePlayerPhase.paused);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Player action: Carte',
      );
      expect(session.commands.map((command) => command.action), [
        RuntimePlayerAction.openMap,
      ]);
      expect(session.backRequests, isEmpty);
      expect(session.state, same(_initialState));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('regional map local back and Fly confirmation stay above pause', (
    tester,
  ) async {
    final session = await _mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    session.preparation.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('region-map-info')), findsNothing);
    expect(
      find.byKey(const ValueKey('region-detail-clairbois')),
      findsOneWidget,
    );
    for (final key in ['region-map-region']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      final commandsBeforeBack = session.worldCommands.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(session.worldCommands.length, commandsBeforeBack);
      expect(session.content.selectedPointId, 'clairbois');
      expect(session.content.message, 'Voler vers Clairbois ?');
      expect(_focusedInside(PlayerRegionalMapOverlay), isTrue);
    }

    for (var count = 0; count < 2; count++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(
      _focusedInsideKey(const ValueKey('regional-map-fly-confirm')),
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      session.worldCommands.last.action,
      RuntimeWorldServiceAction.confirm,
    );
    expect(session.transfers, ['clairbois']);
    expect(session.state.currentMapId, 'clairbois');
    expect(session.service.worldServiceSnapshot, isNull);
    expect(session.commands.map((command) => command.action), [
      RuntimePlayerAction.openMap,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unavailable Fly reason keeps keyboard back in the regional map',
    (tester) async {
      final session = await _mount(tester, denied: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      session.preparation.complete();
      await tester.pumpAndSettle();
      expect(session.content.selectedPointId, isNull);
      expect(
        session.content.message,
        'Vol n’est pas encore débloqué dans votre progression.',
      );
      expect(_focusedInside(PlayerRegionalMapOverlay), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(session.service.worldServiceSnapshot, isNull);
      expect(
        session.worldCommands.last.action,
        RuntimeWorldServiceAction.cancel,
      );
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Player action: Carte',
      );
      expect(session.state, same(_initialState));
      expect(session.transfers, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

bool _focusedInside(Type type) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  var found = false;
  focus.visitAncestorElements((element) {
    if (element.widget.runtimeType == type) found = true;
    return !found;
  });
  return found;
}

bool _focusedInsideKey(Key key) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  var found = false;
  focus.visitAncestorElements((element) {
    if (element.widget.key == key) found = true;
    return !found;
  });
  return found;
}

Future<_RegionalMapSession> _mount(
  WidgetTester tester, {
  bool denied = false,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = _RegionalMapSession(denied: denied);
  addTearDown(session.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(reducedMotion: true),
      home: PokeMapPlayerSessionView(
        controller: session,
        controllerInputEnabled: false,
        touchControlsAvailable: false,
        titlePresentation: const RuntimePlayerTitlePresentation(author: 'Test'),
        gameSceneBuilder: (_) => const SizedBox.expand(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    FocusManager.instance.primaryFocus?.debugLabel,
    'Player action: Carte',
  );
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(find.byType(PlayerRegionalMapOverlay), findsOneWidget);
  return session;
}

const _initialState = GameState(
  saveId: 'regional-focus',
  currentMapId: 'source',
  playerPosition: GridPos(x: 1, y: 1),
);

final class _RegionalMapSession implements RuntimePlayerViewController {
  _RegionalMapSession({required this.denied}) {
    service = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => fail('Opening the map must not save.'),
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => throw StateError('No healing requested'),
    );
    _subscription = service.worldServiceSnapshots.listen((_) {
      _revision++;
      _snapshots.add(snapshot);
    });
  }

  final bool denied;
  final preparation = Completer<void>();
  final prepared = <String>[];
  final transfers = <String>[];
  final commands = <RuntimePlayerCommand>[];
  final worldCommands = <RuntimeWorldServiceCommand>[];
  final backRequests = <int>[];
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  late final PlayerServiceRuntimeController service;
  late final StreamSubscription<RuntimeWorldServiceSnapshot?> _subscription;
  var state = _initialState;
  var _revision = 1;

  RuntimeRegionalMapServiceContent get content =>
      service.worldServiceSnapshot!.content as RuntimeRegionalMapServiceContent;

  @override
  RuntimePlayerSnapshot get snapshot => RuntimePlayerSnapshot(
    revision: _revision,
    phase: RuntimePlayerPhase.paused,
    pauseSection: RuntimePlayerPauseSection.root,
    logicalSelectionId: 'pause.map',
    gameTitle: 'Hub',
    worldService: service.worldServiceSnapshot,
    actions: const [
      RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMap),
      RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
    ],
  );

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) async {
    commands.add(command);
    if (command.action == RuntimePlayerAction.openMap &&
        service.worldServiceSnapshot == null) {
      unawaited(
        service.openRegionalMap(
          request: const OpenRegionalMapService(interactionId: 'player.map'),
          detail: RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.map,
            title: 'Carte',
            regionalMap: RuntimePlayerRegionMapSnapshot(
              regions: [
                RuntimePlayerRegionSnapshot(
                  id: 'region',
                  label: 'Région',
                  points: const [
                    RuntimePlayerMapPointSnapshot(
                      id: 'clairbois',
                      label: 'Clairbois',
                      status: RuntimePlayerMapPointStatus.discovered,
                    ),
                    RuntimePlayerMapPointSnapshot(
                      id: 'source',
                      label: 'Départ',
                      status: RuntimePlayerMapPointStatus.current,
                    ),
                  ],
                ),
                RuntimePlayerRegionSnapshot(
                  id: 'other',
                  label: 'Autre région',
                  points: const [],
                ),
              ],
            ),
          ),
          prepareFly: (id) async {
            prepared.add(id);
            await preparation.future;
            if (denied) return (ticket: null, reason: FlyBlockReason.locked);
            final map = MapData(
              id: 'source',
              name: 'Source',
              size: const GridSize(width: 8, height: 8),
            );
            return (
              ticket: FlyActionTicket(
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
              ),
              reason: null,
            );
          },
          applyFly: (ticket) async {
            transfers.add(ticket.evaluation.pointId);
            state = state.copyWith(
              currentMapId: ticket.evaluation.arrival.mapId,
              playerPosition: ticket.evaluation.arrival.position,
            );
            return true;
          },
        ),
      );
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      );
    }
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.unavailable,
    );
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) {
    worldCommands.add(command);
    return service.dispatchWorldService(command);
  }

  @override
  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  }) async {
    backRequests.add(snapshotRevision);
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.unavailable,
    );
  }

  Future<void> dispose() async {
    if (!preparation.isCompleted) preparation.complete();
    await _subscription.cancel();
    await service.dispose();
    await _snapshots.close();
  }
}
