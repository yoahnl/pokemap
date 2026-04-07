/// Calcule la raison bloquante (si présente) empêchant de considérer qu'une
/// cutscene est réellement terminée côté runtime.
///
/// La priorité est stable pour garantir des logs déterministes.
String? scenarioRuntimeCompletionBlockingReason({
  required bool isOverworldFlow,
  required bool isDialogueOpen,
  required bool isCutsceneRunnerActive,
  required bool hasPendingFollowCharacter,
  required bool hasPendingMoveContinuations,
  required bool hasPendingNpcWarpEntries,
  required bool hasPendingTransitionMapRequest,
  required bool hasPendingRuntimeWarp,
  required bool hasPendingRuntimeConnection,
  required bool isPlayerStepInProgress,
  String? flowPhaseName,
}) {
  if (!isOverworldFlow) {
    final suffix = (flowPhaseName ?? '').trim();
    return suffix.isEmpty ? 'flow_phase_not_overworld' : 'flow_phase_$suffix';
  }
  if (isDialogueOpen) {
    return 'dialogue_open';
  }
  if (isCutsceneRunnerActive) {
    return 'cutscene_runner_active';
  }
  if (hasPendingFollowCharacter) {
    return 'follow_character_active';
  }
  if (hasPendingMoveContinuations) {
    return 'move_continuations_pending';
  }
  if (hasPendingNpcWarpEntries) {
    return 'npc_warp_entries_pending';
  }
  if (hasPendingTransitionMapRequest) {
    return 'transition_map_request_pending';
  }
  if (hasPendingRuntimeWarp) {
    return 'runtime_warp_pending';
  }
  if (hasPendingRuntimeConnection) {
    return 'runtime_connection_pending';
  }
  if (isPlayerStepInProgress) {
    return 'player_step_in_progress';
  }
  return null;
}
