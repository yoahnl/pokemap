import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_project_map_backdrop.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';
import 'package:path/path.dart' as p;

void main() {
  late String projectRoot;
  late ProjectManifest manifest;
  late MapData map;

  setUpAll(() async {
    projectRoot = p.join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'golden_personalization_v3',
    );
    manifest = ProjectManifest.fromJson(
      jsonDecode(await File(p.join(projectRoot, 'project.json')).readAsString())
          as Map<String, dynamic>,
    );
    map = MapData.fromJson(
      jsonDecode(
            await File(
              p.join(projectRoot, 'maps', 'vermeil_village.json'),
            ).readAsString(),
          )
          as Map<String, dynamic>,
    );
  });

  testWidgets('uses the shared read-only project map renderer', (tester) async {
    final stageMap = manifest.maps.singleWhere((entry) => entry.id == map.id);
    final previewModel = buildCinematicMapBackdropPreviewModel(
      asset: CinematicAsset(
        id: 'fixture-preview',
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
    final planLoader = CinematicMapBackdropLayerPlanLoader();
    addTearDown(planLoader.clear);
    final plan = await tester.runAsync(
      () => planLoader.load(
        manifest: manifest,
        mapData: map,
        previewModel: previewModel,
        resolveTilesetPath: (tilesetId) {
          final tileset = manifest.tilesets.singleWhere(
            (entry) => entry.id == tilesetId,
          );
          return p.join(projectRoot, tileset.relativePath);
        },
      ),
    );

    expect(plan, isNotNull);
    expect(plan!.diagnostics, isEmpty);
    expect(plan.hasBitmapInstructions, isTrue);
    expect(
      plan.instructions.every(
        (instruction) => plan.tilesets[instruction.tilesetId]?.image != null,
      ),
      isTrue,
    );
    final tilePlan = buildCinematicMapBackdropTileRenderPlan(
      mapData: map,
      manifest: manifest,
      tilesets: plan.tilesets,
    );
    expect(tilePlan.hasBitmapInstructions, isTrue);
    expect(
      tilePlan.instructions.every(
        (instruction) =>
            tilePlan.tilesets[instruction.tilesetId]?.image != null,
      ),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => SizedBox(
              width: 960,
              height: 540,
              child: PersonalizationProjectMapBackdrop(
                map: map,
                colors: context.pokeMapColors,
                projectRootPath: projectRoot,
                manifest: manifest,
                planLoader: planLoader,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 5; attempt += 1) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
    }

    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-renderer'),
      ),
      findsOneWidget,
    );
    expect(find.text('Village de Vermeil'), findsOneWidget);
  });

  testWidgets('keeps its render plan when only presentation changes', (
    tester,
  ) async {
    var currentManifest = manifest;
    late StateSetter update;
    final planLoader = CinematicMapBackdropLayerPlanLoader();
    addTearDown(planLoader.clear);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SizedBox(
                width: 960,
                height: 540,
                child: PersonalizationProjectMapBackdrop(
                  map: map,
                  colors: context.pokeMapColors,
                  projectRootPath: projectRoot,
                  manifest: currentManifest,
                  planLoader: planLoader,
                ),
              );
            },
          ),
        ),
      ),
    );
    for (var attempt = 0; attempt < 20; attempt += 1) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find
          .byKey(const ValueKey<String>('personalization-project-map-renderer'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-renderer'),
      ),
      findsOneWidget,
    );

    update(() {
      currentManifest = manifest.copyWith(
        presentation: const ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#123456'),
        ),
      );
    });
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-renderer'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-fallback'),
      ),
      findsNothing,
    );
  });
}
