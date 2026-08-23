import 'package:map_battle/map_battle.dart';

import '../../application/runtime_move_catalog_loader.dart';
import 'battle_animation_plan.dart';
import 'battle_move_visual_catalog.dart';
import 'battle_move_visual_recipe_library.dart';
import 'battle_move_visual_resolver.dart';

/// Le nom affichable d'une espèce, ou son identifiant faute de mieux.
typedef BattleTurnSpeciesDisplayName = String Function(String speciesId);

/// Le nom affichable d'une capacité, depuis son identifiant et son libellé
/// brut.
typedef BattleTurnMoveDisplayName = String Function(
  String moveId,
  String fallbackName,
);

String _rawSpeciesName(String speciesId) => speciesId;

String _rawMoveName(String moveId, String fallbackName) => fallbackName;

final class BattleTurnAnimationPlanner {
  BattleTurnAnimationPlanner({
    BattleMoveVisualRecipeLibrary? recipeLibrary,
    this.speciesDisplayName = _rawSpeciesName,
    this.moveDisplayName = _rawMoveName,
  }) : _recipeLibrary = recipeLibrary ?? BattleMoveVisualRecipeLibrary();

  final BattleMoveVisualRecipeLibrary _recipeLibrary;

  /// BETA-BAT-011 : le journal parle la langue du joueur.
  ///
  /// Les deux résolveurs existent depuis longtemps et alimentent déjà le HUD et
  /// le menu de commandes ; le plan d'animation les contournait, donc le joueur
  /// lisait « machop utilise Low Kick ! » à côté d'un HUD disant « Machoc » et
  /// d'un menu disant « Tornade ». Ils sont injectés, avec un défaut qui rend
  /// l'identifiant : un appelant qui n'en fournit pas garde exactement l'ancien
  /// texte.
  final BattleTurnSpeciesDisplayName speciesDisplayName;
  final BattleTurnMoveDisplayName moveDisplayName;

  BattleAnimationPlan build({
    required BattleSession previousSession,
    required BattleSession newSession,
    required RuntimeMoveCatalog moveCatalog,
    required BattleMoveVisualResolver resolver,
  }) {
    final turnResult = newSession.state.currentTurn;
    if (turnResult == null) {
      final outcome = newSession.state.outcome;
      if (!newSession.state.isFinished || outcome == null) {
        return const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
      }
      return BattleAnimationPlan(
        steps: List<BattleAnimationStep>.unmodifiable(
          _buildOutcomeSteps(
            outcome,
            isTrainerBattle: newSession.setup.isTrainerBattle,
            speciesDisplayName: speciesDisplayName,
          ),
        ),
      );
    }
    final plan = buildForTurn(
      playerBefore: previousSession.state.player,
      enemyBefore: previousSession.state.enemy,
      turnResult: turnResult,
      moveCatalog: moveCatalog,
      resolver: resolver,
    );
    final outcome = newSession.state.outcome;
    if (!newSession.state.isFinished || outcome == null) {
      return plan;
    }
    return BattleAnimationPlan(
      steps: List<BattleAnimationStep>.unmodifiable(<BattleAnimationStep>[
        ...plan.steps,
        ..._buildOutcomeSteps(
          outcome,
          isTrainerBattle: newSession.setup.isTrainerBattle,
          speciesDisplayName: speciesDisplayName,
        ),
      ]),
    );
  }

