import 'personalization_preview_surface_descriptor.dart';

enum PersonalizationControlEffect { project, previewOnly, navigation }

enum PersonalizationPreviewContentSource { demonstration, project }

enum PersonalizationPreviewSurfaceFidelity { playerInterface, editorBackdrop }

enum PersonalizationBattlePreviewState { commands, moves, target, message }

final class PersonalizationCapabilityDescriptor {
  PersonalizationCapabilityDescriptor({
    required this.id,
    required this.scene,
    required this.label,
    required this.effect,
    this.projectPath,
    this.additionalProjectPaths = const <String>{},
    this.runtimeSurface,
    this.testKey,
    this.additionalTestKeys = const <String>{},
  }) {
    if (id.trim().isEmpty || label.trim().isEmpty) {
      throw ArgumentError('Capability identity and label must not be blank.');
    }
    if (testKey?.trim().isEmpty ?? false) {
      throw ArgumentError.value(testKey, 'testKey');
    }
    if (additionalTestKeys.any((key) => key.trim().isEmpty)) {
      throw ArgumentError.value(additionalTestKeys, 'additionalTestKeys');
    }
    switch (effect) {
      case PersonalizationControlEffect.project:
        if (projectPath?.startsWith('/presentation/') != true ||
            additionalProjectPaths.any(
              (path) => !path.startsWith('/presentation/'),
            ) ||
            runtimeSurface?.trim().isEmpty != false ||
            testKey == null) {
          throw ArgumentError(
            'Project capabilities require a presentation path, runtime '
            'surface and test key.',
          );
        }
      case PersonalizationControlEffect.previewOnly:
      case PersonalizationControlEffect.navigation:
        if (projectPath != null ||
            additionalProjectPaths.isNotEmpty ||
            runtimeSurface != null ||
            testKey == null) {
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
  final Set<String> additionalProjectPaths;
  final String? runtimeSurface;
  final String? testKey;
  final Set<String> additionalTestKeys;

  Set<String> get testKeys => <String>{?testKey, ...additionalTestKeys};

  Set<String> get projectPaths => <String>{
    ?projectPath,
    ...additionalProjectPaths,
  };
}
