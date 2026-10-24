import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_encounter_terrain_binding.dart';

final class SourceGrassRustleRaster {
  SourceGrassRustleRaster._(this.imageBytes, this.frameCount,
      this.animationName, this.animationImageName);

  final Uint8List imageBytes;
  final int frameCount;
  final String animationName;
  final String animationImageName;

  static SourceGrassRustleRaster compile({
    required List<int> animationArchiveBytes,
    required List<int> animationPngBytes,
    int animationId = 1,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits.validate();
    if (animationArchiveBytes.length > limits.maxArtifactBytes ||
        animationPngBytes.length > limits.maxArtifactBytes) {
      throw const NativeWriteException('grass_rustle.source.quota',
          'Grass source files exceed the artifact byte budget');
    }
    final definition =
        _AnimationDefinition.read(animationArchiveBytes, animationId);
    final size = const NativePngValidator()
        .headerDimensions(animationPngBytes, limits: limits);
    if (size.$1 * size.$2 > limits.maxImagePixels ||
        (definition.frames.length + 1) * 1024 > limits.maxImagePixels ||
        size.$1 * size.$2 + (definition.frames.length + 1) * 1024 >
            limits.maxTotalImagePixels) {
      throw const NativeWriteException('grass_rustle.image.quota',
          'Grass animation images exceed the native pixel budget');
    }
    const NativePngValidator().validate(animationPngBytes, limits: limits);
    final source = image.decodePng(Uint8List.fromList(animationPngBytes));
    if (source == null || source.numFrames != 1) {
      throw const NativeWriteException('grass_rustle.image.decode',
          'Grass animation requires one admitted PNG atlas');
    }
    final raster = image.Image(
        width: (definition.frames.length + 1) * 32, height: 32, numChannels: 4);
    for (var index = 0; index < definition.frames.length; index++) {
      final cell = definition.frames[index];
      final sourceX = cell.pattern % 5 * 192;
      final sourceY = cell.pattern ~/ 5 * 192;
      if (sourceX + 192 > source.width || sourceY + 192 > source.height) {
        throw const NativeWriteException('grass_rustle.image.pattern',
            'Grass animation pattern is outside its source atlas');
      }
      for (var y = 0; y < 192; y++) {
        for (var x = 0; x < 192; x++) {
          final pixel = source.getPixel(sourceX + x, sourceY + y);
          final maximum = source.hasPalette ? 255 : source.maxChannelValue;
          final rawAlpha = source.hasPalette
              ? source.palette!.getAlpha(pixel.index.toInt())
              : source.numChannels == 1 || source.numChannels == 3
                  ? maximum
                  : pixel.a;
          final alpha = (rawAlpha * cell.opacity / maximum).round();
          if (alpha == 0) continue;
          final targetX = 16 + cell.x + (cell.mirror ? 95 - x : x - 96);
          final targetY = 32 + cell.y + y - 96;
          if (targetX < 0 || targetX >= 32 || targetY < 0 || targetY >= 32) {
            throw const NativeWriteException('grass_rustle.image.overflow',
                'Visible grass animation pixels exceed one native cell');
          }
          raster.setPixelRgba(
              (index + 1) * 32 + targetX,
              targetY,
              (pixel.r * 255 / maximum).round(),
              (pixel.g * 255 / maximum).round(),
              (pixel.b * 255 / maximum).round(),
              alpha);
        }
      }
    }
    final output = image.encodePng(raster, level: 9);
    if (output.length > limits.maxArtifactBytes) {
      throw const NativeWriteException('grass_rustle.image.quota',
          'Compiled grass animation exceeds the artifact byte budget');
    }
    return SourceGrassRustleRaster._(output.asUnmodifiableView(),
        definition.frames.length, definition.name, definition.imageName);
  }
}

final class SourceGrassRustleComposition {
  SourceGrassRustleComposition._(
      {required this.artifacts,
      required this.mutations,
      required this.layersBySourceMapId,
      required this.catalog,
      required this.tilesets,
      required this.evidence});

  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final Map<int, SmartTileLayer> layersBySourceMapId;
  final ProjectSmartTileCatalog catalog;
  final List<ProjectTilesetEntry> tilesets;
  final Map<String, Object?> evidence;
}

final class SourceGrassRustleCompiler {
  const SourceGrassRustleCompiler();

