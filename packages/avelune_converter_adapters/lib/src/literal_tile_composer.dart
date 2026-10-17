import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'literal_autotile_composer.dart';

enum LiteralDependencyDisposition { include, excludeStudy, block }

enum LiteralDependencyKind { staticTransfer, dynamicTransfer, invalidTransfer }

final class LiteralDependencyDecision {
  const LiteralDependencyDecision({
    required this.sourceSnapshotHash,
    required this.selectionHash,
    required this.locator,
    required this.targetSourceMapId,
    required this.decision,
  });

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash selectionHash;
  final SourceLocator locator;
  final int? targetSourceMapId;
  final LiteralDependencyDisposition decision;

  Map<String, Object?> toJson() => {
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'selectionHash': selectionHash.value,
        'locator': locator.toJson(),
        'targetSourceMapId': targetSourceMapId,
        'decision': decision.name,
      };

  Sha256Hash get canonicalHash => canonicalHashOf(toJson());
}

Sha256Hash literalSelectionHash(
    NormalizedSourceProject source, List<int> selectedSourceMapIds) {
  if (selectedSourceMapIds.isEmpty || selectedSourceMapIds.length > 2048) {
    throw const NativeWriteException('literal.selection.invalid',
        'A bounded nonempty map selection is required');
  }
  final count = selectedSourceMapIds.length;
  final identities = <int>{};
  for (var index = 0; index < count; index++) {
    final id = selectedSourceMapIds[index];
    if (id <= 0 || id > 2147483647 || !identities.add(id)) {
      throw const NativeWriteException('literal.selection.invalid',
          'Map selection must have unique valid IDs');
    }
  }
  final ids = identities.toList()..sort();
  return canonicalHashOf({
    'kind': 'literalSelection',
    'version': 1,
    'sourceSnapshotHash': source.snapshot.canonicalHash.value,
    'logicalProjectNamespace': source.snapshot.logicalProjectNamespace.value,
    'selectedSourceMapIds': ids,
  });
}

final class LiteralCompositionDiagnostic {
  LiteralCompositionDiagnostic({
    required this.code,
    required this.blocksPlanning,
    required Map<String, Object?> locator,
    required this.message,
  }) : locator = _literalFreezeJson(jsonDecode(canonicalJsonOf(locator)))
            as Map<String, Object?>;

  final String code;
  final bool blocksPlanning;
  final Map<String, Object?> locator;
  final String message;

  Map<String, Object?> toJson() => {
        'code': code,
        'blocksPlanning': blocksPlanning,
        'locator': locator,
        'message': message,
      };
}

final class LiteralTileCrop {
  const LiteralTileCrop({
    required this.sourceTilesetId,
    required this.sourceTileId,
    required this.nativeTilesetId,
    required this.nativeLocalTileId,
    required this.paletteCell,
    required this.imageFileId,
    required this.imageSha256,
    required this.x,
    required this.y,
    required this.passage,
    required this.priority,
    required this.terrainTag,
    this.autotileSlot,
    this.autotileVariant,
    this.nativeImageSha256,
  });

  final int sourceTilesetId;
  final int sourceTileId;
  final String nativeTilesetId;
  final int nativeLocalTileId;
  final int paletteCell;
  final ConverterId imageFileId;
  final Sha256Hash imageSha256;
  final int x;
  final int y;
  int get width => 32;
  int get height => 32;
  final int passage;
  final int priority;
  final int terrainTag;
  final int? autotileSlot;
  final int? autotileVariant;
  final Sha256Hash? nativeImageSha256;

  Map<String, Object?> toJson() => {
        'sourceTilesetId': sourceTilesetId,
        'sourceTileId': sourceTileId,
        'nativeTilesetId': nativeTilesetId,
        'nativeLocalTileId': nativeLocalTileId,
        'paletteCell': paletteCell,
        'imageFileId': imageFileId.value,
        'imageSha256': imageSha256.value,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'passage': passage,
        'priority': priority,
        'terrainTag': terrainTag,
        if (autotileSlot != null) 'autotileSlot': autotileSlot,
        if (autotileVariant != null) 'autotileVariant': autotileVariant,
        if (nativeImageSha256 != null)
          'nativeImageSha256': nativeImageSha256!.value,
      };
}

final class LiteralLayerProvenance {
  const LiteralLayerProvenance({
    required this.sourceMapId,
    required this.sourceFileId,
    required this.sourceZ,
    required this.nativeLayerId,
    required this.cellCount,
    required this.sourceLayerHash,
    required this.nativeCellsHash,
  });

  final int sourceMapId;
  final ConverterId sourceFileId;
  final int sourceZ;
  final String nativeLayerId;
  final int cellCount;
  final Sha256Hash sourceLayerHash;
  final Sha256Hash nativeCellsHash;

  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'sourceFileId': sourceFileId.value,
        'sourceZ': sourceZ,
        'nativeLayerId': nativeLayerId,
        'cellCount': cellCount,
        'sourceLayerHash': sourceLayerHash.value,
        'nativeCellsHash': nativeCellsHash.value,
      };
}

final class LiteralMapDependency {
  const LiteralMapDependency({
    required this.sourceMapId,
    required this.targetSourceMapId,
    required this.locator,
    required this.kind,
    required this.decision,
  });

  final int sourceMapId;
  final int? targetSourceMapId;
  final SourceLocator locator;
  final LiteralDependencyKind kind;
  final LiteralDependencyDisposition? decision;

  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'targetSourceMapId': targetSourceMapId,
        'locator': locator.toJson(),
        'kind': kind.name,
        'decision': decision?.name,
      };
}

