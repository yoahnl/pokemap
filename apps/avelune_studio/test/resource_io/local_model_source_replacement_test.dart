import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final unrelated in [0, 90]) {
    test(
      'Studio replaces only the selected source cold and repeated with $unrelated unrelated models',
      () async {
        final fixture = await _Fixture.create(unrelated);
        addTearDown(fixture.dispose);
        var baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        await fixture.maps.loadMapSelection(
          fixture.session,
          baseline.manifest.maps.first,
        );
        baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        await fixture.maps.loadWorkshop(
          fixture.session,
          MapWorkspaceWorkshop.dialogue,
        );
        baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        final lightModel = (baseline.manifest.models3d as ProjectModel3dEntries)
            .lookup('house')!;
        await fixture.maps.acceptModelLight(
          fixture.session,
          lightModel,
          baseline.revision,
          baseline.revision,
        );
        baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        final mapBefore = await fixture.mapFile.readAsBytes();
        final descriptorBefore = await File('${fixture.root.path}/project.json')
            .readAsBytes();
        for (var operation = 0; operation < 2; operation++) {
          final replacement = _volumeGlb(
            edit: (json) {
              json['nodes'][0]['translation'] = [0, operation + 2, 0];
            },
          );
          await fixture.input.writeAsBytes(replacement);
          final denied = <String>[];
          final outside = Zone.current;
          final receipt = await IOOverrides.runZoned(
            () => fixture.resources.replaceModelSource(
              modelId: 'house',
              sourcePath: fixture.input.path,
            ),
            createFile: (path) {
              final file = outside.run(() => File(path));
              return fixture.foreignPaths.contains(path)
                  ? _UnreadableFile(file, denied)
                  : file;
            },
          );
          expect(denied, isEmpty);
          final model = receipt.manifest.models3d.singleWhere(
            (model) => model.id == 'house',
          );
          expect(model.sourceAssetId, 'house-source');
          expect(model.scale, 1.25);
          expect(model.pivot.toJson(), {'x': 0.25, 'y': 0.0, 'z': 0.0});
          expect(model.inspection.bounds.min.y, operation + 2);
          expect(receipt.changedModels.keys, ['house']);
          expect(receipt.modelSourceRevisions.keys, ['house-source']);
          expect(await fixture.resources.readModel('house'), replacement);
          expect(await fixture.mapFile.readAsBytes(), mapBefore);
          expect(
            await File('${fixture.root.path}/project.json').readAsBytes(),
            descriptorBefore,
          );
        }
        await fixture.maps.loadMapSelection(
          fixture.session,
          baseline.manifest.maps.first,
        );
        final revisited = await fixture.maps.resourceBaseline(fixture.session);
        expect(
          revisited.manifest.models3d
              .singleWhere((model) => model.id == 'house')
              .inspection
              .bounds
              .min
              .y,
          3,
        );
        final reopened = LocalMapWorkspaceAdapter();
        await reopened.loadCatalog(fixture.session);
        final selected = await reopened.loadResourceKind(
          fixture.session,
          'model3d',
        );
        expect(
          selected.metadata.models3d
              .singleWhere((model) => model.id == 'house')
              .inspection
              .bounds
              .min
              .y,
          3,
        );
      },
    );
  }
  test(
    'source acceptance publishes only the model delta without resource reads',
    () async {
      final fixture = await _Fixture.create(90);
      addTearDown(fixture.dispose);
      final baseline = await fixture.maps.resourceBaseline(fixture.session);
      final workspace = MapWorkspaceController(fixture.session, fixture.maps)
        ..project = baseline.manifest;
      addTearDown(workspace.dispose);
      final visuals = await StudioMapResources.load(
        fixture.session,
        baseline.manifest,
      );
      addTearDown(visuals.dispose);
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: fixture.resources,
        visuals: visuals,
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      await fixture.input.writeAsBytes(
        _volumeGlb(
          edit: (json) {
            json['materials'] = [
              {
                'pbrMetallicRoughness': {
                  'baseColorFactor': [0, 1, 0, 1],
                },
              },
            ];
            json['meshes'][0]['primitives'][0]['material'] = 0;
          },
        ),
      );
      final receipt = await fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      );
      var notifications = 0;
      visuals.modelSourceUpdates.addListener(() => notifications++);
      final attempted = <String>[];
      final outside = Zone.current;
      await IOOverrides.runZoned(
        () => navigation.accept(receipt),
        createFile: (path) =>
            _UnreadableFile(outside.run(() => File(path)), attempted),
      );
      expect(attempted, isEmpty);
      expect(workspace.project, receipt.manifest);
      expect(visuals.manifest, same(workspace.project));
      expect(
        visuals.modelSourceUpdates.definition('house'),
        receipt.changedModels['house'],
      );
      expect(
        visuals.modelSourceUpdates.revision('house-source'),
        receipt.modelSourceRevisions['house-source'],
      );
      expect(notifications, 1);
      expect(visuals.store.decoder.reads, 0);
      expect(visuals.store.decoder.decodes, 0);
      expect(navigation.pendingReceipt, isNull);
      final current = workspace.project;
      final lookups = workspace.modelSourceProjectionLookups;
      final unchanged = await fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      );
      expect(unchanged.noChange, true);
      await navigation.accept(unchanged);
      expect(workspace.project, same(current));
      expect(workspace.modelSourceProjectionLookups, lookups);
      expect(notifications, 1);
    },
  );
  test('replacement outside the loaded projection does not materialize the catalogue', () async {
    final fixture = await _Fixture.create(90, loadModels: false);
    addTearDown(fixture.dispose);
    final before = await fixture.maps.resourceBaseline(fixture.session);
    expect(before.manifest.models3d, isEmpty);
    expect(before.manifest.models3d, isA<ProjectModel3dEntries>());
    final bytes = _volumeGlb(
      edit: (json) {
        json['nodes'][0]['translation'] = [0, 8, 0];
      },
    );
    await fixture.input.writeAsBytes(bytes);
    final receipt = await fixture.resources.replaceModelSource(
      modelId: 'house',
      sourcePath: fixture.input.path,
    );
    expect(receipt.manifest.models3d, isEmpty);
    expect(receipt.changedModels['house']!.inspection.bounds.min.y, 8);
    expect(await fixture.resources.readModel('house'), bytes);
    final reopened = LocalMapWorkspaceAdapter();
    await reopened.loadCatalog(fixture.session);
    final all = await reopened.loadResourceKind(fixture.session, 'model3d');
    expect(
      all.metadata.models3d
          .singleWhere((model) => model.id == 'house')
          .inspection
          .bounds
          .min
          .y,
      8,
    );
  });
  for (final tampered in [false, true]) {
    test(
      'published replacement reconciliation is local and detects tampering=$tampered',
      () async {
        final fixture = await _Fixture.create(
          90,
          beforeReconciliation: () async {
            throw StateError('Injected refresh failure');
          },
        );
        addTearDown(fixture.dispose);
        await fixture.input.writeAsBytes(
          _volumeGlb(
            edit: (json) {
              json['nodes'][0]['translation'] = [0, 4, 0];
            },
          ),
        );
        ResourceMutationReceipt? receipt;
        try {
          await fixture.resources.replaceModelSource(
            modelId: 'house',
            sourcePath: fixture.input.path,
          );
          fail('Expected partial publication');
        } on ResourceFailure catch (failure) {
          receipt = failure.partialReceipt;
        }
        expect(receipt, isNotNull);
        final headFile = File(
          '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
        );
        final head = await headFile.readAsBytes();
        if (tampered) {
          await File('${fixture.root.path}/assets/models3d/house.glb')
              .writeAsBytes(_volumeGlb());
        }
        final outside = Zone.current;
        final denied = <String>[];
        final reconciliation = IOOverrides.runZoned(
          () => fixture.resources.reconcileReceipt(receipt!),
          createFile: (path) {
            final file = outside.run(() => File(path));
            return fixture.foreignPaths.contains(path)
                ? _UnreadableFile(file, denied)
                : file;
          },
        );
        if (tampered) {
          await expectLater(reconciliation, throwsA(anything));
        } else {
          await reconciliation;
          expect(
            (await fixture.maps.resourceBaseline(fixture.session))
                .manifest
                .models3d
                .singleWhere((model) => model.id == 'house')
                .inspection
                .bounds
                .min
                .y,
            4,
          );
        }
        expect(denied, isEmpty);
        expect(await headFile.readAsBytes(), head);
      },
    );
  }
  test('Studio explains incompatible animation replacement and preserves the source', () async {
    final fixture = await _Fixture.create(0);
    addTearDown(fixture.dispose);
    final original = await fixture.resources.readModel('house');
    await fixture.input.writeAsBytes(animatedGlb());
    await expectLater(
      fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      ),
      throwsA(
        isA<ResourceFailure>().having(
          (failure) => failure.message,
          'message',
          contains('animations disponibles'),
        ),
      ),
    );
    expect(await fixture.resources.readModel('house'), original);
  });
  test(
    'scoped context can still materialize a subsequent full resource action',
    () async {
      final fixture = await _Fixture.create(0);
      addTearDown(fixture.dispose);
      await fixture.input.writeAsBytes(
        _volumeGlb(
          edit: (json) {
            json['nodes'][0]['translation'] = [0, 5, 0];
          },
        ),
      );
      await fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      );
      final configured = await fixture.resources.mutate('model3d.configure', {
        'modelId': 'house',
        'name': 'Renamed house',
      });
      expect(configured.manifest.models3d.single.name, 'Renamed house');
      expect(configured.manifest.models3d.single.inspection.bounds.min.y, 5);
    },
  );
}

