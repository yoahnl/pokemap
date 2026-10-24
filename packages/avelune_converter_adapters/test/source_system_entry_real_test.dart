import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';
import 'support/source_external_original_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_SYSTEM_START_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_SYSTEM_START_SNAPSHOT'];
  test(
      'automatic System start survives strict writer and the native new game factory',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('source-system-entry-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {134});
    final source = fixture.source;
    final sourceBefore = source.canonicalHash;
    final start = sourceSystemStart(source)!;
    expect([start.sourceMapId, start.x, start.y], [134, 43, 13]);
    final limits = sourceCatalogStudyWriteLimitsFor(1);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: [start.sourceMapId],
            projectName: 'Original source start',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final d in probe.dependencies)
        if (d.targetSourceMapId != start.sourceMapId)
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: d.locator,
              targetSourceMapId: d.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: source, base: base, files: fixture.files, limits: limits))!;
    final events = (await const SourceEventStudyComposer().compose(
        source: source, base: semantic, files: fixture.files, limits: limits))!;
    final diagnosticsPath=Platform.environment['AVELUNE_SYSTEM_START_EVIDENCE'];
    if(diagnosticsPath!=null) { await File('$diagnosticsPath.projection.json').writeAsString(jsonEncode(events.projection.semanticEvidence)); }
    final oracle=SourceSemanticResolver.forProject(source);
    final native=events.projection.nativeMaps[start.sourceMapId]!;
    expect(events.freshEntry,isNotNull,reason:jsonEncode({
      'evidence':{for(final k in ['sourceSnapshotHash','normalizationHash','sourceProfileHash']) k:events.projection.semanticEvidence[k]},
      'profile':SourceEventProfile.forProject(source).canonicalHash.value,
      'qualifiedEvents':sourceSystemEntryEventsQualified(source,events.projection,start.sourceMapId),
      'passage':oracle.resolveConnectionEntryTile(oracle.cellAt(start.sourceMapId,start.x,start.y)).status.name,
      'automatic':[for(final e in SourceEventAnalyzer.forProject(source,profile:SourceEventProfile.forProject(source)).analyze().events)
        if(e.pages.any((p)=>const{3,4}.contains(p.triggerCode))) {
          'id':e.sourceEventId,'pages':[for(final p in e.pages) {'index':p.originalPageIndex,'trigger':p.triggerCode,
            'active':p.condition.evaluate(),'condition':p.condition.toJson(),'empty':p.isEmpty}]}],
      'collisionLayers':[for(final l in native.layers.whereType<CollisionLayer>()) l.collisions[start.y*native.size.width+start.x]],
      'blocking':[for(final e in native.entities) if(e.blocksMovement && resolveEntityCollisionCells(e).contains(GridPos(x:start.x,y:start.y))) e.toJson()],
    }));
    final binding = events.freshEntry!;
    expect(binding, isA<SourceSystemEntryBinding>());
    expect(binding.config.initialParty, isEmpty);
    expect(binding.config.starterOptions, isEmpty);
    expect(binding.config.initialBag, isEmpty);
    expect(binding.config.preSessionSceneId, isNull);
    expect(binding.config.initialRecoveryPoint, isNull);
    expect(binding.defeatRecovery, isNull);
    expect(binding.scenes, isEmpty);
    expect(binding.config.playerName, 'Unnamed');
    expect(binding.config.startingMoney, 3000);
    expect(binding.imports.map((a) => a.selectedHeaderId), [1]);
    expect(binding.imports.map((a) => a.selectedOutfit), [0]);
    final beforeMap = events.projection.nativeMaps[start.sourceMapId]!;
    final startMap = binding.nativeMaps[start.sourceMapId]!;
    expect(startMap.layers, beforeMap.layers);
    expect(startMap.entities.where((e) => e.id != binding.config.startSpawnId),
        beforeMap.entities);
    expect(binding.evidence['sourceScriptsExecuted'], 0);
    expect(binding.evidence['aiCalls'], 0);
    final approval = approveNativeFixtureDraft(events.draft);
    final receipt = await const NativeProjectWriter()
        .write(approval.plan, approval.context, events.draft, limits: limits);
    expect(receipt.verified, isTrue);
    final project = ProjectManifest.fromJson(jsonDecode(
            await File('${receipt.projectPath}/project.json').readAsString())
        as Map<String, dynamic>);
    final mapEntry =
        project.maps.singleWhere((m) => m.id == project.newGame.startMapId);
    final persistedMap = MapData.fromJson(jsonDecode(
        await File('${receipt.projectPath}/${mapEntry.relativePath}')
            .readAsString()) as Map<String, dynamic>);
    final game = createNewGameStateFromProject(
        project: project, startMap: persistedMap, saveId: 'source-start');
    expect(game.currentMapId, startMap.id);
    expect(game.playerPosition, const GridPos(x: 43, y: 13));
    expect(game.playerFacing, EntityFacing.south);
    expect(game.party.members, isEmpty);
    expect(game.bag.entries, isEmpty);
    expect(PlayerRecoveryPoint.tryRead(game), isNull);
    expect(source.canonicalHash, sourceBefore);
    final out = Platform.environment['AVELUNE_SYSTEM_START_EVIDENCE'];
    if (out != null) {
      await File(out).writeAsString(jsonEncode({
        'binding': binding.evidence,
        'newGame': project.newGame.toJson(),
        'map': persistedMap.toJson(),
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'writerVerified': receipt.verified,
        'projectPath': receipt.projectPath,
        'game': game.toJson()
      }));
    }
  },
      skip: root == null ||
          snapshot == null ||
          Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] == null,
      timeout: const Timeout(Duration(minutes: 4)));
}
