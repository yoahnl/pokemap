import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceTownMapBindingUnavailable implements Exception {
  const SourceTownMapBindingUnavailable(this.reason);
  final String reason;
}

final class SourceTownMapBinding {
  SourceTownMapBinding._({
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.nativeMapId,
    required this.catalog,
    required this.artifact,
    required List<SourceFileEntry> files,
    required List<NativeMutation> mutations,
    required Map<String, Object?> evidence,
  })  : _files = List.unmodifiable(files),
        mutations = List.unmodifiable(mutations),
        evidence = _freeze(evidence) as Map<String, Object?>;

  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final String nativeMapId;
  final ProjectRegionalMapCatalog catalog;
  final NativeArtifact artifact;
  final List<NativeMutation> mutations;
  final Map<String, Object?> evidence;
  final List<SourceFileEntry> _files;

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile,
          Map<int, String> nativeMapIds) =>
      sourceSnapshotHash == source.snapshot.canonicalHash &&
      normalizationHash == source.canonicalHash &&
      profileHash == profile.canonicalHash &&
      nativeMapIds[102] == nativeMapId &&
      _files.every((file) => source.snapshot.entries.any((current) =>
          current.fileId == file.fileId &&
          current.relativePath == file.relativePath &&
          current.sha256 == file.sha256 &&
          current.byteLength == file.byteLength &&
          current.kind == SourceNodeKind.file));
}

final class SourceTownMapBindingResolver {
  const SourceTownMapBindingResolver();

