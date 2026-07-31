import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_request.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'path_actions.dart';
import 'semantic_map_action_support.dart';
import 'surface_actions.dart';
import 'terrain_actions.dart';

final class SemanticAutotileRegion {
  const SemanticAutotileRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

final class SemanticAutotileArtifact {
  SemanticAutotileArtifact({
    required this.mapId,
    required this.layerId,
    required this.layerKind,
    required this.seed,
    required this.requestedRegion,
    required this.resolutionRegion,
    required Iterable<Map<String, Object?>> entries,
    required Iterable<Map<String, Object?>> diagnostics,
  })  : entries = List.unmodifiable(
          entries.map((entry) => Map<String, Object?>.unmodifiable(entry)),
        ),
        diagnostics = List.unmodifiable(
          diagnostics.map((entry) => Map<String, Object?>.unmodifiable(entry)),
        ) {
    fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'semantic-autotile.json',
        bytes: utf8.encode(jsonEncode(_payload())),
      ),
    ]);
  }

  final String mapId;
  final String layerId;
  final String layerKind;
  final int seed;
  final SemanticAutotileRegion requestedRegion;
  final SemanticAutotileRegion resolutionRegion;
  final List<Map<String, Object?>> entries;
  final List<Map<String, Object?>> diagnostics;
  late final String fingerprint;

  bool get isValid => diagnostics.isEmpty;

  Map<String, Object?> _payload() => {
        'mapId': mapId,
        'layerId': layerId,
        'layerKind': layerKind,
        'seed': seed,
        'requestedRegion': requestedRegion.toJson(),
        'resolutionRegion': resolutionRegion.toJson(),
        'entryCount': entries.length,
        'entries': entries,
        'diagnosticCount': diagnostics.length,
        'diagnostics': diagnostics,
        'rawTilesetRequired': false,
      };

  Map<String, Object?> toJson() => {
        ..._payload(),
        'fingerprint': fingerprint,
      };
}

/// Renderer-neutral semantic resolution for terrain, path, surface, and native
/// Smart Tile layers. Derived roles and variants are never persisted in maps.
final class SemanticAutotileResolver {
  const SemanticAutotileResolver();

  static const int maxResolutionCells = 4096;

  SemanticAutotileArtifact preview({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    SemanticAutotileRegion? region,
  }) =>
      resolve(
        manifest: manifest,
        map: map,
        layerId: layerId,
        seed: seed,
        preferredPresetId: preferredPresetId,
        region: region,
      );

  SemanticAutotileArtifact rebuildRegion({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    required SemanticAutotileRegion region,
  }) =>
      resolve(
        manifest: manifest,
        map: map,
        layerId: layerId,
        seed: seed,
        preferredPresetId: preferredPresetId,
        region: region,
      );

  List<Map<String, Object?>> validate({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    SemanticAutotileRegion? region,
  }) =>
      resolve(
        manifest: manifest,
        map: map,
        layerId: layerId,
        seed: seed,
        preferredPresetId: preferredPresetId,
        region: region,
      ).diagnostics;

