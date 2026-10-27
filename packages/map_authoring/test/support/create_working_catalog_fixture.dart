import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as img;
import 'glb_fixture.dart';
import '../domains/maps/border_spatial_actions_test.dart' show spatialBorderAuthoringFixture;

import '../domains/maps/healing_display_fixture.dart';

Future<void> main(List<String> arguments) async {
  final root = arguments.first;
  if (arguments.contains('--map-creation')) {
    await File('$root/source.glb').writeAsBytes(triangleGlb());
    await File('$root/source.png').writeAsBytes(img.encodePng(img.Image(width: 16, height: 16)));
    await File('$root/border.json').writeAsString(jsonEncode(encodeBorderBlueprintRecordJson(
        spatialBorderAuthoringFixture().project.borderCatalog.records.single,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion)).replaceAll('tree', 'house'));
  }
  final legacyHistory = arguments.contains('--legacy-history');
  final mapCreation = arguments.contains('--map-creation');
  final healing = arguments.contains('--story-map') ? healingProject() : null;
  final project = ProjectManifest(
      name: 'Transport catalog',
      version: mapCreation ? ProjectVersion.v9 : ProjectVersion.v8,
      settings: mapCreation ? ProjectSettings(dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()) : const ProjectSettings(),
      maps: arguments.contains('--story-map')
          ? const [
              ProjectMapEntry(
                  id: 'story', name: 'Story', relativePath: 'maps/story.json'),
              ProjectMapEntry(
                  id: 'foreign',
                  name: 'Foreign',
                  relativePath: 'maps/foreign.json'),
            ]
          : legacyHistory
              ? const [
                  ProjectMapEntry(
                      id: 'foreign',
                      name: 'Foreign',
                      relativePath: 'maps/foreign.json')
                ]
              : const [],
      eventRegistry: arguments.contains('--story-map')
          ? NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              legacyClaims: const [],
              records: [
                  NarrativeEventRecord.draft(NarrativeEventDraft(
                      id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                      name: 'Consumed event',
                      conditions: const [],
                      priority: 0,
                      order: 0)),
                ])
          : null,
      elements: [
        ...?healing?.elements,
        for (final element
            in healing?.elements ?? const <ProjectElementEntry>[])
          element.copyWith(id: 'alternate-${element.id}')
      ],
      elementCategories: healing?.elementCategories ?? const [],
      facts: legacyHistory
          ? [
              NarrativeFactDefinition(
                  id: 'fixture_fact',
                  label: 'Fixture fact',
                  legacyFlagName: 'fixture_alias')
            ]
          : const [],
      models3d: [
        if (arguments.contains('--light-workshop'))
          ProjectModel3dEntry(
              id: 'lamp',
              name: 'Lamp',
              sourceAssetId: 'model3d_lamp',
              relativePath: 'assets/models3d/lamp.glb',
              inspection: Model3dInspection(
                  bounds: Model3dBounds(
                      min: Model3dVector3.zero,
                      max: Model3dVector3(x: 1, y: 3, z: 1)),
                  meshCount: 1,
                  triangleCount: 4))
      ],
      tilesets: [
        ...?healing?.tilesets,
        for (var i = 0; i < 205; i++)
          ProjectTilesetEntry(
              id: 'tile-${i.toString().padLeft(3, '0')}',
              name: 'Object $i',
              relativePath: 'assets/object.png')
      ]);
  if (arguments.contains('--story-map')) {
    await Directory('$root/maps').create(recursive: true);
    await File('$root/maps/story.json').writeAsString(jsonEncode(const MapData(
      id: 'story',
      name: 'Story',
      size: GridSize(width: 8, height: 6),
      version: ProjectVersion.v8,
    ).toJson()));
    await File('$root/maps/foreign.json')
        .writeAsString('foreign map must remain unread');
  }
  if (legacyHistory && !arguments.contains('--story-map')) {
    await Directory('$root/maps').create(recursive: true);
    await File('$root/maps/foreign.json')
        .writeAsString('foreign map must remain unread');
  }
  if (arguments.contains('--monolithic')) {
    await File('$root/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    return;
  }
  final store = await CatalogStorageStore.open(projectRoot: root);
  final built = PortableCatalogPublication.encodeProject(project);
  var storage = built.storage;
  if (legacyHistory) {
    final units = CatalogSnapshot.readAllSync(
        root: storage.root,
        readObject: (reference) => storage.objects[reference.sha256]!).units;
    final metadata = <CatalogDefinitionUnit>[];
    for (final unit in CatalogMetadataDocuments.initialize(units)) {
      if (unit.key == CatalogNarrativeEventDocuments.indexKey ||
          unit.key.id.startsWith('["narrativeEventDocument') ||
          unit.key.id.startsWith('["factRuntimeIdentity",')) {
        continue;
      }
      metadata.add(unit.key == CatalogMetadataDocuments.fieldKey('facts')
          ? CatalogDefinitionUnit(
              key: unit.key,
              payload: {...unit.payload}
                ..remove('factRuntimeIdentitiesVersion'))
          : unit);
    }
    storage = CatalogStorageBuilder().build([...units, ...metadata]);
  }
  await store.publish(storage, expectedRootRevision: null);
  await File('$root/project.json').writeAsString(jsonEncode(
      WorkingProjectCatalogDescriptor(projectId: 'transport-fixture')
          .toJson()));
  if (legacyHistory) {
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'transport-fixture',
        actorId: 'local_cli',
        incrementalHistory: true);
    try {
      final receipts = <AuthoringReceipt>[];
      for (final name in ['Legacy first', 'Legacy second']) {
        final key =
            CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile-204');
        final unit = (await session.snapshot.lookup(key))!;
        final value = Map<String, Object?>.from(unit.payload['value'] as Map)
          ..['name'] = name;
        final plan = await session.planPatch(upserts: [
          CatalogDefinitionUnit(
              key: key,
              payload: {...unit.payload, 'value': value},
              references: unit.references)
        ], idempotencyKey: name.replaceAll(' ', '-'));
        receipts.add(await session.apply(plan));
      }
      await session.prepareMetadataDocuments(force: true);
      stdout.writeln(jsonEncode({
        'first': receipts[0].receiptId,
        'second': receipts[1].receiptId,
        'helperPid': pid,
        'originalReceipts': {
          for (final receipt in receipts) receipt.receiptId: receipt.toJson()
        }
      }));
    } finally {
      await session.close();
    }
  }
}
