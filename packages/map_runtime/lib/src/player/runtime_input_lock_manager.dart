import 'dart:async';
import 'dart:collection';

/// Runtime surfaces ordered from the playable world to terminal modal states.
///
/// The numeric order is deliberately private. Callers declare intent through
/// a surface, while the manager remains the only authority that compares
/// priorities.
enum RuntimeInputSurface {
  world,
  pause,
  playerService,
  dialogue,
  cinematic,
  battle,
  progression,
  transition,
  blocked,
  background,
  completion,
}

/// Stable owners for every runtime input lock.
///
/// A token can only be released by the same owner that acquired it. This keeps
/// one overlay from accidentally unlocking another overlay's input boundary.
enum RuntimeInputLockOwner {
  pauseMenu,
  lifecycle,
  playerService,
  dialogue,
  cinematic,
  battle,
  postBattleProgression,
  transition,
  blockingInteraction,
  mapActivation,
  narrativeDispatch,
  checkpoint,
  scriptedMovement,
  gameCompletion,
}

/// Opaque capability returned when an input surface acquires authority.
final class RuntimeInputLockToken {
  const RuntimeInputLockToken._({
    required this.id,
    required this.owner,
    required this.surface,
    required Object managerIdentity,
  }) : _managerIdentity = managerIdentity;

  final int id;
  final RuntimeInputLockOwner owner;
  final RuntimeInputSurface surface;
  final Object _managerIdentity;
}

/// Immutable view of the active runtime surface stack.
final class RuntimeInputLockSnapshot {
  RuntimeInputLockSnapshot._(List<RuntimeInputLockToken> activeTokens)
      : activeTokens = UnmodifiableListView<RuntimeInputLockToken>(
          activeTokens,
        );

  final List<RuntimeInputLockToken> activeTokens;

  RuntimeInputSurface get activeSurface => activeTokens.isEmpty
      ? RuntimeInputSurface.world
      : activeTokens.last.surface;

  RuntimeInputLockToken? get activeToken =>
      activeTokens.isEmpty ? null : activeTokens.last;

  bool get acceptsOverworldInput => activeSurface == RuntimeInputSurface.world;

  bool isOwnedBy(RuntimeInputLockOwner owner) =>
      activeTokens.any((token) => token.owner == owner);
}

/// Single token-based authority for modal runtime input.
final class RuntimeInputLockManager {
  final Object _identity = Object();
  final Map<int, RuntimeInputLockToken> _active =
      <int, RuntimeInputLockToken>{};
  int _nextTokenId = 0;

  RuntimeInputLockSnapshot get snapshot {
    final tokens = _active.values.toList(growable: false)
      ..sort((left, right) {
        final priority = _priority(left.surface).compareTo(
          _priority(right.surface),
        );
        return priority != 0 ? priority : left.id.compareTo(right.id);
      });
    return RuntimeInputLockSnapshot._(tokens);
  }

  RuntimeInputLockToken acquire({
    required RuntimeInputLockOwner owner,
    required RuntimeInputSurface surface,
  }) {
    final token = RuntimeInputLockToken._(
      id: _nextTokenId++,
      owner: owner,
      surface: surface,
      managerIdentity: _identity,
    );
    _active[token.id] = token;
    return token;
  }

  /// Releases [token] only when both the manager and owner match.
  ///
  /// Returning `false` for an already released token makes cleanup safe inside
  /// nested `finally` blocks.
  bool release({
    required RuntimeInputLockOwner owner,
    required RuntimeInputLockToken token,
  }) {
    if (!identical(token._managerIdentity, _identity) ||
        token.owner != owner ||
        !identical(_active[token.id], token)) {
      return false;
    }
    _active.remove(token.id);
    return true;
  }

  Future<T> runLocked<T>({
    required RuntimeInputLockOwner owner,
    required RuntimeInputSurface surface,
    required FutureOr<T> Function() action,
  }) async {
    final token = acquire(owner: owner, surface: surface);
    try {
      return await action();
    } finally {
      release(owner: owner, token: token);
    }
  }

  static int _priority(RuntimeInputSurface surface) => switch (surface) {
        RuntimeInputSurface.world => 0,
        RuntimeInputSurface.pause => 100,
        RuntimeInputSurface.playerService => 200,
        RuntimeInputSurface.dialogue => 300,
        RuntimeInputSurface.cinematic => 350,
        RuntimeInputSurface.battle => 400,
        RuntimeInputSurface.progression => 500,
        RuntimeInputSurface.transition => 600,
        RuntimeInputSurface.blocked => 650,
        RuntimeInputSurface.background => 700,
        RuntimeInputSurface.completion => 800,
      };
}
