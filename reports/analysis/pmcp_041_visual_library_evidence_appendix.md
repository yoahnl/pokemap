# PMCP-041 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/domains/assets/element_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';

final class ElementActions {
  const ElementActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'element.upsert',
      'Create or replace one validated visual element',
    ),
    visualLibraryDescriptor(
      'element.delete',
      'Delete one unreferenced visual element',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'element.upsert':
        parameters.allow(const {'element'});
        final element = ProjectElementEntry.fromJson(
          Map<String, dynamic>.from(parameters.object('element')),
        );
        final next = upsert(
          context.snapshot.manifest,
          element: element,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element.upsert',
          path: '/elements/${element.id}',
          after: element.toJson(),
        );
      case 'element.delete':
        parameters.allow(const {'elementId'});
        final elementId = parameters.string('elementId');
        final next = delete(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          elementId: elementId,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element.delete',
          path: '/elements/$elementId',
          before: {'elementId': elementId},
          referenceImpact: {'references': const <String>[]},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested element action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required ProjectElementEntry element,
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    if (!manifest.elementCategories.any(
      (category) => category.id == element.categoryId,
    )) {
      throw VisualLibraryException(
        'element.category_missing',
        'The element category is unknown.',
        details: {'categoryId': element.categoryId},
      );
    }
    if (element.frames.isEmpty) {
      throw VisualLibraryException(
        'element.frames_required',
        'An element requires at least one visual frame.',
      );
    }
    for (final frame in element.frames) {
      const TilesetActions().validateFrame(
        frame,
        owningTilesetId: element.tilesetId,
        atlases: atlases,
      );
    }
    final elements = [
      for (final existing in manifest.elements)
        if (existing.id != element.id) existing,
      element,
    ]..sort((left, right) => left.id.compareTo(right.id));
    return manifest.copyWith(elements: elements);
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required String elementId,
  }) {
    if (!manifest.elements.any((element) => element.id == elementId)) {
      throw VisualLibraryException(
        'element.unknown',
        'The element identity is unknown.',
        details: {'elementId': elementId},
      );
    }
    final references = <String>{};
    for (final map in maps) {
      for (final placed in map.placedElements) {
        if (placed.elementId == elementId) {
          references.add('map:${map.id}:placedElement:${placed.id}');
        }
      }
    }
    for (final preset in manifest.environmentPresets) {
      if (preset.palette.any((item) => item.elementId == elementId)) {
        references.add('environmentPreset:${preset.id}');
      }
    }
    final ordered = references.toList()..sort();
    if (ordered.isNotEmpty) {
      throw VisualLibraryException(
        'element.references_blocking',
        'The element is still referenced and cannot be deleted safely.',
        details: {'elementId': elementId, 'references': ordered},
      );
    }
    return manifest.copyWith(
      elements: manifest.elements
          .where((element) => element.id != elementId)
          .toList(growable: false),
    );
  }
}
```

## `packages/map_authoring/lib/src/domains/assets/palette_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';

