import 'package:map_runtime/map_runtime.dart';

enum HubPlayerLaunchIntent { title, continueGame }

extension HubPlayerLaunchIntentBehavior on HubPlayerLaunchIntent {
  bool get skipsIntro => this == HubPlayerLaunchIntent.continueGame;
}

typedef HubRuntimeCommandDispatcher = Future<RuntimePlayerCommandResult>
    Function(RuntimePlayerCommand command);

Future<RuntimePlayerCommandResult?> dispatchHubInitialLaunchIntent({
  required HubPlayerLaunchIntent intent,
  required RuntimePlayerSnapshot snapshot,
  required HubRuntimeCommandDispatcher dispatch,
}) {
  if (intent == HubPlayerLaunchIntent.title) {
    return Future<RuntimePlayerCommandResult?>.value();
  }
  return dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.continueGame,
      snapshotRevision: snapshot.revision,
    ),
  );
}
