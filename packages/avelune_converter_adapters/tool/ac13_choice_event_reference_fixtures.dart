import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import '../test/support/literal_tile_fixture.dart';

const _namespace = 'original-ac13-evt04-choice-cancel';
const _archiveHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

void _require(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<String> _sha(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

Future<Map<String, String>> _inventory(Directory root) async {
  final hashes = <String, String>{};
  await for (final entry in root.list(recursive: true, followLinks: false)) {
    _require(entry is! Link, 'Symlinks are not part of this QA fixture');
    if (entry is File) {
      hashes[path.relative(entry.path, from: root.path)] = await _sha(entry);
    }
  }
  final names = hashes.keys.toList()..sort();
  return {for (final name in names) name: hashes[name]!};
}

List<int> _character(int red) {
  final raster = image.Image(width: 128, height: 128, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var y = 8; y < 32; y++) {
        for (var x = 8; x < 24; x++) {
          raster.setPixelRgba(
              column * 32 + x, row * 32 + y, red, 40 + row * 24, 112, 255);
        }
      }
    }
  }
  return image.encodePng(raster);
}

List<LiteralFixtureEventCommand> _commands({required bool cancellable}) => [
      LiteralFixtureEventCommand(
          101, [cancellable ? 'Quelle voie ?' : 'Choix obligatoire.']),
      LiteralFixtureEventCommand(102, [
        ['Voie A', 'Voie B'],
        cancellable ? 5 : 0
      ]),
      const LiteralFixtureEventCommand(402, [0, 'Voie A']),
      const LiteralFixtureEventCommand(101, ['Branche A.'], indent: 1),
      const LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
      const LiteralFixtureEventCommand(402, [1, 'Voie B']),
      const LiteralFixtureEventCommand(101, ['Branche B.'], indent: 1),
      const LiteralFixtureEventCommand(123, ['B', 0], indent: 1),
      if (cancellable) ...[
        const LiteralFixtureEventCommand(403, []),
        const LiteralFixtureEventCommand(101, ['Annulation distincte.'],
            indent: 1),
        const LiteralFixtureEventCommand(123, ['C', 0], indent: 1),
      ],
      const LiteralFixtureEventCommand(404, []),
      LiteralFixtureEventCommand(101, [
        cancellable ? 'Continuation commune.' : 'Continuation obligatoire.'
      ]),
      const LiteralFixtureEventCommand(123, ['D', 0]),
    ];

