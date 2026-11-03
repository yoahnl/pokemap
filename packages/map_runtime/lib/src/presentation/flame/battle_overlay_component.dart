import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show Image;

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter/foundation.dart' show listEquals;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_move_catalog_loader.dart';
import '../../application/runtime_battle_presentation.dart';
import '../../infrastructure/runtime_ui_image.dart';
import '../flutter/battle_command_overlay_snapshot.dart';
import 'battle_bag_menu_model.dart';
import 'battle_bag_item_icon_resolver.dart';
import 'battle_command_menu_model.dart';
import 'battle_combatant_gender_resolver.dart';
import 'battle_animation_plan.dart';
import 'battle_move_audio_scope.dart';
import 'battle_recipe_audio_program.dart';
import 'battle_motion_policy.dart';
import 'battle_live_attachment.dart';
import 'battle_animation_runner.dart';
import 'battle_ball_capture_component.dart';
import 'battle_ball_flash_component.dart';
import 'battle_ball_throw_component.dart';
import 'battle_background_resolver.dart';
import 'battle_perspective_camera.dart';
import 'battle_camera_framing.dart';
import 'battle_camera_motion_envelope.dart';
import 'battle_perspective_ground_component.dart';
import 'battle_stage_3d_component.dart';
import 'battle_idle_motion.dart';
import 'battle_debug_panel_component.dart';
import 'battle_fx_bundle_cache.dart';
import 'battle_fx_layer_component.dart';
import 'battle_intro_animation_planner.dart';
import 'battle_intro_trainer_component.dart';
import 'battle_stat_aura_component.dart';
import 'battle_stat_sheet_manifest.dart';
import 'battle_medicine_target_menu_model.dart';
import 'battle_party_menu_model.dart';
import 'battle_pokemon_sprite_resolver.dart';
import 'battle_visual_asset_cache.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';
import 'battle_scene_layout.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_turn_animation_planner.dart';
import 'battle_sfx_player.dart';
import 'battle_move_visual_resolver.dart';
import 'battle_move_recipe_compiler.dart';
import 'battle_gen5_motion_playback.dart';
import 'battle_gen5_actor_motion.dart';
import 'battle_gen5_swing.dart';
import 'battle_gen5_camera_motion.dart';
import 'battle_gen5_source_background.dart';
import 'battle_gen5_source_program_playback.dart';
import 'battle_offline_move_recipe_loader.dart';
import 'battle_spl_camera_projection.dart';
import 'battle_spl_static_admission.dart';
import 'battle_spl_static_component.dart';
import 'battle_verified_spl_loader.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Ce helper reste volontairement pur parce que le lot 1 ne doit surtout pas
/// recréer une logique de commande parallèle dans la présentation :
/// - la vérité de ce qu'on attend du joueur reste `BattleDecisionRequest` ;
/// - l'UI ne fait que reformuler cette vérité de manière plus lisible.
String buildBattleDecisionPromptForOverlay(BattleDecisionRequest request) {
  return switch (request) {
    BattleTurnChoiceRequest() => 'Que doit faire le joueur ?',
    BattleForcedReplacementRequest() =>
      'Le joueur doit remplacer son Pokémon K.O.',
    BattleContinueRequest() => 'Le joueur doit continuer un tour forcé',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible',
      },
  };
}

typedef BattleSpeciesDisplayNameResolver = String Function(String speciesId);

String buildBattleDecisionPromptForSession(
  BattleSession session, {
  BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName =
      _battleDisplayName,
}) {
  return switch (session.decisionRequest) {
    BattleTurnChoiceRequest() =>
      'Que doit faire ${resolveSpeciesDisplayName(session.state.player.speciesId)} ?',
    BattleForcedReplacementRequest() =>
      '${resolveSpeciesDisplayName(session.state.player.speciesId)} est K.O. Choisis un remplaçant.',
    BattleContinueRequest() => 'Appuie pour continuer.',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé.',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours.',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible.',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible.',
      },
  };
}

/// Construit les lignes de restitution d'un tour pour l'overlay runtime.
///
/// La vraie source de vérité de narration reste `BattleTurnResult.timeline`.
/// Le lot 1 améliore uniquement la composition visuelle de cette narration.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.stealthRockEvents.isNotEmpty ||
          turnResult.spikesEvents.isNotEmpty ||
          turnResult.bagHpHealItemEvents.isNotEmpty ||
          turnResult.captureAttemptEvents.isNotEmpty ||
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (var index = 0; index < turnResult.timeline.length; index++) {
    final event = turnResult.timeline[index];
    final previous = index == 0 ? null : turnResult.timeline[index - 1];
    switch (event) {
      case BattleTurnBagHpHealItemEvent(:final event):
        final actor = _overlayCombatantLabelForSide(event.side);
        lines.add(
          '$actor utilise ${event.displayName} sur ${event.targetSpeciesId}',
        );
        lines.add('${event.targetSpeciesId} récupère ${event.healedAmount} PV');
      case BattleTurnStatusCuredItemEvent():
        if (!itemHealingAnnouncesStatusCure(previous, event)) {
          final actor = _overlayCombatantLabelForSide(event.side);
          lines.add('$actor utilise ${event.displayName} sur ${event.targetSpeciesId}');
        }
        lines.add('${event.targetSpeciesId} est guéri de son problème de statut');
      case BattleTurnMovePpRestoredEvent():
        final actor = _overlayCombatantLabelForSide(event.side);
        lines.add('$actor utilise ${event.displayName} sur ${event.targetSpeciesId}');
        lines.add('${event.moveName} récupère ${event.amount} PP');
      case BattleTurnCaptureAttemptEvent(:final event):
        final target = _battleDisplayName(event.targetSpeciesId);
        lines.add('Une Poké Ball est lancée sur $target !');
        lines.add(
          event.caught
              ? '$target est capturé !'
              : '$target s’échappe de la Poké Ball !',
        );
      case BattleTurnExecutionEvent(:final execution):
        final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
        lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts',
        );
      case BattleTurnStatusEvent(:final event):
        lines.add(_formatOverlayStatusEvent(event));
      case BattleTurnVolatileEvent(:final event):
        lines.add(_formatOverlayVolatileEvent(event));
      case BattleTurnFieldEvent(:final event):
        lines.add(_formatOverlayFieldEvent(event));
      case BattleTurnStealthRockEvent(:final event):
        lines.add(_formatOverlayStealthRockEvent(event));
      case BattleTurnSpikesEvent(:final event):
        lines.add(_formatOverlaySpikesEvent(event));
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
      case BattleTurnFleeFailedEvent(:final side):
        lines.add('${_overlayCombatantLabelForSide(side)} échoue à fuir');
      case BattleTurnStatStageEvent():
        final direction = event.amount == 0
            ? 'ne change pas'
            : event.amount > 0
                ? 'monte de ${event.amount}'
                : 'descend de ${event.amount.abs()}';
        lines.add(
          '${_overlayCombatantLabelForSide(event.side)} : '
          '${event.stat.name} $direction',
        );
    }
  }

  return List<String>.unmodifiable(lines);
}

/// Construit les lignes de narration visibles dans la command box.
///
/// Invariant important du lot 1 :
/// - on reste adossé à la timeline observable du moteur ;
/// - quand aucun tour n'est disponible, on retombe sur la requête courante ;
/// - on n'invente pas de narration "UI-only".
List<String> buildBattleNarrationLinesForOverlay(
  BattleSession session, {
  BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName =
      _battleDisplayName,
}) {
  final currentTurn = session.state.currentTurn;
  if (currentTurn != null) {
    final lines = buildBattleTurnLinesForOverlay(currentTurn);
    if (lines.isNotEmpty) {
      final startIndex = lines.length > 4 ? lines.length - 4 : 0;
      return List<String>.unmodifiable(lines.sublist(startIndex));
    }
  }

  if (session.state.isFinished && session.state.outcome != null) {
    return List<String>.unmodifiable(<String>[
      _buildOutcomeHeadline(
        session.state.outcome!,
        resolveSpeciesDisplayName,
      ),
    ]);
  }

  return buildBattleOpeningNarrationLinesForOverlay(
    session,
    resolveSpeciesDisplayName: resolveSpeciesDisplayName,
  );
}

List<String> buildBattleOpeningNarrationLinesForOverlay(
  BattleSession session, {
  BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName =
      _battleDisplayName,
}) {
  final enemyName = resolveSpeciesDisplayName(session.state.enemy.speciesId);
  final playerName = resolveSpeciesDisplayName(session.state.player.speciesId);
  if (session.setup.isTrainerBattle) {
    final trainerName = session.setup.trainerId?.trim();
    final challenger = trainerName == null || trainerName.isEmpty
        ? 'Un Dresseur'
        : 'Le Dresseur $trainerName';
    return List<String>.unmodifiable(<String>[
      '$challenger te défie !',
      '$challenger envoie $enemyName !',
      'Vas-y, $playerName !',
    ]);
  }
  return List<String>.unmodifiable(<String>[
    'Un $enemyName sauvage apparaît !',
    'Vas-y, $playerName !',
  ]);
}

String buildBattlePartyPromptForOverlay(BattlePartyMenuModel partyMenuModel) {
  return switch (partyMenuModel.mode) {
    BattlePartyMenuMode.voluntarySwitch => 'Choisis un Pokémon.',
    BattlePartyMenuMode.forcedReplacement => 'Choisis un remplaçant.',
    BattlePartyMenuMode.unavailable => 'POKÉMON indisponible.',
  };
}

List<String> buildBattlePartyNarrationLinesForOverlay(
  BattlePartyMenuModel partyMenuModel,
) {
  if (partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement) {
    return const <String>['Remplacement requis.'];
  }
  if (!partyMenuModel.hasSelectableEntries) {
    return const <String>['Aucun switch disponible.'];
  }
  return const <String>['Actif et K.O. sont indisponibles.'];
}

String buildBattleBagPromptForOverlay(
  BattleBagMenuModel bagMenuModel, {
  String? feedbackMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return feedbackMessage;
  }
  return switch (bagMenuModel.mode) {
    BattleBagMenuMode.empty => 'Sac vide.',
    BattleBagMenuMode.available => 'Choisis un objet.',
    BattleBagMenuMode.unavailable => 'Choisis un objet.',
  };
}

List<String> buildBattleBagNarrationLinesForOverlay(
  BattleBagMenuModel bagMenuModel, {
  String? feedbackMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return const <String>['Le sac reflète maintenant l’état réel du runtime.'];
  }
  return switch (bagMenuModel.mode) {
    BattleBagMenuMode.empty => const <String>['Aucun objet dans le sac.'],
    BattleBagMenuMode.available => const <String>[
        'Les objets indisponibles restent grisés.',
      ],
    BattleBagMenuMode.unavailable => const <String>[
        'Aucun objet utilisable pour ce tour.',
      ],
  };
}

String buildBattleMedicineTargetPromptForOverlay(
  BattleMedicineTargetMenuModel medicineTargetMenuModel, {
  String? feedbackMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return feedbackMessage;
  }
  return 'Choisis une cible pour ${medicineTargetMenuModel.displayName}.';
}

List<String> buildBattleMedicineTargetNarrationLinesForOverlay(
  BattleMedicineTargetMenuModel medicineTargetMenuModel, {
  String? feedbackMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return const <String>[
      'L’état battle/runtime affiché a déjà été mis à jour.',
    ];
  }
  if (!medicineTargetMenuModel.hasSelectableEntries) {
    return const <String>[
      'Aucune cible valide pour cet objet.',
    ];
  }
  return const <String>[
    'Les Pokémon K.O. et full HP sont indisponibles.',
  ];
}

/// Construit les lignes du panneau debug optionnel.
///
/// Ce panneau ne sert qu'au diagnostic local. Il doit rester :
/// - explicitement dérivé de la vérité battle/runtime déjà existante ;
/// - explicitement séparé de l'UI de combat normale.
List<String> buildBattleDebugLinesForOverlay(
  BattleSession session, {
  required int selectedIndex,
}) {
  return List<String>.unmodifiable(<String>[
    'phase: ${session.state.phase.name}',
    'request: ${session.decisionRequest.runtimeType}',
    'choix: ${session.decisionRequest.allowedChoices.length}',
    'selection: $selectedIndex',
    'joueur: ${session.state.player.speciesId} ${session.state.player.currentHp}/${session.state.player.maxHp}',
    'ennemi: ${session.state.enemy.speciesId} ${session.state.enemy.currentHp}/${session.state.enemy.maxHp}',
  ]);
}

String _formatOverlaySwitchEvent(BattleSwitchEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleSwitchEventKind.switched => event.wasForced
        ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
        : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
    BattleSwitchEventKind.replacementRequired =>
      '$actor doit remplacer ${event.fromSpeciesId} K.O.',
  };
}

String _formatOverlayStatusEvent(BattleStatusEvent event) {
  final actor = _overlayCombatantLabelForSide(event.targetSide);
  final status = event.status.name.toUpperCase();
  return switch (event.kind) {
    BattleStatusEventKind.applied =>
      '$actor reçoit le statut $status (${event.sourceMoveId})',
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '$actor garde déjà ${event.existingStatus!.name.toUpperCase()} '
          'et ignore $status',
    BattleStatusEventKind.preventedAction =>
      '$actor ne peut pas agir à cause de $status',
    BattleStatusEventKind.residualDamage =>
      '$actor subit ${event.damage} dégâts résiduels ($status'
          '${event.toxicCounter == null ? '' : ', compteur ${event.toxicCounter}'}'
          ')',
  };
}

String _formatOverlayVolatileEvent(BattleVolatileEvent event) {
  final actor = _overlayCombatantLabelForSide(event.actorSide);
  final target = event.targetSide == null
      ? null
      : _overlayCombatantLabelForSide(event.targetSide!);

  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated => '$actor active Protect',
    BattleVolatileEventKind.protectBlocked =>
      '${target ?? 'La cible'} bloque l’attaque avec Protect',
    BattleVolatileEventKind.protectBroken =>
      '$actor perce Protect sur ${target ?? 'la cible'}',
    BattleVolatileEventKind.rechargeRequired =>
      '$actor doit recharger au tour suivant',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '$actor passe son tour pour recharger',
    BattleVolatileEventKind.chargeStarted =>
      '$actor commence à charger ${event.sourceMoveId ?? 'son attaque'}',
    BattleVolatileEventKind.chargeReleased =>
      '$actor libère ${event.sourceMoveId ?? 'son attaque chargée'}',
    BattleVolatileEventKind.confusionApplied => '$actor devient confus',
    BattleVolatileEventKind.confusionActive => '$actor est confus',
    BattleVolatileEventKind.confusionEnded => '$actor n’est plus confus',
  };
}

String _formatOverlayFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet =>
      'Le champ passe à ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherResidualDamage =>
      '${_overlayCombatantLabelForSide(event.targetSide!)} subit ${event.damage} dégâts de ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherExpired =>
      '${_overlayWeatherLabel(event.weather!)} prend fin',
    BattleFieldEventKind.pseudoWeatherSet =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} devient actif',
    BattleFieldEventKind.pseudoWeatherCleared =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
    BattleFieldEventKind.pseudoWeatherExpired =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} prend fin',
  };
}

String _formatOverlayStealthRockEvent(BattleStealthRockEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleStealthRockEventKind.set => 'Stealth Rock est posé du côté $actor',
    BattleStealthRockEventKind.alreadyPresent =>
      'Stealth Rock est déjà posé du côté $actor',
    BattleStealthRockEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Stealth Rock à l’entrée',
  };
}

String _formatOverlaySpikesEvent(BattleSpikesEvent event) {
  final actor = event.targetSlot == null
      ? _overlayCombatantLabelForSide(event.side)
      : _overlayCombatantLabelForSide(event.targetSlot!.side);
  return switch (event.kind) {
    BattleSpikesEventKind.setLayer =>
      'Spikes monte à ${event.layers} couche(s) du côté $actor',
    BattleSpikesEventKind.alreadyAtMaxLayers =>
      'Spikes est déjà à ${event.layers} couche(s) du côté $actor',
    BattleSpikesEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Spikes à l’entrée (${event.layers} couche(s))',
  };
}

String _overlayCombatantLabelForSide(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}

String _overlayWeatherLabel(BattleWeatherId weather) {
  return switch (weather) {
    BattleWeatherId.rain => 'la pluie',
    BattleWeatherId.sandstorm => 'la tempête de sable',
  };
}

String _overlayPseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
  return switch (pseudoWeather) {
    BattlePseudoWeatherId.trickRoom => 'Trick Room',
  };
}

/// BETA-BAT-011 : le bandeau prend le résolveur en argument.
///
/// Il appelait `_battleDisplayName`, qui n'est que le DÉFAUT du champ
/// injectable — donc un jeu fournissant un vrai résolveur voyait quand même
/// l'identifiant brut dans son message de capture.
String _buildOutcomeHeadline(
  BattleOutcome outcome,
  BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName,
) {
  return switch (outcome.type) {
    BattleOutcomeType.victory => 'Tu as gagné le combat !',
    BattleOutcomeType.defeat =>
      'Tu n’as plus de Pokémon en état de combattre !',
    BattleOutcomeType.runaway => 'Tu as pris la fuite !',
    BattleOutcomeType.captured =>
      '${resolveSpeciesDisplayName(outcome.finalState.enemy.speciesId)} est capturé !',
  };
}

String _battleDisplayName(String speciesId) => speciesId;

/// Overlay de combat lot 1.
///
/// Responsabilité :
/// - garder le runtime battle branché sur les mêmes vérités métier ;
/// - composer une scène de combat lisible ;
/// - déléguer le rendu concret aux composants de présentation du runtime.
///
/// Garde-fous :
/// - aucune logique battle n'entre ici ;
/// - aucune logique parallèle aux requests ou à la timeline n'est créée ;
/// - aucun resolver de background contextuel n'est introduit ici ;
/// - aucun seam IA n'est introduit ici.
String _defaultBattleMoveDisplayName(String moveId, String fallbackName) =>
    fallbackName;

/// Vitesse de la scène de combat quand le joueur demande un mouvement réduit.
///
/// Calé sur le « combat rapide » des jeux de la série : environ deux fois et
/// demie plus court, assez pour que la lecture reste possible. Nommé plutôt
/// qu'écrit en dur pour rester discutable sans relire la scène.
///
/// RÉSERVE HONNÊTE : « reduced motion » signifie d'ordinaire MOINS de mouvement,
/// pas du mouvement plus rapide, et accélérer peut gêner une sensibilité au
/// mouvement plutôt que la soulager. Raccourcir plutôt que sauter est un choix
/// produit assumé (Yoahn, 2026-08-20) ; ce commentaire existe pour qu'il reste
/// visible et non oublié.
const double battleReducedMotionSpeedFactor = 2.5;