final class PaletteActions {
  const PaletteActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'palette.upsert',
      'Create or replace one validated tileset palette entry',
    ),
    visualLibraryDescriptor(
      'palette.delete',
      'Delete one tileset palette entry',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'palette.upsert':
        parameters.allow(const {'tilesetId', 'entry'});
        final tilesetId = parameters.string('tilesetId');
        final entry = TilesetPaletteEntry.fromJson(
          Map<String, dynamic>.from(parameters.object('entry')),
        );
        final next = upsert(
          context.snapshot.manifest,
          tilesetId: tilesetId,
          entry: entry,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'palette.upsert',
          path: '/tilesets/$tilesetId/paletteEntries/${entry.id}',
          after: entry.toJson(),
        );
      case 'palette.delete':
        parameters.allow(const {'tilesetId', 'entryId'});
        final tilesetId = parameters.string('tilesetId');
        final entryId = parameters.string('entryId');
        final next = delete(
          context.snapshot.manifest,
          tilesetId: tilesetId,
          entryId: entryId,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'palette.delete',
          path: '/tilesets/$tilesetId/paletteEntries/$entryId',
          before: {'entryId': entryId},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested palette action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required String tilesetId,
    required TilesetPaletteEntry entry,
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    if (entry.frames.isEmpty) {
      throw VisualLibraryException(
        'palette.frames_required',
        'A palette entry requires at least one frame.',
      );
    }
    for (final frame in entry.frames) {
      const TilesetActions().validateFrame(
        frame,
        owningTilesetId: tilesetId,
        atlases: atlases,
      );
    }
    final tilesets = [
      for (final tileset in manifest.tilesets)
        if (tileset.id == tilesetId)
          tileset.copyWith(
            paletteEntries: [
              for (final existing in tileset.paletteEntries)
                if (existing.id != entry.id) existing,
              entry,
            ]..sort((left, right) => left.id.compareTo(right.id)),
          )
        else
          tileset,
    ];
    if (!tilesets.any((tileset) => tileset.id == tilesetId)) {
      throw VisualLibraryException(
        'tileset.unknown',
        'The palette owner tileset is unknown.',
      );
    }
    return manifest.copyWith(tilesets: tilesets);
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required String tilesetId,
    required String entryId,
  }) {
    var found = false;
    final tilesets = [
      for (final tileset in manifest.tilesets)
        if (tileset.id == tilesetId)
          tileset.copyWith(
            paletteEntries: tileset.paletteEntries.where((entry) {
              if (entry.id == entryId) found = true;
              return entry.id != entryId;
            }).toList(growable: false),
          )
        else
          tileset,
    ];
    if (!found) {
      throw VisualLibraryException(
        'palette.unknown',
        'The palette entry is unknown.',
        details: {'tilesetId': tilesetId, 'entryId': entryId},
      );
    }
    return manifest.copyWith(tilesets: tilesets);
  }
}
```

## `packages/map_authoring/lib/src/domains/assets/preset_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/assets/tileset_actions.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'asset_store.dart';

const String visualLibraryMetadataKey = 'pokemapAuthoringVisualLibrary';

final class VisualLibraryException implements Exception {
  VisualLibraryException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'VisualLibraryException($code): $message';
}

final class VisualTileProperty {
  const VisualTileProperty({
    required this.tileId,
    this.passable = true,
    this.tags = const [],
  });

  factory VisualTileProperty.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
          (key) => !const {'tileId', 'passable', 'tags'}.contains(key),
        ) ||
        json['tileId'] is! int ||
        json['passable'] is! bool ||
        json['tags'] is! List ||
        (json['tags']! as List).any((tag) => tag is! String)) {
      throw const FormatException('Invalid visual tile property');
    }
    return VisualTileProperty(
      tileId: json['tileId']! as int,
      passable: json['passable']! as bool,
      tags: List<String>.unmodifiable((json['tags']! as List).cast<String>()),
    );
  }

  final int tileId;
  final bool passable;
  final List<String> tags;

  Map<String, Object?> toJson() => {
        'tileId': tileId,
        'passable': passable,
        'tags': tags,
      };
}

/// Pixel/grid facts that the legacy manifest did not persist on a tileset.
///
/// Keeping these facts in a typed `globalProperties` namespace preserves old
/// project readers while making atlas-bound validation and regrid impact honest.
final class TilesetAtlasSpec {
  const TilesetAtlasSpec({
    required this.tilesetId,
    required this.assetId,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.tileWidth,
    required this.tileHeight,
    this.tileProperties = const [],
  });

  factory TilesetAtlasSpec.fromJson(Map<String, dynamic> json) {
    const keys = {
      'tilesetId',
      'assetId',
      'pixelWidth',
      'pixelHeight',
      'tileWidth',
      'tileHeight',
      'tileProperties',
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['tilesetId'] is! String ||
        json['assetId'] is! String ||
        json['pixelWidth'] is! int ||
        json['pixelHeight'] is! int ||
        json['tileWidth'] is! int ||
        json['tileHeight'] is! int ||
        json['tileProperties'] is! List) {
      throw const FormatException('Invalid tileset atlas metadata');
    }
    return TilesetAtlasSpec(
      tilesetId: json['tilesetId']! as String,
      assetId: json['assetId']! as String,
      pixelWidth: json['pixelWidth']! as int,
      pixelHeight: json['pixelHeight']! as int,
      tileWidth: json['tileWidth']! as int,
      tileHeight: json['tileHeight']! as int,
      tileProperties: (json['tileProperties']! as List).map((raw) {
        if (raw is! Map) throw const FormatException();
        return VisualTileProperty.fromJson(Map<String, dynamic>.from(raw));
      }).toList(growable: false),
    )..validate();
  }