final class LiteralTileComposition {
  LiteralTileComposition._({
    required this.draft,
    required this.selectionHash,
    required this.compositionHash,
    required Map<int, String> mapIds,
    required Map<int, String> tilesetIds,
    required Map<int, MapData> nativeMaps,
    required List<int> selectedSourceMapIds,
    required List<int> includedSourceMapIds,
    required List<LiteralTileCrop> crops,
    required List<LiteralAutotileComposition> autotiles,
    required List<LiteralLayerProvenance> layerProvenance,
    required List<LiteralMapDependency> dependencies,
    required List<LiteralCompositionDiagnostic> diagnostics,
    required NativeWriteLimits creationLimits,
    required List<SourceFileEntry> sourceReads,
  })  : mapIds = Map.unmodifiable(mapIds),
        tilesetIds = Map.unmodifiable(tilesetIds),
        nativeMaps = Map.unmodifiable(nativeMaps),
        selectedSourceMapIds = List.unmodifiable(selectedSourceMapIds),
        includedSourceMapIds = List.unmodifiable(includedSourceMapIds),
        crops = List.unmodifiable(crops),
        autotiles = List.unmodifiable(autotiles),
        layerProvenance = List.unmodifiable(layerProvenance),
        dependencies = List.unmodifiable(dependencies),
        diagnostics = List.unmodifiable(diagnostics),
        _creationLimits = creationLimits,
        _sourceReads = List.unmodifiable(sourceReads);

  final NativeProjectDraft? draft;
  final Sha256Hash selectionHash;
  final Sha256Hash compositionHash;
  final Map<int, String> mapIds;
  final Map<int, String> tilesetIds;
  final Map<int, MapData> nativeMaps;
  final List<int> selectedSourceMapIds;
  final List<int> includedSourceMapIds;
  final List<LiteralTileCrop> crops;
  final List<LiteralAutotileComposition> autotiles;
  final List<LiteralLayerProvenance> layerProvenance;
  final List<LiteralMapDependency> dependencies;
  final List<LiteralCompositionDiagnostic> diagnostics;
  final NativeWriteLimits _creationLimits;
  final List<SourceFileEntry> _sourceReads;
  bool get canWrite => draft != null;
  bool get playableCertified => false;

  Future<LiteralTileComposition?> verifyForReuse({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final original = draft;
    if (original == null || !_coversCreationLimits(limits)) return null;
    if (!source.canPlan ||
        !source.archive.isSealed ||
        source.snapshot.state != SourceScanState.complete ||
        source.snapshot.canonicalHash !=
            original.source.snapshot.canonicalHash ||
        source.canonicalHash != original.normalizedSourceHash ||
        source.archive.canonicalHash != original.source.archive.canonicalHash ||
        literalSelectionHash(source, selectedSourceMapIds) != selectionHash ||
        original.compositionEvidence['compositionHash'] !=
            compositionHash.value) {
      throw const NativeWriteException('semantics.literal.changed',
          'Source semantic composition requires the exact original literal generation');
    }
    original.validateResourceBudget(limits: limits);
    cancellation?.check();
    final entries = {
      for (final entry in source.snapshot.entries) entry.fileId: entry
    };
    for (final entry in _sourceReads) {
      cancellation?.check();
      final current = entries[entry.fileId];
      if (current == null ||
          canonicalJsonOf(current.toJson()) !=
              canonicalJsonOf(entry.toJson())) {
        throw const NativeWriteException('semantics.literal.changed',
            'Original literal source read is not in the current snapshot');
      }
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          crypto.sha256.convert(bytes).toString() != entry.sha256?.value) {
        throw const NativeWriteException('literal.source.changed',
            'Original literal source read differs from its admitted snapshot');
      }
    }
    return this;
  }

  bool _coversCreationLimits(NativeWriteLimits limits) =>
      limits.maxArtifacts >= _creationLimits.maxArtifacts &&
      limits.maxMutations >= _creationLimits.maxMutations &&
      limits.maxArtifactBytes >= _creationLimits.maxArtifactBytes &&
      limits.maxTotalArtifactBytes >= _creationLimits.maxTotalArtifactBytes &&
      limits.maxTotalDraftJsonBytes >= _creationLimits.maxTotalDraftJsonBytes &&
      limits.maxImagePixels >= _creationLimits.maxImagePixels &&
      limits.maxTotalImagePixels >= _creationLimits.maxTotalImagePixels &&
      limits.maxMapCells >= _creationLimits.maxMapCells &&
      limits.jsonLimits.maxDepth >= _creationLimits.jsonLimits.maxDepth &&
      limits.jsonLimits.maxNodes >= _creationLimits.jsonLimits.maxNodes &&
      limits.jsonLimits.maxStringCodeUnits >=
          _creationLimits.jsonLimits.maxStringCodeUnits &&
      limits.jsonLimits.maxTextCodeUnits >=
          _creationLimits.jsonLimits.maxTextCodeUnits;
}

final class _LiteralSourceReads implements SourceFilePort {
  _LiteralSourceReads(this.delegate, SourceSnapshot snapshot, this.cancellation)
      : entries = {for (final entry in snapshot.entries) entry.fileId: entry};

  final SourceFilePort delegate;
  final Map<ConverterId, SourceFileEntry> entries;
  final ScanCancellation? cancellation;
  final Map<ConverterId, SourceFileEntry> reads = {};

  @override
  Future<List<int>> read(ConverterId fileId) async {
    cancellation?.check();
    final entry = entries[fileId];
    if (entry == null ||
        entry.kind != SourceNodeKind.file ||
        entry.sha256 == null) {
      throw const NativeWriteException('literal.source.file',
          'A literal source read requires an inventoried hashed file');
    }
    final bytes = await delegate.read(fileId);
    cancellation?.check();
    reads.putIfAbsent(fileId, () => entry);
    return bytes;
  }
}

