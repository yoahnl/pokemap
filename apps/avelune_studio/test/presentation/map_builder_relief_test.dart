import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_relief_tool.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_relief_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_relief_palette.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

Widget _canvas({
  required bool relief,
  StudioMapTool tool = StudioMapTool.select,
  ValueChanged<StudioMapTool>? onTool,
  ({String message, bool isError})? notice,
}) => MapBuilderCanvas(
  space: MapBuilderSpace.construction,
  onSpace: (_) {},
  entry: null,
  tool: tool,
  onTool: onTool ?? (_) {},
  inspectorOpen: false,
  onToggleInspector: () {},
  error: null,
  reliefAvailable: relief,
  reliefPalette: relief && tool == StudioMapTool.relief
      ? MapBuilderReliefPalette(
          palette: const MapReliefPalette(levels: [3, 2, 1, 0], ground: 1),
          level: 2,
          onLevel: (_) {},
        )
      : null,
  reliefNotice: notice,
  surface: const SizedBox(),
  statusBar: const SizedBox(),
);

void main() {
  testWidgets('the relief tool appears for 3D construction only', (
    tester,
  ) async {
    await _pump(tester, const Locale('fr'), _canvas(relief: false));
    expect(find.byKey(const ValueKey('map-tool-relief')), findsNothing);
    StudioMapTool? chosen;
    await _pump(
      tester,
      const Locale('fr'),
      _canvas(relief: true, onTool: (tool) => chosen = tool),
    );
    await tester.tap(find.byKey(const ValueKey('map-tool-relief')));
    expect(chosen, StudioMapTool.relief);
    expect(find.byKey(const ValueKey('map-relief-palette')), findsNothing);
    await _pump(
      tester,
      const Locale('fr'),
      _canvas(relief: true, tool: StudioMapTool.relief),
    );
    expect(find.byKey(const ValueKey('map-relief-palette')), findsOneWidget);
    expect(find.text('Hauteur'), findsOneWidget);
  });

  testWidgets('the palette marks the ground and chooses a level', (
    tester,
  ) async {
    int? chosen;
    await _pump(
      tester,
      const Locale('fr'),
      Row(
        children: [
          MapBuilderReliefPalette(
            palette: const MapReliefPalette(levels: [3, 2, 1, 0], ground: 1),
            level: 2,
            onLevel: (level) => chosen = level,
          ),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Niveau 1 · Sol de la carte'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-relief-level-3')));
    expect(chosen, 3);
    await tester.tap(find.byKey(const ValueKey('map-relief-level-up')));
    expect(chosen, 3);
    await tester.tap(find.byKey(const ValueKey('map-relief-level-down')));
    expect(chosen, 1);
  });

  testWidgets('the inspector lists styles and explains outcomes', (
    tester,
  ) async {
    final state = MapReliefToolState()..profileId = 'rock';
    MapReliefProfile? chosen;
    await _pump(
      tester,
      const Locale('fr'),
      MapBuilderReliefInspector(
        state: state,
        profiles: const [
          MapReliefProfile(id: 'rock', name: 'Roche', twoLevelId: 'rock-2'),
          MapReliefProfile(id: 'grass', name: 'Herbe'),
        ],
        onProfile: (profile) => chosen = profile,
      ),
    );
    expect(find.text('Style des falaises'), findsOneWidget);
    expect(find.text('Variante sur deux niveaux disponible'), findsOneWidget);
    await tester.tap(find.text('Herbe'));
    expect(chosen?.id, 'grass');

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      mapBuilderReliefNotice(
        l10n,
        const MapReliefOutcome(warnings: {MapReliefWarning.unreachable}),
      ),
      (
        message: 'Zone inaccessible : ajoutez une pente ou un escalier',
        isError: false,
      ),
    );
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    for (final problem in MapReliefProblem.values) {
      final notice = mapBuilderReliefNotice(
        english,
        MapReliefOutcome(problem: problem),
      );
      expect(notice?.isError, isTrue);
      expect(notice?.message, isNot(contains('spatial.')));
    }
    await _pump(
      tester,
      const Locale('fr'),
      _canvas(
        relief: true,
        tool: StudioMapTool.relief,
        notice: mapBuilderReliefNotice(
          l10n,
          const MapReliefOutcome(problem: MapReliefProblem.narrowCorner),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('map-relief-notice')), findsOneWidget);
    expect(find.textContaining('Coin trop étroit'), findsOneWidget);
  });
}