  final String tilesetId;
  final String assetId;
  final int pixelWidth;
  final int pixelHeight;
  final int tileWidth;
  final int tileHeight;
  final List<VisualTileProperty> tileProperties;

  int get columns => pixelWidth ~/ tileWidth;
  int get rows => pixelHeight ~/ tileHeight;
  int get tileCount => columns * rows;

  TilesetAtlasSpec validate() {
    if (!_stableId(tilesetId) || !_stableId(assetId)) {
      throw VisualLibraryException(
        'tileset.atlas_identity_invalid',
        'Atlas and asset identities must be stable.',
      );
    }
    if (pixelWidth <= 0 ||
        pixelHeight <= 0 ||
        tileWidth <= 0 ||
        tileHeight <= 0 ||
        pixelWidth % tileWidth != 0 ||
        pixelHeight % tileHeight != 0) {
      throw VisualLibraryException(
        'tileset.grid_invalid',
        'Atlas dimensions must be positive multiples of the tile grid.',
        details: toJson(),
      );
    }
    final ids = <int>{};
    for (final property in tileProperties) {
      if (property.tileId < 0 ||
          property.tileId >= tileCount ||
          !ids.add(property.tileId)) {
        throw VisualLibraryException(
          'tileset.tile_property_invalid',
          'Tile properties must target unique in-bounds tile identities.',
          details: {'tileId': property.tileId, 'tileCount': tileCount},
        );
      }
    }
    return this;
  }

  TilesetAtlasSpec regrid({required int width, required int height}) =>
      TilesetAtlasSpec(
        tilesetId: tilesetId,
        assetId: assetId,
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight,
        tileWidth: width,
        tileHeight: height,
        tileProperties: const [],
      )..validate();

  Map<String, Object?> toJson() => {
        'tilesetId': tilesetId,
        'assetId': assetId,
        'pixelWidth': pixelWidth,
        'pixelHeight': pixelHeight,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'tileProperties': [
          for (final property in tileProperties) property.toJson(),
        ],
      };
}

final class TilesetRegridImpact {
  const TilesetRegridImpact({
    required this.ownerKind,
    required this.ownerId,
    required this.path,
    required this.before,
    required this.after,
  });

  final String ownerKind;
  final String ownerId;
  final String path;
  final TilesetSourceRect before;
  final TilesetSourceRect? after;

  bool get blocking => after == null;

  Map<String, Object?> toJson() => {
        'ownerKind': ownerKind,
        'ownerId': ownerId,
        'path': path,
        'before': before.toJson(),
        if (after != null) 'after': after!.toJson(),
        'blocking': blocking,
      };
}

final class TilesetRegridPreview {
  TilesetRegridPreview({
    required this.before,
    required this.after,
    required Iterable<TilesetRegridImpact> impacts,
  }) : impacts = List.unmodifiable(
          impacts.toList()
            ..sort((left, right) {
              final kind = left.ownerKind.compareTo(right.ownerKind);
              if (kind != 0) return kind;
              final id = left.ownerId.compareTo(right.ownerId);
              return id != 0 ? id : left.path.compareTo(right.path);
            }),
        );

  final TilesetAtlasSpec before;
  final TilesetAtlasSpec after;
  final List<TilesetRegridImpact> impacts;

  bool get canApply => impacts.every((impact) => !impact.blocking);

  Map<String, Object?> toJson() => {
        'before': before.toJson(),
        'after': after.toJson(),
        'canApply': canApply,
        'impacts': [for (final impact in impacts) impact.toJson()],
      };
}

