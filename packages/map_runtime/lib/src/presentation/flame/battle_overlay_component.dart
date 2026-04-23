import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_move_catalog_loader.dart';
import '../flutter/battle_command_overlay_snapshot.dart';
import 'battle_bag_menu_model.dart';
import 'battle_bag_item_icon_resolver.dart';
import 'battle_command_menu_model.dart';
import 'battle_command_panel_component.dart';
import 'battle_combatant_gender_resolver.dart';
import 'battle_animation_plan.dart';
import 'battle_animation_runner.dart';
import 'battle_background_resolver.dart';
import 'battle_debug_panel_component.dart';
import 'battle_fx_bundle_cache.dart';
import 'battle_fx_layer_component.dart';
import 'battle_medicine_target_menu_model.dart';
import 'battle_party_menu_model.dart';
import 'battle_pokemon_sprite_resolver.dart';
import 'battle_visual_asset_cache.dart';
import 'battle_scene_layout.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_hud_component.dart';
import 'battle_turn_animation_planner.dart';
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
          '$actor utilise ${event.itemKind.label} sur ${event.targetSpeciesId}',
        );
        lines.add('${event.targetSpeciesId} récupère ${event.healedAmount} PV');
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
List<String> buildBattleNarrationLinesForOverlay(BattleSession session) {
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
      _buildOutcomeHeadline(session.state.outcome!),
    ]);
  }

  return List<String>.unmodifiable(<String>[
    buildBattleDecisionPromptForOverlay(session.decisionRequest),
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
  final supportedItemLabel = _overlaySupportedMedicineLabel(
    medicineTargetMenuModel.itemId,
  );
  if (supportedItemLabel != null) {
    return 'Choisis une cible pour $supportedItemLabel.';
  }
  return 'Choisis un Pokémon.';
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

String? _overlaySupportedMedicineLabel(String itemId) {
  return switch (itemId) {
    'potion' => 'Potion',
    'super-potion' => 'Super Potion',
    'hyper-potion' => 'Hyper Potion',
    _ => null,
  };
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

String _buildOutcomeHeadline(BattleOutcome outcome) {
  return switch (outcome.type) {
    BattleOutcomeType.victory => 'Victoire !',
    BattleOutcomeType.defeat => 'Défaite...',
    BattleOutcomeType.runaway => 'Fuite réussie !',
    BattleOutcomeType.captured => 'Capture réussie !',
  };
}

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
class BattleOverlayComponent extends PositionComponent {
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
    this.onBagHpHealItemUseRequested,
    this.onCommandOverlaySnapshotChanged,
    GameState gameState = const GameState(saveId: 'battle-overlay'),
    this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
    this.spriteResolver,
    this.visualAssetCache,
    this.bagItemIconResolver,
    this.genderResolver,
    this.showDebugPanel = false,
    RuntimeMoveCatalog? moveCatalog,
    BattleMoveVisualResolver? moveVisualResolver,
    BattleFxBundleCache? fxBundleCache,
    bool preferTouchListDragScroll = false,
    bool useFlutterCommandOverlay = false,
  })  : _session = session,
        _gameState = gameState,
        _moveCatalog = moveCatalog ??
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        _fxBundleCache = fxBundleCache ?? BattleFxBundleCache(),
        _preferTouchListDragScroll = preferTouchListDragScroll,
        _useFlutterCommandOverlay = useFlutterCommandOverlay,
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
  final RuntimeMoveCatalog _moveCatalog;
  late final BattleMoveVisualResolver _moveVisualResolver;
  final BattleFxBundleCache _fxBundleCache;

  /// Le debug reste volontairement opt-in.
  ///
  /// Le lot 1 doit sortir l'UI normale du mode "debug panel". On garde donc un
  /// interrupteur explicite au lieu de laisser le debug redéfinir l'apparence
  /// par défaut du combat.
  final bool showDebugPanel;
  bool _preferTouchListDragScroll;
  bool _useFlutterCommandOverlay;

  BattleSceneBackdropComponent? _backdrop;
  BattleSceneCombatantComponent? _enemyCombatant;
  BattleSceneCombatantComponent? _playerCombatant;
  BattleFxLayerComponent? _fxLayer;
  BattleSceneHudComponent? _enemyHud;
  BattleSceneHudComponent? _playerHud;
  BattleCommandPanelComponent? _commandPanel;
  BattleDebugPanelComponent? _debugPanel;
  TextComponent? _outcomeBanner;
  Future<void>? _pendingVisualSync;
  final BattleTurnAnimationPlanner _turnAnimationPlanner =
      BattleTurnAnimationPlanner();
  BattleAnimationRunner? _animationRunner;
  BattleSceneLayout? _sceneLayout;
  BattleAnimationPlan _activeAnimationPlan =
      const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
  Set<BattleSideId> _presentationLockedCombatantSides = <BattleSideId>{};
  BattleCombatant? _displayedEnemyCombatant;
  BattleCombatant? _displayedPlayerCombatant;
  int _presentationGeneration = 0;

  BattleCommandMenuMode _menuMode = BattleCommandMenuMode.root;
  int _selectedRootIndex = 0;
  int _selectedChoiceIndex = 0;
  int _selectedPartyIndex = 0;
  int _selectedBagIndex = 0;
  int _selectedMedicineTargetIndex = 0;
  String? _bagFeedbackMessage;
  BattleBagMenuActionMedicineTarget? _selectedMedicineAction;
  BattleCommandOverlaySnapshot? _currentCommandOverlaySnapshot;
  final Map<String, String?> _bagIconAssetPathByItemId = <String, String?>{};
  final Map<String, Future<void>> _pendingBagIconPathsByItemId =
      <String, Future<void>>{};

  @visibleForTesting
  bool get commandPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get enemyHudMounted => _enemyHud != null;

  @visibleForTesting
  bool get playerHudMounted => _playerHud != null;

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
      buildBattleDecisionPromptForOverlay(_session.decisionRequest);

  @visibleForTesting
  String get currentNarrationText =>
      (_currentCommandOverlaySnapshot?.narrationLines ??
              buildBattleNarrationLinesForOverlay(_session))
          .join('\n');

  @visibleForTesting
  BattleCommandMenuMode get currentMenuMode => _menuMode;

  @visibleForTesting
  bool get isTurnPresentationActive => _animationRunner?.isActive ?? false;

  @visibleForTesting
  int get activeBattleFxCount => _fxLayer?.activeFxCount ?? 0;

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

  Future<void> waitForPendingVisualSync() async {
    await (_pendingVisualSync ?? Future<void>.value());
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
      );

  @override
  Future<void> onLoad() async {
    final overlayStopwatch = Stopwatch()..start();
    final layout = BattleSceneLayout.forViewport(
      viewportSize: Size(size.x, size.y),
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
      speciesLabel: _session.state.enemy.speciesId,
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
      speciesLabel: _session.state.player.speciesId,
      visualAssetCache: visualAssetCache,
    );
    await add(_playerCombatant!);
    playerCombatantStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.playerCombatant=${playerCombatantStopwatch.elapsedMilliseconds}ms',
    );

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
      onBarrierPulse: _handleBarrierPulseStep,
      onSwapCombatantVisual: _handleSwapCombatantVisualStep,
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
    _presentationLockedCombatantSides =
        _lockedCombatantSidesFor(animationPlan).toSet();
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
    );
    _sceneLayout = layout;

    _backdrop?.size = viewportSize.clone();
    _fxLayer?.size = viewportSize.clone();
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    if (isTurnPresentationActive) {
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
    _animationRunner?.update(dt);
    super.update(dt);
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
        speciesLabel: displayedEnemyCombatant.speciesId,
        spriteSpec: enemySpriteSpec,
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
    }
    if (_playerCombatant != null && playerSpriteSpec != null) {
      await _playerCombatant!.sync(
        speciesLabel: displayedPlayerCombatant.speciesId,
        spriteSpec: playerSpriteSpec,
      );
      if (!_isCurrentPresentationGeneration(presentationGeneration)) {
        return;
      }
    }
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
    return genderSymbol == null
        ? combatant.speciesId
        : '${combatant.speciesId} $genderSymbol';
  }

  void _syncPanelsOnly() {
    _syncMenuStateFromModel();
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
    final currentAnimationMessage = _animationRunner?.currentMessage;
    final isPresenting = _animationRunner?.isActive ?? false;
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
        buildBattleDecisionPromptForOverlay(_session.decisionRequest);
    final resolvedNarration = isPresenting
        ? const <String>[]
        : (medicineTargetNarration ??
            bagNarration ??
            partyNarration ??
            buildBattleNarrationLinesForOverlay(_session));

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

  void _publishCommandOverlaySnapshot({
    required BattleCommandMenuModel menuModel,
    required BattlePartyMenuModel partyMenuModel,
    required BattleBagMenuModel bagMenuModel,
    required BattleMedicineTargetMenuModel? medicineTargetMenuModel,
    required String prompt,
    required List<String> narrationLines,
    required bool interactionsEnabled,
  }) {
    final layout = currentSceneLayout;
    final snapshot = BattleCommandOverlaySnapshot(
      mode: _overlayModeForMenuMode(menuModel.mode),
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
    final statusLabel = combatant.isFainted
        ? 'K.O.'
        : combatant.majorStatus?.id.name.toUpperCase();
    return BattleCommandOverlayHudSnapshot(
      rect: rect,
      ownerLabel: ownerLabel,
      speciesLabel: combatant.speciesId,
      level: combatant.level,
      currentHp: combatant.currentHp,
      maxHp: combatant.maxHp,
      displayedHp:
          isHpTweenStep ? presentationStep!.fromHp : combatant.currentHp,
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
          menuModel.choiceEntries.asMap().entries.map(
                (entry) => BattleCommandOverlayEntry(
                  index: entry.key,
                  kind: menuModel.mode == BattleCommandMenuMode.continueOnly
                      ? BattleCommandOverlayEntryKind.continueAction
                      : BattleCommandOverlayEntryKind.move,
                  primaryLabel: entry.value.title,
                  secondaryLabel: entry.value.subtitle,
                  enabled: true,
                  selected: entry.key == menuModel.selectedChoiceIndex,
                  tone: _overlayEntryToneForChoiceTone(entry.value.tone),
                ),
              ),
        ),
      BattleCommandMenuMode.bag => List<BattleCommandOverlayEntry>.unmodifiable(
          bagMenuModel.entries.asMap().entries.map(
                (entry) => BattleCommandOverlayEntry(
                  index: entry.key,
                  kind: BattleCommandOverlayEntryKind.bag,
                  primaryLabel: _humanizeBattleBagItemId(entry.value.itemId),
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
                  primaryLabel: entry.value.speciesId,
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
                  primaryLabel: entry.value.speciesId,
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
    if (selectedMedicineAction == null ||
        _overlaySupportedMedicineLabel(selectedMedicineAction.itemId) == null) {
      return false;
    }

    // Lots 9-e / 9-f / 9-g gardent l'overlay strictement borné au shell de
    // ciblage :
    // - le parent runtime commit le vrai tour pour `Potion`, `Super Potion`
    //   et `Hyper Potion` ;
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
    );
  }

  BattlePartyMenuModel _currentPartyMenuModel() {
    return buildBattlePartyMenuModel(session: _session);
  }

  BattleBagMenuModel _currentBagMenuModel() {
    return buildBattleBagMenuModel(
      gameState: _gameState,
      session: _session,
    );
  }

  BattleMedicineTargetMenuModel? _currentMedicineTargetMenuModel() {
    final selectedMedicineAction = _selectedMedicineAction;
    if (selectedMedicineAction == null) {
      return null;
    }
    // Le ciblage medicine reste borné à la vérité battle courante :
    // - lineup du combat, pas party complète du GameState ;
    // - aucune heuristique par index visuel ;
    // - aucun effet item calculé ici, seulement le menu de cibles.
    return buildBattleMedicineTargetMenuModel(
      session: _session,
      itemId: selectedMedicineAction.itemId,
      categoryId: selectedMedicineAction.categoryId,
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
    if (!_session.state.isFinished || _session.state.outcome == null) {
      _outcomeBanner?.removeFromParent();
      _outcomeBanner = null;
      return;
    }

    final outcome = _session.state.outcome!;
    final bannerText = _buildOutcomeHeadline(outcome);
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
    _presentationLockedCombatantSides = <BattleSideId>{};
    _activeAnimationPlan =
        const BattleAnimationPlan(steps: <BattleAnimationStep>[]);
    final presentationGeneration = _presentationGeneration;
    _pendingVisualSync = _syncVisualState(
      presentationGeneration: presentationGeneration,
    );
    unawaited(_pendingVisualSync);
  }

  void _handleSpawnFxStep(SpawnFxStep step) {
    final fxLayer = _fxLayer;
    if (fxLayer == null) {
      return;
    }
    unawaited(
      fxLayer.playFx(
        step,
        BattleFxRuntimeContext(
          sceneSize: size.clone(),
          resolveAnchor: _resolveBattleVisualAnchor,
        ),
      ),
    );
  }

  void _handleScreenFlashStep(ScreenFlashStep step) {
    _fxLayer?.playScreenFlash(step);
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

  void _handleFaintCombatantStep(FaintCombatantStep step) {
    final combatant = _combatantForSide(step.side);
    if (combatant == null) {
      return;
    }
    unawaited(combatant.playFaint(durationSeconds: step.durationSeconds));
  }

  void _handleHudHpTweenStep(HudHpTweenStep step) {
    _hudForSide(step.side)?.animateDisplayedHp(
      fromHp: step.fromHp,
      toHp: step.toHp,
      duration: step.durationMs / 1000,
    );
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
    return _combatantForSide(side)?.currentRenderedSpriteRect;
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

    Offset headFor(Rect? rect, Rect fallbackRect) {
      final effectiveRect = rect ?? fallbackRect;
      return Offset(
        effectiveRect.center.dx,
        effectiveRect.top + (effectiveRect.height * 0.18),
      );
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

    final offset = switch (anchor) {
      BattleVisualAnchor.attackerCenter =>
        centerFor(attackerRect, attackerFallback),
      BattleVisualAnchor.attackerHead =>
        headFor(attackerRect, attackerFallback),
      BattleVisualAnchor.defenderCenter =>
        centerFor(defenderRect, defenderFallback),
      BattleVisualAnchor.defenderHead =>
        headFor(defenderRect, defenderFallback),
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
        speciesLabel: combatant.speciesId,
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
        !_activeAnimationPlan.steps
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

  int _hpTweenRevisionFor(HudHpTweenStep targetStep) {
    var revision = 0;
    for (final step in _activeAnimationPlan.steps.whereType<HudHpTweenStep>()) {
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
  return switch (entry.kind) {
    BattleBagItemKind.captureBall => 'Capture',
    BattleBagItemKind.medicine => 'Medicine',
    BattleBagItemKind.unsupported => 'Unsupported',
  };
}

String _overlayBagEntryStatusLabel(BattleBagMenuEntry entry) {
  if (entry.isSelectable) {
    return 'OK';
  }
  return switch (entry.disabledReason) {
    BattleBagMenuDisabledReason.trainerBattle => 'Trainer only',
    BattleBagMenuDisabledReason.partyFull => 'Party full',
    BattleBagMenuDisabledReason.captureUnavailable => 'Unavailable',
    BattleBagMenuDisabledReason.currentRequestDisallowsBag => 'Unavailable',
    BattleBagMenuDisabledReason.medicineNotImplemented => 'Not implemented',
    BattleBagMenuDisabledReason.unsupportedMedicine => 'Unsupported',
    BattleBagMenuDisabledReason.unsupportedItem => 'Unsupported',
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

String _humanizeBattleBagItemId(String itemId) {
  final trimmed = itemId.trim();
  if (trimmed.isEmpty) {
    return 'Item';
  }
  return trimmed
      .split('-')
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
      )
      .join(' ');
}
