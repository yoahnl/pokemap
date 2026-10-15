import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

final class _OriginalFiles implements SourceFilePort {
  _OriginalFiles(this.root, this.snapshot);
  final String root;
  final SourceSnapshot snapshot;
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = snapshot.entries.singleWhere((entry) => entry.fileId == id);
    validateSourceRelativePath(entry.relativePath);
    final file = File('$root/${entry.relativePath}');
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) throw StateError('Source escapes root');
    return file.readAsBytes();
  }
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  final outputParent =
      Platform.environment['AVELUNE_KANTO33_CENTER_OUTPUT_PARENT'];
  test(
      'exact original Nurse survives normal composition writer and strict reopen',
      () async {
    final input =
        jsonDecode(await File('$archive/snapshot.json').readAsString())
            as Map<String, dynamic>;
    final snapshot = SourceSnapshot(
        logicalProjectNamespace:
            ConverterId(input['logicalProjectNamespace'] as String),
        policyHash: Sha256Hash(input['policyHash'] as String),
        entries: [
          for (final dynamic row in input['entries'])
            SourceFileEntry(
                fileId: ConverterId(row['fileId'] as String),
                relativePath: row['relativePath'] as String,
                kind: SourceNodeKind.values.byName(row['kind'] as String),
                byteLength: row['byteLength'] as int,
                sha256: row['sha256'] == null
                    ? null
                    : Sha256Hash(row['sha256'] as String),
                format: row['format'] as String,
                family: row['family'] as String)
        ],
        diagnostics: [],
        excludedPaths: (input['excludedPaths'] as List).cast<String>(),
        profileEvidence: [
          for (final dynamic row in input['profileEvidence'])
            SourceProfileEvidence(
                relativePath: row['relativePath'] as String,
                fileHash: Sha256Hash(row['fileHash'] as String),
                version: row['version'] as String,
                line: row['line'] as int,
                excerpt: row['excerpt'] as String)
        ],
        state: SourceScanState.values.byName(input['state'] as String));
    expect(snapshot.canonicalHash.value, input['canonicalHash']);
    const limits = NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048);
    final files = _OriginalFiles(sourceRoot!, snapshot);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot,
        files: files,
        selectedMapIds: {102},
        includeEventSystem: true);
    final parent =
        outputParent == null ? Directory.systemTemp : Directory(outputParent);
    expect(parent.isAbsolute, isTrue);
    expect(await parent.exists(), isTrue);
    final output = await parent.createTemp('original-center-nurse-');
    if (outputParent == null) addTearDown(() => output.delete(recursive: true));
    Future<LiteralTileComposition> composeLiteral(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: files,
            selectedSourceMapIds: [102],
            projectName: 'Original Kanto Center native nurse',
            parentPath: output.path,
            folderName: 'native-center',
            sourceRootPath: sourceRoot,
            allowFirstFrameAutotiles: true,
            dependencyDecisions: decisions,
            limits: limits);
    var literal = await composeLiteral(const []);
    final decisions = [
      for (final dependency in literal.dependencies)
        if (dependency.kind == LiteralDependencyKind.staticTransfer &&
            dependency.targetSourceMapId != null &&
            dependency.targetSourceMapId != 102)
          LiteralDependencyDecision(
              sourceSnapshotHash: snapshot.canonicalHash,
              selectionHash: literalSelectionHash(source, [102]),
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId!,
              decision: LiteralDependencyDisposition.excludeStudy)
    ];
    if (decisions.isNotEmpty) literal = await composeLiteral(decisions);
    expect(literal.draft, isNotNull,
        reason:
            '${literal.diagnostics.map((entry) => entry.toJson()).toList()}');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: literal, files: files, limits: limits))!;
    final composition = (await const SourceEventStudyComposer().compose(
        source: source, base: semantic, files: files, limits: limits))!;
    final evidence =
        (composition.projection.semanticEvidence['events'] as List).cast<Map>();
    final nurseEvidence =
        evidence.singleWhere((row) => (row['locator'] as Map)['eventId'] == 2);
    expect(nurseEvidence['status'], 'adaptedStaticSemantics',
        reason: '${nurseEvidence['gaps']}');
    expect(
        evidence.singleWhere(
            (row) => (row['locator'] as Map)['eventId'] == 4)['status'],
        'quarantinedWholeEvent');
    final approval = approveNativeFixtureDraft(composition.draft);
    final receipt = await const NativeProjectWriter().write(
        approval.plan, approval.context, composition.draft,
        limits: limits);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final loaded = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(loaded.loadDiagnostics, isEmpty);
      final map = loaded.mapById(composition.draft.mapIds[102]!)!;
      final nurse =
          map.entities.singleWhere((entity) => entity.name == 'Nurse');
      expect(nurse.pos, const GridPos(x: 9, y: 4));
      expect(nurse.npc!.counterInteractionSides, [EntityFacing.south]);
      final record = loaded.manifest.eventRegistry!.records.singleWhere(
          (record) =>
              record.definitionOrNull?.source.toJson()['entityId'] == nurse.id);
      final scene = loaded.manifest.scenes
          .singleWhere((scene) => scene.id == record.definitionOrNull!.sceneId);
      final commands = scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneInteractiveCommand>();
      expect(commands,
          [SceneInteractiveCommand.openHeal(requiresConfirmation: false)]);
      expect(
          scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneYarnDialoguePayload>()
              .expand((payload) => payload.linePolicies)
              .where((policy) => policy.feedback.audioCue != null),
          hasLength(1));
      final manifest = {
        'kind': 'originalKantoCenterNativeNurseFixture',
        'projectPath': receipt.projectPath,
        'projectFilePath': '${receipt.projectPath}/project.json',
        'nativeMapId': map.id,
        'nativeNurseId': nurse.id,
        'nativeSceneId': scene.id,
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'normalizationHash': source.canonicalHash.value,
        'sourceRootPath': sourceRoot,
        'sourceMapId': 102,
        'sourceEventId': 2,
        'nativePlayerStart': {'x': 9, 'y': 6, 'direction': 'north'},
        'nativeNurseSourceAnchor': {'x': 9, 'y': 4},
        'nativeCommand': 'openHeal',
        'requiresConfirmation': false,
        'nativeCheckpointTiming': 'afterAcceptedNativeHeal',
        'sourceCheckpointTiming': 'beforeSourceChoice',
        'sourceScriptsExecuted': 0,
        'fullSourceServiceParityQualified': false,
        'nativeWriterVerified': receipt.verified,
        'nativeWriteLimits': {'maxArtifacts': 512, 'maxMutations': 2048},
        'strictOpenDiagnostics': loaded.loadDiagnostics,
        'runtimePlayerServiceExecuted': false,
        'nativeDraftHash': composition.draft.canonicalHash.value,
        'nurseEvidence': nurseEvidence,
      };
      await File('${output.path}/fixture-manifest.json')
          .writeAsString(jsonEncode(manifest), flush: true);
      print('CENTER_NURSE_FIXTURE=${output.path}/fixture-manifest.json');
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  },
      skip: archive == null || sourceRoot == null || !Platform.isMacOS,
      timeout: const Timeout(Duration(minutes: 3)));
}
