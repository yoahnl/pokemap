import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import 'authoring_resource_fixture.dart';

Future<ProjectManifest> seedResourceLibraryKinds(
  AuthoringResourceFixture fixture,
) async {
  final input = File('${fixture.directory.path}/context-source.glb');
  await input.writeAsBytes(triangleGlb());
  final receipt = await fixture.resources.importModel(
    sourcePath: input.path,
    name: 'Modèle contexte',
  );
  await fixture.navigation.accept(receipt);
  final original = fixture.workspace.project!;
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
  await File('${fixture.directory.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  await fixture.resources.mapAdapter.loadProject(fixture.session);
  fixture.workspace.project = project;
  fixture.navigation.changed();
  return project;
}
