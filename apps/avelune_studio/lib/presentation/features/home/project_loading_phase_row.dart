import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class ProjectLoadingPhaseRow extends StatelessWidget {
  const ProjectLoadingPhaseRow({
    super.key,
    required this.phase,
    required this.step,
  });

  final ProjectOpeningPhase phase;
  final ProjectOpeningStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = step.status != ProjectOpeningStepStatus.pending;
    return Row(
      key: ValueKey('studio-opening-${phase.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: switch (step.status) {
            ProjectOpeningStepStatus.pending => Icon(
              Icons.radio_button_unchecked,
              size: 18,
              color: scheme.outlineVariant,
            ),
            ProjectOpeningStepStatus.running => const Padding(
              padding: EdgeInsets.all(StudioSpacing.xxs),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            ProjectOpeningStepStatus.done => Icon(
              Icons.check_circle,
              size: 18,
              color: scheme.primary,
            ),
            ProjectOpeningStepStatus.skipped => Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            ProjectOpeningStepStatus.failed => Icon(
              Icons.error,
              size: 18,
              color: scheme.error,
            ),
          },
        ),
        const SizedBox(width: StudioSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      projectOpeningPhaseLabel(l10n, phase),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: active ? null : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    _detail(context, l10n),
                    key: ValueKey('studio-opening-${phase.name}-detail'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: step.status == ProjectOpeningStepStatus.failed
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StudioSpacing.xs),
              ProjectLoadingBar(
                value: step.fraction,
                height: 4,
                color: step.status == ProjectOpeningStepStatus.failed
                    ? scheme.error
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _detail(BuildContext context, AppLocalizations l10n) {
    String percent(double value) =>
        l10n.openingPercent('${(value * 100).floor()}');
    return switch (step.status) {
      ProjectOpeningStepStatus.pending => percent(0),
      ProjectOpeningStepStatus.running => switch ((step.total, step.fraction)) {
        (final total?, final fraction?) => l10n.openingCount(
          '${step.completed}',
          '$total',
          '${(fraction * 100).floor()}',
        ),
        _ => l10n.openingRunning,
      },
      ProjectOpeningStepStatus.done => switch (step.elapsed) {
        final elapsed? => l10n.openingElapsed(
          NumberFormat(
            '0.0',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(elapsed.inMicroseconds / Duration.microsecondsPerSecond),
        ),
        null => percent(1),
      },
      ProjectOpeningStepStatus.skipped => l10n.openingSkipped,
      ProjectOpeningStepStatus.failed => l10n.openingFailed,
    };
  }
}

class ProjectLoadingBar extends StatelessWidget {
  const ProjectLoadingBar({
    super.key,
    required this.value,
    required this.height,
    this.color,
  });

  final double? value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: value,
    minHeight: height,
    color: color,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(height / 2),
  );
}

String projectOpeningPhaseLabel(
  AppLocalizations l10n,
  ProjectOpeningPhase phase,
) => switch (phase) {
  ProjectOpeningPhase.project => l10n.openingPhaseProject,
  ProjectOpeningPhase.workshop => l10n.openingPhaseWorkshop,
  ProjectOpeningPhase.map => l10n.openingPhaseMap,
  ProjectOpeningPhase.resources => l10n.openingPhaseResources,
  ProjectOpeningPhase.palette => l10n.openingPhasePalette,
  ProjectOpeningPhase.scene => l10n.openingPhaseScene,
};
