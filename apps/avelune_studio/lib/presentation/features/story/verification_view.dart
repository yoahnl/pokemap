import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_problems.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({
    super.key,
    required this.verification,
    required this.unsaved,
    required this.destination,
  });

  final ProjectVerificationController? verification;
  final bool unsaved;
  final VoidCallback? Function(VerificationProblem problem) destination;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final verification = this.verification;
    if (verification == null) {
      return StudioEmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.verificationUnavailable,
      );
    }
    final phase = verification.phase;
    final problems = verification.problems;
    final counts = {
      for (final severity in VerificationProblemSeverity.values)
        severity: problems.where((p) => p.severity == severity).length,
    };
    return Material(
      key: const ValueKey('verification-view'),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.l),
            child: Wrap(
              spacing: StudioSpacing.m,
              runSpacing: StudioSpacing.m,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (verification.running)
                  StudioButton(
                    key: const ValueKey('verification-cancel'),
                    label: l10n.verificationCancel,
                    icon: Icons.stop_circle_outlined,
                    variant: StudioButtonVariant.secondary,
                    onPressed: verification.cancel,
                  )
                else
                  StudioButton(
                    key: const ValueKey('verification-start'),
                    label: l10n.verificationStart,
                    icon: Icons.fact_check_outlined,
                    onPressed: () => unawaited(verification.start()),
                  ),
                Text(l10n.verificationScope, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (unsaved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
              child: StudioNotice(
                key: const ValueKey('verification-unsaved'),
                l10n.verificationUnsaved,
              ),
            ),
          if (verification.running)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: Column(
                key: const ValueKey('verification-progress'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.verificationPhase(
                      phase.name,
                      verification.mapsLoaded,
                      verification.mapsTotal,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.s),
                  LinearProgressIndicator(
                    value:
                        phase == ProjectVerificationPhase.maps &&
                            verification.mapsTotal > 0
                        ? verification.mapsLoaded / verification.mapsTotal
                        : null,
                  ),
                ],
              ),
            ),
          if (phase == ProjectVerificationPhase.failed)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: StudioNotice(
                key: const ValueKey('verification-failed'),
                l10n.verificationFailed('${verification.failure}'),
                isError: true,
              ),
            ),
          if (phase == ProjectVerificationPhase.cancelled)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: StudioNotice(l10n.verificationCancelled),
            ),
          if (phase == ProjectVerificationPhase.done)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: Text(
                l10n.verificationSummary(
                  counts[VerificationProblemSeverity.error]!,
                  counts[VerificationProblemSeverity.warning]!,
                  ((verification.elapsed?.inMilliseconds ?? 0) / 1000)
                      .toStringAsFixed(1),
                ),
                key: const ValueKey('verification-summary'),
                style: theme.textTheme.titleSmall,
              ),
            ),
          Expanded(
            child: switch (phase) {
              ProjectVerificationPhase.idle => StudioEmptyState(
                icon: Icons.fact_check_outlined,
                title: l10n.verificationIdle,
                description: l10n.verificationIdleHint,
              ),
              ProjectVerificationPhase.done when problems.isEmpty =>
                StudioEmptyState(
                  key: const ValueKey('verification-clean'),
                  icon: Icons.check_circle_outline,
                  title: l10n.verificationClean,
                ),
              ProjectVerificationPhase.done => ListView.builder(
                key: const ValueKey('verification-problems'),
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.l,
                ),
                itemCount: problems.length,
                itemBuilder: (context, index) =>
                    _row(context, index, problems[index]),
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int index, VerificationProblem problem) {
    final l10n = context.l10n;
    final open = destination(problem);
    return StudioChoice(
      key: ValueKey('verification-problem-$index'),
      label: problem.message,
      maxLines: 3,
      subtitle: l10n.verificationSeverity(problem.severity.name),
      tone: problem.severity == VerificationProblemSeverity.error
          ? StudioTone.danger
          : problem.severity == VerificationProblemSeverity.warning
          ? StudioTone.warning
          : null,
      trailing: open == null
          ? null
          : StudioButton(
              key: ValueKey('verification-open-$index'),
              label: l10n.verificationOpen,
              variant: StudioButtonVariant.quiet,
              onPressed: open,
            ),
      onTap: open,
    );
  }
}
