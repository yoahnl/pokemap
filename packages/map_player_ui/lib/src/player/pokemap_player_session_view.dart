import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_title_screen.dart';
import 'runtime_player_surface_router.dart';

/// Small presentation-facing subset of the runtime player coordinator.
///
/// Tests and standalone hosts can provide this contract without importing the
/// Hub or exposing package installation details to the player UI.
abstract interface class RuntimePlayerViewController {
  RuntimePlayerSnapshot get snapshot;

  Stream<RuntimePlayerSnapshot> get snapshots;

  Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command);
}

/// Adapter for the canonical in-process runtime coordinator.
final class RuntimePlayerCoordinatorViewController
    implements RuntimePlayerViewController {
  const RuntimePlayerCoordinatorViewController(this.coordinator);

  final RuntimePlayerCoordinator coordinator;

  @override
  RuntimePlayerSnapshot get snapshot => coordinator.snapshot;

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => coordinator.snapshots;

  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) =>
      coordinator.dispatch(command);
}

typedef RuntimePlayerActionPayloadBuilder = Object? Function(
  RuntimePlayerAction action,
);

/// Canonical Flutter host for one runtime-owned player session.
///
/// The widget only renders [RuntimePlayerSnapshot] values and sends versioned
/// commands back. It never derives a phase from Hub state.
class PokeMapPlayerSessionView extends StatelessWidget {
  const PokeMapPlayerSessionView({
    super.key,
    required this.controller,
    required this.titlePresentation,
    required this.gameSceneBuilder,
    this.payloadForAction,
    this.onShowDiagnostics,
  });

  final RuntimePlayerViewController controller;
  final RuntimePlayerTitlePresentation titlePresentation;
  final WidgetBuilder gameSceneBuilder;
  final RuntimePlayerActionPayloadBuilder? payloadForAction;
  final VoidCallback? onShowDiagnostics;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RuntimePlayerSnapshot>(
      stream: controller.snapshots,
      initialData: controller.snapshot,
      builder: (context, asyncSnapshot) {
        final snapshot = asyncSnapshot.data ?? controller.snapshot;
        return RuntimePlayerSurfaceRouter(
          snapshot: snapshot,
          titlePresentation: titlePresentation,
          gameSceneBuilder: gameSceneBuilder,
          onShowDiagnostics: onShowDiagnostics,
          onAction: (action) => controller.dispatch(
            RuntimePlayerCommand(
              action: action,
              snapshotRevision: snapshot.revision,
              payload: payloadForAction?.call(action),
            ),
          ),
        );
      },
    );
  }
}
