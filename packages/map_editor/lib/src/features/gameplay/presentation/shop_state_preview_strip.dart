import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/shop_state_simulation_controller.dart';

class ShopStatePreviewStrip extends StatelessWidget {
  const ShopStatePreviewStrip({
    super.key,
    required this.preview,
    this.contextLabel = 'Contexte simulé',
    this.onEditContext,
  });

  final ShopStateSimulationReadModel preview;
  final String contextLabel;
  final VoidCallback? onEditContext;

  @override
  Widget build(BuildContext context) {
    final resolved = preview.resolvedState;
    final matchedCount = preview.matchedStates.length;
    return PokeMapPanel(
      key: const Key('shop-state-preview-strip'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 760
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildContextSummary(matchedCount),
                      const SizedBox(height: 8),
                      _buildResolvedSummary(),
                      if (onEditContext != null) ...[
                        const SizedBox(height: 8),
                        _buildEditButton(),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildContextSummary(matchedCount)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildResolvedSummary()),
                      if (onEditContext != null) ...[
                        const SizedBox(width: 8),
                        _buildEditButton(),
                      ],
                    ],
                  ),
          ),
          if (preview.hasPriorityConflict) ...[
            const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              title: 'Priorité ambiguë',
              message: preview.matchedStates
                  .where(
                    (state) => state.priority == resolved.priority,
                  )
                  .map((state) => state.label)
                  .join(' · '),
            ),
          ] else if (preview.conditionRows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final row in preview.conditionRows)
                  PokeMapBadge(
                    label: row.label,
                    variant: row.selected
                        ? PokeMapBadgeVariant.success
                        : row.matched
                            ? PokeMapBadgeVariant.info
                            : PokeMapBadgeVariant.neutral,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextSummary(int matchedCount) => _PreviewSummary(
        title: 'Contexte simulé',
        value: contextLabel,
        badge: PokeMapBadge(
          label: '$matchedCount condition'
              '${matchedCount == 1 ? '' : 's'} remplie'
              '${matchedCount == 1 ? '' : 's'}',
          variant: matchedCount == 0
              ? PokeMapBadgeVariant.neutral
              : PokeMapBadgeVariant.info,
        ),
      );

  Widget _buildResolvedSummary() => _PreviewSummary(
        title: 'État retenu',
        value: preview.resolvedState.authoringLabel,
        badge: PokeMapBadge(
          label: preview.resolvedState.isDefault
              ? 'Par défaut'
              : 'Priorité ${preview.resolvedState.priority}',
          variant: preview.hasPriorityConflict
              ? PokeMapBadgeVariant.warning
              : PokeMapBadgeVariant.success,
        ),
      );

  Widget _buildEditButton() => PokeMapButton(
        key: const Key('shop-preview-edit-context'),
        onPressed: onEditContext,
        size: PokeMapButtonSize.compact,
        variant: PokeMapButtonVariant.secondary,
        leading: const Icon(CupertinoIcons.slider_horizontal_3),
        child: const Text('Modifier le contexte'),
      );
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({
    required this.title,
    required this.value,
    required this.badge,
  });

  final String title;
  final String value;
  final Widget badge;

  @override
  Widget build(BuildContext context) => PokeMapCard(
        child: Row(
          children: [
            Expanded(
              child: PokeMapSectionHeader(
                title: title,
                description: value,
              ),
            ),
            const SizedBox(width: 6),
            badge,
          ],
        ),
      );
}

class ShopStateSimulationContextEditor extends StatelessWidget {
  const ShopStateSimulationContextEditor({
    super.key,
    required this.project,
    required this.controller,
    required this.itemLabels,
    required this.onChanged,
  });