  BattleAnimationPlan buildForTurn({
    required BattleCombatant playerBefore,
    required BattleCombatant enemyBefore,
    required BattleTurnResult turnResult,
    required RuntimeMoveCatalog moveCatalog,
    required BattleMoveVisualResolver resolver,
  }) {
    final trackedHp = <BattleSideId, int>{
      BattleSideId.player: playerBefore.currentHp,
      BattleSideId.enemy: enemyBefore.currentHp,
    };
    // BETA-BAT-011 : cette map porte le nom AFFICHABLE, pas l'identifiant. Son
    // ancien nom annonçait un identifiant tout en étant interpolé dans des
    // messages joueur — c'est précisément le mensonge qui a laissé « machop »
    // atteindre l'écran.
    final trackedDisplayName = <BattleSideId, String>{
      BattleSideId.player: speciesDisplayName(playerBefore.speciesId),
      BattleSideId.enemy: speciesDisplayName(enemyBefore.speciesId),
    };
    final replacementRequiredSides = turnResult.timeline
        .whereType<BattleTurnSwitchEvent>()
        .map((event) => event.event)
        .where(
            (event) => event.kind == BattleSwitchEventKind.replacementRequired)
        .map((event) => event.side)
        .toSet();
    final steps = <BattleAnimationStep>[];

    for (final event in turnResult.timeline) {
      switch (event) {
        case BattleTurnExecutionEvent(:final execution):
          steps.add(
            ShowMessageStep(
              message:
                  '${_presentationCombatantName(execution.attackerSide, trackedDisplayName)} utilise ${moveDisplayName(execution.move.id, execution.move.name)} !',
            ),
          );
          final resolvedMove = resolver.resolve(execution.move);
          final recipeSteps = _recipeLibrary
              .build(
                resolvedMove.recipeId,
                BattleMoveVisualRecipeContext(
                  resolvedMove: resolvedMove,
                  battleMove: execution.move,
                  execution: execution,
                  attackerSide: execution.attackerSide,
                  targetSide: execution.targetSide,
                  damage: execution.damage,
                  didHit: execution.didHit,
                  didCrit: execution.didCrit,
                ),
              )
              .toList();
          // BETA-BAT-013 : le clignotement de la cible est une réaction au
          // DÉGÂT, pas une étape de la chorégraphie du coup. Chez PSDK il vit
          // dans `show_hp_animations`, pilote par le gestionnaire de dégâts, et
          // part sur la même frame que la barre de PV.
          //
          // La recette garde le droit de déclarer QUE la cible clignote ; c'est
          // le planner qui décide QUAND, parce que lui seul connaît le dégât.
          // L'alternative aurait été de retirer l'étape des 112 recettes qui
          // l'émettent, pour le même résultat et un diff sans rapport avec le
          // sujet.
          final targetSideForFlash = execution.targetSide;
          if (targetSideForFlash != null) {
            recipeSteps.removeWhere(
              (step) =>
                  step is CombatantFlashStep &&
                  step.side == targetSideForFlash,
            );
          }
          steps.addAll(recipeSteps);
          if (execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null) {
            final targetSide = execution.targetSide!;
            final hpFrom = trackedHp[targetSide] ?? 0;
            final hpTo = (hpFrom - execution.damage).clamp(0, hpFrom);
            trackedHp[targetSide] = hpTo;
            final drainSeconds = _hpDrainSeconds(hpFrom - hpTo);
            // Le clignotement et la barre partent ENSEMBLE : un groupe
            // parallèle bloque la phase sur le plus long des deux, ce qui est
            // la sémantique du `Yuki::Animation::Handler` de la référence.
            steps.add(
              AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: <BattleAnimationStep>[
                  // Inconditionnel : la référence joue le clignotement depuis
                  // le gestionnaire de dégâts, donc il ne dépend pas de ce que
                  // la recette a déclaré. Un coup à animation RMXP n'en émet
                  // aucun, et devait quand même faire clignoter sa cible.
                  CombatantFlashStep(
                    side: targetSide,
                    durationSeconds: _damageBlinkSeconds,
                  ),
                  HudHpTweenStep(
                    side: targetSide,
                    fromHp: hpFrom,
                    toHp: hpTo,
                    durationMs: (drainSeconds * 1000).round(),
                  ),
                ],
              ),
            );
            // Le maintien après la descente, que la référence impose : court
            // quand la cible tombe, sinon de quoi compléter environ une
            // seconde.
            steps.add(
              WaitStep(
                durationSeconds: _postDrainHoldSeconds(
                  drainSeconds: drainSeconds,
                  faints: hpFrom > 0 && hpTo == 0,
                ),
              ),
            );
            // BETA-BAT-011 : critique puis efficacité, tous deux APRÈS la
            // descente des PV et AVANT la séquence de K.O. C'est l'ordre de la
            // référence, où `hit_criticality_message` précède
            // `efficent_message` et où les deux sont joués une fois
            // `show_hp_animations` terminé.
            if (execution.didCrit) {
              steps.add(const ShowMessageStep(message: 'Coup critique !'));
            }
            if (_effectivenessMessage(execution.typeEffectivenessMultiplier)
                case final effectiveness?) {
              steps.add(ShowMessageStep(message: effectiveness));
            }
            if (hpFrom > 0 && hpTo == 0) {
              if (!replacementRequiredSides.contains(targetSide)) {
                steps.add(
                  FaintCombatantStep(
                    side: targetSide,
                    // BETA-BAT-013 : la chute de la référence est de 0,1 s,
                    // fondu et descente en parallèle.
                    durationSeconds: 0.1,
                  ),
                );
              }
              steps.add(
                ShowMessageStep(
                  message:
                      '${_presentationCombatantName(targetSide, trackedDisplayName)} est K.O. !',
                ),
              );
            }
          }
        case BattleTurnBagHpHealItemEvent(:final event):
          steps.add(
            ShowMessageStep(
              message:
                  '${_presentationCombatantLabel(event.side)} utilise ${event.displayName} sur ${speciesDisplayName(event.targetSpeciesId)} !',
            ),
          );
          final visibleTargetSide = event.side == BattleSideId.player &&
                  playerBefore.lineupIndex == event.targetLineupIndex
              ? BattleSideId.player
              : event.side == BattleSideId.enemy &&
                      enemyBefore.lineupIndex == event.targetLineupIndex
                  ? BattleSideId.enemy
                  : null;
          steps.add(
            ShowMessageStep(
              message:
                  '${speciesDisplayName(event.targetSpeciesId)} récupère ${event.healedAmount} PV.',
            ),
          );
          if (visibleTargetSide != null && event.healedAmount > 0) {
            trackedHp[visibleTargetSide] = event.hpAfter;
            steps.add(
              HudHpTweenStep(
                side: visibleTargetSide,
                fromHp: event.hpBefore,
                toHp: event.hpAfter,
              ),
            );
          }
        case BattleTurnCaptureAttemptEvent(:final event):
          final targetName = speciesDisplayName(event.targetSpeciesId);
          steps.add(
            ShowMessageStep(
              message: 'Une Poké Ball est lancée sur $targetName !',
            ),
          );
          // ENC-005 : la séquence visuelle rejoue le nombre décidé par la
          // formule, elle ne le recalcule jamais. Au plus trois secousses sont
          // jouées — la quatrième « secousse » d'une capture est le clic de
          // verrouillage, porté par le message de verdict. Le suspense reste
          // couvert par reduced motion via le motionScale global de l'overlay.
          final visibleShakes = event.shakes.clamp(0, 3);
          for (var shake = 0; shake < visibleShakes; shake++) {
            steps.add(const WaitStep(durationSeconds: 0.30));
            steps.add(
              const CombatantShakeStep(
                side: BattleSideId.enemy,
                amplitudePx: 6,
                durationSeconds: 0.28,
              ),
            );
          }
          steps.add(
            ShowMessageStep(
              message: event.caught
                  ? '$targetName est capturé !'
                  : '$targetName s’échappe de la Poké Ball !',
            ),
          );
        case BattleTurnStatusEvent(:final event):
          steps.add(ShowMessageStep(message: _messageForStatusEvent(event)));
        case BattleTurnVolatileEvent(:final event):
          steps.add(ShowMessageStep(message: _messageForVolatileEvent(event)));
          switch (event.kind) {
            case BattleVolatileEventKind.protectActivated:
              steps.add(
                BarrierPulseStep(
                  side: event.actorSide,
                  colorArgb: 0xAA95E7B9,
                  durationSeconds: 0.24,
                ),
              );
            case BattleVolatileEventKind.chargeStarted:
              steps.addAll(
                _recipeLibrary.build(
                  BattleMoveVisualRecipeId.chargeUp,
                  BattleMoveVisualRecipeContext(
                    resolvedMove: BattleResolvedMoveVisual(
                      localMoveId: event.sourceMoveId ?? 'charge',
                      sdkMoveId: event.sourceMoveId,
                      recipeId: BattleMoveVisualRecipeId.chargeUp,
                      usesFallback: false,
                      canonicalMove: null,
                    ),
                    battleMove: BattleMove(
                      id: event.sourceMoveId ?? 'charge',
                      name: event.sourceMoveId ?? 'Charge',
                      power: 0,
                    ),
                    execution: null,
                    attackerSide: event.actorSide,
                    targetSide: event.targetSide,
                    damage: null,
                    didHit: false,
                    didCrit: false,
                  ),
                ),
              );
            case BattleVolatileEventKind.rechargeTurnSpent:
              steps.addAll(
                _recipeLibrary.build(
                  BattleMoveVisualRecipeId.rechargePause,
                  BattleMoveVisualRecipeContext(
                    resolvedMove: const BattleResolvedMoveVisual(
                      localMoveId: 'recharge',
                      sdkMoveId: 'recharge',
                      recipeId: BattleMoveVisualRecipeId.rechargePause,
                      usesFallback: false,
                      canonicalMove: null,
                    ),
                    battleMove: const BattleMove(
                      id: 'recharge',
                      name: 'Recharge',
                      power: 0,
                    ),
                    execution: null,
                    attackerSide: event.actorSide,
                    targetSide: event.targetSide,
                    damage: null,
                    didHit: false,
                    didCrit: false,
                  ),
                ),
              );
            default:
              break;
          }
        case BattleTurnFieldEvent(:final event):
          steps.add(ShowMessageStep(message: _messageForFieldEvent(event)));
          switch (event.kind) {
            case BattleFieldEventKind.weatherSet:
              if (event.weather == BattleWeatherId.rain) {
                steps.addAll(
                  _recipeLibrary.build(
                    BattleMoveVisualRecipeId.weatherRain,
                    _fieldRecipeContext(
                      recipeId: BattleMoveVisualRecipeId.weatherRain,
                    ),
                  ),
                );
              } else if (event.weather == BattleWeatherId.sandstorm) {
                steps.addAll(
                  _recipeLibrary.build(
                    BattleMoveVisualRecipeId.weatherSandstorm,
                    _fieldRecipeContext(
                      recipeId: BattleMoveVisualRecipeId.weatherSandstorm,
                    ),
                  ),
                );
              }
            case BattleFieldEventKind.pseudoWeatherSet:
              if (event.pseudoWeather == BattlePseudoWeatherId.trickRoom) {
                steps.addAll(
                  _recipeLibrary.build(
                    BattleMoveVisualRecipeId.pseudoWeatherTrickRoom,
                    _fieldRecipeContext(
                      recipeId: BattleMoveVisualRecipeId.pseudoWeatherTrickRoom,
                    ),
                  ),
                );
              }
            default:
              break;
          }
        case BattleTurnStealthRockEvent(:final event):
          steps.add(
            ShowMessageStep(message: _messageForStealthRockEvent(event)),
          );
          if (event.kind == BattleStealthRockEventKind.set) {
            steps.addAll(
              _recipeLibrary.build(
                BattleMoveVisualRecipeId.setStealthRock,
                _fieldRecipeContext(
                  recipeId: BattleMoveVisualRecipeId.setStealthRock,
                  attackerSide: _oppositeSide(event.side),
                  targetSide: event.side,
                ),
              ),
            );
          } else if (event.kind == BattleStealthRockEventKind.damagedOnEntry &&
              event.targetSlot != null &&
              event.damage != null) {
            final targetSide = event.targetSlot!.side;
            final hpFrom = trackedHp[targetSide] ?? 0;
            final hpTo = (hpFrom - event.damage!).clamp(0, hpFrom);
            trackedHp[targetSide] = hpTo;
            steps.add(
              SpawnFxStep(
                effectId: 'impact',
                attackerSide: _oppositeSide(targetSide),
                defenderSide: targetSide,
                from: BattleVisualAnchor.defenderCenter,
                to: BattleVisualAnchor.defenderCenter,
                durationSeconds: 0.12,
                afterEffect: BattleFxAfterEffect.fade,
              ),
            );
            steps.add(
              HudHpTweenStep(
                side: targetSide,
                fromHp: hpFrom,
                toHp: hpTo,
              ),
            );
            if (hpFrom > 0 && hpTo == 0) {
              if (!replacementRequiredSides.contains(targetSide)) {
                steps.add(
                  FaintCombatantStep(
                    side: targetSide,
                    // BETA-BAT-013 : la chute de la référence est de 0,1 s,
                    // fondu et descente en parallèle.
                    durationSeconds: 0.1,
                  ),
                );
              }
              steps.add(
                ShowMessageStep(
                  message:
                      '${_presentationCombatantName(targetSide, trackedDisplayName)} est K.O. !',
                ),
              );
            }
          }
        case BattleTurnSpikesEvent(:final event):
          steps.add(
            ShowMessageStep(message: _messageForSpikesEvent(event)),
          );
          if (event.kind == BattleSpikesEventKind.setLayer) {
            steps.addAll(
              _recipeLibrary.build(
                BattleMoveVisualRecipeId.setSpikes,
                _fieldRecipeContext(
                  recipeId: BattleMoveVisualRecipeId.setSpikes,
                  attackerSide: _oppositeSide(event.side),
                  targetSide: event.side,
                ),
              ),
            );
          } else if (event.kind == BattleSpikesEventKind.damagedOnEntry &&
              event.targetSlot != null &&
              event.damage != null) {
            final targetSide = event.targetSlot!.side;
            final hpFrom = trackedHp[targetSide] ?? 0;
            final hpTo = (hpFrom - event.damage!).clamp(0, hpFrom);
            trackedHp[targetSide] = hpTo;
            steps.add(
              SpawnFxStep(
                effectId: 'impact',
                attackerSide: _oppositeSide(targetSide),
                defenderSide: targetSide,
                from: BattleVisualAnchor.defenderCenter,
                to: BattleVisualAnchor.defenderCenter,
                durationSeconds: 0.12,
                afterEffect: BattleFxAfterEffect.fade,
              ),
            );
            steps.add(
              HudHpTweenStep(
                side: targetSide,
                fromHp: hpFrom,
                toHp: hpTo,
              ),
            );
            if (hpFrom > 0 && hpTo == 0) {
              if (!replacementRequiredSides.contains(targetSide)) {
                steps.add(
                  FaintCombatantStep(
                    side: targetSide,
                    // BETA-BAT-013 : la chute de la référence est de 0,1 s,
                    // fondu et descente en parallèle.
                    durationSeconds: 0.1,
                  ),
                );
              }
              steps.add(
                ShowMessageStep(
                  message:
                      '${_presentationCombatantName(targetSide, trackedDisplayName)} est K.O. !',
                ),
              );
            }
          }
        case BattleTurnSwitchEvent(:final event):
          steps.add(ShowMessageStep(message: _messageForSwitchEvent(event)));
          if (event.kind == BattleSwitchEventKind.switched) {
            steps.add(
              CombatantMotionStep(
                side: event.side,
                motionKind: BattleCombatantMotionKind.switchOut,
                durationSeconds: 0.16,
              ),
            );
            steps.add(SwapCombatantVisualStep(side: event.side));
            steps.add(
              CombatantMotionStep(
                side: event.side,
                motionKind: BattleCombatantMotionKind.switchIn,
                durationSeconds: 0.16,
              ),
            );
            trackedDisplayName[event.side] =
                speciesDisplayName(event.toSpeciesId!);
          } else {
            steps.add(
              FaintCombatantStep(
                side: event.side,
                durationSeconds: 0.2,
              ),
            );
          }
      }
    }

