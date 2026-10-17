part of '../avelune_converter_core.dart';

final class SourceNormalizationLimits {
  const SourceNormalizationLimits({
    this.maxMaps = 4096,
    this.maxConnections = 16384,
    this.maxTotalCells = 16777216,
    this.maxEvents = 100000,
    this.maxCommands = 500000,
    this.maxParameterNodes = 1000000,
    this.maxDiagnostics = 10000,
    this.maxTotalBytes = 134217728,
    this.maxMetadataCells = 1048576,
    this.maxTotalIrNodes = 8000000,
    this.maxTotalTextCodeUnits = 33554432,
    this.maxDiagnosticTextCodeUnits = 1048576,
  });

  final int maxMaps;
  final int maxConnections;
  final int maxTotalCells;
  final int maxEvents;
  final int maxCommands;
  final int maxParameterNodes;
  final int maxDiagnostics;
  final int maxTotalBytes;
  final int maxMetadataCells;
  final int maxTotalIrNodes;
  final int maxTotalTextCodeUnits;
  final int maxDiagnosticTextCodeUnits;

  void _validate() {
    for (final pair in [
      (maxMaps, 100000),
      (maxConnections, 65536),
      (maxTotalCells, 67108864),
      (maxEvents, 1000000),
      (maxCommands, 2000000),
      (maxParameterNodes, 4000000),
      (maxDiagnostics, 100000),
      (maxTotalBytes, 268435456),
      (maxMetadataCells, 8388608),
      (maxTotalIrNodes, 16000000),
      (maxTotalTextCodeUnits, 67108864),
      (maxDiagnosticTextCodeUnits, 4194304),
    ]) {
      if (pair.$1 < 1 || pair.$1 > pair.$2) {
        throw ArgumentError(
            'Normalization limits must be positive and bounded');
      }
    }
  }
}

final class SourceNormalizationDiagnostic {
  const SourceNormalizationDiagnostic({
    required this.code,
    required this.blocksPlanning,
    required this.locator,
    required this.message,
    this.relatedPaths = const [],
  });

  final String code;
  final bool blocksPlanning;
  final SourceLocator locator;
  final String message;
  final List<String> relatedPaths;

  Map<String, Object?> toJson() => {
        'code': code,
        'blocksPlanning': blocksPlanning,
        'locator': locator.toJson(),
        'message': message,
        'relatedPaths': relatedPaths,
      };
}

final class NormalizedMapInfo {
  const NormalizedMapInfo({
    required this.sourceMapId,
    required this.identity,
    required this.name,
    required this.parentSourceMapId,
    required this.order,
    required this.rawDataRef,
    required this.locator,
    this.expanded,
    this.scrollX,
    this.scrollY,
  });

  final int sourceMapId;
  final ConverterId identity;
  final String name;
  final int parentSourceMapId;
  final int order;
  final bool? expanded;
  final int? scrollX;
  final int? scrollY;
  final SourcePreservedData rawDataRef;
  final SourceLocator locator;

  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'identity': identity.value,
        'name': name,
        'parentSourceMapId': parentSourceMapId,
        'order': order,
        'expanded': expanded,
        'scrollX': scrollX,
        'scrollY': scrollY,
        'rawDataRef': rawDataRef.id.value,
        'locator': locator.toJson(),
      };
}

final class SourceImageBinding {
  SourceImageBinding({
    required this.expectedReferencePath,
    required this.sourceRelativePath,
    required this.sourceSha256,
  }) {
    validateSourceRelativePath(expectedReferencePath);
    validateSourceRelativePath(sourceRelativePath);
    final expected = sourcePathCollisionKey(expectedReferencePath);
    final source = sourcePathCollisionKey(sourceRelativePath);
    _require(
        expectedReferencePath.length <= 4096 &&
            sourceRelativePath.length <= 4096 &&
            RegExp(r'^graphics/(tilesets|autotiles)/[^/]+$')
                .hasMatch(expected) &&
            RegExp(r'^graphics/(tilesets|autotiles)/[^/]+\.(png|bmp|jpe?g)$')
                .hasMatch(source) &&
            expected.substring(0, expected.lastIndexOf('/')) ==
                source.substring(0, source.lastIndexOf('/')) &&
            RegExp(r'\.(png|bmp|jpe?g)$').hasMatch(source),
        'normalization.image_binding.invalid',
        expectedReferencePath,
        'An atlas image binding requires a source image in the same folder');
  }

  factory SourceImageBinding.fromJson(Object? input) {
    _require(
        input is Map<String, Object?> &&
            input.length == 5 &&
            input['kind'] == 'sourceImageBinding' &&
            input['version'] == 1 &&
            input['expectedReferencePath'] is String &&
            input['sourceRelativePath'] is String &&
            input['sourceSha256'] is String,
        'normalization.image_binding.invalid',
        r'$',
        'Invalid closed atlas image binding');
    final json = input as Map<String, Object?>;
    return SourceImageBinding(
        expectedReferencePath: json['expectedReferencePath'] as String,
        sourceRelativePath: json['sourceRelativePath'] as String,
        sourceSha256: Sha256Hash(json['sourceSha256'] as String));
  }

  static List<SourceImageBinding> canonicalize(
      Iterable<SourceImageBinding> bindings) {
    final result = <SourceImageBinding>[];
    final references = <String>{};
    for (final binding in bindings) {
      _require(
          result.length < 256 &&
              references
                  .add(sourcePathCollisionKey(binding.expectedReferencePath)),
          'normalization.image_binding.invalid',
          binding.expectedReferencePath,
          'Atlas image bindings must be unique and bounded');
      result.add(binding);
    }
    result.sort((a, b) => sourcePathCollisionKey(a.expectedReferencePath)
        .compareTo(sourcePathCollisionKey(b.expectedReferencePath)));
    return List.unmodifiable(result);
  }

  final String expectedReferencePath;
  final String sourceRelativePath;
  final Sha256Hash sourceSha256;

  Map<String, Object?> toJson() => Map.unmodifiable({
        'kind': 'sourceImageBinding',
        'version': 1,
        'expectedReferencePath': expectedReferencePath,
        'sourceRelativePath': sourceRelativePath,
        'sourceSha256': sourceSha256.value,
      });
}

final class NormalizedMediaReference {
  const NormalizedMediaReference({
    required this.ownerId,
    required this.role,
    required this.sourceName,
    required this.locator,
    required this.state,
    this.sourceFile,
    this.slot,
    this.sourceTileId,
    this.appliedImageBinding,
  });

  final ConverterId ownerId;
  final String role;
  final int? slot;
  final int? sourceTileId;
  final String sourceName;
  final SourceLocator locator;
  final String state;
  final SourceFileEntry? sourceFile;
  final SourceImageBinding? appliedImageBinding;

  Map<String, Object?> toJson() => {
        'ownerId': ownerId.value,
        'role': role,
        'slot': slot,
        'sourceTileId': sourceTileId,
        'sourceName': sourceName,
        'locator': locator.toJson(),
        'state': state,
        'sourceFile': sourceFile?.toJson(),
        if (appliedImageBinding != null)
          'appliedImageBinding': appliedImageBinding!.toJson(),
      };
}

final class NormalizedTileset {
  const NormalizedTileset({
    required this.sourceTilesetId,
    required this.identity,
    required this.name,
    required this.images,
    required this.passages,
    required this.priorities,
    required this.terrainTags,
    required this.rawDataRef,
    required this.locator,
  });

