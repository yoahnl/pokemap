import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show Image, instantiateImageCodec;

import 'package:flutter/services.dart' show ByteData, rootBundle;

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_move_catalog_loader.dart';
import '../flutter/battle_command_overlay_snapshot.dart';
import 'battle_bag_menu_model.dart';
import 'battle_bag_item_icon_resolver.dart';
import 'battle_command_menu_model.dart';
import 'battle_command_panel_component.dart';
import 'battle_combatant_gender_resolver.dart';
import 'battle_animation_plan.dart';
import 'battle_animation_runner.dart';
import 'battle_ball_manifest.dart';
import 'battle_ball_throw_component.dart';
import 'battle_background_resolver.dart';
import 'battle_camera_rig.dart';
import 'battle_debug_panel_component.dart';
import 'battle_fx_bundle_cache.dart';
import 'battle_fx_layer_component.dart';
import 'battle_intro_animation_planner.dart';
import 'battle_medicine_target_menu_model.dart';
import 'battle_party_menu_model.dart';
import 'battle_pokemon_sprite_resolver.dart';
import 'battle_visual_asset_cache.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';
import 'battle_scene_layout.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_hud_component.dart';
import 'battle_turn_animation_planner.dart';
import 'battle_sfx_player.dart';
import 'battle_move_visual_resolver.dart';

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
  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnBagHpHealItemEvent(:final event):
        final actor = _overlayCombatantLabelForSide(event.side);
        lines.add(
          '$actor utilise ${event.displayName} sur ${event.targetSpeciesId}',
        );
        lines.add('${event.targetSpeciesId} récupère ${event.healedAmount} PV');
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