    return BattleAnimationPlan(
      steps: List<BattleAnimationStep>.unmodifiable(steps),
    );
  }

  BattleMoveVisualRecipeContext _fieldRecipeContext({
    required BattleMoveVisualRecipeId recipeId,
    BattleSideId attackerSide = BattleSideId.player,
    BattleSideId? targetSide,
  }) {
    return BattleMoveVisualRecipeContext(
      resolvedMove: BattleResolvedMoveVisual(
        localMoveId: recipeId.name,
        sdkMoveId: recipeId.name,
        recipeId: recipeId,
        usesFallback: false,
        canonicalMove: null,
      ),
      battleMove: BattleMove(
        id: recipeId.name,
        name: recipeId.name,
        power: 0,
      ),
      execution: null,
      attackerSide: attackerSide,
      targetSide: targetSide,
      damage: null,
      didHit: false,
      didCrit: false,
    );
  }
}

/// BETA-BAT-012 — une victoire en combat SAUVAGE ne s'annonce pas.
///
/// Décision de Yoahn du 2026-08-23, alignée sur la référence : chez PSDK
/// `show_wild_victory` ne fait qu'un changement de musique, l'XP et un message
/// d'argent optionnel. Le texte de victoire est réservé aux combats de dresseur,
/// où il accompagne le retour des sprites.
///
/// Les autres issues gardent leur texte : une défaite, une fuite et une capture
/// ont chacune leur propre annonce dans la référence aussi.
///
/// Ce prédicat est le SEUL : le plan d'animation et le bandeau de l'overlay le
/// consultent tous les deux, faute de quoi l'un pourrait annoncer ce que l'autre
/// taît.
bool battleOutcomeIsAnnounced(
  BattleOutcome outcome, {
  required bool isTrainerBattle,
}) =>
    isTrainerBattle || outcome.type != BattleOutcomeType.victory;

