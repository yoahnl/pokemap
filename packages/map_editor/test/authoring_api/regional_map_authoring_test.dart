import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_add_authoring_gateway.dart';
import 'package:map_editor/src/application/authoring_api/regional_map_authoring_gateway.dart';
import 'package:map_editor/src/features/personalization/presentation/regional_map_workshop.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_pause_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test(
    'editor saves region and multi-map POI through canonical actions and rereads',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.close);
      final before = await fixture.gateway.load(fixture.root.path);
      expect(before.images.single.label, 'Illustration de test');
      final region = ProjectRegionDefinition(
        id: 'line',
        label: 'Ligne locale',
        imagePath: before.images.single.path,
      );
      final regionSaved = await fixture.gateway.saveRegion(
        fixture.root.path,
        before,
        region,
      );
      final point = ProjectRegionPointOfInterest(
        id: 'village',
        regionId: 'line',
        label: 'Village',
        u: .25,
        v: .75,
        mapIds: const ['village-map', 'pension-map'],
        description: 'Une halte au bord du village.',
        thumbnailPath: before.images.single.path,
        visibility: ProjectRegionPointVisibility.discoveredOnly,
      );
      final saved = await fixture.gateway.savePoint(
        fixture.root.path,
        regionSaved,
        point,
      );
      expect(
        fixture.mutations.lastAppliedReceipt?.actionId,
        'regionalMap.poi.upsert',
      );
      final read = await fixture.gateway.load(fixture.root.path);
      expect(read.revision, saved.revision);
      expect(
        read.manifest.regionalMap!.pointsOfInterest.single.toJson(),
        point.toJson(),
      );
      expect(
        read.manifest.presentation?.pause?.style,
        ProjectPauseMenuStyle.nightIllustrated,
      );
      expect(read.manifest.name, 'Atelier test');
      expect(read.manifest.maps, before.manifest.maps);

      final detail = await const RuntimeRegionalMapBuilder().build(
        gameState: const GameState(
          saveId: 'proof',
          currentMapId: 'pension-map',
        ),
        projectRootDirectory: fixture.root.path,
        locale: 'fr',
        catalog: read.manifest.regionalMap,
        projectMaps: read.manifest.maps,
      );
      expect(
        detail.regionalMap!.regions.single.points.single.status,
        RuntimePlayerMapPointStatus.current,
      );
      expect(detail.regionalMap!.regions.single.imageFilePath, isNotNull);
      expect(
        detail.regionalMap!.regions.single.points.single.thumbnailFilePath,
        isNotNull,
      );

      await expectLater(
        fixture.gateway.deleteRegion(fixture.root.path, read, region.id),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (e) => e.code,
            'code',
            'regional_map.region_referenced',
          ),
        ),
      );
      final withoutPoint = await fixture.gateway.deletePoint(
        fixture.root.path,
        read,
        point.id,
      );
      final cleared = await fixture.gateway.deleteRegion(
        fixture.root.path,
        withoutPoint,
        region.id,
      );
      expect(cleared.manifest.regionalMap!.regions, isEmpty);
      expect(cleared.manifest.regionalMap!.pointsOfInterest, isEmpty);
    },
  );

  test('stale editor revision cannot overwrite a newer region', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.close);
    final before = await fixture.gateway.load(fixture.root.path);
    await fixture.gateway.saveRegion(
      fixture.root.path,
      before,
      ProjectRegionDefinition(id: 'line', label: 'Version récente'),
    );
    await expectLater(
      fixture.gateway.saveRegion(
        fixture.root.path,
        before,
        ProjectRegionDefinition(id: 'line', label: 'Version périmée'),
      ),
      throwsA(isA<EditorAuthoringMutationFailure>()),
    );
    final current = await fixture.gateway.load(fixture.root.path);
    expect(
      current.manifest.regionalMap!.regions.single.label,
      'Version récente',
    );
    await expectLater(
      fixture.gateway.saveRegion(
        fixture.root.path,
        current,
        ProjectRegionDefinition(
          id: 'line',
          label: 'Image absente',
          imagePath: 'assets/absent.png',
        ),
      ),
      throwsA(
        isA<EditorAuthoringMutationFailure>().having(
          (e) => e.code,
          'code',
          'regional_map.image_missing',
        ),
      ),
    );
    expect(
      (await fixture.gateway.load(
        fixture.root.path,
      )).manifest.regionalMap!.regions.single.label,
      'Version récente',
    );
  });

  testWidgets('pause inspector exposes the no-code regional workshop', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalizationPauseInspector(
              profile: const ProjectPresentationProfile(),
              onPauseChanged: (_) {},
              onWindowsChanged: (_) {},
              onLayoutsChanged: (_) {},
              onImportBodyFont: () {},
              onUseSystemBodyFont: () {},
              onConfigureRegionalMap: () => opened++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('pause-configure-regional-map')),
    );
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'workshop blocks focused keyboard input while canonical save is pending',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reader = _GatedReader();
      final fixture = (await tester.runAsync(
        () => _Fixture.create(queryReader: reader),
      ))!;
      addTearDown(
        () => tester.runAsync(() async {
          reader.release();
          await fixture.close();
        }),
      );
      ProjectManifest? published;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: RegionalMapWorkshop(
            projectRootPath: fixture.root.path,
            gateway: fixture.gateway,
            onProjectChanged: (project) => published = project,
          ),
        ),
      );
      final name = find.byKey(const ValueKey('regional-authoring-region-name'));
      await _waitFor(tester, name);
      await tester.enterText(name, 'Nom à enregistrer');
      await tester.pump();
      final field = tester.widget<EditableText>(
        find.descendant(of: name, matching: find.byType(EditableText)),
      );
      expect(field.focusNode.hasFocus, isTrue);
      await tester.runAsync(() async {
        reader.arm();
        await tester.tap(find.byKey(const ValueKey('regional-authoring-save')));
        await reader.entered.future;
      });
      await tester.pump();
      expect(field.focusNode.hasFocus, isFalse);
      expect(field.focusNode.canRequestFocus, isFalse);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      field.focusNode.requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pump();
      expect(field.focusNode.hasFocus, isFalse);
      expect(field.controller.text, 'Nom à enregistrer');
      await tester.runAsync(() async => reader.release());
      await _waitFor(tester, find.text('Enregistré et relu dans le projet.'));
      expect(
        published!.regionalMap!.regions.single.label,
        field.controller.text,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'workshop hides old placement geometry while the next image is loading',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reader = _GatedReader();
      final fixture = (await tester.runAsync(
        () => _Fixture.create(queryReader: reader),
      ))!;
      addTearDown(
        () => tester.runAsync(() async {
          reader.release();
          await fixture.close();
        }),
      );
      await tester.runAsync(() async {
        var state = await fixture.gateway.load(fixture.root.path);
        final landscape = state.images.single.path;
        final source = File('${fixture.root.path}/portrait.png');
        await source.writeAsBytes(
          image.encodePng(image.Image(width: 200, height: 400)),
        );
        state = await fixture.gateway.importImage(
          fixture.root.path,
          state,
          PresentationStudioPickedMedia(
            sourcePath: source.path,
            label: 'Portrait de test',
          ),
        );
        final portrait = state.images
            .singleWhere((i) => i.path != landscape)
            .path;
        for (final region in [
          ProjectRegionDefinition(
            id: 'wide',
            label: 'Région large',
            imagePath: landscape,
          ),
          ProjectRegionDefinition(
            id: 'tall',
            label: 'Région haute',
            imagePath: portrait,
          ),
        ]) {
          state = await fixture.gateway.saveRegion(
            fixture.root.path,
            state,
            region,
          );
        }
        await fixture.gateway.savePoint(
          fixture.root.path,
          state,
          ProjectRegionPointOfInterest(
            id: 'tall-place',
            regionId: 'tall',
            label: 'Lieu haut',
            u: .5,
            v: .5,
            mapIds: const ['village-map'],
          ),
        );
      });
      ProjectManifest? published;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: RegionalMapWorkshop(
            projectRootPath: fixture.root.path,
            gateway: fixture.gateway,
            onProjectChanged: (project) => published = project,
          ),
        ),
      );
      final placement = find.byKey(
        const ValueKey('regional-authoring-placement'),
      );
      await _waitFor(tester, placement);
      await tester.runAsync(() async => reader.arm());
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is PokeMapDropdownField<String> &&
              widget.label == 'Région',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Région haute').last);
      await tester.pumpAndSettle();
      expect(reader.entered.isCompleted, isTrue);
      expect(find.text('Chargement de l’illustration…'), findsOneWidget);
      expect(placement, findsNothing);
      await tester.runAsync(() async => reader.release());
      await _waitFor(tester, placement);
      await tester.tap(
        find.byKey(const ValueKey('regional-authoring-selection')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lieu haut').last);
      await tester.pumpAndSettle();
      final rect = tester.getRect(placement);
      final geometry = RegionMapGeometry(
        viewport: rect.size,
        imageSize: const Size(200, 400),
      );
      await tester.tapAt(
        rect.topLeft + geometry.project(const Offset(.75, .25)),
      );
      await tester.pump();
      await tester.runAsync(
        () => tester.tap(find.byKey(const ValueKey('regional-authoring-save'))),
      );
      await _waitFor(tester, find.text('Enregistré et relu dans le projet.'));
      final point = published!.regionalMap!.pointsOfInterest.single;
      expect(point.u, closeTo(.75, .001));
      expect(point.v, closeTo(.25, .001));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('workshop discards region artwork before placing a new POI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(_Fixture.create))!;
    addTearDown(() => tester.runAsync(fixture.close));
    await tester.runAsync(() async {
      var state = await fixture.gateway.load(fixture.root.path);
      final landscape = state.images.single.path;
      final source = File('${fixture.root.path}/portrait.png');
      await source.writeAsBytes(
        image.encodePng(image.Image(width: 200, height: 400)),
      );
      state = await fixture.gateway.importImage(
        fixture.root.path,
        state,
        PresentationStudioPickedMedia(
          sourcePath: source.path,
          label: 'Portrait de test',
        ),
      );
      await fixture.gateway.saveRegion(
        fixture.root.path,
        state,
        ProjectRegionDefinition(
          id: 'line',
          label: 'Région enregistrée',
          imagePath: landscape,
        ),
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: RegionalMapWorkshop(
          projectRootPath: fixture.root.path,
          gateway: fixture.gateway,
          onProjectChanged: (_) {},
        ),
      ),
    );
    final placement = find.byKey(
      const ValueKey('regional-authoring-placement'),
    );
    await _waitFor(tester, placement);
    await tester.enterText(
      find.byKey(const ValueKey('regional-authoring-region-name')),
      'Nom abandonné',
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is PokeMapDropdownField<String> &&
            widget.label == 'Illustration de la région',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portrait de test').last);
    await tester.pumpAndSettle();
    await _waitFor(tester, placement);
    final draftImage = tester.widget<Image>(
      find.descendant(of: placement, matching: find.byType(Image)),
    );
    expect(
      image.decodeImage((draftImage.image as MemoryImage).bytes)!.width,
      200,
    );
    await tester.tap(
      find.byKey(const ValueKey('regional-authoring-new-point')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonner les changements'));
    await tester.pumpAndSettle();
    await _waitFor(tester, placement);
    final restoredImage = tester.widget<Image>(
      find.descendant(of: placement, matching: find.byType(Image)),
    );
    expect(
      image.decodeImage((restoredImage.image as MemoryImage).bytes)!.width,
      400,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await fixture.container.read(authoringQueryAdapterProvider).closeAll();
  });

  testWidgets(
    'workshop positions and saves a POI without IDs and previews chosen discovery',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(_Fixture.create))!;
      addTearDown(() => tester.runAsync(fixture.close));
      await tester.runAsync(() async {
        final loaded = await fixture.gateway.load(fixture.root.path);
        await fixture.gateway.saveRegion(
          fixture.root.path,
          loaded,
          ProjectRegionDefinition(
            id: 'line',
            label: 'Ligne locale',
            imagePath: loaded.images.single.path,
          ),
        );
      });
      ProjectManifest? published;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: RegionalMapWorkshop(
            projectRootPath: fixture.root.path,
            gateway: fixture.gateway,
            onProjectChanged: (project) {
              published = project;
            },
          ),
        ),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('regional-authoring-new-point')),
      );
      await tester.tap(
        find.byKey(const ValueKey('regional-authoring-new-point')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('regional-authoring-save')));
      await tester.pump();
      expect(find.text('Saisissez un nom avant de continuer.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('regional-authoring-point-name')),
        'Lieu discret',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      for (final id in ['village-map', 'pension-map']) {
        final field = find.byKey(ValueKey('regional-authoring-map-$id'));
        await Scrollable.ensureVisible(tester.element(field), alignment: .5);
        await tester.pumpAndSettle();
        expect(
          field.hitTestable(),
          findsOneWidget,
          reason: '${tester.getRect(field)}',
        );
        await tester.tap(field);
        await tester.pump();
      }
      final placement = find.byKey(
        const ValueKey('regional-authoring-placement'),
      );
      await _waitFor(tester, placement);
      final rect = tester.getRect(placement);
      final geometry = RegionMapGeometry(
        viewport: rect.size,
        imageSize: const Size(400, 200),
      );
      await tester.tapAt(
        rect.topLeft + geometry.project(const Offset(.25, .75)),
      );
      await tester.pump();
      await tester.runAsync(
        () => tester.tap(find.byKey(const ValueKey('regional-authoring-save'))),
      );
      await _waitFor(tester, find.text('Enregistré et relu dans le projet.'));
      final point = published!.regionalMap!.pointsOfInterest.single;
      expect(point.id, startsWith('place-'));
      expect(point.label, 'Lieu discret');
      expect(point.mapIds, containsAll(['village-map', 'pension-map']));
      expect(point.u, closeTo(.25, .001));
      expect(point.v, closeTo(.75, .001));
      await tester.tap(
        find.byKey(const ValueKey('regional-authoring-player-preview')),
      );
      await _waitFor(tester, find.byType(RuntimePlayerRegionMap));
      final previewContext = tester.element(
        find.byType(RuntimePlayerRegionMap),
      );
      expect(previewContext.playerMenuTheme.base.toARGB32(), 0xff123456);
      expect(
        previewContext
            .getInheritedWidgetOfExactType<PlayerMenuThemeScope>()
            ?.role,
        ProjectPresentationSurfaceRole.map,
      );
      expect(
        find.descendant(
          of: find.byType(RuntimePlayerRegionMap),
          matching: find.text('Lieu discret'),
        ),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('regional-authoring-preview-visited')),
      );
      await _waitFor(
        tester,
        find.descendant(
          of: find.byType(RuntimePlayerRegionMap),
          matching: find.text('Lieu discret'),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 500; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(
    finder,
    findsWidgets,
    reason: find
        .descendant(
          of: find.byKey(const ValueKey('regional-authoring-error')),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .join(' '),
  );
}

final class _Fixture {
  _Fixture(this.root, this.container, this.gateway, this.mutations);

  final Directory root;
  final ProviderContainer container;
  final RegionalMapAuthoringGateway gateway;
  final AuthoringMutationAdapter mutations;

  static Future<_Fixture> create({ProjectFileReader? queryReader}) async {
    final root = await Directory.systemTemp.createTemp('regional_editor_');
    final container = ProviderContainer(
      overrides: [
        if (queryReader != null)
          authoringQueryAdapterProvider.overrideWith(
            (ref) => AuthoringQueryAdapter(fileReader: queryReader),
          ),
      ],
    );
    final queries = container.read(authoringQueryAdapterProvider);
    final mutations = container.read(authoringMutationAdapterProvider);
    final gateway = RegionalMapAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );
    final maps = [
      const ProjectMapEntry(
        id: 'village-map',
        name: 'Village test',
        relativePath: 'maps/village.json',
      ),
      const ProjectMapEntry(
        id: 'pension-map',
        name: 'Pension test',
        relativePath: 'maps/pension.json',
      ),
    ];
    await Directory('${root.path}/maps').create();
    for (final map in maps) {
      await File('${root.path}/${map.relativePath}').writeAsString(
        jsonEncode(
          MapData(
            id: map.id,
            name: map.name,
            size: const GridSize(width: 4, height: 4),
          ).toJson(),
        ),
      );
    }
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Atelier test',
          maps: maps,
          tilesets: const [],
          presentation: const ProjectPresentationProfile(
            surfacePalettes: ProjectPresentationSurfacePalettesProfile(
              pauseMenu: ProjectSurfacePaletteProfile(background: '#123456'),
            ),
            pause: ProjectPausePresentationProfile(
              style: ProjectPauseMenuStyle.nightIllustrated,
            ),
          ),
        ).toJson(),
      ),
    );
    final source = File('${root.path}/source.png');
    await source.writeAsBytes(
      image.encodePng(image.Image(width: 400, height: 200)),
    );
    final before = await gateway.load(root.path);
    await gateway.importImage(
      root.path,
      before,
      PresentationStudioPickedMedia(
        sourcePath: source.path,
        label: 'Illustration de test',
      ),
    );
    return _Fixture(root, container, gateway, mutations);
  }

  Future<void> close() async {
    await mutations.closeAll();
    await container.read(authoringQueryAdapterProvider).closeAll();
    container.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _GatedReader implements ProjectFileReader {
  static const _delegate = LocalProjectFileReader();
  Completer<void>? _entered;
  Completer<void>? _released;
  bool _armed = false;

  Completer<void> get entered => _entered!;

  void arm() {
    _entered = Completer<void>();
    _released = Completer<void>();
    _armed = true;
  }

  void release() {
    _armed = false;
    if (_released?.isCompleted == false) _released!.complete();
  }

  @override
  Future<String> canonicalizeDirectory(String path) async {
    if (_armed) {
      _armed = false;
      _entered!.complete();
      await _released!.future;
    }
    return _delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) =>
      _delegate.readBytes(projectRoot: projectRoot, relativePath: relativePath);
}