final class TilesetActions {
  const TilesetActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'tileset.upsert',
      'Create or replace a validated tileset and atlas metadata',
    ),
    visualLibraryDescriptor(
      'tileset.delete',
      'Delete one unreferenced tileset',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    final manifest = context.snapshot.manifest;
    switch (context.request.actionId) {
      case 'tileset.upsert':
        parameters.allow(const {'tileset', 'atlas'});
        final tileset = ProjectTilesetEntry.fromJson(
          Map<String, dynamic>.from(parameters.object('tileset')),
        );
        final atlas = TilesetAtlasSpec.fromJson(
          Map<String, dynamic>.from(parameters.object('atlas')),
        );
        if (atlas.tilesetId != tileset.id) {
          throw VisualLibraryException(
            'tileset.atlas_identity_mismatch',
            'Tileset and atlas metadata identities must match.',
          );
        }
        _requireAssetPath(context.snapshot, atlas, tileset.relativePath);
        final next = upsert(manifest, tileset: tileset, atlas: atlas);
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'tileset.upsert',
          path: '/tilesets/${tileset.id}',
          after: {'tileset': tileset.toJson(), 'atlas': atlas.toJson()},
        );
      case 'tileset.delete':
        parameters.allow(const {'tilesetId'});
        final id = parameters.string('tilesetId');
        final next =
            delete(manifest, maps: context.snapshot.maps, tilesetId: id);
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'tileset.delete',
          path: '/tilesets/$id',
          before: {'tilesetId': id},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested tileset action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required ProjectTilesetEntry tileset,
    required TilesetAtlasSpec atlas,
  }) {
    atlas.validate();
    final atlases = readTilesetAtlases(manifest)..[tileset.id] = atlas;
    final tilesets = [
      for (final existing in manifest.tilesets)
        if (existing.id != tileset.id) existing,
      tileset,
    ]..sort((left, right) => left.id.compareTo(right.id));
    final next = manifest.copyWith(
      tilesets: tilesets,
      globalProperties: writeTilesetAtlases(manifest.globalProperties, atlases),
    );
    validateManifestFrames(next, atlases);
    return next;
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required String tilesetId,
  }) {
    if (!manifest.tilesets.any((tileset) => tileset.id == tilesetId)) {
      throw VisualLibraryException(
        'tileset.unknown',
        'The tileset identity is unknown.',
        details: {'tilesetId': tilesetId},
      );
    }
    final references = visualReferencesForTileset(manifest, maps, tilesetId);
    if (references.isNotEmpty) {
      throw VisualLibraryException(
        'tileset.references_blocking',
        'The tileset is still referenced and cannot be deleted safely.',
        details: {'tilesetId': tilesetId, 'references': references},
      );
    }
    final atlases = readTilesetAtlases(manifest)..remove(tilesetId);
    return manifest.copyWith(
      tilesets: manifest.tilesets
          .where((tileset) => tileset.id != tilesetId)
          .toList(growable: false),
      globalProperties: writeTilesetAtlases(manifest.globalProperties, atlases),
    );
  }

  void validateFrame(
    TilesetVisualFrame frame, {
    required String owningTilesetId,
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    final tilesetId =
        frame.tilesetId.isEmpty ? owningTilesetId : frame.tilesetId;
    final atlas = atlases[tilesetId];
    if (atlas == null) {
      throw VisualLibraryException(
        'tileset.atlas_missing',
        'A visual frame targets a tileset without atlas metadata.',
        details: {'tilesetId': tilesetId},
      );
    }
    final source = frame.source;
    if (source.x < 0 ||
        source.y < 0 ||
        source.width <= 0 ||
        source.height <= 0 ||
        source.x + source.width > atlas.columns ||
        source.y + source.height > atlas.rows) {
      throw VisualLibraryException(
        'tileset.source_out_of_bounds',
        'A visual source rectangle leaves the real atlas bounds.',
        details: {
          'tilesetId': tilesetId,
          'source': source.toJson(),
          'columns': atlas.columns,
          'rows': atlas.rows,
        },
      );
    }
    if (frame.durationMs != null && frame.durationMs! <= 0) {
      throw VisualLibraryException(
        'tileset.frame_duration_invalid',
        'Animated frame durations must be positive.',
      );
    }
  }

  TilesetRegridPreview previewRegrid(
    ProjectManifest manifest, {
    required TilesetAtlasSpec current,
    required int tileWidth,
    required int tileHeight,
  }) {
    final after = current.regrid(width: tileWidth, height: tileHeight);
    final impacts = <TilesetRegridImpact>[];
    for (final frame in _visualFramesForTileset(manifest, current.tilesetId)) {
      impacts.add(
        TilesetRegridImpact(
          ownerKind: frame.ownerKind,
          ownerId: frame.ownerId,
          path: frame.path,
          before: frame.frame.source,
          after: _regridSource(frame.frame.source, current, after),
        ),
      );
    }
    return TilesetRegridPreview(
        before: current, after: after, impacts: impacts);
  }
}