List<BattleAnimationStep> _buildOutcomeSteps(
  BattleOutcome outcome, {
  required bool isTrainerBattle,
  required BattleTurnSpeciesDisplayName speciesDisplayName,
}) {
  if (!battleOutcomeIsAnnounced(outcome, isTrainerBattle: isTrainerBattle)) {
    return const <BattleAnimationStep>[];
  }
  final message = switch (outcome.type) {
    BattleOutcomeType.victory => 'Tu as gagné le combat !',
    BattleOutcomeType.defeat =>
      'Tu n’as plus de Pokémon en état de combattre !',
    BattleOutcomeType.runaway => 'Tu as pris la fuite !',
    BattleOutcomeType.captured =>
      '${speciesDisplayName(outcome.finalState.enemy.speciesId)} est capturé !',
  };
  return <BattleAnimationStep>[ShowMessageStep(message: message)];
}

/// Le message d'efficacité de type, ou `null` quand il n'y a rien à dire.
///
/// La référence ne parle que des cas où le multiplicateur s'écarte de 1 : une
/// efficacité neutre ne produit AUCUN message. Une immunité n'en produit pas
/// non plus ici, parce qu'un coup immunisé n'infligeait aucun dégât et
/// n'atteint donc jamais ce point.
String? _effectivenessMessage(double multiplier) {
  if (multiplier > 1.0) return 'C’est super efficace !';
  if (multiplier > 0.0 && multiplier < 1.0) {
    return 'Ce n’est pas très efficace…';
  }
  return null;
}

