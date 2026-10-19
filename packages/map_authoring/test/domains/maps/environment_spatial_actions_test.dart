import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:image/image.dart' as img;

import '../assets/resource_information_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import '../../support/glb_fixture.dart';

const editing = EnvironmentEditing();

void main() {
  for (final modelDefault in [false, true]) {
    for (final mode in EnvironmentCollisionMode.values) {
      final expected = switch (mode) {
        EnvironmentCollisionMode.useElementDefault => modelDefault,
        EnvironmentCollisionMode.forceEnabled => true,
        EnvironmentCollisionMode.forceDisabled => false,
      };
      test('manual Environment model default $modelDefault mode ${mode.name}', () {
        final fixture = spatialEnvironmentFixture(
            modelDefaultBlocking: modelDefault, collisionMode: mode);
        final result = editing.addGeneratedPlacement(fixture.project, fixture.map,
            layerId: 'env', areaId: 'forest', placementId: 'manual-default',
            modelId: 'tree', pos: const GridPos(x: 1, y: 1));
        expect(result.spatialScene!.instances.single.blocksMovement, expected);
      });
      test('generated Environment model default $modelDefault mode ${mode.name}', () {
        final fixture = spatialEnvironmentFixture(
            modelDefaultBlocking: modelDefault, collisionMode: mode);
        final preview = generate(fixture.project, fixture.map);
        expect(preview.placements, hasLength(24));
        expect(preview.placements.every((entry) => entry.applyCollision == expected), isTrue);
        final result = apply(fixture.project, fixture.map, preview);
        expect(result.spatialScene!.instances.every((entry) => entry.blocksMovement == expected), isTrue);
      });
    }
  }

  test('model default blocking invalidates stale Environment generation previews', () {
    final fixture = spatialEnvironmentFixture(
        collisionMode: EnvironmentCollisionMode.useElementDefault);
    final preview = generate(fixture.project, fixture.map);
    final changed = fixture.project.copyWith(models3d: [
      fixture.project.models3d.single.copyWith(blocksMovementByDefault: false),
    ]);
    expect(generate(changed, fixture.map).inputFingerprint,
        isNot(preview.inputFingerprint));
    expect(() => apply(changed, fixture.map, preview),
        throwsA(isA<MapAuthoringException>()));
  });

  test('continuous terrain invalidates stale Environment generation previews', () {
    final fixture = spatialEnvironmentFixture();
    final preview = generate(fixture.project, fixture.map);
    final surface = SpatialTerrainSurface(id: 'hill', x: 0, z: 0, height: 2,
      gradientX: .25, footprints: [BorderGroundFootprint(points: [
        BorderGroundPoint(x: 0, z: 0), BorderGroundPoint(x: 2, z: 0),
        BorderGroundPoint(x: 2, z: 2), BorderGroundPoint(x: 0, z: 2),
      ])]);
    final changed = const SpatialMapOperations().upsertTerrainSurfaces(fixture.map, [surface]);
    expect(generate(fixture.project, changed).inputFingerprint, isNot(preview.inputFingerprint));
    expect(() => apply(fixture.project, changed, preview), throwsA(isA<MapAuthoringException>()));
    final regenerated = apply(fixture.project, changed, generate(fixture.project, changed));
    for (final instance in regenerated.spatialScene!.instances) {
      expect(instance.position.y, regenerated.spatialScene!.worldHeightAt(instance.position.x, instance.position.z));
    }
  });

  test(
      'native generation input ignores unrelated instances areas and resource metadata',
      () {
    final fixture = spatialEnvironmentFixture();
    final preview = generate(fixture.project, fixture.map);
    final otherLayer = MapLayer.environment(
        id: 'other-env',
        name: 'Other forest',
        content: EnvironmentLayerContent(targetsSpatialTerrain: true, areas: [
          EnvironmentArea(
              id: 'other',
              name: 'Other',
              presetId: 'forest',
              seed: 33,
              mask: EnvironmentAreaMask(
                  width: 6, height: 4, cells: List.filled(24, false))),
        ]));
    final changedMap = fixture.map.copyWith(
        layers: [...fixture.map.layers, otherLayer],
        spatialScene: fixture.map.spatialScene!.copyWith(instances: [
          SpatialModelInstance(
              id: 'prop',
              modelId: 'tree',
              position: Model3dVector3(x: .5, y: 0, z: .5)),
        ]));
    final changedProject = fixture.project.copyWith(
        models3d: [
          ...fixture.project.models3d,
          ProjectModel3dEntry.fromJson({
            ...fixture.project.models3d.single.toJson(),
            'id': 'unrelated',
            'name': 'Unrelated',
            'sourceAssetId': 'unrelated-source',
            'relativePath': 'assets/models3d/unrelated.glb'
          }),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'unrelated',
              familyId: 'props'),
        ]));
    final after = generate(changedProject, changedMap);
    expect(after.inputFingerprint, preview.inputFingerprint);
    expect(after.placements.map((placement) => placement.toJson()).toList(),
        preview.placements.map((placement) => placement.toJson()).toList());
    final result = apply(changedProject, changedMap, preview);
    expect(
        result.spatialScene!.instances
            .singleWhere((i) => i.id == 'prop')
            .position
            .x,
        .5);
  });

  test(
      'native generation input tracks source terrain mask and manual placement state',
      () {
    final fixture = spatialEnvironmentFixture();
    final preview = generate(fixture.project, fixture.map);
    final changedProject = fixture.project.copyWith(
        models3d: [fixture.project.models3d.single.copyWith(scale: 2)]);
    expect(generate(changedProject, fixture.map).inputFingerprint,
        isNot(preview.inputFingerprint));
    final relief = fixture.map.copyWith(
        spatialScene: fixture.map.spatialScene!
            .copyWith(heightLevels: List.filled(24, 2)));
    expect(generate(fixture.project, relief).inputFingerprint,
        isNot(preview.inputFingerprint));
    final mask = editing.paintCells(fixture.map,
        layerId: 'env',
        areaId: 'forest',
        cells: const [GridPos(x: 1, y: 1)],
        value: false);
    expect(generate(fixture.project, mask).inputFingerprint,
        isNot(preview.inputFingerprint));
    final applied = apply(fixture.project, fixture.map, preview);
    final id = applied.spatialScene!.instances.first.id;
    final manual = editing.moveGeneratedPlacement(applied,
        layerId: 'env',
        areaId: 'forest',
        placementId: id,
        pos: const GridPos(x: 2, y: 2));
    expect(generate(fixture.project, manual).inputFingerprint,
        isNot(generate(fixture.project, applied).inputFingerprint));
  });

  test(
      'deterministic native instances use terrain height and stay in their mask',
      () {
    final fixture = spatialEnvironmentFixture();
    final preview = generate(fixture.project, fixture.map);
    expect(preview.fingerprint,
        generate(fixture.project, fixture.map).fingerprint);
    expect(preview.placements, hasLength(24));
    final result = apply(fixture.project, fixture.map, preview);
    expect(result.placedElements, isEmpty);
    expect(result.spatialScene!.instances, hasLength(24));
    for (final instance in result.spatialScene!.instances) {
      expect(instance.modelId, 'tree');
      expect(
          instance.position.y,
          result.spatialScene!
              .worldHeightAt(instance.position.x, instance.position.z));
      expect(instance.blocksMovement, isFalse);
    }
    expect(MapData.fromJson(result.toJson()).spatialScene, result.spatialScene);
    expect(diagnoseMapEnvironmentLayerUsage(fixture.project, result).hasErrors,
        isFalse);
  });

  test(
      'local regeneration keeps foreign instances and matches full generation with spacing',
      () {
    final fixture = spatialEnvironmentFixture(spacing: 1);
    final preview = generate(fixture.project, fixture.map);
    var map = apply(fixture.project, fixture.map, preview);
    final manual = SpatialModelInstance(
        id: 'manual',
        modelId: 'tree',
        position: Model3dVector3(x: .5, y: 0, z: .5));
    map = map.copyWith(
        spatialScene: map.spatialScene!
            .copyWith(instances: [...map.spatialScene!.instances, manual]));
    final before = {
      for (final value in map.spatialScene!.instances) value.id: value
    };
    final local = generate(fixture.project, map,
        region:
            const EnvironmentGenerationRegion(x: 2, y: 1, width: 1, height: 1));
    final result = apply(fixture.project, map, local);
    expect(
        {for (final value in result.spatialScene!.instances) value.id: value},
        before);
    expect(preview.placements, isNotEmpty);
    for (final a in preview.placements) {
      for (final b in preview.placements) {
        if (a.id == b.id) continue;
        expect((a.pos.x - b.pos.x).abs() > 1 || (a.pos.y - b.pos.y).abs() > 1,
            isTrue);
      }
    }
  });

  test(
      'manual move add delete survive regeneration and clearing preserves unrelated models',
      () {
    final fixture = spatialEnvironmentFixture();
    var map = apply(
        fixture.project, fixture.map, generate(fixture.project, fixture.map));
    final selected = map.spatialScene!.instances.first;
    map = editing.moveGeneratedPlacement(map,
        layerId: 'env',
        areaId: 'forest',
        placementId: selected.id,
        pos: const GridPos(x: 2, y: 1));
    final exact = map.spatialScene!.instances
        .firstWhere((value) => value.id == selected.id)
        .copyWith(
            position: Model3dVector3(x: 2.3, y: .8, z: 1.7),
            rotationDegrees: 45,
            scale: 1.2);
    map = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
      for (final value in map.spatialScene!.instances)
        if (value.id == exact.id) exact else value,
    ]));
    map = editing.addGeneratedPlacement(fixture.project, map,
        layerId: 'env',
        areaId: 'forest',
        placementId: 'added',
        modelId: 'tree',
        pos: const GridPos(x: 3, y: 2));
    map = apply(fixture.project, map, generate(fixture.project, map));
    expect(
        map.spatialScene!.instances
            .firstWhere((value) => value.id == selected.id),
        exact);
    expect(map.spatialScene!.instances.any((value) => value.id == 'added'),
        isTrue);
    final removed =
        map.spatialScene!.instances.lastWhere((value) => value.id != 'added');
    map = editing.deleteGeneratedPlacement(map,
        layerId: 'env', areaId: 'forest', placementId: removed.id);
    map = apply(fixture.project, map, generate(fixture.project, map));
    expect(map.spatialScene!.instances.any((value) => value.id == removed.id),
        isFalse);
    final foreign = SpatialModelInstance(
        id: 'foreign', modelId: 'tree', position: Model3dVector3.zero);
    map = map.copyWith(
        spatialScene: map.spatialScene!
            .copyWith(instances: [...map.spatialScene!.instances, foreign]));
    final cleared =
        editing.clearGeneratedPlacements(map, layerId: 'env', areaId: 'forest');
    expect(cleared.spatialScene!.instances, [foreign]);
    expect(
        editing
            .areaOf(cleared, layerId: 'env', areaId: 'forest')
            .manualPlacementIds,
        isEmpty);
    expect(
        editing
            .deleteArea(map, layerId: 'env', areaId: 'forest')
            .spatialScene!
            .instances,
        [foreign]);
  });

  test('spatial masks select centers independently of large visual footprints',
      () {
    final fixture = spatialEnvironmentFixture();
    final originalModel = fixture.project.models3d.single;
    final model = ProjectModel3dEntry(
        id: originalModel.id,
        name: originalModel.name,
        sourceAssetId: originalModel.sourceAssetId,
        relativePath: originalModel.relativePath,
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -1.6, y: 0, z: -.2),
                max: Model3dVector3(x: 1.6, y: 2, z: .2)),
            meshCount: 1,
            triangleCount: 2));
    final project = fixture.project.copyWith(models3d: [model]);
    final fullPreview = generate(project, fixture.map);
    expect(fullPreview.placements, hasLength(24));
    var map = apply(project, fixture.map, fullPreview);
    map = editing.paintCells(map,
        layerId: 'env',
        areaId: 'forest',
        cells: const [GridPos(x: 4, y: 1)],
        value: false);
    final region =
        const EnvironmentGenerationRegion(x: 4, y: 1, width: 1, height: 1);
    final localPreview = generate(project, map, region: region);
    expect(localPreview.haloCells, 1);
    final local = apply(project, map, localPreview);
    final full = apply(project, map, generate(project, map));
    expect({for (final value in local.spatialScene!.instances) value.id: value},
        {for (final value in full.spatialScene!.instances) value.id: value});
  });

  test(
      'sparse centers preserve XYZ offsets through local regeneration move delete and reopen',
      () {
    final fixture = spatialEnvironmentFixture();
    final preset = fixture.project.environmentPresets.single;
    final offset = Model3dVector3(x: -.5, y: .1875, z: .75);
    final shifted = EnvironmentPreset(
        id: preset.id,
        name: preset.name,
        templateId: preset.templateId,
        palette: [
          EnvironmentPaletteItem(
              modelId: 'tree',
              weight: 1,
              cellOffsetWorld: offset,
              collisionMode: EnvironmentCollisionMode.forceDisabled)
        ],
        defaultParams: preset.defaultParams,
        sortOrder: preset.sortOrder);
    final project = fixture.project.copyWith(environmentPresets: [shifted]);
    var map = editing.paintCells(fixture.map,
        layerId: 'env',
        areaId: 'forest',
        cells: [
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 6; x++) GridPos(x: x, y: y)
        ],
        value: false);
    map = editing.paintCells(map,
        layerId: 'env',
        areaId: 'forest',
        cells: const [GridPos(x: 1, y: 0), GridPos(x: 4, y: 1)],
        value: true);
    final preview = generate(project, map);
    expect(preview.placements, hasLength(2));
    for (final placement in preview.placements) {
      expect(placement.position!.x, placement.pos.x.toDouble());
      expect(placement.position!.z, placement.pos.y + 1.25);
      expect(
          placement.position!.y,
          map.spatialScene!
                  .worldHeightAt(placement.position!.x, placement.position!.z) +
              .1875);
    }
    map = apply(project, map, preview);
    final before = {
      for (final instance in map.spatialScene!.instances) instance.id: instance
    };
    final local = generate(project, map,
        region:
            const EnvironmentGenerationRegion(x: 4, y: 1, width: 1, height: 1));
    map = apply(project, map, local);
    expect({
      for (final instance in map.spatialScene!.instances) instance.id: instance
    }, before);
    map = MapData.fromJson(
        jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>);
    MapValidator.validate(map, projectDialogueContext: project);
    final movedId = preview.placements.first.id;
    map = editing.moveGeneratedPlacement(map,
        layerId: 'env',
        areaId: 'forest',
        placementId: movedId,
        pos: const GridPos(x: 3, y: 2));
    expect(
        editing
            .areaOf(map, layerId: 'env', areaId: 'forest')
            .mask
            .isActiveAt(1, 0),
        isFalse);
    final deletedId = preview.placements.last.id;
    map = editing.deleteGeneratedPlacement(map,
        layerId: 'env', areaId: 'forest', placementId: deletedId);
    expect(
        editing
            .areaOf(map, layerId: 'env', areaId: 'forest')
            .mask
            .isActiveAt(4, 1),
        isFalse);
    map = apply(project, map, generate(project, map));
    expect(
        map.spatialScene!.instances.map((instance) => instance.id), [movedId]);
    final reopenedPreset = decodeEnvironmentPreset(
        jsonDecode(jsonEncode(encodeEnvironmentPreset(shifted))));
    expect(reopenedPreset.palette.single.cellOffsetWorld, offset);
    expect(() => apply(fixture.project, fixture.map, preview),
        throwsA(isA<MapAuthoringException>()));
  });

  test(
      'only shifted anchors are constrained to map bounds and invalid automatic ownership fails closed',
      () {
    final fixture = spatialEnvironmentFixture();
    final original = fixture.project.environmentPresets.single;
    final offsetPreset = EnvironmentPreset(
        id: original.id,
        name: original.name,
        templateId: original.templateId,
        palette: [
          EnvironmentPaletteItem(
              modelId: 'tree',
              weight: 1,
              cellOffsetWorld: Model3dVector3(x: -.6, y: 100, z: 0))
        ],
        defaultParams: original.defaultParams,
        sortOrder: 0);
    expect(
        () => generate(
            fixture.project.copyWith(environmentPresets: [offsetPreset]),
            fixture.map),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'environment.placement_out_of_bounds')));
    var map = apply(
        fixture.project, fixture.map, generate(fixture.project, fixture.map));
    final layer = map.layers.whereType<EnvironmentLayer>().single;
    final area = layer.content.areas.single;
    final originalInstance = map.spatialScene!.instances.first;
    final bad = SpatialModelInstance(
        id: 'uncanonical',
        modelId: originalInstance.modelId,
        position: originalInstance.position);
    map = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [bad]),
        layers: [
          layer.copyWith(
              content:
                  EnvironmentLayerContent(targetsSpatialTerrain: true, areas: [
            EnvironmentArea(
                id: area.id,
                name: area.name,
                presetId: area.presetId,
                mask: area.mask,
                seed: area.seed,
                generatedPlacementIds: [bad.id])
          ]))
        ]);
    expect(
        () => generate(fixture.project, map),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'environment.placement_anchor_invalid')));
    expect(
        () =>
            MapValidator.validate(map, projectDialogueContext: fixture.project),
        throwsA(isA<ValidationException>().having((error) => error.code, 'code',
            'environment.placement_anchor_invalid')));
  });

  test(
      'stale height preview dimension mismatch missing models and cross-map scope fail closed',
      () {
    final fixture = spatialEnvironmentFixture();
    final preview = generate(fixture.project, fixture.map);
    expect(
        () => editing.applyGeneration(
            manifest: fixture.project,
            map: fixture.map,
            preview: preview,
            currentRevision: 'other'),
        throwsA(isA<MapAuthoringException>()));
    final changed = fixture.map.copyWith(
        spatialScene: fixture.map.spatialScene!
            .copyWith(heightLevels: List.filled(24, 2)));
    expect(() => apply(fixture.project, changed, preview),
        throwsA(isA<MapAuthoringException>()));
    expect(() => generate(fixture.project.copyWith(models3d: []), fixture.map),
        throwsA(isA<MapAuthoringException>()));
    final private = fixture.project.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
      ResourceLibraryEntry(
          resourceKind: 'model3d', resourceId: 'tree', mapId: 'other')
    ]));
    expect(
        () => generate(private, fixture.map),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'resource_library.scope_conflict')));
    expect(
        resourceLibraryMapUsages(
            librarySnapshot([fixture.map], project: fixture.project),
            'model3d',
            'tree'),
        {'map'});
    expect(
        () => editing.attachToSpatialTerrain(
            fixture.map.copyWith(spatialScene: null),
            layerId: 'env'),
        throwsA(isA<MapAuthoringException>()));
    expect(
        () => MapValidator.validate(fixture.map,
            projectDialogueContext:
                fixture.project.copyWith(environmentPresets: const [])),
        throwsA(isA<ValidationException>().having((error) => error.code, 'code',
            'environment.spatial_preset_invalid')));
  });

  test(
      'ownership conflicts missing tracked instances and same-output input changes fail closed',
      () {
    final fixture = spatialEnvironmentFixture();
    final original = generate(fixture.project, fixture.map);
    final changedModel =
        fixture.project.models3d.single.copyWith(name: 'Changed after preview');
    expect(
        () => apply(fixture.project.copyWith(models3d: [changedModel]),
            fixture.map, original),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'environment.preview_invalid')));
    final generated = apply(fixture.project, fixture.map, original);
    final layer = generated.layers.whereType<EnvironmentLayer>().single;
    final duplicate = generated
        .copyWith(layers: [...generated.layers, layer.copyWith(id: 'other')]);
    expect(
        () => generate(fixture.project, duplicate),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'environment.placement_owner_conflict')));
    expect(() => MapData.fromJson(duplicate.toJson()), throwsFormatException);
    final missing = generated.copyWith(
        spatialScene: generated.spatialScene!.copyWith(instances: const []));
    expect(
        () => generate(fixture.project, missing),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'environment.placement_missing')));
    expect(() => MapData.fromJson(missing.toJson()), throwsFormatException);
  });

  test(
      'canonical preset mutation rejects missing models and cross-map transitive usage',
      () async {
    final fixture = spatialEnvironmentFixture();
    final dispatcher = MapMutationDispatcher.canonical();
    Future<AuthoringMutationDraft> build(ProjectManifest project, String action,
        Map<String, Object?> parameters) async {
      final snapshot = librarySnapshot([
        fixture.map,
        if (project.maps.any((map) => map.id == 'other'))
          fixture.map.copyWith(id: 'other', layers: const []),
      ], project: project);
      return dispatcher.build(AuthoringPlanningContext(
          snapshot: snapshot,
          request: AuthoringRequest(
              requestId: 'env-contract',
              actionId: action,
              actionVersion: 1,
              workspaceHandle: 'workspace',
              expectedRevision: snapshot.revision,
              idempotencyKey: 'env-contract',
              parameters: parameters),
          planId: 'env-plan',
          seed: 1));
    }

    await expectLater(
        build(fixture.project.copyWith(models3d: const []),
            'environment.preset.upsert', {
          'preset':
              encodeEnvironmentPreset(fixture.project.environmentPresets.single)
        }),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'environment.palette_invalid')));
    final otherMap = const ProjectMapEntry(
        id: 'other', name: 'Other', relativePath: 'maps/other.json');
    await expectLater(
        build(
            fixture.project.copyWith(maps: [...fixture.project.maps, otherMap]),
            'resource.classify', {
          'resourceKind': 'model3d',
          'resourceId': 'tree',
          'familyId': null,
          'mapId': 'other'
        }),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
  });

  test(
      'canonical JSONL attachment generation undo and independent reopen preserve native models',
      () async {
    final fixture = spatialEnvironmentFixture();
    expect(ProjectManifest.fromJson(fixture.project.toJson()), fixture.project);
    final host = await ResourceInformationFixture.create(fixture.project
        .copyWith(
            maps: const [], models3d: const [], environmentPresets: const []));
    addTearDown(host.dispose);
    final file = File('${host.root.path}/maps/map.json');
    await file.parent.create(recursive: true);
    final detached = fixture.map
        .copyWith(layers: [MapLayer.environment(id: 'env', name: 'Forest')]);
    await file.writeAsString(jsonEncode(detached.toJson()));
    final model = fixture.project.models3d.single;
    final bytes = environmentModelGlb();
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final source = File('${host.root.path}/${model.relativePath}');
    await source.parent.create(recursive: true);
    await source.writeAsBytes(bytes);
    final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    final heroBytes = img.encodePng(img.Image(width: 1, height: 1));
    final heroArtifact =
        ContentArtifactRef.fromBytes(heroBytes, mediaType: 'image/png');
    final heroSource = File('${host.root.path}/assets/hero.png');
    await heroSource.writeAsBytes(heroBytes);
    final heroBlob =
        File('${host.root.path}/${assetBlobStorageKey(heroArtifact)}');
    await heroBlob.writeAsBytes(heroBytes);
    await File('${host.root.path}/assets/.pokemap-assets.json')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact),
      AssetRecord(
          id: 'hero-sprite',
          logicalPath: 'assets/hero.png',
          artifact: heroArtifact),
    ]).toJson()));
    await File('${host.root.path}/project.json')
        .writeAsString(jsonEncode(fixture.project.copyWith(
      settings: fixture.project.settings.copyWith(
          defaultPlayerCharacterId: 'hero', tileWidth: 1, tileHeight: 1),
      tilesets: [
        const ProjectTilesetEntry(
            id: 'hero-sheet',
            name: 'Hero',
            relativePath: 'assets/hero.png',
            source: ProjectRegularAtlasTilesetSource(
                assetId: 'hero-sprite',
                pixelWidth: 1,
                pixelHeight: 1,
                tileWidth: 1,
                tileHeight: 1))
      ],
      characters: [
        ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'hero-sheet',
            frameHeight: 1,
            animations: [
              for (final direction in [
                EntityFacing.north,
                EntityFacing.south,
                EntityFacing.east,
                EntityFacing.west
              ])
                CharacterAnimation(
                    state: CharacterAnimationState.walk,
                    direction: direction,
                    sourceAssetId: 'hero-sprite',
                    frames: [
                      const CharacterAnimationFrame(
                          source: TilesetSourceRect(x: 0, y: 0))
                    ])
            ])
      ],
    ).toJson()));
    final initialPreset = fixture.project.environmentPresets.single;
    final sourceOffset = Model3dVector3(x: -.5, y: .1875, z: 0);
    await host.mutate('environment.preset.upsert', {
      'preset': encodeEnvironmentPreset(EnvironmentPreset(
          id: initialPreset.id,
          name: initialPreset.name,
          templateId: initialPreset.templateId,
          palette: [
            EnvironmentPaletteItem(
                modelId: 'tree',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceDisabled,
                cellOffsetWorld: sourceOffset)
          ],
          defaultParams: initialPreset.defaultParams,
          sortOrder: initialPreset.sortOrder)),
    });
    await host.mutate('environment.attach_to_spatial_terrain',
        {'mapId': 'map', 'layerId': 'env'});
    await host.mutate('environment.area_create', {
      'mapId': 'map',
      'layerId': 'env',
      'areaId': 'forest',
      'name': 'Forest',
      'presetId': 'forest',
      'seed': 31
    });
    await host.mutate('environment.mask_paint', {
      'mapId': 'map',
      'layerId': 'env',
      'areaId': 'forest',
      'x': 0,
      'y': 0,
      'width': 6,
      'height': 4
    });
    final before = await file.readAsBytes();
    await host.mutate('environment.generate_apply',
        {'mapId': 'map', 'layerId': 'env', 'areaId': 'forest'});
    final saved = MapData.fromJson(jsonDecode(await file.readAsString()));
    expect(saved.spatialScene!.instances, hasLength(24));
    for (final instance in saved.spatialScene!.instances) {
      expect(instance.position.x, instance.position.x.floorToDouble());
      expect(
          instance.position.y,
          saved.spatialScene!
                  .worldHeightAt(instance.position.x, instance.position.z) +
              .1875);
    }
    final profile = GamePackageExportProfile(
        gameId: 'games.example.environment',
        gameVersion: '0.1.0',
        title: 'Forest',
        authorName: 'Yoahn',
        defaultLocale: 'fr',
        supportedLocales: ['fr']);
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: host.root, profile: profile);
    final exported = MapData.fromJson(jsonDecode(
        utf8.decode(projection.payloadFiles['project/maps/map.json']!)));
    expect(exported.spatialScene!.instances, saved.spatialScene!.instances);
    expect(projection.payloadFiles['project/${model.relativePath}'], bytes);
    await host.command('close', {'projectHandle': host.project});
    final reopened =
        await host.command('open', {'projectRoot': host.root.path});
    expect(reopened.status, AuthoringResultStatus.success);
    final snapshot = await host.snapshots
        .load(ProjectHandle(reopened.data['projectHandle'] as String));
    expect(snapshot.maps.single.spatialScene, saved.spatialScene);
    expect(
        snapshot
            .manifest.environmentPresets.single.palette.single.cellOffsetWorld,
        sourceOffset);
    final history = await host.mutations.history(
        ProjectHandle(reopened.data['projectHandle'] as String),
        limit: 1);
    await host.mutations.undo(
        ProjectHandle(reopened.data['projectHandle'] as String),
        entryId: (history['entries'] as List).first['entryId'] as String,
        idempotencyKey: 'undo-env');
    expect(await file.readAsBytes(), before);
    await host
        .command('close', {'projectHandle': reopened.data['projectHandle']});
  });
}

