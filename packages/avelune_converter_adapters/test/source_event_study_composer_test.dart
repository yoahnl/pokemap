import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];

  test('unqualified event profile leaves a literal study unchanged', () async {
    final fixture = await LiteralTileFixture.create(includeEventSystem: true);
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Unqualified',
        parentPath: '/private/tmp',
        folderName: 'unused');
    expect(
        await const SourceEventStudyComposer().compose(
            source: fixture.source, base: literal.draft!, files: fixture.files),
        isNull);
  });

  test('missing NPC sprite quarantines its whole event and preserves the map',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('ac13-missing-npc-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = PresentActor\n'),
          'Graphics/Characters/PresentActor.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        },
        maps: [
          LiteralFixtureMap(id: 1, width: 4, height: 4, layers: [
            List.filled(16, 384),
            List.filled(16, 0),
            List.filled(16, 0)
          ], events: const [
            LiteralFixtureEvent(id: 1, name: 'Missing NPC', x: 1, y: 1, pages: [
              LiteralFixtureEventPage(characterName: 'MissingActor', commands: [
                LiteralFixtureEventCommand(101, ['Ne pas activer']),
                LiteralFixtureEventCommand(123, ['A', 0]),
              ]),
              LiteralFixtureEventPage(
                  characterName: 'MissingActor', selfSwitch: 'A', commands: []),
            ]),
            LiteralFixtureEvent(id: 2, name: 'Present NPC', x: 2, y: 2, pages: [
              LiteralFixtureEventPage(characterName: 'PresentActor', commands: [
                LiteralFixtureEventCommand(101, ['Bienvenue']),
              ]),
            ]),
          ])
        ]);
    expect(fixture.source.canPlan, isTrue);
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Missing sprite study',
        parentPath: temporary.path,
        folderName: 'missing-sprite-study');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: fixture.source, base: literal, files: fixture.files))!;
    final composed = (await const SourceEventStudyComposer().compose(
        source: fixture.source, base: semantic, files: fixture.files))!;
    final events = composed.projection.semanticEvidence['events'] as List;
    final missing = events
        .cast<Map>()
        .singleWhere((entry) => (entry['locator'] as Map)['eventId'] == 1);
    expect(missing['status'], 'quarantinedWholeEvent');
    expect(missing['gaps'], contains('characterBindingMissing'));
    expect(missing['pages'], hasLength(2));
    final records = composed.projection.registry.records;
    expect(records.where((record) => record.definitionOrNull != null),
        hasLength(1));
    expect(records.where((record) => record.draftOrNull != null), hasLength(1));
    expect(composed.projection.facts, isEmpty);
    expect(composed.projection.dialogueSources.values.single,
        contains('Bienvenue'));
    final approval = approveNativeFixtureDraft(composed.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, composed.draft);
    expect(receipt.verified, isTrue);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      final map = native.mapById(composed.draft.mapIds[1]!)!;
      final actors =
          map.entities.where((entity) => entity.kind != MapEntityKind.spawn);
      expect(actors.map((entity) => entity.name), ['Present NPC']);
      expect(native.manifest.eventRegistry!.records, records);
      expect(native.manifest.facts, isEmpty);
      expect(map.size, const GridSize(width: 4, height: 4));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);

  test(
      'qualified pages survive canonical native write and reject altered actions',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('ac13-events-writer-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
          'Graphics/Characters/UnusedActor.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        },
        maps: [
          LiteralFixtureMap(id: 1, width: 4, height: 4, layers: [
            List.filled(16, 384),
            List.filled(16, 0),
            List.filled(16, 0)
          ], events: const [
            LiteralFixtureEvent(id: 1, x: 1, y: 1, pages: [
              LiteralFixtureEventPage(
                  characterName: 'OriginalPlayer',
                  commands: [
                    LiteralFixtureEventCommand(101, ['Bienvenue']),
                    LiteralFixtureEventCommand(123, ['A', 0]),
                  ]),
              LiteralFixtureEventPage(
                  characterName: 'OriginalPlayer',
                  selfSwitch: 'A',
                  commands: [
                    LiteralFixtureEventCommand(101, ['De retour']),
                  ]),
            ]),
            LiteralFixtureEvent(id: 2, x: 2, y: 2, pages: [
              LiteralFixtureEventPage(characterName: 'UnusedActor', commands: [
                LiteralFixtureEventCommand(355, ['unknown_reward()']),
                LiteralFixtureEventCommand(123, ['A', 0]),
              ]),
            ]),
            LiteralFixtureEvent(id: 3, x: 3, y: 0, pages: [
              LiteralFixtureEventPage(trigger: 1, through: true, commands: [
                LiteralFixtureEventCommand(102, [
                  ['Continuer'],
                  5
                ]),
                LiteralFixtureEventCommand(402, [0, 'Continuer']),
                LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                LiteralFixtureEventCommand(403, []),
                LiteralFixtureEventCommand(123, ['B', 0], indent: 1),
                LiteralFixtureEventCommand(404, []),
              ]),
            ]),
            LiteralFixtureEvent(id: 4, x: 3, y: 3, pages: [
              LiteralFixtureEventPage(
                  characterName: 'OriginalPlayer',
                  commands: [
                    LiteralFixtureEventCommand(201, [0, 2, 1, 1, 0, 0]),
                  ]),
            ]),
          ]),
          LiteralFixtureMap(id: 2, width: 4, height: 4, layers: [
            List.filled(16, 384),
            List.filled(16, 0),
            List.filled(16, 0)
          ]),
        ]);
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1, 2],
        projectName: 'Original events',
        parentPath: temporary.path,
        folderName: 'original-events');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: fixture.source, base: literal, files: fixture.files))!;
    final composed = (await const SourceEventStudyComposer().compose(
        source: fixture.source, base: semantic, files: fixture.files))!;
    final draft = composed.draft;
    expect((draft.compositionEvidence['sourceEvents'] as Map)['aiCalls'], 0);
    expect(
        draft.mutations.where(
            (entry) => entry.actionId == 'characterStudio.character.create'),
        hasLength(2));
    expect(composed.projection.registry.records, hasLength(5));
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      expect(native.manifest.eventRegistry!.records,
          composed.projection.registry.records);
      expect(native.manifest.facts, composed.projection.facts);
      expect(native.manifest.scenes, composed.projection.scenes);
      final firstMap = native.mapById(draft.mapIds[1]!)!;
      expect(
          firstMap.entities
              .where((entity) => entity.kind != MapEntityKind.spawn),
          hasLength(3));
      expect(firstMap.triggers, hasLength(1));
      expect(native.mapById(draft.mapIds[2]!)!.warps, hasLength(1));
      final policy = native.manifest.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneYarnDialoguePayload>()
          .expand((payload) => payload.choicePolicies)
          .single;
      expect(
          policy.cancellation.kind, SceneDialogueChoiceCancellationKind.branch);
      for (final entry in native.manifest.dialogues) {
        expect(
            await File('${receipt.projectPath}/${entry.relativePath}')
                .readAsString(),
            composed.projection.dialogueSources[entry.id]);
      }
      final catalog = AssetCatalog.fromJson(jsonDecode(
              utf8.decode(native.resourceBytes(assetCatalogResourceIdentity)))
          as Map<String, dynamic>);
      final companion = catalog.records.singleWhere(
          (entry) => entry.usages.contains('converter.sourceEvents'));
      final preserved = jsonDecode(
          await File('${receipt.projectPath}/${companion.logicalPath}')
              .readAsString()) as Map;
      final sourceFiles = preserved['preservedSourceFiles'] as List;
      final sourceMap = sourceFiles.cast<Map>().singleWhere(
          (entry) => entry['relativePath'] == 'Data/Map001.rxdata');
      final reconstructed = <int>[];
      for (final chunk in sourceMap['chunks'] as List) {
        final data = jsonDecode(await File(
                '${receipt.projectPath}/${(chunk as Map)['logicalPath']}')
            .readAsString()) as Map;
        reconstructed.addAll(base64Decode(data['bytesBase64'] as String));
      }
      expect(reconstructed, fixture.sourceBytes['Data/Map001.rxdata']);
      expect(literalFixtureHash(reconstructed).value, sourceMap['rawSha256']);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    final altered = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: draft.folderName,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        compositionEvidence: draft.compositionEvidence,
        mutations: draft.mutations
            .map((entry) => entry.actionId == 'scene.upsert'
                ? NativeMutation(
                    operationId: entry.operationId,
                    actionId: entry.actionId,
                    sourceEntityIds: entry.sourceEntityIds,
                    targetEntityIds: entry.targetEntityIds,
                    parameters: {
                        'scene': {
                          ...entry.parameters['scene'] as Map,
                          'name': 'Altered'
                        }
                      })
                : entry)
            .toList());
    final alteredApproval = approveNativeFixtureDraft(altered);
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(alteredApproval.plan, alteredApproval.context, altered),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.semantics.regeneration')));
    expect(stages, isEmpty);
    final dialogue = composed.projection.dialogues.first;
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
          if (stage == NativeWriteStage.beforeNativeVerify) {
            final file = File('$projectPath/${dialogue.relativePath}');
            await file.writeAsString((await file.readAsString())
                .replaceFirst('Bienvenue', 'Texte modifié'));
          }
        }).write(approval.plan, approval.context, draft),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.verify.dialogue')));
  }, skip: scriptsPath == null || !Platform.isMacOS);
}
