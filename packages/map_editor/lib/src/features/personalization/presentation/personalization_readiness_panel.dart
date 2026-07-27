import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_panel.dart';
import '../application/personalization_publish_readiness.dart';

/// Compact publication preparation table for all presentation categories.
class PersonalizationReadinessPanel extends StatelessWidget {
  const PersonalizationReadinessPanel({
    super.key,
    required this.report,
    this.onCorrectIssue,
    this.requiresPreflight = false,
    this.hasCompletedPreflight = true,
    this.isPreflightRunning = false,
    this.isPreflightStale = false,
    this.hasUnsavedChanges = false,
    this.preflightError,
    this.onRunPreflight,
    this.onSaveDraft,
    this.canContinueToExport = false,
    this.onContinueToExport,
  });

  final PersonalizationPublishReadiness report;
  final ValueChanged<PersonalizationReadinessIssue>? onCorrectIssue;
  final bool requiresPreflight;
  final bool hasCompletedPreflight;
  final bool isPreflightRunning;
  final bool isPreflightStale;
  final bool hasUnsavedChanges;
  final String? preflightError;
  final VoidCallback? onRunPreflight;
  final VoidCallback? onSaveDraft;
  final bool canContinueToExport;
  final VoidCallback? onContinueToExport;

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
              label: _overallLabel(
                report,
                requiresPreflight: requiresPreflight,
                hasCompletedPreflight: hasCompletedPreflight,
                isPreflightRunning: isPreflightRunning,
                isPreflightStale: isPreflightStale,
                hasUnsavedChanges: hasUnsavedChanges,
                hasPreflightError: preflightError != null,
              ),
              variant: _overallBadgeVariant(
                report,
                requiresPreflight: requiresPreflight,
                hasCompletedPreflight: hasCompletedPreflight,
                isPreflightRunning: isPreflightRunning,
                isPreflightStale: isPreflightStale,
                hasUnsavedChanges: hasUnsavedChanges,
                hasPreflightError: preflightError != null,
              ),
            ),
            if (requiresPreflight)
              PokeMapButton(
                key: const ValueKey<String>(
                  'personalization-readiness-run-preflight',
                ),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(Icons.fact_check_outlined),
                isLoading: isPreflightRunning,
                onPressed: isPreflightRunning ? null : onRunPreflight,
                child: Text(
                  isPreflightRunning
                      ? 'Vérification en cours…'
                      : hasCompletedPreflight
                          ? 'Relancer le preflight'
                          : 'Lancer le preflight',
                ),
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
          const spacing = 10.0;
          final width = (constraints.maxWidth - spacing * (columnCount - 1)) /
              columnCount;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (preflightError case final error?) ...<Widget>[
                PokeMapCard(
                  key: const ValueKey<String>(
                    'personalization-readiness-preflight-error',
                  ),
                  child: Text(error),
                ),
                const SizedBox(height: 10),
              ],
              if (hasUnsavedChanges) ...<Widget>[
                PokeMapCard(
                  key: const ValueKey<String>(
                    'personalization-readiness-unsaved',
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Enregistrez le brouillon avant de poursuivre vers '
                        'l’export.',
                      ),
                      PokeMapButton(
                        key: const ValueKey<String>(
                          'personalization-readiness-save-draft',
                        ),
                        size: PokeMapButtonSize.small,
                        leading: const Icon(Icons.save_outlined),
                        onPressed: onSaveDraft,
                        child: const Text('Enregistrer le brouillon'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  for (final category in report.categories)
                    SizedBox(
                      width: width,
                      child: _ReadinessCategoryCard(readiness: category),
                    ),
                ],
              ),
              if (report.issues.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                const Text(
                  'Corrections recommandées',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final (index, issue) in report.issues.indexed) ...<Widget>[
                  _ReadinessIssueCard(
                    key: ValueKey<String>(
                      'personalization-readiness-issue-$index',
                    ),
                    issue: issue,
                    correctionKey: ValueKey<String>(
                      'personalization-readiness-correction-$index',
                    ),
                    onCorrect: onCorrectIssue == null
                        ? null
                        : () => onCorrectIssue!(issue),
                  ),
                  if (index < report.issues.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
              if (requiresPreflight) ...<Widget>[
                const SizedBox(height: 12),
                PokeMapCard(
                  key: const ValueKey<String>(
                    'personalization-readiness-export-guide',
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Text(
                          canContinueToExport
                              ? 'Toutes les vérifications sont terminées. '
                                  'Poursuivez dans le flux de publication.'
                              : 'Le passage vers l’export sera disponible '
                                  'après un preflight valide et '
                                  'l’enregistrement du brouillon.',
                        ),
                      ),
                      PokeMapButton(
                        key: const ValueKey<String>(
                          'personalization-readiness-export',
                        ),
                        variant: PokeMapButtonVariant.success,
                        size: PokeMapButtonSize.medium,
                        leading: const Icon(Icons.rocket_launch_outlined),
                        onPressed:
                            canContinueToExport ? onContinueToExport : null,
                        child: const Text('Continuer vers l’export'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
          if (!constraints.hasBoundedHeight) return content;
          return SingleChildScrollView(child: content);
        },
      ),
    );
  }
}

class _ReadinessIssueCard extends StatelessWidget {
  const _ReadinessIssueCard({
    super.key,
    required this.issue,
    required this.correctionKey,
    required this.onCorrect,
  });

  final PersonalizationReadinessIssue issue;
  final Key correctionKey;
  final VoidCallback? onCorrect;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      issue.isBlocker
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        issue.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(issue.explanation),
              ],
            ),
          ),
          PokeMapButton(
            key: correctionKey,
            variant: issue.correctionKind ==
                    PersonalizationCorrectionKind.useSafeTheme
                ? PokeMapButtonVariant.successOutline
                : PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(Icons.build_outlined),
            onPressed: onCorrect,
            child: Text(issue.correctionLabel),
          ),
        ],
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

String _overallLabel(
  PersonalizationPublishReadiness report, {
  required bool requiresPreflight,
  required bool hasCompletedPreflight,
  required bool isPreflightRunning,
  required bool isPreflightStale,
  required bool hasUnsavedChanges,
  required bool hasPreflightError,
}) {
  if (isPreflightRunning) return 'Vérification en cours…';
  if (hasPreflightError) return 'Preflight interrompu';
  if (isPreflightStale) return 'Preflight à relancer';
  if (requiresPreflight && !hasCompletedPreflight) return 'Preflight requis';
  if (hasUnsavedChanges) return 'Brouillon à enregistrer';
  return switch (report.status) {
    PersonalizationReadinessStatus.blocked => 'Export bloqué',
    PersonalizationReadinessStatus.attention => 'Prêt avec avertissements',
    PersonalizationReadinessStatus.ready => 'Prêt à exporter',
  };
}

PokeMapBadgeVariant _overallBadgeVariant(
  PersonalizationPublishReadiness report, {
  required bool requiresPreflight,
  required bool hasCompletedPreflight,
  required bool isPreflightRunning,
  required bool isPreflightStale,
  required bool hasUnsavedChanges,
  required bool hasPreflightError,
}) {
  if (hasPreflightError) return PokeMapBadgeVariant.error;
  if (isPreflightStale || hasUnsavedChanges) {
    return PokeMapBadgeVariant.warning;
  }
  if (isPreflightRunning || (requiresPreflight && !hasCompletedPreflight)) {
    return PokeMapBadgeVariant.info;
  }
  return _badgeVariant(report.status);
}

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
