import 'dart:io';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm2_ui_fixture.dart';
import 'm3_story_fixture.dart';
import 'map_workspace_fixture.dart' show WorkspaceTestVisuals;
import 'ui05_narrative_fixture.dart';
import 'ui08_workspace_harness.dart';
import 'ui12_widget_world_port.dart';

class MapHostFixture {
  MapHostFixture._(this.tester, this.source, this.maps, this.visuals);
  final WidgetTester tester;
  final M3StoryFixture source;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals visuals;
  late final StudioGameExportController gameExport;

  EditableMapDocument get document => maps.active!;

  static Future<MapHostFixture> open(
    WidgetTester tester, {
    bool events = true,
    NarrativePort Function(NarrativePort port)? narrative,
    Future<void> Function(M3StoryFixture source)? prepareSource,
    Future<File?> Function(String)? gameExportPicker,
    AssetBundle? assetBundle,
    GlobalKey? captureKey,
    StudioHomeNavigation? home,
    Future<void> Function()? onClose,
    void Function(Future<bool> Function()?)? registerExitGuard,
    StudioGameExportController Function(M3StoryFixture)? createGameExport,
    Size size = const Size(1536, 1024),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (source, maps, mapPort) = (await tester.runAsync(() async {
      final source = await M3StoryFixture.create();
      if (prepareSource != null) await prepareSource(source);
      final mapPort = Ui08MapPort(source.maps, tester);
      final maps = MapWorkspaceController(source.session, mapPort);
      await maps.initialize();
      return (source, maps, mapPort);
    }))!;
    final visuals = WorkspaceTestVisuals();
    mapPort.interactive = true;
    final fixture = MapHostFixture._(tester, source, maps, visuals);
    final gameExport =
        createGameExport?.call(source) ??
        StudioGameExportController(
          projectRoot: source.directory,
          projectName: source.session.name,
        );
    fixture.gameExport = gameExport;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      gameExport.dispose();
      maps.dispose();
      await tester.runAsync(() async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
      });
    });
    final narrativePort = Ui05NarrativePort(
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      tester,
    );
    final app = MaterialApp(
      theme: studioTheme(),
      home: MapWorkspaceScreen(
        controller: maps,
        home: home,
        gameExport: gameExport,
        gameExportPicker: (suggested) async {
          final file = await gameExportPicker?.call(suggested);
          return file == null
              ? null
              : StudioGameExportDestination(
                  file.path,
                  exists: await file.exists(),
                );
        },
        loadVisuals: (_, _) async => visuals,
        narrativePort: narrative?.call(narrativePort) ?? narrativePort,
        eventPort: events
            ? Ui08EventPort(
                LocalEventAdapter(
                  session: source.session,
                  mapAdapter: source.maps,
                ),
                tester,
              )
            : null,
        worldPort: Ui12WidgetWorldPort(
          LocalWorldAdapter(session: source.session, mapAdapter: source.maps),
          tester,
        ),
        runtimeBuilder: (_, _, _) => const SizedBox(),
        onClose: onClose ?? () async {},
        registerExitGuard: registerExitGuard ?? (_) {},
      ),
    );
    final rooted = assetBundle == null
        ? app
        : DefaultAssetBundle(bundle: assetBundle, child: app);
    await tester.pumpWidget(
      captureKey == null
          ? rooted
          : RepaintBoundary(key: captureKey, child: rooted),
    );
    await pumpIo(tester);
    return fixture;
  }

  Finder get menu => find.byKey(const ValueKey('map-context-menu'));
  Finder inMenu(String label) =>
      find.descendant(of: menu, matching: find.text(label));

  Offset cellAt(int x, int y) {
    final rect = tester.getRect(find.byKey(const ValueKey('map-canvas')));
    final size = document.current.size;
    return rect.topLeft +
        Offset(
          (x + .5) * rect.width / size.width,
          (y + .5) * rect.height / size.height,
        );
  }

  Future<void> tapCell(int x, int y) async {
    await tester.tapAt(cellAt(x, y));
    await pumpIo(tester, frames: 4);
  }

  Future<void> rightClick(int x, int y) async {
    final gesture = await tester.startGesture(
      cellAt(x, y),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await pumpIo(tester, frames: 4);
  }

  Future<void> choose(String label) async {
    await tester.tap(inMenu(label));
    await pumpIo(tester, frames: 6);
  }

  Future<TestGesture> press(int x, int y) async {
    final gesture = await tester.startGesture(cellAt(x, y));
    await tester.pump();
    return gesture;
  }

  Future<void> drag(int fromX, int fromY, int toX, int toY) async {
    final gesture = await press(fromX, fromY);
    await gesture.moveTo(cellAt(toX, toY));
    await tester.pump();
    await gesture.up();
    await pumpIo(tester, frames: 4);
  }

  Future<void> key(LogicalKeyboardKey key, {bool shift = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await pumpIo(tester, frames: 4);
  }

  Future<void> switchMap(String name) async {
    final mapId = document.base.mapId;
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is DropdownButton<String> && widget.value == mapId,
      ),
    );
    await pumpIo(tester, frames: 6);
    await tester.tap(find.text(name).last);
    await pumpIo(tester, frames: 15);
  }

  Matrix4 get transform => tester
      .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
      .transformationController!
      .value
      .clone();

  Future<void> zoomAt(int x, int y, double delta) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(cellAt(x, y)));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, delta)));
    await pumpIo(tester, frames: 4);
  }

  Future<void> go(String destination) async {
    final target = find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip(destination),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(target);
    await pumpIo(tester, frames: 12);
  }

  Future<void> enter(String label) async {
    final target = find.text(label).first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await pumpIo(tester, frames: 15);
  }

  Future<NarrativeWorkspaceController> narrativeOwner() async {
    await go('Histoire');
    final owner = tester
        .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
        .controller;
    await go('Carte');
    return owner;
  }

  Future<WorldWorkspaceController> worldOwner() async {
    await go('Histoire');
    await enter('États et règles du monde');
    final owner = tester
        .widget<WorldWorkspacePage>(find.byType(WorldWorkspacePage))
        .controller;
    for (var i = 0; i < 40 && !owner.initialized; i++) {
      await pumpIo(tester, frames: 3);
    }
    await go('Carte');
    return owner;
  }

  Future<EventWorkspaceController> eventOwner() async {
    await go('Histoire');
    await enter('Événements');
    final owner = tester
        .widget<EventWorkspacePage>(find.byType(EventWorkspacePage))
        .controller;
    final ready = owner.prepare();
    await pumpIo(tester, frames: 20);
    expect(await ready, isTrue, reason: owner.error);
    await go('Carte');
    return owner;
  }

  Future<Map<String, List<int>>> disk() async => (await tester.runAsync(
    () async => {
      for (final file
          in await source.directory
              .list(recursive: true)
              .where(
                (file) => file is File && !file.path.contains('/.pokemap/'),
              )
              .cast<File>()
              .toList())
        file.path.substring(source.directory.path.length): await file
            .readAsBytes(),
    },
  ))!;
}
