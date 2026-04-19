import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_command_panel_component.dart';
import 'battle_debug_panel_component.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_hud_component.dart';

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
    this.showDebugPanel = false,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  BattleSession _session;

  final void Function(PlayerBattleChoice choice) onPlayerChoice;

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

  int _selectedIndex = 0;

  @visibleForTesting
  bool get commandPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get narrationPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get debugPanelMounted => _debugPanel != null;

  @visibleForTesting
  String get currentPromptText =>
      buildBattleDecisionPromptForOverlay(_session.decisionRequest);

  @visibleForTesting
  String get currentNarrationText =>
      buildBattleNarrationLinesForOverlay(_session).join('\n');

  @override
  Future<void> onLoad() async {
    // Le layout du lot 1 reste volontairement local et concret :
    // - on assume une scène plein écran ;
    // - on place des zones stables joueur/ennemi ;
    // - on garde un seul panneau bas pour narration + commandes ;
    // - on évite volontairement un système de layout générique.
    const padding = 28.0;
    final commandPanelHeight = (size.y * 0.31).clamp(188.0, 232.0).toDouble();
    final commandPanelY = size.y - commandPanelHeight - padding;

    final enemyHudSize = Vector2(
      (size.x * 0.31).clamp(240.0, 320.0).toDouble(),
      98,
    );
    final playerHudSize = Vector2(
      (size.x * 0.34).clamp(250.0, 340.0).toDouble(),
      106,
    );

    final enemyCombatantSize = Vector2(
      (size.x * 0.27).clamp(220.0, 320.0).toDouble(),
      (size.y * 0.28).clamp(140.0, 190.0).toDouble(),
    );
    final playerCombatantSize = Vector2(
      (size.x * 0.31).clamp(250.0, 360.0).toDouble(),
      (size.y * 0.32).clamp(170.0, 230.0).toDouble(),
    );

    _backdrop = BattleSceneBackdropComponent(size: size.clone());
    await add(_backdrop!);

    _enemyCombatant = BattleSceneCombatantComponent(
      position: Vector2(size.x - enemyCombatantSize.x - 88, 82),
      size: enemyCombatantSize,
      isPlayerSide: false,
      speciesLabel: _session.state.enemy.speciesId,
    );
    await add(_enemyCombatant!);

    _playerCombatant = BattleSceneCombatantComponent(
      position: Vector2(72, commandPanelY - playerCombatantSize.y - 26),
      size: playerCombatantSize,
      isPlayerSide: true,
      speciesLabel: _session.state.player.speciesId,
    );
    await add(_playerCombatant!);

    _enemyHud = BattleSceneHudComponent(
      position: Vector2(padding, padding),
      size: enemyHudSize,
      ownerLabel: 'ENNEMI',
      combatant: _session.state.enemy,
      isPlayerSide: false,
    );
    await add(_enemyHud!);

    _playerHud = BattleSceneHudComponent(
      position: Vector2(
        size.x - playerHudSize.x - padding,
        commandPanelY - playerHudSize.y - 18,
      ),
      size: playerHudSize,
      ownerLabel: 'JOUEUR',
      combatant: _session.state.player,
      isPlayerSide: true,
    );
    await add(_playerHud!);

    _commandPanel = BattleCommandPanelComponent(
      position: Vector2(padding, commandPanelY),
      size: Vector2(size.x - (padding * 2), commandPanelHeight),
      onChoiceSelected: onPlayerChoice,
    );
    await add(_commandPanel!);

    if (showDebugPanel) {
      _debugPanel = BattleDebugPanelComponent(
        position: Vector2(size.x - 248, 32),
        size: Vector2(216, 148),
      );
      await add(_debugPanel!);
    }

    _syncVisualState();
  }

  /// Met à jour l'overlay avec une nouvelle session immutable.
  ///
  /// Invariants runtime préservés :
  /// - `BattleSession` reste la seule source de vérité d'état ;
  /// - `BattleDecisionRequest` reste la seule source de vérité des commandes ;
  /// - `BattleTurnResult.timeline` reste la seule source de vérité narrative.
  void updateState(BattleSession newSession) {
    _session = newSession;
    _clampSelectionToCurrentChoices();
    _syncVisualState();
  }

  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      _syncPanelsOnly();
      return true;
    }
    return false;
  }

  bool moveSelectionDown() {
    final choices = _session.decisionRequest.allowedChoices;
    if (_selectedIndex < choices.length - 1) {
      _selectedIndex++;
      _syncPanelsOnly();
      return true;
    }
    return false;
  }

  PlayerBattleChoice? getSelectedChoice() {
    final choices = _session.decisionRequest.allowedChoices;
    if (choices.isEmpty) {
      return null;
    }
    if (_selectedIndex < 0 || _selectedIndex >= choices.length) {
      return null;
    }
    return choices[_selectedIndex];
  }

  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice == null) {
      return false;
    }
    onPlayerChoice(selectedChoice);
    return true;
  }

  void _syncVisualState() {
    _enemyCombatant?.sync(speciesLabel: _session.state.enemy.speciesId);
    _playerCombatant?.sync(speciesLabel: _session.state.player.speciesId);
    _enemyHud?.sync(combatant: _session.state.enemy);
    _playerHud?.sync(combatant: _session.state.player);
    _syncPanelsOnly();
    _syncOutcomeBanner();
  }

  void _syncPanelsOnly() {
    _clampSelectionToCurrentChoices();

    _commandPanel?.sync(
      battleLabel: _titleForSession(),
      prompt: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      narrationLines: buildBattleNarrationLinesForOverlay(_session),
      choices: _buildChoiceEntries(_session.decisionRequest),
      selectedIndex: _selectedIndex,
    );

    _debugPanel?.sync(
      lines: buildBattleDebugLinesForOverlay(
        _session,
        selectedIndex: _selectedIndex,
      ),
    );
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

  List<BattleCommandChoiceEntry> _buildChoiceEntries(
    BattleDecisionRequest request,
  ) {
    return List<BattleCommandChoiceEntry>.unmodifiable(
      request.allowedChoices.map(
        (choice) => BattleCommandChoiceEntry(
          choice: choice,
          label: _labelForChoice(request, choice),
        ),
      ),
    );
  }

  String _labelForChoice(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      final move = _session.state.player.moves[choice.moveIndex];
      final moveKind = switch (move.category) {
        BattleMoveCategory.physical => 'Physique',
        BattleMoveCategory.special => 'Speciale',
        BattleMoveCategory.status => 'Statut',
        null => 'Technique',
      };
      final powerLabel = move.power > 0 ? ' · Puissance ${move.power}' : '';
      return '${move.name} · $moveKind$powerLabel';
    }

    if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final verb = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '$verb ${reserve.speciesId} · ${reserve.currentHp}/${reserve.maxHp} PV';
    }

    if (choice is PlayerBattleChoiceContinue) {
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return 'Continuer · liberer la charge';
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return 'Continuer · tour de recharge';
        }
      }
      return 'Continuer';
    }

    if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    }

    if (choice is PlayerBattleChoiceRun) {
      return 'Fuir';
    }

    return 'Action inconnue';
  }

  void _clampSelectionToCurrentChoices() {
    final choices = _session.decisionRequest.allowedChoices;
    if (choices.isEmpty) {
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= choices.length) {
      _selectedIndex = choices.length - 1;
    }
    if (_selectedIndex < 0) {
      _selectedIndex = 0;
    }
  }

  String _titleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat dresseur';
    }
    return 'Combat sauvage';
  }
}
