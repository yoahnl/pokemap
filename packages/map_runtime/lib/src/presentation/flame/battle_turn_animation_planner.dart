import 'package:map_battle/map_battle.dart';

import '../../application/runtime_move_catalog_loader.dart';
import 'battle_animation_plan.dart';
import 'battle_move_visual_catalog.dart';
import 'battle_move_visual_recipe_library.dart';
import 'battle_move_visual_resolver.dart';

final class BattleTurnAnimationPlanner {
  BattleTurnAnimationPlanner({
    BattleMoveVisualRecipeLibrary? recipeLibrary,
  }) : _recipeLibrary = recipeLibrary ?? BattleMoveVisualRecipeLibrary();

  final BattleMoveVisualRecipeLibrary _recipeLibrary;

  BattleAnimationPlan build({
    required BattleSession previousSession,
    required BattleSession newSession,
    required RuntimeMoveCatalog moveCatalog,
    required BattleMoveVisualResolver resolver,
  }) {
    final turnResult = newSession.state.currentTurn;
    if (turnResult == null) {
      return const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
    }
    return buildForTurn(
      playerBefore: previousSession.state.player,
      enemyBefore: previousSession.state.enemy,
      turnResult: turnResult,
      moveCatalog: moveCatalog,
      resolver: resolver,
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
    final steps = <BattleAnimationStep>[];

    for (final event in turnResult.timeline) {
      switch (event) {
        case BattleTurnExecutionEvent(:final execution):
          steps.add(
            ShowMessageStep(
              message:
                  '${_presentationCombatantLabel(execution.attackerSide)} utilise ${execution.move.name} !',
            ),
          );
          final resolvedMove = resolver.resolve(execution.move);
          steps.addAll(
            _recipeLibrary.build(
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
            ),
          );
          if (execution.didHit &&
              execution.damage > 0 &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null) {
            final targetSide = execution.targetSide!;
            final hpFrom = trackedHp[targetSide] ?? 0;
            final hpTo = (hpFrom - execution.damage).clamp(0, hpFrom);
            trackedHp[targetSide] = hpTo;
            steps.add(
              HudHpTweenStep(
                side: targetSide,
                fromHp: hpFrom,
                toHp: hpTo,
              ),
            );
          }
        case BattleTurnBagHpHealItemEvent(:final event):
          steps.add(
            ShowMessageStep(
              message:
                  '${_presentationCombatantLabel(event.side)} utilise ${event.itemKind.label} sur ${event.targetSpeciesId} !',
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
                  '${event.targetSpeciesId} récupère ${event.healedAmount} PV.',
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
                      showdownMoveId: event.sourceMoveId,
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
                    resolvedMove: BattleResolvedMoveVisual(
                      localMoveId: 'recharge',
                      showdownMoveId: 'recharge',
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
        showdownMoveId: recipeId.name,
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

String _presentationCombatantLabel(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
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
