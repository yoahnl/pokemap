import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Panneau V0 de synthèse "Structure narrative" pour l'aperçu auteur.
///
/// Le widget affiche uniquement des données déjà normalisées par
/// [NarrativeOverviewReadModel] afin d'éviter les compteurs ou statuts inventés.
class NarrativeOverviewStructureInspector extends StatelessWidget {
  const NarrativeOverviewStructureInspector({
    super.key,
    required this.inspector,
    required this.editorialStatus,
    required this.projectHealth,
  });

  final NarrativeStructureInspectorSummary inspector;
  final EditorialStatusSummary editorialStatus;
  final NarrativeProjectHealthSummary projectHealth;

  @override
  Widget build(BuildContext context) {
    final accent = _editorialAccent(context, editorialStatus.validationState);
    return Container(
      key: const ValueKey('narrative-overview-structure-inspector'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'STRUCTURE NARRATIVE',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.pin_fill,
                color: EditorChrome.subtleLabel(context),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InspectorIdentity(
            projectName: inspector.projectName,
            statusLabel: inspector.globalStatusLabel,
            accent: accent,
          ),
          const SizedBox(height: 10),
          _InspectorDivider(),
          const SizedBox(height: 10),
          _InspectorCounters(counters: inspector.counters),
          const SizedBox(height: 12),
          _InspectorSection(
            title: 'DESCRIPTION',
            child: _DescriptionBlock(inspector: inspector),
          ),
          const SizedBox(height: 12),
          _InspectorSection(
            title: 'TAGS',
            child: _TagsBlock(inspector: inspector),
          ),
          const SizedBox(height: 12),
          _InspectorSection(
            title: 'CHAPITRES (${inspector.chapters.length})',
            child: _ChaptersBlock(chapters: inspector.chapters),
          ),
          const SizedBox(height: 12),
          _InspectorSection(
            title: 'STATUT ÉDITORIAL',
            child: _EditorialStatusBlock(
              editorialStatus: editorialStatus,
              projectHealth: projectHealth,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorIdentity extends StatelessWidget {
  const _InspectorIdentity({
    required this.projectName,
    required this.statusLabel,
    required this.accent,
  });

  final String projectName;
  final String statusLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.24)),
          ),
          alignment: Alignment.center,
          child: Icon(
            CupertinoIcons.compass_fill,
            color: accent,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                projectName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              _InspectorPill(label: statusLabel, accent: accent),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorCounters extends StatelessWidget {
  const _InspectorCounters({required this.counters});

  final List<NarrativeMetricSummary> counters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final counter in counters) _StructureCounterRow(counter: counter),
      ],
    );
  }
}

class _StructureCounterRow extends StatelessWidget {
  const _StructureCounterRow({required this.counter});

  final NarrativeMetricSummary counter;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, counter.availability);
    return Container(
      key: ValueKey('narrative-overview-structure-counter-${counter.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(_counterIcon(counter.id), color: accent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              counter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _metricValue(counter),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: _metricValue(counter).length > 12 ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorDivider(),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.inspector});

  final NarrativeStructureInspectorSummary inspector;

  @override
  Widget build(BuildContext context) {
    final description = inspector.description?.trim();
    if (inspector.descriptionAvailability ==
            NarrativeOverviewAvailability.available &&
        description != null &&
        description.isNotEmpty) {
      return _BodyText(description);
    }
    return const _UnavailableCopy(
      message: 'Description non disponible en V0.',
      detail: 'Aucun synopsis global fiable n’est encore exposé.',
    );
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock({required this.inspector});

  final NarrativeStructureInspectorSummary inspector;

  @override
  Widget build(BuildContext context) {
    if (inspector.tagsAvailability == NarrativeOverviewAvailability.available &&
        inspector.tags.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in inspector.tags) _TagChip(label: tag),
        ],
      );
    }
    return const _UnavailableCopy(
      message: 'Tags non disponibles en V0.',
      detail: 'Registre de tags à définir avant affichage.',
    );
  }
}

class _ChaptersBlock extends StatelessWidget {
  const _ChaptersBlock({required this.chapters});

  final List<NarrativeChapterOverviewSummary> chapters;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Text(
        'Aucun chapitre authoré.',
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Column(
      children: [
        for (final chapter in chapters) _ChapterRow(chapter: chapter),
      ],
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter});

  final NarrativeChapterOverviewSummary chapter;

