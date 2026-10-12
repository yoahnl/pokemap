import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import '../test/support/literal_tile_fixture.dart';
import '../test/support/native_writer_fixture.dart';

const _namespace = 'original-ac13-pickup-runtime-reference';
const _skinPath = 'Graphics/Windowskins/speech hgss 1.png';
const _iconPath = 'Graphics/Icons/bagPocket2.png';
const _audioPath = 'Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).wav';

final class Ac13PickupReferenceFixture {
  Ac13PickupReferenceFixture({
    required this.manifestPath,
    required this.projectFilePath,
    required Map<String, Object?> evidence,
  }) : evidence = Map.unmodifiable(evidence);

  final String manifestPath;
  final String projectFilePath;
  final Map<String, Object?> evidence;
}

Future<Ac13PickupReferenceFixture> buildAc13PickupReferenceFixture({
  required String sourceScriptsPath,
  String? outputParentPath,
}) async {
  _require(path.isAbsolute(sourceScriptsPath),
      'The source archive path must be absolute');
  _require(
      await FileSystemEntity.type(sourceScriptsPath, followLinks: false) ==
          FileSystemEntityType.file,
      'The source archive must be a regular file');
  final scripts = File(sourceScriptsPath);
  final scriptsBefore = await scripts.stat();
  _require(scriptsBefore.size > 0 && scriptsBefore.size <= 16 * 1024 * 1024,
      'The source archive exceeds the bounded profile');
  final archiveBytes = await scripts.readAsBytes();
  final archiveHash = _hash(archiveBytes);
  _require(archiveHash == SourceEventProfile.kantoScriptsArchiveSha256,
      'The pickup oracle requires the exact attested Kanto archive');
  final parent = outputParentPath == null
      ? Directory.systemTemp
      : Directory(outputParentPath);
  _require(path.isAbsolute(parent.path), 'The output parent must be absolute');
  final root = await parent.createTemp('ac13-pickup-reference-');
  final sourceRoot = Directory(path.join(root.path, 'original-source'));
  final destination =
      await Directory(path.join(root.path, 'native-output')).create();
  final originalFiles = {
    'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
    'Graphics/Characters/OriginalPlayer.png': _characterPng(48),
    'Graphics/Characters/OriginalPickup.png': _characterPng(144),
    'Data/items.dat': _marshal({
      const _Symbol('BURNHEAL'): _Object('GameData::Item', {
        '@id': const _Symbol('BURNHEAL'),
        '@real_name': 'Burn Heal',
        '@real_name_plural': 'Burn Heals',
        '@real_portion_name': null,
        '@real_portion_name_plural': null,
        '@pocket': 2,
        '@price': 200,
        '@sell_price': 50,
        '@bp_price': 1,
        '@field_use': 1,
        '@battle_use': 1,
        '@flags': ['Fling_30'],
        '@consumable': true,
        '@show_quantity': null,
        '@move': null,
        '@real_description': 'Original burn cure qualification fixture.',
        '@pbs_file_suffix': '',
      }),
    }),
    'Data/map_metadata.dat': _marshal({
      1: _Object('GameData::MapMetadata', {
        '@id': 1,
        '@town_map_position': [1, 16, 5],
        '@real_name': 'Original pickup reference',
      }),
    }),
    _skinPath: _skinPng(),
    _iconPath: _iconPng(),
    _audioPath: _wav(),
  };
  final fixture = await LiteralTileFixture.create(
    namespace: _namespace,
    sourceRootPath: sourceRoot.path,
    scriptsBytes: archiveBytes,
    includeEventSystem: true,
    selectedMapIds: const {1},
    maps: [
      LiteralFixtureMap(
        id: 1,
        name: 'Original pickup reference',
        width: 6,
        height: 5,
        layers: [List.filled(30, 384), List.filled(30, 0), List.filled(30, 0)],
        events: const [
          LiteralFixtureEvent(
            id: 1,
            x: 1,
            y: 1,
            name: 'Original pickup',
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalPickup',
                commands: [
                  LiteralFixtureEventCommand(
                      111, [12, 'pbItemBall(:BURNHEAL)']),
                  LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                  LiteralFixtureEventCommand(412, []),
                ],
              ),
              LiteralFixtureEventPage(selfSwitch: 'A', commands: []),
            ],
          ),
          LiteralFixtureEvent(
            id: 2,
            x: 4,
            y: 1,
            name: 'Quarantined pickup',
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalPickup',
                commands: [
                  LiteralFixtureEventCommand(355, ['originalUnknownReward()']),
                  LiteralFixtureEventCommand(
                      111, [12, 'pbItemBall(:BURNHEAL)']),
                  LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                  LiteralFixtureEventCommand(412, []),
                ],
              ),
              LiteralFixtureEventPage(selfSwitch: 'A', commands: []),
            ],
          ),
        ],
      ),
    ],
    extraFiles: originalFiles,
  );
  final sourceHashesBefore = await _directoryHashes(sourceRoot.path);
  final literal = await const LiteralTileComposer().compose(
    source: fixture.source,
    files: fixture.files,
    selectedSourceMapIds: const [1],
    projectName: 'Original pickup runtime reference',
    parentPath: destination.path,
    folderName: 'converted-pickup',
    sourceRootPath: sourceRoot.path,
  );
  final semantic = await const SourceSemanticStudyComposer()
      .compose(source: fixture.source, base: literal, files: fixture.files);
  _require(semantic != null, 'The original tile semantics must qualify');
  final events = await const SourceEventStudyComposer()
      .compose(source: fixture.source, base: semantic!, files: fixture.files);
  _require(events != null, 'The original pickup event must compose');
  final draft = events!.draft;
  final eventEvidence = Map<String, Object?>.from(
      draft.compositionEvidence['sourceEvents'] as Map);
  final projection =
      Map<String, Object?>.from(eventEvidence['projection'] as Map);
  _require(
      projection['qualifiedEventCount'] == 1 &&
          projection['quarantinedEventCount'] == 1,
      'One original pickup must qualify and the whole unknown event must quarantine');
  final approval = approveNativeFixtureDraft(draft);
  final receipt = await const NativeProjectWriter()
      .write(approval.plan, approval.context, draft);
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(receipt.projectPath);
  late ProjectManifest manifest;
  late MapData map;
  late ProjectItemCatalog itemCatalog;
  try {
    final native = await ProjectSnapshotLoader(handles: handles)
        .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
    _require(native.loadDiagnostics.isEmpty,
        'The generated native project must reopen strictly');
    manifest = native.manifest;
    map = native.mapById(draft.mapIds[1]!)!;
    itemCatalog = native.itemCatalog!;
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
  _require(
      itemCatalog.entries.length == 1 &&
          itemCatalog.entries.single.displayName == 'Burn Heal',
      'Only the qualified pickup may produce its native item');
  final sourceHashesAfter = await _directoryHashes(sourceRoot.path);
  _require(
      canonicalJsonOf(sourceHashesBefore) == canonicalJsonOf(sourceHashesAfter),
      'The original source must remain unchanged');
  final scriptsAfter = await scripts.stat();
  _require(
      scriptsBefore.size == scriptsAfter.size &&
          scriptsBefore.modified == scriptsAfter.modified &&
          _hash(await scripts.readAsBytes()) == archiveHash,
      'The external inert script archive must remain unchanged');
  final projectFilePath = path.join(receipt.projectPath, 'project.json');
  final evidence = <String, Object?>{
    'kind': 'originalSourceConvertedPickupReference',
    'version': 1,
    'projectFilePath': projectFilePath,
    'sourceRootPath': sourceRoot.path,
    'sourceScriptsArchiveHash': archiveHash,
    'sourceSnapshotHash': fixture.snapshot.canonicalHash.value,
    'sourceHashesBefore': sourceHashesBefore,
    'sourceHashesAfter': sourceHashesAfter,
    'nativeHashes': await _directoryHashes(receipt.projectPath),
    'nativeDraftHash': draft.canonicalHash.value,
    'nativeRevision': receipt.nativeRevision,
    'sourceNamespace': _namespace,
    'mapId': map.id,
    'itemId': itemCatalog.entries.single.id,
    'entityIds': {
      for (final entity
          in map.entities.where((entry) => entry.kind != MapEntityKind.spawn))
        entity.name: entity.id
    },
    'sourceEvents': eventEvidence,
    'sourceAutoplayBgm': false,
    'originalMedia': {
      'skin': {
        'relativePath': _skinPath,
        'width': 96,
        'height': 48,
        'sha256': _hash(originalFiles[_skinPath]!)
      },
      'icon': {
        'relativePath': _iconPath,
        'width': 18,
        'height': 32,
        'sha256': _hash(originalFiles[_iconPath]!)
      },
      'audio': {
        'relativePath': _audioPath,
        'durationMs': 1000,
        'sha256': _hash(originalFiles[_audioPath]!)
      },
    },
    'configuredRecordCount': manifest.eventRegistry!.records
        .where((record) => record.definitionOrNull != null)
        .length,
    'draftRecordCount': manifest.eventRegistry!.records
        .where((record) => record.draftOrNull != null)
        .length,
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
    'published': false,
    'globalPlayabilityCertified': false,
    'writerVerified': receipt.verified,
    'sourceUnchanged': true,
    'qualificationScope':
        'State after completed original unit pickup and save reload; fresh session; default source options; no active BGM.',
    'sourceBagMutationTimingQualified': false,
    'nativeConsequenceCommitPolicy': 'bufferUntilSceneCompleted',
    'fullBagSourceParityQualified': false,
    'sourceAudioPauseResumeQualified': false,
  };
  final output = File(path.join(root.path, 'pickup-reference.json'));
  await output.writeAsString(jsonEncode(evidence), flush: true);
  return Ac13PickupReferenceFixture(
      manifestPath: output.path,
      projectFilePath: projectFilePath,
      evidence: evidence);
}

