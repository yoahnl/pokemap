import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('OW007 second finger opens Menu once after releasing direction and sprint', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = Completer<RuntimePlayerCommandResult>();
    final menuHaptic = Completer<void>();
    final events = <RuntimeInputEvent>[];
    final controller = _Controller(onDispatch: (command) {
      expect(events.where((event) => event.isRelease), unorderedEquals(const [
        RuntimeInputEvent.release(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.sprint),
      ]));
      return pending.future;
    });
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld, sprintAllowed: true,
    ));
    addTearDown(controller.close);
    addTearDown(authority.dispose);
    await tester.pumpWidget(_app(controller, events, authority: authority,
      touch: true, viewportKey: GlobalKey(),
      haptic: () async {
        if (controller.commands.isNotEmpty) await menuHaptic.future;
      }));
    final first = await tester.startGesture(const Offset(100, 600), pointer: 1,
      kind: ui.PointerDeviceKind.touch);
    await first.moveBy(const Offset(48, 0));
    expect(events, unorderedEquals(const [
      RuntimeInputEvent.press(RuntimeInputControl.right),
      RuntimeInputEvent.press(RuntimeInputControl.sprint),
    ]));
    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld, sprintAllowed: true, sprintAccepted: true,
    );
    await tester.pump();
    final menuPosition = tester.getCenter(find.byType(PlayerOverworldMenuButton));
    for (final pointer in [2, 3]) {
      final menu = await tester.startGesture(menuPosition, pointer: pointer,
        kind: ui.PointerDeviceKind.touch);
      await menu.up();
      await tester.pump();
    }
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    final eventCount = events.length;
    await first.moveBy(const Offset(-100, 0));
    await first.up();
    expect(events, hasLength(eventCount));
    controller.publish(RuntimePlayerPhase.paused);
    pending.complete(const RuntimePlayerCommandResult(status: RuntimePlayerCommandStatus.accepted));
    await tester.pump();
    controller.publish(RuntimePlayerPhase.playing);
    await tester.pump();
    expect(find.byKey(const ValueKey('runtime-player-touch-joystick')), findsNothing);
    expect(find.byType(RuntimePlayerTouchControls), findsNothing);
    menuHaptic.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<RuntimePlayerTouchControls>(find.byType(RuntimePlayerTouchControls)).showControls, isTrue);
    final fresh = await tester.startGesture(const Offset(100, 600), pointer: 4,
      kind: ui.PointerDeviceKind.touch);
    await fresh.moveBy(const Offset(20, 0));
    expect(events.last, const RuntimeInputEvent.press(RuntimeInputControl.right));
    await fresh.up();
    await tester.pumpWidget(const SizedBox());
  });

  for (final replaceAuthority in [true, false]) {
    testWidgets('OW007 replacing a blocked projection requires fresh input $replaceAuthority', (tester) async {
      final controller = _Controller();
      final events = <RuntimeInputEvent>[];
      final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.dialogue));
      final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(const DialoguePresentationSnapshot(
        revision: 1, mode: DialoguePresentationMode.line, nodeTitle: 'QA',
        speaker: 'QA', text: 'Dialogue', fullText: 'Dialogue',
        isCurrentLineFullyRevealed: true, isLastContent: true, choices: [],
      ));
      addTearDown(controller.close);
      addTearDown(authority.dispose);
      addTearDown(dialogue.dispose);
      await tester.pumpWidget(_app(controller, events));
      await tester.pumpWidget(_app(controller, events,
        authority: replaceAuthority ? authority : null,
        dialogue: replaceAuthority ? null : dialogue,
      ));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
      dialogue.value = null;
      events.clear();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      expect(events, isEmpty);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('OW007 closing a dialogue projection without authority rejects held repeats', (tester) async {
    final controller = _Controller();
    final events = <RuntimeInputEvent>[];
    final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(null);
    addTearDown(controller.close);
    addTearDown(dialogue.dispose);
    await tester.pumpWidget(_app(controller, events, dialogue: dialogue));
    dialogue.value = const DialoguePresentationSnapshot(
      revision: 1, mode: DialoguePresentationMode.line, nodeTitle: 'QA',
      speaker: 'QA', text: 'Dialogue', fullText: 'Dialogue',
      isCurrentLineFullyRevealed: true, isLastContent: true,
      choices: [],
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    dialogue.value = null;
    events.clear();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    expect(events, isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('OW007 external lock in the same context rejects held input on resume', (tester) async {
    final controller = _Controller();
    final events = <RuntimeInputEvent>[];
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
    addTearDown(controller.close);
    addTearDown(authority.dispose);
    await tester.pumpWidget(_app(controller, events, authority: authority));
    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
      externalLocks: {RuntimeExternalInputLock.lifecycle},
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
    events.clear();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    expect(events, isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('OW007 direction first pressed in dialogue requires a fresh press', (tester) async {
    final controller = _Controller();
    final events = <RuntimeInputEvent>[];
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
    addTearDown(controller.close);
    addTearDown(authority.dispose);
    await tester.pumpWidget(_app(controller, events, authority: authority));
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.dialogue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
    events.clear();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    expect(events, isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('OW007 view focus loss neutralizes held actions and rejects repeats', (tester) async {
    final controller = _Controller();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.close);
    await tester.pumpWidget(_app(controller, events));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
    events.clear();
    tester.binding.handleViewFocusChanged(ui.ViewFocusEvent(
      viewId: tester.view.viewId, state: ui.ViewFocusState.unfocused,
      direction: ui.ViewFocusDirection.undefined,
    ));
    expect(events, unorderedEquals(const [
      RuntimeInputEvent.release(RuntimeInputControl.right),
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.primary),
    ]));
    tester.binding.handleViewFocusChanged(ui.ViewFocusEvent(
      viewId: tester.view.viewId, state: ui.ViewFocusState.focused,
      direction: ui.ViewFocusDirection.undefined,
    ));
    events.clear();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    expect(events, isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
    await tester.pumpWidget(const SizedBox());
  });

  for (final phase in [
    RuntimePlayerPhase.paused,
    RuntimePlayerPhase.loadingSession,
    RuntimePlayerPhase.lifecyclePaused,
    RuntimePlayerPhase.error,
    RuntimePlayerPhase.disposingSession,
  ]) {
    testWidgets('OW007 neutralizes hardware input before $phase', (tester) async {
      final controller = _Controller();
      final events = <RuntimeInputEvent>[];
      addTearDown(controller.close);
      await tester.pumpWidget(_app(controller, events));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(events, const [
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.press(RuntimeInputControl.sprint),
      ]);
      events.clear();
      controller.publish(phase);
      await tester.pump();
      expect(events, unorderedEquals(const [
        RuntimeInputEvent.release(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.sprint),
      ]));

      events.clear();
      controller.publish(RuntimePlayerPhase.playing);
      await tester.pump();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      expect(events, isEmpty);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('OW007 lifecycle interruption neutralizes hardware immediately', (tester) async {
    final controller = _Controller();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.close);
    await tester.pumpWidget(_app(controller, events));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    events.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(events, unorderedEquals(const [
      RuntimeInputEvent.release(RuntimeInputControl.right),
      RuntimeInputEvent.release(RuntimeInputControl.sprint),
    ]));
    events.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    expect(events, isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpWidget(const SizedBox());
  });
}

Widget _app(_Controller controller, List<RuntimeInputEvent> events, {
  ValueNotifier<RuntimeInputAuthoritySnapshot>? authority,
  ValueNotifier<DialoguePresentationSnapshot?>? dialogue,
  bool touch = false,
  GlobalKey? viewportKey,
  Future<void> Function()? haptic,
}) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapPlayerTheme.dark(),
  home: PokeMapPlayerSessionView(
    controller: controller,
    titlePresentation: const RuntimePlayerTitlePresentation(
      author: 'QA', description: 'Transitions',
    ),
    gameSceneBuilder: (_) => SizedBox.expand(key: viewportKey),
    gameplayViewportKey: viewportKey,
    touchControlsAvailable: touch,
    controllerInputEnabled: false,
    gameplayInputAuthority: authority,
    hapticFeedback: haptic,
    dialoguePresentation: dialogue,
    gameplayInputRoute: (event) { events.add(event); return true; },
  ),
);

final class _Controller implements RuntimePlayerViewController {
  _Controller({this.onDispatch});

  final Future<RuntimePlayerCommandResult> Function(RuntimePlayerCommand)? onDispatch;
  final commands = <RuntimePlayerCommand>[];
  final _stream = StreamController<RuntimePlayerSnapshot>.broadcast();
  var _revision = 0;
  var _phase = RuntimePlayerPhase.playing;

  @override
  RuntimePlayerSnapshot get snapshot => RuntimePlayerSnapshot(
    revision: _revision, phase: _phase, gameTitle: 'Transitions',
    pauseSection: _phase == RuntimePlayerPhase.paused ? RuntimePlayerPauseSection.root : null,
    actions: const [RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu)],
  );

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _stream.stream;

  void publish(RuntimePlayerPhase phase) {
    _phase = phase;
    _revision++;
    _stream.add(snapshot);
  }

  @override
  Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command) async {
    commands.add(command);
    return onDispatch?.call(command) ??
        const RuntimePlayerCommandResult(status: RuntimePlayerCommandStatus.accepted);
  }

  @override
  Future<RuntimePlayerCommandResult> requestBack({required int snapshotRevision}) async =>
      const RuntimePlayerCommandResult(status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(RuntimeWorldServiceCommand command) async =>
      const RuntimeWorldServiceCommandResult(status: RuntimeWorldServiceCommandStatus.accepted);

  Future<void> close() => _stream.close();
}