class BattleOverlayComponent extends PositionComponent {
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
    this.onBagHpHealItemUseRequested,
    this.onCommandOverlaySnapshotChanged,
    GameState gameState = const GameState(saveId: 'battle-overlay'),
    ItemCapabilityResolver? itemCapabilityResolver,
    this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
    this.spriteResolver,
    this.visualAssetCache,
    this.bagItemIconResolver,
    this.genderResolver,
    this.resolveMoveDisplayName = _defaultBattleMoveDisplayName,
    this.playSfx,
    this.onOutcomePresented,
    this.introEnabled = false,
    this.outcomeBannerEnabled = true,
    this.resolveSpeciesDisplayName = _battleDisplayName,
    this.showDebugPanel = false,
    this.motionScale = 1.0,
    this.textScale = 1.0,
    RuntimeMoveCatalog? moveCatalog,
    BattleMoveVisualResolver? moveVisualResolver,
    BattleFxBundleCache? fxBundleCache,
    bool preferTouchListDragScroll = false,
    bool useFlutterCommandOverlay = false,
    bool allowMedicineReserveTargets = true,
    Map<int, double> playerExperienceProgressByLineupIndex = const {},
  })  : _session = session,
        _gameState = gameState,
        _itemCapabilityResolver = itemCapabilityResolver ??
            ItemCapabilityResolver(ItemCatalogSnapshot.empty()),
        _moveCatalog = moveCatalog ??
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        _fxBundleCache = fxBundleCache ?? BattleFxBundleCache(),
        _preferTouchListDragScroll = preferTouchListDragScroll,
        _useFlutterCommandOverlay = useFlutterCommandOverlay,
        _allowMedicineReserveTargets = allowMedicineReserveTargets,
        _playerExperienceProgressByLineupIndex = Map<int, double>.unmodifiable(
          playerExperienceProgressByLineupIndex,
        ),
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        ) {
    _moveVisualResolver =
        moveVisualResolver ?? BattleMoveVisualResolver(_moveCatalog);
  }

  BattleSession _session;
  GameState _gameState;
  final ItemCapabilityResolver _itemCapabilityResolver;

  final void Function(PlayerBattleChoice choice) onPlayerChoice;
  final bool Function(
    BattleBagMenuActionMedicineTarget action,
    BattleMedicineTargetEntry entry,
  )? onBagHpHealItemUseRequested;
  final ValueChanged<BattleCommandOverlaySnapshot?>?
      onCommandOverlaySnapshotChanged;
  final BattleBackgroundSpec backgroundSpec;
  final BattlePokemonSpriteResolver? spriteResolver;
  final BattleVisualAssetCache? visualAssetCache;
  final BattleBagItemIconResolver? bagItemIconResolver;
  final BattleCombatantGenderResolver? genderResolver;
  final BattleMoveDisplayNameResolver resolveMoveDisplayName;

  /// BETA-BAT-014 : le lecteur des sons de combat. Nul chez un hôte silencieux
  /// — les harnais de test et les hôtes sans audio gardent exactement l'ancien
  /// comportement, et aucun test existant ne change.
  final BattleSfxPlayer? playSfx;

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
  final BattleFxBundleCache _fxBundleCache;
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

  /// Échelle de texte demandée par le joueur, transmise au panneau de commande.
  final double textScale;
  bool _preferTouchListDragScroll;
  bool _useFlutterCommandOverlay;
  final bool _allowMedicineReserveTargets;
  bool _acceptsPlayerCommands = true;

  BattleSceneBackdropComponent? _backdrop;
  BattleSceneCombatantComponent? _enemyCombatant;
  BattleSceneCombatantComponent? _playerCombatant;
  BattleFxLayerComponent? _fxLayer;
  BattleSceneHudComponent? _enemyHud;
  BattleSceneHudComponent? _playerHud;
  BattleCommandPanelComponent? _commandPanel;
  BattleDebugPanelComponent? _debugPanel;
  TextComponent? _outcomeBanner;

  /// Le texte du bandeau de fin, ou `null` quand il n'y en a pas.
  ///
  /// BETA-BAT-012 : exposé parce que le défaut portait précisément sur le
  /// MOMENT où ce bandeau apparaît, et qu'aucun test ne pouvait le voir.
  @visibleForTesting
  String? get outcomeBannerText => _outcomeBanner?.text;
  Future<void>? _pendingVisualSync;
  // BETA-BAT-011 : le planner reçoit les MÊMES résolveurs que le HUD et le
  // menu. `late` parce qu'un initialiseur de champ ne peut pas lire `this`, et
  // c'est exactement pour ça que le plan d'animation s'en passait.
  late final BattleTurnAnimationPlanner _turnAnimationPlanner =
      BattleTurnAnimationPlanner(
    speciesDisplayName: resolveSpeciesDisplayName,
    moveDisplayName: resolveMoveDisplayName,
  );
  BattleAnimationRunner? _animationRunner;
  BattleSceneLayout? _sceneLayout;
  BattleAnimationPlan _activeAnimationPlan =
      const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
  Set<BattleSideId> _presentationLockedCombatantSides = <BattleSideId>{};
  BattleCombatant? _displayedEnemyCombatant;
  BattleCombatant? _displayedPlayerCombatant;
  int _presentationGeneration = 0;
  final BattleCameraRig _battleCameraRig = BattleCameraRig();
  final Vector2 _cameraScaleScratch = Vector2.all(1);

  BattleCommandMenuMode _menuMode = BattleCommandMenuMode.root;
  int _selectedRootIndex = 0;
  int _selectedChoiceIndex = 0;
  int _selectedPartyIndex = 0;
  int _selectedBagIndex = 0;
  int _selectedMedicineTargetIndex = 0;
  String? _bagFeedbackMessage;
  BattleBagMenuActionMedicineTarget? _selectedMedicineAction;
  BattleCommandOverlaySnapshot? _currentCommandOverlaySnapshot;
  int _commandOverlayRevision = 0;
  final Map<String, String?> _bagIconAssetPathByItemId = <String, String?>{};
  final Map<String, Future<void>> _pendingBagIconPathsByItemId =
      <String, Future<void>>{};

  @visibleForTesting
  bool get commandPanelMounted => _commandPanel != null;

  bool get acceptsPlayerCommands => _acceptsPlayerCommands;

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
    _commandPanel?.removeFromParent();
    _commandPanel = null;
    _currentCommandOverlaySnapshot = null;
    onCommandOverlaySnapshotChanged?.call(null);
  }

  @visibleForTesting
  bool get enemyHudMounted => _enemyHud != null;

  @visibleForTesting
  bool get playerHudMounted => _playerHud != null;

  @visibleForTesting
  BattleSceneHudComponent? get debugPlayerHud => _playerHud;

  @visibleForTesting
  BattleSceneHudComponent? get debugEnemyHud => _enemyHud;

  @visibleForTesting
  String? get debugCurrentAnimationMessage => _animationRunner?.currentMessage;

  @visibleForTesting
  double? get debugPlayerSpriteOpacity =>
      // ignore: invalid_use_of_visible_for_testing_member
      _playerCombatant?.currentVisualOpacity;

  @visibleForTesting
  bool get narrationPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get debugPanelMounted => _debugPanel != null;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => backgroundSpec.key;

  @visibleForTesting
  String get currentPromptText =>
      _commandPanel?.currentPromptText ??
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

  /// BETA-BAT-017 : quand l'hôte présente la fin de combat DANS la scène
  /// (messages du coordinator joués par le runner), le bandeau flottant
  /// « Victoire ! » ferait doublon — et il flasherait dans la fenêtre entre
  /// la fin du dernier tour et le démarrage du plan de fin. L'hôte le coupe
  /// au montage ; les harnais existants gardent l'ancien comportement.
  final bool outcomeBannerEnabled;

  void startIntro() {
    final plan = _pendingIntroPlan;
    if (plan == null) return;
    _pendingIntroPlan = null;
    _introPlayed = true;
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
    if (plan.isEmpty) return;
    // Le plan actif suit le même cycle qu'un tour : posé ici, vidé par
    // [_handleAnimationPresentationChanged] quand le runner s'éteint. Les
    // révisions de tween du snapshot se comptent dessus, et le bandeau
    // d'issue le regarde pour savoir qu'une présentation est en cours.
    _activeAnimationPlan = plan;
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

  /// La planche utilisée par ce combat. Le lien individu → Ball de capture
  /// n'existe pas encore dans la donnée : la Poké Ball standard (`ball_1`)
  /// vaut pour tous, l'id reste un point d'extension.
  static const String _introBallSheetName = 'ball_1';

  Future<ui.Image?> _loadBallSheet(String sheetName) async {
    final cached = _ballSheetImages[sheetName];
    if (cached != null) return cached;
    final fileName = battleBallSheetManifest[sheetName];
    if (fileName == null) return null;
    ByteData? bytes;
    try {
      bytes = await rootBundle.load('packages/map_runtime/assets/battle/balls/'
          '$fileName');
    } on Object {
      try {
        bytes = await rootBundle.load('assets/battle/balls/$fileName');
      } on Object catch (error) {
        debugPrint('[battle] ball sheet unavailable ($sheetName): $error');
        return null;
      }
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _ballSheetImages[sheetName] = frame.image;
      return frame.image;
    } on Object catch (error) {
      debugPrint('[battle] ball sheet undecodable ($sheetName): $error');
      return null;
    }
  }

  void _handleBallSequenceStep(PlayBallSequenceStep step) {
    final sheet = _ballSheetImages[step.sheetName];
    if (sheet == null) return;
    final layout = currentSceneLayout;
    final spriteRect = step.side == BattleSideId.player
        ? layout.playerSpriteRect
        : layout.enemySpriteRect;
    final targetCenter = Offset(
      spriteRect.center.dx,
      spriteRect.bottom - spriteRect.height * 0.25,
    );
    if (step.kind == BattleBallSequenceKind.sendOutThrown) {
      playSfx?.call('ball_throw', volume: 100, pitch: 100);
    }
    add(
      BattleBallThrowComponent(
        sheet: sheet,
        kind: step.kind,
        targetCenter: targetCenter,
        throwStartX: ballThrowStartXFor(
          side: step.side,
          viewportWidth: size.x,
        ),
        cellSize: spriteRect.height * 0.32,
        onOpen: () => playSfx?.call('ball_open', volume: 100, pitch: 100),
      ),
    );
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

  void prepareDefeatedTrainerVisual(ui.Image image) {
    _defeatedTrainerImage = image;
  }

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

  /// L'horloge de présentation des PV, par camp — recette 2026-08-23.
  ///
  /// Le HUD Flame la tient déjà via `startingDisplayedHp`, mais sur mobile
  /// les HUD sont les widgets Flutter nourris par le snapshot, et le snapshot
  /// publiait l'état FINAL du tour dès `updateState` : barres drainées et
  /// badge K.O. pendant tout l'avant-impact. Ici : tant que le plan actif
  /// porte un drain à venir pour un camp, le snapshot publie le PV d'avant ;
  /// chaque drain joué avance la référence à son `toHp` ; la fin de la
  /// présentation rend la main à l'état réel.
  final Map<BattleSideId, int> _presentationHeldHp = <BattleSideId, int>{};

  bool get isTurnPresentationActive =>
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
      (_animationRunner?.isActive ?? false) ||
      _activeAnimationPlan.steps.isNotEmpty;

  @visibleForTesting
  bool get isBattleCameraFocusActive => _battleCameraRig.isActive;

  @visibleForTesting
  bool get isBattleCameraActive =>
      _battleCameraRig.isActive ||
      _battleCameraRig.offset.length > 0 ||
      _battleCameraRig.scale != 1.0;

  @visibleForTesting
  Vector2 get battleCameraOffset => _battleCameraRig.offset;

  @visibleForTesting
  double get battleCameraScale => _battleCameraRig.scale;

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
        _displayedPlayerCombatant ?? _session.state.player,
        isPlayerSide: true,
      );

  @visibleForTesting
  String get currentEnemyHudSpeciesText => _hudSpeciesDisplayText(
        _displayedEnemyCombatant ?? _session.state.enemy,
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
  /// de niveau, et les timings sonores des animations des capacités des
  /// deux camps. L'hôte les donne à préchauffer à son lecteur.
  Future<Set<String>> collectBattleSeNames() async {
    final seNames = <String>{'hit', 'hitplus', 'hitlow', 'down', 'level_up'};
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
    await waitForPendingVisualSync();
    await (_animationRunner?.completionFuture ?? Future<void>.value());
    await waitForPendingVisualSync();
  }

  /// Le host garde la détection de plateforme/manette et pousse simplement une
  /// préférence UX dans l'overlay.
  ///
  /// Cela évite de recréer une logique de hardware dans `map_runtime` tout en
  /// gardant le panel battle tactile quand il n'y a pas de manette sur mobile.
  void setPreferTouchListDragScroll(bool preferred) {
    if (_preferTouchListDragScroll == preferred) {
      return;
    }
    _preferTouchListDragScroll = preferred;
    _commandPanel?.setPreferTouchListDragScroll(preferred);
    _syncPanelsOnly();
  }

  /// Le host peut demander une chrome battle Flutter complète.
  ///
  /// Frontière volontaire :
  /// - Flame garde le décor, les sprites et les flashes de hit ;
  /// - Flutter reprend les HUDs et toute l'UI de décision ;
  /// - aucun moteur battle parallèle n'est introduit ici.
  void setUseFlutterCommandOverlay(bool preferred) {
    if (_useFlutterCommandOverlay == preferred) {
      return;
    }
    _useFlutterCommandOverlay = preferred;
    if (preferred) {
      _enemyHud?.removeFromParent();
      _enemyHud = null;
      _playerHud?.removeFromParent();
      _playerHud = null;
      _commandPanel?.removeFromParent();
      _commandPanel = null;
      _syncPanelsOnly();
      return;
    }
    unawaited(_ensureFlameHudsMounted());
    unawaited(_ensureCommandPanelMounted());
  }

  @visibleForTesting
  BattleSceneLayout get currentSceneLayout =>
      _sceneLayout ??
      BattleSceneLayout.forViewport(
        viewportSize: Size(size.x, size.y),
        textScale: textScale,
      );

  @visibleForTesting
  Vector2 get currentRmxpAnimationViewportSize => _rmxpAnimationViewportSize();

  @override
  Future<void> onLoad() async {
    final overlayStopwatch = Stopwatch()..start();
    // Le catalogue d'animations RMXP est un asset binaire décodé
    // paresseusement : le charger ici garantit que toute la planification
    // d'animations du combat peut y accéder de façon synchrone.
    await BattleSdkRmxpAnimationCatalog.ensureLoaded();
    final layout = BattleSceneLayout.forViewport(
      viewportSize: Size(size.x, size.y),
      textScale: textScale,
    );
    _sceneLayout = layout;

    final backdropStopwatch = Stopwatch()..start();
    _backdrop = BattleSceneBackdropComponent(
      size: size.clone(),
      backgroundSpec: backgroundSpec,
      visualAssetCache: visualAssetCache,
    );
    await add(_backdrop!);
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
    );
    await add(_enemyCombatant!);
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
    );
    await add(_playerCombatant!);
    playerCombatantStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.playerCombatant=${playerCombatantStopwatch.elapsedMilliseconds}ms',
    );

    // BETA-BAT-022 : la planche de Poké Ball se charge au montage — l'intro
    // ET les remplacements en vivent. Si elle manque, l'intro retombe sur le
    // glissement historique et les étapes Ball des remplacements ne montrent
    // rien (les durées s'écoulent, rien ne casse). Le chargement ne bloque
    // JAMAIS le chemin sans intro : allonger onLoad d'un tour d'event loop
    // suffisait à ce qu'un hôte pressé pousse son premier tour avant la
    // création du runner — le plan tombait dans le vide (recette du
    // 2026-08-24, capture PSDK muette).
    final ballSheetFuture = _loadBallSheet(_introBallSheetName);
    if (!introEnabled) {
      unawaited(ballSheetFuture);
    }
    if (introEnabled) {
      // BETA-BAT-016 : les combattants attendent hors écran, à leur position
      // de départ d'intro, AVANT le premier rendu — sous le noir de la
      // pré-transition, personne ne doit apparaître à sa place finale.
      // 360 px sur l'écran 320 de la référence = 1,125 largeur d'écran.
      final introSlideDistancePx = size.x * 1.125;
      final playerUsesBall = (await ballSheetFuture) != null;
      _enemyCombatant?.holdIntroSlideOffscreen(
        distancePx: introSlideDistancePx,
      );
      if (playerUsesBall) {
        _playerCombatant?.holdMaterializeHidden();
      } else {
        _playerCombatant?.holdIntroSlideOffscreen(
          distancePx: introSlideDistancePx,
        );
      }
      _pendingIntroPlan = buildBattleIntroAnimationPlan(
        session: _session,
        slideDistancePx: introSlideDistancePx,
        resolveSpeciesDisplayName: resolveSpeciesDisplayName,
        playerBallSheetName: playerUsesBall ? _introBallSheetName : null,
      );
    }

    _fxLayer = BattleFxLayerComponent(
      size: size.clone(),
      fxBundleCache: _fxBundleCache,
    );
    await add(_fxLayer!);
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
      onShowDefeatedTrainer: _handleShowDefeatedTrainerStep,
      onPlayBallSequence: _handleBallSequenceStep,
      onPlaySe: (step) => playSfx?.call(
        step.seName,
        volume: step.volume,
        pitch: step.pitch,
      ),
      onBarrierPulse: _handleBarrierPulseStep,
      onSwapCombatantVisual: _handleSwapCombatantVisualStep,
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

    if (!_useFlutterCommandOverlay) {
      final enemyHudStopwatch = Stopwatch()..start();
      _enemyHud = BattleSceneHudComponent(
        position: Vector2(layout.enemyHudRect.left, layout.enemyHudRect.top),
        size: Vector2(layout.enemyHudRect.width, layout.enemyHudRect.height),
        ownerLabel: 'ENNEMI',
        combatant: _session.state.enemy,
        isPlayerSide: false,
        initialGenderSymbol: _resolveCombatantGenderSymbol(
          combatant: _session.state.enemy,
          isPlayerSide: false,
        ),
        textScale: textScale,
      );
      await add(_enemyHud!);
      enemyHudStopwatch.stop();
      debugPrint(
        '[perf][battle][real] overlay.enemyHud=${enemyHudStopwatch.elapsedMilliseconds}ms',
      );

      final playerHudStopwatch = Stopwatch()..start();
      _playerHud = BattleSceneHudComponent(
        position: Vector2(layout.playerHudRect.left, layout.playerHudRect.top),
        size: Vector2(layout.playerHudRect.width, layout.playerHudRect.height),
        ownerLabel: 'JOUEUR',
        combatant: _session.state.player,
        isPlayerSide: true,
        initialGenderSymbol: _resolveCombatantGenderSymbol(
          combatant: _session.state.player,
          isPlayerSide: true,
        ),
        textScale: textScale,
      );
      await add(_playerHud!);
      playerHudStopwatch.stop();
      debugPrint(
        '[perf][battle][real] overlay.playerHud=${playerHudStopwatch.elapsedMilliseconds}ms',
      );
    }

    if (!_useFlutterCommandOverlay) {
      final commandPanelStopwatch = Stopwatch()..start();
      await _ensureCommandPanelMounted();
      commandPanelStopwatch.stop();
      debugPrint(
        '[perf][battle][real] overlay.commandPanel=${commandPanelStopwatch.elapsedMilliseconds}ms',
      );
    }

    if (showDebugPanel) {
      final debugPanelStopwatch = Stopwatch()..start();
      _debugPanel = BattleDebugPanelComponent(
        position: Vector2(size.x - 248, 32),
        size: Vector2(216, 148),
      );
      await add(_debugPanel!);
      debugPanelStopwatch.stop();
      debugPrint(
        '[perf][battle][real] overlay.debugPanel=${debugPanelStopwatch.elapsedMilliseconds}ms',
      );
    }

    final initialSyncStopwatch = Stopwatch()..start();
    final presentationGeneration = _presentationGeneration;
    _pendingVisualSync = _syncVisualState(
      presentationGeneration: presentationGeneration,
    );
    await _pendingVisualSync;
    initialSyncStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.initialVisualSync=${initialSyncStopwatch.elapsedMilliseconds}ms',
    );
    overlayStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.total=${overlayStopwatch.elapsedMilliseconds}ms',
    );
  }

  Future<void> _ensureCommandPanelMounted() async {
    if (_useFlutterCommandOverlay || _commandPanel != null) {
      return;
    }
    final layout = currentSceneLayout;
    final commandPanel = BattleCommandPanelComponent(
      position: Vector2(
        layout.commandPanelRect.left,
        layout.commandPanelRect.top,
      ),
      size: Vector2(
        layout.commandPanelRect.width,
        layout.commandPanelRect.height,
      ),
      onChoiceSelected: _handleChoiceSelected,
      onRootActionSelected: _handleRootActionSelected,
      onPartyEntrySelected: _handlePartyEntrySelected,
      onBagEntrySelected: _handleBagEntrySelected,
      onMedicineTargetEntrySelected: _handleMedicineTargetEntrySelected,
      onBackRequested: handleEscape,
      onScrollUpRequested: moveSelectionUp,
      onScrollDownRequested: moveSelectionDown,
      bagItemIconResolver: bagItemIconResolver,
      visualAssetCache: visualAssetCache,
      layoutModeOverride: layout.commandPanelLayoutMode,
      textScale: textScale,
      preferTouchListDragScroll: _preferTouchListDragScroll,
    );
    _commandPanel = commandPanel;
    await add(commandPanel);
    _syncPanelsOnly();
  }

  Future<void> _ensureFlameHudsMounted() async {
    if (_useFlutterCommandOverlay ||
        (_enemyHud != null && _playerHud != null)) {
      return;
    }
    final layout = currentSceneLayout;
    if (_enemyHud == null) {
      final enemyHud = BattleSceneHudComponent(
        position: Vector2(layout.enemyHudRect.left, layout.enemyHudRect.top),
        size: Vector2(layout.enemyHudRect.width, layout.enemyHudRect.height),
        ownerLabel: 'ENNEMI',
        combatant: _session.state.enemy,
        isPlayerSide: false,
        initialGenderSymbol: _resolveCombatantGenderSymbol(
          combatant: _session.state.enemy,
          isPlayerSide: false,
        ),
        textScale: textScale,
      );
      _enemyHud = enemyHud;
      await add(enemyHud);
    }
    if (_playerHud == null) {
      final playerHud = BattleSceneHudComponent(
        position: Vector2(layout.playerHudRect.left, layout.playerHudRect.top),
        size: Vector2(layout.playerHudRect.width, layout.playerHudRect.height),
        ownerLabel: 'JOUEUR',
        combatant: _session.state.player,
        isPlayerSide: true,
        initialGenderSymbol: _resolveCombatantGenderSymbol(
          combatant: _session.state.player,
          isPlayerSide: true,
        ),
        textScale: textScale,
      );
      _playerHud = playerHud;
      await add(playerHud);
    }
    await _syncVisualState(
      presentationGeneration: _presentationGeneration,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
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
  void updateState(BattleSession newSession, {GameState? gameState}) {
    final previousSession = _session;
    final presentationGeneration = ++_presentationGeneration;
    final animationPlan = _turnAnimationPlanner.build(
      previousSession: previousSession,
      newSession: newSession,
      moveCatalog: _moveCatalog,
      resolver: _moveVisualResolver,
    );
    _session = newSession;
    _syncFieldAmbientState();
    if (gameState != null) {
      _gameState = gameState;
    }
    _selectedMedicineAction = null;
    _selectedMedicineTargetIndex = 0;
    _bagFeedbackMessage = null;
    _activeAnimationPlan = animationPlan;
    _presentationHeldHp.clear();
    for (final step
        in animationPlan.flattenedSteps.whereType<HudHpTweenStep>()) {
      _presentationHeldHp.putIfAbsent(step.side, () => step.fromHp);
    }
    _presentationLockedCombatantSides =
        _lockedCombatantSidesFor(animationPlan).toSet();
    _resetBattleCamera();
    _animationRunner?.cancel(
      clearMessage: animationPlan.isEmpty,
      notify: false,
    );
    _normalizeMenuSelection();
    _pendingVisualSync = _prepareAnimationPresentation(
      previousSession: previousSession,
      animationPlan: animationPlan,
      presentationGeneration: presentationGeneration,
    );
    unawaited(_pendingVisualSync);
  }

  void _applyViewportLayout(Vector2 viewportSize) {
    if (viewportSize.x <= 0 || viewportSize.y <= 0) {
      return;
    }
    size = viewportSize.clone();
    final layout = BattleSceneLayout.forViewport(
      viewportSize: Size(size.x, size.y),
      textScale: textScale,
    );
    _sceneLayout = layout;

    _backdrop?.size = viewportSize.clone();
    _fxLayer?.size = viewportSize.clone();
    _applyBattleCameraTransform();
    _syncFieldAmbientState();
    _enemyCombatant?.updateSceneGeometry(
      sceneSpriteRect: layout.enemySpriteRect,
      scenePlatformRect: layout.enemyPlatformRect,
      sceneFootAnchor: layout.enemyFootAnchor,
    );
    _playerCombatant?.updateSceneGeometry(
      sceneSpriteRect: layout.playerSpriteRect,
      scenePlatformRect: layout.playerPlatformRect,
      sceneFootAnchor: layout.playerFootAnchor,
    );
    _enemyHud?.updateBounds(
      position: Vector2(layout.enemyHudRect.left, layout.enemyHudRect.top),
      size: Vector2(layout.enemyHudRect.width, layout.enemyHudRect.height),
    );
    _playerHud?.updateBounds(
      position: Vector2(layout.playerHudRect.left, layout.playerHudRect.top),
      size: Vector2(layout.playerHudRect.width, layout.playerHudRect.height),
    );
    _commandPanel?.updateLayout(
      position: Vector2(
        layout.commandPanelRect.left,
        layout.commandPanelRect.top,
      ),
      size: Vector2(
        layout.commandPanelRect.width,
        layout.commandPanelRect.height,
      ),
      modeOverride: layout.commandPanelLayoutMode,
    );
    _debugPanel?.position = Vector2(size.x - 248, 32);
    _applyBattleCameraTransform();
    _syncOutcomeBanner();
    _syncPanelsOnly();
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
        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget) {
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
    if (_postBattleDecision != null) {
      return _submitPostBattleDecision(_postBattleDecisionSelectedIndex);
    }
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
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

  bool handleEscape() {
    if (!_acceptsPlayerCommands || isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
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
    // Une seule mise à l'échelle pour toute la scène : le runner, la caméra et
    // les enfants visuels avancent sur la même horloge, donc rien ne se
    // désynchronise. Scaler la seule durée de phase du runner couperait les
    // effets en cours, ce qui reviendrait à les sauter.
    final scaledDt = dt * (motionScale <= 0 ? 1.0 : motionScale);
    _animationRunner?.update(scaledDt);
    if (isBattleCameraActive) {
      _battleCameraRig.update(scaledDt);
      _applyBattleCameraTransform();
    }
    super.update(scaledDt);
  }

  Future<void> _syncVisualState({
    BattleSession? previousSession,
    Set<BattleSideId> preserveDisplayedCombatantSides = const <BattleSideId>{},
    required int presentationGeneration,
  }) async {
    if (!_isCurrentPresentationGeneration(presentationGeneration)) {
      return;
    }
    _syncFieldAmbientState();
    final displayedEnemyCombatant =
        preserveDisplayedCombatantSides.contains(BattleSideId.enemy) &&
                previousSession != null
            ? previousSession.state.enemy
            : _session.state.enemy;
    final displayedPlayerCombatant =
        preserveDisplayedCombatantSides.contains(BattleSideId.player) &&
                previousSession != null
            ? previousSession.state.player
            : _session.state.player;
    BattleCombatantSpriteSpec? enemySpriteSpec;
    if (_enemyCombatant != null) {
      enemySpriteSpec = await _resolveCombatantSpriteSpec(
        speciesId: displayedEnemyCombatant.speciesId,
        isPlayerSide: false,
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
      preserveDisplayedCombatantSides: preserveDisplayedCombatantSides,
    );
    _restoreAliveCombatantPoseAfterSync(
      side: BattleSideId.player,
      combatant: displayedPlayerCombatant,
      preserveDisplayedCombatantSides: preserveDisplayedCombatantSides,
    );
    _enemyHud?.sync(
      combatant: displayedEnemyCombatant,
      genderSymbol: _resolveCombatantGenderSymbol(
        combatant: displayedEnemyCombatant,
        isPlayerSide: false,
      ),
      startingDisplayedHp: _presentationStartingHpForSide(
        side: BattleSideId.enemy,
        previousSession: previousSession,
      ),
    );
    _playerHud?.sync(
      combatant: displayedPlayerCombatant,
      genderSymbol: _resolveCombatantGenderSymbol(
        combatant: displayedPlayerCombatant,
        isPlayerSide: true,
      ),
      startingDisplayedHp: _presentationStartingHpForSide(
        side: BattleSideId.player,
        previousSession: previousSession,
      ),
    );
    _syncPanelsOnly();
    _syncOutcomeBanner();
  }

  void _restoreAliveCombatantPoseAfterSync({
    required BattleSideId side,
    required BattleCombatant combatant,
    required Set<BattleSideId> preserveDisplayedCombatantSides,
  }) {
    if (preserveDisplayedCombatantSides.contains(side) || combatant.isFainted) {
      return;
    }
    _combatantForSide(side)?.snapToBattlePose();
  }

  Future<BattleCombatantSpriteSpec> _resolveCombatantSpriteSpec({
    required String speciesId,
    required bool isPlayerSide,
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
      _publishPostBattleDecisionPresentation(decision);
      return;
    }
    _syncMenuStateFromModel();
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    final currentAnimationMessage = _animationRunner?.currentMessage;
    final isPresenting =
        (_animationRunner?.isActive ?? false) || !_acceptsPlayerCommands;
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
    final resolvedPrompt = currentAnimationMessage ??
        medicineTargetPrompt ??
        bagPrompt ??
        partyPrompt ??
        buildBattleDecisionPromptForSession(
          _session,
          resolveSpeciesDisplayName: resolveSpeciesDisplayName,
        );
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
        : (medicineTargetNarration ??
            bagNarration ??
            partyNarration ??
            defaultNarration);

    _commandPanel?.sync(
      battleLabel: _titleForSession(),
      prompt: resolvedPrompt,
      narrationLines: resolvedNarration,
      menuModel: menuModel,
      partyMenuModel: partyMenuModel,
      bagMenuModel: bagMenuModel,
      medicineTargetMenuModel: medicineTargetMenuModel,
      selectedPartyIndex: _selectedPartyIndex,
      selectedBagIndex: _selectedBagIndex,
      selectedMedicineTargetIndex: _selectedMedicineTargetIndex,
      allowEmptyNarrationBody: isPresenting,
      interactionsEnabled: !isPresenting,
    );
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
    final narrationLines = List<String>.unmodifiable(<String>[
      for (var index = 0; index < decision.choices.length; index++)
        '${index == _postBattleDecisionSelectedIndex ? '▶' : ' '} '
            '${decision.choices[index]}',
    ]);
    _commandPanel?.sync(
      battleLabel: _titleForSession(),
      prompt: decision.prompt,
      narrationLines: narrationLines,
      menuModel: _currentMenuModel(),
      partyMenuModel: _currentPartyMenuModel(),
      bagMenuModel: _currentBagMenuModel(),
      medicineTargetMenuModel: _currentMedicineTargetMenuModel(),
      selectedPartyIndex: _selectedPartyIndex,
      selectedBagIndex: _selectedBagIndex,
      selectedMedicineTargetIndex: _selectedMedicineTargetIndex,
      allowEmptyNarrationBody: false,
      interactionsEnabled: false,
    );
    final layout = currentSceneLayout;
    final snapshot = BattleCommandOverlaySnapshot(
      revision: ++_commandOverlayRevision,
      phase: BattlePresentationPhase.choosingCommand,
      forcedReplacement: false,
      mode: BattleCommandOverlayMode.root,
      viewportSize: layout.viewportSize,
      panelRect: layout.commandPanelRect,
      enemyHud: _buildHudSnapshot(
        rect: layout.enemyHudRect,
        ownerLabel: 'ENNEMI',
        combatant: _displayedEnemyCombatant ?? _session.state.enemy,
        isPlayerSide: false,
      ),
      playerHud: _buildHudSnapshot(
        rect: layout.playerHudRect,
        ownerLabel: 'JOUEUR',
        combatant: _displayedPlayerCombatant ?? _session.state.player,
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
            kind: BattleCommandOverlayEntryKind.root,
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
    final isForcedReplacement =
        partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement &&
            menuModel.mode == BattleCommandMenuMode.pokemon;
    final snapshot = BattleCommandOverlaySnapshot(
      revision: ++_commandOverlayRevision,
      phase: isForcedReplacement
          ? BattlePresentationPhase.forcedReplacement
          : interactionsEnabled
              ? BattlePresentationPhase.choosingCommand
              : BattlePresentationPhase.presentingTurn,
      forcedReplacement: isForcedReplacement,
      mode: _overlayModeForMenuMode(menuModel.mode),
      viewportSize: layout.viewportSize,
      panelRect: layout.commandPanelRect,
      enemyHud: _buildHudSnapshot(
        rect: layout.enemyHudRect,
        ownerLabel: 'ENNEMI',
        combatant: _displayedEnemyCombatant ?? _session.state.enemy,
        isPlayerSide: false,
      ),
      playerHud: _buildHudSnapshot(
        rect: layout.playerHudRect,
        ownerLabel: 'JOUEUR',
        combatant: _displayedPlayerCombatant ?? _session.state.player,
        isPlayerSide: true,
      ),
      battleLabel: _titleForSession(),
      title: menuModel.isRootMode ? 'COMMANDS' : menuModel.choiceGroupTitle,
      prompt: prompt,
      narrationLines: List<String>.unmodifiable(narrationLines),
      entries: _buildCommandOverlayEntries(
        menuModel: menuModel,
        partyMenuModel: partyMenuModel,
        bagMenuModel: bagMenuModel,
        medicineTargetMenuModel: medicineTargetMenuModel,
      ),
      interactionsEnabled: interactionsEnabled,
      canGoBack: _canGoBackFrom(menuModel, partyMenuModel),
    );
    _currentCommandOverlaySnapshot = snapshot;
    onCommandOverlaySnapshotChanged?.call(snapshot);
    _primeBagIconAssetPaths(bagMenuModel);
  }

  BattleCommandOverlayHudSnapshot _buildHudSnapshot({
    required Rect rect,
    required String ownerLabel,
    required BattleCombatant combatant,
    required bool isPlayerSide,
  }) {
    final targetSide = isPlayerSide ? BattleSideId.player : BattleSideId.enemy;
    final presentationStep = _animationRunner?.currentHpTweenStep;
    final isHpTweenStep = presentationStep?.side == targetSide;
    final xpStep = isPlayerSide ? _animationRunner?.currentXpTweenStep : null;
    final heldHp = _presentationHeldHp[targetSide];
    final koIsPresented = heldHp == null || heldHp <= 0;
    final statusLabel = combatant.isFainted && koIsPresented
        ? 'K.O.'
        : combatant.majorStatus?.id.name.toUpperCase();
    return BattleCommandOverlayHudSnapshot(
      rect: rect,
      ownerLabel: ownerLabel,
      speciesLabel: resolveSpeciesDisplayName(combatant.speciesId),
      level: combatant.level,
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
              _presentationXpProgress ??
              _playerExperienceProgressByLineupIndex[combatant.lineupIndex])
          : null,
      experienceProgressTarget: xpStep?.toProgress,
      xpTweenDurationMs: xpStep?.durationMs,
      xpTweenRevision: xpStep == null ? 0 : _xpTweenRevisionFor(xpStep),
    );
  }

  List<BattleCommandOverlayEntry> _buildCommandOverlayEntries({
    required BattleCommandMenuModel menuModel,
    required BattlePartyMenuModel partyMenuModel,
    required BattleBagMenuModel bagMenuModel,
    required BattleMedicineTargetMenuModel? medicineTargetMenuModel,
  }) {
    return switch (menuModel.mode) {
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
    if (_postBattleDecision != null) {
      return _movePostBattleDecisionSelection(
        verticalDelta != 0 ? verticalDelta : horizontalDelta,
      );
    }
    if (!_acceptsPlayerCommands) return false;
    if (isTurnPresentationActive) {
      return false;
    }
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    if (menuModel.isContinueOnly) {
      return false;
    }
    if (menuModel.isRootMode) {
      final nextIndex = moveBattleCommandGridSelection(
        currentIndex: menuModel.selectedRootIndex,
        itemCount: menuModel.rootEntries.length,
        columnCount: 2,
        horizontalDelta: horizontalDelta,
        verticalDelta: verticalDelta,
      );
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
        columnCount: 1,
        horizontalDelta: 0,
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
        columnCount: 1,
        horizontalDelta: 0,
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
        columnCount: 1,
        horizontalDelta: 0,
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
      columnCount: menuModel.choiceColumns,
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
    onPlayerChoice(choice);
  }

  void _handlePartyEntrySelected(BattlePartyMenuEntry entry) {
    final choice = entry.playerChoice;
    if (choice == null) {
      return;
    }
    onPlayerChoice(choice);
  }

  bool _handleMedicineTargetEntrySelected(BattleMedicineTargetEntry entry) {
    if (!entry.isSelectable) {
      return false;
    }
    final selectedMedicineAction = _selectedMedicineAction;
    if (selectedMedicineAction == null) {
      return false;
    }

    // Lots 9-e à 9-h gardent l'overlay strictement borné au shell de
    // ciblage :
    // - le parent runtime commit le vrai tour pour `Potion`, `Super Potion`
    //   `Hyper Potion` et `Max Potion` ;
    // - l'overlay ne patche plus sa session localement ;
    // - cela évite de mentir sur l'ordre du tour et garde `PlayableMapGame`
    //   propriétaire unique du vrai BattleSession / GameState.
    return onBagHpHealItemUseRequested?.call(selectedMedicineAction, entry) ??
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
    );
  }

  BattlePartyMenuModel _currentPartyMenuModel() {
    return buildBattlePartyMenuModel(session: _session);
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
      isTargetAllowed: (combatant) =>
          _allowMedicineReserveTargets ||
          combatant.lineupIndex == _session.state.player.lineupIndex,
    );
  }

  BattleCommandMenuMode _effectiveMenuMode() {
    final partyMenuModel = _currentPartyMenuModel();
    if (partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement &&
        partyMenuModel.hasSelectableEntries) {
      return BattleCommandMenuMode.pokemon;
    }
    if (_menuMode == BattleCommandMenuMode.bagMedicineTarget &&
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
    if (_menuMode != BattleCommandMenuMode.bagMedicineTarget) {
      _selectedMedicineAction = null;
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
    if (_menuMode != BattleCommandMenuMode.bagMedicineTarget) {
      _selectedMedicineAction = null;
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
    if (previousMenuMode != BattleCommandMenuMode.bagMedicineTarget) {
      return _firstSelectableMedicineTargetIndexFor(medicineTargetMenuModel);
    }
    return safeIndex;
  }

  void _syncOutcomeBanner() {
    if (!outcomeBannerEnabled) {
      _outcomeBanner?.removeFromParent();
      _outcomeBanner = null;
      return;
    }
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
    if (!outcomePresented ||
        !battleOutcomeIsAnnounced(
          outcome,
          isTrainerBattle: _session.setup.isTrainerBattle,
        )) {
      _outcomeBanner?.removeFromParent();
      _outcomeBanner = null;
      return;
    }

    final bannerText = _buildOutcomeHeadline(
      outcome,
      resolveSpeciesDisplayName,
    );
    final bannerColor = outcome.isVictory || outcome.isCaptured
        ? const Color(0xFF8AE36A)
        : const Color(0xFFFF8E75);

    if (_outcomeBanner == null) {
      _outcomeBanner = TextComponent(
        text: bannerText,
        position: Vector2(size.x / 2, size.y * 0.17),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: bannerColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        priority: 45,
      );
      add(_outcomeBanner!);
      return;
    }

    _outcomeBanner!.text = bannerText;
    _outcomeBanner!.position = Vector2(size.x / 2, size.y * 0.17);
    _outcomeBanner!.textRenderer = TextPaint(
      style: TextStyle(
        color: bannerColor,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
    );
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
    await _syncVisualState(
      previousSession: previousSession,
      preserveDisplayedCombatantSides: _presentationLockedCombatantSides,
      presentationGeneration: presentationGeneration,
    );
    if (!_isCurrentPresentationGeneration(presentationGeneration)) {
      return;
    }
    if (animationPlan.isEmpty) {
      _presentationLockedCombatantSides = <BattleSideId>{};
      _syncPanelsOnly();
      return;
    }
    await _fxBundleCache.prewarm(animationPlan.requiredFxIds);
    if (!_isCurrentPresentationGeneration(presentationGeneration)) {
      return;
    }
    _animationRunner?.start(animationPlan);
  }

  Set<BattleSideId> _lockedCombatantSidesFor(BattleAnimationPlan plan) {
    return plan.steps
        .whereType<SwapCombatantVisualStep>()
        .map((step) => step.side)
        .toSet();
  }

  void _handleAnimationPresentationChanged() {
    _syncPanelsOnly();
    final animationRunner = _animationRunner;
    if (animationRunner == null || animationRunner.isActive) {
      return;
    }
    _resetBattleCamera();
    _presentationLockedCombatantSides = <BattleSideId>{};
    _presentationHeldHp.clear();
    _activeAnimationPlan =
        const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
    final presentationGeneration = _presentationGeneration;
    _pendingVisualSync = _syncVisualState(
      presentationGeneration: presentationGeneration,
    );
    unawaited(_pendingVisualSync);
  }

  BattleFxRuntimeContext _battleFxRuntimeContext({Vector2? sceneSize}) {
    return BattleFxRuntimeContext(
      sceneSize: sceneSize ?? size.clone(),
      stageRect: currentSceneLayout.stageRect,
      resolveAnchor: _resolveBattleVisualAnchor,
    );
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
    final combatant = _combatantForSide(step.subjectSide);
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playRmxpAnimation(
        step,
        _battleFxRuntimeContext(sceneSize: _rmxpAnimationViewportSize()),
        onCombatantTransform: combatant == null
            ? null
            : (transform) {
                combatant.applyRmxpTransform(
                  offset: transform.offset,
                  scale: transform.scale,
                );
              },
        onCombatantTransformCleared: combatant?.clearRmxpTransform,
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
          combatant?.triggerHitFlash(
            duration:
                (timing.flashDuration * 2 / 60).clamp(0.05, 0.8).toDouble(),
          );
        },
        onSceneFlash: (timing) {
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
        onVisibilityChanged: combatant?.setRmxpHidden,
      ),
    );
  }

  Vector2 _rmxpAnimationViewportSize() {
    final layout = currentSceneLayout;
    final battleViewportHeight =
        layout.commandPanelRect.top.clamp(0.0, size.y).toDouble();
    return Vector2(size.x, battleViewportHeight);
  }

  void _handleSceneTintStep(SceneTintStep step) {
    _fxLayer?.playSceneTint(step);
  }

  void _handleCombatantMotionStep(CombatantMotionStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    switch (step.motionKind) {
      case BattleCombatantMotionKind.lunge:
        unawaited(
          combatant.playLunge(
            towardOpponent: true,
            distancePx: step.distancePx,
            durationSeconds: step.durationSeconds,
          ),
        );
      case BattleCombatantMotionKind.fastDash:
        unawaited(
          combatant.playFastDash(
            towardOpponent: true,
            distancePx: step.distancePx,
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
            distancePx: step.distancePx,
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
    _combatantForSide(step.side)
        ?.triggerHitFlash(duration: step.durationSeconds);
  }

  void _handleCombatantShakeStep(CombatantShakeStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playShake(
        amplitudePx: step.amplitudePx,
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void _handleCombatantToneStep(CombatantToneStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playTone(
        color: Color(step.colorArgb),
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void _handleCombatantCompressStep(CombatantCompressStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playCompress(
        scaleX: step.scaleX,
        scaleY: step.scaleY,
        durationSeconds: step.durationSeconds,
        iteration: step.iteration,
      ),
    );
  }

  void _handleCombatantEllipseStep(CombatantEllipseStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    unawaited(
      combatant.playEllipse(
        radiusX: step.radiusX,
        radiusY: step.radiusY,
        turns: step.turns,
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void _handleCameraFocusStep(CameraFocusStep step) {
    switch (step.target) {
      case BattleCameraFocusTarget.user:
        _battleCameraRig.focusUser(durationSeconds: step.durationSeconds);
      case BattleCameraFocusTarget.target:
        _battleCameraRig.focusTarget(durationSeconds: step.durationSeconds);
      case BattleCameraFocusTarget.scene:
        _battleCameraRig.centerScene(durationSeconds: step.durationSeconds);
    }
    _applyBattleCameraTransform();
  }

  void _handleBattleCameraMoveStep(BattleCameraMoveStep step) {
    _battleCameraRig.moveTo(
      offset: Vector2(step.offsetX, step.offsetY),
      scale: step.scale,
      durationSeconds: step.durationSeconds,
      curve: step.curve,
    );
    _applyBattleCameraTransform();
  }

  void _handleBattleCameraResetStep(BattleCameraResetStep step) {
    _battleCameraRig.reset(durationSeconds: step.durationSeconds);
    _applyBattleCameraTransform();
  }

  void _resetBattleCamera() {
    _battleCameraRig.cancel();
    _applyBattleCameraTransform();
  }

  void _applyBattleCameraTransform() {
    // Tourne à chaque frame quand la caméra battle est active : les setters
    // Flame copient déjà (setFrom), aucun clone nécessaire.
    final offset = _battleCameraRig.offset;
    final scale = _battleCameraRig.scale;
    _cameraScaleScratch.setValues(scale, scale);
    _backdrop
      ?..position = offset
      ..scale = _cameraScaleScratch;
    _fxLayer
      ?..position = offset
      ..scale = _cameraScaleScratch;
    _enemyCombatant?.applyBattleCameraTransform(
      offset: offset,
      scale: scale,
    );
    _playerCombatant?.applyBattleCameraTransform(
      offset: offset,
      scale: scale,
    );
  }

  void _handleFaintCombatantStep(FaintCombatantStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    unawaited(combatant.playFaint(durationSeconds: step.durationSeconds));
  }

  void _handleHudHpTweenStep(HudHpTweenStep step) {
    _presentationHeldHp[step.side] = step.toHp;
    _hudForSide(step.side)?.animateDisplayedHp(
      fromHp: step.fromHp,
      toHp: step.toHp,
      duration: step.durationMs / 1000,
    );
  }

  void _handleHudXpTweenStep(HudXpTweenStep step) {
    _presentationXpProgress = step.toProgress;
  }

  void _handleBarrierPulseStep(BarrierPulseStep step) {
    final fxLayer = _fxLayer;
    final targetRect = _combatantRenderedRectForSide(step.side);
    if (fxLayer == null || targetRect == null) {
      return;
    }
    fxLayer.playBarrierPulse(
      step,
      targetRect: targetRect.inflate(18),
    );
  }

  void _handleSwapCombatantVisualStep(BattleSideId side) {
    unawaited(
      _syncCombatantVisualForSide(
        side,
        presentationGeneration: _presentationGeneration,
      ),
    );
  }

  BattleSceneCombatantComponent? _combatantForSide(BattleSideId side) {
    return side == BattleSideId.player ? _playerCombatant : _enemyCombatant;
  }

  BattleSceneHudComponent? _hudForSide(BattleSideId side) {
    return side == BattleSideId.player ? _playerHud : _enemyHud;
  }

  Rect? _combatantRenderedRectForSide(BattleSideId side) {
    return _combatantForSide(side)?.currentCameraNeutralRenderedSpriteRect;
  }

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
  }) {
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
      required BattleSideId side,
      required Rect? rect,
      required Rect fallbackRect,
      required Offset opponentCenter,
    }) {
      final combatant = _combatantForSide(side);
      if (combatant != null) {
        return combatant.currentCameraNeutralImpactAnchorToward(
          opponentCenter: opponentCenter,
        );
      }
      final effectiveRect = rect ?? fallbackRect;
      final sign = opponentCenter.dx >= effectiveRect.center.dx ? 1.0 : -1.0;
      return Offset(
        effectiveRect.center.dx + (sign * effectiveRect.width * 0.16),
        effectiveRect.top + (effectiveRect.height * 0.42),
      );
    }

    Offset footFor(BattleSideId side, Rect? rect, Rect fallbackRect) {
      final footAnchor =
          _combatantForSide(side)?.currentCameraNeutralFootAnchor;
      if (footAnchor != null) {
        return footAnchor;
      }
      final effectiveRect = rect ?? fallbackRect;
      return Offset(effectiveRect.center.dx, effectiveRect.bottom);
    }

    final layout = currentSceneLayout;
    final attackerRect = _combatantRenderedRectForSide(attackerSide);
    final defenderRect = _combatantRenderedRectForSide(defenderSide);
    final attackerFallback = attackerSide == BattleSideId.player
        ? layout.playerCombatantBoundsRect
        : layout.enemyCombatantBoundsRect;
    final defenderFallback = defenderSide == BattleSideId.player
        ? layout.playerCombatantBoundsRect
        : layout.enemyCombatantBoundsRect;
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
        footFor(attackerSide, attackerRect, attackerFallback),
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
          side: defenderSide,
          rect: defenderRect,
          fallbackRect: defenderFallback,
          opponentCenter: centerFor(attackerRect, attackerFallback),
        ),
      BattleVisualAnchor.defenderFoot =>
        footFor(defenderSide, defenderRect, defenderFallback),
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
  }) async {
    if (!_isCurrentPresentationGeneration(presentationGeneration)) {
      return;
    }
    final combatant = side == BattleSideId.player
        ? _session.state.player
        : _session.state.enemy;
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
      sceneCombatant.snapToBattlePose();
    }
    _hudForSide(side)?.sync(
      combatant: combatant,
      genderSymbol: _resolveCombatantGenderSymbol(
        combatant: combatant,
        isPlayerSide: side == BattleSideId.player,
      ),
    );
    _presentationLockedCombatantSides.remove(side);
    _syncPanelsOnly();
  }

  bool _isCurrentPresentationGeneration(int presentationGeneration) {
    return presentationGeneration == _presentationGeneration;
  }

  int? _presentationStartingHpForSide({
    required BattleSideId side,
    required BattleSession? previousSession,
  }) {
    if (previousSession == null ||
        !_activeAnimationPlan.flattenedSteps
            .whereType<HudHpTweenStep>()
            .any((step) => step.side == side)) {
      return null;
    }
    final previousCombatant = side == BattleSideId.player
        ? previousSession.state.player
        : previousSession.state.enemy;
    final currentCombatant = side == BattleSideId.player
        ? (_displayedPlayerCombatant ?? _session.state.player)
        : (_displayedEnemyCombatant ?? _session.state.enemy);
    if (!_isSameVisibleCombatant(previousCombatant, currentCombatant)) {
      return null;
    }
    return previousCombatant.currentHp;
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

  bool _isSameVisibleCombatant(
    BattleCombatant current,
    BattleCombatant next,
  ) {
    return current.lineupIndex == next.lineupIndex &&
        current.speciesId == next.speciesId;
  }
}

BattleCommandOverlayMode _overlayModeForMenuMode(BattleCommandMenuMode mode) {
  return switch (mode) {
    BattleCommandMenuMode.root => BattleCommandOverlayMode.root,
    BattleCommandMenuMode.fight => BattleCommandOverlayMode.fight,
    BattleCommandMenuMode.bag => BattleCommandOverlayMode.bag,
    BattleCommandMenuMode.bagMedicineTarget =>
      BattleCommandOverlayMode.bagMedicineTarget,
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
  if (entry.currentHp >= entry.maxHp) {
    return 'Full HP';
  }
  if (entry.isSelectable) {
    return 'OK';
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
