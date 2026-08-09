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
    extends Notifier<NarrativeSceneFocusRequest?> {
  @override
  NarrativeSceneFocusRequest? build() => null;

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

final narrativeSceneFocusProvider = NotifierProvider<
    NarrativeSceneFocusController,
    NarrativeSceneFocusRequest?>(NarrativeSceneFocusController.new);
