import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../application/border_preview_controller.dart';
import '../application/border_preview_transaction.dart';
import '../application/pending_border_save_guard.dart';

final borderPreviewControllerProvider =
    StateNotifierProvider<BorderPreviewController, BorderPreviewState>((ref) {
  return BorderPreviewController();
});

final pendingBorderSaveGuardProvider = Provider<PendingBorderSaveGuard>((ref) {
  return PendingBorderSaveGuard();
});

/// Transient resize diagnostics owned by one concrete map value.
///
/// Successful warnings target the resized value; blocking diagnostics target
/// the unchanged source. Identity ownership prevents either from leaking after
/// undo, map switches, or any later mutation that replaces the active map.
final class BorderResizeFeedback {
  const BorderResizeFeedback({
    required this.mapIdentity,
    required this.diagnosticReport,
  });

  final MapData mapIdentity;
  final BorderDiagnosticsReport diagnosticReport;

  bool appliesTo(MapData? map) => map != null && identical(mapIdentity, map);
}

final borderResizeFeedbackProvider = StateProvider<BorderResizeFeedback?>(
  (ref) => null,
);
