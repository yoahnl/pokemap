import 'package:flutter/cupertino.dart';

import '../../application/services/narrative_activity_journal.dart';
import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'narrative_overview_empty_states.dart';
import 'narrative_overview_structure_inspector.dart';
import 'new_game/project_new_game_configuration_sheet.dart';
import 'narrative_studio/narrative_studio_route_presentation.dart';
import 'narrative_studio/narrative_studio_workspace_page.dart';

/// Authoring overview of the Narrative Studio project.
class NarrativeOverviewWorkspace extends StatelessWidget {
  const NarrativeOverviewWorkspace({
    super.key,
    this.readModel,
    this.onOpenStorylines,
    this.onOpenScenes,
    this.onOpenCutscenes,
    this.onOpenDialogues,
    this.onOpenFacts,
    this.onOpenWorldRules,
    this.onResumeEditing,
    this.onOpenActivity,
    this.onOpenDiagnostic,
    this.onOpenValidator,
  });

  final NarrativeOverviewReadModel? readModel;
  final VoidCallback? onOpenStorylines;
  final VoidCallback? onOpenScenes;
  final VoidCallback? onOpenCutscenes;
  final VoidCallback? onOpenDialogues;
  final VoidCallback? onOpenFacts;
  final VoidCallback? onOpenWorldRules;
  final ValueChanged<NarrativeOverviewResumeTarget>? onResumeEditing;
  final ValueChanged<NarrativeActivityEntry>? onOpenActivity;
  final ValueChanged<NarrativeOverviewDiagnosticSummary>? onOpenDiagnostic;
  final VoidCallback? onOpenValidator;

  @override
  Widget build(BuildContext context) {
    final overview = readModel;
    return NarrativeStudioWorkspacePage(
      presentation: narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.narrativeOverview,
      )!,
      actions: overview == null
          ? const <Widget>[]
          : <Widget>[
              PokeMapButton(
                key: projectNewGameConfigurationLauncherKey,
                onPressed: () => showPokeMapDesktopSideSheet<void>(
                  context: context,
                  title: 'Nouveau Jeu',
                  semanticLabel: 'Configuration du Nouveau Jeu',
                  width: 560,
                  builder: (_) => const ProjectNewGameConfigurationSheet(),
                ),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.compact,
                leading: const Icon(CupertinoIcons.play_circle),
                child: const Text('Nouveau Jeu'),
              ),
            ],
      body: overview == null
          ? const PokeMapEmptyState(
              key: ValueKey('narrative-overview-project-unavailable'),
              title: 'Aucun projet chargé',
              description:
                  'Chargez un projet pour consulter ses indicateurs narratifs.',
              icon: Icon(CupertinoIcons.folder_open),
            )
          : ListView(
              key: const ValueKey('narrative-overview-scroll'),
              padding: const EdgeInsets.all(18),
              children: [
                _OverviewResponsiveBody(
                  readModel: overview,
                  onOpenStorylines: onOpenStorylines,
                  onOpenScenes: onOpenScenes,
                  onOpenCutscenes: onOpenCutscenes,
                  onOpenDialogues: onOpenDialogues,
                  onOpenFacts: onOpenFacts,
                  onOpenWorldRules: onOpenWorldRules,
                  onResumeEditing: onResumeEditing,
                  onOpenActivity: onOpenActivity,
                  onOpenDiagnostic: onOpenDiagnostic,
                  onOpenValidator: onOpenValidator,
                ),
              ],
            ),
    );
  }
}

class _OverviewResponsiveBody extends StatelessWidget {
  const _OverviewResponsiveBody({
    required this.readModel,
    required this.onOpenStorylines,
    required this.onOpenScenes,
    required this.onOpenCutscenes,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onResumeEditing,
    required this.onOpenActivity,
    required this.onOpenDiagnostic,
    required this.onOpenValidator,
  });

