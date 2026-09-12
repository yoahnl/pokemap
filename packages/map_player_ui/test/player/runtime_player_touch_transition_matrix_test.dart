import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final rotate in [true, false]) {
    testWidgets(
        'OW007 relayout cancels running and pending tap: rotation $rotate',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final events = <RuntimeInputEvent>[];
      final taps = <RuntimeOverworldInteractionRequest>[];
      var size = const Size(800, 600);
      var padding = EdgeInsets.zero;
      final request = _projection().primaryAction!.request;

      Widget app() => _material(MediaQuery(
            data: MediaQueryData(size: size, padding: padding),
            child: RuntimePlayerTouchControls(
              dispatch: events.add,
              sprintAllowed: true,
              sprintAccepted: true,
              readGameplayViewport: () => Offset.zero & size,
              resolveTapTarget: (_) => request,
              onTap: taps.add,
            ),
          ));

      await tester.pumpWidget(app());
      final running = await tester.startGesture(const Offset(100, 450),
          pointer: 1, kind: ui.PointerDeviceKind.touch);
      await running.moveBy(const Offset(50, 0));
      final pending = await tester.startGesture(const Offset(650, 100),
          pointer: 2, kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.press(RuntimeInputControl.right),
            RuntimeInputEvent.press(RuntimeInputControl.sprint),
          ]));
      expect(
          tester
              .widget<PlayerOverworldJoystickVisual>(
                  find.byType(PlayerOverworldJoystickVisual))
              .running,
          isTrue);
      events.clear();

      if (rotate) {
        size = const Size(600, 800);
        tester.view.physicalSize = size;
      } else {
        padding = const EdgeInsets.fromLTRB(32, 24, 48, 40);
      }
      await tester.pumpWidget(app());
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.right),
            RuntimeInputEvent.release(RuntimeInputControl.sprint),
          ]));
      await running.moveBy(const Offset(30, 0));
      await running.up();
      await pending.up();
      expect(events, hasLength(2));
      expect(taps, isEmpty);

      events.clear();
      final fresh = await tester.startGesture(Offset(100, size.height - 150),
          pointer: 3, kind: ui.PointerDeviceKind.touch);
      await fresh.moveBy(const Offset(50, 0));
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.press(RuntimeInputControl.right),
            RuntimeInputEvent.press(RuntimeInputControl.sprint),
          ]));
      final action = await tester.startGesture(Offset(size.width - 100, 100),
          pointer: 4, kind: ui.PointerDeviceKind.touch);
      await action.up();
      expect(taps, [request]);
      await fresh.up();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  for (final newSession in [true, false]) {
    testWidgets(
        'OW007 old pointers cannot release new owner: session $newSession',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final projection = ValueNotifier(_projection());
      addTearDown(projection.dispose);
      final events = <RuntimeInputEvent>[];
      final taps = <RuntimeOverworldInteractionRequest>[];
      await tester.pumpWidget(_material(RuntimePlayerTouchControls(
        dispatch: events.add,
        sprintAllowed: true,
        readGameplayViewport: () => const Rect.fromLTWH(0, 0, 800, 600),
        interactionChanges: projection,
        resolveTapTarget: (_) => projection.value.primaryAction?.request,
        onTap: taps.add,
      )));
      final oldMovement = await tester.startGesture(const Offset(100, 450),
          pointer: 1, kind: ui.PointerDeviceKind.touch);
      await oldMovement.moveBy(const Offset(50, 0));
      final oldAction = await tester.startGesture(const Offset(650, 100),
          pointer: 2, kind: ui.PointerDeviceKind.touch);
      events.clear();

      projection.value = _projection(
        session: newSession ? 'next-session' : 'session',
        map: newSession ? 'map' : 'next-map',
        activation: 'next-activation',
      );
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.right),
            RuntimeInputEvent.release(RuntimeInputControl.sprint),
          ]));
      events.clear();
      final fresh = await tester.startGesture(const Offset(150, 450),
          pointer: 3, kind: ui.PointerDeviceKind.touch);
      await fresh.moveBy(const Offset(-50, 0));
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.press(RuntimeInputControl.left),
            RuntimeInputEvent.press(RuntimeInputControl.sprint),
          ]));
      events.clear();
      await oldMovement.moveBy(const Offset(-100, 0));
      await oldMovement.up();
      await oldAction.up();
      expect(events, isEmpty);
      expect(taps, isEmpty);

      final action = await tester.startGesture(const Offset(650, 100),
          pointer: 4, kind: ui.PointerDeviceKind.touch);
      await action.up();
      expect(taps, [projection.value.primaryAction!.request]);
      await fresh.up();
      expect(
          events,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.left),
            RuntimeInputEvent.release(RuntimeInputControl.sprint),
          ]));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'OW007 rapid sources preserve scene and remount detaches old input',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final old = _SessionFixture();
    final fresh = _SessionFixture();
    addTearDown(old.close);
    addTearDown(fresh.close);
    await tester.pumpWidget(_material(old.view()));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    old.input.add(const RuntimeInputEvent.press(RuntimeInputControl.left));
    await tester.pump();
    final touch = await tester.startGesture(const Offset(100, 450),
        pointer: 1, kind: ui.PointerDeviceKind.touch);
    await touch.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(old.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.right),
      RuntimeInputEvent.release(RuntimeInputControl.right),
      RuntimeInputEvent.press(RuntimeInputControl.left),
      RuntimeInputEvent.release(RuntimeInputControl.left),
      RuntimeInputEvent.press(RuntimeInputControl.right),
    ]);
    expect(old.mounts, 1);
    expect(old.disposals, 0);
    expect(
        tester
            .widget<RuntimePlayerTouchControls>(
                find.byType(RuntimePlayerTouchControls))
            .showControls,
        isTrue);
    old.events.clear();
    old.input.add(const RuntimeInputEvent.release(RuntimeInputControl.left));
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(old.events, isEmpty);

    await tester.pumpWidget(const SizedBox());
    expect(old.events,
        const [RuntimeInputEvent.release(RuntimeInputControl.right)]);
    expect(old.disposals, 1);
    expect(old.input.hasListener, isFalse);
    expect(old.controller.changes.hasListener, isFalse);
    old.events.clear();
    await tester.pumpWidget(_material(fresh.view()));
    final newTouch = await tester.startGesture(const Offset(150, 450),
        pointer: 2, kind: ui.PointerDeviceKind.touch);
    await newTouch.moveBy(const Offset(-30, 0));
    expect(fresh.events,
        const [RuntimeInputEvent.press(RuntimeInputControl.left)]);
    fresh.events.clear();
    await touch.up();
    old.input.add(const RuntimeInputEvent.press(RuntimeInputControl.right));
    old.connected.value = {};
    old.authority.value = const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.dialogue);
    old.projection.value = _projection(session: 'expired');
    old.controller.publish(RuntimePlayerPhase.error);
    await tester.pump();
    expect(old.events, isEmpty);
    expect(fresh.events, isEmpty);
    expect(fresh.mounts, 1);
    expect(fresh.disposals, 0);
    await newTouch.up();
    expect(fresh.events,
        const [RuntimeInputEvent.release(RuntimeInputControl.left)]);
    fresh.events.clear();
    fresh.input.add(const RuntimeInputEvent.press(RuntimeInputControl.down));
    fresh.input.add(const RuntimeInputEvent.release(RuntimeInputControl.down));
    await tester.pump();
    expect(fresh.events, const [
      RuntimeInputEvent.press(RuntimeInputControl.down),
      RuntimeInputEvent.release(RuntimeInputControl.down),
    ]);
    await tester.pumpWidget(const SizedBox());
    expect(fresh.disposals, 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _material(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );

RuntimeOverworldInteractionSnapshot _projection({
  String session = 'session',
  String map = 'map',
  String activation = 'activation',
}) =>
    RuntimeOverworldInteractionSnapshot(
      sessionId: session,
      mapActivationId: activation,
      mapId: map,
      primaryAction: RuntimeOverworldInteractionAction(
        request: RuntimeOverworldInteractionRequest(
          sessionId: session,
          mapActivationId: activation,
          mapId: map,
          targetKind: RuntimeOverworldInteractionTargetKind.entity,
          targetId: 'npc',
          actionId: 'talk',
        ),
        verb: RuntimeOverworldInteractionVerb.talk,
        targetCell: const GridPos(x: 1, y: 1),
        targetBounds:
            const PixelRect(leftPx: 32, topPx: 32, widthPx: 32, heightPx: 32),
      ),
    );

final class _SessionFixture {
  final controller = _Coordinator();
  final input = StreamController<RuntimeInputEvent>.broadcast(sync: true);
  final connected = ValueNotifier<Set<String>>({'pad'});
  final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld));
  final projection = ValueNotifier(_projection());
  final viewport = GlobalKey();
  final events = <RuntimeInputEvent>[];
  int mounts = 0;
  int disposals = 0;

  Widget view() => PokeMapPlayerSessionView(
        controller: controller,
        titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'QA', description: 'Transitions tactiles'),
        gameSceneBuilder: (_) =>
            SizedBox.expand(key: viewport, child: _SceneProbe(fixture: this)),
        gameplayViewportKey: viewport,
        touchControlsAvailable: true,
        controllerInputEnabled: true,
        controllerInputEvents: input.stream,
        connectedControllerIds: connected,
        gameplayInputAuthority: authority,
        overworldInteractions: projection,
        gameplayInputRoute: (event) {
          events.add(event);
          return true;
        },
        hapticFeedback: () async {},
      );

  Future<void> close() async {
    await input.close();
    await controller.changes.close();
    connected.dispose();
    authority.dispose();
    projection.dispose();
  }
}

final class _SceneProbe extends StatefulWidget {
  const _SceneProbe({required this.fixture});
  final _SessionFixture fixture;

  @override
  State<_SceneProbe> createState() => _SceneProbeState();
}

final class _SceneProbeState extends State<_SceneProbe> {
  @override
  void initState() {
    super.initState();
    widget.fixture.mounts++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  void dispose() {
    widget.fixture.disposals++;
    super.dispose();
  }
}

final class _Coordinator implements RuntimePlayerViewController {
  final changes = StreamController<RuntimePlayerSnapshot>.broadcast(sync: true);
  var _phase = RuntimePlayerPhase.playing;
  var _revision = 1;

  @override
  RuntimePlayerSnapshot get snapshot => RuntimePlayerSnapshot(
      revision: _revision, phase: _phase, gameTitle: 'QA');

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => changes.stream;

  void publish(RuntimePlayerPhase phase) {
    _phase = phase;
    _revision++;
    changes.add(snapshot);
  }

  @override
  Future<RuntimePlayerCommandResult> dispatch(
          RuntimePlayerCommand command) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimePlayerCommandResult> requestBack(
          {required int snapshotRevision}) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
          RuntimeWorldServiceCommand command) async =>
      const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.accepted);
}
