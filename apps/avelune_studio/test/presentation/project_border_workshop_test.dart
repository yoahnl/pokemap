import 'dart:async';

import 'package:avelune_studio/features/rendering/contracts/border_workshop_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/project_border_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('opens a real assembly and lists only its selected pieces', (
    tester,
  ) async {
    final project = _project();
    final original = project.borderCatalog.records.single;
    final visuals = _BorderVisuals();
    final reading = Completer<ProjectManifest>();
    var reads = 0;
    var back = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectBorderWorkshop(
            item: _item(),
            visuals: visuals,
            loadProject: () {
              reads++;
              return reading.future;
            },
            onBack: () => back++,
          ),
        ),
      ),
    );
    expect(reads, 1);
    expect(visuals.map, isNull);

    reading.complete(project);
    await tester.pumpAndSettle();
    expect(find.text('Pièces utilisées'), findsOneWidget);
    expect(find.text('Poteau'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Coin'), findsOneWidget);
    expect(find.text('Autre section'), findsNothing);
    final map = visuals.map!;
    final materialization = map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single
        .materialization!;
    expect(materialization.receipt.blueprintRevision, 2);
    expect(
      materialization.spatialPlacements.map((p) => p.instanceId),
      unorderedEquals(map.spatialScene!.instances.map((i) => i.id)),
    );
    expect(map.spatialScene!.instances.map((i) => i.modelId).toSet(), {
      'post',
      'section',
      'corner',
    });

    await tester.tap(find.text('Brouillon'));
    await tester.pumpAndSettle();
    expect(find.text('Autre section'), findsOneWidget);
    expect(find.text('Section'), findsNothing);
    expect(visuals.map!.spatialScene!.instances.map((i) => i.modelId).toSet(), {
      'post',
      'alternate',
      'corner',
    });
    expect(reads, 1);
    expect(project.borderCatalog.records.single, same(original));
    await tester.tap(find.text('Retour à la bibliothèque'));
    expect(back, 1);
    expect(visuals.activatedMaps, isEmpty);
  });

  testWidgets('an incomplete unpublished kit gives a reason without a canvas', (
    tester,
  ) async {
    final visuals = _BorderVisuals();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectBorderWorkshop(
            item: _item(),
            visuals: visuals,
            loadProject: () async => _project(publish: false),
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Brouillon'), findsOneWidget);
    expect(find.text('Pièces manquantes'), findsOneWidget);
    expect(visuals.map, isNull);
    expect(tester.takeException(), isNull);
  });
}

ProjectLibraryItem _item() => ProjectLibraryItem(
  kind: 'borderBlueprint',
  id: 'fence',
  name: 'Clôture de la prairie',
  mapId: 'prairie',
);

ProjectManifest _project({bool publish = true}) {
  final settings = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: [0, 1, 2, 3],
  );
  const ids = {
    BorderPrimitiveRole.lineCap: 'post',
    BorderPrimitiveRole.lineStraight: 'section',
    BorderPrimitiveRole.lineCorner: 'corner',
  };
  final draft = BorderBlueprintDraftDefinition(
    name: _item().name,
    previewSeed: BorderSignedInt64.fromInt(38),
    template: BorderBlueprintTemplate.connectedLine,
    defaults: settings,
    sortOrder: 0,
    primitives: [
      for (final entry in ids.entries)
        if (publish || entry.key != BorderPrimitiveRole.lineCorner)
          BorderPrimitiveDraft(
            id: entry.value,
            role: entry.key,
            sourceModelId: entry.key == BorderPrimitiveRole.lineStraight
                ? 'alternate'
                : entry.value,
            weight: 1,
            transforms: transforms,
          ),
    ],
  );
  return ProjectManifest(
    name: 'Recette Assemblage',
    maps: [],
    tilesets: [],
    version: ProjectVersion.v9,
    settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    models3d: [
      _model('post', 'Poteau'),
      _model('section', 'Section'),
      _model('corner', 'Coin'),
      _model('alternate', 'Autre section'),
    ],
    resourceLibraryCatalog: ResourceLibraryCatalog(
      entries: [
        ResourceLibraryEntry(
          resourceKind: 'borderBlueprint',
          resourceId: 'fence',
          mapId: 'prairie',
        ),
        ResourceLibraryEntry(
          resourceKind: 'model3d',
          resourceId: 'corner',
          mapId: 'prairie',
        ),
      ],
    ),
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [
        BorderBlueprintRecord(
          id: 'fence',
          draft: BorderBlueprintDraft(
            baseRevision: publish ? 2 : 0,
            definition: draft,
          ),
          latestPublished: publish
              ? BorderBlueprintRevision(
                  revision: 2,
                  definition: BorderBlueprintPublishedDefinition(
                    name: draft.name,
                    previewSeed: draft.previewSeed,
                    template: draft.template,
                    defaults: settings,
                    sortOrder: 0,
                    primitives: [
                      for (final entry in ids.entries)
                        BorderPublishedPrimitive(
                          id: entry.value,
                          role: entry.key,
                          sourceModelId: entry.value,
                          weight: 1,
                          transforms: transforms,
                        ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    ),
  );
}

ProjectModel3dEntry _model(String id, String name) => ProjectModel3dEntry(
  id: id,
  name: name,
  sourceAssetId: '$id-source',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

class _BorderVisuals extends WorkspaceTestVisuals
    implements BorderWorkshopVisuals {
  MapData? map;

  @override
  Widget borderAssemblyPreview(MapData map, ProjectManifest project) {
    this.map = map;
    return const SizedBox.expand();
  }
}
