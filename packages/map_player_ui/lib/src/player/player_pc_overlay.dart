import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_input_scope.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_pc_strings.dart';
import 'runtime_player_actions.dart';
import 'player_pokemon_image.dart';
import 'player_pokemon_summary_sheet.dart';

class PlayerPcOverlay extends StatefulWidget {
  const PlayerPcOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  State<PlayerPcOverlay> createState() => _PlayerPcOverlayState();
}

class _PlayerPcOverlayState extends State<PlayerPcOverlay> {
  var _party = false;
  var _swap = false;
  var _slot = 0;
  var _storedSlot = 0;
  var _boxDirection = 1;
  String? _swapTarget;
  final _surfaceFocus = FocusNode(debugLabel: 'PC service');

  @override
  void initState() {
    super.initState();
    _focusSurface();
  }

  void _focusSurface() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        _surfaceFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _surfaceFocus.dispose();
    super.dispose();
  }

  RuntimeWorldServiceSnapshot get snapshot => widget.snapshot;

  @override
  void didUpdateWidget(PlayerPcOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.snapshot.content;
    final value = snapshot.content;
    if (old is RuntimePcServiceContent &&
        value is RuntimePcServiceContent &&
        old.selectedBoxId != value.selectedBoxId) {
      final previous = old.boxes.indexWhere(
        (box) => box.boxId == old.selectedBoxId,
      );
      final next = value.boxes.indexWhere(
        (box) => box.boxId == value.selectedBoxId,
      );
      _boxDirection = next >= previous ? 1 : -1;
      _slot = 0;
      _storedSlot = 0;
      _party = false;
      _swap = false;
      _swapTarget = null;
    }
  }

  void _emit(
    RuntimeWorldServiceAction action, {
    String? targetId,
    String? secondaryTargetId,
  }) {
    if (!snapshot.isActionEnabled(action)) return;
    widget.onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: targetId,
        secondaryTargetId: secondaryTargetId,
      ),
    );
  }

  void _back() {
    if (_party) {
      setState(() {
        _party = false;
        _swap = false;
        _swapTarget = null;
        _slot = _storedSlot;
      });
      return;
    }
    _emit(RuntimeWorldServiceAction.close);
  }

  @override
  Widget build(BuildContext context) {
    final content = snapshot.content;
    final strings = PlayerPcStrings.of(context);
    if (content is! RuntimePcServiceContent) {
      return _InvalidPcOverlay(
        strings: strings,
        onClose: () => _emit(RuntimeWorldServiceAction.close),
      );
    }
    final entries = _party ? content.party : content.stored;
    final entry = _slot >= 0 && _slot < entries.length ? entries[_slot] : null;
    final boxIndex = content.boxes.indexWhere(
      (box) => box.boxId == content.selectedBoxId,
    );
    final box = boxIndex < 0 ? null : content.boxes[boxIndex];
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final action = _party
        ? RuntimeWorldServiceAction.deposit
        : RuntimeWorldServiceAction.withdraw;
    final enabled =
        entry?.canTransfer == true && snapshot.isActionEnabled(action);
    void toggleParty() {
      _focusSurface();
      setState(() {
        if (_party) {
          _party = false;
          _slot = _storedSlot;
        } else {
          _storedSlot = _slot;
          _party = true;
          _slot = 0;
        }
        _swap = false;
      });
    }

    void stepBox(int delta) {
      final next = boxIndex + delta;
      if (_party || boxIndex < 0 || next < 0 || next >= content.boxes.length)
        return;
      _emit(
        RuntimeWorldServiceAction.select,
        targetId: content.boxes[next].boxId,
      );
    }

    return RuntimePlayerTabActions(
      resetToken: content.selectedBoxId,
      onPreviousTab: () => stepBox(-1),
      onNextTab: () => stepBox(1),
      child: RuntimePlayerActions(
        includeDefaultKeyboardShortcuts: false,
        onBack: _back,
        onMenu: _back,
        onInputSourceChanged: (source) =>
            RuntimePlayerInputSourceNotification(source).dispatch(context),
        onPreviousTab: () => stepBox(-1),
        onNextTab: () => stepBox(1),
        child: Focus(
          focusNode: _surfaceFocus,
          autofocus: true,
          child: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.pauseMenu,
            child: Builder(
              builder: (context) {
                final theme = context.playerMenuTheme;
                final footerStyle = TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: theme.actionLabel.copyWith(fontSize: 14),
                  foregroundColor: theme.text,
                  backgroundColor: theme.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: theme.border),
                  ),
                );
                final footer = PlayerMenuFooter(
                  hints: const [],
                  returnAction: const SizedBox.shrink(),
                  padding: EdgeInsets.fromLTRB(
                    PlayerCompanionScope.of(context) ? 0 : 16,
                    PlayerCompanionScope.of(context) ? 4 : 8,
                    PlayerCompanionScope.of(context) ? 0 : 16,
                    PlayerCompanionScope.of(context) ? 12 : 8,
                  ),
                  actionsBuilder: (context, _) => PlayerMenuActionGroup(
                    children: [
                      TextButton(
                        key: ValueKey(
                          'pc-summary-${entry?.targetId ?? 'empty'}',
                        ),
                        onPressed: entry == null
                            ? null
                            : () => _showSummary(context, entry),
                        style: footerStyle,
                        child: Text(french ? 'Résumé' : 'Summary'),
                      ),
                      if (!_party && entry != null)
                        IconButton(
                          key: ValueKey('pc-swap-${entry.targetId}'),
                          tooltip: strings.swapTooltip,
                          onPressed:
                              snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.swap,
                                  ) &&
                                  content.party.isNotEmpty
                              ? () => setState(() {
                                  _swapTarget = entry.targetId;
                                  _storedSlot = _slot;
                                  _party = true;
                                  _swap = true;
                                  _slot = 0;
                                })
                              : null,
                          icon: const Icon(Icons.swap_horiz),
                        ),
                      TextButton(
                        key: ValueKey(
                          _swap
                              ? 'pc-swap-with-${entry?.targetId ?? 'empty'}'
                              : 'pc-${action.name}-${entry?.targetId ?? 'empty'}',
                        ),
                        onPressed: _swap
                            ? entry != null &&
                                      snapshot.isActionEnabled(
                                        RuntimeWorldServiceAction.swap,
                                      )
                                  ? () {
                                      _emit(
                                        RuntimeWorldServiceAction.swap,
                                        targetId: _swapTarget,
                                        secondaryTargetId: entry.targetId,
                                      );
                                      setState(() {
                                        _swap = false;
                                        _party = false;
                                        _slot = 0;
                                      });
                                    }
                                  : null
                            : enabled
                            ? () => _emit(action, targetId: entry!.targetId)
                            : null,
                        style: footerStyle,
                        child: Text(
                          _swap
                              ? strings.swapTooltip
                              : _party
                              ? strings.deposit
                              : strings.withdraw,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('pc-party-toggle'),
                        onPressed: toggleParty,
                        style: footerStyle,
                        child: Text(
                          _party ? (box?.label ?? 'Box') : strings.deposit,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('pc-footer-close'),
                        onPressed:
                            snapshot.isActionEnabled(
                              RuntimeWorldServiceAction.close,
                            )
                            ? () => _emit(RuntimeWorldServiceAction.close)
                            : null,
                        style: footerStyle,
                        child: Text(strings.close),
                      ),
                    ],
                  ),
                );
                return PlayerMenuFrame(
                  scrollable: false,
                  header: Padding(
                    padding: PlayerCompanionScope.of(context)
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        PlayerMenuBackButton(
                          key: const ValueKey('pc-close'),
                          onPressed: _back,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _swap ? strings.swapTooltip : content.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.title.copyWith(fontSize: 22),
                              ),
                              Text(
                                _party
                                    ? strings.party
                                    : '${box?.label ?? 'Box'} · ${box?.count ?? 0}/${box?.capacity ?? 30}',
                                style: theme.meta.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('pc-box-previous'),
                          tooltip: french ? 'Boîte précédente' : 'Previous box',
                          onPressed:
                              !_party &&
                                  boxIndex > 0 &&
                                  snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.select,
                                  )
                              ? () => _emit(
                                  RuntimeWorldServiceAction.select,
                                  targetId: content.boxes[boxIndex - 1].boxId,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          key: const ValueKey('pc-box-next'),
                          tooltip: french ? 'Boîte suivante' : 'Next box',
                          onPressed:
                              !_party &&
                                  boxIndex >= 0 &&
                                  boxIndex + 1 < content.boxes.length &&
                                  snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.select,
                                  )
                              ? () => _emit(
                                  RuntimeWorldServiceAction.select,
                                  targetId: content.boxes[boxIndex + 1].boxId,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  footer: footer,
                  child: LayoutBuilder(
                    builder: (context, area) {
                      final companion = PlayerCompanionScope.of(context);
                      final wide =
                          !companion &&
                          area.maxWidth >= 600 &&
                          MediaQuery.sizeOf(context).width >
                              MediaQuery.sizeOf(context).height;
                      final detailWidth = wide ? 164.0 : 0.0;
                      final availableGridWidth =
                          area.maxWidth - (wide ? detailWidth + 12 : 0);
                      final preferredColumns = _party
                          ? (wide ? 3 : 2)
                          : (wide ? 10 : 6);
                      final fittingColumns = ((availableGridWidth - 4) / 56)
                          .floor();
                      final columns = preferredColumns.clamp(
                        1,
                        fittingColumns < 1 ? 1 : fittingColumns,
                      );
                      final count = _party ? 6 : (box?.capacity ?? 30);
                      final rows = (count / columns).ceil();
                      final gridHeight = rows * 48.0 + (rows - 1) * 8;
                      final showDetailBelow =
                          !wide &&
                          !companion &&
                          area.maxHeight - gridHeight >= 160;
                      final detail = Container(
                        padding: EdgeInsets.only(
                          left: wide ? 16 : 0,
                          top: wide ? 0 : 16,
                        ),
                        decoration: BoxDecoration(
                          border: wide
                              ? Border(left: BorderSide(color: theme.border))
                              : Border(top: BorderSide(color: theme.border)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (entry?.summary case final summary?) ...[
                                  PlayerPokemonImage(
                                    summary: summary,
                                    width: wide ? 40 : 56,
                                    height: wide ? 40 : 56,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    snapshot.safeMessage ??
                                        entry?.unavailableReason ??
                                        (entry == null
                                            ? (entries.isEmpty
                                                  ? (_party
                                                        ? strings.emptyParty
                                                        : strings.emptyBox)
                                                  : strings.emptyPokemon)
                                            : '${entry.label} · ${strings.levelValue(entry.level)}'),
                                    style: theme.body.copyWith(
                                      fontSize: wide ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (entry?.summary case final summary?
                                when area.maxHeight >= 180) ...[
                              const SizedBox(height: 12),
                              PlayerMenuGauge(
                                value: summary.currentHp.toDouble(),
                                maximum: summary.maxHp.toDouble(),
                                label:
                                    '${summary.currentHp} / ${summary.maxHp} ${french ? 'PV' : 'HP'}',
                              ),
                            ],
                          ],
                        ),
                      );
                      final grid = SizedBox(
                        height: gridHeight.clamp(
                          48.0,
                          area.maxHeight < 48 ? 48.0 : area.maxHeight,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.recessed,
                            border: Border.all(color: theme.border),
                          ),
                          child: PlayerMenuDetailTransition(
                            contentKey: ValueKey((
                              'pc',
                              _party,
                              content.selectedBoxId,
                            )),
                            direction: _boxDirection,
                            child: PlayerPagedList(
                              spacing: 8,
                              revealChildKey: ValueKey(
                                'pc-grid-row-${_slot ~/ columns}',
                              ),
                              key: ValueKey('pc-grid-${columns}x$rows'),
                              children: [
                                for (var row = 0; row < rows; row++) ...[
                                  SizedBox(
                                    key: ValueKey('pc-grid-row-$row'),
                                    height: 48,
                                    child: Row(
                                      children: [
                                        for (
                                          var column = 0;
                                          column < columns;
                                          column++
                                        ) ...[
                                          if (column > 0)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                row * columns + column >= count
                                                ? const SizedBox.shrink()
                                                : _cell(
                                                    context,
                                                    entries,
                                                    row * columns + column,
                                                    _party,
                                                  ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (snapshot.stage ==
                              RuntimeWorldServiceStage.applying)
                            const LinearProgressIndicator(),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: grid),
                                const SizedBox(width: 12),
                                SizedBox(width: detailWidth, child: detail),
                              ],
                            )
                          else
                            grid,
                          if (showDetailBelow) ...[
                            const SizedBox(height: 12),
                            detail,
                          ],
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    List<RuntimePcPokemonSnapshot> entries,
    int index,
    bool party,
  ) {
    final entry = index < entries.length ? entries[index] : null;
    final theme = context.playerMenuTheme;
    return Semantics(
      key: ValueKey(party ? 'pc-party-slot-$index' : 'pc-slot-$index'),
      selected: _slot == index,
      label:
          entry?.label ??
          '${PlayerPcStrings.of(context).emptyPokemon} ${index + 1}',
      child: TextButton(
        autofocus: index == 0,
        onPressed: () => setState(() => _slot = index),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(2),
          backgroundColor: theme.panel,
          foregroundColor: theme.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(
              color: _slot == index ? theme.accent : theme.border,
              width: _slot == index ? 3 : 1,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: entry == null
                    ? const SizedBox.shrink()
                    : entry.summary == null
                    ? const Icon(Icons.catching_pokemon, size: 24)
                    : PlayerPokemonImage(
                        summary: entry.summary!,
                        thumbnail: true,
                        width: constraints.maxWidth,
                        height: 42,
                      ),
              ),
              if (party && entry != null)
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.meta,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummary(BuildContext context, RuntimePcPokemonSnapshot entry) {
    final strings = PlayerPcStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => PlayerMenuThemeScope(
        child: Dialog.fullscreen(
          child: PlayerMenuFrame(
            scrollable: false,
            header: PlayerMenuHeader(
              icon: Icons.catching_pokemon,
              title: entry.summary?.displayLabel ?? entry.label,
              secondary: Text(
                '${entry.summary?.speciesLabel ?? _humanize(entry.speciesId)} · ${strings.levelValue(entry.level)}',
              ),
              onBack: () => Navigator.of(context).pop(),
            ),
            footer: PlayerMenuFooter(
              hints: const [],
              returnAction: TextButton(
                key: const ValueKey('pc-summary-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.close),
              ),
            ),
            child: _summaryContent(context, entry, strings),
          ),
        ),
      ),
    );
  }

  Widget _summaryContent(
    BuildContext context,
    RuntimePcPokemonSnapshot entry,
    PlayerPcStrings strings,
  ) {
    if (entry.summary case final summary?) {
      return PlayerPokemonSummarySheet(summary: summary, showHeader: false);
    }
    return PlayerPagedList(
      children: <Widget>[
        Text(
          strings.summaryTitle(entry.label),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: PlayerSpacing.md),
        _SummaryLine(label: strings.species, value: _humanize(entry.speciesId)),
        if (entry.nickname.isNotEmpty)
          _SummaryLine(label: strings.nickname, value: entry.nickname),
        _SummaryLine(label: strings.level, value: '${entry.level}'),
        _SummaryLine(label: strings.currentHp, value: '${entry.currentHp}'),
        _SummaryLine(label: strings.nature, value: _humanize(entry.natureId)),
        _SummaryLine(label: strings.ability, value: _humanize(entry.abilityId)),
        if (entry.gender case final gender?)
          _SummaryLine(label: strings.gender, value: _humanize(gender)),
        _SummaryLine(
          label: strings.status,
          value: entry.statusId.isEmpty
              ? strings.none
              : _humanize(entry.statusId),
        ),
        _SummaryLine(
          label: strings.shiny,
          value: entry.isShiny ? strings.yes : strings.no,
        ),
        _SummaryLine(
          label: strings.heldItem,
          value: entry.heldItemId.isEmpty
              ? strings.none
              : _humanize(entry.heldItemId),
        ),
        _SummaryLine(
          label: strings.moves,
          value: entry.knownMoveIds.isEmpty
              ? strings.none
              : entry.knownMoveIds.map(_humanize).join(', '),
        ),
        _SummaryLine(
          label: strings.friendship,
          value: '${entry.friendship} / 255',
        ),
        _SummaryLine(
          label: strings.origin,
          value: strings.originLabel(entry.originKind),
        ),
        if (entry.metMapId.isNotEmpty)
          _SummaryLine(
            label: strings.metLocation,
            value: _humanize(entry.metMapId),
          ),
        if (entry.metSourceId.isNotEmpty)
          _SummaryLine(
            label: strings.metSource,
            value: _humanize(entry.metSourceId),
          ),
        if (entry.metLevel case final metLevel?)
          _SummaryLine(label: strings.metLevel, value: '$metLevel'),
        if (entry.ballItemId.isNotEmpty)
          _SummaryLine(
            label: strings.captureBall,
            value: _humanize(entry.ballItemId),
          ),
      ],
    );
  }

  String _humanize(String identifier) {
    final words = identifier
        .trim()
        .replaceAll(RegExp('[-_]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return words
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}'
              '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
    child: Text('$label : $value'),
  );
}

class _InvalidPcOverlay extends StatelessWidget {
  const _InvalidPcOverlay({required this.strings, required this.onClose});

  final PlayerPcStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.playerColors.scrim,
    child: Center(
      child: PlayerPanel(
        elevated: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strings.unavailable),
            const SizedBox(height: PlayerSpacing.md),
            PlayerActionButton(
              label: strings.close,
              icon: Icons.close,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    ),
  );
}
