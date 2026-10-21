import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_catalog_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_event_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  test(
      'automatic parcel composition retains all six masks and only four executable pages',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('oak-parcel-native-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final source = fixture.source, files = fixture.files;
    final limits =
        sourceCatalogStudyWriteLimitsFor(1, includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: files,
            selectedSourceMapIds: [9],
            projectName: 'Original Oak parcel',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (dependency.targetSourceMapId != 9)
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: base, files: files, limits: limits))!;
    final composition = (await const SourceEventStudyComposer().compose(
        source: source, base: semantic, files: files, limits: limits))!;
    final projection = composition.projection;
    final rows = (projection.semanticEvidence['events'] as List).cast<Map>();
    final owner = rows.singleWhere((row) =>
        row['locator']['mapId'] == 9 && row['locator']['eventId'] == 1);
    expect(owner['status'], 'partiallyAdapted', reason: '${owner['gaps']}');
    expect(owner['gaps'], isEmpty);
    expect(projection.staticSemanticsQualified, isFalse);
    expect(projection.semanticEvidence['partiallyAdaptedEventCount'], 1);
    expect(
        (projection.semanticEvidence['qualifiedEventCount'] as int) +
            (projection.semanticEvidence['partiallyAdaptedEventCount'] as int) +
            (projection.semanticEvidence['quarantinedEventCount'] as int),
        rows.length);
    final persistedEvidence = _readEvidence(projection.artifacts);
    expect(persistedEvidence['partiallyAdaptedEventCount'], 1);
    expect(persistedEvidence['qualifiedEventCount'],
        projection.semanticEvidence['qualifiedEventCount']);
    expect(persistedEvidence['quarantinedEventCount'],
        projection.semanticEvidence['quarantinedEventCount']);
    expect(persistedEvidence['events'], projection.semanticEvidence['events']);
    expect(owner['nativeOakParcel']['unsupportedPageIndices'], [4, 5]);
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final event = analysis.eventAt(9, 1)!;
    final map = projection.nativeMaps[9]!;
    final actor = map.entities.singleWhere((entity) =>
        entity.properties['sourceEventIdentity'] == event.identity.value);
    expect(actor.kind, MapEntityKind.npc);
    expect(actor.presentation!.variants, hasLength(6));
    final records = projection.registry.records
        .where((record) =>
            record.definitionOrNull?.source ==
            NarrativeEventSourceRef.entityInteract(map.id, actor.id))
        .toList();
    expect(records, hasLength(4));
    expect(records.every((record) => record.enabledOrNull == true), isTrue);
    for (final page in event.pages) {
      final id = 'page_${page.originalPageIndex}';
      expect(actor.presentation!.variants.any((variant) => variant.id == id),
          isTrue);
    }
    final factBindings = projection.semanticEvidence['factBindings'] as Map;
    for (final sourceFact in [
      event.pages[4].condition.children.single.factId!,
      event.pages[5].condition.children.single.factId!
    ]) {
      final nativeFact = factBindings[sourceFact] as String;
      expect(
          records.every((record) => record
              .definitionOrNull!.conditionExpression.leaves
              .any((leaf) => leaf.toJson().toString().contains(nativeFact))),
          isTrue);
    }
    final analyzer =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile);
    final beforeParcel = <String, NarrativeValue>{
      sourceEventIntegerVariableBindingId(analyzer.variableFactId(29)):
          NarrativeValue.integer(1),
      sourceEventFactBindingId(analyzer.selfFactId(9, 1, 'A')):
          NarrativeValue.boolean(true),
    };
    bool eligible(NarrativeEventRecord record,
            Map<String, NarrativeValue> overrides) =>
        evaluateNarrativeConditionExpression(
            record.definitionOrNull!.conditionExpression,
            evaluateLeaf: (condition) => condition.whenTyped(
                  fact: (id, operator, expected) =>
                      NarrativeConditionEvaluation(
                          passed: (overrides[id] ??
                                  projection.facts
                                      .singleWhere((fact) => fact.id == id)
                                      .initialValue)
                              .matches(operator, expected)),
                  narrativeEventConsumed: (eventId, expected) =>
                      const NarrativeConditionEvaluation(passed: false),
                )).passed;
    expect(records.where((record) => eligible(record, beforeParcel)),
        hasLength(1));
    for (final page in event.pages.skip(4)) {
      final sourceFact = page.condition.children.single.factId!;
      final overrides = {
        ...beforeParcel,
        sourceEventFactBindingId(sourceFact): NarrativeValue.boolean(true)
      };
      expect(records.any((record) => eligible(record, overrides)), isFalse,
          reason:
              'An unsupported higher source page must mask every executable lower page.');
    }
    for (final id in [12, 15]) {
      final propSource = analysis.eventAt(9, id)!;
      final prop = map.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] ==
          propSource.identity.value);
      expect(prop.pos, GridPos(x: propSource.x, y: propSource.y));
      expect(prop.size, const GridSize(width: 1, height: 1));
      expect(
          prop.presentation!.variants
              .firstWhere((v) => v.id == 'page_0')
              .characterId,
          startsWith('source-oak-tile-'));
      expect(
          prop.presentation!.variants
              .firstWhere((v) => v.id == 'page_0')
              .blocksMovement,
          isTrue);
      expect(
          prop.presentation!.variants
              .firstWhere((v) => v.id == 'page_1')
              .characterId,
          isNull);
    }
    final data = owner['nativeOakParcel'] as Map;
    for (final id in data['persistentSourceFacts'] as List) {
      final fact = projection.facts.singleWhere(
          (fact) => fact.id == sourceEventFactBindingId(id as String));
      expect(fact.initialValue.kind, NarrativeValueKind.boolean);
      expect(fact.initialValue.boolValue, isFalse);
    }
    final scenes = records
        .map((record) => projection.scenes.singleWhere(
            (scene) => scene.id == record.definitionOrNull!.sceneId))
        .toList();
    final commands = scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .toList();
    final ownerSceneIds =
        records.map((record) => record.definitionOrNull!.sceneId).toSet();
    final ownerRoutes = projection.scenes
        .where((scene) => ownerSceneIds.contains(scene.id))
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneActorRouteInteractiveCommand>()
        .toList();
    final rivalSource = analysis.eventAt(9, 25)!;
    final rivalEntity = map.entities.singleWhere((entity) =>
        entity.properties['sourceEventIdentity'] == rivalSource.identity.value);
    final rivalRoutes = ownerRoutes
        .where((route) => route.target.entityId == rivalEntity.id)
        .toList();
    expect(rivalRoutes, hasLength(17));
    for (final route in rivalRoutes) {
      expect(
          route.steps.first,
          isA<SceneActorThroughStep>()
              .having((step) => step.enabled, 'enabled', isTrue));
      expect(route.steps.whereType<SceneActorThroughStep>(), hasLength(1));
    }
    expect(
        ownerRoutes
            .where((route) => route.target.entityId != rivalEntity.id)
            .expand((route) => route.steps)
            .whereType<SceneActorThroughStep>(),
        isEmpty);
    expect(
        commands
            .where((payload) =>
                payload.interactiveCommand is SceneGiveItemInteractiveCommand)
            .map((payload) =>
                (payload.interactiveCommand as SceneGiveItemInteractiveCommand)
                    .quantity),
        [5, 5, 5, 5]);
    expect(
        commands
            .where((payload) => payload.consequence is SceneTakeItemConsequence)
            .map((payload) =>
                (payload.consequence as SceneTakeItemConsequence).quantity),
        [1, 1, 1, 1]);
    expect(projection.dialogueSources.values.join('\n'),
        contains('You obtained 5'));
    final compositionExport =
        Platform.environment['AVELUNE_OAK_COMPOSITION_EXPORT'];
    if (compositionExport != null) {
      await _exportComposition(compositionExport, projection, composition.draft,
          strictVerified: false);
    }
    if (Platform.environment['AVELUNE_OAK_STRICT_WRITE'] == 'true') {
      final catalog = await SourceCatalogStudyComposer(
              nativeTrainerCatalog: composition.pokemonGiftCatalog)
          .compose(
              source: source,
              base: composition.draft,
              files: files,
              limits: limits);
      final draft = catalog?.draft ?? composition.draft;
      final approval = approveNativeFixtureDraft(draft);
      NativePreparationStage? previousStage;
      final receipt =
          await NativeProjectWriter(preparationCheckpoint: (stage, progress) {
        if (stage == previousStage) return;
        previousStage = stage;
        stdout.writeln('Oak strict writer: ${stage.name}');
      }).write(approval.plan, approval.context, draft, limits: limits);
      expect(receipt.verified, isTrue);
      final output = Platform.environment['AVELUNE_OAK_NATIVE_QA_OUTPUT'];
      if (output != null) {
        expect(await Directory(output).exists(), isFalse);
        await Directory(receipt.projectPath).rename(output);
        await _exportComposition(output, projection, draft,
            strictVerified: receipt.verified);
      }
    }
  },
      skip: enabled
          ? false
          : 'Requires the attested external source and interpretation profile.',
      timeout: const Timeout(Duration(minutes: 10)));
}