class BattleOverlayComponent extends PositionComponent with CustomTraversal {
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
    this.onPlayerDecision,
    RuntimeBattlePresentation? presentation,
    this.onBagHpHealItemUseRequested,
    this.onBagMovePpItemUseRequested,
    this.medicineBattleState,
    this.medicineTargetIsConfused,
    this.onCommandOverlaySnapshotChanged,
    GameState gameState = const GameState(saveId: 'battle-overlay'),
    ItemCapabilityResolver? itemCapabilityResolver,
    this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
    this.spriteResolver,
    this.visualAssetCache,
    this.bagItemIconResolver,
    this.genderResolver,
    this.resolveBallSpritePath,
    this.resolveCombatantBallItemId,
    this.resolveMoveDisplayName = _defaultBattleMoveDisplayName,
    this.playSfx,
    this.onStartTrackedEffect,
    this.onStartRecoverableTrackedEffect,
    this.playCry,
    this.onOutcomePresented,
    this.introEnabled = false,
    this.resolveSpeciesDisplayName = _battleDisplayName,
    this.showDebugPanel = false,
    this.motionScale = 1.0,
    BattleMotionPolicy? motionPolicy,
    this.textScale = 1.0,
    EdgeInsets safeAreaPadding = EdgeInsets.zero,
    RuntimeMoveCatalog? moveCatalog,
    BattleMoveVisualResolver? moveVisualResolver,
    BattleFxBundleCache? fxBundleCache,
    RuntimeResourceBudget? resourceBudget,
    bool allowMedicineReserveTargets = true,
    Map<int, double> playerExperienceProgressByLineupIndex = const {},
  })  : _session = session,
        _motionPolicy = motionPolicy ?? BattleMotionPolicy.legacy(motionScale),
        _hasExplicitMotionPolicy = motionPolicy != null,
        _battlePresentation = presentation,
        _gameState = gameState,
        _itemCapabilityResolver = itemCapabilityResolver ??
            ItemCapabilityResolver(ItemCatalogSnapshot.empty()),
        _moveCatalog = moveCatalog ??
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        _resourceBudget = resourceBudget ?? RuntimeResourceBudget(),
        _ownsResourceBudget = resourceBudget == null,
        _ownsFxBundleCache = fxBundleCache == null,
        _allowMedicineReserveTargets = allowMedicineReserveTargets,
        _playerExperienceProgressByLineupIndex = Map<int, double>.unmodifiable(
          playerExperienceProgressByLineupIndex,
        ),
        _safeAreaPadding = safeAreaPadding,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        ) {
    _moveVisualResolver =
        moveVisualResolver ?? BattleMoveVisualResolver(_moveCatalog);
    _fxBundleCache = fxBundleCache ?? BattleFxBundleCache(resourceBudget: _resourceBudget);
    _visualImageScope = visualAssetCache?.beginScope();
    _fxImageScope = _fxBundleCache.beginScope();
  }

  BattleSession _session;
  RuntimeBattlePresentation? _battlePresentation;
  RuntimeBattlePresentation? _previousBattlePresentation;
  bool get _isDoubles => _battlePresentation?.isDoubles ?? false;
  final Map<BattleSlotRef, BattleSceneCombatantComponent> _additionalCombatants = {};
  final Map<BattleSlotRef, BattleCombatant> _displayedCombatantsBySlot = {};
  final void Function(BattleDecision decision, BattleEngineDecisionRequest request)? onPlayerDecision;
  PlayerBattleChoiceFight? _pendingTargetChoice;
  BattleEngineDecisionRequest? _pendingTargetRequest;
  int _selectedTargetIndex = 0;

  BattleCombatant _combatantDataAt(BattleSlotRef slot) {
    final projected = _battlePresentation?.combatantAt(slot);
    if (projected != null) return projected.combatant;
    if (slot.slotIndex != 0 || _isDoubles) {
      throw StateError('Missing battle occupant at $slot.');
    }
    return slot.side == BattleSideId.player ? _session.state.player : _session.state.enemy;
  }

  BattleCombatantSceneGeometry _geometryFor(BattleSlotRef slot) =>
      currentSceneLayout.combatantGeometry(slot, doubles: _isDoubles);
  GameState _gameState;
  final ItemCapabilityResolver _itemCapabilityResolver;

  /// Recette du 2026-08-24 : « en portrait, le HUD est partiellement caché
  /// par la notch ». La géométrie de scène connaissait la safe area
  /// ([BattleSceneLayout.forViewport] la gère depuis toujours) mais personne
  /// ne la lui donnait. L'hôte la pousse depuis MediaQuery et la met à jour
  /// aux rotations.
  EdgeInsets _safeAreaPadding;

  void setSafeAreaPadding(EdgeInsets padding) {
    if (_safeAreaPadding == padding) return;
    _safeAreaPadding = padding;
    _applyViewportLayout(size);
    _syncPanelsOnly();
  }

  final void Function(PlayerBattleChoice choice) onPlayerChoice;
  final bool Function(
    BattleBagMenuActionMedicineTarget action,
    BattleMedicineTargetEntry entry, {
    BattleEngineDecisionRequest? request,
  })? onBagHpHealItemUseRequested;
  final bool Function(
    BattleBagMenuActionMedicineTarget action,
    BattleMedicineTargetEntry entry,
    int moveIndex, {
    BattleEngineDecisionRequest? request,
  })? onBagMovePpItemUseRequested;
  final BattleState Function()? medicineBattleState;
  final bool Function(int lineupIndex)? medicineTargetIsConfused;
  final ValueChanged<BattleCommandOverlaySnapshot?>?
      onCommandOverlaySnapshotChanged;
  final BattleBackgroundSpec backgroundSpec;
  final BattlePokemonSpriteResolver? spriteResolver;
  final BattleVisualAssetCache? visualAssetCache;
  final BattleBagItemIconResolver? bagItemIconResolver;
  final BattleCombatantGenderResolver? genderResolver;
  final Future<String?> Function(String itemId)? resolveBallSpritePath;
  final String? Function(BattleSideId side, int lineupIndex)?
      resolveCombatantBallItemId;
  final BattleMoveDisplayNameResolver resolveMoveDisplayName;

  /// BETA-BAT-014 : le lecteur des sons de combat. Nul chez un hôte silencieux
  /// — les harnais de test et les hôtes sans audio gardent exactement l'ancien
  /// comportement, et aucun test existant ne change.
  final BattleSfxPlayer? playSfx;
  final void Function() Function(StartTrackedEffectStep, void Function())?
      onStartTrackedEffect;
  final void Function() Function(
    StartTrackedEffectStep,
    void Function(),
    void Function(),
  )? onStartRecoverableTrackedEffect;

  /// Notifié une seule fois, au moment où l'issue devient VISIBLE — plan
  /// d'animation vidé, plus rien en attente. C'est l'horloge du thème de
  /// victoire (BETA-BAT-015) : la référence lance sa fanfare quand la phase
  /// de fin commence à se jouer, pas quand le tour est calculé. Le bandeau
  /// texte reste soumis en plus à [battleOutcomeIsAnnounced] : une victoire
  /// sauvage se notifie ici sans jamais s'afficher là-bas.
  final void Function(BattleOutcome outcome)? onOutcomePresented;
  bool _outcomePresentedNotified = false;
  final BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName;
  final RuntimeMoveCatalog _moveCatalog;
  late final BattleMoveVisualResolver _moveVisualResolver;
  late final BattleFxBundleCache _fxBundleCache;
  final RuntimeResourceBudget _resourceBudget;
  final bool _ownsResourceBudget;
  final bool _ownsFxBundleCache;
  Object? _visualImageScope;
  Object? _fxImageScope;
  final Map<String, RuntimeUiImageLease> _sheetLeases = {};
  final Set<void Function()> _trainerImageReleases = {};
  final Map<int, double> _playerExperienceProgressByLineupIndex;

  /// Le debug reste volontairement opt-in.
  ///
  /// Le lot 1 doit sortir l'UI normale du mode "debug panel". On garde donc un
  /// interrupteur explicite au lieu de laisser le debug redéfinir l'apparence
  /// par défaut du combat.
  final bool showDebugPanel;

  /// Facteur de vitesse appliqué au temps de la scène de combat.
  ///
  /// BETA-BAT-007 demande que le reduced motion RACCOURCISSE les animations
  /// plutôt que de les sauter — décision de Yoahn du 2026-08-20. Mettre `dt` à
  /// l'échelle ici est le seul endroit qui obtienne ça sans rien supprimer :
  /// `update` pilote le runner d'animation, le rig caméra ET tous les enfants
  /// visuels, donc phases et effets se raccourcissent ENSEMBLE. Chaque étape du
  /// plan est encore jouée, chaque callback encore appelé, chaque dégât encore
  /// appliqué : seule la durée change.
  ///
  /// L'alternative envisagée puis écartée était de mettre les durées à l'échelle
  /// dans le plan : 29 types d'étapes, aucun `copyWith`, donc un mapper à
  /// reconstruire à la main où un champ oublié se perdrait en silence. Et
  /// certaines durées sont dérivées d'un catalogue et ne sont pas dans l'étape.
  ///
  /// `1.0` laisse le rythme d'origine, ce qui garde ce paramètre sans effet
  /// partout où personne ne le passe.
  final double motionScale;
  BattleMotionPolicy _motionPolicy;
  bool _hasExplicitMotionPolicy;
  bool _reducedEffectsApplied = false;

  BattleMotionPolicy get motionPolicy => _motionPolicy;
  bool get _systemReducedMotion =>
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  bool get _reducedBattleMotion => _motionPolicy.reducedMotion || _systemReducedMotion;
  bool get _reducedBattleEffects =>
      (_hasExplicitMotionPolicy && _motionPolicy.reducedMotion) || _systemReducedMotion;
  bool get _canPlayGroupedSpl =>
      !_isDoubles && !_reducedBattleEffects &&
      _motionPolicy.effectIntensity == 1 && _motionPolicy.playbackSpeed == 1;

  void applyMotionPolicy(BattleMotionPolicy? policy, {double? legacyMotionScale}) {
    _motionPolicy = policy ?? BattleMotionPolicy.legacy(legacyMotionScale ?? motionScale);
    _hasExplicitMotionPolicy = policy != null;
    _fxLayer?.effectIntensity = _motionPolicy.effectIntensity;
    for (final actor in [_playerCombatant, _enemyCombatant,
      ..._additionalCombatants.values]) {
      actor?.setEffectIntensity(_motionPolicy.effectIntensity);
    }
    _syncReducedBattleEffects();
    if (_reducedBattleMotion) {
      _resetBattleCamera();
      for (final actor in [
        _playerCombatant, _enemyCombatant, ..._additionalCombatants.values,
      ]) {
        actor?.setIdleLateralOffset(0);
      }
    }
  }

  void _syncReducedBattleEffects() {
    final reduced = _reducedBattleEffects;
    if (_reducedEffectsApplied == reduced) return;
    _reducedEffectsApplied = reduced;
    if (!reduced) return;
    for (final actor in [_playerCombatant, _enemyCombatant,
      ..._additionalCombatants.values]) {
      actor?.reduceCurrentMotion();
    }
    _fxLayer?.reduceCurrentMotion();
  }

  /// Échelle de texte demandée par le joueur, transmise au panneau de commande.
  final double textScale;
  final bool _allowMedicineReserveTargets;
  bool _acceptsPlayerCommands = true;
  bool _preparingTurn = false;

  BattleSceneBackdropComponent? _backdrop;
  BattleSceneCombatantComponent? _enemyCombatant;
  BattleSceneCombatantComponent? _playerCombatant;
  BattleFxLayerComponent? _fxLayer;
  BattleDebugPanelComponent? _debugPanel;

  Future<void>? _pendingVisualSync;
  bool _visualSyncPending = false;

  void _trackVisualSync(Future<void> future) {
    _visualSyncPending = true;
    late final Future<void> tracked;
    tracked = future.whenComplete(() {
      if (identical(_pendingVisualSync, tracked)) _visualSyncPending = false;
    });
    _pendingVisualSync = tracked;
  }
  BattleAnimationPlan? _pendingTurnAudioPlan;
  _PendingTurnAudioPreparation? _pendingTurnAudioPreparation;
  _PendingTurnAudioPreparation? _turnAudioSettlement;
  final Map<String, _PreparedGroupedSpl> _groupedSplEffects = {};
  final Set<BattleVerifiedSplLoader> _groupedSplLoads = {};
  final Completer<void> _groupedSplClosed = Completer<void>();
  var _nextGroupedSplId = 0;
  // BETA-BAT-011 : le planner reçoit les MÊMES résolveurs que le HUD et le
  // menu. `late` parce qu'un initialiseur de champ ne peut pas lire `this`, et
  // c'est exactement pour ça que le plan d'animation s'en passait.
  late final BattleTurnAnimationPlanner _turnAnimationPlanner =
      BattleTurnAnimationPlanner(
    speciesDisplayName: resolveSpeciesDisplayName,
    moveDisplayName: resolveMoveDisplayName,
    resolveCombatantBallItemId: resolveCombatantBallItemId,
    announcesOutcome: false,
  );
  BattleAnimationRunner? _animationRunner;
  BattleSceneLayout? _sceneLayout;
  BattleAnimationPlan _activeAnimationPlan =
      const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
  Map<BattleSlotRef, BattleCameraMotionEnvelope> _cameraMotionEnvelopes = const {};
  int _cameraMotionEnvelopeRevision = 0;

  @visibleForTesting
  int get battleCameraMotionEnvelopeRevision => _cameraMotionEnvelopeRevision;

  @visibleForTesting
  Rect? battleCameraMotionEnvelope(BattleSlotRef slot) {
    final geometry = _combatantForSlot(slot)?.stableCameraGeometry;
    final layout = _sceneLayout;
    if (geometry == null || layout == null) return null;
    if (_reducedBattleEffects) return geometry.framingBounds;
    return _cameraMotionEnvelopes[slot]?.resolve(geometry,
      rmxpSceneScale: math.min(layout.stageRect.width / 320, layout.stageRect.height / 240)) ?? geometry.framingBounds;
  }

  void _installActiveAnimationPlan(BattleAnimationPlan plan) {
    _activeAnimationPlan = plan;
    _cameraMotionEnvelopes = compileBattleCameraMotionEnvelopes(plan);
    _cameraMotionEnvelopeRevision += 1;
  }
  Set<BattleSlotRef> _presentationLockedCombatantSlots = <BattleSlotRef>{};

  /// BETA-BAT-025 : le sauvage capturé reste dans sa Ball jusqu'au démontage
  /// du combat — la resynchronisation de fin de plan le remettrait debout.
  bool _capturedEnemyHeldInBall = false;

  /// BETA-BAT-028 : les barres d'info sont-elles entrées en scène ?
  ///
  /// Parité `show_team_info` : la référence les fait glisser APRÈS le message
  /// d'apparition. Faux seulement pendant l'intro, avant son step de
  /// révélation — tout autre chemin (pas d'intro, tours suivants) les garde
  /// visibles.
  bool _teamInfoRevealed = true;

  /// Joue le cri d'une espèce — BETA-BAT-028.
  ///
  /// Fourni par l'hôte, qui seul sait résoudre un fichier de la DONNÉE (les
  /// cris ne sont pas des assets embarqués). Nul chez un hôte sans banque de
  /// cris : l'étape ne fait alors rien.
  final void Function(String speciesId)? playCry;

  void _handlePlayCryStep(PlayCryStep step) {
    playCry?.call(step.speciesId);
  }

  void _handleShowTeamInfoStep() {
    if (_teamInfoRevealed) return;
    _teamInfoRevealed = true;
    _syncPanelsOnly();
  }

  /// Les côtés dont la pose d'ENTRÉE doit survivre à la synchronisation —
  /// recette du 2026-08-24. Rempli quand le plan d'intro est armé, vidé au
  /// démarrage de l'intro : à partir de là, c'est le plan qui pilote les
  /// sprites, et la sync de fin de plan les remet légitimement en place.
  Set<BattleSlotRef> _introHeldCombatantSlots = <BattleSlotRef>{};
  BattleCombatant? _displayedEnemyCombatant;
  BattleCombatant? _displayedPlayerCombatant;
  int _presentationGeneration = 0;
  BattlePerspectiveCamera? _perspectiveCamera;
  ({BattleSlotRef slot, int lineupIndex, String? combatantId})? _cameraFocusSubject;
  List<Object?>? _cameraFramingInputs;
  int _cameraFramingRevision = 0;
  BattleCameraShot? _cameraReturnShot;

  @visibleForTesting
  BattleCameraShot? get battleCameraReturnShot => _cameraReturnShot;

  @visibleForTesting
  int get battleCameraFramingRevision => _cameraFramingRevision;
  BattleStage3DComponent? _stage3D;
  final Map<BattleSlotRef, BattleIdleMotion> _idleMotions = {};

  BattleCommandMenuMode _menuMode = BattleCommandMenuMode.root;
  int _selectedRootIndex = 0;
  int _selectedChoiceIndex = 0;
  int _selectedPartyIndex = 0;
  int _selectedBagIndex = 0;
  int _selectedMedicineTargetIndex = 0;
  int _selectedMedicineMoveIndex = 0;
  String? _bagFeedbackMessage;
  BattleBagMenuActionMedicineTarget? _selectedMedicineAction;
  BattleEngineDecisionRequest? _selectedMedicineRequest;
  BattleCommandOverlaySnapshot? _currentCommandOverlaySnapshot;
  int _commandOverlayRevision = 0;
  final Map<String, String?> _bagIconAssetPathByItemId = <String, String?>{};
  final Map<String, Future<void>> _pendingBagIconPathsByItemId =
      <String, Future<void>>{};

  bool get acceptsPlayerCommands => _acceptsPlayerCommands;

  BattleGen5SourceProgramPlayback? _gen5SourceProgram;
  Completer<BattleGen5SourcePlaybackStatus>? _gen5SourceCompletion;
  void Function(BattleGen5SourcePlaybackStatus)? _gen5SourceDetach;
  FutureOr<void> Function(BattleGen5SourcePlaybackStatus)? _gen5SourceRelease;
  void Function()? _gen5SourceAdvance;
  double _gen5SourceTickElapsed = 0;
  bool _startingTrackedSourceEffect = false;

  BattleSplCameraProjection experimentalGen5DefenderProjection() =>
      experimentalGen5Projection(attacker: false);

  BattleSplCameraProjection experimentalGen5FieldProjection() {
    final camera = _perspectiveCamera;
    if (camera == null) {
      throw StateError('Experimental source camera is unavailable');
    }
    BattleSplCameraBinding binding(BattleSideId side) {
      final slot = BattleSlotRef.active(side);
      return BattleSplCameraBinding(
        resolveNeutralFoot: () => _geometryFor(slot).footAnchor,
        resolveAnchor: () {
          final projected = camera.tryBillboardAt(_geometryFor(slot).footAnchor);
          return projected == null
              ? null
              : Vector2(projected.position.dx, projected.position.dy);
        },
      );
    }

    final player = binding(BattleSideId.player);
    final enemy = binding(BattleSideId.enemy);
    final anchors = BattleSplCameraProjection(
      camera: camera, bindings: [player, enemy],
    ).capture();
    if (anchors == null) {
      throw StateError('Experimental source field is unavailable');
    }
    final dx = anchors.last.x - anchors.first.x;
    final dz = anchors.last.z - anchors.first.z;
    final spacing = math.sqrt(dx * dx + dz * dz) /
        math.sqrt(17 * 17 + math.pow(819 / 4096, 2));
    return BattleSplCameraProjection(
      camera: camera,
      bindings: [player],
      worldTransform: BattleSplWorldTransform(
        worldUnitsPerUnit: spacing,
        yawRadians: math.atan2(-819, -17 * 4096) - math.atan2(dx, dz),
      ),
    );
  }

  BattleSplCameraProjection experimentalGen5Projection({
    required bool attacker,
    bool towardOpponent = false,
    bool matchBattleSpacing = false,
    bool anchorAtFoot = false,
  }) {
    final camera = _perspectiveCamera;
    final slot = BattleSlotRef.active(
      attacker ? BattleSideId.player : BattleSideId.enemy,
    );
    final identity = _effectSubjectAt(slot);
    if (camera == null || identity == null) {
      throw StateError('Experimental source target is unavailable');
    }
    bool current() {
      final value = _effectSubjectAt(slot);
      return value != null && identical(value.actor, identity.actor) &&
          value.lineupIndex == identity.lineupIndex &&
          value.combatantId == identity.combatantId;
    }
    final binding = BattleSplCameraBinding(
      resolveNeutralFoot: () => current() ? _geometryFor(slot).footAnchor : null,
      resolveAnchor: () {
        if (!current()) return null;
        if (anchorAtFoot) {
          final foot = identity.actor.currentFootAnchor;
          return Vector2(foot.dx, foot.dy);
        }
        final rect = identity.actor.currentEffectAttachmentSpriteRect;
        return rect.isEmpty ? null : Vector2(rect.center.dx, rect.center.dy);
      },
    );
    final opponentSlot = BattleSlotRef.active(
      attacker ? BattleSideId.enemy : BattleSideId.player,
    );
    final opponent = _effectSubjectAt(opponentSlot);
    final bindings = [binding];
    if (towardOpponent || matchBattleSpacing) {
      if (opponent == null) {
        throw StateError('Experimental source opponent is unavailable');
      }
      bindings.add(BattleSplCameraBinding(
        resolveNeutralFoot: () => _geometryFor(opponentSlot).footAnchor,
        resolveAnchor: () {
          final value = _effectSubjectAt(opponentSlot);
          if (value == null || !identical(value.actor, opponent.actor) ||
              value.combatantId != opponent.combatantId ||
              value.lineupIndex != opponent.lineupIndex) return null;
          if (anchorAtFoot) {
            final foot = opponent.actor.currentFootAnchor;
            return Vector2(foot.dx, foot.dy);
          }
          final rect = opponent.actor.currentEffectAttachmentSpriteRect;
          return rect.isEmpty ? null : Vector2(rect.center.dx, rect.center.dy);
        },
      ));
    }
    final neutral = BattleSplCameraProjection(camera: camera, bindings: bindings);
    final anchors = neutral.capture();
    if (anchors == null) {
      throw StateError('Experimental source anchor is unavailable');
    }
    final spacing = matchBattleSpacing
        ? math.sqrt(math.pow(anchors.last.x - anchors.first.x, 2) +
            math.pow(anchors.last.z - anchors.first.z, 2)) /
            math.sqrt(17 * 17 + math.pow(819 / 4096, 2))
        : anchors.first.unit * 5;
    return BattleSplCameraProjection(
      camera: camera,
      bindings: [binding],
      worldTransform: BattleSplWorldTransform(
        worldUnitsPerUnit: spacing,
        yawRadians: towardOpponent
            ? math.atan2(-(anchors.last.x - anchors.first.x),
                anchors.last.z - anchors.first.z)
            : 0,
      ),
    );
  }

  Future<BattleGen5SourcePlaybackStatus> presentExperimentalGen5Attack({
    required Map<String, dynamic> program,
    required String variant,
    required bool Function(int particle, int emitter) hasEmitter,
    required void Function(int particle, int emitter, int offsetY) startEmitter,
    void Function(Map<String, dynamic> args)? startSourceEmitter,
    void Function(int particle)? deleteSourceParticle,
    required bool Function() particlesBusy,
    required void Function() detachParticles,
    required bool allowSilentAudio,
    Map<int, ui.Image> sourceBackgrounds = const {},
    Map<int, ({int background, List<ui.Image> frames, List<int> durations})>
        sourceBackgroundAnimations = const {},
    bool allowUnmappedAudioControls = false,
    bool allowOrthographicEmitters = false,
    bool allowFieldEmitters = false,
    bool allowSourceVisibility = false,
    bool allowApproximateFlatActors = false,
    bool adaptSourceCamera = false,
    bool duringTrackedEffect = false,
  }) {
    final camera = _perspectiveCamera;
    final userSlot = const BattleSlotRef.active(BattleSideId.player);
    final targetSlot = const BattleSlotRef.active(BattleSideId.enemy);
    final user = _effectSubjectAt(userSlot);
    final target = _effectSubjectAt(targetSlot);
    if (camera == null || user == null || target == null || _reducedBattleMotion) {
      throw StateError('Experimental source scene is unavailable');
    }
    final actors = {'EFFVM_ATTACKER': user, 'EFFVM_DEFENDER': target};
    final slots = {'EFFVM_ATTACKER': userSlot, 'EFFVM_DEFENDER': targetSlot};
    final paused = <BattleSceneCombatantComponent>{};
    final previouslyHidden = <String>{};
    final pauseOwner = Object();
    final visualOwner = Object();
    final sourceBackground = BattleGen5SourceBackground(
      viewport: () => Rect.fromLTWH(0, 0, size.x, size.y),
    );
    final initialPlatformsHidden = _stage3D?.sourceHidePlatforms ?? false;
    final initialFloorHidden = _stage3D?.sourceHideFloor ?? false;
    var backgroundAdded = false;
    int? currentSourceBackground;
    void attachBackground() {
      if (backgroundAdded) return;
      add(sourceBackground);
      backgroundAdded = true;
    }
    final paletteJobs = <String, ({int level, int end, int wait, int remaining,
        int step, Color color})>{};
    final alphaValues = <String, int>{};
    final alphaJobs = <String, ({int value, int target, int step, int wait,
        int remaining})>{};
    ({int level, int end, int wait, int remaining, int step, Color color})?
        stagePaletteJob;
    RectangleComponent? stagePalette;
    var stagePaletteTarget = 2;
    void setStagePalette(int level, Color color) {
      var component = stagePalette;
      if (component == null) {
        component = RectangleComponent(size: size.clone(), priority: 1);
        stagePalette = component;
        add(component);
      }
      component.size = size.clone();
      component.priority = switch (stagePaletteTarget) {3 => 3, 4 => 14, _ => 1};
      component.paint.color = color.withValues(alpha: level / 16);
    }
    final sourceCamera = Gen5CameraMotion();
    final initialEye = camera.eye;
    final initialAim = camera.aim;
    BattleSplWorldTransform? cameraTransform;
    if (adaptSourceCamera) {
      final from = camera.tryGroundAt(_geometryFor(userSlot).footAnchor);
      final to = camera.tryGroundAt(_geometryFor(targetSlot).footAnchor);
      if (from == null || to == null) {
        throw StateError('Experimental camera anchors are unavailable');
      }
      final dx = to.x - from.x;
      final dz = to.z - from.z;
      const sourceDx = -819 / 4096;
      const sourceDz = -17.0;
      cameraTransform = BattleSplWorldTransform(
        worldUnitsPerUnit: math.sqrt(dx * dx + dz * dz) /
            math.sqrt(sourceDx * sourceDx + sourceDz * sourceDz),
        yawRadians: math.atan2(-dx, dz) - math.atan2(-sourceDx, sourceDz),
      );
      if (!cameraTransform.isValid) {
        throw StateError('Experimental camera transform is unavailable');
      }
    }
    bool current(String key) {
      final identity = actors[key]!;
      final value = _effectSubjectAt(slots[key]!);
      return value != null && identical(value.actor, identity.actor) &&
          value.lineupIndex == identity.lineupIndex &&
          value.combatantId == identity.combatantId;
    }
    final motion = BattleGen5ActorMotionController(
      claim: (actor, owner) {
        final key = actor as String;
        if (!current(key)) return false;
        final component = actors[key]!.actor;
        return component.ownsBattleScriptTransform(owner) ||
            component.applyBattleScriptTransform(
              offset: Offset.zero, scaleX: 1, scaleY: 1, owner: owner);
      },
      apply: (actor, owner, pose) {
        final key = actor as String;
        if (!current(key)) return false;
        var offset = Offset(pose.offsetXFx32 / 4096 * 5,
            -pose.offsetYFx32 / 4096 * 5);
        var depthScale = 1.0;
        if (pose.spatialOffset) {
          final transform = cameraTransform;
          final foot = _geometryFor(slots[key]!).footAnchor;
          final ground = camera.tryGroundAt(foot);
          final billboard = camera.tryBillboardAt(foot);
          if (transform == null || ground == null || billboard == null ||
              billboard.scale <= 0) return false;
          final origin = camera.tryProject(ground);
          final displaced = camera.tryProject(ground + transform.apply((
            x: pose.offsetXFx32,
            y: pose.offsetYFx32,
            z: pose.offsetZFx32,
          )));
          if (origin == null || displaced == null) return false;
          offset = (displaced.position - origin.position) / billboard.scale;
          depthScale = origin.depth / displaced.depth;
        }
        return actors[key]!.actor.applyBattleScriptTransform(
          offset: offset,
          scaleX: pose.scaleXFx32 / 4096 * depthScale,
          scaleY: pose.scaleYFx32 / 4096 * depthScale,
          rotation: pose.rotationFx32 * (2 * math.pi / (4096 * 65536)),
          owner: owner,
        );
      },
      release: (actor, owner) =>
          actors[actor as String]!.actor.clearBattleScriptTransform(owner: owner),
    );
    bool bounded(Object? value, int min, int max) =>
        value is int && value >= min && value <= max;
    String? admit(BattleGen5SourceInstruction instruction) {
      final args = instruction.args;
      bool safeScaleShake() {
        final frames = args['frames'] as int;
        final wait = args['wait'] as int;
        final times = args['times'] as int;
        bool valid(Object? value) => bounded(value, -4095, 4095) &&
            (battleGen5SwingStep(value as int, frames) * frames).abs() <= 4095;
        return times <= 32 && valid(args['x']) && valid(args['y']) &&
            frames * 4 * times * (wait + 1) - wait <= 1800;
      }
      switch (instruction.op) {
        case 'moveCameraPreset':
          return args['moveType'] == 1 &&
                  ({8, 9, 11}.contains(args['camera']) ||
                      (!_isDoubles && {10, 12, 14, 15, 16, 17, 21}.contains(args['camera'])) ||
                      (args['camera'] == 20 && allowApproximateFlatActors)) &&
                  bounded(args['frames'], 0, 524287) &&
                  bounded(args['wait'], 0, 2147483647) &&
                  bounded(args['brake'], 0, 2147483647)
              ? null : 'unsupported camera preset';
        case 'moveCameraRelative':
        case 'moveCameraAbsolute':
          return !_isDoubles &&
                  args['moveType'] == (instruction.op == 'moveCameraAbsolute' ? 1 : 2) &&
                  ['x', 'y', 'z', 'targetX', 'targetY', 'targetZ']
                      .every((field) => bounded(args[field], -131072, 131072)) &&
                  bounded(args['frames'], 1, 600) &&
                  bounded(args['wait'], 0, 600) && bounded(args['brake'], 0, 600)
              ? null : 'unsupported relative camera movement';
        case 'shakeCamera':
          return {0, 1}.contains(args['direction']) &&
                  bounded(args['frames'], 1, 600) &&
                  bounded(args['amplitude'], -28672, 28672) &&
                  bounded(args['unused'], -2147483648, 2147483647) &&
                  bounded(args['wait'], 0, 600) &&
                  bounded(args['count'], 1, 64) &&
                  (args['frames'] as int) * 4 * (args['count'] as int) *
                          ((args['wait'] as int) + 1) - (args['wait'] as int) <=
                      1800
              ? null : 'unsupported camera shake';
        case 'moveCombatant':
        case 'scaleCombatant':
          final scaleStep = instruction.op == 'scaleCombatant' && args['type'] == 1;
          final positionStep = instruction.op == 'moveCombatant' &&
              (args['type'] == 1 || args['type'] == 5);
          final step = scaleStep || positionStep;
          return actors.containsKey(args['targets']) &&
                  (step || args['type'] == 2 || args['type'] == 3) &&
                  bounded(args['x'], scaleStep ? 1 : positionStep ? -131072 : -28672,
                      scaleStep ? 32768 : positionStep ? 131072 : 28672) &&
                  bounded(args['y'], scaleStep ? 1 : positionStep ? -131072 : -28672,
                      scaleStep ? 32768 : positionStep ? 131072 : 28672) &&
                  bounded(args['frames'], 1, 600) &&
                  bounded(args['wait'], 0, 600) &&
                  bounded(args['times'], step ? 0 : 1, step ? 32 : 64) &&
                  (!step || (args['frames'] as int) * ((args['wait'] as int) + 1) <= 900) &&
                  (args['type'] != 3 ||
                      (instruction.op == 'scaleCombatant'
                          ? safeScaleShake()
                          : (args['times'] as int) <= 32 &&
                              (args['frames'] as int) * 4 * (args['times'] as int) *
                                  ((args['wait'] as int) + 1) - (args['wait'] as int) <= 1800))
              ? null : 'unsupported combatant motion';
        case 'circleCombatant':
          if (_isDoubles || cameraTransform == null ||
              !actors.containsKey(args['targets']) ||
              !bounded(args['mode'], 0, 5) ||
              !bounded(args['start'], 0, 3) ||
              !bounded(args['radius1'], -32768, 32768) ||
              !bounded(args['radius2'], -32768, 32768) ||
              !bounded(args['frames'], 1, 600) ||
              !bounded(args['wait'], 0, 600) ||
              !bounded(args['count'], 1, 32) ||
              !bounded(args['turnWait'], 0, 600) ||
              !bounded(args['framesFx32'], 4096, 600 * 4096 + 4095) ||
              !bounded(args['waitFx32'], 0, 600 * 4096 + 4095) ||
              !bounded(args['countFx32'], 4096, 32 * 4096 + 4095) ||
              args['frames'] != (args['framesFx32'] as int) >> 12 ||
              args['wait'] != (args['waitFx32'] as int) >> 12 ||
              args['count'] != (args['countFx32'] as int) >> 12) {
            return 'unsupported circular combatant motion';
          }
          final frames = args['frames'] as int;
          final wait = args['wait'] as int;
          final count = args['count'] as int;
          final turnWait = args['turnWait'] as int;
          final speed = 65536 ~/ frames;
          return (65536 ~/ speed + 1) * count * (wait + 1) +
                      (count - 1) * turnWait <=
                  1800
              ? null : 'circular combatant motion is too long';
        case 'rotateCombatant':
          return actors.containsKey(args['targets']) && {2, 3}.contains(args['type']) &&
                  bounded(args['angle'], -268435456, 268435456) &&
                  bounded(args['frames'], 1, 600) &&
                  bounded(args['wait'], 0, 600) &&
                  bounded(args['times'], 1, 32) &&
                  (args['frames'] as int) * (args['type'] == 3 ? 4 : 2) * (args['times'] as int) *
                          ((args['wait'] as int) + 1) - (args['wait'] as int) <=
                      1800
              ? null : 'unsupported combatant rotation';
        case 'setAnimationState':
          return (actors.containsKey(args['targets']) ||
                      (!_isDoubles && args['targets'] == 'EFFVM_ALL')) &&
                  (args['mode'] == 0 || args['mode'] == 1)
              ? null : 'unsupported animation state';
        case 'setActorCameraMode':
          return !_isDoubles && allowApproximateFlatActors &&
                  args['mode'] == 0 && args['scope'] == 0
              ? null : 'actor camera mode unavailable';
        case 'setCombatantVisibility':
          return !_isDoubles && allowSourceVisibility &&
                  actors.containsKey(args['targets']) && {3, 4}.contains(args['mode'])
              ? null : 'unsupported combatant visibility';
        case 'fadeCombatantAlpha':
          return !_isDoubles && allowSourceVisibility &&
                  actors.containsKey(args['targets']) && {0, 1}.contains(args['type']) &&
                  bounded(args['alpha'], 0, 31) && bounded(args['frames'], 1, 600) &&
                  bounded(args['wait'], 0, 600) && bounded(args['times'], 0, 32) &&
                  (args['frames'] as int) * ((args['wait'] as int) + 1) <= 1800
              ? null : 'unsupported combatant alpha';
        case 'loadParticle':
          return bounded(args['particle'], 0, 65535)
              ? null : 'unsupported particle';
        case 'deleteParticle':
          return deleteSourceParticle != null && bounded(args['particle'], 0, 65535)
              ? null : 'particle deletion unavailable';
        case 'startEmitter':
          final particle = args['particle'];
          final emitter = args['emitter'];
          return particle is int && emitter is int &&
                  hasEmitter(particle, emitter) &&
                  (startSourceEmitter == null
                      ? args['from'] == 'EFFVM_EMIT_DEFENDER' && args['to'] == 8
                      : !_isDoubles &&
                          {0, 'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'}
                              .contains(args['from']) &&
                          {8, 'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'}
                              .contains(args['to'])) &&
                  bounded(args['offsetY'], -2147483648, 2147483647) &&
                  (startSourceEmitter == null
                      ? args['unk18'] == 0 && args['unused'] == 0 &&
                          args['radiusScale'] == 4096 && args['lifeScale'] == 4096 &&
                          args['scaleScale'] == 4096 && args['cameraScale'] == 4096
                      : bounded(args['unk18'], 0, 4294967295) &&
                          bounded(args['unused'], 0, 4294967295) &&
                          bounded(args['radiusScale'], 0, 8192) &&
                          bounded(args['lifeScale'], 0, 8192) &&
                          bounded(args['scaleScale'], 0, 8192) &&
                          bounded(args['cameraScale'], 0, 12288))
              ? null : 'unsupported emitter';
        case 'startOrthoEmitter':
          final particle = args['particle'];
          final emitter = args['emitter'];
          final unscaled = args['from'] == 0 || args['from'] == 'EFFVM_EMIT_ATTACKER';
          return !_isDoubles && allowOrthographicEmitters &&
                  startSourceEmitter != null &&
                  particle is int && emitter is int &&
                  hasEmitter(particle, emitter) &&
                  {0, 'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'}
                      .contains(args['from']) &&
                  {8, 'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'}
                      .contains(args['to']) &&
                  bounded(args['offsetX'], -65536, 65536) &&
                  bounded(args['offsetY'], -65536, 65536) &&
                  bounded(args['offsetZ'], -65536, 65536) &&
                  bounded(args['radiusScale'], 0, 8192) &&
                  bounded(args['lifeScale'], 0, 8192) &&
                  bounded(args['scaleScale'], 0, 8192) &&
                  (unscaled || {0, 4096}.contains(args['cameraScale'])) &&
                  bounded(args['cameraScale'], 0, 8192)
              ? null : 'unsupported orthographic emitter';
        case 'startFieldEmitter':
          final particle = args['particle'];
          final emitter = args['emitter'];
          return !_isDoubles && allowFieldEmitters && startSourceEmitter != null &&
                  particle is int && emitter is int && hasEmitter(particle, emitter) &&
                  ['fromX', 'fromY', 'fromZ', 'toX', 'toY', 'toZ', 'offsetY']
                      .every((field) => bounded(args[field], -131072, 131072)) &&
                  bounded(args['unk18'], 0, 4294967295) &&
                  bounded(args['unused'], 0, 4294967295) &&
                  bounded(args['radiusScale'], 0, 8192) &&
                  bounded(args['lifeScale'], 0, 8192) &&
                  bounded(args['scaleScale'], 0, 8192) &&
                  {0, 4096}.contains(args['cameraScale'])
              ? null : 'unsupported field emitter';
        case 'startMovingEmitter':
        case 'startMovingFieldEmitter':
          final particle = args['particle'];
          final emitter = args['emitter'];
          final fieldOrigin = instruction.op == 'startMovingFieldEmitter';
          return startSourceEmitter != null &&
                  particle is int && emitter is int &&
                  hasEmitter(particle, emitter) &&
                  {1, 2, 5, 6}.contains(args['motion']) &&
                  (!{5, 6}.contains(args['motion']) ||
                      bounded(args['turns'], 0, 32768)) &&
                  {'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'}.contains(args['to']) &&
                  (fieldOrigin
                      ? !_isDoubles && allowFieldEmitters &&
                          ['fromX', 'fromY', 'fromZ'].every(
                              (field) => bounded(args[field], -131072, 131072))
                      : {'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'}
                              .contains(args['from']) && args['from'] != args['to']) &&
                  bounded(args['offsetY'], -2147483648, 2147483647) &&
                  bounded(args['height'], -2147483648, 2147483647) &&
                  bounded(args['turns'], -2147483648, 2147483647) &&
                  (args['motionFramesFx32'] == 0 ||
                      bounded(args['motionFramesFx32'], 4096, 600 * 4096)) &&
                  args['motionFrames'] == ((args['motionFramesFx32'] as int) >> 12) &&
                  bounded(args['lifeScale'], 0, 8192) &&
                  {0, 4096}.contains(args['cameraScale'])
              ? null : 'unsupported moving emitter';
        case 'setShadow':
          return (args['targets'] == 'EFFVM_ALL' || actors.containsKey(args['targets'])) &&
                  (args['value'] == 0 || args['value'] == 1)
              ? null : 'unsupported shadow';
        case 'fadePalette':
          return (actors.containsKey(args['targets']) ||
                      (!_isDoubles && args['targets'] == 'EFFVM_ALL')) &&
                  bounded(args['startEvy'], 0, 16) &&
                  bounded(args['endEvy'], 0, 16) &&
                  bounded(args['wait'], 0, 600) &&
                  bounded(args['color'], 0, 32767)
              ? null : 'unsupported palette fade';
        case 'fadeStagePalette':
          return ({2, 4}.contains(args['fade']) ||
                      (sourceBackgrounds.isNotEmpty && args['fade'] == 3)) &&
                  bounded(args['evy'], 0, 16) &&
                  bounded(args['targetEvy'], 0, 16) &&
                  bounded(args['wait'], 0, 600) &&
                  bounded(args['color'], 0, 32767)
              ? null : 'unsupported stage palette fade';
        case 'loadBackground':
          final id = args['background'];
          final image = id is int ? sourceBackgrounds[id] : null;
          return image != null && image.width == 512 && image.height == 512
              ? null : 'source background unavailable';
        case 'moveBackground':
          if (sourceBackgrounds.isEmpty ||
              !bounded(args['x'], -512, 512) ||
              !bounded(args['y'], -512, 512)) {
            return 'unsupported background motion';
          }
          if (args['mode'] == 4) {
            return bounded(args['frames'], 0, 60000) &&
                    bounded(args['wait'], 0, 600) && bounded(args['count'], 0, 32)
                ? null : 'unsupported background scroll';
          }
          if (args['mode'] == 1 && bounded(args['frames'], 1, 600) &&
              bounded(args['wait'], 0, 600) && bounded(args['count'], 0, 32) &&
              (args['frames'] as int) * ((args['wait'] as int) + 1) <= 1800) {
            return null;
          }
          if (args['mode'] == 2 && bounded(args['frames'], 1, 600) &&
              bounded(args['wait'], 0, 600) && bounded(args['count'], 1, 32) &&
              (args['frames'] as int) * 2 * (args['count'] as int) *
                      ((args['wait'] as int) + 1) - (args['wait'] as int) <= 1800) {
            return null;
          }
          return 'unsupported background motion';
        case 'waveBackground':
          return sourceBackgrounds.isNotEmpty &&
                  {0, 1}.contains(args['mode']) &&
                  bounded(args['amplitude'], 0, 65536) &&
                  bounded(args['step'], 1, 360) &&
                  bounded(args['frames'], 1, 600) &&
                  args['fadeMode'] == 0 && args['fadeFrames'] == 0
              ? null : 'unsupported background wave';
        case 'setSceneVisibility':
          return ({0, 1}.contains(args['target']) ||
                      (sourceBackgrounds.isNotEmpty && args['target'] == 2)) &&
                  {0, 1}.contains(args['hide'])
              ? null : 'unsupported scene visibility';
        case 'animateBackgroundPalette':
          final id = args['animation'];
          final animation = id is int ? sourceBackgroundAnimations[id] : null;
          return animation != null &&
                  sourceBackgrounds.containsKey(animation.background) &&
                  animation.frames.isNotEmpty && animation.frames.length <= 32 &&
                  animation.frames.length == animation.durations.length &&
                  animation.frames.every((image) => image.width == 512 && image.height == 512) &&
                  animation.durations.every((duration) => duration >= 0 && duration <= 255) &&
                  bounded(args['loops'], 0, 32)
              ? null : 'unsupported background palette animation';
        case 'playCry':
        case 'playSound':
          return allowSilentAudio ? null : 'source audio unavailable';
        case 'panSound':
        case 'moveSound':
          return allowSilentAudio && allowUnmappedAudioControls
              ? null : 'source audio controls unavailable';
        default:
          return 'operation not connected to this scene';
      }
    }
    BattleGen5SourceDispatchResult dispatch(BattleGen5SourceInstruction instruction) {
      final args = instruction.args;
      switch (instruction.op) {
        case 'moveCameraPreset':
          sourceCamera.applyPreset(
            preset: args['camera'] as int,
            attacker: Gen5CameraSlot.player,
            defender: Gen5CameraSlot.enemy,
            frames: args['frames'] as int,
            wait: args['wait'] as int,
            brake: args['brake'] as int,
          );
        case 'moveCameraRelative':
        case 'moveCameraAbsolute':
          final move = instruction.op == 'moveCameraAbsolute'
              ? sourceCamera.moveAbsolute : sourceCamera.moveRelative;
          move(
            position: (x: args['x'] as int, y: args['y'] as int, z: args['z'] as int),
            target: (x: args['targetX'] as int, y: args['targetY'] as int,
                z: args['targetZ'] as int),
            frames: args['frames'] as int, wait: args['wait'] as int,
            brake: args['brake'] as int,
          );
        case 'shakeCamera':
          final shake = args['direction'] == 1
              ? sourceCamera.shakeHorizontal
              : sourceCamera.shakeVertical;
          shake(
            amplitude: args['amplitude'] as int,
            frames: args['frames'] as int,
            wait: args['wait'] as int,
            count: args['count'] as int,
          );
        case 'moveCombatant':
        case 'scaleCombatant':
        case 'rotateCombatant':
          final key = args['targets'] as String;
          motion.start(
            actor: key,
            channel: instruction.op == 'moveCombatant'
                ? BattleGen5ActorMotionChannel.position
                : instruction.op == 'scaleCombatant'
                    ? BattleGen5ActorMotionChannel.scale
                    : BattleGen5ActorMotionChannel.rotation,
            type: args['type'] as int,
            xFx32: (instruction.op == 'rotateCombatant'
                ? args['angle']
                : args['x']) as int,
            yFx32: instruction.op == 'rotateCombatant' ? 0 : args['y'] as int,
            frames: args['frames'] as int,
            wait: args['wait'] as int,
            times: args['times'] as int,
            mirrorX: instruction.op != 'scaleCombatant' &&
                slots[key]!.side == BattleSideId.enemy,
          );
        case 'circleCombatant':
          final key = args['targets'] as String;
          motion.startCircle(
            actor: key,
            mode: args['mode'] as int,
            start: args['start'] as int,
            radius1Fx32: args['radius1'] as int,
            radius2Fx32: args['radius2'] as int,
            frames: args['frames'] as int,
            wait: args['wait'] as int,
            count: args['count'] as int,
            turnWait: args['turnWait'] as int,
            mirror: slots[key]!.side == BattleSideId.enemy,
          );
        case 'setAnimationState':
          final keys = args['targets'] == 'EFFVM_ALL'
              ? actors.keys : [args['targets'] as String];
          for (final key in keys) {
            if (!current(key)) throw StateError('Battle actor changed');
            final actor = actors[key]!.actor;
            if (args['mode'] == 1) {
              actor.pauseBattleSpriteAnimation(owner: pauseOwner);
              paused.add(actor);
            } else {
              actor.resumeBattleSpriteAnimation(owner: pauseOwner);
              paused.remove(actor);
            }
          }
        case 'setCombatantVisibility':
          final key = args['targets'] as String;
          if (!current(key)) throw StateError('Battle actor changed');
          final actor = actors[key]!.actor;
          if (args['mode'] == 3) {
            if (actor.isHiddenForBattleScript) previouslyHidden.add(key);
            actor.setBattleScriptHidden(true, owner: visualOwner);
          } else if (!previouslyHidden.remove(key)) {
            actor.setBattleScriptHidden(false, owner: visualOwner);
          }
        case 'fadeCombatantAlpha':
          final key = args['targets'] as String;
          if (!current(key)) throw StateError('Battle actor changed');
          final start = (alphaValues[key] ?? 31) << 12;
          final target = (args['alpha'] as int) << 12;
          final difference = target - start;
          var step = args['type'] == 0 ? difference : battleGen5SwingStep(
            difference, args['frames'] as int, maxDelta: 31 * 4096,
          );
          if (step == 0 && difference != 0) step = difference.sign;
          alphaJobs[key] = (value: start, target: target, step: step,
              wait: args['wait'] as int, remaining: 0);
        case 'startEmitter':
        case 'startFieldEmitter':
        case 'startOrthoEmitter':
        case 'startMovingEmitter':
        case 'startMovingFieldEmitter':
          if (startSourceEmitter != null) {
            startSourceEmitter(args);
          } else {
            startEmitter(args['particle'] as int, args['emitter'] as int,
                args['offsetY'] as int);
          }
        case 'setShadow':
          final keys = args['targets'] == 'EFFVM_ALL'
              ? actors.keys : [args['targets'] as String];
          for (final key in keys) {
            if (!current(key)) throw StateError('Battle actor changed');
            actors[key]!.actor.setBattleScriptShadowHidden(
              args['value'] == 1, owner: visualOwner);
          }
        case 'fadePalette':
          final keys = args['targets'] == 'EFFVM_ALL'
              ? actors.keys : [args['targets'] as String];
          final value = args['color'] as int;
          final start = args['startEvy'] as int;
          final end = args['endEvy'] as int;
          for (final key in keys) {
            if (!current(key)) throw StateError('Battle actor changed');
            paletteJobs[key] = (level: start, end: end, wait: args['wait'] as int,
              remaining: 0, step: start <= end ? 1 : -1,
              color: Color.fromARGB(255, (value & 31) * 255 ~/ 31,
                ((value >> 5) & 31) * 255 ~/ 31,
                ((value >> 10) & 31) * 255 ~/ 31));
          }
        case 'fadeStagePalette':
          final value = args['color'] as int;
          final start = args['evy'] as int;
          final end = args['targetEvy'] as int;
          final color = Color.fromARGB(255, (value & 31) * 255 ~/ 31,
              ((value >> 5) & 31) * 255 ~/ 31,
              ((value >> 10) & 31) * 255 ~/ 31);
          stagePaletteTarget = args['fade'] as int;
          setStagePalette(start, color);
          stagePaletteJob = start == end ? null : (level: start, end: end,
              wait: args['wait'] as int, remaining: 0,
              step: start < end ? 1 : -1, color: color);
        case 'loadBackground':
          sourceBackground.load(sourceBackgrounds[args['background']]!);
          currentSourceBackground = args['background'] as int;
          attachBackground();
        case 'moveBackground':
          if (args['mode'] == 4) {
            sourceBackground.scroll(x: args['x'] as int, y: args['y'] as int,
                frames: args['frames'] as int);
          } else if (args['mode'] == 1) {
            sourceBackground.move(x: args['x'] as int, y: args['y'] as int,
                frames: args['frames'] as int, wait: args['wait'] as int);
          } else {
            sourceBackground.swing(x: args['x'] as int, y: args['y'] as int,
                frames: args['frames'] as int, wait: args['wait'] as int,
                count: args['count'] as int);
          }
        case 'waveBackground':
          sourceBackground.startWave(mode: args['mode'] as int,
              amplitude: args['amplitude'] as int, step: args['step'] as int,
              frames: args['frames'] as int);
        case 'setSceneVisibility':
          final hidden = args['hide'] == 1;
          switch (args['target']) {
            case 0:
              _stage3D?.sourceHidePlatforms = hidden;
            case 1:
              _stage3D?.sourceHideFloor = hidden;
              sourceBackground.hideField = hidden;
              if (hidden) attachBackground();
            case 2:
              sourceBackground.visible = !hidden;
          }
        case 'animateBackgroundPalette':
          final animation = sourceBackgroundAnimations[args['animation']]!;
          if (currentSourceBackground != animation.background) {
            throw StateError('Background palette does not match the loaded background');
          }
          sourceBackground.animatePalette(frames: animation.frames,
              durations: animation.durations, loops: args['loops'] as int);
        case 'deleteParticle':
          deleteSourceParticle!(args['particle'] as int);
        case 'loadParticle':
        case 'setActorCameraMode':
        case 'playCry':
        case 'playSound':
        case 'panSound':
        case 'moveSound':
          break;
        default:
          throw StateError('Unsupported source instruction');
      }
      return BattleGen5SourceDispatchResult.completed;
    }
    void advance() {
      motion.tick();
      sourceBackground.tick();
      for (final entry in alphaJobs.entries.toList()) {
        final job = entry.value;
        if (!current(entry.key)) throw StateError('Battle actor changed');
        if (job.remaining > 0) {
          alphaJobs[entry.key] = (value: job.value, target: job.target,
              step: job.step, wait: job.wait, remaining: job.remaining - 1);
          continue;
        }
        final value = job.step < 0
            ? math.max(job.target, job.value + job.step)
            : math.min(job.target, job.value + job.step);
        final alpha = value >> 12;
        actors[entry.key]!.actor.setBattleScriptAlpha(alpha, owner: visualOwner);
        alphaValues[entry.key] = alpha;
        if (value == job.target) {
          alphaJobs.remove(entry.key);
        } else {
          alphaJobs[entry.key] = (value: value, target: job.target,
              step: job.step, wait: job.wait, remaining: job.wait);
        }
      }
      final stageJob = stagePaletteJob;
      if (stageJob != null) {
        if (stageJob.remaining > 0) {
          stagePaletteJob = (level: stageJob.level, end: stageJob.end,
              wait: stageJob.wait, remaining: stageJob.remaining - 1,
              step: stageJob.step, color: stageJob.color);
        } else {
          final level = stageJob.level + stageJob.step;
          setStagePalette(level, stageJob.color);
          stagePaletteJob = level == stageJob.end ? null : (level: level,
              end: stageJob.end, wait: stageJob.wait,
              remaining: stageJob.wait, step: stageJob.step,
              color: stageJob.color);
        }
      }
      for (final entry in paletteJobs.entries.toList()) {
        final job = entry.value;
        if (!current(entry.key)) throw StateError('Battle actor changed');
        if (job.remaining > 0) {
          paletteJobs[entry.key] = (level: job.level, end: job.end,
            wait: job.wait, remaining: job.remaining - 1, step: job.step,
            color: job.color);
        } else {
          actors[entry.key]!.actor.setBattleScriptPalette(
            owner: visualOwner, level: job.level, color: job.color);
          if (job.level == job.end) {
            paletteJobs.remove(entry.key);
          } else {
            paletteJobs[entry.key] = (level: job.level + job.step, end: job.end,
              wait: job.wait, remaining: job.wait, step: job.step, color: job.color);
          }
        }
      }
      final pose = sourceCamera.tick();
      BattleCameraPoint position(Gen5CameraVector value, Gen5CameraVector base,
          BattleCameraPoint initial) {
        final transform = cameraTransform;
        if (transform == null) {
          return BattleCameraPoint(value.x / 4096, value.y / 4096, value.z / 4096);
        }
        return initial + transform.apply((x: value.x - base.x,
          y: value.y - base.y, z: value.z - base.z));
      }
      camera.moveTo(
        eye: position(pose.position, Gen5CameraMotion.defaultPose.position, initialEye),
        aim: position(pose.target, Gen5CameraMotion.defaultPose.target, initialAim),
        durationSeconds: 0,
      );
      _applyBattleCameraTransform();
    }
    final playback = BattleGen5SourceProgramPlayback(
      program: program,
      variant: variant,
      admit: admit,
      dispatch: dispatch,
      isBusy: (category) => switch (category) {
        BattleGen5SourceTaskCategory.camera => sourceCamera.isMoving,
        BattleGen5SourceTaskCategory.mcss => motion.isBusy || alphaJobs.isNotEmpty,
        BattleGen5SourceTaskCategory.background => sourceBackground.isMoving,
        BattleGen5SourceTaskCategory.backgroundWave => sourceBackground.isWaving,
        BattleGen5SourceTaskCategory.palette =>
          paletteJobs.isNotEmpty || stagePaletteJob != null ||
              sourceBackground.isPaletteAnimating,
        BattleGen5SourceTaskCategory.stageFieldPalette => stagePaletteJob != null,
        BattleGen5SourceTaskCategory.particles => particlesBusy(),
        _ => false,
      },
      isParticleLoading: () => false,
    );
    return presentGen5SourceProgram(playback, advance: advance,
        duringTrackedEffect: duringTrackedEffect, detach: (status) {
      if (status == BattleGen5SourcePlaybackStatus.failed) {
        debugPrint('[battle] source program failed at instruction '
            '${playback.instructionIndex}: ${playback.diagnostic}');
      }
      try {
        motion.cancel();
      } finally {
        try {
          for (final actor in paused) {
            actor.resumeBattleSpriteAnimation(owner: pauseOwner);
          }
          paused.clear();
          for (final actor in actors.values) {
            actor.actor.setBattleScriptShadowHidden(false, owner: visualOwner);
            actor.actor.setBattleScriptHidden(false, owner: visualOwner);
            actor.actor.clearBattleScriptAlpha(owner: visualOwner);
            actor.actor.clearBattleScriptPalette(owner: visualOwner);
          }
          paletteJobs.clear();
          alphaJobs.clear();
          stagePaletteJob = null;
          stagePalette?.removeFromParent();
          stagePalette = null;
          sourceBackground.reset();
          if (backgroundAdded) sourceBackground.removeFromParent();
          _stage3D?.sourceHidePlatforms = initialPlatformsHidden;
          _stage3D?.sourceHideFloor = initialFloorHidden;
        } finally {
          try {
            detachParticles();
          } finally {
            _resetBattleCamera();
          }
        }
      }
    });
  }

  Future<BattleGen5SourcePlaybackStatus> presentGen5SourceProgram(
    BattleGen5SourceProgramPlayback playback, {
    required void Function(BattleGen5SourcePlaybackStatus) detach,
    FutureOr<void> Function(BattleGen5SourcePlaybackStatus)? release,
    void Function()? advance,
    bool duringTrackedEffect = false,
  }) {
    final tracked = duringTrackedEffect && _startingTrackedSourceEffect &&
        (_animationRunner?.isActive ?? false);
    if (_ballImagesDisposed ||
        !isLoaded ||
        _visualSyncPending ||
        _gen5SourceCompletion != null ||
        _preparingTurn ||
        _pendingIntroPlan != null ||
        (!tracked && (_animationRunner?.isActive ?? false)) ||
        (!tracked && _activeAnimationPlan.steps.isNotEmpty) ||
        (duringTrackedEffect && !tracked) ||
        playback.status != BattleGen5SourcePlaybackStatus.ready) {
      throw StateError('Battle scene cannot start the source program');
    }
    final completion = Completer<BattleGen5SourcePlaybackStatus>();
    if (!tracked) _resetSceneClock();
    _gen5SourceProgram = playback;
    _gen5SourceCompletion = completion;
    _gen5SourceDetach = detach;
    _gen5SourceRelease = release;
    _gen5SourceAdvance = advance;
    _gen5SourceTickElapsed = 0;
    _syncPanelsOnly();
    return completion.future;
  }

  void cancelExperimentalGen5Attack() => _cancelGen5SourceProgram();

  void _finishGen5SourceProgram(BattleGen5SourceProgramPlayback playback, {
    bool syncPanels = true,
    Object? failure,
    StackTrace? failureStack,
  }) {
    if (!identical(_gen5SourceProgram, playback)) return;
    _gen5SourceProgram = null;
    _gen5SourceTickElapsed = 0;
    final completion = _gen5SourceCompletion;
    final detach = _gen5SourceDetach;
    _gen5SourceDetach = null;
    final release = _gen5SourceRelease;
    _gen5SourceRelease = null;
    _gen5SourceAdvance = null;
    try {
      detach?.call(playback.status);
    } on Object catch (error, stack) {
      failure ??= error;
      failureStack ??= stack;
    }
    unawaited(Future<void>.sync(() => release?.call(playback.status)).then<void>(
      (_) {
        if (identical(_gen5SourceCompletion, completion)) {
          _gen5SourceCompletion = null;
        }
        if (completion != null && !completion.isCompleted) {
          if (failure == null) {
            completion.complete(playback.status);
          } else {
            completion.completeError(failure, failureStack);
          }
        }
        if (syncPanels && !_ballImagesDisposed) _syncPanelsOnly();
      },
      onError: (Object error, StackTrace stack) {
        if (identical(_gen5SourceCompletion, completion)) {
          _gen5SourceCompletion = null;
        }
        if (completion != null && !completion.isCompleted) {
          completion.completeError(failure ?? error, failureStack ?? stack);
        }
        if (syncPanels && !_ballImagesDisposed) _syncPanelsOnly();
      }
    ));
  }

  void _cancelGen5SourceProgram({bool syncPanels = true}) {
    final playback = _gen5SourceProgram;
    if (playback == null) return;
    try {
      playback.cancel();
      _finishGen5SourceProgram(playback, syncPanels: syncPanels);
    } on Object catch (error, stack) {
      _finishGen5SourceProgram(playback, syncPanels: syncPanels,
        failure: error, failureStack: stack);
    }
  }

  void beginTurnPreparation() {
    if (_preparingTurn) return;
    _preparingTurn = true;
    _syncPanelsOnly();
  }

  Future<BattleTurnAudioRequest?> prepareGroupedSplTurn({
    required BattleTurnExecutionEvent event,
    required BattleOfflineVerifiedMedia media,
    required FlameAudioBattleSfxPlayer player,
  }) async {
    BattleVerifiedSplLoader? loader;
    BattleSplStaticComponent? component;
    RuntimeResourceReservation? decodeReservation;
    var abandoned = false;
    var handedOff = false;
    try {
      if (_ballImagesDisposed || !_canPlayGroupedSpl) {
        return null;
      }
      final camera = _perspectiveCamera;
      final targetSlot = event.execution.targetSlot;
      if (camera == null || targetSlot == null) return null;
      final attackerSlot = event.execution.attackerSlot;
      final attacker = _effectSubjectAt(attackerSlot);
      final target = _effectSubjectAt(targetSlot);
      if (attacker == null || target == null) return null;
      BattleSplCameraBinding binding(
        BattleSlotRef slot,
        ({BattleSceneCombatantComponent actor, int lineupIndex, String? combatantId}) identity,
      ) {
        bool current() {
          final value = _effectSubjectAt(slot);
          return value != null &&
              identical(value.actor, identity.actor) &&
              value.lineupIndex == identity.lineupIndex &&
              value.combatantId == identity.combatantId;
        }
        return BattleSplCameraBinding(
          resolveNeutralFoot: () => current() ? _geometryFor(slot).footAnchor : null,
          resolveAnchor: () {
            if (!current()) return null;
            final rect = identity.actor.currentEffectAttachmentSpriteRect;
            return rect.isEmpty ? null : Vector2(rect.center.dx, rect.center.dy);
          },
        );
      }

      final bindings = {
        'userMouth': binding(attackerSlot, attacker),
        'targetImpact': binding(targetSlot, target),
      };
      final bundle = media.bundle;
      final selection = const BattleMoveRecipeCompiler().selectGroupedSpl(bundle.recipe);
      if (selection == null) return null;
      final definitions = bundle.recipe.readVerifiedSplParticleDefinitions(
        bundle.media,
        availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      );
      final directions = selection.particles
          .where((item) => item.from != item.to)
          .map((item) => (from: item.from, to: item.to))
          .toSet();
      final anchors = BattleSplCameraProjection(
        camera: camera,
        bindings: [bindings['userMouth']!, bindings['targetImpact']!],
      ).capture();
      if (anchors == null) return null;
      final anchorByName = {'userMouth': anchors[0], 'targetImpact': anchors[1]};
      final yaws = <({String from, String to}), double>{};
      for (final direction in directions) {
        final from = anchorByName[direction.from]!;
        final to = anchorByName[direction.to]!;
        final dx = to.x - from.x;
        final dz = to.z - from.z;
        if (dx.abs() + dz.abs() < .000001) return null;
        yaws[direction] = math.atan2(dz, dx);
      }
      final yaw = yaws.isEmpty ? 0.0 : yaws.values.first;
      final emitters = <BattleSplStaticEmitter>[];
      final emitterBindings = <BattleSplCameraBinding>[];
      final emitterTransforms = <BattleSplWorldTransform>[];
      for (final part in selection.particles) {
        final definition = definitions[part.resourceId];
        if (definition == null) return null;
        for (var i = 0; i < definition.emitters.length; i++) {
          emitters.add(BattleSplStaticEmitter(
            emitterIndex: emitters.length,
            startTick: part.startTick,
            position: (x: 0, y: 0, z: 0),
          ));
          emitterBindings.add(bindings[part.from]!);
          emitterTransforms.add(BattleSplWorldTransform(
            worldUnitsPerUnit: anchors[0].unit * 5,
            yawRadians: yaws[(from: part.from, to: part.to)] ?? yaw,
          ));
        }
      }
      if (emitters.isEmpty || emitters.length > 32) return null;
      final projection = BattleSplCameraProjection(
        camera: camera,
        bindings: emitterBindings,
        worldTransform: BattleSplWorldTransform(
          worldUnitsPerUnit: anchors[0].unit * 5,
          yawRadians: yaw,
        ),
        emitterTransforms: emitterTransforms,
      );
      final pendingDecode = media.acquireTextureDecode(
        isCurrent: () => !_ballImagesDisposed,
      );
      unawaited(pendingDecode.then<void>((reservation) {
        if (abandoned || _ballImagesDisposed) reservation.release();
      }, onError: (Object _) {}));
      decodeReservation = await Future.any<RuntimeResourceReservation>([
        pendingDecode,
        _groupedSplClosed.future.then((_) =>
            throw const BattleOfflineRecipeLoadCancelled()),
      ]).timeout(const Duration(seconds: 2));
      if (_ballImagesDisposed) return null;
      loader = BattleVerifiedSplLoader(bundle);
      _groupedSplLoads.add(loader);
      late _PreparedGroupedSpl prepared;
      final result = await loader.createGrouped(
        selection.particles.map((item) => item.resourceId).toList(),
        emitters: emitters,
        seed: 0,
        poolCapacity: 128,
        maxTicks: BattleMoveRecipeCompiler.groupedSplMaxTicks,
        origin: Offset.zero,
        pixelsPerUnit: 25 * currentSceneLayout.scale,
        projection: projection,
        onComplete: () => prepared.visualCompleted(),
        onFailure: (_) => prepared.visualFailed(),
      );
      component = result.component;
      if (_ballImagesDisposed || component == null) return null;
      final coordinator = BattleRecipeAudioCoordinator(
        player: player,
        bundle: bundle,
        preparationTimeout: const Duration(seconds: 2),
        startTimeout: const Duration(seconds: 1),
      );
      final id = 'grouped-spl-${_nextGroupedSplId++}';
      BattleGen5MotionComponent? motion;
      if (selection.swings.isNotEmpty) {
        final owner = Object();
        BattleGen5MotionBinding motionBinding(
          BattleSlotRef slot,
          ({BattleSceneCombatantComponent actor, int lineupIndex, String? combatantId}) identity,
        ) {
          var claimed = false;
          var paused = false;
          bool current() {
            final value = _effectSubjectAt(slot);
            return value != null && identical(value.actor, identity.actor) &&
                value.lineupIndex == identity.lineupIndex && value.combatantId == identity.combatantId;
          }
          return BattleGen5MotionBinding(
            apply: (pose) {
              if (!current() || (claimed && !identity.actor.ownsBattleScriptTransform(owner)) ||
                  (paused && !identity.actor.ownsBattleSpriteAnimationPause(owner))) return false;
              final applied = identity.actor.applyBattleScriptTransform(
                offset: _reducedBattleEffects ? Offset.zero : Offset(pose.offsetX, pose.offsetY),
                scaleX: _reducedBattleEffects ? 1 : pose.scaleX,
                scaleY: _reducedBattleEffects ? 1 : pose.scaleY,
                owner: owner,
              );
              claimed = claimed || applied;
              return applied;
            },
            clear: () => identity.actor.clearBattleScriptTransform(owner: owner),
            pause: () {
              if (!current()) throw StateError('Battle motion target changed');
              identity.actor.pauseBattleSpriteAnimation(owner: owner);
              paused = true;
            },
            resume: () {
              identity.actor.resumeBattleSpriteAnimation(owner: owner);
              paused = false;
            },
          );
        }
        final userBinding = motionBinding(attackerSlot, attacker);
        final targetBinding = identical(attacker.actor, target.actor)
            ? userBinding : motionBinding(targetSlot, target);
        motion = BattleGen5MotionComponent(BattleGen5MotionPlayback(
          bindings: {'user': userBinding, 'target': targetBinding},
          swings: [for (final spec in selection.swings) BattleGen5MotionSpec(
            target: spec.target, channel: spec.channel, x: spec.x, y: spec.y,
            frames: spec.frames, wait: spec.wait, count: spec.count,
            mirrorX: (spec.target == 'user' ? attackerSlot.side : targetSlot.side) == BattleSideId.enemy,
          )],
          pausedTargets: {selection.pausedTarget!},
          pixelsPerUnit: 5,
          onComplete: () => prepared.motionCompleted(),
          onFailure: () => prepared.visualFailed(),
        ));
      }
      prepared = _PreparedGroupedSpl(
        component: component,
        motion: motion,
        media: media,
        coordinator: coordinator,
        onClosed: () => _groupedSplEffects.remove(id),
      );
      _groupedSplEffects[id] = prepared;
      handedOff = true;
      return BattleTurnAudioRequest(
        event: event,
        coordinator: coordinator,
        audio: selection.audio,
        trackedEffectId: id,
        cameraBefore: selection.cameraBefore == null ? null : CameraFocusStep(
          target: switch (selection.cameraBefore!.target) {
            'user' => BattleCameraFocusTarget.user,
            'target' => BattleCameraFocusTarget.target,
            _ => BattleCameraFocusTarget.scene,
          },
          durationSeconds: selection.cameraBefore!.durationMs / 1000,
        ),
        cameraAfter: selection.cameraAfterMs == null ? null : BattleCameraResetStep(
          durationSeconds: selection.cameraAfterMs! / 1000,
        ),
        silentVisuals: const AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [
            CameraFocusStep(
              target: BattleCameraFocusTarget.scene,
              durationSeconds: 0,
            ),
          ],
        ),
      );
    } on Object catch (error) {
      debugPrint('[battle] grouped SPL unavailable: $error');
      return null;
    } finally {
      abandoned = true;
      decodeReservation?.release();
      if (loader != null) _groupedSplLoads.remove(loader);
      if (!handedOff) {
        component?.dispose();
        media.release();
      }
    }
  }

  void discardGroupedSplTurn(BattleTurnAudioRequest request) {
    final effect = _groupedSplEffects[request.trackedEffectId];
    if (effect != null) unawaited(effect.cancel());
  }

  void Function() startGroupedSplEffect(
    StartTrackedEffectStep step,
    void Function() onComplete,
    void Function() onFailure,
  ) {
    final effect = _groupedSplEffects[step.effectId];
    if (effect == null) {
      onFailure();
      return () {};
    }
    return effect.start(this, onComplete, onFailure, allowed: _canPlayGroupedSpl);
  }

  Future<bool> prepareTurnAudioAndUpdateState(
    BattleSession newSession, {
    required List<BattleTurnAudioRequest> audioRequests,
    Duration preparationTimeout = const Duration(seconds: 2),
    GameState? gameState,
    RuntimeBattlePresentation? presentation,
    Map<String, PreparedBattleMoveRecipe>? importedRecipes,
    bool Function()? isCurrent,
  }) async {
    final requests = List<BattleTurnAudioRequest>.unmodifiable(audioRequests);
    final events = Set<BattleTurnExecutionEvent>.identity();
    final coordinators = Set<Object>.identity();
    final timeline = newSession.state.currentTurn?.timeline ?? const [];
    final valid = preparationTimeout > Duration.zero &&
        preparationTimeout <= const Duration(seconds: 30) &&
        requests.length <= 16 &&
        requests.every((request) =>
            timeline.where((event) => identical(event, request.event)).length ==
                1 &&
            !request.event.execution.move.id.startsWith('effect:') &&
            events.add(request.event) &&
            coordinators.add(request.coordinator) &&
            request.coordinator.canRequest);
    if (!valid || _ballImagesDisposed) {
      final seen = Set<Object>.identity();
      for (final request in requests) {
        discardGroupedSplTurn(request);
        if (request.coordinator.canRequest && seen.add(request.coordinator)) {
          unawaited(Future.sync(request.coordinator.cancel).then<void>(
            (_) {},
            onError: (Object _) {},
          ));
        }
      }
      if (_ballImagesDisposed) return false;
      throw StateError('Invalid turn audio preparation');
    }
    if (requests.isEmpty) {
      if (isCurrent?.call() == false) return false;
      updateState(
        newSession,
        gameState: gameState,
        presentation: presentation,
        importedRecipes: importedRecipes,
      );
      return true;
    }
    _cancelPendingTurnAudioPreparation();
    final pending = _PendingTurnAudioPreparation(requests, discardGroupedSplTurn);
    _pendingTurnAudioPreparation = pending;
    _turnAudioSettlement = pending;
    final clock = Stopwatch()..start();
    final selections = <BattleTurnAudioSelection>[];
    bool current() =>
        !_ballImagesDisposed &&
        identical(_pendingTurnAudioPreparation, pending) &&
        (isCurrent?.call() ?? true);
    void abort({required bool unlock}) {
      final shouldUnlock = unlock &&
          !_ballImagesDisposed &&
          identical(_pendingTurnAudioPreparation, pending);
      if (identical(_pendingTurnAudioPreparation, pending)) {
        _pendingTurnAudioPreparation = null;
      }
      pending.cancel();
      if (shouldUnlock) {
        _preparingTurn = false;
        _syncPanelsOnly();
      }
    }
    try {
      beginTurnPreparation();
      for (final request in requests) {
        if (!current()) throw const _TurnAudioInterrupted();
        if (clock.elapsed >= preparationTimeout) {
          throw const _TurnAudioPreparationTimedOut();
        }
        final operation = request.coordinator.prepare(request.audio);
        unawaited(operation.then<void>((_) {}, onError: (Object _) {}));
        final remaining = preparationTimeout - clock.elapsed;
        if (remaining <= Duration.zero) {
          throw const _TurnAudioPreparationTimedOut();
        }
        final result = await Future.any<BattleRecipeAudioResult>([
          operation,
          pending.interrupted.future.then(
            (_) => throw const _TurnAudioInterrupted(),
          ),
        ]).timeout(
          remaining,
          onTimeout: () => throw const _TurnAudioPreparationTimedOut(),
        );
        if (!current() || result.status == BattleRecipeAudioStatus.cancelled) {
          throw const _TurnAudioInterrupted();
        }
        _groupedSplEffects[request.trackedEffectId]?.audioPrepared(result);
        selections.add(
          BattleTurnAudioSelection(
            event: request.event,
            audio: result,
            silentVisuals: request.silentVisuals,
            trackedEffectId: request.trackedEffectId,
            cameraBefore: request.cameraBefore,
            cameraAfter: request.cameraAfter,
          ),
        );
      }
      if (!current()) throw const _TurnAudioInterrupted();
      _pendingTurnAudioPreparation = null;
      updateState(
        newSession,
        gameState: gameState,
        presentation: presentation,
        importedRecipes: importedRecipes,
        audioSelections: selections,
      );
      return true;
    } on _TurnAudioPreparationTimedOut {
      final shouldApplyFallback = current();
      abort(unlock: false);
      if (!shouldApplyFallback) return false;
      updateState(
        newSession,
        gameState: gameState,
        presentation: presentation,
        importedRecipes: importedRecipes,
      );
      return true;
    } on _TurnAudioInterrupted {
      abort(unlock: true);
      return false;
    } catch (_) {
      abort(unlock: true);
      rethrow;
    } finally {
      if (identical(_turnAudioSettlement, pending)) {
        _turnAudioSettlement = null;
      }
      pending.settled.complete();
    }
  }

  void _cancelPendingTurnAudioPreparation() {
    final pending = _pendingTurnAudioPreparation;
    _pendingTurnAudioPreparation = null;
    if (pending != null) {
      _preparingTurn = false;
      pending.cancel();
    }
  }

  /// BETA-BAT-017 : ferme les commandes sans éteindre l'UI de combat.
  ///
  /// Le chemin « fin de combat dans la scène » garde les HUD et la boîte de
  /// dialogue vivants — ils jouent les messages du coordinator et la barre
  /// d'XP — mais plus aucune commande ne doit répondre, ni pendant que le
  /// coordinator calcule, ni sous le fondu de sortie. [lockForPostBattle]
  /// reste la coupure totale du chemin plein écran.
  void beginPostBattleGate() {
    if (!_acceptsPlayerCommands) return;
    _acceptsPlayerCommands = false;
    _syncPanelsOnly();
  }

  /// Permanently hands command authority to the post-battle coordinator.
  void lockForPostBattle() {
    if (!_acceptsPlayerCommands) return;
    _acceptsPlayerCommands = false;
    _currentCommandOverlaySnapshot = null;
    onCommandOverlaySnapshotChanged?.call(null);
  }

  @visibleForTesting
  String? get debugCurrentAnimationMessage => _animationRunner?.currentMessage;

  @visibleForTesting
  BattleAnimationPlan get debugActiveAnimationPlan => _activeAnimationPlan;

  @visibleForTesting
  double? get debugPlayerSpriteOpacity =>
      // ignore: invalid_use_of_visible_for_testing_member
      _playerCombatant?.currentVisualOpacity;

  @visibleForTesting
  BattleSceneCombatantComponent? get debugEnemyCombatant => _enemyCombatant;

  @visibleForTesting
  BattleSceneCombatantComponent? get debugPlayerCombatant => _playerCombatant;

  @visibleForTesting
  void debugHandleBallSequenceForTest(PlayBallSequenceStep step) =>
      _handleBallSequenceStep(step);

  @visibleForTesting
  void debugSpawnBallFlashForTest(BattleSideId side) => _spawnBallFlash(side);

  @visibleForTesting
  double? get debugEnemySpriteOpacity =>
      // ignore: invalid_use_of_visible_for_testing_member
      _enemyCombatant?.currentVisualOpacity;

  @visibleForTesting
  double? get debugEnemySpriteScaleX =>
      // ignore: invalid_use_of_visible_for_testing_member
      _enemyCombatant?.currentVisualScaleX;

  @visibleForTesting
  double? get debugPlayerSpriteScaleX =>
      // ignore: invalid_use_of_visible_for_testing_member
      _playerCombatant?.currentVisualScaleX;

  @visibleForTesting
  Offset? get debugEnemySpriteOffset =>
      // ignore: invalid_use_of_visible_for_testing_member
      _enemyCombatant?.currentVisualOffset;

  @visibleForTesting
  Offset? get debugPlayerSpriteOffset =>
      // ignore: invalid_use_of_visible_for_testing_member
      _playerCombatant?.currentVisualOffset;

  @visibleForTesting
  bool get debugPanelMounted => _debugPanel != null;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => backgroundSpec.key;

  @visibleForTesting
  String get currentPromptText =>
      _currentCommandOverlaySnapshot?.prompt ??
      buildBattleDecisionPromptForSession(
        _session,
        resolveSpeciesDisplayName: resolveSpeciesDisplayName,
      );

  @visibleForTesting
  String get currentNarrationText =>
      (_currentCommandOverlaySnapshot?.narrationLines ??
              buildBattleNarrationLinesForOverlay(
                _session,
                resolveSpeciesDisplayName: resolveSpeciesDisplayName,
              ))
          .join('\n');

  @visibleForTesting
  BattleCommandMenuMode get currentMenuMode => _menuMode;

  @visibleForTesting

  /// BETA-BAT-016 : l'entrée en combat se joue comme une présentation.
  ///
  /// Le plan d'intro est construit au montage et reste EN ATTENTE sous le
  /// noir de la pré-transition : pendant cette attente, les commandes sont
  /// verrouillées par le même gate que les tours. [startIntro] le lance au
  /// moment où la pré-transition fond son noir ; le déverrouillage est la
  /// fin du plan, une seule fois, comme tout plan du runner.
  final bool introEnabled;
  BattleAnimationPlan? _pendingIntroPlan;

  void startIntro() {
    if (_ballImagesDisposed) return;
    final plan = _pendingIntroPlan;
    if (plan == null) return;
    _cancelPendingTurnAudioPreparation();
    _pendingIntroPlan = null;
    // À partir d'ici c'est le PLAN qui pilote les sprites d'entrée : les
    // poses retenues n'ont plus à survivre à une synchronisation.
    _introHeldCombatantSlots = <BattleSlotRef>{};
    _introPlayed = true;
    _resetSceneClock();
    _animationRunner?.start(plan);
    _handleAnimationPresentationChanged();
  }

  /// Recette 2026-08-23 (22-57-18) : tant que le rideau n'est pas tombé, la
  /// scène ne dessine RIEN — le flash de la pré-transition est translucide et
  /// la scène montée en parallèle se voyait à travers, à la place de
  /// l'overworld que la référence garde affiché.
  @override
  void renderTree(Canvas canvas) {
    if (_pendingIntroPlan != null) return;
    super.renderTree(canvas);
  }

  /// L'intro a déjà déroulé les messages d'ouverture un à un : les réafficher
  /// en bloc dans la narration du premier tour serait une redite.
  bool _introPlayed = false;

  /// BETA-BAT-017 : la fin de combat se joue dans la scène.
  ///
  /// Le plan porte les messages du coordinator (victoire, Exp., niveaux,
  /// argent…) et les remplissages de barre d'XP. Même mécanique qu'un tour :
  /// le runner le joue, les commandes restent verrouillées, l'hôte attend
  /// [waitForTurnPresentationComplete] avant de committer et démonter.
  void presentPostBattlePlan(BattleAnimationPlan plan) {
    if (_ballImagesDisposed) return;
    if (plan.isEmpty) return;
    _cancelGen5SourceProgram(syncPanels: false);
    _cancelPendingTurnAudioPreparation();
    _discardPendingTurnAudio();
    _presentationGeneration += 1;
    _fxLayer?.clearAll();
    _syncFieldAmbientState();
    // Le plan actif suit le même cycle qu'un tour : posé ici, vidé par
    // [_handleAnimationPresentationChanged] quand le runner s'éteint. Les
    // révisions de tween du snapshot se comptent dessus, et le bandeau
    // d'issue le regarde pour savoir qu'une présentation est en cours.
    _installActiveAnimationPlan(plan);
    _resetSceneClock();
    _resetBattleCamera();
    _animationRunner?.start(plan);
    _handleAnimationPresentationChanged();
  }

  /// Une décision post-combat posée par l'hôte — BETA-BAT-017 sous-lot 2.
  ///
  /// L'apprentissage de capacité et l'évolution se choisissent DANS la scène :
  /// la boîte de dialogue garde le message du coordinator en prompt, le
  /// panneau liste les choix, et le tap/clavier remonte l'index à l'hôte.
  /// Pendant qu'une décision est affichée, le snapshot publié est celui de la
  /// décision (mode root, interactions ouvertes malgré le gate) et toutes les
  /// entrées de navigation sont routées vers elle.
  _PostBattleDecisionRequest? _postBattleDecision;
  int _postBattleDecisionSelectedIndex = 0;

  void presentPostBattleDecision({
    required String prompt,
    required List<String> choices,
    required ValueChanged<int> onChoice,
  }) {
    assert(choices.isNotEmpty, 'a decision needs at least one choice');
    _postBattleDecision = _PostBattleDecisionRequest(
      prompt: prompt,
      choices: List<String>.unmodifiable(choices),
      onChoice: onChoice,
    );
    _postBattleDecisionSelectedIndex = 0;
    _syncPanelsOnly();
  }

  void clearPostBattleDecision() {
    if (_postBattleDecision == null) return;
    _postBattleDecision = null;
    _postBattleDecisionSelectedIndex = 0;
    _syncPanelsOnly();
  }

  bool get hasPostBattleDecision => _postBattleDecision != null;

  @visibleForTesting
  int get debugPostBattleDecisionSelectedIndex =>
      _postBattleDecisionSelectedIndex;

  bool _movePostBattleDecisionSelection(int delta) {
    final decision = _postBattleDecision;
    if (decision == null) return false;
    final next = (_postBattleDecisionSelectedIndex + delta)
        .clamp(0, decision.choices.length - 1);
    if (next == _postBattleDecisionSelectedIndex) return true;
    _postBattleDecisionSelectedIndex = next;
    _syncPanelsOnly();
    return true;
  }

  bool _submitPostBattleDecision(int index) {
    final decision = _postBattleDecision;
    if (decision == null) return false;
    if (index < 0 || index >= decision.choices.length) return false;
    _postBattleDecisionSelectedIndex = index;
    decision.onChoice(index);
    return true;
  }

  /// Les planches de Poké Ball chargées pour ce combat — BETA-BAT-022.
  ///
  /// Chargées AVANT la construction du plan d'intro : si la planche manque
  /// ou ne se lit pas, l'intro retombe sur le glissement historique
  /// (critère 4) et les remplacements gardent leurs mouvements d'origine.
  final Map<String, ui.Image> _ballSheetImages = <String, ui.Image>{};

  final Map<String, Future<ui.Image?>> _pendingBallSheets = {};
  bool _ballImagesDisposed = false;

  /// Les planches d'aura de stats chargées pour ce combat — BETA-BAT-021.
  /// Même contrat que les planches de Ball : chargement paresseux au premier
  /// besoin, et une planche introuvable ne montre rien sans jamais casser.
  final Map<String, ui.Image> _statSheetImages = <String, ui.Image>{};
  final Map<String, Future<ui.Image?>> _pendingStatSheets = {};

  @visibleForTesting
  int get debugStatSheetCount => _statSheetImages.length;

  bool _releaseUnusedStatSheets() {
    final live = Set<ui.Image>.identity()
      ..addAll(children
          .whereType<BattleStatAuraComponent>()
          .map((aura) => aura.sheet));
    var released = false;
    for (final entry in _statSheetImages.entries.toList()) {
      if (live.contains(entry.value)) continue;
      final lease = _sheetLeases.remove('stat:${entry.key}');
      if (lease == null) continue;
      _statSheetImages.remove(entry.key);
      lease.dispose();
      released = true;
    }
    return released;
  }

  Future<ui.Image?> _loadStatSheet(String sheetName) async {
    if (_ballImagesDisposed) return null;
    final cached = _statSheetImages[sheetName];
    if (cached != null) return cached;
    final pending = _pendingStatSheets.putIfAbsent(
      sheetName, () => _decodeStatSheet(sheetName));
    try {
      return await pending;
    } finally {
      if (identical(_pendingStatSheets[sheetName], pending)) {
        _pendingStatSheets.remove(sheetName);
      }
    }
  }

  Future<ui.Image?> _decodeStatSheet(String sheetName) async {
    final earlierLoads = _pendingStatSheets.values.toList();
    if (earlierLoads.isNotEmpty) await Future.wait(earlierLoads);
    if (_ballImagesDisposed) return null;
    final fileName = battleStatSheetManifest[sheetName];
    if (fileName == null) return null;
    ByteData? bytes;
    try {
      bytes = await rootBundle.load('packages/map_runtime/assets/battle/stats/'
          '$fileName');
    } on Object {
      try {
        bytes = await rootBundle.load('assets/battle/stats/$fileName');
      } on Object catch (error) {
        debugPrint('[battle] stat sheet unavailable ($sheetName): $error');
        return null;
      }
    }
    if (_ballImagesDisposed) return null;
    final encodedBytes =
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    try {
      Future<RuntimeUiImageLease> decode() => decodeRuntimeUiImage(
            encodedBytes,
            resourceBudget: _resourceBudget,
            isCurrent: () => !_ballImagesDisposed,
          );
      late final RuntimeUiImageLease lease;
      try {
        lease = await decode();
      } on RuntimeResourceAdmissionException catch (error) {
        if (error.reason != 'resident_bytes' || !_releaseUnusedStatSheets()) {
          rethrow;
        }
        lease = await decode();
      }
      try {
        final image = lease.image;
        final cached = _statSheetImages[sheetName];
        if (_ballImagesDisposed || cached != null) {
          lease.dispose();
          return cached;
        }
        _statSheetImages[sheetName] = image;
        _sheetLeases['stat:$sheetName'] = lease;
        return image;
      } catch (_) {
        lease.dispose();
        rethrow;
      }
    } on Object catch (error) {
      debugPrint('[battle] stat sheet undecodable ($sheetName): $error');
      return null;
    }
  }

  /// Parité `change_stat_animation` : le SE part avec l'aura, la planche est
  /// parcourue en 1,5 s au-dessus de la cible. Sans planche, le SE joue seul
  /// et la durée s'écoule — le message reste lisible.
  void _handleStatStageAuraStep(StatStageAuraStep step) {
    playSfx?.call(step.seName, volume: 100, pitch: 100);
    final cached = _statSheetImages[step.sheetName];
    if (cached != null) {
      _mountStatAura(step: step, sheet: cached);
      return;
    }
    unawaited(
      _loadStatSheet(step.sheetName).then((sheet) {
        //  et non  : un overlay chargé mais pas
        // encore attaché à son jeu (harnais de test, montage différé) doit
        // pouvoir monter son aura — seul un overlay RETIRÉ doit refuser.
        if (sheet == null || isRemoved) return;
        _mountStatAura(step: step, sheet: sheet);
      }),
    );
  }

  void _mountStatAura({
    required StatStageAuraStep step,
    required ui.Image sheet,
  }) {
    final layout = currentSceneLayout;
    add(
      BattleStatAuraComponent(
        sheet: sheet,
        targetSpriteRect: _geometryFor(step.slot).spriteRect,
        durationSeconds: step.durationSeconds,
        // Toujours depuis le sprite du JOUEUR : la référence garde la même
        // taille d'aura des deux côtés, l'ennemi ne la rétrécit pas.
        auraSize: layout.playerSpriteRect.height *
            BattleStatAuraComponent.auraToPlayerSpriteRatio,
        priority: (_combatantForSlot(step.slot)?.priority ?? 10) + 2,
      ),
    );
  }

  Future<ui.Image?> _loadBallSheet(String? itemId) {
    if (itemId == null || itemId.isEmpty || _ballImagesDisposed) {
      return Future.value();
    }
    final cached = _ballSheetImages[itemId];
    if (cached != null) return Future.value(cached);
    return _pendingBallSheets.putIfAbsent(
      itemId,
      () => _decodeBallSheet(itemId),
    );
  }

  Future<ui.Image?> _decodeBallSheet(String itemId) async {
    try {
      final path = await resolveBallSpritePath?.call(itemId);
      if (path == null || _ballImagesDisposed) return null;
      final lease = await loadRuntimeUiImageFromFilePath(path,
        resourceBudget: _resourceBudget,
        isCurrent: () => !_ballImagesDisposed,
      );
      try {
        final image = lease.image;
        if (_ballImagesDisposed ||
            image.width != 64 ||
            image.height != 2048) {
          lease.dispose();
          return null;
        }
        _ballSheetImages[itemId] = image;
        _sheetLeases['ball:$itemId'] = lease;
        return image;
      } catch (_) {
        lease.dispose();
        rethrow;
      }
    } on Object catch (error) {
      debugPrint('[battle] item animation unavailable ($itemId): $error');
      return null;
    }
  }

  @override
  void onRemove() {
    _resetSceneClock();
    if (_ballImagesDisposed) return;
    _cancelGen5SourceProgram(syncPanels: false);
    _ballImagesDisposed = true;
    if (!_groupedSplClosed.isCompleted) _groupedSplClosed.complete();
    _presentationGeneration++;
    _cancelPendingTurnAudioPreparation();
    _discardPendingTurnAudio();
    _animationRunner?.cancel(notify: false);
    for (final loader in _groupedSplLoads) {
      loader.cancel();
    }
    for (final effect in _groupedSplEffects.values.toList()) {
      unawaited(effect.cancel());
    }
    for (final lease in _sheetLeases.values) {
      lease.dispose();
    }
    _sheetLeases.clear();
    for (final release in _trainerImageReleases) {
      release();
    }
    _trainerImageReleases.clear();
    _ballSheetImages.clear();
    _statSheetImages.clear();
    final visualScope = _visualImageScope;
    _visualImageScope = null;
    if (visualScope != null) visualAssetCache?.endScope(visualScope);
    final fxScope = _fxImageScope;
    _fxImageScope = null;
    if (fxScope != null) _fxBundleCache.endScope(fxScope);
    if (_ownsFxBundleCache) _fxBundleCache.dispose();
    if (_ownsResourceBudget) _resourceBudget.dispose();
    super.onRemove();
  }

  /// La séquence de capture — BETA-BAT-025. Le composant pilote la Ball et
  /// notifie ses moments ; l'hôte joue les sons de la référence et fait
  /// rétrécir/réapparaître le sauvage. Sans planche chargeable, rien ne se
  /// monte et les durées s'écoulent : les messages restent lisibles.
  void _handleBallCaptureSequenceStep(PlayBallCaptureSequenceStep step) {
    final sheet = _ballSheetImages[step.ballItemId];
    if (sheet == null) return;
    final placement = _bindBallPlacement(const BattleSlotRef.active(BattleSideId.enemy),
      verticalRatio: .45, throwingSide: BattleSideId.player);
    final initial = placement();
    if (initial == null) return;
    add(
      BattleBallCaptureComponent(
        sheet: sheet,
        shakes: step.shakes,
        caught: step.caught,
        targetCenter: Offset(initial.targetCenter.x, initial.targetCenter.y),
        throwStartX: initial.throwStartX,
        // Toujours depuis le sprite du JOUEUR — recette du 2026-08-25 : « la
        // pokéball que l'on lance pour attraper un pokémon sauvage est trop
        // petite ». C'est la même Ball, lancée par la même main : elle n'a
        // aucune raison de rétrécir parce que la cible est plus loin. Se
        // baser sur le sprite VISÉ la faisait perdre 30 % côté ennemi.
        cellSize: initial.cellSize,
        resolvePlacement: placement,
        onCue: (cue) {
          if (placement() == null) return;
          switch (cue) {
            case BattleBallCaptureCue.absorb:
              unawaited(
                _enemyCombatant?.playMaterializeOut(durationSeconds: 0.2) ??
                    Future<void>.value(),
              );
            case BattleBallCaptureCue.close:
              playSfx?.call('ball_open', volume: 100, pitch: 100);
            case BattleBallCaptureCue.bounce:
              playSfx?.call('ball_bounce', volume: 100, pitch: 100);
            case BattleBallCaptureCue.shake:
              playSfx?.call('ball_shake', volume: 100, pitch: 100);
            case BattleBallCaptureCue.verdict:
              // Parité `catching_ball_se` / `break_ball_se` : le même son,
              // aigu (pitch 180) pour le clic de verrouillage, normal pour
              // l'éclatement.
              playSfx?.call(
                'ball_verdict',
                volume: 100,
                pitch: step.caught ? 180 : 100,
              );
            case BattleBallCaptureCue.release:
              // La Ball éclate : même éclat que la sortie de Ball, puisque
              // c'est la même chose — un Pokémon qui reprend forme.
              _spawnBallFlash(BattleSideId.enemy);
              unawaited(
                _enemyCombatant?.playMaterializeIn(durationSeconds: 0.2) ??
                    Future<void>.value(),
              );
          }
        },
      ),
    );
    playSfx?.call('ball_throw', volume: 100, pitch: 100);
    if (step.caught) {
      _capturedEnemyHeldInBall = true;
    }
  }

  void _handleBallSequenceStep(PlayBallSequenceStep step) {
    final sheet = _ballSheetImages[step.ballItemId];
    if (sheet == null) return;
    final placement = _bindBallPlacement(step.slot, verticalRatio: .25,
      throwingSide: step.side);
    final initial = placement();
    if (initial == null) return;
    if (step.kind == BattleBallSequenceKind.sendOutThrown) {
      playSfx?.call('ball_throw', volume: 100, pitch: 100);
    }
    add(
      BattleBallThrowComponent(
        sheet: sheet,
        kind: step.kind,
        targetCenter: Offset(initial.targetCenter.x, initial.targetCenter.y),
        throwStartX: initial.throwStartX,
        cellSize: initial.cellSize,
        resolvePlacement: placement,
        onOpen: () {
          if (placement() == null) return;
          playSfx?.call('ball_open', volume: 100, pitch: 100);
          _spawnBallFlash(step.side, slotIndex: step.slotIndex);
        },
      ),
    );
  }

  /// La taille d'une cellule de Ball à l'écran.
  ///
  /// Recette du 2026-08-24 : « la pokéball est minuscule ». La cellule 64×64
  /// de la planche est très paddée — la Ball opaque n'y occupe que ~14 px. La
  /// référence dessine cette cellule au même zoom que le sprite 96×96 du
  /// Pokémon : la cellule vaut donc 2/3 de la boîte du sprite.
  ///
  /// Recette du 2026-08-25 : elle se mesure sur le sprite du JOUEUR, jamais
  /// sur la cible. C'est la même Ball lancée par la même main ; la faire
  /// rétrécir de 30 % parce que le sauvage est plus loin la rendait à nouveau
  /// minuscule à la capture.
  double get _ballCellSize =>
      _geometryFor(const BattleSlotRef.active(BattleSideId.player)).spriteRect.height * (64 / 96);

  @visibleForTesting
  double get debugBallCellSize => _ballCellSize;

  BattleBallLivePlacement? Function() _bindBallPlacement(BattleSlotRef slot, {
    required double verticalRatio, required BattleSideId throwingSide,
  }) {
    final generation = _presentationGeneration;
    final identity = _effectSubjectAt(slot);
    return () {
      if (!_isCurrentPresentationGeneration(generation) || identity == null ||
          _effectSubjectAt(slot) != identity) {
        return null;
      }
      final geometry = _geometryFor(slot);
      final rect = geometry.spriteRect;
      final projection = _perspectiveCamera?.tryBillboardAt(geometry.footAnchor);
      final playerProjection = _perspectiveCamera?.tryBillboardAt(
        _geometryFor(const BattleSlotRef.active(BattleSideId.player)).footAnchor);
      if (projection == null || playerProjection == null || rect.isEmpty) return null;
      final target = Offset(rect.center.dx, rect.bottom - rect.height * verticalRatio);
      return (targetCenter: Vector2(
        projection.position.dx + (target.dx - geometry.footAnchor.dx) * projection.scale,
        projection.position.dy + (target.dy - geometry.footAnchor.dy) * projection.scale),
        throwStartX: ballThrowStartXFor(side: throwingSide, viewportWidth: size.x),
        cellSize: _ballCellSize * playerProjection.scale);
    };
  }

  /// Le flash d'ouverture d'une Ball — BETA-BAT-031.
  ///
  /// Recette du 2026-08-24 : « ça manque de l'espèce de flash jolie ». La
  /// référence (Platine) projette un éclat blanc au point d'apparition juste
  /// avant que le Pokémon prenne forme.
  void _spawnBallFlash(BattleSideId side, {int slotIndex = 0}) {
    if (_reducedBattleEffects || _motionPolicy.effectIntensity <= 0) return;
    final slot = BattleSlotRef(side: side, slotIndex: slotIndex);
    final generation = _presentationGeneration;
    final placement = _bindBallPlacement(slot, verticalRatio: .32, throwingSide: side);
    final initial = placement();
    if (initial == null) return;
    final rect = _geometryFor(slot).spriteRect;
    final flash = BattleBallFlashComponent(
      center: Offset(initial.targetCenter.x, initial.targetCenter.y),
      radiusPx: rect.height * 0.62,
      resolveCenter: () => placement()?.targetCenter,
      resolveRadiusPx: () => _geometryFor(slot).spriteRect.height * .62 *
          (_perspectiveCamera?.tryBillboardAt(_geometryFor(slot).footAnchor)?.scale ?? 1),
      resolveIntensity: () => _reducedBattleEffects ? 0 : _motionPolicy.effectIntensity,
      priority: (_combatantForSlot(slot)?.priority ?? 10) + 3,
    );
    // En microtask : ce flash naît DANS le `update` du composant de Ball
    // (son callback d'ouverture), donc en pleine itération updateTree —
    // ajouter un enfant là mute l'arbre pendant son parcours. Le piège de
    // BETA-BAT-016, cette fois à l'ajout et non au retrait.
    Future<void>.microtask(() {
      if (!_isCurrentPresentationGeneration(generation) || isRemoved || placement() == null) return;
      add(flash);
    });
  }

  /// L'image du dresseur vaincu, préparée par l'hôte — BETA-BAT-017.
  ///
  /// La référence fait réapparaître le dresseur à la place de son Pokémon
  /// avec « Vous avez battu X ! ». L'hôte charge l'image (chemin projet,
  /// peut échouer) AVANT le plan de fin ; le [ShowDefeatedTrainerStep] du
  /// plan la monte. Sans image préparée, le step ne fait rien et le message
  /// seul fait l'annonce — le fallback demandé.
  ui.Image? _defeatedTrainerImage;
  PositionComponent? _defeatedTrainerSprite;

  void prepareDefeatedTrainerVisual(ui.Image image, {void Function()? onRelease}) {
    if (_ballImagesDisposed) {
      onRelease?.call();
      return;
    }
    if (onRelease != null) _trainerImageReleases.add(onRelease);
    _defeatedTrainerImage = image;
  }

  /// L'image du dresseur adverse pour l'INTRO — BETA-BAT-027.
  ///
  /// Même contrat que le dresseur vaincu : l'hôte la charge depuis la donnée
  /// projet AVANT le montage (elle doit être là quand `onLoad` construit le
  /// plan d'intro). Sans elle, le Pokémon adverse glisse comme un sauvage.
  ui.Image? _introTrainerImage;
  BattleIntroTrainerComponent? _introTrainerSprite;

  void prepareIntroTrainerVisual(ui.Image image, {void Function()? onRelease}) {
    if (_ballImagesDisposed) {
      onRelease?.call();
      return;
    }
    if (onRelease != null) _trainerImageReleases.add(onRelease);
    _introTrainerImage = image;
  }

  @visibleForTesting
  BattleIntroTrainerComponent? get debugIntroTrainerSprite =>
      _introTrainerSprite;

  /// Parité `create_sprite_move_animation` / `create_enemy_send_animation` :
  /// le dresseur adverse entre, annonce, puis sort en lançant sa Ball. Sans
  /// sprite monté, l'étape ne fait rien et sa durée s'écoule.
  void _handleEnemyTrainerIntroStep(EnemyTrainerIntroStep step) {
    final sprite = _introTrainerSprite;
    if (sprite == null) return;
    sprite.play(
      motion: switch (step.motion) {
        BattleIntroTrainerMotionKind.enter => BattleIntroTrainerMotion.enter,
        BattleIntroTrainerMotionKind.exit => BattleIntroTrainerMotion.exit,
      },
      durationSeconds: step.durationSeconds,
    );
    if (step.motion == BattleIntroTrainerMotionKind.exit) {
      // Il ne revient pas : le retirer à la fin de sa sortie, en microtask
      // pour ne pas muter l'arbre pendant son parcours.
      _introTrainerExitPending = true;
    }
  }

  bool _introTrainerExitPending = false;

  @visibleForTesting
  bool get debugDefeatedTrainerSpriteMounted => _defeatedTrainerSprite != null;

  void _handleShowDefeatedTrainerStep() {
    final image = _defeatedTrainerImage;
    if (image == null || _defeatedTrainerSprite != null) return;
    final rect = currentSceneLayout.enemySpriteRect;
    final sprite = _DefeatedTrainerSpriteComponent(
      image: image,
      spriteRect: rect,
      priority: (_enemyCombatant?.priority ?? 10) + 1,
    );
    _defeatedTrainerSprite = sprite;
    add(sprite);
  }

  /// L'XP présentée du combattant joueur actif — BETA-BAT-017.
  ///
  /// La table `_playerExperienceProgressByLineupIndex` est figée au montage
  /// (l'état d'AVANT combat) : après un remplissage joué, elle mentirait.
  /// Chaque tween avance cette référence à sa cible ; le snapshot la préfère
  /// à la table dès qu'elle existe.
  double? _presentationXpProgress;
  int? _presentationPlayerLevel;

  /// L'horloge de présentation des PV, par camp — recette 2026-08-23.
  ///
  /// Le HUD Flame la tient déjà via `startingDisplayedHp`, mais sur mobile
  /// les HUD sont les widgets Flutter nourris par le snapshot, et le snapshot
  /// publiait l'état FINAL du tour dès `updateState` : barres drainées et
  /// badge K.O. pendant tout l'avant-impact. Ici : tant que le plan actif
  /// porte un drain à venir pour un camp, le snapshot publie le PV d'avant ;
  /// chaque drain joué avance la référence à son `toHp` ; la fin de la
  /// présentation rend la main à l'état réel.
  final Map<BattleSlotRef, int> _presentationHeldHp = <BattleSlotRef, int>{};

  bool get isTurnPresentationActive =>
      _gen5SourceCompletion != null || _preparingTurn ||
      (_animationRunner?.isActive ?? false) || _pendingIntroPlan != null;

  /// Une présentation est en cours OU pas encore démarrée.
  ///
  /// BETA-BAT-012 : [isTurnPresentationActive] ne regarde que le runner, et il
  /// existe une fenêtre entre le moment où le plan est posé et celui où le
  /// runner l'entame. C'est dans cette fenêtre que le bandeau de fin
  /// s'affichait, puisque le plan n'avait encore rien joué.
  ///
  /// Le plan est remis à vide quand le runner a fini, donc « plan non vide ou
  /// runner actif » couvre exactement la durée d'une présentation.
  bool get _presentationPendingOrRunning =>
      _gen5SourceCompletion != null || _preparingTurn || (_animationRunner?.isActive ?? false) ||
      _activeAnimationPlan.steps.isNotEmpty;

  @visibleForTesting
  bool get isBattleCameraFocusActive => _perspectiveCamera?.isMoving ?? false;

  @visibleForTesting
  bool get isBattleCameraActive =>
      (_perspectiveCamera?.isMoving ?? false) ||
      !(_perspectiveCamera?.isHome ?? true);

  @visibleForTesting
  Vector2 get battleCameraOffset {
    final foot = _geometryFor(const BattleSlotRef.active(BattleSideId.player)).footAnchor;
    final projection = _perspectiveCamera?.tryBillboardAt(foot);
    return projection == null ? Vector2.zero() : Vector2(
      projection.position.dx - foot.dx * projection.scale,
      projection.position.dy - foot.dy * projection.scale,
    );
  }

  @visibleForTesting
  double get battleCameraScale {
    final camera = _perspectiveCamera;
    if (camera == null) return 1;
    final geometry = _geometryFor(const BattleSlotRef.active(BattleSideId.player));
    if (geometry.spriteRect.isEmpty) return 0;
    return camera.tryBillboardAt(geometry.footAnchor)?.scale ?? 0;
  }

  @visibleForTesting
  ({BattleSlotRef slot, int lineupIndex, String? combatantId})?
  get battleCameraFocusSubject => _cameraFocusSubject;

  ({BattleCameraPoint eye, BattleCameraPoint aim})? get battleCameraPose {
    final camera = _perspectiveCamera;
    return camera == null ? null : (eye: camera.eye, aim: camera.aim);
  }

  @visibleForTesting
  int get activeBattleFxCount {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return 0;
    }
    return fxLayer.activeFxCount +
        fxLayer.activeSpriteSheetFxCount +
        fxLayer.activeRmxpFxCount +
        fxLayer.activeSdkParticleCount;
  }

  @visibleForTesting
  bool get hasWeatherAmbient => _fxLayer?.hasWeatherAmbient ?? false;

  @visibleForTesting
  bool get hasPseudoWeatherAmbient =>
      _fxLayer?.hasPseudoWeatherAmbient ?? false;

  @visibleForTesting
  BattleSession get debugSession => _session;

  @visibleForTesting
  GameState get debugGameState => _gameState;

  @visibleForTesting
  BattleCommandOverlaySnapshot? get currentCommandOverlaySnapshot =>
      _currentCommandOverlaySnapshot;

  @visibleForTesting
  String get currentPlayerHudSpeciesText => _hudSpeciesDisplayText(
        _displayedCombatantsBySlot[const BattleSlotRef.active(BattleSideId.player)] ?? _displayedPlayerCombatant ?? _combatantDataAt(const BattleSlotRef.active(BattleSideId.player)),
        isPlayerSide: true,
      );

  @visibleForTesting
  String get currentEnemyHudSpeciesText => _hudSpeciesDisplayText(
        _displayedCombatantsBySlot[const BattleSlotRef.active(BattleSideId.enemy)] ?? _displayedEnemyCombatant ?? _combatantDataAt(const BattleSlotRef.active(BattleSideId.enemy)),
        isPlayerSide: false,
      );

  /// BETA-BAT-018 : préchauffe les visuels des capacités du combat.
  ///
  /// Le premier usage d'une capacité décodait ses planches d'animation à la
  /// demande et gelait la scène plusieurs secondes. L'hôte appelle cette
  /// préchauffe pendant le noir de la pré-transition, borné par son budget ;
  /// chaque échec individuel est silencieux — le chargement paresseux
  /// existant reste le filet de sécurité.
  Future<void> precacheBattleMoveEffects() async {
    try {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
    } on Object catch (error) {
      debugPrint('[battle] rmxp catalog unavailable for precache: $error');
      return;
    }
    final assetIds = <String>{};
    for (final move in <BattleMove>[
      ..._session.state.player.moves,
      ..._session.state.enemy.moves,
    ]) {
      final resolved = _moveVisualResolver.resolve(move);
      for (final animationId in <int?>[
        resolved.rmxpUserAnimationId,
        resolved.rmxpTargetAnimationId,
      ]) {
        if (animationId == null) continue;
        final spec = BattleSdkRmxpAnimationCatalog.byAnimationId[animationId];
        if (spec != null) assetIds.add(spec.assetId);
      }
    }
    await Future.wait(assetIds.map((assetId) async {
      try {
        await _fxBundleCache.loadImage(assetId);
      } on Object catch (error) {
        debugPrint('[battle] move effect precache failed for $assetId: '
            '$error');
      }
    }));
  }

  /// Les noms de sons que ce combat peut jouer — BETA-BAT-018.
  ///
  /// Les sons système du tour (impact selon l'efficacité, K.O.), le jingle
  /// de niveau, la fuite, et les timings sonores des animations des capacités
  /// des deux camps. L'hôte les donne à préchauffer à son lecteur.
  Future<Set<String>> collectBattleSeNames() async {
    final seNames = <String>{
      'hit',
      'hitplus',
      'hitlow',
      'down',
      'level_up',
      'flee',
      // BETA-BAT-025 : les sons de la Ball — envoi, capture et verdicts.
      'ball_throw',
      'ball_open',
      'ball_bounce',
      'ball_shake',
      'ball_verdict',
      // BETA-BAT-021 : les sons d'aura de stats.
      'stat_rise_up',
      'stat_fall_down',
    };
    try {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
    } on Object catch (error) {
      debugPrint('[battle] rmxp catalog unavailable for se precache: $error');
      return seNames;
    }
    for (final move in <BattleMove>[
      ..._session.state.player.moves,
      ..._session.state.enemy.moves,
    ]) {
      final resolved = _moveVisualResolver.resolve(move);
      for (final animationId in <int?>[
        resolved.rmxpUserAnimationId,
        resolved.rmxpTargetAnimationId,
      ]) {
        if (animationId == null) continue;
        final spec = BattleSdkRmxpAnimationCatalog.byAnimationId[animationId];
        if (spec == null) continue;
        for (final timing in spec.timings) {
          final seName = timing.seName;
          if (seName != null && seName.isNotEmpty) seNames.add(seName);
        }
      }
    }
    return seNames;
  }

  Future<void> waitForPendingVisualSync() async {
    await (_pendingVisualSync ?? Future<void>.value());
  }

  Future<void> waitForTurnPresentationComplete() async {
    while (true) {
      final pending = _turnAudioSettlement;
      if (pending == null) break;
      await pending.settled.future;
    }
    await waitForPendingVisualSync();
    await (_animationRunner?.completionFuture ?? Future<void>.value());
    await (_gen5SourceCompletion?.future ?? Future<void>.value());
    await waitForPendingVisualSync();
  }

  BattleCommandPanelPlacement _commandPanelPlacement = BattleCommandPanelPlacement.bottom;

  bool _controllerLayout = false;
  bool _portraitTouchLayout = false;

  List<int> _rootCommandOrder = const [0, 1, 2, 3];
  int? _collectionColumns;

  bool setCommandPanelPlacement(BattleCommandPanelPlacement placement, {
    bool controllerLayout = false,
    bool portraitTouchLayout = false,
    List<int> rootCommandOrder = const [0, 1, 2, 3],
    int? collectionColumns,
  }) {
    if (!BattleSetCommandPanelPlacementCommand.isValidRootCommandOrder(rootCommandOrder) || collectionColumns != null && collectionColumns != 1 && collectionColumns != 2) return false;
    if (_commandPanelPlacement == placement && _controllerLayout == controllerLayout && _portraitTouchLayout == portraitTouchLayout && listEquals(_rootCommandOrder, rootCommandOrder) && _rootCommandOrder.contains(_selectedRootIndex) && _collectionColumns == collectionColumns) return true;
    _commandPanelPlacement = placement;
    _controllerLayout = controllerLayout;
    _portraitTouchLayout = portraitTouchLayout;
    _rootCommandOrder = List<int>.unmodifiable(rootCommandOrder);
    _collectionColumns = collectionColumns;
    if (!_rootCommandOrder.contains(_selectedRootIndex)) _selectedRootIndex = _rootCommandOrder.first;
    _applyViewportLayout(size);
    return true;
  }

  BattleCommandOverlayMode get _sceneLayoutMode => _postBattleDecision != null
      ? BattleCommandOverlayMode.decision
      : _pendingTargetChoice != null
      ? BattleCommandOverlayMode.moveTarget
      : _overlayModeForMenuMode(_effectiveMenuMode());

  @visibleForTesting
  BattleSceneLayout get currentSceneLayout =>
      _sceneLayout ??
      BattleSceneLayout.forViewport(
        viewportSize: Size(size.x, size.y),
        safePadding: _safeAreaPadding,
        textScale: textScale,
        commandPanelPlacement: _commandPanelPlacement,
        commandPanelMode: _sceneLayoutMode,
        controllerLayout: _controllerLayout,
      portraitTouchLayout: _portraitTouchLayout,
      );

  @visibleForTesting
  Vector2 get currentRmxpAnimationViewportSize => _rmxpAnimationViewportSize();

  @override
  Future<void> onLoad() async {
    final loadingGame = findGame();
    if (_ballImagesDisposed || loadingGame == null) return;
    final loadingParent = parent;
    bool isLoadingAttached() =>
        !_ballImagesDisposed &&
        identical(parent, loadingParent) &&
        identical(findGame(), loadingGame);
    final overlayStopwatch = Stopwatch()..start();
    // Le catalogue d'animations RMXP est un asset binaire décodé
    // paresseusement : le charger ici garantit que toute la planification
    // d'animations du combat peut y accéder de façon synchrone.
    await BattleSdkRmxpAnimationCatalog.ensureLoaded();
    if (!isLoadingAttached()) return;
    final layout = BattleSceneLayout.forViewport(
      viewportSize: Size(size.x, size.y),
      safePadding: _safeAreaPadding,
      textScale: textScale,
      commandPanelPlacement: _commandPanelPlacement,
      commandPanelMode: _sceneLayoutMode,
      controllerLayout: _controllerLayout,
      portraitTouchLayout: _portraitTouchLayout,
    );
    _sceneLayout = layout;

    _perspectiveCamera = BattlePerspectiveCamera(viewport: layout.stageRect);
    _stage3D = BattleStage3DComponent(
      resourceBudget: _resourceBudget,
      camera: _perspectiveCamera!,
      layout: () => currentSceneLayout,
      combatants: () => {
        const BattleSlotRef.active(BattleSideId.enemy): ?_enemyCombatant,
        const BattleSlotRef.active(BattleSideId.player): ?_playerCombatant,
        ..._additionalCombatants,
      },
      platforms: () => {
        for (final slot in [const BattleSlotRef.active(BattleSideId.enemy), const BattleSlotRef.active(BattleSideId.player), ..._additionalCombatants.keys])
          slot: _geometryFor(slot),
      },
      paintFloor: !backgroundSpec.hasExplicitImage,
    );
    add(_stage3D!);
    add(BattlePerspectiveGroundComponent(
      camera: _perspectiveCamera!,
      isVisible: () => !(_stage3D?.currentFramePresented ?? false),
      isFloorVisible: () => !(_stage3D?.sourceHideFloor ?? false),
      arePlatformsVisible: () => !(_stage3D?.sourceHidePlatforms ?? false),
      paintFloor: !backgroundSpec.hasExplicitImage,
      clipRect: () => currentSceneLayout.arenaRect,
      groundRects: () => [
        for (final slot in [const BattleSlotRef.active(BattleSideId.enemy),
          const BattleSlotRef.active(BattleSideId.player), ..._additionalCombatants.keys])
          _geometryFor(slot).platformRect.shift(
            _geometryFor(slot).footAnchor - _geometryFor(slot).platformRect.center),
      ],
    ));

    final backdropStopwatch = Stopwatch()..start();
    _backdrop = BattleSceneBackdropComponent(
      size: Vector2(size.x, size.y),
      perspectiveGround: true,
      backgroundSpec: backgroundSpec,
      visualAssetCache: visualAssetCache,
      artworkRect: layout.backdropArtworkRect,
    );
    add(_backdrop!);
    await _backdrop!.loaded;
    if (!isLoadingAttached()) return;
    backdropStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.backdrop=${backdropStopwatch.elapsedMilliseconds}ms',
    );

    final enemyCombatantStopwatch = Stopwatch()..start();
    _enemyCombatant = BattleSceneCombatantComponent(
      sceneSpriteRect: layout.enemySpriteRect,
      scenePlatformRect: layout.enemyPlatformRect,
      sceneFootAnchor: layout.enemyFootAnchor,
      spriteFootXRatio: 0.5,
      isPlayerSide: false,
      speciesLabel: resolveSpeciesDisplayName(_session.state.enemy.speciesId),
      visualAssetCache: visualAssetCache,
      resourceBudget: _resourceBudget,
    );
    add(_enemyCombatant!);
    await _enemyCombatant!.loaded;
    if (!isLoadingAttached()) return;
    enemyCombatantStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.enemyCombatant=${enemyCombatantStopwatch.elapsedMilliseconds}ms',
    );

    final playerCombatantStopwatch = Stopwatch()..start();
    _playerCombatant = BattleSceneCombatantComponent(
      sceneSpriteRect: layout.playerSpriteRect,
      scenePlatformRect: layout.playerPlatformRect,
      sceneFootAnchor: layout.playerFootAnchor,
      spriteFootXRatio: 0.68,
      isPlayerSide: true,
      speciesLabel: resolveSpeciesDisplayName(_session.state.player.speciesId),
      visualAssetCache: visualAssetCache,
      resourceBudget: _resourceBudget,
    );
    add(_playerCombatant!);
    await _playerCombatant!.loaded;
    if (!isLoadingAttached()) return;
    playerCombatantStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.playerCombatant=${playerCombatantStopwatch.elapsedMilliseconds}ms',
    );

    if (_isDoubles) {
      for (final active in _battlePresentation!.activeCombatants.where((entry) => entry.slot.slotIndex != 0)) {
        final geometry = _geometryFor(active.slot);
        final component = BattleSceneCombatantComponent(
          sceneSpriteRect: geometry.spriteRect,
          scenePlatformRect: geometry.platformRect,
          sceneFootAnchor: geometry.footAnchor,
          spriteFootXRatio: active.slot.side == BattleSideId.player ? 0.68 : 0.5,
          isPlayerSide: active.slot.side == BattleSideId.player,
          speciesLabel: resolveSpeciesDisplayName(active.combatant.speciesId),
          visualAssetCache: visualAssetCache,
          resourceBudget: _resourceBudget,
        );
        _additionalCombatants[active.slot] = component;
        add(component);
        await component.loaded;
        if (!isLoadingAttached()) return;
      }
      _applyViewportLayout(size);
    }

    _applyViewportLayout(size, syncPanels: false);

    // BETA-BAT-022 : la planche de Poké Ball se charge au montage — l'intro
    // ET les remplacements en vivent. Si elle manque, l'intro retombe sur le
    // glissement historique et les étapes Ball des remplacements ne montrent
    // rien (les durées s'écoulent, rien ne casse). Le chargement ne bloque
    // JAMAIS le chemin sans intro : allonger onLoad d'un tour d'event loop
    // suffisait à ce qu'un hôte pressé pousse son premier tour avant la
    // création du runner — le plan tombait dans le vide (recette du
    // 2026-08-24, capture PSDK muette).
    // BETA-BAT-021 : les deux planches d'aura (865 Ko chacune) se chargent au
    // montage, jamais en pleine animation — décoder une image de cette taille
    // pendant un tour gèlerait la scène, exactement ce que BAT-018 combat.
    // Le chargement ne bloque pas onLoad : l'aura retombe sur son SE seul si
    // la planche n'est pas prête.
    unawaited(_loadStatSheet('stat_up').then((_) => _loadStatSheet('stat_down')));
    final playerBallItemId = resolveCombatantBallItemId?.call(
      BattleSideId.player,
      _session.state.player.lineupIndex,
    );
    final enemyBallItemId = _session.setup.isTrainerBattle
        ? resolveCombatantBallItemId?.call(
            BattleSideId.enemy,
            _session.state.enemy.lineupIndex,
          )
        : null;
    final playerBallSheetFuture = _loadBallSheet(playerBallItemId);
    final enemyBallSheetFuture = _loadBallSheet(enemyBallItemId);
    if (!introEnabled) {
      unawaited(playerBallSheetFuture);
      unawaited(enemyBallSheetFuture);
    }
    if (introEnabled) {
      // BETA-BAT-016 : les combattants attendent hors écran, à leur position
      // de départ d'intro, AVANT le premier rendu — sous le noir de la
      // pré-transition, personne ne doit apparaître à sa place finale.
      // 360 px sur l'écran 320 de la référence = 1,125 largeur d'écran.
      final introSlideDistancePx = size.x * 1.125;
      final playerUsesBall = (await playerBallSheetFuture) != null;
      if (!isLoadingAttached()) return;
      final enemyUsesBall = (await enemyBallSheetFuture) != null;
      if (!isLoadingAttached()) return;
      // Recette du 2026-08-24 : ces poses doivent SURVIVRE à la sync qui
      // termine onLoad — d'où l'enregistrement des côtés retenus.
      // Parité `actor_sprites` / `enemy_sprites` de la référence, qui posent
      // `zoom = 0` sur les Pokémon avant toute animation d'entrée.
      _introHeldCombatantSlots = {
        if (_battlePresentation == null) ...[
          const BattleSlotRef.active(BattleSideId.enemy),
          const BattleSlotRef.active(BattleSideId.player),
        ] else ..._battlePresentation!.activeCombatants.map((entry) => entry.slot),
      };
      // Parité `show_team_info` : les barres entrent APRÈS l'annonce.
      _teamInfoRevealed = false;

      if (_session.setup.isTrainerBattle) {
        // Parité `enemy_sprites` : dans un combat de DRESSEUR, le Pokémon
        // adverse ne glisse pas — c'est le dresseur qui entre, puis sort en
        // lançant sa Ball. Le Pokémon attend caché.
        _enemyCombatant?.holdMaterializeHidden();
      } else {
        _enemyCombatant?.holdIntroSlideOffscreen(
          distancePx: introSlideDistancePx,
        );
      }
      if (playerUsesBall) {
        _playerCombatant?.holdMaterializeHidden();
      } else {
        _playerCombatant?.holdIntroSlideOffscreen(
          distancePx: introSlideDistancePx,
        );
      }
      final introTrainerImage = _introTrainerImage;
      if (_session.setup.isTrainerBattle && introTrainerImage != null) {
        final sprite = BattleIntroTrainerComponent(
          image: introTrainerImage,
          spriteRect: layout.enemySpriteRect,
          offscreenDistancePx: introSlideDistancePx,
          priority: (_enemyCombatant?.priority ?? 10) + 1,
        )..holdOffscreen();
        _introTrainerSprite = sprite;
        add(sprite);
      }
      for (final component in _additionalCombatants.values) {
        component.holdMaterializeHidden();
      }
      _pendingIntroPlan = buildBattleIntroAnimationPlan(
        session: _session,
        slideDistancePx: introSlideDistancePx,
        resolveSpeciesDisplayName: resolveSpeciesDisplayName,
        playerBallItemId: playerUsesBall ? playerBallItemId : null,
        enemyBallItemId: enemyUsesBall ? enemyBallItemId : null,
        hasEnemyTrainerSprite: _introTrainerImage != null,
      );
      if (_isDoubles) {
        _pendingIntroPlan = BattleAnimationPlan(steps: [
          ..._pendingIntroPlan!.steps,
          for (final active in _battlePresentation!.activeCombatants.where((entry) => entry.slot.slotIndex != 0)) ...[
            ShowMessageStep(message: '${resolveSpeciesDisplayName(active.combatant.speciesId)} rejoint le combat !'),
            PlayBallSequenceStep(
              side: active.slot.side,
              slotIndex: active.slot.slotIndex,
              kind: active.slot.side == BattleSideId.player ? BattleBallSequenceKind.sendOutThrown : BattleBallSequenceKind.sendOutHeld,
              ballItemId: resolveCombatantBallItemId?.call(active.slot.side, active.lineupIndex),
            ),
            CombatantMotionStep(
              side: active.slot.side,
              slotIndex: active.slot.slotIndex,
              motionKind: BattleCombatantMotionKind.materializeIn,
              durationSeconds: 0.1,
            ),
            PlayCryStep(speciesId: active.combatant.speciesId),
          ],
        ]);
      }
    }

    _fxLayer = BattleFxLayerComponent(
      size: size.clone(),
      fxBundleCache: _fxBundleCache,
    )..effectIntensity = _motionPolicy.effectIntensity;
    add(_fxLayer!);
    _syncFieldAmbientState();
    _animationRunner = BattleAnimationRunner(
      onPresentationChanged: _handleAnimationPresentationChanged,
      onSpawnFx: _handleSpawnFxStep,
      onScreenFlash: _handleScreenFlashStep,
      onCombatantMotion: _handleCombatantMotionStep,
      onCombatantFlash: _handleCombatantFlashStep,
      onCombatantShake: _handleCombatantShakeStep,
      onFaintCombatant: _handleFaintCombatantStep,
      onHudHpTween: _handleHudHpTweenStep,
      onHudXpTween: _handleHudXpTweenStep,
      onHudLevelUp: _handleHudLevelUpStep,
      onShowDefeatedTrainer: _handleShowDefeatedTrainerStep,
      onPlayBallSequence: _handleBallSequenceStep,
      onPlayBallCaptureSequence: _handleBallCaptureSequenceStep,
      onEnemyTrainerIntro: _handleEnemyTrainerIntroStep,
      onStatStageAura: _handleStatStageAuraStep,
      onShowTeamInfo: _handleShowTeamInfoStep,
      onPlayCry: _handlePlayCryStep,
      onPlaySe: (step) => playSfx?.call(
        step.seName,
        volume: step.volume,
        pitch: step.pitch,
      ),
      onStartTrackedEffect: onStartTrackedEffect,
      onStartRecoverableTrackedEffect: onStartRecoverableTrackedEffect == null
          ? null
          : (step, done, fail) {
              _startingTrackedSourceEffect = true;
              try {
                return onStartRecoverableTrackedEffect!(step, done, fail);
              } finally {
                _startingTrackedSourceEffect = false;
              }
            },
      onBarrierPulse: _handleBarrierPulseStep,
      onSwapCombatantVisual: _handleSwapCombatantVisualStep,
      onSwapCombatantVisualStep: _handleSwapCombatantVisualSlot,
      onSpriteSheetFx: _handleSpriteSheetFxStep,
      onSpriteSheetOnCombatant: _handleSpriteSheetOnCombatantStep,
      onParticleBurst: _handleParticleBurstStep,
      onSdkParticleSequence: _handleSdkParticleSequenceStep,
      onSdkFallingParticles: _handleSdkFallingParticlesStep,
      onSdkRadiusParticles: _handleSdkRadiusParticlesStep,
      onSdkScalarParticle: _handleSdkScalarParticleStep,
      onSdkParticleZoom: _handleSdkParticleZoomStep,
      onWeatherParticles: _handleWeatherParticleStep,
      onSceneTint: _handleSceneTintStep,
      onCombatantTone: _handleCombatantToneStep,
      onCombatantCompress: _handleCombatantCompressStep,
      onCombatantEllipse: _handleCombatantEllipseStep,
      onCameraFocus: _handleCameraFocusStep,
      onBattleCameraMove: _handleBattleCameraMoveStep,
      onBattleCameraReset: _handleBattleCameraResetStep,
      onRmxpAnimation: _handleRmxpAnimationStep,
    );

    if (showDebugPanel) {
      final debugPanelStopwatch = Stopwatch()..start();
      _debugPanel = BattleDebugPanelComponent(
        position: Vector2(size.x - 248, 32),
        size: Vector2(216, 148),
      );
      add(_debugPanel!);
      await _debugPanel!.loaded;
      if (!isLoadingAttached()) return;
      debugPanelStopwatch.stop();
      debugPrint(
        '[perf][battle][real] overlay.debugPanel=${debugPanelStopwatch.elapsedMilliseconds}ms',
      );
    }

    final initialSyncStopwatch = Stopwatch()..start();
    final presentationGeneration = _presentationGeneration;
    _trackVisualSync(_syncVisualState(
      presentationGeneration: presentationGeneration,
    ));
    await _pendingVisualSync;
    if (!isLoadingAttached()) return;
    initialSyncStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.initialVisualSync=${initialSyncStopwatch.elapsedMilliseconds}ms',
    );
    overlayStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.total=${overlayStopwatch.elapsedMilliseconds}ms',
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_sceneLayout?.viewportSize == Size(size.x, size.y)) {
      return;
    }
    _applyViewportLayout(size);
  }

  /// Met à jour l'overlay avec une nouvelle session immutable.
  ///
  /// Invariants runtime préservés :
  /// - `BattleSession` reste la seule source de vérité d'état ;
  /// - `BattleDecisionRequest` reste la seule source de vérité des commandes ;
  /// - `BattleTurnResult.timeline` reste la seule source de vérité narrative.
  ///
  /// Le fond n'est volontairement pas recalculé ici :
  /// - le lot 2 le résout à l'ouverture du combat à partir du contexte runtime ;
  /// - l'évolution du tour ne doit pas recréer une logique parallèle de décor ;
  /// - un vrai resolver contextuel plus riche restera un sujet futur côté
  ///   runtime, pas un effet secondaire de `BattleSession`.
  void updateState(BattleSession newSession, {
    GameState? gameState,
    RuntimeBattlePresentation? presentation,
    Map<String, PreparedBattleMoveRecipe>? importedRecipes,
    List<BattleTurnAudioSelection> audioSelections = const [],
    Map<BattleTurnExecutionEvent, String> experimentalSourceEffects = const {},
  }) {
    _cancelGen5SourceProgram(syncPanels: false);
    _cancelPendingTurnAudioPreparation();
    _discardPendingTurnAudio();
    _preparingTurn = false;
    final previousSession = _session;
    final previousPresentation = _battlePresentation;
    _previousBattlePresentation = previousPresentation;
    _battlePresentation = presentation ?? _battlePresentation;
    _pendingTargetChoice = null;
    _pendingTargetRequest = null;
    if (_isDoubles && !identical(previousPresentation?.request, _battlePresentation?.request)) {
      _menuMode = BattleCommandMenuMode.root;
      _selectedChoiceIndex = 0;
    }
    final presentationGeneration = ++_presentationGeneration;
    final animationPlan = _turnAnimationPlanner.build(
      previousSession: previousSession,
      newSession: newSession,
      combatantsBefore: previousPresentation?.combatantsBySlot,
      combatantsAfter: _battlePresentation?.combatantsBySlot,
      moveCatalog: _moveCatalog,
      resolver: _moveVisualResolver,
      importedRecipes: importedRecipes,
      audioSelections: audioSelections,
      experimentalSourceEffects: experimentalSourceEffects,
    );
    if (animationPlan.flattenedSteps.whereType<SwapCombatantVisualStep>()
        .any((step) => step.side == BattleSideId.player)) {
      _menuMode = BattleCommandMenuMode.root;
      _selectedChoiceIndex = 0;
    }
    if (animationPlan.audioScopes.isNotEmpty) {
      _pendingTurnAudioPlan = animationPlan;
    }
    try {
      _session = newSession;
      _syncFieldAmbientState();
      if (gameState != null) {
        _gameState = gameState;
      }
      _selectedMedicineAction = null;
      _selectedMedicineRequest = null;
      _selectedMedicineTargetIndex = 0;
      _bagFeedbackMessage = null;
      _capturedEnemyHeldInBall = false;
      _installActiveAnimationPlan(animationPlan);
      _presentationHeldHp.clear();
      for (final step
          in animationPlan.flattenedSteps.whereType<HudHpTweenStep>()) {
        _presentationHeldHp.putIfAbsent(step.slot, () => step.fromHp);
      }
      _presentationLockedCombatantSlots =
          _lockedCombatantSlotsFor(animationPlan).toSet();
      for (final slot in _presentationLockedCombatantSlots) {
        final previous = previousPresentation?.combatantAt(slot)?.combatant ??
            (slot.slotIndex != 0 ? null : slot.side == BattleSideId.player
                ? previousSession.state.player : previousSession.state.enemy);
        if (previous != null) {
          _presentationHeldHp[slot] = previous.currentHp;
        }
      }
      _resetBattleCamera();
      _resetSceneClock();
      _animationRunner?.cancel(
        clearMessage: animationPlan.isEmpty,
        notify: false,
      );
      _normalizeMenuSelection();
      _trackVisualSync(_prepareAnimationPresentation(
        previousSession: previousSession,
        animationPlan: animationPlan,
        presentationGeneration: presentationGeneration,
      ));
      unawaited(_pendingVisualSync);
    } catch (_) {
      _discardPendingTurnAudio(animationPlan);
      rethrow;
    }
  }

  void _discardPendingTurnAudio([BattleAnimationPlan? expected]) {
    final plan = _pendingTurnAudioPlan;
    if (plan == null || (expected != null && !identical(plan, expected))) return;
    _pendingTurnAudioPlan = null;
    for (final scope in plan.audioScopes) {
      unawaited(scope.cancel().then<void>((_) {}, onError: (Object _) {}));
    }
  }

  void _applyViewportLayout(Vector2 viewportSize, {bool syncPanels = true}) {
    if (viewportSize.x <= 0 || viewportSize.y <= 0) {
      return;
    }
    size = viewportSize.clone();
    final layout = BattleSceneLayout.forViewport(
      viewportSize: Size(size.x, size.y),
      safePadding: _safeAreaPadding,
      textScale: textScale,
      commandPanelPlacement: _commandPanelPlacement,
      commandPanelMode: _sceneLayoutMode,
      controllerLayout: _controllerLayout,
      portraitTouchLayout: _portraitTouchLayout,
    );
    _sceneLayout = layout;

    _perspectiveCamera?.viewport = layout.stageRect;
    _backdrop?.size = Vector2(size.x, size.y);
    _backdrop?.artworkRect = layout.backdropArtworkRect;
    _fxLayer?.size = viewportSize.clone();
    _syncFieldAmbientState();
    _enemyCombatant?.updateSceneGeometry(
      sceneSpriteRect: _geometryFor(const BattleSlotRef.active(BattleSideId.enemy)).spriteRect,
      scenePlatformRect: _geometryFor(const BattleSlotRef.active(BattleSideId.enemy)).platformRect,
      sceneFootAnchor: _geometryFor(const BattleSlotRef.active(BattleSideId.enemy)).footAnchor,
    );
    _playerCombatant?.updateSceneGeometry(
      sceneSpriteRect: _geometryFor(const BattleSlotRef.active(BattleSideId.player)).spriteRect,
      scenePlatformRect: _geometryFor(const BattleSlotRef.active(BattleSideId.player)).platformRect,
      sceneFootAnchor: _geometryFor(const BattleSlotRef.active(BattleSideId.player)).footAnchor,
    );
    for (final entry in _additionalCombatants.entries) {
      final geometry = _geometryFor(entry.key);
      entry.value.updateSceneGeometry(
        sceneSpriteRect: geometry.spriteRect,
        scenePlatformRect: geometry.platformRect,
        sceneFootAnchor: geometry.footAnchor,
      );
    }
    _debugPanel?.position = Vector2(size.x - 248, 32);
    _refreshBattleCameraFramingIfChanged();
    _applyBattleCameraTransform();
    _notifyOutcomePresented();
    if (syncPanels) _syncPanelsOnly();
  }

  bool moveSelectionUp() {
    return _moveSelection(horizontalDelta: 0, verticalDelta: -1);
  }

  bool moveSelectionDown() {
    return _moveSelection(horizontalDelta: 0, verticalDelta: 1);
  }

  bool moveSelectionLeft() {
    return _moveSelection(horizontalDelta: -1, verticalDelta: 0);
  }

  bool moveSelectionRight() {
    return _moveSelection(horizontalDelta: 1, verticalDelta: 0);
  }

  PlayerBattleChoice? getSelectedChoice() {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return null;
    }
    final menuModel = _currentMenuModel();
    if (menuModel.mode == BattleCommandMenuMode.bag ||
        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget ||
        menuModel.mode == BattleCommandMenuMode.bagMedicineMoveTarget) {
      return null;
    }
    final partyMenuModel = _currentPartyMenuModel();
    if (menuModel.mode == BattleCommandMenuMode.pokemon) {
      if (partyMenuModel.allEntries.isEmpty) {
        return null;
      }
      final safeIndex =
          _selectedPartyIndex.clamp(0, partyMenuModel.allEntries.length - 1);
      return partyMenuModel.allEntries[safeIndex].playerChoice;
    }
    if (menuModel.isRootMode || menuModel.choiceEntries.isEmpty) {
      return null;
    }
    return menuModel.choiceEntries[menuModel.selectedChoiceIndex].choice;
  }

  bool validateSelectedChoice() {
    if (_pendingTargetChoice != null) {
      return selectMoveTargetEntry(_selectedTargetIndex);
    }
    if (_postBattleDecision != null) {
      return _submitPostBattleDecision(_postBattleDecisionSelectedIndex);
    }
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
    if (menuModel.mode == BattleCommandMenuMode.bagMedicineMoveTarget) {
      return selectMedicineMoveTargetEntry(_selectedMedicineMoveIndex);
    }
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    if (menuModel.isContinueOnly) {
      final selectedChoice = menuModel.choiceEntries.first.choice;
      _handleChoiceSelected(selectedChoice);
      return true;
    }
    if (menuModel.isRootMode) {
      final entry = menuModel.rootEntries[menuModel.selectedRootIndex];
      if (!entry.enabled) {
        return false;
      }
      _handleRootActionSelected(entry.action);
      return true;
    }
    if (menuModel.mode == BattleCommandMenuMode.pokemon) {
      if (partyMenuModel.allEntries.isEmpty) {
        return false;
      }
      final safeIndex =
          _selectedPartyIndex.clamp(0, partyMenuModel.allEntries.length - 1);
      final selectedEntry = partyMenuModel.allEntries[safeIndex];
      if (!selectedEntry.isSelectable || selectedEntry.playerChoice == null) {
        return false;
      }
      _handlePartyEntrySelected(selectedEntry);
      return true;
    }
    if (menuModel.mode == BattleCommandMenuMode.bag) {
      if (bagMenuModel.entries.isEmpty) {
        return false;
      }
      final safeIndex =
          _selectedBagIndex.clamp(0, bagMenuModel.entries.length - 1);
      final selectedEntry = bagMenuModel.entries[safeIndex];
      if (!selectedEntry.isSelectable) {
        return false;
      }
      _handleBagEntrySelected(selectedEntry);
      return true;
    }
    if (menuModel.mode == BattleCommandMenuMode.bagMedicineTarget) {
      if (medicineTargetMenuModel == null ||
          medicineTargetMenuModel.entries.isEmpty) {
        return false;
      }
      final safeIndex = _selectedMedicineTargetIndex.clamp(
        0,
        medicineTargetMenuModel.entries.length - 1,
      );
      final selectedEntry = medicineTargetMenuModel.entries[safeIndex];
      if (!selectedEntry.isSelectable) {
        return false;
      }
      return _handleMedicineTargetEntrySelected(selectedEntry);
    }
    final selectedChoice =
        menuModel.choiceEntries[menuModel.selectedChoiceIndex].choice;
    _handleChoiceSelected(selectedChoice);
    return true;
  }

  bool selectRootEntry(int index) {
    if (_postBattleDecision != null) {
      return _submitPostBattleDecision(index);
    }
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
    if (!menuModel.isRootMode ||
        index < 0 ||
        index >= menuModel.rootEntries.length) {
      return false;
    }
    final entry = menuModel.rootEntries[index];
    if (!entry.enabled) {
      return false;
    }
    _selectedRootIndex = index;
    _handleRootActionSelected(entry.action);
    return true;
  }

  bool selectChoiceEntry(int index) {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
    if (menuModel.isRootMode ||
        menuModel.isContinueOnly ||
        index < 0 ||
        index >= menuModel.choiceEntries.length) {
      return false;
    }
    _selectedChoiceIndex = index;
    _handleChoiceSelected(menuModel.choiceEntries[index].choice);
    return true;
  }

  bool selectBagEntry(int index) {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final bagMenuModel = _currentBagMenuModel();
    if (_currentMenuModel().mode != BattleCommandMenuMode.bag ||
        index < 0 ||
        index >= bagMenuModel.entries.length) {
      return false;
    }
    final entry = bagMenuModel.entries[index];
    if (!entry.isSelectable) {
      return false;
    }
    _selectedBagIndex = index;
    _handleBagEntrySelected(entry);
    return true;
  }

  bool selectPartyEntry(int index) {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final partyMenuModel = _currentPartyMenuModel();
    if (_currentMenuModel().mode != BattleCommandMenuMode.pokemon ||
        index < 0 ||
        index >= partyMenuModel.allEntries.length) {
      return false;
    }
    final entry = partyMenuModel.allEntries[index];
    if (!entry.isSelectable || entry.playerChoice == null) {
      return false;
    }
    _selectedPartyIndex = index;
    _handlePartyEntrySelected(entry);
    return true;
  }

  bool selectMedicineTargetEntry(int index) {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    if (_currentMenuModel().mode != BattleCommandMenuMode.bagMedicineTarget ||
        medicineTargetMenuModel == null ||
        index < 0 ||
        index >= medicineTargetMenuModel.entries.length) {
      return false;
    }
    final entry = medicineTargetMenuModel.entries[index];
    if (!entry.isSelectable) {
      return false;
    }
    _selectedMedicineTargetIndex = index;
    return _handleMedicineTargetEntrySelected(entry);
  }

  bool selectMedicineMoveTargetEntry(int index) {
    if (!_acceptsPlayerCommands ||
        isTurnPresentationActive ||
        _currentMenuModel().mode != BattleCommandMenuMode.bagMedicineMoveTarget) {
      return false;
    }
    final entries = _medicineMoveEntries();
    final action = _selectedMedicineAction;
    final target = _selectedMedicineEntry();
    if (action == null ||
        target == null ||
        index < 0 ||
        index >= entries.length ||
        !entries[index].enabled) {
      return false;
    }
    _selectedMedicineMoveIndex = index;
    return onBagMovePpItemUseRequested?.call(action, target, index, request: _selectedMedicineRequest) ?? false;
  }

  BattleMedicineTargetEntry? _selectedMedicineEntry() {
    final model = _currentMedicineTargetMenuModel();
    if (model == null ||
        _selectedMedicineTargetIndex < 0 ||
        _selectedMedicineTargetIndex >= model.entries.length) {
      return null;
    }
    return model.entries[_selectedMedicineTargetIndex];
  }

  List<BattleCommandOverlayEntry> _medicineMoveEntries() {
    final entry = _selectedMedicineEntry();
    if (entry == null) return const [];
    final state = medicineBattleState?.call() ?? _session.state;
    final targets = [state.player, ...state.playerReserve];
    final target = targets.where(
      (target) => target.lineupIndex == entry.lineupIndex,
    );
    if (target.length != 1) return const [];
    return List<BattleCommandOverlayEntry>.unmodifiable(
      target.single.moves.asMap().entries.map((slot) {
        final move = slot.value;
        final enabled = entry.isSelectable && move.currentPp < move.pp;
        return BattleCommandOverlayEntry(
          index: slot.key,
          kind: BattleCommandOverlayEntryKind.move,
          primaryLabel: resolveMoveDisplayName(
            move.id,
            move.name,
          ),
          secondaryLabel: move.type,
          trailingLabel: 'PP ${move.currentPp}/${move.pp}',
          enabled: enabled,
          selected: slot.key == _selectedMedicineMoveIndex,
          tone: enabled
              ? BattleCommandOverlayEntryTone.medicine
              : BattleCommandOverlayEntryTone.disabled,
        );
      }),
    );
  }

  bool handleEscape() {
    if (_pendingTargetChoice != null) {
      _pendingTargetChoice = null;
      _pendingTargetRequest = null;
      _syncPanelsOnly();
      return true;
    }
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
    if (menuModel.mode == BattleCommandMenuMode.bagMedicineMoveTarget) {
      _menuMode = BattleCommandMenuMode.bagMedicineTarget;
      _syncPanelsOnly();
      return true;
    }
    if (menuModel.isContinueOnly) {
      return false;
    }
    if (!menuModel.isRootMode) {
      final partyMenuModel = _currentPartyMenuModel();
      if (menuModel.mode == BattleCommandMenuMode.pokemon &&
          partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement) {
        return false;
      }
      if (menuModel.mode == BattleCommandMenuMode.bagMedicineTarget) {
        _selectedMedicineAction = null;
    _selectedMedicineRequest = null;
        _selectedMedicineTargetIndex = 0;
        _bagFeedbackMessage = null;
        _menuMode = BattleCommandMenuMode.bag;
        _syncPanelsOnly();
        return true;
      }
      _bagFeedbackMessage = null;
      _menuMode = BattleCommandMenuMode.root;
      _syncPanelsOnly();
      return true;
    }

    final runEntry = menuModel.rootEntries[BattleCommandRootAction.run.index];
    if (menuModel.selectedRootIndex == BattleCommandRootAction.run.index &&
        runEntry.enabled) {
      _handleRootActionSelected(BattleCommandRootAction.run);
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    _advanceScene(dt, updateChildren: false);
  }

  @override
  void updateSubtree(double dt) {
    _advanceScene(dt, updateChildren: true);
  }

  double _pendingSceneSeconds = 0;
  int _sceneClockRevision = 0;

  void _resetSceneClock() {
    _sceneClockRevision += 1;
    _pendingSceneSeconds = 0;
  }

  void _advanceScene(double dt, {required bool updateChildren}) {
    final runner = _animationRunner;
    if (runner == null) {
      _advanceSceneWithinBudget(dt, updateChildren: updateChildren);
    } else {
      runner.withWorkBudget(() =>
        _advanceSceneWithinBudget(dt, updateChildren: updateChildren));
    }
  }

  void _advanceSceneWithinBudget(double dt, {required bool updateChildren}) {
    if (_ballImagesDisposed || !dt.isFinite || dt < 0) return;
    _syncReducedBattleEffects();
    if (!_canPlayGroupedSpl) {
      for (final effect in _groupedSplEffects.values.toList()) {
        effect.failIfStarted();
      }
    }
    if (_reducedBattleMotion && isBattleCameraActive) _resetBattleCamera();
    if (_introTrainerExitPending &&
        (_introTrainerSprite?.isMotionComplete ?? false)) {
      _introTrainerExitPending = false;
      final sprite = _introTrainerSprite;
      _introTrainerSprite = null;
      // En microtask : le retrait en pleine itération updateTree muterait
      // l'arbre pendant son parcours (le piège de BAT-016).
      Future<void>.microtask(() => sprite?.removeFromParent());
    }
    // Une seule mise à l'échelle pour toute la scène : le runner, la caméra et
    // les enfants visuels avancent sur la même horloge, donc rien ne se
    // désynchronise. Scaler la seule durée de phase du runner couperait les
    // effets en cours, ce qui reviendrait à les sauter.
    final scaledDt = dt * _motionPolicy.playbackSpeed;
    final elapsed = _pendingSceneSeconds + scaledDt;
    if (!elapsed.isFinite) return;
    var remaining = elapsed;
    var substeps = 0;
    var runnerWorkRemaining = 256;
    final revision = _sceneClockRevision;
    if (_animationRunner?.hasImmediateWork ?? false) {
      runnerWorkRemaining -= _animationRunner!.update(0,
        workBudget: runnerWorkRemaining);
      if (_sceneClockRevision != revision) return;
      if (_animationRunner?.hasImmediateWork ?? false) {
        _pendingSceneSeconds = remaining;
        return;
      }
    }
    while (remaining > .000001 && substeps < 32) {
      if (runnerWorkRemaining <= 0) break;
      substeps += 1;
      final sourceProgram = _gen5SourceProgram;
      if (sourceProgram != null && _gen5SourceTickElapsed == 0) {
        try {
          sourceProgram.tick();
        } on Object catch (error, stack) {
          _finishGen5SourceProgram(sourceProgram,
            failure: error, failureStack: stack);
        }
        if (_sceneClockRevision != revision) return;
        if (!identical(_gen5SourceProgram, sourceProgram)) continue;
        if (sourceProgram.status != BattleGen5SourcePlaybackStatus.ready &&
            sourceProgram.status != BattleGen5SourcePlaybackStatus.running) {
          _finishGen5SourceProgram(sourceProgram);
          continue;
        }
        try {
          _gen5SourceAdvance?.call();
        } on Object catch (error, stack) {
          try {
            sourceProgram.cancel();
          } on Object {
            _finishGen5SourceProgram(sourceProgram,
              failure: error, failureStack: stack);
            continue;
          }
          _finishGen5SourceProgram(sourceProgram,
            failure: error, failureStack: stack);
          continue;
        }
      }
      final phaseRemaining = _animationRunner?.secondsUntilNextPhase ?? double.infinity;
      final sourceRemaining = sourceProgram == null
          ? double.infinity : 1 / 60 - _gen5SourceTickElapsed;
      final tick = math.min(remaining, math.min(sourceRemaining, math.min(1 / 60,
          phaseRemaining > .000001 ? phaseRemaining : 1 / 60)));
      _advanceIdleMotion(tick);
      if (_perspectiveCamera?.isMoving ?? false) {
        _perspectiveCamera?.update(tick);
        _applyBattleCameraTransform();
      }
      if (updateChildren) {
        for (final child in children) {
          child.updateTree(tick);
          if (_sceneClockRevision != revision) return;
        }
      }
      runnerWorkRemaining -= _animationRunner?.update(tick,
        workBudget: runnerWorkRemaining) ?? 0;
      if (_sceneClockRevision != revision) return;
      if (sourceProgram != null && identical(_gen5SourceProgram, sourceProgram)) {
        _gen5SourceTickElapsed += tick;
        if (_gen5SourceTickElapsed >= 1 / 60 - .000000001) {
          _gen5SourceTickElapsed = 0;
          if (sourceProgram.status != BattleGen5SourcePlaybackStatus.ready &&
              sourceProgram.status != BattleGen5SourcePlaybackStatus.running) {
            _finishGen5SourceProgram(sourceProgram);
          }
        }
      }
      remaining -= tick;
      if (_animationRunner?.hasImmediateWork ?? false) break;
    }
    _pendingSceneSeconds = math.max(0, remaining);
  }

  void _advanceIdleMotion(double dt) {
    final waiting = !_presentationPendingOrRunning && _pendingIntroPlan == null && _teamInfoRevealed && !_session.state.isFinished;
    for (final slot in [const BattleSlotRef.active(BattleSideId.enemy), const BattleSlotRef.active(BattleSideId.player), ..._additionalCombatants.keys]) {
      final actor = _combatantForSlot(slot);
      if (actor == null) continue;
      final motion = _idleMotions.putIfAbsent(slot, () => BattleIdleMotion(
        periodSeconds: (slot.side == BattleSideId.player ? 4.8 : 5.6) + slot.slotIndex * .4,
        direction: slot.side == BattleSideId.player ? 1 : -1,
      ));
      final amount = math.min(10.0, currentSceneLayout.stageRect.width * .018);
      actor.setIdleLateralOffset(motion.advance(dt, waiting: waiting && !_reducedBattleMotion) * amount);
    }
  }

  Future<void> _syncVisualState({
    BattleSession? previousSession,
    Set<BattleSlotRef> preserveDisplayedCombatantSlots = const <BattleSlotRef>{},
    required int presentationGeneration,
  }) async {
    if (!_isCurrentPresentationGeneration(presentationGeneration)) {
      return;
    }
    _syncFieldAmbientState();
    if (_isDoubles) {
      for (final active in _battlePresentation!.activeCombatants) {
        final old = _previousBattlePresentation?.combatantAt(active.slot);
        final projected =
            preserveDisplayedCombatantSlots.contains(active.slot) && old != null
                ? old
                : active;
        final displayed = projected.combatant;
        final component = _combatantForSlot(active.slot);
        if (component == null) continue;
        final sprite = await _resolveCombatantSpriteSpec(
          speciesId: displayed.speciesId,
          isPlayerSide: active.slot.side == BattleSideId.player,
          lineupIndex: displayed.lineupIndex,
          projection: projected,
        );
        if (!_isCurrentPresentationGeneration(presentationGeneration)) return;
        _displayedCombatantsBySlot[active.slot] = displayed;
        await component.sync(
          speciesLabel: resolveSpeciesDisplayName(displayed.speciesId),
          spriteSpec: sprite,
        );
        if (!_isCurrentPresentationGeneration(presentationGeneration)) return;
        if (!displayed.isFainted && !preserveDisplayedCombatantSlots.contains(active.slot) && !_introHeldCombatantSlots.contains(active.slot)) {
          component.snapToBattlePose();
        }
      }
      _syncPanelsOnly();
      _notifyOutcomePresented();
      return;
    }
    const enemySlot = BattleSlotRef.active(BattleSideId.enemy);
    const playerSlot = BattleSlotRef.active(BattleSideId.player);
    final preserveEnemy =
        preserveDisplayedCombatantSlots.contains(enemySlot) && previousSession != null;
    final preservePlayer =
        preserveDisplayedCombatantSlots.contains(playerSlot) && previousSession != null;
    final displayedEnemyCombatant =
        preserveEnemy
            ? previousSession.state.enemy
            : _session.state.enemy;
    final displayedPlayerCombatant =
        preservePlayer
            ? previousSession.state.player
            : _session.state.player;
    BattleCombatantSpriteSpec? enemySpriteSpec;
    if (_enemyCombatant != null) {
      enemySpriteSpec = await _resolveCombatantSpriteSpec(
        speciesId: displayedEnemyCombatant.speciesId,
        isPlayerSide: false,
        lineupIndex: displayedEnemyCombatant.lineupIndex,
        projection: (preserveEnemy ? _previousBattlePresentation : _battlePresentation)
            ?.combatantAt(enemySlot),
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
    }
    BattleCombatantSpriteSpec? playerSpriteSpec;
    if (_playerCombatant != null) {
      playerSpriteSpec = await _resolveCombatantSpriteSpec(
        speciesId: displayedPlayerCombatant.speciesId,
        isPlayerSide: true,
        lineupIndex: displayedPlayerCombatant.lineupIndex,
        projection: (preservePlayer ? _previousBattlePresentation : _battlePresentation)
            ?.combatantAt(playerSlot),
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
    }
    _displayedEnemyCombatant = displayedEnemyCombatant;
    _displayedPlayerCombatant = displayedPlayerCombatant;

    if (_enemyCombatant != null && enemySpriteSpec != null) {
      await _enemyCombatant!.sync(
        speciesLabel:
            resolveSpeciesDisplayName(displayedEnemyCombatant.speciesId),
        spriteSpec: enemySpriteSpec,
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
    }
    if (_playerCombatant != null && playerSpriteSpec != null) {
      await _playerCombatant!.sync(
        speciesLabel:
            resolveSpeciesDisplayName(displayedPlayerCombatant.speciesId),
        spriteSpec: playerSpriteSpec,
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
    }
    _restoreAliveCombatantPoseAfterSync(
      side: BattleSideId.enemy,
      combatant: displayedEnemyCombatant,
      preserveDisplayedCombatantSlots: preserveDisplayedCombatantSlots,
    );
    _restoreAliveCombatantPoseAfterSync(
      side: BattleSideId.player,
      combatant: displayedPlayerCombatant,
      preserveDisplayedCombatantSlots: preserveDisplayedCombatantSlots,
    );
    _syncPanelsOnly();
    _notifyOutcomePresented();
  }

  void _restoreAliveCombatantPoseAfterSync({
    required BattleSideId side,
    required BattleCombatant combatant,
    required Set<BattleSlotRef> preserveDisplayedCombatantSlots,
  }) {
    if (preserveDisplayedCombatantSlots.contains(BattleSlotRef.active(side)) || combatant.isFainted) {
      return;
    }
    // BETA-BAT-025 : un sauvage CAPTURÉ reste dans sa Ball, comme un K.O.
    // reste couché — sans quoi il se remettait debout une fraction de
    // seconde après le clic de verrouillage.
    if (side == BattleSideId.enemy && _capturedEnemyHeldInBall) {
      _combatantForSide(side)?.holdMaterializeHidden();
      return;
    }
    // Recette du 2026-08-24 (vidéo 18-09-39) : « les deux pokémons sont déjà
    // présents, PUIS il y a l'animation ». Les holds d'entrée posés en fin
    // d'onLoad étaient écrasés par CETTE restauration, appelée par la sync du
    // même onLoad : au lever du rideau, les deux combattants étaient debout à
    // leur place et l'intro rejouait leur arrivée par-dessus. Tant que le
    // plan d'intro attend son départ, les poses d'entrée tiennent.
    if (_introHeldCombatantSlots.contains(BattleSlotRef.active(side))) {
      return;
    }

    _combatantForSide(side)?.snapToBattlePose();
  }

  Future<BattleCombatantSpriteSpec> _resolveCombatantSpriteSpec({
    required String speciesId,
    required bool isPlayerSide,
    required int lineupIndex,
    RuntimeBattleActiveCombatantProjection? projection,
  }) async {
    final resolver = spriteResolver;
    if (resolver == null) {
      return BattleCombatantSpriteSpec(
        facing: isPlayerSide
            ? BattleCombatantSpriteFacing.back
            : BattleCombatantSpriteFacing.front,
      );
    }
    return resolver.resolve(
      speciesId: speciesId,
      isPlayerSide: isPlayerSide,
      visualIdentity: projection?.lineupIndex == lineupIndex &&
              projection?.combatant.speciesId == speciesId
          ? projection?.currentVisualIdentity
          : null,
    );
  }

  String? _resolveCombatantGenderSymbol({
    required BattleCombatant combatant,
    required bool isPlayerSide,
  }) {
    return genderResolver?.resolveGenderSymbol(
      isPlayerSide: isPlayerSide,
      lineupIndex: combatant.lineupIndex,
    );
  }

  String _hudSpeciesDisplayText(
    BattleCombatant combatant, {
    required bool isPlayerSide,
  }) {
    final genderSymbol = _resolveCombatantGenderSymbol(
      combatant: combatant,
      isPlayerSide: isPlayerSide,
    );
    final speciesName = resolveSpeciesDisplayName(combatant.speciesId);
    return genderSymbol == null ? speciesName : '$speciesName $genderSymbol';
  }

  void _syncPanelsOnly() {
    final decision = _postBattleDecision;
    if (decision != null) {
      if (_sceneLayout?.commandPanelMode != BattleCommandOverlayMode.decision) {
        _applyViewportLayout(size, syncPanels: false);
      }
      _refreshBattleCameraFramingIfChanged();
      _publishPostBattleDecisionPresentation(decision);
      return;
    }
    _syncMenuStateFromModel();
    if (_sceneLayout?.commandPanelMode != _sceneLayoutMode) {
      _applyViewportLayout(size, syncPanels: false);
    }
    _refreshBattleCameraFramingIfChanged();
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    final currentAnimationMessage = _animationRunner?.currentMessage;
    // BETA-BAT-033 : `_presentationPendingOrRunning` couvre aussi la fenêtre
    // entre la pose du plan et son démarrage — le trou que BETA-BAT-012 avait
    // documenté puis bouché pour le seul bandeau d'issue.
    final isPresenting =
        _presentationPendingOrRunning || !_acceptsPlayerCommands;
    final partyPrompt = menuModel.mode == BattleCommandMenuMode.pokemon
        ? buildBattlePartyPromptForOverlay(partyMenuModel)
        : null;
    final partyNarration = menuModel.mode == BattleCommandMenuMode.pokemon
        ? buildBattlePartyNarrationLinesForOverlay(partyMenuModel)
        : null;
    final bagPrompt = menuModel.mode == BattleCommandMenuMode.bag
        ? buildBattleBagPromptForOverlay(
            bagMenuModel,
            feedbackMessage: _bagFeedbackMessage,
          )
        : null;
    final bagNarration = menuModel.mode == BattleCommandMenuMode.bag
        ? buildBattleBagNarrationLinesForOverlay(
            bagMenuModel,
            feedbackMessage: _bagFeedbackMessage,
          )
        : null;
    final medicineTargetPrompt =
        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
                medicineTargetMenuModel != null
            ? buildBattleMedicineTargetPromptForOverlay(
                medicineTargetMenuModel,
                feedbackMessage: _bagFeedbackMessage,
              )
            : null;
    final medicineTargetNarration =
        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
                medicineTargetMenuModel != null
            ? buildBattleMedicineTargetNarrationLinesForOverlay(
                medicineTargetMenuModel,
                feedbackMessage: _bagFeedbackMessage,
              )
            : null;
    // Recette du 2026-08-24 (vidéo 18-09-39) : pendant l'intro, la boîte
    // affichait « Que doit faire X ? » AVANT les messages d'ouverture — le
    // menu semblait ouvert alors que la scène entrait encore. Une animation
    // qui joue sans message ne pose aucune question : la référence laisse sa
    // boîte muette jusqu'à ce qu'elle ait quelque chose à dire.
    final resolvedPrompt = currentAnimationMessage ??
        (menuModel.mode == BattleCommandMenuMode.bagMedicineMoveTarget
            ? 'Choisis une attaque pour ${_selectedMedicineAction?.displayName}.'
            : null) ??
        medicineTargetPrompt ??
        bagPrompt ??
        partyPrompt ??
        ((_animationRunner?.isActive ?? false)
            ? ''
            : buildBattleDecisionPromptForSession(
                _session,
                resolveSpeciesDisplayName: resolveSpeciesDisplayName,
              ));
    final defaultNarration = _introPlayed &&
            !_session.state.isFinished &&
            _session.state.currentTurn == null
        ? const <String>[]
        : buildBattleNarrationLinesForOverlay(
            _session,
            resolveSpeciesDisplayName: resolveSpeciesDisplayName,
          );
    final resolvedNarration = isPresenting
        ? const <String>[]
        : ((menuModel.mode == BattleCommandMenuMode.bagMedicineMoveTarget
                ? const <String>['Les attaques aux PP max restent grisées.']
                : null) ??
            medicineTargetNarration ??
            bagNarration ??
            partyNarration ??
            defaultNarration);

    _publishCommandOverlaySnapshot(
      menuModel: menuModel,
      partyMenuModel: partyMenuModel,
      bagMenuModel: bagMenuModel,
      medicineTargetMenuModel: medicineTargetMenuModel,
      prompt: resolvedPrompt,
      narrationLines: resolvedNarration,
      interactionsEnabled: !isPresenting,
    );

    _debugPanel?.sync(
      lines: buildBattleDebugLinesForOverlay(
        _session,
        selectedIndex: menuModel.isRootMode
            ? menuModel.selectedRootIndex
            : menuModel.selectedChoiceIndex,
      ),
    );
  }

  /// BETA-BAT-017 sous-lot 2 : la présentation d'une décision post-combat.
  ///
  /// Le prompt (le message du coordinator) reste dans la boîte de dialogue,
  /// les choix prennent la place des commandes. Les interactions passent
  /// outre le gate post-combat : c'est précisément le moment où le joueur
  /// doit répondre. Sur le panneau Flame (hôte développeur), les choix
  /// s'affichent en narration avec la sélection marquée.
  void _publishPostBattleDecisionPresentation(
    _PostBattleDecisionRequest decision,
  ) {
    final layout = currentSceneLayout;
    final snapshot = BattleCommandOverlaySnapshot(
      revision: ++_commandOverlayRevision,
      phase: BattlePresentationPhase.choosingCommand,
      forcedReplacement: false,
      mode: BattleCommandOverlayMode.decision,
      viewportSize: layout.viewportSize,
      panelRect: layout.commandPanelRect,
      commandPanelPlacement: layout.commandPanelPlacement,
      controllerLayout: _controllerLayout,
      portraitTouchLayout: _portraitTouchLayout,
      rootCommandOrder: _rootCommandOrder,
      collectionColumns: _collectionColumns,
      additionalHuds: _additionalHudSnapshots(),
      actorSlot: _isDoubles ? runtimeBattleSlot(_battlePresentation!.request.actor) : null,
      actorCombatantId: _isDoubles ? _battlePresentation!.request.actorCombatantId : null,
      enemyHud: _buildHudSnapshot(
        rect: _geometryFor(const BattleSlotRef.active(BattleSideId.enemy)).hudRect,
        ownerLabel: 'ENNEMI',
        combatant: _displayedCombatantsBySlot[const BattleSlotRef.active(BattleSideId.enemy)] ?? _displayedEnemyCombatant ?? _combatantDataAt(const BattleSlotRef.active(BattleSideId.enemy)),
        isPlayerSide: false,
      ),
      playerHud: _buildHudSnapshot(
        rect: _geometryFor(const BattleSlotRef.active(BattleSideId.player)).hudRect,
        ownerLabel: 'JOUEUR',
        combatant: _displayedCombatantsBySlot[const BattleSlotRef.active(BattleSideId.player)] ?? _displayedPlayerCombatant ?? _combatantDataAt(const BattleSlotRef.active(BattleSideId.player)),
        isPlayerSide: true,
      ),
      battleLabel: _titleForSession(),
      title: 'CHOIX',
      prompt: decision.prompt,
      narrationLines: const <String>[],
      entries: List<
          BattleCommandOverlayEntry>.unmodifiable(<BattleCommandOverlayEntry>[
        for (var index = 0; index < decision.choices.length; index++)
          BattleCommandOverlayEntry(
            index: index,
            kind: BattleCommandOverlayEntryKind.decision,
            primaryLabel: decision.choices[index],
            secondaryLabel: '',
            enabled: true,
            selected: index == _postBattleDecisionSelectedIndex,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
      ]),
      interactionsEnabled: true,
      canGoBack: false,
    );
    _currentCommandOverlaySnapshot = snapshot;
    onCommandOverlaySnapshotChanged?.call(snapshot);
  }

  void _publishCommandOverlaySnapshot({
    required BattleCommandMenuModel menuModel,
    required BattlePartyMenuModel partyMenuModel,
    required BattleBagMenuModel bagMenuModel,
    required BattleMedicineTargetMenuModel? medicineTargetMenuModel,
    required String prompt,
    required List<String> narrationLines,
    required bool interactionsEnabled,
  }) {
    if (_pendingIntroPlan != null) {
      // Sous le rideau, les widgets Flutter (au-dessus de tout canvas Flame)
      // perceraient le noir : aucun snapshot tant que l'intro n'a pas démarré.
      onCommandOverlaySnapshotChanged?.call(null);
      return;
    }
    final layout = currentSceneLayout;
    // La garde sur `_effectiveMenuMode` couvre déjà la bascule automatique ;
    // celle-ci reste pour le cas où le joueur avait laissé le menu POKÉMON
    // ouvert avant de soumettre — le mode vient alors de lui, pas du KO.
    final isForcedReplacement =
        partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement &&
            menuModel.mode == BattleCommandMenuMode.pokemon &&
            !_presentationPendingOrRunning;
    final choosingTarget = _pendingTargetChoice != null;
    final actor = _isDoubles ? _battlePresentation!.combatantAt(runtimeBattleSlot(_battlePresentation!.request.actor)) : null;
    final snapshot = BattleCommandOverlaySnapshot(
      revision: ++_commandOverlayRevision,
      phase: isForcedReplacement
          ? BattlePresentationPhase.forcedReplacement
          : interactionsEnabled
              ? BattlePresentationPhase.choosingCommand
              : BattlePresentationPhase.presentingTurn,
      forcedReplacement: isForcedReplacement,
      mode: choosingTarget ? BattleCommandOverlayMode.moveTarget : _overlayModeForMenuMode(menuModel.mode),
      viewportSize: layout.viewportSize,
      panelRect: layout.commandPanelRect,
      commandPanelPlacement: layout.commandPanelPlacement,
      controllerLayout: _controllerLayout,
      portraitTouchLayout: _portraitTouchLayout,
      rootCommandOrder: _rootCommandOrder,
      collectionColumns: _collectionColumns,
      additionalHuds: _additionalHudSnapshots(),
      actorSlot: _isDoubles ? runtimeBattleSlot(_battlePresentation!.request.actor) : null,
      actorCombatantId: _isDoubles ? _battlePresentation!.request.actorCombatantId : null,
      enemyHud: _buildHudSnapshot(
        rect: _geometryFor(const BattleSlotRef.active(BattleSideId.enemy)).hudRect,
        ownerLabel: 'ENNEMI',
        combatant: _displayedCombatantsBySlot[const BattleSlotRef.active(BattleSideId.enemy)] ?? _displayedEnemyCombatant ?? _combatantDataAt(const BattleSlotRef.active(BattleSideId.enemy)),
        isPlayerSide: false,
      ),
      playerHud: _buildHudSnapshot(
        rect: _geometryFor(const BattleSlotRef.active(BattleSideId.player)).hudRect,
        ownerLabel: 'JOUEUR',
        combatant: _displayedCombatantsBySlot[const BattleSlotRef.active(BattleSideId.player)] ?? _displayedPlayerCombatant ?? _combatantDataAt(const BattleSlotRef.active(BattleSideId.player)),
        isPlayerSide: true,
      ),
      battleLabel: _titleForSession(),
      title: choosingTarget ? 'TARGET' : menuModel.isRootMode ? 'COMMANDS' : menuModel.choiceGroupTitle,
      prompt: choosingTarget ? 'Choisis la cible de ${resolveSpeciesDisplayName(actor!.combatant.speciesId)}.' : actor != null && menuModel.isRootMode ? 'Que doit faire ${resolveSpeciesDisplayName(actor.combatant.speciesId)} ?' : prompt,
      narrationLines: List<String>.unmodifiable(narrationLines),
      entries: choosingTarget ? _moveTargetEntries() : _buildCommandOverlayEntries(
        menuModel: menuModel,
        partyMenuModel: partyMenuModel,
        bagMenuModel: bagMenuModel,
        medicineTargetMenuModel: medicineTargetMenuModel,
      ),
      interactionsEnabled: interactionsEnabled,
      canGoBack: choosingTarget || _canGoBackFrom(menuModel, partyMenuModel),
    );
    _currentCommandOverlaySnapshot = snapshot;
    onCommandOverlaySnapshotChanged?.call(snapshot);
    _primeBagIconAssetPaths(bagMenuModel);
  }

  List<BattleCommandOverlayEntry> _moveTargetEntries() {
    final targets = _pendingMoveTargets;
    return List.unmodifiable([
      for (var index = 0; index < targets.length; index++)
        BattleCommandOverlayEntry(
          index: index,
          kind: BattleCommandOverlayEntryKind.target,
          primaryLabel: resolveSpeciesDisplayName(_battlePresentation!.combatantAt(runtimeBattleSlot(targets[index]))!.combatant.speciesId),
          secondaryLabel: '${_battlePresentation!.combatantAt(runtimeBattleSlot(targets[index]))!.combatant.currentHp}/${_battlePresentation!.combatantAt(runtimeBattleSlot(targets[index]))!.combatant.maxHp} PV',
          enabled: true,
          selected: index == _selectedTargetIndex,
          tone: BattleCommandOverlayEntryTone.neutral,
        ),
    ]);
  }

  List<BattleCommandOverlayHudSnapshot> _additionalHudSnapshots() {
    if (!_isDoubles) return const [];
    return List.unmodifiable([
      for (final active in _battlePresentation!.activeCombatants.where((entry) => entry.slot.slotIndex != 0))
        _buildHudSnapshot(
          rect: _geometryFor(active.slot).hudRect,
          ownerLabel: active.slot.side == BattleSideId.player ? 'JOUEUR' : 'ENNEMI',
          combatant: _displayedCombatantsBySlot[active.slot] ?? active.combatant,
          isPlayerSide: active.slot.side == BattleSideId.player,
          slot: active.slot,
          combatantId: active.combatantId,
        ),
    ]);
  }

  BattleCommandOverlayHudSnapshot _buildHudSnapshot({
    required Rect rect,
    required String ownerLabel,
    required BattleCombatant combatant,
    required bool isPlayerSide,
    BattleSlotRef? slot,
    String combatantId = '',
  }) {
    final targetSide = slot ?? BattleSlotRef.active(
      isPlayerSide ? BattleSideId.player : BattleSideId.enemy,
    );
    final currentProjection = _battlePresentation?.combatantAt(targetSide);
    final previousProjection = _previousBattlePresentation?.combatantAt(targetSide);
    final displayedIdentity = currentProjection?.lineupIndex == combatant.lineupIndex
        ? currentProjection?.combatantId
        : previousProjection?.combatantId;
    final presentationStep = _animationRunner?.currentHpTweenStep;
    final isHpTweenStep = presentationStep?.slot == targetSide;
    final xpStep = isPlayerSide && targetSide.slotIndex == 0
        ? _animationRunner?.currentXpTweenStep : null;
    final heldHp = _presentationHeldHp[targetSide];
    final koIsPresented = !isHpTweenStep && (heldHp == null || heldHp <= 0);
    final statusLabel = combatant.isFainted && koIsPresented
        ? 'K.O.'
        : combatant.majorStatus?.id.name.toUpperCase();
    return BattleCommandOverlayHudSnapshot(
      rect: rect,
      slot: targetSide,
      combatantId: displayedIdentity ?? combatantId,
      isRevealed: _teamInfoRevealed,
      isVisible:
          !(_animationRunner?.areGaugesHidden ?? false) &&
          !(_perspectiveCamera?.isMoving ?? false),
      remainingTeamCount: !isPlayerSide && _session.setup.isTrainerBattle
          ? _remainingEnemyTeamCount() : null,
      teamSize: !isPlayerSide && _session.setup.isTrainerBattle
          ? 1 + _session.setup.enemyReservePokemon.length : null,
      ownerLabel: ownerLabel,
      speciesLabel: resolveSpeciesDisplayName(combatant.speciesId),
      level: isPlayerSide && targetSide.slotIndex == 0
          ? _presentationPlayerLevel ?? combatant.level
          : combatant.level,
      currentHp: combatant.currentHp,
      maxHp: combatant.maxHp,
      displayedHp: isHpTweenStep
          ? presentationStep!.fromHp
          : (heldHp ?? combatant.currentHp),
      targetDisplayedHp: isHpTweenStep ? presentationStep!.toHp : null,
      hpTweenDurationMs: isHpTweenStep ? presentationStep!.durationMs : null,
      hpTweenRevision:
          isHpTweenStep ? _hpTweenRevisionFor(presentationStep!) : 0,
      isPlayerSide: isPlayerSide,
      genderSymbol: _resolveCombatantGenderSymbol(
        combatant: combatant,
        isPlayerSide: isPlayerSide,
      ),
      statusLabel: statusLabel?.trim().isEmpty ?? true ? null : statusLabel,
      experienceProgress: isPlayerSide
          ? (xpStep?.fromProgress ??
              (targetSide.slotIndex == 0 ? _presentationXpProgress : null) ??
              _playerExperienceProgressByLineupIndex[combatant.lineupIndex])
          : null,
      experienceProgressTarget: xpStep?.toProgress,
      xpTweenDurationMs: xpStep?.durationMs,
      xpTweenRevision: xpStep == null ? 0 : _xpTweenRevisionFor(xpStep),
    );
  }

  int _remainingEnemyTeamCount() {
    final hpByLineup = {
      for (final combatant in [_session.state.enemy, ..._session.state.enemyReserve])
        combatant.lineupIndex: combatant.currentHp,
    };
    for (final entry in _presentationHeldHp.entries) {
      if (entry.key.side != BattleSideId.enemy) continue;
      final displayed = _displayedCombatantsBySlot[entry.key] ??
          (entry.key.slotIndex == 0 ? _displayedEnemyCombatant : null);
      if (displayed != null) {
        final tween = _animationRunner?.currentHpTweenStep;
        hpByLineup[displayed.lineupIndex] = tween?.slot == entry.key
            ? tween!.fromHp : entry.value;
      }
    }
    return hpByLineup.values.where((hp) => hp > 0).length;
  }

  List<BattleCommandOverlayEntry> _buildCommandOverlayEntries({
    required BattleCommandMenuModel menuModel,
    required BattlePartyMenuModel partyMenuModel,
    required BattleBagMenuModel bagMenuModel,
    required BattleMedicineTargetMenuModel? medicineTargetMenuModel,
  }) {
    return switch (menuModel.mode) {
      BattleCommandMenuMode.bagMedicineMoveTarget =>
        _medicineMoveEntries(),
      BattleCommandMenuMode.root =>
        List<BattleCommandOverlayEntry>.unmodifiable(
          menuModel.rootEntries.asMap().entries.map(
                (entry) => BattleCommandOverlayEntry(
                  index: entry.key,
                  kind: BattleCommandOverlayEntryKind.root,
                  primaryLabel: entry.value.label,
                  secondaryLabel: entry.value.subtitle,
                  enabled: entry.value.enabled,
                  selected: entry.key == menuModel.selectedRootIndex,
                  tone: entry.value.enabled
                      ? BattleCommandOverlayEntryTone.neutral
                      : BattleCommandOverlayEntryTone.disabled,
                ),
              ),
        ),
      BattleCommandMenuMode.fight ||
      BattleCommandMenuMode.continueOnly =>
        List<BattleCommandOverlayEntry>.unmodifiable(
          menuModel.choiceEntries.asMap().entries.map((entry) {
            final choice = entry.value.choice;
            final move = choice is PlayerBattleChoiceFight
                ? _session.state.player.moves[choice.moveIndex]
                : null;
            return BattleCommandOverlayEntry(
              index: entry.key,
              kind: menuModel.mode == BattleCommandMenuMode.continueOnly
                  ? BattleCommandOverlayEntryKind.continueAction
                  : BattleCommandOverlayEntryKind.move,
              primaryLabel: entry.value.title,
              secondaryLabel: move?.type ?? entry.value.subtitle,
              tertiaryLabel: move == null ? null : entry.value.subtitle,
              trailingLabel:
                  move == null ? null : 'PP ${move.currentPp}/${move.pp}',
              enabled: true,
              selected: entry.key == menuModel.selectedChoiceIndex,
              tone: _overlayEntryToneForChoiceTone(entry.value.tone),
            );
          }),
        ),
      BattleCommandMenuMode.bag => List<BattleCommandOverlayEntry>.unmodifiable(
          bagMenuModel.entries.asMap().entries.map(
                (entry) => BattleCommandOverlayEntry(
                  index: entry.key,
                  kind: BattleCommandOverlayEntryKind.bag,
                  primaryLabel: entry.value.displayName,
                  secondaryLabel: _overlayBagEntryTypeLabel(entry.value),
                  tertiaryLabel: null,
                  trailingLabel: 'x${entry.value.quantity}',
                  statusLabel: _overlayBagEntryStatusLabel(entry.value),
                  enabled: entry.value.isSelectable,
                  selected: entry.key == _selectedBagIndex,
                  tone: _overlayEntryToneForBagEntry(entry.value),
                  iconAssetPath: _bagIconAssetPathByItemId[entry.value.itemId],
                ),
              ),
        ),
      BattleCommandMenuMode.pokemon =>
        List<BattleCommandOverlayEntry>.unmodifiable(
          partyMenuModel.allEntries.asMap().entries.map(
                (entry) => BattleCommandOverlayEntry(
                  index: entry.key,
                  kind: BattleCommandOverlayEntryKind.party,
                  primaryLabel:
                      resolveSpeciesDisplayName(entry.value.speciesId),
                  secondaryLabel:
                      '${entry.value.currentHp}/${entry.value.maxHp} PV',
                  trailingLabel: 'Nv. ${entry.value.level}',
                  statusLabel: _overlayPartyEntryStatusLabel(entry.value),
                  enabled: entry.value.isSelectable &&
                      entry.value.playerChoice != null,
                  selected: entry.key == _selectedPartyIndex,
                  tone: entry.value.isSelectable
                      ? BattleCommandOverlayEntryTone.switching
                      : BattleCommandOverlayEntryTone.disabled,
                ),
              ),
        ),
      BattleCommandMenuMode.bagMedicineTarget =>
        List<BattleCommandOverlayEntry>.unmodifiable(
          (medicineTargetMenuModel?.entries ??
                  const <BattleMedicineTargetEntry>[])
              .asMap()
              .entries
              .map(
                (entry) => BattleCommandOverlayEntry(
                  index: entry.key,
                  kind: BattleCommandOverlayEntryKind.medicineTarget,
                  primaryLabel:
                      resolveSpeciesDisplayName(entry.value.speciesId),
                  secondaryLabel:
                      '${entry.value.currentHp}/${entry.value.maxHp} PV',
                  trailingLabel: 'Nv. ${entry.value.level}',
                  statusLabel: _overlayMedicineTargetStatusLabel(entry.value),
                  enabled: entry.value.isSelectable,
                  selected: entry.key == _selectedMedicineTargetIndex,
                  tone: entry.value.isSelectable
                      ? BattleCommandOverlayEntryTone.medicine
                      : BattleCommandOverlayEntryTone.disabled,
                ),
              ),
        ),
    };
  }

  bool _canGoBackFrom(
    BattleCommandMenuModel menuModel,
    BattlePartyMenuModel partyMenuModel,
  ) {
    if (menuModel.isContinueOnly || menuModel.isRootMode) {
      return false;
    }
    if (menuModel.mode == BattleCommandMenuMode.pokemon &&
        partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement) {
      return false;
    }
    return true;
  }

  void _primeBagIconAssetPaths(BattleBagMenuModel bagMenuModel) {
    final resolver = bagItemIconResolver;
    if (resolver == null || bagMenuModel.entries.isEmpty) {
      return;
    }
    final uniqueItemIds = bagMenuModel.entries
        .map((entry) => entry.itemId.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toSet();
    for (final itemId in uniqueItemIds) {
      _ensureBagIconAssetPathResolved(itemId, resolver);
    }
  }

  void _ensureBagIconAssetPathResolved(
    String itemId,
    BattleBagItemIconResolver resolver,
  ) {
    if (_bagIconAssetPathByItemId.containsKey(itemId) ||
        _pendingBagIconPathsByItemId.containsKey(itemId)) {
      return;
    }

    Future<void> load() async {
      try {
        final spec = await resolver.resolve(itemId);
        final imagePath = spec.explicitImageAbsolutePath?.trim();
        _bagIconAssetPathByItemId[itemId] =
            imagePath == null || imagePath.isEmpty ? null : imagePath;
      } catch (_) {
        _bagIconAssetPathByItemId[itemId] = null;
      } finally {
        _pendingBagIconPathsByItemId.remove(itemId);
      }
      _syncPanelsOnly();
    }

    final future = load();
    _pendingBagIconPathsByItemId[itemId] = future;
  }

  bool _moveSelection({
    required int horizontalDelta,
    required int verticalDelta,
  }) {
    if (_pendingTargetChoice != null && !isTurnPresentationActive) {
      final targets = _pendingMoveTargets;
      if (targets.isEmpty) return false;
      final next = (_selectedTargetIndex + (verticalDelta != 0 ? verticalDelta : horizontalDelta))
          .clamp(0, targets.length - 1);
      if (next == _selectedTargetIndex) return false;
      _selectedTargetIndex = next;
      _syncPanelsOnly();
      return true;
    }
    if (_postBattleDecision != null) {
      return _movePostBattleDecisionSelection(
        verticalDelta != 0 ? verticalDelta : horizontalDelta,
      );
    }
    if (!_acceptsPlayerCommands) return false;
    if (isTurnPresentationActive) {
      return false;
    }
    final controllerColumns = _controllerLayout &&
        _commandPanelPlacement != BattleCommandPanelPlacement.detached &&
        !currentSceneLayout.isPortrait ? 1 : 2;
    final menuModel = _currentMenuModel();
    if (menuModel.mode == BattleCommandMenuMode.bagMedicineMoveTarget) {
      final entries = _medicineMoveEntries();
      if (entries.isEmpty) return false;
      final next = moveBattleCommandGridSelection(
        currentIndex: _selectedMedicineMoveIndex,
        itemCount: entries.length,
        columnCount: controllerColumns,
        horizontalDelta: horizontalDelta,
        verticalDelta: verticalDelta,
      );
      if (next == _selectedMedicineMoveIndex) return false;
      _selectedMedicineMoveIndex = next;
      _syncPanelsOnly();
      return true;
    }
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    if (menuModel.isContinueOnly) {
      return false;
    }
    if (menuModel.isRootMode) {
      final visualOrder = _rootCommandOrder.where((index) => index < menuModel.rootEntries.length).toList();
      final currentPosition = visualOrder.indexOf(menuModel.selectedRootIndex);
      final nextPosition = moveBattleCommandGridSelection(
        currentIndex: currentPosition < 0 ? 0 : currentPosition,
        itemCount: visualOrder.length,
        columnCount: controllerColumns,
        horizontalDelta: horizontalDelta,
        verticalDelta: verticalDelta,
      );
      final nextIndex = visualOrder[nextPosition];
      if (nextIndex == _selectedRootIndex) {
        return false;
      }
      _selectedRootIndex = nextIndex;
      _syncPanelsOnly();
      return true;
    }

    if (menuModel.mode == BattleCommandMenuMode.pokemon &&
        partyMenuModel.allEntries.isNotEmpty) {
      final nextIndex = moveBattleCommandGridSelection(
        currentIndex: _selectedPartyIndex,
        itemCount: partyMenuModel.allEntries.length,
        columnCount: _collectionColumns ?? 1,
        horizontalDelta: horizontalDelta,
        verticalDelta: verticalDelta,
      );
      if (nextIndex == _selectedPartyIndex) {
        return false;
      }
      _selectedPartyIndex = nextIndex;
      _syncPanelsOnly();
      return true;
    }

    if (menuModel.mode == BattleCommandMenuMode.bag &&
        bagMenuModel.entries.isNotEmpty) {
      final nextIndex = moveBattleCommandGridSelection(
        currentIndex: _selectedBagIndex,
        itemCount: bagMenuModel.entries.length,
        columnCount: _collectionColumns ?? 1,
        horizontalDelta: horizontalDelta,
        verticalDelta: verticalDelta,
      );
      if (nextIndex == _selectedBagIndex) {
        return false;
      }
      _selectedBagIndex = nextIndex;
      _bagFeedbackMessage = null;
      _syncPanelsOnly();
      return true;
    }

    if (menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
        medicineTargetMenuModel != null &&
        medicineTargetMenuModel.entries.isNotEmpty) {
      final nextIndex = moveBattleCommandGridSelection(
        currentIndex: _selectedMedicineTargetIndex,
        itemCount: medicineTargetMenuModel.entries.length,
        columnCount: _collectionColumns ?? 1,
        horizontalDelta: horizontalDelta,
        verticalDelta: verticalDelta,
      );
      if (nextIndex == _selectedMedicineTargetIndex) {
        return false;
      }
      _selectedMedicineTargetIndex = nextIndex;
      _bagFeedbackMessage = null;
      _syncPanelsOnly();
      return true;
    }

    final nextIndex = moveBattleCommandGridSelection(
      currentIndex: menuModel.selectedChoiceIndex,
      itemCount: menuModel.choiceEntries.length,
      columnCount: _controllerLayout ? controllerColumns : menuModel.choiceColumns,
      horizontalDelta: horizontalDelta,
      verticalDelta: verticalDelta,
    );
    if (nextIndex == _selectedChoiceIndex) {
      return false;
    }
    _selectedChoiceIndex = nextIndex;
    _syncPanelsOnly();
    return true;
  }

  void _handleChoiceSelected(PlayerBattleChoice choice) {
    if (_isDoubles && onPlayerDecision != null) {
      final request = _battlePresentation!.request;
      if (choice case PlayerBattleChoiceFight(:final moveIndex)) {
        final option = request.fightChoices
            .where((option) => option.moveSlot == moveIndex)
            .firstOrNull;
        final chooseTarget = option != null && (switch (option.target) {
          PsdkBattleMoveTarget.adjacentFoe ||
          PsdkBattleMoveTarget.anyFoe ||
          PsdkBattleMoveTarget.adjacentAlly ||
          PsdkBattleMoveTarget.adjacentAllyOrSelf => true,
          _ => false,
        });
        if (chooseTarget && option.legalTargets.length > 1) {
          _pendingTargetChoice = PlayerBattleChoiceFight(moveIndex);
          _pendingTargetRequest = request;
          _selectedTargetIndex = 0;
          _syncPanelsOnly();
          return;
        }
        final decision = option == null && request.canStruggle
            ? const BattleDecision.struggle()
            : BattleDecision.fight(
                moveSlot: moveIndex,
                target: chooseTarget && option.legalTargets.length == 1
                    ? option.legalTargets.single : null,
              );
        onPlayerDecision!(decision, request);
        return;
      }
      if (choice case PlayerBattleChoiceSwitch(:final reserveIndex)) {
        if (reserveIndex < 0 || reserveIndex >= request.switchChoices.length) return;
        onPlayerDecision!(BattleDecision.switchPokemon(
          partyIndex: request.switchChoices[reserveIndex].partyIndex,
        ), request);
        return;
      }
      return;
    }
    onPlayerChoice(choice);
  }

  List<PsdkBattleSlotRef> get _pendingMoveTargets {
    final request = _pendingTargetRequest;
    final choice = _pendingTargetChoice;
    if (request == null || choice == null ||
        !identical(request, _battlePresentation?.request)) {
      return const [];
    }
    return request.fightChoices
        .where((option) => option.moveSlot == choice.moveIndex)
        .firstOrNull?.legalTargets ?? const [];
  }

  bool selectMoveTargetEntry(int index) {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) return false;
    final targets = _pendingMoveTargets;
    final choice = _pendingTargetChoice;
    final request = _pendingTargetRequest;
    if (choice == null || request == null || index < 0 || index >= targets.length) return false;
    final decision = BattleDecision.fight(moveSlot: choice.moveIndex, target: targets[index]);
    if (!request.allows(decision)) return false;
    _pendingTargetChoice = null;
    _pendingTargetRequest = null;
    onPlayerDecision?.call(decision, request);
    return true;
  }

  void _handlePartyEntrySelected(BattlePartyMenuEntry entry) {
    final choice = entry.playerChoice;
    if (choice == null) {
      return;
    }
    _handleChoiceSelected(choice);
  }

  bool _handleMedicineTargetEntrySelected(BattleMedicineTargetEntry entry) {
    if (!entry.isSelectable) {
      return false;
    }
    final selectedMedicineAction = _selectedMedicineAction;
    if (selectedMedicineAction == null) {
      return false;
    }

    final effect = _itemCapabilityResolver.resolveUse(
      itemId: selectedMedicineAction.itemId,
      context: ProjectItemUseContext.battle,
    ).use?.effect;
    if (effect is ProjectItemRestorePpEffectDefinition) {
      _menuMode = BattleCommandMenuMode.bagMedicineMoveTarget;
      final entries = _medicineMoveEntries();
      _selectedMedicineMoveIndex = entries.indexWhere((entry) => entry.enabled);
      if (_selectedMedicineMoveIndex < 0) _selectedMedicineMoveIndex = 0;
      _syncPanelsOnly();
      return true;
    }

    // Lots 9-e à 9-h gardent l'overlay strictement borné au shell de
    // ciblage :
    // - le parent runtime commit le vrai tour pour `Potion`, `Super Potion`
    //   `Hyper Potion` et `Max Potion` ;
    // - l'overlay ne patche plus sa session localement ;
    // - cela évite de mentir sur l'ordre du tour et garde `PlayableMapGame`
    //   propriétaire unique du vrai BattleSession / GameState.
    return onBagHpHealItemUseRequested?.call(selectedMedicineAction, entry, request: _selectedMedicineRequest) ??
        false;
  }

  void _handleBagEntrySelected(BattleBagMenuEntry entry) {
    if (!entry.isSelectable) {
      return;
    }
    final action = entry.action;
    if (action case BattleBagMenuActionCapture(:final playerChoice)) {
      _bagFeedbackMessage = null;
      onPlayerChoice(playerChoice);
      return;
    }
    if (action case BattleBagMenuActionMedicineTarget()) {
      // Le shell medicine reste borné à la lineup battle courante :
      // - aucun accès direct à la party complète du save ;
      // - aucune consommation ni soin ici ;
      // - seulement la préparation du ciblage pour le seam runtime réel.
      _selectedMedicineAction = action;
      _selectedMedicineRequest = _isDoubles ? _battlePresentation!.request : null;
      _selectedMedicineTargetIndex = _firstSelectableMedicineTargetIndex();
      _bagFeedbackMessage = null;
      _menuMode = BattleCommandMenuMode.bagMedicineTarget;
      _syncPanelsOnly();
    }
  }

  void _handleRootActionSelected(BattleCommandRootAction action) {
    _bagFeedbackMessage = null;
    switch (action) {
      case BattleCommandRootAction.fight:
        _menuMode = BattleCommandMenuMode.fight;
        _selectedChoiceIndex = 0;
        _syncPanelsOnly();
        return;
      case BattleCommandRootAction.bag:
        _selectedMedicineAction = null;
    _selectedMedicineRequest = null;
        _selectedMedicineTargetIndex = 0;
        _menuMode = BattleCommandMenuMode.bag;
        _selectedBagIndex = _firstSelectableBagIndex();
        _syncPanelsOnly();
        return;
      case BattleCommandRootAction.pokemon:
        _menuMode = BattleCommandMenuMode.pokemon;
        _selectedPartyIndex = _firstSelectablePartyIndex();
        _syncPanelsOnly();
        return;
      case BattleCommandRootAction.run:
        for (final choice in _session.decisionRequest.allowedChoices) {
          if (choice is PlayerBattleChoiceRun) {
            onPlayerChoice(choice);
            break;
          }
        }
        return;
    }
  }

  BattleCommandMenuModel _currentMenuModel() {
    return buildBattleCommandMenuModel(
      session: _session,
      mode: _effectiveMenuMode(),
      selectedRootIndex: _selectedRootIndex,
      selectedChoiceIndex: _selectedChoiceIndex,
      resolveMoveDisplayName: resolveMoveDisplayName,
      engineRequest: _isDoubles ? _battlePresentation!.request : null,
    );
  }

  BattlePartyMenuModel _currentPartyMenuModel() {
    return buildBattlePartyMenuModel(
      session: _session,
      engineRequest: _isDoubles ? _battlePresentation!.request : null,
      playerParty: _isDoubles ? _battlePresentation!.playerParty : null,
      activeLineupIndexes: _battlePresentation?.activeCombatants
          .where((entry) => entry.slot.side == BattleSideId.player)
          .map((entry) => entry.lineupIndex) ?? const [],
    );
  }

  BattleBagMenuModel _currentBagMenuModel() {
    return buildBattleBagMenuModel(
      gameState: _gameState,
      session: _session,
      resolver: _itemCapabilityResolver,
    );
  }

  BattleMedicineTargetMenuModel? _currentMedicineTargetMenuModel() {
    final selectedMedicineAction = _selectedMedicineAction;
    if (selectedMedicineAction == null) {
      return null;
    }
    final capability = _itemCapabilityResolver.resolveUse(
      itemId: selectedMedicineAction.itemId,
      context: ProjectItemUseContext.battle,
    );
    if (!capability.isAvailable) {
      return null;
    }
    // Le ciblage medicine reste borné à la vérité battle courante :
    // - lineup du combat, pas party complète du GameState ;
    // - aucune heuristique par index visuel ;
    // - aucun effet item calculé ici, seulement le menu de cibles.
    return buildBattleMedicineTargetMenuModel(
      session: _session,
      itemId: selectedMedicineAction.itemId,
      displayName: selectedMedicineAction.displayName,
      use: capability.use!,
      battleState: medicineBattleState?.call(),
      isConfusedByLineupIndex: medicineTargetIsConfused,
      isTargetAllowed: (combatant) =>
          _allowMedicineReserveTargets ||
          combatant.lineupIndex == _session.state.player.lineupIndex,
    );
  }

  BattleCommandMenuMode _effectiveMenuMode() {
    final partyMenuModel = _currentPartyMenuModel();
    if (partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement &&
        partyMenuModel.hasSelectableEntries &&
        // BETA-BAT-033 : le moteur résout le tour ENTIER à la soumission, donc
        // il sait que l'actif tombe avant que le premier coup ne soit joué.
        // Sans cette garde, choisir une attaque ouvrait immédiatement la liste
        // de l'équipe : le KO était annoncé avant d'avoir eu lieu. Même
        // horloge que le bandeau d'issue de BETA-BAT-012.
        !_presentationPendingOrRunning) {
      return BattleCommandMenuMode.pokemon;
    }
    if ((_menuMode == BattleCommandMenuMode.bagMedicineTarget ||
            _menuMode == BattleCommandMenuMode.bagMedicineMoveTarget) &&
        _selectedMedicineAction == null) {
      return BattleCommandMenuMode.bag;
    }
    return _menuMode;
  }

  void _normalizeMenuSelection() {
    final previousMenuMode = _menuMode;
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    _menuMode = menuModel.mode;
    _selectedRootIndex = _firstEnabledRootIndex(
      rootEntries: menuModel.rootEntries,
      requestedIndex: menuModel.selectedRootIndex,
    );
    _selectedChoiceIndex = menuModel.selectedChoiceIndex;
    _selectedPartyIndex = _normalizeSelectedPartyIndex(
      partyMenuModel: partyMenuModel,
      previousMenuMode: previousMenuMode,
      nextMenuMode: menuModel.mode,
    );
    _selectedBagIndex = _normalizeSelectedBagIndex(
      bagMenuModel: bagMenuModel,
      previousMenuMode: previousMenuMode,
      nextMenuMode: menuModel.mode,
    );
    _selectedMedicineTargetIndex = _normalizeSelectedMedicineTargetIndex(
      medicineTargetMenuModel: medicineTargetMenuModel,
      previousMenuMode: previousMenuMode,
      nextMenuMode: menuModel.mode,
    );
    if (_menuMode != BattleCommandMenuMode.bagMedicineTarget &&
        _menuMode != BattleCommandMenuMode.bagMedicineMoveTarget) {
      _selectedMedicineAction = null;
    _selectedMedicineRequest = null;
    }
  }

  void _syncMenuStateFromModel() {
    final previousMenuMode = _menuMode;
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    _menuMode = menuModel.mode;
    _selectedRootIndex = menuModel.selectedRootIndex;
    _selectedChoiceIndex = menuModel.selectedChoiceIndex;
    _selectedPartyIndex = _normalizeSelectedPartyIndex(
      partyMenuModel: partyMenuModel,
      previousMenuMode: previousMenuMode,
      nextMenuMode: menuModel.mode,
    );
    _selectedBagIndex = _normalizeSelectedBagIndex(
      bagMenuModel: bagMenuModel,
      previousMenuMode: previousMenuMode,
      nextMenuMode: menuModel.mode,
    );
    _selectedMedicineTargetIndex = _normalizeSelectedMedicineTargetIndex(
      medicineTargetMenuModel: medicineTargetMenuModel,
      previousMenuMode: previousMenuMode,
      nextMenuMode: menuModel.mode,
    );
    if (_menuMode != BattleCommandMenuMode.bagMedicineTarget &&
        _menuMode != BattleCommandMenuMode.bagMedicineMoveTarget) {
      _selectedMedicineAction = null;
    _selectedMedicineRequest = null;
    }
  }

  int _firstEnabledRootIndex({
    required List<BattleCommandRootEntry> rootEntries,
    required int requestedIndex,
  }) {
    if (rootEntries.isEmpty) {
      return 0;
    }
    final safeIndex = requestedIndex.clamp(0, rootEntries.length - 1);
    if (rootEntries[safeIndex].enabled) {
      return safeIndex;
    }
    for (var index = 0; index < rootEntries.length; index++) {
      if (rootEntries[index].enabled) {
        return index;
      }
    }
    return safeIndex;
  }

  int _firstSelectablePartyIndex() {
    return _firstSelectablePartyIndexFor(_currentPartyMenuModel());
  }

  int _firstSelectableBagIndex() {
    return _firstSelectableBagIndexFor(_currentBagMenuModel());
  }

  int _firstSelectableMedicineTargetIndex() {
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    if (medicineTargetMenuModel == null) {
      return 0;
    }
    // Le curseur commence sur la première cible réellement soignable :
    // - aucun soin n'est appliqué ici ;
    // - on évite juste un aller-retour UX inutile avant validation.
    return _firstSelectableMedicineTargetIndexFor(medicineTargetMenuModel);
  }

  int _firstSelectablePartyIndexFor(BattlePartyMenuModel partyMenuModel) {
    for (var index = 0; index < partyMenuModel.allEntries.length; index++) {
      if (partyMenuModel.allEntries[index].isSelectable) {
        return index;
      }
    }
    return 0;
  }

  int _firstSelectableBagIndexFor(BattleBagMenuModel bagMenuModel) {
    for (var index = 0; index < bagMenuModel.entries.length; index++) {
      if (bagMenuModel.entries[index].isSelectable) {
        return index;
      }
    }
    return 0;
  }

  int _firstSelectableMedicineTargetIndexFor(
    BattleMedicineTargetMenuModel medicineTargetMenuModel,
  ) {
    for (var index = 0;
        index < medicineTargetMenuModel.entries.length;
        index++) {
      if (medicineTargetMenuModel.entries[index].isSelectable) {
        return index;
      }
    }
    return 0;
  }

  int _normalizeSelectedPartyIndex({
    required BattlePartyMenuModel partyMenuModel,
    required BattleCommandMenuMode previousMenuMode,
    required BattleCommandMenuMode nextMenuMode,
  }) {
    if (partyMenuModel.allEntries.isEmpty) {
      return 0;
    }
    final safeIndex = _selectedPartyIndex.clamp(
      0,
      partyMenuModel.allEntries.length - 1,
    );
    final isEnteringForcedReplacement =
        previousMenuMode != BattleCommandMenuMode.pokemon &&
            nextMenuMode == BattleCommandMenuMode.pokemon &&
            partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement;
    if (isEnteringForcedReplacement) {
      return _firstSelectablePartyIndexFor(partyMenuModel);
    }
    return safeIndex;
  }

  int _normalizeSelectedBagIndex({
    required BattleBagMenuModel bagMenuModel,
    required BattleCommandMenuMode previousMenuMode,
    required BattleCommandMenuMode nextMenuMode,
  }) {
    if (bagMenuModel.entries.isEmpty) {
      return 0;
    }
    final safeIndex = _selectedBagIndex.clamp(
      0,
      bagMenuModel.entries.length - 1,
    );
    if (nextMenuMode != BattleCommandMenuMode.bag) {
      return safeIndex;
    }
    if (previousMenuMode != BattleCommandMenuMode.bag) {
      return _firstSelectableBagIndexFor(bagMenuModel);
    }
    return safeIndex;
  }

  int _normalizeSelectedMedicineTargetIndex({
    required BattleMedicineTargetMenuModel? medicineTargetMenuModel,
    required BattleCommandMenuMode previousMenuMode,
    required BattleCommandMenuMode nextMenuMode,
  }) {
    if (medicineTargetMenuModel == null ||
        medicineTargetMenuModel.entries.isEmpty) {
      return 0;
    }
    final safeIndex = _selectedMedicineTargetIndex.clamp(
      0,
      medicineTargetMenuModel.entries.length - 1,
    );
    if (nextMenuMode != BattleCommandMenuMode.bagMedicineTarget) {
      return safeIndex;
    }
    if (previousMenuMode != BattleCommandMenuMode.bagMedicineTarget &&
        previousMenuMode != BattleCommandMenuMode.bagMedicineMoveTarget) {
      return _firstSelectableMedicineTargetIndexFor(medicineTargetMenuModel);
    }
    return safeIndex;
  }

  void _notifyOutcomePresented() {
    final outcome = _session.state.outcome;
    // BETA-BAT-012 : deux horloges. L'issue est décidée dès que le tour est
    // CALCULÉ, bien avant d'être JOUÉ, et ce bandeau ne regardait que la
    // première — il s'affichait donc par-dessus l'attaque qui provoquait la
    // victoire. Il attend maintenant que le plan d'animation soit vidé.
    //
    // La référence obtient la même chose par trois barrières structurelles :
    // aucune phase n'est dispatchée pendant qu'un message est à l'écran,
    // `wait_for_animation` bloque la pile, et l'animation d'une capacité est
    // drainée deux fois avant que sa procédure ne rende la main.
    final outcomePresented = _session.state.isFinished &&
        outcome != null &&
        !_presentationPendingOrRunning;
    if (outcomePresented && !_outcomePresentedNotified) {
      _outcomePresentedNotified = true;
      onOutcomePresented?.call(outcome);
    }
  }

  String _titleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat dresseur';
    }
    return 'Combat sauvage';
  }

  Future<void> _prepareAnimationPresentation({
    required BattleSession previousSession,
    required BattleAnimationPlan animationPlan,
    required int presentationGeneration,
  }) async {
    var transferred = false;
    try {
      await _syncVisualState(
        previousSession: previousSession,
        preserveDisplayedCombatantSlots: _presentationLockedCombatantSlots,
        presentationGeneration: presentationGeneration,
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
      if (animationPlan.isEmpty) {
        _presentationLockedCombatantSlots = <BattleSlotRef>{};
        _syncPanelsOnly();
        return;
      }
      final requiredFxIds = animationPlan.requiredFxIds;
      final fxScope = _fxImageScope;
      if (fxScope != null && requiredFxIds.isNotEmpty) {
        _fxBundleCache.updateScope(fxScope,
          effectIds: requiredFxIds, liveImages: _fxLayer?.liveImages ?? const []);
      }
      try {
        await _fxBundleCache.prewarm(requiredFxIds);
      } on RuntimeResourceAdmissionException catch (error) {
        if (error.reason != 'resident_bytes' || !_releaseUnusedStatSheets()) {
          rethrow;
        }
        await _fxBundleCache.prewarm(requiredFxIds);
      }
      final ballItemIds = <String>{
        for (final step in animationPlan.flattenedSteps)
          if (step is PlayBallCaptureSequenceStep && step.ballItemId != null)
            step.ballItemId!,
        for (final step in animationPlan.flattenedSteps)
          if (step is PlayBallSequenceStep && step.ballItemId != null)
            step.ballItemId!,
      };
      await Future.wait(ballItemIds.map(_loadBallSheet));
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
      _resetSceneClock();
      final runner = _animationRunner;
      if (runner == null) return;
      runner.start(animationPlan);
      transferred = true;
    } on RuntimeResourceAdmissionException catch (error) {
      if (error.reason != 'cancelled_or_closed' ||
          _isCurrentPresentationGeneration(presentationGeneration)) {
        rethrow;
      }
    } finally {
      if (identical(_pendingTurnAudioPlan, animationPlan)) {
        if (transferred) {
          _pendingTurnAudioPlan = null;
        } else {
          _discardPendingTurnAudio(animationPlan);
        }
      }
    }
  }

  Set<BattleSlotRef> _lockedCombatantSlotsFor(BattleAnimationPlan plan) {
    // `flattenedSteps`, jamais `steps` : le contrat du plan prévient qu'un
    // scan de surface « renverrait silencieusement rien » pour une étape
    // imbriquée dans un groupe. Ici le prix d'un tel silence est un sprite
    // qui bascule avant que le K.O. ait été joué — le défaut exact de la
    // recette du 2026-08-25.
    return plan.flattenedSteps
        .whereType<SwapCombatantVisualStep>()
        .map((step) => step.slot)
        .toSet();
  }

  void _handleAnimationPresentationChanged() {
    _syncPanelsOnly();
    final animationRunner = _animationRunner;
    if (animationRunner == null || animationRunner.isActive) {
      return;
    }
    _resetBattleCamera();
    _presentationLockedCombatantSlots = <BattleSlotRef>{};
    _presentationHeldHp.clear();
    _installActiveAnimationPlan(
        const BattleAnimationPlan(steps: <BattleAnimationStep>[]));
    final presentationGeneration = _presentationGeneration;
    _trackVisualSync(_syncVisualState(
      presentationGeneration: presentationGeneration,
    ));
    unawaited(_pendingVisualSync);
  }

  BattleFxRuntimeContext _battleFxRuntimeContext({Vector2? sceneSize, bool ignoreRmxpTransform = false}) {
    final generation = _presentationGeneration;
    final identities = {
      for (final slot in [const BattleSlotRef.active(BattleSideId.player),
        const BattleSlotRef.active(BattleSideId.enemy), ..._additionalCombatants.keys])
        slot: _effectSubjectAt(slot),
    };
    return BattleFxRuntimeContext(
      sceneSize: sceneSize ?? size.clone(),
      stageRect: currentSceneLayout.stageRect,
      isCurrent: () => _isCurrentPresentationGeneration(generation),
      resolveSceneSize: () => sceneSize == null ? size : _rmxpAnimationViewportSize(),
      resolveStageRect: () => currentSceneLayout.stageRect,
      bindSlotAnchor: ({required anchor, required attackerSlot, required defenderSlot}) {
        final subject = switch (anchor) {
          BattleVisualAnchor.attackerCenter || BattleVisualAnchor.attackerBody ||
          BattleVisualAnchor.attackerHead || BattleVisualAnchor.attackerMouth ||
          BattleVisualAnchor.attackerHand || BattleVisualAnchor.attackerFoot => attackerSlot,
          BattleVisualAnchor.defenderCenter || BattleVisualAnchor.defenderBody ||
          BattleVisualAnchor.defenderHead || BattleVisualAnchor.defenderMouth ||
          BattleVisualAnchor.defenderHand || BattleVisualAnchor.defenderImpact ||
          BattleVisualAnchor.defenderFoot => defenderSlot,
          _ => null,
        };
        return () {
          if (subject != null && (identities[subject] == null ||
              _effectSubjectAt(subject) != identities[subject])) {
            return null;
          }
          return _resolveBattleVisualAnchor(anchor: anchor,
            ignoreRmxpTransform: ignoreRmxpTransform,
            attackerSide: attackerSlot.side, attackerSlotIndex: attackerSlot.slotIndex,
            defenderSide: defenderSlot.side, defenderSlotIndex: defenderSlot.slotIndex);
        };
      },
      resolveAnchor: _resolveBattleVisualAnchor,
      resolveSlotAnchor: ({required anchor, required attackerSlot, required defenderSlot}) => _resolveBattleVisualAnchor(
        anchor: anchor,
        attackerSide: attackerSlot.side,
        defenderSide: defenderSlot.side,
        attackerSlotIndex: attackerSlot.slotIndex,
        defenderSlotIndex: defenderSlot.slotIndex,
      ),
    );
  }

  ({BattleSceneCombatantComponent actor, int lineupIndex, String? combatantId})?
  _effectSubjectAt(BattleSlotRef slot) {
    final actor = _combatantForSlot(slot);
    if (actor == null || _geometryFor(slot).spriteRect.isEmpty) return null;
    final displayed = _displayedCombatantsBySlot[slot] ??
        (slot.side == BattleSideId.player ? _displayedPlayerCombatant : _displayedEnemyCombatant);
    if (displayed == null) return null;
    final current = _battlePresentation?.combatantAt(slot);
    final previous = _previousBattlePresentation?.combatantAt(slot);
    final projection = current?.lineupIndex == displayed.lineupIndex ? current :
        previous?.lineupIndex == displayed.lineupIndex ? previous : null;
    if (_battlePresentation != null && projection == null) return null;
    return (actor: actor, lineupIndex: displayed.lineupIndex,
      combatantId: projection?.combatantId);
  }

  void _handleSpawnFxStep(SpawnFxStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playFx(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleScreenFlashStep(ScreenFlashStep step) {
    if (_reducedBattleEffects) return;
    _fxLayer?.playScreenFlash(step);
  }

  void _handleSpriteSheetFxStep(PlaySpriteSheetFxStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSpriteSheetFx(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleSpriteSheetOnCombatantStep(SpriteSheetOnCombatantStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSpriteSheetOnCombatant(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleParticleBurstStep(ParticleBurstStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playParticleBurst(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleSdkParticleSequenceStep(PlaySdkParticleSequenceStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSdkParticleSequence(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleSdkFallingParticlesStep(SdkFallingParticlesStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSdkFallingParticles(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleSdkRadiusParticlesStep(SdkRadiusParticleStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSdkRadiusParticles(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleSdkScalarParticleStep(SdkScalarParticleStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSdkScalarParticle(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleSdkParticleZoomStep(SdkParticleZoomStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playSdkParticleZoom(
        step,
        _battleFxRuntimeContext(),
      ),
    );
  }

  void _handleWeatherParticleStep(WeatherParticleStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(fxLayer.playWeatherParticles(step));
  }

  void _handleRmxpAnimationStep(PlayRmxpAnimationStep step) {
    final fxLayer = _fxLayer;
    final combatant = _combatantForSlot(step.subjectSlot);
    final generation = _presentationGeneration;
    final subjectIdentity = _effectSubjectAt(step.subjectSlot);
    final transformOwner = Object();
    bool currentSubject() => _isCurrentPresentationGeneration(generation) &&
        subjectIdentity != null && _effectSubjectAt(step.subjectSlot) == subjectIdentity;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playRmxpAnimation(
        step,
        _battleFxRuntimeContext(sceneSize: _rmxpAnimationViewportSize(), ignoreRmxpTransform: true),
        onCombatantTransform: combatant == null
            ? null
            : (transform) {
                if (!currentSubject()) return;
                combatant.applyRmxpTransform(
                  owner: transformOwner,
                  offset: _reducedBattleEffects ? Offset.zero : transform.offset,
                  scale: _reducedBattleEffects ? 1 : transform.scale,
                );
              },
        onCombatantTransformCleared: () {
          combatant?.clearRmxpTransform(owner: transformOwner);
        },
        onSeTiming: (timing) {
          final seName = timing.seName;
          if (seName != null) {
            playSfx?.call(
              seName,
              volume: timing.seVolume,
              pitch: timing.sePitch,
            );
          }
        },
        onPokemonFlash: (timing) {
          if (!currentSubject()) return;
          if (_reducedBattleEffects || _motionPolicy.effectIntensity == 0) return;
          combatant?.triggerHitFlash(
            intensity: _motionPolicy.effectIntensity,
            duration:
                (timing.flashDuration * 2 / 60).clamp(0.05, 0.8).toDouble(),
          );
        },
        onSceneFlash: (timing) {
          if (_reducedBattleEffects) return;
          fxLayer.playScreenFlash(
            ScreenFlashStep(
              colorArgb: Color.fromARGB(
                timing.flashAlpha.clamp(0, 255).toInt(),
                timing.flashRed.clamp(0, 255).toInt(),
                timing.flashGreen.clamp(0, 255).toInt(),
                timing.flashBlue.clamp(0, 255).toInt(),
              ).toARGB32(),
              durationSeconds:
                  (timing.flashDuration * 2 / 60).clamp(0.05, 0.8).toDouble(),
            ),
          );
        },
        onVisibilityChanged: (hidden) {
          if (!hidden || currentSubject()) combatant?.setRmxpHidden(hidden, owner: transformOwner);
        },
      ),
    );
  }

  Vector2 _rmxpAnimationViewportSize() {
    final layout = currentSceneLayout;
    final sidePanel = layout.commandPanelPlacement == BattleCommandPanelPlacement.end;
    final detached = layout.commandPanelPlacement == BattleCommandPanelPlacement.detached;
    final battleViewportHeight = (sidePanel || detached ? layout.arenaRect.bottom : layout.commandPanelRect.top).clamp(0.0, size.y).toDouble();
    return Vector2(sidePanel ? layout.arenaRect.right : size.x, battleViewportHeight);
  }

  void _handleSceneTintStep(SceneTintStep step) {
    _fxLayer?.playSceneTint(step);
  }

  void _handleCombatantMotionStep(CombatantMotionStep step) {
    final combatant = _combatantForSlot(step.slot);
    if (combatant == null) {
      return;
    }
    switch (step.motionKind) {
      case BattleCombatantMotionKind.lunge:
        unawaited(
          combatant.playLunge(
            towardOpponent: true,
            distancePx: _reducedBattleEffects ? 0 : step.distancePx,
            durationSeconds: step.durationSeconds,
          ),
        );
      case BattleCombatantMotionKind.fastDash:
        unawaited(
          combatant.playFastDash(
            towardOpponent: true,
            distancePx: _reducedBattleEffects ? 0 : step.distancePx,
            durationSeconds: step.durationSeconds,
          ),
        );
      case BattleCombatantMotionKind.switchOut:
        unawaited(
          combatant.playSwitchOut(durationSeconds: step.durationSeconds),
        );
      case BattleCombatantMotionKind.switchIn:
        unawaited(
          combatant.playSwitchIn(durationSeconds: step.durationSeconds),
        );
      case BattleCombatantMotionKind.introSlide:
        unawaited(
          combatant.playIntroSlide(
            durationSeconds: step.durationSeconds,
            distancePx: _reducedBattleEffects ? 0 : step.distancePx,
          ),
        );
      case BattleCombatantMotionKind.materializeIn:
        unawaited(
          combatant.playMaterializeIn(durationSeconds: step.durationSeconds),
        );
      case BattleCombatantMotionKind.materializeOut:
        unawaited(
          combatant.playMaterializeOut(durationSeconds: step.durationSeconds),
        );
    }
  }

  void _handleCombatantFlashStep(CombatantFlashStep step) {
    if (_reducedBattleEffects || _motionPolicy.effectIntensity == 0) return;
    _combatantForSlot(step.slot)
        ?.triggerHitFlash(duration: step.durationSeconds,
          intensity: _motionPolicy.effectIntensity);
  }

  void _handleCombatantShakeStep(CombatantShakeStep step) {
    final combatant = _combatantForSlot(step.slot);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playShake(
        amplitudePx: _reducedBattleEffects ? 0 : step.amplitudePx,
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void _handleCombatantToneStep(CombatantToneStep step) {
    final combatant = _combatantForSlot(step.slot);
    if (combatant == null) {
      return;
    }
    combatant.setEffectIntensity(_motionPolicy.effectIntensity);
    unawaited(
      combatant.playTone(
        color: Color(step.colorArgb),
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void _handleCombatantCompressStep(CombatantCompressStep step) {
    final combatant = _combatantForSlot(step.slot);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playCompress(
        scaleX: _reducedBattleEffects ? 0 : step.scaleX,
        scaleY: _reducedBattleEffects ? 0 : step.scaleY,
        durationSeconds: step.durationSeconds,
        iteration: step.iteration,
      ),
    );
  }

  void _handleCombatantEllipseStep(CombatantEllipseStep step) {
    final combatant = _combatantForSlot(step.slot);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playEllipse(
        radiusX: _reducedBattleEffects ? 0 : step.radiusX,
        radiusY: _reducedBattleEffects ? 0 : step.radiusY,
        turns: step.turns,
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  ({BattleSlotRef slot, int lineupIndex, String? combatantId})?
  _cameraSubjectAt(BattleSlotRef slot) {
    if (_combatantForSlot(slot) == null) return null;
    final projected = _battlePresentation?.combatantAt(slot);
    if (_battlePresentation != null && projected == null) return null;
    if (projected == null && slot.slotIndex != 0) return null;
    final displayed = _displayedCombatantsBySlot[slot] ??
        (slot.side == BattleSideId.player
          ? _displayedPlayerCombatant : _displayedEnemyCombatant) ??
        _combatantDataAt(slot);
    if ((_presentationHeldHp[slot] ?? displayed.currentHp) <= 0) return null;
    final previous = _previousBattlePresentation?.combatantAt(slot);
    final displayedProjection = projected?.lineupIndex == displayed.lineupIndex
        ? projected
        : previous?.lineupIndex == displayed.lineupIndex ? previous : null;
    if (_battlePresentation != null && displayedProjection == null) return null;
    return (
      slot: slot, lineupIndex: displayed.lineupIndex,
      combatantId: displayedProjection?.combatantId,
    );
  }

  BattleCameraShot? _resolveBattleCameraShot({BattleSlotRef? principal}) {
    final camera = _perspectiveCamera;
    final layout = _sceneLayout;
    if (camera == null || layout == null) return null;
    final slots = [
      const BattleSlotRef.active(BattleSideId.enemy),
      const BattleSlotRef.active(BattleSideId.player),
      ..._additionalCombatants.keys,
    ].where((slot) =>
        _combatantForSlot(slot) != null &&
        !_geometryFor(slot).spriteRect.isEmpty &&
        (_cameraSubjectAt(slot) != null ||
            (principal == null && _session.state.isFinished && slot.slotIndex == 0)))
        .toList(growable: false);
    String id(BattleSlotRef slot) => '${slot.side.name}:${slot.slotIndex}';
    BattleCameraSubjectGeometry geometry(BattleSlotRef slot) {
      final stable = _combatantForSlot(slot)!.stableCameraGeometry;
      final bounds = stable.bounds;
      return BattleCameraSubjectGeometry(
        foot: stable.foot, bounds: bounds, focusAnchor: stable.focusAnchor,
        animationEnvelope: principal == slot
          ? battleCameraMotionEnvelope(slot)
          : stable.framingBounds.inflate(2),
      );
    }
    return const BattleCameraShotResolver().resolve(
      camera: camera,
      intent: principal == null ? BattleCameraShotIntent.overview : BattleCameraShotIntent.attacker,
      subjects: [
        for (final slot in slots)
          BattleCameraSubject(id: id(slot), geometry: geometry(slot)),
      ],
      principalId: principal == null ? null : id(principal),
      usefulViewport: layout.arenaRect.intersect(Rect.fromLTRB(
        _safeAreaPadding.left, _safeAreaPadding.top,
        size.x - _safeAreaPadding.right, size.y - _safeAreaPadding.bottom,
      )),
      obstacles: [
        if (layout.commandPanelPlacement != BattleCommandPanelPlacement.detached)
          layout.commandPanelRect,
        if (_teamInfoRevealed && !(_animationRunner?.areGaugesHidden ?? false))
          for (final slot in slots) _geometryFor(slot).hudRect,
      ],
      playerSide: principal?.side == BattleSideId.player,
      strength: _isDoubles ? .65 : 1,
    );
  }

  void _refreshBattleCameraFramingIfChanged() {
    final layout = _sceneLayout;
    if (layout == null || _perspectiveCamera == null) return;
    final inputs = <Object?>[
      layout.viewportSize, layout.stageRect, layout.arenaRect,
      layout.commandPanelRect, layout.commandPanelPlacement, _safeAreaPadding,
      _cameraMotionEnvelopeRevision, _reducedBattleEffects,
      _teamInfoRevealed && !(_animationRunner?.areGaugesHidden ?? false),
      for (final slot in [
        const BattleSlotRef.active(BattleSideId.enemy),
        const BattleSlotRef.active(BattleSideId.player),
        ..._additionalCombatants.keys,
      ])
        (slot, _cameraSubjectAt(slot), _geometryFor(slot).hudRect,
          _combatantForSlot(slot)?.stableCameraGeometry.bounds,
          _combatantForSlot(slot)?.stableCameraGeometry.foot,
          _combatantForSlot(slot)?.stableCameraGeometry.focusAnchor,
          _combatantForSlot(slot)?.stableCameraGeometry.framingBounds),
    ];
    if (listEquals(_cameraFramingInputs, inputs)) return;
    _cameraFramingInputs = inputs;
    _cameraFramingRevision += 1;
    _reflowBattleCameraFocus();
    _applyBattleCameraTransform();
  }

  void _resolveBattleCameraReturn() {
    final overview = _resolveBattleCameraShot();
    _cameraReturnShot = overview;
    if (overview != null && overview.fits) {
      _perspectiveCamera?.reflowOverview((eye: overview.eye, aim: overview.aim));
    }
  }

  void _reflowBattleCameraFocus() {
    _resolveBattleCameraReturn();
    final subject = _cameraFocusSubject;
    if (subject == null) return;
    if (_cameraSubjectAt(subject.slot) != subject) {
      _cameraFocusSubject = null;
      _perspectiveCamera?.cancel();
      return;
    }
    final shot = _resolveBattleCameraShot(principal: subject.slot);
    _perspectiveCamera?.reflowFocus(_geometryFor(subject.slot).footAnchor,
      resolvedPose: shot == null ? null : (eye: shot.eye, aim: shot.aim),
    );
  }

  void _handleCameraFocusStep(CameraFocusStep step) {
    if (_reducedBattleMotion) return;
    _cameraFocusSubject = null;
    if (step.target == BattleCameraFocusTarget.scene) {
      _resolveBattleCameraReturn();
      _perspectiveCamera?.reset(durationSeconds: step.durationSeconds);
    } else {
      final side = step.side ?? (step.target == BattleCameraFocusTarget.user
          ? BattleSideId.player : BattleSideId.enemy);
      final slot = BattleSlotRef(side: side, slotIndex: step.slotIndex);
      final subject = _cameraSubjectAt(slot);
      final geometry = _geometryFor(slot);
      if (subject == null || _perspectiveCamera?.tryGroundAt(geometry.footAnchor) == null) {
        _resetBattleCamera();
        return;
      }
      final shot = _resolveBattleCameraShot(principal: slot);
      _perspectiveCamera?.focus(geometry.footAnchor,
        resolvedPose: shot == null ? null : (eye: shot.eye, aim: shot.aim),
        playerSide: side == BattleSideId.player,
        durationSeconds: step.durationSeconds,
        strength: _isDoubles ? .65 : 1,
      );
      _cameraFocusSubject = subject;
    }
    _applyBattleCameraTransform();
  }

  void _handleBattleCameraMoveStep(BattleCameraMoveStep step) {
    if (_reducedBattleMotion) return;
    _cameraFocusSubject = null;
    _perspectiveCamera?.moveTo(
      eye: BattlePerspectiveCamera.homeEye + BattleCameraPoint(
        step.offsetX / 12, -step.offsetY / 12, (1 - step.scale) * 20,
      ),
      aim: BattlePerspectiveCamera.homeAim,
      durationSeconds: step.durationSeconds,
      easing: switch (step.curve) {
        BattleFxMotionCurve.linear => BattleCameraEasing.linear,
        _ => BattleCameraEasing.easeOut,
      },
    );
    _applyBattleCameraTransform();
  }

  void _handleBattleCameraResetStep(BattleCameraResetStep step) {
    _cameraFocusSubject = null;
    _resolveBattleCameraReturn();
    if (_reducedBattleMotion) {
      _resetBattleCamera();
      return;
    }
    _perspectiveCamera?.reset(durationSeconds: step.durationSeconds);
    _applyBattleCameraTransform();
  }

  void _resetBattleCamera() {
    _cameraFocusSubject = null;
    _resolveBattleCameraReturn();
    _perspectiveCamera?.cancel();
    _applyBattleCameraTransform();
  }

  void _applyBattleCameraTransform() {
    final camera = _perspectiveCamera;
    if (camera == null) return;
    _backdrop?.cameraParallax = camera.backdropOffset;
    void apply(BattleSlotRef slot, BattleSceneCombatantComponent? component) {
      if (component == null) return;
      final foot = _geometryFor(slot).footAnchor;
      final projected = camera.tryBillboardAt(foot);
      if (projected == null || _geometryFor(slot).spriteRect.isEmpty) {
        component.applyBattleCameraTransform(offset: Vector2.zero(), scale: 0);
        return;
      }
      component.applyBattleCameraTransform(
        offset: Vector2(
          projected.position.dx - foot.dx * projected.scale,
          projected.position.dy - foot.dy * projected.scale,
        ),
        scale: projected.scale,
      );
    }
    apply(const BattleSlotRef.active(BattleSideId.enemy), _enemyCombatant);
    apply(const BattleSlotRef.active(BattleSideId.player), _playerCombatant);
    for (final entry in _additionalCombatants.entries) { apply(entry.key, entry.value); }
    for (final child in children) {
      if (child case final BattleLiveAttachment attachment) attachment.refreshAttachment();
    }
  }

  void _handleFaintCombatantStep(FaintCombatantStep step) {
    if (_cameraFocusSubject?.slot == step.slot) _resetBattleCamera();
    final combatant = _combatantForSlot(step.slot);
    if (combatant == null) {
      return;
    }
    unawaited(combatant.playFaint(durationSeconds: step.durationSeconds));
  }

  void _handleHudHpTweenStep(HudHpTweenStep step) {
    _presentationHeldHp[step.slot] = step.toHp;
  }

  void _handleHudXpTweenStep(HudXpTweenStep step) {
    _presentationXpProgress = step.toProgress;
  }

  void _handleHudLevelUpStep() {
    final combatant = _combatantDataAt(const BattleSlotRef.active(BattleSideId.player));
    _presentationPlayerLevel = (_presentationPlayerLevel ?? combatant.level) + 1;
  }

  void _handleBarrierPulseStep(BarrierPulseStep step) {
    final fxLayer = _fxLayer;
    final targetRect = _combatantRenderedRectForSlot(step.slot);
    if (fxLayer == null || targetRect == null) {
      return;
    }
    final generation = _presentationGeneration;
    final identity = _effectSubjectAt(step.slot);
    fxLayer.playBarrierPulse(
      step,
      targetRect: targetRect.inflate(18),
      resolveTargetRect: () => _isCurrentPresentationGeneration(generation) &&
          identity != null && _effectSubjectAt(step.slot) == identity
          ? _combatantRenderedRectForSlot(step.slot)?.inflate(18) : null,
    );
  }

  void _handleSwapCombatantVisualStep(BattleSideId side) {
    if (_cameraFocusSubject?.slot == BattleSlotRef.active(side)) _resetBattleCamera();
    unawaited(
      _syncCombatantVisualForSide(
        side,
        presentationGeneration: _presentationGeneration,
      ),
    );
  }

  void _handleSwapCombatantVisualSlot(SwapCombatantVisualStep step) {
    final slot = step.slot;
    if (_cameraFocusSubject?.slot == slot) _resetBattleCamera();
    if (!_isDoubles) {
      unawaited(_syncCombatantVisualForSide(slot.side,
          presentationGeneration: _presentationGeneration,
          initialHp: step.initialHp));
      return;
    }
    unawaited(() async {
      final generation = _presentationGeneration;
      final data = _combatantDataAt(slot);
      final component = _combatantForSlot(slot);
      if (component == null) return;
      final sprite = await _resolveCombatantSpriteSpec(
        speciesId: data.speciesId,
        isPlayerSide: slot.side == BattleSideId.player,
        lineupIndex: data.lineupIndex,
        projection: _battlePresentation?.combatantAt(slot),
      );
      if (!_isCurrentPresentationGeneration(generation)) return;
      _displayedCombatantsBySlot[slot] = data;
      await component.sync(speciesLabel: resolveSpeciesDisplayName(data.speciesId), spriteSpec: sprite);
      if (!_isCurrentPresentationGeneration(generation)) return;
      component.snapToBattlePose();
      _presentationLockedCombatantSlots.remove(slot);
      _presentationHeldHp[slot] = step.initialHp ?? data.currentHp;
      _syncPanelsOnly();
    }());
  }

  BattleSceneCombatantComponent? _combatantForSide(BattleSideId side) =>
      _combatantForSlot(BattleSlotRef.active(side));

  BattleSceneCombatantComponent? _combatantForSlot(BattleSlotRef slot) {
    if (slot.slotIndex != 0) return _additionalCombatants[slot];
    return slot.side == BattleSideId.player ? _playerCombatant : _enemyCombatant;
  }

  Rect? _combatantRenderedRectForSlot(BattleSlotRef slot) =>
      _combatantForSlot(slot)?.currentRenderedSpriteRect;

  void _syncFieldAmbientState() {
    _fxLayer?.syncFieldAmbient(
      weather: _session.state.field.weather?.id,
      pseudoWeather: _session.state.field.pseudoWeather?.id,
    );
  }

  Vector2 _resolveBattleVisualAnchor({
    required BattleVisualAnchor anchor,
    required BattleSideId attackerSide,
    required BattleSideId defenderSide,
    int attackerSlotIndex = 0,
    int defenderSlotIndex = 0,
    bool ignoreRmxpTransform = false,
  }) {
    final attackerSlot = BattleSlotRef(side: attackerSide, slotIndex: attackerSlotIndex);
    final defenderSlot = BattleSlotRef(side: defenderSide, slotIndex: defenderSlotIndex);
    Offset centerFor(Rect? rect, Rect fallbackRect) {
      final effectiveRect = rect ?? fallbackRect;
      return effectiveRect.center;
    }

    Offset bodyFor(Rect? rect, Rect fallbackRect) {
      final effectiveRect = rect ?? fallbackRect;
      return Offset(
        effectiveRect.center.dx,
        effectiveRect.top + (effectiveRect.height * 0.55),
      );
    }

    Offset headFor(Rect? rect, Rect fallbackRect) {
      final effectiveRect = rect ?? fallbackRect;
      return Offset(
        effectiveRect.center.dx,
        effectiveRect.top + (effectiveRect.height * 0.18),
      );
    }

    double facingSign(Rect subjectRect, Rect opponentRect) {
      return opponentRect.center.dx >= subjectRect.center.dx ? 1.0 : -1.0;
    }

    Offset mouthFor(Rect? rect, Rect fallbackRect, Rect opponentFallback) {
      final effectiveRect = rect ?? fallbackRect;
      final sign = facingSign(effectiveRect, opponentFallback);
      return Offset(
        effectiveRect.center.dx + (sign * effectiveRect.width * 0.28),
        effectiveRect.top + (effectiveRect.height * 0.34),
      );
    }

    Offset handFor(Rect? rect, Rect fallbackRect, Rect opponentFallback) {
      final effectiveRect = rect ?? fallbackRect;
      final sign = facingSign(effectiveRect, opponentFallback);
      return Offset(
        effectiveRect.center.dx + (sign * effectiveRect.width * 0.34),
        effectiveRect.top + (effectiveRect.height * 0.58),
      );
    }

    Offset impactFor({
      required BattleSlotRef slot,
      required Rect? rect,
      required Rect fallbackRect,
      required Offset opponentCenter,
    }) {
      final combatant = _combatantForSlot(slot);
      if (combatant != null) {
        final spriteRect = ignoreRmxpTransform ? combatant.currentEffectAttachmentSpriteRect : combatant.currentRenderedSpriteRect;
        final facingSign = opponentCenter.dx >= spriteRect.center.dx ? 1.0 : -1.0;
        return Offset(
          spriteRect.center.dx + facingSign * spriteRect.width * .16,
          spriteRect.top + spriteRect.height * .42,
        );
      }
      final effectiveRect = rect ?? fallbackRect;
      final sign = opponentCenter.dx >= effectiveRect.center.dx ? 1.0 : -1.0;
      return Offset(
        effectiveRect.center.dx + (sign * effectiveRect.width * 0.16),
        effectiveRect.top + (effectiveRect.height * 0.42),
      );
    }

    Offset footFor(BattleSlotRef slot, Rect? rect, Rect fallbackRect) {
      final footAnchor =
          ignoreRmxpTransform ? _combatantForSlot(slot)?.currentEffectAttachmentFootAnchor :
            _combatantForSlot(slot)?.currentFootAnchor;
      if (footAnchor != null) {
        return footAnchor;
      }
      final effectiveRect = rect ?? fallbackRect;
      return Offset(effectiveRect.center.dx, effectiveRect.bottom);
    }

    final layout = currentSceneLayout;
    final attackerRect = ignoreRmxpTransform
        ? _combatantForSlot(attackerSlot)?.currentEffectAttachmentSpriteRect
        : _combatantRenderedRectForSlot(attackerSlot);
    final defenderRect = ignoreRmxpTransform
        ? _combatantForSlot(defenderSlot)?.currentEffectAttachmentSpriteRect
        : _combatantRenderedRectForSlot(defenderSlot);
    final attackerGeometry = _geometryFor(attackerSlot);
    final defenderGeometry = _geometryFor(defenderSlot);
    final attackerFallback = attackerGeometry.spriteRect.expandToInclude(attackerGeometry.platformRect);
    final defenderFallback = defenderGeometry.spriteRect.expandToInclude(defenderGeometry.platformRect);
    final stageRect = layout.stageRect;

    final offset = switch (anchor) {
      BattleVisualAnchor.attackerCenter =>
        centerFor(attackerRect, attackerFallback),
      BattleVisualAnchor.attackerBody =>
        bodyFor(attackerRect, attackerFallback),
      BattleVisualAnchor.attackerHead =>
        headFor(attackerRect, attackerFallback),
      BattleVisualAnchor.attackerMouth =>
        mouthFor(attackerRect, attackerFallback, defenderFallback),
      BattleVisualAnchor.attackerHand =>
        handFor(attackerRect, attackerFallback, defenderFallback),
      BattleVisualAnchor.attackerFoot =>
        footFor(attackerSlot, attackerRect, attackerFallback),
      BattleVisualAnchor.defenderCenter =>
        centerFor(defenderRect, defenderFallback),
      BattleVisualAnchor.defenderBody =>
        bodyFor(defenderRect, defenderFallback),
      BattleVisualAnchor.defenderHead =>
        headFor(defenderRect, defenderFallback),
      BattleVisualAnchor.defenderMouth =>
        mouthFor(defenderRect, defenderFallback, attackerFallback),
      BattleVisualAnchor.defenderHand =>
        handFor(defenderRect, defenderFallback, attackerFallback),
      BattleVisualAnchor.defenderImpact => impactFor(
          slot: defenderSlot,
          rect: defenderRect,
          fallbackRect: defenderFallback,
          opponentCenter: centerFor(attackerRect, attackerFallback),
        ),
      BattleVisualAnchor.defenderFoot =>
        footFor(defenderSlot, defenderRect, defenderFallback),
      BattleVisualAnchor.stageCenter => stageRect.center,
      BattleVisualAnchor.stageTop => Offset(stageRect.center.dx, stageRect.top),
      BattleVisualAnchor.stageBottom =>
        Offset(stageRect.center.dx, stageRect.bottom),
      BattleVisualAnchor.screenCenter => Offset(size.x / 2, size.y / 2),
    };
    return Vector2(offset.dx, offset.dy);
  }

  Future<void> _syncCombatantVisualForSide(
    BattleSideId side, {
    required int presentationGeneration,
    int? initialHp,
  }) async {
    if (!_isCurrentPresentationGeneration(presentationGeneration)) {
      return;
    }
    final combatant = side == BattleSideId.player
        ? _session.state.player
        : _session.state.enemy;
    _presentationHeldHp[BattleSlotRef.active(side)] =
        initialHp ?? combatant.currentHp;
    if (side == BattleSideId.player) {
      _displayedPlayerCombatant = combatant;
    } else {
      _displayedEnemyCombatant = combatant;
    }
    final sceneCombatant = _combatantForSide(side);
    if (sceneCombatant != null) {
      final spriteSpec = await _resolveCombatantSpriteSpec(
        speciesId: combatant.speciesId,
        isPlayerSide: side == BattleSideId.player,
        lineupIndex: combatant.lineupIndex,
        projection: _battlePresentation?.combatantAt(
          BattleSlotRef.active(side),
        ),
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
      await sceneCombatant.sync(
        speciesLabel: resolveSpeciesDisplayName(combatant.speciesId),
        spriteSpec: spriteSpec,
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
      // BETA-BAT-025 : même exemption que [_restoreAliveCombatantPoseAfterSync]
      // — un sauvage capturé reste dans sa Ball.
      if (side == BattleSideId.enemy && _capturedEnemyHeldInBall) {
        sceneCombatant.holdMaterializeHidden();
      } else {
        sceneCombatant.snapToBattlePose();
      }
    }
    _presentationLockedCombatantSlots.remove(BattleSlotRef.active(side));
    _syncPanelsOnly();
  }

  bool _isCurrentPresentationGeneration(int presentationGeneration) {
    return !_ballImagesDisposed &&
        presentationGeneration == _presentationGeneration;
  }

  int _xpTweenRevisionFor(HudXpTweenStep targetStep) {
    var revision = 0;
    for (final step
        in _activeAnimationPlan.flattenedSteps.whereType<HudXpTweenStep>()) {
      revision += 1;
      if (identical(step, targetStep)) {
        return revision;
      }
    }
    return 0;
  }

  int _hpTweenRevisionFor(HudHpTweenStep targetStep) {
    var revision = 0;
    for (final step
        in _activeAnimationPlan.flattenedSteps.whereType<HudHpTweenStep>()) {
      revision += 1;
      if (identical(step, targetStep)) {
        return revision;
      }
    }
    return 0;
  }
}

BattleCommandOverlayMode _overlayModeForMenuMode(BattleCommandMenuMode mode) {
  return switch (mode) {
    BattleCommandMenuMode.root => BattleCommandOverlayMode.root,
    BattleCommandMenuMode.fight => BattleCommandOverlayMode.fight,
    BattleCommandMenuMode.bag => BattleCommandOverlayMode.bag,
    BattleCommandMenuMode.bagMedicineTarget =>
      BattleCommandOverlayMode.bagMedicineTarget,
    BattleCommandMenuMode.bagMedicineMoveTarget =>
      BattleCommandOverlayMode.bagMedicineMoveTarget,
    BattleCommandMenuMode.pokemon => BattleCommandOverlayMode.pokemon,
    BattleCommandMenuMode.continueOnly => BattleCommandOverlayMode.continueOnly,
  };
}

BattleCommandOverlayEntryTone _overlayEntryToneForChoiceTone(
  BattleCommandChoiceTone tone,
) {
  return switch (tone) {
    BattleCommandChoiceTone.attack => BattleCommandOverlayEntryTone.attack,
    BattleCommandChoiceTone.special => BattleCommandOverlayEntryTone.special,
    BattleCommandChoiceTone.support => BattleCommandOverlayEntryTone.support,
    BattleCommandChoiceTone.switching =>
      BattleCommandOverlayEntryTone.switching,
    BattleCommandChoiceTone.neutral => BattleCommandOverlayEntryTone.neutral,
  };
}

BattleCommandOverlayEntryTone _overlayEntryToneForBagEntry(
  BattleBagMenuEntry entry,
) {
  if (!entry.isSelectable) {
    return BattleCommandOverlayEntryTone.disabled;
  }
  return switch (entry.kind) {
    BattleBagItemKind.captureBall => BattleCommandOverlayEntryTone.capture,
    BattleBagItemKind.medicine => BattleCommandOverlayEntryTone.medicine,
    BattleBagItemKind.unsupported => BattleCommandOverlayEntryTone.disabled,
  };
}

String _overlayBagEntryTypeLabel(BattleBagMenuEntry entry) {
  return switch (entry.usability) {
    ItemUsabilityState.passive => 'Passive',
    ItemUsabilityState.unavailableInContext => 'Unavailable here',
    ItemUsabilityState.invalidDefinition => 'Invalid definition',
    ItemUsabilityState.unsupportedCapability => 'Unsupported capability',
    ItemUsabilityState.usable => switch (entry.kind) {
        BattleBagItemKind.captureBall => 'Capture',
        BattleBagItemKind.medicine => 'Medicine',
        BattleBagItemKind.unsupported => 'Unsupported',
      },
  };
}

String _overlayBagEntryStatusLabel(BattleBagMenuEntry entry) {
  if (entry.isSelectable) {
    return 'OK';
  }
  return switch (entry.disabledReason) {
    BattleBagMenuDisabledReason.trainerBattle => 'Trainer only',
    BattleBagMenuDisabledReason.partyFull => 'Party full',
    BattleBagMenuDisabledReason.storageFull => 'Stockage plein',
    BattleBagMenuDisabledReason.captureUnavailable => 'Unavailable',
    BattleBagMenuDisabledReason.currentRequestDisallowsBag => 'Unavailable',
    BattleBagMenuDisabledReason.medicineNotImplemented => 'Not implemented',
    BattleBagMenuDisabledReason.unsupportedMedicine => 'Unsupported',
    BattleBagMenuDisabledReason.unsupportedItem => 'Unsupported',
    BattleBagMenuDisabledReason.passive => 'Passive',
    BattleBagMenuDisabledReason.unavailableInContext => 'Unavailable here',
    BattleBagMenuDisabledReason.invalidDefinition => 'Invalid definition',
    BattleBagMenuDisabledReason.unsupportedCapability =>
      'Unsupported capability',
    null => 'Unavailable',
  };
}

String _overlayPartyEntryStatusLabel(BattlePartyMenuEntry entry) {
  if (entry.isFainted) {
    return 'K.O.';
  }
  if (entry.isActive && !entry.isSelectable) {
    return 'Actif';
  }
  if (entry.isSelectable) {
    return 'OK';
  }
  return 'Unavailable';
}

String _overlayMedicineTargetStatusLabel(BattleMedicineTargetEntry entry) {
  if (entry.isFainted) {
    return 'K.O.';
  }
  if (entry.isSelectable) {
    return 'OK';
  }
  if (entry.disabledReason == BattleMedicineTargetDisabledReason.fullPp) {
    return 'PP max';
  }
  if (entry.currentHp >= entry.maxHp) {
    return 'Full HP';
  }
  return 'Unavailable';
}

/// Le dresseur vaincu, dessiné dans le cadre du sprite ennemi : ajusté en
/// hauteur, centré, les pieds au bas du cadre — là où son Pokémon se tenait.
final class _DefeatedTrainerSpriteComponent extends PositionComponent {
  _DefeatedTrainerSpriteComponent({
    required this.image,
    required Rect spriteRect,
    required int priority,
  }) : super(
          position: Vector2(spriteRect.left, spriteRect.top),
          size: Vector2(spriteRect.width, spriteRect.height),
          priority: priority,
        );

  final ui.Image image;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scale = math.min(
      size.x / image.width,
      size.y / image.height,
    );
    final destWidth = image.width * scale;
    final destHeight = image.height * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        (size.x - destWidth) / 2,
        size.y - destHeight,
        destWidth,
        destHeight,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}

final class _PostBattleDecisionRequest {
  const _PostBattleDecisionRequest({
    required this.prompt,
    required this.choices,
    required this.onChoice,
  });

  final String prompt;
  final List<String> choices;
  final ValueChanged<int> onChoice;
}

final class _TurnAudioInterrupted implements Exception {
  const _TurnAudioInterrupted();
}

final class _TurnAudioPreparationTimedOut implements Exception {
  const _TurnAudioPreparationTimedOut();
}

final class _PreparedGroupedSpl {
  _PreparedGroupedSpl({
    required this.component,
    required this.motion,
    required this.media,
    required this.coordinator,
    required this.onClosed,
  });

  final BattleSplStaticComponent component;
  final BattleGen5MotionComponent? motion;
  final BattleOfflineVerifiedMedia media;
  final BattleRecipeAudioCoordinator coordinator;
  final void Function() onClosed;
  void Function()? _onComplete;
  void Function()? _onFailure;
  Future<void>? _cancelling;
  bool _started = false;
  bool _visualFinished = false;
  bool _particleFinished = false;
  bool _motionFinished = false;
  bool _audioFinished = false;
  bool _closed = false;
  bool _failed = false;
  bool _cancelled = false;

  void audioPrepared(BattleRecipeAudioResult result) {
    final program = result.program;
    if (result.status != BattleRecipeAudioStatus.ready || program == null) {
      unawaited(cancel());
      return;
    }
    unawaited(program.finished.then<void>((_) async {
      try {
        await coordinator.cancel();
      } on Object catch (error) {
        debugPrint('[battle] grouped audio cleanup failed: $error');
      } finally {
        _audioFinished = true;
        if (!program.anyDispatched && !_started) _cancelVisual();
        _finishIfDone();
      }
    }, onError: (Object _) async {
      await cancel();
    }));
  }

  void Function() start(
    BattleOverlayComponent overlay,
    void Function() onComplete,
    void Function() onFailure, {
    required bool allowed,
  }
  ) {
    if (_closed || _visualFinished || _started) {
      onFailure();
      return () {};
    }
    _started = true;
    _onComplete = onComplete;
    _onFailure = onFailure;
    if (!allowed) {
      visualFailed();
      return _cancelVisual;
    }
    if (!component.refreshAttachment()) return _cancelVisual;
    try {
      if (motion != null) {
        motion!.begin();
        if (_visualFinished) return _cancelVisual;
        overlay.add(motion!);
      }
      component.priority = 9999;
      overlay.add(component);
    } on Object {
      visualFailed();
    }
    return _cancelVisual;
  }

  void failIfStarted() {
    if (_started && !_visualFinished) visualFailed();
  }

  void visualCompleted() {
    _particleFinished = true;
    _finishVisualIfReady();
  }

  void motionCompleted() {
    _motionFinished = true;
    _finishVisualIfReady();
  }

  void _finishVisualIfReady() {
    if (_visualFinished || !_particleFinished || (motion != null && !_motionFinished)) return;
    _visualFinished = true;
    if (motion == null) _onComplete?.call();
    _finishIfDone();
  }

  void visualFailed() {
    if (_closed || _failed || _cancelled || (_visualFinished && motion == null)) return;
    _visualFinished = true;
    _failed = true;
    component.dispose();
    motion?.dispose();
    _onFailure?.call();
    _finishIfDone();
  }

  void _cancelVisual() {
    _cancelled = true;
    motion?.dispose();
    if (_visualFinished) return;
    _visualFinished = true;
    component.dispose();
    _finishIfDone();
  }

  Future<void> cancel() => _cancelling ??= _cancel();

  Future<void> _cancel() async {
    _cancelVisual();
    try {
      await coordinator.cancel();
    } on Object catch (error) {
      debugPrint('[battle] grouped audio cleanup failed: $error');
    } finally {
      _audioFinished = true;
      _finishIfDone();
    }
  }

  void _finishIfDone() {
    if (_closed || !_visualFinished || !_audioFinished) return;
    _closed = true;
    motion?.dispose();
    media.release();
    onClosed();
    if (motion != null && !_failed && !_cancelled) _onComplete?.call();
  }
}

final class _PendingTurnAudioPreparation {
  _PendingTurnAudioPreparation(this.requests, this.cancelEffect);

  final List<BattleTurnAudioRequest> requests;
  final void Function(BattleTurnAudioRequest) cancelEffect;
  final Completer<void> interrupted = Completer<void>();
  final Completer<void> settled = Completer<void>();

  void cancel() {
    if (!interrupted.isCompleted) interrupted.complete();
    for (final request in requests) {
      cancelEffect(request);
      unawaited(Future.sync(request.coordinator.cancel).then<void>(
        (_) {},
        onError: (Object _) {},
      ));
    }
  }
}
