import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:path/path.dart' as p;

const selbrumeTwoTierCliffV3OrganicTilesetId =
    'ts_selbrume_cliff_two_tier_v3_organic';
const selbrumeTwoTierCliffV3OrganicBlueprintId = 'border-blueprint-5';
const selbrumeTwoTierCliffV3OrganicAtlasRelativePath =
    'assets/tilesets/falaises_selbrume_deux_etages_v3_organic.png';
const selbrumeTwoTierCliffV3OrganicProvenanceRelativePath =
    'assets/provenance/selbrume_two_tier_cliff_v3_organic.json';

const _elementCategoryId = 'cat_selbrume_borders';
const _tilesetFolderId = 'tsf_selbrume_beta_borders';
const _elementPrefix = 'el_selbrume_cliff_v3_';
const _primitivePrefix = 'selbrume-cliff-v3-organic-';

enum _OrganicPieceKind { top, face, corner, cap }

enum _Orientation { north, east, south, west }

final class SelbrumeTwoTierCliffV3OrganicRegistrationResult {
  const SelbrumeTwoTierCliffV3OrganicRegistrationResult({
    required this.projectFile,
    required this.tilesetId,
    required this.blueprintId,
    required this.elementCount,
    required this.primitiveCount,
  });

  final File projectFile;
  final String tilesetId;
  final String blueprintId;
  final int elementCount;
  final int primitiveCount;
}