final class LiteralTileComposer {
  const LiteralTileComposer();

  Future<LiteralTileComposition> compose({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required List<int> selectedSourceMapIds,
    required String projectName,
    required String parentPath,
    required String folderName,
    String? sourceRootPath,
    List<LiteralDependencyDecision> dependencyDecisions = const [],
    bool allowFirstFrameAutotiles = false,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    final selectedCount = selectedSourceMapIds.length;
    final decisionCount = dependencyDecisions.length;
    if (selectedCount > limits.maxMutations ||
        decisionCount > limits.maxMutations) {
      throw const NativeWriteException(
          'literal.quota.selection', 'Selection or decision budget exceeded');
    }
    final selected = List<int>.generate(
        selectedCount, (index) => selectedSourceMapIds[index],
        growable: false);
    final frozenDecisions = List<LiteralDependencyDecision>.generate(
        decisionCount, (index) => dependencyDecisions[index],
        growable: false);
    final selectionHash = literalSelectionHash(source, selected);
    return _LiteralCompositionRun(
      source: source,
      files: _LiteralSourceReads(files, source.snapshot, cancellation),
      selected: selected..sort(),
      selectionHash: selectionHash,
      projectName: projectName,
      parentPath: parentPath,
      folderName: folderName,
      sourceRootPath: sourceRootPath,
      decisions: List.unmodifiable(frozenDecisions),
      limits: limits,
      cancellation: cancellation,
      allowFirstFrameAutotiles: allowFirstFrameAutotiles,
    ).run();
  }
}

final class _LiteralMapInput {
  const _LiteralMapInput(this.map, this.layers, this.cells);
  final SourceMapData map;
  final List<SourceTileLayer> layers;
  final List<List<int>> cells;
}

final class _LiteralCompositionRun {
  _LiteralCompositionRun({
    required this.source,
    required this.files,
    required this.selected,
    required this.selectionHash,
    required this.projectName,
    required this.parentPath,
    required this.folderName,
    required this.sourceRootPath,
    required this.decisions,
    required this.limits,
    required this.cancellation,
    required this.allowFirstFrameAutotiles,
  });

  final NormalizedSourceProject source;
  final _LiteralSourceReads files;
  final List<int> selected;
  final Sha256Hash selectionHash;
  final String projectName;
  final String parentPath;
  final String folderName;
  final String? sourceRootPath;
  final List<LiteralDependencyDecision> decisions;
  final NativeWriteLimits limits;
  final ScanCancellation? cancellation;
  final bool allowFirstFrameAutotiles;
  final autotiles = <(int, int), LiteralAutotileComposition>{};
  final diagnostics = <LiteralCompositionDiagnostic>[];
  final dependencies = <LiteralMapDependency>[];
  final crops = <LiteralTileCrop>[];
  final provenance = <LiteralLayerProvenance>[];
  final mapIds = <int, String>{};
  final tilesetIds = <int, String>{};
  final nativeMaps = <int, MapData>{};
  final artifacts = <String, NativeArtifact>{};
  final mutations = <NativeMutation>[];
  final inputs = <int, _LiteralMapInput>{};
  final usedTiles = <int, Set<int>>{};
  final atlasEntries = <int, SourceFileEntry>{};
  final atlasArtifacts = <int, NativeArtifact>{};
  final dimensions = <int, (int, int)>{};
  final resolvedDecisions = <String, LiteralDependencyDecision>{};
  final usedDecisions = <String>{};
  final closure = <int>{};
  final diagnosticKeys = <String>{};
  final mapPaths = <ConverterId, String>{};
  int diagnosticNodes = 0;
  int diagnosticText = 0;
  late final Sha256Hash sourceHash;
  late final Sha256Hash snapshotHash;

  Future<LiteralTileComposition> run() async {
    cancellation?.check();
    snapshotHash = source.snapshot.canonicalHash;
    sourceHash = source.canonicalHash;
    if (!source.canPlan ||
        !source.archive.isSealed ||
        source.snapshot.state != SourceScanState.complete) {
      diagnostic('literal.source.incomplete', true, const {},
          'A complete plannable normalized source is required');
      return finish();
    }
    if (source.snapshot.profile.state != SourceProfileState.confirmed) {
      diagnostic('literal.profile.${source.snapshot.profile.state.name}', false,
          const {}, 'Source profile remains an unconfirmed study observation');
    }
    inspectDependencies();
    if (blocked) return finish();
    inspectMaps();
    if (blocked) return finish();
    inspectAtlases();
    if (blocked) return finish();
    await readAtlases();
    if (blocked) return finish();
    await readAutotiles();
    if (blocked) return finish();
    composeMaps();
    cancellation?.check();
    return finish();
  }

  bool get blocked => diagnostics.any((item) => item.blocksPlanning);

  SourceMapData? sourceMap(int id) {
    for (final map in source.maps) {
      if (map.map.sourceMapId == id) return map.map;
    }
    return null;
  }

  NormalizedTileset? sourceTileset(int id) {
    for (final tileset in source.tilesets) {
      if (tileset.sourceTilesetId == id) return tileset;
    }
    return null;
  }

  String decisionKey(SourceLocator locator, int? target) => canonicalJsonOf(
      {'locator': locator.toJson(), 'targetSourceMapId': target});

