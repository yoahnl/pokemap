import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_ramp_fixture.dart';

void main() {
  test('fractional stair endpoints retain edit preview apply and undo without snapping', () {
    final ramp = SpatialRamp.fromJson({
      'id': 'stairs',
      'x': 2,
      'z': 2,
      'width': 1,
      'depth': 2,
      'lowLevel': 0,
      'highLevel': 1.12542724609375,
      'direction': 'north',
      'surfaceInstanceId': 'stairs',
    });
    final map = MapData(
      id: 'map',
      name: 'Fractional stairs',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        navigation: SpatialNavigationProfile(ramps: [ramp]),
        instances: [
          SpatialModelInstance(
            id: 'stairs',
            modelId: 'model',
            position: Model3dVector3(x: 2, y: 0, z: 2),
            blocksMovement: false,
          ),
        ],
      ),
    );
    final document = rampDocument(map);
    final view = MapWorkspaceEditingState();
    final editing = SpatialRampEditingSession(document, view);
    addTearDown(editing.dispose);
    expect(editing.highLevel, '1.12542724609375');
    editing.highLevel = '1,5';
    editing.preview();
    expect(view.rampPreview!.updatedRamp.highLevel, 1.5);
    expect(document.current, map);
    editing.apply();
    expect(
      document.current.spatialScene!.navigation.ramps.single.highLevel,
      1.5,
    );
    expect(
      document.current.spatialScene!.heightLevels,
      map.spatialScene!.heightLevels,
    );
    final applied = document.current;
    editing.highLevel = 'NaN';
    editing.preview();
    expect(view.rampPreview, isNull);
    expect(document.current, applied);
    expect(editing.error, contains('nombre fini'));
    document.restore(redo: false);
    expect(document.current, map);
  });
}
