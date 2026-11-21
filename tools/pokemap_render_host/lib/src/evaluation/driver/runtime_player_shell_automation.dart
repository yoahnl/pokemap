import 'package:map_runtime/map_runtime.dart';

import 'evaluation_driver.dart';

/// Typed PokeMap Eval adapter over the production runtime-player state machine.
final class RuntimePlayerCoordinatorEvaluationShell
    implements EvaluationPlayerShellAutomation {
  RuntimePlayerCoordinatorEvaluationShell(this.coordinator);

  final RuntimePlayerCoordinator coordinator;

  @override
  Future<void> pause() => _dispatch(RuntimePlayerAction.openMenu);

  @override
  Future<void> resume() => _dispatch(RuntimePlayerAction.resume);

  @override
  Future<void> openOptions() => _dispatch(RuntimePlayerAction.openOptions);

  @override
  Future<void> openPokedex() => _dispatch(RuntimePlayerAction.openPokedex);

  @override
  Future<void> saveSlot() => _dispatch(RuntimePlayerAction.save);

  @override
  Future<void> loadSlot(String profileId, String slotId) {
    return _dispatch(
      RuntimePlayerAction.load,
      payload: RuntimePlayerLoadSlot(profileId: profileId, slotId: slotId),
    );
  }

  Future<void> _dispatch(RuntimePlayerAction action, {Object? payload}) async {
    final result = await coordinator.dispatch(
      RuntimePlayerCommand(
        action: action,
        snapshotRevision: coordinator.snapshot.revision,
        payload: payload,
      ),
    );
    if (result.status != RuntimePlayerCommandStatus.accepted) {
      throw StateError(
        'Player shell rejected ${action.name}: '
        '${result.safeMessage ?? result.status.name}.',
      );
    }
  }
}