  void inspectDependencies() {
    for (final decision in decisions) {
      final key = decisionKey(decision.locator, decision.targetSourceMapId);
      if (decision.sourceSnapshotHash != snapshotHash ||
          decision.selectionHash != selectionHash ||
          (decision.targetSourceMapId == null
              ? decision.decision == LiteralDependencyDisposition.include
              : decision.targetSourceMapId! <= 0 ||
                  decision.targetSourceMapId! > 2147483647) ||
          resolvedDecisions.containsKey(key)) {
        diagnostic(
            'literal.dependency.decision',
            true,
            decision.locator.toJson(),
            'Dependency decision is stale or ambiguous');
      } else {
        resolvedDecisions[key] = decision;
      }
    }
    closure.addAll(selected);
    final queue = List<int>.of(selected);
    for (var index = 0; index < queue.length; index++) {
      cancellation?.check();
      final id = queue[index];
      final map = sourceMap(id);
      if (map == null) {
        diagnostic('literal.dependency.renormalize', true, {'mapId': id},
            'Selected or included map is absent from the normalized source');
        continue;
      }
      var hasEvents = false;
      for (final event in map.events) {
        hasEvents = true;
        for (final page in event.pages) {
          for (final command in page.commands) {
            if (command.code != 201) continue;
            if (dependencies.length >= limits.maxMutations) {
              throw const NativeWriteException('literal.quota.dependencies',
                  'Dependency inspection budget exceeded');
            }
            final parameters = command.parameters;
            final mode = parameters.isEmpty ? null : parameters[0];
            final rawTarget = parameters.length < 2 ? null : parameters[1];
            if (mode == 1) {
              final key = decisionKey(command.sourceLocator, null);
              final decision = resolvedDecisions[key];
              if (decision != null) usedDecisions.add(key);
              final retainedInactive = decision?.decision ==
                  LiteralDependencyDisposition.excludeStudy;
              dependencies.add(LiteralMapDependency(
                  sourceMapId: id,
                  targetSourceMapId: null,
                  locator: command.sourceLocator,
                  kind: LiteralDependencyKind.dynamicTransfer,
                  decision: decision?.decision));
              diagnostic(
                  retainedInactive
                      ? 'literal.dependency.dynamic_inactive'
                      : 'literal.dependency.dynamic',
                  !retainedInactive,
                  command.sourceLocator.toJson(),
                  retainedInactive
                      ? 'The variable transfer is preserved inactive without a fabricated destination'
                      : 'A variable transfer cannot be resolved as a static dependency');
              continue;
            }
            if (mode != 0 ||
                rawTarget is! int ||
                rawTarget <= 0 ||
                rawTarget > 2147483647) {
              dependencies.add(LiteralMapDependency(
                  sourceMapId: id,
                  targetSourceMapId: null,
                  locator: command.sourceLocator,
                  kind: LiteralDependencyKind.invalidTransfer,
                  decision: null));
              diagnostic(
                  'literal.dependency.invalid',
                  true,
                  command.sourceLocator.toJson(),
                  'A direct transfer requires a valid literal map identity');
              continue;
            }
            final key = decisionKey(command.sourceLocator, rawTarget);
            final decision = resolvedDecisions[key];
            if (decision != null) usedDecisions.add(key);
            dependencies.add(LiteralMapDependency(
                sourceMapId: id,
                targetSourceMapId: rawTarget,
                locator: command.sourceLocator,
                kind: LiteralDependencyKind.staticTransfer,
                decision: decision?.decision));
            if (decision?.decision == LiteralDependencyDisposition.block) {
              diagnostic(
                  'literal.dependency.blocked',
                  true,
                  command.sourceLocator.toJson(),
                  'Dependency explicitly blocked');
            } else if (decision?.decision ==
                LiteralDependencyDisposition.excludeStudy) {
              diagnostic(
                  'literal.dependency.excluded_study',
                  false,
                  command.sourceLocator.toJson(),
                  'Transfer is excluded from this study and remains inactive');
            } else if (decision?.decision ==
                LiteralDependencyDisposition.include) {
              if (sourceMap(rawTarget) == null) {
                diagnostic(
                    'literal.dependency.renormalize',
                    true,
                    command.sourceLocator.toJson(),
                    'Included destination requires a new normalization selection');
              } else if (closure.add(rawTarget)) {
                if (closure.length * 2 > limits.maxMutations) {
                  throw const NativeWriteException('literal.quota.selection',
                      'Included map mutation budget exceeded');
                }
                queue.add(rawTarget);
              }
            }
          }
        }
      }
      if (hasEvents) {
        diagnostic(
            'literal.events.deferred',
            false,
            {'mapId': id, 'file': mapFile(map)},
            'Original event data is preserved; native event conversion is deferred');
      }
    }
    for (final entry in resolvedDecisions.entries) {
      if (!usedDecisions.contains(entry.key)) {
        diagnostic(
            'literal.dependency.decision',
            true,
            entry.value.locator.toJson(),
            'Dependency decision does not name an inspected direct transfer');
      }
    }
    for (final dependency in dependencies) {
      if (dependency.kind == LiteralDependencyKind.staticTransfer &&
          dependency.decision == null &&
          !closure.contains(dependency.targetSourceMapId)) {
        diagnostic(
            'literal.dependency.unresolved',
            true,
            dependency.locator.toJson(),
            'A destination outside the selection requires an explicit decision');
      }
    }
  }

  String mapFile(SourceMapData map) => mapPaths.putIfAbsent(
      map.sourceFileId,
      () => source.snapshot.entries
          .firstWhere((entry) => entry.fileId == map.sourceFileId)
          .relativePath);

