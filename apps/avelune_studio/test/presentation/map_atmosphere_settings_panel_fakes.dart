import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const atmosphereSession = ProjectSession(
  sessionId: 's',
  name: 'Copy',
  directoryPath: '/copy',
);

class AtmospherePanelPort implements MapAtmospherePort {
  var writes = 0;
  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => MapAtmosphereState(
    revision: 'r0',
    settings: SpatialAtmosphereSettings(
      waterTargets: [
        SpatialAtmosphereMaterialTarget(
          instanceId: 'river',
          materialName: 'water',
        ),
      ],
      windows: [
        SpatialAtmosphereWindow(
          target: SpatialAtmosphereMaterialTarget(
            instanceId: 'house',
            materialName: 'glass',
          ),
          uvRects: [
            SpatialAtmosphereUvRect(left: 0, top: 0, right: 1, bottom: 1),
          ],
        ),
      ],
      fireflyZones: [
        SpatialAtmosphereFireflyZone(
          bounds: Model3dBounds(
            min: Model3dVector3(x: 0, y: 0, z: 0),
            max: Model3dVector3(x: 2, y: 2, z: 2),
          ),
        ),
      ],
      halos: [
        SpatialAtmosphereHalo(
          instanceId: 'lamp',
          localPosition: Model3dVector3(x: 0, y: 2, z: 0),
        ),
      ],
    ),
  );
  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async {
    writes++;
    return MapAtmosphereState(settings: settings, revision: 'r$writes');
  }
}