Future<void> main(List<String> args) async {
  _require(args.length == 1, 'Expected one fresh absolute output directory');
  final output = Directory(args.single);
  _require(output.isAbsolute && !await output.exists(),
      'The QA output directory must be fresh and absolute');
  _require(!await FileSystemEntity.isLink(output.path),
      'The QA output must not be a symlink');
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  _require(scriptsPath != null && path.isAbsolute(scriptsPath),
      'AVELUNE_AC13_SOURCE_SCRIPTS must identify the attested archive');
  final scripts = File(scriptsPath!);
  _require(
      await FileSystemEntity.type(scripts.path, followLinks: false) ==
          FileSystemEntityType.file,
      'The source archive must be a regular file');
  _require(await _sha(scripts) == _archiveHash,
      'The source profile requires the exact attested archive');
  final archiveBytes = await scripts.readAsBytes();
  final source = Directory(path.join(output.path, 'original-source'));
  final nativeParent = Directory(path.join(output.path, 'native-output'));
  await output.create();
  await nativeParent.create();
  final withCancel = _commands(cancellable: true);
  final withoutCancel = _commands(cancellable: false);
  final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

      namespace: _namespace,
      sourceRootPath: source.path,
      scriptsBytes: archiveBytes,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(
            id: 1,
            name: 'Original choice and cancellation',
            width: 7,
            height: 5,
            layers: [
              List.filled(35, 384),
              List.filled(35, 0),
              List.filled(35, 0)
            ],
            events: [
              LiteralFixtureEvent(
                  id: 1,
                  x: 1,
                  y: 1,
                  name: 'Separate cancel',
                  pages: [
                    LiteralFixtureEventPage(
                        characterName: 'ChoiceNpc', commands: withCancel)
                  ]),
              LiteralFixtureEvent(
                  id: 2,
                  x: 4,
                  y: 1,
                  name: 'Disabled cancel',
                  pages: [
                    LiteralFixtureEventPage(
                        characterName: 'ChoiceNpc', commands: withoutCancel)
                  ]),
            ])
      ],
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = ChoicePlayer\n'),
        'Graphics/Characters/ChoicePlayer.png': _character(48),
        'Graphics/Characters/ChoiceNpc.png': _character(128),
      });
  final sourceBefore = await _inventory(source);
  final workflow = ConverterWorkflow();
  final subscription = workflow.events.listen((event) {
    stdout.writeln(jsonEncode({'phase': event.state.phase?.name ?? 'idle'}));
  });
  try {
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: source.path,
        logicalProjectNamespace: ConverterId(_namespace)));
    _require(snapshot.state == SourceScanState.complete,
        'The original RMXP fixture scan must complete');
    workflow.updateSettings(ConverterStudySettings(
        interpretationProfile: fixtureSourceInterpretationProfile,
        projectName: 'EVT04 original choice and cancellation',
        parentPath: nativeParent.path,
        folderName: 'published-choice-reference',
        selectedSourceMapIds: const [1],
        assetOutputMode: AssetOutputMode.sharedAtlas,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason:
                'User-authorized original offline EVT04 qualification; no global source admission.')));
    final prepared = await workflow.prepareStudy();
    await File(path.join(output.path, 'preparation.json')).writeAsString(
        jsonEncode({
          'canApprove': prepared.canApprove,
          'normalized': prepared.normalizedSource.toJson(),
          'diagnostics': [
            for (final entry in prepared.composition.diagnostics) entry.toJson()
          ],
          'compositionEvidence': prepared.nativeDraft?.compositionEvidence,
          'sourceAdmission': false,
          'runtimeExecuted': false,
        }),
        flush: true);
    _require(prepared.canApprove && prepared.nativeDraft != null,
        'The real RMXP choice fixture must be approvable');
    final draft = prepared.nativeDraft!;
    final sourceEvents = Map<String, dynamic>.from(
        draft.compositionEvidence['sourceEvents'] as Map);
    final projection =
        Map<String, dynamic>.from(sourceEvents['projection'] as Map);
    _require(
        projection['qualifiedEventCount'] == 2 &&
            projection['quarantinedEventCount'] == 0,
        'Both exact fixture events must adapt without quarantine');
    final recipe = workflow.exportStudyPlanRecipe();
    await File(path.join(output.path, 'recipe.json'))
        .writeAsString(recipe.encode(), flush: true);
    final approval = workflow.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    final result = await workflow.writeApproved(approval);
    _require(
        result.published && result.receipt.verified && result.sourceUnchanged,
        'A normal verified publication is required');
    final project = Directory(result.projectPath);
    final verification = await const NativeStudyVerifier().verify(
        projectPath: project.path,
        allowedParentPath: await nativeParent.resolveSymbolicLinks());
    _require(
        verification.mapCount == 1 &&
            verification.nativeRevision == result.publication.nativeRevision,
        'Strict verification must match the one-map publication');
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [nativeParent.path], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(project.path);
    late ProjectManifest manifest;
    late MapData map;
    try {
      final loaded = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      _require(loaded.loadDiagnostics.isEmpty,
          'Strict load must be diagnostic-free');
      manifest = loaded.manifest;
      map = loaded.mapById(draft.mapIds[1]!)!;
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    final definitions = manifest.eventRegistry!.records
        .map((entry) => entry.definitionOrNull)
        .whereType<NarrativeEventDefinition>()
        .toList();
    _require(
        definitions.length == 2, 'Exactly two canonical events are expected');
    final eventIds = <String, String>{};
    final entityIds = <String, String>{};
    for (final entry
        in {'1': 'Separate cancel', '2': 'Disabled cancel'}.entries) {
      final entity =
          map.entities.singleWhere((entity) => entity.name == entry.value);
      final definition = definitions.singleWhere(
          (definition) => definition.source.toJson()['entityId'] == entity.id);
      _require(definition.source.toJson()['kind'] == 'entityInteract',
          'The fixture must start by real primary interaction');
      final scene = manifest.scenes
          .singleWhere((scene) => scene.id == definition.toJson()['sceneId']);
      final payload = scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneYarnDialoguePayload>()
          .singleWhere((payload) => payload.choicePolicies.isNotEmpty);
      final choice = payload.choicePolicies.single;
      _require(
          choice.defaultOutcomeId == 'choice_0' &&
              choice.cancellation.kind ==
                  (entry.key == '1'
                      ? SceneDialogueChoiceCancellationKind.branch
                      : SceneDialogueChoiceCancellationKind.disabled),
          'The converted policy must preserve the source cancel mode');
      eventIds[entry.key] = definition.id;
      entityIds[entry.key] = entity.id;
    }
    final sourceAfter = await _inventory(source);
    _require(canonicalJsonOf(sourceBefore) == canonicalJsonOf(sourceAfter),
        'The generated source must remain byte-identical');
    _require(
        await _sha(scripts) == _archiveHash &&
            fixture.sourceBytes['Data/Scripts.rxdata']!.length ==
                archiveBytes.length,
        'The inert source archive must be preserved');
    final record = {
      'kind': 'originalRmxpChoiceCancellationReference',
      'version': 1,
      'projectPath': project.path,
      'projectFilePath': path.join(project.path, 'project.json'),
      'sourceRootPath': source.path,
      'sourceNamespace': _namespace,
      'sourceScriptsArchiveHash': _archiveHash,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'nativeDraftHash': draft.canonicalHash.value,
      'nativeRevision': verification.nativeRevision,
      'nativeHashes': await _inventory(project),
      'sourceHashesBefore': sourceBefore,
      'sourceHashesAfter': sourceAfter,
      'mapId': draft.mapIds[1],
      'eventIds': eventIds,
      'entityIds': entityIds,
      'sourceEvents': sourceEvents,
      'originalCommands': {
        for (final entry in {'1': withCancel, '2': withoutCancel}.entries)
          entry.key: [
            for (final command in entry.value)
              {
                'code': command.code,
                'indent': command.indent,
                'parameters': command.parameters
              }
          ]
      },
      'writerOrigin': 'converterWorkflow.writeApproved',
      'published': result.published,
      'verified': verification.verified,
      'sourceUnchanged': result.sourceUnchanged,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'sourceAdmission': false,
      'playableCertified': false,
      'runtimeExecuted': false,
      'guiQualified': false,
      'stateBoundary': 'afterCompletedInteraction',
      'nativeConsequenceCommitPolicy': 'bufferUntilSceneCompleted',
      'sourceIntermediateFactCommitTimingQualified': false,
    };
    await File(path.join(output.path, 'reference-fixture.json'))
        .writeAsString(jsonEncode(record), flush: true);
    await File(path.join(output.path, 'native-verification.json'))
        .writeAsString(jsonEncode(verification.toJson()), flush: true);
    stdout.writeln(jsonEncode({
      'referencePath': path.join(output.path, 'reference-fixture.json'),
      'projectPath': project.path,
      'published': true,
      'sourceAdmission': false,
      'runtimeExecuted': false,
    }));
  } finally {
    await subscription.cancel();
    await workflow.dispose();
  }
}
