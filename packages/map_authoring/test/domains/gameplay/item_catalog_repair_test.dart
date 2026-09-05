import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const repaired = <String, dynamic>{
    'schemaVersion': 1,
    'entries': <Map<String, Object?>>[
      {'id': 'potion', 'displayName': 'Potion', 'pocketId': 'medicine'},
    ],
  };

  test('item documents use the item codec and reject generic catalog envelopes', () {
    final document = PokemonJsonDocument.fromJson(PokemonDocumentKind.catalog, repaired);
    expect(document.identity, 'items');
    expect(decodeProjectItemCatalog(document.toJson()).entries.single.id, 'potion');
    expect(() => PokemonJsonDocument.fromJson(PokemonDocumentKind.catalog, {
      ...repaired, 'kind': 'pokemon_catalog', 'catalog': 'items',
    }), throwsFormatException);
  });

  test('a malformed item catalog stays readable and only its repair can mutate', () async {
    final root = await Directory.systemTemp.createTemp('item-catalog-repair-');
    addTearDown(() => root.delete(recursive: true));
    final manifest = const ProjectManifest(name: 'Repair fixture', maps: [], tilesets: [], pokemon: ProjectPokemonConfig(enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    await File('${root.path}/project.json').writeAsString(jsonEncode(manifest.toJson()));
    final itemFile = File('${root.path}/${manifest.pokemon.catalogFiles['items']}');
    await itemFile.parent.create(recursive: true);
    final invalidBytes = utf8.encode(jsonEncode({...repaired, 'kind': 'pokemon_catalog', 'catalog': 'items'}));
    await itemFile.writeAsBytes(invalidBytes);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(openService: ProjectOpenService(policy: policy, fileReader: reader, handles: handles), snapshotLoader: snapshots);
    final mutations = LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(projectRootPath: root.path, workspaceHandle: opened.workspaceHandle, projectHandle: opened.projectHandle);
    await expectLater(() => snapshots.load(opened.projectHandle), throwsA(isA<ProjectSnapshotException>()));
    final snapshot = await snapshots.load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.editorReadProjection);
    expect(snapshot.loadDiagnostics.single.code, 'project.item_catalog_invalid');
    expect(snapshot.resourceBytes(itemCatalogResourceIdentity), invalidBytes);
    AuthoringRequest request(String id, String action, Map<String, Object?> parameters) => AuthoringRequest(requestId: id, actionId: action, actionVersion: 1, workspaceHandle: opened.workspaceHandle.value, parameters: parameters, expectedRevision: snapshot.revision, idempotencyKey: id, dryRun: false);
    await expectLater(() => mutations.plan(opened.projectHandle, request('unrelated', 'fact.create', {'fact': {'id': 'fact_unrelated', 'label': 'Unrelated'}})), throwsA(isA<ProjectSnapshotException>()));
    final plan = await mutations.plan(opened.projectHandle, request('repair', 'pokemon.catalog.write', {
      'relativePath': manifest.pokemon.catalogFiles['items'],
      'document': repaired,
      'beforeBytesBase64': base64Encode(invalidBytes),
    }));
    await mutations.apply(opened.projectHandle, planId: plan['planId']! as String, operationId: 'repair-items');
    final restored = await snapshots.load(opened.projectHandle);
    expect(restored.loadDiagnostics, isEmpty);
    expect(restored.itemCatalog!.entries.single.id, 'potion');
    expect(decodeProjectItemCatalog(jsonDecode(await itemFile.readAsString())).entries.single.id, 'potion');
  });
}
