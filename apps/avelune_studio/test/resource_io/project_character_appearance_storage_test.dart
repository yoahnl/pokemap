import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show CatalogStorageStore, WorkingProjectCatalog;
import 'package:map_core/map_core.dart';

void main() {
  test(
    'character appearance publishes only its definition and reopens',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'actor-appearance-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final root = await directory.resolveSymbolicLinks();
      final rigged = _model('actor-rig', skinned: true);
      final foreignModel = _model('reserve-model');
      final manifest = ProjectManifest(
        name: 'Personnages',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [
          ProjectMapEntry(id: 'map', name: 'Carte', relativePath: 'map.json'),
        ],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'sheet',
            name: 'Planche',
            relativePath: 'sheet.png',
          ),
        ],
        models3d: [rigged, foreignModel],
        characters: [
          const ProjectCharacterEntry(
            id: 'actor',
            name: 'Personnage',
            tilesetId: 'sheet',
          ),
          for (var index = 0; index < 12; index++)
            ProjectCharacterEntry(
              id: 'reserve-$index',
              name: 'Réserve $index',
              tilesetId: 'sheet',
            ),
        ],
      );
      final map = File('$root/map.json');
      final mapBytes = utf8.encode(
        jsonEncode(
          MapData(
            id: 'map',
            name: 'Carte',
            version: ProjectVersion.v9,
            size: const GridSize(width: 2, height: 2),
            spatialScene: MapSpatialScene(width: 2, depth: 2),
          ).toJson(),
        ),
      );
      await map.writeAsBytes(mapBytes);
      final working = await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root),
        projectId: 'appearance-fixture',
        project: manifest,
      );
      final foreign = {
        for (var index = 0; index < 12; index++)
          (await working.catalog.snapshot.indexEntry(
            CatalogDefinitionKey(
              CatalogDefinitionKind.character,
              'reserve-$index',
            ),
          ))!.reference.sha256,
        (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, foreignModel.id),
        ))!.reference.sha256,
      };
      final sessions = LocalProjectSessionAdapter();
      final session = await sessions.open(root);
      addTearDown(() => sessions.close(session));
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final resources = LocalResourceAdapter(
        session: session,
        mapAdapter: maps,
      );
      addTearDown(resources.dispose);
      var read = await resources.readWorkshopCharacter('actor');
      final observed = <String>[];
      final outside = Zone.current;
      Future<ResourceMutationReceipt> edit(Map<String, Object?> parameters) =>
          IOOverrides.runZoned(
            () => resources.editWorkshopCharacter(
              'actor',
              'characterStudio.character.update',
              parameters,
              expectedRevision: read.revision,
            ),
            createFile: (path) {
              observed.add(path);
              return outside.run(() => File(path));
            },
          );
      for (final enabled in [true, false, null]) {
        final receipt = await edit({'contactShadow': enabled});
        expect(receipt.changedPaths, ['catalog/HEAD.json']);
        read = await resources.readWorkshopCharacter('actor');
        expect(read.project.characters.single.contactShadow, enabled);
      }

      final invalid = ProjectCharacterSpatialModel(
        modelId: rigged.id,
        clips: const {CharacterAnimationState.idle: 12},
      );
      await expectLater(
        edit({'spatialModel': invalid.toJson()}),
        throwsA(isA<ResourceFailure>()),
      );
      expect(
        (await resources.readWorkshopCharacter('actor')).revision,
        read.revision,
      );

      final binding = ProjectCharacterSpatialModel(
        modelId: rigged.id,
        clips: const {
          CharacterAnimationState.idle: 0,
          CharacterAnimationState.walk: 1,
        },
      );
      final assigned = await edit({
        'spatialModel': binding.toJson(),
        'contactShadow': true,
      });
      expect(assigned.changedPaths, ['catalog/HEAD.json']);
      read = await resources.readWorkshopCharacter('actor');
      expect(read.project.characters.single.spatialModel, binding);
      expect(
        observed.where(
          (path) =>
              path.endsWith('/map.json') ||
              path.endsWith('/sheet.png') ||
              path.endsWith('.glb') ||
              foreign.any(path.contains),
        ),
        isEmpty,
      );
      expect(await map.readAsBytes(), mapBytes);

      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadCatalog(session);
      final reopenedProject = await reopened.readResourcePreview(
        session,
        'character',
        'actor',
      );
      expect(reopenedProject.models3d, [rigged]);
      expect(
        reopenedProject.characters.single,
        manifest.characters.first.copyWith(
          spatialModel: binding,
          contactShadow: true,
        ),
      );

      final detached = await edit({'spatialModel': null});
      expect(detached.changedPaths, ['catalog/HEAD.json']);
      read = await resources.readWorkshopCharacter('actor');
      expect(read.project.characters.single.spatialModel, isNull);
      expect(read.project.characters.single.contactShadow, isTrue);
    },
  );
}

ProjectModel3dEntry _model(String id, {bool skinned = false}) =>
    ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: '$id-source',
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
        skinned: skinned,
        animations: [
          if (skinned) ...[
            Model3dAnimation(index: 0, name: 'Au repos', durationSeconds: 1),
            Model3dAnimation(index: 1, name: 'Marche', durationSeconds: 2),
          ],
        ],
      ),
    );
