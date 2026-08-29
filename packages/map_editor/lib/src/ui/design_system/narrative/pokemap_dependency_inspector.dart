import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../pokemap_badge.dart';
import '../pokemap_button.dart';
import '../pokemap_card.dart';
import '../pokemap_diagnostic_callout.dart';
import '../pokemap_empty_state.dart';
import '../pokemap_section_header.dart';

/// Read-only dependency details shared by Narrative Studio authoring surfaces.
///
/// Navigation is expressed exclusively through canonical Core intents. A bulk
/// replacement is offered only when Core supplied an unforgeable capability
/// whose covered paths still match this exact inspection model.
class PokeMapDependencyInspector extends StatelessWidget {
  const PokeMapDependencyInspector({
    super.key,
    required this.model,
    this.onOpen,
    this.replacementCapability,
    this.onReplaceEverywhere,
  });

  final NarrativeDependencyInspectionReadModel model;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;
  final NarrativeReferenceReplacementCapability? replacementCapability;
  final ValueChanged<NarrativeReferenceReplacementCapability>?
  onReplaceEverywhere;

  @override
  Widget build(BuildContext context) {
    final capability = _usableReplacementCapability;
    final targetTitle = switch (model.definitions.length) {
      0 => 'Référence introuvable',
      > 1 => 'Référence ambiguë',
      _ => model.definitions.single.label,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PokeMapSectionHeader(
            title: targetTitle,
            description: model.target.id,
            trailing: capability == null
                ? null
                : PokeMapButton(
                    key: const ValueKey('dependency-inspector-replace-all'),
                    onPressed: () => onReplaceEverywhere!(capability),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(Icons.find_replace_rounded),
                    child: const Text('Remplacer partout'),
                  ),
          ),
          if (model.definitions.isEmpty) ...[
            const PokeMapCard(
              child: PokeMapEmptyState(
                title: 'Référence introuvable',
                description:
                    'Aucune définition canonique ne correspond à cette cible.',
                icon: Icon(Icons.link_off_rounded),
              ),
            ),
          ] else ...[
            _DefinitionsSection(model: model, onOpen: onOpen),
          ],
          const SizedBox(height: 12),
          _ConsumersSection(model: model, onOpen: onOpen),
          const SizedBox(height: 12),
          _DiagnosticsSection(model: model),
        ],
      ),
    );
  }

  NarrativeReferenceReplacementCapability? get _usableReplacementCapability {
    final capability = replacementCapability;
    if (capability == null || onReplaceEverywhere == null) return null;
    if (model.definitions.length != 1 ||
        model.definitions.single.key != model.target ||
        model.usages.any((usage) => usage.target != model.target) ||
        model.target.kind != NarrativeDependencyTargetKind.cinematic ||
        capability.source.kind != NarrativeDependencyTargetKind.cinematic ||
        capability.replacement.kind !=
            NarrativeDependencyTargetKind.cinematic ||
        capability.source != model.target) {
      return null;
    }

    final inspectedPaths = model.usages.map((usage) => usage.path).toList();
    if (!_hasExactPathCoverage(
      capability.coveredReferencePaths,
      inspectedPaths,
    )) {
      return null;
    }
    return capability;
  }
}

class _DefinitionsSection extends StatelessWidget {
  const _DefinitionsSection({required this.model, required this.onOpen});

  final NarrativeDependencyInspectionReadModel model;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapSectionHeader(
          title: 'Définitions',
          description: _countLabel(
            model.definitions.length,
            singular: 'définition',
            plural: 'définitions',
          ),
        ),
        for (var index = 0; index < model.definitions.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _DefinitionCard(
            definition: model.definitions[index],
            index: index,
            onOpen: onOpen,
          ),
        ],
      ],
    );
  }
}

class _DefinitionCard extends StatelessWidget {
  const _DefinitionCard({
    required this.definition,
    required this.index,
    required this.onOpen,
  });

  final NarrativeDependencyDefinition definition;
  final int index;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final intent = definition.navigationIntent;
    final canOpen = intent != null && onOpen != null;

