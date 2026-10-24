import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../scene_text_fact_transaction_test.dart' show TextFactFixture;

OpenSceneTextInteractionService _request({
  String id = 'rival',
  Duration? timeout,
}) => OpenSceneTextInteractionService(
  interactionId: id,
  interaction: SceneTextInteractionRequest(
    requestId: id,
    revision: 1,
    prompt: SceneInteractionPrompt(localizationKey: 'name'),
    constraints: SceneTextInputConstraints(minGraphemes: 1, maxGraphemes: 7),
    timeout: timeout,
  ),
);

RuntimeWorldServiceCommand _submit(
  RuntimeWorldServiceSnapshot snapshot,
  String value,
) {
  final request = snapshot.content! as SceneTextInteractionRequest;
  return RuntimeWorldServiceCommand(
    action: RuntimeWorldServiceAction.confirm,
    snapshotRevision: snapshot.revision,
    interactionResult: SceneInteractionResult.textSubmitted(
      requestId: request.requestId,
      revision: request.revision,
      value: value,
    ),
  );
}

void main() {
  test('native item feedback uses an acknowledged scene message without saving twice', () async {
    final fixture = TextFactFixture();
    addTearDown(fixture.controller.dispose);
    final request = SceneMessageInteractionRequest(
      requestId: 'item',
      revision: 0,
      prompt: SceneInteractionPrompt(
        localizationKey: 'item.received',
        fallbackText: 'Obtenu : Ressource !',
      ),
    );
    final pending = fixture.controller.openSceneTextInteraction(
      request: OpenSceneTextInteractionService(
        interactionId: 'item',
        interaction: request,
      ),
    );
    final snapshot = fixture.controller.worldServiceSnapshot!;
    expect(snapshot.content, request);
    final reply = SceneInteractionResult.acknowledged(
      requestId: request.requestId,
      revision: request.revision,
    );
    final result = await fixture.controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: snapshot.revision,
        interactionResult: reply,
      ),
    );
    expect(result.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(await pending, reply);
    expect(fixture.commits, 0);
    expect(fixture.locks, [true, false]);
  });
  test('Scene text rejects invalid graphemes and accepts one typed reply without saving', () async {
    final fixture = TextFactFixture();
    addTearDown(fixture.controller.dispose);
    final pending = fixture.controller.openSceneTextInteraction(
      request: _request(),
    );
    final snapshot = fixture.controller.worldServiceSnapshot!;
    for (final value in ['', '12345678']) {
      expect(
        (await fixture.controller.dispatchWorldService(
          _submit(snapshot, value),
        )).status,
        RuntimeWorldServiceCommandStatus.unavailable,
      );
      expect(fixture.controller.worldServiceSnapshot, snapshot);
    }
    final response = _submit(snapshot, 'e\u0301👨‍👩‍👧‍👦');
    final first = fixture.controller.dispatchWorldService(response);
    final duplicate = fixture.controller.dispatchWorldService(response);
    expect((await first).status, RuntimeWorldServiceCommandStatus.accepted);
    expect((await duplicate).status, RuntimeWorldServiceCommandStatus.stale);
    expect(await pending, response.interactionResult);
    expect(fixture.commits, 0);
    expect(fixture.initial.scriptVariables.values, isEmpty);
    expect(fixture.locks, [true, false]);
  });

  test('a closed Scene request cannot answer a replacement modal', () async {
    final fixture = TextFactFixture();
    addTearDown(fixture.controller.dispose);
    final first = fixture.controller.openSceneTextInteraction(
      request: _request(),
    );
    final old = fixture.controller.worldServiceSnapshot!;
    await fixture.controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.cancel,
        snapshotRevision: old.revision,
      ),
    );
    expect(await first, isA<SceneCancelledInteractionResult>());
    final second = fixture.controller.openSceneTextInteraction(
      request: _request(id: 'replacement'),
    );
    expect(
      (await fixture.controller.dispatchWorldService(_submit(old, 'Old')))
          .status,
      RuntimeWorldServiceCommandStatus.stale,
    );
    await fixture.controller.dispose();
    expect(
      await second,
      isA<SceneCancelledInteractionResult>().having(
        (value) => value.reason,
        'reason',
        SceneInteractionCancellationReason.disposed,
      ),
    );
    expect(fixture.commits, 0);
    expect(fixture.locks, [true, false, true, false]);
  });

  testWidgets('Scene text timeout releases the modal without writing', (
    tester,
  ) async {
    final fixture = TextFactFixture();
    addTearDown(fixture.controller.dispose);
    final pending = fixture.controller.openSceneTextInteraction(
      request: _request(timeout: const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      await pending,
      isA<SceneCancelledInteractionResult>().having(
        (value) => value.reason,
        'reason',
        SceneInteractionCancellationReason.timeout,
      ),
    );
    expect(fixture.controller.worldServiceSnapshot, isNull);
    expect(fixture.commits, 0);
    expect(fixture.locks, [true, false]);
  });
}
