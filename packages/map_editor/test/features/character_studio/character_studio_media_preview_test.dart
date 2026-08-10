import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/presentation/preview/character_studio_media_preview.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:path/path.dart' as p;

void main() {
  test('resolver cache is isolated by asset and project revision', () async {
    final source = _CountingSource();
    final resolver = CharacterStudioMediaResolver(source: source);
    const request = CharacterStudioMediaRequest(
      projectRootPath: '/tmp/character-studio-media',
      assetId: 'elia-portrait',
      projectRevision: 'revision-a',
    );

    final first = await resolver.resolve(request);
    final second = await resolver.resolve(request);
    final refreshed = await resolver.resolve(
      request.copyWith(projectRevision: 'revision-b'),
    );

    expect(first, same(second));
    expect(refreshed, isNot(same(first)));
    expect(source.loadCount, 2);
  });

  test(
    'file source resolves the portable catalog blob inside the project',
    () async {
      final root = await Directory.systemTemp.createTemp('character_media_');
      addTearDown(() => root.delete(recursive: true));
      final artifact = ContentArtifactRef.fromBytes(
        _greenPng,
        mediaType: 'image/png',
      );
      final catalog = AssetCatalog(
        records: <AssetRecord>[
          AssetRecord(
            id: 'elia-portrait',
            logicalPath: 'assets/characters/elia.png',
            artifact: artifact,
            tags: const <String>['character-studio:portrait'],
          ),
        ],
      );
      final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
      await catalogFile.parent.create(recursive: true);
      await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
      final blob = File(p.join(root.path, assetBlobStorageKey(artifact)));
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(_greenPng);

      final bytes = await const FileCharacterStudioMediaSource().load(
        CharacterStudioMediaRequest(
          projectRootPath: root.path,
          assetId: 'elia-portrait',
          projectRevision: 'revision-a',
        ),
      );

      expect(bytes, orderedEquals(_greenPng));
    },
  );

  testWidgets('stale media resolution never replaces the latest selection', (
    tester,
  ) async {
    final resolver = _ControlledResolver();
    const first = CharacterStudioMediaRequest(
      projectRootPath: '/tmp/character-studio-media',
      assetId: 'slow',
      projectRevision: 'revision-a',
    );
    const second = CharacterStudioMediaRequest(
      projectRootPath: '/tmp/character-studio-media',
      assetId: 'fast',
      projectRevision: 'revision-a',
    );

    await _pumpPreview(tester, resolver: resolver, request: first);
    expect(
      find.byKey(const ValueKey<String>('character-studio-preview-loading')),
      findsOneWidget,
    );

    await _pumpPreview(tester, resolver: resolver, request: second);
    resolver.complete('fast', _greenPng);
    await tester.pump();
    resolver.complete('slow', _redPng);
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as MemoryImage;
    expect(provider.bytes, orderedEquals(_greenPng));
  });

  testWidgets('preview exposes empty, error, fit and pixelated states', (
    tester,
  ) async {
    final resolver = _ControlledResolver();

    await _pumpPreview(tester, resolver: resolver, request: null);
    expect(
      find.byKey(const ValueKey<String>('character-studio-preview-empty')),
      findsOneWidget,
    );

    const broken = CharacterStudioMediaRequest(
      projectRootPath: '/tmp/character-studio-media',
      assetId: 'broken',
      projectRevision: 'revision-a',
    );
    await _pumpPreview(tester, resolver: resolver, request: broken);
    resolver.fail('broken', StateError('missing blob'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('character-studio-preview-error')),
      findsOneWidget,
    );

    const sprite = CharacterStudioMediaRequest(
      projectRootPath: '/tmp/character-studio-media',
      assetId: 'sprite',
      projectRevision: 'revision-a',
    );
    await _pumpPreview(
      tester,
      resolver: resolver,
      request: sprite,
      fit: BoxFit.cover,
      pixelated: true,
    );
    resolver.complete('sprite', _greenPng);
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.filterQuality, FilterQuality.none);
    expect(
      find.byKey(const ValueKey<String>('pokemap-media-preview-checkerboard')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required CharacterStudioMediaResolverContract resolver,
  required CharacterStudioMediaRequest? request,
  BoxFit fit = BoxFit.contain,
  bool pixelated = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 240,
          child: CharacterStudioMediaPreview(
            resolver: resolver,
            request: request,
            semanticLabel: 'Aperçu média du personnage',
            fit: fit,
            pixelated: pixelated,
          ),
        ),
      ),
    ),
  );
}

final class _CountingSource implements CharacterStudioMediaSource {
  int loadCount = 0;

  @override
  Future<Uint8List> load(CharacterStudioMediaRequest request) async {
    loadCount++;
    return Uint8List.fromList(_greenPng);
  }
}

final class _ControlledResolver
    implements CharacterStudioMediaResolverContract {
  final _completers = <String, Completer<Uint8List>>{};

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) {
    return _completers
        .putIfAbsent(request.assetId, Completer<Uint8List>.new)
        .future;
  }

  void complete(String assetId, List<int> bytes) {
    _completers[assetId]!.complete(Uint8List.fromList(bytes));
  }

  void fail(String assetId, Object error) {
    _completers[assetId]!.completeError(error);
  }
}

final _redPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Z4xQAAAAASUVORK5CYII=',
);
final _greenPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