    return PokeMapCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  definition.label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (definition.owner != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Propriétaire : ${definition.owner!.id}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
                if (definition.path case final path?) ...[
                  const SizedBox(height: 4),
                  Text(
                    path,
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (canOpen) ...[
            const SizedBox(width: 8),
            PokeMapButton(
              key: ValueKey<Object>((
                'dependency-inspector-definition-open',
                definition.key,
                definition.path,
              )),
              onPressed: () => onOpen!(intent),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(Icons.open_in_new_rounded),
              child: const Text('Ouvrir'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsumersSection extends StatelessWidget {
  const _ConsumersSection({required this.model, required this.onOpen});

  final NarrativeDependencyInspectionReadModel model;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapSectionHeader(
          title: 'Consommateurs',
          description: _countLabel(
            model.usages.length,
            singular: 'consommateur',
            plural: 'consommateurs',
          ),
        ),
        if (model.usages.isEmpty)
          const PokeMapCard(
            child: PokeMapEmptyState(
              title: 'Aucun consommateur',
              description: 'Cette référence n’est utilisée par aucun contenu.',
              icon: Icon(Icons.hub_outlined),
            ),
          )
        else
          for (var index = 0; index < model.usages.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _ConsumerCard(
              usage: model.usages[index],
              index: index,
              onOpen: onOpen,
            ),
          ],
      ],
    );
  }
}

class _ConsumerCard extends StatelessWidget {
  const _ConsumerCard({
    required this.usage,
    required this.index,
    required this.onOpen,
  });

  final NarrativeDependencyUsage usage;
  final int index;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final intent = usage.navigationIntent;
    final canOpen = intent != null && onOpen != null;

    return PokeMapCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        usage.owner.id,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PokeMapBadge(
                      label: _criticalityLabel(usage.criticality),
                      variant: _criticalityBadge(usage.criticality),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_kindLabel(usage.owner.kind)} · ${usage.path}',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (canOpen) ...[
            const SizedBox(width: 8),
            PokeMapButton(
              key: ValueKey<Object>((
                'dependency-inspector-consumer-open',
                usage.target,
                usage.owner,
                usage.path,
              )),
              onPressed: () => onOpen!(intent),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(Icons.open_in_new_rounded),
              child: const Text('Ouvrir'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({required this.model});

  final NarrativeDependencyInspectionReadModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapSectionHeader(
          title: 'Diagnostics',
          description: _countLabel(
            model.issues.length,
            singular: 'diagnostic',
            plural: 'diagnostics',
          ),
        ),
        if (model.issues.isEmpty)
          const PokeMapCard(
            child: PokeMapEmptyState(
              title: 'Aucun diagnostic',
              description: 'Aucun problème de dépendance n’est détecté.',
              icon: Icon(Icons.check_circle_outline_rounded),
            ),
          )
        else
          for (var index = 0; index < model.issues.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: _diagnosticSeverity(model.issues[index].criticality),
              title: _issueTitle(model.issues[index].kind),
              message: model.issues[index].message,
            ),
          ],
      ],
    );
  }
}

bool _hasExactPathCoverage(List<String> covered, List<String> inspected) {
  if (covered.length != inspected.length) return false;
  final remaining = <String, int>{};
  for (final path in covered) {
    remaining.update(path, (count) => count + 1, ifAbsent: () => 1);
  }
  for (final path in inspected) {
    final count = remaining[path];
    if (count == null) return false;
    if (count == 1) {
      remaining.remove(path);
    } else {
      remaining[path] = count - 1;
    }
  }
  return remaining.isEmpty;
}

String _countLabel(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural}';
}

String _criticalityLabel(NarrativeDependencyCriticality criticality) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational => 'Information',
    NarrativeDependencyCriticality.authoringWarning =>
      'Avertissement de création',
    NarrativeDependencyCriticality.runtimeBlocking =>
      'Bloquant pour l’exécution',
  };
}

PokeMapBadgeVariant _criticalityBadge(
  NarrativeDependencyCriticality criticality,
) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational => PokeMapBadgeVariant.info,
    NarrativeDependencyCriticality.authoringWarning =>
      PokeMapBadgeVariant.warning,
    NarrativeDependencyCriticality.runtimeBlocking => PokeMapBadgeVariant.error,
  };
}

PokeMapDiagnosticSeverity _diagnosticSeverity(
  NarrativeDependencyCriticality criticality,
) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational =>
      PokeMapDiagnosticSeverity.info,
    NarrativeDependencyCriticality.authoringWarning =>
      PokeMapDiagnosticSeverity.warning,
    NarrativeDependencyCriticality.runtimeBlocking =>
      PokeMapDiagnosticSeverity.error,
  };
}

String _issueTitle(NarrativeDependencyIssueKind kind) {
  return switch (kind) {
    NarrativeDependencyIssueKind.missingReference => 'Référence introuvable',
    NarrativeDependencyIssueKind.ambiguousReference => 'Référence ambiguë',
    NarrativeDependencyIssueKind.unavailableReference =>
      'Référence indisponible',
    NarrativeDependencyIssueKind.duplicateId => 'Identifiant dupliqué',
    NarrativeDependencyIssueKind.forbiddenCycle => 'Cycle interdit',
  };
}

String _kindLabel(NarrativeDependencyTargetKind kind) {
  return switch (kind) {
    NarrativeDependencyTargetKind.fact => 'Fact',
    NarrativeDependencyTargetKind.badge => 'Badge',
    NarrativeDependencyTargetKind.item => 'Objet',
    NarrativeDependencyTargetKind.eventV2 => 'Événement',
    NarrativeDependencyTargetKind.scene => 'Scène',
    NarrativeDependencyTargetKind.dialogue => 'Dialogue',
    NarrativeDependencyTargetKind.cinematic => 'Cinématique',
    NarrativeDependencyTargetKind.media => 'Média cinematic',
    NarrativeDependencyTargetKind.storyline => 'Storyline',
    NarrativeDependencyTargetKind.chapter => 'Chapitre',
    NarrativeDependencyTargetKind.step => 'Étape',
    NarrativeDependencyTargetKind.worldRule => 'Règle du monde',
    NarrativeDependencyTargetKind.railJourney => 'Voyage ferroviaire',
    NarrativeDependencyTargetKind.sourceMap => 'Source de map',
  };
}
