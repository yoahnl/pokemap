// Conversion pure d'un tileset TSX anime vers les modeles Surface PokeMap.
//
// Cette brique ne cree pas de preset, ne devine aucun role Surface, ne touche
// pas au manifest et ne lit/ecrit aucun fichier.

import 'package:map_core/map_core.dart';

import 'tiled_tsx_animated_tileset_parser.dart';

enum TiledTsxSurfaceAnimationImportDiagnosticSeverity {
  warning,
  error,
}

final class TiledTsxSurfaceAnimationImportDiagnostic {
  const TiledTsxSurfaceAnimationImportDiagnostic({
    required this.severity,
    required this.message,
    this.baseTileId,
    this.frameTileId,
  });

  final TiledTsxSurfaceAnimationImportDiagnosticSeverity severity;
  final String message;
  final int? baseTileId;
  final int? frameTileId;
}

final class TiledTsxSurfaceAnimationImportOptions {
  const TiledTsxSurfaceAnimationImportOptions({
    required this.atlasId,
    required this.tilesetId,
    required this.animationIdPrefix,
    this.categoryId,
    this.sortOrderBase = 0,
  });

  final String atlasId;
  final String tilesetId;
  final String animationIdPrefix;
  final String? categoryId;
  final int sortOrderBase;
}

final class TiledTsxSurfaceAnimationImportResult {
  const TiledTsxSurfaceAnimationImportResult({
    required this.atlas,
    required this.animations,
    required this.diagnostics,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final List<TiledTsxSurfaceAnimationImportDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            TiledTsxSurfaceAnimationImportDiagnosticSeverity.warning,
      );

  ProjectSurfaceAnimation? animationById(String id) {
    for (final animation in animations) {
      if (animation.id == id) {
        return animation;
      }
    }
    return null;
  }
}

TiledTsxSurfaceAnimationImportResult importTiledTsxSurfaceAnimationsFromXml({
  required String xml,
  required TiledTsxSurfaceAnimationImportOptions options,
}) {
  return importTiledTsxSurfaceAnimations(
    audit: parseTiledTsxAnimatedTileset(xml),
    options: options,
  );
}

TiledTsxSurfaceAnimationImportResult importTiledTsxSurfaceAnimations({
  required TiledTsxTilesetAudit audit,
  required TiledTsxSurfaceAnimationImportOptions options,
}) {
  final diagnostics = <TiledTsxSurfaceAnimationImportDiagnostic>[
    for (final diagnostic in audit.diagnostics)
      TiledTsxSurfaceAnimationImportDiagnostic(
        severity: diagnostic.severity == TiledTsxDiagnosticSeverity.error
            ? TiledTsxSurfaceAnimationImportDiagnosticSeverity.error
            : TiledTsxSurfaceAnimationImportDiagnosticSeverity.warning,
        message: 'TSX parser: ${diagnostic.message}',
      ),
  ];

  final atlasId = options.atlasId.trim();
  final tilesetId = options.tilesetId.trim();
  final animationIdPrefixSlug = _slugForIdSegment(options.animationIdPrefix);
  _validateOptions(
    options: options,
    animationIdPrefixSlug: animationIdPrefixSlug,
    diagnostics: diagnostics,
  );

  final grid = _validatedGridSize(
    summary: audit.summary,
    diagnostics: diagnostics,
  );
  _validateAnimations(
    audit: audit,
    animationIdPrefixSlug: animationIdPrefixSlug,
    gridSize: grid,
    diagnostics: diagnostics,
  );

  if (_hasImportErrors(diagnostics)) {
    return TiledTsxSurfaceAnimationImportResult(
      atlas: null,
      animations: const [],
      diagnostics: List<TiledTsxSurfaceAnimationImportDiagnostic>.unmodifiable(
        diagnostics,
      ),
    );
  }

  final atlas = ProjectSurfaceAtlas(
    id: atlasId,
    name: audit.summary.name,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(
        width: audit.summary.tileWidth,
        height: audit.summary.tileHeight,
      ),
      gridSize: SurfaceAtlasGridSize(
        columns: grid.columns,
        rows: grid.rows,
      ),
      layout: SurfaceAtlasLayout.grid,
    ),
    categoryId: options.categoryId,
    sortOrder: options.sortOrderBase,
  );

  final animations = <ProjectSurfaceAnimation>[];
  for (var i = 0; i < audit.animations.length; i++) {
    final animation = audit.animations[i];
    animations.add(
      _convertAnimation(
        animation: animation,
        summary: audit.summary,
        atlasId: atlasId,
        animationIdPrefixSlug: animationIdPrefixSlug,
        displayNamePrefix: audit.summary.name,
        categoryId: options.categoryId,
        sortOrder: options.sortOrderBase + i,
      ),
    );
  }

