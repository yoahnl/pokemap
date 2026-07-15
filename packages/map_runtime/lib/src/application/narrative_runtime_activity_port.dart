import 'package:map_gameplay/map_gameplay.dart';

import 'narrative_runtime_activity_gate.dart';

final class NarrativeRuntimeActivityPort implements NarrativeEventActivityPort {
  const NarrativeRuntimeActivityPort(this.gate);

  final NarrativeRuntimeActivityGate gate;

  @override
  Future<T> runWithActivity<T>(
    NarrativeEventActivity activity,
    Future<T> Function() action,
  ) {
    if (activity == NarrativeEventActivity.idle) return action();
    return gate.runWithActivity(_runtimeActivity(activity), action);
  }

  NarrativeRuntimeActivity _runtimeActivity(NarrativeEventActivity activity) {
    return switch (activity) {
      NarrativeEventActivity.idle => throw StateError('idle is handled first'),
      NarrativeEventActivity.dispatching =>
        NarrativeRuntimeActivity.dispatching,
      NarrativeEventActivity.sceneActive =>
        NarrativeRuntimeActivity.sceneActive,
      NarrativeEventActivity.sceneSuspended =>
        NarrativeRuntimeActivity.sceneSuspended,
      NarrativeEventActivity.outboxProcessing =>
        NarrativeRuntimeActivity.outboxProcessing,
    };
  }
}
