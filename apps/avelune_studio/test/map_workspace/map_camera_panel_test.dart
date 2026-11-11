import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_spatial_settings_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_settings_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
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

  for (final spatial in [false, true]) {
    testWidgets(
      '${spatial ? '3D' : '2D'} map settings retain catalogue actions without the retired camera controls',
      (tester) async {
        final map = MapData(
          id: 'room',
          name: 'Room',
          version: ProjectVersion.v9,
          size: const GridSize(width: 8, height: 8),
          spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
        );
        final view = MapWorkspaceViewState();
        addTearDown(view.dispose);
        var renamed = 0;
        var escapeSettings = 0;
        var changed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: MapSettingsInspector(
                project: const ProjectManifest(
                  name: 'Camera retirement',
                  maps: [],
                  tilesets: [],
                ),
                document: document,
                view: view,
                onChanged: () => changed++,
                onRenameMap: () => renamed++,
                onEscapeSettings: () => escapeSettings++,
              ),
            ),
          ),
        );
        expect(find.text('Room'), findsOneWidget);
        expect(find.text('8 × 8 cases'), findsOneWidget);
        expect(find.text('Caméra du jeu'), findsNothing);
        expect(find.text('Inclinaison en degrés'), findsNothing);
        expect(find.byKey(const ValueKey('map-settings-tabs')), findsNothing);
        await tester.tap(find.text('Renommer la carte…'));
        await tester.tap(find.text('Déplacements et sortie…'));
        expect(renamed, 1);
        expect(escapeSettings, 1);
        expect(changed, 0);
        expect(document.current, same(map));
        expect(document.canUndo, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

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