  return TiledTsxSurfaceAnimationImportResult(
    atlas: atlas,
    animations: List<ProjectSurfaceAnimation>.unmodifiable(animations),
    diagnostics: List<TiledTsxSurfaceAnimationImportDiagnostic>.unmodifiable(
      diagnostics,
    ),
  );
}

ProjectSurfaceAnimation _convertAnimation({
  required TiledTsxTileAnimation animation,
  required TiledTsxTilesetSummary summary,
  required String atlasId,
  required String animationIdPrefixSlug,
  required String displayNamePrefix,
  required String? categoryId,
  required int sortOrder,
}) {
  final frames = <SurfaceAnimationFrame>[];
  for (final frame in animation.frames) {
    final coordinate = resolveTiledTsxTileCoordinate(
      tileId: frame.tileId,
      columns: summary.columns,
      tileWidth: summary.tileWidth,
      tileHeight: summary.tileHeight,
    );
    frames.add(
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: atlasId,
          column: coordinate.column,
          row: coordinate.row,
        ),
        durationMs: frame.durationMs,
      ),
    );
  }
  return ProjectSurfaceAnimation(
    id: _animationIdForBaseTileId(
      animationIdPrefixSlug: animationIdPrefixSlug,
      baseTileId: animation.baseTileId,
    ),
    name: '$displayNamePrefix tile ${animation.baseTileId}',
    timeline: SurfaceAnimationTimeline(frames: frames),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

void _validateOptions({
  required TiledTsxSurfaceAnimationImportOptions options,
  required String animationIdPrefixSlug,
  required List<TiledTsxSurfaceAnimationImportDiagnostic> diagnostics,
}) {
  if (options.atlasId.trim().isEmpty) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'atlasId must be non-empty.',
      ),
    );
  }
  if (options.tilesetId.trim().isEmpty) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'tilesetId must be non-empty.',
      ),
    );
  }
  if (options.animationIdPrefix.trim().isEmpty) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'animationIdPrefix must be non-empty.',
      ),
    );
  } else if (animationIdPrefixSlug.isEmpty) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'animationIdPrefix must contain letters or digits.',
      ),
    );
  }
}

_TiledTsxGridSize _validatedGridSize({
  required TiledTsxTilesetSummary summary,
  required List<TiledTsxSurfaceAnimationImportDiagnostic> diagnostics,
}) {
  if (summary.tileWidth <= 0) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'tileWidth must be > 0.',
      ),
    );
  }
  if (summary.tileHeight <= 0) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'tileHeight must be > 0.',
      ),
    );
  }
  if (summary.columns <= 0) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'columns must be > 0.',
      ),
    );
  }
  if (summary.tileCount <= 0) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'tileCount must be > 0.',
      ),
    );
  }
  if (summary.imageWidth <= 0) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'imageWidth must be > 0.',
      ),
    );
  }
  if (summary.imageHeight <= 0) {
    diagnostics.add(
      const TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
        message: 'imageHeight must be > 0.',
      ),
    );
  }

  var columnsFromImage = 0;
  var rowsFromImage = 0;
  if (summary.tileWidth > 0 && summary.imageWidth > 0) {
    if (summary.imageWidth % summary.tileWidth != 0) {
      diagnostics.add(
        TiledTsxSurfaceAnimationImportDiagnostic(
          severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
          message: 'imageWidth ${summary.imageWidth} is not divisible by '
              'tileWidth ${summary.tileWidth}.',
        ),
      );
    } else {
      columnsFromImage = summary.imageWidth ~/ summary.tileWidth;
      if (columnsFromImage != summary.columns) {
        diagnostics.add(
          TiledTsxSurfaceAnimationImportDiagnostic(
            severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
            message: 'columns ${summary.columns} does not match '
                'imageWidth/tileWidth $columnsFromImage.',
          ),
        );
      }
    }
  }
  if (summary.tileHeight > 0 && summary.imageHeight > 0) {
    if (summary.imageHeight % summary.tileHeight != 0) {
      diagnostics.add(
        TiledTsxSurfaceAnimationImportDiagnostic(
          severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
          message: 'imageHeight ${summary.imageHeight} is not divisible by '
              'tileHeight ${summary.tileHeight}.',
        ),
      );
    } else {
      rowsFromImage = summary.imageHeight ~/ summary.tileHeight;
    }
  }
  if (columnsFromImage > 0 &&
      rowsFromImage > 0 &&
      summary.tileCount != columnsFromImage * rowsFromImage) {
    diagnostics.add(
      TiledTsxSurfaceAnimationImportDiagnostic(
        severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.warning,
        message: 'tileCount ${summary.tileCount} does not match image grid '
            '${columnsFromImage * rowsFromImage}.',
      ),
    );
  }

  return _TiledTsxGridSize(
    columns: columnsFromImage > 0 ? columnsFromImage : summary.columns,
    rows: rowsFromImage,
  );
}

