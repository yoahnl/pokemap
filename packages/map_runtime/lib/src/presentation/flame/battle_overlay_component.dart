import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Phase C utilise cette petite fonction pure pour une raison concrète :
/// - l'overlay doit désormais afficher le *type* de requête demandé par le
///   moteur, pas déduire ce type depuis une liste plate de choix ;
/// - garder ce formatage dans un helper pur permet aussi de le verrouiller en
///   test sans devoir piloter tout le composant Flame ;
/// - on reste très loin d'un système de présentation générique.
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
/// BE10A centralise ici la restitution textuelle pour une raison précise :
/// - l'overlay ne doit plus réinventer l'ordre du tour en triant des buckets ;
/// - la vraie source de vérité est désormais `BattleTurnResult.timeline` ;
/// - cette fonction garde donc la surface runtime alignée sur la chronologie
///   réellement produite par le moteur battle.
///
/// Garde-fou volontaire :
/// - si un `BattleTurnResult` porte encore des buckets non vides sans
///   chronologie ordonnée, on échoue explicitement ;
/// - mieux vaut un seam bruyant qu'une UI qui raconte un ordre faux.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.stealthRockEvents.isNotEmpty ||
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
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
    }
  }

  return List<String>.unmodifiable(lines);
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

/// Composant UI d'overlay de combat.
///
/// Affiche l'état courant du combat et permet au joueur de choisir une action.
/// Ne contient AUCUNE logique métier de combat — pure UI.
///
/// La logique métier est dans `map_battle` (BattleSession).
/// Ce composant se contente de :
/// - Afficher les PV des combattants
/// - Afficher les choix disponibles
/// - Notifier le runtime du choix du joueur via [onPlayerChoice]
///
/// **Interaction** : L'utilisateur peut cliquer sur un choix pour le sélectionner.
/// Le clic appelle [onPlayerChoice] avec le choix correspondant.
///
/// **IMPORTANT** : Ce composant stocke une référence mutable vers la session
/// courante. Quand le runtime appelle [updateState()], la session interne
/// est mise à jour pour refléter le nouvel état. Toutes les méthodes d'affichage
/// lisent [session] qui est donc toujours à jour.
class BattleOverlayComponent extends PositionComponent with TapCallbacks {
  /// Crée un overlay de combat.
  ///
  /// [session] - La session de combat courante (état + API).
  /// [viewportSize] - La taille de la viewport pour centrer le panneau.
  /// [onPlayerChoice] - Callback appelé quand le joueur fait un choix.
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  /// La session de combat courante.
  ///
  /// **Mutable** : mise à jour par [updateState()] pour refléter le nouvel état.
  /// Toutes les méthodes d'affichage lisent cette propriété, donc l'UI est
  /// toujours synchronisée avec l'état réel du combat.
  BattleSession _session;

  /// Callback appelé quand le joueur fait un choix.
  ///
  /// Le runtime doit appeler `session.applyChoice(choice)` pour appliquer le choix.
  final void Function(PlayerBattleChoice choice) onPlayerChoice;

  /// Référence vers le panneau principal (pour mise à jour dynamique).
  PositionComponent? _panel;

  /// Composants de texte pour les PV (pour mise à jour dynamique).
  TextComponent? _playerHpText;
  TextComponent? _enemyHpText;
  TextComponent? _choicesTitleText;

  /// Composant de texte pour afficher le résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts.
  TextComponent? _turnResultText;

  /// Composants de choix (pour mise à jour dynamique).
  /// Chaque composant est associé à un index de choix.
  final List<_ChoiceComponent> _choiceComponents = [];

  /// Index du choix actuellement sélectionné.
  ///
  /// Utilisé pour la navigation clavier (↑/↓) et pour afficher visuellement
  /// le choix sélectionné avec un style différent.
  ///
  /// Invariant : `_selectedIndex` est toujours entre 0 et `_choiceComponents.length - 1`.
  int _selectedIndex = 0;

  /// Composant de surbrillance pour le choix sélectionné.
  ///
  /// Affiché derrière le choix sélectionné pour le mettre en évidence visuellement.
  RectangleComponent? _selectionHighlight;

  @override
  Future<void> onLoad() async {
    // Fond sombre
    final bg = RectangleComponent(
      size: size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xF20B1020),
      priority: 0,
    );
    add(bg);

