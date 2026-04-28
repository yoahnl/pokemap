import 'package:flutter/cupertino.dart';

/// Layout principal du Surface Studio V1.1.
///
/// Le shell sépare volontairement les quatre zones du workflow au lieu
/// d'empiler tous les formulaires dans une seule colonne : l'utilisateur doit
/// lire l'écran comme un assistant atlas -> grille -> animations -> surfaces.
class SurfaceStudioWorkflowLayout extends StatelessWidget {
  const SurfaceStudioWorkflowLayout({
    super.key,
    required this.assistant,
    required this.atlasWorkspace,
    required this.detectedAnimations,
    required this.paintableSurfaces,
  });

  final Widget assistant;
  final Widget atlasWorkspace;
  final Widget detectedAnimations;
  final Widget paintableSurfaces;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1280) {
          return Row(
            key: const ValueKey('surface_studio_workflow_desktop_grid'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                key: const ValueKey('surface_studio_workflow_assistant_lane'),
                width: 250,
                child: assistant,
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 46,
                child: KeyedSubtree(
                  key: const ValueKey('surface_studio_workflow_atlas_lane'),
                  child: atlasWorkspace,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                key: const ValueKey('surface_studio_workflow_animations_lane'),
                width: 320,
                child: detectedAnimations,
              ),
              const SizedBox(width: 14),
              SizedBox(
                key: const ValueKey('surface_studio_workflow_surfaces_lane'),
                width: 330,
                child: paintableSurfaces,
              ),
            ],
          );
        }

        if (c.maxWidth >= 900) {
          return Row(
            key: const ValueKey('surface_studio_workflow_tablet_grid'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    atlasWorkspace,
                    const SizedBox(height: 12),
                    detectedAnimations,
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    assistant,
                    const SizedBox(height: 12),
                    paintableSurfaces,
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          key: const ValueKey('surface_studio_workflow_stacked'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            assistant,
            const SizedBox(height: 12),
            atlasWorkspace,
            const SizedBox(height: 12),
            detectedAnimations,
            const SizedBox(height: 12),
            paintableSurfaces,
          ],
        );
      },
    );
  }
}
