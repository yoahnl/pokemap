import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_inventory_controller_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'source_inventory_controller_test.dart'
    show createInventoryControllerInput;
import 'support/native_writer_fixture.dart';

void main() {
  test('STD-EV-07 exports an owned parallel process and a local key donor',
      () async {
    final requested =
        Platform.environment['AVELUNE_STD07_PARALLEL_FIXTURE_ROOT'];
    final output = requested == null
        ? await Directory.systemTemp.createTemp('std07-converted-parallel-')
        : await Directory(requested).create(recursive: true);
    if (requested == null) {
      addTearDown(() => output.delete(recursive: true));
    }
    final input = await createInventoryControllerInput(
        localWriter: 'give', playerFixture: true);
    final controller = input.analysis.eventAt(58, 16)!;
    final donor = input.analysis.eventAt(58, 20)!;
    expect(controller.isQuarantined, isFalse);
    expect(donor.isQuarantined, isFalse);
    expect(donor.pages.first.body.nodes.single, isA<SourcePickupNode>());
    final limits =
        sourceCatalogStudyWriteLimitsFor(2, includeNativeCatalog: true);
    final pbs = await const SourcePbsParser()
        .read(snapshot: input.source.snapshot, files: input.files);
    final nativeReference = await NativeEncounterCatalogQualification.prepare(
        snapshot: input.source.snapshot,
        source: pbs,
        files: input.files,
        nativeCatalog: NativePsdkTrainerBundle.builtin(),
        selectedSourceMapIds: [58, 200]);
    expect(nativeReference.sourceMappings, isEmpty);
    expect(nativeReference.wildCases, isEmpty);
    final gift = input.analysis.eventAt(200, 2)!;
    expect(gift.isQuarantined, isFalse);
    expect(gift.pages.first.body.nodes.whereType<SourcePokemonGiftNode>(),
        hasLength(1));
    final gifts = await const SourcePokemonGiftBindingResolver().read(
        source: input.source,
        analysis: input.analysis,
        files: input.files,
        nativeCatalog: nativeReference.bundle);
    expect(gifts.refusals, isEmpty);
    final giftBinding = gifts.byEventIdentity[gift.identity.value]!;
    expect(giftBinding.nativeSpeciesId, 'arbok');
    expect(
        giftBinding.isBoundToEvent(
            source: input.source, analysis: input.analysis, event: gift),
        isTrue);
    final literal = await const LiteralTileComposer().compose(
        source: input.source,
        files: input.files,
        selectedSourceMapIds: [58, 200],
        projectName: 'STD07 converted parallel Player fixture',
        parentPath: output.path,
        folderName: 'converted-parallel',
        limits: limits);
    expect(literal.draft, isNotNull,
        reason:
            '${literal.diagnostics.map((value) => value.toJson()).toList()}');
    final semantic = await const SourceSemanticStudyComposer(
            includeNativeSurfTraversal: true)
        .compose(
            source: input.source,
            base: literal,
            files: input.files,
            limits: limits);
    expect(semantic, isNotNull);
    final events = await SourceEventStudyComposer(
            nativeEncounterQualification: nativeReference)
        .compose(
            source: input.source,
            base: semantic!,
            files: input.files,
            limits: limits);
    expect(events, isNotNull);
    expect(
        (events!.draft.compositionEvidence['sourceEvents']
            as Map)['nativeCatalogHash'],
        canonicalHashOf(nativeReference.bundle.toJson(),
                limits: nativePsdkCatalogShardJsonLimits)
            .value);
    final rows =
        (events.projection.semanticEvidence['events'] as List).cast<Map>();
    for (final sourceEvent in [controller, donor, gift]) {
      final row = rows.singleWhere(
          (value) => value['sourceIdentity'] == sourceEvent.identity.value);
      expect(row['status'], 'adaptedStaticSemantics', reason: '$row');
    }
    final catalogs = await SourceCatalogStudyComposer(
            nativeEncounterQualification: nativeReference)
        .compose(
            source: input.source,
            base: events.draft,
            files: input.files,
            limits: limits);
    expect(catalogs, isNotNull);
    expect(catalogs!.projection.encounterTables, isEmpty);
    expect(catalogs.projection.trainers, isEmpty);
    expect(
        catalogs.projection.documents.map((document) => document.relativePath),
        containsAll([
          for (final family in ['species', 'learnsets', 'evolutions', 'media'])
            'data/pokemon/$family/arbok.json',
        ]));
    final draft = catalogs.draft;
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft, limits: limits);
    expect(receipt.verified, isTrue);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final loaded = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(loaded.loadDiagnostics, isEmpty);
      final mapId = events.draft.mapIds[58]!;
      final map = loaded.mapById(mapId)!;
      final owner = map.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] ==
          controller.identity.value);
      final nativeDonor = map.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] == donor.identity.value);
      final definitions = loaded.manifest.eventRegistry!.records
          .map((record) => record.definitionOrNull)
          .whereType<NarrativeEventDefinition>()
          .toList();
      final parallel = definitions.singleWhere((definition) =>
          definition.source.toJson()['entityId'] == owner.id &&
          definition.toJson()['parallelPolicy'] != null);
      final donation = definitions.singleWhere((definition) =>
          definition.source.toJson()['entityId'] == nativeDonor.id &&
          definition.source.kind == NarrativeEventSourceKind.entityInteract);
      expect(parallel.source.kind, NarrativeEventSourceKind.entityAutorun);
      final parallelPolicy = parallel.toJson()['parallelPolicy'] as Map;
      expect(parallelPolicy['cadenceMs'], 100);
      expect(parallelPolicy['ownerVariantId'], 'page_0');
      final programs = sourceInventoryControllerPrograms(
          source: input.source, analysis: input.analysis);
      final program = programs[controller.identity]!;
      final ownFactId = sourceEventFactBindingId(program.guardFactId);
      final foreignFactId =
          sourceEventFactBindingId(program.foreignTargetFactId);
      final keyItemId = input.items['SECRETKEY']!.definition.id;
      expect(loaded.itemCatalog!.entries.map((item) => item.id),
          contains(keyItemId));
      for (final factId in [ownFactId, foreignFactId]) {
        final fact =
            loaded.manifest.facts.singleWhere((value) => value.id == factId);
        expect(fact.defaultValue, isFalse);
      }
      final reference = {
        'kind': 'std07ConvertedParallelFixture',
        'projectFilePath': '${receipt.projectPath}/project.json',
        'startMapId': mapId,
        'otherMapId': events.draft.mapIds[200],
        'spawn': {'x': 4, 'y': 3},
        'donorAnchor': {'x': nativeDonor.pos.x, 'y': nativeDonor.pos.y},
        'donorEntityId': nativeDonor.id,
        'donorEventId': donation.id,
        'donorSceneId': donation.sceneId,
        'ownerEntityId': owner.id,
        'ownerAnchor': {'x': owner.pos.x, 'y': owner.pos.y},
        'parallelEventId': parallel.id,
        'parallelSceneId': parallel.sceneId,
        'ownerVariantId': parallelPolicy['ownerVariantId'],
        'cadenceMs': parallelPolicy['cadenceMs'],
        'itemId': keyItemId,
        'ownGuardFactId': ownFactId,
        'foreignTargetFactId': foreignFactId,
        'sourceMaps': [58, 200],
        'sourceControllerEvent': 16,
        'sourceDonorEvent': 20,
        'sourceSnapshotHash': input.source.snapshot.canonicalHash.value,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'nativeWriterVerified': receipt.verified,
        'strictReopenVerified': true,
        'sourceTemporalParity': false,
        'fixtureCatalogSource': 'canonicalNativeReferenceComposition',
        'fixtureEncounterCount': catalogs.projection.encounterTables.length,
        'fixtureTrainerCount': catalogs.projection.trainers.length,
        'fixtureCatalogSpecies': ['arbok'],
        'fixtureCatalogGiftSourceMap': 200,
        'fixtureCatalogGiftSourceEvent': 2,
      };
      if (requested != null) {
        await File('${output.path}/reference.json').writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(reference)}\n');
      }
      stdout.writeln(jsonEncode(reference));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