Future<void> main() async {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  _require(scriptsPath != null,
      'AVELUNE_AC13_SOURCE_SCRIPTS must identify the exact inert source archive');
  final fixture =
      await buildAc13PickupReferenceFixture(sourceScriptsPath: scriptsPath!);
  stdout.writeln(jsonEncode({
    'manifestPath': fixture.manifestPath,
    'projectFilePath': fixture.projectFilePath,
    'configuredRecordCount': fixture.evidence['configuredRecordCount'],
    'draftRecordCount': fixture.evidence['draftRecordCount']
  }));
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

String _hash(List<int> bytes) => crypto.sha256.convert(bytes).toString();

Future<Map<String, String>> _directoryHashes(String root) async {
  final hashes = <String, String>{};
  await for (final entity
      in Directory(root).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      hashes[path.relative(entity.path, from: root)] =
          _hash(await entity.readAsBytes());
    }
  }
  final names = hashes.keys.toList()..sort();
  return {for (final name in names) name: hashes[name]!};
}

List<int> _characterPng(int red) {
  final raster = image.Image(width: 128, height: 128, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var y = 8; y < 32; y++) {
        for (var x = 8; x < 24; x++) {
          raster.setPixelRgba(column * 32 + x, row * 32 + y, red + column * 8,
              40 + row * 32, 112, 255);
        }
      }
    }
  }
  return image.encodePng(raster);
}

