import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/dialogue_runtime_models.dart';
import '../application/load_dialogue_content.dart';
import '../application/resolve_dialogue.dart';
import 'runtime_initial_map_preloader.dart';

abstract interface class RuntimeNewGamePreSessionRunner {
  Future<NewGameDraft> run({
    required String runId,
    required NewGameDraft draft,
    required SceneStructuredInteractionPort interactions,
  });
}

final class RuntimeNewGamePreparation {
  const RuntimeNewGamePreparation({
    required this.projectRevision,
    required this.project,
    required this.startMap,
    this.preSessionRunner,
  });

  final String projectRevision;
  final ProjectManifest project;
  final MapData startMap;
  final RuntimeNewGamePreSessionRunner? preSessionRunner;
}

abstract interface class RuntimeNewGameFlowPort {
  Future<RuntimeNewGamePreparation> prepare();

  Future<String> readCurrentProjectRevision();

  void clear();
}

final class RuntimeProjectNewGameFlowPort implements RuntimeNewGameFlowPort {
  RuntimeProjectNewGameFlowPort({
    required Future<String> Function() projectFilePath,
    required RuntimeInitialMapPreloader initialMapPreloader,
  })  : _projectFilePath = projectFilePath,
        _initialMapPreloader = initialMapPreloader;

  final Future<String> Function() _projectFilePath;
  final RuntimeInitialMapPreloader _initialMapPreloader;

  @override
  Future<RuntimeNewGamePreparation> prepare() async {
    final projectFilePath = p.normalize(p.absolute(await _projectFilePath()));
    await _initialMapPreloader.preloadInitialMap(
      const RuntimeInitialMapPreloadRequest.newGame(),
    );
    final bundle = _initialMapPreloader.preparedNewGameBundle(
      projectFilePath: projectFilePath,
    );
    if (bundle == null) {
      throw StateError('The new game preload did not produce a usable map.');
    }
    final snapshot = await _readProjectSnapshot(projectFilePath);
    if (snapshot.project != bundle.manifest || snapshot.map != bundle.map) {
      clear();
      throw StateError('The project changed while New Game was preloading.');
    }
    final sceneId = bundle.manifest.newGame.preSessionSceneId?.trim();
    return RuntimeNewGamePreparation(
      projectRevision: snapshot.revision,
      project: bundle.manifest,
      startMap: bundle.map,
      preSessionRunner: sceneId == null || sceneId.isEmpty
          ? null
          : RuntimeTextPreSessionSceneRunner(
              project: bundle.manifest,
              projectRootDirectory: bundle.projectRootDirectory,
              sceneId: sceneId,
            ),
    );
  }

  @override
  Future<String> readCurrentProjectRevision() async {
    final projectFilePath = p.normalize(p.absolute(await _projectFilePath()));
    return (await _readProjectSnapshot(projectFilePath)).revision;
  }

  @override
  void clear() => _initialMapPreloader.clear();
}

