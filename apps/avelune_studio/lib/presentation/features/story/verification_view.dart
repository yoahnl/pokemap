import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_problems.dart';
import 'package:avelune_studio/features/verification/application/verification_snapshot.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class VerificationView extends StatefulWidget {
  const VerificationView({
    super.key,
    required this.verification,
    required this.unsaved,
    required this.destination,
  });

  final ProjectVerificationController? verification;
  final bool unsaved;
  final Future<bool> Function()? Function(VerificationProblem problem)
  destination;

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  var _openRequest = 0;
  var _destinationUnavailable = false;

  Future<void> _open(Future<bool> Function() open) async {
    final request = ++_openRequest;
    if (_destinationUnavailable) {
      setState(() => _destinationUnavailable = false);
    }
    bool opened;
    try {
      opened = await open();
    } on Object {
      opened = false;
    }
    if (mounted && request == _openRequest && !opened) {
      setState(() => _destinationUnavailable = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final verification = widget.verification;
    if (verification == null) {
      return StudioEmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.verificationUnavailable,
      );
    }
    final phase = verification.phase;
    final snapshot = verification.snapshot;
    final problems = snapshot?.problems ?? const <VerificationProblem>[];
    final fresh = verification.freshness == VerificationFreshness.current;
    final clean = fresh && snapshot?.clean == true;
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
                    onPressed: () {
                      setState(() {
                        _openRequest++;
                        _destinationUnavailable = false;
                      });
                      unawaited(verification.start());
                    },
                  ),
                Text(l10n.verificationScope, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (widget.unsaved)
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
              child: StudioNotice(
                l10n.verificationCancelled,
                key: const ValueKey('verification-incomplete'),
              ),
            ),
          if (snapshot != null) ...[
            if (verification.freshness != VerificationFreshness.current)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.l,
                ),
                child: StudioNotice(
                  key: const ValueKey('verification-stale'),
                  verification.freshness == VerificationFreshness.stale
                      ? l10n.verificationStale
                      : l10n.verificationUnconfirmed,
                ),
              ),
            if (!snapshot.complete)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.l,
                ),
                child: StudioNotice(
                  l10n.verificationIncomplete,
                  key: const ValueKey('verification-incomplete'),
                ),
              ),
            if (problems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.l),
                child: Text(
                  l10n.verificationSummary(
                    snapshot.errors,
                    snapshot.warnings,
                    (snapshot.elapsed.inMilliseconds / 1000).toStringAsFixed(1),
                  ),
                  key: const ValueKey('verification-summary'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
          ],
          if (_destinationUnavailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
              child: StudioNotice(
                key: const ValueKey('verification-destination-unavailable'),
                l10n.verificationTargetUnavailable,
              ),
            ),
          Expanded(
            child: switch (phase) {
              ProjectVerificationPhase.idle => StudioEmptyState(
                icon: Icons.fact_check_outlined,
                title: l10n.verificationIdle,
                description: l10n.verificationIdleHint,
              ),
              ProjectVerificationPhase.done when clean => StudioEmptyState(
                key: const ValueKey('verification-clean'),
                icon: Icons.check_circle_outline,
                title: l10n.verificationCoveredClean,
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
    final open = widget.destination(problem);
    final label = switch ((problem.code, problem.objectName)) {
      (
        verificationUnreadableMap || verificationRuntimeMissingMap,
        final name?,
      ) =>
        l10n.verificationMapUnavailable(name),
      ('narrativeEventSceneMissing', _) => l10n.verificationTriggerSceneInvalid,
      ('worldRuleTargetUnknown', _) => l10n.verificationRuleTargetUnknown,
      ('sceneOutcomePolicyIndeterminate', _) =>
        l10n.verificationSceneEndIncomplete,
      ('dialogue.outcome_unused', _) => l10n.verificationDialogueOutcomeUnused,
      ('permanentlyBlocked', _) => l10n.verificationPhysicalTriggerBlocked,
      _ => problem.message,
    };
    final tap = open == null ? null : () => unawaited(_open(open));
    final tone = switch (problem.severity) {
      VerificationProblemSeverity.error => StudioTone.danger,
      VerificationProblemSeverity.warning => StudioTone.warning,
      VerificationProblemSeverity.info => StudioTone.info,
    };
    final severity = l10n.verificationSeverity(problem.severity.name);
    final badge = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: StudioBadge(severity, tone: tone),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final showBadge = tap == null || constraints.maxWidth >= 420;
        return StudioChoice(
          key: ValueKey('verification-problem-$index'),
          label: label,
          maxLines: 3,
          subtitle: [
            if (!showBadge) severity,
            l10n.verificationIssueKind(problem.destination.name),
            ?problem.objectName,
            ?problem.location,
            if (problem.objectState case final state?)
              l10n.verificationIssueStatus(state.name),
          ].join(' · '),
          leading: Icon(switch (problem.severity) {
            VerificationProblemSeverity.error => Icons.error_outline,
            VerificationProblemSeverity.warning => Icons.warning_amber_outlined,
            VerificationProblemSeverity.info => Icons.info_outline,
          }, color: tone.color(context)),
          tone: tone,
          trailing: Wrap(
            spacing: StudioSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (showBadge) badge,
              if (tap != null)
                StudioButton(
                  key: ValueKey('verification-open-$index'),
                  label: l10n.verificationOpen,
                  icon: Icons.arrow_forward,
                  variant: StudioButtonVariant.quiet,
                  onPressed: tap,
                ),
            ],
          ),
          onTap: tap,
        );
      },
    );
  }
}

class VerificationCoverageView extends StatelessWidget {
  const VerificationCoverageView({super.key, required this.snapshot});

  final VerificationSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = this.snapshot;
    if (snapshot == null) {
      return StudioEmptyState(
        icon: Icons.fact_check_outlined,
        title: l10n.verificationRecordedOnly,
        description: l10n.verificationScope,
      );
    }
    final revision = snapshot.revision;
    final shortRevision = revision.length > 20
        ? '${revision.substring(0, 20)}…'
        : revision;
    String status(String? name) => l10n.verificationDimensionStatus(
      name == 'pass' && snapshot.unreadableMapCount > 0
          ? 'partial'
          : name ?? 'notRun',
    );
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.l),
      children: [
        StudioSection(
          title: l10n.verificationCoverage,
          children: [
            Tooltip(
              message: l10n.verificationRevision(revision),
              child: Text(l10n.verificationRevision(shortRevision)),
            ),
            Text(
              '${l10n.verificationSymbolic} · ${status(snapshot.symbolic?.name)}',
            ),
            Text(
              '${l10n.verificationPhysical} · ${status(snapshot.physical.name)}',
            ),
            if (snapshot.unreadableMapCount > 0)
              Text(l10n.verificationExcludedMaps(snapshot.unreadableMapCount)),
            for (final limitation in snapshot.physicalLimitations)
              Text(limitation),
            Text(l10n.verificationTranslationScope),
            for (final dialogue in snapshot.unreadableDialogues)
              Text(l10n.verificationMissingDialogue(dialogue.name)),
          ],
        ),
      ],
    );
  }
}
