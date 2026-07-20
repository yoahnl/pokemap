import '../models/project_manifest.dart';
import '../models/scene_interactive_command.dart';
import '../read_models/narrative_command_catalog.dart';

enum NarrativeCommandDiagnosticCode {
  duplicateCommandId,
  duplicateWire,
  unsupportedCommand,
  unknownDestinationMap,
}

final class NarrativeCommandDiagnostic {
  const NarrativeCommandDiagnostic({required this.code, required this.message});

  final NarrativeCommandDiagnosticCode code;
  final String message;
}

List<NarrativeCommandDiagnostic> diagnoseNarrativeCommandCatalog(
  NarrativeCommandCatalog catalog,
) {
  final diagnostics = <NarrativeCommandDiagnostic>[];
  final ids = <String>{};
  final wires = <String>{};
  for (final command in catalog.commands) {
    if (!ids.add(command.id)) {
      diagnostics.add(
        NarrativeCommandDiagnostic(
          code: NarrativeCommandDiagnosticCode.duplicateCommandId,
          message: 'Commande dupliquée : ${command.id}.',
        ),
      );
    }
    if (command.isPublishable && !wires.add(command.wireId)) {
      diagnostics.add(
        NarrativeCommandDiagnostic(
          code: NarrativeCommandDiagnosticCode.duplicateWire,
          message: 'Wire canonique dupliqué : ${command.wireId}.',
        ),
      );
    }
  }
  return diagnostics;
}

List<NarrativeCommandDiagnostic> diagnoseInteractiveCommand({
  required SceneInteractiveCommand command,
  required ProjectManifest project,
  NarrativeCommandCatalog? catalog,
}) {
  final canonical = catalog ?? NarrativeCommandCatalog.canonical();
  final descriptor = canonical.byId(command.kind.name);
  if (descriptor == null || !descriptor.isPublishable) {
    return [
      NarrativeCommandDiagnostic(
        code: NarrativeCommandDiagnosticCode.unsupportedCommand,
        message: 'La commande ${command.kind.name} n’est pas publiable.',
      ),
    ];
  }
  if (command case SceneWarpInteractiveCommand(:final destinationMapId)) {
    if (!project.maps.any((map) => map.id == destinationMapId)) {
      return [
        NarrativeCommandDiagnostic(
          code: NarrativeCommandDiagnosticCode.unknownDestinationMap,
          message: 'Map de destination inconnue : $destinationMapId.',
        ),
      ];
    }
  }
  return const [];
}