final class RuntimeTextPreSessionSceneRunner
    implements RuntimeNewGamePreSessionRunner {
  RuntimeTextPreSessionSceneRunner({
    required this.project,
    required String projectRootDirectory,
    required this.sceneId,
  }) : projectRootDirectory = p.normalize(p.absolute(projectRootDirectory));

  final ProjectManifest project;
  final String projectRootDirectory;
  final String sceneId;

  @override
  Future<NewGameDraft> run({
    required String runId,
    required NewGameDraft draft,
    required SceneStructuredInteractionPort interactions,
  }) async {
    final scene = project.scenes.where((candidate) => candidate.id == sceneId);
    if (scene.length != 1 ||
        scene.single.executionProfile != SceneExecutionProfile.preSession) {
      throw StateError('The configured preSession Scene is unavailable.');
    }
    final plan = buildSceneRuntimePlan(scene.single);
    if (!plan.canBuild || plan.plan == null) {
      throw StateError(
        'The configured preSession Scene cannot run: '
        '${plan.diagnostics.map((diagnostic) => diagnostic.message).join(' | ')}',
      );
    }
    var dialogueSerial = 0;
    Future<String> unsupported(SceneRuntimePlanIntent intent) async {
      throw StateError(
        'Unsupported preSession intent ${intent.kind.name} in text mode.',
      );
    }

    final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: unsupported,
        showDialogue: (intent) => _runDialogue(
          intent: intent,
          runId: runId,
          dialogueSerial: dialogueSerial++,
          interactions: interactions,
        ),
        startBattle: unsupported,
        playCinematic: unsupported,
        playPresentationCinematic: unsupported,
        executeInteractiveCommand: unsupported,
        applyConsequence: (_) async {
          throw StateError('Consequences are unavailable before GameState.');
        },
      ),
    ).execute(plan.plan!);
    if (result.status != SceneRuntimeExecutionStatus.completed) {
      throw StateError(result.message ?? 'The preSession Scene failed.');
    }
    return draft;
  }

  Future<String> _runDialogue({
    required SceneRuntimePlanIntent intent,
    required String runId,
    required int dialogueSerial,
    required SceneStructuredInteractionPort interactions,
  }) async {
    final dialogueId = intent.dialogueId?.trim();
    if (dialogueId == null || dialogueId.isEmpty) {
      throw StateError('The preSession dialogue has no identifier.');
    }
    final matches = project.dialogues.where((entry) => entry.id == dialogueId);
    if (matches.length != 1) {
      throw StateError('The preSession dialogue is unavailable.');
    }
    final entry = matches.single;
    final relativePath = entry.relativePath.trim().replaceAll(r'\', '/');
    final absolutePath =
        p.normalize(p.join(projectRootDirectory, relativePath));
    if (!p.isWithin(projectRootDirectory, absolutePath)) {
      throw StateError('The preSession dialogue path is outside the project.');
    }
    var session = await loadDialogueContent(
      ResolvedDialogue(
        absoluteFilePath: absolutePath,
        dialogueId: dialogueId,
        startNode: intent.yarnNodeName ?? entry.defaultStartNode,
      ),
    );
    if (session == null) {
      throw StateError('The preSession dialogue could not be loaded.');
    }
    var interactionSerial = 0;
    String? selectedOutcomeId;
    while (session != null) {
      final requestId =
          '$runId:dialogue:$dialogueSerial:${interactionSerial++}';
      switch (session.state) {
        case DialogueShowingLine(:final text):
          final response = await interactions.request(
            SceneInteractionRequest.message(
              requestId: requestId,
              revision: 0,
              prompt: SceneInteractionPrompt(
                localizationKey: 'scene.pre_session.dialogue.line',
                fallbackText: text,
              ),
            ),
          );
          _rejectCancellation(response);
          selectedOutcomeId = session.selectedOutcomeId ?? selectedOutcomeId;
          session = session.advance();
        case DialogueWaitingForChoice(:final choices, :final selectedIndex):
          final response = await interactions.request(
            SceneInteractionRequest.choice(
              requestId: requestId,
              revision: 0,
              prompt: SceneInteractionPrompt(
                localizationKey: 'scene.pre_session.dialogue.choice',
                fallbackText: 'Choisissez une réponse.',
              ),
              options: <SceneInteractionOption>[
                for (var index = 0; index < choices.length; index++)
                  SceneInteractionOption(
                    id: '$index',
                    label: SceneInteractionPrompt(
                      localizationKey:
                          'scene.pre_session.dialogue.choice.$index',
                      fallbackText: choices[index].text,
                    ),
                  ),
              ],
            ),
          );
          _rejectCancellation(response);
          final selected = response as SceneChoiceSelectedInteractionResult;
          final targetIndex = int.parse(selected.selectedOptionId);
          selectedOutcomeId =
              choices[targetIndex].outcomeId ?? selectedOutcomeId;
          session = session
              .moveChoiceCursor(targetIndex - selectedIndex)
              .confirmChoice();
      }
    }
    return selectedOutcomeId ?? 'completed';
  }
}

void _rejectCancellation(SceneInteractionResult result) {
  if (result is SceneCancelledInteractionResult) {
    throw StateError('The preSession interaction was cancelled.');
  }
}

final class _RuntimeNewGameProjectSnapshot {
  const _RuntimeNewGameProjectSnapshot({
    required this.project,
    required this.map,
    required this.revision,
  });

  final ProjectManifest project;
  final MapData map;
  final String revision;
}

Future<_RuntimeNewGameProjectSnapshot> _readProjectSnapshot(
  String projectFilePath,
) async {
  final projectFile = File(projectFilePath);
  final projectBytes = await projectFile.readAsBytes();
  final projectJson = jsonDecode(utf8.decode(projectBytes));
  if (projectJson is! Map<String, dynamic>) {
    throw const FormatException('The project manifest must be an object.');
  }
  final project = ProjectManifest.fromJson(projectJson);
  final startMapId = project.newGame.startMapId.trim();
  final mapEntries = project.maps.where((entry) => entry.id == startMapId);
  if (!project.newGame.enabled ||
      startMapId.isEmpty ||
      mapEntries.length != 1) {
    throw StateError('The project does not define one launchable start map.');
  }
  final projectRoot = p.normalize(p.absolute(projectFile.parent.path));
  final relativeMapPath =
      mapEntries.single.relativePath.trim().replaceAll(r'\', '/');
  final mapPath = p.normalize(p.join(projectRoot, relativeMapPath));
  if (!p.isWithin(projectRoot, mapPath)) {
    throw StateError('The start map path is outside the project.');
  }
  final mapBytes = await File(mapPath).readAsBytes();
  final mapJson = jsonDecode(utf8.decode(mapBytes));
  if (mapJson is! Map<String, dynamic>) {
    throw const FormatException('The start map must be an object.');
  }
  return _RuntimeNewGameProjectSnapshot(
    project: project,
    map: MapData.fromJson(mapJson),
    revision:
        computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: projectBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: relativeMapPath,
        bytes: mapBytes,
      ),
    ]),
  );
}
