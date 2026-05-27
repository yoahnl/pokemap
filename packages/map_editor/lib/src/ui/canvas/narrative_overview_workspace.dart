import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Shell V0 de la page "Aperçu" du Narrative Studio.
///
/// Ce widget reste volontairement sobre : il prouve le point d'entrée UI et la
/// consommation du read model sans construire le dashboard final.
class NarrativeOverviewWorkspace extends StatelessWidget {
  const NarrativeOverviewWorkspace({
    super.key,
    required this.readModel,
  });

  final NarrativeOverviewReadModel readModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        Text(
          'Aperçu',
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vue d’ensemble auteur du Narrative Studio.',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        _OverviewSection(
          title: 'Projet',
          children: [
            _OverviewLine(label: 'Nom', value: readModel.projectName),
            _OverviewLine(
              label: 'Statut éditorial',
              value: _editorialStatusLabel(
                readModel.editorialStatus.validationState,
              ),
            ),
            _OverviewLine(
              label: 'Project Health',
              value: _projectHealthLabel(readModel.projectHealth.healthKind),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _KpiCardsSection(
          metrics: [
            readModel.metrics.chapters,
            readModel.metrics.scenes,
            readModel.metrics.cutscenes,
            readModel.metrics.quests,
            readModel.metrics.dialogues,
            readModel.metrics.openIssues,
          ],
        ),
        const SizedBox(height: 12),
        _MainStoryCard(story: readModel.mainStory),
        const SizedBox(height: 12),
        _ModuleCardsSection(modules: readModel.modules),
        const SizedBox(height: 12),
        _OverviewSection(
          title: 'V0 volontairement limitée',
          children: [
            const Text(
              'Les sections détaillées seront construites dans les lots suivants.',
            ),
            const SizedBox(height: 6),
            const Text(
              'Aucun compteur fake, aucune activité récente inventée, aucune notification simulée.',
            ),
            const SizedBox(height: 6),
            _MetricLine(metric: readModel.metrics.facts),
            _FeatureLine(feature: readModel.recentActivity),
            _FeatureLine(feature: readModel.notifications),
          ],
        ),
      ],
    );
  }
}

class _ModuleCardsSection extends StatelessWidget {
  const _ModuleCardsSection({required this.modules});

  final List<NarrativeModuleSummary> modules;

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
              >= 960 => 3,
              >= 620 => 2,
              _ => 1,
            };
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              key: const ValueKey('narrative-overview-module-grid'),
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final module in modules)
                  SizedBox(
                    width: cardWidth,
                    child: _ModuleCard(module: module),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final NarrativeModuleSummary module;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, module.availability);
    return Container(
      key: ValueKey('narrative-overview-module-${module.id}'),
      constraints: const BoxConstraints(minHeight: 184),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModuleIcon(moduleId: module.id, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _AvailabilityPill(
                      label: _moduleSupportLabel(module),
                      accent: accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            module.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _moduleCardValue(module),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: _moduleCardValue(module).length > 12 ? 18 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (module.secondaryStats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in module.secondaryStats)
                  _ModuleSecondaryStat(stat: stat),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _ModuleDestinationPill(module: module),
        ],
      ),
    );
  }
}

class _ModuleIcon extends StatelessWidget {
  const _ModuleIcon({
    required this.moduleId,
    required this.accent,
  });

