import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';

Future<MapEditingViewportSession> _pump(
  WidgetTester tester, {
  required bool spatial,
}) async {
  final view = MapEditingViewportSession();
  if (spatial) view.spatialSceneController = SpatialSceneController();
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MapBuilderStatusBar(
          toolLabel: 'Sélection',
          view: view,
          spatial: spatial,
          onChanged: () {},
        ),
      ),
    ),
  );
  return view;
}

void main() {
  testWidgets(
    '3D zoom in brings the camera closer and zoom out moves it away',
    (tester) async {
      final view = await _pump(tester, spatial: true);
      final camera = view.spatialSceneController!;
      final initial = camera.zoom;

      await tester.tap(find.byKey(const ValueKey('map-status-zoom-in')));
      await tester.pump();
      expect(camera.zoom, lessThan(initial));

      await tester.tap(find.byKey(const ValueKey('map-status-zoom-out')));
      await tester.tap(find.byKey(const ValueKey('map-status-zoom-out')));
      await tester.pump();
      expect(camera.zoom, greaterThan(initial));
    },
  );

  testWidgets('2D zoom in enlarges the map and zoom out shrinks it', (
    tester,
  ) async {
    final view = await _pump(tester, spatial: false);
    final initial = view.scale;

    await tester.tap(find.byKey(const ValueKey('map-status-zoom-in')));
    await tester.pump();
    expect(view.scale, greaterThan(initial));

    await tester.tap(find.byKey(const ValueKey('map-status-zoom-out')));
    await tester.tap(find.byKey(const ValueKey('map-status-zoom-out')));
    await tester.pump();
    expect(view.scale, lessThan(initial));
  });
}
