/// Player-facing contexts understood by the single runtime input seam.
///
/// The context describes where an accepted command is routed. It does not
/// duplicate the runtime flow state: [PlayableMapGame] derives it from the
/// already authoritative dialogue, battle, transition and cinematic state.
enum RuntimeInputContext {
  overworld,
  dialogue,
  battle,
  cinematic,
  transition,
  blocked,
}

/// Locks owned outside Flame but still enforced by the runtime input seam.
///
/// A closed Flutter pause route is the only external owner in Phase 9. Keeping
/// the owner typed prevents an arbitrary boolean from being released by the
/// wrong overlay when more player surfaces are added later.
enum RuntimeExternalInputLock {
  pauseMenu,
  playerService,
  gameCompletion,
}

/// Immutable explanation of which player surface currently owns input.
final class RuntimeInputAuthoritySnapshot {
  const RuntimeInputAuthoritySnapshot({
    required this.context,
    this.externalLocks = const <RuntimeExternalInputLock>{},
  });

  final RuntimeInputContext context;
  final Set<RuntimeExternalInputLock> externalLocks;

  /// External Flutter surfaces consume input before Flame can route it.
  bool get acceptsRuntimeInput => externalLocks.isEmpty;

  /// Overworld movement is legal only when no overlay owns the command.
  bool get acceptsOverworldInput =>
      acceptsRuntimeInput && context == RuntimeInputContext.overworld;

  bool get isGameplayLocked => !acceptsOverworldInput;
}
