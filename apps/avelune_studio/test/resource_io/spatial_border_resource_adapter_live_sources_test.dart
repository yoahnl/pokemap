import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/spatial_border_fixture.dart';
import 'resource_fixture.dart';

void main() {
  test('Studio publishes live model border sources without any image staging and reopens exact primitives', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    await fixture.manifestFile.writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Bordure native',
          version: ProjectVersion.v9,
          maps: [ResourceFixture.entry],
          tilesets: [],
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
        ).toJson(),
      ),
    );
    await fixture.mapFile.writeAsBytes(
      encodeMapDocumentBytes(
        MapData(
          id: 'garden',
          name: 'Jardin',
          version: ProjectVersion.v9,
          size: const GridSize(width: 4, height: 4),
          spatialScene: MapSpatialScene(width: 4, depth: 4),
        ),
      ),
    );
    await fixture.maps.loadProject(fixture.session);
    final input = File('${fixture.root.path}/piece.glb');
    await input.writeAsBytes(triangleGlb());
    final imported = await fixture.resources.importModel(
      sourcePath: input.path,
      name: 'Pièce de clôture',
    );
    final id = imported.manifest.models3d.single.id;
    final mapBefore = await fixture.mapFile.readAsBytes();
    final receipt = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: 'native-fence',
        name: 'Clôture 3D',
        capModelId: id,
        straightModelId: id,
        cornerModelId: id,
      ),
    );
    final record = receipt.manifest.borderCatalog.records.single;
    expect(record.latestPublished!.definition.isSpatial, isTrue);
    expect(
      record.latestPublished!.definition.primitives.map(
        (primitive) => primitive.sourceModelId,
      ),
      everyElement(id),
    );
    expect(receipt.manifest.borderCatalog.visualSnapshots, isEmpty);
    expect(receipt.manifest.elements, isEmpty);
    expect(receipt.manifest.tilesets, isEmpty);
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(reopened.borderCatalog.records.single, record);
    final importedProfile = jsonDecode(
      await fixture.manifestFile.readAsString(),
    ) as Map<String, dynamic>;
    importedProfile['borderCatalog']['records'][0]['draft']['definition']['straightOnly'] =
        true;
    await fixture.manifestFile.writeAsString(jsonEncode(importedProfile));
    await fixture.maps.loadProject(fixture.session);
    await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: record.id,
        name: 'Clôture renommée',
        capModelId: id,
        straightModelId: id,
        cornerModelId: id,
      ),
    );
    final updated = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(
      updated.borderCatalog.records.single.draft.definition.primitives,
      record.draft.definition.primitives,
    );
    expect(
      updated.borderCatalog.records.single.latestPublished!.definition.name,
      'Clôture renommée',
    );
    expect(
      updated.borderCatalog.records.single.draft.definition.straightOnly,
      isTrue,
    );
    expect(
      updated
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition
          .straightOnly,
      isTrue,
    );
    final variantJson = jsonDecode(
      await fixture.manifestFile.readAsString(),
    ) as Map<String, dynamic>;
    final definitionJson =
        variantJson['borderCatalog']['records'][0]['draft']['definition']
            as Map<String, dynamic>;
    final capJson = (definitionJson['primitives'] as List).firstWhere(
      (p) => p['role'] == 'lineCap',
    ) as Map;
    final bodyJson = (definitionJson['primitives'] as List).firstWhere(
      (p) => p['role'] == 'lineStraight',
    );
    definitionJson['primitives'] = [
      bodyJson,
      {
        ...capJson,
        'id': 'north-cap',
        'authoredOrientation': 'north',
        'weight': 400,
        'anchorWorld': {'x': .1, 'y': .2, 'z': 0},
      },
      {
        ...capJson,
        'id': 'south-cap',
        'authoredOrientation': 'south',
        'weight': 600,
        'anchorWorld': {'x': .2, 'y': .3, 'z': 0},
        'transforms': {
          'allowFlipX': false,
          'allowedQuarterTurns': [0, 2],
        },
      },
    ];
    await fixture.manifestFile.writeAsString(jsonEncode(variantJson));
    final variantsBefore = await fixture.maps.loadProject(fixture.session);
    final replacement = await fixture.resources.importModel(
      sourcePath: input.path,
      name: 'Autre terminal',
    );
    final replacementId = replacement.manifest.models3d.last.id;
    final variantReceipt = await fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: record.id,
        name: 'Clôture à deux terminaux',
        primitiveModelIds: {'south-cap': replacementId},
        straightOnly: true,
      ),
    );
    final variantsReopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    final beforePrimitives =
        variantsBefore.borderCatalog.records.single.draft.definition.primitives;
    final afterPrimitives = variantsReopened
        .borderCatalog
        .records
        .single
        .draft
        .definition
        .primitives;
    expect(afterPrimitives, hasLength(3));
    expect(afterPrimitives.take(2), beforePrimitives.take(2));
    expect(afterPrimitives.last.sourceModelId, replacementId);
    expect(afterPrimitives.last.id, beforePrimitives.last.id);
    expect(afterPrimitives.last.anchorWorld, beforePrimitives.last.anchorWorld);
    expect(
      afterPrimitives.last.authoredOrientation,
      beforePrimitives.last.authoredOrientation,
    );
    expect(afterPrimitives.last.weight, beforePrimitives.last.weight);
    expect(afterPrimitives.last.transforms, beforePrimitives.last.transforms);
    expect(
      variantsReopened.borderCatalog.records.single,
      variantReceipt.manifest.borderCatalog.records.single,
    );
    expect(
      variantsReopened
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition
          .primitives,
      hasLength(3),
    );
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
  });

  test('border sources preserve local anchors and reject mixed dimensions and private models', () async {
    final directory = await Directory.systemTemp.createTemp(
      'studio_border_sources_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final project = spatialBorderProject(
      anchor: Model3dVector3(x: .1, y: .2, z: .3),
    );
    const request = BorderCreationRequest(
      blueprintId: 'fence',
      name: 'Clôture',
      capModelId: 'oak',
      straightModelId: 'oak',
      cornerModelId: 'oak',
    );
    final sources = await prepareBorderResources(
      manifest: project,
      projectRoot: directory.path,
      request: request,
    );
    expect(
      sources.map((source) => source.draft),
      project.borderCatalog.records.single.draft.definition.primitives,
    );
    expect(sources.every((source) => source.frames.isEmpty), isTrue);
    final scoped = project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'oak',
            mapId: 'a',
          ),
        ],
      ),
    );
    await expectLater(
      prepareBorderResources(
        manifest: scoped,
        projectRoot: directory.path,
        request: request,
      ),
      throwsA(isA<ResourceFailure>()),
    );
    final local = scoped.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'oak',
            mapId: 'a',
          ),
          ResourceLibraryEntry(
            resourceKind: 'borderBlueprint',
            resourceId: 'fence',
            mapId: 'a',
          ),
        ],
      ),
    );
    expect(
      await prepareBorderResources(
        manifest: local,
        projectRoot: directory.path,
        request: request,
      ),
      hasLength(3),
    );
    await expectLater(
      prepareBorderResources(
        manifest: project,
        projectRoot: directory.path,
        request: const BorderCreationRequest(
          name: 'Mixte',
          capElementId: 'tree',
          capModelId: 'oak',
        ),
      ),
      throwsA(isA<ResourceFailure>()),
    );
    await expectLater(
      prepareBorderResources(
        manifest: project.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.twoD),
        ),
        projectRoot: directory.path,
        request: request,
      ),
      throwsA(isA<ResourceFailure>()),
    );
  });
}
