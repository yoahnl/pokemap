// Parser d'audit TSX Tiled limite aux tilesets animes.
//
// Cette brique ne cree pas de Surface, ne mute pas de manifest et ne depend
// pas d'un runtime. Elle extrait uniquement les metadonnees utiles pour
// comprendre un tileset Tiled/Pokemon SDK et ses animations declarees.

enum TiledTsxDiagnosticSeverity {
  warning,
  error,
}

final class TiledTsxDiagnostic {
  const TiledTsxDiagnostic({
    required this.severity,
    required this.message,
  });

  final TiledTsxDiagnosticSeverity severity;
  final String message;
}

final class TiledTsxTilesetSummary {
  const TiledTsxTilesetSummary({
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.tileCount,
    required this.imageSource,
    required this.imageWidth,
    required this.imageHeight,
    required this.transparentColor,
    required this.animationCount,
  });

  final String name;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int tileCount;
  final String imageSource;
  final int imageWidth;
  final int imageHeight;
  final String? transparentColor;
  final int animationCount;
}

final class TiledTsxAnimationFrame {
  const TiledTsxAnimationFrame({
    required this.tileId,
    required this.durationMs,
  });

  final int tileId;
  final int durationMs;
}

final class TiledTsxTileAnimation {
  const TiledTsxTileAnimation({
    required this.baseTileId,
    required this.frames,
  });

  final int baseTileId;
  final List<TiledTsxAnimationFrame> frames;
}

final class TiledTsxTileCoordinate {
  const TiledTsxTileCoordinate({
    required this.tileId,
    required this.column,
    required this.row,
    required this.sourceX,
    required this.sourceY,
  });

  final int tileId;
  final int column;
  final int row;
  final int sourceX;
  final int sourceY;
}

final class TiledTsxTilesetAudit {
  const TiledTsxTilesetAudit({
    required this.summary,
    required this.animations,
    required this.diagnostics,
  });

  final TiledTsxTilesetSummary summary;
  final List<TiledTsxTileAnimation> animations;
  final List<TiledTsxDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) => diagnostic.severity == TiledTsxDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == TiledTsxDiagnosticSeverity.warning,
      );

  TiledTsxTileAnimation? animationForBaseTileId(int baseTileId) {
    for (final animation in animations) {
      if (animation.baseTileId == baseTileId) {
        return animation;
      }
    }
    return null;
  }
}

TiledTsxTileCoordinate resolveTiledTsxTileCoordinate({
  required int tileId,
  required int columns,
  required int tileWidth,
  required int tileHeight,
}) {
  if (tileId < 0) {
    throw ArgumentError.value(tileId, 'tileId', 'must be >= 0');
  }
  if (columns <= 0) {
    throw ArgumentError.value(columns, 'columns', 'must be > 0');
  }
  if (tileWidth <= 0) {
    throw ArgumentError.value(tileWidth, 'tileWidth', 'must be > 0');
  }
  if (tileHeight <= 0) {
    throw ArgumentError.value(tileHeight, 'tileHeight', 'must be > 0');
  }

  final column = tileId % columns;
  final row = tileId ~/ columns;
  return TiledTsxTileCoordinate(
    tileId: tileId,
    column: column,
    row: row,
    sourceX: column * tileWidth,
    sourceY: row * tileHeight,
  );
}

TiledTsxTilesetAudit parseTiledTsxAnimatedTileset(String xml) {
  final diagnostics = <TiledTsxDiagnostic>[];
  final tilesetMatch = RegExp(r'<tileset\b([^>]*)>').firstMatch(xml);
  final tilesetAttrs = tilesetMatch == null
      ? const <String, String>{}
      : _parseXmlAttributes(tilesetMatch.group(1) ?? '');
  if (tilesetMatch == null) {
    diagnostics.add(
      const TiledTsxDiagnostic(
        severity: TiledTsxDiagnosticSeverity.error,
        message: 'Missing <tileset> root tag.',
      ),
    );
  }

  final imageMatch = RegExp(r'<image\b([^>]*)/?>').firstMatch(xml);
  final imageAttrs = imageMatch == null
      ? const <String, String>{}
      : _parseXmlAttributes(imageMatch.group(1) ?? '');
  if (imageMatch == null) {
    diagnostics.add(
      const TiledTsxDiagnostic(
        severity: TiledTsxDiagnosticSeverity.error,
        message: 'Missing <image> tag in TSX tileset.',
      ),
    );
  }

  final name = _requiredString(
    attrs: tilesetAttrs,
    key: 'name',
    diagnostics: diagnostics,
    context: 'tileset',
  );
  final tileWidth = _requiredInt(
    attrs: tilesetAttrs,
    key: 'tilewidth',
    diagnostics: diagnostics,
    context: 'tileset',
  );
  final tileHeight = _requiredInt(
    attrs: tilesetAttrs,
    key: 'tileheight',
    diagnostics: diagnostics,
    context: 'tileset',
  );
  final columns = _requiredInt(
    attrs: tilesetAttrs,
    key: 'columns',
    diagnostics: diagnostics,
    context: 'tileset',
  );
  final tileCount = _requiredInt(
    attrs: tilesetAttrs,
    key: 'tilecount',
    diagnostics: diagnostics,
    context: 'tileset',
  );
  final imageSource = _requiredString(
    attrs: imageAttrs,
    key: 'source',
    diagnostics: diagnostics,
    context: 'image',
  );
  final imageWidth = _requiredInt(
    attrs: imageAttrs,
    key: 'width',
    diagnostics: diagnostics,
    context: 'image',
  );
  final imageHeight = _requiredInt(
    attrs: imageAttrs,
    key: 'height',
    diagnostics: diagnostics,
    context: 'image',
  );

  final animations = _parseTileAnimations(
    xml: xml,
    tileCount: tileCount,
    diagnostics: diagnostics,
  );
  final summary = TiledTsxTilesetSummary(
    name: name,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    columns: columns,
    tileCount: tileCount,
    imageSource: imageSource,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    transparentColor: imageAttrs['trans'],
    animationCount: animations.length,
  );

  return TiledTsxTilesetAudit(
    summary: summary,
    animations: List<TiledTsxTileAnimation>.unmodifiable(animations),
    diagnostics: List<TiledTsxDiagnostic>.unmodifiable(diagnostics),
  );
}