Map<String, dynamic> _readEvidence(List<NativeArtifact> artifacts) {
  final root =
      jsonDecode(utf8.decode(artifacts.first.bytes)) as Map<String, dynamic>;
  if (root['kind'] != 'sourceEventProjectionChunks') return root;
  final bytes = <int>[];
  for (final descriptor in root['chunks'] as List) {
    final artifact = artifacts.singleWhere(
        (artifact) => artifact.handle == descriptor['artifactHandle']);
    final chunk = jsonDecode(utf8.decode(artifact.bytes)) as Map;
    expect(chunk['offset'], bytes.length);
    bytes.addAll(base64Decode(chunk['bytesBase64'] as String));
  }
  expect(crypto.sha256.convert(bytes).toString(), root['sha256']);
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

Future<void> _exportComposition(
    String output, SourceEventProjection projection, NativeProjectDraft draft,
    {required bool strictVerified}) async {
  final artifactRoot =
      await Directory('$output.artifacts').create(recursive: true);
  final artifacts = <Map<String, Object?>>[];
  for (final artifact in draft.artifacts) {
    final file = File('${artifactRoot.path}/${artifact.rawSha256.value}');
    await file.writeAsBytes(artifact.bytes);
    artifacts.add({
      'handle': artifact.handle,
      'path': file.path,
      'sha256': artifact.rawSha256.value,
      'reference': artifact.reference.toJson()
    });
  }
  await File('$output.bundle.json').writeAsString(jsonEncode({
    'kind': 'boundedAutomaticOakParcelComposition',
    'mutationScope': strictVerified
        ? 'completeStrictDraftIncludingCatalog'
        : 'eventsOnlyAutomaticComposition',
    'sourceSnapshotHash': draft.source.snapshot.canonicalHash.value,
    'maps': {
      for (final entry in projection.nativeMaps.entries)
        '${entry.key}': entry.value.toJson()
    },
    'projection': projection.semanticEvidence,
    'scenes': projection.scenes.map((scene) => scene.toJson()).toList(),
    'cinematics':
        projection.cinematics.map((cinematic) => cinematic.toJson()).toList(),
    'facts': projection.facts.map((fact) => fact.toJson()).toList(),
    'registry': projection.registry.toJson(),
    'dialogues':
        projection.dialogues.map((dialogue) => dialogue.toJson()).toList(),
    'dialogueSources': projection.dialogueSources,
    'mutations': [
      for (final (i, mutation) in draft.mutations.indexed) mutation.toJson(i)
    ],
    'artifacts': artifacts,
    'strictNativeWriterVerified': strictVerified,
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
    'runtimeJourneyVerified': false,
  }));
}
