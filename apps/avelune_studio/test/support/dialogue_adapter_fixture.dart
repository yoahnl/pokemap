import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

class DialogueAdapterFixture {
  DialogueAdapterFixture(this.directory, this.session, this.maps);

  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;

  static const source = 'title: Accueil\n---\nBonjour !\n===\n';
  static const entry = ProjectDialogueEntry(
    id: 'gare',
    name: 'Chef de gare',
    relativePath: 'dialogues/gare.yarn',
    defaultStartNode: 'Accueil',
  );

  static Future<DialogueAdapterFixture> create({
    List<ProjectDialogueEntry> entries = const [entry],
    List<SceneAsset> scenes = const [],
  }) async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ui09_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'UI09',
      directoryPath: directory.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final fixture = DialogueAdapterFixture(directory, session, maps);
    await fixture.writeManifest(
      ProjectManifest(
        name: 'UI09',
        maps: const [],
        tilesets: const [],
        dialogues: entries,
        scenes: scenes,
      ),
    );
    for (final value in entries) {
      final file = fixture.file(value.relativePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
    }
    await maps.loadProject(session);
    return fixture;
  }

  File file(String path) => File('${directory.path}/$path');
  LocalDialogueAdapter adapter({
    ProjectFileReader reader = const LocalProjectFileReader(),
    AuthoringTransactionFaultInjector? faultInjector,
  }) => LocalDialogueAdapter(
    session: session,
    mapAdapter: maps,
    reader: reader,
    faultInjector: faultInjector,
  );

  Future<ProjectManifest> readManifest() async => ProjectManifest.fromJson(
    jsonDecode(await file('project.json').readAsString())
        as Map<String, dynamic>,
  );

  Future<void> writeManifest(ProjectManifest value) =>
      file('project.json').writeAsString(jsonEncode(value.toJson()));

  Future<void> dispose() => directory.delete(recursive: true);
}

class DialogueCountingReader implements ProjectFileReader {
  final paths = <String>[];
  @override
  Future<String> canonicalizeDirectory(String path) =>
      const LocalProjectFileReader().canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return const LocalProjectFileReader().readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
