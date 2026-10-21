import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initial preload consumes the catalog already opened by its host',
    () async {
      final file = await _project();
      final catalog = await RuntimeProjectCatalog.open(file.path);
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        preparedProjectCatalog: catalog,
      );
      addTearDown(preloader.clear);
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      final bundle = preloader.preparedNewGameBundle(
        projectFilePath: file.path,
      )!;
      expect(bundle.projectCatalog, same(catalog));
      expect(RuntimeProjectCatalog.ownerOf(bundle.manifest), same(catalog));
      preloader.clear();
      expect(RuntimeProjectCatalog.ownerOf(catalog.projectMetadata), isNull);
    },
  );

  test('clearing before preload releases the provided catalog', () async {
    final file = await _project();
    final catalog = await RuntimeProjectCatalog.open(file.path);
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => file.path,
      loadSave: (_) async => null,
      preparedProjectCatalog: catalog,
    );
    preloader.clear();
    expect(RuntimeProjectCatalog.ownerOf(catalog.projectMetadata), isNull);
  });

  test(
    'transferred catalog survives preloader clear and result disposal',
    () async {
      final file = await _project();
      final catalog = await RuntimeProjectCatalog.open(file.path);
      addTearDown(catalog.dispose);
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        preparedProjectCatalog: catalog,
      );
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      final result = await preloader.resolveForSession(
        projectFilePath: file.path,
        descriptor: _descriptor(),
        initialSave: null,
      );
      expect(result!.takeProjectCatalog(), same(catalog));
      preloader.clear();
      result.dispose();
      expect(
        RuntimeProjectCatalog.ownerOf(catalog.projectMetadata),
        same(catalog),
      );
      expect((await catalog.manifestForMap(_map)).name, 'Original');
    },
  );

  test('missing project resolution releases the provided catalog', () async {
    final file = await _project();
    final catalog = await RuntimeProjectCatalog.open(file.path);
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => '${file.parent.path}/missing.json',
      loadSave: (_) async => null,
      preparedProjectCatalog: catalog,
    );
    addTearDown(preloader.clear);
    await expectLater(
      preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(RuntimeProjectCatalog.ownerOf(catalog.projectMetadata), isNull);
  });

  test(
    'equivalent publication formatting preserves the catalog owner',
    () async {
      final file = await _project();
      final catalog = await RuntimeProjectCatalog.open(file.path);
      final json = jsonDecode(await file.readAsString());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        preparedProjectCatalog: catalog,
      );
      addTearDown(preloader.clear);
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      expect(
        preloader
            .preparedNewGameBundle(projectFilePath: file.path)!
            .projectCatalog,
        same(catalog),
      );
    },
  );

  test('revision reads still observe a changed valid publication after preparation', () async {
    final file = await _project();
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => file.path,
      loadSave: (_) async => null,
    );
    final flow = RuntimeProjectNewGameFlowPort(
      projectFilePath: () async => file.path,
      initialMapPreloader: preloader,
    );
    addTearDown(flow.clear);
    final prepared = await flow.prepare();
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    await file.writeAsString(
      jsonEncode(original.copyWith(name: 'Changed').toJson()),
    );
    expect(
      await flow.readCurrentProjectRevision(),
      isNot(prepared.projectRevision),
    );
  });

  test(
    'prepared narrative corpus avoids reading maps outside the start map',
    () async {
      final file = await _narrativeProject();
      final maps = [
        NarrativeMapProjection.fromMapData(_map),
        NarrativeMapProjection.fromMapData(_otherMap),
      ];
      var calls = 0;
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        preparedNarrativeMapsLoader: (catalog) async {
          calls++;
          expect(catalog.projectMetadata.maps.length, 2);
          return maps;
        },
      );
      addTearDown(preloader.clear);
      expect(await File('${file.parent.path}/other.json').exists(), isFalse);
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      final result = await preloader.resolveForSession(
        projectFilePath: file.path,
        descriptor: _descriptor(),
        initialSave: null,
      );
      expect(calls, 1);
      expect(result!.narrativeSnapshot!.mapsById['other'], same(maps[1]));
      result.dispose();
    },
  );

  test(
    'clear during prepared corpus load releases catalog and warmed images',
    () async {
      final file = await _narrativeProject(withTileset: true);
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder);
      final picture = recorder.endRecording();
      final image = await picture.toImage(32, 32);
      picture.dispose();
      final tileset = RuntimeTilesetImage(
        images: [image],
        chunks: const [RuntimeTilesetChunk(top: 0, width: 32, height: 32)],
        width: 32,
        height: 32,
      );
      addTearDown(tileset.dispose);
      var disposed = 0;
      tileset.addDisposeListener(() => disposed++);
      final entered = Completer<RuntimeProjectCatalog>();
      final release = Completer<List<NarrativeMapProjection>?>();
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        tilesetImageLoader: (
          paths, {
          transparentColorByTilesetId = const {},
          onProgress,
        }) async => {'tiles': tileset},
        preparedNarrativeMapsLoader: (catalog) {
          entered.complete(catalog);
          return release.future;
        },
      );
      addTearDown(preloader.clear);
      final pending = preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      final catalog = await entered.future;
      expect(disposed, 0);
      preloader.clear();
      expect(disposed, 1);
      expect(RuntimeProjectCatalog.ownerOf(catalog.projectMetadata), isNull);
      release.complete([
        NarrativeMapProjection.fromMapData(_map),
        NarrativeMapProjection.fromMapData(_otherMap),
      ]);
      await pending;
      expect(
        preloader.preparedNewGameBundle(projectFilePath: file.path),
        isNull,
      );
      expect(
        await preloader.resolveForSession(
          projectFilePath: file.path,
          descriptor: _descriptor(),
          initialSave: null,
        ),
        isNull,
      );
      expect(disposed, 1);
    },
  );

  test(
    'a changed publication cannot reuse the host metadata catalog',
    () async {
      final file = await _project();
      final catalog = await RuntimeProjectCatalog.open(file.path);
      final current = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      await file.writeAsString(
        jsonEncode(current.copyWith(name: 'Changed').toJson()),
      );
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        preparedProjectCatalog: catalog,
      );
      addTearDown(preloader.clear);
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      final bundle = preloader.preparedNewGameBundle(
        projectFilePath: file.path,
      )!;
      expect(bundle.manifest.name, 'Changed');
      expect(bundle.projectCatalog, isNot(same(catalog)));
      expect(RuntimeProjectCatalog.ownerOf(catalog.projectMetadata), isNull);
    },
  );
}