final class _Fixture {
  _Fixture(
    this.root,
    this.session,
    this.maps,
    this.resources,
    this.input,
    this.foreignPaths,
  );

  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final LocalResourceAdapter resources;
  final File input;
  final Set<String> foreignPaths;
  File get mapFile => File('${root.path}/maps/room.json');

  static Future<_Fixture> create(
    int unrelated, {
    Future<void> Function()? beforeReconciliation,
    bool loadModels = true,
  }) async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio_model_source_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    final bytes = _volumeGlb();
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'model/gltf-binary',
    );
    final model = ProjectModel3dEntry(
      id: 'house',
      name: 'House',
      sourceAssetId: 'house-source',
      relativePath: 'assets/models3d/house.glb',
      scale: 1.25,
      pivot: Model3dVector3(x: .25, y: 0, z: 0),
      inspection: const GlbModel3dInspector().inspect(bytes),
    );
    final manifest = ProjectManifest(
      name: 'Scoped source replacement',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: [
        const ProjectMapEntry(
          id: 'room',
          name: 'Room',
          relativePath: 'maps/room.json',
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'foreign-$i',
            name: 'Foreign $i',
            relativePath: 'maps/foreign-$i.json',
          ),
      ],
      tilesets: const [],
      models3d: [
        model,
        for (var i = 0; i < unrelated; i++)
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'id': 'foreign-$i',
            'name': 'Foreign $i',
            'sourceAssetId': 'foreign-source-$i',
            'relativePath': 'assets/models3d/foreign-$i.glb',
          }),
      ],
    );
    final working = await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-source-replacement',
      project: manifest,
    );
    final assetFile = File('${root.path}/$assetCatalogStorageKey');
    await assetFile.parent.create(recursive: true);
    await assetFile.writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            AssetRecord(
              id: 'house-source',
              logicalPath: model.relativePath,
              artifact: artifact,
            ),
            for (var i = 0; i < unrelated; i++)
              AssetRecord(
                id: 'foreign-source-$i',
                logicalPath: 'assets/models3d/foreign-$i.glb',
                artifact: artifact,
              ),
          ],
        ).toJson(),
      ),
    );
    final source = File('${root.path}/${model.relativePath}');
    await source.parent.create(recursive: true);
    await source.writeAsBytes(bytes);
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    final foreignPaths = <String>{};
    for (var i = 0; i < manifest.maps.length; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(
          CatalogDefinitionKind.catalogMetadata,
          jsonEncode(['projectDefinition', 'maps', i]),
        ),
      ))!;
      foreignPaths.add(
        '${root.path}/catalog/objects/${entry.reference.sha256}.json',
      );
    }
    for (var i = 0; i < unrelated; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'foreign-$i'),
      ))!;
      foreignPaths.add(
        '${root.path}/catalog/objects/${entry.reference.sha256}.json',
      );
    }
    for (final entry in manifest.maps) {
      final file = File('${root.path}/${entry.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        entry.id == 'room'
            ? jsonEncode(
                MapData(
                  id: 'room',
                  name: 'Room',
                  version: ProjectVersion.v9,
                  size: const GridSize(width: 8, height: 8),
                  spatialScene: MapSpatialScene(
                    width: 8,
                    depth: 8,
                    instances: [
                      SpatialModelInstance(
                        id: 'house-placed',
                        modelId: 'house',
                        position: Model3dVector3(x: 2, y: 0, z: 2),
                        rotationDegrees: 90,
                        scale: .8,
                        blocksMovement: true,
                      ),
                    ],
                  ),
                ).toJson(),
              )
            : 'unrelated map must not be decoded',
      );
      foreignPaths.add(file.path);
    }
    final session = ProjectSession(
      sessionId: root.path,
      name: manifest.name,
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    if (loadModels) await maps.loadResourceKind(session, 'model3d');
    final resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      beforeReconciliation: beforeReconciliation,
    );
    final input = File('${root.path}/replacement.glb');
    return _Fixture(root, session, maps, resources, input, foreignPaths);
  }

  Future<void> dispose() async {
    await resources.dispose();
    await root.delete(recursive: true);
  }
}

final class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<int> _volumeGlb({void Function(Map<String, dynamic>)? edit}) =>
    triangleGlb(
      edit: (json) {
        json['nodes'][0]['rotation'] = [
          0,
          .3826834323650898,
          0,
          .9238795325112867,
        ];
        edit?.call(json);
      },
    );
