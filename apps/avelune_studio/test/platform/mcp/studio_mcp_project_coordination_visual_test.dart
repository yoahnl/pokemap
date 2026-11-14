import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../support/scoped_map_workspace_port.dart';
import 'studio_mcp_project_coordination_fakes.dart';

void main() {
  for (final global in [false, true]) {
    for (final dirtyOwner in [false, true]) {
      test(
        'visual file refresh preserves dirty geometry: global=$global dirtyOwner=$dirtyOwner',
        () async {
          final port = VisualCoordinationPort();
          final controller = MapWorkspaceController(scopedMapSession, port);
          addTearDown(controller.dispose);
          await controller.initialize();
          final a = controller.active!;
          final owner = ProjectVisualsController(
            session: scopedMapSession,
            port: port,
          );
          await owner.open(map: firstScopedMap);
          a.weatherVisuals = owner;
          if (dirtyOwner) {
            owner.edit(
              SpatialVisualPatch({SpatialVisualParameter.waterAnimated: true}),
            );
          }
          final preview = owner.preview.value;
          final saved = owner.saved;
          a.commit(a.current.copyWith(name: 'Geometry draft'));
          final base = a.base;
          final undo = a.undoToken;
          if (global) {
            port.projectState = ProjectVisualsState(
              profile: SpatialVisualPatch({
                SpatialVisualParameter.minuteOfDay: 960.0,
              }),
              revision: 'project-2',
            );
          } else {
            port.mapState = ProjectVisualsState(
              profile: SpatialVisualPatch({
                SpatialVisualParameter.depthOfFieldEnabled: true,
              }),
              revision: 'map-visual-2',
            );
          }
          await controller.acceptExternalMutation({
            (
              kind: 'visualSettings',
              id: global
                  ? SpatialVisualDocument.projectRelativePath
                  : SpatialVisualDocument.relativePathForMap('first'),
            ),
          });
          expect(controller.active, same(a));
          expect(a.current.name, 'Geometry draft');
          expect(a.base, same(base));
          expect(a.undoToken, same(undo));
          expect(a.error, isNull);
          expect(controller.error, isNull);
          expect(a.weatherVisuals, same(owner));
          if (global || dirtyOwner) {
            expect(owner.preview.value, same(preview));
            expect(owner.saved, same(saved));
          } else {
            expect(owner.preview.value, port.mapState.profile);
            expect(owner.saved!.revision, 'map-visual-2');
          }
          if (global) {
            expect(owner.error, isNull);
            expect(
              a.visualProfile.value(SpatialVisualParameter.minuteOfDay),
              960.0,
            );
          } else if (dirtyOwner) {
            expect(owner.error, contains('externe'));
          }
          controller.restore(redo: false);
          expect(a.current.name, firstScopedMap.name);
          expect(a.error, isNull);
          expect(await controller.save(a), global || !dirtyOwner);
        },
      );
    }
  }

  for (final global in [false, true]) {
    test(
      'settings visual owner conflicts only for its own scope: global=$global',
      () async {
        final port = VisualCoordinationPort();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Geometry draft'));
        final owner = ProjectVisualsController(
          session: scopedMapSession,
          port: port,
        );
        addTearDown(owner.dispose);
        await owner.open();
        controller.settingsVisualsOwner = owner;
        owner.edit(
          SpatialVisualPatch({SpatialVisualParameter.waterAnimated: true}),
        );
        final preview = owner.preview.value;
        final saved = owner.saved;
        port.projectState = ProjectVisualsState(
          profile: SpatialVisualPatch({
            SpatialVisualParameter.minuteOfDay: 960.0,
          }),
          revision: 'project-2',
        );
        port.mapState = ProjectVisualsState(
          profile: SpatialVisualPatch({
            SpatialVisualParameter.depthOfFieldEnabled: true,
          }),
          revision: 'map-visual-2',
        );
        await controller.acceptExternalMutation({
          (
            kind: 'visualSettings',
            id: global
                ? SpatialVisualDocument.projectRelativePath
                : SpatialVisualDocument.relativePathForMap('first'),
          ),
        });
        expect(controller.active, same(a));
        expect(a.error, isNull);
        expect(owner.preview.value, same(preview));
        expect(owner.saved, same(saved));
        expect(owner.canUndo, isTrue);
        if (global) {
          expect(owner.error, contains('externe'));
        } else {
          expect(owner.error, isNull);
        }
        controller.restore(redo: false);
        expect(a.current.name, firstScopedMap.name);
        expect(await controller.save(a), isTrue);
      },
    );
  }

  for (final kind in ['mapAtmosphere', 'mapEditor', 'mapExteriorDecoration']) {
    for (final dirtyOwner in [false, true]) {
      test(
        'secondary file refresh preserves geometry and unrelated owners: $kind/$dirtyOwner',
        () async {
          final port = OwnerCoordinationPort();
          final controller = MapWorkspaceController(scopedMapSession, port);
          addTearDown(controller.dispose);
          await controller.initialize();
          final a = controller.active!;
          a.atmosphere ??= await MapAtmosphereController.open(
            scopedMapSession,
            'first',
            port,
          );
          a.exteriorDecoration ??= await MapExteriorDecorationController.open(
            scopedMapSession,
            a.current,
            port,
          );
          final atmosphere = a.atmosphere;
          final editor = a.editor;
          final exterior = a.exteriorDecoration;
          if (dirtyOwner) {
            switch (kind) {
              case 'mapAtmosphere':
                a.atmosphere!.edit(
                  SpatialAtmosphereSettings(waterAnimated: true),
                );
              case 'mapEditor':
                a.editor!.current = a.editor!.current.copyWith(
                  hiddenFamilies: {'decor'},
                );
              case 'mapExteriorDecoration':
                a.exteriorDecoration!.configureMargins(
                  west: 1,
                  east: 1,
                  north: 1,
                  south: 1,
                );
            }
          }
          final preview = switch (kind) {
            'mapAtmosphere' => a.atmosphere!.current,
            'mapEditor' => a.editor!.current,
            _ => a.exteriorDecoration!.current,
          };
          a.commit(a.current.copyWith(name: 'Geometry draft'));
          final undo = a.undoToken;
          final base = a.base;
          port.atmosphere = MapAtmosphereState(
            settings: SpatialAtmosphereSettings(windowsLit: true),
            revision: 'atmosphere-2',
          );
          port.editor = MapEditorWorkspaceState(
            state: MapEditorState(hiddenFamilies: {'model'}),
            revision: 'editor-2',
          );
          port.exterior = MapExteriorDecorationState(
            decoration: MapExteriorDecoration(
              mapId: 'first',
              playableWidth: 2,
              playableDepth: 2,
              west: 2,
              east: 2,
              north: 2,
              south: 2,
            ),
            revision: 'exterior-2',
          );
          await controller.acceptExternalMutation({(kind: kind, id: 'first')});
          expect(controller.active, same(a));
          expect(a.current.name, 'Geometry draft');
          expect(a.base, same(base));
          expect(a.undoToken, same(undo));
          expect(a.error, isNull);
          if (kind != 'mapAtmosphere') expect(a.atmosphere, same(atmosphere));
          if (kind != 'mapEditor') expect(a.editor, same(editor));
          if (kind != 'mapExteriorDecoration') {
            expect(a.exteriorDecoration, same(exterior));
          }
          final current = switch (kind) {
            'mapAtmosphere' => a.atmosphere!.current,
            'mapEditor' => a.editor!.current,
            _ => a.exteriorDecoration!.current,
          };
          final error = switch (kind) {
            'mapAtmosphere' => a.atmosphere!.error,
            'mapEditor' => a.editor!.error,
            _ => a.exteriorDecoration!.error,
          };
          if (dirtyOwner) {
            expect(current, same(preview));
            expect(error, contains('externe'));
          } else {
            expect(current, isNot(preview));
            expect(error, isNull);
          }
          controller.restore(redo: false);
          expect(a.current.name, firstScopedMap.name);
          expect(await controller.save(a), !dirtyOwner);
          expect(port.unexpectedWrites, 0);
        },
      );
    }
  }
}
