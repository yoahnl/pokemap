import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main() {
  final env = Platform.environment;
  testWidgets(
    'published Kanto opens renders edits saves and cold reopens in Studio',
    (tester) async {
      expect(Platform.isMacOS, isTrue, reason: 'The QA clone requires APFS.');
      final roots = (await tester.runAsync(
        () async => (
          master: await _directory(
            env['AVELUNE_KANTO_STUDIO_PUBLISHED_PROJECT'],
          ),
          qa: await _directory(env['AVELUNE_KANTO_STUDIO_QA_PARENT']),
        ),
      ))!;
      final master = roots.master;
      expect(p.basename(roots.qa.path), 'QA');
      expect(p.basename(p.dirname(roots.qa.path)), 'execution');
      expect(p.isWithin(master.path, roots.qa.path), isFalse);
      expect(p.isWithin(roots.qa.path, master.path), isFalse);
      expect(master.path, isNot(roots.qa.path));
      final routeId = _required(env, 'AVELUNE_KANTO_STUDIO_ROUTE9_ID');
      final map007Id = _required(env, 'AVELUNE_KANTO_STUDIO_MAP007_ID');
      final centerId = _required(env, 'AVELUNE_KANTO_STUDIO_CENTER_ID');
      expect({routeId, map007Id, centerId}, hasLength(3));
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = Stopwatch()..start();
      final phases = <Map<String, Object?>>[];
      void checkpoint(String phase) {
        phases.add({'phase': phase, 'elapsedMs': clock.elapsedMilliseconds});
        debugPrint('Kanto Studio QA $phase ${clock.elapsedMilliseconds} ms');
      }

      final masterBefore = (await tester.runAsync(() => _fingerprint(master)))!;
      checkpoint('masterAttested');
      final run = (await tester.runAsync(
        () => roots.qa.createTemp('kanto-studio-headless-'),
      ))!;
      final clone = Directory(p.join(run.path, 'project'));
      _StudioSession? opened;
      final visits = <Map<String, Object?>>[];
      final screenshots = <Map<String, Object?>>[];
      final edits = <Map<String, Object?>>[];
      var lifecycleComplete = false;
      String? originalName;
      var restored = false;
      try {
        final copied = (await tester.runAsync(
          () => Process.run('/bin/cp', ['-cR', master.path, clone.path]),
        ))!;
        expect(copied.exitCode, 0, reason: '${copied.stderr}');
        expect(await tester.runAsync(() => _fingerprint(clone)), masterBefore);
        checkpoint('apfsCloneAttested');
        final firstOpen = Stopwatch()..start();
        opened = (await tester.runAsync(() => _StudioSession.open(clone)))!;
        checkpoint('studioSessionOpened:${firstOpen.elapsedMilliseconds}ms');
        expect(opened.controller.project!.maps, hasLength(383));
        final catalogIds = opened.controller.project!.maps
            .map((entry) => entry.id)
            .toSet();
        for (final id in [routeId, map007Id, centerId]) {
          final entry = opened.controller.project!.maps.singleWhere(
            (entry) => entry.id == id,
          );
          if (id == routeId) {
            expect(
              entry.name.trim(),
              matches(RegExp(r'^Route\s+0?9$', caseSensitive: false)),
            );
            originalName = entry.name;
          }
          if (id == map007Id) {
            expect(entry.name, r"\PN's House");
          }
          if (id == centerId) {
            expect(entry.name.toLowerCase(), contains('cerulean'));
            expect(entry.name.toLowerCase(), contains('center'));
          }
          final watch = Stopwatch()..start();
          await tester.runAsync(() => opened!.controller.activate(entry));
          expect(opened.controller.error, isNull);
          final map = opened.controller.active!.current;
          expect(map.id, id);
          expect(map.size.width, greaterThan(0));
          expect(map.size.height, greaterThan(0));
          visits.add({
            'mapId': id,
            'name': map.name,
            'width': map.size.width,
            'height': map.size.height,
            'openMs': watch.elapsedMilliseconds,
          });
          checkpoint('opened:${entry.name}');
        }
        final route = opened.controller.project!.maps.singleWhere(
          (entry) => entry.id == routeId,
        );
        await tester.runAsync(() => opened!.controller.activate(route));
        final originalMap = opened.controller.active!.current;
        screenshots.add(
          await _capture(
            tester,
            opened,
            File(p.join(run.path, 'route9-before.png')),
          ),
        );
        checkpoint('routeRendered');
        await tester.runAsync(() => opened!.controller.materializeProject());
        final renamed = (await tester.runAsync(
          () => opened!.controller.mutateCatalog('map.update_metadata', {
            'mapId': routeId,
            'name': '$originalName — contrôle QA',
          }),
        ))!;
        expect(renamed.published, isTrue, reason: renamed.error);
        expect(renamed.integrated, isTrue, reason: renamed.error);
        expect(renamed.receipt, isNotNull);
        expect(renamed.receipt!.changedPaths, isNotEmpty);
        expect(
          renamed.receipt!.revision,
          isNot(renamed.receipt!.beforeRevision),
        );
        edits.add({
          'actionId': 'map.update_metadata',
          'mapId': routeId,
          'beforeRevision': renamed.receipt!.beforeRevision,
          'afterRevision': renamed.receipt!.revision,
          'changedPaths': renamed.receipt!.changedPaths,
        });
        final saved = opened.controller.active!.saved;
        expect(saved.name, '$originalName — contrôle QA');
        expect(saved.copyWith(name: originalName!), originalMap);
        expect(opened.controller.dirty, isFalse);
        checkpoint('canonicalRenameSaved');
        await tester.runAsync(opened.close);
        opened = null;
        opened = (await tester.runAsync(() => _StudioSession.open(clone)))!;
        expect(
          opened.controller.project!.maps.map((entry) => entry.id).toSet(),
          catalogIds,
        );
        final renamedEntry = opened.controller.project!.maps.singleWhere(
          (entry) => entry.id == routeId,
        );
        expect(renamedEntry.name, saved.name);
        await tester.runAsync(() => opened!.controller.activate(renamedEntry));
        expect(opened.controller.error, isNull);
        expect(opened.controller.active!.current, saved);
        expect(opened.controller.active!.dirty, isFalse);
        screenshots.add(
          await _capture(
            tester,
            opened,
            File(p.join(run.path, 'route9-reopened.png')),
          ),
        );
        checkpoint('coldReopenRendered');
        await tester.runAsync(() => opened!.controller.materializeProject());
        final restoration = (await tester.runAsync(
          () => opened!.controller.mutateCatalog('map.update_metadata', {
            'mapId': routeId,
            'name': originalName,
          }),
        ))!;
        expect(restoration.integrated, isTrue, reason: restoration.error);
        expect(
          restoration.receipt!.revision,
          isNot(restoration.receipt!.beforeRevision),
        );
        edits.add({
          'actionId': 'map.update_metadata',
          'mapId': routeId,
          'beforeRevision': restoration.receipt!.beforeRevision,
          'afterRevision': restoration.receipt!.revision,
          'changedPaths': restoration.receipt!.changedPaths,
        });
        await tester.runAsync(opened.close);
        opened = null;
        opened = (await tester.runAsync(() => _StudioSession.open(clone)))!;
        expect(
          opened.controller.project!.maps.map((entry) => entry.id).toSet(),
          catalogIds,
        );
        final restoredEntry = opened.controller.project!.maps.singleWhere(
          (entry) => entry.id == routeId,
        );
        expect(restoredEntry.name, originalName);
        await tester.runAsync(() => opened!.controller.activate(restoredEntry));
        expect(opened.controller.error, isNull);
        expect(opened.controller.active!.current.name, originalName);
        expect(opened.controller.active!.current, originalMap);
        restored = true;
        checkpoint('originalNameColdReopened');
        expect(tester.takeException(), isNull);
        lifecycleComplete = true;
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        if (opened != null) await tester.runAsync(opened.close);
        final masterAfter = (await tester.runAsync(
          () => _fingerprint(master),
        ))!;
        expect(
          masterAfter,
          masterBefore,
          reason: 'The master must remain byte-identical.',
        );
        await tester.runAsync(
          () => File(p.join(run.path, 'studio-lifecycle.json')).writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'kind': 'fullKantoStudioHeadlessLifecycle',
              'schemaVersion': 1,
              'masterPath': master.path,
              'qaProjectPath': clone.path,
              'masterBefore': masterBefore,
              'masterAfter': masterAfter,
              'fingerprintPolicy':
                  'sortedRelativePathsKindsSizesAndPerFileSha256',
              'catalogMapCountExpected': 383,
              'visits': visits,
              'screenshots': screenshots,
              'editedMapId': routeId,
              'originalName': originalName,
              'originalNameRestored': restored,
              'canonicalEdits': edits,
              'phases': phases,
              'elapsedMs': clock.elapsedMilliseconds,
              'studioHeadlessLifecycleCertified': lifecycleComplete,
              'macosGuiObserved': false,
              'playerCertified': false,
            }),
          ),
        );
        debugPrint('Kanto Studio QA evidence: ${run.path}');
      }
    },
    skip: env['AVELUNE_KANTO_STUDIO_LIFECYCLE'] != '1',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

