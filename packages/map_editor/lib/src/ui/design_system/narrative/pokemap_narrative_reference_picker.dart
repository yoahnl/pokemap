import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../pokemap_badge.dart';
import '../pokemap_button.dart';
import '../pokemap_card.dart';
import '../pokemap_empty_state.dart';
import '../pokemap_icon_button.dart';
import '../pokemap_search_field.dart';

/// Shared no-code picker for references exposed by the canonical dependency
/// index.
///
/// It deliberately selects existing project assets only. Physical map sources
/// continue to be authored in Map Editor and are never created from here.
class PokeMapNarrativeReferencePicker extends StatefulWidget {
  const PokeMapNarrativeReferencePicker({
    super.key,
    required this.label,
    required this.readModel,
    required this.selectedKey,
    required this.onSelected,
    this.onOpen,
    this.enabled = true,
    this.maxListHeight = 360,
  }) : assert(maxListHeight > 0);

  final String label;
  final CanonicalNarrativeReferencePickerReadModel readModel;
  final NarrativeDependencyKey? selectedKey;
  final ValueChanged<CanonicalNarrativeReferenceOption> onSelected;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;
  final bool enabled;
  final double maxListHeight;

  @override
  State<PokeMapNarrativeReferencePicker> createState() =>
      _PokeMapNarrativeReferencePickerState();
}

