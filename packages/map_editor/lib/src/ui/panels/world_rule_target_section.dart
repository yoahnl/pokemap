import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import '../shared/inspector_embedded_widgets.dart';

final class WorldRuleEventRuleDraft {
  const WorldRuleEventRuleDraft({
    required this.label,
    required this.factId,
    required this.predicate,
    required this.effectKind,
    required this.enabled,
  });

  final String label;
  final String factId;
  final WorldRuleSourcePredicate predicate;
  final WorldRuleEffectKind effectKind;
  final bool enabled;
}

class WorldRuleTargetSection extends StatefulWidget {
  const WorldRuleTargetSection({
    super.key,
    required this.model,
    required this.facts,
    this.allowMapEventCreation = false,
    this.onCreateEventRule,
    this.onToggleEnabled,
  });

  final WorldRuleTargetContextReadModel model;
  final List<NarrativeFactDefinition> facts;
  final bool allowMapEventCreation;
  final Future<void> Function(WorldRuleEventRuleDraft draft)? onCreateEventRule;
  final Future<void> Function(WorldRuleDefinition rule)? onToggleEnabled;

  @override
  State<WorldRuleTargetSection> createState() => _WorldRuleTargetSectionState();
}

class _WorldRuleTargetSectionState extends State<WorldRuleTargetSection> {
  final _labelController = TextEditingController();
  String? _selectedFactId;
  WorldRuleSourcePredicate _selectedPredicate = WorldRuleSourcePredicate.isTrue;
  WorldRuleEffectKind _selectedEffectKind = WorldRuleEffectKind.eventEnabled;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _selectedFactId = widget.facts.isEmpty ? null : widget.facts.first.id;
  }

  @override
  void didUpdateWidget(covariant WorldRuleTargetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedFactId == null ||
        !widget.facts.any((fact) => fact.id == _selectedFactId)) {
      _selectedFactId = widget.facts.isEmpty ? null : widget.facts.first.id;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final secondary = colors.textMuted;
    return Container(
      key: const ValueKey('world-rule-target-section'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.controlBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: InspectorEmbeddedSectionLabel('Règles du monde'),
              ),
              Text(
                '${widget.model.ruleCount} liée(s)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.model.isEmpty)
            Text(
              'Aucune règle du monde ne cible cet élément.',
              key: const ValueKey('world-rule-empty-state'),
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                color: secondary,
              ),
            )
          else
            ...widget.model.rules.map(_buildRuleCard),
          if (widget.allowMapEventCreation) ...[
            const SizedBox(height: 10),
            _SectionDivider(color: colors.divider),
            const SizedBox(height: 10),
            _buildEventCreationForm(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleCard(WorldRuleTargetContextRuleView view) {
    return Builder(
      builder: (context) {
        final colors = context.pokeMapColors;
        final accent = colors.worldRule;
        final secondary = colors.textMuted;
        final primary = colors.textPrimary;
        final statusAccent = view.enabled ? colors.success : colors.textMuted;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      view.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: view.enabled ? 'Active' : 'Inactive',
                    accent: statusAccent,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _RuleInfoLine(label: 'Source', value: view.sourceLabel),
              _RuleInfoLine(label: 'Effet', value: view.effectLabel),
              if (view.hasDiagnostics) ...[
                const SizedBox(height: 6),
                for (final diagnostic in view.diagnostics)
                  Text(
                    diagnostic.message,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      color: diagnostic.severity ==
                              WorldRuleDiagnosticSeverity.error
                          ? colors.error
                          : secondary,
                    ),
                  ),
              ],
              if (widget.onToggleEnabled != null) ...[
                const SizedBox(height: 8),
                InspectorEmbeddedSecondaryCapsule(
                  key: ValueKey('world-rule-toggle-${view.rule.id}'),
                  accent: view.enabled ? colors.error : colors.success,
                  icon: view.enabled
                      ? CupertinoIcons.pause_circle
                      : CupertinoIcons.play_circle,
                  label: view.enabled ? 'Désactiver' : 'Activer',
                  enabled: true,
                  onPressed: () => widget.onToggleEnabled!(view.rule),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventCreationForm(BuildContext context) {
    final colors = context.pokeMapColors;
    final accent = colors.worldRule;
    final facts = widget.facts;
    final selectedFactId = _selectedFactId;
    if (facts.isEmpty || selectedFactId == null) {
      return InspectorEmbeddedFootnote(
        text: 'Ajoutez d’abord un Fact pour créer une règle ciblant cet event.',
        accent: accent,
      );
    }
    const effectIds = [
      WorldRuleEffectKind.eventEnabled,
      WorldRuleEffectKind.eventDisabled,
      WorldRuleEffectKind.eventHidden,
    ];
    const predicateIds = [
      WorldRuleSourcePredicate.isTrue,
      WorldRuleSourcePredicate.isFalse,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InspectorEmbeddedSectionLabel('Créer une règle pour cet event'),
        const SizedBox(height: 8),
        CupertinoTextField(
          key: const ValueKey('world-rule-create-label-field'),
          controller: _labelController,
          placeholder: 'Nom lisible de la règle',
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.controlSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.controlBorder),
          ),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          placeholderStyle: TextStyle(
            color: colors.textDisabled,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          key: const ValueKey('world-rule-create-fact-dropdown'),
          accent: accent,
          fieldLabel: 'Fact source',
          valueLabel: _factLabel(selectedFactId),
          orderedIds: facts.map((fact) => fact.id).toList(),
          selectedMenuValue: selectedFactId,
          selectedIdForCheck: selectedFactId,
          idToLabel: _factLabel,
          onSelected: (id) => setState(() => _selectedFactId = id),
          tooltip: 'Fact source de la World Rule',
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          key: const ValueKey('world-rule-create-predicate-dropdown'),
          accent: accent,
          fieldLabel: 'Prédicat',
          valueLabel: _predicateLabel(_selectedPredicate),
          orderedIds: predicateIds.map((predicate) => predicate.name).toList(),
          selectedMenuValue: _selectedPredicate.name,
          selectedIdForCheck: _selectedPredicate.name,
          idToLabel: (id) => _predicateLabel(
            predicateIds.firstWhere((predicate) => predicate.name == id),
          ),
          onSelected: (id) {
            setState(() {
              _selectedPredicate =
                  predicateIds.firstWhere((predicate) => predicate.name == id);
            });
          },
          tooltip: 'Prédicat du Fact',
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          key: const ValueKey('world-rule-create-effect-dropdown'),
          accent: accent,
          fieldLabel: 'Effet sur event',
          valueLabel: _effectLabel(_selectedEffectKind),
          orderedIds: effectIds.map((effect) => effect.name).toList(),
          selectedMenuValue: _selectedEffectKind.name,
          selectedIdForCheck: _selectedEffectKind.name,
          idToLabel: (id) => _effectLabel(
            effectIds.firstWhere((effect) => effect.name == id),
          ),
          onSelected: (id) {
            setState(() {
              _selectedEffectKind =
                  effectIds.firstWhere((effect) => effect.name == id);
            });
          },
          tooltip: 'Effet declaratif sur cet event',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Règle active',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoSwitch(
              value: _enabled,
              activeTrackColor: accent,
              onChanged: (value) => setState(() => _enabled = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedPrimaryCapsule(
          key: const ValueKey('world-rule-create-event-rule'),
          accent: accent,
          icon: CupertinoIcons.add_circled,
          label: 'Créer la règle ciblée',
          prominent: true,
          onPressed: _createEventRule,
        ),
      ],
    );
  }

  String _factLabel(String id) {
    for (final fact in widget.facts) {
      if (fact.id == id) {
        return fact.label;
      }
    }
    return 'Fact manquant';
  }

  String _predicateLabel(WorldRuleSourcePredicate predicate) {
    return switch (predicate) {
      WorldRuleSourcePredicate.isTrue => 'Fact vrai',
      WorldRuleSourcePredicate.isFalse => 'Fact faux',
      WorldRuleSourcePredicate.completed => 'Étape terminée',
      WorldRuleSourcePredicate.notCompleted => 'Étape non terminée',
      WorldRuleSourcePredicate.consumed => 'Event consommé',
      WorldRuleSourcePredicate.notConsumed => 'Event non consommé',
    };
  }

  String _effectLabel(WorldRuleEffectKind effect) {
    return switch (effect) {
      WorldRuleEffectKind.eventEnabled => 'Event activé',
      WorldRuleEffectKind.eventDisabled => 'Event désactivé',
      WorldRuleEffectKind.eventHidden => 'Event masqué',
      WorldRuleEffectKind.entityVisible => 'Entité visible',
      WorldRuleEffectKind.entityHidden => 'Entité cachée',
      WorldRuleEffectKind.npcDialogueOverride => 'Dialogue PNJ remplacé',
    };
  }

  Future<void> _createEventRule() async {
    final label = _labelController.text.trim();
    final factId = _selectedFactId;
    final callback = widget.onCreateEventRule;
    if (label.isEmpty || factId == null || callback == null) {
      return;
    }
    await callback(
      WorldRuleEventRuleDraft(
        label: label,
        factId: factId,
        predicate: _selectedPredicate,
        effectKind: _selectedEffectKind,
        enabled: _enabled,
      ),
    );
    if (!mounted) {
      return;
    }
    _labelController.clear();
  }
}

class _RuleInfoLine extends StatelessWidget {
  const _RuleInfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
        style: TextStyle(
          fontSize: 10.5,
          height: 1.25,
          color: colors.textMuted,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: color,
    );
  }
}
