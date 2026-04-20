import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_command_menu_model.dart';
import 'battle_party_menu_model.dart';
import 'battle_scene_layout.dart';

class BattleCommandButtonSnapshot {
  const BattleCommandButtonSnapshot({
    required this.bounds,
    required this.titleRect,
    required this.subtitleRect,
    required this.showSubtitle,
    required this.titleFontSize,
    required this.subtitleFontSize,
  });

  final Rect bounds;
  final Rect titleRect;
  final Rect? subtitleRect;
  final bool showSubtitle;
  final double titleFontSize;
  final double subtitleFontSize;
}

class BattlePartyEntrySnapshot {
  const BattlePartyEntrySnapshot({
    required this.bounds,
    required this.titleRect,
    required this.levelRect,
    required this.hpRect,
    required this.statusRect,
    required this.titleFontSize,
    required this.levelFontSize,
    required this.metaFontSize,
  });

  final Rect bounds;
  final Rect titleRect;
  final Rect levelRect;
  final Rect hpRect;
  final Rect statusRect;
  final double titleFontSize;
  final double levelFontSize;
  final double metaFontSize;
}

class BattleCommandPanelComponent extends PositionComponent {
  BattleCommandPanelComponent({
    required Vector2 position,
    required Vector2 size,
    required this.onChoiceSelected,
    required this.onRootActionSelected,
    required this.onPartyEntrySelected,
    this.layoutModeOverride,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 30,
        );

  final void Function(PlayerBattleChoice choice) onChoiceSelected;
  final void Function(BattleCommandRootAction action) onRootActionSelected;
  final void Function(BattlePartyMenuEntry entry) onPartyEntrySelected;
  final BattleCommandPanelLayoutMode? layoutModeOverride;

  PositionComponent? _promptPanel;
  PositionComponent? _commandsPanel;
  TextComponent? _battleLabelText;
  TextComponent? _promptText;
  TextComponent? _narrationBodyText;
  TextComponent? _commandTitleText;
  TextComponent? _hintText;
  final List<PositionComponent> _interactiveComponents = <PositionComponent>[];
  final List<BattleCommandButtonSnapshot> _rootButtonSnapshots =
      <BattleCommandButtonSnapshot>[];
  final List<BattlePartyEntrySnapshot> _partyEntrySnapshots =
      <BattlePartyEntrySnapshot>[];
  String _currentPromptValue = '';
  String _currentNarrationValue = '';
  _BattleCommandPanelLayout? _layout;
  BattlePartyMenuModel? _partyMenuModel;
  int _selectedPartyIndex = 0;
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
  String get currentPromptText => _currentPromptValue;
  String get currentNarrationText => _currentNarrationValue;

  @visibleForTesting
  BattleCommandMenuMode get currentMenuMode => _menuModel.mode;

  @visibleForTesting
  List<String> get currentRootLabels => _menuModel.rootEntries
      .map((entry) => entry.label)
      .toList(growable: false);

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
  List<String> get currentPartySpeciesLabels => (_partyMenuModel?.allEntries ??
          const <BattlePartyMenuEntry>[])
      .map((entry) => entry.speciesId)
      .toList(growable: false);

  @visibleForTesting
  List<bool> get currentPartySelectableStates =>
      (_partyMenuModel?.allEntries ?? const <BattlePartyMenuEntry>[])
          .map((entry) => entry.isSelectable)
          .toList(growable: false);

  @visibleForTesting
  List<String> get currentPartyStatusLabels =>
      (_partyMenuModel?.allEntries ?? const <BattlePartyMenuEntry>[])
          .map(_partyEntryStatusLabel)
          .toList(growable: false);

  @visibleForTesting
  int get currentSelectedPartyIndex => _selectedPartyIndex;

  @visibleForTesting
  List<BattlePartyEntrySnapshot> get currentPartyEntrySnapshots =>
      List<BattlePartyEntrySnapshot>.unmodifiable(_partyEntrySnapshots);

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

  @visibleForTesting
  List<BattleCommandButtonSnapshot> get currentRootButtonSnapshots =>
      List<BattleCommandButtonSnapshot>.unmodifiable(_rootButtonSnapshots);

  @override
  Future<void> onLoad() async {
    final layout = _BattleCommandPanelLayout.forSize(
      size,
      modeOverride: layoutModeOverride,
    );
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
    BattlePartyMenuModel? partyMenuModel,
    int selectedPartyIndex = 0,
    bool allowEmptyNarrationBody = false,
    bool interactionsEnabled = true,
  }) {
    _menuModel = menuModel;
    _partyMenuModel = partyMenuModel;
    _selectedPartyIndex = selectedPartyIndex;
    _battleLabelText?.text = battleLabel.toUpperCase();
    _currentPromptValue = prompt;
    _promptText?.text = prompt;
    final clippedNarration = _sanitizeNarrationBody(
      prompt: prompt,
      narrationLines: narrationLines,
      allowEmptyFallback: allowEmptyNarrationBody,
    );
    _currentNarrationValue = clippedNarration.join('\n');
    _narrationBodyText?.text = _currentNarrationValue;
    _commandTitleText?.text =
        menuModel.isRootMode ? '' : menuModel.choiceGroupTitle;
    _hintText?.text = _hintFor(menuModel);
    _renderInteractiveArea(interactionsEnabled: interactionsEnabled);
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

  void _renderInteractiveArea({
    required bool interactionsEnabled,
  }) {
    for (final component in _interactiveComponents) {
      component.removeFromParent();
    }
    _interactiveComponents.clear();
    _rootButtonSnapshots.clear();
    _partyEntrySnapshots.clear();

    final commandsPanel = _commandsPanel;
    if (commandsPanel == null) {
      return;
    }

    if (_menuModel.isRootMode) {
      _renderRootEntries(
        commandsPanel,
        interactionsEnabled: interactionsEnabled,
      );
      return;
    }

    if (_menuModel.mode == BattleCommandMenuMode.pokemon &&
        _partyMenuModel != null) {
      _renderPartyEntries(
        commandsPanel,
        interactionsEnabled: interactionsEnabled,
      );
      return;
    }

    if (_menuModel.isContinueOnly) {
      _renderChoiceEntries(
        commandsPanel,
        interactionsEnabled: interactionsEnabled,
      );
      return;
    }

    _renderChoiceEntries(
      commandsPanel,
      interactionsEnabled: interactionsEnabled,
    );
  }

  void _renderRootEntries(
    PositionComponent commandsPanel, {
    required bool interactionsEnabled,
  }) {
    final layout = _layout ?? _BattleCommandPanelLayout.forSize(size);
    final top =
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 14.0 : 20.0;
    final gap =
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 8.0 : 10.0;
    final availableWidth = commandsPanel.size.x - 24;
    final availableHeight = commandsPanel.size.y -
        (layout.mode == BattleCommandPanelLayoutMode.stacked ? 18 : 28);
    final cardWidth = (availableWidth - gap) / 2;
    final cardHeight = ((availableHeight - gap) / 2).clamp(
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 46.0 : 54.0,
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 64.0 : 72.0);

    for (var index = 0; index < _menuModel.rootEntries.length; index++) {
      final entry = _menuModel.rootEntries[index];
      final row = index ~/ 2;
      final column = index % 2;
      final snapshot = _buildRootButtonSnapshot(
        buttonSize: Size(cardWidth, cardHeight),
        title: entry.label,
        subtitle: entry.subtitle,
        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
      );
      _rootButtonSnapshots.add(snapshot);
      final card = _BattleRootButtonComponent(
        entry: entry,
        position: Vector2(
          12 + ((cardWidth + gap) * column),
          top + ((cardHeight + gap) * row),
        ),
        size: Vector2(cardWidth, cardHeight),
        snapshot: snapshot,
        isSelected: index == _menuModel.selectedRootIndex,
        onPressed: onRootActionSelected,
        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
        interactionsEnabled: interactionsEnabled,
      );
      _interactiveComponents.add(card);
      commandsPanel.add(card);
    }
  }

  void _renderChoiceEntries(
    PositionComponent commandsPanel, {
    required bool interactionsEnabled,
  }) {
    final layout = _layout ?? _BattleCommandPanelLayout.forSize(size);
    final top = _menuModel.isContinueOnly
        ? (layout.mode == BattleCommandPanelLayoutMode.stacked ? 16.0 : 28.0)
        : (layout.mode == BattleCommandPanelLayoutMode.stacked ? 18.0 : 24.0);
    final gap =
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 8.0 : 10.0;
    final entries = _menuModel.choiceEntries;
    if (entries.isEmpty) {
      return;
    }

    final availableWidth = commandsPanel.size.x - 24;
    final availableHeight = commandsPanel.size.y - (top + 14);
    final columns =
        _menuModel.choiceColumns <= 0 ? 1 : _menuModel.choiceColumns;
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
        interactionsEnabled: interactionsEnabled,
      );
      _interactiveComponents.add(card);
      commandsPanel.add(card);
    }
  }

  void _renderPartyEntries(
    PositionComponent commandsPanel, {
    required bool interactionsEnabled,
  }) {
    final partyMenuModel = _partyMenuModel;
    if (partyMenuModel == null) {
      return;
    }

    final layout = _layout ?? _BattleCommandPanelLayout.forSize(size);
    final top =
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 18.0 : 24.0;
    final gap =
        layout.mode == BattleCommandPanelLayoutMode.stacked ? 7.0 : 8.0;
    final entries = partyMenuModel.allEntries;
    if (entries.isEmpty) {
      return;
    }

    final availableWidth = commandsPanel.size.x - 24;
    final availableHeight = commandsPanel.size.y - (top + 14);
    final cardHeight = ((availableHeight - ((entries.length - 1) * gap)) /
            entries.length)
        .clamp(
          layout.mode == BattleCommandPanelLayoutMode.stacked ? 36.0 : 42.0,
          layout.mode == BattleCommandPanelLayoutMode.stacked ? 58.0 : 64.0,
        )
        .toDouble();

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final snapshot = _buildPartyEntrySnapshot(
        entrySize: Size(availableWidth, cardHeight),
        speciesLabel: entry.speciesId,
        levelLabel: 'Nv. ${entry.level}',
        hpLabel: '${entry.currentHp}/${entry.maxHp} PV',
        statusLabel: _partyEntryStatusLabel(entry),
        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
      );
      _partyEntrySnapshots.add(snapshot);
      final card = _BattlePartyEntryComponent(
        entry: entry,
        position: Vector2(12, top + ((cardHeight + gap) * index)),
        size: Vector2(availableWidth, cardHeight),
        snapshot: snapshot,
        isSelected: index == _selectedPartyIndex,
        onPressed: onPartyEntrySelected,
        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
        interactionsEnabled: interactionsEnabled,
        statusLabel: _partyEntryStatusLabel(entry),
      );
      _interactiveComponents.add(card);
      commandsPanel.add(card);
    }
  }

  String _hintFor(BattleCommandMenuModel menuModel) {
    if (menuModel.isContinueOnly) {
      return 'Enter / Space';
    }
    if (menuModel.mode == BattleCommandMenuMode.pokemon &&
        _partyMenuModel?.mode == BattlePartyMenuMode.forcedReplacement) {
      return '';
    }
    if (menuModel.isRootMode) {
      return '';
    }
    return 'Esc back';
  }

  List<String> _sanitizeNarrationBody({
    required String prompt,
    required List<String> narrationLines,
    required bool allowEmptyFallback,
  }) {
    final normalizedPrompt = prompt.trim().toLowerCase();
    final sanitized = narrationLines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => line.toLowerCase() != normalizedPrompt)
        .take(3)
        .toList(growable: false);
    if (sanitized.isNotEmpty) {
      return sanitized;
    }
    if (allowEmptyFallback) {
      return const <String>[];
    }
    return const <String>['Choisis une action.'];
  }
}

