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
    this.announcesOutcome = true,
  }) : _recipeLibrary = recipeLibrary ?? BattleMoveVisualRecipeLibrary();

  /// Ce plan annonce-t-il lui-même l'issue du combat ?
  ///
  /// BETA-BAT-030 : quand l'hôte présente la fin de combat DANS la scène
  /// (BETA-BAT-017), il joue déjà les messages du coordinator — « Vous avez
  /// pris la fuite. », « Victoire ! »… Le plan de tour qui annonçait AUSSI
  /// l'issue faisait donc dire deux fois la même chose : la recette du
  /// 2026-08-24 montre trois annonces successives pour une seule fuite.
  ///
  /// Le SON de la fuite reste attaché ici : c'est un accent du tour, pas une
  /// annonce.
  final bool announcesOutcome;

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
            announcesOutcome: announcesOutcome,
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
          announcesOutcome: announcesOutcome,
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
          // Recette du 2026-08-24 : un dégât `effect:*` n'est pas l'usage
          // d'une attaque — « X utilise effect:confusion ! » mentait au
          // joueur. La confusion a son texte de parité ; les autres procs
          // d'effet laissent parler la barre de PV plutôt que d'inventer un
          // faux message d'usage.
          final isEffectProc = execution.move.id.startsWith('effect:');
          if (isEffectProc) {
            if (execution.move.id == 'effect:confusion') {
              steps.add(
                const ShowMessageStep(
                  message: 'Il se blesse dans sa confusion.',
                ),
              );
            }
          } else {
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
            // DÉGÂT, pas une étape de la chorégraphie du coup. Chez PSDK il
            // vit dans `show_hp_animations`, pilote par le gestionnaire de
            // dégâts, et part sur la même frame que la barre de PV.
            //
            // La recette garde le droit de déclarer QUE la cible clignote ;
            // c'est le planner qui décide QUAND, parce que lui seul connaît le
            // dégât. L'alternative aurait été de retirer l'étape des 112
            // recettes qui l'émettent, pour le même résultat et un diff sans
            // rapport avec le sujet.
            final targetSideForFlash = execution.targetSide;
            if (targetSideForFlash != null) {
              recipeSteps.removeWhere(
                (step) =>
                    step is CombatantFlashStep &&
                    step.side == targetSideForFlash,
              );
            }
            steps.addAll(recipeSteps);
          }
          // Recette du 2026-08-24 : une attaque qui rate se dit — la
          // référence affiche « [cible] évite l'attaque ! » et ne joue ni
          // impact ni barre.
          if (!execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null) {
            steps.add(
              ShowMessageStep(
                message:
                    '${_presentationCombatantName(execution.targetSide!, trackedDisplayName)} évite l’attaque !',
              ),
            );
          }
          if (execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null &&
              execution.typeEffectivenessMultiplier == 0.0) {
            // Recette du 2026-08-24 : une immunité se dit aussi — « Ça
            // n'affecte pas X… », sans son d'impact, sans clignotement et
            // sans barre : le coup n'a rien touché.
            steps.add(
              ShowMessageStep(
                message:
                    'Ça n’affecte pas ${_presentationCombatantName(execution.targetSide!, trackedDisplayName)}…',
              ),
            );
          } else if (execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null &&
              // Un move de statut (puissance nulle, aucun dégât) ne joue pas
              // le bloc d'impact : la référence n'a ni son de coup ni
              // clignotement pour Doux Baiser. Un move OFFENSIF encaissé à 0
              // dégât garde son clignotement d'une seconde (BETA-BAT-013).
              (execution.damage > 0 || execution.move.power > 0)) {
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
                  // BETA-BAT-014 : le son du coup part sur la même frame que le
                  // clignotement et la descente des PV — les trois sont les
                  // entrées du même handler parallèle chez la référence, et le
                  // son est choisi par l'efficacité.
                  PlaySeStep(
                    seName: _hitSeName(execution.typeEffectivenessMultiplier),
                  ),
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
              // BETA-BAT-014 : le son de K.O. de la référence — `down`, volume
              // 100, pitch 80, joué une fois avant que la chute ne démarre.
              steps.add(const PlaySeStep(seName: 'down', pitch: 80));
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
          // BETA-BAT-025 : la capture passe par la vraie Poké Ball — le
          // lancer, l'absorption du sauvage, la chute à rebonds, les
          // secousses de la BALL et le verdict (clic ou éclatement), la
          // séquence exacte de la référence.
          //
          // ENC-005 : la séquence rejoue le nombre de secousses décidé par
          // la formule, elle ne le recalcule jamais. Au plus trois sont
          // jouées — la quatrième « secousse » d'une capture est le clic de
          // verrouillage, porté par le verdict. Le suspense reste couvert
          // par reduced motion via le motionScale global de l'overlay.
          steps.add(
            PlayBallCaptureSequenceStep(
              shakes: event.shakes.clamp(0, 3),
              caught: event.caught,
            ),
          );
          steps.add(
            ShowMessageStep(
              message: event.caught
                  ? '$targetName est capturé !'
                  : '$targetName s’échappe de la Poké Ball !',
            ),
          );
        case BattleTurnStatusEvent(:final event):
          steps.add(
            ShowMessageStep(
              message: _messageForStatusEvent(event, trackedDisplayName),
            ),
          );
        case BattleTurnVolatileEvent(:final event):
          steps.add(
            ShowMessageStep(
              message: _messageForVolatileEvent(event, trackedDisplayName),
            ),
          );
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
            // BETA-BAT-022 : le remplacement passe par la Poké Ball, comme
            // la référence — rappel (la Ball s'ouvre, le Pokémon rétrécit),
            // échange du visuel, nouvelle Ball posée puis le remplaçant
            // grandit. Sans planche chargeable côté overlay, les étapes
            // Ball ne montrent rien et les durées s'écoulent : le
            // remplacement reste lisible.
            steps.add(
              PlayBallSequenceStep(
                side: event.side,
                kind: BattleBallSequenceKind.recall,
              ),
            );
            steps.add(
              CombatantMotionStep(
                side: event.side,
                motionKind: BattleCombatantMotionKind.materializeOut,
                durationSeconds: 0.1,
              ),
            );
            steps.add(SwapCombatantVisualStep(side: event.side));
            steps.add(
              PlayBallSequenceStep(
                side: event.side,
                kind: BattleBallSequenceKind.sendOutHeld,
              ),
            );
            steps.add(
              CombatantMotionStep(
                side: event.side,
                motionKind: BattleCombatantMotionKind.materializeIn,
                durationSeconds: 0.1,
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
        case BattleTurnStatStageEvent():
          // BETA-BAT-021 : le message se dit TOUJOURS (même un refus :
          // « ne peut plus baisser ! »), l'aura ne joue que sur un
          // changement réellement appliqué — la référence n'appelle
          // `show_stat_animation` que dans ce cas.
          if (event.amount != 0) {
            steps.add(
              StatStageAuraStep(
                side: event.side,
                isRise: event.amount > 0,
              ),
            );
          }
          steps.add(
            ShowMessageStep(
              message: _messageForStatStageEvent(event, trackedDisplayName),
            ),
          );
        case BattleTurnFleeFailedEvent():
          // Recette du 2026-08-24 : sans ce texte, l'adversaire attaquait
          // après une fuite ratée sans que le joueur sache pourquoi.
          steps.add(
            const ShowMessageStep(
              message: 'Vous n’avez pas réussi à fuir.',
            ),
          );
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
  bool announcesOutcome = true,
}) {
  // Le SON de la fuite part même quand l'annonce revient à l'hôte : c'est un
  // accent du tour (`escape` de la référence), pas un message.
  final fleeSe = outcome.type == BattleOutcomeType.runaway
      ? const <BattleAnimationStep>[
          PlaySeStep(seName: 'flee', volume: 80, pitch: 70),
        ]
      : const <BattleAnimationStep>[];
  if (!announcesOutcome) {
    return fleeSe;
  }
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
  return <BattleAnimationStep>[
    // Recette du 2026-08-24 : la fuite a son propre son chez la référence —
    // `escape` (fleee.wav), volume 80, pitch 70 — joué avec l'annonce.
    ...fleeSe,
    ShowMessageStep(message: message),
  ];
}

/// Le message d'efficacité de type, ou `null` quand il n'y a rien à dire.
///
/// La référence ne parle que des cas où le multiplicateur s'écarte de 1 : une
/// efficacité neutre ne produit AUCUN message. Une immunité n'en produit pas
/// non plus ici : elle prend sa branche dédiée « Ça n'affecte pas X… » en
/// amont et le bloc d'impact ne joue jamais à multiplicateur nul.
/// Le son du coup selon l'efficacité, comme la référence le choisit :
/// `hit` pour un coup neutre, `hitplus` quand ça porte, `hitlow` quand ça
/// glisse. La référence n'a AUCUN son de coup critique — le critique est un
/// texte seul.
String _hitSeName(double multiplier) {
  if (multiplier > 1.0) return 'hitplus';
  if (multiplier > 0.0 && multiplier < 1.0) return 'hitlow';
  return 'hit';
}

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

/// Les textes de changement d'étage de la référence — BETA-BAT-021.
///
/// Parité Data/Text/Dialogs 100019 : le nom de la stat est genré en français
/// (« L'Attaque … augmente ! », « La Défense … baisse ! »), et l'ampleur suit
/// le nombre d'étages : 1 « augmente/baisse », 2 « beaucoup », 3 et plus
/// « énormément ». Un changement refusé dit « ne peut plus … ».
String _messageForStatStageEvent(
  BattleTurnStatStageEvent event,
  Map<BattleSideId, String> displayNameBySide,
) {
  final target = _presentationCombatantName(event.side, displayNameBySide);
  final label = switch (event.stat) {
    BattleStatId.attack => 'L’Attaque',
    BattleStatId.defense => 'La Défense',
    BattleStatId.specialAttack => 'L’Attaque Spéciale',
    BattleStatId.specialDefense => 'La Défense Spéciale',
    BattleStatId.speed => 'La Vitesse',
    BattleStatId.accuracy => 'La Précision',
    BattleStatId.evasion => 'L’Esquive',
  };
  if (event.amount == 0) {
    // Le sens du refus se lit sur l'étage atteint : au plafond on ne peut
    // plus monter, au plancher on ne peut plus descendre.
    return event.currentStage > 0
        ? '$label de $target ne peut plus augmenter !'
        : '$label de $target ne peut plus baisser !';
  }
  final magnitude = switch (event.amount.abs()) {
    1 => '',
    2 => ' beaucoup',
    _ => ' énormément',
  };
  final verb = event.amount > 0 ? 'augmente' : 'baisse';
  return '$label de $target $verb$magnitude !';
}

String _messageForStatusEvent(
  BattleStatusEvent event,
  Map<BattleSideId, String> displayNameBySide,
) {
  final target = _presentationCombatantName(event.targetSide, displayNameBySide);
  return switch (event.kind) {
    // Recette du 2026-08-24 : les textes d'application suivent la référence
    // (« [X] est empoisonné ! »), avec le nom affichable du Pokémon plutôt
    // qu'un « Joueur subit PSN ! » technique.
    BattleStatusEventKind.applied => switch (event.status) {
        BattleMajorStatusId.par =>
          '$target est paralysé ! Il aura du mal à attaquer !',
        BattleMajorStatusId.brn => '$target est brûlé !',
        BattleMajorStatusId.psn => '$target est empoisonné !',
        BattleMajorStatusId.tox => '$target est gravement empoisonné !',
        BattleMajorStatusId.slp => '$target s’est endormi !',
        BattleMajorStatusId.frz => '$target est gelé !',
      },
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '$target a déjà un statut majeur.',
    BattleStatusEventKind.preventedAction => '$target ne peut pas agir !',
    BattleStatusEventKind.residualDamage => switch (event.status) {
        BattleMajorStatusId.brn => '$target souffre de sa brûlure !',
        BattleMajorStatusId.psn ||
        BattleMajorStatusId.tox =>
          '$target souffre du poison !',
        _ => '$target subit des dégâts !',
      },
  };
}

String _messageForVolatileEvent(
  BattleVolatileEvent event,
  Map<BattleSideId, String> displayNameBySide,
) {
  final actor = _presentationCombatantName(event.actorSide, displayNameBySide);
  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated => '$actor se protège !',
    BattleVolatileEventKind.protectBlocked =>
      'L’attaque est bloquée par Protect !',
    BattleVolatileEventKind.protectBroken => 'La protection est brisée !',
    BattleVolatileEventKind.rechargeRequired => '$actor doit se recharger !',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '$actor récupère son souffle.',
    BattleVolatileEventKind.chargeStarted => '$actor se charge !',
    BattleVolatileEventKind.chargeReleased => '$actor libère son attaque !',
    // Recette du 2026-08-24 : les trois temps de la confusion, aux textes de
    // la référence.
    BattleVolatileEventKind.confusionApplied => 'Ça rend $actor confus !',
    BattleVolatileEventKind.confusionActive => '$actor est confus !',
    BattleVolatileEventKind.confusionEnded => '$actor n’est plus confus !',
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
