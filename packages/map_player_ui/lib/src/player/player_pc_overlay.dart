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
    return RuntimePlayerActions(
      includeDefaultKeyboardShortcuts: false,
      onBack: _back,
      onMenu: _back,
      onInputSourceChanged: (_) {},
      child: Focus(
        focusNode: _surfaceFocus,
        autofocus: true,
        child: PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.pauseMenu,
          child: Builder(
            builder: (context) => ColoredBox(
              color: context.playerColors.scrim,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1000,
                        maxHeight: 760,
                      ),
                      child: PlayerMenuPanel(
                        primary: true,
                        padding: const EdgeInsets.all(8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final landscape =
                                !PlayerCompanionScope.of(context) &&
                                constraints.maxWidth >
                                    constraints.maxHeight * 1.3 &&
                                constraints.maxWidth >= 560;
                            final columns = _party
                                ? (landscape ? 3 : 2)
                                : (landscape ? 10 : 6);
                            final count = _party ? 6 : (box?.capacity ?? 30);
                            final rows = (count / columns).ceil();
                            final compactHeader = constraints.maxHeight < 500;
                            final boxNavigation = Row(
                              children: [
                                IconButton(
                                  key: const ValueKey('pc-box-previous'),
                                  tooltip: french
                                      ? 'Boîte précédente'
                                      : 'Previous box',
                                  onPressed:
                                      !_party &&
                                          boxIndex > 0 &&
                                          snapshot.isActionEnabled(
                                            RuntimeWorldServiceAction.select,
                                          )
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.select,
                                          targetId:
                                              content.boxes[boxIndex - 1].boxId,
                                        )
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Expanded(
                                  child: Text(
                                    _party
                                        ? strings.party
                                        : compactHeader && entry != null
                                        ? '${box?.label ?? 'Box'} · ${entry.label}'
                                        : '${box?.label ?? 'Box'} · ${box?.count ?? 0}/${box?.capacity ?? 30}',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.playerMenuTheme.label,
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey('pc-box-next'),
                                  tooltip: french
                                      ? 'Boîte suivante'
                                      : 'Next box',
                                  onPressed:
                                      !_party &&
                                          boxIndex >= 0 &&
                                          boxIndex + 1 < content.boxes.length &&
                                          snapshot.isActionEnabled(
                                            RuntimeWorldServiceAction.select,
                                          )
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.select,
                                          targetId:
                                              content.boxes[boxIndex + 1].boxId,
                                        )
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 48,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: compactHeader
                                            ? boxNavigation
                                            : Text(
                                                _swap
                                                    ? strings.swapTooltip
                                                    : content.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context
                                                    .playerMenuTheme
                                                    .title,
                                              ),
                                      ),
                                      IconButton(
                                        key: const ValueKey('pc-party-toggle'),
                                        tooltip: _party
                                            ? (box?.label ?? 'Box')
                                            : strings.deposit,
                                        onPressed: () {
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
                                        },
                                        icon: Icon(
                                          _party
                                              ? Icons.grid_view
                                              : Icons.groups_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        key: const ValueKey('pc-close'),
                                        tooltip: strings.close,
                                        onPressed:
                                            snapshot.isActionEnabled(
                                              RuntimeWorldServiceAction.close,
                                            )
                                            ? () => _emit(
                                                RuntimeWorldServiceAction.close,
                                              )
                                            : null,
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!compactHeader)
                                  SizedBox(height: 48, child: boxNavigation),
                                const SizedBox(height: 12),
                                if (snapshot.stage ==
                                    RuntimeWorldServiceStage.applying)
                                  const LinearProgressIndicator(),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, area) {
                                      final minimumGrid =
                                          rows * 48 + (rows - 1) * 8;
                                      final rowHeight =
                                          area.maxHeight >= minimumGrid
                                          ? (area.maxHeight - (rows - 1) * 8) /
                                                rows
                                          : 48.0;
                                      return PlayerPagedList(
                                        key: ValueKey(
                                          'pc-grid-${columns}x$rows',
                                        ),
                                        revealChildKey: ValueKey(
                                          'pc-grid-row-${_slot ~/ columns}',
                                        ),
                                        children: [
                                          for (var row = 0; row < rows; row++)
                                            SizedBox(
                                              key: ValueKey('pc-grid-row-$row'),
                                              height: rowHeight,
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
                                                          row * columns +
                                                                  column >=
                                                              count
                                                          ? const SizedBox.shrink()
                                                          : _cell(
                                                              context,
                                                              entries,
                                                              row * columns +
                                                                  column,
                                                              _party,
                                                            ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                if (!compactHeader ||
                                    snapshot.safeMessage != null ||
                                    entry?.unavailableReason != null)
                                  SizedBox(
                                    height: 40,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.playerMenuTheme.meta,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 48,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          key: ValueKey(
                                            'pc-summary-${entry?.targetId ?? 'empty'}',
                                          ),
                                          onPressed: entry == null
                                              ? null
                                              : () => _showSummary(
                                                  context,
                                                  entry,
                                                ),
                                          icon: const Icon(Icons.info_outline),
                                          label: Text(strings.summaryTooltip),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!_party && entry != null) ...[
                                        IconButton(
                                          key: ValueKey(
                                            'pc-swap-${entry.targetId}',
                                          ),
                                          tooltip: strings.swapTooltip,
                                          onPressed:
                                              snapshot.isActionEnabled(
                                                    RuntimeWorldServiceAction
                                                        .swap,
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
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: TextButton.icon(
                                          key: ValueKey(
                                            _swap
                                                ? 'pc-swap-with-${entry?.targetId ?? 'empty'}'
                                                : 'pc-${action.name}-${entry?.targetId ?? 'empty'}',
                                          ),
                                          onPressed: _swap
                                              ? entry != null &&
                                                        snapshot.isActionEnabled(
                                                          RuntimeWorldServiceAction
                                                              .swap,
                                                        )
                                                    ? () {
                                                        _emit(
                                                          RuntimeWorldServiceAction
                                                              .swap,
                                                          targetId: _swapTarget,
                                                          secondaryTargetId:
                                                              entry.targetId,
                                                        );
                                                        setState(() {
                                                          _swap = false;
                                                          _party = false;
                                                          _slot = 0;
                                                        });
                                                      }
                                                    : null
                                              : enabled
                                              ? () => _emit(
                                                  action,
                                                  targetId: entry!.targetId,
                                                )
                                              : null,
                                          icon: Icon(
                                            _swap
                                                ? Icons.swap_horiz
                                                : _party
                                                ? Icons.move_to_inbox_outlined
                                                : Icons
                                                      .person_add_alt_1_outlined,
                                          ),
                                          label: Text(
                                            _swap
                                                ? strings.swapTooltip
                                                : _party
                                                ? strings.deposit
                                                : strings.withdraw,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
          backgroundColor: _slot == index ? theme.selectionTop : theme.recessed,
          foregroundColor: _slot == index ? theme.selectionText : theme.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _slot == index ? theme.focus : theme.border,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: entry?.summary == null
                    ? Icon(
                        entry == null ? Icons.add : Icons.catching_pokemon,
                        size: 24,
                      )
                    : PlayerPokemonImage(
                        summary: entry!.summary!,
                        thumbnail: true,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight > 50 ? 42 : 24,
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
        child: Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 640,
            height: MediaQuery.sizeOf(context).height - 48,
            child: PlayerMenuPanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _summaryContent(context, entry, strings)),
                  SizedBox(
                    height: 48,
                    child: TextButton.icon(
                      key: const ValueKey('pc-summary-close'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: Text(strings.close),
                    ),
                  ),
                ],
              ),
            ),
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
      return PlayerPokemonSummarySheet(summary: summary);
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