  Future<SourceTownMapBinding> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required Map<int, String> nativeMapIds,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    final profile = SourceEventProfile.kantoForProject(source);
    if (!source.canPlan ||
        source.snapshot.state != SourceScanState.complete ||
        !profile.isQualified) {
      throw const SourceTownMapBindingUnavailable('source_unqualified');
    }
    final nativeMapId = nativeMapIds[102];
    if (nativeMapId == null ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]*$').hasMatch(nativeMapId) ||
        !source.maps.any((map) => map.map.sourceMapId == 102)) {
      throw const SourceTownMapBindingUnavailable('native_map_unbound');
    }
    final admittedFiles = <SourceFileEntry>[];
    var inputBytes = 0;
    Future<(SourceFileEntry, List<int>)> readFile(
        String path, int maximum) async {
      cancellation?.check();
      final matches = source.snapshot.entries
          .where((entry) => entry.relativePath == path)
          .toList();
      if (matches.length != 1 ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 == null) {
        throw const SourceTownMapBindingUnavailable('source_file_missing');
      }
      final entry = matches.single;
      if (entry.byteLength > maximum ||
          inputBytes + entry.byteLength > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException('source.town_map.quota',
            'Town Map source files exceed the admitted byte budget.');
      }
      inputBytes += entry.byteLength;
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
        throw ContractError('source.town_map.changed', path,
            'Town Map bytes differ from their source inventory.');
      }
      admittedFiles.add(entry);
      return (entry, bytes);
    }

    final (scripts, _) = await readFile('Data/Scripts.rxdata', 8388608);
    if (scripts.sha256 != profile.scriptsArchiveHash) {
      throw const SourceTownMapBindingUnavailable('source_unqualified');
    }
    final (metadataFile, metadataBytes) =
        await readFile('Data/map_metadata.dat', 1048576);
    final metadata = _decode(metadataBytes, metadataFile.relativePath);
    final map = _record(metadata, 102, 'GameData::MapMetadata');
    if (_integer(_field(metadata, map, '@id')) != 102 ||
        _field(metadata, map, '@town_map_size').kind != MarshalKind.nil) {
      throw const SourceTownMapBindingUnavailable(
          'dynamic_map_position_unsupported');
    }
    final position = _array(_field(metadata, map, '@town_map_position'));
    if (position.length != 3) _invalid('position');
    final regionNumber = _integer(metadata.node(position[0]));
    final currentX = _integer(metadata.node(position[1]));
    final currentY = _integer(metadata.node(position[2]));

    final (townFile, townBytes) = await readFile('Data/town_map.dat', 1048576);
    final town = _decode(townBytes, townFile.relativePath);
    final region = _record(town, regionNumber, 'GameData::TownMap');
    if (_integer(_field(town, region, '@id')) != regionNumber ||
        _array(_field(town, region, '@flags')).isNotEmpty ||
        _string(_field(town, region, '@pbs_file_suffix'), allowEmpty: true) !=
            '') {
      _invalid('region');
    }
    final label = _string(_field(town, region, '@real_name'));
    final filename = _string(_field(town, region, '@filename'));
    if (!RegExp(r'^[A-Za-z0-9_-]+\.png$').hasMatch(filename)) {
      _invalid('image_path');
    }
    final rows = _array(_field(town, region, '@point'));
    if (rows.isEmpty ||
        rows.length > 256 ||
        rows.length + 2 > limits.maxMutations) {
      throw const NativeWriteException('source.town_map.quota',
          'Town Map point mutations exceed the admitted collection budget.');
    }
    final (imageFile, imageBytes) = await readFile(
        'Graphics/UI/Town Map/$filename', limits.maxArtifactBytes);
    final (width, height) =
        const NativePngValidator().headerDimensions(imageBytes, limits: limits);
    const NativePngValidator().validate(imageBytes, limits: limits);
    final artifact = NativeArtifact(
        bytes: imageBytes, expectedSha256: imageFile.sha256, limits: limits);
    final identity = canonicalHashOf({
      'kind': 'sourceTownMap',
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'sourceRegionId': regionNumber,
    }).value.substring(0, 24);
    final regionId = 'source_region_$identity';
    final assetId =
        'source_region_image_${imageFile.sha256!.value.substring(0, 24)}';
    final logicalPath = 'assets/regions/$assetId.png';
    final nativeRegion = ProjectRegionDefinition(
        id: regionId,
        label: label,
        imagePath: logicalPath,
        sampling: ProjectMenuImageSampling.pixelArt);
    final points = <ProjectRegionPointOfInterest>[];
    final coordinates = <(int, int)>{};
    var currentCount = 0;
    for (final rowId in rows) {
      cancellation?.check();
      final row = _array(town.node(rowId));
      if (row.length != 8) _invalid('point');
      final x = _integer(town.node(row[0]));
      final y = _integer(town.node(row[1]));
      if (!coordinates.add((x, y)) ||
          x * 16 < 8 ||
          y * 16 < 8 ||
          x * 16 - 8 > width ||
          y * 16 - 8 > height) {
        _invalid('point_coordinate');
      }
      if (town.node(row[7]).kind != MarshalKind.nil) {
        throw const SourceTownMapBindingUnavailable(
            'conditional_point_unsupported');
      }
      for (final index in [4, 5, 6]) {
        if (town.node(row[index]).kind != MarshalKind.nil) {
          _integer(town.node(row[index]));
        }
      }
      final current = x == currentX && y == currentY;
      if (current) currentCount++;
      points.add(ProjectRegionPointOfInterest(
          id: '${regionId}_point_${x}_$y',
          regionId: regionId,
          label: _string(town.node(row[2])),
          description: town.node(row[3]).kind == MarshalKind.nil
              ? null
              : _string(town.node(row[3])),
          u: (x * 16 - 8) / width,
          v: (y * 16 - 8) / height,
          discovery: ProjectRegionPointDiscovery.always,
          mapIds: current ? [nativeMapId] : const [],
          sortOrder: points.length));
    }
    if (currentCount != 1) _invalid('current_point');
    final catalog = ProjectRegionalMapCatalog(
        regions: [nativeRegion], pointsOfInterest: points);
    final mutations = <NativeMutation>[];
    void mutate(String id, String action, List<String> targets,
        Map<String, Object?> parameters) {
      mutations.add(NativeMutation(
          operationId: ConverterId(id),
          actionId: action,
          sourceEntityIds: [
            townFile.fileId,
            metadataFile.fileId,
            imageFile.fileId
          ],
          targetEntityIds: targets.map(ConverterId.new).toList(),
          parameters: parameters,
          limits: limits));
    }

    mutate('import_$assetId', 'asset.import', [
      assetId
    ], {
      'artifactHandle': artifact.handle,
      'assetId': assetId,
      'logicalPath': logicalPath,
      'tags': ['source-town-map'],
      'usages': ['regional-map'],
    });
    mutate('upsert_$regionId', 'regionalMap.region.upsert', [regionId],
        {'region': nativeRegion.toJson()});
    for (final point in points) {
      mutate('upsert_${point.id}', 'regionalMap.poi.upsert', [point.id],
          {'poi': point.toJson()});
    }
    return SourceTownMapBinding._(
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: profile.normalizationHash,
        profileHash: profile.canonicalHash,
        nativeMapId: nativeMapId,
        catalog: catalog,
        artifact: artifact,
        files: admittedFiles,
        mutations: mutations,
        evidence: {
          'kind': 'sourceTownMapBinding',
          'version': 1,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': profile.normalizationHash.value,
          'profileHash': profile.canonicalHash.value,
          'sourceMapId': 102,
          'nativeMapId': nativeMapId,
          'sourceRegionId': regionNumber,
          'nativeRegionId': regionId,
          'sourceFiles': admittedFiles.map((entry) => entry.toJson()).toList(),
          'image': {
            'width': width,
            'height': height,
            'sha256': artifact.rawSha256.value,
            'artifactHandle': artifact.handle,
            'assetId': assetId,
            'logicalPath': logicalPath,
            'pixelPolicy': 'original-source-png-no-transform'
          },
          'currentPoint': {'x': currentX, 'y': currentY},
          'pointCount': points.length,
          'sourceWallMap': true,
          'flyEnabled': false,
          'sourceScriptsExecuted': false,
          'aiCalls': 0,
          'sourceCursorParityQualified': false,
          'sourcePresentationParityQualified': false,
          'nativePresentation': 'aveluneRegionalMapReadOnly2D',
          'coordinatePolicy':
              'sourcePointCenter(x*16-8,y*16-8)/sourceImageSize',
          'sourceOracle': {
            'schema': {
              'sha256':
                  'd90e49b28b477f2b332a9d4943e730fc8f05f05d9a5dbd2c4e9ae01e2a205f13',
              'lines': '1-19'
            },
            'regionMap': {
              'sha256':
                  '67a4511fb1c48f2533a7a930a615f4d0dc9be8d8ed4a19fa67bece3968856c13',
              'currentRegion': '77-94',
              'pointCenter': '165-170',
              'wallMapVisibility': '184-190,212-219',
              'cancelAndFly': '294-311',
              'pbShowMap': '348-354'
            },
          },
        });
  }
}

