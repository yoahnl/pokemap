import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_panel.dart';
import '../application/personalization_publish_readiness.dart';

/// Compact publication preparation table for all presentation categories.
class PersonalizationReadinessPanel extends StatelessWidget {
  const PersonalizationReadinessPanel({
    super.key,
    required this.report,
  });

  final PersonalizationPublishReadiness report;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey<String>('personalization-readiness-panel'),
      header: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Préparation à l’export',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text('Vérifiez chaque catégorie avant de publier votre jeu.'),
              ],
            ),
            PokeMapBadge(
              key: const ValueKey<String>(
                'personalization-readiness-overall',
              ),
              label: _overallLabel(report),
              variant: _badgeVariant(report.status),
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnCount = constraints.maxWidth >= 680
              ? 4
              : constraints.maxWidth >= 480
                  ? 2
                  : 1;
          final spacing = 10.0;
          final width = (constraints.maxWidth - spacing * (columnCount - 1)) /
              columnCount;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: <Widget>[
              for (final category in report.categories)
                SizedBox(
                  width: width,
                  child: _ReadinessCategoryCard(readiness: category),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadinessCategoryCard extends StatelessWidget {
  const _ReadinessCategoryCard({required this.readiness});

  final PersonalizationCategoryReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: ValueKey<String>(
        'personalization-readiness-${readiness.category.name}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_categoryIcon(readiness.category), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _categoryLabel(readiness.category),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PokeMapBadge(
            label: _categoryStatusLabel(readiness),
            variant: _badgeVariant(readiness.status),
          ),
          const SizedBox(height: 8),
          Text(
            readiness.issues.isEmpty
                ? readiness.isConfigured
                    ? 'Configuration valide.'
                    : 'Optionnel · réglages par défaut valides.'
                : _issueSummary(readiness),
          ),
        ],
      ),
    );
  }
}

String _overallLabel(PersonalizationPublishReadiness report) =>
    switch (report.status) {
      PersonalizationReadinessStatus.blocked => 'Export bloqué',
      PersonalizationReadinessStatus.attention => 'Prêt avec avertissements',
      PersonalizationReadinessStatus.ready => 'Prêt à exporter',
    };

String _categoryStatusLabel(PersonalizationCategoryReadiness readiness) =>
    switch (readiness.status) {
      PersonalizationReadinessStatus.blocked => 'À corriger',
      PersonalizationReadinessStatus.attention => 'À vérifier',
      PersonalizationReadinessStatus.ready => 'Prêt',
    };

String _issueSummary(PersonalizationCategoryReadiness readiness) {
  final parts = <String>[
    if (readiness.blockerCount > 0)
      '${readiness.blockerCount} '
          '${readiness.blockerCount == 1 ? 'blocage' : 'blocages'}',
    if (readiness.warningCount > 0)
      '${readiness.warningCount} '
          '${readiness.warningCount == 1 ? 'avertissement' : 'avertissements'}',
  ];
  return parts.join(' · ');
}

PokeMapBadgeVariant _badgeVariant(PersonalizationReadinessStatus status) =>
    switch (status) {
      PersonalizationReadinessStatus.ready => PokeMapBadgeVariant.success,
      PersonalizationReadinessStatus.attention => PokeMapBadgeVariant.warning,
      PersonalizationReadinessStatus.blocked => PokeMapBadgeVariant.error,
    };

String _categoryLabel(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'Branding',
      ProjectPresentationCategory.intro => 'Intro vidéo',
      ProjectPresentationCategory.typography => 'Typographie',
      ProjectPresentationCategory.theme => 'Thème & HUD',
    };

IconData _categoryIcon(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => Icons.auto_awesome_outlined,
      ProjectPresentationCategory.intro => Icons.movie_outlined,
      ProjectPresentationCategory.typography => Icons.font_download_outlined,
      ProjectPresentationCategory.theme => Icons.palette_outlined,
    };
