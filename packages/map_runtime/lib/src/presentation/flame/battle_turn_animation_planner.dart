import 'dart:async';
import 'dart:collection';

import 'package:map_battle/map_battle.dart';

import '../../application/runtime_move_catalog_loader.dart';
import '../runtime_battle_message.dart';
import 'battle_animation_plan.dart';
import 'battle_move_audio_scope.dart';
import 'battle_move_recipe_compiler.dart';
import 'battle_move_visual_catalog.dart';
import 'battle_move_visual_recipe_library.dart';
import 'battle_move_visual_resolver.dart';
import 'battle_recipe_audio_program.dart';
import 'battle_turn_messages.dart';

final class BattleTurnAudioCancelled implements Exception {
  const BattleTurnAudioCancelled();
}

void _cancelUnclaimedTurnAudio(Iterable<BattleTurnAudioSelection> selections) {
  final seen = HashSet<BattlePreparedRecipeAudio>.identity();
  for (final selection in selections) {
    final program = selection.audio.program;
    if (program != null && program.canClaim && seen.add(program)) {
      unawaited(program.cancel().then<void>((_) {}, onError: (Object _) {}));
    }
  }
}

void _cancelTurnAudioScopes(Iterable<BattleAnimationAudioScope> scopes) {
  for (final scope in scopes) {
    unawaited(scope.cancel().then<void>((_) {}, onError: (Object _) {}));
  }
}

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

bool _containsCameraStep(BattleAnimationStep step) {
  return step is CameraFocusStep ||
      step is BattleCameraMoveStep ||
      (step is AnimationGroupStep && step.steps.any(_containsCameraStep));
}

List<BattleAnimationStep>? _silentMoveFallback(
  List<BattleAnimationStep> steps,
) {
  final silent = <BattleAnimationStep>[];
  for (final step in steps) {
    switch (step) {
      case PlaySeStep():
        break;
      case PlayRmxpAnimationStep():
        silent.add(WaitStep(durationSeconds: step.totalDurationSeconds));
      case AnimationGroupStep(:final mode, :final steps):
        final children = _silentMoveFallback(steps);
        if (children == null) return null;
        if (children.isNotEmpty) {
          silent.add(AnimationGroupStep(mode: mode, steps: children));
        }
      case WaitStep() ||
          SpawnFxStep() ||
          ScreenFlashStep() ||
          SceneTintStep() ||
          PlaySpriteSheetFxStep() ||
          SpriteSheetOnCombatantStep() ||
          ParticleBurstStep() ||
          PlaySdkParticleSequenceStep() ||
          SdkFallingParticlesStep() ||
          SdkRadiusParticleStep() ||
          SdkScalarParticleStep() ||
          SdkParticleZoomStep() ||
          WeatherParticleStep() ||
          CombatantMotionStep() ||
          CombatantFlashStep() ||
          CombatantShakeStep() ||
          CombatantToneStep() ||
          CombatantCompressStep() ||
          CombatantEllipseStep() ||
          CameraFocusStep() ||
          BattleCameraMoveStep() ||
          BattleCameraResetStep() ||
          BarrierPulseStep():
        silent.add(step);
      default:
        return null;
    }
  }
  return List.unmodifiable(silent);
}

BattleAnimationStep _resolveCameraFocusStep(
  BattleAnimationStep step,
  BattleMoveExecution execution,
) {
  if (step is AnimationGroupStep) {
    return AnimationGroupStep(
      mode: step.mode,
      steps: step.steps
          .map((child) => _resolveCameraFocusStep(child, execution))
          .toList(growable: false),
    );
  }
  if (step is! CameraFocusStep ||
      step.side != null ||
      step.target == BattleCameraFocusTarget.scene) {
    return step;
  }
  final slot = step.target == BattleCameraFocusTarget.user
      ? execution.attackerSlot
      : execution.targetSlot ?? execution.attackerSlot;
  return CameraFocusStep(
    target: step.target,
    side: slot.side,
    slotIndex: slot.slotIndex,
    durationSeconds: step.durationSeconds,
  );
}

bool itemHealingAnnouncesStatusCure(
  BattleTurnEvent? previous,
  BattleTurnStatusCuredItemEvent cure,
) {
  if (previous is! BattleTurnBagHpHealItemEvent) return false;
  final healing = previous.event;
  return healing.itemId == cure.itemId &&
      healing.side == cure.side &&
      healing.targetLineupIndex == cure.targetLineupIndex;
}