  @override
  Widget build(BuildContext context) {
    final accent = _chapterAccent(chapter.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: EditorChrome.islandCoolTint.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              '${chapter.order + 1}',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              chapter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _chapterStatusLabel(chapter.status),
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialStatusBlock extends StatelessWidget {
  const _EditorialStatusBlock({
    required this.editorialStatus,
    required this.projectHealth,
  });

  final EditorialStatusSummary editorialStatus;
  final NarrativeProjectHealthSummary projectHealth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _EditorialStatusTile(
              slot: 'validation',
              label: 'Validation',
              value: _validationValue(editorialStatus),
              accent: _editorialAccent(
                context,
                editorialStatus.validationState,
              ),
            ),
            _EditorialStatusTile(
              slot: 'review',
              label: 'À revoir',
              value: '${editorialStatus.toReview}',
              accent: editorialStatus.toReview > 0
                  ? EditorChrome.accentWarm
                  : EditorChrome.subtleLabel(context),
            ),
            _EditorialStatusTile(
              slot: 'blocking',
              label: 'Bloquants',
              value: '${editorialStatus.blocking}',
              accent: editorialStatus.blocking > 0
                  ? EditorChrome.accentCoral
                  : EditorChrome.subtleLabel(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BodyText(editorialStatus.diagnosticSourceSummary),
        const SizedBox(height: 4),
        _BodyText(
          'Project Health : ${_projectHealthLabel(projectHealth.healthKind)}',
        ),
      ],
    );
  }
}

class _EditorialStatusTile extends StatelessWidget {
  const _EditorialStatusTile({
    required this.slot,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String slot;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('narrative-overview-structure-editorial-$slot'),
      constraints: const BoxConstraints(minWidth: 92),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: value.length > 14 ? 12 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCopy extends StatelessWidget {
  const _UnavailableCopy({
    required this.message,
    required this.detail,
  });

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        _BodyText(detail),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentPrimary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: EditorChrome.accentPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InspectorPill extends StatelessWidget {
  const _InspectorPill({
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
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InspectorDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.14),
    );
  }
}

String _metricValue(NarrativeMetricSummary metric) {
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

String _validationValue(EditorialStatusSummary editorialStatus) {
  if (editorialStatus.notEvaluated) {
    return 'Validation non lancée';
  }
  return switch (editorialStatus.validationState) {
    NarrativeEditorialValidationState.notEvaluated => 'Validation non lancée',
    NarrativeEditorialValidationState.upToDate => 'À jour',
    NarrativeEditorialValidationState.toReview => 'À revoir',
    NarrativeEditorialValidationState.blocking => 'Bloquant',
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

String _projectHealthLabel(NarrativeProjectHealthKind healthKind) {
  return switch (healthKind) {
    NarrativeProjectHealthKind.notEvaluated => 'Non évalué',
    NarrativeProjectHealthKind.healthy => 'Sain',
    NarrativeProjectHealthKind.reviewNeeded => 'À revoir',
    NarrativeProjectHealthKind.blocked => 'Bloqué',
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

Color _editorialAccent(
  BuildContext context,
  NarrativeEditorialValidationState state,
) {
  return switch (state) {
    NarrativeEditorialValidationState.notEvaluated => EditorChrome.accentWarm,
    NarrativeEditorialValidationState.upToDate => EditorChrome.accentJade,
    NarrativeEditorialValidationState.toReview => EditorChrome.accentWarm,
    NarrativeEditorialValidationState.blocking => EditorChrome.accentCoral,
  };
}

Color _chapterAccent(NarrativeChapterEditorialStatus status) {
  return switch (status) {
    NarrativeChapterEditorialStatus.defined => EditorChrome.accentJade,
    NarrativeChapterEditorialStatus.inProgress => EditorChrome.accentPrimary,
    NarrativeChapterEditorialStatus.draft => EditorChrome.accentLilac,
    NarrativeChapterEditorialStatus.notEvaluated => EditorChrome.accentWarm,
  };
}

IconData _counterIcon(String metricId) {
  return switch (metricId) {
    'chapters' => CupertinoIcons.book_fill,
    'scenes' => CupertinoIcons.rectangle_stack_fill,
    'cutscenes' => CupertinoIcons.film_fill,
    'dialogues' => CupertinoIcons.chat_bubble_2_fill,
    'facts' => CupertinoIcons.doc_text_fill,
    _ => CupertinoIcons.chart_bar_fill,
  };
}
