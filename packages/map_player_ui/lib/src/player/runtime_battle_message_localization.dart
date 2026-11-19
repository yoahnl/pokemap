import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';

String localizeRuntimeBattleMessage(
  String locale,
  RuntimeBattleMessage message,
) {
  final tag = RuntimePlayerLanguageChoice.tryNormalizeLanguageTag(locale);
  final l10n = PokeMapPlayerLocalizations.lookup(
    Locale(tag?.split('-').first ?? 'en'),
  );

  return switch (message.id) {
    RuntimeBattleMessageId.player => l10n.battleNarrationPlayer,
    RuntimeBattleMessageId.enemy => l10n.battleNarrationEnemy,
    RuntimeBattleMessageId.wildAppeared => l10n.battleWildAppeared(
      target: message.target,
    ),
    RuntimeBattleMessageId.trainerChallenges => l10n.battleTrainerChallenges(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.unknownTrainerChallenges =>
      l10n.battleUnknownTrainerChallenges,
    RuntimeBattleMessageId.trainerSends => l10n.battleTrainerSends(
      actor: message.actor,
      target: message.target,
    ),
    RuntimeBattleMessageId.unknownTrainerSends =>
      l10n.battleUnknownTrainerSends(target: message.target),
    RuntimeBattleMessageId.go => l10n.battleSendOut(target: message.target),
    RuntimeBattleMessageId.joined => l10n.battleJoined(target: message.target),
    RuntimeBattleMessageId.confusionHurt => l10n.battleConfusionHurt,
    RuntimeBattleMessageId.moveUsed => l10n.battleMoveUsed(
      actor: message.actor,
      move: message.move,
    ),
    RuntimeBattleMessageId.moveDamageSummary => l10n.battleMoveDamageSummary(
      actor: message.actor,
      move: message.move,
      amount: message.amount,
    ),
    RuntimeBattleMessageId.moveDodged => l10n.battleMoveDodged(
      target: message.target,
    ),
    RuntimeBattleMessageId.moveImmune => l10n.battleMoveImmune(
      target: message.target,
    ),
    RuntimeBattleMessageId.criticalHit => l10n.battleCriticalHit,
    RuntimeBattleMessageId.superEffective => l10n.battleSuperEffective,
    RuntimeBattleMessageId.notVeryEffective => l10n.battleNotVeryEffective,
    RuntimeBattleMessageId.fainted => l10n.battleFainted(
      target: message.target,
    ),
    RuntimeBattleMessageId.itemUsed => l10n.battleItemUsed(
      actor: message.actor,
      item: message.item,
      target: message.target,
    ),
    RuntimeBattleMessageId.hpRecovered => l10n.battleHpRecovered(
      target: message.target,
      amount: message.amount,
    ),
    RuntimeBattleMessageId.statusCured => l10n.battleStatusCured(
      target: message.target,
    ),
    RuntimeBattleMessageId.ppRecovered => l10n.battlePpRecovered(
      move: message.move,
      amount: message.amount,
    ),
    RuntimeBattleMessageId.captureThrown => l10n.battleCaptureThrown(
      target: message.target,
    ),
    RuntimeBattleMessageId.captureCaught => l10n.battleCaptureCaught(
      target: message.target,
    ),
    RuntimeBattleMessageId.captureEscaped => l10n.battleCaptureEscaped(
      target: message.target,
    ),
    RuntimeBattleMessageId.paralyzed => l10n.battleParalyzed(
      target: message.target,
    ),
    RuntimeBattleMessageId.burned => l10n.battleBurned(target: message.target),
    RuntimeBattleMessageId.poisoned => l10n.battlePoisoned(
      target: message.target,
    ),
    RuntimeBattleMessageId.badlyPoisoned => l10n.battleBadlyPoisoned(
      target: message.target,
    ),
    RuntimeBattleMessageId.fellAsleep => l10n.battleFellAsleep(
      target: message.target,
    ),
    RuntimeBattleMessageId.frozen => l10n.battleFrozen(target: message.target),
    RuntimeBattleMessageId.alreadyHasStatus => l10n.battleAlreadyHasStatus(
      target: message.target,
    ),
    RuntimeBattleMessageId.cannotAct => l10n.battleCannotAct(
      target: message.target,
    ),
    RuntimeBattleMessageId.burnDamage => l10n.battleBurnDamage(
      target: message.target,
    ),
    RuntimeBattleMessageId.poisonDamage => l10n.battlePoisonDamage(
      target: message.target,
    ),
    RuntimeBattleMessageId.statusDamage => l10n.battleStatusDamage(
      target: message.target,
    ),
    RuntimeBattleMessageId.protectActivated => l10n.battleProtectActivated(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.protectBlocked => l10n.battleProtectBlocked,
    RuntimeBattleMessageId.protectBroken => l10n.battleProtectBroken,
    RuntimeBattleMessageId.rechargeRequired => l10n.battleRechargeRequired(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.rechargeTurnSpent => l10n.battleRechargeTurnSpent(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.chargeStarted => l10n.battleChargeStarted(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.chargeReleased => l10n.battleChargeReleased(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.confusionApplied => l10n.battleConfusionApplied(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.confusionActive => l10n.battleConfusionActive(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.confusionEnded => l10n.battleConfusionEnded(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.rainStarted => l10n.battleRainStarted,
    RuntimeBattleMessageId.sandstormStarted => l10n.battleSandstormStarted,
    RuntimeBattleMessageId.sandstormDamage => l10n.battleSandstormDamage(
      target: message.target,
    ),
    RuntimeBattleMessageId.weatherExpired => l10n.battleWeatherExpired,
    RuntimeBattleMessageId.trickRoomStarted => l10n.battleTrickRoomStarted,
    RuntimeBattleMessageId.fieldCleared => l10n.battleFieldCleared,
    RuntimeBattleMessageId.fieldExpired => l10n.battleFieldExpired,
    RuntimeBattleMessageId.stealthRockSet => l10n.battleStealthRockSet,
    RuntimeBattleMessageId.stealthRockAlreadyPresent =>
      l10n.battleStealthRockAlreadyPresent,
    RuntimeBattleMessageId.stealthRockDamage => l10n.battleStealthRockDamage,
    RuntimeBattleMessageId.spikesSet => l10n.battleSpikesSet,
    RuntimeBattleMessageId.spikesAlreadyPresent =>
      l10n.battleSpikesAlreadyPresent,
    RuntimeBattleMessageId.spikesDamage => l10n.battleSpikesDamage,
    RuntimeBattleMessageId.switched => l10n.battleSwitched(
      actor: message.actor,
      target: message.target,
      replacement: message.replacement,
    ),
    RuntimeBattleMessageId.replacementRequired =>
      l10n.battleReplacementRequired(
        actor: message.actor,
        target: message.target,
      ),
    RuntimeBattleMessageId.statRaised => l10n.battleStatRaised(
      target: message.target,
      stat: l10n.battleStatName(stat: message.stat?.name ?? ''),
      amount: message.amount,
    ),
    RuntimeBattleMessageId.statLowered => l10n.battleStatLowered(
      target: message.target,
      stat: l10n.battleStatName(stat: message.stat?.name ?? ''),
      amount: message.amount,
    ),
    RuntimeBattleMessageId.statCannotRaise => l10n.battleStatCannotRaise(
      target: message.target,
      stat: l10n.battleStatName(stat: message.stat?.name ?? ''),
    ),
    RuntimeBattleMessageId.statCannotLower => l10n.battleStatCannotLower(
      target: message.target,
      stat: l10n.battleStatName(stat: message.stat?.name ?? ''),
    ),
    RuntimeBattleMessageId.moveFailed => l10n.battleMoveFailed,
    RuntimeBattleMessageId.fleeFailed => l10n.battleFleeFailed,
    RuntimeBattleMessageId.victory => l10n.battleNarrationVictory,
    RuntimeBattleMessageId.defeat => l10n.battleNarrationDefeat,
    RuntimeBattleMessageId.fled => l10n.battleNarrationFled,
    RuntimeBattleMessageId.emptyBag => l10n.bagEmpty,
    RuntimeBattleMessageId.actionUnavailable => l10n.actionUnavailable,
    RuntimeBattleMessageId.replacementRequiredHint => l10n.mandatoryReplacement,
    RuntimeBattleMessageId.hudHp => l10n.healHp(
      current: message.amount,
      maximum: message.maximum,
    ),
    RuntimeBattleMessageId.hudLevel => l10n.pokemonLevel(level: message.amount),
    RuntimeBattleMessageId.chooseAction => l10n.battleChooseAction(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.chooseReplacementAfterFaint =>
      l10n.battleChooseReplacementAfterFaint(actor: message.actor),
    RuntimeBattleMessageId.continuePrompt => l10n.battleContinuePrompt,
    RuntimeBattleMessageId.battleFinished => l10n.battleFinished,
    RuntimeBattleMessageId.resolvingTurn => l10n.battleResolvingTurn,
    RuntimeBattleMessageId.noReplacement => l10n.battleNoReplacement,
    RuntimeBattleMessageId.noLegalChoice => l10n.battleNoLegalChoice,
    RuntimeBattleMessageId.chooseAttackTarget => l10n.battleChooseAttackTarget(
      actor: message.actor,
    ),
    RuntimeBattleMessageId.choosePokemon => l10n.battleChoosePokemon,
    RuntimeBattleMessageId.chooseReplacement => l10n.battleChooseReplacement,
    RuntimeBattleMessageId.noSwitch => l10n.battleNoSwitch,
    RuntimeBattleMessageId.activeOrFainted => l10n.battleActiveOrFainted,
    RuntimeBattleMessageId.chooseItem => l10n.battleChooseItem,
    RuntimeBattleMessageId.noUsableItem => l10n.battleNoUsableItem,
    RuntimeBattleMessageId.itemsDisabled => l10n.battleItemsDisabled,
    RuntimeBattleMessageId.chooseItemTarget => l10n.battleChooseItemTarget(
      item: message.item,
    ),
    RuntimeBattleMessageId.chooseItemMove => l10n.battleChooseItemMove(
      item: message.item,
    ),
    RuntimeBattleMessageId.noItemTarget => l10n.battleNoItemTarget,
    RuntimeBattleMessageId.faintedOrFullHp => l10n.battleFaintedOrFullHp,
    RuntimeBattleMessageId.fullPpDisabled => l10n.battleFullPpDisabled,
    RuntimeBattleMessageId.wildBattle => l10n.battleWildTitle,
    RuntimeBattleMessageId.trainerBattle => l10n.battleTrainerTitle,
    RuntimeBattleMessageId.postBattleVictory => l10n.postBattleVictoryMessage,
    RuntimeBattleMessageId.postBattleDefeat => l10n.postBattleDefeatMessage,
    RuntimeBattleMessageId.postBattleFled => l10n.postBattleFledMessage,
    RuntimeBattleMessageId.postBattleCaptured => l10n.postBattleCapturedMessage(
      target: message.target,
    ),
    RuntimeBattleMessageId.postBattleCaptureParty =>
      l10n.postBattleCaptureParty(target: message.target),
    RuntimeBattleMessageId.postBattleCaptureStorage =>
      l10n.postBattleCaptureStorage(target: message.target),
    RuntimeBattleMessageId.postBattleCaptureUnavailable =>
      l10n.postBattleCaptureUnavailable,
    RuntimeBattleMessageId.postBattleExperience =>
      l10n.postBattleExperienceMessage(
        target: message.target,
        amount: message.amount,
      ),
    RuntimeBattleMessageId.postBattleLevelUp => l10n.postBattleLevelUpMessage(
      target: message.target,
      amount: message.amount,
    ),
    RuntimeBattleMessageId.postBattleMoveLearning =>
      l10n.postBattleMoveLearningMessage(
        target: message.target,
        move: message.move,
      ),
    RuntimeBattleMessageId.postBattleMoveReplacement =>
      l10n.postBattleMoveReplacementMessage(move: message.move),
    RuntimeBattleMessageId.postBattleMoveLearned =>
      l10n.postBattleMoveLearnedMessage(move: message.move),
    RuntimeBattleMessageId.postBattleMoveReplaced =>
      l10n.postBattleMoveReplacedMessage(
        previousMove: message.previousMove,
        move: message.move,
      ),
    RuntimeBattleMessageId.postBattleMoveDeclined =>
      l10n.postBattleMoveDeclinedMessage(move: message.move),
    RuntimeBattleMessageId.postBattleEvolutionPrompt =>
      l10n.postBattleEvolutionPrompt(
        target: message.target,
        replacement: message.replacement,
      ),
    RuntimeBattleMessageId.postBattleEvolutionAccepted =>
      l10n.postBattleEvolutionAccepted(
        target: message.target,
        replacement: message.replacement,
      ),
    RuntimeBattleMessageId.postBattleEvolutionRefused =>
      l10n.postBattleEvolutionRefused(target: message.target),
    RuntimeBattleMessageId.postBattleTrainerDefeated =>
      l10n.postBattleTrainerDefeated(actor: message.actor),
    RuntimeBattleMessageId.postBattleMoney => l10n.postBattleMoneyMessage(
      amount: message.amount,
    ),
    RuntimeBattleMessageId.postBattleItem => l10n.postBattleItemMessage(
      item: message.item,
      amount: message.amount,
    ),
    RuntimeBattleMessageId.postBattleFlag => l10n.postBattleFlagMessage(
      target: message.target,
    ),
    RuntimeBattleMessageId.postBattleBadge => l10n.postBattleBadgeMessage(
      target: message.target,
    ),
    RuntimeBattleMessageId.postBattleAbility => l10n.postBattleAbilityMessage(
      move: message.move,
    ),
    RuntimeBattleMessageId.postBattleLearn => l10n.postBattleLearn,
    RuntimeBattleMessageId.postBattleDeclineMove => l10n.postBattleDeclineMove,
    RuntimeBattleMessageId.postBattleEvolve => l10n.postBattleEvolve,
    RuntimeBattleMessageId.postBattleDeclineEvolution =>
      l10n.postBattleDeclineEvolution,
    RuntimeBattleMessageId.postBattleChoose => l10n.postBattleChoose,
    RuntimeBattleMessageId.postBattleCompleted => l10n.postBattleCompleted,
    RuntimeBattleMessageId.postBattleNoResult => l10n.postBattleNoResult,
    RuntimeBattleMessageId.postBattleDecisionError =>
      l10n.postBattleDecisionError,
    RuntimeBattleMessageId.postBattleMissingTransaction =>
      l10n.postBattleMissingTransaction,
    RuntimeBattleMessageId.postBattleAlreadyApplied =>
      l10n.postBattleAlreadyApplied,
    RuntimeBattleMessageId.postBattleApplyFailed => l10n.postBattleApplyFailed,
    RuntimeBattleMessageId.postBattleMoveNotPending =>
      l10n.postBattleMoveNotPending,
    RuntimeBattleMessageId.postBattleMoveInvalid => l10n.postBattleMoveInvalid,
    RuntimeBattleMessageId.postBattleEvolutionNotPending =>
      l10n.postBattleEvolutionNotPending,
    RuntimeBattleMessageId.postBattleEvolutionInvalid =>
      l10n.postBattleEvolutionInvalid,
    RuntimeBattleMessageId.postBattleRewardBagCapacity =>
      l10n.postBattleRewardBagCapacity,
    RuntimeBattleMessageId.postBattleRewardQuantity =>
      l10n.postBattleRewardQuantity,
    RuntimeBattleMessageId.postBattleRewardMissingItemCatalog =>
      l10n.postBattleRewardMissingItemCatalog,
    RuntimeBattleMessageId.postBattleRewardUnknownItem =>
      l10n.postBattleRewardUnknownItem(item: message.item),
    RuntimeBattleMessageId.postBattleRewardInvalid =>
      l10n.postBattleRewardInvalid,
    RuntimeBattleMessageId.postBattleRewardMissingTrainer =>
      l10n.postBattleRewardMissingTrainer,
    RuntimeBattleMessageId.postBattleRewardInvalidBattle =>
      l10n.postBattleRewardInvalidBattle,
    RuntimeBattleMessageId.postBattleRewardMissingData =>
      l10n.postBattleRewardMissingData,
  };
}