  void inspectMaps() {
    var cellCount = 0;
    final ids = closure.toList()..sort();
    for (final id in ids) {
      cancellation?.check();
      final map = sourceMap(id)!;
      if (map.tileWidth != 32 ||
          map.tileHeight != 32 ||
          map.width <= 0 ||
          map.height <= 0 ||
          map.width > limits.maxMapCells ~/ map.height) {
        diagnostic(
            'literal.map.geometry',
            true,
            {'file': mapFile(map), 'mapId': id},
            'A bounded 32px map is required');
        continue;
      }
      final count = map.width * map.height;
      cellCount += count * 3;
      if (cellCount > limits.maxMapCells ||
          cellCount > limits.jsonLimits.maxNodes) {
        throw const NativeWriteException('literal.quota.cells',
            'Aggregate literal layer cell budget exceeded');
      }
      final layers = map.layers.toList()
        ..sort((a, b) => a.sourceZ.compareTo(b.sourceZ));
      if (layers.length != 3 ||
          layers[0].sourceZ != 0 ||
          layers[1].sourceZ != 1 ||
          layers[2].sourceZ != 2) {
        diagnostic(
            'literal.map.layers',
            true,
            {'file': mapFile(map), 'mapId': id},
            'The three original source Z layers are required');
        continue;
      }
      final cells = <List<int>>[];
      final used = usedTiles.putIfAbsent(map.sourceTilesetId, () => <int>{});
      for (final layer in layers) {
        final values = layer.cells;
        if (values.length != count) {
          diagnostic(
              'literal.map.layers',
              true,
              {'file': mapFile(map), 'mapId': id, 'sourceZ': layer.sourceZ},
              'Layer cells must match the original map geometry');
          continue;
        }
        cells.add(values);
        for (var index = 0; index < values.length; index++) {
          final tile = values[index];
          if (tile == 0) continue;
          if (tile < 48) {
            diagnostic(
                'literal.tile.reserved',
                true,
                {
                  'file': mapFile(map),
                  'mapId': id,
                  'sourceZ': layer.sourceZ,
                  'tileId': tile,
                  'x': index % map.width,
                  'y': index ~/ map.width
                },
                'Reserved tile identity is not a regular tile',
                key: 'reserved:$id:${layer.sourceZ}:$tile');
          } else {
            used.add(tile);
          }
        }
      }
      inputs[id] = _LiteralMapInput(map, layers, cells);
      mapIds[id] = nativeIdentity('map', source.mapIdentity(id));
    }
    if (closure.length * 2 + usedTiles.length > limits.maxMutations) {
      throw const NativeWriteException(
          'literal.quota.mutations', 'Literal native mutation budget exceeded');
    }
  }

  void inspectAtlases() {
    var logicalBytes = 0;
    final hashes = <Sha256Hash>{};
    final ids = usedTiles.keys.toList()..sort();
    for (final id in ids) {
      final tileset = sourceTileset(id);
      final images =
          tileset?.images.where((item) => item.role == 'tileset').toList();
      final entry = images?.length == 1 ? images!.single.sourceFile : null;
      if (tileset == null ||
          images?.length != 1 ||
          images!.single.state != 'resolved' ||
          entry == null ||
          entry.kind != SourceNodeKind.file ||
          entry.sha256 == null ||
          entry.format != 'raster' ||
          !entry.relativePath.toLowerCase().endsWith('.png') ||
          !source.snapshot.entries.any((item) =>
              item.fileId == entry.fileId &&
              canonicalJsonOf(item.toJson()) ==
                  canonicalJsonOf(entry.toJson()))) {
        diagnostic('literal.tileset.image', true, {'sourceTilesetId': id},
            'An admitted unique source PNG atlas is required');
        continue;
      }
      logicalBytes += entry.byteLength;
      if (entry.byteLength > limits.maxArtifactBytes ||
          logicalBytes > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException('literal.quota.artifact',
            'Source image import byte budget exceeded');
      }
      atlasEntries[id] = entry;
      hashes.add(entry.sha256!);
      if (hashes.length > limits.maxArtifacts) {
        throw const NativeWriteException('literal.quota.artifact',
            'Unique source image artifact budget exceeded');
      }
      tilesetIds[id] = nativeIdentity('tileset', tileset.identity);
    }
  }

  Future<void> readAtlases() async {
    final byFile = <ConverterId, NativeArtifact>{};
    var pixels = 0;
    for (final entry in atlasEntries.entries) {
      cancellation?.check();
      final file = entry.value;
      var artifact = byFile[file.fileId];
      if (artifact == null) {
        final bytes = await files.read(file.fileId);
        cancellation?.check();
        if (bytes.length != file.byteLength ||
            bytes.length > limits.maxArtifactBytes) {
          throw const NativeWriteException('literal.source.length',
              'Source PNG length differs from its admitted snapshot entry');
        }
        artifact = NativeArtifact(
            bytes: bytes, expectedSha256: file.sha256, limits: limits);
        byFile[file.fileId] = artifact;
      }
      final size = const NativePngValidator()
          .headerDimensions(artifact.bytes, limits: limits);
      if (size.$1 != 256 || size.$2 % 32 != 0) {
        diagnostic(
            'literal.tileset.geometry',
            true,
            {'file': file.relativePath, 'sourceTilesetId': entry.key},
            'An XP regular atlas must be 256px wide with complete 32px rows');
        continue;
      }
      pixels += size.$1 * size.$2;
      if (pixels > limits.maxTotalImagePixels) {
        throw const NativeWriteException('literal.quota.image',
            'Aggregate logical source image pixel budget exceeded');
      }
      artifacts.putIfAbsent(artifact.handle, () => artifact!);
      if (artifacts.length > limits.maxArtifacts) {
        throw const NativeWriteException('literal.quota.artifact',
            'Unique source image artifact budget exceeded');
      }
      atlasArtifacts[entry.key] = artifacts[artifact.handle]!;
      dimensions[entry.key] = size;
      final tileset = sourceTileset(entry.key)!;
      final invalidTiles = <int>{};
      for (final tile in usedTiles[entry.key]!) {
        final localId = tile - 384;
        if (tile >= 384 && localId >= 8 * (size.$2 ~/ 32)) {
          invalidTiles.add(tile);
        } else if (tile >= tileset.passages.cellCount ||
            tile >= tileset.priorities.cellCount ||
            tile >= tileset.terrainTags.cellCount) {
          diagnostic(
              'literal.tileset.metadata',
              true,
              {
                'file': tileset.locator.file,
                'sourceTilesetId': entry.key,
                'tileId': tile
              },
              'Original tile metadata must contain every used tile identity');
        }
      }
      if (invalidTiles.isNotEmpty) {
        for (final input in inputs.values
            .where((item) => item.map.sourceTilesetId == entry.key)) {
          for (var z = 0; z < input.cells.length; z++) {
            final values = input.cells[z];
            for (var index = 0; index < values.length; index++) {
              final tile = values[index];
              if (!invalidTiles.contains(tile)) continue;
              final key = 'bounds:${input.map.sourceMapId}:$z:$tile';
              if (diagnosticKeys.contains(key)) continue;
              diagnostic(
                  'literal.tile.out_of_bounds',
                  true,
                  {
                    'file': mapFile(input.map),
                    'mapId': input.map.sourceMapId,
                    'sourceZ': z,
                    'tileId': tile,
                    'x': index % input.map.width,
                    'y': index ~/ input.map.width,
                  },
                  'Regular tile crop exceeds its original source image',
                  key: key);
            }
          }
        }
      }
    }
    if (blocked) return;
    for (final artifact in artifacts.values) {
      cancellation?.check();
      const NativePngValidator().validate(artifact.bytes, limits: limits);
    }
  }

