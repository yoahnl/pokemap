import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';

enum HubInstallMilestone {
  package,
  snapshot,
  extraction,
  verification,
  validation,
  activation,
  library,
}

final class HubInstallMilestonePresentation {
  const HubInstallMilestonePresentation({
    required this.milestone,
    required this.state,
  });

  final HubInstallMilestone milestone;
  final PlayerProgressStepState state;
}

/// Pure, deterministic projection of real installer signals for the Hub UI.
final class HubInstallProgressPresentation {
  const HubInstallProgressPresentation({
    required this.fraction,
    required this.remaining,
    required this.milestones,
  });

  factory HubInstallProgressPresentation.from(
    GameInstallProgress? progress, {
    required Duration elapsed,
  }) {
    final fraction = _fraction(progress);
    final remaining = _remaining(fraction, elapsed);
    return HubInstallProgressPresentation(
      fraction: fraction,
      remaining: remaining,
      milestones: <HubInstallMilestonePresentation>[
        for (final milestone in HubInstallMilestone.values)
          HubInstallMilestonePresentation(
            milestone: milestone,
            state: _milestoneState(progress?.stage, milestone),
          ),
      ],
    );
  }

  final double fraction;
  final Duration? remaining;
  final List<HubInstallMilestonePresentation> milestones;

  int get percent => (fraction * 100).round().clamp(0, 100);

  static double _fraction(GameInstallProgress? progress) {
    if (progress == null) return 0;
    final detail = progress.totalBytes > 0
        ? progress.completedBytes / progress.totalBytes
        : progress.totalFiles > 0
            ? progress.completedFiles / progress.totalFiles
            : 0.0;
    final bounded = detail.clamp(0.0, 1.0);
    return switch (progress.stage) {
      GameInstallStage.recovering => .01,
      GameInstallStage.inspecting => .03,
      GameInstallStage.checkingCompatibility => .08,
      GameInstallStage.checkingStorage => .12,
      GameInstallStage.snapshotting => .12 + (.18 * bounded),
      GameInstallStage.extracting => .30 + (.30 * bounded),
      GameInstallStage.verifying => .66,
      GameInstallStage.validatingProject => .74,
      GameInstallStage.smokeLoading => .82,
      GameInstallStage.preparingSaves => .87,
      GameInstallStage.promoting => .93,
      GameInstallStage.updatingLibrary => .98,
      GameInstallStage.completed => 1,
      GameInstallStage.cancelled => 0,
    };
  }

  static Duration? _remaining(double fraction, Duration elapsed) {
    if (fraction < .05 ||
        fraction >= 1 ||
        elapsed < const Duration(seconds: 1)) {
      return null;
    }
    final remainingMilliseconds =
        (elapsed.inMilliseconds * ((1 - fraction) / fraction)).round();
    if (remainingMilliseconds <= 0) return const Duration(seconds: 1);
    const maximum = Duration(hours: 24);
    final estimate = Duration(milliseconds: remainingMilliseconds);
    return estimate > maximum ? maximum : estimate;
  }

  static PlayerProgressStepState _milestoneState(
    GameInstallStage? stage,
    HubInstallMilestone milestone,
  ) {
    if (stage == null) return PlayerProgressStepState.pending;
    if (stage == GameInstallStage.completed) {
      return PlayerProgressStepState.completed;
    }
    final rank = _stageRank(stage);
    final start = switch (milestone) {
      HubInstallMilestone.package => 1,
      HubInstallMilestone.snapshot => 4,
      HubInstallMilestone.extraction => 5,
      HubInstallMilestone.verification => 6,
      HubInstallMilestone.validation => 7,
      HubInstallMilestone.activation => 10,
      HubInstallMilestone.library => 11,
    };
    final end = switch (milestone) {
      HubInstallMilestone.package => 4,
      HubInstallMilestone.snapshot => 5,
      HubInstallMilestone.extraction => 6,
      HubInstallMilestone.verification => 7,
      HubInstallMilestone.validation => 10,
      HubInstallMilestone.activation => 11,
      HubInstallMilestone.library => 12,
    };
    if (rank >= end) return PlayerProgressStepState.completed;
    if (rank >= start) return PlayerProgressStepState.active;
    return PlayerProgressStepState.pending;
  }