  final int sourceTilesetId;
  final ConverterId identity;
  final String name;
  final List<NormalizedMediaReference> images;
  final SourceTable passages;
  final SourceTable priorities;
  final SourceTable terrainTags;
  final SourcePreservedData rawDataRef;
  final SourceLocator locator;

  Map<String, Object?> toJson() => {
        'sourceTilesetId': sourceTilesetId,
        'identity': identity.value,
        'name': name,
        'images': images.map((image) => image.toJson()).toList(),
        'passages': _normalizedTableJson(passages),
        'priorities': _normalizedTableJson(priorities),
        'terrainTags': _normalizedTableJson(terrainTags),
        'rawDataRef': rawDataRef.id.value,
        'locator': locator.toJson(),
      };
}

Map<String, Object?> _normalizedTableJson(SourceTable table) => {
      'dimensions': table.dimensions,
      'xSize': table.xSize,
      'ySize': table.ySize,
      'zSize': table.zSize,
      'cells': [
        for (var z = 0; z < table.zSize; z++)
          for (var y = 0; y < table.ySize; y++)
            for (var x = 0; x < table.xSize; x++) table.valueAt(x, y, z),
      ],
    };

final class NormalizedPreservedParameter {
  const NormalizedPreservedParameter({
    required this.locator,
    required this.parameterIndex,
    required this.graphPath,
    required this.rawDataRef,
  });

  final SourceLocator locator;
  final int parameterIndex;
  final String graphPath;
  final SourcePreservedData rawDataRef;

  Map<String, Object?> toJson() => {
        'locator': locator.toJson(),
        'parameterIndex': parameterIndex,
        'graphPath': graphPath,
        'rawDataRef': rawDataRef.id.value,
        'status': 'preservedOnly',
      };
}

enum SourceConnectionDirection {
  north,
  east,
  south,
  west;

  String get sourceCode => switch (this) {
        north => 'N',
        east => 'E',
        south => 'S',
        west => 'W',
      };

  SourceConnectionDirection get opposite => switch (this) {
        north => south,
        east => west,
        south => north,
        west => east,
      };
}

enum SourceConnectionsState { notRequested, missing, extracted, invalid }

final class NormalizedMapConnection {
  const NormalizedMapConnection._({
    required this.identity,
    required this.sourceRowIndex,
    required this.sourceMapId,
    required this.sourceDirection,
    required this.sourceOffset,
    required this.targetSourceMapId,
    required this.targetDirection,
    required this.targetOffset,
    required this.rawDataRef,
    required this.locator,
  });

  final ConverterId identity;
  final int sourceRowIndex;
  final int sourceMapId;
  final SourceConnectionDirection sourceDirection;
  final int sourceOffset;
  final int targetSourceMapId;
  final SourceConnectionDirection targetDirection;
  final int targetOffset;
  final SourcePreservedData rawDataRef;
  final SourceLocator locator;
  int get nativeOffset => sourceOffset - targetOffset;

  Map<String, Object?> toJson() => {
        'identity': identity.value,
        'sourceRowIndex': sourceRowIndex,
        'sourceMapId': sourceMapId,
        'sourceDirection': sourceDirection.sourceCode,
        'sourceOffset': sourceOffset,
        'targetSourceMapId': targetSourceMapId,
        'targetDirection': targetDirection.sourceCode,
        'targetOffset': targetOffset,
        'nativeOffset': nativeOffset,
        'rawDataRef': rawDataRef.id.value,
        'locator': locator.toJson(),
      };
}

final class NormalizedSourceProject {
  NormalizedSourceProject._({
    required this.snapshot,
    required this.sourceProfileId,
    required List<SourceMapIr> maps,
    required List<NormalizedMapConnection> connections,
    required this.connectionsState,
    required this.connectionsFileId,
    required List<NormalizedMapInfo> mapHierarchy,
    required List<NormalizedTileset> tilesets,
    required List<NormalizedMediaReference> eventImages,
    required List<SourceNormalizationDiagnostic> diagnostics,
    required List<NormalizedPreservedParameter> preservedParameterRefs,
    required List<int> selectedSourceMapIds,
    required List<int> unprocessedSourceMapIds,
    required this.archive,
  })  : maps = List.unmodifiable(maps),
        connections = List.unmodifiable(connections),
        mapHierarchy = List.unmodifiable(mapHierarchy),
        tilesets = List.unmodifiable(tilesets),
        eventImages = List.unmodifiable(eventImages),
        preservedParameterRefs = List.unmodifiable(preservedParameterRefs),
        selectedSourceMapIds = List.unmodifiable(selectedSourceMapIds),
        unprocessedSourceMapIds = List.unmodifiable(unprocessedSourceMapIds),
        diagnostics = List.unmodifiable(diagnostics) {
    if (!archive.isSealed) {
      throw StateError(
          'A normalized source project requires a sealed archive.');
    }
  }

  final SourceSnapshot snapshot;
  final ConverterId sourceProfileId;
  final List<SourceMapIr> maps;
  final List<NormalizedMapConnection> connections;
  final SourceConnectionsState connectionsState;
  final ConverterId? connectionsFileId;
  bool get connectionsExtracted =>
      connectionsState == SourceConnectionsState.extracted;
  final List<NormalizedMapInfo> mapHierarchy;
  final List<NormalizedTileset> tilesets;
  final List<NormalizedMediaReference> eventImages;
  final List<SourceNormalizationDiagnostic> diagnostics;
  final List<NormalizedPreservedParameter> preservedParameterRefs;
  final SourceArchive archive;
  final List<int> selectedSourceMapIds;
  final List<int> unprocessedSourceMapIds;

  bool get canPlan =>
      maps.isNotEmpty &&
      unprocessedSourceMapIds.isEmpty &&
      !diagnostics.any((item) => item.blocksPlanning);

  ConverterId mapIdentity(int sourceMapId) => SourceIdentity(
        snapshot.logicalProjectNamespace,
        ConverterId('rmxp-map'),
        sourceMapId,
      ).stableId;

  ConverterId eventIdentity(int sourceMapId, int sourceEventId) =>
      SourceIdentity(
        snapshot.logicalProjectNamespace,
        ConverterId('rmxp-map-$sourceMapId-event'),
        sourceEventId,
      ).stableId;

  Map<String, Object?> _normalizedJson() => {
        'schemaVersion': '1.0',
        'kind': 'normalizedSourceProject',
        'extractorVersion': 'rmxp-normalization-v4',
        'connections':
            connections.map((connection) => connection.toJson()).toList(),
        'connectionsState': connectionsState.name,
        'connectionsExtracted': connectionsExtracted,
        'connectionsFileId': connectionsFileId?.value,
        'sourceSnapshotHash': snapshot.canonicalHash.value,
        'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
        'sourceProfileId': sourceProfileId.value,
        'sourceProfileState': snapshot.profile.state.name,
        'selectedSourceMapIds': selectedSourceMapIds,
        'unprocessedSourceMapIds': unprocessedSourceMapIds,
        'maps': maps.map((map) => map.toJson()).toList(),
        'mapHierarchy': mapHierarchy.map((info) => info.toJson()).toList(),
        'tilesets': tilesets.map((tileset) => tileset.toJson()).toList(),
        'eventImages': eventImages.map((image) => image.toJson()).toList(),
        'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
        'preservedParameterRefs':
            preservedParameterRefs.map((item) => item.toJson()).toList(),
        'archiveHash': archive.canonicalHash.value,
      };