  SemanticAutotileArtifact resolve({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    SemanticAutotileRegion? region,
  }) {
    final requested = region ??
        SemanticAutotileRegion(
          x: 0,
          y: 0,
          width: map.size.width,
          height: map.size.height,
        );
    _requireRegion(requested, map.size);
    final resolution = _expandHalo(requested, map.size);
    if (resolution.width * resolution.height > maxResolutionCells) {
      throw semanticFailure(
        'autotile.region_too_large',
        'The autotile resolution region exceeds the bounded preview limit.',
        details: {
          'cellCount': resolution.width * resolution.height,
          'maxResolutionCells': maxResolutionCells,
        },
        remediation: const ['Request a smaller region and rebuild in chunks.'],
      );
    }
    final layer =
        map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
    if (layer == null) {
      throw semanticFailure(
        'map.layer_missing',
        'The requested autotile layer does not exist.',
        details: {'layerId': layerId},
      );
    }
    final entries = <Map<String, Object?>>[];
    final diagnostics = <Map<String, Object?>>[];
    final diagnosticKeys = <String>{};
    void diagnose(
      String key,
      String code,
      String message,
      List<String> remediation, {
      Map<String, Object?> details = const {},
    }) {
      if (!diagnosticKeys.add(key)) return;
      diagnostics.add({
        'code': code,
        'message': message,
        'details': details,
        'remediation': remediation,
      });
    }

    late final String layerKind;
    switch (layer) {
      case TerrainLayer terrain:
        layerKind = 'terrain';
        ProjectTerrainPreset? preferred;
        if (preferredPresetId != null) {
          preferred = manifest.terrainPresets
              .where((preset) => preset.id == preferredPresetId)
              .firstOrNull;
          if (preferred == null) {
            diagnose(
              'terrain.preferred.$preferredPresetId',
              'terrain.preset_missing',
              'The preferred terrain preset does not exist.',
              const [
                'Create the preset or choose an ID returned by project inspection.',
              ],
              details: {'presetId': preferredPresetId},
            );
          }
        }
        final presets = manifest.terrainPresets.toList()
          ..sort((left, right) => left.id.compareTo(right.id));
        for (var y = resolution.y; y < resolution.bottom; y++) {
          for (var x = resolution.x; x < resolution.right; x++) {
            final terrainType = terrain.terrains[y * map.size.width + x];
            if (terrainType == TerrainType.none) continue;
            final preset = preferred?.terrainType == terrainType
                ? preferred
                : presets
                    .where((candidate) => candidate.terrainType == terrainType)
                    .firstOrNull;
            if (preset == null) {
              diagnose(
                'terrain.type.${terrainType.name}',
                'terrain.preset_missing',
                'No terrain preset resolves this authored terrain type.',
                const [
                  'Create a terrain preset for the reported terrain type.',
                ],
                details: {'terrainType': terrainType.name},
              );
              continue;
            }
            if (preset.variants.isEmpty) {
              diagnose(
                'terrain.variants.${preset.id}',
                'terrain.preset_variants_missing',
                'The terrain preset has no visual variants.',
                const [
                  'Add at least one visual variant to the terrain preset.'
                ],
                details: {'presetId': preset.id},
              );
              continue;
            }
            final chosen = pickTerrainPresetVariantForMapCell(
              variants: preset.variants,
              mapX: x,
              mapY: y,
              phase: seed,
            );
            final variantIndex = preset.variants.indexOf(chosen);
            entries.add({
              'x': x,
              'y': y,
              'presetId': preset.id,
              'terrainType': terrainType.name,
              'role': resolveTerrainPathVariantAt(
                terrains: terrain.terrains,
                mapSize: map.size,
                pos: GridPos(x: x, y: y),
                terrain: terrainType,
              ).name,
              'variantIndex': variantIndex,
              'variantRef': {
                'kind': 'terrain_preset_variant',
                'presetId': preset.id,
                'index': variantIndex,
              },
              'frameCount': chosen.frames.length,
            });
          }
        }
      case PathLayer path:
        layerKind = 'path';
        final preset = manifest.pathPresets
            .where((candidate) => candidate.id == path.presetId)
            .firstOrNull;
        if (preset == null) {
          diagnose(
            'path.preset.${path.presetId}',
            'path.preset_missing',
            'The path layer references a missing preset.',
            const [
              'Assign a valid preset with path.assign_preset before rebuilding.',
            ],
            details: {'presetId': path.presetId},
          );
        } else {
          final patternPreset = manifest.pathPatternPresets
              .where((candidate) => candidate.basePathPresetId == preset.id)
              .firstOrNull;
          for (var y = resolution.y; y < resolution.bottom; y++) {
            for (var x = resolution.x; x < resolution.right; x++) {
              if (!path.cells[y * map.size.width + x]) continue;
              final role = resolvePathVariantAt(
                cells: path.cells,
                mapSize: map.size,
                pos: GridPos(x: x, y: y),
              );
              final mapping = preset.variants
                  .where((candidate) => candidate.variant == role)
                  .firstOrNull;
              final patternResolution = patternPreset == null
                  ? null
                  : resolvePathPatternVisual(
                      pathPatternPreset: patternPreset,
                      basePathPreset: preset,
                      resolvedVariant: role,
                      mapX: x,
                      mapY: y,
                    );
              if (mapping == null && patternResolution == null) {
                diagnose(
                  'path.variant.${preset.id}.${role.name}',
                  'path.variant_missing',
                  'The path preset does not map a resolved autotile role.',
                  const ['Map the reported role in the path preset.'],
                  details: {'presetId': preset.id, 'role': role.name},
                );
              }
              entries.add({
                'x': x,
                'y': y,
                'presetId': preset.id,
                'role': role.name,
                'variantRef': {
                  'kind': 'path_preset_variant',
                  'presetId': preset.id,
                  'role': role.name,
                },
                'frameCount': patternResolution?.frames.length ??
                    mapping?.frames.length ??
                    0,
                if (patternResolution != null)
                  'resolutionKind': patternResolution.kind.name,
              });
            }
          }
        }
      case SurfaceLayer surface:
        layerKind = 'surface';
        final placements = surface.placements.toList()
          ..sort((left, right) {
            final y = left.y.compareTo(right.y);
            return y != 0 ? y : left.x.compareTo(right.x);
          });
        for (final placement in placements) {
          if (!_contains(resolution, placement.x, placement.y)) continue;
          final preset =
              manifest.surfaceCatalog.presetById(placement.surfacePresetId);
          if (preset == null) {
            diagnose(
              'surface.preset.${placement.surfacePresetId}',
              'surface.preset_missing',
              'A surface placement references a missing preset.',
              const [
                'Create the preset or repaint the placement with a valid preset.',
              ],
              details: {'presetId': placement.surfacePresetId},
            );
            continue;
          }
          final role = resolveSurfaceVariantRoleForPlacement(
            placements: surface.placements,
            x: placement.x,
            y: placement.y,
            surfacePresetId: placement.surfacePresetId,
          );
          final animationId = _surfaceAnimationId(preset, role);
          if (animationId == null) {
            diagnose(
              'surface.role.${preset.id}.${role.name}',
              'surface.variant_missing',
              'The surface preset cannot resolve this autotile role.',
              const ['Add the reported role or an isolated fallback.'],
              details: {'presetId': preset.id, 'role': role.name},
            );
          }
          if (animationId != null &&
              manifest.surfaceCatalog.animationById(animationId) == null) {
            diagnose(
              'surface.animation.$animationId',
              'surface.animation_missing',
              'The resolved surface animation does not exist.',
              const ['Create the animation or update the surface preset role.'],
              details: {'presetId': preset.id, 'animationId': animationId},
            );
          }
          entries.add({
            'x': placement.x,
            'y': placement.y,
            'presetId': preset.id,
            'role': role.name,
            if (animationId != null) ...{
              'animationId': animationId,
              'variantRef': {
                'kind': 'surface_animation',
                'animationId': animationId,
              },
            },
          });
        }
      case SmartTileLayer smart:
        layerKind = 'smart_tile';
        final preset = manifest.smartTileCatalog.presets
            .where((candidate) => candidate.id == smart.presetId)
            .firstOrNull;
        if (preset == null) {
          diagnose(
            'smart.preset.${smart.presetId}',
            'autotile.preset_missing',
            'The Smart Tile layer references a missing preset.',
            const ['Assign a published Smart Tile preset to the layer.'],
            details: {'presetId': smart.presetId},
          );
        } else {
          for (var y = resolution.y; y < resolution.bottom; y++) {
            for (var x = resolution.x; x < resolution.right; x++) {
              final neighborhood = smartTileNeighborhoodForLayerCell(
                layer: smart,
                map: map,
                preset: preset,
                x: x,
                y: y,
              );
              final resolved = resolveSmartTile(
                preset: preset,
                materials: manifest.smartTileCatalog.materials,
                neighborhood: neighborhood,
                x: x,
                y: y,
                mapId: map.id,
                layerId: layerId,
                projectSeed: seed,
                layerSeed: smart.layerSeed,
              );
              if (resolved.status ==
                  SmartTileResolutionStatus.noCenterMaterial) {
                continue;
              }
              if (resolved.status != SmartTileResolutionStatus.resolved) {
                diagnose(
                  'smart.resolve.${resolved.status.name}',
                  'autotile.unresolved',
                  resolved.message,
                  const ['Repair the Smart Tile rules or candidate weights.'],
                  details: {'status': resolved.status.name},
                );
              }
              entries.add({
                'x': x,
                'y': y,
                'presetId': preset.id,
                'status': resolved.status.name,
                if (resolved.ruleId != null) 'ruleId': resolved.ruleId,
                if (resolved.candidate != null)
                  'candidateId': resolved.candidate!.id,
                if (resolved.candidate != null)
                  'variantRef': {
                    'kind': 'smart_tile_candidate',
                    'presetId': preset.id,
                    'candidateId': resolved.candidate!.id,
                  },
                if (resolved.deterministicHash != null)
                  'deterministicHash': resolved.deterministicHash,
              });
            }
          }
        }
      case TileLayer() ||
            CollisionLayer() ||
            ObjectLayer() ||
            EnvironmentLayer() ||
            BorderLayer():
        throw semanticFailure(
          'autotile.layer_unsupported',
          'This layer kind has no semantic autotile resolver.',
          details: {'layerId': layerId},
        );
    }
    return SemanticAutotileArtifact(
      mapId: map.id,
      layerId: layerId,
      layerKind: layerKind,
      seed: seed,
      requestedRegion: requested,
      resolutionRegion: resolution,
      entries: entries,
      diagnostics: diagnostics,
    );
  }
}

