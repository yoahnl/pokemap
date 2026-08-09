import 'package:map_runtime/map_runtime.dart';

/// How the Hub enters an installed game.
///
/// [title] is the ordinary cold launch, even when a save exists. A host may
/// expose [quickResume] as a separate, explicit shortcut, but it must never be
/// inferred from the presence of a save.
enum HubPlayerLaunchIntent { title, quickResume }

extension HubPlayerLaunchIntentBehavior on HubPlayerLaunchIntent {
  bool get skipsStartup => this == HubPlayerLaunchIntent.quickResume;
}

typedef HubRuntimeCommandDispatcher = Future<RuntimePlayerCommandResult>
    Function(RuntimePlayerCommand command);

Future<RuntimePlayerCommandResult?> dispatchHubInitialLaunchIntent({
  required HubPlayerLaunchIntent intent,
  required RuntimePlayerSnapshot snapshot,
  required HubRuntimeCommandDispatcher dispatch,
}) {
  if (!intent.skipsStartup) {
    return Future<RuntimePlayerCommandResult?>.value();
  }
  return dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.continueGame,
      snapshotRevision: snapshot.revision,
    ),
  );
}
