import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class EnvironmentPresetActions {
  const EnvironmentPresetActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'environment.preset.upsert',
      'Create or replace one validated Environment preset',
      resourceKinds: const ['project', 'preset', 'element'],
    ),
    visualLibraryDescriptor(
      'environment.preset.delete',
      'Remove an unused Environment preset while preserving its palette',
      risk: AuthoringRiskLevel.high,
      resourceKinds: const ['project', 'preset', 'map'],
      inputSchema: const {
        'type': 'object',
        'additionalProperties': false,
        'required': ['presetId'],
        'properties': {
          'presetId': {'type': 'string', 'minLength': 1}
        },
      },
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'environment.preset.upsert':
        parameters.allow(const {'preset'});
        final preset = decodeEnvironmentPreset(parameters.object('preset'));
        final next = upsertProjectEnvironmentPreset(
          context.snapshot.manifest,
          preset,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'environment.preset.upsert',
          path: '/environmentPresets/${preset.id}',
          after: encodeEnvironmentPreset(preset),
        );
      case 'environment.preset.delete':
        parameters.allow(const {'presetId'});
        final id = parameters.string('presetId');
        final snapshot = context.snapshot;
        final preset = findProjectEnvironmentPresetById(snapshot.manifest, id);
        if (preset == null) {
          throw VisualLibraryException('environment.preset_missing',
              'The requested Environment preset does not exist.');
        }
        final mapIds = snapshot.manifest.maps.map((map) => map.id).toSet();
        final loadedIds = snapshot.maps.map((map) => map.id).toSet();
        if (snapshot.loadDiagnostics.any((diagnostic) => diagnostic.blocking) ||
            snapshot.maps.length != mapIds.length ||
            loadedIds.length != mapIds.length ||
            !loadedIds.containsAll(mapIds)) {
          throw VisualLibraryException('environment.inventory_incomplete',
              'All project maps must be readable before removing an Environment preset.');
        }
        final usages = [
          for (final map in snapshot.maps)
            for (final layer in map.layers.whereType<EnvironmentLayer>())
              for (final area in layer.content.areas)
                if (area.presetId == id)
                  {
                    'mapId': map.id,
                    'mapName': map.name,
                    'layerId': layer.id,
                    'areaId': area.id,
                    'areaName': area.name,
                  }
        ];
        if (usages.isNotEmpty) {
          throw VisualLibraryException('environment.preset_in_use',
              'This Environment preset is used by a map area.',
              details: {'presetId': id, 'usages': usages});
        }
        return buildVisualManifestDraft(
          snapshot,
          removeProjectEnvironmentPresetById(snapshot.manifest, id),
          operation: 'environment.preset.delete',
          path: '/environmentPresets/$id',
          before: encodeEnvironmentPreset(preset),
          referenceImpact: const {'paletteElementsPreserved': true},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested Environment preset action is unsupported.',
        );
    }
  }
}
