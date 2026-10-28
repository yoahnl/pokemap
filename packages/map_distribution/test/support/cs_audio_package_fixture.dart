import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'spatial_package_fixture.dart';

Map<String, List<int>> csAudioPayload(
  ProjectDimension dimension, {
  ProjectFieldAbilitiesSettings? fieldAbilities,
  ProjectAudioSettings? audio,
}) {
  final files = spatialPayload();
  final initial = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>);
  final spatial = dimension == ProjectDimension.threeD;
  final project = initial.copyWith(
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    settings: initial.settings.copyWith(
      dimension: dimension,
      spatialCamera: spatial ? SpatialCameraProfile() : null,
      fieldAbilities: fieldAbilities,
      audio: audio,
    ),
    newGame: spatial
        ? initial.newGame
        : const ProjectNewGameConfig(
            enabled: true, startMapId: 'map', startSpawnId: 'start'),
    models3d: spatial ? initial.models3d : [],
  );
  files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
  if (!spatial) {
    files['project/maps/map.json'] = utf8.encode(jsonEncode(MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v8,
      size: const GridSize(width: 8, height: 8),
      entities: const [
        MapEntity(
            id: 'start',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 2, y: 2),
            spawn: MapEntitySpawnData(facing: EntityFacing.south))
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'start'),
    ).toJson()));
  }
  return files;
}

GamePackageManifest csAudioManifest(
    ProjectDimension dimension, Iterable<String> extra) {
  final json = spatialManifest(capabilities: [
    dimension == ProjectDimension.threeD ? 'map3d@1' : 'map@1',
    ...extra
  ]).toJson();
  (json['compatibility']! as Map)['projectFormat'] =
      dimension == ProjectDimension.threeD ? 'v9' : 'v8';
  return const GamePackageManifestCodec().decodeJson(json);
}

List<int> csAudioWav() {
  final bytes = Uint8List(52);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  data.setUint32(4, 44, Endian.little);
  bytes.setRange(8, 16, ascii.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 16000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, ascii.encode('data'));
  data.setUint32(40, 8, Endian.little);
  return bytes;
}

String addCsAudioMedia(Map<String, List<int>> files,
    {ProjectMediaKind kind = ProjectMediaKind.audio}) {
  final bytes = csAudioWav();
  final digest = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
        relativePath: 'artifact-content', bytes: bytes)
  ]);
  final catalogPath = 'project/assets/.pokemap-assets.json';
  final catalog =
      jsonDecode(utf8.decode(files[catalogPath]!)) as Map<String, dynamic>;
  (catalog['records'] as List).add({
    'id': 'sound-source',
    'logicalPath': 'assets/bell.wav',
    'artifact': {
      'digest': digest,
      'handle': 'artifact://sha256/${digest.substring(7)}',
      'mediaType': 'audio/wav',
      'byteLength': bytes.length
    },
    'usages': <String>[],
    'tags': <String>[],
  });
  files[catalogPath] = utf8.encode(jsonEncode(catalog));
  files['project/assets/bell.wav'] = bytes;
  final blob = 'project/assets/.pokemap-store/${digest.substring(7)}.blob';
  files[blob] = bytes;
  files['project/assets/.pokemap-media.json'] =
      utf8.encode(jsonEncode(ProjectMediaCatalog(entries: [
    ProjectMediaAsset(
      id: 'bell',
      label: 'Bell',
      kind: kind,
      sourceAssetId: 'sound-source',
      provenance: ProjectMediaProvenance(source: 'Generic QA generated tone'),
      license: ProjectMediaLicense(identifier: 'CC0-1.0', name: 'CC0'),
      technicalMetadata: ProjectMediaTechnicalMetadata(
          mediaType: 'audio/wav',
          container: 'wav',
          codec: 'pcm_s16le',
          sizeBytes: bytes.length,
          durationMilliseconds: 1),
    )
  ]).toJson()));
  return blob;
}
