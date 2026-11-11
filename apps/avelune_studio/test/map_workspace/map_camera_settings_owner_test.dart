import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_spatial_settings_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  late EditableMapDocument document;
  late MapSpatialSettingsCommands commands;
  setUp(() {
    final map = MapData(
      id: 'room',
      name: 'Room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
    );
    commands = MapSpatialSettingsCommands(document);
  });

  test(
    'camera override notice identifies the effective project camera values',
    () {
      expect(mapCameraOverrides(document), isNull);
      document.visualProfile = SpatialVisualPatch()
          .set(SpatialVisualParameter.cameraDistance, 24.0)
          .set(SpatialVisualParameter.pitchDegrees, 34.0);
      final notice = mapCameraOverrides(document)!;
      expect(notice, contains('Distance 24,00 cases'));
      expect(notice, contains('Inclinaison 34,0°'));
      expect(notice, contains('réglages du projet'));
    },
  );

  test('camera projection edits remain undoable and redoable', () {
    final original = document.current;
    expect(
      commands.camera(
        () => document.current.spatialScene!.camera.copyWith(
          projection: SpatialCameraProjection.orthographic,
        ),
      ),
      isTrue,
    );
    expect(
      document.current.spatialScene!.camera.projection,
      SpatialCameraProjection.orthographic,
    );
    expect(document.canUndo, isTrue);
    document.restore(redo: false);
    expect(document.current, original);
    document.restore(redo: true);
    expect(
      document.current.spatialScene!.camera.projection,
      SpatialCameraProjection.orthographic,
    );
  });

  test(
    'invalid camera input preserves the document and valid input can follow',
    () {
      expect(
        commands.camera(
          () => document.current.spatialScene!.camera.copyWith(
            projection: SpatialCameraProjection.orthographic,
          ),
        ),
        isTrue,
      );
      final source = document.current;
      for (final text in ['0', 'NaN', 'infinity', 'abc']) {
        expect(
          commands.cameraNumber(
            text,
            (value) => document.current.spatialScene!.camera.copyWith(
              orthographicHeight: value,
            ),
          ),
          isFalse,
        );
        expect(document.current, same(source));
        expect(document.error, isNotNull);
      }
      expect(
        commands.cameraNumber(
          '16',
          (value) => document.current.spatialScene!.camera.copyWith(
            orthographicHeight: value,
          ),
        ),
        isTrue,
      );
      expect(document.current.spatialScene!.camera.orthographicHeight, 16);
      expect(document.error, isNull);
    },
  );
}