  late final Sha256Hash canonicalHash = canonicalHashOf(
    _normalizedJson(),
    limits: const ContractLimits(
      maxNodes: 40000000,
      maxStringCodeUnits: 1048576,
      maxTextCodeUnits: 134217728,
    ),
  );

  Map<String, Object?> toJson() => {
        ..._normalizedJson(),
        'archive': archive.toJson(),
      };
}

final class RmxpSourceNormalizer {
  const RmxpSourceNormalizer();

  Future<NormalizedSourceProject> inspectMapHierarchy({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    SourceNormalizationLimits limits = const SourceNormalizationLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits._validate();
    final token = cancellation ?? ScanCancellation();
    token.check();
    return _SourceNormalizationRun(
            snapshot, files, limits, token, null, false, false, const [])
        .run(hierarchyOnly: true);
  }

  Future<NormalizedSourceProject> normalize({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    SourceNormalizationLimits limits = const SourceNormalizationLimits(),
    ScanCancellation? cancellation,
    Set<int>? selectedMapIds,
    bool includeEventSystem = false,
    bool includeConnections = false,
    List<SourceImageBinding> imageBindings = const [],
  }) async {
    limits._validate();
    final token = cancellation ?? ScanCancellation();
    token.check();
    _require(imageBindings.length <= 256, 'normalization.image_binding.invalid',
        r'$', 'Too many atlas image bindings');
    return _SourceNormalizationRun(
            snapshot,
            files,
            limits,
            token,
            selectedMapIds == null ? null : Set.unmodifiable(selectedMapIds),
            includeEventSystem,
            includeConnections,
            List.unmodifiable(imageBindings))
        .run();
  }
}

final class _SourceNormalizationRun {
  _SourceNormalizationRun(
      this.snapshot,
      this.files,
      this.limits,
      this.cancellation,
      this.selectedMapIds,
      this.includeEventSystem,
      this.includeConnections,
      this.requestedImageBindings)
      : archive = SourceArchive(
          limits: SourceArchiveLimits(maxTotalBytes: limits.maxTotalBytes),
        ),
        sourceProfileId =
            ConverterId('profile:${snapshot.profile.evidenceHash.value}') {
    for (final entry in snapshot.entries) {
      byPath[sourcePathCollisionKey(entry.relativePath)] = entry;
    }
    if (includeConnections) {
      final entry = byPath[sourcePathCollisionKey('Data/map_connections.dat')];
      connectionsFileId = entry?.fileId;
      connectionsState = entry == null
          ? SourceConnectionsState.missing
          : SourceConnectionsState.invalid;
    }
  }

  final SourceSnapshot snapshot;
  final SourceFilePort files;
  final SourceNormalizationLimits limits;
  final ScanCancellation cancellation;
  final Set<int>? selectedMapIds;
  final bool includeEventSystem;
  final bool includeConnections;
  final List<SourceImageBinding> requestedImageBindings;
  final imageBindings = <String, SourceImageBinding>{};
  final boundImages = <String, SourceFileEntry>{};
  final usedImageBindings = <String>{};
  final SourceArchive archive;
  final ConverterId sourceProfileId;
  final byPath = <String, SourceFileEntry>{};
  final maps = <SourceMapIr>[];
  final connections = <NormalizedMapConnection>[];
  var connectionsState = SourceConnectionsState.notRequested;
  ConverterId? connectionsFileId;
  final hierarchy = <int, NormalizedMapInfo>{};
  final tilesets = <NormalizedTileset>[];
  final eventImages = <NormalizedMediaReference>[];
  final diagnostics = <SourceNormalizationDiagnostic>[];
  final preservedParameters = <NormalizedPreservedParameter>[];
  final eventTiles = <(int, int, ConverterId, SourceLocator)>[];
  final parameterWarningFiles = <String>{};
  final declaredSourceMapIds = <int>{};
  var readBytes = 0;
  var totalCells = 0;
  var events = 0;
  var commands = 0;
  var parameterNodes = 0;
  var metadataCells = 0;
  var irNodes = 0;
  var irTextCodeUnits = 0;
  var diagnosticTextCodeUnits = 0;

  (int, int) projectionSize(Object? value) {
    var nodes = 0;
    var text = 0;
    void visit(Object? item) {
      nodes++;
      if (item is String) text += item.length;
      if (item is List) {
        for (final child in item) {
          visit(child);
        }
      }
      if (item is Map<String, Object?>) {
        for (final entry in item.entries) {
          text += entry.key.length;
          visit(entry.value);
        }
      }
    }

    visit(value);
    return (nodes, text);
  }

  void reserveProjection(Object? value, SourceLocator loc) {
    final size = projectionSize(value);
    _require(
        size.$1 <= limits.maxTotalIrNodes - irNodes,
        'normalization.quota.ir_nodes',
        loc.file,
        'Aggregate normalized IR node quota exceeded');
    _require(
        size.$2 <= limits.maxTotalTextCodeUnits - irTextCodeUnits,
        'normalization.quota.ir_text',
        loc.file,
        'Aggregate normalized IR text quota exceeded');
    irNodes += size.$1;
    irTextCodeUnits += size.$2;
  }

  void addEventImage(NormalizedMediaReference image) {
    reserveProjection(image.toJson(), image.locator);
    eventImages.add(image);
  }

  SourceLocator locator(String path,
          {int? mapId, int? eventId, int? pageIndex, int? commandIndex}) =>
      SourceLocator._(Map.unmodifiable({
        'file': path,
        'mapId': mapId,
        'eventId': eventId,
        'pageIndex': pageIndex,
        'commandIndex': commandIndex,
        'tileId': null,
        'line': null,
      }));

  void diagnostic(String code, SourceLocator sourceLocator, String message,
      {bool blocks = true, List<String> paths = const []}) {
    if (diagnostics.length >= limits.maxDiagnostics) {
      throw ContractError('normalization.quota.diagnostics', sourceLocator.file,
          'Diagnostic quota exceeded');
    }
    final record = SourceNormalizationDiagnostic(
      code: code,
      blocksPlanning: blocks,
      locator: sourceLocator,
      message: message,
      relatedPaths: List.unmodifiable(paths.toList()..sort()),
    );
    final text = projectionSize(record.toJson()).$2;
    _require(
        text <= limits.maxDiagnosticTextCodeUnits - diagnosticTextCodeUnits,
        'normalization.quota.diagnostic_text',
        sourceLocator.file,
        'Diagnostic text quota exceeded');
    diagnosticTextCodeUnits += text;
    diagnostics.add(record);
  }

  ConverterId identity(String domain, int id) =>
      SourceIdentity(snapshot.logicalProjectNamespace, ConverterId(domain), id)
          .stableId;

  Future<SourceArchivedFile> load(SourceFileEntry entry) async {
    cancellation.check();
    if (entry.byteLength > limits.maxTotalBytes - readBytes) {
      throw ContractError('normalization.quota.bytes', entry.relativePath,
          'Total source byte quota exceeded before reading');
    }
    readBytes += entry.byteLength;
    final bytes = await files.read(entry.fileId);
    cancellation.check();
    _require(
        bytes.length == entry.byteLength &&
            Sha256Hash(sha256.convert(bytes).toString()) == entry.sha256,
        'normalization.source_changed',
        entry.relativePath,
        'Source bytes disagree with the admitted snapshot');
    return archive.add(entry, bytes);
  }

