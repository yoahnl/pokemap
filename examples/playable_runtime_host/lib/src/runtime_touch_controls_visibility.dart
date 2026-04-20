enum RuntimeTouchControlsBlockReason {
  unavailablePlatform,
  userHidden,
  battleActive,
  gamepadConnected,
}

final class RuntimeTouchControlsVisibility {
  const RuntimeTouchControlsVisibility({
    required this.showToggleButton,
    required this.showControls,
    required this.userHidden,
    required this.blockReason,
    required this.toggleTooltip,
  });

  final bool showToggleButton;
  final bool showControls;
  final bool userHidden;
  final RuntimeTouchControlsBlockReason? blockReason;
  final String toggleTooltip;
}

RuntimeTouchControlsVisibility resolveRuntimeTouchControlsVisibility({
  required bool supportsTouchControls,
  required bool userHidden,
  required bool hasConnectedGamepad,
  required bool isBattleActive,
}) {
  if (!supportsTouchControls) {
    return const RuntimeTouchControlsVisibility(
      showToggleButton: false,
      showControls: false,
      userHidden: false,
      blockReason: RuntimeTouchControlsBlockReason.unavailablePlatform,
      toggleTooltip: 'Contrôles tactiles indisponibles',
    );
  }

  if (hasConnectedGamepad) {
    return RuntimeTouchControlsVisibility(
      showToggleButton: true,
      showControls: false,
      userHidden: userHidden,
      blockReason: RuntimeTouchControlsBlockReason.gamepadConnected,
      toggleTooltip: userHidden
          ? 'Manette connectée · les contrôles tactiles restent masqués'
          : 'Manette connectée · les contrôles tactiles sont masqués',
    );
  }

  if (isBattleActive) {
    return RuntimeTouchControlsVisibility(
      showToggleButton: true,
      showControls: false,
      userHidden: userHidden,
      blockReason: RuntimeTouchControlsBlockReason.battleActive,
      toggleTooltip: userHidden
          ? 'Combat en cours · les contrôles tactiles restent masqués'
          : 'Combat en cours · les contrôles tactiles sont masqués',
    );
  }

  if (userHidden) {
    return const RuntimeTouchControlsVisibility(
      showToggleButton: true,
      showControls: false,
      userHidden: true,
      blockReason: RuntimeTouchControlsBlockReason.userHidden,
      toggleTooltip: 'Afficher les contrôles tactiles',
    );
  }

  return const RuntimeTouchControlsVisibility(
    showToggleButton: true,
    showControls: true,
    userHidden: false,
    blockReason: null,
    toggleTooltip: 'Masquer les contrôles tactiles',
  );
}
