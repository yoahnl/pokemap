import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelSize;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'literal_tile_composer.dart';
import 'native_project_writer.dart';

final class SourceDirectedJumpStudyComposition {
  SourceDirectedJumpStudyComposition(
      {required this.project,
      required Map<int, MapData> preparedMaps,
      required Map<int, MapData> nativeMaps,
      required List<NativeArtifact> artifacts,
      required List<NativeMutation> resourceMutations,
      required List<NativeMutation> mapMutations,
      required Map<String, Object?> evidence,
      required ContractLimits jsonLimits})
      : preparedMaps = Map.unmodifiable(preparedMaps),
        nativeMaps = Map.unmodifiable(nativeMaps),
        artifacts = List.unmodifiable(artifacts),
        resourceMutations = List.unmodifiable(resourceMutations),
        mapMutations = List.unmodifiable(mapMutations),
        evidence =
            _freeze(jsonDecode(canonicalJsonOf(evidence, limits: jsonLimits)))
                as Map<String, Object?>;
  final ProjectManifest project;
  final Map<int, MapData> preparedMaps;
  final Map<int, MapData> nativeMaps;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> resourceMutations;
  final List<NativeMutation> mapMutations;
  final Map<String, Object?> evidence;
  List<NativeMutation> get mutations =>
      List.unmodifiable([...resourceMutations, ...mapMutations]);
}

final class SourceBorderMutationReplay {
  SourceBorderMutationReplay(
      this.project, Map<String, MapData> maps, Map<String, List<int>> files)
      : maps = Map.unmodifiable(maps),
        files = Map.unmodifiable({
          for (final entry in files.entries)
            entry.key: List<int>.unmodifiable(entry.value)
        });
  final ProjectManifest project;
  final Map<String, MapData> maps;
  final Map<String, List<int>> files;
}

Future<SourceBorderMutationReplay> replaySourceBorderMutation({
  required ProjectManifest project,
  required Map<String, MapData> maps,
  required NativeMutation mutation,
  required Iterable<NativeArtifact> artifacts,
  NativeWriteLimits limits = const NativeWriteLimits(),
  ScanCancellation? cancellation,
}) async {
  cancellation?.check();
  limits.validate();
  if (!const {
    'border.blueprint.draft.upsert',
    'border.blueprint.publish',
    'border_layer.feature_create',
    'border_layer.feature_set_replacement',
    'border_layer.materialize_apply'
  }.contains(mutation.actionId)) {
    throw const NativeWriteException(
        'jumps.action', 'Unsupported source Border mutation');
  }
  final storage = <String, String>{
    'project': 'project.json',
    for (final entry in project.maps)
      if (maps.containsKey(entry.id)) 'map:${entry.id}': entry.relativePath
  };
  final bytes = <String, List<int>>{
    'project': utf8.encode(jsonEncode(project.toJson())),
    for (final map in maps.values)
      'map:${map.id}': utf8.encode(jsonEncode(map.toJson()))
  };
  final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('source-border-study'),
      revision: computeAuthoringBytesFingerprint(bytes['project']!,
          logicalName: 'project.json'),
      manifest: project,
      maps: maps.values.toList(),
      resourceFingerprints: {
        for (final entry in bytes.entries)
          entry.key: computeAuthoringBytesFingerprint(entry.value,
              logicalName: storage[entry.key]!)
      },
      resourceBytes: bytes,
      resourceStorageKeys: storage);
  final context = AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
          requestId: mutation.operationId.value,
          actionId: mutation.actionId,
          actionVersion: mutation.actionVersion,
          workspaceHandle: 'source-border-study',
          parameters: mutation.parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: mutation.operationId.value),
      planId: mutation.operationId.value,
      seed: 0);
  final store =
      MemoryArtifactStore(maximumArtifactBytes: limits.maxArtifactBytes);
  if (mutation.actionId == 'border.blueprint.publish') {
    for (final artifact in artifacts) {
      cancellation?.check();
      await store.put(artifact.bytes,
          declaredMediaType: artifact.reference.mediaType);
    }
  }
  cancellation?.check();
  final draft = mutation.actionId.startsWith('border.')
      ? await BorderCatalogActions(artifactStore: store).build(context)
      : const BorderActions().build(context);
  cancellation?.check();
  var nextProject = project;
  final nextMaps = Map<String, MapData>.from(maps);
  final companions = <String, List<int>>{};
  var total = 0;
  for (final change in draft.changeSet.changes) {
    final after = change.afterBytes;
    if (after == null) {
      throw const NativeWriteException(
          'jumps.action', 'Source Border mutations cannot delete resources');
    }
    total += after.length;
    if (total > limits.maxTotalDraftJsonBytes) {
      throw const NativeWriteException('jumps.quota.action',
          'Canonical Border changes exceed the aggregate byte budget');
    }
    if (change.resource.kind == 'project') {
      nextProject = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(after)) as Map<String, dynamic>);
    } else if (change.resource.kind == 'map') {
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(after)) as Map<String, dynamic>);
      nextMaps[map.id] = map;
    } else {
      if (after.length > limits.maxArtifactBytes) {
        throw const NativeWriteException('jumps.quota.artifact',
            'Canonical Border snapshot exceeds the byte budget');
      }
      const NativePngValidator().validate(after, limits: limits);
      companions[change.storageKey] = after;
    }
  }
  return SourceBorderMutationReplay(nextProject, nextMaps, companions);
}

