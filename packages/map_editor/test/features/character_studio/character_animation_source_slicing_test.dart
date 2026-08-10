import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_matrix_model.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_source_import_service.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_source_slicing.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_portrait_import_service.dart';
import 'package:map_editor/src/features/character_studio/presentation/animations/character_animation_source_editor.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  test('reads exact PNG dimensions and slices a row-major grid', () {
    final dimensions = CharacterAnimationSourceDimensions.fromPng(
      _pngHeader(width: 96, height: 64),
    );

    final frames = CharacterAnimationSourceSlicing.grid(
      dimensions: dimensions,
      columns: 3,
      rows: 2,
      durationMs: 120,
    );

    expect(dimensions, const CharacterAnimationSourceDimensions(96, 64));
    expect(frames, hasLength(6));
    expect(frames.map((frame) => frame.source), const <TilesetSourceRect>[
      TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
      TilesetSourceRect(x: 32, y: 0, width: 32, height: 32),
      TilesetSourceRect(x: 64, y: 0, width: 32, height: 32),
      TilesetSourceRect(x: 0, y: 32, width: 32, height: 32),
      TilesetSourceRect(x: 32, y: 32, width: 32, height: 32),
      TilesetSourceRect(x: 64, y: 32, width: 32, height: 32),
    ]);
    expect(frames.every((frame) => frame.durationMs == 120), isTrue);
  });

  test(
    'rejects malformed grids, invalid durations, and escaped rectangles',
    () {
      const dimensions = CharacterAnimationSourceDimensions(95, 64);

      expect(
        () => CharacterAnimationSourceSlicing.grid(
          dimensions: dimensions,
          columns: 3,
          rows: 2,
        ),
        throwsA(isA<CharacterAnimationSlicingException>()),
      );
      expect(
        () => CharacterAnimationSourceSlicing.grid(
          dimensions: dimensions,
          columns: 1,
          rows: 1,
          durationMs: 0,
        ),
        throwsA(isA<CharacterAnimationSlicingException>()),
      );
      expect(
        () => CharacterAnimationSourceSlicing.validateFrame(
          const CharacterAnimationFrame(
            source: TilesetSourceRect(x: 80, y: 0, width: 32, height: 32),
          ),
          dimensions,
        ),
        throwsA(isA<CharacterAnimationSlicingException>()),
      );
    },
  );

  test(
    'imports a portable sprite sheet then assigns only the selected slot',
    () async {
      final gateway = _AssetGateway();
      final service = CharacterAnimationSourceImportService(gateway: gateway);
      final project = _project();
      const slot = CharacterAnimationSlotKey.system(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.north,
      );

      await service.import(
        projectRootPath: '/project',
        project: project,
        characterId: 'elia',
        slotKey: slot,
        sourcePath: '/source/elia.png',
        loop: true,
      );

      expect(gateway.actions, <String>[
        'characterStudio.asset.import',
        'characterStudio.animationClip.upsert',
      ]);
      expect(gateway.parameters.last['characterId'], 'elia');
      expect(gateway.parameters.last['kind'], 'system');
      expect(gateway.parameters.last['state'], 'idle');
      expect(gateway.parameters.last['direction'], 'north');
      expect(gateway.parameters.last['frames'], isEmpty);
      expect(
        gateway.parameters.last['sourceAssetId'],
        startsWith('sprite-elia-'),
      );
    },
  );

  test(
    'reimporting a historical source never reuses its asset record',
    () async {
      final gateway = _AssetGateway();
      var sequence = 0;
      final service = CharacterAnimationSourceImportService(
        gateway: gateway,
        uniqueSuffix: () => 'import-${sequence++}',
      );
      final project = _project();
      const slot = CharacterAnimationSlotKey.system(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.north,
      );

      await service.import(
        projectRootPath: '/project',
        project: project,
        characterId: 'elia',
        slotKey: slot,
        sourcePath: '/source/a.png',
        loop: true,
      );
      final firstAssetId = gateway.parameters.last['sourceAssetId'];
      await service.import(
        projectRootPath: '/project',
        project: project,
        characterId: 'elia',
        slotKey: slot,
        sourcePath: '/source/a.png',
        loop: true,
      );

      expect(gateway.parameters.last['sourceAssetId'], isNot(firstAssetId));
      expect(
        gateway.actions.where(
          (action) => action == 'characterStudio.asset.import',
        ),
        hasLength(2),
      );
    },
  );

  testWidgets('source editor exposes dimensions and applies an assisted grid', (
    tester,
  ) async {
    List<CharacterAnimationFrame>? savedFrames;
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 760,
            child: CharacterAnimationSourceEditor(
              slot: const CharacterAnimationMatrixSlot(
                key: CharacterAnimationSlotKey.system(
                  state: CharacterAnimationState.idle,
                  direction: EntityFacing.north,
                ),
                label: 'Nord',
                status: CharacterAnimationSlotStatus.invalid,
                frames: <CharacterAnimationFrame>[],
                sourceAssetId: 'sprite-elia-base-north',
                loop: true,
              ),
              projectRootPath: '/project',
              projectRevision: '1',
              mediaResolver: _MediaResolver(bytes),
              enabled: true,
              onImportSource: () async {},
              onFramesChanged: (frames) async => savedFrames = frames,
              onLoopChanged: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 × 1 px · PNG'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('animation-grid-duration')),
      '120',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('animation-grid-apply')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('animation-grid-apply')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-grid-apply')),
    );
    await tester.pump();

    expect(savedFrames, hasLength(1));
    expect(savedFrames!.single.durationMs, 120);
    expect(
      savedFrames!.single.source,
      const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
    );
  });
}

final class _MediaResolver implements CharacterStudioMediaResolverContract {
  const _MediaResolver(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) async => bytes;
}

final class _AssetGateway implements CharacterStudioPortraitAssetGateway {
  final List<String> actions = <String>[];
  final List<Map<String, Object?>> parameters = <Map<String, Object?>>[];

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    return ContentArtifactRef(
      digest: 'sha256:${List<String>.filled(64, 'a').join()}',
      mediaType: 'image/png',
      byteLength: 24,
    );
  }

  @override
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
  }) async {
    actions.add(actionId);
    this.parameters.add(parameters);
    return expectedProject;
  }
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Source',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(id: 'elia', name: 'Élia', tilesetId: 'elia'),
    ],
  );
}

Uint8List _pngHeader({required int width, required int height}) {
  final bytes = Uint8List(24);
  bytes.setAll(0, const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.setAll(12, const <int>[73, 72, 68, 82]);
  _writeUint32(bytes, 16, width);
  _writeUint32(bytes, 20, height);
  return bytes;
}

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = (value >> 24) & 0xff;
  bytes[offset + 1] = (value >> 16) & 0xff;
  bytes[offset + 2] = (value >> 8) & 0xff;
  bytes[offset + 3] = value & 0xff;
}