/// Registers the generated organic two-tier atlas as a new unpublished draft.
///
/// Only `project.json` is replaced. The manifest's map references are guarded
/// before the atomic replacement.
Future<SelbrumeTwoTierCliffV3OrganicRegistrationResult>
    registerSelbrumeTwoTierCliffV3Organic({
  required Directory projectRoot,
}) async {
  final root = Directory(p.normalize(p.absolute(projectRoot.path)));
  if (!root.existsSync()) {
    throw StateError('Missing Selbrume project root: ${root.path}');
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  if (!projectFile.existsSync()) {
    throw StateError('Missing Selbrume project manifest: ${projectFile.path}');
  }
  final atlasFile = File(p.joinAll(<String>[
    root.path,
    ...selbrumeTwoTierCliffV3OrganicAtlasRelativePath.split('/'),
  ]));
  if (!atlasFile.existsSync()) {
    throw StateError('Missing V3 organic atlas: ${atlasFile.path}');
  }
  final provenanceFile = File(p.joinAll(<String>[
    root.path,
    ...selbrumeTwoTierCliffV3OrganicProvenanceRelativePath.split('/'),
  ]));
  if (!provenanceFile.existsSync()) {
    throw StateError(
      'Missing V3 organic provenance: ${provenanceFile.path}',
    );
  }

  final rawJson = jsonDecode(await projectFile.readAsString());
  if (rawJson is! Map<String, dynamic>) {
    throw const FormatException(r'$: expected a project object');
  }
  final beforeManifest = ProjectManifest.fromJson(rawJson);
  ProjectValidator.validate(beforeManifest);
  if (beforeManifest.borderCatalog.formatVersion <
      ProjectBorderCatalog.formatVersionV4) {
    throw StateError(
      'V3 organic registration requires Border catalog format version 4.',
    );
  }
  _requireSelbrumeRegistrationContext(beforeManifest);

  final protectedMaps = utf8.encode(jsonEncode(rawJson['maps']));
  final specs = _specsFromProvenance(
    jsonDecode(await provenanceFile.readAsString()),
  );

  final tilesets = _objectList(rawJson, 'tilesets');
  tilesets.removeWhere(
    (item) => item['id'] == selbrumeTwoTierCliffV3OrganicTilesetId,
  );
  tilesets.add(_tilesetJson());

  final elements = _objectList(rawJson, 'elements');
  elements.removeWhere(
    (item) =>
        item['id'] is String &&
        (item['id'] as String).startsWith(_elementPrefix),
  );
  for (var index = 0; index < specs.length; index += 1) {
    elements.add(_elementJson(specs[index], index));
  }

  // Parse and validate the manifest before metric analysis so every source
  // element, atlas cell and category reference goes through the real model.
  final manifestWithAssets = ProjectManifest.fromJson(rawJson);
  ProjectValidator.validate(manifestWithAssets);

  const assetService = BorderProjectElementAssetService();
  final primitives = <BorderPrimitiveDraft>[];
  for (final spec in specs) {
    final prepared = await assetService.prepare(
      manifest: manifestWithAssets,
      projectRootPath: root.path,
      sourceElementId: spec.elementId,
      primitiveId: spec.primitiveId,
      role: spec.role,
      authoredOrientation: spec.authoredOrientation,
      weight:
          spec.piece == _OrganicPieceKind.top && spec.variant == 6 ? 1 : 1000,
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      anchorPx: spec.anchor,
    );
    primitives.add(prepared.primitive);
  }

  final record = BorderBlueprintRecord(
    id: selbrumeTwoTierCliffV3OrganicBlueprintId,
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: BorderBlueprintDraftDefinition(
        name: 'Falaises Selbrume — pierres organiques imbriquées',
        previewSeed: BorderSignedInt64.parse('1907202601'),
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: primitives,
        defaults: BorderGenerationParams(
          irregularityPermille: 280,
          detailDensityPermille: 0,
          variationPermille: 1000,
          maxOverlapPx: 9,
          gapTolerancePx: 0,
          depthRows: 2,
          allowAutoRotation: false,
        ),
        sortOrder: 4,
      ),
    ),
  );
  final catalogJson = rawJson['borderCatalog'];
  if (catalogJson is! Map<String, dynamic>) {
    throw const FormatException(r'$.borderCatalog: expected an object');
  }
  final records = _objectList(catalogJson, 'records');
  records.removeWhere(
    (item) => item['id'] == selbrumeTwoTierCliffV3OrganicBlueprintId,
  );
  records.add(
    encodeBorderBlueprintRecordJson(
      record,
      path: r'$.borderCatalog.records[v3Organic]',
      formatVersion: beforeManifest.borderCatalog.formatVersion,
    ),
  );

  final finalManifest = ProjectManifest.fromJson(rawJson);
  ProjectValidator.validate(finalManifest);
  final registered = finalManifest.borderCatalog.recordById(
    selbrumeTwoTierCliffV3OrganicBlueprintId,
  );
  if (registered == null ||
      registered.latestPublished != null ||
      registered.draft.definition.primitives.length != specs.length) {
    throw StateError('Invalid V3 organic draft after registration.');
  }
  if (!_bytesEqual(utf8.encode(jsonEncode(rawJson['maps'])), protectedMaps)) {
    throw StateError('V3 organic registration changed project map references.');
  }

  final encoded = utf8.encode(
    '${const JsonEncoder.withIndent('  ').convert(rawJson)}\n',
  );
  await _replaceFileAtomically(projectFile, encoded);
  return SelbrumeTwoTierCliffV3OrganicRegistrationResult(
    projectFile: projectFile,
    tilesetId: selbrumeTwoTierCliffV3OrganicTilesetId,
    blueprintId: selbrumeTwoTierCliffV3OrganicBlueprintId,
    elementCount: specs.length,
    primitiveCount: primitives.length,
  );
}

void _requireSelbrumeRegistrationContext(ProjectManifest manifest) {
  if (!manifest.elementCategories
      .any((category) => category.id == _elementCategoryId)) {
    throw StateError('Missing Selbrume border category $_elementCategoryId.');
  }
  if (!manifest.tilesetFolders.any((folder) => folder.id == _tilesetFolderId)) {
    throw StateError(
        'Missing Selbrume border tileset folder $_tilesetFolderId.');
  }
}

Map<String, Object?> _tilesetJson() => <String, Object?>{
      'id': selbrumeTwoTierCliffV3OrganicTilesetId,
      'name': 'Falaises Selbrume - pierres organiques imbriquées',
      'relativePath': selbrumeTwoTierCliffV3OrganicAtlasRelativePath,
      'scope': 'global',
      'groupId': null,
      'folderId': _tilesetFolderId,
      'sortOrder': 4,
      'isWorldTileset': false,
      'elementGroups': <Object?>[],
      'paletteEntries': <Object?>[],
    };