  Future<void> readAutotiles() async {
    final slots = <(int, int)>[
      for (final id in usedTiles.keys.toList()..sort())
        for (final slot
            in (usedTiles[id]!
                .where((tile) => tile >= 48 && tile < 384)
                .map((tile) => tile ~/ 48 - 1)
                .toSet()
                .toList()
              ..sort()))
          (id, slot),
    ];
    if (slots.isEmpty) return;
    if (closure.length * 2 + usedTiles.length + slots.length * 2 >
        limits.maxMutations) {
      throw const NativeWriteException('literal.quota.mutations',
          'Autotile import and timeline mutation budget exceeded');
    }
    const composer = LiteralAutotileComposer();
    final profile = await composer.inspectProfile(
        snapshot: source.snapshot,
        files: files,
        limits: limits,
        cancellation: cancellation);
    var pixels =
        dimensions.values.fold<int>(0, (sum, size) => sum + size.$1 * size.$2);
    var logicalBytes = atlasArtifacts.values
        .fold<int>(0, (sum, artifact) => sum + artifact.bytes.length);
    for (final slot in slots) {
      cancellation?.check();
      final remainingPixels = limits.maxTotalImagePixels - pixels;
      final remainingBytes = limits.maxTotalArtifactBytes - logicalBytes;
      if (remainingPixels <= 0 ||
          remainingBytes <= 0 ||
          artifacts.length >= limits.maxArtifacts) {
        throw const NativeWriteException('literal.quota.autotiles',
            'Aggregate source and generated atlas budget exceeded');
      }
      try {
        final composition = await composer.compose(
            source: source,
            files: files,
            sourceTilesetId: slot.$1,
            autotileSlot: slot.$2,
            profile: profile,
            limits: NativeWriteLimits(
                maxArtifacts: limits.maxArtifacts,
                maxMutations: limits.maxMutations,
                maxArtifactBytes: limits.maxArtifactBytes,
                maxTotalArtifactBytes: remainingBytes,
                maxImagePixels: limits.maxImagePixels < remainingPixels
                    ? limits.maxImagePixels
                    : remainingPixels,
                maxTotalImagePixels: remainingPixels,
                maxMapCells: limits.maxMapCells,
                jsonLimits: limits.jsonLimits),
            cancellation: cancellation);
        pixels += composition.sourcePixelWidth * composition.sourcePixelHeight +
            composition.pixelWidth * composition.pixelHeight;
        final sourceEntry = source.snapshot.entries
            .singleWhere((entry) => entry.fileId == composition.sourceFileId);
        logicalBytes +=
            sourceEntry.byteLength + composition.artifact.bytes.length;
        if (pixels > limits.maxTotalImagePixels ||
            logicalBytes > limits.maxTotalArtifactBytes) {
          throw const NativeWriteException('literal.quota.autotiles',
              'Aggregate source and generated atlas budget exceeded');
        }
        if (composition.degraded) {
          diagnostic(
              'literal.autotile.animation_unverified',
              !allowFirstFrameAutotiles,
              {
                'file': sourceEntry.relativePath,
                'sourceTilesetId': slot.$1,
                'autotileSlot': slot.$2,
                'firstFrameOnly': true,
                'sourceFrameCount': composition.sourceFrameCount,
              },
              allowFirstFrameAutotiles
                  ? 'Explicit study choice retains all frames but displays only the first; animation is unverified'
                  : 'Unverified animation requires an explicit first-frame study choice');
        }
        for (final entry in composition.diagnostics) {
          diagnostic(
              entry.code,
              false,
              entry.locator?.toJson() ?? {'file': sourceEntry.relativePath},
              entry.message);
        }
        autotiles[slot] = composition;
        artifacts.putIfAbsent(
            composition.artifact.handle, () => composition.artifact);
      } on LiteralAutotileFailure catch (error) {
        diagnostic(
            error.code,
            true,
            {
              ...?error.locator?.toJson(),
              'sourceTilesetId': slot.$1,
              'autotileSlot': slot.$2,
            },
            error.message);
      }
    }
  }

