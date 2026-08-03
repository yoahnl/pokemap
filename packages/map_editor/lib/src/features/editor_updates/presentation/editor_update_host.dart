import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/editor_update_providers.dart';
import '../domain/editor_exit_readiness.dart';
import '../domain/editor_update_models.dart';
import 'editor_update_banner.dart';

final class EditorUpdateHost extends ConsumerStatefulWidget {
  const EditorUpdateHost({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<EditorUpdateHost> createState() => _EditorUpdateHostState();
}

final class _EditorUpdateHostState extends ConsumerState<EditorUpdateHost> {
  bool _automaticCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _automaticCheckScheduled) {
        return;
      }
      _automaticCheckScheduled = true;
      unawaited(
        ref.read(editorUpdateControllerProvider).scheduleAutomaticCheck(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(editorUpdateControllerProvider);
    final state =
        ref.watch(editorUpdateStateProvider).valueOrNull ?? controller.state;
    final readiness = ref.watch(editorExitReadinessProvider);
    final banner = _bannerFor(
      context,
      state: state,
      readiness: readiness,
      onDismiss: controller.dismissAvailableBanner,
      onReturnToEditor: controller.returnToEditor,
      onReadNotes: () => unawaited(controller.openReleaseNotes()),
      onInstall: () => unawaited(controller.openNativeUpdateFlow()),
      onRetryCheck: () => unawaited(controller.checkManually()),
      onOpenGitHub: () => unawaited(controller.openReleasesPage()),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: widget.child),
        if (banner != null)
          PositionedDirectional(
            top: 16,
            start: 16,
            end: 16,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: banner,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget? _bannerFor(
  BuildContext context, {
  required EditorUpdateState state,
  required EditorExitReadiness readiness,
  required VoidCallback onDismiss,
  required VoidCallback onReturnToEditor,
  required VoidCallback onReadNotes,
  required VoidCallback onInstall,
  required VoidCallback onRetryCheck,
  required VoidCallback onOpenGitHub,
}) {
  final l10n = context.pokeMapL10n;
  switch (state.phase) {
    case EditorUpdatePhase.idle:
      return null;
    case EditorUpdatePhase.checking:
      if (!state.userInitiated) return null;
      return PokeMapActionBanner(
        title: l10n.editorUpdateCheck,
        message: l10n.editorUpdateChecking,
        tone: PokeMapTone.info,
        actions: [
          PokeMapActionBannerAction(
            label: l10n.editorUpdateChecking,
            onPressed: null,
            isLoading: true,
          ),
        ],
      );
    case EditorUpdatePhase.upToDate:
      return PokeMapActionBanner(
        title: l10n.editorUpdateUpToDate,
        message: l10n.editorUpdateUpToDateBody,
        tone: PokeMapTone.success,
        dismissLabel: l10n.editorUpdateDismiss,
        onDismiss: onDismiss,
      );
    case EditorUpdatePhase.available:
      final release = state.availableRelease;
      if (release == null) return null;
      return EditorUpdateBanner(
        versionLabel: release.version.toString(),
        onReadNotes: onReadNotes,
        onUpdate: onInstall,
        onDismiss: onDismiss,
      );
    case EditorUpdatePhase.handingOff:
    case EditorUpdatePhase.installing:
      return PokeMapActionBanner(
        title: l10n.editorUpdateInstall,
        message: l10n.editorUpdateInstalling,
        tone: PokeMapTone.info,
      );
    case EditorUpdatePhase.restarting:
      return PokeMapActionBanner(
        title: l10n.editorUpdateInstall,
        message: l10n.editorUpdateRestarting,
        tone: PokeMapTone.info,
      );
    case EditorUpdatePhase.blockedByUnsavedWork:
      final labels = <String>{
        for (final blocker in state.exitBlockers)
          _blockerLabel(context, blocker.kind),
      }.toList(growable: false);
      return PokeMapActionBanner(
        title: l10n.editorUpdateUnsavedTitle,
        message: l10n.editorUpdateUnsavedBody,
        tone: PokeMapTone.warning,
        details: _EditorUpdateBlockerList(labels: labels),
        actions: [
          PokeMapActionBannerAction(
            label: l10n.editorUpdateBackToEditor,
            onPressed: onReturnToEditor,
            variant: PokeMapButtonVariant.secondary,
          ),
          PokeMapActionBannerAction(
            label: l10n.editorUpdateRetryRestart,
            onPressed: readiness.canExit ? onInstall : null,
          ),
        ],
      );
    case EditorUpdatePhase.failed:
      return PokeMapActionBanner(
        title: l10n.editorUpdateManualCheckFailedTitle,
        message: l10n.editorUpdateManualCheckFailed,
        tone: PokeMapTone.danger,
        dismissLabel: l10n.editorUpdateDismiss,
        onDismiss: onDismiss,
        actions: [
          PokeMapActionBannerAction(
            label: l10n.editorUpdateOpenGitHub,
            onPressed: onOpenGitHub,
            variant: PokeMapButtonVariant.secondary,
          ),
          PokeMapActionBannerAction(
            label: l10n.editorUpdateRetry,
            onPressed: onRetryCheck,
          ),
        ],
      );
    case EditorUpdatePhase.unsupported:
      return PokeMapActionBanner(
        title: l10n.editorUpdateUnsupportedTitle,
        message: l10n.editorUpdateUnsupported,
        tone: PokeMapTone.warning,
        dismissLabel: l10n.editorUpdateDismiss,
        onDismiss: onDismiss,
        actions: [
          PokeMapActionBannerAction(
            label: l10n.editorUpdateOpenGitHub,
            onPressed: onOpenGitHub,
            variant: PokeMapButtonVariant.secondary,
          ),
        ],
      );
  }
}

class _EditorUpdateBlockerList extends StatelessWidget {
  const _EditorUpdateBlockerList({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _blockerLabel(BuildContext context, EditorExitBlockerKind kind) {
  final l10n = context.pokeMapL10n;
  return switch (kind) {
    EditorExitBlockerKind.map => l10n.editorUpdateBlockerMap,
    EditorExitBlockerKind.projectManifest =>
      l10n.editorUpdateBlockerProjectManifest,
    EditorExitBlockerKind.narrative => l10n.editorUpdateBlockerNarrative,
    EditorExitBlockerKind.personalization =>
      l10n.editorUpdateBlockerPersonalization,
    EditorExitBlockerKind.borderPreview =>
      l10n.editorUpdateBlockerBorderPreview,
    EditorExitBlockerKind.borderStudio => l10n.editorUpdateBlockerBorderStudio,
    EditorExitBlockerKind.pathStudio => l10n.editorUpdateBlockerPathStudio,
    EditorExitBlockerKind.stepStudio => l10n.editorUpdateBlockerStepStudio,
    EditorExitBlockerKind.environmentStudio =>
      l10n.editorUpdateBlockerEnvironmentStudio,
    EditorExitBlockerKind.dialogueStudio =>
      l10n.editorUpdateBlockerDialogueStudio,
    EditorExitBlockerKind.globalStoryStudio =>
      l10n.editorUpdateBlockerGlobalStoryStudio,
    EditorExitBlockerKind.eventBuilderV2 =>
      l10n.editorUpdateBlockerEventBuilderV2,
    EditorExitBlockerKind.pendingTemplate =>
      l10n.editorUpdateBlockerPendingTemplate,
    EditorExitBlockerKind.saveInProgress =>
      l10n.editorUpdateBlockerSaveInProgress,
    EditorExitBlockerKind.unknown => l10n.editorUpdateBlockerUnknown,
  };
}
