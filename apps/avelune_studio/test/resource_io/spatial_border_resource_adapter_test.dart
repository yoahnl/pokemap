import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/spatial_border_fixture.dart';
import '../application/spatial_border_commands_test.dart' show borderDraft;
import 'resource_fixture.dart';

void main() {
  test('model replacement preserves existing playback or refuses an incompatible animation', () async {
    final directory = await Directory.systemTemp.createTemp(
      'border_existing_playback_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final base = spatialBorderVariantProject();
    final encoded = encodeBorderBlueprintRecordJson(
      base.borderCatalog.records.single,
      formatVersion: 5,
    );
    final definition = (encoded['draft'] as Map)['definition'] as Map;
    final primitive = (definition['primitives'] as List)
        .cast<Map>()
        .singleWhere((value) => value['id'] == 'south-cap');
    primitive.addAll(<String, Object?>{
      'animationIndex': 0,
      'animationLoop': false,
      'animationSpeed': .5,
      'blocksMovement': false,
    });
    ProjectManifest project(bool replacementAnimated) => base.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(encoded, formatVersion: 5)],
      ),
      models3d: [
        for (final model in base.models3d)
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'inspection': {
              ...model.inspection.toJson(),
              'animations': [
                if (model.id == 'oak' || replacementAnimated)
                  {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
              ],
            },
          }),
      ],
    );
    const request = BorderCreationRequest(
      name: 'Clôture',
      blueprintId: 'fence',
      primitiveModelIds: {'south-cap': 'replacement'},
    );
    await expectLater(
      prepareBorderResources(
        manifest: project(false),
        projectRoot: directory.path,
        request: request,
      ),
      throwsA(isA<ResourceFailure>()),
    );
    final prepared = await prepareBorderResources(
      manifest: project(true),
      projectRoot: directory.path,
      request: request,
    );
    final replaced = prepared
        .singleWhere((value) => value.draft.id == 'south-cap')
        .draft;
    expect(replaced.animationIndex, 0);
    expect(replaced.animationLoop, false);
    expect(replaced.animationSpeed, .5);
    expect(replaced.blocksMovement, false);
    final cleared = await prepareBorderResources(
      manifest: project(false),
      projectRoot: directory.path,
      request: const BorderCreationRequest(
        name: 'Clôture',
        blueprintId: 'fence',
        primitiveModelIds: {'south-cap': 'replacement'},
        primitiveModelSettings: {
          'south-cap': BorderModelSettings(
            animationLoop: false,
            animationSpeed: .5,
            blocksMovement: false,
          ),
        },
      ),
    );
    expect(
      cleared
          .singleWhere((value) => value.draft.id == 'south-cap')
          .draft
          .animationIndex,
      isNull,
    );
  });

  test(
    'model border settings are explicit and isolated to the selected variant',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'border_playback_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final base = spatialBorderVariantProject();
      final project = base.copyWith(
        models3d: [
          for (final model in base.models3d)
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
      );
      final prepared = await prepareBorderResources(
        manifest: project,
        projectRoot: directory.path,
        request: const BorderCreationRequest(
          name: 'Clôture',
          blueprintId: 'fence',
          primitiveModelIds: {'south-cap': 'replacement'},
          primitiveModelSettings: {
            'south-cap': BorderModelSettings(
              animationIndex: 0,
              animationLoop: false,
              animationSpeed: .5,
              blocksMovement: false,
            ),
          },
        ),
      );
      final encoded = encodeBorderBlueprintRecordJson(
        BorderBlueprintRecord(
          id: 'test',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: BorderBlueprintDraftDefinition(
              name: 'Test',
              previewSeed: BorderSignedInt64.fromInt(1),
              template: BorderBlueprintTemplate.connectedLine,
              straightOnly: true,
              defaults:
                  base.borderCatalog.records.single.draft.definition.defaults,
              sortOrder: 0,
              primitives: prepared.map((value) => value.draft).toList(),
            ),
          ),
        ),
        formatVersion: 5,
      );
      final definition = (encoded['draft'] as Map)['definition'] as Map;
      final primitives = (definition['primitives'] as List).cast<Map>();
      final selected = primitives.singleWhere(
        (value) => value['id'] == 'south-cap',
      );
      expect(selected['animationIndex'], 0);
      expect(selected['animationLoop'], false);
      expect(selected['animationSpeed'], .5);
      expect(selected['blocksMovement'], false);
      for (final primitive in primitives.where(
        (value) => value['id'] != 'south-cap',
      )) {
        expect(primitive['animationIndex'], isNull);
        expect(primitive['blocksMovement'] ?? true, isTrue);
      }
    },
  );

  test(
    'model border settings reject unknown variants and unavailable clips',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'border_playback_invalid_',
      );
      addTearDown(() => directory.delete(recursive: true));
      for (final settings in [
        {'missing': const BorderModelSettings(blocksMovement: false)},
        {'south-cap': const BorderModelSettings(animationIndex: 0)},
        {'south-cap': const BorderModelSettings(animationSpeed: 0)},
        {'south-cap': const BorderModelSettings(animationSpeed: double.nan)},
      ]) {
        await expectLater(
          prepareBorderResources(
            manifest: spatialBorderVariantProject(),
            projectRoot: directory.path,
            request: BorderCreationRequest(
              name: 'Clôture',
              blueprintId: 'fence',
              primitiveModelSettings: settings,
            ),
          ),
          throwsA(isA<ResourceFailure>()),
        );
      }
    },
  );

  test('variant source replacement retains all other primitive metadata and rejects unknown or private sources', () async {
    final directory = await Directory.systemTemp.createTemp(
      'studio_border_variants_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final project = spatialBorderVariantProject();
    final original =
        project.borderCatalog.records.single.draft.definition.primitives;
    final request = BorderCreationRequest(
      blueprintId: 'fence',
      name: 'Clôture',
      primitiveModelIds: const {'south-cap': 'replacement'},
      straightOnly: true,
    );
    final prepared = await prepareBorderResources(
      manifest: project,
      projectRoot: directory.path,
      request: request,
    );
    expect(prepared, hasLength(3));
    expect(prepared[0].draft, same(original[0]));
    expect(prepared[1].draft, same(original[1]));
    final replaced = prepared[2].draft;
    expect(replaced.id, 'south-cap');
    expect(replaced.sourceModelId, 'replacement');
    expect(replaced.anchorWorld, original[2].anchorWorld);
    expect(replaced.authoredOrientation, original[2].authoredOrientation);
    expect(replaced.transforms, original[2].transforms);
    expect(replaced.weight, original[2].weight);
    await expectLater(
      prepareBorderResources(
        manifest: project,
        projectRoot: directory.path,
        request: const BorderCreationRequest(
          blueprintId: 'fence',
          name: 'Clôture',
          primitiveModelIds: {'missing': 'replacement'},
        ),
      ),
      throwsA(isA<ResourceFailure>()),
    );
    final private = project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'replacement',
            mapId: 'b',
          ),
        ],
      ),
    );
    await expectLater(
      prepareBorderResources(
        manifest: private,
        projectRoot: directory.path,
        request: request,
      ),
      throwsA(isA<ResourceFailure>()),
    );
  });
  test('Studio map save and reopen retain spatial border offset and native ownership', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final project = spatialBorderProject().copyWith(
      maps: [ResourceFixture.entry],
    );
    final map = spatialBorderMap().copyWith(id: ResourceFixture.entry.id);
    await fixture.manifestFile.writeAsString(jsonEncode(project.toJson()));
    await fixture.mapFile.writeAsBytes(encodeMapDocumentBytes(map));
    await fixture.maps.loadProject(fixture.session);
    final baseline = await fixture.loadMap();
    final document = EditableMapDocument(baseline);
    final commands = MapBorderEditingCommands(document, project);
    commands.finish(borderDraft(document.current, project));
    final layer = document.current.layers.whereType<BorderLayer>().single;
    final feature = layer.content.features.single;
    final offset = Model3dVector3(x: .25, y: 1.5, z: -.25);
    commands.setSpatialOffset(
      layerId: layer.id,
      featureId: feature.id,
      offset: offset,
      source: feature,
    );
    final source = document.current;
    final preview = commands.previewExisting(
      layerId: layer.id,
      featureId: feature.id,
    );
    commands.applyExisting(preview, source: source, sourceProject: project);
    await fixture.maps.saveMap(fixture.session, baseline, document.current);
    final reopened = LocalMapWorkspaceAdapter();
    await reopened.loadProject(fixture.session);
    final saved = await reopened.loadMap(
      fixture.session,
      ResourceFixture.entry,
    );
    expect(saved.map, document.current);
    final savedFeature = saved.map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(savedFeature.spatialOffsetWorld, offset);
    expect(
      savedFeature.generatedPlacementIds.toSet(),
      saved.map.spatialScene!.instances.map((instance) => instance.id).toSet(),
    );
    expect(
      diagnoseSpatialBorderFeature(
        manifest: project,
        map: saved.map,
        layerId: layer.id,
        featureId: feature.id,
      ).diagnostics,
      isEmpty,
    );
  });

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