final class SourceDirectedJumpStudyComposer {
  const SourceDirectedJumpStudyComposer();
  Future<SourceDirectedJumpStudyComposition> compose({
    required NormalizedSourceProject source,
    required LiteralTileComposition base,
    required Map<int, MapData> nativeMaps,
    required ProjectManifest project,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final resolver = SourceSemanticResolver.forProject(source);
    _validateReferences(project, nativeMaps.values);
    final rows = <Map<String, Object?>>[];
    final diagnostics = <Map<String, Object?>>[];
    final maps = Map<int, MapData>.from(nativeMaps);
    final prepared = Map<int, MapData>.from(nativeMaps);
    final artifacts = <String, NativeArtifact>{};
    final resourceMutations = <NativeMutation>[];
    final mapMutations = <NativeMutation>[];
    var manifest = project;
    final evidence = <String, Object?>{
      'kind': 'sourceDirectedJumpStudy',
      'version': 2,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'sourceProfile': resolver.profile.toJson(),
      'sourceProfileQualified': resolver.profile.isQualified,
      'scope': 'kantoStaticSouthLedgeLine32',
      'nativeTemplate': 'ledgeLine',
      'nativeResolverVersion': borderResolverVersion,
      'sourceEventStateQualified': false,
      'nativeAnimationQualified': false,
      'runtimeJourneyQualified': false,
      'sourceBattleScriptsExecuted': false,
      'aiCalls': 0,
      'eventFootprintPolicy': 'excludeSourceDepartureViaAndLanding',
      'genericCollisionMasksRemoved': 0,
      'rows': rows,
      'diagnostics': diagnostics,
    };
    SourceDirectedJumpStudyComposition finish() {
      evidence['importedJumpCount'] =
          rows.where((r) => r['nativeStatus'] == 'imported').length;
      evidence['operationIds'] = [...resourceMutations, ...mapMutations]
          .map((m) => m.operationId.value)
          .toList();
      if (resourceMutations.length + mapMutations.length >
          limits.maxMutations) {
        throw const NativeWriteException('jumps.quota.mutations',
            'Directed Border actions exceed the explicit mutation budget');
      }
      canonicalJsonOf(evidence, limits: limits.jsonLimits);
      _validateReferences(manifest, maps.values);
      return SourceDirectedJumpStudyComposition(
          project: manifest,
          preparedMaps: prepared,
          nativeMaps: maps,
          artifacts: artifacts.values.toList(),
          resourceMutations: resourceMutations,
          mapMutations: mapMutations,
          evidence: evidence,
          jsonLimits: limits.jsonLimits);
    }

    if (!resolver.profile.isQualified) return finish();
    if (base.draft == null ||
        base.draft!.source.canonicalHash != source.canonicalHash ||
        project.settings.tileWidth != 32 ||
        project.settings.tileHeight != 32 ||
        maps.values.map((m) => m.id).toSet().length != maps.length) {
      throw const NativeWriteException('jumps.native_binding',
          'Source Border study requires exact qualified source and 32px native maps');
    }
    final selected = maps.keys.toList()..sort();
    final dataRefs = <ConverterId>{
      for (final map
          in source.maps.where((m) => selected.contains(m.map.sourceMapId)))
        map.map.sourceFileId,
      for (final entry in source.snapshot.entries.where((e) =>
          e.kind == SourceNodeKind.file &&
          const {'data/tilesets.rxdata', 'data/scripts.rxdata'}
              .contains(sourcePathCollisionKey(e.relativePath))))
        entry.fileId,
    };
    final dataEvidence = <Map<String, Object?>>[];
    for (final fileId in dataRefs) {
      cancellation?.check();
      final entry =
          source.snapshot.entries.singleWhere((e) => e.fileId == fileId);
      final bytes = await files.read(fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          sha256.convert(bytes).toString() != entry.sha256?.value) {
        throw const NativeWriteException('jumps.source_changed',
            'Directed Border source bytes differ from their sealed archive');
      }
      dataEvidence.add({
        'fileId': fileId.value,
        'path': entry.relativePath,
        'byteLength': bytes.length,
        'sha256': entry.sha256!.value
      });
    }
    evidence['sourceFiles'] = dataEvidence;
    final candidates = <int, List<_Jump>>{};
    var cellCount = 0;
    for (final id in selected) {
      cancellation?.check();
      final original =
          source.maps.singleWhere((m) => m.map.sourceMapId == id).map;
      final native = maps[id]!;
      cellCount += native.size.width * native.size.height;
      if (native.size.width != original.width ||
          native.size.height != original.height ||
          cellCount > limits.maxMapCells) {
        throw const NativeWriteException('jumps.native_binding',
            'Directed Border maps require exact bounded source geometry');
      }
      for (var y = 0; y < original.height; y++) {
        cancellation?.check();
        for (var x = 0; x < original.width; x++) {
          final via = resolver.cellAt(id, x, y);
          if (!via.stack
              .any((tile) => tile.tileId != 0 && tile.terrainTag == 1)) {
            continue;
          }
          for (final direction in SourceCardinalDirection.values) {
            final from =
                resolver.cellAt(id, x - direction.dx, y - direction.dy);
            final landing =
                resolver.cellAt(id, x + direction.dx, y + direction.dy);
            final passage =
                resolver.resolveDirectedJump(from, via, landing, direction);
            final row = <String, Object?>{
              'sourceMapId': id,
              'nativeMapId': native.id,
              'from': [from.x, from.y],
              'via': [x, y],
              'landing': [landing.x, landing.y],
              'direction': direction.name,
              'status': passage.status.name,
              'reason': passage.reason.name,
              'sourceTraceHash':
                  canonicalHashOf(passage.toJson(), limits: limits.jsonLimits)
                      .value,
              'nativeStatus': 'notImported'
            };
            if (rows.length >= limits.jsonLimits.maxNodes ~/ 32) {
              throw const NativeWriteException('jumps.quota.evidence',
                  'Directed jump traces exceed the explicit inert JSON budget');
            }
            rows.add(row);
            if (passage.isPassable != true) continue;
            void gap(String code) {
              row['nativeStatus'] = 'preservedOnly';
              diagnostics.add({
                'code': code,
                'sourceMapId': id,
                'via': [x, y],
                'direction': direction.name
              });
            }

            if (direction != SourceCardinalDirection.down) {
              gap('jumps.orientation_unqualified');
              continue;
            }
            if (_hasSourceEventFootprint(original, [from, via, landing])) {
              gap('jumps.source_event_footprint');
              continue;
            }
            final ledges = via.stack
                .where((t) =>
                    t.sourceZ == 1 &&
                    t.tileId >= 384 &&
                    t.terrainTag == 1 &&
                    t.priority == 0 &&
                    t.passage == 7)
                .toList();
            if (ledges.length != 1) {
              gap('jumps.source_glyph_unqualified');
              continue;
            }
            final crop = base.crops.singleWhere((c) =>
                c.sourceTilesetId == original.sourceTilesetId &&
                c.sourceTileId == ledges.single.tileId);
            final provenance = base.layerProvenance
                .singleWhere((p) => p.sourceMapId == id && p.sourceZ == 1);
            final layer = native.layers
                .whereType<TileLayer>()
                .where((l) => l.id == provenance.nativeLayerId)
                .toList();
            final index = y * original.width + x;
            if (layer.length != 1 ||
                layer.single.cells[index] != crop.paletteCell ||
                crop.priority != 0 ||
                crop.terrainTag != 1 ||
                crop.passage != 7 ||
                crop.autotileSlot != null ||
                crop.paletteCell <= 0 ||
                crop.paletteCell > layer.single.palette.length ||
                layer.single.palette[crop.paletteCell - 1] !=
                    TileLayerPaletteEntry(
                        tilesetId: crop.nativeTilesetId,
                        localTileId: crop.nativeLocalTileId) ||
                provenance.sourceLayerHash !=
                    canonicalHashOf(original.layers
                        .singleWhere((l) => l.sourceZ == 1)
                        .cells)) {
              throw const NativeWriteException('jumps.native_glyph',
                  'Source Border requires the exact owned Z1 cell, palette, crop and source layer');
            }
            final sourceFile = source.snapshot.entries
                .singleWhere((f) => f.fileId == crop.imageFileId);
            final atlas = project.tilesets
                .singleWhere((t) => t.id == crop.nativeTilesetId);
            final regular = atlas.source;
            if (sourceFile.sha256 != crop.imageSha256 ||
                regular is! ProjectRegularAtlasTilesetSource ||
                regular.tileWidth != 32 ||
                regular.tileHeight != 32 ||
                regular.tileAnimations.isNotEmpty ||
                regular.assetId != 'image_${atlas.id}' ||
                regular.columns * (crop.y ~/ 32) + crop.x ~/ 32 !=
                    crop.nativeLocalTileId) {
              throw const NativeWriteException('jumps.native_glyph',
                  'Directed Border atlas must bind the exact static source image and crop');
            }
            final key = canonicalHashOf({
              'namespace': source.snapshot.logicalProjectNamespace.value,
              'sourceTileset': original.sourceTilesetId,
              'sourceTile': crop.sourceTileId,
              'image': crop.imageSha256.value
            }).value.substring(0, 40);
            (candidates[id] ??= [])
                .add(_Jump(id, x, y, layer.single.id, crop, key, row));
          }
        }
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (candidates.isEmpty) return finish();
    final minimumActions = 3 +
        {
          for (final list in candidates.values)
            for (final j in list) j.key
        }.length +
        candidates.values.fold<int>(0, (n, list) => n + list.length + 2);
    if (minimumActions > limits.maxMutations) {
      throw const NativeWriteException('jumps.quota.mutations',
          'Directed Border actions exceed the explicit mutation budget');
    }
    final glyphs = <String, _Glyph>{};
    final decoded = <ConverterId, image.Image>{};
    final bytesById = <ConverterId, List<int>>{};
    for (final list in candidates.values) {
      for (final jump in list) {
        cancellation?.check();
        if (glyphs.containsKey(jump.key)) continue;
        final crop = jump.crop;
        var bytes = bytesById[crop.imageFileId];
        if (bytes == null) {
          bytes = await files.read(crop.imageFileId);
          cancellation?.check();
          final entry = source.snapshot.entries
              .singleWhere((f) => f.fileId == crop.imageFileId);
          if (bytes.length != entry.byteLength ||
              Sha256Hash(sha256.convert(bytes).toString()) !=
                  crop.imageSha256) {
            throw const NativeWriteException('jumps.source_image_changed',
                'Directed Border source image differs from its sealed witness');
          }
          const NativePngValidator().validate(bytes, limits: limits);
          decoded[crop.imageFileId] =
              image.decodePng(Uint8List.fromList(bytes))!;
          bytesById[crop.imageFileId] = bytes;
          final artifact = NativeArtifact(
              bytes: bytes, expectedSha256: crop.imageSha256, limits: limits);
          artifacts[artifact.handle] = artifact;
        }
        final raster = decoded[crop.imageFileId]!;
        if (crop.x + 32 > raster.width || crop.y + 32 > raster.height) {
          throw const NativeWriteException('jumps.native_glyph',
              'Directed Border crop lies outside the exact atlas');
        }
        for (var py = 0; py < 32; py++) {
          for (var px = 0; px < 32; px++) {
            if (py < 16 && raster.getPixel(crop.x + px, crop.y + py).a > 0) {
              throw const NativeWriteException('jumps.glyph_shape',
                  'Only complete south modules with exact transparent top16 are qualified');
            }
          }
        }
        final elementId = 'ac15-ledge-element-${jump.key}';
        final path = project.tilesets
            .singleWhere((t) => t.id == crop.nativeTilesetId)
            .relativePath;
        final frame = CanonicalBorderSourceFrame(
            sourceProjectRelativePath: path,
            encodedImageBytes: bytes,
            sourceRectPx:
                BorderPixelRect(x: crop.x, y: crop.y, width: 32, height: 32),
            durationMs: 100);
        final prep = const CanonicalBorderSnapshotCompiler().prepare(
            sourceElementId: elementId,
            frames: [frame],
            anchorPx: const BorderPixelPos(x: 16, y: 31));
        if (prep.metrics.opaqueBounds !=
            BorderPixelRect(x: 0, y: 16, width: 32, height: 16)) {
          throw const NativeWriteException('jumps.glyph_shape',
              'The exact south source module must occupy the lower16 bounds of its 32px carrier');
        }
        glyphs[jump.key] = _Glyph(
            jump,
            elementId,
            prep,
            frame,
            artifacts.values
                .singleWhere((a) => a.rawSha256 == crop.imageSha256)
                .handle);
      }
    }
    final categoryId = _id(
        'ac15-ledge-category', source.snapshot.logicalProjectNamespace.value);
    final catalogId = _id('ac15-ledge-blueprint', [...glyphs.keys].join(':'));
    final category =
        ProjectElementCategory(id: categoryId, name: 'Rebords source');
    final elements = [
      for (final glyph in glyphs.values)
        ProjectElementEntry(
            id: glyph.elementId,
            name: 'Rebord source ${glyph.jump.crop.sourceTileId}',
            tilesetId: glyph.jump.crop.nativeTilesetId,
            categoryId: categoryId,
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(
                      x: glyph.jump.crop.x ~/ 32, y: glyph.jump.crop.y ~/ 32))
            ],
            collisionProfile:
                const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]))
    ];
    if (project.elementCategories.any((c) => c.id == categoryId) ||
        project.elements.any((e) => elements.any((g) => g.id == e.id)) ||
        project.borderCatalog.recordById(catalogId) != null) {
      throw const NativeWriteException('jumps.identity_conflict',
          'Source Border identities already exist in the native context');
    }
    manifest = manifest.copyWith(
        elementCategories: [...manifest.elementCategories, category],
        elements: [...manifest.elements, ...elements]);
    final resourceRefs = <ConverterId>{
      ...dataRefs,
      for (final g in glyphs.values) g.jump.crop.imageFileId,
      for (final id in candidates.keys) source.mapIdentity(id)
    }.toList();
    NativeMutation action(
            String suffix,
            String actionId,
            List<ConverterId> refs,
            List<String> targets,
            Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId(_id('ac15-ledge-op', suffix)),
            actionId: actionId,
            sourceEntityIds: refs,
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    resourceMutations.add(action(
        '$catalogId-category',
        'element_category.upsert',
        resourceRefs,
        [categoryId],
        {'category': category.toJson()}));
    for (final element in elements) {
      resourceMutations.add(action(element.id, 'element.upsert', resourceRefs,
          [element.id], {'element': element.toJson()}));
    }
    final definition = BorderBlueprintDraftDefinition(
        name: 'Rebords source sud',
        previewSeed: BorderSignedInt64.fromInt(0),
        template: BorderBlueprintTemplate.ledgeLine,
        sortOrder: 0,
        categoryId: categoryId,
        defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 1000,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
            allowAutoRotation: false),
        jumpBehavior: BorderJumpBehavior(
            side: BorderLineSide.primary, durationMs: 500, peakHeightPx: 24),
        primitives: [
          for (final g in glyphs.values)
            BorderPrimitiveDraft(
                id: g.jump.key,
                sourceElementId: g.elementId,
                role: BorderPrimitiveRole.structureLarge,
                authoredOrientation: BorderPrimitiveOrientation.south,
                weight: 1,
                anchorPx: const BorderPixelPos(x: 16, y: 31),
                transforms: BorderTransformPolicy(
                    allowFlipX: false, allowedQuarterTurns: [0]),
                currentMetrics: g.preparation.metrics)
        ]);
    final record = BorderBlueprintRecord(
        id: catalogId,
        draft: BorderBlueprintDraft(baseRevision: 0, definition: definition));
    for (final mutation in [
      action(
          '$catalogId-draft', 'border.blueprint.draft.upsert', resourceRefs, [
        catalogId
      ], {
        'record': encodeBorderBlueprintRecordJson(record, formatVersion: 7)
      }),
      action('$catalogId-publish', 'border.blueprint.publish', resourceRefs, [
        catalogId
      ], {
        'blueprintId': catalogId,
        'primitiveSources': [
          for (final g in glyphs.values)
            {
              'primitiveId': g.jump.key,
              'frames': [
                {
                  'artifactHandle': g.artifactHandle,
                  'sourceProjectRelativePath':
                      g.frame.sourceProjectRelativePath,
                  'sourceRectPx': {
                    'x': g.jump.crop.x,
                    'y': g.jump.crop.y,
                    'width': 32,
                    'height': 32
                  },
                  'durationMs': 100
                }
              ]
            }
        ],
        'groundSources': [],
        'acceptedWarningCodes': []
      }),
    ]) {
      final replay = await replaySourceBorderMutation(
          project: manifest,
          maps: {for (final m in maps.values) m.id: m},
          mutation: mutation,
          artifacts: artifacts.values,
          limits: limits,
          cancellation: cancellation);
      manifest = replay.project;
      resourceMutations.add(mutation);
    }
    evidence['glyphs'] = [
      for (final g in glyphs.values)
        {
          'crop': g.jump.crop.toJson(),
          'primitiveId': g.jump.key,
          'elementId': g.elementId,
          'snapshotId': g.preparation.snapshot.id,
          'snapshotFingerprint': g.preparation.snapshot.contentFingerprint,
          'anchorPx': {'x': 16, 'y': 31},
          'quarterTurns': 0,
          'flipX': false
        }
    ];
    for (final id in selected) {
      final jumps = candidates[id] ?? [];
      if (jumps.isEmpty) continue;
      final layerId = _id('ac15-ledge-layer', source.mapIdentity(id).value);
      final featureId = _id('ac15-ledge-feature', source.mapIdentity(id).value);
      final emptyLayer = MapLayer.border(
          id: layerId,
          name: 'Rebords source Z1',
          content: BorderLayerContent(formatVersion: 3));
      final before = maps[id]!;
      final originalLayerId = jumps.first.layerId;
      if (jumps.any((j) => j.layerId != originalLayerId) ||
          before.layers.any((l) => l.id == layerId)) {
        throw const NativeWriteException(
            'jumps.native_glyph', 'Source Border layer ownership is ambiguous');
      }
      final insertion =
          before.layers.indexWhere((l) => l.id == originalLayerId);
      MapData seedMap(List<_Jump> entries) {
        final cells = (before.layers[insertion] as TileLayer).cells.toList();
        for (final j in entries) {
          cells[j.y * before.size.width + j.x] = 0;
        }
        return before.copyWith(layers: [
          for (var i = 0; i < before.layers.length; i++)
            if (i == insertion) ...[
              emptyLayer,
              (before.layers[i] as TileLayer).copyWith(cells: cells)
            ] else
              before.layers[i]
        ]);
      }

      Future<({MapData map, List<NativeMutation> actions})> materialize(
          List<_Jump> entries) async {
        var map = seedMap(entries);
        final local = <NativeMutation>[];
        final geometry = BorderStrokeGeometry(
            alignment: BorderStrokeAlignment.gridEdges,
            strokes: _strokes(entries, source.mapIdentity(id).value));
        final refs = [
          source.mapIdentity(id),
          ...dataRefs,
          ...{for (final j in entries) j.crop.imageFileId}
        ];
        Future<void> apply(String suffix, String actionId,
            Map<String, Object?> parameters) async {
          final mutation = action('$featureId-$suffix', actionId, refs, [
            map.id
          ], {
            'mapId': map.id,
            'layerId': layerId,
            'featureId': featureId,
            ...parameters
          });
          final replay = await replaySourceBorderMutation(
              project: manifest,
              maps: {map.id: map},
              mutation: mutation,
              artifacts: artifacts.values,
              limits: limits,
              cancellation: cancellation);
          map = replay.maps[map.id]!;
          local.add(mutation);
        }

        await apply('create', 'border_layer.feature_create', {
          'name': 'Rebords source',
          'blueprintId': catalogId,
          'seed': '0',
          'geometry':
              encodeBorderFeatureGeometryJson(geometry, formatVersion: 3),
          'lineSide': 'primary'
        });
        final feature = map.layers
            .whereType<BorderLayer>()
            .singleWhere((l) => l.id == layerId)
            .content
            .features
            .single;
        final request = BorderResolutionRequest(
            mapSize: map.size,
            tileSizePx: const GridSize(width: 32, height: 32),
            blueprintId: catalogId,
            blueprintRevision:
                manifest.borderCatalog.recordById(catalogId)!.latestPublished!,
            feature: feature,
            visualSnapshots: manifest.borderCatalog.visualSnapshots,
            resolverVersion: borderResolverVersion);
        final edges = <GridPos, List<LedgeLineEdgePlacementEvidence>>{};
        for (final edge in resolveLedgeLineBorderWithEvidence(request).edges) {
          edges.putIfAbsent(edge.expectedCarrierCell, () => []).add(edge);
        }
        for (final j in entries) {
          final edge = edges[GridPos(x: j.x, y: j.y)] ?? [];
          if (edge.length != 1) {
            throw const NativeWriteException('jumps.border_owner',
                'Source unit edge must resolve one exact canonical carrier');
          }
          await apply('replacement-${j.x}-${j.y}',
              'border_layer.feature_set_replacement', {
            'slotKey': edge.single.finalPlacement.slotKey,
            'primitiveId': j.key
          });
        }
        await apply('materialize', 'border_layer.materialize_apply', {
          'tileWidthPx': 32,
          'tileHeightPx': 32,
          'resolverVersion': borderResolverVersion
        });
        return (map: map, actions: local);
      }

      var materialized = await materialize(jumps);
      final world = GameplayWorldState.initial(
          map: materialized.map,
          project: manifest,
          playerPos: const GridPos(x: 0, y: 0),
          tileWidth: 32,
          tileHeight: 32);
      final allowed = <_Jump>[];
      for (final j in jumps) {
        cancellation?.check();
        final start = world.withPlayer(GameplayPlayerState.fromGridSpawn(
            cell: GridPos(x: j.x, y: j.y - 1),
            facing: Direction.south,
            tileWidthPx: 32,
            tileHeightPx: 32,
            mapWidthCells: before.size.width,
            mapHeightCells: before.size.height));
        final result = stepGameplayWorld(
            start, const MoveIntent(Direction.south, pixelsPerStep: 32));
        if (start.worldStaticObstaclesCollidePlayerCollisionRect() ||
            result is! Jumped ||
            result.plan.binding.owner.layerId != layerId ||
            result.plan.binding.owner.featureId != featureId ||
            result.plan.viaPos != GridPos(x: j.x, y: j.y) ||
            result.plan.landingPos != GridPos(x: j.x, y: j.y + 1)) {
          j.row['nativeStatus'] = 'preservedOnly';
          diagnostics.add({
            'code': 'jumps.native_admission_refused',
            'sourceMapId': id,
            'via': [j.x, j.y]
          });
        } else {
          allowed.add(j);
        }
      }
      if (allowed.isEmpty) continue;
      if (allowed.length != jumps.length) {
        materialized = await materialize(allowed);
      }
      prepared[id] = seedMap(allowed);
      maps[id] = materialized.map;
      mapMutations.addAll(materialized.actions);
      for (final j in allowed) {
        j.row.addAll({
          'nativeStatus': 'imported',
          'layerId': layerId,
          'featureId': featureId,
          'primitiveId': j.key,
          'sourceZ': 1,
          'sourceTileId': j.crop.sourceTileId,
          'nativeLayerId': j.layerId
        });
      }
    }
    if (mapMutations.isEmpty) {
      manifest = project;
      resourceMutations.clear();
      artifacts.clear();
    }
    return finish();
  }
}