final class AutotileActions {
  const AutotileActions({
    SemanticAutotileResolver resolver = const SemanticAutotileResolver(),
  }) : _resolver = resolver;

  final SemanticAutotileResolver _resolver;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor(
      'autotile.apply',
      'Apply a semantic edit with a deterministic autotile preview',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    if (planning.request.actionId != 'autotile.apply') {
      throw semanticFailure(
        'map.action_unsupported',
        'The requested autotile mutation action is unsupported.',
        details: {'actionId': planning.request.actionId},
      );
    }
    if (planning.request.actionVersion != 1) {
      throw semanticFailure(
        'map.action_version_unsupported',
        'The requested autotile action version is unsupported.',
      );
    }
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const {
        'mapId',
        'semanticActionId',
        'semanticParameters',
        'previewRegion',
      },
    );
    final mapId = parameters.string('mapId');
    final semanticActionId = parameters.string('semanticActionId');
    final semanticParameters = parameters.object('semanticParameters');
    if (semanticParameters.containsKey('mapId')) {
      throw semanticFailure(
        'map.request_invalid',
        'semanticParameters must not override the outer mapId.',
      );
    }
    final innerRequest = AuthoringRequest(
      requestId: '${planning.request.requestId}_semantic',
      actionId: semanticActionId,
      actionVersion: 1,
      workspaceHandle: planning.request.workspaceHandle,
      parameters: {'mapId': mapId, ...semanticParameters},
      expectedRevision: planning.request.expectedRevision,
      idempotencyKey: planning.request.idempotencyKey,
      dryRun: true,
    );
    final innerContext = AuthoringPlanningContext(
      snapshot: planning.snapshot,
      request: innerRequest,
      planId: planning.planId,
      seed: planning.seed,
    );
    final semanticDraft = switch (semanticActionId.split('.').first) {
      'terrain' => const TerrainActions().build(innerContext),
      'path' => const PathActions().build(innerContext),
      'surface' => const SurfaceActions().build(innerContext),
      _ => throw semanticFailure(
          'autotile.semantic_action_unsupported',
          'Autotile apply accepts only terrain, path, or surface actions.',
          details: {'semanticActionId': semanticActionId},
        ),
    };
    final afterBytes = semanticDraft.changeSet.changes.single.afterBytes;
    if (afterBytes == null) {
      throw StateError('semantic mutation unexpectedly deletes its map');
    }
    late final MapData projected;
    try {
      projected = MapData.fromJson(
        jsonDecode(utf8.decode(afterBytes)) as Map<String, dynamic>,
      );
    } on Object {
      throw semanticFailure(
        'autotile.projected_map_invalid',
        'The semantic action did not produce a readable map preview.',
      );
    }
    final layerId = semanticParameters['layerId'];
    if (layerId is! String || layerId.trim() != layerId || layerId.isEmpty) {
      throw invalidSemanticField(
        'semanticParameters.layerId',
        'a nonblank trimmed string',
      );
    }
    final previewRegion = parameters.contains('previewRegion')
        ? _regionFromJson(parameters.object('previewRegion'))
        : _inferSemanticRegion(semanticParameters, projected.size);
    final preferredPresetId = semanticParameters['presetId'];
    final artifact = _resolver.preview(
      manifest: planning.snapshot.manifest,
      map: projected,
      layerId: layerId,
      seed: planning.seed,
      preferredPresetId: preferredPresetId is String ? preferredPresetId : null,
      region: previewRegion,
    );
    return AuthoringMutationDraft(
      changeSet: semanticDraft.changeSet,
      preview: {
        ...semanticDraft.preview,
        'operation': 'autotile.apply',
        'semanticActionId': semanticActionId,
        'autotile': artifact.toJson(),
      },
      referenceImpact: semanticDraft.referenceImpact,
      artifacts: semanticDraft.artifacts,
    );
  }
}