AuthoringActionDescriptor visualLibraryDescriptor(
  String id,
  String summary, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.visual_library.mutation.v1',
      riskLevel: risk,
      resourceKinds: const ['project', 'asset'],
      capabilityIds: const ['authoring.visual_library'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft buildVisualManifestDraft(
  ProjectSnapshot snapshot,
  ProjectManifest manifest, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  Map<String, Object?> referenceImpact = const {},
}) {
  try {
    ProjectValidator.validate(manifest);
  } on Object catch (error) {
    throw VisualLibraryException(
      'visual.projected_state_invalid',
      'The visual library mutation would invalidate the project.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: encodeProjectAuthoringDocument(snapshot, manifest),
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: {'operation': operation, 'path': path},
    referenceImpact: referenceImpact,
  );
}

Map<String, TilesetAtlasSpec> readTilesetAtlases(ProjectManifest manifest) {
  final rawLibrary = manifest.globalProperties[visualLibraryMetadataKey];
  if (rawLibrary == null) return {};
  if (rawLibrary is! Map || rawLibrary['tilesets'] is! List) {
    throw VisualLibraryException(
      'visual.metadata_invalid',
      'The visual library metadata is invalid.',
    );
  }
  final result = <String, TilesetAtlasSpec>{};
  for (final raw in rawLibrary['tilesets']! as List) {
    if (raw is! Map) {
      throw VisualLibraryException(
        'visual.metadata_invalid',
        'A tileset atlas metadata entry is invalid.',
      );
    }
    final spec = TilesetAtlasSpec.fromJson(Map<String, dynamic>.from(raw));
    if (result.containsKey(spec.tilesetId)) {
      throw VisualLibraryException(
        'visual.metadata_duplicate',
        'Tileset atlas metadata identities must be unique.',
      );
    }
    result[spec.tilesetId] = spec;
  }
  return result;
}

Map<String, Object?> writeTilesetAtlases(
  Map<String, dynamic> properties,
  Map<String, TilesetAtlasSpec> atlases,
) {
  final result = Map<String, Object?>.from(properties);
  final rawExisting = result[visualLibraryMetadataKey];
  final library = rawExisting is Map
      ? Map<String, Object?>.from(rawExisting)
      : <String, Object?>{};
  library['schemaVersion'] = 1;
  library['tilesets'] = [
    for (final entry
        in (atlases.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key))))
      entry.value.toJson(),
  ];
  result[visualLibraryMetadataKey] = library;
  return result;
}

void validateManifestFrames(
  ProjectManifest manifest,
  Map<String, TilesetAtlasSpec> atlases,
) {
  const actions = TilesetActions();
  for (final tileset in manifest.tilesets) {
    for (final entry in tileset.paletteEntries) {
      for (final frame in entry.frames) {
        actions.validateFrame(
          frame,
          owningTilesetId: tileset.id,
          atlases: atlases,
        );
      }
    }
  }
  for (final element in manifest.elements) {
    for (final frame in element.frames) {
      actions.validateFrame(
        frame,
        owningTilesetId: element.tilesetId,
        atlases: atlases,
      );
    }
  }
  for (final preset in manifest.terrainPresets) {
    for (final variant in preset.variants) {
      for (final frame in variant.frames) {
        actions.validateFrame(
          frame,
          owningTilesetId: preset.tilesetId,
          atlases: atlases,
        );
      }
    }
  }
  for (final preset in manifest.pathPresets) {
    for (final variant in preset.variants) {
      for (final frame in variant.frames) {
        actions.validateFrame(
          frame,
          owningTilesetId: preset.tilesetId,
          atlases: atlases,
        );
      }
    }
  }
}

List<String> visualReferencesForTileset(
  ProjectManifest manifest,
  Iterable<MapData> maps,
  String tilesetId,
) {
  final references = <String>{};
  for (final map in maps) {
    if (map.tilesetId == tilesetId) references.add('map:${map.id}:tileset');
    for (final layer in map.layers) {
      final json = layer.toJson();
      if (_containsExactString(json, tilesetId)) {
        references.add('map:${map.id}:layer:${layer.id}');
      }
    }
  }
  for (final element in manifest.elements) {
    if (element.tilesetId == tilesetId ||
        element.frames.any((frame) => frame.tilesetId == tilesetId)) {
      references.add('element:${element.id}');
    }
  }
  for (final preset in manifest.terrainPresets) {
    if (preset.tilesetId == tilesetId) {
      references.add('terrainPreset:${preset.id}');
    }
  }
  for (final preset in manifest.pathPresets) {
    if (preset.tilesetId == tilesetId) {
      references.add('pathPreset:${preset.id}');
    }
  }
  for (final tileset in manifest.tilesets) {
    if (tileset.id == tilesetId) continue;
    if (tileset.paletteEntries.any(
      (entry) => entry.frames.any((frame) => frame.tilesetId == tilesetId),
    )) {
      references.add('tileset:${tileset.id}:palette');
    }
  }
  return List.unmodifiable(references.toList()..sort());
}

