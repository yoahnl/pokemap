import '../operations/scene_warp_presentation_visual.dart';
import '../models/project_manifest.dart';
import '../models/map_spatial_scene.dart';
import '../models/rail_journey.dart';
import '../models/scene_interactive_command.dart';
import '../read_models/narrative_command_catalog.dart';

enum NarrativeCommandDiagnosticCode {
  duplicateCommandId,
  duplicateWire,
  unsupportedCommand,
  unknownDestinationMap,
  unknownRailJourney,
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
  if (command is SceneWaitForActorRoutesInteractiveCommand) {
    if (project.settings.dimension != ProjectDimension.twoD) {
      return const [NarrativeCommandDiagnostic(
        code: NarrativeCommandDiagnosticCode.unsupportedCommand,
        message: 'L’attente des déplacements nécessite un projet 2D.',
      )];
    }
    if (project.maps.where((map) => map.id == command.mapId).length != 1) {
      return [NarrativeCommandDiagnostic(
        code: NarrativeCommandDiagnosticCode.unknownDestinationMap,
        message: 'La carte ${command.mapId} doit être connue et unique.',
      )];
    }
  }
  if (command is SceneWarpInteractiveCommand && command.presentation != null) {
    try {
      resolveSceneWarpPresentationVisual(command.presentation!, project);
    } catch (_) {
      return const [NarrativeCommandDiagnostic(
        code: NarrativeCommandDiagnosticCode.unsupportedCommand,
        message: 'La transition doit référencer une illustration native statique dans un projet 2D.',
      )];
    }
  }
  final canonical = catalog ?? NarrativeCommandCatalog.canonical();
  final descriptor = canonical.byId(
    NarrativeCommandIds.forInteractiveCommand(command),
  );
  if (descriptor == null || !descriptor.isPublishable) {
    return [
      NarrativeCommandDiagnostic(
        code: NarrativeCommandDiagnosticCode.unsupportedCommand,
        message: 'La commande ${command.kind.name} n’est pas publiable.',
      ),
    ];
  }
  if ((command is SceneWhiteOutInteractiveCommand ||
          command is SceneWaitInteractiveCommand ||
          command is SceneWorldToneInteractiveCommand ||
          command is ScenePlaySoundEffectInteractiveCommand ||
          command is SceneStopSoundEffectsInteractiveCommand ||
          command is ScenePlayMusicEffectInteractiveCommand ||
          command is SceneMusicInteractiveCommand) &&
      project.settings.dimension != ProjectDimension.twoD) {
    return const [
      NarrativeCommandDiagnostic(
        code: NarrativeCommandDiagnosticCode.unsupportedCommand,
        message: 'Les commandes de présentation du monde sont disponibles uniquement dans un projet 2D.',
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
  if (command case SceneRailJourneyInteractiveCommand(:final journeyId)) {
    final journeys =
        project.railJourneyCatalog?.journeys ?? const <RailJourneyDefinition>[];
    if (!journeys.any((journey) => journey.id == journeyId)) {
      return [
        NarrativeCommandDiagnostic(
          code: NarrativeCommandDiagnosticCode.unknownRailJourney,
          message: 'Voyage ferroviaire inconnu : $journeyId.',
        ),
      ];
    }
  }
  return const [];
}
