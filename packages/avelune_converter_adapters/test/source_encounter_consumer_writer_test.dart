import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_encounter_catalog_bindings.dart';
import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:avelune_converter_adapters/src/source_catalog_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_event_study_composer.dart';
import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/native_media_source_fixture.dart';

List<int> _symbol(String text) => [58, text.length + 5, ...utf8.encode(text)];
List<int> _compiled(String symbol, {String? name}) => [
      4,
      8,
      123,
      6,
      ..._symbol(symbol),
      111,
      ..._symbol('GameData::Species'),
      name == null ? 8 : 9,
      ..._symbol('@id'),
      ..._symbol(symbol),
      ..._symbol('@species'),
      ..._symbol(symbol),
      ..._symbol('@form'),
      105,
      0,
      if (name != null) ...[
        ..._symbol('@real_name'),
        34,
        name.length + 5,
        ...utf8.encode(name)
      ],
    ];

Future<({LiteralTileFixture fixture, SourcePbsProject pbs})> _source({
  String symbol = 'RATTATA',
  String methods = 'Land,11\n100,RATTATA,14,17\n100,RATTATA,14,17\n',
  Map<String, List<int>> extraFiles = const {},
  List<int>? scriptsBytes,
  String? nativeName,
}) async {
  final fixture = await LiteralTileFixture.create(
      maps: [
        LiteralFixtureMap(id: 98, width: 3, height: 2, layers: [
          [384, 386, 386, 384, 386, 386],
          List.filled(6, 0),
          List.filled(6, 0)
        ])
      ],
      tilesets: [
        LiteralFixtureTileset(id: 1, passages: {386: 15}, terrainTags: {386: 7})
      ],
      scriptsBytes: scriptsBytes,
      includeEventSystem: scriptsBytes != null,
      extraFiles: {
        'PBS/pokemon.txt': utf8
            .encode('[$symbol]\nName = ${nativeName ?? 'Source species'}\n'),
        'PBS/encounters.txt': utf8.encode('[098]\n$methods'),
        'Data/species.dat': _compiled(symbol, name: nativeName),
        ...extraFiles,
      });
  final pbs = await const SourcePbsParser()
      .read(snapshot: fixture.snapshot, files: fixture.files);
  return (fixture: fixture, pbs: pbs);
}

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  test(
      'automatic world release restores with caller limits and rejects corrupted release before staging',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('world-release-writer-');
    addTearDown(() => temporary.delete(recursive: true));
    final catalog = NativePsdkCatalogManifest.builtin();
    final source = await _source(
        nativeName: 'Rattata',
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        methods: 'Water,2\n100,RATTATA,14\n',
        extraFiles: {
          ...nativeMediaSourceFiles(catalog),
          'Data/items.dat': await File.fromUri(
                  File(scriptsPath).parent.uri.resolve('items.dat'))
              .readAsBytes(),
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 128, numChannels: 4)),
        });
    final limits = sourceCatalogStudyWriteLimitsFor(9);
    final qualification =
        (await NativeEncounterCatalogQualification.prepareAutomatic(
            source: source.fixture.source,
            files: source.fixture.files,
            selectedSourceMapIds: [98]))!;
    final release = qualification.artifacts(limits: limits);
    expect(release.artifacts.length,
        greaterThan(const NativeWriteLimits().maxArtifacts));
    final literal = await const LiteralTileComposer().compose(
        source: source.fixture.source,
        files: source.fixture.files,
        selectedSourceMapIds: [98],
        projectName: 'World release',
        parentPath: temporary.path,
        folderName: 'native',
        limits: limits);
    final semantic = await const SourceSemanticStudyComposer(
            includeNativeSurfTraversal: true)
        .compose(
            source: source.fixture.source,
            base: literal,
            files: source.fixture.files,
            limits: limits);
    final events = await SourceEventStudyComposer(
            nativeEncounterQualification: qualification)
        .compose(
            source: source.fixture.source,
            base: semantic!,
            files: source.fixture.files,
            limits: limits);
    final composition = (await const SourceCatalogStudyComposer(
            includeNativeEncounterConsumers: true)
        .compose(
            source: source.fixture.source,
            base: events!.draft,
            files: source.fixture.files,
            limits: limits))!;
    final draft = composition.draft;
    expect(
        (draft.compositionEvidence['sourceCatalogs']
            as Map)['nativeEncounterRelease'],
        release.evidence);
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await const NativeProjectWriter()
        .write(approval.plan, approval.context, draft, limits: limits);
    expect(receipt.verified, isTrue);
    for (final corruption in ['hash', 'policy']) {
      final changed = jsonDecode(jsonEncode(draft.compositionEvidence))
          as Map<String, dynamic>;
      if (corruption == 'hash') {
        final descriptor = ((changed['sourceCatalogs']['nativeEncounterRelease']
                ['files']) as List)
            .first as Map;
        descriptor['sha256'] = '0' * 64;
      } else {
        changed['sourceCatalogs']['automaticNativeEncounters'] = false;
      }
      final forged = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: 'corrupted-$corruption',
          sourceRootPath: draft.sourceRootPath,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          mutations: draft.mutations,
          compositionEvidence: changed,
          limits: limits);
      final forgedApproval = approveNativeFixtureDraft(forged);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(forgedApproval.plan, forgedApproval.context, forged,
                  limits: limits),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.semantics.regeneration')));
      expect(stages, isEmpty);
      expect(
          await Directory('${temporary.path}/corrupted-$corruption').exists(),
          isFalse);
    }
    expect(
        (await temporary.list().toList())
            .where((entry) => entry.path.contains('staging')),
        isEmpty);
  }, skip: scriptsPath == null, timeout: const Timeout(Duration(minutes: 6)));
  final qualification = NativeEncounterCatalogQualification.builtinKantoV1();
  Map<String, List<int>> nativeMedia() =>
      nativeMediaSourceFiles(qualification.bundle);

  test(
      'Surf encounter consumers publish through typed actions and refuse removed terrain before staging',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('native-encounters-');
    addTearDown(() => temporary.delete(recursive: true));
    final source = await _source(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        methods: 'Water,2\n100,RATTATA,14\n',
        extraFiles: {
          ...nativeMedia(),
          'Data/items.dat': await File.fromUri(
                  File(scriptsPath).parent.uri.resolve('items.dat'))
              .readAsBytes(),
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 128, numChannels: 4)),
        });
    final limits =
        sourceCatalogStudyWriteLimitsFor(1, includeNativeCatalog: true);
    final literal = await const LiteralTileComposer().compose(
        source: source.fixture.source,
        files: source.fixture.files,
        selectedSourceMapIds: [98],
        projectName: 'Qualified native encounters',
        parentPath: temporary.path,
        folderName: 'native',
        limits: limits);
    final semantic = await const SourceSemanticStudyComposer(
            includeNativeSurfTraversal: true)
        .compose(
            source: source.fixture.source,
            base: literal,
            files: source.fixture.files,
            limits: limits);
    expect(semantic, isNotNull);
    final events = await SourceEventStudyComposer(
            nativeEncounterQualification: qualification)
        .compose(
            source: source.fixture.source,
            base: semantic!,
            files: source.fixture.files,
            limits: limits);
    expect(events, isNotNull);
    final composer = SourceCatalogStudyComposer(
        nativeEncounterQualification: qualification,
        includeNativeEncounterConsumers: true);
    final sourceOnlyLimits = sourceCatalogStudyWriteLimitsFor(1);
    expect(sourceOnlyLimits.maxArtifacts, 512);
    await expectLater(
        composer.compose(
            source: source.fixture.source,
            base: events!.draft,
            files: source.fixture.files,
            limits: sourceOnlyLimits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'catalogs.artifacts.quota')));
    final composed = await composer.compose(
        source: source.fixture.source,
        base: events.draft,
        files: source.fixture.files,
        limits: limits);
    expect(composed, isNotNull);
    final draft = composed!.draft;
    expect(draft.artifacts.length + draft.sourceArtifacts.length,
        greaterThan(sourceOnlyLimits.maxArtifacts));
    expect(
        draft.mutations.where(
            (mutation) => mutation.actionId == 'campaign.trainer.upsert'),
        isEmpty);
    expect(
        draft.mutations.where((mutation) =>
            mutation.actionId == 'campaign.encounter_table.upsert'),
        hasLength(1));
    expect(
        draft.mutations.any((mutation) =>
            mutation.actionId == 'pokemon.configuration.set_enabled' &&
            mutation.parameters['enabled'] == true),
        isTrue);
    expect(draft.mutations.where((m) => m.actionId == 'gameplay_zone.create'),
        hasLength(2));
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await const NativeProjectWriter()
        .write(approval.plan, approval.context, draft, limits: limits);
    expect(receipt.verified, isTrue);
    final manifest = jsonDecode(
            await File('${receipt.projectPath}/project.json').readAsString())
        as Map;
    expect(manifest['encounterTables'], hasLength(1));
    expect((manifest['encounterTables'] as List).single['chancePerStep'], .02);
    final reopened =
        ProjectManifest.fromJson(Map<String, dynamic>.from(manifest));
    expect(reopened.newGame.initialBag, isEmpty);
    expect(reopened.newGame.initialParty, isEmpty);
    final itemPath =
        const ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1)
            .catalogFiles['items']!;
    final catalog = decodeProjectItemCatalog(jsonDecode(
        await File('${receipt.projectPath}/$itemPath').readAsString()));
    expect(
        catalog.entries.where((item) => item.uses
            .any((use) => use.effect is ProjectItemFishingEffectDefinition)),
        hasLength(3));
    expect(
        catalog.entries.where((item) => item.uses
            .any((use) => use.effect is ProjectItemRepelEffectDefinition)),
        hasLength(3));

    final changed = jsonDecode(jsonEncode(draft.compositionEvidence))
        as Map<String, dynamic>;
    final forged = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: 'forged',
        sourceRootPath: draft.sourceRootPath,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        mutations: draft.mutations
            .where((m) => m.actionId != 'gameplay_zone.create')
            .toList(),
        compositionEvidence: changed,
        limits: limits);
    final forgedApproval = approveNativeFixtureDraft(forged);
    await expectLater(
        const NativeProjectWriter().write(
            forgedApproval.plan, forgedApproval.context, forged,
            limits: limits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.semantics.regeneration')));
    expect(await Directory('${temporary.path}/forged').exists(), isFalse);
    var modifiedCatalogs = 0;
    final changedItems = draft.mutations.map((mutation) {
      if (mutation.actionId != 'pokemon.catalog.write' ||
          mutation.parameters['relativePath'] != itemPath) {
        return mutation;
      }
      final parameters =
          jsonDecode(jsonEncode(mutation.parameters)) as Map<String, dynamic>;
      final definitions = (parameters['document'] as Map)['entries'] as List;
      final rod = definitions.cast<Map>().firstWhere((definition) =>
          (definition['uses'] as List)
              .any((use) => (use['effect'] as Map)['kind'] == 'fishing'));
      rod['uses'] = <Object?>[];
      modifiedCatalogs++;
      return NativeMutation(
          operationId: mutation.operationId,
          actionId: mutation.actionId,
          sourceEntityIds: mutation.sourceEntityIds,
          targetEntityIds: mutation.targetEntityIds,
          parameters: parameters,
          limits: limits);
    }).toList();
    expect(modifiedCatalogs, 1);
    final forgedItems = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: 'forged_items',
        sourceRootPath: draft.sourceRootPath,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        mutations: changedItems,
        compositionEvidence: draft.compositionEvidence,
        limits: limits);
    final itemsApproval = approveNativeFixtureDraft(forgedItems);
    await expectLater(
        const NativeProjectWriter().write(
            itemsApproval.plan, itemsApproval.context, forgedItems,
            limits: limits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.semantics.regeneration')));
    expect(await Directory('${temporary.path}/forged_items').exists(), isFalse);

    expect(
        (await temporary.list().toList())
            .where((entry) => entry.path.contains('staging')),
        isEmpty);
  }, skip: scriptsPath == null, timeout: const Timeout(Duration(seconds: 120)));
}