SemanticAutotileRegion _regionFromJson(Map<String, Object?> value) {
  final unknown = value.keys
      .where((key) => !const {'x', 'y', 'width', 'height'}.contains(key))
      .toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw semanticFailure(
      'map.request_invalid',
      'The autotile preview region contains unsupported fields.',
      details: {'unknownFields': unknown},
    );
  }
  int read(String key) {
    final raw = value[key];
    if (raw is! int) {
      throw invalidSemanticField('previewRegion.$key', 'an integer');
    }
    return raw;
  }

  return SemanticAutotileRegion(
    x: read('x'),
    y: read('y'),
    width: read('width'),
    height: read('height'),
  );
}

SemanticAutotileRegion? _inferSemanticRegion(
  Map<String, Object?> parameters,
  GridSize mapSize,
) {
  final x = parameters['x'];
  final y = parameters['y'];
  if (x is! int || y is! int) return null;
  final rawWidth = parameters['width'];
  final rawHeight = parameters['height'];
  if (rawWidth != null && rawWidth is! int) return null;
  if (rawHeight != null && rawHeight is! int) return null;
  final region = SemanticAutotileRegion(
    x: x,
    y: y,
    width: rawWidth as int? ?? 1,
    height: rawHeight as int? ?? 1,
  );
  _requireRegion(region, mapSize);
  return region;
}