String _required(Map<String, String> environment, String name) {
  final value = environment[name];
  if (value == null || value.trim().isEmpty) {
    throw StateError('Missing opt-in parameter $name');
  }
  return value;
}

Future<Directory> _directory(String? input) async {
  if (input == null || !p.isAbsolute(input) || p.normalize(input) != input) {
    throw StateError('An explicit absolute canonical directory is required.');
  }
  final directory = Directory(input);
  if (await directory.resolveSymbolicLinks() != input ||
      !await directory.exists()) {
    throw StateError('The directory must exist without a symlink alias.');
  }
  return directory;
}

Future<String> _fingerprint(Directory directory) async {
  final entries = await directory
      .list(recursive: true, followLinks: false)
      .toList();
  entries.sort((left, right) => left.path.compareTo(right.path));
  final rows = <Map<String, Object?>>[];
  for (final entry in entries) {
    final path = p.relative(entry.path, from: directory.path);
    if (entry is File) {
      final bytes = await entry.readAsBytes();
      rows.add({
        'path': path,
        'kind': 'file',
        'bytes': bytes.length,
        'sha256': narrativeEventBytesFingerprint(bytes),
      });
    } else if (entry is Directory) {
      rows.add({'path': path, 'kind': 'directory'});
    } else {
      throw StateError('Unsupported project entry: $path');
    }
  }
  return narrativeEventBytesFingerprint(utf8.encode(jsonEncode(rows)));
}

