import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import '../test/support/literal_tile_fixture.dart';

const _namespace = 'original-ac13-event-runtime-reference';

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

String _hash(List<int> bytes) => crypto.sha256.convert(bytes).toString();

List<int> _originalCharacterPng({required int red}) {
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

List<LiteralFixtureMap> _originalMaps() => [
      LiteralFixtureMap(
          id: 1,
          name: 'Original event reference',
          width: 6,
          height: 5,
          layers: [
            List.filled(30, 384),
            List.filled(30, 0),
            List.filled(30, 0)
          ],
          events: const [
            LiteralFixtureEvent(id: 1, x: 1, y: 1, name: 'Welcome', pages: [
              LiteralFixtureEventPage(characterName: 'ReferenceNpc', commands: [
                LiteralFixtureEventCommand(
                    101, ['Bienvenue dans la carte source.']),
                LiteralFixtureEventCommand(
                    401, ['Ce texte vient de la commande suivante.']),
                LiteralFixtureEventCommand(123, ['A', 0]),
                LiteralFixtureEventCommand(121, [1, 1, 0]),
              ]),
              LiteralFixtureEventPage(
                  characterName: 'ReferenceNpc',
                  selfSwitch: 'A',
                  commands: [
                    LiteralFixtureEventCommand(101, ['Content de te revoir.']),
                  ]),
            ]),
            LiteralFixtureEvent(id: 2, x: 3, y: 1, name: 'Independent', pages: [
              LiteralFixtureEventPage(characterName: 'ReferenceNpc', commands: [
                LiteralFixtureEventCommand(101, ['Je suis indépendant.']),
                LiteralFixtureEventCommand(123, ['A', 0]),
              ]),
              LiteralFixtureEventPage(
                  characterName: 'ReferenceNpc',
                  selfSwitch: 'A',
                  globalSwitch: 1,
                  commands: [
                    LiteralFixtureEventCommand(101, [
                      "Mon A est distinct et l'interrupteur global est actif."
                    ]),
                  ]),
            ]),
            LiteralFixtureEvent(
                id: 3,
                x: 5,
                y: 1,
                name: 'Quarantined reward',
                pages: [
                  LiteralFixtureEventPage(
                      characterName: 'ReferenceNpc',
                      commands: [
                        LiteralFixtureEventCommand(
                            355, ['referenceUnknownReward()']),
                        LiteralFixtureEventCommand(
                            111, [12, 'pbItemBall(:POTION)']),
                        LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                        LiteralFixtureEventCommand(412, []),
                        LiteralFixtureEventCommand(121, [2, 2, 0]),
                      ]),
                ]),
            LiteralFixtureEvent(id: 4, x: 1, y: 3, name: 'Static warp', pages: [
              LiteralFixtureEventPage(characterName: 'ReferenceNpc', commands: [
                LiteralFixtureEventCommand(201, [0, 2, 2, 2, 0, 0]),
              ]),
            ]),
            LiteralFixtureEvent(
                id: 5,
                x: 3,
                y: 3,
                name: 'Empty final page',
                pages: [
                  LiteralFixtureEventPage(
                      characterName: 'ReferenceNpc',
                      commands: [
                        LiteralFixtureEventCommand(
                            101, ['Première page à jouer avant la page vide.']),
                        LiteralFixtureEventCommand(123, ['A', 0]),
                      ]),
                  LiteralFixtureEventPage(
                      characterName: 'ReferenceNpc',
                      selfSwitch: 'A',
                      commands: [
                        LiteralFixtureEventCommand(
                            101, ['Cette page inférieure doit rester muette.']),
                        LiteralFixtureEventCommand(123, ['B', 0]),
                      ]),
                  LiteralFixtureEventPage(
                      characterName: 'ReferenceNpc',
                      selfSwitch: 'A',
                      commands: [
                        LiteralFixtureEventCommand(0, []),
                      ]),
                ]),
          ]),
      LiteralFixtureMap(
          id: 2,
          name: 'Original warp arrival',
          width: 6,
          height: 5,
          layers: [
            List.filled(30, 384),
            List.filled(30, 0),
            List.filled(30, 0)
          ]),
    ];

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

Future<void> main() async {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  _require(scriptsPath != null && path.isAbsolute(scriptsPath),
      'AVELUNE_AC13_SOURCE_SCRIPTS must name the exact source archive');
  final scripts = File(scriptsPath!);
  _require(
      await FileSystemEntity.type(scripts.path, followLinks: false) ==
          FileSystemEntityType.file,
      'The source archive must be a regular file');
  final stat = await scripts.stat();
  _require(stat.size > 0 && stat.size <= 16 * 1024 * 1024,
      'Source archive size is outside the bounded profile');
  final archiveBytes = await scripts.readAsBytes();
  final archiveHash = _hash(archiveBytes);
  _require(archiveHash == SourceEventProfile.kantoScriptsArchiveSha256,
      'The event oracle requires the exact attested Kanto archive');
  final root = await Directory.systemTemp.createTemp('ac13-event-reference-');
  final sourceRoot = Directory(path.join(root.path, 'original-source'));
  final destination =
      await Directory(path.join(root.path, 'native-output')).create();
  final fixture = await LiteralTileFixture.create(
      namespace: _namespace,
      sourceRootPath: sourceRoot.path,
      scriptsBytes: archiveBytes,
      includeEventSystem: true,
      maps: _originalMaps(),
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = ReferencePlayer\n'),
        'Graphics/Characters/ReferencePlayer.png':
            _originalCharacterPng(red: 48),
        'Graphics/Characters/ReferenceNpc.png': _originalCharacterPng(red: 128),
      });
  final sourceHashesBefore = await _directoryHashes(sourceRoot.path);
  final workflow = ConverterWorkflow();
  try {
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: sourceRoot.path,
        logicalProjectNamespace: ConverterId(_namespace)));
    _require(snapshot.state == SourceScanState.complete,
        'The original source scan must complete');
    workflow.updateSettings(ConverterStudySettings(
        projectName: 'Original event runtime reference',
        parentPath: destination.path,
        folderName: 'converted-reference',
        selectedSourceMapIds: const [1, 2],
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason:
                'User-authorized original offline event qualification; no global game certification.'),
        assetOutputMode: AssetOutputMode.sharedAtlas));
    final prepared = await workflow.prepareStudy();
    await File(path.join(root.path, 'preparation.json')).writeAsString(
        jsonEncode({
          'diagnostics': prepared.composition.diagnostics
              .map((item) => item.toJson())
              .toList(),
          'normalizedSource': prepared.normalizedSource.toJson(),
          'compositionEvidence': prepared.nativeDraft?.compositionEvidence,
        }),
        flush: true);
    _require(prepared.canApprove && prepared.nativeDraft != null,
        'The original event study must be admissible');
    final draft = prepared.nativeDraft!;
    final eventEvidence = Map<String, dynamic>.from(
        draft.compositionEvidence['sourceEvents'] as Map);
    final projection =
        Map<String, dynamic>.from(eventEvidence['projection'] as Map);
    _require(
        projection['qualifiedEventCount'] == 4 &&
            projection['quarantinedEventCount'] == 1,
        'Exactly four original events must project and the unknown reward must quarantine');
    final approval = workflow.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final result = await workflow.writeApproved(approval);
    _require(
        result.receipt.verified && result.sourceUnchanged && result.published,
        'The canonical workflow must publish a verified source-preserving project');
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [result.projectPath], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.projectPath);
    late ProjectManifest manifest;
    late MapData firstMap;
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      _require(native.loadDiagnostics.isEmpty,
          'The native project must reopen strictly');
      manifest = native.manifest;
      firstMap = native.mapById(draft.mapIds[1]!)!;
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    final sourceHashesAfter = await _directoryHashes(sourceRoot.path);
    _require(
        canonicalJsonOf(sourceHashesBefore) ==
            canonicalJsonOf(sourceHashesAfter),
        'The original fixture source must remain unchanged');
    _require(_hash(await scripts.readAsBytes()) == archiveHash,
        'The external archive must remain unchanged');
    _require(
        fixture.sourceBytes['Data/Scripts.rxdata']!.length ==
            archiveBytes.length,
        'The inert archive witness must retain exact bytes');
    final record = {
      'kind': 'originalSourceConvertedEventReference',
      'version': 1,
      'projectFilePath': path.join(result.projectPath, 'project.json'),
      'sourceRootPath': sourceRoot.path,
      'sourceScriptsArchiveHash': archiveHash,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourceHashesBefore': sourceHashesBefore,
      'sourceHashesAfter': sourceHashesAfter,
      'nativeHashes': await _directoryHashes(result.projectPath),
      'nativeDraftHash': draft.canonicalHash.value,
      'nativeRevision': result.receipt.nativeRevision,
      'sourceNamespace': _namespace,
      'mapIds': {
        for (final entry in draft.mapIds.entries) '${entry.key}': entry.value
      },
      'entityIds': {
        for (final entity in firstMap.entities
            .where((entity) => entity.kind != MapEntityKind.spawn))
          entity.name: entity.id
      },
      'sourceEvents': eventEvidence,
      'configuredRecordCount': manifest.eventRegistry!.records
          .where((record) => record.definitionOrNull != null)
          .length,
      'draftRecordCount': manifest.eventRegistry!.records
          .where((record) => record.draftOrNull != null)
          .length,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'published': result.published,
      'globalPlayabilityCertified': false,
      'writerVerified': result.receipt.verified,
      'sourceUnchanged': result.sourceUnchanged,
    };
    final output = File(path.join(root.path, 'reference-fixtures.json'));
    await output.writeAsString(jsonEncode(record), flush: true);
    stdout.writeln(jsonEncode({
      'manifestPath': output.path,
      'projectFilePath': record['projectFilePath'],
      'configuredRecordCount': record['configuredRecordCount'],
      'draftRecordCount': record['draftRecordCount']
    }));
  } finally {
    await workflow.dispose();
  }
}