  final NarrativeOverviewReadModel readModel;
  final VoidCallback? onOpenStorylines;
  final VoidCallback? onOpenScenes;
  final VoidCallback? onOpenCutscenes;
  final VoidCallback? onOpenDialogues;
  final VoidCallback? onOpenFacts;
  final VoidCallback? onOpenWorldRules;
  final ValueChanged<NarrativeOverviewResumeTarget>? onResumeEditing;
  final ValueChanged<NarrativeActivityEntry>? onOpenActivity;
  final ValueChanged<NarrativeOverviewDiagnosticSummary>? onOpenDiagnostic;
  final VoidCallback? onOpenValidator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mainColumn = _OverviewMainColumn(
          readModel: readModel,
          onOpenStorylines: onOpenStorylines,
          onOpenScenes: onOpenScenes,
          onOpenCutscenes: onOpenCutscenes,
          onOpenDialogues: onOpenDialogues,
          onOpenFacts: onOpenFacts,
          onOpenWorldRules: onOpenWorldRules,
          onResumeEditing: onResumeEditing,
          onOpenActivity: onOpenActivity,
          onOpenDiagnostic: onOpenDiagnostic,
          onOpenValidator: onOpenValidator,
        );
        final structureInspector = NarrativeOverviewStructureInspector(
          inspector: readModel.structureInspector,
          editorialStatus: readModel.editorialStatus,
          projectHealth: readModel.projectHealth,
        );
        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mainColumn),
              const SizedBox(width: 10),
              SizedBox(
                key: const ValueKey('narrative-overview-structure-column'),
                width: 340,
                child: structureInspector,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            mainColumn,
            const SizedBox(height: 10),
            KeyedSubtree(
              key: const ValueKey('narrative-overview-structure-column'),
              child: structureInspector,
            ),
          ],
        );
      },
    );
  }
}

class _OverviewMainColumn extends StatelessWidget {
  const _OverviewMainColumn({
    required this.readModel,
    required this.onOpenStorylines,
    required this.onOpenScenes,
    required this.onOpenCutscenes,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onResumeEditing,
    required this.onOpenActivity,
    required this.onOpenDiagnostic,
    required this.onOpenValidator,
  });

  final NarrativeOverviewReadModel readModel;
  final VoidCallback? onOpenStorylines;
  final VoidCallback? onOpenScenes;
  final VoidCallback? onOpenCutscenes;
  final VoidCallback? onOpenDialogues;
  final VoidCallback? onOpenFacts;
  final VoidCallback? onOpenWorldRules;
  final ValueChanged<NarrativeOverviewResumeTarget>? onResumeEditing;
  final ValueChanged<NarrativeActivityEntry>? onOpenActivity;
  final ValueChanged<NarrativeOverviewDiagnosticSummary>? onOpenDiagnostic;
  final VoidCallback? onOpenValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('narrative-overview-main-column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectSummaryStrip(
          projectName: readModel.projectName,
          editorialStatusLabel: _editorialStatusLabel(
            readModel.editorialStatus.validationState,
          ),
          projectHealthLabel: readModel.projectHealth.healthKind ==
                  NarrativeProjectHealthKind.notEvaluated
              ? null
              : _projectHealthLabel(readModel.projectHealth.healthKind),
        ),
        const SizedBox(height: 8),
        _OverviewResumeCard(
          scope: readModel.scope,
          target: readModel.resumeTarget,
          onResumeEditing: onResumeEditing,
        ),
        const SizedBox(height: 8),
        _KpiCardsSection(
          metrics: [
            readModel.metrics.chapters,
            readModel.metrics.scenes,
            readModel.metrics.cutscenes,
            readModel.metrics.quests,
            readModel.metrics.dialogues,
            readModel.metrics.openIssues,
          ],
          onOpenStorylines: onOpenStorylines,
          onOpenScenes: onOpenScenes,
          onOpenCutscenes: onOpenCutscenes,
          onOpenDialogues: onOpenDialogues,
          onOpenValidator: onOpenValidator,
        ),
        const SizedBox(height: 8),
        _MainStoryCard(
          story: readModel.mainStory,
          onOpenStorylines: onOpenStorylines,
        ),
        const SizedBox(height: 8),
        _ModuleCardsSection(
          modules: readModel.modules,
          onOpenCutscenes: onOpenCutscenes,
          onOpenDialogues: onOpenDialogues,
          onOpenFacts: onOpenFacts,
          onOpenWorldRules: onOpenWorldRules,
          onOpenStorylines: onOpenStorylines,
        ),
        const SizedBox(height: 8),
        NarrativeOverviewUnavailableDataSection(
          recentActivity: readModel.recentActivity,
          notifications: readModel.notifications,
          activities: readModel.recentActivities,
          diagnostics: readModel.diagnostics,
          onOpenActivity: onOpenActivity,
          onOpenDiagnostic: onOpenDiagnostic,
        ),
        const SizedBox(height: 8),
        NarrativeOverviewFooter(
          projectName: readModel.projectName,
          footer: readModel.footer,
        ),
      ],
    );
  }
}