String _partyEntryStatusLabel(BattlePartyMenuEntry entry) {
  if (entry.isActive) {
    return 'Actif';
  }
  if (entry.isFainted) {
    return 'K.O.';
  }
  if (entry.isSelectable) {
    return 'OK';
  }
  return 'Indisponible';
}

class _BattleRootButtonComponent extends PositionComponent with TapCallbacks {
  _BattleRootButtonComponent({
    required this.entry,
    required Vector2 position,
    required Vector2 size,
    required this.snapshot,
    required this.isSelected,
    required this.onPressed,
    this.compact = false,
    this.interactionsEnabled = true,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 32,
        );

  final BattleCommandRootEntry entry;
  final BattleCommandButtonSnapshot snapshot;
  final bool isSelected;
  final void Function(BattleCommandRootAction action) onPressed;
  final bool compact;
  final bool interactionsEnabled;

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.x <= size.x &&
        point.y >= 0 &&
        point.y <= size.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!interactionsEnabled || !entry.enabled) {
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
        ..color =
            isSelected ? const Color(0xFFF6E8B0) : const Color(0x55FFFFFF),
    );

    _paintButtonText(
      canvas,
      text: entry.label,
      rect: snapshot.titleRect,
      fontSize: snapshot.titleFontSize,
      color: entry.enabled ? const Color(0xFFFDFDFD) : const Color(0x9AFDFDFD),
      align: TextAlign.center,
      fontWeight: FontWeight.w900,
    );
    if (snapshot.showSubtitle && snapshot.subtitleRect != null) {
      _paintButtonText(
        canvas,
        text: entry.subtitle,
        rect: snapshot.subtitleRect!,
        fontSize: snapshot.subtitleFontSize,
        color:
            entry.enabled ? const Color(0xDDF7F7F7) : const Color(0x99F7F7F7),
        align: TextAlign.center,
        fontWeight: FontWeight.w700,
      );
    }
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
    this.interactionsEnabled = true,
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
  final bool interactionsEnabled;

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
    if (!interactionsEnabled) {
      return;
    }
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
        ..color =
            isSelected ? const Color(0xFFF7F0D4) : const Color(0x55FFFFFF),
    );
  }
}