MarshalDocument _decode(List<int> bytes, String path) =>
    const MarshalDecoder().decode(bytes,
        sourcePath: path,
        limits: const MarshalDecodeLimits(
            maxInputBytes: 1048576,
            maxNodes: 200000,
            maxObjects: 100000,
            maxContainerEntries: 10000,
            maxTotalEntries: 200000,
            maxStringBytes: 4096,
            maxTotalStringBytes: 1048576));

MarshalNode _record(MarshalDocument data, int key, String className) {
  final root = data.node(data.rootId);
  if (root.kind != MarshalKind.hash) _invalid('root');
  final matches = root.pairs
      .where((pair) =>
          data.node(pair.key).kind == MarshalKind.integer &&
          data.node(pair.key).integerValue == BigInt.from(key))
      .toList();
  if (matches.length != 1) _invalid('record');
  final node = data.node(matches.single.value);
  if (node.kind != MarshalKind.object || node.className != className) {
    _invalid('record_class');
  }
  return node;
}

MarshalNode _field(MarshalDocument data, MarshalNode node, String name) {
  final matches = node.instanceVariables
      .where((pair) =>
          data.node(pair.key).kind == MarshalKind.symbol &&
          data.node(pair.key).text().text == name)
      .toList();
  if (matches.length != 1) _invalid('field');
  return data.node(matches.single.value);
}

List<int> _array(MarshalNode node) {
  if (node.kind != MarshalKind.array) _invalid('array');
  return node.elements;
}

int _integer(MarshalNode node) {
  final value = node.integerValue;
  if (node.kind != MarshalKind.integer ||
      value == null ||
      value < BigInt.zero ||
      value > BigInt.from(1000000)) {
    _invalid('integer');
  }
  return value.toInt();
}

String _string(MarshalNode node, {bool allowEmpty = false}) {
  if (node.kind != MarshalKind.string) _invalid('string');
  final text = node.text().text;
  if (text == null ||
      (!allowEmpty && text.trim().isEmpty) ||
      text.length > 2048 ||
      text.contains('\\') ||
      text.contains('#{') ||
      text.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    _invalid('plain_text');
  }
  return text;
}

Never _invalid(String field) =>
    throw SourceTownMapBindingUnavailable('source_data_invalid_$field');

Object? _freeze(Object? value) => switch (value) {
      Map value => Map<String, Object?>.unmodifiable({
          for (final entry in value.entries)
            entry.key as String: _freeze(entry.value),
        }),
      List value => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
