import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;
import '../maps/map_catalog_fixture.dart';
import 'element_definition_fixture.dart';
import 'element_definition_transaction_test.dart'
    show applyConfirmed, independentlyReopen, registeredFixture;
import 'resource_information_fixture.dart';

void main() {
  test('JSONL reviews the scope, replaces every map occurrence and undoes it',
      () async {
    final fixture = await _project();
    addTearDown(fixture.dispose);
    final before = await _files(fixture);
    final plan = await fixture.plan('resource.usages.replace', _parameters());
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    final preview = (plan.data['plan'] as Map)['preview'] as Map;
    expect(preview['mapCount'], 2);
    expect(preview['occurrenceCount'], 3);
    expect(preview['definitionsUnchanged'], isTrue);
    expect(
        {
          for (final map in preview['maps'] as List)
            (map as Map)['mapId']: map['instanceIds']
        },
        {
          'garden': ['g1', 'g2'],
          'house': ['h1'],
        });
    expect(await _files(fixture), before);
    final unconfirmed = await fixture.apply(plan);
    expect(unconfirmed.status, AuthoringResultStatus.failure);
    expect(await _files(fixture), before);
    final applied = await applyConfirmed(fixture, plan);
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final reopened = await independentlyReopen(fixture.root);
    final maps = {for (final map in reopened.maps) map.id: map};
    expect(maps['garden']!.placedElements.map((e) => e.elementId),
        ['bush', 'bush']);
    expect(
        {for (final e in maps['house']!.placedElements) e.id: e.elementId},
        {'h1': 'bush', 'h2': 'rock'});
    expect(maps['garden']!.placedElements.first.pos, const GridPos(x: 1, y: 1));
    final after = await _files(fixture);
    expect(after['project.json'], before['project.json']);
    expect(after['maps/empty.json'], before['maps/empty.json']);
    expect(after['maps/garden.json'], isNot(before['maps/garden.json']));
    final receipt = applied.data['receipt'] as Map;
    final undone = await fixture.command('undo', {
      'projectHandle': fixture.project,
      'entryId': receipt['receiptId'],
      'idempotencyKey': 'undo-replace-usages',
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: jsonEncode(undone.toJson()));
    expect(await _files(fixture), before);
  });

  test('incompatible or unknown replacements are refused before any write',
      () async {
    final fixture = await _project();
    addTearDown(fixture.dispose);
    final before = await _files(fixture);
    for (final (replacement, code) in [
      ('decor', 'resource.usages.replacement_same'),
      ('missing', 'resource.usages.replacement_unknown'),
    ]) {
      final plan = await fixture.plan('resource.usages.replace',
          _parameters(replacement: replacement));
      expect(plan.status, AuthoringResultStatus.failure);
      expect(plan.error!.details['domainCode'], code);
    }
    final family = await fixture.plan('resource.usages.replace',
        {..._parameters(), 'family': 'terrains'});
    expect(family.error!.details['domainCode'],
        'resource.usages.family_unsupported');
    expect(await _files(fixture), before);
  });

  test('one occurrence that cannot take the replacement leaves every map intact',
      () async {
    final fixture = await _project(edgeOccurrence: true);
    addTearDown(fixture.dispose);
    final before = await _files(fixture);
    final plan = await fixture.plan(
        'resource.usages.replace', _parameters(replacement: 'wide'));
    expect(plan.status, AuthoringResultStatus.failure);
    expect(plan.error!.details['domainCode'],
        'resource.usages.replacement_incompatible');
    expect(plan.error!.details['mapId'], 'house');
    expect(plan.error!.details['reason'], 'outOfBounds');
    expect(await _files(fixture), before);
  });

  test('a usage outside map placements refuses the whole replacement',
      () async {
    final fixture = await _project(borderUsage: true);
    addTearDown(fixture.dispose);
    final before = await _files(fixture);
    final plan = await fixture.plan('resource.usages.replace', _parameters());
    expect(plan.status, AuthoringResultStatus.failure);
    expect(plan.error!.details['domainCode'],
        'resource.usages.unsupported_usages');
    expect(jsonEncode(plan.error!.details['usages']), contains('border'));
    expect(await _files(fixture), before);
  });

  test('a map changed after the review refuses the confirmed publication',
      () async {
    final fixture = await _project();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('resource.usages.replace', _parameters());
    expect(plan.status, AuthoringResultStatus.success);
    final confirmation = await fixture.command('confirm',
        {'projectHandle': fixture.project, 'planId': plan.data['planId']});
    expect(confirmation.status, AuthoringResultStatus.success);
    final empty = File('${fixture.root.path}/maps/empty.json');
    final changed = MapData.fromJson(
            jsonDecode(await empty.readAsString()) as Map<String, dynamic>)
        .copyWith(placedElements: const [
      MapPlacedElement(
          id: 'late', layerId: 'base', elementId: 'decor', pos: GridPos(x: 0, y: 0)),
    ]);
    await empty.writeAsString(jsonEncode(changed.toJson()));
    final external = await _files(fixture);
    final result = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
      'operationId': 'stale-replace',
      'confirmationToken': confirmation.data['confirmationToken'],
    });
    expect(result.status, AuthoringResultStatus.failure);
    expect(await _files(fixture), external);
  });

  test('3D usages are repointed to another model on every spatial map', () {
    final maps = [
      _spatial('cave', ['a', 'b']),
      _spatial('hill', ['c']),
    ];
    final base = elementDefinitionFixture();
    final manifest = base.copyWith(
      settings: base.settings.copyWith(dimension: ProjectDimension.threeD),
      models3d: [_model('old'), _model('new')],
      maps: [
        for (final map in maps)
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ],
    );
    AuthoringMutationDraft build(String replacement) =>
        const ResourceUsageReplacementActions().build(catalogContext(
            _withAssetCatalog(catalogSnapshot(maps, project: manifest)),
            'resource.usages.replace', {
          'family': 'models3d',
          'resourceId': 'old',
          'replacementId': replacement,
        }));
    final draft = build('new');
    expect(draft.preview['occurrenceCount'], 3);
    expect(draft.changeSet.changes.map((c) => c.resource.id), ['cave', 'hill']);
    for (final change in draft.changeSet.changes) {
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>);
      expect(map.spatialScene!.instances.map((i) => i.modelId),
          everyElement('new'));
    }
    expect(
        () => build('decor'),
        throwsA(isA<VisualLibraryException>().having((e) => e.code, 'code',
            'resource.usages.replacement_incompatible')));
  });

  test(
      'Border pieces of a duplicate model are repointed and regenerated identically',
      () {
    final base = spatialBorderAuthoringFixture(published: true);
    SpatialBorderResolutionResult resolve(
            ProjectManifest project, MapData map) =>
        resolveSpatialBorderFeature(
            manifest: project, map: map, layerId: 'border', featureId: 'fence');
    final map = applySpatialBorderFeaturePreview(base.map,
        manifest: base.project,
        proposedResult: resolve(base.project, base.map));
    final tree =
        base.project.models3d.singleWhere((model) => model.id == 'tree');
    final copy = ProjectModel3dEntry.fromJson({
      ...tree.toJson(),
      'id': 'tree-copy',
      'sourceAssetId': tree.sourceAssetId.replaceAll('tree', 'tree-copy'),
      'relativePath': tree.relativePath.replaceAll('tree', 'tree-copy'),
    });
    final manifest = base.project.copyWith(
      models3d: [...base.project.models3d, copy],
      maps: [
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ],
    );
    final draft = const ResourceUsageReplacementActions().build(catalogContext(
        _withAssetCatalog(catalogSnapshot([map], project: manifest)),
        'resource.usages.replace', {
      'family': 'models3d',
      'resourceId': 'tree',
      'replacementId': 'tree-copy',
    }));

    expect(draft.preview['repointedBorderIds'], ['fence']);
    expect(draft.referenceImpact['definitionsUnchanged'], isFalse);
    final project = draft.projectedProject!;
    final record = project.borderCatalog.records.single;
    expect(
        record.latestPublished!.revision,
        base.project.borderCatalog.records.single.latestPublished!.revision +
            1);
    final change = draft.changeSet.changes
        .singleWhere((change) => change.resource.kind == 'map');
    final after = MapData.fromJson(
        jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>);
    expect(after.spatialScene!.instances.where((i) => i.modelId == 'tree'),
        isEmpty);
    final feature =
        (after.layers.single as BorderLayer).content.features.single;
    expect(
        spatialBorderMaterializationIsFresh(
            resolve(project, after), feature.materialization!, after),
        isTrue);
    expect({
      for (final instance in after.spatialScene!.instances)
        instance.id: instance
    }, {
      for (final instance in map.spatialScene!.instances)
        instance.id: instance.modelId == 'tree'
            ? instance.copyWith(modelId: 'tree-copy')
            : instance
    });
  });

  test('instances of a Border that no longer uses the model follow an identical copy only',
      () {
    final base = spatialBorderAuthoringFixture(published: true);
    final map = applySpatialBorderFeaturePreview(base.map,
        manifest: base.project,
        proposedResult: resolveSpatialBorderFeature(
            manifest: base.project,
            map: base.map,
            layerId: 'border',
            featureId: 'fence'));
    final tree = base.project.models3d.singleWhere((model) => model.id == 'tree');
    ProjectModel3dEntry copyOf(String id, {Map<String, Object?> changes = const {}}) =>
        ProjectModel3dEntry.fromJson({
          ...tree.toJson(),
          'id': id,
          'sourceAssetId': tree.sourceAssetId.replaceAll('tree', id),
          'relativePath': tree.relativePath.replaceAll('tree', id),
          ...changes,
        });
    final catalog = base.project.borderCatalog;
    final moved = base.project.copyWith(
      models3d: [
        ...base.project.models3d,
        copyOf('other'),
        copyOf('tree-copy'),
        copyOf('tree-bigger', changes: {'scale': 2.0}),
      ],
      borderCatalog: ProjectBorderCatalog(
          formatVersion: catalog.formatVersion,
          records: [
            for (final record in catalog.records)
              repointModelInBorderRecord(record,
                  modelId: 'tree',
                  replacementId: 'other',
                  formatVersion: catalog.formatVersion)
          ],
          visualSnapshots: catalog.visualSnapshots),
      maps: [
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ],
    );
    AuthoringMutationDraft replace(String replacement) =>
        const ResourceUsageReplacementActions().build(catalogContext(
            _scoped(_withAssetCatalog(catalogSnapshot([map], project: moved))),
            'resource.usages.replace', {
          'family': 'models3d',
          'resourceId': 'tree',
          'replacementId': replacement,
        }));

    final draft = replace('tree-copy');
    final after = MapData.fromJson(jsonDecode(
            utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);
    expect(after.spatialScene!.instances.where((i) => i.modelId == 'tree'),
        isEmpty);
    expect((after.layers.single as BorderLayer).content.features.single.materialization,
        (map.layers.single as BorderLayer).content.features.single.materialization);
    expect(
        () => replace('tree-bigger'),
        throwsA(isA<VisualLibraryException>().having((e) => e.code, 'code',
            'resource.usages.replacement_incompatible')));
  });
}

