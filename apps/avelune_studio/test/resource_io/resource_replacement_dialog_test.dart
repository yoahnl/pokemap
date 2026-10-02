import 'dart:typed_data';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
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
}
