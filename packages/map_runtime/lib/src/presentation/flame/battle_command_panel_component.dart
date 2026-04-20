import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_command_menu_model.dart';

enum BattleCommandPanelLayoutMode {
  split,
  stacked,
}

class BattleCommandPanelComponent extends PositionComponent {
  BattleCommandPanelComponent({
    required Vector2 position,
    required Vector2 size,
    required this.onChoiceSelected,
    required this.onRootActionSelected,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 30,
        );

  final void Function(PlayerBattleChoice choice) onChoiceSelected;
  final void Function(BattleCommandRootAction action) onRootActionSelected;

  PositionComponent? _promptPanel;
  PositionComponent? _commandsPanel;
  TextComponent? _battleLabelText;
  TextComponent? _promptText;
  TextComponent? _narrationBodyText;
  TextComponent? _commandTitleText;
  TextComponent? _hintText;
  final List<PositionComponent> _interactiveComponents = <PositionComponent>[];
  _BattleCommandPanelLayout? _layout;
  BattleCommandMenuModel _menuModel = const BattleCommandMenuModel(
    mode: BattleCommandMenuMode.root,
    rootEntries: <BattleCommandRootEntry>[],
    selectedRootIndex: 0,
    choiceEntries: <BattleCommandChoiceEntry>[],
    selectedChoiceIndex: 0,
    choiceColumns: 1,
    choiceGroupTitle: 'COMMANDS',
  );

  bool get narrationPanelMounted => _promptPanel != null;
  bool get commandPanelMounted => _commandsPanel != null;
  String get currentPromptText => _promptText?.text ?? '';
  String get currentNarrationText => _narrationBodyText?.text ?? '';

  @visibleForTesting
  BattleCommandMenuMode get currentMenuMode => _menuModel.mode;

  @visibleForTesting
  List<String> get currentRootLabels =>
      _menuModel.rootEntries.map((entry) => entry.label).toList(growable: false);

  @visibleForTesting
  List<bool> get currentRootEnabledStates => _menuModel.rootEntries
      .map((entry) => entry.enabled)
      .toList(growable: false);

  @visibleForTesting
  int get currentSelectedRootIndex => _menuModel.selectedRootIndex;

  @visibleForTesting
  List<String> get currentChoiceLabels => _menuModel.choiceEntries
      .map((entry) => entry.title)
      .toList(growable: false);

  @visibleForTesting
  int get currentSelectedChoiceIndex => _menuModel.selectedChoiceIndex;

  @visibleForTesting
  BattleCommandPanelLayoutMode get currentLayoutMode =>
      _layout?.mode ?? BattleCommandPanelLayoutMode.split;

  @visibleForTesting
  Vector2 get promptPanelPosition => _promptPanel?.position ?? Vector2.zero();

  @visibleForTesting
  Vector2 get promptPanelSize => _promptPanel?.size ?? Vector2.zero();

  @visibleForTesting
  Vector2 get commandsPanelPosition =>
      _commandsPanel?.position ?? Vector2.zero();

  @visibleForTesting
  Vector2 get commandsPanelSize => _commandsPanel?.size ?? Vector2.zero();

  @override
  Future<void> onLoad() async {
    final layout = _BattleCommandPanelLayout.forSize(size);
    _layout = layout;

    _promptPanel = PositionComponent(
      position: layout.promptPosition,
      size: layout.promptSize,
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_promptPanel!);

    _commandsPanel = PositionComponent(
      position: layout.commandsPosition,
      size: layout.commandsSize,
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_commandsPanel!);

    _battleLabelText = TextComponent(
      text: '',
      position: layout.battleLabelPosition,
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xCC55657D),
          fontSize: layout.battleLabelFontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
    await _promptPanel!.add(_battleLabelText!);

    _promptText = TextComponent(
      text: '',
      position: layout.promptTextPosition,
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF1D2634),
          fontSize: layout.promptFontSize,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
    await _promptPanel!.add(_promptText!);

    _narrationBodyText = TextComponent(
      text: '',
      position: layout.narrationPosition,
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF435064),
          fontSize: layout.narrationFontSize,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
    await _promptPanel!.add(_narrationBodyText!);

    _commandTitleText = TextComponent(
      text: 'COMMANDS',
      position: layout.commandTitlePosition,
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xDCE6EDF8),
          fontSize: layout.commandLabelFontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
    await _commandsPanel!.add(_commandTitleText!);

    _hintText = TextComponent(
      text: '',
      position: layout.hintPosition(commandsPanelSize: _commandsPanel!.size),
      anchor: Anchor.bottomRight,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xA6E8EEF8),
          fontSize: layout.commandLabelFontSize,
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
    required BattleCommandMenuModel menuModel,
  }) {
    _menuModel = menuModel;
    _battleLabelText?.text = battleLabel.toUpperCase();
    _promptText?.text = prompt;
    final clippedNarration = narrationLines.isEmpty
        ? const <String>['The battle awaits the next action.']
        : narrationLines.take(3).toList(growable: false);
    _narrationBodyText?.text = clippedNarration.join('\n');
    _commandTitleText?.text = menuModel.isRootMode ? '' : menuModel.choiceGroupTitle;
    _hintText?.text = _hintFor(menuModel);
    _renderInteractiveArea();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_promptPanel != null) {
      final promptRect = Rect.fromLTWH(
        _promptPanel!.position.x,
        _promptPanel!.position.y,
        _promptPanel!.size.x,
        _promptPanel!.size.y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptRect, const Radius.circular(18)),
        Paint()..color = const Color(0xFF57626C),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptRect, const Radius.circular(22)),
        Paint()..color = const Color(0x22000000),
      );
      final promptInnerRect = promptRect.deflate(6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptInnerRect, const Radius.circular(14)),
        Paint()..color = const Color(0xFFF7F1E7),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptInnerRect, const Radius.circular(14)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25
          ..color = const Color(0xFFD1C7B7),
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
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(18)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xC12D3640),
              Color(0xA61B2127),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(commandsRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(18)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25
          ..color = const Color(0x38FFFFFF),
      );
    }
  }

  void _renderInteractiveArea() {
    for (final component in _interactiveComponents) {
      component.removeFromParent();
    }
    _interactiveComponents.clear();

    final commandsPanel = _commandsPanel;
    if (commandsPanel == null) {
      return;
    }

    if (_menuModel.isRootMode) {
      _renderRootEntries(commandsPanel);
      return;
    }

    if (_menuModel.isContinueOnly) {
      _renderChoiceEntries(commandsPanel);
      return;
    }

    _renderChoiceEntries(commandsPanel);
  }

  void _renderRootEntries(PositionComponent commandsPanel) {
    final layout = _layout ?? _BattleCommandPanelLayout.forSize(size);
    final top = layout.mode == BattleCommandPanelLayoutMode.stacked ? 14.0 : 20.0;
    final gap = layout.mode == BattleCommandPanelLayoutMode.stacked ? 8.0 : 10.0;
    final availableWidth = commandsPanel.size.x - 24;
    final availableHeight = commandsPanel.size.y - (layout.mode == BattleCommandPanelLayoutMode.stacked ? 18 : 28);
    final cardWidth = (availableWidth - gap) / 2;
    final cardHeight = ((availableHeight - gap) / 2)
        .clamp(layout.mode == BattleCommandPanelLayoutMode.stacked ? 46.0 : 54.0, layout.mode == BattleCommandPanelLayoutMode.stacked ? 64.0 : 72.0);

    for (var index = 0; index < _menuModel.rootEntries.length; index++) {
      final entry = _menuModel.rootEntries[index];
      final row = index ~/ 2;
      final column = index % 2;
      final card = _BattleRootButtonComponent(
        entry: entry,
        position: Vector2(
          12 + ((cardWidth + gap) * column),
          top + ((cardHeight + gap) * row),
        ),
        size: Vector2(cardWidth, cardHeight),
        isSelected: index == _menuModel.selectedRootIndex,
        onPressed: onRootActionSelected,
        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
      );
      _interactiveComponents.add(card);
      commandsPanel.add(card);
    }
  }

  void _renderChoiceEntries(PositionComponent commandsPanel) {
    final layout = _layout ?? _BattleCommandPanelLayout.forSize(size);
    final top = _menuModel.isContinueOnly
        ? (layout.mode == BattleCommandPanelLayoutMode.stacked ? 16.0 : 28.0)
        : (layout.mode == BattleCommandPanelLayoutMode.stacked ? 18.0 : 24.0);
    final gap = layout.mode == BattleCommandPanelLayoutMode.stacked ? 8.0 : 10.0;
    final entries = _menuModel.choiceEntries;
    if (entries.isEmpty) {
      return;
    }

    final availableWidth = commandsPanel.size.x - 24;
    final availableHeight = commandsPanel.size.y - (top + 14);
    final columns = _menuModel.choiceColumns <= 0 ? 1 : _menuModel.choiceColumns;
    final rows = (entries.length / columns).ceil();
    final cardWidth = columns == 1
        ? availableWidth
        : ((availableWidth - ((columns - 1) * gap)) / columns);
    final cardHeight = ((availableHeight - ((rows - 1) * gap)) / rows)
        .clamp(52.0, _menuModel.isContinueOnly ? 92.0 : 78.0);

    for (var index = 0; index < entries.length; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      final card = _BattleChoiceCardComponent(
        entry: entries[index],
        position: Vector2(
          12 + ((cardWidth + gap) * column),
          top + ((cardHeight + gap) * row),
        ),
        size: Vector2(cardWidth, cardHeight),
        isSelected: index == _menuModel.selectedChoiceIndex,
        onPressed: onChoiceSelected,
        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
      );
      _interactiveComponents.add(card);
      commandsPanel.add(card);
    }
  }

  String _hintFor(BattleCommandMenuModel menuModel) {
    if (menuModel.isContinueOnly) {
      return 'Enter / Space';
    }
    if (menuModel.isRootMode) {
      return '';
    }
    return 'Esc back';
  }
}

