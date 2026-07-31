import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
final class WorldMapTargetEditorNavigationRequest {
  const WorldMapTargetEditorNavigationRequest({
    required this.revision,
    required this.stableKey,
  });

  final int revision;
  final String stableKey;
}

@immutable
final class WorldMapTargetEditorNavigationState {
  const WorldMapTargetEditorNavigationState({
    this.latestRevision = 0,
    this.pending,
  });

  final int latestRevision;
  final WorldMapTargetEditorNavigationRequest? pending;
}

final worldMapTargetEditorNavigationProvider = NotifierProvider<
    WorldMapTargetEditorNavigationController,
    WorldMapTargetEditorNavigationState>(
  WorldMapTargetEditorNavigationController.new,
);

/// Carries one compatibility selection safely across the Map → Events switch.
final class WorldMapTargetEditorNavigationController
    extends Notifier<WorldMapTargetEditorNavigationState> {
  @override
  WorldMapTargetEditorNavigationState build() =>
      const WorldMapTargetEditorNavigationState();

  WorldMapTargetEditorNavigationRequest enqueue(String stableKey) {
    final normalizedKey = stableKey.trim();
    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(stableKey, 'stableKey', 'must not be empty');
    }
    final request = WorldMapTargetEditorNavigationRequest(
      revision: state.latestRevision + 1,
      stableKey: normalizedKey,
    );
    state = WorldMapTargetEditorNavigationState(
      latestRevision: request.revision,
      pending: request,
    );
    return request;
  }

  bool acknowledge(int revision) {
    final pending = state.pending;
    if (pending == null || pending.revision != revision) return false;
    state = WorldMapTargetEditorNavigationState(
      latestRevision: state.latestRevision,
    );
    return true;
  }

  bool acknowledgeIfCurrent({
    required int revision,
    required String stableKey,
  }) {
    final pending = state.pending;
    if (pending == null ||
        pending.revision != revision ||
        pending.stableKey != stableKey) {
      return false;
    }
    return acknowledge(revision);
  }
}