  Map<String, int> fields(MarshalDocument document, int id, String className) {
    final node = document.node(id);
    _require(
        node.kind == MarshalKind.object && node.className == className,
        'normalization.class',
        node.location.graphPath,
        'Expected inert $className data');
    final result = <String, int>{};
    for (final pair in node.instanceVariables) {
      final key = document.node(pair.key).name;
      _require(
          key != null && !result.containsKey(key),
          'normalization.fields',
          node.location.graphPath,
          'Object fields must have unique decodable symbols');
      result[key!] = pair.value;
    }
    return result;
  }

  int requiredField(Map<String, int> object, String name) {
    final id = object[name];
    _require(id != null, 'normalization.field_missing', name,
        'Required source field is absent');
    return id!;
  }

  int integer(MarshalDocument doc, int id,
      {int minimum = 0, int maximum = 2147483647}) {
    final node = doc.node(id);
    final value = node.integerValue;
    _require(
        node.kind == MarshalKind.integer &&
            value != null &&
            value >= BigInt.from(minimum) &&
            value <= BigInt.from(maximum),
        'normalization.integer',
        node.location.graphPath,
        'Expected a bounded integer');
    return value!.toInt();
  }

  String text(MarshalDocument doc, int id, {int maxLength = 512}) {
    final node = doc.node(id);
    _require(node.kind == MarshalKind.string, 'normalization.text',
        node.location.graphPath, 'Expected source text');
    final value = node.text().text;
    _require(
        value != null && value.length <= maxLength,
        'normalization.text',
        node.location.graphPath,
        'Source text is undecodable or exceeds its quota');
    return value!;
  }

  List<int> array(MarshalDocument doc, int id, {int maximum = 100000}) {
    final node = doc.node(id);
    _require(
        node.kind == MarshalKind.array && node.elements.length <= maximum,
        'normalization.array',
        node.location.graphPath,
        'Expected a bounded source array');
    return node.elements;
  }

  SourcePreservedData preserve(
          SourceArchivedFile file, int nodeId, SourceLocator sourceLocator) =>
      archive.reference(
          fileId: file.fileId, nodeId: nodeId, locator: sourceLocator);

  void failure(Object error, SourceLocator sourceLocator) {
    if (error is ContractError) {
      if (error.code.contains('.quota.') ||
          error.code == 'normalization.source_changed' ||
          error.code == 'source.cancelled') {
        throw error;
      }
      diagnostic(error.code, sourceLocator, error.message);
    } else if (error is BinaryDecodeError) {
      diagnostic(error.code, sourceLocator,
          '${error.message} at byte ${error.location.byteOffset}, ${error.location.graphPath}');
    } else {
      throw error;
    }
  }

  Future<NormalizedSourceProject> run({bool hierarchyOnly = false}) async {
    _require(
        snapshot.state == SourceScanState.complete,
        'normalization.incomplete_snapshot',
        r'$',
        'Normalization requires a complete admitted snapshot');
    if (selectedMapIds != null) {
      _require(
          selectedMapIds!.isNotEmpty &&
              selectedMapIds!.every((id) => id >= 0 && id <= 2147483647),
          'normalization.selection',
          r'$',
          'Invalid source map selection');
    }
    try {
      for (final binding
          in SourceImageBinding.canonicalize(requestedImageBindings)) {
        final key = sourcePathCollisionKey(binding.expectedReferencePath);
        final entry =
            byPath[sourcePathCollisionKey(binding.sourceRelativePath)];
        _require(
            entry != null &&
                entry.kind == SourceNodeKind.file &&
                entry.relativePath == binding.sourceRelativePath &&
                entry.sha256 == binding.sourceSha256 &&
                const {'raster', 'png', 'bmp', 'jpeg', 'jpg'}
                    .contains(entry.format),
            'normalization.image_binding.invalid',
            binding.sourceRelativePath,
            'The chosen atlas image must match an admitted regular file');
        imageBindings[key] = binding;
        boundImages[key] = entry!;
      }
      if (hierarchyOnly) {
        await extractHierarchy();
      } else {
        await extract();
      }
      for (final entry in imageBindings.entries) {
        if (!usedImageBindings.contains(entry.key)) {
          diagnostic(
              'normalization.image_binding.unused',
              locator(entry.value.expectedReferencePath),
              'The chosen atlas image is not used by the selected maps',
              paths: [entry.value.sourceRelativePath]);
        }
      }
    } on Object catch (error) {
      if (error is ContractError && error.code == 'source.cancelled') rethrow;
      if (error is ContractError &&
          error.code == 'normalization.quota.diagnostics') {
        rethrow;
      }
      if (error is ContractError) {
        final path = error.path == r'$' ? 'Data' : error.path;
        final match = RegExp(r'^data/map([0-9]+)\.rxdata$')
            .firstMatch(sourcePathCollisionKey(path));
        diagnostic(
            error.code,
            locator(path,
                mapId: match == null ? null : int.parse(match.group(1)!)),
            error.message);
      } else if (error is BinaryDecodeError) {
        diagnostic(
            error.code, locator(error.location.sourcePath), error.message);
      } else {
        rethrow;
      }
    }
    return finish();
  }

  Future<void> extract() async {
    final mapEntries = <int, SourceFileEntry>{};
    final mapPattern = RegExp(r'^data/map([0-9]+)\.rxdata$');
    for (final entry in snapshot.entries) {
      cancellation.check();
      final match =
          mapPattern.firstMatch(sourcePathCollisionKey(entry.relativePath));
      if (entry.kind != SourceNodeKind.file || match == null) continue;
      final id = int.tryParse(match.group(1)!);
      _require(id != null && id <= 2147483647, 'normalization.map_id',
          entry.relativePath, 'Map ID is out of bounds');
      _require(!mapEntries.containsKey(id), 'normalization.duplicate_map_id',
          entry.relativePath, 'Two files declare the same source map ID');
      mapEntries[id!] = entry;
    }
    declaredSourceMapIds.addAll(selectedMapIds ?? mapEntries.keys);
    _require(
        mapEntries.length <= limits.maxMaps &&
            (selectedMapIds?.length ?? 0) <= limits.maxMaps,
        'normalization.quota.maps',
        r'$',
        'Map quota exceeded');
    final requiredEntries = <SourceFileEntry>[
      for (final path in [
        'Data/MapInfos.rxdata',
        'Data/Tilesets.rxdata',
        if (includeEventSystem) 'Data/System.rxdata',
        if (includeConnections) 'Data/map_connections.dat'
      ])
        if (byPath[sourcePathCollisionKey(path)] != null)
          byPath[sourcePathCollisionKey(path)]!,
      for (final id in selectedMapIds ?? mapEntries.keys)
        if (mapEntries[id] != null) mapEntries[id]!,
    ];
    var plannedBytes = 0;
    for (final entry in requiredEntries) {
      _require(
          entry.kind == SourceNodeKind.file && entry.sha256 != null,
          'normalization.required_source_file',
          entry.relativePath,
          'Required RMXP input must be an admitted hashed regular file');
      _require(
          entry.byteLength <= 67108864,
          'normalization.quota.file_bytes',
          entry.relativePath,
          'Source file exceeds the decoder byte quota before reading');
      _require(
          entry.byteLength <= limits.maxTotalBytes - plannedBytes,
          'normalization.quota.bytes',
          entry.relativePath,
          'Declared extraction bytes exceed the quota before reading');
      plannedBytes += entry.byteLength;
    }
    if (includeEventSystem) {
      final systemEntry = byPath[sourcePathCollisionKey('Data/System.rxdata')];
      if (systemEntry == null) {
        diagnostic(
            'normalization.missing_event_system',
            locator('Data/System.rxdata'),
            'Event switch names cannot be qualified without System data',
            blocks: false);
      } else {
        try {
          await load(systemEntry);
        } on Object catch (error) {
          failure(error, locator(systemEntry.relativePath));
        }
      }
    }
    await extractHierarchy();
    if (includeConnections) {
      await readConnections(mapEntries);
    }
    final ids = (selectedMapIds ?? mapEntries.keys.toSet()).toList()..sort();
    for (final id in ids) {
      cancellation.check();
      final entry = mapEntries[id];
      if (entry == null) {
        diagnostic(
            'normalization.missing_map',
            locator('Data/Map$id.rxdata', mapId: id),
            'Selected source map file is absent');
        continue;
      }
      if (!hierarchy.containsKey(id)) {
        diagnostic(
            'normalization.missing_map_info',
            locator(entry.relativePath, mapId: id),
            'Map has no corresponding source MapInfo');
      }
      try {
        final file = await load(entry);
        final map = readMap(file, id);
        reserveProjection(map.toJson(), locator(entry.relativePath, mapId: id));
        maps.add(map);
      } on Object catch (error) {
        failure(error, locator(entry.relativePath, mapId: id));
      }
    }
    if (selectedMapIds == null) {
      for (final info in hierarchy.values) {
        if (!mapEntries.containsKey(info.sourceMapId)) {
          diagnostic('normalization.missing_map', info.locator,
              'MapInfo references an absent source map file');
        }
      }
    }
    final usedTilesets = maps.map((map) => map.map.sourceTilesetId).toSet();
    final tilesetEntry = byPath[sourcePathCollisionKey('Data/Tilesets.rxdata')];
    if (tilesetEntry == null) {
      diagnostic('normalization.missing_tilesets',
          locator('Data/Tilesets.rxdata'), 'Tilesets source file is absent');
    } else {
      try {
        readTilesets(await load(tilesetEntry), usedTilesets);
      } on Object catch (error) {
        failure(error, locator(tilesetEntry.relativePath));
      }
    }
    final knownTilesets =
        tilesets.map((value) => value.sourceTilesetId).toSet();
    for (final map in maps) {
      if (!knownTilesets.contains(map.map.sourceTilesetId)) {
        diagnostic(
            'normalization.missing_tileset',
            locator(archive.files[map.map.sourceFileId]!.entry.relativePath,
                mapId: map.map.sourceMapId),
            'Map references missing or malformed tileset ${map.map.sourceTilesetId}');
      }
    }
    validateUsedImages();
  }