class _BattleRootButtonComponent extends PositionComponent with TapCallbacks {
  _BattleRootButtonComponent({
    required this.entry,
    required Vector2 position,
    required Vector2 size,
    required this.isSelected,
    required this.onPressed,
    this.compact = false,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 32,
        );

  final BattleCommandRootEntry entry;
  final bool isSelected;
  final void Function(BattleCommandRootAction action) onPressed;
  final bool compact;

  TextComponent? _labelText;
  TextComponent? _subtitleText;

  @override
  Future<void> onLoad() async {
    _labelText = TextComponent(
      text: entry.label,
      position: Vector2(size.x / 2, size.y * 0.38),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: entry.enabled
              ? const Color(0xFFFDFDFD)
              : const Color(0x9AFDFDFD),
          fontSize: compact ? 17 : 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
      priority: 33,
    );
    await add(_labelText!);

    _subtitleText = TextComponent(
      text: entry.subtitle,
      position: Vector2(size.x / 2, size.y - 10),
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          color: entry.enabled
              ? const Color(0xDDF7F7F7)
              : const Color(0x99F7F7F7),
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
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
    if (!entry.enabled) {
      return;
    }
    onPressed(entry.action);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final palette = _rootPaletteFor(entry.action, enabled: entry.enabled);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[palette.primary, palette.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final upperBevelRect = Rect.fromLTWH(3, 3, size.x - 6, size.y * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(upperBevelRect, const Radius.circular(12)),
      Paint()..color = const Color(0x26FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.25
        ..color = isSelected
            ? const Color(0xFFF6E8B0)
            : const Color(0x55FFFFFF),
    );
  }
}

class _BattleChoiceCardComponent extends PositionComponent with TapCallbacks {
  _BattleChoiceCardComponent({
    required this.entry,
    required Vector2 position,
    required Vector2 size,
    required this.isSelected,
    required this.onPressed,
    this.compact = false,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 32,
        );

  final BattleCommandChoiceEntry entry;
  final bool isSelected;
  final void Function(PlayerBattleChoice choice) onPressed;
  final bool compact;

  TextComponent? _titleText;
  TextComponent? _subtitleText;

  @override
  Future<void> onLoad() async {
    _titleText = TextComponent(
      text: entry.title,
      position: Vector2(14, 12),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFF8FBFF),
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 33,
    );
    await add(_titleText!);

    _subtitleText = TextComponent(
      text: entry.subtitle,
      position: Vector2(14, size.y - 10),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xCCE6EEF8),
          fontSize: compact ? 9 : 10,
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
    onPressed(entry.choice);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final palette = _choicePaletteFor(entry.tone);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[palette.primary, palette.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.25
        ..color = isSelected
            ? const Color(0xFFF7F0D4)
            : const Color(0x55FFFFFF),
    );
  }
}

class _BattleCommandPanelLayout {
  const _BattleCommandPanelLayout({
    required this.mode,
    required this.promptPosition,
    required this.promptSize,
    required this.commandsPosition,
    required this.commandsSize,
    required this.battleLabelPosition,
    required this.battleLabelFontSize,
    required this.promptTextPosition,
    required this.promptFontSize,
    required this.narrationPosition,
    required this.narrationFontSize,
    required this.commandTitlePosition,
    required this.commandLabelFontSize,
  });

  final BattleCommandPanelLayoutMode mode;
  final Vector2 promptPosition;
  final Vector2 promptSize;
  final Vector2 commandsPosition;
  final Vector2 commandsSize;
  final Vector2 battleLabelPosition;
  final double battleLabelFontSize;
  final Vector2 promptTextPosition;
  final double promptFontSize;
  final Vector2 narrationPosition;
  final double narrationFontSize;
  final Vector2 commandTitlePosition;
  final double commandLabelFontSize;

  Vector2 hintPosition({
    required Vector2 commandsPanelSize,
  }) {
    return Vector2(commandsPanelSize.x - 10, commandsPanelSize.y - 2);
  }

  factory _BattleCommandPanelLayout.forSize(Vector2 panelSize) {
    final useStacked =
        panelSize.x < 700 || (panelSize.x / (panelSize.y <= 0 ? 1 : panelSize.y)) < 2.45;
    if (useStacked) {
      const spacing = 12.0;
      final promptHeight = (panelSize.y * 0.42).clamp(90.0, 120.0).toDouble();
      final commandsHeight = (panelSize.y - promptHeight - spacing)
          .clamp(110.0, panelSize.y)
          .toDouble();
      return _BattleCommandPanelLayout(
        mode: BattleCommandPanelLayoutMode.stacked,
        promptPosition: Vector2.zero(),
        promptSize: Vector2(panelSize.x, promptHeight),
        commandsPosition: Vector2(0, promptHeight + spacing),
        commandsSize: Vector2(panelSize.x, commandsHeight),
        battleLabelPosition: Vector2(16, 12),
        battleLabelFontSize: 9,
        promptTextPosition: Vector2(16, 28),
        promptFontSize: 16,
        narrationPosition: Vector2(16, 58),
        narrationFontSize: 11,
        commandTitlePosition: Vector2(10, 2),
        commandLabelFontSize: 9,
      );
    }

    final promptWidth = (panelSize.x * 0.46).clamp(320.0, 430.0).toDouble();
    const spacing = 22.0;
    final commandsWidth = panelSize.x - promptWidth - spacing;
    return _BattleCommandPanelLayout(
      mode: BattleCommandPanelLayoutMode.split,
      promptPosition: Vector2.zero(),
      promptSize: Vector2(promptWidth, panelSize.y),
      commandsPosition: Vector2(promptWidth + spacing, 0),
      commandsSize: Vector2(commandsWidth, panelSize.y),
      battleLabelPosition: Vector2(20, 16),
      battleLabelFontSize: 10,
      promptTextPosition: Vector2(20, 36),
      promptFontSize: 20,
      narrationPosition: Vector2(20, 82),
      narrationFontSize: 13,
      commandTitlePosition: Vector2(10, 2),
      commandLabelFontSize: 10,
    );
  }
}

_BattlePalette _rootPaletteFor(
  BattleCommandRootAction action, {
  required bool enabled,
}) {
  if (!enabled) {
    return const _BattlePalette(
      primary: Color(0xFF4E5768),
      secondary: Color(0xFF373F4C),
    );
  }
  return switch (action) {
    BattleCommandRootAction.fight => const _BattlePalette(
        primary: Color(0xFFF5897D),
        secondary: Color(0xFFD55D59),
      ),
    BattleCommandRootAction.bag => const _BattlePalette(
        primary: Color(0xFFE8B95D),
        secondary: Color(0xFFC48D2B),
      ),
    BattleCommandRootAction.pokemon => const _BattlePalette(
        primary: Color(0xFF86B665),
        secondary: Color(0xFF4E7E3D),
      ),
    BattleCommandRootAction.run => const _BattlePalette(
        primary: Color(0xFF6C95D8),
        secondary: Color(0xFF4569B1),
      ),
  };
}

_BattlePalette _choicePaletteFor(BattleCommandChoiceTone tone) {
  return switch (tone) {
    BattleCommandChoiceTone.attack => const _BattlePalette(
        primary: Color(0xFFDE7B58),
        secondary: Color(0xFFB54F4B),
      ),
    BattleCommandChoiceTone.special => const _BattlePalette(
        primary: Color(0xFF5B84D6),
        secondary: Color(0xFF3758A8),
      ),
    BattleCommandChoiceTone.support => const _BattlePalette(
        primary: Color(0xFF5FAD86),
        secondary: Color(0xFF3D7F64),
      ),
    BattleCommandChoiceTone.switching => const _BattlePalette(
        primary: Color(0xFF8D79D6),
        secondary: Color(0xFF6655AC),
      ),
    BattleCommandChoiceTone.neutral => const _BattlePalette(
        primary: Color(0xFF637890),
        secondary: Color(0xFF46586F),
      ),
  };
}

class _BattlePalette {
  const _BattlePalette({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;
}
