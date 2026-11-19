import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../api/local_map_authoring_mutation_api.dart';
import '../../workspace/catalog/catalog_project_reader.dart';
import '../../workspace/project_snapshot.dart';
import '../../workspace/project_snapshot_loader.dart';
import '../../workspace/workspace_handle_store.dart';
import '../assets/asset_store.dart';

typedef ProjectItemAssetSources = ({
  ProjectPokemonConfig pokemon,
  ProjectItemCatalog? items,
  AssetCatalog assets,
});

Future<ProjectItemAssetSources> readProjectItemAssetSources({
  required CatalogProjectReader? catalog,
  required ProjectSnapshotLoader snapshots,
  required ProjectHandle handle,
  required Future<File> Function(String path) projectFile,
}) async {
  if (catalog == null) {
    final snapshot = await snapshots.load(
      handle,
      policy: ProjectSnapshotLoadPolicy.resourceUsageReadProjection,
    );
    final pokemon = snapshot.manifest.pokemon;
    final items = snapshot.itemCatalog;
    final assetBytes = pokemon.enabled && items != null
        ? snapshot.findResourceBytes(assetCatalogResourceIdentity)
        : null;
    return (pokemon: pokemon, items: items, assets: _decodeAssets(assetBytes));
  }
  return catalog.read((selected) async {
    final pokemon = selected.projectMetadata.pokemon;
    final path = pokemon.catalogFiles['items'];
    if (!pokemon.enabled || path == null) {
      return (pokemon: pokemon, items: null, assets: AssetCatalog());
    }
    final itemFile = await projectFile(path);
    if (!await itemFile.exists()) {
      return (pokemon: pokemon, items: null, assets: AssetCatalog());
    }
    final items =
        decodeProjectItemCatalog(jsonDecode(await itemFile.readAsString()));
    final assetFile = await projectFile(assetCatalogStorageKey);
    final assetBytes =
        await assetFile.exists() ? await assetFile.readAsBytes() : null;
    return (pokemon: pokemon, items: items, assets: _decodeAssets(assetBytes));
  });
}

AssetCatalog _decodeAssets(List<int>? bytes) => bytes == null
    ? AssetCatalog()
    : AssetCatalog.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);

Future<ProjectSnapshot> readItemAssetMutationSnapshot({
  required bool catalogBacked,
  required ProjectSnapshotLoader snapshots,
  required LocalMapAuthoringMutationApi api,
  required ProjectHandle handle,
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    catalogBacked || actionId == 'item.update'
        ? api.readWorkshopSnapshot(handle,
            actionId: actionId, parameters: parameters)
        : snapshots.load(handle,
            policy: ProjectSnapshotLoadPolicy.editorReadProjection);
