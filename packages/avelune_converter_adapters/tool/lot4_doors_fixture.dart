import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import '../test/support/literal_tile_fixture.dart';

const _namespace = 'original-lot4-doors';

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

List<int> _character(int red) {
  final raster = image.Image(width: 128, height: 192, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var y = 12; y < 48; y++) {
        for (var x = 8; x < 24; x++) {
          raster.setPixelRgba(column * 32 + x, row * 48 + y, red + column * 8,
              40 + row * 32, 96, 255);
        }
      }
    }
  }
  return image.encodePng(raster);
}

LiteralFixtureObject _step(int code) =>
    LiteralFixtureObject('RPG::MoveCommand', {
      '@code': code,
      '@parameters': code == 15 ? [2] : <Object?>[],
    });

List<LiteralFixtureEventCommand> _route(int actor, List<int> codes,
        {int indent = 0}) =>
    [
      LiteralFixtureEventCommand(
          209,
          [
            actor,
            LiteralFixtureObject('RPG::MoveRoute', {
              '@repeat': false,
              '@skippable': true,
              '@list': [...codes.map(_step), _step(0)],
            })
          ],
          indent: indent),
      for (final code in codes)
        LiteralFixtureEventCommand(509, [_step(code)], indent: indent),
      LiteralFixtureEventCommand(210, [], indent: indent),
    ];

LiteralFixtureUserDefined _tone(double value) {
  final data = ByteData(32);
  for (var axis = 0; axis < 3; axis++) {
    data.setFloat64(axis * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', data.buffer.asUint8List());
}

LiteralFixtureEvent _door(int target) => LiteralFixtureEvent(
        id: 1,
        name: 'Invisible paired door',
        x: 2,
        y: 1,
        pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            LiteralFixtureEventCommand(223, [_tone(-255), 2]),
            const LiteralFixtureEventCommand(106, [2]),
            LiteralFixtureEventCommand(201, [0, target, 2, 1, 2, 1]),
            LiteralFixtureEventCommand(223, [_tone(0), 2]),
            const LiteralFixtureEventCommand(0, []),
          ]),
          LiteralFixtureEventPage(trigger: 3, globalSwitch: 1, commands: [
            const LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
            const LiteralFixtureEventCommand(208, [0], indent: 1),
            ..._route(0, [15, 17, 15, 18, 15, 19, 15], indent: 1),
            const LiteralFixtureEventCommand(208, [1], indent: 1),
            ..._route(-1, [1], indent: 1),
            ..._route(0, [18, 15, 17, 15, 16, 15], indent: 1),
            const LiteralFixtureEventCommand(412, []),
            const LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
            const LiteralFixtureEventCommand(0, []),
          ]),
        ]);

List<LiteralFixtureMap> _maps() => [
      for (final id in [42, 43])
        LiteralFixtureMap(
            id: id,
            name: 'Original door laboratory $id',
            width: 8,
            height: 6,
            layers: [
              List.generate(48, (index) => index == 6 ? 385 : 384),
              List.filled(48, 0),
              List.filled(48, 0)
            ],
            events: [
              _door(id == 42 ? 43 : 42),
              if (id == 42) ...[
                const LiteralFixtureEvent(
                    id: 2,
                    name: 'Stationary touch one',
                    x: 1,
                    y: 4,
                    pages: [
                      LiteralFixtureEventPage(trigger: 1, commands: [
                        LiteralFixtureEventCommand(101, ['Touch one.']),
                        LiteralFixtureEventCommand(0, [])
                      ]),
                    ]),
                const LiteralFixtureEvent(
                    id: 3,
                    name: 'Stationary touch two',
                    x: 3,
                    y: 4,
                    pages: [
                      LiteralFixtureEventPage(
                          trigger: 2,
                          characterName: 'OriginalNpc',
                          commands: [
                            LiteralFixtureEventCommand(101, ['Touch two.']),
                            LiteralFixtureEventCommand(0, [])
                          ]),
                    ]),
                LiteralFixtureEvent(
                    id: 4,
                    name: 'Finite routed NPC',
                    x: 5,
                    y: 4,
                    pages: [
                      LiteralFixtureEventPage(
                          characterName: 'OriginalNpc',
                          commands: [
                            const LiteralFixtureEventCommand(
                                101, ['Before routes.']),
                            ..._route(0, [3, 15, 2, 18]),
                            ..._route(-1, [3, 15, 2, 16]),
                            const LiteralFixtureEventCommand(
                                101, ['After routes.']),
                            const LiteralFixtureEventCommand(0, []),
                          ]),
                    ]),
                const LiteralFixtureEvent(
                    id: 5,
                    name: 'Unqualified command',
                    x: 7,
                    y: 5,
                    pages: [
                      LiteralFixtureEventPage(trigger: 0, commands: [
                        LiteralFixtureEventCommand(999, []),
                        LiteralFixtureEventCommand(0, [])
                      ]),
                    ]),
              ],
            ]),
    ];

Future<Map<String, String>> _hashes(String root) async {
  final entries = <String, String>{};
  await for (final entity
      in Directory(root).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      entries[path.relative(entity.path, from: root)] =
          crypto.sha256.convert(await entity.readAsBytes()).toString();
    }
  }
  final names = entries.keys.toList()..sort();
  return {for (final name in names) name: entries[name]!};
}

