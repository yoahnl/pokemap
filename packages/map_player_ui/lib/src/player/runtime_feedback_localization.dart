import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';

part 'runtime_service_feedback_localization.dart';

String localizeRuntimeStartupFailure(
  RuntimeStartupFailure? failure,
  PokeMapPlayerLocalizations l10n,
) {
  if (failure == null) return l10n.startupStartupUnavailable;
  return switch (failure.code) {
    'runtimeGraphActivationFailed' =>
      l10n.runtimeFeedbackStartupGamePreparationFailed,
    'runtimeBootstrapFailed' =>
      l10n.runtimeFeedbackStartupPreparationStartFailed,
    'manifestPreparationFailed' =>
      l10n.runtimeFeedbackStartupIdentityPreparationFailed,
    'initialMapPreparationFailed' =>
      l10n.runtimeFeedbackStartupMapPreparationFailed,
    'presentationProfileUnavailable' =>
      l10n.runtimeFeedbackStartupPresentationLoadFailed,
    'saveDiscoveryFailed' => l10n.runtimeFeedbackStartupSaveDiscoveryFailed,
    'preferencesFailed' => l10n.runtimeFeedbackStartupPreferencesLoadFailed,
    final code when code.startsWith('hub.') =>
      l10n.runtimeFeedbackStartupInstalledGamePreparationFailed,
    _ => failure.safeMessage,
  };
}

String? localizeRuntimePlayerFeedback(
  String locale,
  RuntimePlayerFeedback feedback,
  Map<String, Object> arguments,
) {
  final language = RuntimePlayerLanguageChoice.tryNormalizeLanguageTag(locale)
      ?.split('-')
      .first;
  final l10n = PokeMapPlayerLocalizations.lookup(Locale(language ?? 'en'));
  return switch (feedback) {
    RuntimeOverworldFeedback() => _localizeOverworldFeedback(
      l10n,
      feedback,
      arguments,
    ),
    RuntimeServiceFeedback() => _localizeServiceFeedback(
      l10n,
      feedback,
      arguments,
    ),
    RuntimeNavigationFeedback() => _localizeNavigationFeedback(l10n, feedback),
  };
}

