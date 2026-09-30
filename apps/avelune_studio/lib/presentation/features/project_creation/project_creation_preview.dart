import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../features/project_creation/application/project_creation_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';

class ProjectCreationPreview extends StatelessWidget {
  const ProjectCreationPreview({super.key, required this.controller});
  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Aperçu du modèle',
    compact: true,
    children: [
      AspectRatio(
        aspectRatio: 4 / 3,
        child: controller.previewLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : controller.previewBytes == null
            ? const Center(child: Icon(Icons.grid_on_outlined, size: 54))
            : Image.memory(
                Uint8List.fromList(controller.previewBytes!),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
      ),
      const SizedBox(height: 12),
      Text(
        controller.previewError ??
            (controller.previewBytes == null
                ? 'Une base propre, sans carte initiale.'
                : controller.template == ProjectCreationTemplate.clairbois
                ? 'Clairbois · 2 cartes, un dialogue et les ressources du projet. Copie indépendante en 32 × 32.'
                : 'La carte et le personnage réellement inclus dans ce modèle.'),
      ),
      if (controller.previewError != null)
        StudioButton(
          label: 'Recharger l’aperçu',
          secondary: true,
          onPressed: controller.previewLoading ? null : controller.loadPreview,
        ),
    ],
  );
}