EnvironmentGenerationPreview generate(ProjectManifest project, MapData map,
        {EnvironmentGenerationRegion? region}) =>
    editing.previewGeneration(
        manifest: project,
        map: map,
        layerId: 'env',
        areaId: 'forest',
        projectRevision: 'current',
        region: region);
MapData apply(ProjectManifest project, MapData map,
        EnvironmentGenerationPreview preview) =>
    editing.applyGeneration(
        manifest: project,
        map: map,
        preview: preview,
        currentRevision: 'current');

({ProjectManifest project, MapData map}) spatialEnvironmentFixture(
    {int spacing = 0, bool modelDefaultBlocking = true,
    EnvironmentCollisionMode collisionMode = EnvironmentCollisionMode.forceDisabled}) {
  final model = ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'tree-source',
      relativePath: 'assets/models3d/tree.glb',
      blocksMovementByDefault: modelDefaultBlocking,
      inspection: const GlbModel3dInspector().inspect(environmentModelGlb()));
  final preset = EnvironmentPreset(
      id: 'forest',
      name: 'Forest',
      templateId: 'forest',
      palette: [
        EnvironmentPaletteItem(
            modelId: 'tree',
            weight: 1,
            collisionMode: collisionMode)
      ],
      defaultParams: EnvironmentGenerationParams(
          density: 1, variation: 0, edgeDensity: 1, minSpacingCells: spacing),
      sortOrder: 0);
  final map = MapData(
      version: ProjectVersion.v9,
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 6, height: 4),
      spatialScene:
          MapSpatialScene(width: 6, depth: 4, heightLevels: List.filled(24, 1)),
      layers: [
        MapLayer.environment(
            id: 'env',
            name: 'Forest',
            content:
                EnvironmentLayerContent(targetsSpatialTerrain: true, areas: [
              EnvironmentArea(
                  id: 'forest',
                  name: 'Forest',
                  presetId: 'forest',
                  seed: 31,
                  mask: EnvironmentAreaMask(
                      width: 6, height: 4, cells: List.filled(24, true)))
            ]))
      ]);
  final project = ProjectManifest(
      version: ProjectVersion.v9,
      name: 'Spatial forest',
      tilesets: const [],
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      models3d: [model],
      environmentPresets: [preset],
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ]);
  return (project: project, map: map);
}

List<int> environmentModelGlb() {
  final binary = ByteData(36);
  final positions = [-.2, 0.0, -.2, .2, 0.0, -.2, 0.0, 2.0, .2];
  for (var index = 0; index < positions.length; index++) {
    binary.setFloat32(index * 4, positions[index], Endian.little);
  }
  return encodeGlb({
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0]
      }
    ],
    'nodes': [
      {'mesh': 0}
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0}
          }
        ]
      }
    ],
    'buffers': [
      {'byteLength': 36}
    ],
    'bufferViews': [
      {'buffer': 0, 'byteLength': 36}
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 3,
        'type': 'VEC3',
        'min': [-.2, 0, -.2],
        'max': [.2, 2, .2]
      }
    ],
  }, binary.buffer.asUint8List());
}