String _localizeNavigationFeedback(
  PokeMapPlayerLocalizations l10n,
  RuntimeNavigationFeedback feedback,
) => switch (feedback) {
  .saveUnavailablePostGameContinuationRefused =>
    l10n.saveUnavailablePostGameContinuationRefused,
  .saveUnavailableMigrationRequired => l10n.saveUnavailableMigrationRequired,
  .saveUnavailableIncompatibleVersion =>
    l10n.saveUnavailableIncompatibleVersion,
  .saveUnavailableCorrupt => l10n.saveUnavailableCorrupt,
  .saveUnavailableMissing => l10n.saveUnavailableMissing,
  .saveUnavailableTemporarilyUnavailable =>
    l10n.saveUnavailableTemporarilyUnavailable,
  .saveInProgress => l10n.runtimeFeedbackSaveInProgress,
  .favoritesBagChanged => l10n.runtimeFeedbackFavoritesBagChanged,
  .favoritesUnavailable => l10n.runtimeFeedbackFavoritesUnavailable,
  .favoritesSaveFailed => l10n.runtimeFeedbackFavoritesSaveFailed,
  .playerActionStale => l10n.runtimeFeedbackPlayerActionStale,
  .regionalMapCloseFirst => l10n.runtimeFeedbackRegionalMapCloseFirst,
  .playerActionUnavailable => l10n.runtimeFeedbackPlayerActionUnavailable,
  .newGameSlotRequired => l10n.runtimeFeedbackNewGameSlotRequired,
  .noCompatibleSave => l10n.runtimeFeedbackNoCompatibleSave,
  .loadSlotRequired => l10n.runtimeFeedbackLoadSlotRequired,
  .selectedSaveUnavailable => l10n.runtimeFeedbackSelectedSaveUnavailable,
  .finalSaveFailed => l10n.runtimeFeedbackFinalSaveFailed,
  .partyMembersRequired => l10n.runtimeFeedbackPartyMembersRequired,
  .playerCommandUnavailable => l10n.runtimeFeedbackPlayerCommandUnavailable,
  .playerPreferencesRequired => l10n.runtimeFeedbackPlayerPreferencesRequired,
  .playerPreferencesSaveFailed => l10n.optionsError,
  .saveWriteFailed => l10n.runtimeFeedbackSaveWriteFailed,
  .creditsUnavailable => l10n.runtimeFeedbackCreditsUnavailable,
  .surfaceActionUnavailable => l10n.runtimeFeedbackSurfaceActionUnavailable,
  .playerResponseStale => l10n.runtimeFeedbackPlayerResponseStale,
  .returnToHostFailed => l10n.runtimeFeedbackReturnToHostFailed,
  .playerDataRefreshFailed => l10n.runtimeFeedbackPlayerDataRefreshFailed,
  .sessionCloseFailed => l10n.runtimeFeedbackSessionCloseFailed,
  .explorationMapChanged => l10n.runtimeFeedbackExplorationMapChanged,
  .newGamePreparationChanged => l10n.runtimeFeedbackNewGamePreparationChanged,
  .newGameSetupInvalid => l10n.runtimeFeedbackNewGameSetupInvalid,
  .newGameContentChanged => l10n.runtimeFeedbackNewGameContentChanged,
  .newGameResourceLimit => l10n.runtimeFeedbackNewGameResourceLimit,
  .newGameSaveReadFailed => l10n.runtimeFeedbackNewGameSaveReadFailed,
  .newGamePreloadFailed => l10n.runtimeFeedbackNewGamePreloadFailed,
  .newGameSceneFailed => l10n.runtimeFeedbackNewGameSceneFailed,
  .newGameSetupFailed => l10n.runtimeFeedbackNewGameSetupFailed,
  .saveOpenFailed => l10n.runtimeFeedbackSaveOpenFailed,
  .sessionLaunchFailed => l10n.runtimeFeedbackSessionLaunchFailed,
  .playerDataLoadFailed => l10n.runtimeFeedbackPlayerDataLoadFailed,
  .sessionFailed => l10n.runtimeFeedbackSessionFailed,
  .explorationSaveUnavailable => l10n.runtimeFeedbackExplorationSaveUnavailable,
  .noCompatibleGameSave => l10n.runtimeFeedbackNoCompatibleGameSave,
  .playerMapUnavailable => l10n.runtimeFeedbackPlayerMapUnavailable,
  .unusableSaveNotSelected => l10n.runtimeFeedbackUnusableSaveNotSelected,
  .serviceNotActive => l10n.runtimeFeedbackServiceNotActive,
  .bagRequiresPause => l10n.runtimeFeedbackBagRequiresPause,
  .bagItemCheckpointFailed => l10n.runtimeFeedbackBagItemCheckpointFailed,
  .sessionEventStreamFailed => l10n.runtimeFeedbackSessionEventStreamFailed,
  .sessionPrepareTimedOut => l10n.runtimeFeedbackSessionPrepareTimedOut,
  .sessionPrepareFailed => l10n.runtimeFeedbackSessionPrepareFailed,
  .sessionStartTimedOut => l10n.runtimeFeedbackSessionStartTimedOut,
  .sessionStartFailed => l10n.runtimeFeedbackSessionStartFailed,
  .sessionSignalInvalid => l10n.runtimeFeedbackSessionSignalInvalid,
  .sessionEndingMismatch => l10n.runtimeFeedbackSessionEndingMismatch,
  .sessionEndingInvalid => l10n.runtimeFeedbackSessionEndingInvalid,
  .previousSessionCloseFailed => l10n.runtimeFeedbackPreviousSessionCloseFailed,
};

