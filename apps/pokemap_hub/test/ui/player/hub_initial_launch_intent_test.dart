import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  test(
      'continue intent dispatches the runtime continue action at this revision',
      () async {
    RuntimePlayerCommand? command;
    final snapshot = RuntimePlayerSnapshot(
      revision: 7,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Aube',
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
      ],
    );

    final result = await dispatchHubInitialLaunchIntent(
      intent: HubPlayerLaunchIntent.continueGame,
      snapshot: snapshot,
      dispatch: (value) async {
        command = value;
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      },
    );

    expect(result?.status, RuntimePlayerCommandStatus.accepted);
    expect(command?.action, RuntimePlayerAction.continueGame);
    expect(command?.snapshotRevision, 7);
    expect(command?.payload, isNull);
    expect(HubPlayerLaunchIntent.continueGame.skipsIntro, isTrue);
  });

  test('title intent preserves the existing guided player flow', () async {
    var dispatches = 0;
    final result = await dispatchHubInitialLaunchIntent(
      intent: HubPlayerLaunchIntent.title,
      snapshot: RuntimePlayerSnapshot(
        revision: 2,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Aube',
      ),
      dispatch: (_) async {
        dispatches++;
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      },
    );

    expect(result, isNull);
    expect(dispatches, 0);
    expect(HubPlayerLaunchIntent.title.skipsIntro, isFalse);
  });
}