class _OverviewResumeCard extends StatelessWidget {
  const _OverviewResumeCard({
    required this.scope,
    required this.target,
    required this.onResumeEditing,
  });

  final NarrativeOverviewScopeSummary scope;
  final NarrativeOverviewResumeTarget? target;
  final ValueChanged<NarrativeOverviewResumeTarget>? onResumeEditing;

  @override
  Widget build(BuildContext context) {
    final resumeTarget = target;
    return PokeMapCard(
      key: const ValueKey('narrative-overview-resume-card'),
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reprendre le travail',
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                resumeTarget?.label ?? 'Aucune cible de reprise disponible.',
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scope : ${_scopeLabel(scope.kind)} · '
                'Source : ${resumeTarget?.sourceLabel ?? scope.sourceLabel}',
                key: const ValueKey('narrative-overview-resume-source'),
                style: TextStyle(
                  color: context.pokeMapColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
          final action = PokeMapButton(
            key: const ValueKey('narrative-overview-resume-action'),
            onPressed: resumeTarget == null || onResumeEditing == null
                ? null
                : () => onResumeEditing!(resumeTarget),
            size: PokeMapButtonSize.compact,
            leading: const Icon(CupertinoIcons.arrow_right_circle_fill),
            child: const Text('Reprendre l’édition'),
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 10), action],
            );
          }
          return Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.clock_fill,
                tone: PokeMapTone.brand,
              ),
              const SizedBox(width: 12),
              Expanded(child: copy),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

String _scopeLabel(NarrativeOverviewScopeKind kind) => switch (kind) {
      NarrativeOverviewScopeKind.canonicalStoryline => 'Storyline canonique',
      NarrativeOverviewScopeKind.legacyScenario => 'Scenario legacy',
      NarrativeOverviewScopeKind.empty => 'Projet vide',
      NarrativeOverviewScopeKind.ambiguous => 'Sélection requise',
    };

class _ProjectSummaryStrip extends StatelessWidget {
  const _ProjectSummaryStrip({
    required this.projectName,
    required this.editorialStatusLabel,
    this.projectHealthLabel,
  });

  final String projectName;
  final String editorialStatusLabel;
  final String? projectHealthLabel;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: const ValueKey('narrative-overview-project-summary'),
      borderRadius: 12,
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Projet',
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          _ProjectSummaryItem(label: 'Nom', value: projectName),
          _ProjectSummaryItem(
            label: 'Statut éditorial',
            value: editorialStatusLabel,
          ),
          if (projectHealthLabel case final projectHealthLabel?)
            _ProjectSummaryItem(
              label: 'Project Health',
              value: projectHealthLabel,
            ),
        ],
      ),
    );
  }
}

