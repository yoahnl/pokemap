import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3 && !(args.length == 4 && args.last == '--sync-battle')) {
    throw ArgumentError('Expected source project, owned QA directory and evidence directory.');
  }
  final source = Directory(args[0]).absolute;
  final qa = Directory(args[1]).absolute;
  final evidence = Directory(args[2]).absolute;
  if (!qa.path.startsWith('/Users/karim/Library/Caches/AveluneQA/')) {
    throw ArgumentError('The fixture must belong to AveluneQA.');
  }
  final target = Directory('${qa.path}/project');
  if (args.length == 4) {
    final moves = <String>{'body_slam', 'mist', 'confuse_ray', 'ice_shard', 'water_pulse', 'water_gun', 'sing', 'growl', 'surf', 'tackle', 'yawn', 'headbutt', 'confusion', 'disable', 'slack_off', 'withdraw'};
    var copied = 0;
    for (final move in moves) {
      final bindingFile = File('${source.path}/${battleRecipeBindingPath(move)}');
      if (!await bindingFile.exists()) continue;
      final binding = BattleRecipeProjectBinding.fromJson(jsonDecode(await bindingFile.readAsString()) as Map<String, dynamic>).binding;
      final recipePath = battleRecipeBlobPath(binding.recipeSha256, 'application/vnd.avelune.battle-recipe+json', projectMoveId: move);
      final bytes = await File('${source.path}/$recipePath').readAsBytes();
      final recipe = binding.inspectRecipe(bytes);
      for (final relative in [battleRecipeBindingPath(move), recipePath,
        for (final resource in recipe.resources) battleRecipeBlobPath(resource.sha256Hex, resource.mediaType, projectMoveId: move)]) {
        final original = File('${source.path}/$relative');
        final destination = File('${target.path}/$relative');
        await destination.parent.create(recursive: true);
        await original.copy(destination.path);
        copied++;
      }
    }
    stdout.writeln(jsonEncode({'selectedMoveIds': moves.toList(), 'copiedRecipeFiles': copied, 'sourceModified': false}));
    return;
  }
  if (target.existsSync()) throw StateError('Preserve the existing fixture.');
  final catalog = await RuntimeProjectCatalog.open('${source.path}/project.json');
  try {
    final maps = <MapData>[];
    final hashes = <String, String>{};
    for (final entry in catalog.projectMetadata.maps) {
      final bytes = await File('${source.path}/${entry.relativePath}').readAsBytes();
      hashes[entry.relativePath] = sha256.convert(bytes).toString();
      maps.add(MapData.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>));
    }
    final manifest = await catalog.manifestForMaps(maps,
      extraCharacterIds: const ['hgss-joueur', 'hgss-joueuse'],
      extraSceneIds: catalog.projectMetadata.scenes.map((scene) => scene.id));
    await evidence.create(recursive: true);
    await File('${evidence.path}/readback-before.json').writeAsString(jsonEncode({
      'project': manifest.toJson(),
      'maps': {for (final map in maps.where((map) => map.id == 'route-32' || map.id == 'caves-jumelles-sous-sol2')) map.id: map.toJson()},
      'mapHashes': hashes,
    }));
    await target.create(recursive: true);
    Future<void> copy(String relative) async {
      final original = File('${source.path}/$relative');
      if (!await original.exists()) return;
      final destination = File('${target.path}/$relative');
      await destination.parent.create(recursive: true);
      await original.copy(destination.path);
    }
    for (final entry in manifest.maps) { await copy(entry.relativePath); }
    await for (final entry in Directory('${source.path}/data').list(recursive: true, followLinks: false)) {
      if (entry is File && entry.path.endsWith('.json')) {
        await copy(entry.path.substring(source.path.length + 1));
      }
    }
    final strings = <String>{};
    void visit(Object? value) {
      if (value is String) strings.add(value);
      if (value is Map) { for (final item in value.values) { visit(item); } }
      if (value is List) { for (final item in value) { visit(item); } }
    }
    visit(manifest.toJson());
    final assetFile = File('${source.path}/assets/.pokemap-assets.json');
    final assets = AssetCatalog.fromJson(jsonDecode(await assetFile.readAsString()) as Map<String, dynamic>);
    for (final asset in assets.records.where((asset) => strings.contains(asset.id))) {
      await copy(assetBlobStorageKey(asset.artifact));
      await copy(asset.logicalPath);
    }
    await copy('assets/.pokemap-assets.json');
    final paths = strings.where((value) => value.contains('/') && !value.startsWith('/') && !value.contains('..') && !value.contains(':'));
    for (final path in paths) { await copy(path); }
    final store = await CatalogStorageStore.open(projectRoot: target.path);
    final working = await WorkingProjectCatalog.create(store: store, projectId: 'hgss-c708-qa', project: manifest);
    await working.close();
    stdout.writeln(jsonEncode({'fixture': target.path, 'maps': maps.length, 'characters': manifest.characters.length, 'sourceModified': false}));
  } finally {
    catalog.dispose();
  }
}