const _map = MapData(
  id: 'start',
  name: 'Start',
  size: GridSize(width: 2, height: 2),
);

Future<File> _project() async {
  final root = await Directory.systemTemp.createTemp('preload-reused-catalog-');
  addTearDown(() => root.delete(recursive: true));
  final file = File('${root.path}/project.json');
  final project = ProjectManifest(
    name: 'Original',
    maps: const [
      ProjectMapEntry(id: 'start', name: 'Start', relativePath: 'start.json'),
    ],
    tilesets: const [],
    newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'start'),
  );
  await file.writeAsString(jsonEncode(project.toJson()));
  await File('${root.path}/start.json')
      .writeAsString(jsonEncode(_map.toJson()));
  return file;
}

const _otherMap = MapData(
  id: 'other',
  name: 'Other',
  size: GridSize(width: 2, height: 2),
);

Future<File> _narrativeProject({bool withTileset = false}) async {
  final file = await _project();
  final project = ProjectManifest.fromJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  await file.writeAsString(
    jsonEncode(
      project
          .copyWith(
            maps: [
              ...project.maps,
              const ProjectMapEntry(
                id: 'other',
                name: 'Other',
                relativePath: 'other.json',
              ),
            ],
            tilesets: withTileset
                ? const [
                    ProjectTilesetEntry(
                      id: 'tiles',
                      name: 'Tiles',
                      relativePath: 'tiles.png',
                    ),
                  ]
                : const [],
            eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.dualRead,
              records: const [],
              legacyClaims: const [],
            ),
          )
          .toJson(),
    ),
  );
  if (withTileset) {
    await File('${file.parent.path}/start.json').writeAsString(
      jsonEncode(
        _map
            .copyWith(
              tilesetId: 'tiles',
              layers: const [
                MapLayer.tile(
                  id: 'ground',
                  name: 'Ground',
                  palette: [
                    TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0),
                  ],
                  cells: [1, 1, 1, 1],
                ),
              ],
            )
            .toJson(),
      ),
    );
  }
  return file;
}

GameSessionDescriptor _descriptor() => GameSessionDescriptor(
  sessionId: 'session',
  sessionToken: 'token',
  identity: GameIdentity(
    gameId: 'org.example.reuse',
    gameVersion: '1.0.0',
    projectFormat: ProjectFormat.v1,
    saveFormat: 1,
    compatibilityId: 'reuse',
  ),
  profileId: 'profile',
  slotId: 'slot',
  launchMode: GameSessionLaunchMode.newGame,
  installedVersionHandle: 'fixture',
  runtimeApiVersion: '1.0.0',
  grantedCapabilities: const {'map.v1'},
  locale: 'fr-FR',
  accessibility: const GameSessionAccessibilityOptions(),
  initialGameState: const GameState(saveId: 'save', currentMapId: 'start'),
);
