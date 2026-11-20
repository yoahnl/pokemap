import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'studio_home_screen.dart';

class ProjectImportPage extends StatelessWidget {
  const ProjectImportPage({
    super.key,
    required this.busy,
    required this.projects,
    required this.destinations,
    this.status,
  });

  final bool busy;
  final StudioHomeProjectAccess projects;
  final Map<String, VoidCallback> destinations;
  final Widget? status;

  @override
  Widget build(BuildContext context) => StudioHomeScreen(
    key: const ValueKey('studio-home'),
    busy: busy,
    onOpen: projects.open,
    recentProjects: projects.recent,
    onRecent: projects.openRecent,
    onRemoveRecent: projects.removeRecent,
    destinations: destinations,
    onMap: (_) {},
    status: status,
    statusAtTop: status != null,
  );
}

Widget? projectHomeStatus(
  BuildContext context, {
  required ProjectSessionState state,
  required bool busy,
  required bool pickerFailed,
  required bool recentsFailed,
  VoidCallback? onRetry,
}) {
  final l10n = context.l10n;
  final problem = state.problem;
  final message = problem == null
      ? pickerFailed
            ? l10n.homePickerFailed
            : null
      : projectOpenProblemMessage(l10n, problem);
  if (message == null && !recentsFailed) return null;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (message != null) StudioNotice(message, isError: true),
      if (recentsFailed) StudioNotice(l10n.homeRecentsFailed, isError: true),
      if (problem == ProjectOpenProblem.recoveryFailed && onRetry != null)
        StudioButton(
          key: const ValueKey('studio-home-retry-open'),
          label: l10n.openProblemRetry,
          icon: Icons.refresh,
          variant: StudioButtonVariant.secondary,
          onPressed: busy ? null : onRetry,
        ),
    ],
  );
}

String projectOpenProblemMessage(
  AppLocalizations l10n,
  ProjectOpenProblem problem,
) => switch (problem) {
  ProjectOpenProblem.invalidPath => l10n.openProblemInvalidPath,
  ProjectOpenProblem.pathNotPreserved => l10n.openProblemPathNotPreserved,
  ProjectOpenProblem.directoryUnavailable =>
    l10n.openProblemDirectoryUnavailable,
  ProjectOpenProblem.manifestMissing => l10n.openProblemManifestMissing,
  ProjectOpenProblem.manifestInvalid => l10n.openProblemManifestInvalid,
  ProjectOpenProblem.accessDenied => l10n.openProblemAccessDenied,
  ProjectOpenProblem.readFailed => l10n.openProblemReadFailed,
  ProjectOpenProblem.recoveryFailed => l10n.openProblemRecoveryFailed,
};