List<TiledTsxTileAnimation> _parseTileAnimations({
  required String xml,
  required int tileCount,
  required List<TiledTsxDiagnostic> diagnostics,
}) {
  final animations = <TiledTsxTileAnimation>[];
  final tileRegex = RegExp(r'<tile\b([^>]*)>([\s\S]*?)</tile>');
  final animationRegex = RegExp(r'<animation\b[^>]*>([\s\S]*?)</animation>');

  for (final tileMatch in tileRegex.allMatches(xml)) {
    final tileAttrs = _parseXmlAttributes(tileMatch.group(1) ?? '');
    final tileBody = tileMatch.group(2) ?? '';
    final animationMatch = animationRegex.firstMatch(tileBody);
    if (animationMatch == null) {
      continue;
    }

    final baseTileId = _requiredInt(
      attrs: tileAttrs,
      key: 'id',
      diagnostics: diagnostics,
      context: 'tile',
    );
    if (tileCount > 0 && baseTileId >= tileCount) {
      diagnostics.add(
        TiledTsxDiagnostic(
          severity: TiledTsxDiagnosticSeverity.warning,
          message: 'Tile id $baseTileId is outside tilecount $tileCount.',
        ),
      );
    }

    final frames = _parseAnimationFrames(
      animationXml: animationMatch.group(1) ?? '',
      baseTileId: baseTileId,
      tileCount: tileCount,
      diagnostics: diagnostics,
    );
    animations.add(
      TiledTsxTileAnimation(
        baseTileId: baseTileId,
        frames: List<TiledTsxAnimationFrame>.unmodifiable(frames),
      ),
    );
  }

  return animations;
}

List<TiledTsxAnimationFrame> _parseAnimationFrames({
  required String animationXml,
  required int baseTileId,
  required int tileCount,
  required List<TiledTsxDiagnostic> diagnostics,
}) {
  final frames = <TiledTsxAnimationFrame>[];
  final frameRegex = RegExp(r'<frame\b([^>]*)/?>');
  var frameIndex = 0;
  for (final frameMatch in frameRegex.allMatches(animationXml)) {
    final frameAttrs = _parseXmlAttributes(frameMatch.group(1) ?? '');
    final tileId = _requiredInt(
      attrs: frameAttrs,
      key: 'tileid',
      diagnostics: diagnostics,
      context: 'tile $baseTileId frame $frameIndex',
    );
    final duration = _requiredInt(
      attrs: frameAttrs,
      key: 'duration',
      diagnostics: diagnostics,
      context: 'tile $baseTileId frame $frameIndex',
    );
    if (frameAttrs.containsKey('tileid') &&
        frameAttrs.containsKey('duration')) {
      if (tileCount > 0 && tileId >= tileCount) {
        diagnostics.add(
          TiledTsxDiagnostic(
            severity: TiledTsxDiagnosticSeverity.warning,
            message: 'Frame tileId $tileId for base tile $baseTileId is '
                'outside tilecount $tileCount.',
          ),
        );
      }
      frames.add(
        TiledTsxAnimationFrame(
          tileId: tileId,
          durationMs: duration,
        ),
      );
    }
    frameIndex++;
  }
  return frames;
}

Map<String, String> _parseXmlAttributes(String rawAttributes) {
  final attrs = <String, String>{};
  final attrRegex = RegExp(r'([A-Za-z_:][\w:.-]*)="([^"]*)"');
  for (final match in attrRegex.allMatches(rawAttributes)) {
    attrs[match.group(1)!] = _decodeBasicXmlEntities(match.group(2)!);
  }
  return attrs;
}

String _requiredString({
  required Map<String, String> attrs,
  required String key,
  required List<TiledTsxDiagnostic> diagnostics,
  required String context,
}) {
  final value = attrs[key];
  if (value == null) {
    diagnostics.add(
      TiledTsxDiagnostic(
        severity: TiledTsxDiagnosticSeverity.error,
        message: 'Missing required $context attribute "$key".',
      ),
    );
    return '';
  }
  return value;
}

int _requiredInt({
  required Map<String, String> attrs,
  required String key,
  required List<TiledTsxDiagnostic> diagnostics,
  required String context,
}) {
  final raw = attrs[key];
  if (raw == null) {
    diagnostics.add(
      TiledTsxDiagnostic(
        severity: TiledTsxDiagnosticSeverity.error,
        message: 'Missing required $context attribute "$key".',
      ),
    );
    return 0;
  }
  final parsed = int.tryParse(raw);
  if (parsed == null) {
    diagnostics.add(
      TiledTsxDiagnostic(
        severity: TiledTsxDiagnosticSeverity.error,
        message: 'Invalid integer "$raw" for $context attribute "$key".',
      ),
    );
    return 0;
  }
  return parsed;
}

String _decodeBasicXmlEntities(String value) {
  return value
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
