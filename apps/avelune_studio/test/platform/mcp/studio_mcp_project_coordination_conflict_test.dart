import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../support/scoped_map_workspace_port.dart';
import 'studio_mcp_project_coordination_fakes.dart';

void main() {
  for (final savedHistory in [false, true]) {
    test(
      'dependency refresh preserves ${savedHistory ? 'saved history' : 'dirty draft'} without a conflict',
      () async {
        final port = CoordinationPort();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Human edit'));
        if (savedHistory) a.acceptSave(a.current, a.base.revision);
        final undo = a.undoToken;
        final base = a.base;
        port.tilesetName = 'Updated tileset';
        await controller.acceptExternalMutation({
          (kind: 'tileset', id: 'first'),
        });
        expect(controller.active, same(a));
        expect(a.current.name, 'Human edit');
        expect(a.base, same(base));
        expect(a.undoToken, same(undo));
        expect(a.error, isNull);
        expect(controller.error, isNull);
        expect(
          controller.visualProject!.tilesets.single.name,
          'Updated tileset',
        );
        controller.restore(redo: false);
        expect(a.current.name, firstScopedMap.name);
        expect(a.error, isNull);
        expect(await controller.save(a), isTrue);
      },
    );
  }

  for (final renamed in [false, true]) {
    for (final dirty in [false, true]) {
      test(
        'external ${renamed ? 'rename' : 'delete'} closes a clean selection and preserves a dirty one: $dirty',
        () async {
          final port = CoordinationPort();
          final controller = MapWorkspaceController(scopedMapSession, port);
          addTearDown(controller.dispose);
          await controller.initialize();
          final a = controller.active!;
          if (dirty) a.commit(a.current.copyWith(name: 'Protected draft'));
          final undo = a.undoToken;
          final previewB = controller.previewMap(secondScopedMap.id);
          await previewB;
          port.externalMetadata = scopedMapMetadata.copyWith(
            maps: [
              if (renamed)
                firstScopedMap.copyWith(
                  id: 'renamed',
                  name: 'Renamed',
                  relativePath: 'renamed.json',
                ),
              secondScopedMap,
            ],
          );
          await controller.acceptExternalMutation({
            (kind: 'map', id: 'first'),
            (kind: 'project', id: 'project'),
            if (renamed) (kind: 'map', id: 'renamed'),
          });
          expect(
            controller.project!.maps.any((entry) => entry.id == 'first'),
            isFalse,
          );
          expect(
            controller.project!.maps.any((entry) => entry.id == 'renamed'),
            renamed,
          );
          expect(controller.previewMap(secondScopedMap.id), same(previewB));
          if (dirty) {
            expect(controller.active, same(a));
            expect(controller.documents['first'], same(a));
            expect(a.current.name, 'Protected draft');
            expect(a.undoToken, same(undo));
            expect(a.error, contains('externe'));
            expect(await controller.save(a), isFalse);
          } else {
            expect(controller.active, isNull);
            expect(controller.documents.containsKey('first'), isFalse);
            expect(controller.previewDefinitionsFor('first'), isNull);
            expect(
              controller.visualProject!.maps.any(
                (entry) => entry.id == 'first',
              ),
              isFalse,
            );
          }
        },
      );
    }
  }

  test(
    'dirty document and local undo survive with an explicit conflict',
    () async {
      final port = CoordinationPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      a.commit(a.current.copyWith(name: 'Brouillon'));
      final token = a.undoToken;
      port.revision = 'map-external';
      await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
      expect(controller.active, same(a));
      expect(a.current.name, 'Brouillon');
      expect(a.base.revision, 'map-1');
      expect(a.undoToken, same(token));
      expect(a.error, contains('externe'));
      expect(await controller.save(a), isFalse);
      expect(a.current.name, 'Brouillon');
    },
  );

  test(
    'saved local history is retained and cannot undo an external publication',
    () async {
      final port = CoordinationPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      a.commit(a.current.copyWith(name: 'Previously saved'));
      a.acceptSave(a.current, 'map-1');
      final token = a.undoToken;
      port.revision = 'external-publication';
      await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
      controller.restore(redo: false);
      expect(controller.active, same(a));
      expect(a.current.name, 'Previously saved');
      expect(a.undoToken, same(token));
      expect(a.error, contains('externe'));
    },
  );

  for (final owner in ['editor', 'atmosphere', 'exterior', 'weather']) {
    test('a dirty $owner owner protects the complete document', () async {
      final port = CoordinationPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      final secondary = SecondaryCoordinationPort();
      switch (owner) {
        case 'editor':
          final editor = MapEditorController(
            session: scopedMapSession,
            mapId: 'first',
            port: EditorCoordinationPort(),
            state: MapEditorWorkspaceState(
              state: MapEditorState(),
              revision: 'editor-1',
            ),
          );
          a.editor = editor;
          editor.current = editor.current.copyWith(hiddenFamilies: {'decor'});
        case 'atmosphere':
          a.atmosphere = await MapAtmosphereController.open(
            scopedMapSession,
            'first',
            secondary,
          );
          a.atmosphere!.edit(SpatialAtmosphereSettings(waterAnimated: true));
        case 'exterior':
          a.exteriorDecoration = await MapExteriorDecorationController.open(
            scopedMapSession,
            a.current,
            secondary,
          );
          a.exteriorDecoration!.configureMargins(
            west: 1,
            east: 1,
            north: 1,
            south: 1,
          );
        case 'weather':
          a.weatherVisuals = ProjectVisualsController(
            session: scopedMapSession,
            port: secondary,
          );
          await a.weatherVisuals!.open(map: firstScopedMap);
          a.weatherVisuals!.edit(
            SpatialVisualPatch({SpatialVisualParameter.waterAnimated: true}),
          );
      }
      port.revision = 'external-publication';
      await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
      expect(controller.active, same(a));
      expect(switch (owner) {
        'editor' => a.editor!.dirty,
        'atmosphere' => a.atmosphere!.dirty,
        'exterior' => a.exteriorDecoration!.dirty,
        _ => a.weatherVisuals!.dirty,
      }, isTrue);
      expect(a.error, contains('externe'));
    });
  }
}
