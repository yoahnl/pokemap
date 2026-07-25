import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_title_screen.dart';
import 'player_heal_confirmation.dart';
import 'player_shop_overlay.dart';
import 'runtime_player_surface_router.dart';

/// Small presentation-facing subset of the runtime player coordinator.
///
/// Tests and standalone hosts can provide this contract without importing the
/// Hub or exposing package installation details to the player UI.
abstract interface class RuntimePlayerViewController {
  RuntimePlayerSnapshot get snapshot;

  Stream<RuntimePlayerSnapshot> get snapshots;

  Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command);

  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  );
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

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) =>
      coordinator.dispatchWorldService(command);
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
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            RuntimePlayerSurfaceRouter(
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
            ),
            if (snapshot.worldService case final service?)
              _RuntimeWorldServiceOverlay(
                snapshot: service,
                onCommand: controller.dispatchWorldService,
              ),
          ],
        );
      },
    );
  }
}

class _RuntimeWorldServiceOverlay extends StatelessWidget {
  const _RuntimeWorldServiceOverlay({
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final Future<RuntimeWorldServiceCommandResult> Function(
    RuntimeWorldServiceCommand command,
  ) onCommand;

  @override
  Widget build(BuildContext context) {
    return switch (snapshot.request.kind) {
      RuntimeWorldServiceKind.shop => PlayerShopOverlay(
          snapshot: snapshot,
          onCommand: (command) => onCommand(command),
        ),
      RuntimeWorldServiceKind.heal => PlayerHealConfirmation(
          snapshot: snapshot,
          onCommand: (command) => onCommand(command),
        ),
      RuntimeWorldServiceKind.pc => const SizedBox.shrink(),
    };
  }
}