final class BattleTurnAnimationPlanner {
  BattleTurnAnimationPlanner({
    BattleMoveVisualRecipeLibrary? recipeLibrary,
    Map<String, PreparedBattleMoveRecipe> importedRecipes = const {},
    List<BattleAnimationStep> Function(
      BattleMoveVisualRecipeId,
      BattleMoveVisualRecipeContext,
    )? recipeBuilder,
    this.speciesDisplayName = _rawSpeciesName,
    this.resolveCombatantDisplayName,
    RuntimeBattleMessageRenderer? formatBattleMessage,
    this.moveDisplayName = _rawMoveName,
    this.announcesOutcome = true,
    this.resolveCombatantBallItemId,
  }) : _importedRecipes = Map.unmodifiable(importedRecipes),
       _messages = BattleTurnMessages(formatBattleMessage),
       _buildRecipe =
           recipeBuilder ??
           (recipeLibrary ?? BattleMoveVisualRecipeLibrary()).build;

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
  final Map<String, PreparedBattleMoveRecipe> _importedRecipes;
  final String? Function(BattleSideId side, int lineupIndex)?
      resolveCombatantBallItemId;

  final List<BattleAnimationStep> Function(
    BattleMoveVisualRecipeId,
    BattleMoveVisualRecipeContext,
  ) _buildRecipe;

  /// BETA-BAT-011 : le journal parle la langue du joueur.
  ///
  /// Les deux résolveurs existent depuis longtemps et alimentent déjà le HUD et
  /// le menu de commandes ; le plan d'animation les contournait, donc le joueur
  /// lisait « machop utilise Low Kick ! » à côté d'un HUD disant « Machoc » et
  /// d'un menu disant « Tornade ». Ils sont injectés, avec un défaut qui rend
  /// l'identifiant : un appelant qui n'en fournit pas garde exactement l'ancien
  /// texte.
  final BattleTurnSpeciesDisplayName speciesDisplayName;
  final String Function(BattleSideId side, BattleCombatant combatant)?
  resolveCombatantDisplayName;
  final BattleTurnMessages _messages;

  String _combatantName(BattleSideId side, BattleCombatant combatant) =>
      resolveCombatantDisplayName?.call(side, combatant) ??
      speciesDisplayName(combatant.speciesId);
  final BattleTurnMoveDisplayName moveDisplayName;

