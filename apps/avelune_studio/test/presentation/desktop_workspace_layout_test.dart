import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/studio_resource_thumbnail.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resource_stress_fixture.dart';
import '../support/desktop_workspace_capture.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets(
    'real stress workspace stays usable across desktop sizes and diagnostics',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late ResourceStressFixture fixture;
      await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        fixture = await ResourceStressFixture.create();
      });
      final controller = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      StudioMapResources? resources;
      addTearDown(() async {
        controller.dispose();
        await resources?.dispose();
        await fixture.dispose();
      });
      final capture = GlobalKey();
      final loaded = Completer<void>();
      var textScale = 1.0;
      Widget app() => RepaintBoundary(
        key: capture,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: studioTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: MapWorkspaceScreen(
            controller: controller,
            loadVisuals: (session, manifest) async {
              try {
                resources = await StudioMapResources.load(session, manifest);
                loaded.complete();
                return resources!;
              } on Object catch (error, stack) {
                loaded.completeError(error, stack);
                rethrow;
              }
            },
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpWidget(app());
      await awaitDesktopIo(tester, loaded.future);
      await settleDesktopWorkspace(tester, resources!);
      expect(controller.active?.base.mapId, 'stress-a');
      expect(controller.error, isNull);
      expect(resources!.images.containsKey(fixture.lateAtlasId), isTrue);
      expect(resources!.diagnostics, isEmpty);
      final document = controller.active!;
      final selected = document.current.placedElements.first;
      document.selectedId = selected.id;
      document.stackPosition = selected.pos;
      controller.notify();
      await settleDesktopWorkspace(tester, resources!);

      for (final scale in [1.0, 1.5, 1.75]) {
        textScale = scale;
        for (final size in [
          const Size(1024, 640),
          const Size(1280, 800),
          const Size(1600, 1000),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(app());
          await settleDesktopWorkspace(tester, resources!);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Layout $size avec texte ×$scale',
          );
          final viewport = tester.getSize(find.byType(InteractiveViewer));
          expect(viewport.width, greaterThanOrEqualTo(size.width * .43));
          expect(
            viewport.height,
            greaterThanOrEqualTo(scale > 1.5 ? 128 : 160),
            reason: 'Viewport $size avec texte ×$scale',
          );
          if (size == const Size(1280, 800)) {
            expect(viewport.width, greaterThanOrEqualTo(560));
          }
          for (final label in [
            'Sélection',
            'Décors',
            'Terrains',
            'Bordures',
            'Environnements',
            'Zones',
            'Collisions',
            'Passages',
          ]) {
            expect(
              find.widgetWithText(StudioButton, label).hitTestable(),
              findsOneWidget,
            );
          }
          final dock = tester.getRect(find.byType(MapWorkspacePaletteDock));
          expect(dock.bottom, lessThanOrEqualTo(size.height));
          expect(
            dock.top,
            greaterThanOrEqualTo(
              tester.getRect(find.byType(InteractiveViewer)).bottom,
            ),
          );
          if (find.byType(MapLibraryNavigator).evaluate().isNotEmpty) {
            expect(
              tester.getRect(find.byType(MapLibraryNavigator)).right,
              lessThanOrEqualTo(
                tester.getRect(find.byType(InteractiveViewer)).left,
              ),
            );
          }
          expect(find.byKey(const ValueKey('Enregistrer')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('Enregistrer et tester')),
            findsOneWidget,
          );
          await captureDesktopWorkspace(
            tester,
            capture,
            'workspace-${size.width.toInt()}x${size.height.toInt()}-text${(scale * 100).round()}',
          );
        }
      }

      textScale = 1;
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(app());
      await settleDesktopWorkspace(tester, resources!);
      final decorThumbnails = tester
          .widgetList<StudioResourceThumbnail>(
            find.byType(StudioResourceThumbnail),
          )
          .where((widget) => widget.element != null);
      expect(decorThumbnails, isNotEmpty);
      expect(
        decorThumbnails.length,
        lessThan(fixture.manifest.elements.length),
      );
      expect(resources!.images.length, lessThan(fixture.atlasCount));
      final readsBefore = resources!.store.decoder.reads;
      await tester.tap(find.byTooltip('Changer la palette'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tuiles'));
      await settleDesktopWorkspace(tester, resources!);
      final tileThumbnails = tester
          .widgetList<StudioResourceThumbnail>(
            find.byType(StudioResourceThumbnail),
          )
          .where((widget) => widget.tile != null)
          .toList();
      expect(tileThumbnails, isNotEmpty);
      expect(
        tileThumbnails.every(
          (widget) => fixture.manifest.tilesets.any(
            (entry) => entry.id == widget.tile!.tilesetId,
          ),
        ),
        isTrue,
      );
      for (final widget in tileThumbnails) {
        expect(
          resources!
              .tileResourceIds(widget.tile!)
              .every(resources!.images.containsKey),
          isTrue,
        );
      }
      final visibleTileSources = tileThumbnails
          .map((widget) => widget.tile!.tilesetId)
          .toSet();
      expect(
        resources!.store.decoder.reads - readsBefore,
        lessThanOrEqualTo(visibleTileSources.length),
      );
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
      await captureDesktopWorkspace(
        tester,
        capture,
        'workspace-tile-thumbnails',
      );
      await tester.tap(find.byTooltip('Retour à la carte'));
      await tester.pumpAndSettle();

      await awaitDesktopIo(
        tester,
        controller.activate(
          fixture.manifest.maps.singleWhere(
            (entry) => entry.id == 'stress-errors',
          ),
        ),
      );
      await settleDesktopWorkspace(tester, resources!);
      expect(resources!.diagnostics, hasLength(200));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('resource-summary'))).height,
        lessThanOrEqualTo(40),
      );
      expect(
        tester.getSize(find.byType(InteractiveViewer)).height,
        greaterThanOrEqualTo(800 * .35),
      );
      await captureDesktopWorkspace(
        tester,
        capture,
        'workspace-200-diagnostics-compact',
      );
      await tester.tap(find.byKey(const ValueKey('resource-details')));
      await tester.pumpAndSettle();
      final rows = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('resource-row-'),
      );
      expect(rows.evaluate().length, lessThan(200));
      expect(
        find.byKey(const ValueKey('resource-diagnostics-list')),
        findsOneWidget,
      );
      await captureDesktopWorkspace(
        tester,
        capture,
        'workspace-200-diagnostics-details',
      );
      await tester.drag(
        find.byKey(const ValueKey('resource-diagnostics-list')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('Fermer les diagnostics')));
      await tester.pumpAndSettle();
      expect(controller.active?.base.mapId, 'stress-errors');
      expect(controller.documents['stress-a'], same(document));
      expect(document.selectedId, selected.id);
      await tester.runAsync(() async {
        await fixture.makeMissingAvailable();
      });
      await awaitDesktopIo(
        tester,
        resources!.retryResources([stressIncidentId(0)]),
      );
      await settleDesktopWorkspace(tester, resources!);
      expect(resources!.images.containsKey(stressIncidentId(0)), isTrue);
      expect(resources!.diagnostics, hasLength(199));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
