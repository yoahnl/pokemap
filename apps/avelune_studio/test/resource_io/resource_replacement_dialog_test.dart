import 'dart:io';
import 'dart:typed_data';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:avelune_studio/presentation/features/resources/resource_replacement_dialog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_asset_preview.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../../tool/example_project_assets.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/uwu4_resource_host.dart';
import 'package:image/image.dart' as image;
import 'resource_fixture.dart';

void main() {
  const item = ResourceItem(
    id: 'planche',
    name: 'Planche étudiée',
    kind: ResourceKind.images,
    tileset: ProjectTilesetEntry(
      id: 'planche',
      name: 'Planche étudiée',
      relativePath: 'assets/planche.png',
    ),
  );
  for (final size in [
    const Size(1536, 1024),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets('replacement confirmation remains reachable at $size', (
      tester,
    ) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final captureKey = GlobalKey();
      final bytes = Uint8List.fromList(exampleAtlasPng());
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          builder: (context, child) => RepaintBoundary(
            key: captureKey,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.height == 640 ? 1.5 : 1),
              ),
              child: child!,
            ),
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showResourceReplacement(
                context,
                item: item,
                before: bytes,
                candidate: bytes,
                width: 160,
                height: 64,
                projectTileWidth: 16,
                projectTileHeight: 16,
                impacts: const ['Décor · Arbre'],
                noChange: false,
                canApply: () => true,
                apply: () async {
                  calls++;
                  return null;
                },
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(StudioAssetPreview), findsNWidgets(2));
      expect(find.text('Actuellement'), findsOneWidget);
      expect(find.text('Après remplacement'), findsOneWidget);
      await captureM3Widget(
        tester,
        captureKey,
        'uwu4-widget-replacement-${size.width.toInt()}',
      );
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('resource-management-save')),
            )
            .onPressed,
        isNull,
      );
      final checkbox = find.byKey(
        const ValueKey('resource-replacement-confirm'),
      );
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      final save = find.byKey(const ValueKey('resource-management-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'an interrupted replacement keeps its publication and is re-read without replay',
    (tester) async {
      var fail = true;
      late ResourceFixture resources;
      late File candidate;
      late Uint8List candidateBytes;
      final host = await openUwU4ResourceHost(
        tester,
        configure: (fixture) async {
          resources = fixture;
          final pixels = image.Image(width: 64, height: 48);
          image.fill(pixels, color: image.ColorRgba8(220, 80, 30, 255));
          candidateBytes = Uint8List.fromList(image.encodePng(pixels));
          candidate = File('${fixture.root.path}/candidate.png');
          await candidate.writeAsBytes(candidateBytes);
        },
        adapter: (fixture) {
          final adapter = LocalResourceAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
            beforeReconciliation: () async {
              if (fail) throw StateError('Injected interface refresh failure');
            },
          );
          addTearDown(adapter.dispose);
          return adapter;
        },
        imagePicker: () async => PickedResourceImage(
          candidate.path,
          'Candidate',
          candidateBytes,
          64,
          48,
        ),
      );
      final tileset = (await host.reopen()).tilesets.single;
      await host.family(ResourceKind.images);
      await host.action('tileset:${tileset.id}', 'Remplacer l’image source…');
      await host.tap('resource-replacement-confirm');
      await host.tap('resource-management-save');
      expect(find.textContaining('Publication effectuée'), findsOneWidget);
      expect(find.textContaining('Relire le résultat'), findsWidgets);
      final published = (await host.reopen()).tilesets.single;
      expect(published.id, tileset.id);
      Future<Map<String, List<int>>> files() async => {
        for (final entity in resources.root.listSync(recursive: true))
          if (entity is File) entity.path: await entity.readAsBytes(),
      };
      final publishedFiles = (await tester.runAsync(files))!;
      expect(
        await tester.runAsync(
          () =>
              File('${resources.root.path}/${published.relativePath}')
                  .readAsBytes(),
        ),
        candidateBytes,
      );
      await host.tap('resource-management-cancel');
      expect(
        find.byKey(const ValueKey('resource-retry-reconciliation')),
        findsOneWidget,
      );
      fail = false;
      await host.tap('resource-retry-reconciliation');
      expect(
        find.byKey(const ValueKey('resource-retry-reconciliation')),
        findsNothing,
      );
      expect(host.navigation.pendingReceipt, isNull);
      expect(await tester.runAsync(files), publishedFiles);
      expect((await host.reopen()).tilesets.single, published);
    },
  );
}