void _requireRegion(SemanticAutotileRegion region, GridSize mapSize) {
  if (region.x < 0 ||
      region.y < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.right > mapSize.width ||
      region.bottom > mapSize.height) {
    throw semanticFailure(
      'autotile.region_out_of_bounds',
      'The autotile region is outside map bounds.',
      details: region.toJson(),
    );
  }
}

SemanticAutotileRegion _expandHalo(
  SemanticAutotileRegion region,
  GridSize mapSize,
) {
  final x = region.x > 0 ? region.x - 1 : 0;
  final y = region.y > 0 ? region.y - 1 : 0;
  final right = region.right < mapSize.width ? region.right + 1 : mapSize.width;
  final bottom =
      region.bottom < mapSize.height ? region.bottom + 1 : mapSize.height;
  return SemanticAutotileRegion(
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
}

bool _contains(SemanticAutotileRegion region, int x, int y) =>
    x >= region.x && y >= region.y && x < region.right && y < region.bottom;

String? _surfaceAnimationId(
  ProjectSurfacePreset preset,
  SurfaceVariantRole role,
) {
  final exact = preset.animationIdForRole(role)?.trim();
  if (exact != null && exact.isNotEmpty) return exact;
  final isolated =
      preset.animationIdForRole(SurfaceVariantRole.isolated)?.trim();
  if (isolated != null && isolated.isNotEmpty) return isolated;
  for (final reference in preset.variantAnimations.refs) {
    final id = reference.animationId.trim();
    if (id.isNotEmpty) return id;
  }
  return null;
}
