import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_bag_strings.dart';
import 'player_party_pokemon_detail.dart';
import 'player_pokemon_image.dart';
import 'player_pokemon_summary_sheet.dart';
import 'player_pokemon_summary_strings.dart';
import 'runtime_player_actions.dart';

final class RuntimePlayerPartyNavigation extends ChangeNotifier {
  bool Function()? _handleBack;
  WidgetBuilder? _actionsBuilder;

  bool back() => _handleBack?.call() ?? false;
  Widget buildActions(BuildContext context) =>
      _actionsBuilder?.call(context) ?? const SizedBox.shrink();

  void refreshActions() => notifyListeners();
}

final class RuntimePlayerPartyCommandFailure implements Exception {
  const RuntimePlayerPartyCommandFailure(this.safeMessage);

  final String safeMessage;
}

class RuntimePlayerParty extends StatefulWidget {
  const RuntimePlayerParty(
      {super.key,
      required this.detail,
      required this.onCommand,
      this.canReorder = false,
      this.navigation});

  final RuntimePlayerPauseDetailSnapshot detail;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onCommand;
  final bool canReorder;
  final RuntimePlayerPartyNavigation? navigation;

  @override
  State<RuntimePlayerParty> createState() => _RuntimePlayerPartyState();
}

class _RuntimePlayerPartyState extends State<RuntimePlayerParty> {
  final _nodes = <String, FocusNode>{};
  final _detailFocus = FocusNode(debugLabel: 'Party detail');
  String? _selectedId;
  String? _swapSourceId;
  bool _busy = false;
  bool _showDetail = false;
  String? _failure;

