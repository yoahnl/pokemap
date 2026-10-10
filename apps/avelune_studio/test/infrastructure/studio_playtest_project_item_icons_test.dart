import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/pokemon/data/studio_project_item_icons.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart';

void main() {
  testWidgets('prepares project item icons before loading the playtest bundle', (
    tester,
  ) async {
    late Directory directory;
    late ProjectSession session;
    late ProjectMapEntry entry;
    late MapWorkspaceDocument document;
    late ProjectManifest project;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'studio_icon_playtest_',
      );
      await writeExampleProject(directory);
      session = ProjectSession(
        sessionId: 'item-icon-playtest',
        name: 'Project item icons',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final port = LocalMapWorkspaceAdapter();
      project = await port.loadProject(session);
      entry = project.maps.first;
      document = await port.loadMap(session, entry);
      final catalog = File(
        p.join(session.directoryPath, 'data/pokemon/catalogs/items.json'),
      );
      await catalog.parent.create(recursive: true);
      await catalog.writeAsString(
        jsonEncode(
          encodeProjectItemCatalog(
            ProjectItemCatalog(
              schemaVersion: 1,
              entries: const [
                ProjectItemDefinition(
                  id: 'potion',
                  displayName: 'Potion',
                  pocketId: 'medicine',
                ),
              ],
            ),
          ),
        ),
      );
    });
    addTearDown(() => directory.delete(recursive: true));
    final gate = Completer<void>();
    final port = _CachedMapPort(document);
    var preparing = false;
    var prepared = false;
    var phase = 'waiting';
    await tester.pumpWidget(
      _view(
        session: session,
        entry: entry,
        document: document,
        port: port,
        prepare: (root) async {
          expect(root, session.directoryPath);
          expect(port.loadCalls, 1);
          preparing = true;
          await gate.future;
          phase = 'provisioning';
          await StudioProjectItemIcons.shared.prepare(root);
          phase = 'manifest';
          await File(p.join(root, 'project.json')).writeAsString(
            jsonEncode(project.copyWith(name: 'Item icons prepared').toJson()),
          );
          prepared = true;
        },
      ),
    );
    await tester.pump();
    expect(preparing, isTrue);
    expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
    expect(find.textContaining('Le test ne peut pas démarrer'), findsNothing);
    gate.complete();
    PlayableMapGame? game;
    for (var attempt = 0; attempt < 3000; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final finder = find.byType(GameWidget<PlayableMapGame>);
      if (finder.evaluate().isNotEmpty) {
        game = tester.widget<GameWidget<PlayableMapGame>>(finder).game;
        if (game!.isLoaded && !game.debugIsMapActivationDispatchInFlight) {
          break;
        }
      }
    }
    expect(
      prepared,
      isTrue,
      reason:
          '$phase\n${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).join('\n')}',
    );
    expect(game, isNotNull);
    expect(game!.isLoaded, isTrue);
    await tester.runAsync(() async {
      final bundle = await game!.debugLoadRuntimeMapBundleCachedForTest(
        entry.id,
      );
      expect(bundle.manifest.name, 'Item icons prepared');
      final icon = File(
        p.join(session.directoryPath, 'data/pokemon/assets/items/potion.png'),
      );
      expect((await icon.readAsBytes()).take(8), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
      final assets = AssetCatalog.fromJson(
        jsonDecode(
              await File(
                p.join(session.directoryPath, assetCatalogStorageKey),
              ).readAsString(),
            )
            as Map<String, dynamic>,
      );
      expect(
        assets.findByLogicalPath('data/pokemon/assets/items/potion.png'),
        isNotNull,
      );
      expect(
        assets.records.where(
          (record) => record.tags.contains('item-icon-provenance'),
        ),
        hasLength(1),
      );
    });
    await tester.pumpWidget(const SizedBox());
    expect(game.isPaused, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revision conflict skips item icon preparation', (tester) async {
    final document = _document();
    var calls = 0;
    await tester.pumpWidget(
      _view(
        session: _session,
        entry: _entry,
        document: document,
        port: _CachedMapPort(document),
        expectedRevision: 'different-revision',
        prepare: (_) async => calls++,
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.textContaining('La carte a changé sur disque'), findsOneWidget);
    expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closing during preparation never mounts a late runtime', (
    tester,
  ) async {
    final gate = Completer<void>();
    final document = _document();
    var calls = 0;
    await tester.pumpWidget(
      _view(
        session: _session,
        entry: _entry,
        document: document,
        port: _CachedMapPort(document),
        prepare: (_) async {
          calls++;
          await gate.future;
        },
      ),
    );
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pump();
    expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

const _session = ProjectSession(
  sessionId: 'prepared-playtest',
  name: 'Prepared playtest',
  directoryPath: '/does-not-exist',
);
const _entry = ProjectMapEntry(
  id: 'map',
  name: 'Map',
  relativePath: 'map.json',
);

MapWorkspaceDocument _document() => const MapWorkspaceDocument(
  map: MapData(id: 'map', name: 'Map', size: GridSize(width: 1, height: 1)),
  revision: 'saved-revision',
  mapId: 'map',
);

Widget _view({
  required ProjectSession session,
  required ProjectMapEntry entry,
  required MapWorkspaceDocument document,
  required MapWorkspacePort port,
  required Future<void> Function(String) prepare,
  String? expectedRevision,
}) => MaterialApp(
  home: Scaffold(
    body: StudioPlaytestView(
      session: session,
      entry: entry,
      expectedRevision: expectedRevision ?? document.revision,
      port: port,
      prepareProjectAssets: prepare,
      onClose: () {},
    ),
  ),
);

final class _CachedMapPort implements MapWorkspacePort {
  _CachedMapPort(this.document);

  final MapWorkspaceDocument document;
  int loadCalls = 0;

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    loadCalls++;
    return document;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
