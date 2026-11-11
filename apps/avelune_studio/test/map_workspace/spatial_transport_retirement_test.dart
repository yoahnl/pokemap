import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_model_entity_controls.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  for (final selectedId in ['platform-deck', 'lift-deck']) {
    testWidgets(
      '$selectedId retains its mechanics and selection without transport panels',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final source = spatialEnvironmentMap();
        final map = source.copyWith(
          spatialScene: source.spatialScene!.copyWith(
            instances: [
              SpatialModelInstance(
                id: 'platform-deck',
                modelId: 'oak',
                blocksMovement: false,
                position: Model3dVector3(x: 2, y: 0, z: 2),
              ),
              SpatialModelInstance(
                id: 'lift-deck',
                modelId: 'oak',
                blocksMovement: false,
                position: Model3dVector3(x: 7, y: 0, z: 2),
              ),
            ],
            platforms: [
              SpatialPlatformDefinition(
                id: 'platform',
                name: 'Traversée',
                instanceId: 'platform-deck',
                x: 2,
                z: 2,
                width: 1,
                depth: 1,
                height: 0,
                durationMs: 1500,
                routes: [
                  SpatialPlatformRoute(
                    id: 'default-route',
                    waypoints: [
                      SpatialPlatformStop(x: 0, z: 0),
                      SpatialPlatformStop(x: 2, z: 0),
                    ],
                  ),
                ],
              ),
            ],
            lifts: [
              SpatialLiftDefinition(
                id: 'lift',
                name: 'Montée',
                instanceId: 'lift-deck',
                x: 7,
                z: 2,
                width: 1,
                depth: 1,
                lowerHeight: 0,
                upperHeight: 2,
                durationMs: 1200,
              ),
            ],
          ),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
        );
        final view = MapWorkspaceViewState();
        final visuals = WorkspaceTestVisuals();
        addTearDown(view.dispose);
        addTearDown(visuals.dispose);
        view.select(document, MapSelectionFamily.decor, selectedId);
        final selection = view.target;
        expect(selection, isNotNull);
        var changed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: MapWorkspaceInspector(
                project: spatialEnvironmentProject(),
                document: document,
                visuals: visuals,
                view: view,
                onChanged: () => changed++,
              ),
            ),
          ),
        );

        expect(find.byType(SpatialModelEntityControls), findsOneWidget);
        for (final field in ['x', 'y', 'rotation', 'height-offset', 'scale']) {
          expect(find.byKey(ValueKey('decor-geometry-$field')), findsOneWidget);
        }
        expect(find.byKey(ValueKey('platform-$selectedId')), findsNothing);
        expect(find.byKey(ValueKey('lift-$selectedId')), findsNothing);
        expect(find.text('Plateforme sur trajet'), findsNothing);
        expect(find.text('Plateforme verticale'), findsNothing);
        expect(
          find.byKey(const ValueKey('spatial-platform-duration')),
          findsNothing,
        );
        expect(document.current, same(map));
        expect(
          document.current.spatialScene!.platforms,
          map.spatialScene!.platforms,
        );
        expect(document.current.spatialScene!.lifts, map.spatialScene!.lifts);
        expect(document.undoCount, 0);
        expect(document.selectedId, selectedId);
        expect(view.target, same(selection));
        expect(changed, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
