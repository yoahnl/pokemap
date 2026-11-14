import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';
import 'pokemon_external_png_import_support.dart';

void main() {
  test('preview retains available PNGs when existing files are kept', () async {
    final transport = PngTransport();
    final selection = await AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    ).fetch(speciesId: 'bulbasaur', formId: 'bulbasaur');
    final document = {'id': 'bulbasaur', 'refs': <String, String>{}};
    final preview = PokemonExternalImportPreview(
      speciesId: 'bulbasaur',
      name: 'Bulbizarre',
      projectRevision: 'r',
      inventorySignature: '',
      warnings: const [],
      documents: [
        PokemonExternalDocument(
          family: PokemonDocumentFamily.species,
          relativePath: 'species/bulbasaur.json',
          beforeBytes: utf8.encode(jsonEncode(document)),
          document: document,
        ),
      ],
      pngSelection: selection,
    );
    final plan = preview.plan(PokemonExternalConflictPolicy.skipExisting);
    expect(plan.selected, isEmpty);
    expect(plan.kept, 1);
    expect(preview.pngSelection!.media, hasLength(5));
    expect(preview.pngSelection, same(selection));
  });

  for (final scenario in [
    'normal',
    'existing',
    'legacy',
    'keep',
    'shared',
    'dex',
    'form',
    'offline',
    'corrupt',
  ]) {
    test('Studio imports PNGs safely: $scenario', () async {
      final parent = Directory(
        Platform.environment['AVELUNE_QA_ROOT'] ?? '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await parent.create(recursive: true);
      final root = await parent.createTemp('studio-png-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialFeaturePayload('companion');
      final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>,
      );
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'studio-png',
        project: manifest,
      );
      await working.close();
      for (final entry in files.entries) {
        if (entry.key == 'project/project.json') continue;
        final file = File(
          '${root.path}/${entry.key.substring('project/'.length)}',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final session = ProjectSession(
        sessionId: 'studio-png',
        name: 'PNG',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final transport = PngTransport();
      final adapter = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: maps,
        externalSource: const PokemonExternalSourceFixture(),
        gen5Source: AveluneGen5BattleSource(client: NoGen5Transport(), release: 'test'),
        pngSource: AvelunePokemonPngSource(
          media: AvelunePokemonMediaSource(client: transport, release: 'test'),
        ),
      );
      addTearDown(adapter.close);
      final mediaFile = File('${root.path}/data/pokemon/media/bulbasaur.json');
      final isKept = const {'keep', 'shared', 'dex', 'form'}.contains(scenario);
      if (isKept) {
        transport.offline = true;
        final first = await adapter.previewExternal('bulbasaur');
        await adapter.applyExternal(
          first,
          PokemonExternalConflictPolicy.failOnConflict,
        );
        transport.offline = false;
      }
      if (scenario == 'existing' || scenario == 'legacy' || isKept) {
        await mediaFile.parent.create(recursive: true);
        await mediaFile.writeAsString(
          jsonEncode({
            'schemaVersion': scenario == 'legacy' ? 1 : 2,
            'speciesId': 'bulbasaur',
            'defaultFormId': 'base',
            'vendorExtension': {'keep': true},
            'variants': {
              'base': {'icon': 'assets/custom.png'},
            },
          }),
        );
      }
      if (scenario == 'shared') {
        final other = jsonDecode(
          utf8.decode(files['project/data/pokemon/species/bronze-bird.json']!),
        ) as Map;
        other['id'] = 'shared-owner';
        other['slug'] = 'shared-owner';
        (other['refs'] as Map)['media'] = 'bulbasaur';
        await File('${root.path}/data/pokemon/species/shared-owner.json')
            .writeAsString(jsonEncode(other));
      }
      if (scenario == 'dex' || scenario == 'form') {
        final file = File('${root.path}/data/pokemon/species/bulbasaur.json');
        final doc = jsonDecode(await file.readAsString()) as Map;
        if (scenario == 'dex') doc['nationalDex'] = 2;
        if (scenario == 'form') (doc['forms'] as Map)['isBaseForm'] = false;
        await file.writeAsString(jsonEncode(doc));
      }
      if (scenario == 'offline') transport.offline = true;
      if (scenario == 'corrupt') transport.corrupt = true;
      final before = await mediaFile.exists()
          ? await mediaFile.readAsBytes()
          : null;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        isKept
            ? PokemonExternalConflictPolicy.skipExisting
            : PokemonExternalConflictPolicy.failOnConflict,
      );
      if (const {'offline', 'corrupt'}.contains(scenario)) {
        expect(result.warnings.join(' '), contains('images'));
        expect(await mediaFile.exists(), isFalse);
        return;
      }
      if (const {'shared', 'dex', 'form'}.contains(scenario)) {
        expect(await mediaFile.readAsBytes(), before);
        return;
      }
      expect(
        await mediaFile.exists(),
        isTrue,
        reason: result.warnings.join(' '),
      );
      final media = jsonDecode(await mediaFile.readAsString()) as Map;
      expect(media['schemaVersion'], scenario == 'legacy' ? 1 : 2);
      final variant = media['variants']['base'] as Map;
      final path =
          'assets/pokemon/images/${sha256.convert(transport.bytes)}.png';
      final iconPath =
          'assets/pokemon/images/${sha256.convert(transport.iconBytes)}.png';
      final shinyPath =
          'assets/pokemon/images/${sha256.convert(transport.shinyBytes)}.png';
      expect(variant['frontStatic'], path);
      expect(variant['backStatic'], path);
      expect(variant['overworld'], path);
      expect(variant['overworldShiny'], shinyPath);
      expect(
        variant['icon'],
        scenario == 'normal' ? iconPath : 'assets/custom.png',
      );
      if (scenario != 'normal') {
        expect(media['vendorExtension'], {'keep': true});
      }
      expect(await File('${root.path}/$path').readAsBytes(), transport.bytes);
      if (scenario == 'normal') {
        await verifyPngOfflineExport(
          root,
          path,
          transport.bytes,
          iconPath,
          transport.iconBytes,
          shinyPath,
          transport.shinyBytes,
        );
      }
    });
  }
}