/// BETA-BAT-013 — les constantes de la référence pour un coup.
///
/// Le clignotement est de 3 flashs de 0,2 s. La barre de PV descend à 60 PV par
/// seconde, bornée en bas comme en haut : un petit dégât ne doit pas être
/// invisible, un gros ne doit pas immobiliser le tour.
const double _damageBlinkSeconds = 0.6;
const double _hpDrainRatePerSecond = 60;
const double _hpDrainMinimumSeconds = 0.2;
const double _hpDrainMaximumSeconds = 1.0;

double _hpDrainSeconds(int damage) {
  if (damage <= 0) {
    // Un coup sans dégât consomme quand même une seconde pleine chez PSDK :
    // le joueur voit qu'il s'est passé quelque chose, et le clignotement joue.
    return _hpDrainMaximumSeconds;
  }
  return (damage / _hpDrainRatePerSecond)
      .clamp(_hpDrainMinimumSeconds, _hpDrainMaximumSeconds);
}

double _postDrainHoldSeconds({
  required double drainSeconds,
  required bool faints,
}) {
  if (faints) return 0.1;
  return (1.0 - drainSeconds).clamp(0.25, 1.0);
}

String _presentationCombatantLabel(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}

String _presentationCombatantName(
  BattleSideId side,
  Map<BattleSideId, String> displayNameBySide,
) {
  return displayNameBySide[side] ?? _presentationCombatantLabel(side);
}

