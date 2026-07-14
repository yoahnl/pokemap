import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_canonical_gallery_canvas.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets(
    'renders real immutable snapshot pixels for ground and placements',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: BorderCanonicalGalleryCanvas(
                semanticsLabel: 'Courbe douce générée',
                geometry: BorderRegionGeometry(
                  width: 2,
                  height: 2,
                  cells: const <bool>[true, true, false, true],
                ),
                tileSizePx: const GridSize(width: 16, height: 16),
                materialization: _materialization(),
                catalog: ProjectBorderCatalog(
                  visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
                ),
                framesBySnapshotId: <String, List<BorderCanonicalGalleryFrame>>{
                  _snapshotId: <BorderCanonicalGalleryFrame>[
                    (bytes: _png(), metadata: _snapshot().frames.single),
                  ],
                },
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Courbe douce générée'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('border-gallery-ground-0-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('border-gallery-placement-placement-1'),
        ),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNWidgets(2));
      expect(
        tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
        1,
      );
      expect(
        find.byKey(
          const ValueKey<String>('border-gallery-flip-placement-1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows an honest empty state when resolution failed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: BorderCanonicalGalleryCanvas(
            semanticsLabel: 'Cas invalide',
            geometry: BorderRegionGeometry(
              width: 1,
              height: 1,
              cells: const <bool>[true],
            ),
            tileSizePx: const GridSize(width: 16, height: 16),
            materialization: null,
            catalog: const ProjectBorderCatalog.empty(),
            framesBySnapshotId: const <String,
                List<BorderCanonicalGalleryFrame>>{},
          ),
        ),
      ),
    );

    expect(find.text('Ce cas ne peut pas encore être généré.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('plays every immutable candidate frame using its duration',
      (tester) async {
    final snapshot = _animatedSnapshot();
    final firstBytes = _png(red: 255, green: 0, blue: 0);
    final secondBytes = _png(red: 0, green: 0, blue: 255);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: BorderCanonicalGalleryCanvas(
              semanticsLabel: 'Animation candidate',
              geometry: BorderRegionGeometry(
                width: 2,
                height: 2,
                cells: const <bool>[true, true, false, true],
              ),
              tileSizePx: const GridSize(width: 16, height: 16),
              materialization: _materialization(),
              catalog: ProjectBorderCatalog(
                visualSnapshots: <BorderVisualSnapshot>[snapshot],
              ),
              framesBySnapshotId: <String, List<BorderCanonicalGalleryFrame>>{
                _snapshotId: <BorderCanonicalGalleryFrame>[
                  (bytes: firstBytes, metadata: snapshot.frames[0]),
                  (bytes: secondBytes, metadata: snapshot.frames[1]),
                ],
              },
            ),
          ),
        ),
      ),
    );

    expect(_displayedBytes(tester), orderedEquals(firstBytes));

    await tester.pump(const Duration(milliseconds: 40));
    expect(_displayedBytes(tester), orderedEquals(secondBytes));

    await tester.pump(const Duration(milliseconds: 60));
    expect(_displayedBytes(tester), orderedEquals(firstBytes));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

BorderMaterialization _materialization() => BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 1,
        components: BorderInputFingerprints(
          blueprint: _fingerprint,
          geometryAndSeed: _fingerprint,
          parameters: _fingerprint,
          overrides: _fingerprint,
          keepOutRegions: _fingerprint,
          mapContext: _fingerprint,
          visualSnapshots: _fingerprint,
        ),
        inputFingerprint: _fingerprint,
        outputFingerprint: _fingerprint,
      ),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 0,
          y: 0,
          visualSnapshotId: _snapshotId,
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: <BorderResolvedPlacement>[
        BorderResolvedPlacement(
          id: 'placement-1',
          slotKey: 'slot-1',
          primitiveId: 'rock',
          visualSnapshotId: _snapshotId,
          anchorCell: const GridPos(x: 1, y: 1),
          topLeftWorldPx: const BorderPixelPos(x: 16, y: 16),
          opaqueWorldBoundsPx:
              BorderPixelRect(x: 16, y: 16, width: 2, height: 2),
          transform: BorderSpriteTransform(quarterTurns: 1, flipX: true),
          drawBand: BorderDrawBand.structure,
          stableOrderKey: BorderStableOrderKey(
            drawBandIndex: 1,
            anchorRowMajor: 3,
            passIndex: 0,
            rank: 0,
            ordinalLocal: 0,
            slotKey: 'slot-1',
          ),
        ),
      ],
    );

BorderVisualSnapshot _snapshot() => BorderVisualSnapshot(
      id: _snapshotId,
      contentFingerprint: 'a' * 64,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath:
              'assets/borders/snapshots/${'a' * 64}/frame_0000.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 100,
        ),
      ],
    );

BorderVisualSnapshot _animatedSnapshot() => BorderVisualSnapshot(
      id: _snapshotId,
      contentFingerprint: 'a' * 64,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath:
              'assets/borders/snapshots/${'a' * 64}/frame_0000.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 40,
        ),
        BorderVisualFrameSnapshot(
          relativeAssetPath:
              'assets/borders/snapshots/${'a' * 64}/frame_0001.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 60,
        ),
      ],
    );

Uint8List _png({int red = 255, int green = 255, int blue = 255}) {
  final bitmap = image.Image(width: 2, height: 2);
  bitmap.setPixelRgba(0, 0, red, green, blue, 255);
  bitmap.setPixelRgba(1, 0, red, green, blue, 255);
  bitmap.setPixelRgba(0, 1, red, green, blue, 255);
  bitmap.setPixelRgba(1, 1, red, green, blue, 255);
  return Uint8List.fromList(image.encodePng(bitmap));
}

Uint8List _displayedBytes(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image).first).image as MemoryImage).bytes;

const _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fingerprint =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
