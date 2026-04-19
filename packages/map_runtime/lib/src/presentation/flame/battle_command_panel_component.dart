import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Ton visuel minimal pour les commandes rendues dans la battle box.
///
/// Garde-fous de périmètre :
/// - on ne crée pas un système de thème global ;
/// - on encode uniquement quelques accents utiles pour distinguer les vraies
///   familles de choix déjà supportées par le moteur ;
/// - toute décision reste adossée à `BattleDecisionRequest.allowedChoices`.
enum BattleCommandChoiceTone {
  attack,
  special,
  support,
  switching,
  neutral,
}

/// Entrée de choix rendue dans la command box.
///
/// Cette structure reste strictement présentative :
/// - la vérité des choix vient toujours de `BattleDecisionRequest` ;
/// - le runtime ne crée ici ni faux menu, ni fausse famille d'action ;
/// - le découpage `title/subtitle/tone` ne sert qu'à mieux restituer un choix
///   déjà légal dans une UI plus proche d'une vraie battle box.
class BattleCommandChoiceEntry {
  const BattleCommandChoiceEntry({
    required this.choice,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final PlayerBattleChoice choice;
  final String title;
  final String subtitle;
  final BattleCommandChoiceTone tone;
}

/// Panneau bas de commandes et de narration.
///
/// Dans le lot 4b, on rapproche la composition de l'esprit du gif de
/// référence :
/// - une vraie narration lisible à gauche ;
/// - une grille de commandes lisible à droite quand c'est honnête ;
/// - aucun bouton factice de type `Bag` ou `Pokemon` si le moteur ne les
///   expose pas réellement.
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

  PositionComponent? _promptPanel;
  PositionComponent? _commandsPanel;
  TextComponent? _battleLabelText;
  TextComponent? _promptText;
  TextComponent? _narrationBodyText;
  TextComponent? _commandTitleText;
  TextComponent? _hintText;
  final List<_BattleChoiceCardComponent> _choiceComponents =
      <_BattleChoiceCardComponent>[];

  bool get narrationPanelMounted => _promptPanel != null;
  bool get commandPanelMounted => _commandsPanel != null;
  String get currentPromptText => _promptText?.text ?? '';
  String get currentNarrationText => _narrationBodyText?.text ?? '';

  @override
  Future<void> onLoad() async {
    final promptWidth = (size.x * 0.38).clamp(250.0, 350.0).toDouble();
    const spacing = 16.0;
    final commandsWidth = size.x - promptWidth - spacing;

    _promptPanel = PositionComponent(
      position: Vector2(16, 14),
      size: Vector2(promptWidth - 8, size.y - 28),
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_promptPanel!);

    _commandsPanel = PositionComponent(
      position: Vector2(promptWidth + spacing, 14),
      size: Vector2(commandsWidth - 8, size.y - 28),
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
          color: Color(0xCC55657D),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
    await _promptPanel!.add(_battleLabelText!);

    _promptText = TextComponent(
      text: '',
      position: Vector2(16, 34),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF1D2634),
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
    await _promptPanel!.add(_promptText!);

    _narrationBodyText = TextComponent(
      text: '',
      position: Vector2(16, 104),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF435064),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
    await _promptPanel!.add(_narrationBodyText!);

    _commandTitleText = TextComponent(
      text: 'COMMANDES',
      position: Vector2(16, 16),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xCCEAEEF8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
    await _commandsPanel!.add(_commandTitleText!);

    _hintText = TextComponent(
      text: 'Fleches / clic / entree',
      position: Vector2(_commandsPanel!.size.x - 16, _commandsPanel!.size.y - 14),
      anchor: Anchor.bottomRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0x99E8EEF8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
    _battleLabelText?.text = battleLabel.toUpperCase();
    _promptText?.text = prompt;

    final clippedNarration = narrationLines.isEmpty
        ? const <String>['Le combat attend la prochaine action.']
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
      RRect.fromRectAndRadius(rootRect, const Radius.circular(28)),
      Paint()..color = const Color(0xE7EEF2FB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rootRect, const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF53637B),
    );

    final shadowRect = Rect.fromLTWH(14, size.y - 18, size.x - 28, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(999)),
      Paint()..color = const Color(0x220E1520),
    );

    if (_promptPanel != null) {
      final promptRect = Rect.fromLTWH(
        _promptPanel!.position.x,
        _promptPanel!.position.y,
        _promptPanel!.size.x,
        _promptPanel!.size.y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptRect, const Radius.circular(22)),
        Paint()..color = const Color(0xFFF6F1EA),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptRect, const Radius.circular(22)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFD5CCBD),
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
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(24)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xFF253449),
              Color(0xFF1D2738),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(commandsRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(24)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0x3DFFFFFF),
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

    const contentTop = 40.0;
    final availableWidth = _commandsPanel!.size.x - 32;
    final availableHeight = _commandsPanel!.size.y - 68;

    if (choices.isEmpty) {
      final emptyState = _BattleChoiceCardComponent(
        entry: const BattleCommandChoiceEntry(
          choice: PlayerBattleChoiceContinue(),
          title: 'Aucune commande',
          subtitle: 'Le moteur ne propose actuellement aucun choix interactif.',
          tone: BattleCommandChoiceTone.neutral,
        ),
        position: Vector2(16, contentTop),
        size: Vector2(availableWidth, 72),
        isSelected: false,
        isInteractive: false,
        onPressed: (_) {},
      );
      _choiceComponents.add(emptyState);
      _commandsPanel!.add(emptyState);
      return;
    }

    final useGrid = choices.length <= 4;
    if (useGrid) {
      const gap = 12.0;
      final cardWidth = (availableWidth - gap) / 2;
      final rows = (choices.length / 2).ceil();
      final cardHeight = rows > 1
          ? ((availableHeight - ((rows - 1) * gap)) / rows).clamp(66.0, 88.0)
          : 88.0;

      for (var i = 0; i < choices.length; i++) {
        final row = i ~/ 2;
        final column = i % 2;
        final card = _BattleChoiceCardComponent(
          entry: choices[i],
          position: Vector2(
            16 + ((cardWidth + gap) * column),
            contentTop + ((cardHeight + gap) * row),
          ),
          size: Vector2(cardWidth, cardHeight),
          isSelected: i == selectedIndex,
          isInteractive: true,
          onPressed: onChoiceSelected,
        );
        _choiceComponents.add(card);
        _commandsPanel!.add(card);
      }
      return;
    }

    var y = contentTop;
    for (var i = 0; i < choices.length; i++) {
      final card = _BattleChoiceCardComponent(
        entry: choices[i],
        position: Vector2(16, y),
        size: Vector2(availableWidth, 64),
        isSelected: i == selectedIndex,
        isInteractive: true,
        onPressed: onChoiceSelected,
      );
      _choiceComponents.add(card);
      _commandsPanel!.add(card);
      y += 72;
    }
  }
}

class _BattleChoiceCardComponent extends PositionComponent with TapCallbacks {
  _BattleChoiceCardComponent({
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

  TextComponent? _titleText;
  TextComponent? _subtitleText;

  @override
  Future<void> onLoad() async {
    _titleText = TextComponent(
      text: entry.title,
      position: Vector2(16, 14),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color:
              isInteractive ? const Color(0xFFF8FBFF) : const Color(0x88F8FBFF),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 33,
    );
    await add(_titleText!);

    _subtitleText = TextComponent(
      text: entry.subtitle,
      position: Vector2(16, size.y - 14),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color:
              isInteractive ? const Color(0xCCE6EEF8) : const Color(0x77E6EEF8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      priority: 33,
    );
    await add(_subtitleText!);
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
    final palette = _paletteFor(entry.tone);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..shader = LinearGradient(
          colors: isInteractive
              ? <Color>[
                  palette.primary,
                  palette.secondary,
                ]
              : <Color>[
                  const Color(0xFF445166),
                  const Color(0xFF384457),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 1.5
        ..color = isSelected
            ? const Color(0xFFF7F0D4)
            : const Color(0x35FFFFFF),
    );

    final accentRect = Rect.fromLTWH(10, 10, size.x - 20, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(accentRect, const Radius.circular(999)),
      Paint()..color = const Color(0x24FFFFFF),
    );
  }

  _BattleChoicePalette _paletteFor(BattleCommandChoiceTone tone) {
    return switch (tone) {
      BattleCommandChoiceTone.attack => const _BattleChoicePalette(
          primary: Color(0xFFDE7B58),
          secondary: Color(0xFFB54F4B),
        ),
      BattleCommandChoiceTone.special => const _BattleChoicePalette(
          primary: Color(0xFF5B84D6),
          secondary: Color(0xFF3758A8),
        ),
      BattleCommandChoiceTone.support => const _BattleChoicePalette(
          primary: Color(0xFF5FAD86),
          secondary: Color(0xFF3D7F64),
        ),
      BattleCommandChoiceTone.switching => const _BattleChoicePalette(
          primary: Color(0xFF8D79D6),
          secondary: Color(0xFF6655AC),
        ),
      BattleCommandChoiceTone.neutral => const _BattleChoicePalette(
          primary: Color(0xFF637890),
          secondary: Color(0xFF46586F),
        ),
    };
  }
}

class _BattleChoicePalette {
  const _BattleChoicePalette({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;
}
