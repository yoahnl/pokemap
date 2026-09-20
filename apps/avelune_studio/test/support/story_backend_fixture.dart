import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:map_core/map_core.dart';

class StoryBackendFixture {
  StoryBackendFixture._(this.directory, this.workspace, this.maps) {
    narrative = NarrativeWorkspaceController(
      workspace,
      LocalNarrativeAdapter(session: workspace.session, mapAdapter: maps),
      () {},
      (_, _) async {},
    );
    port = LocalStoryAdapter(session: workspace.session, mapAdapter: maps);
  }
  final Directory directory;
  final MapWorkspaceController workspace;
  final LocalMapWorkspaceAdapter maps;
  late final NarrativeWorkspaceController narrative;
  late final LocalStoryAdapter port;
  StoryWorkspaceController? controller;

  static Future<StoryBackendFixture> create({
    List<StorylineAsset> stories = const [],
    List<NarrativeFactDefinition> facts = const [],
    List<ScenarioAsset> scenarios = const [],
  }) async {
    final temporary = await Directory.systemTemp.createTemp('ui07_backend_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    final project = ProjectManifest(
      name: 'Histoires sans carte',
      maps: [],
      tilesets: [],
      storylines: stories,
      facts: facts,
      scenarios: scenarios,
    );
    await File(
      '${directory.path}/project.json',
    ).writeAsString(jsonEncode(project.toJson()));
    final session = ProjectSession(
      sessionId: directory.path,
      name: project.name,
      directoryPath: directory.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    return StoryBackendFixture._(directory, workspace, maps);
  }

  StoryWorkspaceController attach({StoryPort? overridePort}) => controller =
      StoryWorkspaceController(narrative, overridePort ?? port, changed: () {});

  Future<ProjectManifest> readFresh() =>
      LocalMapWorkspaceAdapter().loadProject(workspace.session);

  Future<void> dispose() async {
    controller?.dispose();
    narrative.dispose();
    workspace.dispose();
    await directory.delete(recursive: true);
  }
}

StorylineAsset backendStory(String id, {String? title}) => StorylineAsset(
  id: id,
  title: title ?? id,
  type: StorylineType.main,
  chapters: [
    StorylineChapter(
      id: '${id}_chapter',
      order: 0,
      title: 'Chapitre',
      steps: [StorylineStep(id: '${id}_step', title: 'Étape', order: 0)],
    ),
  ],
);
