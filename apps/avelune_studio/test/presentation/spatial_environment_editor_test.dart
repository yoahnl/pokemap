import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:avelune_studio/presentation/features/resources/environment_editor_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets(
    'model picker uses shared nature families and project eligibility',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final base = spatialEnvironmentProject();
      final project = base.copyWith(
        models3d: [
          ...base.models3d,
          ProjectModel3dEntry(
            id: 'other-oak',
            name: 'Chêne privé',
            sourceAssetId: 'other-source',
            relativePath: 'assets/models3d/other-oak.glb',
            inspection: base.models3d.single.inspection,
          ),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(id: 'oaks', name: 'Chênes', parentId: 'trees'),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'oak',
              familyId: 'oaks',
            ),
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'other-oak',
              familyId: 'oaks',
              mapId: 'a',
            ),
          ],
        ),
      );
      final draft = EnvironmentDraft()..name = 'Bosquet';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnvironmentEditorScreen(
              draft: draft,
              project: project,
              visuals: WorkspaceTestVisuals(),
              onSave: () async {},
              onChanged: () {},
              onClose: () {},
              onDiscard: () {},
              onEditDecor: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('environment-add-decor')));
      await tester.pumpAndSettle();
      expect(find.text('Chêne unitaire'), findsOneWidget);
      expect(find.text('Chêne privé'), findsNothing);
      expect(
        find.byKey(const ValueKey('environment-decor-tree')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('environment-decor-families')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('resource-nature-family-oaks')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chêne unitaire'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('environment-decor-oak')));
      await tester.pumpAndSettle();
      expect(draft.build().palette.single.modelId, 'oak');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('environment-offset-oak-x')),
          matching: find.byType(TextField),
        ),
        '0,25',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('environment-offset-oak-z')),
          matching: find.byType(TextField),
        ),
        '-0,5',
      );
      expect(draft.build().palette.single.cellOffsetWorld!.x, .25);
      expect(draft.build().palette.single.cellOffsetWorld!.z, -.5);
      expect(find.text('Volume du modèle'), findsOneWidget);
      expect(find.text('Définir ses collisions'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('environment-add-decor')));
      await tester.pumpAndSettle();
      expect(find.text('Aucun autre décor disponible.'), findsOneWidget);
    },
  );

  test('catalogue keeps 2D and spatial environments eligible only in their dimension', () {
    final spatial = spatialEnvironmentProject();
    final item = resourceCatalog(spatial)
        .firstWhere((item) => item.environment != null);
    expect(item.compatibleWith(ProjectDimension.threeD), isTrue);
    expect(item.compatibleWith(ProjectDimension.twoD), isFalse);
    final model = resourceCatalog(spatial)
        .firstWhere((item) => item.model3d != null);
    expect(model.usages, contains(ResourceCatalogUsage.scatter));
    final planar = ResourceItem(
      id: 'flowers',
      name: 'Fleurs',
      kind: ResourceKind.decors,
      environment: EnvironmentPreset(
        id: 'flowers',
        name: 'Fleurs',
        templateId: 'manual',
        sortOrder: 0,
        palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
      ),
    );
    expect(planar.compatibleWith(ProjectDimension.threeD), isFalse);
    expect(planar.compatibleWith(ProjectDimension.twoD), isTrue);
  });
}