Map<String, Object?> _parameters({String replacement = 'bush'}) => {
      'family': 'decors',
      'resourceId': 'decor',
      'replacementId': replacement,
    };

Future<ResourceInformationFixture> _project(
    {bool edgeOccurrence = false, bool borderUsage = false}) async {
  final base = elementDefinitionFixture();
  final decor = base.elements.single;
  final maps = [
    catalogMap('garden').copyWith(placedElements: [
      _placed('g1', 'decor', 1, 1),
      _placed('g2', 'decor', 3, 2),
    ]),
    catalogMap('house').copyWith(placedElements: [
      _placed('h1', 'decor', edgeOccurrence ? 5 : 2, 2),
      _placed('h2', 'rock', 0, 0),
    ]),
    catalogMap('empty'),
  ];
  final manifest = base.copyWith(
    maps: [
      for (final map in maps)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
    ],
    elements: [
      decor,
      decor.copyWith(id: 'bush', name: 'Buisson'),
      decor.copyWith(id: 'rock', name: 'Rocher'),
      decor.copyWith(id: 'wide', name: 'Large', frames: const [
        TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1)),
      ]),
    ],
    borderCatalog: borderUsage ? retainedElementBorder() : base.borderCatalog,
  );
  final fixture = await registeredFixture(manifest: manifest);
  for (final map in maps) {
    final file = File('${fixture.root.path}/maps/${map.id}.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
  }
  return fixture;
}

