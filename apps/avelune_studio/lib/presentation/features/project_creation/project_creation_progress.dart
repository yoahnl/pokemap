import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import '../../../features/project_creation/application/project_creation_controller.dart';

class ProjectCreationProgress extends StatelessWidget {
  const ProjectCreationProgress({super.key, required this.controller});
  final ProjectCreationController controller;
  @override
  Widget build(BuildContext context) {
    final state = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.receipt == null
              ? 'Création du projet…'
              : 'Votre projet est créé',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Les étapes correspondent aux opérations réellement effectuées.',
        ),
        const SizedBox(height: 24),
        for (final entry in const {
          ProjectCreationPhase.validating: 'Vérification de la destination',
          ProjectCreationPhase.preparing:
              'Préparation du modèle et des ressources',
          ProjectCreationPhase.writing: 'Écriture du projet',
          ProjectCreationPhase.verifying: 'Validation et relecture du projet',
          ProjectCreationPhase.completed: 'Projet prêt à ouvrir',
        }.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                if (state.phase == entry.key && state.running)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    state.completed.contains(entry.key) ||
                            (entry.key == ProjectCreationPhase.completed &&
                                state.receipt != null)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.value)),
              ],
            ),
          ),
        if (state.receipt != null)
          SelectionArea(child: Text(state.receipt!.projectPath)),
        if (state.running && !state.canCancel)
          const Text(
            'Écriture engagée : attendez sa vérification avant de fermer.',
          ),
        if (state.cancelled && state.running)
          const Text(
            'Annulation demandée. Attente de la fin de la préparation.',
          ),
      ],
    );
  }
}