  Future<void> extractHierarchy() async {
    const sourcePath = 'Data/MapInfos.rxdata';
    final entry = byPath[sourcePathCollisionKey(sourcePath)];
    if (entry == null) {
      diagnostic('normalization.missing_map_infos', locator(sourcePath),
          'MapInfos source file is absent');
      return;
    }
    _require(
        entry.kind == SourceNodeKind.file && entry.sha256 != null,
        'normalization.required_source_file',
        entry.relativePath,
        'Required RMXP input must be an admitted hashed regular file');
    _require(
        entry.byteLength <= 67108864,
        'normalization.quota.file_bytes',
        entry.relativePath,
        'Source file exceeds the decoder byte quota before reading');
    try {
      readHierarchy(await load(entry));
    } on Object catch (error) {
      failure(error, locator(entry.relativePath));
    }
  }

  NormalizedSourceProject finish() {
    diagnostics.sort((a, b) {
      final path = a.locator.file.compareTo(b.locator.file);
      if (path != 0) return path;
      final map = (a.locator.mapId ?? -1).compareTo(b.locator.mapId ?? -1);
      if (map != 0) return map;
      final code = a.code.compareTo(b.code);
      return code != 0 ? code : a.message.compareTo(b.message);
    });
    final infos = hierarchy.values.toList()
      ..sort((a, b) => a.sourceMapId.compareTo(b.sourceMapId));
    final accounted = {
      ...maps.map((map) => map.map.sourceMapId),
      ...diagnostics
          .where((item) => item.blocksPlanning)
          .map((item) => item.locator.mapId)
          .whereType<int>(),
    };
    final selected = declaredSourceMapIds.toList()..sort();
    final unprocessed = declaredSourceMapIds.difference(accounted).toList()
      ..sort();
    archive.seal();
    return NormalizedSourceProject._(
      snapshot: snapshot,
      sourceProfileId: sourceProfileId,
      maps: maps,
      connections: connections,
      connectionsState: connectionsState,
      connectionsFileId: connectionsFileId,
      mapHierarchy: infos,
      tilesets: tilesets,
      eventImages: eventImages,
      diagnostics: diagnostics,
      preservedParameterRefs: preservedParameters,
      selectedSourceMapIds: selected,
      unprocessedSourceMapIds: unprocessed,
      archive: archive,
    );
  }