class _BattlePartyEntryComponent extends PositionComponent with TapCallbacks {
  _BattlePartyEntryComponent({
    required this.entry,
    required Vector2 position,
    required Vector2 size,
    required this.snapshot,
    required this.isSelected,
    required this.onPressed,
    required this.statusLabel,
    this.compact = false,
    this.interactionsEnabled = true,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 32,
        );

  final BattlePartyMenuEntry entry;
  final BattlePartyEntrySnapshot snapshot;
  final bool isSelected;
  final void Function(BattlePartyMenuEntry entry) onPressed;
  final String statusLabel;
  final bool compact;
  final bool interactionsEnabled;

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.x <= size.x &&
        point.y >= 0 &&
        point.y <= size.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!interactionsEnabled || !entry.isSelectable) {
      return;
    }
    onPressed(entry);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final cornerRadius = Radius.circular(compact ? 12 : 14);
    final enabled = entry.isSelectable;
    final backgroundTop = enabled
        ? const Color(0xFF597FBF)
        : entry.isActive
            ? const Color(0xFF5B616A)
            : const Color(0xFF444B58);
    final backgroundBottom = enabled
        ? const Color(0xFF3C5A93)
        : entry.isActive
            ? const Color(0xFF41464E)
            : const Color(0xFF323844);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, cornerRadius),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[backgroundTop, backgroundBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, cornerRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.25 : 1.1
        ..color = isSelected
            ? const Color(0xFFF7F0D4)
            : enabled
                ? const Color(0x55FFFFFF)
                : const Color(0x33FFFFFF),
    );

    final titleColor =
        enabled ? const Color(0xFFFDFDFD) : const Color(0xD8F1F4FA);
    final metaColor =
        enabled ? const Color(0xE6E7EFFA) : const Color(0xB6D5DDE8);
    final statusColor = switch (entry.disabledReason) {
      BattlePartyMenuDisabledReason.fainted => const Color(0xFFFFB0A5),
      BattlePartyMenuDisabledReason.activePokemon => const Color(0xFFEFDDA8),
      _ => enabled ? const Color(0xFFC8F0CF) : const Color(0xD5DDE8F1),
    };

    _paintButtonText(
      canvas,
      text: entry.speciesId,
      rect: snapshot.titleRect,
      fontSize: snapshot.titleFontSize,
      color: titleColor,
      align: TextAlign.left,
      fontWeight: FontWeight.w900,
    );
    _paintButtonText(
      canvas,
      text: 'Nv. ${entry.level}',
      rect: snapshot.levelRect,
      fontSize: snapshot.levelFontSize,
      color: metaColor,
      align: TextAlign.right,
      fontWeight: FontWeight.w800,
    );
    _paintButtonText(
      canvas,
      text: '${entry.currentHp}/${entry.maxHp} PV',
      rect: snapshot.hpRect,
      fontSize: snapshot.metaFontSize,
      color: metaColor,
      align: TextAlign.left,
      fontWeight: FontWeight.w700,
    );
    _paintButtonText(
      canvas,
      text: statusLabel,
      rect: snapshot.statusRect,
      fontSize: snapshot.metaFontSize,
      color: statusColor,
      align: TextAlign.right,
      fontWeight: FontWeight.w800,
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

  factory _BattleCommandPanelLayout.forSize(
    Vector2 panelSize, {
    BattleCommandPanelLayoutMode? modeOverride,
  }) {
    final useStacked = modeOverride == null
        ? panelSize.x < 700 ||
            (panelSize.x / (panelSize.y <= 0 ? 1 : panelSize.y)) < 2.45
        : modeOverride == BattleCommandPanelLayoutMode.stacked;
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

BattleCommandButtonSnapshot _buildRootButtonSnapshot({
  required Size buttonSize,
  required String title,
  required String subtitle,
  required bool compact,
}) {
  final horizontalPadding = compact ? 10.0 : 12.0;
  final titleMaxWidth = buttonSize.width - (horizontalPadding * 2);
  final maxTitleFontSize = compact ? 17.0 : 20.0;
  final minTitleFontSize = compact ? 12.0 : 14.0;
  final titleFontSize = _fitSingleLineFontSize(
    text: title,
    maxWidth: titleMaxWidth,
    maxFontSize: maxTitleFontSize,
    minFontSize: minTitleFontSize,
    fontWeight: FontWeight.w900,
  );
  final titleHeight = titleFontSize * 1.1;
  final canShowSubtitle = buttonSize.height >= (compact ? 46.0 : 54.0);
  final subtitleFontSize = compact ? 9.0 : 10.0;
  final subtitleHeight = subtitleFontSize * 1.15;

  Rect? subtitleRect;
  if (canShowSubtitle) {
    final subtitleTop = buttonSize.height - subtitleHeight - 8;
    if (subtitleTop - (buttonSize.height * 0.24) >= titleHeight + 4) {
      subtitleRect = Rect.fromLTWH(
        horizontalPadding,
        subtitleTop,
        titleMaxWidth,
        subtitleHeight,
      );
    }
  }

  final titleTop = subtitleRect == null
      ? (buttonSize.height - titleHeight) / 2
      : math.min(buttonSize.height * 0.2, subtitleRect.top - titleHeight - 4);
  final titleRect = Rect.fromLTWH(
    horizontalPadding,
    titleTop,
    titleMaxWidth,
    titleHeight,
  );

  return BattleCommandButtonSnapshot(
    bounds: Offset.zero & buttonSize,
    titleRect: titleRect,
    subtitleRect: subtitleRect,
    showSubtitle: subtitleRect != null,
    titleFontSize: titleFontSize,
    subtitleFontSize: subtitleFontSize,
  );
}

BattlePartyEntrySnapshot _buildPartyEntrySnapshot({
  required Size entrySize,
  required String speciesLabel,
  required String levelLabel,
  required String hpLabel,
  required String statusLabel,
  required bool compact,
}) {
  final horizontalPadding = compact ? 10.0 : 12.0;
  final topPadding = compact ? 7.0 : 8.0;
  final bottomPadding = compact ? 6.0 : 7.0;
  final verticalGap = compact ? 2.0 : 3.0;
  final levelWidth = (entrySize.width * 0.24).clamp(54.0, 88.0).toDouble();
  final metaWidth = (entrySize.width * 0.34).clamp(74.0, 118.0).toDouble();
  final titleWidth =
      entrySize.width - (horizontalPadding * 2) - levelWidth - 6.0;
  final titleFontSize = _fitSingleLineFontSize(
    text: speciesLabel,
    maxWidth: titleWidth,
    maxFontSize: compact ? 13.0 : 14.0,
    minFontSize: compact ? 10.0 : 11.0,
    fontWeight: FontWeight.w900,
  );
  final levelFontSize = _fitSingleLineFontSize(
    text: levelLabel,
    maxWidth: levelWidth,
    maxFontSize: compact ? 11.0 : 12.0,
    minFontSize: compact ? 9.0 : 10.0,
    fontWeight: FontWeight.w800,
  );
  final metaFontSize = compact ? 9.0 : 10.0;
  final titleHeight = titleFontSize * 1.1;
  final levelHeight = levelFontSize * 1.1;
  final metaHeight = metaFontSize * 1.15;
  final bottomTop = entrySize.height - bottomPadding - metaHeight;

  return BattlePartyEntrySnapshot(
    bounds: Offset.zero & entrySize,
    titleRect: Rect.fromLTWH(
      horizontalPadding,
      topPadding,
      titleWidth,
      titleHeight,
    ),
    levelRect: Rect.fromLTWH(
      entrySize.width - horizontalPadding - levelWidth,
      topPadding,
      levelWidth,
      levelHeight,
    ),
    hpRect: Rect.fromLTWH(
      horizontalPadding,
      math.max(topPadding + titleHeight + verticalGap, bottomTop),
      metaWidth,
      metaHeight,
    ),
    statusRect: Rect.fromLTWH(
      entrySize.width - horizontalPadding - metaWidth,
      math.max(topPadding + titleHeight + verticalGap, bottomTop),
      metaWidth,
      metaHeight,
    ),
    titleFontSize: titleFontSize,
    levelFontSize: levelFontSize,
    metaFontSize: metaFontSize,
  );
}

double _fitSingleLineFontSize({
  required String text,
  required double maxWidth,
  required double maxFontSize,
  required double minFontSize,
  required FontWeight fontWeight,
}) {
  var fontSize = maxFontSize;
  while (fontSize > minFontSize) {
    final width = _measureSingleLineWidth(
      text,
      TextStyle(fontSize: fontSize, fontWeight: fontWeight),
    );
    if (width <= maxWidth) {
      break;
    }
    fontSize -= 1;
  }
  return fontSize.clamp(minFontSize, maxFontSize);
}

double _measureSingleLineWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void _paintButtonText(
  Canvas canvas, {
  required String text,
  required Rect rect,
  required double fontSize,
  required Color color,
  required TextAlign align,
  required FontWeight fontWeight,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    ),
    maxLines: 1,
    ellipsis: '…',
    textAlign: align,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: rect.width);

  final dx = switch (align) {
    TextAlign.right => rect.right - painter.width,
    TextAlign.center => rect.left + ((rect.width - painter.width) / 2),
    _ => rect.left,
  };
  final dy = rect.top + ((rect.height - painter.height) / 2);
  painter.paint(canvas, Offset(dx, dy));
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