  Future<SourceGrassRustleComposition?> compile({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required Map<int, String> nativeMapIds,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    final resolver = SourceSemanticResolver.forProject(source);
    if (!source.canPlan || !resolver.profile.isQualified) {
      return null;
    }
    final maps = {for (final map in source.maps) map.map.sourceMapId: map.map};
    if (nativeMapIds.isEmpty ||
        nativeMapIds.length > limits.maxMaps ||
        nativeMapIds.values.toSet().length != nativeMapIds.length ||
        nativeMapIds.entries.any((entry) =>
            !maps.containsKey(entry.key) ||
            entry.value.isEmpty ||
            entry.value != entry.value.trim())) {
      throw const NativeWriteException('grass_rustle.maps.binding',
          'Grass effects require unique selected native map identities');
    }
    final terrain = SourceEncounterTerrainResolver(resolver: resolver);
    final cellsByMap = <int, List<int>>{};
    for (final id in nativeMapIds.keys.toList()..sort()) {
      cancellation?.check();
      final map = maps[id]!;
      final cells = [
        for (var y = 0; y < map.height; y++)
          for (var x = 0; x < map.width; x++)
            const {
              2,
              14
            }.contains(terrain.resolveTerrainTag(resolver.cellAt(id, x, y)))
                ? 1
                : 0
      ];
      if (cells.contains(1)) cellsByMap[id] = cells;
    }
    if (cellsByMap.isEmpty) return null;
    final scriptEntry = _entry(source, 'Data/Scripts.rxdata');
    if (scriptEntry.sha256 != resolver.profile.scriptsArchiveHash) return null;
    final scriptBytes =
        await _verifiedRead(scriptEntry, files, limits, cancellation);
    final sourceSections =
        _attestGrassSections(scriptBytes, limits, cancellation);
    if (sourceSections == null) return null;
    final animationEntry = _entry(source, 'Data/Animations.rxdata');
    final animationBytes =
        await _verifiedRead(animationEntry, files, limits, cancellation);
    final definition = _AnimationDefinition.read(animationBytes, 1);
    final imageEntry =
        _entry(source, 'Graphics/Animations/${definition.imageName}.png');
    final png = await _verifiedRead(imageEntry, files, limits, cancellation);
    final compiled = SourceGrassRustleRaster.compile(
        animationArchiveBytes: animationBytes,
        animationPngBytes: png,
        limits: limits);
    final artifact = NativeArtifact(bytes: compiled.imageBytes, limits: limits);
    final identity = canonicalHashOf({
      'scripts': scriptEntry.sha256!.value,
      'animation': animationEntry.sha256!.value,
      'image': imageEntry.sha256!.value,
      'animationId': 1,
      'policy': 'nativeOnEnterRustleV1'
    }).value.substring(0, 24);
    final id = 'source-grass-$identity';
    final tilesetId = '$id-image';
    final atlasId = '$id-atlas';
    final materialId = '$id-material';
    final animationId = '$id-motion';
    final presetId = '$id-preset';
    final atlas = ProjectSmartTileAtlas(
        id: atlasId,
        name: 'Bruissement des herbes',
        tilesetId: tilesetId,
        columns: compiled.frameCount + 1,
        rows: 1);
    final material = ProjectSmartTileMaterial(
        id: materialId,
        name: 'Hautes herbes — bruissement',
        connectionGroupId: materialId,
        pathSurfaceKind: PathSurfaceKind.tallGrass);
    SmartTileFrameRef frame(int column) =>
        SmartTileFrameRef(atlasId: atlasId, column: column, row: 0);
    final animation = ProjectSmartTileAnimation(
        id: animationId,
        name: compiled.animationName,
        loop: SmartTileAnimationLoop.once,
        frames: [
          ProjectSmartTileAnimationFrame(frame: frame(0), durationMs: 1),
          for (var i = 0; i < compiled.frameCount; i++)
            ProjectSmartTileAnimationFrame(frame: frame(i + 1), durationMs: 50),
          ProjectSmartTileAnimationFrame(frame: frame(0), durationMs: 1)
        ]);
    final preset = ProjectSmartTilePreset(
        id: presetId,
        name: 'Bruissement des hautes herbes',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        status: SmartTilePresetStatus.published,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: materialId,
        allowedMaterialIds: [
          materialId
        ],
        rules: [
          SmartTileRule(
              id: '$id-rule',
              centerMatch: SmartTileSlotMatch.material(materialId),
              candidates: [
                SmartTileCandidate(id: '$id-form', parts: [
                  SmartTileVisualPart(
                      source: SmartTileVisualSource.animation(
                          animationId: animationId),
                      channel: SmartTileRenderChannel.actorOcclusion)
                ])
              ])
        ]);
    final layers = <int, SmartTileLayer>{
      for (final entry in cellsByMap.entries)
        entry.key: SmartTileLayer(
            id: '${nativeMapIds[entry.key]}_grass_rustle',
            name: 'Bruissement des hautes herbes',
            presetId: presetId,
            usage: SmartTileUsage.path,
            animationActivation: SmartTileAnimationActivation.onEnter,
            materialPalette: ['', materialId],
            field: SmartTileField.cell(semanticCells: entry.value))
    };
    final sourceIds = [
      scriptEntry.fileId,
      animationEntry.fileId,
      imageEntry.fileId
    ];
    NativeMutation mutation(String suffix, String action, List<String> targets,
            Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('$id-$suffix'),
            actionId: action,
            sourceEntityIds: sourceIds,
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    final tileset = ProjectTilesetEntry(
        id: tilesetId,
        name: 'Bruissement des herbes',
        relativePath: 'assets/studio/$tilesetId.png',
        source: ProjectRegularAtlasTilesetSource(
            assetId: 'image_$tilesetId',
            pixelWidth: (compiled.frameCount + 1) * 32,
            pixelHeight: 32,
            tileWidth: 32,
            tileHeight: 32));
    return SourceGrassRustleComposition._(
        artifacts: List.unmodifiable([artifact]),
        mutations: List.unmodifiable([
          mutation('import', 'tileset.import_image', [
            tilesetId,
            'image_$tilesetId'
          ], {
            'artifactHandle': artifact.handle,
            'tilesetId': tilesetId,
            'name': tileset.name,
            'tileWidth': 32,
            'tileHeight': 32
          }),
          mutation('atlas', 'smart_tile.atlas.upsert', [atlasId],
              {'atlas': atlas.toJson()}),
          mutation('material', 'smart_tile.material.upsert', [materialId],
              {'material': material.toJson()}),
          mutation('animation', 'smart_tile.animation.upsert', [animationId],
              {'animation': animation.toJson()}),
          mutation('preset', 'smart_tile.preset.publish', [presetId],
              {'preset': preset.toJson()}),
        ]),
        layersBySourceMapId: Map.unmodifiable(layers),
        catalog: ProjectSmartTileCatalog(
            atlases: [atlas],
            materials: [material],
            animations: [animation],
            presets: [preset]),
        tilesets: List.unmodifiable([tileset]),
        evidence: Map.unmodifiable({
          'kind': 'sourceGrassRustle',
          'version': 1,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'scriptsArchiveHash': scriptEntry.sha256!.value,
          'sourceSections': sourceSections,
          'animationId': 1,
          'animationArchiveHash': animationEntry.sha256!.value,
          'sourceImageHash': imageEntry.sha256!.value,
          'sourceImagePath': imageEntry.relativePath,
          'sourceFrameCount': compiled.frameCount,
          'sourceFrameDurationMs': 50,
          'nativeIdlePolicy': 'oneMillisecondTransparentEntryAndExit',
          'sourceTerrainTags': [2, 14],
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
          'maps': [
            for (final entry in cellsByMap.entries)
              {
                'sourceMapId': entry.key,
                'nativeMapId': nativeMapIds[entry.key],
                'layerId': layers[entry.key]!.id,
                'cellCount': entry.value.where((v) => v != 0).length,
                'cellsHash': canonicalHashOf(entry.value).value
              }
          ],
          'oracle': {
            'Settings': [0, 661],
            'TerrainTag': [113, 86, 92, 180, 186],
            'Overworld': [241, 145, 155],
            'RPG_Sprite': [9, 31, 43, 170, 212],
            'Sprite_AnimationSprite': [66, 6, 24]
          }
        }));
  }
}

const _grassSectionWitnesses = {
  'Settings': (
    0,
    'cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f'
  ),
  'RPG_Sprite': (
    9,
    '353bdd0648e9920f33ab44bf5ade2c13a27494f1d629768b5bcd8ad65849f83f'
  ),
  'Sprite_AnimationSprite': (
    66,
    '686c9e2f81a578cb8774e66c459e7fb637e49e275440849bc325c7b5506e3859'
  ),
  'TerrainTag': (
    113,
    '6bcfb146b4ec27576d2c616392e4aa14f1f9baa135db85ac02b33e0139e7382e'
  ),
  'Overworld': (
    241,
    'c96fe00962737e464754800079f8b1c43a9d2d88ea446c0357211e40383093b6'
  ),
};

Map<String, Object?>? _attestGrassSections(
    List<int> bytes, NativeWriteLimits limits, ScanCancellation? cancellation) {
  final document = const MarshalDecoder().decode(bytes,
      sourcePath: 'Data/Scripts.rxdata',
      limits: MarshalDecodeLimits(
          maxInputBytes: limits.maxArtifactBytes,
          maxDepth: 128,
          maxNodes: 100000,
          maxObjects: 100000,
          maxSymbols: 4096,
          maxContainerEntries: 65536,
          maxTotalEntries: 100000,
          maxStringBytes: limits.maxArtifactBytes,
          maxTotalStringBytes: limits.maxArtifactBytes));
  final root = document.node(document.rootId);
  if (root.kind != MarshalKind.array) return null;
  final facts = <String, Object?>{};
  var expandedBytes = 0;
  for (final witness in _grassSectionWitnesses.entries) {
    cancellation?.check();
    if (witness.value.$1 >= root.elements.length) return null;
    final row = document.node(root.elements[witness.value.$1]);
    if (row.kind != MarshalKind.array || row.elements.length != 3) return null;
    final name = document.node(row.elements[1]);
    final data = document.node(row.elements[2]);
    if (name.kind != MarshalKind.string ||
        name.text().text != witness.key ||
        data.kind != MarshalKind.string ||
        data.bytes == null) {
      return null;
    }
    final remaining = limits.maxTotalArtifactBytes - expandedBytes;
    if (remaining <= 0) {
      throw const NativeWriteException('grass_rustle.source.quota',
          'Grass script witnesses exceed their aggregate byte budget');
    }
    final expanded = const BoundedZlibDecoder().decode(data.bytes!,
        sourcePath: 'Data/Scripts.rxdata',
        baseOffset: data.dataOffset ?? data.location.byteOffset,
        limits: ZlibDecodeLimits(
            maxInputBytes: limits.maxArtifactBytes,
            maxOutputBytes: remaining < limits.jsonLimits.maxStringCodeUnits
                ? remaining
                : limits.jsonLimits.maxStringCodeUnits));
    expandedBytes += expanded.length;
    if (crypto.sha256.convert(expanded).toString() != witness.value.$2) {
      return null;
    }
    facts[witness.key] = Map<String, Object?>.unmodifiable({
      'sectionIndex': witness.value.$1,
      'sha256': witness.value.$2,
    });
  }
  return Map<String, Object?>.unmodifiable(facts);
}

SourceFileEntry _entry(NormalizedSourceProject source, String path) {
  final matches = source.snapshot.entries
      .where((entry) =>
          entry.kind == SourceNodeKind.file &&
          sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(path))
      .toList();
  if (matches.length != 1 || matches.single.sha256 == null) {
    throw const NativeWriteException('grass_rustle.source.missing',
        'Grass animation requires one exact source definition and image');
  }
  return matches.single;
}

Future<Uint8List> _verifiedRead(SourceFileEntry entry, SourceFilePort files,
    NativeWriteLimits limits, ScanCancellation? cancellation) async {
  cancellation?.check();
  if (entry.byteLength > limits.maxArtifactBytes) {
    throw const NativeWriteException('grass_rustle.source.quota',
        'Grass source file exceeds its byte budget');
  }
  final sourceBytes = await files.read(entry.fileId);
  cancellation?.check();
  const changed = NativeWriteException('grass_rustle.source.changed',
      'Grass source file differs from its admitted snapshot');
  if (sourceBytes.length != entry.byteLength) throw changed;
  final bytes = Uint8List(sourceBytes.length);
  for (var index = 0; index < sourceBytes.length; index++) {
    final value = sourceBytes[index];
    if (value < 0 || value > 255) throw changed;
    bytes[index] = value;
  }
  if (crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
    throw changed;
  }
  return bytes.asUnmodifiableView();
}

final class _AnimationCell {
  const _AnimationCell(this.pattern, this.x, this.y, this.mirror, this.opacity);
  final int pattern, x, y, opacity;
  final bool mirror;
}

final class _AnimationDefinition {
  const _AnimationDefinition(this.name, this.imageName, this.frames);
  final String name, imageName;
  final List<_AnimationCell> frames;

  static _AnimationDefinition read(List<int> bytes, int animationId) {
    Never fail() => throw const NativeWriteException(
        'grass_rustle.animation.unsupported',
        'Grass animation must use bounded single-cell RGSS frames without custom effects');
    try {
      final doc = const MarshalDecoder().decode(bytes);
      final root = doc.node(doc.rootId);
      if (root.kind != MarshalKind.array ||
          animationId < 1 ||
          animationId >= root.elements.length) {
        fail();
      }
      final animation = doc.node(root.elements[animationId]);
      MarshalNode field(MarshalNode node, String key) {
        final rows = node.instanceVariables
            .where((pair) => doc.node(pair.key).name == key)
            .toList();
        if (rows.length != 1) {
          fail();
        }
        return doc.node(rows.single.value);
      }

      int integer(MarshalNode node) {
        if (node.kind != MarshalKind.integer) fail();
        return node.integerValue!.toInt();
      }

      String text(MarshalNode node) {
        if (node.kind != MarshalKind.string || node.text().text == null) fail();
        return node.text().text!;
      }

      if (animation.className != 'RPG::Animation' ||
          integer(field(animation, '@id')) != animationId ||
          integer(field(animation, '@animation_hue')) != 0 ||
          integer(field(animation, '@position')) != 1 ||
          field(animation, '@timings').kind != MarshalKind.array ||
          field(animation, '@timings').elements.isNotEmpty) {
        fail();
      }
      final name = text(field(animation, '@name'));
      final imageName = text(field(animation, '@animation_name'));
      if (name.trim().isEmpty ||
          name.length > 256 ||
          imageName.isEmpty ||
          imageName.length > 192 ||
          imageName.contains('/') ||
          imageName.contains('\\') ||
          imageName.contains('..') ||
          RegExp(r'\[\s*\d+\s*\]\s*$').hasMatch(name)) {
        fail();
      }
      final rawFrames = field(animation, '@frames');
      if (rawFrames.kind != MarshalKind.array ||
          rawFrames.elements.isEmpty ||
          rawFrames.elements.length > 256 ||
          integer(field(animation, '@frame_max')) !=
              rawFrames.elements.length) {
        fail();
      }
      final frames = <_AnimationCell>[];
      for (final id in rawFrames.elements) {
        final frame = doc.node(id);
        if (frame.className != 'RPG::Animation::Frame' ||
            integer(field(frame, '@cell_max')) != 1) {
          fail();
        }
        final table = const TableDecoder().decode(field(frame, '@cell_data'));
        if (table.xSize != 1 || table.ySize != 8 || table.zSize != 1) fail();
        final values = [for (var i = 0; i < 8; i++) table.valueAt(0, i, 0)];
        if (values[0] < 0 ||
            values[3] != 100 ||
            values[4] != 0 ||
            !const {0, 1}.contains(values[5]) ||
            values[6] < 0 ||
            values[6] > 255 ||
            values[7] != 0 ||
            values[1].abs() > 96 ||
            values[2].abs() > 96) {
          fail();
        }
        frames.add(_AnimationCell(
            values[0], values[1], values[2], values[5] == 1, values[6]));
      }
      return _AnimationDefinition(name, imageName, List.unmodifiable(frames));
    } on NativeWriteException {
      rethrow;
    } on Object {
      fail();
    }
  }
}
