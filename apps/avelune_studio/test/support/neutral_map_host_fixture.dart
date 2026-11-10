import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/narrative/application/narrative_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm3_story_fixture.dart';
import 'map_workspace_fixture.dart' show WorkspaceTestVisuals;

class NeutralMapHostFixture {
  NeutralMapHostFixture._(this.tester, this.maps, [this._source]);

  final WidgetTester tester;
  final M3StoryFixture? _source;
  M3StoryFixture get source => _source!;
  final MapWorkspaceController maps;
  late final WorkspaceSessionControllers sessions;
  late final MapEditingInputSession input;
  final _views = <String, MapEditingViewportSession>{};
  StateSetter? _render;
  Future<void>? _pendingIo;
  bool _active = true;
  bool _ownsMaps = false;
  bool _disposed = false;
  Future<void>? _disposal;

  EditableMapDocument get document => maps.active!;
  MapEditingViewportSession get nativeView =>
      _views.putIfAbsent(document.base.mapId, MapEditingViewportSession.new);

  void _changed() {
    if (_active) _render?.call(() {});
  }

  static Future<NeutralMapHostFixture> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() async {
      final root = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await root.create(recursive: true);
      final source = await M3StoryFixture.create(parent: root);
      final maps = MapWorkspaceController(source.session, source.maps);
      await maps.initialize();
      return NeutralMapHostFixture._(tester, maps, source);
    }))!;
    return fixture._mount(
      mapAdapter: fixture.source.maps,
      withNarrative: true,
      ownsMaps: true,
    );
  }

  static Future<NeutralMapHostFixture> fromController(
    WidgetTester tester,
    MapWorkspaceController maps, {
    LocalMapWorkspaceAdapter? mapAdapter,
    bool withNarrative = false,
    MapWorkspaceVisuals? visuals,
    GlobalKey? captureKey,
  }) => NeutralMapHostFixture._(tester, maps)._mount(
    mapAdapter: mapAdapter,
    withNarrative: withNarrative,
    ownsMaps: false,
    providedVisuals: visuals,
    captureKey: captureKey,
  );

  Future<NeutralMapHostFixture> _mount({
    required LocalMapWorkspaceAdapter? mapAdapter,
    required bool withNarrative,
    required bool ownsMaps,
    MapWorkspaceVisuals? providedVisuals,
    GlobalKey? captureKey,
  }) async {
    final fixture = this;
    _ownsMaps = ownsMaps;
    final visuals = providedVisuals ?? WorkspaceTestVisuals();
    final sessions = WorkspaceSessionControllers(
      controller: maps,
      changed: fixture._changed,
      visualCatalogChanged: (_) {},
      flushEditors: () async => true,
      eventPort: !withNarrative || mapAdapter == null
          ? null
          : LocalEventAdapter(session: maps.session, mapAdapter: mapAdapter),
      worldPort: !withNarrative || mapAdapter == null
          ? null
          : LocalWorldAdapter(session: maps.session, mapAdapter: mapAdapter),
    );
    fixture.sessions = sessions;
    fixture.input = MapEditingInputSession(
      controller: maps,
      view: () => fixture.nativeView,
      referenceGuard: sessions.draftReferences.guard,
    );
    maps.addListener(fixture._changed);
    addTearDown(fixture.dispose);
    final loaded = !withNarrative && maps.project != null
        ? LoadedWorkspaceSession(
            workspace: maps,
            visuals: visuals,
            resources: null,
            narrative: null,
            historyGuard: null,
            changed: fixture._changed,
          )
        : await tester.runAsync(
            () => loadWorkspaceSession(
              workspace: maps,
              loadVisuals: (_, _) async => visuals,
              narrativePort: !withNarrative || mapAdapter == null
                  ? null
                  : LocalNarrativeAdapter(
                      session: maps.session,
                      mapAdapter: mapAdapter,
                    ),
              isActive: () => fixture._active,
              changed: fixture._changed,
              onUse: (_) async {},
            ),
          );
    expect(loaded, isNotNull);
    sessions.initializeLoaded(loaded!);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, update) {
              fixture._render = update;
              if (maps.active == null) return const SizedBox();
              final surface = MapEditingSurface(
                controller: maps,
                visuals: visuals,
                view: fixture.nativeView,
                input: fixture.input,
                onChanged: fixture._changed,
                onZoneDrawn: sessions.narrative == null
                    ? null
                    : (area) {
                        fixture._pendingIo = tester.runAsync(
                          () => openNarrativeZone(sessions.narrative!, area),
                        );
                      },
              );
              return captureKey == null
                  ? surface
                  : RepaintBoundary(key: captureKey, child: surface);
            },
          ),
        ),
      ),
    );
    await fixture.pump();
    return fixture;
  }

  Future<void> dispose() {
    if (_disposed) return Future.value();
    return _disposal ??= _dispose().whenComplete(() => _disposed = true);
  }

  Future<void> _dispose() async {
    _active = false;
    _render = null;
    await _pendingIo;
    await tester.pumpWidget(const SizedBox());
    maps.removeListener(_changed);
    input.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    await _releaseSessions();
    if (_ownsMaps) maps.dispose();
    final source = _source;
    if (source != null) {
      await tester.runAsync(() async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
      });
    }
  }

  Future<void> _releaseSessions() async {
    var finished = false;
    Object? failure;
    StackTrace? failureStack;
    final elapsed = Stopwatch()..start();
    sessions.dispose().then(
      (_) {
        finished = true;
      },
      onError: (Object error, StackTrace stack) {
        failure = error;
        failureStack = stack;
        finished = true;
      },
    );
    while (!finished && elapsed.elapsed < const Duration(seconds: 30)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump();
    }
    if (!finished) {
      throw TimeoutException(
        'Native authoring sessions did not finish disposal.',
      );
    }
    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  }

  Future<void> pump({int frames = 4}) async {
    final io = _pendingIo;
    if (io != null) {
      await io;
      if (identical(io, _pendingIo)) _pendingIo = null;
    }
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Offset cellAt(int x, int y) {
    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final size = document.current.size;
    return box.localToGlobal(
      Offset(
        (x + .5) * box.size.width / size.width,
        (y + .5) * box.size.height / size.height,
      ),
    );
  }

  Future<void> tapCell(int x, int y) async {
    await tester.tapAt(cellAt(x, y));
    await pump();
  }

  Future<void> rightClick(int x, int y) async {
    final gesture = await tester.startGesture(
      cellAt(x, y),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await pump();
  }

  Future<void> key(LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await pump();
  }

  Future<void> drag(int x, int y, int toX, int toY) async {
    final gesture = await tester.startGesture(cellAt(x, y));
    await tester.pump();
    await gesture.moveTo(cellAt(toX, toY));
    await tester.pump();
    await gesture.up();
    await pump();
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

  Future<NarrativeWorkspaceController> narrativeOwner() async =>
      sessions.narrative!;

  Future<WorldWorkspaceController> worldOwner() async {
    final owner = sessions.world!;
    if (!owner.initialized) await tester.runAsync(owner.initialize);
    await pump();
    return owner;
  }

  Future<EventWorkspaceController> eventOwner() async {
    final owner = sessions.events!;
    expect(await tester.runAsync(owner.prepare), isTrue, reason: owner.error);
    await pump();
    return owner;
  }
}