  static int _stageRank(GameInstallStage stage) => switch (stage) {
        GameInstallStage.recovering => 0,
        GameInstallStage.inspecting => 1,
        GameInstallStage.checkingCompatibility => 2,
        GameInstallStage.checkingStorage => 3,
        GameInstallStage.snapshotting => 4,
        GameInstallStage.extracting => 5,
        GameInstallStage.verifying => 6,
        GameInstallStage.validatingProject => 7,
        GameInstallStage.smokeLoading => 8,
        GameInstallStage.preparingSaves => 9,
        GameInstallStage.promoting => 10,
        GameInstallStage.updatingLibrary => 11,
        GameInstallStage.completed => 12,
        GameInstallStage.cancelled => 0,
      };
}

class HubInstallProgressScreen extends StatefulWidget {
  const HubInstallProgressScreen({
    super.key,
    required this.progress,
    this.onCancel,
  });

  final GameInstallProgress? progress;
  final VoidCallback? onCancel;

  @override
  State<HubInstallProgressScreen> createState() =>
      _HubInstallProgressScreenState();
}

class _HubInstallProgressScreenState extends State<HubInstallProgressScreen> {
  final Stopwatch _elapsed = Stopwatch()..start();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant HubInstallProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress?.stage == GameInstallStage.completed) {
      _ticker?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.playerL10n;
    final presentation = HubInstallProgressPresentation.from(
      widget.progress,
      elapsed: _elapsed.elapsed,
    );
    return Material(
      key: const ValueKey<String>('hub-install-progress-screen'),
      color: context.playerColors.scrim.withValues(alpha: .96),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PlayerSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: PlayerProgressCard(
                title: l10n.installingGame,
                stage: _stageLabel(context, widget.progress?.stage),
                value: presentation.fraction,
                progressLabel: '${presentation.percent} %',
                remainingLabel: _remainingLabel(
                  context,
                  presentation.remaining,
                ),
                steps: <PlayerProgressStepData>[
                  for (final step in presentation.milestones)
                    PlayerProgressStepData(
                      key: ValueKey<String>(
                        'hub-install-step-${step.milestone.name}-'
                        '${step.state.name}',
                      ),
                      label: _milestoneLabel(context, step.milestone),
                      state: step.state,
                    ),
                ],
                onCancel: widget.progress?.cancellable == true
                    ? widget.onCancel
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _remainingLabel(BuildContext context, Duration? remaining) {
    final l10n = context.playerL10n;
    if (remaining == null) return l10n.estimatedTimeCalculating;
    final minutes = (remaining.inSeconds / 60).ceil();
    final duration = remaining.inSeconds < 60
        ? l10n.shortSeconds(remaining.inSeconds.clamp(1, 59))
        : l10n.shortMinutes(minutes);
    return l10n.estimatedTimeRemaining(duration);
  }

  String _milestoneLabel(
    BuildContext context,
    HubInstallMilestone milestone,
  ) {
    final l10n = context.playerL10n;
    return switch (milestone) {
      HubInstallMilestone.package => l10n.checkingCompatibility,
      HubInstallMilestone.snapshot => l10n.protectingInstalledVersion,
      HubInstallMilestone.extraction => l10n.secureExtraction,
      HubInstallMilestone.verification => l10n.verifyingFiles,
      HubInstallMilestone.validation => l10n.loadingTrial,
      HubInstallMilestone.activation => l10n.activatingVersion,
      HubInstallMilestone.library => l10n.updatingLibrary,
    };
  }

  String _stageLabel(BuildContext context, GameInstallStage? stage) =>
      switch (stage) {
        GameInstallStage.inspecting => context.playerL10n.loadingPackage,
        GameInstallStage.checkingCompatibility =>
          context.playerL10n.checkingCompatibility,
        GameInstallStage.checkingStorage => context.playerL10n.checkingStorage,
        GameInstallStage.snapshotting =>
          context.playerL10n.protectingInstalledVersion,
        GameInstallStage.extracting => context.playerL10n.secureExtraction,
        GameInstallStage.verifying => context.playerL10n.verifyingFiles,
        GameInstallStage.validatingProject => context.playerL10n.validatingGame,
        GameInstallStage.smokeLoading => context.playerL10n.loadingTrial,
        GameInstallStage.preparingSaves => context.playerL10n.preparingSaves,
        GameInstallStage.promoting => context.playerL10n.activatingVersion,
        GameInstallStage.updatingLibrary => context.playerL10n.updatingLibrary,
        GameInstallStage.completed => context.playerL10n.installationComplete,
        GameInstallStage.cancelled => context.playerL10n.cancelling,
        GameInstallStage.recovering => context.playerL10n.recovering,
        null => context.playerL10n.preparing,
      };

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsed.stop();
    super.dispose();
  }
}