  bool get _french => Localizations.localeOf(context).languageCode == 'fr';
  String _text(String french, String english) => _french ? french : english;
  String _id(RuntimePlayerDetailEntrySnapshot entry) =>
      entry.pokemonSummary?.hasStableIdentity == true
          ? entry.pokemonSummary!.individualId
          : entry.id;
  int get _selectedIndex =>
      widget.detail.entries.indexWhere((e) => _id(e) == _selectedId);
  RuntimePlayerDetailEntrySnapshot get _selected =>
      widget.detail.entries[_selectedIndex < 0 ? 0 : _selectedIndex];
  FocusNode _node(String id) =>
      _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'Party $id'));

  @override
  void initState() {
    super.initState();
    widget.navigation?._handleBack = _back;
    widget.navigation?._actionsBuilder = _footerActions;
    if (widget.detail.entries.isNotEmpty) {
      _selectedId = _id(widget.detail.entries.first);
      _returnToMember();
    }
  }

  @override
  void didUpdateWidget(RuntimePlayerParty oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      oldWidget.navigation?._handleBack = null;
      oldWidget.navigation?._actionsBuilder = null;
      widget.navigation?._handleBack = _back;
      widget.navigation?._actionsBuilder = _footerActions;
    }
    if (_selectedIndex < 0 && widget.detail.entries.isNotEmpty) {
      final previous =
          oldWidget.detail.entries.indexWhere((e) => _id(e) == _selectedId);
      _selectedId = _id(widget
          .detail.entries[previous.clamp(0, widget.detail.entries.length - 1)]);
      _returnToMember();
    }
    if (!widget.detail.entries.any((e) => _id(e) == _swapSourceId)) {
      _swapSourceId = null;
    }
  }

  @override
  void dispose() {
    widget.navigation?._handleBack = null;
    widget.navigation?._actionsBuilder = null;
    for (final node in _nodes.values) {
      node.dispose();
    }
    _detailFocus.dispose();
    super.dispose();
  }

  void _select(RuntimePlayerDetailEntrySnapshot entry) {
    if (_busy || _selectedId == _id(entry)) return;
    setState(() => _selectedId = _id(entry));
  }

  void _returnToMember() {
    final selectedId = _selectedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent != false &&
          selectedId != null &&
          widget.detail.entries.any((entry) => _id(entry) == selectedId)) {
        _node(selectedId).requestFocus();
      }
    });
  }

  Future<void> _emit(RuntimePlayerPauseCommand command) async {
    if (_busy || widget.onCommand == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await widget.onCommand!(command);
    } on RuntimePlayerPartyCommandFailure catch (failure) {
      if (mounted) _failure = failure.safeMessage;
    } catch (_) {
      if (mounted) {
        _failure = _text('Cette action n’a pas pu être effectuée. Réessayez.',
            'The action could not be completed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _activate(RuntimePlayerDetailEntrySnapshot entry, bool compact) {
    if (_busy) return;
    final sourceId = _swapSourceId;
    if (sourceId != null) {
      final source =
          widget.detail.entries.where((e) => _id(e) == sourceId).firstOrNull;
      if (source == null || sourceId == _id(entry)) return;
      setState(() {
        _selectedId = sourceId;
        _swapSourceId = null;
      });
      unawaited(_emit(RuntimePlayerPauseCommand.reorderPartyMember(
        partyTargetId: source.pokemonSummary?.targetId ?? source.id,
        secondPartyTargetId: entry.pokemonSummary?.targetId ?? entry.id,
      )).then((_) => _returnToMember()));
    } else {
      _select(entry);
      if (compact) {
        setState(() => _showDetail = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _showDetail) _detailFocus.requestFocus();
        });
      } else {
        _showActions();
      }
    }
  }

  bool _back() {
    if (_swapSourceId == null && !_showDetail) return false;
    setState(() {
      _swapSourceId = null;
      _showDetail = false;
    });
    _returnToMember();
    return true;
  }

  Object? _input(RuntimePlayerLogicalIntent intent) {
    if (intent.action == PlayerInputAction.back && _back()) {
      return null;
    }
    return Actions.maybeInvoke(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    final navigation = widget.navigation;
    if (navigation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.navigation == navigation) {
          navigation.refreshActions();
        }
      });
    }
    if (widget.detail.entries.isEmpty) {
      return PlayerMenuFeedback(
          key: const ValueKey('runtime-player-detail-empty'),
          id: 'party-empty',
          title: _text('Votre équipe est vide', 'Your party is empty'),
          message: widget.detail.emptyMessage);
    }
    return Actions(
      actions: {
        RuntimePlayerLogicalIntent:
            CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: _input)
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape):
              RuntimePlayerLogicalIntent(PlayerInputAction.back,
                  source: PlayerInputSource.keyboard)
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 760 ||
              constraints.maxWidth < 1024 &&
                  constraints.maxHeight > constraints.maxWidth ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.8;
          final list = _list(compact);
          final detail = _detail();
          final bounded = constraints.hasBoundedHeight;
          Widget scroll(Widget child, String id) =>
              SingleChildScrollView(key: ValueKey(id), child: child);
          final body = compact
              ? scroll(_showDetail && _swapSourceId == null ? detail : list,
                  'party-compact-scroll')
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      flex: 18,
                      child:
                          bounded ? scroll(list, 'party-list-scroll') : list),
                  const SizedBox(width: 24),
                  Expanded(
                      flex: 35,
                      child: bounded
                          ? scroll(detail, 'party-detail-scroll')
                          : detail),
                ]);
          return Column(
              key: const ValueKey('runtime-player-detail-party'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (_swapSourceId != null) ...[
                  PlayerMenuFeedback(
                      id: 'party-swap-instruction',
                      title: _text(
                          'Choisissez le Pokémon avec lequel échanger la place',
                          'Choose the Pokémon to swap places with'),
                      action: PlayerActionButton(
                          key: const ValueKey('party-swap-cancel'),
                          icon: Icons.arrow_back,
                          label: context.playerL10n.back,
                          onPressed: () {
                            setState(() => _swapSourceId = null);
                            _returnToMember();
                          })),
                  const SizedBox(height: 8),
                ],
                if (_failure ?? widget.detail.message case final message?
                    when message.isNotEmpty) ...[
                  Semantics(
                      liveRegion: true,
                      child: Text(message,
                          key: const ValueKey('party-command-message'),
                          style: context.playerMenuTheme.meta)),
                  const SizedBox(height: 8),
                ],
                if (bounded) Expanded(child: body) else body,
              ]);
        }),
      ),
    );
  }

  Widget _list(bool compact) {
    final strings = PlayerPokemonSummaryStrings.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final entry in widget.detail.entries) ...[
        Builder(builder: (context) {
          final summary = entry.pokemonSummary;
          final status = summary?.isFainted == true
              ? _text('KO', 'Fainted')
              : summary?.statusLabel;
          return PlayerMenuSelectableRow(
            key: ValueKey('party-member-${_id(entry)}'),
            id: 'party-member-${_id(entry)}',
            label: summary?.displayLabel ?? entry.title,
            subtitle: summary == null
                ? entry.subtitle
                : '${strings.levelValue(summary.level)} · ${strings.hp} ${strings.hpValue(summary.currentHp, summary.maxHp)}',
            semanticValue: summary == null
                ? null
                : '${strings.hpValue(summary.currentHp, summary.maxHp)}${status == null ? '' : ' · $status'}',
            selected: _selectedId == _id(entry),
            focusNode: _node(_id(entry)),
            onFocusChanged: (focused) {
              if (focused) _select(entry);
            },
            minimumHeight: 94,
            leading: summary == null
                ? const Icon(Icons.catching_pokemon)
                : PlayerMenuPortrait(
                    circular: true,
                    child: PlayerPokemonImage(
                        summary: summary,
                        thumbnail: true,
                        width: 56,
                        height: 56)),
            trailing: _swapSourceId == _id(entry)
                ? Icon(Icons.swap_vert,
                    key: const ValueKey('party-swap-source'))
                : summary?.genderLabel == null && status == null
                    ? null
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        if (summary?.genderLabel case final gender?)
                          Text(gender, style: context.playerMenuTheme.meta),
                        if (status != null)
                          PlayerMenuBadge(
                              label: status, kind: PlayerMenuBadgeKind.status),
                      ]),
            supportingContent: summary == null
                ? null
                : PlayerMenuGauge(
                    value: summary.currentHp.toDouble(),
                    maximum: summary.maxHp.toDouble(),
                    label: strings.hp,
                    showLabel: false,
                    tone: summary.hpRatio <= .2
                        ? PlayerMenuGaugeTone.danger
                        : summary.hpRatio <= .5
                            ? PlayerMenuGaugeTone.warning
                            : PlayerMenuGaugeTone.normal),
            busy: _busy,
            onPressed: () => _activate(entry, compact),
          );
        }),
        if (entry != widget.detail.entries.last ||
            widget.detail.entries.length < 6)
          const SizedBox(height: 16),
      ],
      for (var index = widget.detail.entries.length; index < 6; index++) ...[
        ExcludeSemantics(
            child: PlayerMenuPanel(
                key: ValueKey('party-empty-slot-$index'),
                padding: const EdgeInsets.all(12),
                child: const SizedBox(
                    height: 70, child: Center(child: Text('—'))))),
        if (index < 5) const SizedBox(height: 16),
      ],
    ]);
  }

  Widget _detail() {
    final entry = _selected;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (entry.pokemonSummary case final summary?)
        PlayerPartyPokemonDetail(
            key: ValueKey('party-selected-${_id(entry)}'), summary: summary),
      if (widget.navigation == null) ...[
        const SizedBox(height: 12),
        _actions(entry),
      ],
      if (_showDetail) ...[
        const SizedBox(height: 8),
        PlayerActionButton(
            key: const ValueKey('party-back-to-list'),
            icon: Icons.arrow_back,
            label: _text('Retour à l’équipe', 'Back to party'),
            secondary: true,
            onPressed: () {
              setState(() => _showDetail = false);
              _returnToMember();
            }),
      ],
    ]);
  }

  Widget _footerActions(BuildContext context) => widget.detail.entries.isEmpty
      ? const SizedBox.shrink()
      : PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.party,
          child: _actions(_selected, integrated: true),
        );

  Widget _actions(RuntimePlayerDetailEntrySnapshot entry,
      {bool modal = false, bool integrated = false}) {
    void close() {
      if (modal) Navigator.of(context).pop();
    }

    final actions = <PlayerActionButton>[
      if (entry.pokemonSummary case final summary?)
        PlayerActionButton(
            key: ValueKey('runtime-player-party-summary-${summary.targetId}'),
            expandWidth: false,
            focusNode: modal ? null : _detailFocus,
            label: integrated
                ? _text('Résumé', 'Summary')
                : PlayerPokemonSummaryStrings.of(context).viewSummary,
            icon: Icons.info_outline,
            secondary: true,
            onPressed: () {
              close();
              unawaited(
                  showPlayerPokemonSummaryDialog(context, summary: summary)
                      .then((_) => _returnToMember()));
            }),
      if (entry.heldItemAction case final held?)
        PlayerActionButton(
            key: ValueKey('runtime-player-held-manage-${held.partyTargetId}'),
            expandWidth: false,
            label: integrated
                ? _text('Objet', 'Item')
                : PlayerBagStrings.of(context).manageHeldItem,
            icon: Icons.auto_awesome_rounded,
            secondary: true,
            onPressed: _busy || widget.onCommand == null
                ? null
                : () {
                    close();
                    _showHeldItems(context, held);
                  }),
      if (widget.canReorder && widget.detail.entries.length > 1)
        PlayerActionButton(
            key: const ValueKey('party-swap'),
            expandWidth: false,
            label: _text('Échanger', 'Swap places'),
            icon: Icons.swap_vert,
            secondary: true,
            onPressed: _busy || widget.onCommand == null
                ? null
                : () {
                    close();
                    setState(() {
                      _swapSourceId = _id(entry);
                      _showDetail = false;
                    });
                    _returnToMember();
                  }),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final action in actions)
        if (integrated)
          IntrinsicWidth(
            child: PlayerMenuSelectableRow(
              key: action.key,
              id: (action.key! as ValueKey<String>).value,
              label: action.label,
              leading: Icon(action.icon),
              focusNode: action.focusNode,
              integrated: true,
              disabledReason: action.onPressed == null
                  ? context.playerL10n.actionUnavailable
                  : null,
              onPressed: action.onPressed,
            ),
          )
        else
          action,
    ]);
  }

  void _showActions() {
    final entry = _selected;
    showDialog<void>(
        context: context,
        builder: (_) => PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.party,
            child: Dialog(
                child: SingleChildScrollView(
                    child: PlayerMenuPanel(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                  Text(entry.title, style: context.playerMenuTheme.subtitle),
                  const SizedBox(height: 12),
                  _actions(entry, modal: true),
                  const SizedBox(height: 12),
                  PlayerActionButton(
                      label: context.playerL10n.back,
                      icon: Icons.arrow_back,
                      secondary: true,
                      onPressed: () => Navigator.of(context).pop()),
                ])))))).then((_) => _returnToMember());
  }

  void _showHeldItems(
      BuildContext context, RuntimePlayerHeldItemActionSnapshot action) {
    final strings = PlayerBagStrings.of(context);
    showDialog<void>(
        context: context,
        builder: (_) => PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.party,
            child: Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 520, maxHeight: 640),
                  child: SingleChildScrollView(
                      key: const ValueKey('party-held-dialog-scroll'),
                      child: PlayerMenuPanel(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Text(
                                strings.heldItemSummary(
                                    action.currentItemLabel ??
                                        PlayerPokemonSummaryStrings.of(context)
                                            .none),
                                style: context.playerMenuTheme.subtitle),
                            const SizedBox(height: 8),
                            Text(
                                _text(
                                    'Donner retire un objet du sac. Remplacer ou retirer remet l’objet actuel dans le sac.',
                                    'Giving takes one item from the bag. Replacing or taking returns the current item to the bag.'),
                                style: context.playerMenuTheme.meta),
                            const SizedBox(height: 12),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final option in action.options)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: PlayerActionButton(
                                            key: ValueKey(
                                                'runtime-player-held-option-${action.partyTargetId}-${option.itemTargetId}'),
                                            label: action.hasCurrentItem
                                                ? strings.replaceHeldItem(
                                                    option.label)
                                                : strings
                                                    .giveHeldItem(option.label),
                                            icon: Icons.swap_horiz,
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              unawaited(_emit(
                                                  RuntimePlayerPauseCommand
                                                      .equipHeldItem(
                                                          itemTargetId: option
                                                              .itemTargetId,
                                                          partyTargetId: action
                                                              .partyTargetId)));
                                            })),
                                  if (action.options.isEmpty)
                                    Text(_text(
                                        'Aucun objet compatible dans le sac.',
                                        'No compatible item in the bag.')),
                                ]),
                            if (action.currentItemLabel case final item?)
                              PlayerActionButton(
                                  key: ValueKey(
                                      'runtime-player-held-take-${action.partyTargetId}'),
                                  label: strings.takeHeldItem(item),
                                  icon: Icons.remove_circle_outline,
                                  secondary: true,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    unawaited(_emit(RuntimePlayerPauseCommand
                                        .unequipHeldItem(
                                            partyTargetId:
                                                action.partyTargetId)));
                                  }),
                            const SizedBox(height: 8),
                            PlayerActionButton(
                                key:
                                    const ValueKey('runtime-player-held-close'),
                                icon: Icons.close,
                                label: strings.close,
                                secondary: true,
                                onPressed: () => Navigator.of(context).pop()),
                          ])))),
            ))).then((_) => _returnToMember());
  }
}