class _StudioSession {
  _StudioSession(this.adapter, this.session, this.controller);
  final LocalProjectSessionAdapter adapter;
  final ProjectSession session;
  final MapWorkspaceController controller;
  static Future<_StudioSession> open(Directory directory) async {
    final adapter = LocalProjectSessionAdapter();
    final session = await adapter.open(directory.path);
    final port = LocalMapWorkspaceAdapter();
    final controller = MapWorkspaceController(
      session,
      port,
      catalogPort: LocalMapCatalogAdapter(port),
    );
    try {
      await controller.initialize();
      if (controller.error != null || controller.project == null) {
        throw StateError('Studio open failed: ${controller.error}');
      }
      return _StudioSession(adapter, session, controller);
    } catch (_) {
      controller.dispose();
      await adapter.close(session);
      rethrow;
    }
  }

  Future<void> close() async {
    controller.dispose();
    await adapter.close(session);
  }
}

Future<Map<String, Object?>> _capture(
  WidgetTester tester,
  _StudioSession opened,
  File destination,
) async {
  final controller = opened.controller;
  final watch = Stopwatch()..start();
  void trace(String phase) =>
      debugPrint('Kanto Studio capture $phase ${watch.elapsedMilliseconds} ms');
  trace('loadStart');
  final visuals = (await tester.runAsync(
    () => StudioMapResources.load(opened.session, controller.project!),
  ))!;
  trace('loadComplete');
  final key = GlobalKey();
  try {
    await tester.runAsync(() async {
      visuals.setActiveMap(controller.active!.current);
    });
    trace('resourcesRequested');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: studioTheme(),
        home: RepaintBoundary(
          key: key,
          child: MapWorkspaceScreen(
            controller: controller,
            loadVisuals: (_, _) async => visuals,
            runtimeBuilder: (_, _, _) => const SizedBox.shrink(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      ),
    );
    trace('widgetMounted');
    var settled = false;
    Object? settleError;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() async {
      unawaited(
        Future.wait([visuals.store.settled, visuals.borderPreview.settled])
            .then(
              (_) {
                settled = true;
              },
              onError: (Object error, StackTrace stack) {
                settleError = error;
                settled = true;
              },
            ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    final settling = Stopwatch()..start();
    while (!settled && settling.elapsed < const Duration(seconds: 45)) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    trace(
      'resourcesSettled:${visuals.images.length}images:${visuals.store.decoder.reads}reads',
    );
    expect(
      settled,
      isTrue,
      reason: 'Studio image loading did not settle within45seconds.',
    );
    expect(settleError, isNull);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(StudioMapVisual), findsOneWidget);
    expect(
      tester.widget<StudioMapVisual>(find.byType(StudioMapVisual)).map,
      controller.active!.current,
    );
    expect(visuals.images, isNotEmpty);
    expect(visuals.diagnostics, isEmpty);
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    trace('rasterStart');
    return (await tester.runAsync(() async {
      final raster = await boundary.toImage(pixelRatio: 1);
      try {
        final png = (await raster.toByteData(format: ui.ImageByteFormat.png))!;
        final bytes = png.buffer.asUint8List();
        await destination.writeAsBytes(bytes);
        trace('rasterSaved');
        return <String, Object?>{
          'path': destination.path,
          'width': raster.width,
          'height': raster.height,
          'sha256': narrativeEventBytesFingerprint(bytes),
          'loadedImageCount': visuals.images.length,
          'mapId': controller.active!.current.id,
          'headless': true,
        };
      } finally {
        raster.dispose();
      }
    }))!;
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(visuals.dispose);
  }
}