Map<String, Object?> _elementJson(_OrganicStoneSpec spec, int index) =>
    <String, Object?>{
      'id': spec.elementId,
      'name': 'Falaise organique — ${spec.pieceLabel} '
          '${spec.orientationLabel} ${spec.variantLabel}',
      'tilesetId': selbrumeTwoTierCliffV3OrganicTilesetId,
      'categoryId': _elementCategoryId,
      'tilesetGroupId': null,
      'frames': <Object?>[
        <String, Object?>{
          'tilesetId': '',
          'source': <String, int>{
            'x': spec.atlasColumn,
            'y': spec.atlasRow,
            'width': 1,
            'height': 1,
          },
          'durationMs': null,
        },
      ],
      'presetKind': 'cliff',
      'collisionProfile': null,
      'shadow': null,
      'groupId': null,
      'recommendedLayerId': null,
      'tags': <String>[
        'border',
        'cliff',
        'stone',
        'organic',
        'individual_stone',
        'two_tier',
        'visual_only',
        spec.pieceWire,
        spec.orientationWire,
      ],
      'sortOrder': 300 + index,
    };

List<_OrganicStoneSpec> _specsFromProvenance(Object? json) {
  final provenance = _requireObject(json, r'$provenance');
  final atlasGrid = _requireObject(
    provenance['atlasGrid'],
    r'$provenance.atlasGrid',
  );
  if (_requireInt(atlasGrid['columns'], r'$provenance.atlasGrid.columns') !=
          10 ||
      _requireInt(atlasGrid['rows'], r'$provenance.atlasGrid.rows') != 8) {
    throw const FormatException(
      r'$provenance.atlasGrid: expected the final 10x8 atlas',
    );
  }
  final tileSize = _requireObject(
    provenance['tileSize'],
    r'$provenance.tileSize',
  );
  if (_requireInt(tileSize['width'], r'$provenance.tileSize.width') != 32 ||
      _requireInt(tileSize['height'], r'$provenance.tileSize.height') != 32) {
    throw const FormatException(
      r'$provenance.tileSize: expected 32x32 cells',
    );
  }
  final entries = provenance['entries'];
  if (entries is! List<dynamic> || entries.length != 80) {
    throw const FormatException(
      r'$provenance.entries: expected exactly 80 entries',
    );
  }

  final result = <_OrganicStoneSpec>[];
  final ids = <String>{};
  final fileNames = <String>{};
  final roleCounts = <BorderPrimitiveRole, int>{};
  final orientationCounts = <BorderPrimitiveOrientation, int>{};
  for (var index = 0; index < entries.length; index += 1) {
    final path = '\$provenance.entries[$index]';
    final entry = _requireObject(entries[index], path);
    final spec = _OrganicStoneSpec.fromProvenance(entry, path: path);
    if (!ids.add(spec.primitiveId)) {
      throw FormatException('$path.id: duplicate ${spec.primitiveId}');
    }
    if (!fileNames.add(spec.fileName)) {
      throw FormatException('$path.fileName: duplicate ${spec.fileName}');
    }
    if (spec.atlasColumn != index % 10 || spec.atlasRow != index ~/ 10) {
      throw FormatException(
        '$path.atlasCell: entry order must match the 10x8 atlas',
      );
    }
    roleCounts.update(spec.role, (count) => count + 1, ifAbsent: () => 1);
    orientationCounts.update(
      spec.authoredOrientation,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    result.add(spec);
  }
  if (!_sameCounts(roleCounts, const <BorderPrimitiveRole, int>{
    BorderPrimitiveRole.structureLarge: 24,
    BorderPrimitiveRole.structureMedium: 24,
    BorderPrimitiveRole.lineCorner: 24,
    BorderPrimitiveRole.lineCap: 8,
  })) {
    throw const FormatException(
      r'$provenance.entries: expected roles 24 top, 24 face, 24 corner, 8 cap',
    );
  }
  if (!_sameCounts(
    orientationCounts,
    const <BorderPrimitiveOrientation, int>{
      BorderPrimitiveOrientation.north: 20,
      BorderPrimitiveOrientation.east: 20,
      BorderPrimitiveOrientation.south: 20,
      BorderPrimitiveOrientation.west: 20,
    },
  )) {
    throw const FormatException(
      r'$provenance.entries: expected 20 pieces per orientation',
    );
  }
  return List<_OrganicStoneSpec>.unmodifiable(result);
}

List<Map<String, dynamic>> _objectList(
  Map<String, dynamic> owner,
  String key,
) {
  final value = owner[key];
  if (value is! List<dynamic>) {
    throw FormatException('\$.$key: expected a list');
  }
  for (var index = 0; index < value.length; index += 1) {
    if (value[index] is! Map<String, dynamic>) {
      throw FormatException('\$.$key[$index]: expected an object');
    }
  }
  return value.cast<Map<String, dynamic>>();
}

Future<void> _replaceFileAtomically(File destination, List<int> bytes) async {
  final temporary = File(
    '${destination.path}.v3-organic-$pid-'
    '${DateTime.now().microsecondsSinceEpoch}.tmp',
  );
  try {
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(destination.path);
  } catch (error, stackTrace) {
    if (temporary.existsSync()) {
      await temporary.delete();
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _OrganicStoneSpec {
  const _OrganicStoneSpec({
    required this.primitiveId,
    required this.fileName,
    required this.piece,
    required this.orientation,
    required this.variant,
    required this.anchor,
    required this.atlasColumn,
    required this.atlasRow,
  });

  factory _OrganicStoneSpec.fromProvenance(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final primitiveId = _requireString(json['id'], '$path.id');
    final fileName = _requireString(json['fileName'], '$path.fileName');
    final match = RegExp(
      r'^(top|face|corner|cap)_([nesw])_(\d{2})\.png$',
    ).firstMatch(fileName);
    if (match == null) {
      throw FormatException(
        '$path.fileName: expected top|face|corner|cap orientation asset',
      );
    }
    final piece = switch (match.group(1)) {
      'top' => _OrganicPieceKind.top,
      'face' => _OrganicPieceKind.face,
      'corner' => _OrganicPieceKind.corner,
      'cap' => _OrganicPieceKind.cap,
      _ => throw StateError('Unreachable organic piece kind.'),
    };
    final orientation = switch (match.group(2)) {
      'n' => _Orientation.north,
      'e' => _Orientation.east,
      's' => _Orientation.south,
      'w' => _Orientation.west,
      _ => throw StateError('Unreachable organic orientation.'),
    };
    final variant = _requireInt(json['variant'], '$path.variant');
    final maximumVariant = switch (piece) {
      _OrganicPieceKind.top ||
      _OrganicPieceKind.face ||
      _OrganicPieceKind.corner =>
        6,
      _OrganicPieceKind.cap => 2,
    };
    if (variant < 1 || variant > maximumVariant) {
      throw FormatException(
        '$path.variant: expected 1..$maximumVariant for ${piece.name}',
      );
    }
    if (int.parse(match.group(3)!) != variant) {
      throw FormatException('$path.variant: does not match $fileName');
    }
    final expectedRole = switch (piece) {
      _OrganicPieceKind.top => 'top',
      _OrganicPieceKind.face => 'face',
      _OrganicPieceKind.corner => 'lineCorner',
      _OrganicPieceKind.cap => 'lineCap',
    };
    if (_requireString(json['role'], '$path.role') != expectedRole) {
      throw FormatException('$path.role: does not match $fileName');
    }
    final expectedOrientation = orientation.name;
    if (_requireString(
          json['authoredOrientation'],
          '$path.authoredOrientation',
        ) !=
        expectedOrientation) {
      throw FormatException(
        '$path.authoredOrientation: does not match $fileName',
      );
    }
    final expectedPrimitiveId =
        '$_primitivePrefix${p.basenameWithoutExtension(fileName).replaceAll('_', '-')}';
    if (primitiveId != expectedPrimitiveId) {
      throw FormatException('$path.id: does not match $fileName');
    }

    final anchorJson = _requireObject(json['anchorPx'], '$path.anchorPx');
    final anchor = BorderPixelPos(
      x: _requireBoundedInt(anchorJson['x'], '$path.anchorPx.x', 0, 31),
      y: _requireBoundedInt(anchorJson['y'], '$path.anchorPx.y', 0, 31),
    );
    final atlasCell = _requireObject(json['atlasCell'], '$path.atlasCell');
    final atlasColumn = _requireBoundedInt(
      atlasCell['column'],
      '$path.atlasCell.column',
      0,
      9,
    );
    final atlasRow = _requireBoundedInt(
      atlasCell['row'],
      '$path.atlasCell.row',
      0,
      7,
    );
    _requireBoundedInt(
      json['tangentSpanPx'],
      '$path.tangentSpanPx',
      1,
      32,
    );
    _requireBoundedInt(
      json['normalSpanPx'],
      '$path.normalSpanPx',
      1,
      32,
    );
    _requireBoundedInt(json['frontGapPx'], '$path.frontGapPx', 0, 32);
    return _OrganicStoneSpec(
      primitiveId: primitiveId,
      fileName: fileName,
      piece: piece,
      orientation: orientation,
      variant: variant,
      anchor: anchor,
      atlasColumn: atlasColumn,
      atlasRow: atlasRow,
    );
  }

  final String primitiveId;
  final String fileName;
  final _OrganicPieceKind piece;
  final _Orientation orientation;
  final int variant;
  final BorderPixelPos anchor;
  final int atlasColumn;
  final int atlasRow;

  String get pieceWire => piece.name;
  String get orientationWire => switch (orientation) {
        _Orientation.north => 'n',
        _Orientation.east => 'e',
        _Orientation.south => 's',
        _Orientation.west => 'w',
      };
  String get variantLabel => variant.toString().padLeft(2, '0');
  String get elementId =>
      '$_elementPrefix${p.basenameWithoutExtension(fileName)}';
  String get pieceLabel => switch (piece) {
        _OrganicPieceKind.top => 'Sommet',
        _OrganicPieceKind.face => 'Façade',
        _OrganicPieceKind.corner => 'Angle',
        _OrganicPieceKind.cap => 'Terminaison',
      };
  String get orientationLabel => switch (orientation) {
        _Orientation.north => 'Nord',
        _Orientation.east => 'Est',
        _Orientation.south => 'Sud',
        _Orientation.west => 'Ouest',
      };
  BorderPrimitiveRole get role => switch (piece) {
        _OrganicPieceKind.top => BorderPrimitiveRole.structureLarge,
        _OrganicPieceKind.face => BorderPrimitiveRole.structureMedium,
        _OrganicPieceKind.corner => BorderPrimitiveRole.lineCorner,
        _OrganicPieceKind.cap => BorderPrimitiveRole.lineCap,
      };
  BorderPrimitiveOrientation get authoredOrientation => switch (orientation) {
        _Orientation.north => BorderPrimitiveOrientation.north,
        _Orientation.east => BorderPrimitiveOrientation.east,
        _Orientation.south => BorderPrimitiveOrientation.south,
        _Orientation.west => BorderPrimitiveOrientation.west,
      };
}

Map<String, dynamic> _requireObject(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$path: expected an object');
  }
  return value;
}

String _requireString(Object? value, String path) {
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw FormatException('$path: expected a nonblank trimmed string');
  }
  return value;
}

int _requireInt(Object? value, String path) {
  if (value is! int) {
    throw FormatException('$path: expected an integer');
  }
  return value;
}

int _requireBoundedInt(Object? value, String path, int minimum, int maximum) {
  final parsed = _requireInt(value, path);
  if (parsed < minimum || parsed > maximum) {
    throw FormatException('$path: expected $minimum..$maximum');
  }
  return parsed;
}

bool _sameCounts<K>(Map<K, int> actual, Map<K, int> expected) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) return false;
  }
  return true;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 || arguments.first != '--project-root') {
    throw ArgumentError(
      'Usage: dart run '
      'tool/register_selbrume_two_tier_cliff_v3_organic.dart '
      '--project-root <dir>',
    );
  }
  final result = await registerSelbrumeTwoTierCliffV3Organic(
    projectRoot: Directory(arguments[1]),
  );
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'project': result.projectFile.path,
      'tilesetId': result.tilesetId,
      'blueprintId': result.blueprintId,
      'elementCount': result.elementCount,
      'primitiveCount': result.primitiveCount,
    }),
  );
}
