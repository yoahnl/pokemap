import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_bag_item_icon_resolver.dart';
import 'package:path/path.dart' as p;

const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9tsAAAAASUVORK5CYII=';

Future<void> _writeProjectItemsCatalog(
  Directory root, {
  required List<Map<String, Object?>> entries,
}) async {
  final catalogFile = File(
    p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
  );
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(
    jsonEncode(<String, Object?>{
      'catalog': 'items',
      'entries': entries,
    }),
  );
}

Future<String> _writeTinyItemSprite(
  Directory root,
  String itemId,
) async {
  final file = File(
    p.join(root.path, 'data', 'pokemon', 'assets', 'items', '$itemId.png'),
  );
  await file.parent.create(recursive: true);
  await file.writeAsBytes(base64Decode(_tinyPngBase64));
  return file.path;
}

void main() {
  group('BattleBagItemIconResolver', () {
    test('resolves a project local sprite path from items catalog', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_bag_item_icon_resolver_',
      );
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });

      final expectedPath = await _writeTinyItemSprite(projectRoot, 'potion');
      await _writeProjectItemsCatalog(
        projectRoot,
        entries: <Map<String, Object?>>[
          <String, Object?>{
            'id': 'potion',
            'name': 'Potion',
            'localSpritePath': 'data/pokemon/assets/items/potion.png',
          },
        ],
      );

      final resolver = BattleBagItemIconResolver(
        manifest: const ProjectManifest(
          name: 'Icon Resolver Test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        projectRootDirectory: projectRoot.path,
      );

      final spec = await resolver.resolve('potion');

      expect(spec.itemId, equals('potion'));
      expect(spec.explicitImageAbsolutePath, equals(p.normalize(expectedPath)));
      expect(spec.hasExplicitImage, isTrue);
    });

    test('falls back cleanly when the item has no local sprite path', () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_bag_item_icon_resolver_missing_',
      );
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });

      await _writeProjectItemsCatalog(
        projectRoot,
        entries: <Map<String, Object?>>[
          <String, Object?>{
            'id': 'hyper-potion',
            'name': 'Hyper Potion',
          },
        ],
      );

      final resolver = BattleBagItemIconResolver(
        manifest: const ProjectManifest(
          name: 'Icon Resolver Test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        projectRootDirectory: projectRoot.path,
      );

      final spec = await resolver.resolve('hyper-potion');

      expect(spec.itemId, equals('hyper-potion'));
      expect(spec.explicitImageAbsolutePath, isNull);
      expect(spec.hasExplicitImage, isFalse);
    });
  });
}