final class _Jump {
  _Jump(
      this.mapId, this.x, this.y, this.layerId, this.crop, this.key, this.row);
  final int mapId, x, y;
  final String layerId, key;
  final LiteralTileCrop crop;
  final Map<String, Object?> row;
}

final class _Glyph {
  _Glyph(this.jump, this.elementId, this.preparation, this.frame,
      this.artifactHandle);
  final _Jump jump;
  final String elementId, artifactHandle;
  final CanonicalBorderSnapshotPreparation preparation;
  final CanonicalBorderSourceFrame frame;
}

List<BorderStroke> _strokes(List<_Jump> entries, String identity) {
  final runs = <List<_Jump>>[];
  for (final j in entries) {
    if (runs.isEmpty ||
        runs.last.last.y != j.y ||
        runs.last.last.x + 1 != j.x) {
      runs.add([j]);
    } else {
      runs.last.add(j);
    }
  }
  return [
    for (final run in runs)
      BorderStroke(
          id: _id('ac15-ledge-stroke',
              '$identity:${run.first.x}:${run.first.y}:${run.last.x + 1}'),
          points: [
            for (var x = run.first.x; x <= run.last.x + 1; x++)
              GridPos(x: x, y: run.first.y)
          ],
          closed: false)
  ];
}

String _id(String prefix, String key) =>
    '$prefix-${canonicalHashOf(key).value.substring(0, 36)}';
void _validateReferences(ProjectManifest project, Iterable<MapData> maps) {
  try {
    ProjectValidator.validate(project, maps: maps);
    for (final map in maps) {
      MapValidator.validate(map, projectDialogueContext: project);
    }
  } on ValidationException catch (e) {
    throw NativeWriteException('jumps.native_references',
        'Directed Border admission requires a complete native reference context: ${e.message}');
  }
}

bool _hasSourceEventFootprint(
    SourceMapData source, Iterable<SourceSemanticCell> cells) {
  for (final event in source.events) {
    final size = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
        .firstMatch(event.name);
    final width = size == null ? 1 : int.tryParse(size.group(1)!);
    final height = size == null ? 1 : int.tryParse(size.group(2)!);
    if (width == null || height == null || width < 1 || height < 1) return true;
    for (final cell in cells) {
      if (cell.x >= event.x &&
          cell.x < event.x + width &&
          cell.y > event.y - height &&
          cell.y <= event.y) {
        return true;
      }
    }
  }
  return false;
}

Object? _freeze(Object? value) => switch (value) {
      Map() => Map<String, Object?>.unmodifiable(
          value.map((key, item) => MapEntry(key as String, _freeze(item)))),
      List() => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