class _PokeMapNarrativeReferencePickerState
    extends State<PokeMapNarrativeReferencePicker> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'narrative-reference-search',
  );
  final Map<NarrativeDependencyKey, FocusNode> _optionFocusNodes =
      <NarrativeDependencyKey, FocusNode>{};
  String _query = '';

  CanonicalNarrativeReferencePickerReadModel get _visibleModel =>
      widget.readModel.search(_query);

  List<CanonicalNarrativeReferenceOption> get _visibleOptions =>
      _visibleModel.options.toList(growable: false);

  List<CanonicalNarrativeReferenceOption> get _availableVisibleOptions =>
      _visibleOptions
          .where(
            (option) =>
                option.availability == NarrativeReferenceAvailability.available,
          )
          .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _synchronizeFocusNodes(_visibleOptions.map((option) => option.key).toSet());
  }

  @override
  void didUpdateWidget(covariant PokeMapNarrativeReferencePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = _visibleOptions.map((option) => option.key).toSet();
    final focusedKey = _focusedOptionKey();
    if (!widget.enabled || (focusedKey != null && !keys.contains(focusedKey))) {
      _searchFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    _synchronizeFocusNodes(keys);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final node in _optionFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _synchronizeFocusNodes(Set<NarrativeDependencyKey> visibleKeys) {
    for (final key in visibleKeys) {
      _optionFocusNodes.putIfAbsent(
        key,
        () => FocusNode(debugLabel: 'narrative-reference-$key'),
      );
    }
    final removedKeys = _optionFocusNodes.keys
        .where((key) => !visibleKeys.contains(key))
        .toList(growable: false);
    for (final key in removedKeys) {
      _optionFocusNodes.remove(key)?.dispose();
    }
  }

  NarrativeDependencyKey? _focusedOptionKey() {
    for (final entry in _optionFocusNodes.entries) {
      if (entry.value.hasFocus) return entry.key;
    }
    return null;
  }

  void _handleQueryChanged(String value) {
    if (!widget.enabled) return;
    final focusedKey = _focusedOptionKey();
    final nextModel = widget.readModel.search(value);
    final nextKeys = nextModel.options.map((option) => option.key).toSet();
    if (focusedKey != null && !nextKeys.contains(focusedKey)) {
      _searchFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    setState(() {
      _query = value;
      _synchronizeFocusNodes(nextKeys);
    });
  }

  void _moveOptionFocus(int delta) {
    if (!widget.enabled) return;
    final options = _availableVisibleOptions;
    if (options.isEmpty) {
      _searchFocusNode.requestFocus();
      return;
    }

    final currentKey = _focusedOptionKey();
    var currentIndex = options.indexWhere((option) => option.key == currentKey);
    if (currentIndex < 0) {
      currentIndex = delta > 0 ? -1 : 0;
    }
    final nextIndex = (currentIndex + delta) % options.length;
    _optionFocusNodes[options[nextIndex].key]?.requestFocus();
  }

  void _select(CanonicalNarrativeReferenceOption option) {
    if (!widget.enabled ||
        option.availability != NarrativeReferenceAvailability.available) {
      return;
    }
    widget.onSelected(option);
  }

  Future<void> _copy(CanonicalNarrativeReferenceOption option) async {
    if (!widget.enabled) return;
    await Clipboard.setData(ClipboardData(text: option.technicalId));
  }

  void _open(CanonicalNarrativeReferenceOption option) {
    if (!widget.enabled) return;
    final intent = option.navigationIntent;
    if (intent != null) widget.onOpen?.call(intent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final model = _visibleModel;
    final hasAnyResult = model.options.isNotEmpty ||
        model.missingSelection != null ||
        model.incompatibleSelection != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final referenceList = hasAnyResult
            ? ListView(
                shrinkWrap: !constraints.hasBoundedHeight,
                children: <Widget>[
                  if (model.incompatibleSelection
                      case final incompatible?) ...<Widget>[
                    _ExceptionalReferenceCard(
                      option: incompatible,
                      enabled: widget.enabled,
                      onCopy: () => _copy(incompatible),
                      onOpen: incompatible.navigationIntent != null &&
                              widget.onOpen != null
                          ? () => _open(incompatible)
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (model.missingSelection case final missing?) ...<Widget>[
                    _ExceptionalReferenceCard(
                      option: missing,
                      enabled: widget.enabled,
                      onCopy: () => _copy(missing),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final group in model.groups) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        group.label,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final option in group.options) ...<Widget>[
                      _buildOptionRow(context, option),
                      const SizedBox(height: 7),
                    ],
                    const SizedBox(height: 3),
                  ],
                ],
              )
            : const PokeMapEmptyState(
                title: 'Aucune référence disponible',
                description: 'Créez ou publiez une référence compatible.',
                icon: Icon(Icons.link_off_rounded),
              );
        final listRegion = constraints.hasBoundedHeight
            ? Expanded(child: referenceList)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxListHeight),
                child: referenceList,
              );

        return FocusTraversalGroup(
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _moveOptionFocus(1),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _moveOptionFocus(-1),
              const SingleActivator(LogicalKeyboardKey.escape):
                  _searchFocusNode.requestFocus,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.enabled
                        ? colors.textPrimary
                        : colors.textDisabled,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                PokeMapSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  semanticLabel: 'Rechercher dans ${widget.label}',
                  hintText: 'Rechercher une référence…',
                  enabled: widget.enabled,
                  onChanged: _handleQueryChanged,
                  onClear: () => _handleQueryChanged(''),
                ),
                const SizedBox(height: 10),
                listRegion,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionRow(
    BuildContext context,
    CanonicalNarrativeReferenceOption option,
  ) {
    final focusNode = _optionFocusNodes[option.key]!;
    final isAvailable =
        option.availability == NarrativeReferenceAvailability.available;
    final canSelect = widget.enabled && isAvailable;
    focusNode
      ..canRequestFocus = canSelect
      ..skipTraversal = !canSelect;

    return FocusableActionDetector(
      key: ValueKey<NarrativeDependencyKey>(option.key),
      focusNode: focusNode,
      enabled: canSelect,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _select(option);
            return null;
          },
        ),
      },
      onFocusChange: (_) {
        if (mounted) setState(() {});
      },
      child: ExcludeFocus(
        excluding: !widget.enabled,
        child: PokeMapCard(
          focused: focusNode.hasFocus,
          selected: widget.selectedKey == option.key,
          onTap: canSelect ? () => _select(option) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                container: true,
                enabled: widget.enabled && isAvailable,
                button: isAvailable,
                label: _semanticLabel(option),
                excludeSemantics: true,
                child: _OptionSummary(option: option),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  PokeMapBadge(
                    label: option.kindLabel,
                    variant: PokeMapBadgeVariant.narrative,
                  ),
                  PokeMapBadge(
                    label: _publicationLabel(option.publicationStatus),
                    variant: _publicationVariant(option.publicationStatus),
                  ),
                  if (option.usageCount > 0)
                    PokeMapBadge(label: '${option.usageCount} usages'),
                  PokeMapIconButton(
                    key: ValueKey<String>(_actionKey('copy', option.key)),
                    onPressed: widget.enabled ? () => _copy(option) : null,
                    tooltip: 'Copier l’identifiant ${option.technicalId}',
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  if (option.navigationIntent != null && widget.onOpen != null)
                    PokeMapIconButton(
                      key: ValueKey<String>(_actionKey('open', option.key)),
                      onPressed: widget.enabled ? () => _open(option) : null,
                      tooltip: 'Ouvrir ${option.label}',
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  PokeMapButton(
                    key: ValueKey<String>(_actionKey('select', option.key)),
                    onPressed: widget.enabled && isAvailable
                        ? () => _select(option)
                        : null,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    child: const Text('Choisir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSummary extends StatelessWidget {
  const _OptionSummary({required this.option});

  final CanonicalNarrativeReferenceOption option;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final breadcrumb = option.breadcrumbLabels.join(' › ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          option.label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          option.technicalId,
          style: TextStyle(color: colors.textMuted, fontSize: 11),
        ),
        if (breadcrumb.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            breadcrumb,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
        if (option.diagnostic case final diagnostic?) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            diagnostic,
            style: TextStyle(
              color: option.availability ==
                      NarrativeReferenceAvailability.incompatible
                  ? colors.warning
                  : colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExceptionalReferenceCard extends StatelessWidget {
  const _ExceptionalReferenceCard({
    required this.option,
    required this.enabled,
    required this.onCopy,
    this.onOpen,
  });

  final CanonicalNarrativeReferenceOption option;
  final bool enabled;
  final VoidCallback onCopy;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isMissing =
        option.availability == NarrativeReferenceAvailability.missing;
    final statusLabel = isMissing ? 'Référence manquante' : 'Incompatible';
    return PokeMapCard(
      key: ValueKey<String>(isMissing
          ? 'narrative-reference-missing'
          : 'narrative-reference-incompatible-selection'),
      child: Semantics(
        container: true,
        label: '${option.label}, ${option.technicalId}, '
            '${isMissing ? 'manquante' : 'incompatible'}'
            '${option.diagnostic == null ? '' : ', ${option.diagnostic}'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isMissing ? Icons.link_off_rounded : Icons.block_rounded,
                  size: 16,
                  color: isMissing ? colors.error : colors.warning,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PokeMapBadge(
                  label: statusLabel,
                  variant: isMissing
                      ? PokeMapBadgeVariant.error
                      : PokeMapBadgeVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    option.technicalId,
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ),
                PokeMapIconButton(
                  key: ValueKey<String>(_actionKey('copy', option.key)),
                  onPressed: enabled ? onCopy : null,
                  tooltip: 'Copier l’identifiant ${option.technicalId}',
                  icon: const Icon(Icons.copy_rounded),
                ),
                if (onOpen != null)
                  PokeMapIconButton(
                    key: ValueKey<String>(_actionKey('open', option.key)),
                    onPressed: enabled ? onOpen : null,
                    tooltip: 'Ouvrir ${option.label}',
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
              ],
            ),
            if (option.diagnostic case final diagnostic?) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                diagnostic,
                style: TextStyle(
                  color: isMissing ? colors.error : colors.warning,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _semanticLabel(CanonicalNarrativeReferenceOption option) {
  final parts = <String>[
    option.label,
    option.technicalId,
    switch (option.availability) {
      NarrativeReferenceAvailability.available => 'disponible',
      NarrativeReferenceAvailability.incompatible => 'incompatible',
      NarrativeReferenceAvailability.missing => 'manquante',
    },
    if (option.breadcrumbLabels.isNotEmpty) option.breadcrumbLabels.join(' › '),
    ?option.diagnostic,
  ];
  return parts.join(', ');
}

String _publicationLabel(NarrativeReferencePublicationStatus status) {
  return switch (status) {
    NarrativeReferencePublicationStatus.published => 'Publié',
    NarrativeReferencePublicationStatus.draft => 'Brouillon',
    NarrativeReferencePublicationStatus.inactive => 'Inactif',
    NarrativeReferencePublicationStatus.legacy => 'Ancien format',
    NarrativeReferencePublicationStatus.unknown => 'Statut inconnu',
  };
}

PokeMapBadgeVariant _publicationVariant(
  NarrativeReferencePublicationStatus status,
) {
  return switch (status) {
    NarrativeReferencePublicationStatus.published =>
      PokeMapBadgeVariant.success,
    NarrativeReferencePublicationStatus.draft => PokeMapBadgeVariant.warning,
    NarrativeReferencePublicationStatus.inactive => PokeMapBadgeVariant.neutral,
    NarrativeReferencePublicationStatus.legacy => PokeMapBadgeVariant.warning,
    NarrativeReferencePublicationStatus.unknown => PokeMapBadgeVariant.error,
  };
}

String _actionKey(String action, NarrativeDependencyKey key) =>
    'narrative-reference-$action-${key.kind.name}-${key.id}-'
    '${key.scope ?? ''}-${key.parentId ?? ''}-${key.sourceKind ?? ''}';
