import 'package:flutter_riverpod/flutter_riverpod.dart';

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
