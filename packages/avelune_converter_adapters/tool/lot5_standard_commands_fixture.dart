import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as path;

import '../test/support/literal_tile_fixture.dart';

void _require(bool value, String message) {
  if (!value) throw StateError(message);
}

List<int> _sound() {
  const rate = 22050;
  const samples = 2205;
  final data = ByteData(44 + samples * 2);
  void label(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      data.setUint8(offset + index, value.codeUnitAt(index));
    }
  }
  label(0, 'RIFF');
  data.setUint32(4, data.lengthInBytes - 8, Endian.little);
  label(8, 'WAVE');
  label(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  label(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (var index = 0; index < samples; index++) {
    data.setInt16(44 + index * 2,
        (math.sin(index * math.pi * 880 / rate) * 4096).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

Future<Map<String, String>> _hashes(String root) async {
  final values = <String, String>{};
  await for (final entry in Directory(root).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      values[path.relative(entry.path, from: root)] =
          crypto.sha256.convert(await entry.readAsBytes()).toString();
    }
  }
  final keys = values.keys.toList()..sort();
  return {for (final key in keys) key: values[key]!};
}

Future<void> main(List<String> arguments) async {
  _require(arguments.length == 5 && arguments.every(path.isAbsolute),
      'Provide unused output directory, Kanto root, Johto root, Hoenn root and base profile.');
  final [output, kanto, johto, hoenn, profileFile] = arguments;
  _require(!await Directory(output).exists(), 'Output must be unused.');
  await Directory(output).create(recursive: true);
  final raw = Map<String, dynamic>.from(jsonDecode(await File(profileFile).readAsString()) as Map);
  final profile = SourceInterpretationProfile.fromJson({
    ...raw,
    'profileId': 'original-lot5-standard-commands',
    'sections': {
      ...raw['sections'] as Map,
      'events.Audio_Play': {
        'index': 93, 'name': 'Audio_Play',
        'sha256': 'e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb',
      },
    },
  });
  final originals = {
    'Game.exe': path.join(hoenn, 'Game.exe'),
    'Game.ini': path.join(kanto, 'Game.ini'),
    'mkxp.json': path.join(kanto, 'mkxp.json'),
  };
  final copied = <String, List<int>>{};
  for (final entry in originals.entries) {
    copied[entry.key] = await File(entry.value).readAsBytes();
  }
  final sourceRoot = path.join(output, 'original-source');
  await LiteralTileFixture.create(
    namespace: 'original-lot5-standard-commands', sourceRootPath: sourceRoot,
    scriptsBytes: await File(path.join(johto, 'Data', 'Scripts.rxdata')).readAsBytes(),
    interpretationProfile: profile, includeEventSystem: true,
    switchNames: const [null, 'Ready'],
    maps: [LiteralFixtureMap(id: 1, name: 'Original standard commands laboratory',
      width: 5, height: 4,
      layers: [List.filled(20, 384), List.filled(20, 0), List.filled(20, 0)],
      events: const [
        LiteralFixtureEvent(id: 1, name: 'Audio guide', x: 1, y: 2, pages: [
          LiteralFixtureEventPage(characterName: 'OriginalNpc', commands: [
            LiteralFixtureEventCommand(101, [r'Avant.\se[OriginalCue]Après.']),
            LiteralFixtureEventCommand(121, [1, 1, 0]),
          ]),
        ]),
        LiteralFixtureEvent(id: 2, name: 'Guarded automatic sequence', x: 3, y: 2, pages: [
          LiteralFixtureEventPage(trigger: 3, globalSwitch: 1, commands: [
            LiteralFixtureEventCommand(106, [2]),
            LiteralFixtureEventCommand(101, ['Séquence terminée.']),
            LiteralFixtureEventCommand(123, ['A', 0]),
          ]),
          LiteralFixtureEventPage(selfSwitch: 'A', commands: []),
        ]),
        LiteralFixtureEvent(id: 3, name: 'Unknown command', x: 4, y: 3, pages: [
          LiteralFixtureEventPage(commands: [LiteralFixtureEventCommand(999, [])]),
        ]),
      ],
    )],
    extraFiles: {
      ...copied,
      'Audio/SE/OriginalCue.wav': _sound(),
      'Graphics/Characters/OriginalPlayer.png': literalFixtureAtlas(),
      'Graphics/Characters/OriginalNpc.png': literalFixtureAtlas(),
      'Data/map_connections.dat': literalFixtureMarshal([]),
      'Data/map_metadata.dat': literalFixtureMarshal({
        1: const LiteralFixtureObject('GameData::MapMetadata', {'@id': 1}),
      }),
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
    },
  );
  final before = await _hashes(sourceRoot);
  final destination = await Directory(path.join(output, 'native')).create();
  final workflow = ConverterWorkflow();
  try {
    final scanned = await workflow.scanSource(ConverterSourceSelection(
        rootPath: sourceRoot, logicalProjectNamespace: ConverterId('original-lot5-standard-commands')));
    _require(scanned.state == SourceScanState.complete, 'Source scan incomplete.');
    workflow.updateSettings(ConverterStudySettings(
      interpretationProfile: profile, projectName: 'Original LOT5 commands',
      parentPath: destination.path, folderName: 'converted',
      selectedSourceMapIds: const [1], assetOutputMode: AssetOutputMode.sharedAtlas,
      profileAcknowledgement: SourceStudyAcknowledgement(
        sourceSnapshotHash: scanned.canonicalHash,
        profileEvidenceHash: scanned.profile.evidenceHash, humanConfirmed: true,
        reason: 'User-authorized original standard-command qualification.',
      ),
    ));
    final prepared = await workflow.prepareStudy();
    _require(prepared.canApprove && prepared.nativeDraft != null,
        'Source study refused: ${prepared.composition.diagnostics.map((entry) => entry.code).join(', ')}');
    final draft = prepared.nativeDraft!;
    final evidence = draft.compositionEvidence['sourceEvents'] as Map;
    final projection = evidence['projection'] as Map;
    _require(projection['qualifiedEventCount'] == 2 && projection['quarantinedEventCount'] == 1,
        'Expected exactly two qualified events and one quarantine: $projection');
    final approved = workflow.approvePrepared(sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash, humanConfirmed: true);
    final result = await workflow.writeApproved(approved);
    _require(result.published && result.receipt.verified && result.sourceUnchanged,
        'Canonical publication verification failed.');
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [result.projectPath], fileReader: reader);
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.projectPath);
    ProjectSnapshot? project;
    try {
      project = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      _require(project.loadDiagnostics.isEmpty, 'Native strict reopen failed.');
    } finally {
      await project?.payloadOwner?.release();
      opener.closeWorkspace(opened.workspaceHandle);
    }
    final after = await _hashes(sourceRoot);
    _require(canonicalJsonOf(before) == canonicalJsonOf(after), 'Source changed.');
    final reference = {
      'kind': 'originalLot5CommandsReference', 'sourceScriptsExecuted': 0, 'aiCalls': 0,
      'fullKantoCertified': false, 'manualStudioCertified': false,
      'audiblePlaybackCertified': false, 'nativeWriterVerified': true,
      'projectFilePath': path.join(result.projectPath, 'project.json'),
      'mapId': draft.mapIds[1], 'sourceRootPath': sourceRoot,
      'sourceSnapshotHash': scanned.canonicalHash.value, 'profileHash': profile.canonicalHash.value,
      'engineProvenance': {for (final entry in originals.entries)
        entry.key: {'path': entry.value, 'sha256': before[entry.key]}},
      'sourceHashesBefore': before, 'sourceHashesAfter': after,
      'nativeHashes': await _hashes(result.projectPath), 'sourceEvents': evidence,
    };
    final referenceFile = File(path.join(output, 'commands-reference.json'));
    await referenceFile.writeAsString(jsonEncode(reference), flush: true);
    stdout.writeln(jsonEncode({'referencePath': referenceFile.path,
      'projectFilePath': reference['projectFilePath']}));
  } finally {
    await workflow.dispose();
  }
}