  Future<void> readConnections(Map<int, SourceFileEntry> mapEntries) async {
    const path = 'Data/map_connections.dat';
    final entry = byPath[sourcePathCollisionKey(path)];
    if (entry == null) {
      diagnostic('normalization.missing_connections', locator(path),
          'Requested compiled map connections source file is absent');
      return;
    }
    final fileLocator = locator(entry.relativePath);
    try {
      final file = await load(entry);
      final doc = file.document;
      final root = doc.node(doc.rootId);
      preserve(file, doc.rootId, fileLocator);
      _require(
          root.kind == MarshalKind.array,
          'normalization.connection.graph',
          entry.relativePath,
          'Compiled map connections require an inert array');
      _require(
          root.elements.length <= limits.maxConnections,
          'normalization.quota.connections',
          entry.relativePath,
          'Compiled map connection record quota exceeded');
      final records = <NormalizedMapConnection>[];
      final identities = <ConverterId>{};
      var valid = true;
      for (final indexed in root.elements.indexed) {
        cancellation.check();
        final rowIndex = indexed.$1;
        final nodeId = indexed.$2;
        try {
          final values = array(doc, nodeId, maximum: 6);
          _require(
              values.length == 6,
              'normalization.connection.arity',
              doc.node(nodeId).location.graphPath,
              'Compiled map connections require exactly six fields');
          final sourceMapId = integer(doc, values[0], minimum: 1);
          final targetSourceMapId = integer(doc, values[3], minimum: 1);
          final rowLocator = locator(entry.relativePath, mapId: sourceMapId);
          SourceConnectionDirection direction(int id) {
            final code = text(doc, id, maxLength: 1);
            final matches = SourceConnectionDirection.values
                .where((value) => value.sourceCode == code);
            _require(
                matches.length == 1,
                'normalization.connection.direction',
                doc.node(id).location.graphPath,
                'Compiled map edges require N, E, S or W');
            return matches.single;
          }

          final sourceDirection = direction(values[1]);
          final targetDirection = direction(values[4]);
          final sourceOffset = integer(doc, values[2], minimum: -2147483648);
          final targetOffset = integer(doc, values[5], minimum: -2147483648);
          _require(
              sourceMapId != targetSourceMapId,
              'normalization.connection.self',
              doc.node(nodeId).location.graphPath,
              'A compiled map connection must join distinct source maps');
          _require(
              sourceDirection.opposite == targetDirection,
              'normalization.connection.opposition',
              doc.node(nodeId).location.graphPath,
              'The admitted compiled map connection profile requires opposing edges');
          for (final id in [sourceMapId, targetSourceMapId]) {
            _require(
                hierarchy.containsKey(id) &&
                    mapEntries[id]?.kind == SourceNodeKind.file &&
                    mapEntries[id]?.sha256 != null,
                'normalization.connection.map_reference',
                doc.node(nodeId).location.graphPath,
                'Compiled connection endpoints require complete MapInfos and inventoried hashed map files');
          }
          final identity = ConverterId('s1:${canonicalHashOf([
                'avelune-converter-connection-id-v1',
                snapshot.logicalProjectNamespace.value,
                sourceMapId,
                sourceDirection.sourceCode,
                sourceOffset,
                targetSourceMapId,
                targetDirection.sourceCode,
                targetOffset,
              ]).value}');
          _require(
              identities.add(identity),
              'normalization.connection.duplicate',
              doc.node(nodeId).location.graphPath,
              'Duplicate literal compiled connection identities cannot be overwritten');
          final record = NormalizedMapConnection._(
            identity: identity,
            sourceRowIndex: rowIndex,
            sourceMapId: sourceMapId,
            sourceDirection: sourceDirection,
            sourceOffset: sourceOffset,
            targetSourceMapId: targetSourceMapId,
            targetDirection: targetDirection,
            targetOffset: targetOffset,
            rawDataRef: preserve(file, nodeId, rowLocator),
            locator: rowLocator,
          );
          reserveProjection(record.toJson(), rowLocator);
          records.add(record);
        } on Object catch (error) {
          valid = false;
          failure(error, fileLocator);
        }
      }
      if (valid) {
        connections.addAll(records);
        connectionsState = SourceConnectionsState.extracted;
      }
    } on Object catch (error) {
      failure(error, fileLocator);
    }
  }

  void readHierarchy(SourceArchivedFile file) {
    final doc = file.document;
    final root = doc.node(doc.rootId);
    _require(
        root.kind == MarshalKind.hash && root.pairs.length <= limits.maxMaps,
        'normalization.map_infos',
        file.entry.relativePath,
        'Expected a bounded MapInfos hash');
    for (final pair in root.pairs) {
      final id = integer(doc, pair.key);
      _require(!hierarchy.containsKey(id), 'normalization.duplicate_map_info',
          file.entry.relativePath, 'Duplicate MapInfo source ID');
      final object = fields(doc, pair.value, 'RPG::MapInfo');
      final loc = locator(file.entry.relativePath, mapId: id);
      int? optionalInt(String name) => object[name] == null
          ? null
          : integer(doc, object[name]!, minimum: -2147483648);
      bool? optionalBool(String name) {
        final nodeId = object[name];
        if (nodeId == null) return null;
        final node = doc.node(nodeId);
        _require(node.kind == MarshalKind.boolean, 'normalization.boolean',
            node.location.graphPath, 'Expected a boolean');
        return node.booleanValue;
      }

      final info = NormalizedMapInfo(
        sourceMapId: id,
        identity: identity('rmxp-map', id),
        name: text(doc, requiredField(object, '@name')),
        parentSourceMapId: integer(doc, requiredField(object, '@parent_id')),
        order: integer(doc, requiredField(object, '@order')),
        expanded: optionalBool('@expanded'),
        scrollX: optionalInt('@scroll_x'),
        scrollY: optionalInt('@scroll_y'),
        rawDataRef: preserve(file, pair.value, loc),
        locator: loc,
      );
      reserveProjection(info.toJson(), loc);
      hierarchy[id] = info;
    }
    final complete = <int>{};
    for (final info in hierarchy.values) {
      var current = info.sourceMapId;
      final seen = <int>{};
      while (current != 0 && !complete.contains(current)) {
        if (!seen.add(current)) {
          diagnostic('normalization.map_parent_cycle', info.locator,
              'MapInfo hierarchy contains a parent cycle');
          break;
        }
        final node = hierarchy[current];
        if (node == null) {
          diagnostic('normalization.missing_map_parent', info.locator,
              'MapInfo parent $current is absent');
          break;
        }
        current = node.parentSourceMapId;
      }
      complete.addAll(seen);
    }
  }

  SourceMapIr readMap(SourceArchivedFile file, int mapId) {
    final doc = file.document;
    final object = fields(doc, doc.rootId, 'RPG::Map');
    final width = integer(doc, requiredField(object, '@width'),
        minimum: 1, maximum: 100000);
    final height = integer(doc, requiredField(object, '@height'),
        minimum: 1, maximum: 100000);
    _require(
        width <= limits.maxTotalCells ~/ height ~/ 3,
        'normalization.quota.cells',
        file.entry.relativePath,
        'Map cells exceed the normalization budget before allocation');
    final count = width * height * 3;
    _require(
        count < const ContractLimits().maxNodes &&
            count <= limits.maxTotalIrNodes - irNodes,
        'normalization.quota.ir_nodes',
        file.entry.relativePath,
        'Map cells exceed the remaining IR budget before allocation');
    _require(
        count <= limits.maxTotalCells - totalCells,
        'normalization.quota.cells',
        file.entry.relativePath,
        'Total map cell quota exceeded');
    totalCells += count;
    final table =
        const TableDecoder().decode(doc.node(requiredField(object, '@data')));
    _require(
        table.dimensions == 3 &&
            table.xSize == width &&
            table.ySize == height &&
            table.zSize == 3,
        'normalization.map_table',
        file.entry.relativePath,
        'Map Table dimensions disagree with width, height or three layers');
    final layers = <Map<String, Object?>>[];
    for (var z = 0; z < 3; z++) {
      final cells = <int>[];
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final value = table.valueAt(x, y, z);
          _require(
              value >= 0,
              'normalization.negative_tile',
              file.entry.relativePath,
              'Signed negative tile ID is unsupported');
          cells.add(value);
        }
      }
      layers.add({'sourceZ': z, 'cells': cells});
    }
    final unknowns = <String>[];
    final mapLoc = locator(file.entry.relativePath, mapId: mapId);
    for (final entry in object.entries) {
      if (!const {'@width', '@height', '@tileset_id', '@data', '@events'}
          .contains(entry.key)) {
        unknowns.add(preserve(file, entry.value, mapLoc).id.value);
      }
    }
    final eventNode = doc.node(requiredField(object, '@events'));
    _require(eventNode.kind == MarshalKind.hash, 'normalization.events',
        file.entry.relativePath, 'Expected event hash');
    _require(
        eventNode.pairs.length <= limits.maxEvents - events,
        'normalization.quota.events',
        file.entry.relativePath,
        'Event quota exceeded');
    events += eventNode.pairs.length;
    final pairs = eventNode.pairs.toList()
      ..sort((a, b) => integer(doc, a.key).compareTo(integer(doc, b.key)));
    final eventRecords = <Map<String, Object?>>[];
    final eventIds = <int>{};
    for (final pair in pairs) {
      final id = integer(doc, pair.key);
      _require(eventIds.add(id), 'normalization.duplicate_event_id',
          file.entry.relativePath, 'Duplicate source event ID');
      final event = fields(doc, pair.value, 'RPG::Event');
      _require(
          integer(doc, requiredField(event, '@id')) == id,
          'normalization.event_id',
          file.entry.relativePath,
          'Event ID disagrees with its source hash key');
      final eventLoc =
          locator(file.entry.relativePath, mapId: mapId, eventId: id);
      for (final entry in event.entries) {
        if (!const {'@id', '@name', '@x', '@y', '@pages'}.contains(entry.key)) {
          unknowns.add(preserve(file, entry.value, eventLoc).id.value);
        }
      }
      final pages = array(doc, requiredField(event, '@pages'), maximum: 2048);
      final pageRecords = <Map<String, Object?>>[];
      for (var p = 0; p < pages.length; p++) {
        final page = fields(doc, pages[p], 'RPG::Event::Page');
        final pageLoc = locator(file.entry.relativePath,
            mapId: mapId, eventId: id, pageIndex: p);
        final list = array(doc, requiredField(page, '@list'));
        _require(
            list.length <= limits.maxCommands - commands,
            'normalization.quota.commands',
            file.entry.relativePath,
            'Command quota exceeded');
        commands += list.length;
        final commandRecords = <Map<String, Object?>>[];
        for (var c = 0; c < list.length; c++) {
          final command = fields(doc, list[c], 'RPG::EventCommand');
          final commandLoc = locator(file.entry.relativePath,
              mapId: mapId, eventId: id, pageIndex: p, commandIndex: c);
          final params =
              array(doc, requiredField(command, '@parameters'), maximum: 4096);
          commandRecords.add({
            'originalIndex': c,
            'code': integer(doc, requiredField(command, '@code')),
            'indent':
                integer(doc, requiredField(command, '@indent'), maximum: 1024),
            'parameters': [
              for (var i = 0; i < params.length; i++)
                parameter(file, params[i], commandLoc, i, r'$', <int>{}, 0),
            ],
            'sourceLocator': commandLoc.toJson(),
          });
        }
        final graphicId = page['@graphic'];
        if (graphicId != null) {
          final graphic = fields(doc, graphicId, 'RPG::Event::Page::Graphic');
          final tileId = graphic['@tile_id'];
          if (tileId != null) {
            final value = integer(doc, tileId, maximum: 65535);
            if (value > 0) {
              eventTiles.add((
                mapId,
                value,
                identity('rmxp-map-$mapId-event', id),
                pageLoc
              ));
            }
          }
          final nameId = graphic['@character_name'];
          if (nameId != null) {
            addEventImage(resolveImage(
                file,
                nameId,
                identity('rmxp-map-$mapId-event', id),
                'character',
                'Graphics/Characters',
                pageLoc));
          }
        }
        pageRecords.add({
          'originalPageIndex': p,
          'conditionsDataRef': page['@condition'] == null
              ? null
              : preserve(file, page['@condition']!, pageLoc).id.value,
          'triggerCode': integer(doc, requiredField(page, '@trigger')),
          'commands': commandRecords,
          'rawDataRef': preserve(file, pages[p], pageLoc).id.value,
        });
      }
      eventRecords.add({
        'sourceEventId': id,
        'name': text(doc, requiredField(event, '@name'), maxLength: 256),
        'x': integer(doc, requiredField(event, '@x')),
        'y': integer(doc, requiredField(event, '@y')),
        'pages': pageRecords,
      });
    }
    if (unknowns.isNotEmpty) {
      diagnostic('normalization.unknown_data_preserved', mapLoc,
          'Map and event attributes remain preservedOnly in the source archive',
          blocks: false);
    }
    return SourceMapIr.fromJson({
      'schemaVersion': '1.0',
      'kind': 'sourceMapIr',
      'exampleOnly': false,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourceProfileId': sourceProfileId.value,
      'map': {
        'sourceMapId': mapId,
        'sourceFileId': file.fileId.value,
        'name': hierarchy[mapId]?.name ?? '',
        'width': width,
        'height': height,
        'tileWidth': 32,
        'tileHeight': 32,
        'sourceTilesetId': integer(doc, requiredField(object, '@tileset_id')),
        'layers': layers,
        'events': eventRecords,
        'unknownDataRefs': unknowns.toSet().toList(),
      },
    });
  }

  static final _unsupportedParameter = Object();

  Object? parameter(SourceArchivedFile file, int nodeId, SourceLocator loc,
      int parameterIndex, String graphPath, Set<int> active, int depth) {
    final projected = projectParameter(file, nodeId, loc, active, depth);
    if (!identical(projected, _unsupportedParameter)) return projected;
    final ref = preserve(file, nodeId, loc);
    final parameter = NormalizedPreservedParameter(
      locator: loc,
      parameterIndex: parameterIndex,
      graphPath: graphPath,
      rawDataRef: ref,
    );
    reserveProjection(parameter.toJson(), loc);
    preservedParameters.add(parameter);
    if (parameterWarningFiles.add(loc.file)) {
      diagnostic(
          'normalization.parameter_preserved',
          locator(loc.file, mapId: loc.mapId),
          'Parameters remain inert; exact positions are in preservedParameterRefs',
          blocks: false);
    }
    return {'preservedDataRef': ref.id.value};
  }

  Object? projectParameter(SourceArchivedFile file, int nodeId,
      SourceLocator loc, Set<int> active, int depth) {
    cancellation.check();
    if (++parameterNodes > limits.maxParameterNodes || depth >= 64) {
      throw ContractError('normalization.quota.parameters', loc.file,
          'Parameter projection quota exceeded');
    }
    final node = file.document.node(nodeId);
    switch (node.kind) {
      case MarshalKind.nil:
        return null;
      case MarshalKind.boolean:
        return node.booleanValue;
      case MarshalKind.integer:
        final value = node.integerValue!;
        if (value.abs() <= BigInt.from(9007199254740991)) return value.toInt();
        break;
      case MarshalKind.floating:
        final value = node.floatValue!;
        if (value.isFinite && !(value == 0 && value.isNegative)) return value;
        break;
      case MarshalKind.string:
        final value = node.text().text;
        if (value != null && value.length <= 1048576) return value;
        break;
      case MarshalKind.array:
        if (!active.add(nodeId)) break;
        final result = <Object?>[];
        for (final childId in node.elements) {
          final child = projectParameter(file, childId, loc, active, depth + 1);
          if (identical(child, _unsupportedParameter)) {
            active.remove(nodeId);
            return _unsupportedParameter;
          }
          result.add(child);
        }
        active.remove(nodeId);
        return result;
      default:
        break;
    }
    return _unsupportedParameter;
  }

  NormalizedMediaReference resolveImage(SourceArchivedFile file, int nameId,
      ConverterId ownerId, String role, String folder, SourceLocator loc,
      {int? slot}) {
    final name = text(file.document, nameId, maxLength: 1024);
    if (name.isEmpty) {
      return NormalizedMediaReference(
          ownerId: ownerId,
          role: role,
          sourceName: name,
          locator: loc,
          state: 'none',
          slot: slot);
    }
    final path = '$folder/$name';
    try {
      validateSourceRelativePath(path);
    } on ContractError {
      diagnostic('normalization.invalid_media_path', loc,
          'Invalid source image reference: $path',
          paths: [path]);
      return NormalizedMediaReference(
          ownerId: ownerId,
          role: role,
          sourceName: name,
          locator: loc,
          state: 'invalid',
          slot: slot);
    }
    final explicit =
        RegExp(r'\.(png|bmp|jpe?g)$', caseSensitive: false).hasMatch(name);
    final candidates = <SourceFileEntry>[];
    for (final candidatePath in explicit
        ? [path]
        : ['$path.png', '$path.bmp', '$path.jpg', '$path.jpeg']) {
      final entry = byPath[sourcePathCollisionKey(candidatePath)];
      if (entry?.kind == SourceNodeKind.file) candidates.add(entry!);
    }
    final state = candidates.length == 1
        ? 'resolved'
        : candidates.isEmpty
            ? 'missing'
            : 'ambiguous';
    final bindingKey = sourcePathCollisionKey(path);
    final binding = imageBindings[bindingKey];
    if (binding != null) {
      usedImageBindings.add(bindingKey);
      if (state == 'resolved') {
        diagnostic('normalization.image_binding.unneeded', loc,
            'The original atlas reference already resolves without a binding',
            paths: [path, binding.sourceRelativePath]);
      } else {
        diagnostic('normalization.image_binding_applied', loc,
            'An explicitly chosen source image supplies the $state atlas reference',
            blocks: false, paths: [path, binding.sourceRelativePath]);
        return NormalizedMediaReference(
            ownerId: ownerId,
            role: role,
            sourceName: name,
            locator: loc,
            state: 'resolved',
            slot: slot,
            sourceFile: boundImages[bindingKey],
            appliedImageBinding: binding);
      }
    }
    if (state != 'resolved') {
      diagnostic('normalization.${state}_image', loc,
          'Source image $role "$name" is $state',
          blocks: !(state == 'missing' &&
              role == 'character' &&
              loc.mapId != null &&
              loc.eventId != null &&
              loc.pageIndex != null),
          paths: candidates.isEmpty
              ? [path]
              : candidates.map((entry) => entry.relativePath).toList());
    }
    return NormalizedMediaReference(
        ownerId: ownerId,
        role: role,
        sourceName: name,
        locator: loc,
        state: state,
        slot: slot,
        sourceFile: candidates.length == 1 ? candidates.single : null);
  }

  void readTilesets(SourceArchivedFile file, Set<int> usedIds) {
    final doc = file.document;
    final entries = array(doc, doc.rootId, maximum: 100000);
    for (var index = 0; index < entries.length; index++) {
      if (!usedIds.contains(index)) continue;
      final node = doc.node(entries[index]);
      if (node.kind == MarshalKind.nil) continue;
      final loc = locator(file.entry.relativePath);
      try {
        final object = fields(doc, entries[index], 'RPG::Tileset');
        final id = integer(doc, requiredField(object, '@id'));
        _require(
            id == index,
            'normalization.tileset_id',
            file.entry.relativePath,
            'Tileset ID disagrees with its array index');
        final owner = identity('rmxp-tileset', id);
        final autotiles =
            array(doc, requiredField(object, '@autotile_names'), maximum: 7);
        _require(
            autotiles.length == 7,
            'normalization.autotile_slots',
            file.entry.relativePath,
            'RMXP tileset must retain seven autotile slots');
        final images = <NormalizedMediaReference>[
          resolveImage(file, requiredField(object, '@tileset_name'), owner,
              'tileset', 'Graphics/Tilesets', loc),
          for (var slot = 0; slot < 7; slot++)
            resolveImage(file, autotiles[slot], owner, 'autotile',
                'Graphics/Autotiles', loc,
                slot: slot),
          for (final pair in [
            ('@panorama_name', 'panorama', 'Graphics/Panoramas'),
            ('@fog_name', 'fog', 'Graphics/Fogs'),
            ('@battleback_name', 'battleback', 'Graphics/Battlebacks'),
          ])
            if (object[pair.$1] != null)
              resolveImage(
                  file, object[pair.$1]!, owner, pair.$2, pair.$3, loc),
        ];
        var projectedMetadataCells = 0;
        SourceTable table(String name) {
          final remaining = math.min(limits.maxMetadataCells - metadataCells,
              limits.maxTotalIrNodes - irNodes - projectedMetadataCells);
          _require(
              remaining > 0,
              'normalization.quota.metadata_cells',
              file.entry.relativePath,
              'Tileset metadata quota exceeded before allocation');
          final table = const TableDecoder().decode(
              doc.node(requiredField(object, name)),
              limits: MarshalDecodeLimits(maxTableCells: remaining));
          _require(
              table.dimensions == 1,
              'normalization.tileset_table',
              file.entry.relativePath,
              'Tileset metadata must be one dimensional');
          metadataCells += table.cellCount;
          projectedMetadataCells += table.cellCount;
          return table;
        }

        final passages = table('@passages');
        final priorities = table('@priorities');
        final terrain = table('@terrain_tags');
        _require(
            passages.cellCount == priorities.cellCount &&
                passages.cellCount == terrain.cellCount,
            'normalization.tileset_table',
            file.entry.relativePath,
            'Tileset metadata tables have different cell counts');
        final tileset = NormalizedTileset(
          sourceTilesetId: id,
          identity: owner,
          name: text(doc, requiredField(object, '@name')),
          images: List.unmodifiable(images),
          passages: passages,
          priorities: priorities,
          terrainTags: terrain,
          rawDataRef: preserve(file, entries[index], loc),
          locator: loc,
        );
        reserveProjection(tileset.toJson(), loc);
        tilesets.add(tileset);
      } on Object catch (error) {
        failure(error, loc);
      }
    }
  }

  void validateUsedImages() {
    final catalog = {
      for (final tileset in tilesets) tileset.sourceTilesetId: tileset
    };
    final mapCatalog = {for (final map in maps) map.map.sourceMapId: map};
    for (final tile in eventTiles) {
      final map = mapCatalog[tile.$1];
      if (map == null) continue;
      final tileset = catalog[map.map.sourceTilesetId];
      if (tileset == null) continue;
      if (tile.$2 < 48) {
        diagnostic('normalization.event_tile_unsupported', tile.$4,
            'Event graphic uses a reserved tile ID ${tile.$2}');
        continue;
      }
      final slot = tile.$2 < 384 ? tile.$2 ~/ 48 - 1 : null;
      final image = tileset.images.singleWhere((image) => slot == null
          ? image.role == 'tileset'
          : image.role == 'autotile' && image.slot == slot);
      final metadataValid = tile.$2 < tileset.passages.cellCount;
      addEventImage(NormalizedMediaReference(
        ownerId: tile.$3,
        role: slot == null ? 'eventTile' : 'eventAutotile',
        sourceName: image.sourceName,
        locator: tile.$4,
        state: image.state == 'resolved' && !metadataValid
            ? 'invalid'
            : image.state == 'none'
                ? 'missing'
                : image.state,
        sourceFile: image.sourceFile,
        appliedImageBinding: image.appliedImageBinding,
        slot: slot,
        sourceTileId: tile.$2,
      ));
      if (image.state != 'resolved') {
        diagnostic('normalization.event_tile_image_missing', tile.$4,
            'Event tile ${tile.$2} requires an unavailable source image');
      }
      if (!metadataValid) {
        diagnostic('normalization.event_tile_metadata_missing', tile.$4,
            'Event tile ${tile.$2} exceeds source tileset metadata',
            blocks: false);
      }
    }
    for (final map in maps) {
      final tileset = catalog[map.map.sourceTilesetId];
      if (tileset == null) continue;
      final usedSlots = <int>{};
      var mainUsed = false;
      for (final layer in map.map.layers) {
        for (final value in layer.cells) {
          if (value >= 384) mainUsed = true;
          if (value >= 48 && value < 384) usedSlots.add(value ~/ 48 - 1);
          if (value != 0 && value >= tileset.passages.cellCount) {
            diagnostic(
                'normalization.tile_metadata_missing',
                locator(archive.files[map.map.sourceFileId]!.entry.relativePath,
                    mapId: map.map.sourceMapId),
                'Tile $value exceeds source tileset metadata');
            break;
          }
        }
      }
      for (final image in tileset.images) {
        if (image.state == 'none' &&
            ((image.role == 'tileset' && mainUsed) ||
                (image.role == 'autotile' && usedSlots.contains(image.slot)))) {
          diagnostic('normalization.empty_used_image', image.locator,
              'Map ${map.map.sourceMapId} uses an empty ${image.role} slot ${image.slot}');
        }
      }
    }
  }
}
