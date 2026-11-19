import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameExportStatus extends StatelessWidget {
  const GameExportStatus({super.key, required this.port});
  final StudioGameExportPort port;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = port.progress;
    final completed = port.stage == StudioExportStage.completed;
    final cancelling =
        port.stage == StudioExportStage.cancelled && port.operationActive;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (progress != null && (port.operationActive || completed)) ...[
            _GameExportProgress(progress: progress, completed: completed),
            const SizedBox(height: StudioSpacing.m),
          ],
          if (cancelling) StudioNotice(l10n.exportCancelling),
          if (port.stage == StudioExportStage.cancelled && !cancelling)
            StudioNotice(l10n.exportCancelled),
          if (completed) ...[
            StudioNotice(l10n.exportCompleted),
            if (port.outputPath case final path?) SelectableText(path),
            if (port.warning case final warning?) StudioNotice(warning),
          ],
          if (port.stage == StudioExportStage.failed) ...[
            StudioNotice(
              port.failure?.summary ?? port.error ?? l10n.exportFailed,
              isError: true,
            ),
            if (port.failure?.detail ?? port.error case final detail?)
              ExpansionTile(
                title: Text(l10n.exportDetails),
                children: [SelectableText(detail)],
              ),
          ],
        ],
      ),
    );
  }
}

class _GameExportProgress extends StatelessWidget {
  const _GameExportProgress({required this.progress, required this.completed});

  final StudioExportProgress progress;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final steps = StudioExportStep.values;
    final finished = completed ? steps.length : progress.step.index;
    final fraction = finished / steps.length;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.exportProgressSteps(
            finished,
            steps.length,
            (finished * 100) ~/ steps.length,
          ),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: StudioSpacing.s),
        ExcludeSemantics(child: LinearProgressIndicator(value: fraction)),
        const SizedBox(height: StudioSpacing.m),
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
            child: _GameExportProgressRow(
              label: _stepLabel(l10n, step),
              done: step.index < finished,
              active: !completed && step == progress.step,
              detail: step == progress.step && !completed
                  ? _itemProgress(l10n)
                  : null,
            ),
          ),
      ],
    );
  }

  String? _itemProgress(AppLocalizations l10n) {
    final checked = progress.itemsChecked;
    final total = progress.itemCount;
    if (checked == null || total == null || total <= 0) return null;
    return l10n.exportProgressItems(checked, total, (checked * 100) ~/ total);
  }
}

class _GameExportProgressRow extends StatelessWidget {
  const _GameExportProgressRow({
    required this.label,
    required this.done,
    required this.active,
    required this.detail,
  });

  final String label;
  final bool done;
  final bool active;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = done
        ? StudioColors.of(context).success
        : active
        ? colors.primary
        : colors.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done
              ? Icons.check_circle_outline
              : active
              ? Icons.play_circle_outline
              : Icons.radio_button_unchecked,
          size: 18,
          color: color,
        ),
        const SizedBox(width: StudioSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                value: active ? context.l10n.openingRunning : null,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
              if (detail case final text?)
                Text(text, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

String _stepLabel(AppLocalizations l10n, StudioExportStep step) =>
    switch (step) {
      StudioExportStep.saveProject => l10n.exportStepSave,
      StudioExportStep.checkItemIcons => l10n.exportStepItemIcons,
      StudioExportStep.checkCaptureSprites => l10n.exportStepCaptureSprites,
      StudioExportStep.verifyProfile => l10n.exportStepProfile,
      StudioExportStep.collectFiles => l10n.exportStepCollect,
      StudioExportStep.validateGame => l10n.exportStepValidate,
      StudioExportStep.buildArchive => l10n.exportStepArchive,
      StudioExportStep.inspectArchive => l10n.exportStepInspect,
      StudioExportStep.writePackage => l10n.exportStepWrite,
      StudioExportStep.finishExport => l10n.exportStepFinish,
    };
