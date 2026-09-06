import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:map_editor/src/infrastructure/filesystem/pokemon_menu_sprite_source.dart';

void main() {
  const path = 'src/minisprites/pokemon/home/s32.png';
  const revision = 'ded9d487d0531f8eb749c2d495e54e6f4bd2d5bf';
  final bytes = image.encodePng(image.Image(width: 2, height: 2));
  Map<String, dynamic> manifest() => {
    'schemaVersion': 1,
    'repository': 'https://github.com/smogon/sprites',
    'revision': revision,
    'species': {
      's32': {'sid': 's32', 'num': 1, 'formeNum': 0, 'forme': ''},
    },
    'assets': {
      path: {'sha256': sha256.convert(bytes).toString(), 'bytes': bytes.length},
    },
  };

  test(
    'integrated source pins the revision, verifies bytes, then works offline',
    () async {
      final root = await Directory.systemTemp.createTemp('menu-sprites-cache-');
      addTearDown(() => root.delete(recursive: true));
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(
          request.url.toString(),
          'https://raw.githubusercontent.com/smogon/sprites/$revision/$path',
        );
        expect(request.followRedirects, isFalse);
        return http.Response.bytes(bytes, 200);
      });
      addTearDown(client.close);
      final source = PokemonMenuSpriteSource(
        cacheRoot: root.path,
        manifest: manifest(),
        client: client,
      );
      final resolved = await source.resolve(path);
      expect(await File(resolved!).readAsBytes(), bytes);
      expect(await source.resolve(path), resolved);
      expect(requests, 1);
      expect(
        await source.resolve('src/minisprites/pokemon/home/s999999.png'),
        isNull,
      );
      expect(requests, 1);
    },
  );

  test(
    'corrupt cached bytes are fetched again and remote changes rejected',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'menu-sprites-corrupt-',
      );
      addTearDown(() => root.delete(recursive: true));
      final cached = File('${root.path}/$path');
      await cached.parent.create(recursive: true);
      await cached.writeAsBytes(List.filled(bytes.length, 0));
      final client = MockClient(
        (_) async => http.Response.bytes(List.filled(bytes.length, 1), 200),
      );
      addTearDown(client.close);
      final source = PokemonMenuSpriteSource(
        cacheRoot: root.path,
        manifest: manifest(),
        client: client,
      );
      await expectLater(source.resolve(path), throwsFormatException);
      expect(await cached.readAsBytes(), List.filled(bytes.length, 0));
    },
  );

  test(
    'no redirects, missing remote bytes or cache symlinks are trusted',
    () async {
      final root = await Directory.systemTemp.createTemp('menu-sprites-safe-');
      final outside = await Directory.systemTemp.createTemp(
        'menu-sprites-outside-',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => outside.delete(recursive: true));
      final client = MockClient((_) async => http.Response('', 302));
      addTearDown(client.close);
      final source = PokemonMenuSpriteSource(
        cacheRoot: root.path,
        manifest: manifest(),
        client: client,
      );
      await expectLater(source.resolve(path), throwsA(isA<HttpException>()));
      await Link('${root.path}/$path').create('${outside.path}/image.png');
      await expectLater(source.resolve(path), throwsFormatException);
      expect(await File('${outside.path}/image.png').exists(), isFalse);
    },
  );

  test(
    'a symlinked parent cannot create directories outside the cache',
    () async {
      final root = await Directory.systemTemp.createTemp('menu-parent-cache-');
      final outside = await Directory.systemTemp.createTemp(
        'menu-parent-outside-',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => outside.delete(recursive: true));
      await Link('${root.path}/src').create(outside.path);
      final client = MockClient(
        (_) async => throw StateError('Network must not be used'),
      );
      addTearDown(client.close);
      final source = PokemonMenuSpriteSource(
        cacheRoot: root.path,
        manifest: manifest(),
        client: client,
      );
      await expectLater(source.resolve(path), throwsFormatException);
      expect(await outside.list().toList(), isEmpty);
    },
  );
}