class _ProjectSummaryItem extends StatelessWidget {
  const _ProjectSummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label : $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.pokeMapColors.textMuted,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ModuleCardsSection extends StatelessWidget {
  const _ModuleCardsSection({
    required this.modules,
    required this.onOpenCutscenes,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onOpenStorylines,
  });

  final List<NarrativeModuleSummary> modules;
  final VoidCallback? onOpenCutscenes;
  final VoidCallback? onOpenDialogues;
  final VoidCallback? onOpenFacts;
  final VoidCallback? onOpenWorldRules;
  final VoidCallback? onOpenStorylines;

  @override
  Widget build(BuildContext context) {
    return _OverviewSection(
      title: 'Modules narratifs',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth;
            final columns = switch (maxWidth) {
              >= 900 => 3,
              >= 620 => 2,
              _ => 1,
            };

            final rowsCount = (modules.length / columns).ceil();
            return Column(
              key: const ValueKey('narrative-overview-module-grid'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var r = 0; r < rowsCount; r++) ...[
                  if (r > 0) const SizedBox(height: spacing),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var c = 0; c < columns; c++) ...[
                          if (c > 0) const SizedBox(width: spacing),
                          Expanded(
                            child: () {
                              final index = r * columns + c;
                              if (index < modules.length) {
                                final module = modules[index];
                                return _ModuleCard(
                                  module: module,
                                  onTap: _moduleCallback(module.id),
                                );
                              }
                              return const SizedBox.shrink();
                            }(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  VoidCallback? _moduleCallback(String moduleId) {
    return switch (moduleId) {
      NarrativeOverviewModuleIds.quests ||
      NarrativeOverviewModuleIds.conditions =>
        onOpenStorylines,
      NarrativeOverviewModuleIds.cutscenes => onOpenCutscenes,
      NarrativeOverviewModuleIds.dialogues => onOpenDialogues,
      NarrativeOverviewModuleIds.facts => onOpenFacts,
      NarrativeOverviewModuleIds.worldRules => onOpenWorldRules,
      _ => null,
    };
  }
}

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  final NarrativeModuleSummary module;
  final VoidCallback? onTap;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tone = _availabilityTone(widget.module.availability);
    final accent = tone.resolve(context).icon;
    final content = PokeMapCard(
      key: ValueKey('narrative-overview-module-${widget.module.id}'),
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokeMapIconTile(
                icon: _moduleIcon(widget.module.id),
                tone: tone,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.module.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _AvailabilityPill(
                      label: _moduleSupportLabel(widget.module),
                      accent: accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.module.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Source : ${widget.module.sourceLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.module.previewLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in widget.module.previewLabels)
                  _ModulePreviewLabel(label: label),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _moduleCardValue(widget.module),
            key: ValueKey(
              'narrative-overview-module-${widget.module.id}-value',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: _moduleCardValue(widget.module).length > 12 ? 18 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (widget.module.secondaryStats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in widget.module.secondaryStats)
                  _ModuleSecondaryStat(stat: stat),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _ModuleDestinationPill(enabled: widget.onTap != null),
        ],
      ),
    );
    if (widget.onTap == null) {
      return content;
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.45 : 1.0,
          duration: const Duration(milliseconds: 50),
          child: content,
        ),
      ),
    );
  }
}

class _ModulePreviewLabel extends StatelessWidget {
  const _ModulePreviewLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.pokeMapColors.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.pokeMapColors.brandPrimaryBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.pokeMapColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ModuleSecondaryStat extends StatelessWidget {
  const _ModuleSecondaryStat({required this.stat});

  final NarrativeMetricSummary stat;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, stat.availability);
    return Container(
      key: ValueKey('narrative-overview-module-stat-${stat.id}'),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _metricCardValue(stat),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Source : ${stat.sourceLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleDestinationPill extends StatelessWidget {
  const _ModuleDestinationPill({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = enabled
        ? context.pokeMapColors.brandPrimary
        : context.pokeMapColors.textMuted;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? CupertinoIcons.arrow_right_circle : CupertinoIcons.clock,
            color: accent,
            size: 12,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              enabled ? 'Studio relié' : 'Accès à venir',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainStoryCard extends StatelessWidget {
  const _MainStoryCard({
    required this.story,
    required this.onOpenStorylines,
  });

  final MainStoryOverviewSummary story;
  final VoidCallback? onOpenStorylines;

  @override
  Widget build(BuildContext context) {
    final accent = _sourceStatusAccent(context, story.sourceStatus);
    final canOpenStorylines = story.canEdit &&
        story.availability == NarrativeOverviewAvailability.available &&
        story.sourceStatus == NarrativeOverviewSourceStatus.explicit;
    return PokeMapCard(
      key: const ValueKey('narrative-overview-main-story-card'),
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                color: context.pokeMapColors.brandPrimary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Histoire principale',
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MainStoryActionAffordance(
                accent: accent,
                onTap: canOpenStorylines ? onOpenStorylines : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final useWideLayout = constraints.maxWidth >= 760;
              final visual = _MainStoryVisual(accent: accent);
              final content = _MainStoryContent(story: story, accent: accent);
              if (!useWideLayout) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    visual,
                    const SizedBox(height: 12),
                    content,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visual,
                  const SizedBox(width: 14),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MainStoryVisual extends StatelessWidget {
  const _MainStoryVisual({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 88,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.compass_fill,
        color: accent,
        size: 36,
      ),
    );
  }
}

class _MainStoryContent extends StatelessWidget {
  const _MainStoryContent({
    required this.story,
    required this.accent,
  });

  final MainStoryOverviewSummary story;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _mainStoryTitle(story),
              style: TextStyle(
                color: context.pokeMapColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            _SourceStatusPill(
              label: _sourceStatusLabel(story.sourceStatus),
              accent: accent,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _mainStoryDescription(story),
          style: TextStyle(
            color: context.pokeMapColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _MainStoryMetricsRow(story: story),
        const SizedBox(height: 12),
        _ChapterSummaryRow(story: story),
      ],
    );
  }
}

class _MainStoryMetricsRow extends StatelessWidget {
  const _MainStoryMetricsRow({required this.story});

  final MainStoryOverviewSummary story;

  @override
  Widget build(BuildContext context) {
    final metrics = <NarrativeMetricSummary>[
      story.linkedScenes,
      story.linkedDialogues,
      story.openIssues,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final metric in metrics)
          _MainStoryMetric(
            metric: metric,
            accent: _availabilityAccent(context, metric.availability),
          ),
      ],
    );
  }
}

class _MainStoryMetric extends StatelessWidget {
  const _MainStoryMetric({
    required this.metric,
    required this.accent,
  });

  final NarrativeMetricSummary metric;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.44)),
        ),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _metricCardValue(metric),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: _metricCardValue(metric).length > 12 ? 16 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Source : ${metric.sourceLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterSummaryRow extends StatelessWidget {
  const _ChapterSummaryRow({required this.story});

  final MainStoryOverviewSummary story;

  @override
  Widget build(BuildContext context) {
    final chapters = story.chapters;
    final hasFallbackChapters = chapters.any(
      (chapter) =>
          chapter.sourceStatus == NarrativeOverviewSourceStatus.fallback,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Chapitres',
              style: TextStyle(
                color: context.pokeMapColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasFallbackChapters) ...[
              const SizedBox(width: 8),
              _SourceStatusPill(
                label: 'Chapitres issus d’un fallback',
                accent: context.pokeMapColors.warning,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (chapters.isEmpty)
          Text(
            'Aucun chapitre authoré.',
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chapter in chapters) _ChapterChip(chapter: chapter),
              _DisabledChapterAffordance(),
            ],
          ),
      ],
    );
  }
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({required this.chapter});

  final NarrativeChapterOverviewSummary chapter;

  @override
  Widget build(BuildContext context) {
    final accent = _chapterStatusAccent(context, chapter.status);
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _chapterStatusLabel(chapter.status),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainStoryActionAffordance extends StatelessWidget {
  const _MainStoryActionAffordance({
    required this.accent,
    required this.onTap,
  });

  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PokeMapButton(
      onPressed: onTap,
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      leading: Icon(
        enabled ? CupertinoIcons.arrow_right_circle : CupertinoIcons.pencil,
        color: accent,
        size: 13,
      ),
      child: Text(enabled ? 'Ouvrir Storylines' : 'Modifier à venir'),
    );
  }
}

class _DisabledChapterAffordance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.pokeMapColors.textMuted;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        '+ Chapitre à venir',
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SourceStatusPill extends StatelessWidget {
  const _SourceStatusPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KpiCardsSection extends StatelessWidget {
  const _KpiCardsSection({
    required this.metrics,
    required this.onOpenStorylines,
    required this.onOpenScenes,
    required this.onOpenCutscenes,
    required this.onOpenDialogues,
    required this.onOpenValidator,
  });

  final List<NarrativeMetricSummary> metrics;
  final VoidCallback? onOpenStorylines;
  final VoidCallback? onOpenScenes;
  final VoidCallback? onOpenCutscenes;
  final VoidCallback? onOpenDialogues;
  final VoidCallback? onOpenValidator;

  @override
  Widget build(BuildContext context) {
    return _OverviewSection(
      title: 'Indicateurs auteur',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth;
            final columns = switch (maxWidth) {
              >= 900 => 6,
              >= 640 => 3,
              _ => 2,
            };
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              key: const ValueKey('narrative-overview-kpi-grid'),
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(
                      metric: metric,
                      onTap: _metricCallback(metric.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  VoidCallback? _metricCallback(String metricId) {
    return switch (metricId) {
      'chapters' => onOpenStorylines,
      'quests' => onOpenStorylines,
      'scenes' => onOpenScenes,
      'cutscenes' => onOpenCutscenes,
      'dialogues' => onOpenDialogues,
      'open_issues' => onOpenValidator,
      _ => null,
    };
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.metric,
    required this.onTap,
  });

  final NarrativeMetricSummary metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _availabilityTone(metric.availability);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0).toDouble();
    return SizedBox(
      height: 148 + ((textScale - 1) * 88),
      child: PokeMapMetricCard(
        key: ValueKey('narrative-overview-kpi-${metric.id}'),
        title: metric.label,
        value: _metricCardValue(metric),
        subtitle: _metricSupportLabel(metric),
        source: metric.sourceLabel,
        icon: _metricIcon(metric.id),
        tone: tone,
        onTap: onTap,
        titleMaxLines: 2,
        valueMaxLines: _metricCardValue(metric).length > 11 ? 2 : 1,
        valueFontSize: _metricCardValue(metric).length > 11 ? 20 : 22,
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final inheritedFontFamily = DefaultTextStyle.of(context).style.fontFamily;
    return PokeMapCard(
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: context.pokeMapColors.textMuted,
                  fontFamily: inheritedFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _metricCardValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}

String _metricSupportLabel(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available => 'Disponible',
    NarrativeOverviewAvailability.empty => 'Disponible',
    NarrativeOverviewAvailability.unavailable => metric.unavailableMessage,
    NarrativeOverviewAvailability.notEvaluated => 'Validation non lancée',
    NarrativeOverviewAvailability.outOfScope =>
      metric.id == 'quests' ? 'Pas de modèle Quest' : metric.unavailableMessage,
    NarrativeOverviewAvailability.needsModel => 'Registre absent',
  };
}

String _moduleCardValue(NarrativeModuleSummary module) {
  return switch (module.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${module.count ?? 0}',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}

String _moduleSupportLabel(NarrativeModuleSummary module) {
  return switch (module.availability) {
    NarrativeOverviewAvailability.available => 'Disponible',
    NarrativeOverviewAvailability.empty => module.emptyStateMessage,
    NarrativeOverviewAvailability.unavailable => module.emptyStateMessage,
    NarrativeOverviewAvailability.notEvaluated => 'Validation non lancée',
    NarrativeOverviewAvailability.outOfScope => module.emptyStateMessage,
    NarrativeOverviewAvailability.needsModel => module.emptyStateMessage,
  };
}

Color _availabilityAccent(
  BuildContext context,
  NarrativeOverviewAvailability availability,
) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => context.pokeMapColors.success,
    NarrativeOverviewAvailability.empty => context.pokeMapColors.brandPrimary,
    NarrativeOverviewAvailability.unavailable => context.pokeMapColors.error,
    NarrativeOverviewAvailability.notEvaluated => context.pokeMapColors.warning,
    NarrativeOverviewAvailability.outOfScope => context.pokeMapColors.textMuted,
    NarrativeOverviewAvailability.needsModel => context.pokeMapColors.narrative,
  };
}

PokeMapTone _availabilityTone(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => PokeMapTone.success,
    NarrativeOverviewAvailability.empty => PokeMapTone.brand,
    NarrativeOverviewAvailability.unavailable => PokeMapTone.danger,
    NarrativeOverviewAvailability.notEvaluated => PokeMapTone.warning,
    NarrativeOverviewAvailability.outOfScope => PokeMapTone.neutral,
    NarrativeOverviewAvailability.needsModel => PokeMapTone.narrative,
  };
}

IconData _metricIcon(String metricId) {
  return switch (metricId) {
    'chapters' => CupertinoIcons.book_fill,
    'scenes' => CupertinoIcons.rectangle_stack_fill,
    'cutscenes' => CupertinoIcons.film_fill,
    'quests' => CupertinoIcons.flag_fill,
    'dialogues' => CupertinoIcons.chat_bubble_2_fill,
    'open_issues' => CupertinoIcons.exclamationmark_triangle_fill,
    _ => CupertinoIcons.chart_bar_fill,
  };
}

IconData _moduleIcon(String moduleId) {
  return switch (moduleId) {
    NarrativeOverviewModuleIds.quests => CupertinoIcons.flag_fill,
    NarrativeOverviewModuleIds.cutscenes => CupertinoIcons.film_fill,
    NarrativeOverviewModuleIds.dialogues => CupertinoIcons.chat_bubble_2_fill,
    NarrativeOverviewModuleIds.conditions => CupertinoIcons.arrow_branch,
    NarrativeOverviewModuleIds.worldRules => CupertinoIcons.shield_fill,
    NarrativeOverviewModuleIds.facts => CupertinoIcons.book_fill,
    _ => CupertinoIcons.square_grid_2x2_fill,
  };
}

String _mainStoryTitle(MainStoryOverviewSummary story) {
  if (story.availability == NarrativeOverviewAvailability.empty) {
    return 'Aucune histoire principale';
  }
  if (story.sourceStatus == NarrativeOverviewSourceStatus.ambiguous) {
    return 'Sélection requise';
  }
  return story.title?.trim().isNotEmpty == true
      ? story.title!.trim()
      : 'Histoire principale sans titre';
}

String _mainStoryDescription(MainStoryOverviewSummary story) {
  if (story.availability != NarrativeOverviewAvailability.available) {
    return story.message;
  }
  return story.description?.trim().isNotEmpty == true
      ? story.description!.trim()
      : 'Synopsis non renseigné.';
}

String _sourceStatusLabel(NarrativeOverviewSourceStatus sourceStatus) {
  return switch (sourceStatus) {
    NarrativeOverviewSourceStatus.explicit => 'Source explicite',
    NarrativeOverviewSourceStatus.fallback => 'Source fallback',
    NarrativeOverviewSourceStatus.missing => 'Source manquante',
    NarrativeOverviewSourceStatus.ambiguous => 'Source ambiguë',
    NarrativeOverviewSourceStatus.notApplicable => 'Non applicable',
  };
}

Color _sourceStatusAccent(
  BuildContext context,
  NarrativeOverviewSourceStatus sourceStatus,
) {
  return switch (sourceStatus) {
    NarrativeOverviewSourceStatus.explicit =>
      context.pokeMapColors.brandPrimary,
    NarrativeOverviewSourceStatus.fallback => context.pokeMapColors.warning,
    NarrativeOverviewSourceStatus.missing => context.pokeMapColors.textMuted,
    NarrativeOverviewSourceStatus.ambiguous => context.pokeMapColors.error,
    NarrativeOverviewSourceStatus.notApplicable =>
      context.pokeMapColors.textMuted,
  };
}

String _chapterStatusLabel(NarrativeChapterEditorialStatus status) {
  return switch (status) {
    NarrativeChapterEditorialStatus.defined => 'Défini',
    NarrativeChapterEditorialStatus.inProgress => 'En cours',
    NarrativeChapterEditorialStatus.draft => 'Brouillon',
    NarrativeChapterEditorialStatus.notEvaluated => 'Non évalué',
  };
}

Color _chapterStatusAccent(
  BuildContext context,
  NarrativeChapterEditorialStatus status,
) {
  return switch (status) {
    NarrativeChapterEditorialStatus.defined => context.pokeMapColors.success,
    NarrativeChapterEditorialStatus.inProgress =>
      context.pokeMapColors.brandPrimary,
    NarrativeChapterEditorialStatus.draft => context.pokeMapColors.narrative,
    NarrativeChapterEditorialStatus.notEvaluated =>
      context.pokeMapColors.warning,
  };
}

String _editorialStatusLabel(NarrativeEditorialValidationState state) {
  return switch (state) {
    NarrativeEditorialValidationState.notEvaluated => 'Non évalué',
    NarrativeEditorialValidationState.upToDate => 'À jour',
    NarrativeEditorialValidationState.toReview => 'À revoir',
    NarrativeEditorialValidationState.blocking => 'Bloquant',
  };
}

String _projectHealthLabel(NarrativeProjectHealthKind healthKind) {
  return switch (healthKind) {
    NarrativeProjectHealthKind.notEvaluated => 'Non évalué',
    NarrativeProjectHealthKind.healthy => 'Sain',
    NarrativeProjectHealthKind.reviewNeeded => 'À revoir',
    NarrativeProjectHealthKind.blocked => 'Bloqué',
  };
}
