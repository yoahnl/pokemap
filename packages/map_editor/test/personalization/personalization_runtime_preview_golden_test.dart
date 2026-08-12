import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart';
import 'package:path/path.dart' as p;

enum _EditorVariant {
  dialogueText2x,
  dialogueChoices,
  battleCommands,
  battleMoves,
  battleTarget,
  battleMessage,
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthoringQueryAdapter queries;
  late ({
    ProjectPresentationProfile profile,
    ProjectManifest manifest,
    MapData map,
    String projectName,
    List<PersonalizationPreviewContextOption> contexts,
  })
  fixtureData;

  setUpAll(() async {
    await _loadFixtureFont();
    queries = AuthoringQueryAdapter(
      fileReader: const EditorProjectFileReader(),
    );
    fixtureData = await _readFixture(_fixtureDirectory(), queries);
  });
  tearDownAll(() => queries.closeAll());

  for (final viewport in <PersonalizationPreviewViewport>[
    PersonalizationPreviewViewport.landscape,
    PersonalizationPreviewViewport.portrait,
  ]) {
    for (final surface in PersonalizationStudioScene.values) {
      testWidgets('certifies editor ${surface.name} in ${viewport.name}', (
        tester,
      ) async {
        final size = viewport == PersonalizationPreviewViewport.landscape
            ? const Size(960, 900)
            : const Size(600, 1080);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = _fixtureDirectory();
        await tester.runAsync(() => _seedFixtureImages(fixture));
        final mapBackdropPlanLoader = CinematicMapBackdropLayerPlanLoader();
        addTearDown(mapBackdropPlanLoader.clear);
        final mapPlanReady = await tester.runAsync(
          () => _preloadMapPlan(
            loader: mapBackdropPlanLoader,
            fixture: fixture,
            manifest: fixtureData.manifest,
            map: fixtureData.map,
          ),
        );
        expect(mapPlanReady, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _readableEditorTheme(),
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey<String>('personalization-editor-golden'),
                child: PersonalizationLivePreview(
                  profile: fixtureData.profile,
                  projectName: fixtureData.projectName,
                  projectRootPath: fixture.path,
                  scene: surface,
                  initialViewport: viewport,
                  contentSource: PersonalizationPreviewContentSource.project,
                  contexts: fixtureData.contexts,
                  projectManifest: fixtureData.manifest,
                  mapBackdropPlanLoader: mapBackdropPlanLoader,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey<String>('personalization-editor-golden')),
          matchesGoldenFile(
            'goldens/personalization/editor_${viewport.name}_${surface.name}.png',
          ),
        );
      });
    }
  }

