import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('editing stays clear without changing game presentation', (
    tester,
  ) async {
    final project = spatialEnvironmentProject();
    final map = spatialEnvironmentMap();
    final profile = SpatialVisualPatch.fromJson({
      'pitchDegrees': 34,
      'fieldOfViewDegrees': 20,
      'depthOfFieldEnabled': true,
      'depthOfFieldStrength': .65,
      'depthOfFieldFocusRange': 8,
      'depthFogEnabled': true,
      'halosEnabled': true,
      'fireflies': true,
      'weatherEnabled': true,
      'weatherKind': 'tempest',
      'waterAnimated': true,
      'windowsLit': true,
    });
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    )..visualProfile = profile;
    final view = MapWorkspaceViewState();
    final workspace = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final visuals = _Visuals();
    final game = SpatialSceneController()..visualProfile = profile;
    addTearDown(view.dispose);
    addTearDown(workspace.dispose);
    addTearDown(game.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: workspace,
            project: project,
            visuals: visuals,
            view: view,
            onChanged: () {},
          ),
        ),
      ),
    );
    final editor = tester
        .widget<SpatialSceneView>(find.byType(SpatialSceneView))
        .controller;
    void expectClear() {
      expect(editor.depthOfFieldEnabled, isFalse);
      expect(editor.depthOfFieldProfile.active, isFalse);
      expect(editor.depthFogEnabled, isFalse);
      expect(editor.halosEnabled, isFalse);
      expect(editor.fireflies, isFalse);
      expect(editor.weatherSettings.enabled, isFalse);
    }

    expectClear();
    editor
      ..depthOfFieldEnabled = true
      ..depthFogEnabled = true
      ..halosEnabled = true
      ..fireflies = true;
    editor.applyAtmosphereSettings(
      SpatialAtmosphereSettings(
        depthOfFieldEnabled: true,
        depthFogEnabled: true,
        halosEnabled: true,
        fireflies: true,
        weather: SpatialWeatherSettings(enabled: true, lightning: true),
      ),
    );
    expectClear();
    expect(game.depthOfFieldProfile.active, isTrue);
    expect(game.depthOfFieldProfile.strength, .65);
    expect(game.depthOfFieldProfile.focusRange, 8);
    expect(game.depthFogEnabled, isTrue);
    expect(game.halosEnabled, isTrue);
    expect(game.fireflies, isTrue);
    expect(game.weatherSettings.enabled, isTrue);
    expect(game.weatherSettings.kind, SpatialWeatherKind.tempest);
    expect(editor.effectiveCamera(map.spatialScene!.camera).pitchDegrees, 34);
    expect(
      editor.effectiveCamera(map.spatialScene!.camera).fieldOfViewDegrees,
      20,
    );
    expect(editor.waterAnimated, isTrue);
    expect(editor.windowsLit, isTrue);
    expect(document.visualProfile, same(profile));
    expect(document.current, same(map));
    expect(document.dirty, isFalse);
    expect(document.undoCount, 0);
    await tester.pumpWidget(const SizedBox());
  });
}

final class _Visuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