List<int> _skinPng() {
  final raster = image.Image(width: 96, height: 48, numChannels: 4);
  raster.clear(image.ColorRgba8(248, 248, 248, 255));
  for (var x = 0; x < 96; x++) {
    raster.setPixelRgba(x, 0, 88, 112, 144, 255);
  }
  return image.encodePng(raster);
}

List<int> _iconPng() {
  final raster = image.Image(width: 18, height: 32, numChannels: 4);
  for (var y = 2; y < 30; y++) {
    for (var x = 2; x < 16; x++) {
      raster.setPixelRgba(x, y, 48 + x * 8, 80 + y * 4, 144, 255);
    }
  }
  return image.encodePng(raster);
}

List<int> _wav() {
  final bytes = Uint8List(44 + 16000);
  final view = ByteData.sublistView(bytes);
  void text(int offset, String value) =>
      bytes.setRange(offset, offset + value.length, ascii.encode(value));
  text(0, 'RIFF');
  view.setUint32(4, bytes.length - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little);
  view.setUint32(24, 8000, Endian.little);
  view.setUint32(28, 16000, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  text(36, 'data');
  view.setUint32(40, 16000, Endian.little);
  for (var sample = 0; sample < 8000; sample++) {
    view.setInt16(
        44 + sample * 2,
        (math.sin(sample * 2 * math.pi * 220 / 8000) * 2048).round(),
        Endian.little);
  }
  return bytes;
}

final class _Symbol {
  const _Symbol(this.value);
  final String value;
}

final class _Object {
  const _Object(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

List<int> _marshal(Object? value) => [4, 8, ..._value(value)];

List<int> _packed(int value) {
  if (value == 0) return [0];
  if (value > 0 && value < 123) return [value + 5];
  if (value < 0 && value > -124) return [(value - 5) & 255];
  var width = 1;
  while (value >= (1 << (width * 8)) || value < -(1 << (width * 8))) {
    width++;
  }
  return [
    value >= 0 ? width : (-width) & 255,
    for (var i = 0; i < width; i++) (value >> (i * 8)) & 255
  ];
}

List<int> _value(Object? value) {
  if (value == null) return [0x30];
  if (value is bool) return [value ? 0x54 : 0x46];
  if (value is int) return [0x69, ..._packed(value)];
  if (value is _Symbol) {
    final bytes = utf8.encode(value.value);
    return [0x3a, ..._packed(bytes.length), ...bytes];
  }
  if (value is String) {
    final bytes = utf8.encode(value);
    return [0x22, ..._packed(bytes.length), ...bytes];
  }
  if (value is List) {
    return [
      0x5b,
      ..._packed(value.length),
      for (final entry in value) ..._value(entry)
    ];
  }
  if (value is Map) {
    return [
      0x7b,
      ..._packed(value.length),
      for (final entry in value.entries) ...[
        ..._value(entry.key),
        ..._value(entry.value)
      ]
    ];
  }
  if (value is _Object) {
    return [
      0x6f,
      ..._value(_Symbol(value.className)),
      ..._packed(value.fields.length),
      for (final entry in value.fields.entries) ...[
        ..._value(_Symbol(entry.key)),
        ..._value(entry.value)
      ]
    ];
  }
  throw StateError('Unsupported original Marshal value: $value');
}
