import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_bindings.dart';
import 'package:avelune_studio/presentation/features/resources/resource_management_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';
import '../../../../packages/map_authoring/test/support/glb_fixture.dart';

void main() {
  testWidgets(
    'context-only classification saves reopens and clears all seven resource kinds',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      host.navigation.library.query = 'Arbre';
      final input = File('${host.fixture.directory.path}/context-source.glb');
      await tester.runAsync(() => input.writeAsBytes(triangleGlb()));
      final imported = (await tester.runAsync(
        () => host.fixture.resources.importModel(
          sourcePath: input.path,
          name: 'Modèle contexte',
        ),
      ))!;
      final acceptance = host.navigation.accept(imported);
      await pumpIo(tester);
      await acceptance;
      final original = host.navigation.workspace.project!;
      final project = original.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const [
            ProjectSmartTileMaterial(
              id: 'path',
              name: 'Chemin',
              connectionGroupId: 'path',
            ),
          ],
          presets: [
            const ProjectSmartTilePreset(
              id: 'path-context',
              name: 'Chemin de contexte',
              usage: SmartTileUsage.path,
              topology: SmartTileTopology.uniform,
              templateHint: SmartTileTemplateHint.simple,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'path',
              allowedMaterialIds: ['path'],
            ),
          ],
        ),
        environmentPresets: [
          EnvironmentPreset(
            id: 'garden-context',
            name: 'Jardin de contexte',
            templateId: 'manual',
            sortOrder: 0,
            palette: [EnvironmentPaletteItem(elementId: 'arbre', weight: 1)],
            defaultParams: EnvironmentGenerationParams.standard(),
          ),
        ],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.formatVersionV2,
          records: [
            BorderBlueprintRecord(
              id: 'border-context',
              draft: BorderBlueprintDraft(
                baseRevision: 0,
                definition: BorderBlueprintDraftDefinition(
                  name: 'Bordure de contexte',
                  previewSeed: BorderSignedInt64.zero,
                  template: BorderBlueprintTemplate.connectedLine,
                  primitives: const [],
                  defaults: BorderGenerationParams(
                    irregularityPermille: 0,
                    detailDensityPermille: 0,
                    variationPermille: 0,
                    maxOverlapPx: 0,
                    gapTolerancePx: 0,
                    depthRows: 1,
                  ),
                  sortOrder: 0,
                ),
              ),
            ),
          ],
        ),
      );
      ProjectValidator.validate(project);
      await tester.runAsync(
        () =>
            File('${host.fixture.directory.path}/project.json')
                .writeAsString(jsonEncode(project.toJson())),
      );
      await tester.runAsync(
        () => host.fixture.port.loadProject(host.fixture.session),
      );
      host.fixture.controller.project = project;
      host.navigation.changed();
      await pumpIo(tester);
      final mapsBefore = {
        for (final entry in host.fixture.controller.documents.entries)
          entry.key: entry.value.current,
      };
      final items = resourceCatalog(project);
      for (final kind in [
        'element',
        'smartTilePreset',
        'tileset',
        'model3d',
        'borderBlueprint',
        'environmentPreset',
        'character',
      ]) {
        final item = items.firstWhere((item) => item.canonicalKind == kind);
        for (final label in [
          'Intérieur',
          'Extérieur',
          'Les deux',
          'Non renseigné',
        ]) {
          final pending = classifyResource(
            tester.element(find.byType(Scaffold).first),
            host.navigation,
            item,
          );
          await pumpIo(tester);
          await host.choose('resource-classify-context', label);
          await host.tap('resource-management-save');
          expect(
            find.byKey(const ValueKey('resource-management-error')),
            findsNothing,
            reason: '$kind $label',
          );
          await pending;
          final reopened = await host.reopen();
          final expected = switch (label) {
            'Intérieur' => ResourcePlacementContext.interior,
            'Extérieur' => ResourcePlacementContext.exterior,
            'Les deux' => ResourcePlacementContext.both,
            _ => null,
          };
          final entry = reopened.resourceLibraryCatalog.entryFor(kind, item.id);
          expect(entry?.placementContext, expected, reason: '$kind $label');
          expect(resourceCatalogContextLabel(reopened, item), label);
          expect(entry?.familyId, isNull);
          expect(entry?.mapId, isNull);
          expect(
            entry?.role ?? ResourceLibraryRole.standard,
            ResourceLibraryRole.standard,
          );
          expect(find.byType(ResourceManagementDialog), findsNothing);
        }
      }
      for (final entry in host.fixture.controller.documents.entries) {
        expect(entry.value.current, mapsBefore[entry.key]);
      }
      expect((await host.reopen()).resourceLibraryCatalog.entries, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'component classification persists and library hides it until requested',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final item = resourceCatalog(host.navigation.workspace.project!)
          .singleWhere(
            (item) => item.canonicalKind == 'element' && item.id == 'arbre',
          );
      final mapsBefore = {
        for (final entry in host.fixture.controller.documents.entries)
          entry.key: entry.value.current,
      };
      final pending = classifyResource(
        tester.element(find.byType(Scaffold).first),
        host.navigation,
        item,
      );
      await pumpIo(tester);
      await host.choose('resource-classify-role', 'Composant réutilisable');
      await host.tap('resource-management-save');
      await pending;
      final reopened = await host.reopen();
      expect(
        reopened.resourceLibraryCatalog.entryFor('element', 'arbre')?.role,
        ResourceLibraryRole.component,
      );
      expect(
        find.byKey(const ValueKey('resource-card-element:arbre')),
        findsNothing,
      );
      await host.tap('resource-filter-button');
      await host.tap('resource-filter-components');
      await host.tap('resource-filter-apply');
      expect(
        find.byKey(const ValueKey('resource-filter-tag-components')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-card-element:arbre')),
        findsOneWidget,
      );
      final second = classifyResource(
        tester.element(find.byType(Scaffold).first),
        host.navigation,
        item,
      );
      await pumpIo(tester);
      await host.choose('resource-classify-role', 'Ressource standard');
      await host.tap('resource-management-save');
      await second;
      expect(
        (await host.reopen()).resourceLibraryCatalog.entryFor(
          'element',
          'arbre',
        ),
        isNull,
      );
      for (final entry in host.fixture.controller.documents.entries) {
        expect(entry.value.current, mapsBefore[entry.key]);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('an open classification form cannot overwrite a newer change', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester);
    final item = resourceCatalog(host.navigation.workspace.project!)
        .singleWhere(
          (item) => item.canonicalKind == 'element' && item.id == 'arbre',
        );
    final pending = classifyResource(
      tester.element(find.byType(Scaffold).first),
      host.navigation,
      item,
    );
    await pumpIo(tester);
    await host.choose('resource-classify-family', 'Arbres');
    await tester.runAsync(
      () => host.fixture.resources.mutate('resource.classify', {
        'resourceKind': 'element',
        'resourceId': 'arbre',
        'familyId': 'vegetation',
      }),
    );
    await host.tap('resource-management-save');
    expect(
      find.byKey(const ValueKey('resource-management-error')),
      findsOneWidget,
    );
    expect(
      (await host.reopen()).resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'vegetation',
    );
    await host.tap('resource-management-cancel');
    await tester.tap(find.text('Annuler les modifications').last);
    await pumpIo(tester);
    await pending;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'family management remains usable with little height and large text',
    (tester) async {
      final host = await UwUResourceHost.open(
        tester,
        size: const Size(1024, 600),
        textScale: 1.5,
      );
      final pending = manageResourceFamilies(
        tester.element(find.byType(Scaffold).first),
        host.navigation,
      );
      await pumpIo(tester);
      await host.choose('resource-family-selected', 'Arbres');
      await tester.ensureVisible(find.text('Fermer').last);
      await tester.tap(find.text('Fermer').last);
      await pumpIo(tester);
      await pending;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'family and subfamily are created in Studio and survive reopening',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      await host.tap('resource-manage-families');
      await host.tap('resource-family-create');
      final name = find.descendant(
        of: find.byKey(const ValueKey('resource-family-name')),
        matching: find.byType(TextField),
      );
      await tester.enterText(name, 'Forêt personnelle');
      await tester.pump();
      await host.tap('resource-management-save');
      expect(
        find.byKey(const ValueKey('resource-management-error')),
        findsNothing,
        reason: find
            .byKey(const ValueKey('resource-management-error'))
            .evaluate()
            .map((element) => (element.widget as Text).data)
            .join(' '),
      );
      final root = host
          .navigation
          .workspace
          .project!
          .resourceLibraryCatalog
          .families
          .single;
      expect(root.name, 'Forêt personnelle');
      await host.choose('resource-family-selected', 'Forêt personnelle');
      await host.tap('resource-subfamily-create');
      await tester.enterText(name, 'Petits arbres');
      await tester.pump();
      await host.tap('resource-management-save');
      final reopened = await host.reopen();
      final child = reopened.resourceLibraryCatalog.families.singleWhere(
        (family) => family.name == 'Petits arbres',
      );
      expect(child.parentId, root.id);
      expect(reopened.resourceLibraryCatalog.descendantFamilyIds(root.id), {
        root.id,
        child.id,
      });
      expect(tester.takeException(), isNull);
      await host.fixture.capture(tester, 'resource-family-manager');
    },
  );

  testWidgets(
    'classifying local resource persists without changing map contents',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final imported = (await tester.runAsync(
        () => host.fixture.resources.importImage(
          ResourceImageImport(
            sourcePath: '${host.fixture.directory.path}/assets/atelier.png',
            name: 'Source de l’arbre local',
            tileWidth: 16,
            tileHeight: 16,
          ),
        ),
      ))!;
      final importedAcceptance = host.navigation.accept(imported);
      await pumpIo(tester);
      await importedAcceptance;
      final original = imported.manifest.elements.first;
      final receipt = (await tester.runAsync(
        () => host.fixture.resources.mutate('element.upsert', {
          'element': original
              .copyWith(
                id: 'arbre-local',
                name: 'Arbre unique',
                tilesetId: imported.createdTilesetId!,
                frames: original.frames
                    .map(
                      (frame) =>
                          frame.copyWith(tilesetId: imported.createdTilesetId!),
                    )
                    .toList(),
              )
              .toJson(),
        }),
      ))!;
      final acceptance = host.navigation.accept(receipt);
      await pumpIo(tester);
      await acceptance;
      final project = host.navigation.workspace.project!;
      final mapsBefore = {
        for (final entry in host.fixture.controller.documents.entries)
          entry.key: entry.value.current,
      };
      final item = resourceCatalog(project).singleWhere(
        (item) => item.canonicalKind == 'element' && item.id == 'arbre-local',
      );
      final context = tester.element(find.byType(Scaffold).first);
      final pending = classifyResource(context, host.navigation, item);
      await pumpIo(tester);
      await host.choose('resource-classify-family', 'Arbres');
      await host.choose('resource-classify-availability', 'Propre à une carte');
      await host.choose('resource-classify-map', 'Jardin des essais');
      await host.tap('resource-management-save');
      await pending;
      expect(find.byType(ResourceManagementDialog), findsNothing);
      final reopened = await host.reopen();
      final entry = reopened.resourceLibraryCatalog.entryFor(
        'element',
        'arbre-local',
      );
      expect(entry?.familyId, 'trees');
      expect(entry?.mapId, 'jardin');
      expect(
        reopened.resourceLibraryCatalog.availableForMap(
          'element',
          'arbre-local',
          'clairiere',
        ),
        isFalse,
      );
      for (final entry in host.fixture.controller.documents.entries) {
        expect(entry.value.current, mapsBefore[entry.key]);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared definition cannot be silently reserved for one of its maps',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final item = resourceCatalog(host.navigation.workspace.project!)
          .singleWhere(
            (item) => item.canonicalKind == 'element' && item.id == 'arbre',
          );
      final context = tester.element(find.byType(Scaffold).first);
      final pending = classifyResource(context, host.navigation, item);
      await pumpIo(tester);
      await host.choose('resource-classify-availability', 'Propre à une carte');
      await host.choose('resource-classify-map', 'Jardin des essais');
      await host.tap('resource-management-save');
      expect(
        find.byKey(const ValueKey('resource-management-error')),
        findsOneWidget,
      );
      expect(
        (await host.reopen()).resourceLibraryCatalog.entryFor(
          'element',
          'arbre',
        ),
        isNull,
      );
      expect(tester.takeException(), isNull);
      await host.tap('resource-management-cancel');
      await tester.tap(find.text('Annuler les modifications').last);
      await pumpIo(tester);
      await pending;
    },
  );
}
