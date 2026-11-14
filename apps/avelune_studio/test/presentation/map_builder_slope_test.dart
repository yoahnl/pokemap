import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_slope_tool.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_slope_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

Future<void> _pump(WidgetTester tester, Locale locale, Widget body) =>
    tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      ),
    );

TerrainStairModel _stair(String id, String name) => TerrainStairModel(
  model: ProjectModel3dEntry(
    id: id,
    name: name,
    sourceAssetId: '$id-source',
    relativePath: 'assets/models3d/$id.glb',
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3.zero,
        max: Model3dVector3(x: 3, y: 1, z: 1),
      ),
      meshCount: 1,
      triangleCount: 1,
    ),
  ),
  acrossCells: 3,
  alongCells: 1,
  levels: 1,
  nativeDirection: SpatialRampDirection.north,
);

void main() {
  testWidgets('Pente and Escalier sit next to Relief in Construction', (
    tester,
  ) async {
    StudioMapTool? chosen;
    await _pump(
      tester,
      const Locale('fr'),
      MapBuilderCanvas(
        space: MapBuilderSpace.construction,
        onSpace: (_) {},
        entry: null,
        tool: StudioMapTool.select,
        onTool: (tool) => chosen = tool,
        inspectorOpen: false,
        onToggleInspector: () {},
        error: null,
        reliefAvailable: true,
        reliefNotice: mapBuilderSlopeNotice(
          await AppLocalizations.delegate.load(const Locale('fr')),
          const MapSlopeOutcome(problem: MapSlopeProblem.noRoom),
        ),
        surface: const SizedBox(),
        statusBar: const SizedBox(),
      ),
    );
    final relief = tester.getTopLeft(
      find.byKey(const ValueKey('map-tool-relief')),
    );
    final slope = tester.getTopLeft(
      find.byKey(const ValueKey('map-tool-slope')),
    );
    final stair = tester.getTopLeft(
      find.byKey(const ValueKey('map-tool-stair')),
    );
    expect(relief.dx < slope.dx && slope.dx < stair.dx, isTrue);
    await tester.tap(find.byKey(const ValueKey('map-tool-slope')));
    expect(chosen, StudioMapTool.slope);
    await tester.tap(find.byKey(const ValueKey('map-tool-stair')));
    expect(chosen, StudioMapTool.stair);
    expect(find.textContaining('Pas assez de place'), findsOneWidget);
  });

  testWidgets('the stair inspector lists models and picks one', (tester) async {
    final state = MapSlopeToolState()..stairModelId = 'wide';
    TerrainStairModel? chosen;
    await _pump(
      tester,
      const Locale('fr'),
      MapBuilderSlopeInspector(
        stair: true,
        state: state,
        models: [_stair('wide', 'Escalier large'), _stair('cave', 'Grotte')],
        onModel: (model) => chosen = model,
      ),
    );
    expect(find.text('Modèle d’escalier'), findsOneWidget);
    expect(find.text('3 × 1 cases · monte de 1 niveau(x)'), findsNWidgets(2));
    await tester.tap(find.text('Grotte'));
    expect(chosen?.model.id, 'cave');
    await _pump(
      tester,
      const Locale('fr'),
      MapBuilderSlopeInspector(
        stair: false,
        state: state,
        models: const [],
        onModel: (_) {},
      ),
    );
    expect(find.textContaining('glissez jusqu’au plateau'), findsOneWidget);
  });

  testWidgets('every slope problem has a French and English message', (
    tester,
  ) async {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final problem in MapSlopeProblem.values) {
        final notice = mapBuilderSlopeNotice(
          l10n,
          MapSlopeOutcome(problem: problem),
        );
        expect(notice?.isError, isTrue);
        expect(notice?.message, isNot(contains('spatial.')));
      }
      expect(mapBuilderSlopeNotice(l10n, const MapSlopeOutcome()), isNull);
    }
  });
}
