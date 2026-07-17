import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
final class NarrativeSceneFocusRequest {
  const NarrativeSceneFocusRequest({
    required this.sceneId,
    required this.nonce,
  });

  final String sceneId;
  final int nonce;
}

final class NarrativeSceneFocusController
    extends StateNotifier<NarrativeSceneFocusRequest?> {
  NarrativeSceneFocusController() : super(null);

  int _nonce = 0;

  void focus(String sceneId) {
    final normalized = sceneId.trim();
    if (normalized.isEmpty) return;
    state = NarrativeSceneFocusRequest(
      sceneId: normalized,
      nonce: ++_nonce,
    );
  }
}

final narrativeSceneFocusProvider = StateNotifierProvider<
    NarrativeSceneFocusController, NarrativeSceneFocusRequest?>((ref) {
  return NarrativeSceneFocusController();
});
