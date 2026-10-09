import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('a text response cannot confirm a different world service', () async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    final text = fixture.controller.openTextInput(request: _request());
    final old = fixture.controller.worldServiceSnapshot!;
    final interaction = old.content! as SceneTextInteractionRequest;
    await fixture.controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.cancel,
        snapshotRevision: old.revision,
      ),
    );
    await text;
    final heal = fixture.controller.openHealCenter();
    await Future<void>.delayed(Duration.zero);
    final result = await fixture.controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: old.revision,
        interactionResult: SceneInteractionResult.textSubmitted(
          requestId: interaction.requestId,
          revision: interaction.revision,
          value: 'Gold',
        ),
      ),
    );
    expect(result.status, RuntimeWorldServiceCommandStatus.stale);
    expect(fixture.commits, isEmpty);
    await fixture.controller.dispose();
    expect((await heal).status, PlayerServiceRuntimeStatus.cancelled);
  });

  testWidgets('an unanswered timed request releases input without a write',
      (tester) async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    final open = fixture.controller.openTextInput(
      request: _request(timeout: const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(fixture.controller.worldServiceSnapshot, isNull);
    expect((await open).status, PlayerServiceRuntimeStatus.cancelled);
    expect(fixture.commits, isEmpty);
    expect(fixture.locks, [true, false]);
  });

  test('duplicate cancellation and disposal never write a text variable',
      () async {
    final fixture = _Fixture();
    final open = fixture.controller.openTextInput(request: _request());
    final snapshot = fixture.controller.worldServiceSnapshot!;
    final command = RuntimeWorldServiceCommand(
      action: RuntimeWorldServiceAction.cancel,
      snapshotRevision: snapshot.revision,
    );
    final first = fixture.controller.dispatchWorldService(command);
    final duplicate = fixture.controller.dispatchWorldService(command);
    expect((await first).status, RuntimeWorldServiceCommandStatus.cancelled);
    expect((await duplicate).status, RuntimeWorldServiceCommandStatus.stale);
    expect((await open).status, PlayerServiceRuntimeStatus.cancelled);
    final pending = fixture.controller.openTextInput(request: _request());
    await fixture.controller.dispose();
    expect((await pending).status, PlayerServiceRuntimeStatus.cancelled);
    expect(fixture.commits, isEmpty);
    expect(fixture.locks, [true, false, true, false]);
  });

  test('a numeric variable is rejected before acquiring the input lock',
      () async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    fixture.state = fixture.state.copyWith(
      scriptVariables: const ScriptVariables(
        values: {'rival_name': ScriptVariableValue.int(12)},
      ),
    );
    final result = await fixture.controller.openTextInput(request: _request());
    expect(result.status, PlayerServiceRuntimeStatus.unavailable);
    expect(fixture.locks, isEmpty);
    expect(fixture.commits, isEmpty);
    expect(fixture.state.scriptVariables.values['rival_name'],
        const ScriptVariableValue.int(12));
  });

  test('failed persistence keeps the entered text and permits a fresh retry',
      () async {
    var state = const GameState(saveId: 'retry-text');
    var attempts = 0;
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        attempts++;
        if (attempts == 1) throw StateError('storage unavailable');
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    );
    addTearDown(controller.dispose);
    final open = controller.openTextInput(request: _request());
    Future<RuntimeWorldServiceCommandResult> submit() {
      final snapshot = controller.worldServiceSnapshot!;
      final request = snapshot.content! as SceneTextInteractionRequest;
      return controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: 'Gold',
          ),
        ),
      );
    }

    expect((await submit()).status, RuntimeWorldServiceCommandStatus.failed);
    expect(state.scriptVariables.values, isEmpty);
    final failure = controller.worldServiceSnapshot!;
    expect(failure.stage, RuntimeWorldServiceStage.failed);
    expect((failure.content! as SceneTextInteractionRequest).initialValue, 'Gold');
    expect(failure.safeMessage, isNotEmpty);
    expect((await submit()).status, RuntimeWorldServiceCommandStatus.accepted);
    expect((await open).status, PlayerServiceRuntimeStatus.completed);
    expect(attempts, 2);
    expect(state.scriptVariables.values['rival_name'],
        const ScriptVariableValue.string('Gold'));
  });

  test('a response from a closed request cannot write into its replacement',
      () async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    final first = fixture.controller.openTextInput(request: _request());
    final old = fixture.controller.worldServiceSnapshot!;
    final oldInteraction = old.content! as SceneTextInteractionRequest;
    await fixture.controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.cancel,
        snapshotRevision: old.revision,
      ),
    );
    await first;
    final second = fixture.controller.openTextInput(request: _request());
    final result = await fixture.controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: old.revision,
        interactionResult: SceneInteractionResult.textSubmitted(
          requestId: oldInteraction.requestId,
          revision: oldInteraction.revision,
          value: 'Old',
        ),
      ),
    );
    expect(result.status, RuntimeWorldServiceCommandStatus.stale);
    expect(fixture.commits, isEmpty);
    await fixture.controller.dispose();
    expect((await second).status, PlayerServiceRuntimeStatus.cancelled);
  });

  test('text commits a persistent string once and releases the modal lock',
      () async {
    var state = const GameState(saveId: 'rival-name');
    final commits = <GameState>[];
    final locks = <bool>[];
    final saving = Completer<void>();
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        await saving.future;
        state = next;
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    );
    addTearDown(controller.dispose);

    final open = controller.openTextInput(request: _request());
    final snapshot = controller.worldServiceSnapshot!;
    final interaction = snapshot.content! as SceneTextInteractionRequest;
    expect(interaction.initialValue, 'Silver');
    final command = RuntimeWorldServiceCommand(
      action: RuntimeWorldServiceAction.confirm,
      snapshotRevision: snapshot.revision,
      interactionResult: SceneInteractionResult.textSubmitted(
        requestId: interaction.requestId,
        revision: interaction.revision,
        value: 'e\u0301👨‍👩‍👧‍👦',
      ),
    );

    final submit = controller.dispatchWorldService(command);
    expect(controller.worldServiceSnapshot!.stage,
        RuntimeWorldServiceStage.applying);
    final duplicate = await controller.dispatchWorldService(command);
    expect(duplicate.status, RuntimeWorldServiceCommandStatus.stale);
    expect(commits, hasLength(1));
    saving.complete();
    expect((await submit).status, RuntimeWorldServiceCommandStatus.accepted);
    final result = await open;
    expect(result.status, PlayerServiceRuntimeStatus.completed);
    final restored = GameState.fromJson(
      jsonDecode(jsonEncode(result.gameState!.toJson())) as Map<String, dynamic>,
    );
    expect(restored.scriptVariables.values['rival_name'],
        const ScriptVariableValue.string('e\u0301👨‍👩‍👧‍👦'));
    expect(controller.worldServiceSnapshot, isNull);
    expect(locks, [true, false]);
  });

  test('invalid and stale text stay open, cancellation writes nothing', () async {
    const state = GameState(saveId: 'rival-name');
    final commits = <GameState>[];
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async => commits.add(next),
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    );
    addTearDown(controller.dispose);
    final open = controller.openTextInput(request: _request());
    final snapshot = controller.worldServiceSnapshot!;
    final interaction = snapshot.content! as SceneTextInteractionRequest;
    for (final value in ['', 'Longer than two']) {
      final result = await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: SceneInteractionResult.textSubmitted(
            requestId: interaction.requestId,
            revision: interaction.revision,
            value: value,
          ),
        ),
      );
      expect(result.status, RuntimeWorldServiceCommandStatus.unavailable);
    }
    final stale = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: snapshot.revision,
        interactionResult: SceneInteractionResult.textSubmitted(
          requestId: 'old-request',
          revision: interaction.revision,
          value: 'AB',
        ),
      ),
    );
    expect(stale.status, RuntimeWorldServiceCommandStatus.stale);
    expect(controller.worldServiceSnapshot!.stage,
        RuntimeWorldServiceStage.active);
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.cancel,
        snapshotRevision: snapshot.revision,
      ),
    );
    expect((await open).status, PlayerServiceRuntimeStatus.cancelled);
    expect(commits, isEmpty);
    expect(locks, [true, false]);
  });
}

OpenTextInputService _request({Duration? timeout}) => OpenTextInputService(
      interactionId: 'police.rival-name',
      variableId: 'rival_name',
      interaction: SceneTextInteractionRequest(
        requestId: 'rival-name',
        revision: 0,
        prompt: SceneInteractionPrompt(
          localizationKey: 'story.rivalName',
          fallbackText: 'Comment s’appelle ce garçon ?',
        ),
        initialValue: 'Silver',
        timeout: timeout,
        constraints: SceneTextInputConstraints(minGraphemes: 1, maxGraphemes: 12),
      ),
    );

class _Fixture {
  _Fixture() {
    controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    );
  }

  var state = const GameState(saveId: 'text-service');
  final commits = <GameState>[];
  final locks = <bool>[];
  late final PlayerServiceRuntimeController controller;
}