List<_OwnedVisualFrame> _visualFramesForTileset(
  ProjectManifest manifest,
  String tilesetId,
) {
  final frames = <_OwnedVisualFrame>[];
  for (final tileset in manifest.tilesets) {
    for (final entry in tileset.paletteEntries) {
      for (var index = 0; index < entry.frames.length; index++) {
        final frame = entry.frames[index];
        if (_frameTargets(frame, tileset.id, tilesetId)) {
          frames.add(_OwnedVisualFrame(
              'paletteEntry', entry.id, 'frames/$index', frame));
        }
      }
    }
  }
  for (final element in manifest.elements) {
    for (var index = 0; index < element.frames.length; index++) {
      final frame = element.frames[index];
      if (_frameTargets(frame, element.tilesetId, tilesetId)) {
        frames.add(
            _OwnedVisualFrame('element', element.id, 'frames/$index', frame));
      }
    }
  }
  for (final preset in manifest.terrainPresets) {
    for (var variant = 0; variant < preset.variants.length; variant++) {
      for (var index = 0;
          index < preset.variants[variant].frames.length;
          index++) {
        final frame = preset.variants[variant].frames[index];
        if (_frameTargets(frame, preset.tilesetId, tilesetId)) {
          frames.add(_OwnedVisualFrame(
            'terrainPreset',
            preset.id,
            'variants/$variant/frames/$index',
            frame,
          ));
        }
      }
    }
  }
  for (final preset in manifest.pathPresets) {
    for (var variant = 0; variant < preset.variants.length; variant++) {
      for (var index = 0;
          index < preset.variants[variant].frames.length;
          index++) {
        final frame = preset.variants[variant].frames[index];
        if (_frameTargets(frame, preset.tilesetId, tilesetId)) {
          frames.add(_OwnedVisualFrame(
            'pathPreset',
            preset.id,
            'variants/$variant/frames/$index',
            frame,
          ));
        }
      }
    }
  }
  return frames;
}

final class VisualLibraryParameters {
  VisualLibraryParameters(Map<String, Object?> values) : _values = values;

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw VisualLibraryException(
        'visual.parameters_unknown',
        'The request contains unsupported visual library parameters.',
        details: {'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required visual library parameter is invalid.',
        details: {'parameter': key},
      );
    }
    return value;
  }

  Map<String, Object?> object(String key) {
    final value = _values[key];
    if (value is! Map || value.keys.any((candidate) => candidate is! String)) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required visual library object is invalid.',
        details: {'parameter': key},
      );
    }
    return Map<String, Object?>.from(value);
  }
}

void _requireAssetPath(
  ProjectSnapshot snapshot,
  TilesetAtlasSpec atlas,
  String relativePath,
) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) {
    throw VisualLibraryException(
      'tileset.asset_catalog_required',
      'Tileset authoring requires the canonical asset catalog.',
    );
  }
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
    final asset = catalog.require(atlas.assetId);
    if (asset.logicalPath != relativePath ||
        !asset.artifact.mediaType.startsWith('image/')) {
      throw const FormatException();
    }
  } on Object {
    throw VisualLibraryException(
      'tileset.asset_invalid',
      'Tileset metadata must reference a catalogued image at the same path.',
      details: {'assetId': atlas.assetId, 'relativePath': relativePath},
    );
  }
}

TilesetSourceRect? _regridSource(
  TilesetSourceRect source,
  TilesetAtlasSpec before,
  TilesetAtlasSpec after,
) {
  final x = source.x * before.tileWidth;
  final y = source.y * before.tileHeight;
  final width = source.width * before.tileWidth;
  final height = source.height * before.tileHeight;
  if (x % after.tileWidth != 0 ||
      y % after.tileHeight != 0 ||
      width % after.tileWidth != 0 ||
      height % after.tileHeight != 0) {
    return null;
  }
  return TilesetSourceRect(
    x: x ~/ after.tileWidth,
    y: y ~/ after.tileHeight,
    width: width ~/ after.tileWidth,
    height: height ~/ after.tileHeight,
  );
}

