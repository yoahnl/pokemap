import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class EnvironmentPresetActions {
  const EnvironmentPresetActions();

  static const maximumPresetCount = 50;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'environment.preset.upsert',
      'Create or replace one validated Environment preset',
      resourceKinds: const [
        'project',
        'preset',
        'element',
        'model3d',
        'environmentPreset'
      ],
    ),
    visualLibraryDescriptor(
      'environment.preset.upsert_batch',
      'Atomically create or replace up to 50 validated Environment presets',
      resourceKinds: const [
        'project',
        'preset',
        'element',
        'model3d',
        'environmentPreset'
      ],
      inputSchema: const {
        'type': 'object',
        'additionalProperties': false,
        'required': ['presets'],
        'properties': {
          'presets': {
            'type': 'array',
            'minItems': 1,
            'maxItems': maximumPresetCount,
            'items': {'type': 'object'},
          },
        },
      },
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
      case 'environment.preset.upsert_batch':
        parameters.allow(const {'presets'});
        final values = context.request.parameters['presets'];
        if (values is! List ||
            values.isEmpty ||
            values.length > maximumPresetCount) {
          throw VisualLibraryException('environment.preset_batch_invalid',
              'An Environment preset batch needs between 1 and 50 presets.');
        }
        final presets = <EnvironmentPreset>[];
        final identities = <String>{};
        var projected = context.snapshot.manifest;
        for (final value in values) {
          if (value is! Map || value.keys.any((key) => key is! String)) {
            throw VisualLibraryException('environment.preset_batch_invalid',
                'Every Environment preset must be an object.');
          }
          final preset =
              decodeEnvironmentPreset(Map<String, Object?>.from(value));
          if (!identities.add(preset.id)) {
            throw VisualLibraryException('environment.preset_batch_duplicate',
                'Each Environment preset identity can occur only once in a batch.');
          }
          projected = upsertProjectEnvironmentPreset(projected, preset);
          final errors = diagnoseProjectEnvironmentPresets(projected)
              .diagnostics
              .where((diagnostic) =>
                  diagnostic.presetId == preset.id &&
                  diagnostic.severity ==
                      EnvironmentPresetDiagnosticSeverity.error)
              .toList();
          if (errors.isNotEmpty) {
            throw VisualLibraryException('environment.palette_invalid',
                'The Environment palette must reference existing visual resources.',
                details: {
                  'presetId': preset.id,
                  'diagnostics': [for (final error in errors) error.kind.name]
                });
          }
          presets.add(preset);
        }
        return buildVisualManifestDraft(context.snapshot, projected,
            operation: 'environment.preset.upsert_batch',
            path: '/environmentPresets',
            before: [
              for (final preset in context.snapshot.manifest.environmentPresets)
                if (identities.contains(preset.id))
                  encodeEnvironmentPreset(preset)
            ],
            after: [
              for (final preset in presets) encodeEnvironmentPreset(preset)
            ]);
      case 'environment.preset.upsert':
        parameters.allow(const {'preset'});
        final preset = decodeEnvironmentPreset(parameters.object('preset'));
        final next = upsertProjectEnvironmentPreset(
          context.snapshot.manifest,
          preset,
        );
        final errors = diagnoseProjectEnvironmentPresets(next)
            .diagnostics
            .where((diagnostic) =>
                diagnostic.presetId == preset.id &&
                diagnostic.severity ==
                    EnvironmentPresetDiagnosticSeverity.error)
            .toList();
        if (errors.isNotEmpty) {
          throw VisualLibraryException('environment.palette_invalid',
              'The Environment palette must reference existing visual resources.',
              details: {
                'presetId': preset.id,
                'diagnostics': [for (final error in errors) error.kind.name]
              });
        }
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
