part of '../step_studio_workspace.dart';

// Blocs UI locaux du Step Studio.
//
// On les garde dans la même library via `part` pour préserver les helpers
// privés existants et éviter un renommage massif. Le but du lot est
// structurel : alléger le fichier racine du workspace sans changer son
// comportement.

class _StepSectionCard extends StatelessWidget {
  const _StepSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineInfoBanner extends StatelessWidget {
  const _InlineInfoBanner({
    required this.accent,
    required this.text,
  });

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InlineTextField extends StatefulWidget {
  const _InlineTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int minLines;
  final int maxLines;

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorEmbeddedSectionLabel(widget.label),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: _controller,
          enabled: widget.enabled,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onChanged: widget.onChanged,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimpleOption {
  const _SimpleOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _SimpleDropdown extends StatelessWidget {
  const _SimpleDropdown({
    required this.accent,
    required this.fieldLabel,
    required this.options,
    required this.selectedId,
    required this.emptyLabel,
    required this.enabled,
    required this.onSelected,
    this.treatInvalidSelectionAsUnset = false,
  });

  final Color accent;
  final String fieldLabel;
  final List<_SimpleOption> options;
  final String? selectedId;
  final String emptyLabel;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final bool treatInvalidSelectionAsUnset;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: fieldLabel,
        valueLabel: emptyLabel,
        orderedIds: const <String>[],
        selectedMenuValue: '',
        idToLabel: (_) => '',
        onSelected: (_) {},
      );
    }
    final trimmed = selectedId?.trim();
    _SimpleOption? match;
    if (trimmed != null && trimmed.isNotEmpty) {
      for (final entry in options) {
        if (entry.id == trimmed) {
          match = entry;
          break;
        }
      }
    }
    final selected =
        match ?? (!treatInvalidSelectionAsUnset ? options.first : null);
    if (selected == null) {
      return IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.65,
          child: InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: fieldLabel,
            valueLabel: emptyLabel,
            orderedIds:
                options.map((entry) => entry.id).toList(growable: false),
            selectedMenuValue: '',
            selectedIdForCheck: null,
            allowUnsetSelection: true,
            idToLabel: (id) {
              for (final entry in options) {
                if (entry.id == id) {
                  return entry.label;
                }
              }
              return id;
            },
            onSelected: (id) => onSelected(id),
          ),
        ),
      );
    }
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.65,
        child: InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: fieldLabel,
          valueLabel: selected.label,
          orderedIds: options.map((entry) => entry.id).toList(growable: false),
          selectedMenuValue: selected.id,
          selectedIdForCheck: selected.id,
          allowUnsetSelection: false,
          idToLabel: (id) {
            for (final entry in options) {
              if (entry.id == id) {
                return entry.label;
              }
            }
            return id;
          },
          onSelected: (id) => onSelected(id),
        ),
      ),
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  const _EnumDropdown({
    required this.accent,
    required this.fieldLabel,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.enabled,
    required this.onChanged,
  });

  final Color accent;
  final String fieldLabel;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SimpleDropdown(
      accent: accent,
      fieldLabel: fieldLabel,
      options: values
          .map(
            (entry) => _SimpleOption(
              id: entry.name,
              label: labelBuilder(entry),
            ),
          )
          .toList(growable: false),
      selectedId: value.name,
      emptyLabel: '—',
      enabled: enabled,
      onSelected: (id) {
        if (id == null) return;
        for (final entry in values) {
          if (entry.name == id) {
            onChanged(entry);
            return;
          }
        }
      },
    );
  }
}

class _CutsceneLinkRow extends StatelessWidget {
  const _CutsceneLinkRow({
    required this.link,
    required this.cutsceneOptions,
    required this.enabled,
    required this.onRoleChanged,
    required this.onCutsceneChanged,
    required this.onRemove,
  });