  final String moduleId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Icon(
        _moduleIcon(moduleId),
        color: accent,
        size: 19,
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
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _metricCardValue(stat),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleDestinationPill extends StatelessWidget {
  const _ModuleDestinationPill({required this.module});

  final NarrativeModuleSummary module;

  @override
  Widget build(BuildContext context) {
    final hasDestination = module.destination?.trim().isNotEmpty == true;
    final accent = hasDestination
        ? EditorChrome.accentPrimary
        : EditorChrome.subtleLabel(context);
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
            hasDestination
                ? CupertinoIcons.arrow_right_circle
                : CupertinoIcons.clock,
            color: accent,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            hasDestination ? 'Studio relié' : 'Accès à venir',
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

class _MainStoryCard extends StatelessWidget {
  const _MainStoryCard({required this.story});

  final MainStoryOverviewSummary story;

  @override
  Widget build(BuildContext context) {
    final accent = _sourceStatusAccent(context, story.sourceStatus);
    return Container(
      key: const ValueKey('narrative-overview-main-story-card'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.star_fill,
                color: EditorChrome.accentPrimary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Histoire principale',
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _DisabledEditAffordance(accent: accent),
            ],
          ),
          const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    content,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visual,
                  const SizedBox(width: 18),
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
      width: 118,
      height: 108,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.compass_fill,
        color: accent,
        size: 40,
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
                color: EditorChrome.primaryLabel(context),
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
            color: EditorChrome.subtleLabel(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        _MainStoryMetricsRow(story: story),
        const SizedBox(height: 14),
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
      spacing: 12,
      runSpacing: 10,
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
      constraints: const BoxConstraints(minWidth: 136),
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
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _metricCardValue(metric),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: _metricCardValue(metric).length > 12 ? 16 : 22,
              fontWeight: FontWeight.w900,
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
                color: EditorChrome.subtleLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasFallbackChapters) ...[
              const SizedBox(width: 8),
              const _SourceStatusPill(
                label: 'Chapitres issus d’un fallback',
                accent: EditorChrome.accentWarm,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (chapters.isEmpty)
          Text(
            'Aucun chapitre authoré.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
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
    final accent = _chapterStatusAccent(chapter.status);
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
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

class _DisabledEditAffordance extends StatelessWidget {
  const _DisabledEditAffordance({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.pencil, color: accent, size: 13),
            const SizedBox(width: 6),
            Text(
              'Modifier à venir',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledChapterAffordance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = EditorChrome.subtleLabel(context);
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
  });

  final List<NarrativeMetricSummary> metrics;

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
              >= 1080 => 6,
              >= 720 => 3,
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
                    child: _KpiCard(metric: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.metric});

  final NarrativeMetricSummary metric;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, metric.availability);
    return Container(
      key: ValueKey('narrative-overview-kpi-${metric.id}'),
      height: 154,
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricIcon(metricId: metric.id, accent: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            _metricCardValue(metric),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: _metricCardValue(metric).length > 12 ? 18 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          _AvailabilityPill(
            label: _metricSupportLabel(metric),
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({
    required this.metricId,
    required this.accent,
  });

  final String metricId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Icon(
        _metricIcon(metricId),
        size: 18,
        color: accent,
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
      constraints: const BoxConstraints(minHeight: 24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 11,
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
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
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

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.metric});

  final NarrativeMetricSummary metric;

  @override
  Widget build(BuildContext context) {
    return Text('${metric.label} : ${_metricValue(metric)}');
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.feature});

  final NarrativeOverviewFeatureSummary feature;

  @override
  Widget build(BuildContext context) {
    return Text(
        '${feature.label} : ${_availabilityValue(feature.availability)}');
  }
}

class _OverviewLine extends StatelessWidget {
  const _OverviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text('$label : $value');
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

String _metricValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    _ => _availabilityValue(metric.availability),
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

String _availabilityValue(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => 'disponible',
    NarrativeOverviewAvailability.empty => '0',
    NarrativeOverviewAvailability.unavailable => 'indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'non évalué',
    NarrativeOverviewAvailability.outOfScope => 'hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'nécessite un modèle',
  };
}

Color _availabilityAccent(
  BuildContext context,
  NarrativeOverviewAvailability availability,
) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => EditorChrome.accentJade,
    NarrativeOverviewAvailability.empty => EditorChrome.accentPrimary,
    NarrativeOverviewAvailability.unavailable => EditorChrome.accentCoral,
    NarrativeOverviewAvailability.notEvaluated => EditorChrome.accentWarm,
    NarrativeOverviewAvailability.outOfScope =>
      EditorChrome.subtleLabel(context),
    NarrativeOverviewAvailability.needsModel => EditorChrome.inspectorJoyPlum,
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
    NarrativeOverviewSourceStatus.explicit => EditorChrome.accentPrimary,
    NarrativeOverviewSourceStatus.fallback => EditorChrome.accentWarm,
    NarrativeOverviewSourceStatus.missing => EditorChrome.subtleLabel(context),
    NarrativeOverviewSourceStatus.ambiguous => EditorChrome.accentCoral,
    NarrativeOverviewSourceStatus.notApplicable =>
      EditorChrome.subtleLabel(context),
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

Color _chapterStatusAccent(NarrativeChapterEditorialStatus status) {
  return switch (status) {
    NarrativeChapterEditorialStatus.defined => EditorChrome.accentJade,
    NarrativeChapterEditorialStatus.inProgress => EditorChrome.accentPrimary,
    NarrativeChapterEditorialStatus.draft => EditorChrome.accentLilac,
    NarrativeChapterEditorialStatus.notEvaluated => EditorChrome.accentWarm,
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
