import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'working presentation opens and publishes without unrelated definitions',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'presentation_scope_',
      );
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Projet ciblé',
        maps: const [
          ProjectMapEntry(
            id: 'unavailable',
            name: 'Autre carte',
            relativePath: 'maps/unavailable.json',
          ),
        ],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'unused',
            name: 'Autre atlas',
            relativePath: 'unused.png',
          ),
        ],
        presentationCinematics: [
          PresentationCinematicAsset(
            id: 'intro',
            title: 'Introduction',
            durationUs: 1000000,
          ),
        ],
      );
      final working = await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root.path),
        projectId: 'presentation-scope',
        project: project,
      );
      final unused = await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'unused'),
      );
      final poison = File(
        '${root.path}/catalog/objects/${unused!.reference.sha256}.json',
      );
      await poison.writeAsString(
        'This unrelated definition must never be read.',
      );
      final session = ProjectSession(
        sessionId: 'presentation-scope',
        name: project.name,
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      await maps.loadWorkshop(session, MapWorkspaceWorkshop.presentation);
      final port = LocalPresentationAdapter(session: session, mapAdapter: maps);
      final opened = await port.load('intro');
      expect(opened.asset.title, 'Introduction');
      final prepared = await port.prepare(opened.projection.manifest);
      expect(prepared.manifest.presentationCinematics.single.id, 'intro');
      final saved = await port.publish(
        asset: PresentationCinematicAsset(
          id: 'intro',
          title: 'Introduction modifiée',
          durationUs: 1000000,
        ),
        base: opened,
      );
      expect(saved.snapshot!.asset.title, 'Introduction modifiée');
      final reopened = await LocalPresentationAdapter(
        session: session,
        mapAdapter: LocalMapWorkspaceAdapter(),
      ).load('intro');
      expect(reopened.asset.title, 'Introduction modifiée');
      expect(
        await poison.readAsString(),
        'This unrelated definition must never be read.',
      );
    },
  );
}
