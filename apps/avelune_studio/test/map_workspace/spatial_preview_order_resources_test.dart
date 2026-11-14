import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'spatial_preview_order_resources_harness.dart';
import 'spatial_preview_order_resources_reads.dart';

void main() {
  testWidgets(
    'first and repeated order updates retain the loaded actor resources',
    (tester) async {
      final h = await tester.runAsync(PreviewOrderHarness.create);
      addTearDown(h!.dispose);
      final outside = Zone.current;
      await IOOverrides.runZoned(
        () async {
          await h.pump(tester);
          expect(h.visuals.profiles, hasLength(1));
          expect(h.reads.indexReads, 1);
          expect(h.reads.atmosphereReads, 1);
          expect(h.reads.rasterReads, 2);
          final before = h.reads.snapshot;
          final state = tester.state(find.byType(SpatialMapEditingViewport));
          for (var i = 0; i < 3; i++) {
            h.document.current = h.document.current.copyWith(
              layers: h.document.current.layers.reversed.toList(),
            );
            await h.pump(tester);
            expect(tester.state(find.byType(SpatialMapEditingViewport)), same(state));
            expect(h.visuals.profiles, hasLength(1));
            expect(h.reads.snapshot, before);
          }
          await tester.pumpWidget(const SizedBox());
        },
        createFile: (path) =>
            PreviewCountingFile(outside.run(() => File(path)), h.reads),
      );
    },
  );

  testWidgets(
    'texture catalog edits reload preview and atmosphere edits stay live',
    (tester) async {
      final h = await tester.runAsync(PreviewOrderHarness.create);
      addTearDown(h!.dispose);
      await h.pump(tester);
      final previous = h.visuals.lastRaster;
      h.project = h.project.copyWith(
        tilesets: [
          h.project.tilesets.first.copyWith(relativePath: 'new.png'),
          ...h.project.tilesets.skip(1),
        ],
      );
      await h.pump(tester);
      expect(h.visuals.profiles, hasLength(2));
      expect(h.visuals.lastRaster, isNot(previous));
      expect(h.visuals.disposals, 1);
      h.document.current = h.document.current.copyWith(
        layers: [
          (h.document.current.layers.first as SmartTileLayer).copyWith(
            presetId: 'fresh',
          ),
          ...h.document.current.layers.skip(1),
        ],
      );
      await tester.runAsync(
        () =>
            File('${h.root.path}/maps/a.json')
                .writeAsString(jsonEncode(h.document.current.toJson())),
      );
      await h.pump(tester);
      expect(h.visuals.profiles, hasLength(3));
      expect(h.visuals.loadedPaths, contains('${h.root.path}/fresh.png'));
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.controller.windowsLit, isFalse);
      h.document.atmosphere!.edit(
        h.document.atmosphere!.current.copyWith(
          windowsLit: true,
          fireflies: true,
        ),
      );
      await h.pump(tester);
      final edited = tester
          .widget<SpatialSceneView>(find.byType(SpatialSceneView))
          .controller;
      expect(edited.windowsLit, isTrue);
      expect(edited.fireflies, isFalse);
      expect(h.visuals.profiles, hasLength(3));
      h.document.current = h.document.current.copyWith(
        entities: [
          h.document.current.entities.single.copyWith(
            pos: const GridPos(x: 1, y: 1),
          ),
        ],
      );
      await h.pump(tester);
      expect(h.visuals.profiles, hasLength(4));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
