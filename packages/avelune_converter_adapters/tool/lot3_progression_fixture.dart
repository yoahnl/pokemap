import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import '../test/support/literal_tile_fixture.dart';

const _namespace = 'original-lot3-progression';

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

List<LiteralFixtureMap> _maps() => [
      LiteralFixtureMap(
        id: 1,
        name: 'Original progression laboratory',
        width: 7,
        height: 5,
        layers: [List.filled(35, 384), List.filled(35, 0), List.filled(35, 0)],
        events: const [
          LiteralFixtureEvent(
            id: 1,
            name: 'Progression NPC',
            x: 1,
            y: 2,
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalNpc',
                commands: [
                  LiteralFixtureEventCommand(101, ['Avant la progression.']),
                  LiteralFixtureEventCommand(122, [1, 1, 0, 0, 0]),
                  LiteralFixtureEventCommand(122, [1, 1, 1, 0, 3]),
                  LiteralFixtureEventCommand(122, [1, 1, 2, 0, 1]),
                  LiteralFixtureEventCommand(111, [1, 1, 0, 2, 0]),
                  LiteralFixtureEventCommand(121, [1, 1, 0], indent: 1),
                  LiteralFixtureEventCommand(101, ['Compteur validé.'],
                      indent: 1),
                  LiteralFixtureEventCommand(411, []),
                  LiteralFixtureEventCommand(101, ['Compteur incorrect.'],
                      indent: 1),
                  LiteralFixtureEventCommand(412, []),
                  LiteralFixtureEventCommand(123, ['A', 0]),
                ],
              ),
              LiteralFixtureEventPage(
                characterName: 'OriginalNpcAfter',
                direction: 6,
                selfSwitch: 'A',
                commands: [
                  LiteralFixtureEventCommand(101, ['Après la progression.']),
                ],
              ),
            ],
          ),
          LiteralFixtureEvent(
            id: 2,
            name: 'Disappearing object',
            x: 3,
            y: 2,
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalObject',
                commands: [],
              ),
              LiteralFixtureEventPage(
                globalSwitch: 1,
                through: true,
                commands: [],
              ),
            ],
          ),
          LiteralFixtureEvent(
            id: 3,
            name: 'Progression gate',
            x: 4,
            y: 2,
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalGate',
                commands: [],
              ),
              LiteralFixtureEventPage(
                globalSwitch: 1,
                through: true,
                commands: [],
              ),
            ],
          ),
          LiteralFixtureEvent(
            id: 4,
            name: 'Unqualified progression',
            x: 6,
            y: 4,
            pages: [
              LiteralFixtureEventPage(
                commands: [
                  LiteralFixtureEventCommand(
                      355, ['undeclaredProgressionEffect()']),
                  LiteralFixtureEventCommand(121, [2, 2, 0]),
                  LiteralFixtureEventCommand(122, [2, 2, 0, 0, 7]),
                  LiteralFixtureEventCommand(123, ['A', 0]),
                ],
              ),
            ],
          ),
        ],
      ),
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
    switchNames: const [null, 'Original gate open', 'Unqualified effect'],
    variableNames: const [
      null,
      'Original progress counter',
      'Unqualified count'
    ],
    maps: _maps(),
    extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
      'Graphics/Characters/OriginalPlayer.png': _character(32),
      'Graphics/Characters/OriginalNpc.png': _character(80),
      'Graphics/Characters/OriginalNpcAfter.png': _character(112),
      'Graphics/Characters/OriginalObject.png': _character(144),
      'Graphics/Characters/OriginalGate.png': _character(176),
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
      projectName: 'Original LOT3 progression',
      parentPath: destination.path,
      folderName: 'converted',
      selectedSourceMapIds: const [1],
      profileAcknowledgement: SourceStudyAcknowledgement(
        sourceSnapshotHash: snapshot.canonicalHash,
        profileEvidenceHash: snapshot.profile.evidenceHash,
        humanConfirmed: true,
        reason: 'User-authorized portable original progression qualification.',
      ),
      assetOutputMode: AssetOutputMode.sharedAtlas,
    ));
    final prepared = await workflow.prepareStudy();
    _require(prepared.canApprove && prepared.nativeDraft != null,
        'The original progression study must be admissible.');
    final draft = prepared.nativeDraft!;
    final eventEvidence = Map<String, dynamic>.from(
        draft.compositionEvidence['sourceEvents'] as Map);
    final projection =
        Map<String, dynamic>.from(eventEvidence['projection'] as Map);
    _require(
        projection['qualifiedEventCount'] == 3 &&
            projection['quarantinedEventCount'] == 1,
        'Exactly three original events must qualify and the unknown script must quarantine.');
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
      final map = native.mapById(draft.mapIds[1]!)!;
      entityIds = {
        for (final entity in map.entities
            .where((entity) => entity.kind != MapEntityKind.spawn))
          entity.name: entity.id,
      };
      final adjustments = native.manifest.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.consequence)
          .whereType<SceneAdjustIntegerFactConsequence>()
          .toList();
      _require(
          adjustments.length == 2 &&
              adjustments
                  .map((entry) => entry.delta)
                  .toSet()
                  .containsAll({3, -1}),
          'The converted source must retain both typed arithmetic operations.');
    } finally {
      await native?.payloadOwner?.release();
      opener.closeWorkspace(opened.workspaceHandle);
    }
    final after = await _hashes(sourceRoot);
    _require(canonicalJsonOf(before) == canonicalJsonOf(after),
        'The original source must remain unchanged.');
    final receipt = {
      'kind': 'originalLot3ProgressionReference',
      'schemaVersion': 1,
      'sourceNamespace': _namespace,
      'sourceRootPath': sourceRoot,
      'projectFilePath': path.join(result.projectPath, 'project.json'),
      'mapId': draft.mapIds[1],
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
        for (final event in _maps().single.events)
          '${event.id}': [
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
    final file = File(path.join(root.path, 'progression-reference.json'));
    await file.writeAsString(jsonEncode(receipt), flush: true);
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
