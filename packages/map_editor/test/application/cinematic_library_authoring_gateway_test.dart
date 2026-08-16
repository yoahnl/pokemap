import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/cinematic_library_authoring_gateway.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('canonical gateway owns the complete mode-aware Library flow', () async {
    final root = await Directory.systemTemp.createTemp(
      'cinematic_library_gateway_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final project = _project();
    await File(p.join(root.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(() async {
      await mutations.closeAll();
      await queries.closeAll();
    });
    final gateway = CanonicalCinematicLibraryAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );

    var current = project;
    final world = await gateway.create(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.world,
      title: 'Arrivée au port',
      folderId: 'world-folder',
      worldStartingPoint: CinematicLibraryWorldStartingPoint.establishingShot,
    );
    current = world.manifest;
    expect(world.cinematicId, 'arrivee-au-port');
    expect(current.cinematics.single.timeline.steps, hasLength(2));

    final punctuationTitle = await gateway.create(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.world,
      title: 'Fin !',
      folderId: 'world-folder',
      worldStartingPoint: CinematicLibraryWorldStartingPoint.blank,
    );
    current = punctuationTitle.manifest;
    expect(punctuationTitle.cinematicId, 'fin');

    final presentation = await gateway.create(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.presentation,
      title: 'Ouverture Avelune',
      folderId: 'presentation-folder',
      presentationTemplateId: 'immersiveOpening',
      presentationTemplateVersion: 1,
    );
    current = presentation.manifest;
    expect(current.presentationCinematics.single.layers, isNotEmpty);

    final duplicate = await gateway.duplicate(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.presentation,
      cinematicId: presentation.cinematicId,
      folderId: null,
    );
    current = duplicate.manifest;
    expect(current.presentationCinematics, hasLength(2));

    current = await gateway.rename(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.presentation,
      cinematicId: duplicate.cinematicId,
      title: 'Ouverture alternative',
    );
    expect(
      current.presentationCinematics
          .singleWhere((asset) => asset.id == duplicate.cinematicId)
          .title,
      'Ouverture alternative',
    );

    current = await gateway.move(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.presentation,
      cinematicId: duplicate.cinematicId,
      folderId: 'presentation-folder',
    );
    current = await gateway.setArchived(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.presentation,
      cinematicId: duplicate.cinematicId,
      archived: true,
    );
    expect(
      current.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.presentation, duplicate.cinematicId)
          ?.isArchived,
      isTrue,
    );

    current = await gateway.delete(
      root.path,
      expectedProject: current,
      family: CinematicLibraryFamily.presentation,
      cinematicId: duplicate.cinematicId,
    );
    expect(
      current.presentationCinematics.map((asset) => asset.id),
      isNot(contains(duplicate.cinematicId)),
    );
  });

  test('canonical gateway deletes the final Presentation cinematic', () async {
    final root = await Directory.systemTemp.createTemp(
      'cinematic_library_gateway_delete_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final project = ProjectManifest(
      name: 'Final Presentation deletion',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'presentation-only',
          title: 'Presentation only',
          durationUs: 1000000,
        ),
      ],
      cinematicLibraryCatalog: CinematicLibraryCatalog(
        entries: <CinematicLibraryEntry>[
          CinematicLibraryEntry(
            family: CinematicLibraryFamily.presentation,
            cinematicId: 'presentation-only',
            sortOrder: 0,
          ),
        ],
      ),
    );
    final projectFile = File(p.join(root.path, 'project.json'));
    final projectJson = project.toJson()
      ..['customExtension'] = <String, Object?>{'preserved': true};
    await projectFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(projectJson),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(() async {
      await mutations.closeAll();
      await queries.closeAll();
    });
    final gateway = CanonicalCinematicLibraryAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );

    final deleted = await gateway.delete(
      root.path,
      expectedProject: project,
      family: CinematicLibraryFamily.presentation,
      cinematicId: 'presentation-only',
    );
    final persisted = jsonDecode(await projectFile.readAsString()) as Map;

    expect(deleted.presentationCinematics, isEmpty);
    expect(deleted.cinematicLibraryCatalog.isEmpty, isTrue);
    expect(persisted, isNot(contains('presentationCinematics')));
    expect(persisted, isNot(contains('cinematicLibraryCatalog')));
    expect(persisted['customExtension'], <String, Object?>{'preserved': true});
  });
}

ProjectManifest _project() => ProjectManifest(
  name: 'Library gateway',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  cinematicLibraryCatalog: CinematicLibraryCatalog(
    folders: <CinematicLibraryFolder>[
      CinematicLibraryFolder(
        id: 'world-folder',
        family: CinematicLibraryFamily.world,
        name: 'World',
        sortOrder: 0,
      ),
      CinematicLibraryFolder(
        id: 'presentation-folder',
        family: CinematicLibraryFamily.presentation,
        name: 'Presentation',
        sortOrder: 0,
      ),
    ],
  ),
);