String _messageForStatusEvent(BattleStatusEvent event) {
  return switch (event.kind) {
    BattleStatusEventKind.applied =>
      '${_presentationCombatantLabel(event.targetSide)} subit ${event.status.name.toUpperCase()} !',
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '${_presentationCombatantLabel(event.targetSide)} a déjà un statut majeur.',
    BattleStatusEventKind.preventedAction =>
      '${_presentationCombatantLabel(event.targetSide)} ne peut pas agir !',
    BattleStatusEventKind.residualDamage =>
      '${_presentationCombatantLabel(event.targetSide)} subit des dégâts de ${event.status.name.toUpperCase()} !',
  };
}

String _messageForVolatileEvent(BattleVolatileEvent event) {
  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated =>
      '${_presentationCombatantLabel(event.actorSide)} se protège !',
    BattleVolatileEventKind.protectBlocked =>
      'L’attaque est bloquée par Protect !',
    BattleVolatileEventKind.protectBroken => 'La protection est brisée !',
    BattleVolatileEventKind.rechargeRequired =>
      '${_presentationCombatantLabel(event.actorSide)} doit se recharger !',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '${_presentationCombatantLabel(event.actorSide)} récupère son souffle.',
    BattleVolatileEventKind.chargeStarted =>
      '${_presentationCombatantLabel(event.actorSide)} se charge !',
    BattleVolatileEventKind.chargeReleased =>
      '${_presentationCombatantLabel(event.actorSide)} libère son attaque !',
  };
}

