import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/home/project_loading_phase_row.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/widgets/avelune_wordmark.dart';

class ProjectLoadingScreen extends StatefulWidget {
  const ProjectLoadingScreen({
    super.key,
    required this.progress,
    required this.subtitle,
  });

  final ProjectOpeningProgress progress;
  final String subtitle;

  static const fadeDuration = Duration(milliseconds: 300);

  @override
  State<ProjectLoadingScreen> createState() => _ProjectLoadingScreenState();
}

class _ProjectLoadingScreenState extends State<ProjectLoadingScreen> {
  var _gone = false;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_changed);
  }

  @override
  void didUpdateWidget(ProjectLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.progress, widget.progress)) return;
    oldWidget.progress.removeListener(_changed);
    widget.progress.addListener(_changed);
    _gone = false;
  }

  @override
  void dispose() {
    widget.progress.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final progress = widget.progress;
    final settled = progress.settled;
    return IgnorePointer(
      ignoring: settled,
      child: AnimatedOpacity(
        opacity: settled ? 0 : 1,
        duration: ProjectLoadingScreen.fadeDuration,
        onEnd: () {
          if (mounted && widget.progress.settled) setState(() => _gone = true);
        },
        child: _ProjectLoadingContent(
          progress: progress,
          subtitle: widget.subtitle,
        ),
      ),
    );
  }
}

class _ProjectLoadingContent extends StatelessWidget {
  const _ProjectLoadingContent({
    required this.progress,
    required this.subtitle,
  });

  final ProjectOpeningProgress progress;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (progress.fraction * 100).floor();
    return Scaffold(
      key: const ValueKey('studio-opening'),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(StudioSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AveluneWordmark(height: 40)),
                  const SizedBox(height: StudioSpacing.xxl * 2),
                  Text(l10n.openingTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    subtitle,
                    key: const ValueKey('studio-opening-subtitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: ProjectLoadingBar(
                          key: const ValueKey('studio-opening-overall'),
                          value: progress.fraction,
                          height: 8,
                        ),
                      ),
                      const SizedBox(width: StudioSpacing.l),
                      SizedBox(
                        width: 48,
                        child: Text(
                          l10n.openingPercent('$percent'),
                          key: const ValueKey('studio-opening-percent'),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StudioSpacing.xxl),
                  for (final phase in ProjectOpeningPhase.values) ...[
                    if (phase.index > 0)
                      const SizedBox(height: StudioSpacing.l),
                    ProjectLoadingPhaseRow(phase: phase, step: progress[phase]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
