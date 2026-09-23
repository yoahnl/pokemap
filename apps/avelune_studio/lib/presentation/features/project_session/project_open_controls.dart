import 'package:flutter/material.dart';
import '../../../features/project_session/application/project_session_state.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_path_field.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'project_open_message.dart';

class ProjectOpenControls extends StatelessWidget {
  const ProjectOpenControls({
    super.key,
    required this.path,
    required this.state,
    required this.picking,
    required this.onOpen,
    required this.onBrowse,
    required this.onCancel,
    this.error,
  });
  final TextEditingController path;
  final ProjectSessionState state;
  final bool picking;
  final String? error;
  final VoidCallback onOpen, onBrowse, onCancel;

  @override
  Widget build(BuildContext context) {
    final busy = picking || state.status == ProjectSessionStatus.opening;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) ...[
          StudioNotice(
            state.status == ProjectSessionStatus.opening
                ? 'Lecture du projet…'
                : 'Choisissez un dossier dans la fenêtre de sélection…',
          ),
          StudioButton(
            label: 'Annuler l’ouverture',
            onPressed: onCancel,
            secondary: true,
          ),
        ],
        if (state.status == ProjectSessionStatus.failed)
          StudioNotice(projectOpenMessage(state.problem), isError: true),
        if (error != null) StudioNotice(error!, isError: true),
        ExpansionTile(
          key: const ValueKey('exact-project-path'),
          title: const Text('Utiliser un chemin exact'),
          childrenPadding: const EdgeInsets.all(12),
          children: [
            if (!busy) ...[
              StudioPathField(controller: path, onSubmitted: onOpen),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StudioButton(
                    key: const ValueKey('open-project-path'),
                    label: 'Ouvrir ce chemin',
                    onPressed: onOpen,
                    secondary: true,
                  ),
                  StudioButton(
                    label: 'Parcourir',
                    onPressed: onBrowse,
                    secondary: true,
                  ),
                ],
              ),
            ],
          ],
        ),
        if (state.project != null)
          const StudioNotice('Projet ouvert — lecture seule'),
      ],
    );
  }
}