  void composeMaps() {
    final palettes = <int, List<TileLayerPaletteEntry>>{};
    final paletteCells = <int, Map<int, int>>{};
    for (final id in usedTiles.keys.toList()..sort()) {
      final tileset = sourceTileset(id)!;
      final tileIds = usedTiles[id]!.toList()..sort();
      final atlas = atlasArtifacts[id]!;
      final nativeId = tilesetIds[id]!;
      palettes[id] = List.unmodifiable([
        for (final tile in tileIds)
          tile >= 384
              ? TileLayerPaletteEntry(
                  tilesetId: nativeId, localTileId: tile - 384)
              : TileLayerPaletteEntry(
                  tilesetId: autotiles[(id, tile ~/ 48 - 1)]!.nativeTilesetId,
                  localTileId: tile % 48),
      ]);
      paletteCells[id] = {
        for (var index = 0; index < tileIds.length; index++)
          tileIds[index]: index + 1,
      };
      for (var index = 0; index < tileIds.length; index++) {
        final tile = tileIds[index];
        final autotile = tile < 384 ? autotiles[(id, tile ~/ 48 - 1)]! : null;
        final localId = autotile == null ? tile - 384 : tile % 48;
        crops.add(LiteralTileCrop(
            sourceTilesetId: id,
            sourceTileId: tile,
            nativeTilesetId: autotile?.nativeTilesetId ?? nativeId,
            nativeLocalTileId: localId,
            paletteCell: index + 1,
            imageFileId: autotile?.sourceFileId ?? atlasEntries[id]!.fileId,
            imageSha256: autotile?.sourceFileHash ?? atlas.rawSha256,
            nativeImageSha256: autotile?.artifact.rawSha256,
            autotileSlot: autotile?.autotileSlot,
            autotileVariant: autotile == null ? null : tile % 48,
            x: (localId % 8) * 32,
            y: (localId ~/ 8) * 32,
            passage: tileset.passages.valueAt(tile, 0, 0),
            priority: tileset.priorities.valueAt(tile, 0, 0),
            terrainTag: tileset.terrainTags.valueAt(tile, 0, 0)));
      }
      mutations.add(NativeMutation(
          operationId: ConverterId('literal-import-$nativeId'),
          actionId: 'tileset.import_image',
          sourceEntityIds: [tileset.identity, atlasEntries[id]!.fileId],
          targetEntityIds: [
            ConverterId(nativeId),
            ConverterId('image_$nativeId')
          ],
          parameters: {
            'artifactHandle': atlas.handle,
            'tilesetId': nativeId,
            'name': tileset.name.trim().isEmpty
                ? 'Tileset $id'
                : tileset.name.trim(),
            'tileWidth': 32,
            'tileHeight': 32
          },
          limits: limits));
      for (final autotile
          in autotiles.values.where((entry) => entry.sourceTilesetId == id)) {
        final autoId = autotile.nativeTilesetId;
        final autoName =
            '${tileset.name.trim().isEmpty ? 'Tileset $id' : tileset.name.trim()} · Autotile ${autotile.autotileSlot + 1}';
        final sourceIds = [tileset.identity, autotile.sourceFileId];
        mutations.add(NativeMutation(
            operationId: ConverterId('literal-import-$autoId'),
            actionId: 'tileset.import_image',
            sourceEntityIds: sourceIds,
            targetEntityIds: [
              ConverterId(autoId),
              ConverterId('image_$autoId')
            ],
            parameters: {
              'artifactHandle': autotile.artifact.handle,
              'tilesetId': autoId,
              'name': autoName,
              'tileWidth': 32,
              'tileHeight': 32,
            },
            limits: limits));
        if (autotile.tileAnimations.isNotEmpty) {
          mutations.add(NativeMutation(
              operationId: ConverterId('literal-animation-$autoId'),
              actionId: 'tileset.upsert',
              sourceEntityIds: sourceIds,
              targetEntityIds: [ConverterId(autoId)],
              parameters: {
                'tileset': ProjectTilesetEntry(
                        id: autoId,
                        name: autoName,
                        relativePath: 'assets/studio/$autoId.png',
                        source: ProjectRegularAtlasTilesetSource(
                            assetId: 'image_$autoId',
                            pixelWidth: autotile.pixelWidth,
                            pixelHeight: autotile.pixelHeight,
                            tileWidth: 32,
                            tileHeight: 32,
                            tileAnimations: autotile.tileAnimations))
                    .toJson(),
              },
              limits: limits));
        }
      }
    }
    for (final id in inputs.keys.toList()..sort()) {
      cancellation?.check();
      final input = inputs[id]!;
      final map = input.map;
      final nativeId = mapIds[id]!;
      final layers = <MapLayer>[];
      for (var z = 0; z < 3; z++) {
        final layerId = '${nativeId}_z$z';
        final cells = List<int>.unmodifiable(input.cells[z].map((tile) =>
            tile == 0 ? 0 : paletteCells[map.sourceTilesetId]![tile]!));
        layers.add(MapLayer.tile(
            id: layerId,
            name: 'Source Z $z',
            palette: palettes[map.sourceTilesetId]!,
            cells: cells));
        provenance.add(LiteralLayerProvenance(
            sourceMapId: id,
            sourceFileId: map.sourceFileId,
            sourceZ: z,
            nativeLayerId: layerId,
            cellCount: cells.length,
            sourceLayerHash:
                canonicalHashOf(input.cells[z], limits: limits.jsonLimits),
            nativeCellsHash:
                canonicalHashOf(cells, limits: limits.jsonLimits)));
      }
      final native = MapData(
          id: nativeId,
          name: map.name.trim().isEmpty ? 'Map $id' : map.name.trim(),
          size: GridSize(width: map.width, height: map.height),
          version: ProjectVersion.v8,
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: List.unmodifiable(layers.reversed));
      nativeMaps[id] = native;
      mutations.add(NativeMutation(
          operationId: ConverterId('literal-create-$nativeId'),
          actionId: 'map.create',
          sourceEntityIds: [source.mapIdentity(id)],
          targetEntityIds: [ConverterId(nativeId)],
          parameters: {
            'mapId': nativeId,
            'name': native.name,
            'width': map.width,
            'height': map.height,
            'tilesetId': tilesetIds[map.sourceTilesetId]!
          },
          limits: limits));
      mutations.add(NativeMutation(
          operationId: ConverterId('literal-save-$nativeId'),
          actionId: 'map.save',
          sourceEntityIds: [source.mapIdentity(id)],
          targetEntityIds: [ConverterId(nativeId)],
          parameters: {'map': native.toJson()},
          limits: limits));
    }
    diagnostic('literal.gameplay.deferred', false, const {},
        'Source passages, priorities and terrain tags are preserved without gameplay certification');
  }

