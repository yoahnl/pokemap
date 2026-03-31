import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

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
class BattleOverlayComponent extends PositionComponent {
  /// Crée un overlay de combat.
  ///
  /// [session] - La session de combat courante (état + API).
  /// [viewportSize] - La taille de la viewport pour centrer le panneau.
  /// [onPlayerChoice] - Callback appelé quand le joueur fait un choix.
  BattleOverlayComponent({
    required this.session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
  }) : super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  /// La session de combat courante.
  ///
  /// Contient l'état immutable et permet de récupérer les choix disponibles.
  final BattleSession session;

  /// Callback appelé quand le joueur fait un choix.
  ///
  /// Le runtime doit appeler `session.applyChoice(choice)` pour appliquer le choix.
  final void Function(PlayerBattleChoice choice) onPlayerChoice;

  /// Référence vers le panneau principal (pour mise à jour dynamique).
  PositionComponent? _panel;

  /// Composants de texte pour les PV (pour mise à jour dynamique).
  TextComponent? _playerHpText;
  TextComponent? _enemyHpText;

  /// Composants de choix (pour mise à jour dynamique).
  final List<TextComponent> _choiceComponents = [];

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
    final choicesTitle = TextComponent(
      text: 'Que doit faire le joueur ?',
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
    _panel!.add(choicesTitle);

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
  /// À appeler après que le runtime a appliqué un choix.
  void updateState(BattleSession newSession) {
    // Mettre à jour les PV
    _playerHpText?.text = _getPlayerHpTextFromSession(newSession);
    _enemyHpText?.text = _getEnemyHpTextFromSession(newSession);

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    }
  }

  /// Affiche le résultat final du combat.
  void _showOutcome(BattleOutcome outcome) {
    final outcomeText = switch (outcome.type) {
      BattleOutcomeType.victory => 'Victoire !',
      BattleOutcomeType.defeat => 'Défaite...',
      BattleOutcomeType.runaway => 'Fuite réussie !',
    };

    final outcomeComponent = TextComponent(
      text: outcomeText,
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, _panel!.size.y / 2 + 50),
      textRenderer: TextPaint(
        style: TextStyle(
          color: outcome.isVictory ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 10,
    );
    _panel!.add(outcomeComponent);
  }

  /// Affiche les choix disponibles.
  void _renderChoices() {
    final choices = session.getAvailableChoices();
    var y = 190.0;

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final text = _getChoiceText(choice);
      final choiceComponent = TextComponent(
        text: text,
        anchor: Anchor.topLeft,
        position: Vector2(22, y),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFE5E9F2),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        priority: 3,
      );
      _choiceComponents.add(choiceComponent);
      _panel!.add(choiceComponent);
      y += 32;
    }
  }

  /// Retourne le texte à afficher pour un choix.
  String _getChoiceText(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      final move = session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  /// Retourne le titre pour la session.
  String _getTitleForSession() {
    if (session.setup.isTrainerBattle) {
      return 'Combat Dresseur';
    }
    return 'Combat Sauvage';
  }

  /// Retourne le texte des PV du joueur.
  String _getPlayerHpText() {
    return 'Joueur: ${session.state.player.currentHp}/${session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV du joueur depuis une session.
  String _getPlayerHpTextFromSession(BattleSession newSession) {
    return 'Joueur: ${newSession.state.player.currentHp}/${newSession.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  String _getEnemyHpText() {
    return 'Ennemi: ${session.state.enemy.currentHp}/${session.state.enemy.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi depuis une session.
  String _getEnemyHpTextFromSession(BattleSession newSession) {
    return 'Ennemi: ${newSession.state.enemy.currentHp}/${newSession.state.enemy.maxHp} PV';
  }
}
