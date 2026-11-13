import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderStoryFactPicker extends StatefulWidget {
  const MapBuilderStoryFactPicker({
    super.key,
    required this.facts,
    required this.onPick,
    required this.onClose,
    this.onCreate,
  });

  static const shown = 8;

  final List<NarrativeFactDefinition> facts;
  final ValueChanged<NarrativeFactDefinition> onPick;
  final VoidCallback onClose;
  final void Function(String label, NarrativeValueKind kind)? onCreate;

  @override
  State<MapBuilderStoryFactPicker> createState() =>
      _MapBuilderStoryFactPickerState();
}

class _MapBuilderStoryFactPickerState extends State<MapBuilderStoryFactPicker> {
  final _search = TextEditingController();
  var _query = '';
  var _label = '';
  var _kind = NarrativeValueKind.boolean;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<NarrativeFactDefinition> get _matches {
    final needle = _query.trim().toLowerCase();
    return [
      for (final fact in widget.facts)
        if (needle.isEmpty ||
            fact.label.toLowerCase().contains(needle) ||
            fact.id.toLowerCase().contains(needle))
          fact,
    ].take(MapBuilderStoryFactPicker.shown).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final matches = _matches;
    final create = widget.onCreate;
    return Column(
      key: const ValueKey('map-story-fact-picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSearchField(
          key: const ValueKey('map-story-fact-search'),
          controller: _search,
          label: l10n.storyFactSearch,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: StudioSpacing.xs),
        if (matches.isEmpty)
          Text(
            l10n.storyFactNoMatch,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final fact in matches)
          StudioChoice(
            key: ValueKey('map-story-fact-${fact.id}'),
            dense: true,
            label: fact.label,
            subtitle: l10n.storyFactKind(fact.initialValue.kind.name),
            onTap: () => widget.onPick(fact),
          ),
        if (create != null) ...[
          const SizedBox(height: StudioSpacing.s),
          StudioDraftField(
            key: const ValueKey('map-story-fact-new-label'),
            value: _label,
            label: l10n.storyFactNewLabel,
            onChanged: (value) => setState(() => _label = value),
          ),
          const SizedBox(height: StudioSpacing.xs),
          StudioSelect(
            key: const ValueKey('map-story-fact-new-kind'),
            label: l10n.storyFactKindField,
            value: _kind.name,
            options: {
              for (final kind in const [
                NarrativeValueKind.boolean,
                NarrativeValueKind.integer,
              ])
                kind.name: l10n.storyFactKind(kind.name),
            },
            onChanged: (value) =>
                setState(() => _kind = NarrativeValueKind.values.byName(value)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('map-story-fact-new'),
              variant: StudioButtonVariant.quiet,
              icon: Icons.add,
              label: l10n.storyFactCreate,
              onPressed: _label.trim().isEmpty
                  ? null
                  : () => create(_label.trim(), _kind),
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            key: const ValueKey('map-story-fact-close'),
            variant: StudioButtonVariant.quiet,
            label: l10n.storyFactClose,
            onPressed: widget.onClose,
          ),
        ),
      ],
    );
  }
}
