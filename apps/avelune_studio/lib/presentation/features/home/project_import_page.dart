import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/widgets/avelune_wordmark.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_language_menu.dart';

class ProjectImportPage extends StatelessWidget {
  const ProjectImportPage({
    super.key,
    required this.state,
    required this.busy,
    required this.pickerError,
    required this.onImport,
  });

  final ProjectSessionState state;
  final bool busy;
  final String? pickerError;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final opening = busy || state.status == ProjectSessionStatus.opening;
    final problem = state.status == ProjectSessionStatus.failed
        ? state.problem
        : null;
    final message = problem == null
        ? pickerError == null
              ? null
              : context.l10n.homePickerFailed
        : projectOpenProblemMessage(context.l10n, problem);
    return Scaffold(
      key: const ValueKey('studio-home'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: StudioLanguageMenu(),
              ),
              const AveluneWordmark(height: 56),
              const SizedBox(height: StudioSpacing.xxl * 2),
              StudioButton(
                key: const ValueKey('studio-home-import'),
                label: context.l10n.homeImportProject,
                icon: Icons.folder_open_outlined,
                loading: opening,
                onPressed: opening ? null : onImport,
              ),
              if (message != null) ...[
                const SizedBox(height: StudioSpacing.xl),
                StudioNotice(message, isError: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
};