  LiteralTileComposition finish() {
    final included = closure.where((id) => !selected.contains(id)).toList()
      ..sort();
    final sortedDecisions = decisions.toList()
      ..sort((a, b) => a.canonicalHash.value.compareTo(b.canonicalHash.value));
    final artifactList = artifacts.values.toList()
      ..sort((a, b) => a.handle.compareTo(b.handle));
    final record = {
      'kind': 'literalTileComposition',
      'version': 1,
      'sourceSnapshotHash': snapshotHash.value,
      'logicalProjectNamespace': source.snapshot.logicalProjectNamespace.value,
      'normalizedSourceHash': sourceHash.value,
      'selectionHash': selectionHash.value,
      'selectedSourceMapIds': selected,
      'includedSourceMapIds': included,
      'mapIds': {
        for (final entry in mapIds.entries) '${entry.key}': entry.value
      },
      'tilesetIds': {
        for (final entry in tilesetIds.entries) '${entry.key}': entry.value
      },
      'nativeMapHashes': {
        for (final entry in nativeMaps.entries)
          '${entry.key}':
              canonicalHashOf(entry.value.toJson(), limits: limits.jsonLimits)
                  .value
      },
      'artifacts': [
        for (final artifact in artifactList)
          {'handle': artifact.handle, 'rawSha256': artifact.rawSha256.value}
      ],
      'decisions': sortedDecisions.map((item) => item.toJson()).toList(),
      'crops': crops.map((item) => item.toJson()).toList(),
      'autotiles': [
        for (final item in autotiles.values)
          {
            'sourceTilesetId': item.sourceTilesetId,
            'autotileSlot': item.autotileSlot,
            'nativeTilesetId': item.nativeTilesetId,
            'artifactHandle': item.artifact.handle,
            'sourceFileId': item.sourceFileId.value,
            'sourceFileHash': item.sourceFileHash.value,
            'nativeImageSha256': item.artifact.rawSha256.value,
            'compositionHash': item.compositionHash.value,
            'provenance': item.provenance,
            'firstFrameOnly': item.firstFrameOnly,
            'degraded': item.degraded,
            'animationVerified': item.animationVerified,
            'tileAnimations':
                item.tileAnimations.map((frame) => frame.toJson()).toList(),
          }
      ],
      'allowFirstFrameAutotiles': allowFirstFrameAutotiles,
      'layerProvenance': provenance.map((item) => item.toJson()).toList(),
      'dependencies': dependencies.map((item) => item.toJson()).toList(),
      'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
      'playableCertified': false,
      'sourceArchiveHash': source.archive.canonicalHash.value,
    };
    final hash = canonicalHashOf(record, limits: limits.jsonLimits);
    final draft = blocked
        ? null
        : NativeProjectDraft(
            source: source,
            projectName: projectName,
            parentPath: parentPath,
            folderName: folderName,
            sourceRootPath: sourceRootPath,
            mapIds: mapIds,
            artifacts: artifactList,
            mutations: mutations,
            compositionEvidence: {
              'kind': 'literalTileComposition',
              'version': 1,
              'compositionHash': hash.value,
              'composition': record
            },
            limits: limits);
    return LiteralTileComposition._(
        draft: draft,
        selectionHash: selectionHash,
        compositionHash: hash,
        mapIds: mapIds,
        tilesetIds: tilesetIds,
        nativeMaps: nativeMaps,
        selectedSourceMapIds: selected,
        includedSourceMapIds: included,
        crops: crops,
        autotiles: autotiles.values.toList(),
        layerProvenance: provenance,
        dependencies: dependencies,
        diagnostics: diagnostics,
        creationLimits: limits,
        sourceReads: files.reads.values.toList());
  }

  String nativeIdentity(String kind, ConverterId identity) =>
      '${kind}_${identity.value.substring(3, 59)}';

  void diagnostic(String code, bool blocksPlanning,
      Map<String, Object?> locator, String message,
      {String? key}) {
    final identity = key ?? canonicalJsonOf({'code': code, 'locator': locator});
    if (!diagnosticKeys.add(identity)) return;
    diagnosticNodes += 12 + locator.length * 2;
    diagnosticText +=
        code.length + message.length + canonicalJsonOf(locator).length;
    if (diagnosticNodes > limits.jsonLimits.maxNodes ||
        diagnosticText > limits.jsonLimits.maxTextCodeUnits) {
      throw const NativeWriteException(
          'literal.quota.diagnostics', 'Literal diagnostic budget exceeded');
    }
    diagnostics.add(LiteralCompositionDiagnostic(
        code: code,
        blocksPlanning: blocksPlanning,
        locator: locator,
        message: message));
  }
}

Object? _literalFreezeJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.unmodifiable(
        value.map((key, child) => MapEntry(key, _literalFreezeJson(child))));
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_literalFreezeJson));
  }
  return value;
}
