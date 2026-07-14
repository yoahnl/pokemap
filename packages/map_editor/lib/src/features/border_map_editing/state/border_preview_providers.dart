import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/border_preview_controller.dart';
import '../application/border_preview_transaction.dart';

final borderPreviewControllerProvider =
    StateNotifierProvider<BorderPreviewController, BorderPreviewState>((ref) {
  return BorderPreviewController();
});