String? _localizeOverworldFeedback(
  PokeMapPlayerLocalizations l10n,
  RuntimeOverworldFeedback feedback,
  Map<String, Object> arguments,
) => switch (feedback) {
  .fishingInterrupted => l10n.runtimeFeedbackFishingInterrupted,
  .fishingCasting => l10n.runtimeFeedbackFishingCasting,
  .fishingWaiting => l10n.runtimeFeedbackFishingWaiting,
  .fishingBite => l10n.runtimeFeedbackFishingBite,
  .fishingNoBite => l10n.runtimeFeedbackFishingNoBite,
  .fishingEncounterUnavailable =>
    l10n.runtimeFeedbackFishingEncounterUnavailable,
  .fishingCancelled => l10n.runtimeFeedbackFishingCancelled,
  .fieldActionChanged => l10n.runtimeFeedbackFieldActionChanged,
  .fieldCrossingUnavailable => l10n.runtimeFeedbackFieldCrossingUnavailable,
  .fieldFlashUsed => l10n.runtimeFeedbackFieldFlashUsed,
  .fieldCutUsed => l10n.runtimeFeedbackFieldCutUsed,
  .fieldStrengthActive => l10n.runtimeFeedbackFieldStrengthActive,
  .fieldRockSmashUsed => l10n.runtimeFeedbackFieldRockSmashUsed,
  .fieldDivePassageUnavailable =>
    l10n.runtimeFeedbackFieldDivePassageUnavailable,
  .waterRequiresSurf => l10n.runtimeFeedbackWaterRequiresSurf,
  .underwaterRequiresDive => l10n.runtimeFeedbackUnderwaterRequiresDive,
  .diveRequiresUnderwater => l10n.runtimeFeedbackDiveRequiresUnderwater,
  .incompatibleMovementTerrain =>
    l10n.runtimeFeedbackIncompatibleMovementTerrain,
  .surfMissingPokemon => l10n.runtimeFeedbackSurfMissingPokemon,
  .surfLocked => l10n.runtimeFeedbackSurfLocked,
  .surfConfirm => l10n.runtimeFeedbackSurfConfirm,
  .yes => l10n.yes,
  .no => l10n.no,
  .narrativePending => l10n.runtimeFeedbackNarrativePending,
  .narrativeUnavailable => l10n.runtimeFeedbackNarrativeUnavailable,
  .narrativeResultUnavailable => l10n.runtimeFeedbackNarrativeResultUnavailable,
  .cannotEndGame => l10n.runtimeFeedbackCannotEndGame,
  .giftFailed => l10n.runtimeFeedbackGiftFailed,
  .transitionFailed => l10n.runtimeFeedbackTransitionFailed,
  .transitionPassageMissing => l10n.runtimeFeedbackTransitionPassageMissing,
  .invalidMapConnection => l10n.runtimeFeedbackInvalidMapConnection,
  .mapConnectionBlocked => l10n.runtimeFeedbackMapConnectionBlocked,
  .sceneUnavailable => l10n.runtimeFeedbackSceneUnavailable,
  .sceneCannotContinue => l10n.runtimeFeedbackSceneCannotContinue,
  .dialogueMissing => l10n.runtimeFeedbackDialogueMissing,
  .mapPassageUnavailable => l10n.runtimeFeedbackMapPassageUnavailable,
  .teleportFailed => l10n.runtimeFeedbackTeleportFailed,
  .neighboringMapTransferFailed =>
    l10n.runtimeFeedbackNeighboringMapTransferFailed,
  .contactUnavailable => l10n.runtimeFeedbackContactUnavailable,
  .puzzleSceneRequired => l10n.runtimeFeedbackPuzzleSceneRequired,
  .fieldMoveCut => l10n.runtimeFeedbackFieldMoveCut,
  .fieldMoveStrength => l10n.runtimeFeedbackFieldMoveStrength,
  .fieldMoveRockSmash => l10n.runtimeFeedbackFieldMoveRockSmash,
  .fieldMoveWaterfall => l10n.runtimeFeedbackFieldMoveWaterfall,
  .fieldMoveWhirlpool => l10n.runtimeFeedbackFieldMoveWhirlpool,
  .fieldObstacleCutConfirm => l10n.runtimeFeedbackFieldObstacleCutConfirm,
  .fieldObstacleStrengthConfirm =>
    l10n.runtimeFeedbackFieldObstacleStrengthConfirm,
  .fieldObstacleRockSmashConfirm =>
    l10n.runtimeFeedbackFieldObstacleRockSmashConfirm,
  .fieldObstacleCutMissing => l10n.runtimeFeedbackFieldObstacleCutMissing,
  .fieldObstacleStrengthMissing =>
    l10n.runtimeFeedbackFieldObstacleStrengthMissing,
  .fieldObstacleRockSmashMissing =>
    l10n.runtimeFeedbackFieldObstacleRockSmashMissing,
  .fieldObstacleMoveLocked => switch (arguments) {
    {'move': final String move} => l10n.runtimeFeedbackFieldObstacleMoveLocked(
      move: move,
    ),
    _ => null,
  },
  .fieldObstacleStrengthReady => l10n.runtimeFeedbackFieldObstacleStrengthReady,
  .fieldTraversalConfirm => switch (arguments) {
    {'move': final String move} => l10n.runtimeFeedbackFieldTraversalConfirm(
      move: move,
    ),
    _ => null,
  },
  .fieldTraversalMoveMissing => switch (arguments) {
    {'move': final String move} =>
      l10n.runtimeFeedbackFieldTraversalMoveMissing(move: move),
    _ => null,
  },
  .fieldTraversalMoveLocked => switch (arguments) {
    {'move': final String move} => l10n.runtimeFeedbackFieldTraversalMoveLocked(
      move: move,
    ),
    _ => null,
  },
  .fieldTraversalSurfRequired => l10n.runtimeFeedbackFieldTraversalSurfRequired,
  .fieldTraversalWrongDirection =>
    l10n.runtimeFeedbackFieldTraversalWrongDirection,
  .fieldTraversalObstructed => l10n.runtimeFeedbackFieldTraversalObstructed,
  .fieldTraversalWaterRequired =>
    l10n.runtimeFeedbackFieldTraversalWaterRequired,
  .fieldDiveConfirmDown => l10n.runtimeFeedbackFieldDiveConfirmDown,
  .fieldDiveConfirmUp => l10n.runtimeFeedbackFieldDiveConfirmUp,
  .fieldDiveDisabled => l10n.runtimeFeedbackFieldDiveDisabled,
  .fieldDiveMoveMissing => l10n.runtimeFeedbackFieldDiveMoveMissing,
  .fieldDiveMoveLocked => l10n.runtimeFeedbackFieldDiveMoveLocked,
  .fieldDiveSurfRequired => l10n.runtimeFeedbackFieldDiveSurfRequired,
  .fieldDiveObstructed => l10n.runtimeFeedbackFieldDiveObstructed,
  .fieldDiveDestinationUnavailable =>
    l10n.runtimeFeedbackFieldDiveDestinationUnavailable,
  .fieldFlashConfirm => l10n.runtimeFeedbackFieldFlashConfirm,
  .fieldFlashMoveMissing => l10n.runtimeFeedbackFieldFlashMoveMissing,
  .fieldFlashMoveLocked => l10n.runtimeFeedbackFieldFlashMoveLocked,
  .headbuttMoveMissing => l10n.runtimeFeedbackHeadbuttMoveMissing,
  .headbuttTreeConsumed => l10n.runtimeFeedbackHeadbuttTreeConsumed,
  .headbuttWrongPosition => l10n.runtimeFeedbackHeadbuttWrongPosition,
  .headbuttMapUnsupported => l10n.runtimeFeedbackHeadbuttMapUnsupported,
  .headbuttUnavailable => l10n.runtimeFeedbackHeadbuttUnavailable,
  .headbuttConfirm => l10n.runtimeFeedbackHeadbuttConfirm,
  .interactiveEncounterEmpty => l10n.runtimeFeedbackInteractiveEncounterEmpty,
  .interactiveEncounterUnavailable =>
    l10n.runtimeFeedbackInteractiveEncounterUnavailable,
  .repelExpired => l10n.runtimeFeedbackRepelExpired,
  .repelRenew => l10n.runtimeFeedbackRepelRenew,
  .repelRenewed => l10n.runtimeFeedbackRepelRenewed,
  .repelStockUnavailable => l10n.runtimeFeedbackRepelStockUnavailable,
  .repelProgressSaveFailed => l10n.runtimeFeedbackRepelProgressSaveFailed,
  .spatialNeighborUnavailable => l10n.runtimeFeedbackSpatialNeighborUnavailable,
  .spatialInteractionUnavailable =>
    l10n.runtimeFeedbackSpatialInteractionUnavailable,
  .movingPlatformUnavailable => l10n.runtimeFeedbackMovingPlatformUnavailable,
  .entranceAnimationMissing => l10n.runtimeFeedbackEntranceAnimationMissing,
  .entranceAnimationUnavailable =>
    l10n.runtimeFeedbackEntranceAnimationUnavailable,
  .elementAnimationUpdateFailed =>
    l10n.runtimeFeedbackElementAnimationUpdateFailed,
  .spatialSceneTextInputUnsupported =>
    l10n.runtimeFeedbackSpatialSceneTextInputUnsupported,
  .spatialSceneRegionalMapUnsupported =>
    l10n.runtimeFeedbackSpatialSceneRegionalMapUnsupported,
  .sceneRewardCalendarUnavailable =>
    l10n.runtimeFeedbackSceneRewardCalendarUnavailable,
};