  final ProjectManifest project;
  final ShopStateSimulationController controller;
  final Map<String, String> itemLabels;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final draft = controller.draftGameState;
    final steps = <StorylineStep>[
      for (final storyline in project.storylines)
        for (final chapter in storyline.chapters) ...chapter.steps,
    ];
    return ListView(
      key: const Key('shop-state-simulation-context-editor'),
      padding: const EdgeInsets.all(12),
      children: [
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Snapshot local',
          message: 'Ces valeurs servent uniquement à la prévisualisation. '
              'Elles ne modifient ni le projet ni une sauvegarde.',
        ),
        const SizedBox(height: 12),
        const PokeMapSectionHeader(
          title: 'Facts',
          description: 'Valeurs temporaires du contexte narratif.',
        ),
        if (project.facts.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucun Fact',
            description: 'Le projet ne définit aucun Fact simulable.',
            icon: Icon(CupertinoIcons.checkmark_alt_circle),
          )
        else
          for (final fact in project.facts) ...[
            _buildFactControl(fact),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        const PokeMapSectionHeader(
          title: 'Progression',
          description: 'Étapes et badges possédés dans ce snapshot.',
        ),
        for (final step in steps) ...[
          PokeMapToggleTile(
            key: ValueKey('shop-simulation-step-${step.id}'),
            label: step.title,
            description: 'Étape considérée comme terminée',
            value: draft.progression.completedStepIds.contains(step.id),
            onChanged: (value) {
              controller.setStepCompleted(step.id, completed: value);
              onChanged();
            },
          ),
          const SizedBox(height: 6),
        ],
        for (final badge in project.badges) ...[
          PokeMapToggleTile(
            key: ValueKey('shop-simulation-badge-${badge.id}'),
            label: badge.label,
            description: 'Badge considéré comme obtenu',
            value: draft.trainerProfile.badgeIds.contains(badge.id),
            onChanged: (value) {
              controller.setBadgeOwned(badge.id, owned: value);
              onChanged();
            },
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        const PokeMapSectionHeader(
          title: 'Ressources',
          description: 'Argent et objets utilisés par les conditions.',
        ),
        PokeMapTextField(
          fieldKey: const Key('shop-simulation-money'),
          label: 'Argent',
          placeholder: '${draft.trainerProfile.money}',
          keyboardType: TextInputType.number,
          onSubmitted: (raw) {
            final value = int.tryParse(raw.trim());
            if (value == null || value < 0) return;
            controller.setMoney(value);
            onChanged();
          },
        ),
        for (final entry in itemLabels.entries) ...[
          const SizedBox(height: 8),
          PokeMapTextField(
            fieldKey: ValueKey('shop-simulation-item-${entry.key}'),
            label: entry.value,
            placeholder: '${_itemQuantity(draft, entry.key)}',
            keyboardType: TextInputType.number,
            onSubmitted: (raw) {
              final value = int.tryParse(raw.trim());
              if (value == null || value < 0) return;
              controller.setItemQuantity(entry.key, value);
              onChanged();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFactControl(NarrativeFactDefinition fact) {
    final current =
        controller.draftGameState.narrativeFactRuntimeState.valueFor(fact.id) ??
            fact.initialValue;
    return switch (fact.valueKind) {
      NarrativeValueKind.boolean => PokeMapToggleTile(
          key: ValueKey('shop-simulation-fact-${fact.id}'),
          label: fact.label,
          description: current.boolValue ? 'Vrai' : 'Faux',
          value: current.boolValue,
          onChanged: (value) {
            controller.setFactValue(fact.id, NarrativeValue.boolean(value));
            onChanged();
          },
        ),
      NarrativeValueKind.integer => PokeMapTextField(
          fieldKey: ValueKey('shop-simulation-fact-${fact.id}'),
          label: fact.label,
          placeholder: '${current.intValue}',
          keyboardType: TextInputType.number,
          onSubmitted: (raw) {
            final value = int.tryParse(raw.trim());
            if (value == null) return;
            controller.setFactValue(fact.id, NarrativeValue.integer(value));
            onChanged();
          },
        ),
      NarrativeValueKind.string => PokeMapTextField(
          fieldKey: ValueKey('shop-simulation-fact-${fact.id}'),
          label: fact.label,
          placeholder: current.stringValue,
          onSubmitted: (raw) {
            controller.setFactValue(fact.id, NarrativeValue.string(raw));
            onChanged();
          },
        ),
    };
  }
}

int _itemQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);
