import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_relief_tool.dart';
import 'package:avelune_studio/features/map_workspace/application/map_slope_tool.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_relief_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_relief_palette.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_slope_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

Future<void> _pump(WidgetTester tester, Widget body) => tester.pumpWidget(
  MaterialApp(
    theme: studioTheme(),
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: body),
  ),
);

Widget _inspector(Widget body) => Row(
  children: [
    MapBuilderInspector(
      entry: null,
      projectName: 'Projet',
      armed: null,
      toolLabel: null,
      toolHint: null,
      onRelease: () {},
      onCollapse: () {},
      body: body,
    ),
  ],
);

Widget _canvas(({String message, bool isError})? notice, {String? error}) =>
    MapBuilderCanvas(
      space: MapBuilderSpace.construction,
      onSpace: (_) {},
      entry: null,
      tool: StudioMapTool.relief,
      onTool: (_) {},
      inspectorOpen: false,
      onToggleInspector: () {},
      error: error,
      reliefAvailable: true,
      reliefPalette: MapBuilderReliefPalette(
        palette: const MapReliefPalette(levels: [3, 2, 1, 0], ground: 1),
        level: 2,
        onLevel: (_) {},
      ),
      reliefNotice: notice,
      surface: const SizedBox.expand(key: ValueKey('surface')),
      statusBar: const SizedBox(),
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
  testWidgets('the Propriétés panel shows the relief styles', (tester) async {
    await _pump(
      tester,
      _inspector(
        MapBuilderReliefInspector(
          state: MapReliefToolState()..profileId = 'rock',
          profiles: const [
            MapReliefProfile(id: 'rock', name: 'Roche'),
            MapReliefProfile(id: 'grass', name: 'Herbe'),
          ],
          onProfile: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Style des falaises'), findsOneWidget);
    expect(find.text('Herbe'), findsOneWidget);
  });

  testWidgets('the Propriétés panel shows the stair models and slope help', (
    tester,
  ) async {
    String? chosen;
    await _pump(
      tester,
      _inspector(
        MapBuilderSlopeInspector(
          stair: true,
          state: MapSlopeToolState(),
          models: [_stair('wide', 'Escalier large')],
          onModel: (model) => chosen = model.model.id,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Escalier large'));
    expect(chosen, 'wide');

    await _pump(
      tester,
      _inspector(
        MapBuilderSlopeInspector(
          stair: false,
          state: MapSlopeToolState(),
          models: const [],
          onModel: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('glissez jusqu’au plateau'), findsOneWidget);
  });

  testWidgets('a relief notice does not move the palette or the map', (
    tester,
  ) async {
    await _pump(tester, _canvas(null));
    final level = find.byKey(const ValueKey('map-relief-level-3'));
    final surface = find.byKey(const ValueKey('surface'));
    final before = (tester.getTopLeft(level), tester.getRect(surface));

    await _pump(
      tester,
      _canvas((message: 'Ce style ne convient pas.', isError: true)),
    );

    expect(find.byKey(const ValueKey('map-relief-notice')), findsOneWidget);
    expect(find.text('Ce style ne convient pas.'), findsOneWidget);
    expect((tester.getTopLeft(level), tester.getRect(surface)), before);
  });

  testWidgets('a map banner does not hide the relief refusal', (tester) async {
    await _pump(
      tester,
      _canvas((
        message: 'Coin trop étroit.',
        isError: true,
      ), error: 'Aperçu des personnages indisponible : Léo'),
    );
    expect(
      find.text('Aperçu des personnages indisponible : Léo'),
      findsOneWidget,
    );
    expect(find.text('Coin trop étroit.'), findsOneWidget);
  });
}
