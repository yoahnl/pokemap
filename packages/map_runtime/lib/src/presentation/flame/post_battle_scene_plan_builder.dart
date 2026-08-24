import '../../application/runtime_post_battle_decision_coordinator.dart';
import 'battle_animation_plan.dart';

/// Le plan d'un segment de fin de combat — BETA-BAT-017.
///
/// Chaque message du coordinator devient une phase lisible dans la boîte de
/// dialogue de la scène, et les gains d'Exp. du combattant affiché
/// remplissent la barre : jusqu'au plein avec le jingle de niveau de la
/// référence (`me_play(level_up_me)`, 500 ExpDistribution.rb, adapté en SE)
/// et remise à zéro à chaque niveau gagné, puis jusqu'au reliquat exact.
/// Sur une victoire dresseur, [showDefeatedTrainerVisual] ancre la
/// réapparition du dresseur vaincu sur « Vous avez battu X ! » — sans image
/// préparée côté hôte, le message seul fait l'annonce.
///
/// Retourne aussi la progression affichée en fin de segment, pour enchaîner
/// le segment suivant après une décision.
({BattleAnimationPlan plan, double endXpProgress})
    buildPostBattleScenePlanSegment({
  required List<RuntimePostBattleMessage> messages,
  required int? activePartySlot,
  required double fromXpProgress,
  required double? targetXpProgress,
  bool showDefeatedTrainerVisual = false,
}) {
  var pendingLevelUps = messages
      .where((message) =>
          message.kind == RuntimePostBattleMessageKind.levelUp &&
          message.partySlot == activePartySlot)
      .length;
  var xpProgress = fromXpProgress;
  var xpBarFull = false;
  final steps = <BattleAnimationStep>[];
  for (final message in messages) {
    final concernsDisplayedPokemon =
        activePartySlot != null && message.partySlot == activePartySlot;
    if (message.kind == RuntimePostBattleMessageKind.levelUp &&
        concernsDisplayedPokemon &&
        xpBarFull) {
      steps.add(const PlaySeStep(seName: 'level_up'));
      steps.add(ShowMessageStep(message: message.text));
      steps.add(
        const HudXpTweenStep(fromProgress: 1, toProgress: 0, durationMs: 0),
      );
      final target = pendingLevelUps > 1 ? 1.0 : (targetXpProgress ?? 1.0);
      steps.add(HudXpTweenStep(fromProgress: 0, toProgress: target));
      xpProgress = target;
      xpBarFull = pendingLevelUps > 1;
      pendingLevelUps -= 1;
      steps.add(const WaitStep(durationSeconds: 0.35));
      continue;
    }
    if (message.kind == RuntimePostBattleMessageKind.trainerDefeated &&
        showDefeatedTrainerVisual) {
      steps.add(const ShowDefeatedTrainerStep());
    }
    steps.add(ShowMessageStep(message: message.text));
    if (message.kind == RuntimePostBattleMessageKind.experience &&
        concernsDisplayedPokemon &&
        targetXpProgress != null) {
      final target = pendingLevelUps > 0 ? 1.0 : targetXpProgress;
      steps.add(
        HudXpTweenStep(fromProgress: xpProgress, toProgress: target),
      );
      xpProgress = target;
      xpBarFull = pendingLevelUps > 0;
      steps.add(const WaitStep(durationSeconds: 0.35));
      continue;
    }
    steps.add(const WaitStep(durationSeconds: 0.9));
  }
  return (
    plan: BattleAnimationPlan(steps: List.unmodifiable(steps)),
    endXpProgress: xpProgress,
  );
}