void _validateAnimations({
  required TiledTsxTilesetAudit audit,
  required String animationIdPrefixSlug,
  required _TiledTsxGridSize gridSize,
  required List<TiledTsxSurfaceAnimationImportDiagnostic> diagnostics,
}) {
  final generatedIds = <String>{};
  for (final animation in audit.animations) {
    final animationId = _animationIdForBaseTileId(
      animationIdPrefixSlug: animationIdPrefixSlug,
      baseTileId: animation.baseTileId,
    );
    if (!generatedIds.add(animationId)) {
      diagnostics.add(
        TiledTsxSurfaceAnimationImportDiagnostic(
          severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
          message: 'Duplicate animation id "$animationId".',
          baseTileId: animation.baseTileId,
        ),
      );
    }
    if (animation.frames.isEmpty) {
      diagnostics.add(
        TiledTsxSurfaceAnimationImportDiagnostic(
          severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
          message: 'Animation tile ${animation.baseTileId} has no frames.',
          baseTileId: animation.baseTileId,
        ),
      );
    }
    for (final frame in animation.frames) {
      if (frame.durationMs <= 0) {
        diagnostics.add(
          TiledTsxSurfaceAnimationImportDiagnostic(
            severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
            message: 'Frame duration must be > 0.',
            baseTileId: animation.baseTileId,
            frameTileId: frame.tileId,
          ),
        );
      }
      if (frame.tileId < 0 || frame.tileId >= audit.summary.tileCount) {
        diagnostics.add(
          TiledTsxSurfaceAnimationImportDiagnostic(
            severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.warning,
            message: 'Frame tileId ${frame.tileId} is outside tileCount '
                '${audit.summary.tileCount}.',
            baseTileId: animation.baseTileId,
            frameTileId: frame.tileId,
          ),
        );
        continue;
      }
      if (gridSize.columns <= 0 || gridSize.rows <= 0) {
        continue;
      }
      final coordinate = resolveTiledTsxTileCoordinate(
        tileId: frame.tileId,
        columns: audit.summary.columns,
        tileWidth: audit.summary.tileWidth,
        tileHeight: audit.summary.tileHeight,
      );
      if (coordinate.column >= gridSize.columns ||
          coordinate.row >= gridSize.rows) {
        diagnostics.add(
          TiledTsxSurfaceAnimationImportDiagnostic(
            severity: TiledTsxSurfaceAnimationImportDiagnosticSeverity.warning,
            message:
                'Frame tileId ${frame.tileId} resolves outside atlas grid.',
            baseTileId: animation.baseTileId,
            frameTileId: frame.tileId,
          ),
        );
      }
    }
  }
}

bool _hasImportErrors(
  List<TiledTsxSurfaceAnimationImportDiagnostic> diagnostics,
) {
  return diagnostics.any(
    (diagnostic) =>
        diagnostic.severity ==
        TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
  );
}

String _animationIdForBaseTileId({
  required String animationIdPrefixSlug,
  required int baseTileId,
}) {
  return '$animationIdPrefixSlug-tile-$baseTileId';
}

String _slugForIdSegment(String raw) {
  final input = raw.trim().toLowerCase();
  final out = StringBuffer();
  var previousHyphen = false;
  for (final codeUnit in input.runes) {
    final char = String.fromCharCode(codeUnit);
    final isAsciiLetter = char.compareTo('a') >= 0 && char.compareTo('z') <= 0;
    final isDigit = char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
    if (isAsciiLetter || isDigit) {
      out.write(char);
      previousHyphen = false;
      continue;
    }
    if (!previousHyphen && out.isNotEmpty) {
      out.write('-');
      previousHyphen = true;
    }
  }
  var slug = out.toString();
  while (slug.endsWith('-')) {
    slug = slug.substring(0, slug.length - 1);
  }
  return slug;
}

final class _TiledTsxGridSize {
  const _TiledTsxGridSize({
    required this.columns,
    required this.rows,
  });

  final int columns;
  final int rows;
}
