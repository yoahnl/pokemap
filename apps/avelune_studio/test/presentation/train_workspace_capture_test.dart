import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  final projectPath = Platform.environment['AVELUNE_PROJECT_COPY'];
  final mapId =
      Platform.environment['AVELUNE_CAPTURE_MAP_ID'] ?? 'hanazuki-gare';
  testWidgets(
    'real Train copy renders with demand resources and desktop panels',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = mapId == 'uwu'
          ? const Size(1660, 1080)
          : const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        final root = await Directory(projectPath!).resolveSymbolicLinks();
        expect(root, contains('/work/train-copy'));
        final session = ProjectSession(
          sessionId: 'train-capture',
          name: 'Train · copie isolée',
          directoryPath: root,
        );
        final controller = MapWorkspaceController(
          session,
          LocalMapWorkspaceAdapter(),
        );
        StudioMapResources? resources;
        final loaded = Completer<void>();
        final capture = GlobalKey();
        var coldReads = -1;
        try {
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: studioTheme(),
                home: MapWorkspaceScreen(
                  controller: controller,
                  loadVisuals: (session, manifest) async {
                    try {
                      resources = await StudioMapResources.load(
                        session,
                        manifest,
                      );
                      coldReads = resources!.store.decoder.reads;
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
            ),
          );
          await _awaitWhilePumping(tester, loaded.future);
          expect(coldReads, 0);
          final manifest = controller.project!;
          final entry = manifest.maps.singleWhere((entry) => entry.id == mapId);
          await _awaitWhilePumping(tester, controller.activate(entry));
          await _settle(tester, resources!);
          expect(controller.error, isNull);
          expect(controller.active!.base.mapId, entry.id);
          if (controller.active!.current.layers.whereType<BorderLayer>().any(
            (layer) => layer.isVisible && layer.content.features.isNotEmpty,
          )) {
            expect(resources!.borderPreviewReady, isTrue);
            expect(
              find.byKey(const ValueKey('map-border-notice')),
              findsNothing,
            );
          }
          expect(resources!.images, isNotEmpty);
          expect(
            resources!.store.decoder.decodes,
            lessThan(manifest.tilesets.length),
          );
          expect(
            tester.getSize(find.byType(InteractiveViewer)).width,
            greaterThanOrEqualTo(640),
          );
          expect(
            tester.getSize(find.byType(InteractiveViewer)).height,
            greaterThanOrEqualTo(480),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('Recentrer')));
          await _settle(tester, resources!);
          final document = controller.active!;
          final commands = MapEditingCommands(document, manifest);
          for (final element in document.current.placedElements) {
            final stack = commands.stack(element.pos);
            if (stack.length < 2) continue;
            document.selectedId = stack.last.id;
            document.stackPosition = element.pos;
            break;
          }
          if (document.selectedId == null &&
              document.current.placedElements.isNotEmpty) {
            final element = document.current.placedElements.first;
            document.selectedId = element.id;
            document.stackPosition = element.pos;
          }
          controller.notify();
          await _settle(tester, resources!);
          expect(document.dirty, isFalse);
          expect(find.text('Empilement ici'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _capture(capture, 'train-$mapId-carte-palette-empilement');
          final diagnostics = resources!.diagnostics;
          if (diagnostics.isNotEmpty) {
            await tester.tap(find.byKey(const ValueKey('resource-details')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await _capture(capture, 'train-$mapId-diagnostics');
            await tester.tap(
              find.byKey(const ValueKey('Fermer les diagnostics')),
            );
            await tester.pumpAndSettle();
          }
          final summary = {
            'proof':
                'Flutter desktop widgets offscreen, not native macOS input',
            'projectCopy': root,
            'map': entry.id,
            'manifestAtlases': manifest.tilesets.length,
            'manifestElements': manifest.elements.length,
            'readsAtMetadataOpen': coldReads,
            'reads': resources!.store.decoder.reads,
            'decodes': resources!.store.decoder.decodes,
            'residentDecodedBytes': resources!.decodedBytes,
            'estimatedPeakTransientBytes':
                resources!.store.decoder.peakTransientBytes,
            'activeResourceCount': resources!.activeResourceIds.length,
            'loadedResourceIds': resources!.images.keys.toList(),
            'selectedElement': document.selectedId,
            'stackCount': document.stackPosition == null
                ? 0
                : commands.stack(document.stackPosition!).length,
            'dirty': document.dirty,
            'diagnostics': [
              for (final item in diagnostics)
                {
                  'id': item.resourceId,
                  'name': item.name,
                  'cause': item.cause.name,
                  'detail': item.detail,
                },
            ],
          };
          final directory = Platform.environment['AVELUNE_CAPTURE_DIR'];
          if (directory != null) {
            await Directory(directory).create(recursive: true);
            await File('$directory/train-resource-stats.json').writeAsString(
              const JsonEncoder.withIndent('  ').convert(summary),
            );
          }
          debugPrint(jsonEncode(summary));
        } finally {
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
          await resources?.dispose();
        }
      });
    },
    skip: projectPath == null,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _settle(WidgetTester tester, StudioMapResources resources) async {
  for (var index = 0; index < 4; index++) {
    await tester.pump();
    await _awaitWhilePumping(tester, resources.settled);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

Future<void> _awaitWhilePumping(
  WidgetTester tester,
  Future<void> future,
) async {
  var complete = false;
  Object? failure;
  future.then(
    (_) => complete = true,
    onError: (Object error) {
      failure = error;
      complete = true;
    },
  );
  final watch = Stopwatch()..start();
  while (!complete && watch.elapsed < const Duration(seconds: 60)) {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  if (failure != null) throw failure!;
  expect(
    complete,
    isTrue,
    reason: 'Les E/S réelles progressent entre les frames Flutter',
  );
}

Future<void> _capture(GlobalKey key, String name) async {
  final directory = Platform.environment['AVELUNE_CAPTURE_DIR'];
  if (directory == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}
