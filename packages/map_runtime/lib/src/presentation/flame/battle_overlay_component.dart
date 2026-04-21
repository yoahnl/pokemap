import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_bag_menu_model.dart';
import 'battle_command_menu_model.dart';
import 'battle_command_panel_component.dart';
import 'battle_combatant_gender_resolver.dart';
import 'battle_background_resolver.dart';
import 'battle_debug_panel_component.dart';
import 'battle_party_menu_model.dart';
import 'battle_pokemon_sprite_resolver.dart';
import 'battle_visual_asset_cache.dart';
import 'battle_scene_layout.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_hud_component.dart';
import 'battle_turn_presentation.dart';

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
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (final event in turnResult.timeline) {
    switch (event) {
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
    return const <String>['Action BAG non branchée dans ce lot.'];
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
    GameState gameState = const GameState(saveId: 'battle-overlay'),
    this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
    this.spriteResolver,
    this.visualAssetCache,
    this.genderResolver,
    this.showDebugPanel = false,
  })  : _session = session,
        _gameState = gameState,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  BattleSession _session;
  GameState _gameState;

  final void Function(PlayerBattleChoice choice) onPlayerChoice;
  final BattleBackgroundSpec backgroundSpec;
  final BattlePokemonSpriteResolver? spriteResolver;
  final BattleVisualAssetCache? visualAssetCache;
  final BattleCombatantGenderResolver? genderResolver;

  /// Le debug reste volontairement opt-in.
  ///
  /// Le lot 1 doit sortir l'UI normale du mode "debug panel". On garde donc un
  /// interrupteur explicite au lieu de laisser le debug redéfinir l'apparence
  /// par défaut du combat.
  final bool showDebugPanel;

  BattleSceneBackdropComponent? _backdrop;
  BattleSceneCombatantComponent? _enemyCombatant;
  BattleSceneCombatantComponent? _playerCombatant;
  BattleSceneHudComponent? _enemyHud;
  BattleSceneHudComponent? _playerHud;
  BattleCommandPanelComponent? _commandPanel;
  BattleDebugPanelComponent? _debugPanel;
  TextComponent? _outcomeBanner;
  Future<void>? _pendingVisualSync;
  BattleSceneLayout? _sceneLayout;
  List<BattleTurnPresentationStep> _turnPresentationSteps =
      const <BattleTurnPresentationStep>[];
  int _turnPresentationIndex = 0;
  double _turnPresentationElapsed = 0;
  bool _turnPresentationEffectTriggered = false;

  BattleCommandMenuMode _menuMode = BattleCommandMenuMode.root;
  int _selectedRootIndex = 0;
  int _selectedChoiceIndex = 0;
  int _selectedPartyIndex = 0;
  int _selectedBagIndex = 0;
  String? _bagFeedbackMessage;

  static const double _presentationEffectDelaySeconds = 0.16;
  static const double _presentationImpactStepSeconds = 0.62;
  static const double _presentationMessageOnlyStepSeconds = 0.42;

  @visibleForTesting
  bool get commandPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get narrationPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get debugPanelMounted => _debugPanel != null;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => backgroundSpec.key;

  @visibleForTesting
  String get currentPromptText =>
      _commandPanel?.currentPromptText ??
      buildBattleDecisionPromptForOverlay(_session.decisionRequest);

  @visibleForTesting
  String get currentNarrationText =>
      buildBattleNarrationLinesForOverlay(_session).join('\n');

  @visibleForTesting
  BattleCommandMenuMode get currentMenuMode => _menuMode;

  @visibleForTesting
  bool get isTurnPresentationActive => _currentTurnPresentationStep != null;

  @visibleForTesting
  String get currentPlayerHudSpeciesText =>
      _hudSpeciesDisplayText(_session.state.player, isPlayerSide: true);

  @visibleForTesting
  String get currentEnemyHudSpeciesText =>
      _hudSpeciesDisplayText(_session.state.enemy, isPlayerSide: false);

  Future<void> waitForPendingVisualSync() async {
    await (_pendingVisualSync ?? Future<void>.value());
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

    final commandPanelStopwatch = Stopwatch()..start();
    _commandPanel = BattleCommandPanelComponent(
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
      layoutModeOverride: layout.commandPanelLayoutMode,
    );
    await add(_commandPanel!);
    commandPanelStopwatch.stop();
    debugPrint(
      '[perf][battle][real] overlay.commandPanel=${commandPanelStopwatch.elapsedMilliseconds}ms',
    );

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
    _pendingVisualSync = _syncVisualState();
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
    final presentationSteps = _buildTurnPresentationSteps(
      previousSession: previousSession,
      newSession: newSession,
    );
    _session = newSession;
    if (gameState != null) {
      _gameState = gameState;
    }
    _bagFeedbackMessage = null;
    _startTurnPresentation(presentationSteps);
    _normalizeMenuSelection();
    _pendingVisualSync = _syncVisualState(previousSession: previousSession);
    unawaited(_pendingVisualSync);
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
    if (menuModel.mode == BattleCommandMenuMode.bag) {
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
    final selectedChoice =
        menuModel.choiceEntries[menuModel.selectedChoiceIndex].choice;
    _handleChoiceSelected(selectedChoice);
    return true;
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
    final currentStep = _currentTurnPresentationStep;
    if (currentStep == null) {
      super.update(dt);
      return;
    }
    _turnPresentationElapsed += dt;
    if (!_turnPresentationEffectTriggered &&
        _turnPresentationElapsed >= _presentationEffectDelaySeconds) {
      _turnPresentationEffectTriggered = true;
      _applyTurnPresentationEffect(currentStep);
    }
    super.update(dt);
    if (_turnPresentationElapsed >= _durationForPresentationStep(currentStep)) {
      _advanceTurnPresentationStep();
    }
  }

  Future<void> _syncVisualState({
    BattleSession? previousSession,
  }) async {
    if (_enemyCombatant != null) {
      final enemySpriteSpec = await _resolveCombatantSpriteSpec(
        speciesId: _session.state.enemy.speciesId,
        isPlayerSide: false,
      );
      await _enemyCombatant!.sync(
        speciesLabel: _session.state.enemy.speciesId,
        spriteSpec: enemySpriteSpec,
      );
    }
    if (_playerCombatant != null) {
      final playerSpriteSpec = await _resolveCombatantSpriteSpec(
        speciesId: _session.state.player.speciesId,
        isPlayerSide: true,
      );
      await _playerCombatant!.sync(
        speciesLabel: _session.state.player.speciesId,
        spriteSpec: playerSpriteSpec,
      );
    }
    _enemyHud?.sync(
      combatant: _session.state.enemy,
      genderSymbol: _resolveCombatantGenderSymbol(
        combatant: _session.state.enemy,
        isPlayerSide: false,
      ),
      startingDisplayedHp: _presentationStartingHpForSide(
        side: BattleSideId.enemy,
        previousSession: previousSession,
      ),
    );
    _playerHud?.sync(
      combatant: _session.state.player,
      genderSymbol: _resolveCombatantGenderSymbol(
        combatant: _session.state.player,
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
    final currentPresentationStep = _currentTurnPresentationStep;
    final isPresenting = currentPresentationStep != null;
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

    _commandPanel?.sync(
      battleLabel: _titleForSession(),
      prompt: currentPresentationStep?.message ??
          bagPrompt ??
          partyPrompt ??
          buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      narrationLines: isPresenting
          ? const <String>[]
          : (bagNarration ??
              partyNarration ??
              buildBattleNarrationLinesForOverlay(_session)),
      menuModel: menuModel,
      partyMenuModel: partyMenuModel,
      bagMenuModel: bagMenuModel,
      selectedPartyIndex: _selectedPartyIndex,
      selectedBagIndex: _selectedBagIndex,
      allowEmptyNarrationBody: isPresenting,
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
    _bagFeedbackMessage =
        'L’utilisation des objets sera branchée au prochain lot.';
    _syncPanelsOnly();
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

  BattleCommandMenuMode _effectiveMenuMode() {
    final partyMenuModel = _currentPartyMenuModel();
    if (partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement &&
        partyMenuModel.hasSelectableEntries) {
      return BattleCommandMenuMode.pokemon;
    }
    return _menuMode;
  }

  void _normalizeMenuSelection() {
    final previousMenuMode = _menuMode;
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
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
  }

  void _syncMenuStateFromModel() {
    final previousMenuMode = _menuMode;
    final menuModel = _currentMenuModel();
    final partyMenuModel = _currentPartyMenuModel();
    final bagMenuModel = _currentBagMenuModel();
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

  List<BattleTurnPresentationStep> _buildTurnPresentationSteps({
    required BattleSession previousSession,
    required BattleSession newSession,
  }) {
    final currentTurn = newSession.state.currentTurn;
    if (currentTurn == null) {
      return const <BattleTurnPresentationStep>[];
    }
    if (!_isSameVisibleCombatant(
          previousSession.state.player,
          newSession.state.player,
        ) ||
        !_isSameVisibleCombatant(
          previousSession.state.enemy,
          newSession.state.enemy,
        )) {
      return const <BattleTurnPresentationStep>[];
    }
    return buildBattleTurnPresentationSteps(
      playerBefore: previousSession.state.player,
      enemyBefore: previousSession.state.enemy,
      turnResult: currentTurn,
    );
  }

  void _startTurnPresentation(List<BattleTurnPresentationStep> steps) {
    if (steps.isEmpty) {
      _turnPresentationSteps = const <BattleTurnPresentationStep>[];
      _turnPresentationIndex = 0;
      _turnPresentationElapsed = 0;
      _turnPresentationEffectTriggered = false;
      return;
    }
    _turnPresentationSteps = List<BattleTurnPresentationStep>.unmodifiable(
      steps,
    );
    _turnPresentationIndex = 0;
    _turnPresentationElapsed = 0;
    _turnPresentationEffectTriggered = false;
  }

  BattleTurnPresentationStep? get _currentTurnPresentationStep =>
      _turnPresentationIndex >= _turnPresentationSteps.length
          ? null
          : _turnPresentationSteps[_turnPresentationIndex];

  double _durationForPresentationStep(BattleTurnPresentationStep step) {
    return step.animatesDamage
        ? _presentationImpactStepSeconds
        : _presentationMessageOnlyStepSeconds;
  }

  void _advanceTurnPresentationStep() {
    _turnPresentationIndex += 1;
    _turnPresentationElapsed = 0;
    _turnPresentationEffectTriggered = false;
    if (_turnPresentationIndex >= _turnPresentationSteps.length) {
      _turnPresentationSteps = const <BattleTurnPresentationStep>[];
      _turnPresentationIndex = 0;
    }
    _syncPanelsOnly();
  }

  void _applyTurnPresentationEffect(BattleTurnPresentationStep step) {
    final targetSide = step.flashTargetSide;
    final hpFrom = step.hpFrom;
    final hpTo = step.hpTo;
    if (targetSide == null || hpFrom == null || hpTo == null) {
      return;
    }
    final isPlayerSide = targetSide == BattleSideId.player;
    final combatant = isPlayerSide ? _playerCombatant : _enemyCombatant;
    final hud = isPlayerSide ? _playerHud : _enemyHud;
    combatant?.triggerHitFlash();
    hud?.animateDisplayedHp(fromHp: hpFrom, toHp: hpTo);
  }

  int? _presentationStartingHpForSide({
    required BattleSideId side,
    required BattleSession? previousSession,
  }) {
    if (previousSession == null ||
        !isTurnPresentationActive ||
        !_turnPresentationSteps.any((step) => step.flashTargetSide == side)) {
      return null;
    }
    final previousCombatant = side == BattleSideId.player
        ? previousSession.state.player
        : previousSession.state.enemy;
    final currentCombatant = side == BattleSideId.player
        ? _session.state.player
        : _session.state.enemy;
    if (!_isSameVisibleCombatant(previousCombatant, currentCombatant)) {
      return null;
    }
    return previousCombatant.currentHp;
  }

  bool _isSameVisibleCombatant(
    BattleCombatant current,
    BattleCombatant next,
  ) {
    return current.lineupIndex == next.lineupIndex &&
        current.speciesId == next.speciesId;
  }
}
