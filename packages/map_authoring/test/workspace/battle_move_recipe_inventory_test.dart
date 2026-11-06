import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

Map<String, Object?> _binding(String id) => BattleRecipeProjectBinding(
      binding: BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': id,
        'sourceMoveId': id,
        'catalogReleaseId': 'old-release',
        'recipeId': 'recipe',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': 'a' * 64,
      }),
      catalogMoveId: id,
      recipeMediaId: 'recipe',
    ).toJson();

void main() {
  test('reads all attacks and bindings without rewriting or reading maps',
      () async {
    final root = await Directory.systemTemp.createTemp('battle-inventory-');
    final handles = WorkspaceHandleStore();
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final fixture = spatialFeaturePayload('companion');
    final base = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(fixture['project/project.json']!)));
    final project = base.copyWith(
      pokemon: base.pokemon.copyWith(catalogRelease: 'old-release'),
      maps: [
        ...base.maps,
        ProjectMapEntry(
            id: 'foreign', name: 'Foreign', relativePath: 'maps/foreign.json'),
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store, projectId: 'inventory', project: project);
    final moves = File('${root.path}/${project.pokemon.catalogFiles['moves']}');
    await moves.parent.create(recursive: true);
    await moves.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'catalog': 'moves',
      'entries': [
        {'id': 'tackle', 'source': 'heartgold-fr-rom'},
        {'id': 'surf', 'source': 'heartgold-fr-rom'},
        {'id': 'smoke_screen', 'source': 'heartgold-fr-rom'},
        {'id': 'faint_attack', 'source': 'heartgold-fr-rom'},
        {'id': 'selfdestruct', 'source': 'heartgold-fr-rom'},
        {'id': 'thunder', 'source': 'project_custom'},
        {'id': 'made_up_attack', 'source': 'heartgold-fr-rom'},
        {'id': 'growl', 'source': 'heartgold-fr-rom'},
        {'id': 'growl', 'source': 'heartgold-fr-rom'},
        {
          'id': 'thunderbolt',
          'source': 'showdown',
          'sourceRefs': {'showdownMoveId': 'thunderbolt'}
        },
        {
          'id': 'ice_beam',
          'source': 'showdown',
          'sourceRefs': {'showdownMoveId': 'wrong'}
        },
        {'id': '../wrong', 'source': 'heartgold-fr-rom'},
        'invalid row',
        {'id': 'self_destruct', 'source': 'heartgold-fr-rom'},
      ],
    }));
    final binding = File('${root.path}/${battleRecipeBindingPath('tackle')}');
    await binding.parent.create(recursive: true);
    await binding.writeAsString(jsonEncode(_binding('tackle')));
    final corrupt = File('${root.path}/${battleRecipeBindingPath('surf')}');
    await corrupt.writeAsString('{broken');
    final foreign = File('${root.path}/maps/foreign.json');
    await foreign.parent.create(recursive: true);
    await foreign.writeAsString('unrelated');
    final watched = [
      moves,
      binding,
      corrupt,
      foreign,
      File('${root.path}/project.json'),
      File('${root.path}/catalog/HEAD.json')
    ];
    final before = [
      for (final file in watched)
        sha256.convert(await file.readAsBytes()).toString()
    ];
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {},
        initializeSceneOwners: false);
    final opened = await opener.openProject(root.path);
    addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
    Future<List<String>> paths() async =>
        (await root.list(recursive: true).map((entity) => entity.path).toList())
          ..sort();
    final beforePaths = await paths();
    reader.paths.clear();
    final inventory = await BattleMoveRecipeInventoryReader(opener)
        .read(opened.projectHandle);
    expect(inventory.catalogRelease, 'old-release');
    expect(inventory.moves, hasLength(14));
    expect(inventory.moves[0].status, BattleMoveRecipeInventoryStatus.eligible);
    expect(inventory.moves[0].existing!.binding.projectMoveId, 'tackle');
    expect(
        inventory.moves[1].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(inventory.moves[2].catalogMoveId, 'smokescreen');
    expect(inventory.moves[3].catalogMoveId, 'feint-attack');
    expect(inventory.moves[4].catalogMoveId, 'self-destruct');
    expect(inventory.moves[4].reason,
        BattleMoveRecipeInventoryReason.duplicateIdentity);
    expect(inventory.moves[5].status, BattleMoveRecipeInventoryStatus.custom);
    expect(
        inventory.moves[6].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(
        inventory.moves[7].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(
        inventory.moves[8].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(inventory.moves[9].status, BattleMoveRecipeInventoryStatus.eligible);
    expect(
        inventory.moves[10].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(
        inventory.moves[11].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(
        inventory.moves[12].status, BattleMoveRecipeInventoryStatus.uncertain);
    expect(inventory.moves[13].reason,
        BattleMoveRecipeInventoryReason.duplicateIdentity);
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    expect(
        reader.paths.where((path) => path.endsWith('history.jsonl')), isEmpty);
    expect([
      for (final file in watched)
        sha256.convert(await file.readAsBytes()).toString()
    ], before);
    expect(await paths(), beforePaths);
  });
}
