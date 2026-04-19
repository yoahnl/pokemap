import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Entrée de choix rendue dans la command box.
///
/// Cette structure reste purement présentative :
/// - la vérité des choix vient toujours de `BattleDecisionRequest.allowedChoices` ;
/// - la command box reçoit des labels déjà calculés par l'overlay racine ;
/// - elle ne recrée donc aucune logique parallèle de choix.
class BattleCommandChoiceEntry {
  const BattleCommandChoiceEntry({
    required this.choice,
    required this.label,
  });

  final PlayerBattleChoice choice;
  final String label;
}

/// Panneau bas de commandes et de narration.
///
/// Ce composant sert au lot 1 pour sortir du panneau monolithique :
/// - la narration observable vit à gauche ;
/// - la zone de commandes vit à droite ;
/// - le routage final de choix reste dans `BattleOverlayComponent`.
class BattleCommandPanelComponent extends PositionComponent {
  BattleCommandPanelComponent({
    required Vector2 position,
    required Vector2 size,
    required this.onChoiceSelected,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 30,
        );

  final void Function(PlayerBattleChoice choice) onChoiceSelected;

  PositionComponent? _narrationPanel;
  PositionComponent? _commandsPanel;
  TextComponent? _battleLabelText;
  TextComponent? _narrationTitleText;
  TextComponent? _narrationBodyText;
  TextComponent? _promptText;
  TextComponent? _hintText;
  final List<_BattleChoiceChipComponent> _choiceComponents =
      <_BattleChoiceChipComponent>[];

  bool get narrationPanelMounted => _narrationPanel != null;
  bool get commandPanelMounted => _commandsPanel != null;
  String get currentPromptText => _promptText?.text ?? '';
  String get currentNarrationText => _narrationBodyText?.text ?? '';

  @override
  Future<void> onLoad() async {
    final narrationWidth = size.x * 0.56;
    final spacing = 18.0;
    final commandsWidth = size.x - narrationWidth - spacing;

    _narrationPanel = PositionComponent(
      position: Vector2(18, 18),
      size: Vector2(narrationWidth - 18, size.y - 36),
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_narrationPanel!);

    _commandsPanel = PositionComponent(
      position: Vector2(narrationWidth + spacing, 18),
      size: Vector2(commandsWidth - 18, size.y - 36),
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_commandsPanel!);

    _battleLabelText = TextComponent(
      text: '',
      position: Vector2(16, 14),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xB3D6DDED),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
    await _narrationPanel!.add(_battleLabelText!);

    _narrationTitleText = TextComponent(
      text: 'Narration',
      position: Vector2(16, 32),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F7FB),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await _narrationPanel!.add(_narrationTitleText!);

    _narrationBodyText = TextComponent(
      text: '',
      position: Vector2(16, 62),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE4EAF6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
    await _narrationPanel!.add(_narrationBodyText!);

    _promptText = TextComponent(
      text: '',
      position: Vector2(16, 14),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F7FB),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await _commandsPanel!.add(_promptText!);

    _hintText = TextComponent(
      text: '↑/↓ pour naviguer · Entrée ou clic pour valider',
      position: Vector2(16, _commandsPanel!.size.y - 18),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xB3D6DDED),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    await _commandsPanel!.add(_hintText!);
  }

  void sync({
    required String battleLabel,
    required String prompt,
    required List<String> narrationLines,
    required List<BattleCommandChoiceEntry> choices,
    required int selectedIndex,
  }) {
    _battleLabelText?.text = battleLabel;
    _promptText?.text = prompt;

    final clippedNarration = narrationLines.isEmpty
        ? const <String>['Le combat attend la prochaine action du joueur.']
        : narrationLines.take(4).toList(growable: false);
    _narrationBodyText?.text = clippedNarration.join('\n');

    _renderChoices(
      choices: choices,
      selectedIndex: selectedIndex,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rootRect = Offset.zero & Size(size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rootRect, const Radius.circular(26)),
      Paint()..color = const Color(0xE30C1524),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rootRect.deflate(1),
        const Radius.circular(25),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x52FFFFFF),
    );

    if (_narrationPanel != null) {
      final narrationRect = Rect.fromLTWH(
        _narrationPanel!.position.x,
        _narrationPanel!.position.y,
        _narrationPanel!.size.x,
        _narrationPanel!.size.y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(narrationRect, const Radius.circular(22)),
        Paint()..color = const Color(0xCC15233A),
      );
    }

    if (_commandsPanel != null) {
      final commandsRect = Rect.fromLTWH(
        _commandsPanel!.position.x,
        _commandsPanel!.position.y,
        _commandsPanel!.size.x,
        _commandsPanel!.size.y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(22)),
        Paint()..color = const Color(0xCC1A2032),
      );
    }
  }

  void _renderChoices({
    required List<BattleCommandChoiceEntry> choices,
    required int selectedIndex,
  }) {
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    if (_commandsPanel == null) {
      return;
    }

    if (choices.isEmpty) {
      final emptyState = _BattleChoiceChipComponent(
        entry: const BattleCommandChoiceEntry(
          choice: PlayerBattleChoiceContinue(),
          label: 'Aucune commande interactive disponible',
        ),
        position: Vector2(16, 52),
        size: Vector2(_commandsPanel!.size.x - 32, 44),
        isSelected: false,
        isInteractive: false,
        onPressed: (_) {},
      );
      _choiceComponents.add(emptyState);
      _commandsPanel!.add(emptyState);
      return;
    }

    var y = 52.0;
    for (var i = 0; i < choices.length; i++) {
      final chip = _BattleChoiceChipComponent(
        entry: choices[i],
        position: Vector2(16, y),
        size: Vector2(_commandsPanel!.size.x - 32, 44),
        isSelected: i == selectedIndex,
        isInteractive: true,
        onPressed: onChoiceSelected,
      );
      _choiceComponents.add(chip);
      _commandsPanel!.add(chip);
      y += 52;
    }
  }
}

class _BattleChoiceChipComponent extends PositionComponent with TapCallbacks {
  _BattleChoiceChipComponent({
    required this.entry,
    required Vector2 position,
    required Vector2 size,
    required this.isSelected,
    required this.isInteractive,
    required this.onPressed,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 32,
        );

  final BattleCommandChoiceEntry entry;
  final bool isSelected;
  final bool isInteractive;
  final void Function(PlayerBattleChoice choice) onPressed;

  TextComponent? _labelText;

  @override
  Future<void> onLoad() async {
    _labelText = TextComponent(
      text: entry.label,
      position: Vector2(14, 12),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color:
              isInteractive ? const Color(0xFFF5F7FB) : const Color(0x88F5F7FB),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 33,
    );
    await add(_labelText!);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.x <= size.x &&
        point.y >= 0 &&
        point.y <= size.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isInteractive) {
      return;
    }
    onPressed(entry.choice);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..color =
            isSelected ? const Color(0xFF4B6FB1) : const Color(0xCC22314B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(1),
        const Radius.circular(15),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color =
            isSelected ? const Color(0xFFDCE9FF) : const Color(0x44FFFFFF),
    );
  }
}
