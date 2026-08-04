import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../maps/semantic_map_action_support.dart';
import 'asset_store.dart';
import 'tiled_tileset_import_projection.dart';
import 'tileset_actions.dart';

/// Public regular-atlas Tiled import boundary.
///
/// The TSX and staged image are inputs only. The resulting project owns a
/// canonical asset, regular tileset source, and native Smart Tile catalog.
final class TiledTilesetImportActions {
  const TiledTilesetImportActions({required this.artifactStore});

  final ArtifactStore artifactStore;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      visualLibraryDescriptor(
        'tileset.tiled.import',
        'Import one regular Tiled tileset as canonical PokeMap resources',
        resourceKinds: const <String>[
          'project',
          'asset',
          'tileset',
          'smartTileAtlas',
          'smartTileMaterial',
          'smartTileAnimation',
          'smartTilePreset',
        ],
      ),
    ],
  );

  Future<AuthoringMutationDraft> build(
    AuthoringPlanningContext context,
  ) async {
    final parameters = _TiledTilesetImportParameters(
      context.request.parameters,
    )..allow(const <String>{
        'artifactHandle',
        'assetId',
        'logicalPath',
        'tilesetId',
        'displayName',
        'importId',
        'tsx',
        'selections',
        'tags',
        'usages',
      });
    final artifactHandle = parameters.string('artifactHandle');
    final artifact = artifactStore.inspect(artifactHandle);
    if (artifact == null) {
      throw const ArtifactStoreException(
        'artifact.unknown',
        'The artifact handle is unknown or has expired.',
      );
    }
    if (!artifact.mediaType.startsWith('image/')) {
      throw const ArtifactStoreException(
        'artifact.media_type_invalid',
        'The Tiled tileset artifact must be a raster image.',
      );
    }
    final imageBytes = await artifactStore.read(artifact.handle);

    final document = _parseTsx(parameters.text('tsx'));
    final tilesetId = parameters.string('tilesetId');
    final selections = _selections(parameters.list('selections'));
    final bundle = _compileWang(
      document,
      importId: parameters.string('importId'),
      tilesetId: tilesetId,
      selections: selections,
    );
    final asset = AssetRecord(
      id: parameters.string('assetId'),
      logicalPath: parameters.string('logicalPath'),
      artifact: artifact,
      tags: parameters.strings('tags'),
      usages: parameters.strings('usages'),
    );
    final tileset = ProjectTilesetEntry(
      id: tilesetId,
      name: parameters.string('displayName'),
      relativePath: asset.logicalPath,
      source: ProjectRegularAtlasTilesetSource(
        assetId: asset.id,
        pixelWidth: document.imageWidth,
        pixelHeight: document.imageHeight,
        tileWidth: document.tileWidth,
        tileHeight: document.tileHeight,
      ),
    );
    return const TiledTilesetImportProjector().project(
      snapshot: context.snapshot,
      asset: asset,
      imageBytes: imageBytes,
      tileset: tileset,
      wangBundle: bundle,
      importId: parameters.string('importId'),
    );
  }
}

TiledWangTilesetDocument _parseTsx(String source) {
  try {
    return parseTiledWangTileset(source);
  } on TiledTilesetImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

TiledWangImportBundle _compileWang(
  TiledWangTilesetDocument document, {
  required String importId,
  required String tilesetId,
  required List<TiledWangSetSelection> selections,
}) {
  try {
    return compileTiledWangImport(
      document: document,
      importId: importId,
      tilesetId: tilesetId,
      selections: selections,
    );
  } on TiledTilesetImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

List<TiledWangSetSelection> _selections(List<Object?> rawSelections) {
  final selections = <TiledWangSetSelection>[];
  for (var index = 0; index < rawSelections.length; index += 1) {
    final raw = rawSelections[index];
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw semanticFailure(
        'smart_tile.tiled_wang.selection_invalid',
        'Every Wang Set selection must be a JSON object.',
        details: <String, Object?>{'selectionIndex': index},
      );
    }
    final selection = _TiledTilesetImportParameters(
      Map<String, Object?>.from(raw),
    )..allow(const <String>{'wangSetIndex', 'usage'});
    final usage = switch (selection.string('usage')) {
      'terrain' => SmartTileUsage.terrain,
      'path' => SmartTileUsage.path,
      'forest_surface' => SmartTileUsage.forestSurface,
      final unsupported => throw semanticFailure(
          'smart_tile.tiled_wang.usage_invalid',
          'The selected Wang Set usage is unsupported.',
          details: <String, Object?>{
            'selectionIndex': index,
            'usage': unsupported,
          },
        ),
    };
    selections.add(
      TiledWangSetSelection(
        wangSetIndex: selection.integer('wangSetIndex'),
        usage: usage,
      ),
    );
  }
  return List<TiledWangSetSelection>.unmodifiable(selections);
}

final class _TiledTilesetImportParameters {
  _TiledTilesetImportParameters(Map<String, Object?> values)
      : _values = Map<String, Object?>.unmodifiable(values);

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw VisualLibraryException(
        'visual.parameter_unknown',
        'The Tiled tileset import contains unsupported parameters.',
        details: <String, Object?>{'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import parameter is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  String text(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import text parameter is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  int integer(String key) {
    final value = _values[key];
    if (value is! int) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import integer is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  List<Object?> list(String key) {
    final value = _values[key];
    if (value is! List) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A required Tiled tileset import list is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return List<Object?>.unmodifiable(value);
  }

  List<String> strings(String key) {
    final value = _values[key];
    if (value == null) return const <String>[];
    if (value is! List ||
        value.any(
          (item) =>
              item is! String || item.trim().isEmpty || item != item.trim(),
        )) {
      throw VisualLibraryException(
        'visual.parameter_invalid',
        'A Tiled tileset import string list is invalid.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}