    // Panneau principal
    final panelWidth = (size.x - 80).clamp(240.0, 760.0);
    final panelHeight = (size.y - 120).clamp(220.0, 520.0);
    _panel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2((size.x - panelWidth) / 2, (size.y - panelHeight) / 2),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xE81A223B),
      priority: 1,
    );
    add(_panel!);

    // Bordure du panneau
    final panelBorder = RectangleComponent(
      size: _panel!.size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      priority: 2,
    );
    _panel!.add(panelBorder);

    // Titre
    final title = TextComponent(
      text: _getTitleForSession(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 3,
    );
    _panel!.add(title);

    // PV du joueur
    _playerHpText = TextComponent(
      text: _getPlayerHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 72),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_playerHpText!);

    // PV de l'ennemi
    _enemyHpText = TextComponent(
      text: _getEnemyHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_enemyHpText!);

    // Titre des choix
    _choicesTitleText = TextComponent(
      text: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      anchor: Anchor.topLeft,
      position: Vector2(22, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_choicesTitleText!);

    // Choix disponibles
    _renderChoices();

    // Astuce
    final hint = TextComponent(
      text: 'Utilisez les flèches ↑/↓ et E pour choisir',
      anchor: Anchor.bottomLeft,
      position: Vector2(22, panelHeight - 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(hint);
  }

  /// Met à jour l'affichage avec un nouvel état de session.
  ///
  /// [newSession] - La nouvelle session avec l'état mis à jour.
  ///
  /// **IMPORTANT** : Cette méthode met à jour [_session] pour que toutes les
  /// méthodes d'affichage (_getChoiceText, etc.) lisent le bon état.
  ///
  /// Cette méthode gère aussi la cohérence de la sélection :
  /// - Si le combat est fini, la sélection est désactivée
  /// - Si la sélection est hors bornes (moins de choix), elle est clampée
  /// - Si un tour est en cours, affiche le résultat du tour (attaques + dégâts)
  void updateState(BattleSession newSession) {
    // Mettre à jour la session interne — CRITIQUE pour la cohérence
    _session = newSession;

    // Mettre à jour les PV
    _playerHpText?.text = _getPlayerHpText();
    _enemyHpText?.text = _getEnemyHpText();
    _choicesTitleText?.text =
        buildBattleDecisionPromptForOverlay(newSession.decisionRequest);

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.decisionRequest.allowedChoices;
      if (_selectedIndex >= choices.length) {
        _selectedIndex = choices.length - 1;
      }
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      // Re-render pour mettre à jour les choix et la surbrillance
      _renderChoices();
    }
  }

  /// Met à jour l'affichage du résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts infligés.
  void _updateTurnResult() {
    // Supprimer l'ancien texte de résultat du tour
    _turnResultText?.removeFromParent();
    _turnResultText = null;

    final turnResult = _session.state.currentTurn;
    if (turnResult == null) {
      return;
    }

    final lines = buildBattleTurnLinesForOverlay(turnResult);

    if (lines.isEmpty) {
      return;
    }

    // Afficher le résultat du tour
    _turnResultText = TextComponent(
      text: lines.join('\n'),
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, 130),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_turnResultText!);
  }

  /// Affiche le résultat final du combat.
  void _showOutcome(BattleOutcome outcome) {
    final outcomeText = switch (outcome.type) {
      BattleOutcomeType.victory => 'Victoire !',
      BattleOutcomeType.defeat => 'Défaite...',
      BattleOutcomeType.runaway => 'Fuite réussie !',
      BattleOutcomeType.captured => 'Capture réussie !',
    };

    final outcomeComponent = TextComponent(
      text: outcomeText,
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, _panel!.size.y / 2 + 50),
      textRenderer: TextPaint(
        style: TextStyle(
          color: outcome.isVictory || outcome.isCaptured
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 10,
    );
    _panel!.add(outcomeComponent);
  }

  /// Affiche les choix disponibles.
  ///
  /// Cette méthode :
  /// 1. Récupère les choix disponibles depuis [_session]
  /// 2. Crée un composant visuel pour chaque choix
  /// 3. Ajoute un composant de surbrillance pour le choix sélectionné
  /// 4. Met à jour [_selectionHighlight] pour le rendu visuel
  void _renderChoices() {
    // Lit [_session] qui est toujours à jour grâce à updateState()
    final request = _session.decisionRequest;
    final choices = request.allowedChoices;
    var y = 190.0;

    // Nettoyer les anciens composants de choix
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    // Nettoyer l'ancienne surbrillance
    _selectionHighlight?.removeFromParent();
    _selectionHighlight = null;

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final text = _getChoiceText(request, choice);
      final choiceComponent = _ChoiceComponent(
        choice: choice,
        text: text,
        position: Vector2(22, y),
      );
      _choiceComponents.add(choiceComponent);
      _panel!.add(choiceComponent);

      // Créer la surbrillance pour le choix sélectionné
      if (i == _selectedIndex) {
        _selectionHighlight = RectangleComponent(
          size: Vector2(280, 28),
          position: Vector2(24, y + 2),
          anchor: Anchor.topLeft,
          paint: Paint()
            ..color = const Color(0x40FFFFFF) // Blanc semi-transparent
            ..style = PaintingStyle.fill,
          priority: 2,
        );
        _panel!.add(_selectionHighlight!);
      }

      y += 32;
    }
  }

  /// Retourne le texte à afficher pour un choix.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getChoiceText(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final actionLabel = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '↔ $actionLabel ${reserve.speciesId} '
          '(${reserve.currentHp}/${reserve.maxHp} PV)';
    } else if (choice is PlayerBattleChoiceContinue) {
      // Phase C cesse ici d'inférer le sens du tour forcé depuis l'état
      // volatile brut : la vraie source de vérité est désormais la requête.
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return 'Continuer (libérer la charge)';
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return 'Continuer (recharge)';
        }
      }
      return 'Continuer';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  /// Retourne le titre pour la session.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getTitleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat Dresseur';
    }
    return 'Combat Sauvage';
  }

  /// Retourne le texte des PV du joueur.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getPlayerHpText() {
    return 'Joueur (${_session.state.player.speciesId}): '
        '${_session.state.player.currentHp}/${_session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getEnemyHpText() {
    return 'Ennemi (${_session.state.enemy.speciesId}): '
        '${_session.state.enemy.currentHp}/${_session.state.enemy.maxHp} PV';
  }

  /// Déplace la sélection vers le haut (choix précédent).
  ///
  /// Si la sélection est déjà au premier choix, reste au premier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      debugPrint('[battle-overlay] moveSelectionUp: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionUp: already at first choice (index=$_selectedIndex)');
    return false;
  }

  /// Déplace la sélection vers le bas (choix suivant).
  ///
  /// Si la sélection est déjà au dernier choix, reste au dernier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionDown() {
    if (_selectedIndex < _choiceComponents.length - 1) {
      _selectedIndex++;
      debugPrint(
          '[battle-overlay] moveSelectionDown: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionDown: already at last choice (index=$_selectedIndex, max=${_choiceComponents.length - 1})');
    return false;
  }

  /// Retourne le choix actuellement sélectionné.
  ///
  /// Retourne null si aucun choix n'est disponible.
  PlayerBattleChoice? getSelectedChoice() {
    if (_choiceComponents.isEmpty ||
        _selectedIndex < 0 ||
        _selectedIndex >= _choiceComponents.length) {
      return null;
    }
    return _choiceComponents[_selectedIndex].choice;
  }

  /// Valide le choix actuellement sélectionné.
  ///
  /// Appelle [onPlayerChoice] avec le choix sélectionné.
  ///
  /// Retourne true si un choix a été validé, false si aucun choix n'est disponible.
  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice != null) {
      debugPrint(
          '[battle-overlay] validateSelectedChoice: choice=$selectedChoice');
      onPlayerChoice(selectedChoice);
      return true;
    }
    debugPrint('[battle-overlay] validateSelectedChoice: no choice selected');
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Vérifier si un choix a été cliqué
    final tapPos = event.localPosition;
    for (var i = 0; i < _choiceComponents.length; i++) {
      final choiceComponent = _choiceComponents[i];
      if (choiceComponent.containsPoint(tapPos)) {
        // Mettre à jour la sélection visuelle
        _selectedIndex = i;
        _renderChoices();

        // Choix cliqué — notifier le runtime
        onPlayerChoice(choiceComponent.choice);
        return;
      }
    }
  }
}

/// Composant de choix avec référence au choix associé.
///
/// Permet de détecter les clics sur un choix spécifique et de notifier
/// le runtime via [onPlayerChoice].
class _ChoiceComponent extends PositionComponent {
  _ChoiceComponent({
    required this.choice,
    required String text,
    required Vector2 position,
  }) : super(
          size: Vector2(300, 32),
          position: position,
          anchor: Anchor.topLeft,
        ) {
    // Ajouter le texte du choix
    add(TextComponent(
      text: text,
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  /// Le choix associé à ce composant.
  final PlayerBattleChoice choice;

  /// Vérifie si un point est dans les bounds de ce composant.
  @override
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }
}
