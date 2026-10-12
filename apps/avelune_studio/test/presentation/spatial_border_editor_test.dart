import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_border_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/features/resources/border_source_panel.dart';
import 'package:avelune_studio/presentation/features/resources/border_creation_dialog.dart';
import 'package:avelune_studio/presentation/features/resources/border_pattern_panel.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_spatial_preview.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_border_commands_test.dart'
    show borderDocument, borderDraft;
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  testWidgets(
    'tapping the interactive 3D slot preview assigns its active border model',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = spatialBorderVariantProject();
      final oak = project.models3d.firstWhere((model) => model.id == 'oak');
      final replacement = project.models3d.firstWhere(
        (model) => model.id == 'replacement',
      );
      final chosen = <String, ResourceItem>{
        for (final role in ['lineStraight', 'lineCap'])
          role: ResourceItem(
            id: oak.id,
            name: oak.name,
            kind: ResourceKind.decors,
            model3d: oak,
          ),
      };
      final active = ResourceItem(
        id: replacement.id,
        name: replacement.name,
        kind: ResourceKind.decors,
        model3d: replacement,
      );
      final assignments = <(String, String)>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => BorderPatternPanel(
                project: project,
                chosen: chosen,
                active: active,
                visuals: _BorderVisuals(),
                straightOnly: true,
                onAssign: (role, item) => refresh(() {
                  assignments.add((role, item.id));
                  chosen[role] = item;
                }),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      final slot = find.byKey(const ValueKey('border-pattern-Extrémité'));
      final preview = find.descendant(
        of: slot,
        matching: find.byType(TerrainSpatialPreview),
      );
      final scene = find.descendant(
        of: preview,
        matching: find.byType(SpatialSceneView),
      );
      expect(preview, findsOneWidget);
      expect(scene, findsOneWidget);
      final gesture = find.descendant(
        of: scene,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapUp != null,
        ),
      );
      expect(gesture, findsOneWidget);
      expect(
        tester.widget<SpatialSceneView>(scene).scene.instances.single.modelId,
        'oak',
      );
      await tester.tapAt(tester.getCenter(scene));
      await tester.pump();
      expect(assignments, [('lineCap', 'replacement')]);
      expect(chosen['lineCap']!.id, 'replacement');
      expect(
        tester.widget<SpatialSceneView>(scene).scene.instances.single.modelId,
        'replacement',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('STUDIO_BORDER_GPU_TESTS'),
  );

  testWidgets(
    'an incompatible unselected border variant keeps publication disabled until its clip is cleared',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = spatialBorderVariantProject();
      final record = encodeBorderBlueprintRecordJson(
        base.borderCatalog.records.single,
        formatVersion: 5,
      );
      final definition = (record['draft'] as Map)['definition'] as Map;
      final south = (definition['primitives'] as List).cast<Map>().singleWhere(
        (primitive) => primitive['id'] == 'south-cap',
      );
      south['animationIndex'] = 0;
      final project = base.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 5,
          records: [decodeBorderBlueprintRecordJson(record, formatVersion: 5)],
        ),
        models3d: [
          for (final model in base.models3d)
            ProjectModel3dEntry.fromJson({
              ...model.toJson(),
              'inspection': {
                ...model.inspection.toJson(),
                'animations': [
                  if (model.id == 'oak')
                    {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
                ],
              },
            }),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            for (final id in ['oak', 'replacement'])
              ResourceLibraryEntry(
                resourceKind: 'model3d',
                resourceId: id,
                familyId: 'fences',
                role: ResourceLibraryRole.component,
              ),
          ],
        ),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      )..project = project;
      final port = _BorderRequestPort(project);
      final navigation = ResourceNavigation(
        workspace: controller,
        port: port,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => StudioButton(
                label: 'Modifier',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BorderCreationDialog(
                    navigation: navigation,
                    project: project,
                    visuals: WorkspaceTestVisuals(),
                    initialRecord: project.borderCatalog.records.single,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      final publish = find.byKey(const ValueKey('border-publish'));
      final variants = find.byKey(const ValueKey('border-variant-lineCap'));
      expect(tester.widget<StudioButton>(publish).onPressed, isNotNull);
      await tester.tap(variants);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 · vers le sud').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('border-library-replacement')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-pattern-Extrémité')));
      await tester.pumpAndSettle();
      expect(tester.widget<StudioButton>(publish).onPressed, isNull);
      expect(port.request, isNull);
      await tester.ensureVisible(variants);
      await tester.tap(variants);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 · vers le nord').last);
      await tester.pumpAndSettle();
      expect(tester.widget<StudioButton>(publish).onPressed, isNull);
      expect(
        find.textContaining('Choisissez une animation disponible'),
        findsOneWidget,
      );
      expect(port.request, isNull);
      await tester.ensureVisible(variants);
      await tester.tap(variants);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 · vers le sud').last);
      await tester.pumpAndSettle();
      final settingsPiece = find.byKey(const ValueKey('border-settings-piece'));
      await tester.ensureVisible(settingsPiece);
      await tester.tap(settingsPiece);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Extrémité').last);
      await tester.pumpAndSettle();
      final animation = find.byKey(const ValueKey('border-settings-animation'));
      await tester.ensureVisible(animation);
      await tester.tap(animation);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aucune').last);
      await tester.pumpAndSettle();
      expect(tester.widget<StudioButton>(publish).onPressed, isNotNull);
      expect(
        find.textContaining('Choisissez une animation disponible'),
        findsNothing,
      );
      expect(port.request, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'straight border edits one selected terminal variant and publishes without inventing a corner',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = spatialBorderVariantProject().copyWith(
        models3d: [
          for (final model in spatialBorderVariantProject().models3d)
            ProjectModel3dEntry.fromJson({
              ...model.toJson(),
              'inspection': {
                ...model.inspection.toJson(),
                'animations': [
                  {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
                ],
              },
            }),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            for (final id in ['oak', 'replacement'])
              ResourceLibraryEntry(
                resourceKind: 'model3d',
                resourceId: id,
                familyId: 'fences',
                role: ResourceLibraryRole.component,
              ),
          ],
        ),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      )..project = project;
      final port = _BorderRequestPort(project);
      final navigation = ResourceNavigation(
        workspace: controller,
        port: port,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => StudioButton(
                label: 'Modifier',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BorderCreationDialog(
                    navigation: navigation,
                    project: project,
                    visuals: WorkspaceTestVisuals(),
                    initialRecord: project.borderCatalog.records.single,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2 familles de pièces associées'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('border-pattern-Angle haut gauche')),
        findsNothing,
      );
      final variants = find.byKey(const ValueKey('border-variant-lineCap'));
      await tester.tap(variants);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 · vers le sud').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('border-library-replacement')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-pattern-Extrémité')));
      await tester.pumpAndSettle();
      final settingsPiece = find.byKey(const ValueKey('border-settings-piece'));
      await tester.ensureVisible(settingsPiece);
      await tester.tap(settingsPiece);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Extrémité').last);
      await tester.pumpAndSettle();
      final animation = find.byKey(const ValueKey('border-settings-animation'));
      await tester.ensureVisible(animation);
      await tester.tap(animation);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eau').last);
      await tester.pumpAndSettle();
      final loop = find.byKey(const ValueKey('border-settings-loop'));
      await tester.ensureVisible(loop);
      await tester.tap(loop);
      await tester.pumpAndSettle();
      final speed = find.descendant(
        of: find.byKey(const ValueKey('border-settings-speed-south-cap')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(speed);
      await tester.enterText(speed, '0,5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final blocks = find.byKey(
        const ValueKey('border-settings-blocks-movement'),
      );
      await tester.ensureVisible(blocks);
      await tester.tap(blocks);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-publish')));
      await tester.pumpAndSettle();
      expect(port.request!.primitiveModelIds, {'south-cap': 'replacement'});
      expect(port.request!.straightOnly, isTrue);
      expect(port.request!.cornerModelId, isNull);
      expect(port.request!.capModelId, isNull);
      expect(port.request!.primitiveModelSettings, {
        'south-cap': const BorderModelSettings(
          animationIndex: 0,
          animationLoop: false,
          animationSpeed: .5,
          blocksMovement: false,
        ),
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'creating a straight model border needs a body and terminal only',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = spatialBorderProject(straightOnly: true);
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      )..project = project;
      final port = _BorderRequestPort(project);
      final navigation = ResourceNavigation(
        workspace: controller,
        port: port,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => StudioButton(
                label: 'Créer',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BorderCreationDialog(
                    navigation: navigation,
                    project: project,
                    visuals: WorkspaceTestVisuals(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-straight-only')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('border-name')),
        'Clôture droite',
      );
      final publish = find.byKey(const ValueKey('border-publish'));
      expect(tester.widget<StudioButton>(publish).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('border-library-oak')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-pattern-Corps')));
      await tester.pumpAndSettle();
      expect(tester.widget<StudioButton>(publish).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('border-pattern-Extrémité')));
      await tester.pumpAndSettle();
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(port.request!.straightOnly, isTrue);
      expect(port.request!.capModelId, 'oak');
      expect(port.request!.straightModelId, 'oak');
      expect(port.request!.cornerModelId, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'border altitude accepts French decimals without moving pieces before regeneration',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = spatialBorderProject();
      final map = spatialBorderMap();
      final document = borderDocument(map);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(map, project));
      final before = document.current;
      final view = MapWorkspaceViewState()..tool = StudioMapTool.border;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SingleChildScrollView(
                child: MapBorderToolPanel(
                  document: document,
                  project: project,
                  view: view,
                  onChanged: () => refresh(() {}),
                  onCreateModel: () {},
                ),
              ),
            ),
          ),
        ),
      );
      Finder input(String axis) => find.descendant(
        of: find.byKey(ValueKey('border-spatial-offset-$axis')),
        matching: find.byType(TextField),
      );
      await tester.enterText(input('x'), 'NaN');
      await tester.pump();
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('border-spatial-offset-save')),
            )
            .onPressed,
        isNull,
      );
      expect(document.current, same(before));
      await tester.enterText(input('x'), '0,25');
      await tester.enterText(input('y'), '1,5');
      await tester.enterText(input('z'), '-0,25');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('border-spatial-offset-save')),
      );
      await tester.pump();
      final edited = document.current;
      expect(
        edited.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single
            .spatialOffsetWorld,
        Model3dVector3(x: .25, y: 1.5, z: -.25),
      );
      expect(edited.spatialScene, before.spatialScene);
      expect(
        find.textContaining('Le tracé ou une pièce source a changé'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('border-regeneration-preview')),
      );
      await tester.pump();
      expect(document.current, same(edited));
      expect(view.borderPreview, isNotNull);
      await tester.tap(find.byKey(const ValueKey('border-regeneration-apply')));
      await tester.pump();
      expect(
        document.current.spatialScene!.instances.first.position.y,
        closeTo(before.spatialScene!.instances.first.position.y + 1.5, 1e-9),
      );
      expect(
        document.current.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single
            .spatialOffsetWorld,
        Model3dVector3(x: .25, y: 1.5, z: -.25),
      );
      await tester.tap(
        find.byKey(const ValueKey('border-spatial-offset-clear')),
      );
      await tester.pump();
      expect(
        document.current.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single
            .spatialOffsetWorld,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'straight-only model shows its constraint and offset controls scroll at 150 percent',
    (tester) async {
      final project = spatialBorderProject(straightOnly: true);
      final map = spatialBorderMap();
      final document = borderDocument(map);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(map, project).removeLastAngle()!);
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.border
        ..borderBlueprintId = 'fence';
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SizedBox(
                width: 360,
                height: 180,
                child: SingleChildScrollView(
                  child: MapBorderToolPanel(
                    document: document,
                    project: project,
                    view: view,
                    onChanged: () {},
                    onCreateModel: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Tracés droits uniquement · Entrée pour terminer.'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('border-spatial-offset-y')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'border model source picker shares families and excludes unavailable local resources',
    (tester) async {
      final base = spatialBorderProject();
      final project = base.copyWith(
        models3d: [
          ...base.models3d,
          ProjectModel3dEntry(
            id: 'private',
            name: 'Pièce privée',
            sourceAssetId: 'private-source',
            relativePath: 'assets/models3d/private.glb',
            inspection: base.models3d.single.inspection,
          ),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(
              id: 'wooden-fences',
              name: 'Clôtures en bois',
              parentId: 'fences',
            ),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'oak',
              familyId: 'wooden-fences',
            ),
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'private',
              familyId: 'wooden-fences',
              mapId: 'b',
            ),
          ],
        ),
      );
      ResourceItem? chosen;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 650,
              child: BorderSourcePanel(
                project: project,
                visuals: WorkspaceTestVisuals(),
                active: null,
                onActive: (item) => chosen = item,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('border-library-oak')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('border-library-private')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('resource-source-families')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('resource-nature-family-fences')),
      );
      await tester.tap(
        find.byKey(const ValueKey('resource-nature-family-fences')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-library-oak')));
      expect(chosen!.canonicalKind, 'model3d');
      final border = resourceCatalog(project)
          .firstWhere((item) => item.border != null);
      expect(border.compatibleWith(ProjectDimension.threeD), isTrue);
      expect(border.compatibleWith(ProjectDimension.twoD), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the shared border source list scrolls at 150 percent in a short panel',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SizedBox(
                width: 300,
                height: 180,
                child: BorderSourcePanel(
                  project: workspaceProject,
                  visuals: WorkspaceTestVisuals(),
                  active: null,
                  onActive: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    },
  );

  testWidgets(
    'border selection distinguishes identical feature ids in separate layers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = spatialBorderProject();
      final source = spatialBorderMap();
      final document = borderDocument(source);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(source, project));
      final first = document.current.layers.whereType<BorderLayer>().single;
      var map = addBorderLayer(
        document.current,
        id: 'other-border',
        name: 'Deuxième clôture',
      );
      map = upsertBorderFeature(
        map,
        layerId: 'other-border',
        feature: BorderFeature(
          id: first.content.features.single.id,
          name: 'Deuxième clôture',
          blueprintId: 'fence',
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            strokes: [
              BorderStroke(
                id: 'trait',
                points: const [
                  GridPos(x: 6, y: 2),
                  GridPos(x: 7, y: 2),
                  GridPos(x: 8, y: 2),
                ],
                closed: false,
              ),
            ],
          ),
          overrides: const [],
          keepOutRegions: const [],
        ),
        template: BorderBlueprintTemplate.connectedLine,
      );
      map = applySpatialBorderFeaturePreview(
        map,
        manifest: project,
        proposedResult: resolveSpatialBorderFeature(
          manifest: project,
          map: map,
          layerId: 'other-border',
          featureId: first.content.features.single.id,
        ),
      );
      document.commit(map);
      final view = MapWorkspaceViewState()..tool = StudioMapTool.border;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => Align(
                alignment: Alignment.topLeft,
                child: MapBorderToolPanel(
                  document: document,
                  project: project,
                  view: view,
                  onChanged: () => refresh(() {}),
                  onCreateModel: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final picker = tester
          .widget<DropdownButton<({String layerId, String featureId})>>(
            find.byKey(const ValueKey('border-feature-picker')),
          );
      expect(picker.items!.map((item) => item.value).toSet(), hasLength(2));
      picker.onChanged!((
        layerId: 'other-border',
        featureId: first.content.features.single.id,
      ));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('border-regeneration-preview')),
      );
      await tester.pump();
      expect(view.borderPreview!.layerId, 'other-border');
      view.borderFeature = (
        layerId: first.id,
        featureId: first.content.features.single.id,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: MapBorderToolPanel(
              document: document,
              project: project,
              view: view,
              onChanged: () {},
              onCreateModel: () {},
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('border-regeneration-apply')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native trace previews real units then Enter commits once and Escape discards',
    (tester) async {
      final project = spatialBorderProject();
      final map = spatialBorderMap();
      final document = borderDocument(map);
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.border
        ..borderBlueprintId = 'fence';
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SpatialMapEditor(
                document: document,
                controller: controller,
                project: project,
                visuals: _BorderVisuals(),
                view: view,
                onChanged: () => refresh(() {}),
              ),
            ),
          ),
        ),
      );
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      scene().onCell(2, 5);
      await tester.pump();
      scene().onHover!(
        SpatialSurfaceHit(
          position: Model3dVector3(x: 5.5, y: 2, z: 5.5),
          cell: (5, 5),
        ),
      );
      await tester.pump();
      expect(scene().scene.instances, hasLength(4));
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      scene().onCell(5, 5);
      await tester.pump();
      scene().onCell(5, 7);
      await tester.pump();
      final preview = scene().scene;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(view.borderDraft, isNull);
      expect(document.current.spatialScene, preview);
      expect(document.undoCount, 1);
      final applied = document.current;
      scene().onCell(7, 2);
      scene().onCell(9, 2);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(view.borderDraft, isNull);
      expect(document.current, same(applied));
      expect(document.undoCount, 1);
      final id = applied.spatialScene!.instances.first.id;
      view.tool = StudioMapTool.select;
      await tester.pump();
      final hit = SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: id,
        cell: (2, 5),
      );
      expect(scene().onDragStart!(2, 5, hit), isFalse);
      expect(
        document.error,
        SpatialModelEditingCommands.generatedBorderMessage,
      );
      expect(
        view.borderFeature,
        SpatialModelEditingCommands(document, project).borderOwner(id),
      );
      expect(document.undoCount, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native trace rejects source and camera changes without writes', (
    tester,
  ) async {
    final project = spatialBorderProject();
    final document = borderDocument(spatialBorderMap());
    final view = MapWorkspaceViewState()
      ..tool = StudioMapTool.border
      ..borderBlueprintId = 'fence';
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    VoidCallback rebuild = () {};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) {
              rebuild = () => refresh(() {});
              return SpatialMapEditor(
                document: document,
                controller: controller,
                project: project,
                visuals: _BorderVisuals(),
                view: view,
                onChanged: rebuild,
              );
            },
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    scene().onCell(2, 5);
    scene().onCell(5, 5);
    view.spatialFreeView = true;
    rebuild();
    await tester.pump();
    expect(view.borderDraft, isNull);
    expect(document.undoCount, 0);
    scene().onCell(2, 5);
    scene().onCell(5, 5);
    document.commit(document.current.copyWith(name: 'Révision suivante'));
    rebuild();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(view.borderDraft, isNull);
    expect(document.undoCount, 1);
    expect(document.current.layers.whereType<BorderLayer>(), isEmpty);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'regeneration preview cancel apply and feature removal stay explicit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = spatialBorderProject(
        anchor: Model3dVector3(x: .1, y: 0, z: 0),
      );
      final map = spatialBorderMap();
      final document = borderDocument(map);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(map, project));
      final source = document.current;
      final changed = project.copyWith(
        models3d: [project.models3d.single.copyWith(scale: 2)],
      );
      final view = MapWorkspaceViewState()..tool = StudioMapTool.border;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => Align(
                alignment: Alignment.topLeft,
                child: MapBorderToolPanel(
                  document: document,
                  project: changed,
                  view: view,
                  onChanged: () => refresh(() {}),
                  onCreateModel: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Le tracé ou une pièce source a changé.'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('border-regeneration-preview')),
      );
      await tester.pump();
      expect(
        view.borderPreview!.result.spatialScene,
        isNot(source.spatialScene),
      );
      expect(document.current, same(source));
      await tester.tap(find.text('Annuler l’aperçu'));
      await tester.pump();
      expect(view.borderPreview, isNull);
      expect(document.current, same(source));
      await tester.tap(
        find.byKey(const ValueKey('border-regeneration-preview')),
      );
      await tester.pump();
      final result = view.borderPreview!.result;
      await tester.tap(find.byKey(const ValueKey('border-regeneration-apply')));
      await tester.pump();
      expect(document.current, result);
      expect(document.undoCount, 2);
      expect(find.textContaining('Une pièce source a changé.'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('border-feature-delete')));
      await tester.pump();
      expect(document.current.spatialScene!.instances, isEmpty);
      expect(document.undoCount, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an authored native border without generated units can prepare and apply its first preview',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = spatialBorderProject();
      final map = spatialBorderMap();
      final draft = borderDraft(map, project);
      final source = upsertBorderFeature(
        addBorderLayer(map, id: 'border', name: 'Clôtures'),
        layerId: 'border',
        feature: BorderFeature(
          id: 'unmaterialized',
          name: 'Clôture préparée',
          blueprintId: 'fence',
          seed: draft.seed,
          geometry: BorderStrokeGeometry(strokes: [draft.stroke]),
          overrides: const [],
          keepOutRegions: const [],
        ),
        template: BorderBlueprintTemplate.connectedLine,
      );
      final document = borderDocument(source);
      final view = MapWorkspaceViewState()..tool = StudioMapTool.border;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => Align(
                alignment: Alignment.topLeft,
                child: MapBorderToolPanel(
                  document: document,
                  project: project,
                  view: view,
                  onChanged: () => refresh(() {}),
                  onCreateModel: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Ce tracé n’a pas encore ses pièces.'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('border-regeneration-preview')),
      );
      await tester.pump();
      expect(document.current, same(source));
      expect(view.borderPreview!.result.spatialScene!.instances, hasLength(6));
      await tester.tap(find.byKey(const ValueKey('border-regeneration-apply')));
      await tester.pump();
      expect(document.current.spatialScene!.instances, hasLength(6));
      expect(document.undoCount, 1);
      expect(
        find.textContaining('Ce tracé n’a pas encore ses pièces.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the shared border tool opens the same palette on spatial maps', (
    tester,
  ) async {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceToolStrip(
            view: view,
            onChanged: () {},
            onMoreTools: () => opened = true,
            onResources: () {},
            storyAvailable: false,
            paletteVisible: false,
            onUndo: null,
            onRedo: null,
            spatial: true,
          ),
        ),
      ),
    );
    final button = tester.widget<StudioButton>(
      find.widgetWithText(StudioButton, 'Bordures'),
    );
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(view.tool, StudioMapTool.border);
    expect(view.paletteTab, 'Bordures');
    expect(opened, isTrue);
  });
}

class _BorderVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

class _BorderRequestPort implements ResourcePort {
  _BorderRequestPort(this.project);
  final ProjectManifest project;
  BorderCreationRequest? request;
  @override
  Future<ResourceMutationReceipt> createBorder(
    BorderCreationRequest request,
  ) async {
    this.request = request;
    return ResourceMutationReceipt(
      before: project,
      manifest: project,
      beforeRevision: 'r0',
      revision: 'r0',
      changedPaths: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