Future<void> main(List<String> arguments) async {
  _require(arguments.length == 1 && path.isAbsolute(arguments.single),
      'Provide one absolute, unused output directory.');
  final root = Directory(arguments.single);
  _require(!await root.exists(), 'The output directory must be unused.');
  await root.create(recursive: true);
  final sourceRoot = path.join(root.path, 'original-source');
  final destination = await Directory(path.join(root.path, 'native')).create();
  await LiteralTileFixture.create(
    namespace: _namespace,
    sourceRootPath: sourceRoot,
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    switchNames: const [null, 's:tsOff?("A")'],
    variableNames: const [
      null,
      'Original progress counter',
      'Unqualified count'
    ],
    maps: _maps(),
    tilesets: [
      LiteralFixtureTileset(id: 1, passages: {385: 15})
    ],
    extraFiles: {
      'Data/map_connections.dat': literalFixtureMarshal([]),
      'Data/map_metadata.dat': literalFixtureMarshal({
        for (final id in [42, 43])
          id: LiteralFixtureObject('GameData::MapMetadata', {'@id': id})
      }),
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
      'Graphics/Characters/OriginalPlayer.png': _character(32),
      'Graphics/Characters/OriginalNpc.png': _character(80),
    },
  );
  final before = await _hashes(sourceRoot);
  final workflow = ConverterWorkflow();
  try {
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: sourceRoot,
        logicalProjectNamespace: ConverterId(_namespace)));
    _require(snapshot.state == SourceScanState.complete,
        'The original source scan must complete.');
    workflow.updateSettings(ConverterStudySettings(
      interpretationProfile: syntheticSourceInterpretationProfile,
      projectName: 'Original LOT4 doors',
      parentPath: destination.path,
      folderName: 'converted',
      selectedSourceMapIds: const [42, 43],
      profileAcknowledgement: SourceStudyAcknowledgement(
        sourceSnapshotHash: snapshot.canonicalHash,
        profileEvidenceHash: snapshot.profile.evidenceHash,
        humanConfirmed: true,
        reason: 'User-authorized portable original doors qualification.',
      ),
      assetOutputMode: AssetOutputMode.sharedAtlas,
    ));
    final prepared = await workflow.prepareStudy();
    _require(prepared.canApprove && prepared.nativeDraft != null,
        'The original doors study must be admissible.');
    final draft = prepared.nativeDraft!;
    final eventEvidence = Map<String, dynamic>.from(
        draft.compositionEvidence['sourceEvents'] as Map);
    final projection =
        Map<String, dynamic>.from(eventEvidence['projection'] as Map);
    _require(
        projection['qualifiedEventCount'] == 5 &&
            projection['quarantinedEventCount'] == 1,
        'Exactly five original events must qualify and the unknown script must quarantine: ${jsonEncode(projection)}');
    final approval = workflow.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final result = await workflow.writeApproved(approval);
    _require(
        result.receipt.verified && result.published && result.sourceUnchanged,
        'The canonical workflow must publish a verified, source-preserving project.');
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [result.projectPath], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.projectPath);
    ProjectSnapshot? native;
    late Map<String, String> entityIds;
    try {
      native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      _require(native.loadDiagnostics.isEmpty,
          'Strict native reopening must succeed.');
      entityIds = {
        for (final map in native.maps)
          for (final entity in map.entities
              .where((entity) => entity.kind != MapEntityKind.spawn))
            '${map.id}:${entity.name}': entity.id
      };
    } finally {
      await native?.payloadOwner?.release();
      opener.closeWorkspace(opened.workspaceHandle);
    }
    final after = await _hashes(sourceRoot);
    _require(canonicalJsonOf(before) == canonicalJsonOf(after),
        'The original source must remain unchanged.');
    final receipt = {
      'kind': 'originalLot4DoorsReference',
      'schemaVersion': 1,
      'sourceNamespace': _namespace,
      'sourceRootPath': sourceRoot,
      'projectFilePath': path.join(result.projectPath, 'project.json'),
      'mapIds': {
        for (final entry in draft.mapIds.entries) '${entry.key}': entry.value
      },
      'entityIds': entityIds,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourceHashesBefore': before,
      'sourceHashesAfter': after,
      'nativeHashes': await _hashes(result.projectPath),
      'sourceEvents': eventEvidence,
      'nativeDraftHash': draft.canonicalHash.value,
      'nativeWriterVerified': result.receipt.verified,
      'writerOrigin': 'converterWorkflow.writeApproved',
      'published': result.published,
      'sourceUnchanged': result.sourceUnchanged,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'fullKantoCertified': false,
      'manualStudioCertified': false,
      'manualPlayerCertified': false,
      'originalCommands': {
        for (final map in _maps())
          for (final event in map.events)
            '${map.id}:${event.id}': [
              for (final page in event.pages)
                [
                  for (final command in page.commands)
                    {
                      'code': command.code,
                      'parameters': command.parameters,
                      'indent': command.indent
                    }
                ],
            ],
      },
    };
    final file = File(path.join(root.path, 'doors-reference.json'));
    await file.writeAsString(
        jsonEncode(receipt,
            toEncodable: (value) => switch (value) {
                  LiteralFixtureObject() => {
                      'className': value.name,
                      'fields': value.fields
                    },
                  LiteralFixtureUserDefined() => {
                      'className': value.name,
                      'bytes': value.bytes
                    },
                  _ => throw StateError(
                      'Unexpected original fixture value: ${value.runtimeType}'),
                }),
        flush: true);
    stdout.writeln(jsonEncode({
      'referencePath': file.path,
      'projectFilePath': receipt['projectFilePath'],
      'qualifiedEventCount': projection['qualifiedEventCount'],
      'quarantinedEventCount': projection['quarantinedEventCount']
    }));
  } finally {
    await workflow.dispose();
  }
}
