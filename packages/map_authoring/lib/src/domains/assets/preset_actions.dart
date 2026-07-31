import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../maps/environment_actions.dart';
import '../maps/path_actions.dart';
import '../maps/surface_actions.dart';
import '../maps/terrain_actions.dart';
import 'tileset_actions.dart';

final class VisualPresetDiagnostic {
  const VisualPresetDiagnostic({
    required this.code,
    required this.ownerKind,
    required this.ownerId,
  });

  final String code;
  final String ownerKind;
  final String ownerId;

  Map<String, Object?> toJson() => {
        'code': code,
        'ownerKind': ownerKind,
        'ownerId': ownerId,
      };
}

final class VisualPresetGate {
  VisualPresetGate({
    required Iterable<VisualPresetDiagnostic> diagnostics,
    required Iterable<String> semanticActionIds,
  })  : diagnostics = List.unmodifiable(
          diagnostics.toList()
            ..sort((left, right) {
              final kind = left.ownerKind.compareTo(right.ownerKind);
              return kind != 0 ? kind : left.ownerId.compareTo(right.ownerId);
            }),
        ),
        semanticActionIds =
            List.unmodifiable(semanticActionIds.toList()..sort());

  final List<VisualPresetDiagnostic> diagnostics;
  final List<String> semanticActionIds;

  bool get canConsume => diagnostics.isEmpty;

  Map<String, Object?> toJson() => {
        'canConsume': canConsume,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
        'semanticActionIds': semanticActionIds,
      };
}

final class PresetActions {
  const PresetActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'preset.terrain_upsert',
      'Create or replace one terrain preset',
    ),
    visualLibraryDescriptor(
      'preset.path_upsert',
      'Create or replace one path preset',
    ),
  ]);

  static final List<String> semanticActionIds = List.unmodifiable([
    ...TerrainActions.descriptors.map((descriptor) => descriptor.id),
    ...PathActions.descriptors.map((descriptor) => descriptor.id),
    ...SurfaceActions.descriptors.map((descriptor) => descriptor.id),
    ...EnvironmentActions.descriptors.map((descriptor) => descriptor.id),
  ]..sort());

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'preset.terrain_upsert':
        parameters.allow(const {'preset'});
        final preset = ProjectTerrainPreset.fromJson(
          Map<String, dynamic>.from(parameters.object('preset')),
        );
        final next = upsertTerrain(
          context.snapshot.manifest,
          preset: preset,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'preset.terrain_upsert',
          path: '/terrainPresets/${preset.id}',
          after: preset.toJson(),
        );
      case 'preset.path_upsert':
        parameters.allow(const {'preset'});
        final preset = ProjectPathPreset.fromJson(
          Map<String, dynamic>.from(parameters.object('preset')),
        );
        final next = upsertPath(
          context.snapshot.manifest,
          preset: preset,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'preset.path_upsert',
          path: '/pathPresets/${preset.id}',
          after: preset.toJson(),
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested preset action is unsupported.',
        );
    }
  }

  ProjectManifest upsertTerrain(
    ProjectManifest manifest, {
    required ProjectTerrainPreset preset,
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    final next = manifest.copyWith(
      terrainPresets: [
        for (final current in manifest.terrainPresets)
          if (current.id != preset.id) current,
        preset,
      ]..sort((left, right) => left.id.compareTo(right.id)),
    );
    _requireGate(next, atlases);
    return next;
  }

  ProjectManifest upsertPath(
    ProjectManifest manifest, {
    required ProjectPathPreset preset,
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    final next = manifest.copyWith(
      pathPresets: [
        for (final current in manifest.pathPresets)
          if (current.id != preset.id) current,
        preset,
      ]..sort((left, right) => left.id.compareTo(right.id)),
    );
    _requireGate(next, atlases);
    return next;
  }

  VisualPresetGate validate(
    ProjectManifest manifest, {
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    final diagnostics = <VisualPresetDiagnostic>[];
    void validateFrames(
      String kind,
      String id,
      String ownerTilesetId,
      Iterable<TilesetVisualFrame> frames,
    ) {
      try {
        for (final frame in frames) {
          const TilesetActions().validateFrame(
            frame,
            owningTilesetId: ownerTilesetId,
            atlases: atlases,
          );
        }
      } on VisualLibraryException catch (error) {
        diagnostics.add(
          VisualPresetDiagnostic(
              code: error.code, ownerKind: kind, ownerId: id),
        );
      }
    }

    for (final preset in manifest.terrainPresets) {
      validateFrames(
        'terrainPreset',
        preset.id,
        preset.tilesetId,
        preset.variants.expand((variant) => variant.frames),
      );
    }
    for (final preset in manifest.pathPresets) {
      validateFrames(
        'pathPreset',
        preset.id,
        preset.tilesetId,
        preset.variants.expand((variant) => variant.frames),
      );
    }
    for (final preset in manifest.pathPatternPresets) {
      if (!manifest.pathPresets.any(
        (candidate) => candidate.id == preset.basePathPresetId,
      )) {
        diagnostics.add(
          VisualPresetDiagnostic(
            code: 'preset.base_path_missing',
            ownerKind: 'pathPatternPreset',
            ownerId: preset.id,
          ),
        );
      }
    }
    for (final preset in manifest.environmentPresets) {
      for (final item in preset.palette) {
        if (!manifest.elements.any((element) => element.id == item.elementId)) {
          diagnostics.add(
            VisualPresetDiagnostic(
              code: 'preset.element_missing',
              ownerKind: 'environmentPreset',
              ownerId: preset.id,
            ),
          );
        }
      }
    }
    return VisualPresetGate(
      diagnostics: diagnostics,
      semanticActionIds: semanticActionIds,
    );
  }

  void _requireGate(
    ProjectManifest manifest,
    Map<String, TilesetAtlasSpec> atlases,
  ) {
    final gate = validate(manifest, atlases: atlases);
    if (!gate.canConsume) {
      throw VisualLibraryException(
        'preset.consumption_invalid',
        'The preset cannot be consumed by semantic map actions.',
        details: gate.toJson(),
      );
    }
  }
}
