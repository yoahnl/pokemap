import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/shared/widgets/avelune_wordmark.dart';

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
              : 'Le sélecteur de dossier n’a pas pu s’ouvrir. Réessayez.'
        : projectOpenProblemMessage(problem);
    return Scaffold(
      key: const ValueKey('studio-home'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AveluneWordmark(height: 56),
              const SizedBox(height: StudioSpacing.xxl * 2),
              StudioButton(
                key: const ValueKey('studio-home-import'),
                label: 'Importer un projet',
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

String projectOpenProblemMessage(ProjectOpenProblem problem) =>
    switch (problem) {
      ProjectOpenProblem.invalidPath => 'Ce chemin de projet n’est pas valide.',
      ProjectOpenProblem.pathNotPreserved =>
        'Le Studio ne peut pas conserver l’accès à ce dossier.',
      ProjectOpenProblem.directoryUnavailable => 'Ce dossier est introuvable.',
      ProjectOpenProblem.manifestMissing =>
        'Ce dossier ne contient pas de projet Avelune.',
      ProjectOpenProblem.manifestInvalid =>
        'Le fichier du projet est illisible ou incompatible.',
      ProjectOpenProblem.accessDenied =>
        'Le Studio n’a pas l’autorisation d’ouvrir ce dossier.',
      ProjectOpenProblem.readFailed => 'Le projet n’a pas pu être lu.',
    };