  for (final variant in _EditorVariant.values) {
    testWidgets('certifies editor ${variant.name} variant', (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _fixtureDirectory();
      await tester.runAsync(() => _seedFixtureImages(fixture));
      final mapBackdropPlanLoader = CinematicMapBackdropLayerPlanLoader();
      addTearDown(mapBackdropPlanLoader.clear);
      final mapPlanReady = await tester.runAsync(
        () => _preloadMapPlan(
          loader: mapBackdropPlanLoader,
          fixture: fixture,
          manifest: fixtureData.manifest,
          map: fixtureData.map,
        ),
      );
      expect(mapPlanReady, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _readableEditorTheme(),
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>(
                'personalization-editor-variant-golden',
              ),
              child: PersonalizationLivePreview(
                profile: fixtureData.profile,
                projectName: fixtureData.projectName,
                projectRootPath: fixture.path,
                scene: _variantScene(variant),
                initialViewport: PersonalizationPreviewViewport.landscape,
                contentSource: PersonalizationPreviewContentSource.project,
                contexts: fixtureData.contexts,
                projectManifest: fixtureData.manifest,
                mapBackdropPlanLoader: mapBackdropPlanLoader,
                showDialogueChoices: variant == _EditorVariant.dialogueChoices,
                battleState: _variantBattleState(variant),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      if (variant == _EditorVariant.dialogueChoices) {
        final choicesContext = fixtureData.contexts.singleWhere(
          (option) =>
              option.kind ==
                  PersonalizationPreviewContextKind.dialogueScenario &&
              option.detail['scenarioKind'] == 'choice',
        );
        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'personalization-preview-context-dialogueScenario',
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text(choicesContext.label).last);
        await tester.pump();
      }
      if (variant == _EditorVariant.dialogueText2x) {
        await tester.tap(
          find.byKey(
            const ValueKey<String>('personalization-preview-text-scale-200'),
          ),
        );
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(
          const ValueKey<String>('personalization-editor-variant-golden'),
        ),
        matchesGoldenFile(
          'goldens/personalization/editor_variant_${variant.name}.png',
        ),
      );
    });
  }
}

PersonalizationStudioScene _variantScene(_EditorVariant variant) =>
    switch (variant) {
      _EditorVariant.dialogueText2x ||
      _EditorVariant.dialogueChoices => PersonalizationStudioScene.dialogue,
      _ => PersonalizationStudioScene.battle,
    };

PersonalizationBattlePreviewState _variantBattleState(_EditorVariant variant) =>
    switch (variant) {
      _EditorVariant.battleMoves => PersonalizationBattlePreviewState.moves,
      _EditorVariant.battleTarget => PersonalizationBattlePreviewState.target,
      _EditorVariant.battleMessage => PersonalizationBattlePreviewState.message,
      _ => PersonalizationBattlePreviewState.commands,
    };

Directory _fixtureDirectory() => Directory(
  p.join(
    Directory.current.path,
    '..',
    '..',
    'examples',
    'playable_runtime_host',
    'golden_personalization_v3',
  ),
);

Future<
  ({
    ProjectPresentationProfile profile,
    ProjectManifest manifest,
    MapData map,
    String projectName,
    List<PersonalizationPreviewContextOption> contexts,
  })
>
_readFixture(Directory fixture, AuthoringQueryAdapter queries) async {
  final decoded =
      jsonDecode(
            await File(p.join(fixture.path, 'project.json')).readAsString(),
          )
          as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(decoded);
  final mapEntry = manifest.maps.single;
  final map = MapData.fromJson(
    jsonDecode(
          await File(
            p.join(fixture.path, mapEntry.relativePath),
          ).readAsString(),
        )
        as Map<String, dynamic>,
  );
  final contexts = await AuthoringPersonalizationPreviewContextSource(
    queries: queries,
  ).load(fixture.path);
  return (
    profile: manifest.presentation!,
    manifest: manifest,
    map: map,
    projectName: manifest.name,
    contexts: contexts,
  );
}

Future<bool> _preloadMapPlan({
  required CinematicMapBackdropLayerPlanLoader loader,
  required Directory fixture,
  required ProjectManifest manifest,
  required MapData map,
}) async {
  final stageMap = manifest.maps.singleWhere((entry) => entry.id == map.id);
  final previewModel = buildCinematicMapBackdropPreviewModel(
    asset: CinematicAsset(
      id: 'golden-map-preview',
      title: map.name,
      mapId: map.id,
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
      ),
      timeline: CinematicTimeline(),
    ),
    stageMap: stageMap,
    mapData: map,
    availableTilesetIds: manifest.tilesets.map((entry) => entry.id).toSet(),
    smartTileCatalog: manifest.smartTileCatalog,
  );
  final plan = await loader.load(
    manifest: manifest,
    mapData: map,
    previewModel: previewModel,
    resolveTilesetPath: (tilesetId) {
      final tileset = manifest.tilesets.singleWhere(
        (entry) => entry.id == tilesetId,
      );
      return p.join(fixture.path, tileset.relativePath);
    },
  );
  return plan?.hasBitmapInstructions == true &&
      plan!.instructions.every(
        (instruction) => plan.tilesets[instruction.tilesetId]?.image != null,
      );
}

Future<void> _seedFixtureImages(Directory fixture) async {
  for (final relativePath in <String>[
    'assets/presentation/icon.png',
    'assets/presentation/cover.png',
    'assets/presentation/hero.png',
    'assets/presentation/intro/poster.png',
    'assets/characters/leo-happy.png',
    'assets/battle/battle-clearing.png',
    'assets/maps/vermeil-village-stage.png',
  ]) {
    final provider = FileImage(File(p.join(fixture.path, relativePath)));
    final codec = await ui.instantiateImageCodec(
      await provider.file.readAsBytes(),
    );
    final frame = await codec.getNextFrame();
    PaintingBinding.instance.imageCache.putIfAbsent(
      provider,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: frame.image)),
      ),
    );
    codec.dispose();
  }
}

Future<void> _loadFixtureFont() async {
  final bytes = await File(
    p.join(
      _fixtureDirectory().path,
      'assets',
      'presentation',
      'fonts',
      'display.ttf',
    ),
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
  final flutterCache = _flutterCacheDirectory();
  final iconBytes = await File(
    p.join(
      flutterCache.path,
      'artifacts',
      'material_fonts',
      'MaterialIcons-Regular.otf',
    ),
  ).readAsBytes();
  await _loadFont('MaterialIcons', iconBytes);
}

Future<void> _loadFont(String family, Uint8List bytes) async {
  await (FontLoader(
    family,
  )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
}

Directory _flutterCacheDirectory() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    if (current.path.endsWith('${Platform.pathSeparator}cache')) return current;
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}

ThemeData _readableEditorTheme() {
  final theme = PokeMapTheme.light();
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Aube Display'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Aube Display'),
  );
}