  final StepStudioCutsceneLink link;
  final List<_SimpleOption> cutsceneOptions;
  final bool enabled;
  final ValueChanged<StepStudioCutsceneRole> onRoleChanged;
  final ValueChanged<String?> onCutsceneChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          _EnumDropdown<StepStudioCutsceneRole>(
            accent: EditorChrome.inspectorJoyPlum,
            fieldLabel: 'Rôle de la scène',
            value: link.role,
            values: StepStudioCutsceneRole.values,
            labelBuilder: stepStudioCutsceneRoleLabel,
            enabled: enabled,
            onChanged: onRoleChanged,
          ),
          const SizedBox(height: 6),
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyPlum,
            fieldLabel: 'Scène',
            options: cutsceneOptions,
            selectedId: link.cutsceneId,
            emptyLabel: 'Aucune scène',
            enabled: enabled && cutsceneOptions.isNotEmpty,
            onSelected: onCutsceneChanged,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer cette scène',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
    required this.outcome,
    required this.enabled,
    required this.onLabelChanged,
    required this.onScopeChanged,
    required this.onTapOutcomeId,
    required this.onRemove,
  });

  final StepStudioOutcomeDefinition outcome;
  final bool enabled;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<StepStudioOutcomeScope> onScopeChanged;
  final VoidCallback onTapOutcomeId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyOrchid.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyOrchid.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InlineTextField(
            label: 'Libellé humain',
            value: outcome.label,
            enabled: enabled,
            onChanged: onLabelChanged,
          ),
          const SizedBox(height: 6),
          _EnumDropdown<StepStudioOutcomeScope>(
            accent: EditorChrome.inspectorJoyOrchid,
            fieldLabel: 'Type de résultat',
            value: outcome.scope,
            values: StepStudioOutcomeScope.values,
            labelBuilder: stepStudioOutcomeScopeLabel,
            enabled: enabled,
            onChanged: onScopeChanged,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTapOutcomeId,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID technique (généré automatiquement)',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    outcome.outcomeId,
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer ce résultat',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldChangeRow extends StatelessWidget {
  const _WorldChangeRow({
    required this.change,
    required this.mapOptions,
    required this.entityOptions,
    required this.loadingEntities,
    required this.enabled,
    required this.onMapChanged,
    required this.onEntityChanged,
    required this.onRuleChanged,
    required this.onNoteChanged,
    required this.onRemove,
  });

  final StepStudioWorldChange change;
  final List<_SimpleOption> mapOptions;
  final List<_SimpleOption> entityOptions;
  final bool loadingEntities;
  final bool enabled;
  final ValueChanged<String?> onMapChanged;
  final ValueChanged<String?> onEntityChanged;
  final ValueChanged<StepStudioPresenceRule> onRuleChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Map',
            options: mapOptions,
            selectedId: change.mapId,
            emptyLabel: 'Choisir une map',
            enabled: enabled && mapOptions.isNotEmpty,
            treatInvalidSelectionAsUnset: true,
            onSelected: onMapChanged,
          ),
          const SizedBox(height: 6),
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Entité',
            options: entityOptions,
            selectedId: change.entityId,
            emptyLabel: loadingEntities
                ? 'Chargement des entités...'
                : 'Choisir une entité (PNJ)',
            enabled: enabled && entityOptions.isNotEmpty,
            treatInvalidSelectionAsUnset: true,
            onSelected: onEntityChanged,
          ),
          const SizedBox(height: 6),
          _EnumDropdown<StepStudioPresenceRule>(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Règle de présence',
            value: change.presenceRule,
            values: StepStudioPresenceRule.values,
            labelBuilder: stepStudioPresenceRuleLabel,
            enabled: enabled,
            onChanged: onRuleChanged,
          ),
          const SizedBox(height: 6),
          _InlineTextField(
            label: 'Note (optionnelle)',
            value: change.note ?? '',
            enabled: enabled,
            onChanged: onNoteChanged,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer ce changement',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _InteractionRef {
  const _InteractionRef({
    this.mapId,
    this.entityId,
  });

  final String? mapId;
  final String? entityId;
}