bool _frameTargets(TilesetVisualFrame frame, String owner, String target) =>
    (frame.tilesetId.isEmpty ? owner : frame.tilesetId) == target;

bool _containsExactString(Object? value, String expected) {
  if (value is String) return value == expected;
  if (value is List) {
    return value.any((item) => _containsExactString(item, expected));
  }
  if (value is Map) {
    return value.values.any((item) => _containsExactString(item, expected));
  }
  return false;
}

bool _stableId(String value) =>
    RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(value);

final class _OwnedVisualFrame {
  const _OwnedVisualFrame(this.ownerKind, this.ownerId, this.path, this.frame);

  final String ownerKind;
  final String ownerId;
  final String path;
  final TilesetVisualFrame frame;
}
```

## `packages/map_authoring/test/domains/assets/visual_library_contract_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('visual library contracts', () {
    const atlas = TilesetAtlasSpec(
      tilesetId: 'world',
      assetId: 'world-atlas',
      pixelWidth: 64,
      pixelHeight: 48,
      tileWidth: 16,
      tileHeight: 16,
    );

    test('rejects a source rect outside the real atlas bounds', () {
      expect(
        () => const TilesetActions().validateFrame(
          const TilesetVisualFrame(
            source: TilesetSourceRect(x: 3, y: 0, width: 2),
          ),
          owningTilesetId: 'world',
          atlases: const {'world': atlas},
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.source_out_of_bounds',
          ),
        ),
      );
    });

    test('regrid preview reports every affected visual before apply', () {
      final preview = const TilesetActions().previewRegrid(
        _manifest(),
        current: atlas,
        tileWidth: 8,
        tileHeight: 8,
      );

      expect(preview.canApply, isTrue);
      expect(preview.impacts.map((impact) => impact.ownerKind), [
        'element',
        'paletteEntry',
        'pathPreset',
        'terrainPreset',
      ]);
      expect(preview.before.tileWidth, 16);
      expect(preview.after.tileWidth, 8);
    });

    test('element deletion scans every loaded map', () {
      final town = const MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 4, height: 4),
        placedElements: [
          MapPlacedElement(
            id: 'tree-placed',
            layerId: 'objects',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      expect(
        () => const ElementActions().delete(
          _manifest(),
          maps: [town],
          elementId: 'tree',
        ),
        throwsA(
          isA<VisualLibraryException>()
              .having(
                (error) => error.code,
                'code',
                'element.references_blocking',
              )
              .having(
                (error) => error.details['references'],
                'references',
                contains('map:town:placedElement:tree-placed'),
              ),
        ),
      );
    });

    test('preset gate stays compatible with semantic map actions', () {
      final gate = const PresetActions().validate(
        _manifest(),
        atlases: const {'world': atlas},
      );

      expect(gate.diagnostics, isEmpty);
      expect(
        gate.semanticActionIds,
        containsAll([
          'terrain.paint',
          'path.paint',
          'surface.paint',
          'environment.generate_apply',
        ]),
      );
    });

    test('dispatcher exposes canonical visual library mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll({
          'tileset.upsert',
          'tileset.delete',
          'palette.upsert',
          'palette.delete',
          'element.upsert',
          'element.delete',
          'preset.terrain_upsert',
          'preset.path_upsert',
        }),
      );
    });
  });
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Visual fixture',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'world',
          name: 'World',
          relativePath: 'images/world.png',
          paletteEntries: [
            TilesetPaletteEntry(
              id: 'grass-tile',
              name: 'Grass',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'nature', name: 'Nature'),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'world',
          categoryId: 'nature',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 1, y: 0),
            ),
          ],
        ),
      ],
      terrainPresets: const [
        ProjectTerrainPreset(
          id: 'grass',
          name: 'Grass',
          terrainType: TerrainType.grass,
          tilesetId: 'world',
          variants: [
            TerrainPresetVariant(
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      pathPresets: const [
        ProjectPathPreset(
          id: 'road',
          name: 'Road',
          tilesetId: 'world',
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.isolated,
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
    );
```
