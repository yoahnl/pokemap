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
      manifest.settings.dimension != ProjectDimension.threeD) {
    throw ArgumentError('Expected the authored native Valbois 3D project');
  }
  final profile = GamePackageExportProfile(
    gameId: 'games.yoahn.valbois',
    gameVersion: '0.1.0',
    title: manifest.name,
    description:
        'Une première promenade entre Valbois, sa prairie et sa forêt.',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: const ['fr'],
  );
  final store = GamePackageExportProfileStore(projectRoot: Directory(root));
  final current = await store.load();
  if (current != null && current != profile) {
    throw StateError('An existing export profile must be reviewed separately');
  }
  if (current == null) await store.save(profile);
  await Directory('$root/exports').create(recursive: true);
  stdout.writeln(
    jsonEncode({'created': current == null, 'profile': profile.toJson()}),
  );
}
