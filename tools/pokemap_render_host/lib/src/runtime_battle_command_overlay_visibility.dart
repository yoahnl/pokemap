bool shouldShowRuntimeBattleCommandOverlay({
  required bool supportsTouchControls,
  required bool hasConnectedGamepad,
  required bool isBattleActive,
  required bool hasSnapshot,
}) {
  // La chrome battle visible passe désormais par Flutter partout :
  // - mobile tactile ;
  // - desktop ;
  // - manette ou non.
  //
  // Les paramètres hardware restent conservés pour limiter le churn des call
  // sites/tests du host, mais ils ne gouvernent plus l'affichage battle.
  return isBattleActive && hasSnapshot;
}
