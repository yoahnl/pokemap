import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/l10n.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_panel.dart';
import '../application/personalization_publish_readiness.dart';
import 'personalization_readiness_localizations.dart';

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
    final l10n = context.pokeMapL10n;
    final copy = PersonalizationReadinessCopy(l10n);
    final overallLabel = copy.overallLabel(
      report,
      requiresPreflight: requiresPreflight,
      hasCompletedPreflight: hasCompletedPreflight,
      isPreflightRunning: isPreflightRunning,
      isPreflightStale: isPreflightStale,
      hasUnsavedChanges: hasUnsavedChanges,
      hasPreflightError: preflightError != null,
    );

    void moveFocus({required bool forward}) {
      final scope = FocusScope.of(context);
      if (forward) {
        scope.nextFocus();
      } else {
        scope.previousFocus();
      }
    }

    void activatePrimaryAction() {
      if (canContinueToExport && onContinueToExport != null) {
        onContinueToExport!();
        return;
      }
      if (!isPreflightRunning && onRunPreflight != null) {
        onRunPreflight!();
      }
    }

    Widget buildPanel({required bool expandChild}) => PokeMapPanel(
          key: const ValueKey<String>('personalization-readiness-panel'),
          expandChild: expandChild,
          header: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.personalizationReadinessTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.personalizationReadinessDescription),
                  ],
                ),
                Semantics(
                  key: const ValueKey<String>(
                    'personalization-readiness-overall-semantics',
                  ),
                  label: overallLabel,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: PokeMapBadge(
                      key: const ValueKey<String>(
                        'personalization-readiness-overall',
                      ),
                      label: overallLabel,
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
                          ? l10n.personalizationChecking
                          : hasCompletedPreflight
                              ? l10n.personalizationRerunPreflight
                              : l10n.personalizationRunPreflight,
                    ),
                  ),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = _ReadinessContent(
                report: report,
                onCorrectIssue: onCorrectIssue,
                requiresPreflight: requiresPreflight,
                hasUnsavedChanges: hasUnsavedChanges,
                preflightError: preflightError,
                onSaveDraft: onSaveDraft,
                canContinueToExport: canContinueToExport,
                onContinueToExport: onContinueToExport,
              );
              if (!expandChild) return content;
              return SingleChildScrollView(child: content);
            },
          ),
        );

    return Semantics(
      key: const ValueKey<String>('personalization-readiness-semantics'),
      container: true,
      explicitChildNodes: true,
      label: l10n.personalizationReadinessSemantics,
      value: overallLabel,
      liveRegion: isPreflightRunning ||
          isPreflightStale ||
          preflightError != null ||
          hasCompletedPreflight,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.gameButtonA):
              activatePrimaryAction,
          const SingleActivator(LogicalKeyboardKey.gameButtonStart):
              activatePrimaryAction,
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              moveFocus(forward: true),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              moveFocus(forward: true),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              moveFocus(forward: false),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              moveFocus(forward: false),
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boundedHeight = constraints.hasBoundedHeight &&
                  constraints.maxHeight.isFinite;
              final panel = buildPanel(expandChild: boundedHeight);
              if (!boundedHeight) return panel;
              return SizedBox(height: constraints.maxHeight, child: panel);
            },
          ),
        ),
      ),
    );
  }
}

class _ReadinessContent extends StatelessWidget {
  const _ReadinessContent({
    required this.report,
    required this.onCorrectIssue,
    required this.requiresPreflight,
    required this.hasUnsavedChanges,
    required this.preflightError,
    required this.onSaveDraft,
    required this.canContinueToExport,
    required this.onContinueToExport,
  });

  final PersonalizationPublishReadiness report;
  final ValueChanged<PersonalizationReadinessIssue>? onCorrectIssue;
  final bool requiresPreflight;
  final bool hasUnsavedChanges;
  final String? preflightError;
  final VoidCallback? onSaveDraft;
  final bool canContinueToExport;
  final VoidCallback? onContinueToExport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.pokeMapL10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 680
            ? 4
            : constraints.maxWidth >= 480
                ? 2
                : 1;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        return Column(
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
                    Text(l10n.personalizationSaveGuidance),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'personalization-readiness-save-draft',
                      ),
                      size: PokeMapButtonSize.small,
                      leading: const Icon(Icons.save_outlined),
                      onPressed: onSaveDraft,
                      child: Text(l10n.personalizationSaveDraft),
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
              Text(
                l10n.personalizationCorrectionsRecommended,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
                if (index < report.issues.length - 1) const SizedBox(height: 8),
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
                            ? l10n.personalizationExportReadyGuidance
                            : l10n.personalizationExportLockedGuidance,
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
                      child: Text(l10n.personalizationContinueToExport),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
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
    final l10n = context.pokeMapL10n;
    final copy = PersonalizationReadinessCopy(l10n);
    final title = copy.issueTitle(issue);
    final explanation = copy.issueExplanation(issue);
    final severity = issue.isBlocker
        ? l10n.personalizationSeverityBlocker
        : l10n.personalizationSeverityWarning;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$title. $severity. $explanation',
      child: PokeMapCard(
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            ExcludeSemantics(
              child: ConstrainedBox(
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
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(explanation),
                  ],
                ),
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
              child: Text(copy.correctionLabel(issue)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCategoryCard extends StatelessWidget {
  const _ReadinessCategoryCard({required this.readiness});

  final PersonalizationCategoryReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.pokeMapL10n;
    final copy = PersonalizationReadinessCopy(l10n);
    final label = copy.categoryLabel(readiness.category);
    final status = copy.categoryStatus(readiness);
    final summary = readiness.issues.isEmpty
        ? readiness.isConfigured
            ? l10n.personalizationCategoryValid
            : l10n.personalizationCategoryDefaultValid
        : copy.issueSummary(readiness);
    return Semantics(
      key: ValueKey<String>(
        'personalization-readiness-${readiness.category.name}',
      ),
      container: true,
      label: '$label. $status. $summary',
      child: ExcludeSemantics(
        child: PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(_categoryIcon(readiness.category), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PokeMapBadge(
                label: status,
                variant: _badgeVariant(readiness.status),
              ),
              const SizedBox(height: 8),
              Text(summary),
            ],
          ),
        ),
      ),
    );
  }
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

PokeMapBadgeVariant _badgeVariant(PersonalizationReadinessStatus status) =>
    switch (status) {
      PersonalizationReadinessStatus.ready => PokeMapBadgeVariant.success,
      PersonalizationReadinessStatus.attention => PokeMapBadgeVariant.warning,
      PersonalizationReadinessStatus.blocked => PokeMapBadgeVariant.error,
    };

IconData _categoryIcon(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => Icons.auto_awesome_outlined,
      ProjectPresentationCategory.intro => Icons.movie_outlined,
      ProjectPresentationCategory.typography => Icons.font_download_outlined,
      ProjectPresentationCategory.theme => Icons.palette_outlined,
      ProjectPresentationCategory.layouts => Icons.dashboard_customize_outlined,
    };
