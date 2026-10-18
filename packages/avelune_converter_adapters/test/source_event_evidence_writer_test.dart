import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

const _limits = NativeWriteLimits(
    maxArtifacts: 1024,
    maxMutations: 16384,
    jsonLimits: ContractLimits(maxTextCodeUnits: 16777216));

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  test(
      'large source event companion survives strict write and rejects forged chunks before staging',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('ac13-evidence-writer-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4))
        },
        maps: [
          for (var mapId = 1; mapId <= 4; mapId++)
            LiteralFixtureMap(id: mapId, events: [
              for (var id = 1; id <= 300; id++)
                LiteralFixtureEvent(id: id, x: 0, y: 0, pages: const [
                  LiteralFixtureEventPage(
                      characterName: 'MissingActor', commands: []),
                  LiteralFixtureEventPage(
                      characterName: 'MissingActor',
                      selfSwitch: 'A',
                      commands: []),
                ]),
            ])
        ]);
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1, 2, 3, 4],
        projectName: 'Bounded evidence',
        parentPath: temporary.path,
        folderName: 'bounded',
        limits: _limits);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: fixture.source,
        base: base,
        files: fixture.files,
        limits: _limits))!;
    final composed = (await const SourceEventStudyComposer().compose(
        source: fixture.source,
        base: semantic,
        files: fixture.files,
        limits: _limits))!;
    final draft = composed.draft;
    final companionMutation = draft.mutations.singleWhere((m) =>
        (m.parameters['usages'] as List?)?.contains('converter.sourceEvents') ==
        true);
    final globalOwners = [
      for (var mapId = 1; mapId <= 4; mapId++)
        fixture.snapshot.entries
            .singleWhere(
              (entry) => entry.relativePath == 'Data/Map00$mapId.rxdata',
            )
            .fileId
            .value,
    ]..sort();
    final projectionImports = draft.mutations.where(
      (mutation) =>
          (mutation.parameters['usages'] as List?)?.contains(
            'converter.sourceEventProjectionBytes',
          ) ==
          true,
    );
    expect(projectionImports, isNotEmpty);
    for (final mutation in [companionMutation, ...projectionImports]) {
      expect(mutation.sourceEntityIds.map((id) => id.value), globalOwners);
    }
    final companion = draft.artifacts.singleWhere(
        (a) => a.handle == companionMutation.parameters['artifactHandle']);
    final index = jsonDecode(utf8.decode(companion.bytes)) as Map;
    expect(index['kind'], 'sourceEventProjectionChunks');
    expect(index['byteLength'], greaterThan(1048576));
    final descriptors = index['chunks'] as List;
    final companionBytes = <int>[];
    for (final descriptor in descriptors) {
      final artifact = draft.artifacts
          .singleWhere((a) => a.handle == descriptor['artifactHandle']);
      expect(artifact.bytes.length, lessThanOrEqualTo(1048576));
      final raw = jsonDecode(utf8.decode(artifact.bytes)) as Map;
      expect(raw['offset'], companionBytes.length);
      companionBytes.addAll(base64Decode(raw['bytesBase64'] as String));
    }
    final evidence =
        jsonDecode(utf8.decode(companionBytes)) as Map<String, Object?>;
    final preserved = evidence.remove('preservedSourceFiles');
    expect(preserved, isNotEmpty);
    expect(
        canonicalJsonOf(evidence, limits: _limits.jsonLimits),
        canonicalJsonOf(composed.projection.semanticEvidence,
            limits: _limits.jsonLimits));
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft, limits: _limits);
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
      expect(native.manifest.eventRegistry!.records,
          composed.projection.registry.records);
      expect(native.manifest.facts, composed.projection.facts);
      expect(native.manifest.scenes, composed.projection.scenes);
      final catalog = AssetCatalog.fromJson(jsonDecode(
              utf8.decode(native.resourceBytes(assetCatalogResourceIdentity)))
          as Map<String, dynamic>);
      final asset = catalog.records
          .singleWhere((a) => a.usages.contains('converter.sourceEvents'));
      expect(
          await File('${receipt.projectPath}/${asset.logicalPath}')
              .readAsBytes(),
          companion.bytes);
      for (final descriptor in descriptors) {
        expect(
            await File('${receipt.projectPath}/${descriptor['logicalPath']}')
                .exists(),
            isTrue);
      }
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    NativeProjectDraft withArtifacts(List<NativeArtifact> artifacts) =>
        NativeProjectDraft(
            source: draft.source,
            projectName: draft.projectName,
            parentPath: draft.parentPath,
            folderName: draft.folderName,
            mapIds: draft.mapIds,
            artifacts: artifacts,
            sourceArtifacts: draft.sourceArtifacts,
            mutations: draft.mutations,
            compositionEvidence: draft.compositionEvidence,
            limits: _limits);
    final chunk = draft.artifacts
        .singleWhere((a) => a.handle == descriptors.first['artifactHandle']);
    final raw = jsonDecode(utf8.decode(chunk.bytes)) as Map<String, Object?>;
    final changed = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf({...raw, 'offset': 1})),
        mediaType: 'application/json',
        limits: _limits);
    final extra = NativeArtifact(
        bytes: utf8.encode('{"unreferencedEvidenceChunk":true}'),
        mediaType: 'application/json',
        limits: _limits);
    final cases = [
      (
        draft: withArtifacts(
            draft.artifacts.where((a) => a.handle != chunk.handle).toList()),
        code: 'native.tileset.invalid',
      ),
      (
        draft: withArtifacts([
          for (final a in draft.artifacts)
            a.handle == chunk.handle ? changed : a
        ]),
        code: 'native.tileset.invalid',
      ),
      (
        draft: withArtifacts([...draft.artifacts, extra]),
        code: 'native.semantics.regeneration',
      ),
    ];
    for (final forged in cases) {
      final stages = <NativeWriteStage>[];
      final forgedApproval = approveNativeFixtureDraft(forged.draft);
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(forgedApproval.plan, forgedApproval.context, forged.draft,
                  limits: _limits),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', forged.code)));
      expect(stages, isEmpty);
    }
    final cancellation = ScanCancellation()..cancel();
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(approval.plan, approval.context, draft,
                limits: _limits, cancellation: cancellation),
        throwsA(isA<NativeWriteException>()));
    expect(stages, isEmpty);
  },
      skip: scriptsPath == null || !Platform.isMacOS,
      timeout: const Timeout(Duration(minutes: 10)));
}
