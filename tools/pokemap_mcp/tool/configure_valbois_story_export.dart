import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Expected Valbois project root');
  final root = Directory(args.single).resolveSymbolicLinksSync();
  if (root.split('/').last != 'avelune_3d_village_demo') {
    throw ArgumentError('Expected the dedicated Valbois demo project');
  }
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await File('$root/project.json').readAsString())
        as Map<String, dynamic>,
  );
  if (manifest.name != 'Valbois — Voyage en 3D' ||
      manifest.settings.dimension != ProjectDimension.threeD ||
      !manifest.cinematics.any(
        (asset) => asset.id == 'valbois-guide-door-cinematic',
      ) ||
      !manifest.cinematics.any(
        (asset) => asset.id == 'valbois-guide-return-cinematic',
      )) {
    throw ArgumentError('Expected the authored native Valbois story project');
  }
  final store = GamePackageExportProfileStore(projectRoot: Directory(root));
  final current = await store.load();
  if (current == null ||
      current.gameId != 'games.yoahn.valbois' ||
      !{'0.1.0', '0.2.0'}.contains(current.gameVersion) ||
      current.authorName != 'Yoahn') {
    throw StateError('The existing Valbois export profile changed');
  }
  final profile = GamePackageExportProfile(
    gameId: current.gameId,
    gameVersion: '0.2.0',
    title: current.title,
    description: current.description,
    authorName: current.authorName,
    defaultLocale: current.defaultLocale,
    supportedLocales: current.supportedLocales,
  );
  if (current != profile) await store.save(profile);
  stdout.writeln(
    jsonEncode({'updated': current != profile, 'profile': profile.toJson()}),
  );
}