MapPlacedElement _placed(String id, String elementId, int x, int y) =>
    MapPlacedElement(
        id: id, layerId: 'base', elementId: elementId, pos: GridPos(x: x, y: y));

Future<Map<String, List<int>>> _files(ResourceInformationFixture fixture) async {
  final result = <String, List<int>>{};
  for (final path in [
    'project.json',
    'maps/garden.json',
    'maps/house.json',
    'maps/empty.json'
  ]) {
    result[path] = await File('${fixture.root.path}/$path').readAsBytes();
  }
  return result;
}

MapData _spatial(String id, List<String> instances) => MapData(
      id: id,
      name: id,
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(
        width: 4,
        depth: 4,
        levelHeight: .25,
        heightLevels: List.filled(16, 0),
        instances: [
          for (final (index, instance) in instances.indexed)
            SpatialModelInstance(
              id: instance,
              modelId: 'old',
              position: Model3dVector3(x: index + .5, y: 0, z: .5),
            ),
        ],
      ),
    );

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: '$id-source',
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.5, y: 0, z: -.5),
          max: Model3dVector3(x: .5, y: 1, z: .5),
        ),
        meshCount: 1,
        triangleCount: 4,
      ),
    );

ProjectSnapshot _withAssetCatalog(ProjectSnapshot base) {
  final catalog = utf8.encode(jsonEncode(elementCatalog.toJson()));
  return ProjectSnapshot(
    projectHandle: base.projectHandle,
    revision: base.revision,
    manifest: base.manifest,
    maps: base.maps,
    pokemonInventoryComplete: true,
    resourceFingerprints: {
      ...base.resourceFingerprints,
      assetCatalogResourceIdentity: computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
            relativePath: assetCatalogStorageKey, bytes: catalog),
      ]),
    },
    resourceBytes: {
      for (final identity in base.resourceFingerprints.keys)
        identity: base.resourceBytes(identity),
      assetCatalogResourceIdentity: catalog,
    },
  );
}

ProjectSnapshot _scoped(ProjectSnapshot base) => ProjectSnapshot(
      projectHandle: base.projectHandle,
      revision: base.revision,
      manifest: base.manifest,
      maps: base.maps,
      pokemonInventoryComplete: true,
      materializedCatalogProject: true,
      scopedStorageRevisions: const {},
      resourceFingerprints: base.resourceFingerprints,
      resourceBytes: {
        for (final identity in base.resourceFingerprints.keys)
          identity: base.resourceBytes(identity),
      },
    );