  BattleAnimationPlan build({
    required BattleSession previousSession,
    required BattleSession newSession,
    required RuntimeMoveCatalog moveCatalog,
    required BattleMoveVisualResolver resolver,
    Map<BattleSlotRef, BattleCombatant>? combatantsBefore,
    Map<BattleSlotRef, BattleCombatant>? combatantsAfter,
    Map<String, PreparedBattleMoveRecipe>? importedRecipes,
    List<BattleTurnAudioSelection> audioSelections = const [],
    Map<BattleTurnExecutionEvent, String> experimentalSourceEffects = const {},
  }) {
    final turnResult = newSession.state.currentTurn;
    if (turnResult == null) {
      if (audioSelections.isNotEmpty || experimentalSourceEffects.isNotEmpty) {
        _cancelUnclaimedTurnAudio(audioSelections);
        throw StateError('Presentation selection has no battle turn');
      }
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
            messages: _messages,
            announcesOutcome: announcesOutcome,
          ),
        ),
      );
    }
    final plan = buildForTurn(
      playerBefore: previousSession.state.player,
      enemyBefore: previousSession.state.enemy,
      playerAfter: newSession.state.player,
      enemyAfter: newSession.state.enemy,
      turnResult: turnResult,
      combatantsBefore: combatantsBefore,
      combatantsAfter: combatantsAfter,
      partyHpBefore: {
        for (final combatant in [previousSession.state.player, ...previousSession.state.playerReserve])
          (BattleSideId.player, combatant.lineupIndex): combatant.currentHp,
        for (final combatant in [previousSession.state.enemy, ...previousSession.state.enemyReserve])
          (BattleSideId.enemy, combatant.lineupIndex): combatant.currentHp,
        for (final entry in (combatantsBefore ?? <BattleSlotRef, BattleCombatant>{}).entries)
          (entry.key.side, entry.value.lineupIndex): entry.value.currentHp,
      },
      moveCatalog: moveCatalog,
      resolver: resolver,
      importedRecipes: importedRecipes,
      audioSelections: audioSelections,
      experimentalSourceEffects: experimentalSourceEffects,
    );
    final outcome = newSession.state.outcome;
    if (!newSession.state.isFinished || outcome == null) {
      return plan;
    }
    try {
      return BattleAnimationPlan(
        steps: List<BattleAnimationStep>.unmodifiable(<BattleAnimationStep>[
          ...plan.steps,
          ..._buildOutcomeSteps(
            outcome,
            isTrainerBattle: newSession.setup.isTrainerBattle,
            speciesDisplayName: speciesDisplayName,
            messages: _messages,
            announcesOutcome: announcesOutcome,
          ),
        ]),
        audioScopes: plan.audioScopes,
      );
    } catch (_) {
      _cancelTurnAudioScopes(plan.audioScopes);
      rethrow;
    }
  }

  BattleAnimationPlan buildForTurn({
    required BattleCombatant playerBefore,
    required BattleCombatant enemyBefore,
    BattleCombatant? playerAfter,
    BattleCombatant? enemyAfter,
    required BattleTurnResult turnResult,
    required RuntimeMoveCatalog moveCatalog,
    required BattleMoveVisualResolver resolver,
    Map<BattleSlotRef, BattleCombatant>? combatantsBefore,
    Map<BattleSlotRef, BattleCombatant>? combatantsAfter,
    Map<(BattleSideId, int), int>? partyHpBefore,
    Map<String, PreparedBattleMoveRecipe>? importedRecipes,
    List<BattleTurnAudioSelection> audioSelections = const [],
    Map<BattleTurnExecutionEvent, String> experimentalSourceEffects = const {},
  }) {
    final selectedAudio =
        HashMap<BattleTurnExecutionEvent, BattleTurnAudioSelection>.identity();
    final programs = HashSet<BattlePreparedRecipeAudio>.identity();
    try {
      if (audioSelections.length > 16) {
        throw StateError('Too many audio selections');
      }
      if (experimentalSourceEffects.length > 16 ||
          experimentalSourceEffects.entries.any((entry) =>
              entry.value.isEmpty ||
              entry.key.execution.move.id.startsWith('effect:') ||
              turnResult.timeline.where((event) => identical(event, entry.key)).length != 1 ||
              audioSelections.any((selection) => identical(selection.event, entry.key)))) {
        throw StateError('Invalid experimental source effects');
      }
      for (final selection in audioSelections) {
        final event = selection.event;
        if (turnResult.timeline.where((item) => identical(item, event)).length !=
                1 ||
            event.execution.move.id.startsWith('effect:') ||
            selectedAudio.containsKey(event)) {
          throw StateError('Audio selection does not match one attack');
        }
        if (selection.audio.status == BattleRecipeAudioStatus.cancelled) {
          throw const BattleTurnAudioCancelled();
        }
        final program = selection.audio.program;
        if (program != null && (!program.canClaim || !programs.add(program))) {
          throw StateError('Audio program is already in use');
        }
        selectedAudio[event] = selection;
      }
    } catch (_) {
      _cancelUnclaimedTurnAudio(audioSelections);
      rethrow;
    }
    final audioScopes = <BattleAnimationAudioScope>[];
    try {
      return _buildTurnPlan(
        playerBefore: playerBefore,
        enemyBefore: enemyBefore,
        playerAfter: playerAfter,
        enemyAfter: enemyAfter,
        turnResult: turnResult,
        moveCatalog: moveCatalog,
        resolver: resolver,
        combatantsBefore: combatantsBefore,
        combatantsAfter: combatantsAfter,
        partyHpBefore: partyHpBefore,
        importedRecipes: importedRecipes,
        selectedAudio: selectedAudio,
        experimentalSourceEffects: experimentalSourceEffects,
        audioScopes: audioScopes,
      );
    } catch (_) {
      _cancelTurnAudioScopes(audioScopes);
      _cancelUnclaimedTurnAudio(audioSelections);
      rethrow;
    }
  }

  BattleAnimationPlan _buildTurnPlan({
    required BattleCombatant playerBefore,
    required BattleCombatant enemyBefore,
    required BattleCombatant? playerAfter,
    required BattleCombatant? enemyAfter,
    required BattleTurnResult turnResult,
    required RuntimeMoveCatalog moveCatalog,
    required BattleMoveVisualResolver resolver,
    required Map<BattleSlotRef, BattleCombatant>? combatantsBefore,
    required Map<BattleSlotRef, BattleCombatant>? combatantsAfter,
    required Map<(BattleSideId, int), int>? partyHpBefore,
    required Map<String, PreparedBattleMoveRecipe>? importedRecipes,
    required Map<BattleTurnExecutionEvent, BattleTurnAudioSelection>
        selectedAudio,
    required Map<BattleTurnExecutionEvent, String> experimentalSourceEffects,
    required List<BattleAnimationAudioScope> audioScopes,
  }) {
    final before = combatantsBefore ?? {
      const BattleSlotRef.active(BattleSideId.player): playerBefore,
      const BattleSlotRef.active(BattleSideId.enemy): enemyBefore,
    };
    final after = combatantsAfter ?? {
      const BattleSlotRef.active(BattleSideId.player): ?playerAfter,
      const BattleSlotRef.active(BattleSideId.enemy): ?enemyAfter,
    };
    final trackedHp = <BattleSlotRef, int>{
      for (final entry in before.entries) entry.key: entry.value.currentHp,
    };
    final trackedLineup = {
      for (final entry in before.entries) entry.key: entry.value.lineupIndex,
    };
    final trackedPartyHp = <(BattleSideId, int), int>{
      ...?partyHpBefore,
      for (final entry in before.entries)
        (entry.key.side, entry.value.lineupIndex): entry.value.currentHp,
    };
    final trackedDisplayName = <BattleSlotRef, String>{
      for (final entry in before.entries)
        entry.key: _combatantName(entry.key.side, entry.value),
    };
    String nameForSlot(BattleSlotRef slot) =>
        trackedDisplayName[slot] ?? _messages.sideLabel(slot.side);
    BattleSlotRef? slotForLineup(BattleSideId side, int lineupIndex) =>
        trackedLineup.entries
            .where(
              (entry) => entry.key.side == side && entry.value == lineupIndex,
            )
            .firstOrNull
            ?.key;
    String itemTargetName(
      BattleSideId side,
      int lineupIndex,
      String speciesId,
    ) =>
        trackedDisplayName[slotForLineup(side, lineupIndex)] ??
        speciesDisplayName(speciesId);

    final replacementRequiredSides = turnResult.timeline
        .whereType<BattleTurnSwitchEvent>()
        .map((event) => event.event)
        .where(
            (event) => event.kind == BattleSwitchEventKind.replacementRequired)
        .map((event) => event.slot)
        .toSet();
    final steps = <BattleAnimationStep>[];

    for (var index = 0; index < turnResult.timeline.length; index++) {
      final event = turnResult.timeline[index];
      final previous = index == 0 ? null : turnResult.timeline[index - 1];
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
                _messages.show(
                  const RuntimeBattleMessage(
                    RuntimeBattleMessageId.confusionHurt,
                    'Il se blesse dans sa confusion.',
                  ),
                ),
              );
            }
          } else {
            steps.add(
              _messages.moveUsed(
                nameForSlot(execution.attackerSlot),
                moveDisplayName(execution.move.id, execution.move.name),
                damage:
                    execution.didHit &&
                        execution.targetKind ==
                            BattleMoveExecutionTargetKind.combatant
                    ? execution.damage
                    : 0,
              ),
            );
            final resolvedMove = resolver.resolve(execution.move);
            List<BattleAnimationStep> legacySteps() => _buildRecipe(
              resolvedMove.recipeId,
              BattleMoveVisualRecipeContext(
                resolvedMove: resolvedMove,
                battleMove: execution.move,
                execution: execution,
                attackerSide: execution.attackerSide,
                targetSide: execution.targetSide,
                attackerSlotIndex: execution.attackerSlot.slotIndex,
                targetSlotIndex: execution.targetSlot?.slotIndex ?? 0,
                damage: execution.damage,
                didHit: execution.didHit,
                didCrit: execution.didCrit,
              ),
            ).toList();
            final imported = (importedRecipes ?? _importedRecipes)[execution.move.id];
            List<BattleAnimationStep> recipeSteps;
            if (imported == null ||
                imported.projectMoveId != execution.move.id) {
              recipeSteps = legacySteps();
            } else {
              const compiler = BattleMoveRecipeCompiler();
              final complete = BattleMoveRecipeCompiler.supportsCompleteMoveVisuals;
              BattleAnimationPlan? compiled;
              try {
                if (complete) {
                  compiled = compiler.compile(
                    imported,
                    user: execution.attackerSlot,
                    target: execution.targetSlot,
                  );
                } else {
                  compiled = compiler.compileSupplemental(
                    imported,
                    user: execution.attackerSlot,
                    target: execution.targetSlot,
                  );
                }
              } on FormatException {
                compiled = null;
              }
              if (compiled == null) {
                recipeSteps = legacySteps();
              } else if (complete) {
                recipeSteps = compiled.steps.toList();
              } else {
                recipeSteps = [
                  AnimationGroupStep(
                    mode: BattleAnimationGroupMode.parallel,
                    steps: compiled.steps,
                  ),
                  ...legacySteps(),
                ];
              }
            }
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
            final targetSideForFlash = execution.targetSlot;
            if (targetSideForFlash != null) {
              recipeSteps.removeWhere(
                (step) =>
                    step is CombatantFlashStep &&
                    step.slot == targetSideForFlash,
              );
            }
            var resolvedSteps = recipeSteps.map(
              (step) => _resolveCameraFocusStep(step, execution),
            ).toList();
            final selection = selectedAudio[event];
            if (selection != null) {
              final effectId = selection.trackedEffectId;
              final silentFallback = effectId == null
                  ? null
                  : _silentMoveFallback(resolvedSteps);
              if (effectId != null &&
                  (effectId.isEmpty || silentFallback == null)) {
                final program = selection.audio.program;
                if (program != null) {
                  unawaited(
                    program.cancel().then<void>((_) {}, onError: (Object _) {}),
                  );
                }
              } else {
                final fallback = resolvedSteps;
                final scoped = BattleMoveAudioScope.compose(
                  audio: selection.audio,
                  silentVisuals: selection.silentVisuals,
                  fallback: fallback,
                  forbiddenTargetFlash: execution.targetSlot,
                  attackerSlot: execution.attackerSlot,
                );
                resolvedSteps =
                    effectId != null &&
                        scoped.status == BattleRecipeAudioStatus.ready
                    ? [
                        if (selection.cameraBefore != null)
                          _resolveCameraFocusStep(selection.cameraBefore!, execution),
                        StartTrackedEffectStep(
                          effectId: effectId,
                          fallbackSteps: fallback,
                          fallbackAfterAudioSteps: silentFallback,
                        ),
                        ...scoped.steps,
                        const WaitTrackedEffectsStep(),
                        if (selection.cameraAfter != null) selection.cameraAfter!,
                      ]
                    : scoped.steps;
                audioScopes.addAll(scoped.audioScopes);
              }
            }
            final experimentalEffect = experimentalSourceEffects[event];
            if (experimentalEffect != null) {
              resolvedSteps = [
                StartTrackedEffectStep(
                  effectId: experimentalEffect,
                  fallbackSteps: resolvedSteps,
                ),
                const WaitTrackedEffectsStep(),
              ];
            }
            final focusSlot = execution.targetSlot ?? execution.attackerSlot;
            final moveKey = execution.move.id.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
            if (experimentalEffect == null && !resolvedSteps.any(_containsCameraStep)) {
              if (moveKey == 'shadowball') {
                steps.add(const AnimationGroupStep(
                  mode: BattleAnimationGroupMode.parallel,
                  steps: [BattleCameraMoveStep(offsetX: 36, offsetY: 0,
                    scale: .85, durationSeconds: 16 / 60)],
                ));
              } else if (moveKey == 'flamethrower') {
                steps.add(const AnimationGroupStep(
                  mode: BattleAnimationGroupMode.parallel,
                  steps: [CameraFocusStep(target: BattleCameraFocusTarget.scene,
                    durationSeconds: 24 / 60)],
                ));
              }
              steps.add(AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [CameraFocusStep(
                  target: BattleCameraFocusTarget.target,
                  side: focusSlot.side,
                  slotIndex: focusSlot.slotIndex,
                  durationSeconds: 16 / 60,
                )],
              ));
            }
            steps.addAll(resolvedSteps);
            if (experimentalEffect == null) {
              steps.add(const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [BattleCameraResetStep(durationSeconds: 16 / 60)],
              ));
            }
          }
          // Recette du 2026-08-24 : une attaque qui rate se dit — la
          // référence affiche « [cible] évite l'attaque ! » et ne joue ni
          // impact ni barre.
          if (!execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null) {
            steps.add(_messages.moveDodged(nameForSlot(execution.targetSlot!)));
          }
          if (execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null &&
              execution.typeEffectivenessMultiplier == 0.0) {
            // Recette du 2026-08-24 : une immunité se dit aussi — « Ça
            // n'affecte pas X… », sans son d'impact, sans clignotement et
            // sans barre : le coup n'a rien touché.
            steps.add(_messages.moveImmune(nameForSlot(execution.targetSlot!)));
          } else if (execution.didHit &&
              execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
              execution.targetSide != null &&
              // Un move de statut (puissance nulle, aucun dégât) ne joue pas
              // le bloc d'impact : la référence n'a ni son de coup ni
              // clignotement pour Doux Baiser. Un move OFFENSIF encaissé à 0
              // dégât garde son clignotement d'une seconde (BETA-BAT-013).
              (execution.damage > 0 || execution.move.power > 0)) {
            final targetSide = execution.targetSlot!;
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
                    side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                    durationSeconds: _damageBlinkSeconds,
                  ),
                  HudHpTweenStep(
                    side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
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
              steps.add(
                _messages.show(
                  const RuntimeBattleMessage(
                    RuntimeBattleMessageId.criticalHit,
                    'Coup critique !',
                  ),
                ),
              );
            }
            if (_effectivenessMessage(execution.typeEffectivenessMultiplier)
                case final effectiveness?) {
              steps.add(_messages.show(effectiveness));
            }
            if (hpFrom > 0 && hpTo == 0) {
              // BETA-BAT-014 : le son de K.O. de la référence — `down`, volume
              // 100, pitch 80, joué une fois avant que la chute ne démarre.
              steps.add(const PlaySeStep(seName: 'down', pitch: 80));
              if (!replacementRequiredSides.contains(targetSide)) {
                steps.add(
                  FaintCombatantStep(
                    side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                    // BETA-BAT-013 : la chute de la référence est de 0,1 s,
                    // fondu et descente en parallèle.
                    durationSeconds: 0.1,
                  ),
                );
              }
              steps.add(_messages.fainted(nameForSlot(targetSide)));
            }
          }
        case BattleTurnBagHpHealItemEvent(:final event):
          final visibleTargetSide = slotForLineup(
            event.side,
            event.targetLineupIndex,
          );
          final target =
              trackedDisplayName[visibleTargetSide] ??
              speciesDisplayName(event.targetSpeciesId);
          steps.add(_messages.itemUsed(event.side, event.displayName, target));
          trackedPartyHp[(event.side, event.targetLineupIndex)] = event.hpAfter;
          steps.add(_messages.hpRecovered(target, event.healedAmount));
          if (visibleTargetSide != null && event.healedAmount > 0) {
            trackedHp[visibleTargetSide] = event.hpAfter;
            steps.add(
              HudHpTweenStep(
                side: visibleTargetSide.side,
                slotIndex: visibleTargetSide.slotIndex,
                fromHp: event.hpBefore,
                toHp: event.hpAfter,
              ),
            );
          }
        case BattleTurnStatusCuredItemEvent():
          final target = itemTargetName(
            event.side,
            event.targetLineupIndex,
            event.targetSpeciesId,
          );
          if (!itemHealingAnnouncesStatusCure(previous, event)) {
            steps.add(
              _messages.itemUsed(event.side, event.displayName, target),
            );
          }
          steps.add(_messages.statusCured(target));
        case BattleTurnMovePpRestoredEvent():
          final target = itemTargetName(
            event.side,
            event.targetLineupIndex,
            event.targetSpeciesId,
          );
          steps.add(_messages.itemUsed(event.side, event.displayName, target));
          steps.add(
            _messages.ppRecovered(
              moveDisplayName(event.moveId, event.moveName),
              event.amount,
            ),
          );
        case BattleTurnCaptureAttemptEvent(:final event):
          final targetName = speciesDisplayName(event.targetSpeciesId);
          steps.add(
            _messages.show(
              RuntimeBattleMessage(
                RuntimeBattleMessageId.captureThrown,
                'Une Poké Ball est lancée sur $targetName !',
                target: targetName,
              ),
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
              ballItemId: event.ballId,
            ),
          );
          steps.add(
            _messages.show(
              event.caught
                  ? _battleCaptureCaughtMessage(targetName)
                  : RuntimeBattleMessage(
                      RuntimeBattleMessageId.captureEscaped,
                      '$targetName s’échappe de la Poké Ball !',
                      target: targetName,
                    ),
            ),
          );
        case BattleTurnStatusEvent(:final event):
          steps.add(_messages.status(event, nameForSlot(event.targetSlot)));
        case BattleTurnVolatileEvent(:final event):
          steps.add(_messages.volatile(event, nameForSlot(event.actorSlot)));
          switch (event.kind) {
            case BattleVolatileEventKind.protectActivated:
              steps.add(
                BarrierPulseStep(
                  side: event.actorSide,
                  slotIndex: event.actorSlot.slotIndex,
                  colorArgb: 0xAA95E7B9,
                  durationSeconds: 0.24,
                ),
              );
            case BattleVolatileEventKind.chargeStarted:
              steps.addAll(
                _buildRecipe(
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
                    attackerSlotIndex: event.actorSlot.slotIndex,
                    targetSlotIndex: event.targetSlot?.slotIndex ?? event.actorSlot.slotIndex,
                    damage: null,
                    didHit: false,
                    didCrit: false,
                  ),
                ),
              );
            case BattleVolatileEventKind.rechargeTurnSpent:
              steps.addAll(
                _buildRecipe(
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
                    attackerSlotIndex: event.actorSlot.slotIndex,
                    targetSlotIndex: event.targetSlot?.slotIndex ?? event.actorSlot.slotIndex,
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
          steps.add(
            _messages.field(
              event,
              event.targetSlot == null ? null : nameForSlot(event.targetSlot!),
            ),
          );
          switch (event.kind) {
            case BattleFieldEventKind.weatherResidualDamage:
              final targetSide = event.targetSlot;
              final damage = event.damage;
              final hpTo = event.remainingHp;
              if (targetSide != null &&
                  damage != null &&
                  damage > 0 &&
                  hpTo != null) {
                final hpFrom = hpTo + damage;
                trackedHp[targetSide] = hpTo;
                steps.add(HudHpTweenStep(
                  side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                  fromHp: hpFrom,
                  toHp: hpTo,
                  durationMs: (_hpDrainSeconds(damage) * 1000).round(),
                ));
                if (hpFrom > 0 && hpTo == 0) {
                  steps.add(const PlaySeStep(seName: 'down', pitch: 80));
                  if (!replacementRequiredSides.contains(targetSide)) {
                    steps.add(FaintCombatantStep(
                      side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                      durationSeconds: 0.1,
                    ));
                  }
                  steps.add(_messages.fainted(nameForSlot(targetSide)));
                }
              }
            case BattleFieldEventKind.weatherSet:
              if (event.weather == BattleWeatherId.rain) {
                steps.addAll(
                  _buildRecipe(
                    BattleMoveVisualRecipeId.weatherRain,
                    _fieldRecipeContext(
                      recipeId: BattleMoveVisualRecipeId.weatherRain,
                    ),
                  ),
                );
              } else if (event.weather == BattleWeatherId.sandstorm) {
                steps.addAll(
                  _buildRecipe(
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
                  _buildRecipe(
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
          steps.add(_messages.stealthRock(event));
          if (event.kind == BattleStealthRockEventKind.set) {
            steps.addAll(
              _buildRecipe(
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
            final targetSide = event.targetSlot!;
            final hpFrom = trackedHp[targetSide] ?? 0;
            final hpTo = (hpFrom - event.damage!).clamp(0, hpFrom);
            trackedHp[targetSide] = hpTo;
            steps.add(
              SpawnFxStep(
                effectId: 'impact',
                attackerSide: _oppositeSide(targetSide.side),
                defenderSide: targetSide.side,
                defenderSlotIndex: targetSide.slotIndex,
                from: BattleVisualAnchor.defenderCenter,
                to: BattleVisualAnchor.defenderCenter,
                durationSeconds: 0.12,
                afterEffect: BattleFxAfterEffect.fade,
              ),
            );
            steps.add(
              HudHpTweenStep(
                side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                fromHp: hpFrom,
                toHp: hpTo,
              ),
            );
            if (hpFrom > 0 && hpTo == 0) {
              if (!replacementRequiredSides.contains(targetSide)) {
                steps.add(
                  FaintCombatantStep(
                    side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                    // BETA-BAT-013 : la chute de la référence est de 0,1 s,
                    // fondu et descente en parallèle.
                    durationSeconds: 0.1,
                  ),
                );
              }
              steps.add(_messages.fainted(nameForSlot(targetSide)));
            }
          }
        case BattleTurnSpikesEvent(:final event):
          steps.add(_messages.spikes(event));
          if (event.kind == BattleSpikesEventKind.setLayer) {
            steps.addAll(
              _buildRecipe(
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
            final targetSide = event.targetSlot!;
            final hpFrom = trackedHp[targetSide] ?? 0;
            final hpTo = (hpFrom - event.damage!).clamp(0, hpFrom);
            trackedHp[targetSide] = hpTo;
            steps.add(
              SpawnFxStep(
                effectId: 'impact',
                attackerSide: _oppositeSide(targetSide.side),
                defenderSide: targetSide.side,
                defenderSlotIndex: targetSide.slotIndex,
                from: BattleVisualAnchor.defenderCenter,
                to: BattleVisualAnchor.defenderCenter,
                durationSeconds: 0.12,
                afterEffect: BattleFxAfterEffect.fade,
              ),
            );
            steps.add(
              HudHpTweenStep(
                side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                fromHp: hpFrom,
                toHp: hpTo,
              ),
            );
            if (hpFrom > 0 && hpTo == 0) {
              if (!replacementRequiredSides.contains(targetSide)) {
                steps.add(
                  FaintCombatantStep(
                    side: targetSide.side,
                    slotIndex: targetSide.slotIndex,
                    // BETA-BAT-013 : la chute de la référence est de 0,1 s,
                    // fondu et descente en parallèle.
                    durationSeconds: 0.1,
                  ),
                );
              }
              steps.add(_messages.fainted(nameForSlot(targetSide)));
            }
          }
        case BattleTurnSwitchEvent(:final event):
          final incoming = after[event.slot];
          final incomingSpeciesId = event.toSpeciesId;
          final incomingName =
              incoming != null && incoming.speciesId == incomingSpeciesId
              ? _combatantName(event.side, incoming)
              : incomingSpeciesId == null
              ? ''
              : speciesDisplayName(incomingSpeciesId);
          steps.add(
            _messages.switchCombatant(
              event: event,
              outgoing:
                  trackedDisplayName[event.slot] ??
                  speciesDisplayName(event.fromSpeciesId),
              incoming: incomingName,
            ),
          );
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
                slotIndex: event.slot.slotIndex,
                kind: BattleBallSequenceKind.recall,
                ballItemId: resolveCombatantBallItemId?.call(
                  event.side,
                  before[event.slot]?.lineupIndex ?? 0,
                ),
              ),
            );
            steps.add(
              CombatantMotionStep(
                side: event.side,
                slotIndex: event.slot.slotIndex,
                motionKind: BattleCombatantMotionKind.materializeOut,
                durationSeconds: 0.1,
              ),
            );
            final incomingHp = incoming == null ? null :
                trackedPartyHp[(event.side, incoming.lineupIndex)] ?? incoming.currentHp;
            if (incoming != null && incomingHp != null) {
              trackedLineup[event.slot] = incoming.lineupIndex;
              trackedHp[event.slot] = incomingHp;
            }
            steps.add(SwapCombatantVisualStep(
              side: event.side, slotIndex: event.slot.slotIndex, initialHp: incomingHp,
            ));
            steps.add(
              PlayBallSequenceStep(
                side: event.side,
                slotIndex: event.slot.slotIndex,
                kind: BattleBallSequenceKind.sendOutHeld,
                ballItemId: after[event.slot] == null ? null :
                    resolveCombatantBallItemId?.call(
                      event.side,
                      after[event.slot]!.lineupIndex,
                    ),
              ),
            );
            steps.add(
              CombatantMotionStep(
                side: event.side,
                slotIndex: event.slot.slotIndex,
                motionKind: BattleCombatantMotionKind.materializeIn,
                durationSeconds: 0.1,
              ),
            );
            if (incomingSpeciesId != null) {
              steps.add(PlayCryStep(speciesId: incomingSpeciesId));
            }
            trackedDisplayName[event.slot] = incomingName;
          } else {
            steps.add(
              FaintCombatantStep(
                side: event.side,
                slotIndex: event.slot.slotIndex,
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
                slotIndex: event.slot.slotIndex,
                isRise: event.amount > 0,
              ),
            );
          }
          steps.add(_messages.statStage(event, nameForSlot(event.slot)));
        case BattleTurnMoveFailedEvent():
          steps.add(
            _messages.show(
              const RuntimeBattleMessage(
                RuntimeBattleMessageId.moveFailed,
                'Mais cela échoue !',
              ),
            ),
          );
        case BattleTurnFleeFailedEvent():
          // Recette du 2026-08-24 : sans ce texte, l'adversaire attaquait
          // après une fuite ratée sans que le joueur sache pourquoi.
          steps.add(
            _messages.show(
              const RuntimeBattleMessage(
                RuntimeBattleMessageId.fleeFailed,
                'Vous n’avez pas réussi à fuir.',
              ),
            ),
          );
      }
    }

    return BattleAnimationPlan(
      steps: List<BattleAnimationStep>.unmodifiable(steps),
      audioScopes: List<BattleAnimationAudioScope>.unmodifiable(audioScopes),
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
  required BattleTurnMessages messages,
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
  return <BattleAnimationStep>[
    // Recette du 2026-08-24 : la fuite a son propre son chez la référence —
    // `escape` (fleee.wav), volume 80, pitch 70 — joué avec l'annonce.
    ...fleeSe,
    messages.show(buildBattleOutcomeMessage(outcome, speciesDisplayName)),
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

RuntimeBattleMessage? _effectivenessMessage(double multiplier) {
  if (multiplier > 1.0) {
    return const RuntimeBattleMessage(
      RuntimeBattleMessageId.superEffective,
      'C’est super efficace !',
    );
  }
  if (multiplier > 0.0 && multiplier < 1.0) {
    return const RuntimeBattleMessage(
      RuntimeBattleMessageId.notVeryEffective,
      'Ce n’est pas très efficace…',
    );
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

BattleSideId _oppositeSide(BattleSideId side) {
  return side == BattleSideId.player ? BattleSideId.enemy : BattleSideId.player;
}

RuntimeBattleMessage buildBattleOutcomeMessage(
  BattleOutcome outcome,
  String Function(String speciesId) speciesDisplayName,
) {
  switch (outcome.type) {
    case BattleOutcomeType.victory:
      return const RuntimeBattleMessage(
        RuntimeBattleMessageId.victory,
        'Tu as gagné le combat !',
      );
    case BattleOutcomeType.defeat:
      return const RuntimeBattleMessage(
        RuntimeBattleMessageId.defeat,
        'Tu n’as plus de Pokémon en état de combattre !',
      );
    case BattleOutcomeType.runaway:
      return const RuntimeBattleMessage(
        RuntimeBattleMessageId.fled,
        'Tu as pris la fuite !',
      );
    case BattleOutcomeType.captured:
      return _battleCaptureCaughtMessage(
        speciesDisplayName(outcome.finalState.enemy.speciesId),
      );
  }
}

RuntimeBattleMessage _battleCaptureCaughtMessage(String target) =>
    RuntimeBattleMessage(
      RuntimeBattleMessageId.captureCaught,
      '$target est capturé !',
      target: target,
    );
