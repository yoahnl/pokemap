import 'dart:io';

import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show encodeProjectMediaCatalogBytes, projectMediaCatalogStorageKey;
import 'package:map_core/map_core.dart';

void main() {
  const project = ProjectManifest(
    name: 'Johto',
    maps: [],
    tilesets: [],
    settings: ProjectSettings(dimension: ProjectDimension.threeD),
  );

  test('a 3D project reads its saved media catalog', () async {
    final root = await _root();
    final file = File('${root.path}/$projectMediaCatalogStorageKey');
    await file.create(recursive: true);
    await file.writeAsBytes(
      encodeProjectMediaCatalogBytes(
        ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: 'kabuto-image',
              label: 'Kabuto',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'kabuto-source',
            ),
          ],
        ),
      ),
    );

    final catalog = await _adapter(root).loadPresentationMediaCatalog(project);

    expect(catalog.find('kabuto-image')?.kind, ProjectMediaKind.image);
  });

  test('a 3D project without media gets an empty catalog', () async {
    final root = await _root();

    final catalog = await _adapter(root).loadPresentationMediaCatalog(project);

    expect(catalog.entries, isEmpty);
  });

  test('a 3D project with an unreadable media catalog fails', () async {
    final root = await _root();
    final file = File('${root.path}/$projectMediaCatalogStorageKey');
    await file.create(recursive: true);
    await file.writeAsString('{');

    expect(
      _adapter(root).loadPresentationMediaCatalog(project),
      throwsA(isA<FormatException>()),
    );
  });
}

Future<Directory> _root() async {
  final temporary = await Directory.systemTemp.createTemp(
    'studio_event_media_',
  );
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  return root;
}

LocalEventAdapter _adapter(Directory root) => LocalEventAdapter(
  session: ProjectSession(
    sessionId: root.path,
    name: 'Johto',
    directoryPath: root.path,
  ),
  mapAdapter: LocalMapWorkspaceAdapter(),
);
