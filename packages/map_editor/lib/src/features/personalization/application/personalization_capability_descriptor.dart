import 'personalization_preview_surface_descriptor.dart';

enum PersonalizationControlEffect { project, previewOnly, navigation }

enum PersonalizationPreviewContentSource { demonstration, project }

enum PersonalizationPreviewSurfaceFidelity { playerInterface, editorBackdrop }

final class PersonalizationCapabilityDescriptor {
  PersonalizationCapabilityDescriptor({
    required this.id,
    required this.scene,
    required this.label,
    required this.effect,
    this.projectPath,
    this.runtimeSurface,
    this.testKey,
  }) {
    if (id.trim().isEmpty || label.trim().isEmpty) {
      throw ArgumentError('Capability identity and label must not be blank.');
    }
    if (testKey?.trim().isEmpty ?? false) {
      throw ArgumentError.value(testKey, 'testKey');
    }
    switch (effect) {
      case PersonalizationControlEffect.project:
        if (projectPath?.startsWith('/presentation/') != true ||
            runtimeSurface?.trim().isEmpty != false ||
            testKey == null) {
          throw ArgumentError(
            'Project capabilities require a presentation path, runtime '
            'surface and test key.',
          );
        }
      case PersonalizationControlEffect.previewOnly:
      case PersonalizationControlEffect.navigation:
        if (projectPath != null || runtimeSurface != null || testKey == null) {
          throw ArgumentError(
            'Local capabilities require a test key and cannot claim project '
            'or runtime persistence.',
          );
        }
    }
  }

  final String id;
  final PersonalizationStudioScene scene;
  final String label;
  final PersonalizationControlEffect effect;
  final String? projectPath;
  final String? runtimeSurface;
  final String? testKey;
}
