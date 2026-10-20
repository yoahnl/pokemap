import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshotPath = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profilePath = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final projectParent =
      Platform.environment['AVELUNE_PROGRESSION_BLOCKERS_PROJECT_PARENT'];
  final supplementalRoots =
      (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((path) => path.isNotEmpty)
          .toList();
  test('bounded Kanto source composition admits Card Key and gate transfers',
      () async {
    final elapsed = Stopwatch()..start();
    void progress(String stage) => stdout.writeln(jsonEncode({
          'stage': stage,
          'elapsedMs': elapsed.elapsedMilliseconds,
        }));
    final sourceRoot = root!;
    final sourceSnapshotPath = snapshotPath!;
    final oracleProfilePath = profilePath!;
    for (final path in [sourceRoot, sourceSnapshotPath, oracleProfilePath]) {
      expect(File(path).isAbsolute, isTrue);
    }
    final baselinePath = Platform
            .environment['AVELUNE_PROGRESSION_BLOCKERS_BASELINE'] ??
        '${File(sourceSnapshotPath).parent.path}/source-event-qualification.json';
    expect(File(baselinePath).isAbsolute, isTrue);
    final baseline = jsonDecode(await File(baselinePath).readAsString()) as Map;
    const selectedMapIds = {21, 24, 46, 49, 220};
    const locations = [(21, 6), (46, 26), (220, 38)];
    progress('readSelectedSourceMaps');
    final fixture = await readExternalOriginalSource(
        sourceRoot, sourceSnapshotPath,
        selectedMapIds: selectedMapIds, supplementalRoots: supplementalRoots);
    final source = fixture.source;
    expect(source.selectedSourceMapIds.toSet(), selectedMapIds);
    expect(baseline['sourceSnapshotHash'], source.snapshot.canonicalHash.value);
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final cardKey = analysis.eventAt(220, 38)!;
    expect(cardKey.pages.first.graphic!.characterName, 'OBJ_FRLG_Silph Gate_V');
    expect(cardKey.pages.first.graphic!.directionFix, isFalse);
    expect(cardKey.pages.first.graphic!.walkAnime, isTrue);
    expect(cardKey.pages.first.sourcePage.commands.first.parameters,
        [12, r'$bag.quantity(:CARDKEY)>0']);
    final temporary =
        await Directory.systemTemp.createTemp('progression-real-five-maps-');
    addTearDown(() => temporary.delete(recursive: true));
    var outputParent = temporary.path;
    if (projectParent != null) {
      expect(path.isAbsolute(projectParent), isTrue);
      expect(await Directory(projectParent).exists(), isFalse,
          reason: 'The explicit qualification parent must be unused.');
      final existingParent =
          await Directory(path.dirname(projectParent)).resolveSymbolicLinks();
      final canonicalOutput =
          path.join(existingParent, path.basename(projectParent));
      final canonicalSource =
          await Directory(sourceRoot).resolveSymbolicLinks();
      expect(path.equals(canonicalSource, canonicalOutput), isFalse);
      expect(path.isWithin(canonicalSource, canonicalOutput), isFalse,
          reason: 'Qualification must not create anything in the source.');
      await Directory(canonicalOutput).create();
      outputParent = canonicalOutput;
    }
    final cancellation = ScanCancellation();
    final deadline = Timer(
        Duration(minutes: projectParent == null ? 4 : 9), cancellation.cancel);
    addTearDown(() {
      deadline.cancel();
      cancellation.cancel();
    });
    final limits = sourceCatalogStudyWriteLimitsFor(selectedMapIds.length,
        includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: selectedMapIds.toList(),
            projectName: 'Kanto progression source qualification',
            parentPath: outputParent,
            folderName: 'bounded',
            dependencyDecisions: decisions,
            limits: limits,
            cancellation: cancellation);
    progress('literalSelectedMaps');
    final probe = await literal([]);
    final composed = await literal([
      for (final dependency in probe.dependencies)
        if (!selectedMapIds.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy),
    ]);
    expect(composed.draft, isNotNull,
        reason: jsonEncode(
            composed.diagnostics.map((value) => value.toJson()).toList()));
    progress('nativeCatalogQualification');
    final encounters = projectParent == null
        ? null
        : await NativeEncounterCatalogQualification.prepareAutomatic(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: source.selectedSourceMapIds);
    progress('semanticSelectedMaps');
    final semantic = await SourceSemanticStudyComposer(
            includeNativeSurfTraversal: encounters != null)
        .compose(
            source: source,
            base: composed,
            files: fixture.files,
            limits: limits,
            cancellation: cancellation);
    expect(semantic, isNotNull);
    progress('eventSelectedMaps');
    final events =
        await SourceEventStudyComposer(nativeEncounterQualification: encounters)
            .compose(
                source: source,
                base: semantic!,
                files: fixture.files,
                limits: limits,
                cancellation: cancellation);
    expect(events, isNotNull);
    final projection = events!.projection;
    final sceneExportPath = Platform.environment['AVELUNE_PROGRESSION_BLOCKERS_SCENE_EXPORT'];
    if (sceneExportPath != null) {
      expect(File(sceneExportPath).isAbsolute, isTrue);
      final identities = {for (final location in [(21, 6), (46, 26)])
        analysis.eventAt(location.$1, location.$2)!.identity.value};
      final scenes = projection.scenes.where((scene) =>
          identities.contains(scene.metadata['sourceEventIdentity'])).toList();
      expect(scenes, hasLength(2));
      await File(sceneExportPath).writeAsString(jsonEncode({
        'kind': 'targetedPostTransferSceneQualification',
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'sourceProfileHash': analysis.profile.canonicalHash.value,
        'wholeKantoRegenerated': false,
        'scenes': scenes.map((scene) => scene.toJson()).toList(),
      }));
    }
    expect(projection.nativeMaps.keys.toSet(), selectedMapIds);
    final rows = (projection.semanticEvidence['events'] as List).cast<Map>();
    final baselineRows = (baseline['events'] as List).cast<Map>();
    final changes = [
      for (final location in locations)
        {
          'sourceMapId': location.$1,
          'sourceEventId': location.$2,
          'before': baselineRows.singleWhere((row) =>
              row['locator']['mapId'] == location.$1 &&
              row['locator']['eventId'] == location.$2),
          'after': rows.singleWhere((row) =>
              row['locator']['mapId'] == location.$1 &&
              row['locator']['eventId'] == location.$2),
        }
    ];
    final unchangedSourceMaps = <String, String>{};
    for (final id in selectedMapIds) {
      final path = 'Data/Map${id.toString().padLeft(3, '0')}.rxdata';
      final entry = source.snapshot.entries
          .singleWhere((entry) => entry.relativePath == path);
      final hash = crypto.sha256
          .convert(await fixture.files.read(entry.fileId))
          .toString();
      expect(hash, entry.sha256!.value, reason: path);
      unchangedSourceMaps[path] = hash;
    }
    final receiptPath =
        Platform.environment['AVELUNE_PROGRESSION_BLOCKERS_RECEIPT'];
    final qualificationReceipt = <String, Object?>{
      'kind': 'boundedKantoProgressionSourceComposition',
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'sourceProfileHash': analysis.profile.canonicalHash.value,
      'normalizationHash': source.canonicalHash.value,
      'selectedSourceMapIds': selectedMapIds.toList(),
      'baselineQualificationPath': baselinePath,
      'eventChanges': changes,
      'characterBindings': projection.semanticEvidence['characterBindings'],
      'selectedSourceMapHashesUnchanged': unchangedSourceMaps,
      'elapsedMs': elapsed.elapsedMilliseconds,
      'wholeKantoRegenerated': false,
      'nativeProjectWritten': false,
      'sourceScriptsExecuted': 0,
      'combatRulesModified': false,
      'fullCampaignCertified': false,
    };
    Future<void> recordReceipt() async {
      if (receiptPath == null) return;
      expect(File(receiptPath).isAbsolute, isTrue);
      await File(receiptPath).writeAsString(jsonEncode(qualificationReceipt));
    }

    await recordReceipt();
    for (final change in changes) {
      final before = change['before'] as Map, after = change['after'] as Map;
      final label = '${change['sourceMapId']}/${change['sourceEventId']}';
      expect(before['status'], 'quarantinedWholeEvent', reason: label);
      expect(after['status'], 'adaptedStaticSemantics',
          reason: '$label: ${after['gaps']}');
      expect(after['gaps'], isEmpty, reason: label);
    }
    final gate = projection.nativeMaps[220]!.entities.singleWhere((entity) =>
        entity.properties['sourceEventIdentity'] == cardKey.identity.value);
    expect(gate.pos, GridPos(x: cardKey.x, y: cardKey.y - 1));
    expect(gate.size, const GridSize(width: 2, height: 2));
    expect(resolveEntityCollisionCells(gate), hasLength(4));
    expect(gate.presentation!.variants, hasLength(2));
    expect(gate.presentation!.variants.first.blocksMovement, isFalse);
    expect(gate.presentation!.variants.last.blocksMovement, isTrue);
    if (projectParent != null) {
      expect(receiptPath, isNotNull,
          reason: 'A retained qualification project requires its receipt.');
      progress('catalogSelectedMaps');
      final catalogs = await SourceCatalogStudyComposer(
              nativeEncounterQualification: encounters,
              nativeTrainerQualification: events.trainerQualification,
              nativeTrainerCatalog: events.pokemonGiftCatalog,
              includeNativeEncounterConsumers: encounters != null)
          .compose(
              source: source,
              base: events.draft,
              files: fixture.files,
              limits: limits,
              cancellation: cancellation);
      expect(catalogs, isNotNull);
      final draft = catalogs!.draft;
      final approval = approveNativeFixtureDraft(draft);
      progress('writeSelectedMaps');
      final receipt = await NativeProjectWriter(
        preparationCheckpoint: (stage, status) =>
            progress('prepare.${stage.name}.${status.done}'),
        checkpoint: (stage, _, __) => progress('write.${stage.name}'),
      ).write(approval.plan, approval.context, draft,
          limits: limits, cancellation: cancellation);
      expect(receipt.verified, isTrue);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      progress('strictReopenSelectedMaps');
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final loaded = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(loaded.loadDiagnostics, isEmpty);
        expect(loaded.manifest.maps, hasLength(selectedMapIds.length));
        final reloadedGate = loaded.maps
            .singleWhere((map) => map.id == projection.nativeMaps[220]!.id)
            .entities
            .singleWhere((entity) => entity.id == gate.id);
        expect(reloadedGate.pos, gate.pos);
        expect(resolveEntityCollisionCells(reloadedGate), hasLength(4));
        expect(reloadedGate.presentation!.variants, hasLength(2));
        for (final before in unchangedSourceMaps.entries) {
          final entry = source.snapshot.entries
              .singleWhere((entry) => entry.relativePath == before.key);
          final after = crypto.sha256
              .convert(await fixture.files.read(entry.fileId))
              .toString();
          expect(after, before.value, reason: before.key);
        }
        qualificationReceipt.addAll({
          'nativeProjectWritten': true,
          'nativeWriteVerified': receipt.verified,
          'sourceMapsVerifiedAfterWrite': true,
          'strictReopenCertified': true,
          'strictReopenDiagnostics': loaded.loadDiagnostics.length,
          'mapCount': loaded.manifest.maps.length,
          'projectPath': receipt.projectPath,
          'approvalContext': 'controlledQualificationFixtureOnly',
          'playerTraversalCertified': false,
          'elapsedMs': elapsed.elapsedMilliseconds,
        });
        await recordReceipt();
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    }
    progress('complete');
  },
      timeout: Timeout(Duration(minutes: projectParent == null ? 5 : 10)),
      skip: root == null || snapshotPath == null || profilePath == null
          ? 'Requires explicit external source, snapshot and oracle profile paths.'
          : false);
}