String _messageForFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet => event.weather == BattleWeatherId.rain
        ? 'La pluie commence à tomber.'
        : 'Une tempête de sable se lève.',
    BattleFieldEventKind.weatherResidualDamage =>
      'La météo inflige des dégâts.',
    BattleFieldEventKind.weatherExpired => 'La météo se dissipe.',
    BattleFieldEventKind.pseudoWeatherSet => 'L’espace se tord bizarrement.',
    BattleFieldEventKind.pseudoWeatherCleared =>
      'Le pseudo-climat de champ disparaît.',
    BattleFieldEventKind.pseudoWeatherExpired => 'L’effet de champ prend fin.',
  };
}

String _messageForStealthRockEvent(BattleStealthRockEvent event) {
  return switch (event.kind) {
    BattleStealthRockEventKind.set =>
      'Des pièges de roc entourent le camp adverse !',
    BattleStealthRockEventKind.alreadyPresent =>
      'Les pièges de roc sont déjà en place.',
    BattleStealthRockEventKind.damagedOnEntry =>
      'Les pièges de roc blessent le Pokémon entrant !',
  };
}

String _messageForSpikesEvent(BattleSpikesEvent event) {
  return switch (event.kind) {
    BattleSpikesEventKind.setLayer =>
      'Des picots se dispersent sur le terrain adverse !',
    BattleSpikesEventKind.alreadyAtMaxLayers =>
      'Les picots sont déjà au maximum.',
    BattleSpikesEventKind.damagedOnEntry =>
      'Les picots blessent le Pokémon entrant !',
  };
}

String _messageForSwitchEvent(BattleSwitchEvent event) {
  return switch (event.kind) {
    BattleSwitchEventKind.switched =>
      '${_presentationCombatantLabel(event.side)} rappelle ${event.fromSpeciesId} et envoie ${event.toSpeciesId} !',
    BattleSwitchEventKind.replacementRequired =>
      '${_presentationCombatantLabel(event.side)} doit remplacer ${event.fromSpeciesId} !',
  };
}

BattleSideId _oppositeSide(BattleSideId side) {
  return side == BattleSideId.player ? BattleSideId.enemy : BattleSideId.player;
}
