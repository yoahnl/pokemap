import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/dialogue_runtime_models.dart';
import '../application/load_dialogue_content.dart';
import '../application/resolve_dialogue.dart';
import '../application/scene_runtime/scene_presentation_cinematic_runtime_awaitable_adapter.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';
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
    RuntimeNewGamePreSessionRunnerFactory? preSessionRunnerFactory,
    void Function()? cancelActivePreSession,
  })  : _projectFilePath = projectFilePath,
        _initialMapPreloader = initialMapPreloader,
        _preSessionRunnerFactory = preSessionRunnerFactory,
        _cancelActivePreSession = cancelActivePreSession;

  final Future<String> Function() _projectFilePath;
  final RuntimeInitialMapPreloader _initialMapPreloader;
  final RuntimeNewGamePreSessionRunnerFactory? _preSessionRunnerFactory;
  final void Function()? _cancelActivePreSession;

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
          : (_preSessionRunnerFactory?.call(
                project: bundle.manifest,
                projectRootDirectory: bundle.projectRootDirectory,
                projectRevision: snapshot.revision,
                sceneId: sceneId,
              ) ??
              RuntimeTextPreSessionSceneRunner(
                project: bundle.manifest,
                projectRootDirectory: bundle.projectRootDirectory,
                sceneId: sceneId,
              )),
    );
  }

  @override
  Future<String> readCurrentProjectRevision() async {
    final projectFilePath = p.normalize(p.absolute(await _projectFilePath()));
    return (await _readProjectSnapshot(projectFilePath)).revision;
  }

  @override
  void clear() {
    _cancelActivePreSession?.call();
    _initialMapPreloader.clear();
  }
}

typedef RuntimeNewGamePreSessionRunnerFactory = RuntimeNewGamePreSessionRunner
    Function({
  required ProjectManifest project,
  required String projectRootDirectory,
  required String projectRevision,
  required String sceneId,
});

final class RuntimeTextPreSessionSceneRunner
    implements RuntimeNewGamePreSessionRunner {
  RuntimeTextPreSessionSceneRunner({
    required this.project,
    required String projectRootDirectory,
    required this.sceneId,
    this.presentationCinematic,
  }) : projectRootDirectory = p.normalize(p.absolute(projectRootDirectory));

  final ProjectManifest project;
  final String projectRootDirectory;
  final String sceneId;
  final ScenePresentationCinematicRuntimeAwaitableAdapter?
      presentationCinematic;

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
    final activeScene = scene.single;
    final plan = buildSceneRuntimePlan(activeScene);
    if (!plan.canBuild || plan.plan == null) {
      throw StateError(
        'The configured preSession Scene cannot run: '
        '${plan.diagnostics.map((diagnostic) => diagnostic.message).join(' | ')}',
      );
    }
    var dialogueSerial = 0;
    var interactionSerial = 0;
    var currentDraft = draft;
    final handledInteractionOutputsByNodeId = <String, String>{};
    final handledDialogueOutcomesByNodeId = <String, String>{};
    Future<String> unsupported(SceneRuntimePlanIntent intent) async {
      throw StateError(
        'Unsupported preSession intent ${intent.kind.name} in text mode.',
      );
    }

    final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: unsupported,
        showDialogue: (intent) async {
          final handledOutcome =
              handledDialogueOutcomesByNodeId[intent.sourceNodeId];
          if (handledOutcome != null) return handledOutcome;
          return _runDialogue(
            intent: intent,
            runId: runId,
            dialogueSerial: dialogueSerial++,
            interactions: interactions,
            currentScope: () => _interpolationScopeFor(currentDraft),
          );
        },
        startBattle: unsupported,
        playCinematic: unsupported,
        playPresentationCinematic: (intent) async {
          final adapter = presentationCinematic;
          if (adapter == null) return unsupported(intent);
          final result = await adapter.playPresentationCinematic(
            intent,
            onInteractionCue: (cue) async {
              final awaitableNodeId = intent
                  .presentationAwaitableNodeIdsByMarkerId[cue.markerId];
              final awaitableNode = activeScene.graph.nodes
                  .where((node) => node.id == awaitableNodeId)
                  .firstOrNull;
              final awaitablePayload = awaitableNode?.payload;
              if (awaitableNodeId == null || awaitableNode == null) {
                throw StateError(
                  'Presentation interaction cue "${cue.markerId}" is not '
                  'linked to an awaitable Scene node.',
                );
              }
              final sourcePayload = activeScene.graph.nodes
                  .where((node) => node.id == intent.sourceNodeId)
                  .map((node) => node.payload)
                  .whereType<ScenePresentationCinematicPayload>()
                  .firstOrNull;
              final outcomeRoutes = sourcePayload?.interactionCueBindings
                      .where((binding) => binding.markerId == cue.markerId)
                      .map((binding) => binding.outcomeRoutes)
                      .firstOrNull ??
                  const <ScenePresentationCueOutcomeRoute>[];
              if (awaitablePayload is SceneYarnDialoguePayload) {
                final outcomeId = await _runDialogue(
                  intent: SceneRuntimePlanIntent.showDialogue(
                    dialogueId: awaitablePayload.dialogueId,
                    yarnNodeName: awaitablePayload.yarnNodeName,
                    sourceNodeId: awaitableNodeId,
                    expectedOutcomes: awaitablePayload.expectedOutcomes,
                  ),
                  runId: runId,
                  dialogueSerial: dialogueSerial++,
                  interactions: interactions,
                  currentScope: () => _interpolationScopeFor(currentDraft),
                );
                handledDialogueOutcomesByNodeId[awaitableNodeId] = outcomeId;
                return resolvePresentationCueOutcomeForPort(
                  outcomeId,
                  routes: outcomeRoutes,
                );
              }
              if (awaitablePayload is! SceneActionPayload ||
                  awaitablePayload.preSessionInteraction == null) {
                throw StateError(
                  'Presentation interaction cue "${cue.markerId}" is not '
                  'linked to an awaitable Scene node.',
                );
              }
              final interactionResult = await _runStructuredInteraction(
                intent: SceneRuntimePlanIntent.requestStructuredInteraction(
                  interaction: awaitablePayload.preSessionInteraction!,
                  sourceNodeId: awaitableNodeId,
                ),
                requestId: '$runId:scene:${interactionSerial++}',
                draft: currentDraft,
                interactions: interactions,
              );
              currentDraft = interactionResult.draft;
              handledInteractionOutputsByNodeId[awaitableNodeId] =
                  interactionResult.outputPortId;
              return resolvePresentationCueOutcomeForPort(
                interactionResult.outputPortId,
                routes: outcomeRoutes,
              );
            },
          );
          if (result.success) return result.scenePortId!;
          throw StateError(
            result.diagnosticCode ??
                result.message ??
                'The Presentation cinematic failed.',
          );
        },
        executeInteractiveCommand: unsupported,
        requestStructuredInteraction: (intent) async {
          final handledOutput =
              handledInteractionOutputsByNodeId[intent.sourceNodeId];
          if (handledOutput != null) {
            return handledOutput;
          }
          final interactionResult = await _runStructuredInteraction(
            intent: intent,
            requestId: '$runId:scene:${interactionSerial++}',
            draft: currentDraft,
            interactions: interactions,
          );
          currentDraft = interactionResult.draft;
          return interactionResult.outputPortId;
        },
        applyConsequence: (_) async {
          throw StateError('Consequences are unavailable before GameState.');
        },
      ),
    ).execute(plan.plan!);
    if (result.status != SceneRuntimeExecutionStatus.completed) {
      throw StateError(result.message ?? 'The preSession Scene failed.');
    }
    return currentDraft;
  }

  Future<({NewGameDraft draft, String outputPortId})>
      _runStructuredInteraction({
    required SceneRuntimePlanIntent intent,
    required String requestId,
    required NewGameDraft draft,
    required SceneStructuredInteractionPort interactions,
  }) async {
    final spec = intent.preSessionInteraction;
    if (spec == null) {
      throw StateError('The preSession interaction specification is missing.');
    }
    final scope = _interpolationScopeFor(draft);
    final request = interpolateSceneInteractionRequest(
      spec.buildRequest(requestId: requestId, revision: scope.revision),
      scope,
    );
    final response = await interactions.request(request);
    _rejectCancellation(response);
    final outputPortId = switch (response) {
      SceneAcknowledgedInteractionResult() => 'completed',
      SceneChoiceSelectedInteractionResult(:final selectedOptionId) =>
        selectedOptionId,
      SceneTextSubmittedInteractionResult() => 'completed',
      SceneConfirmedInteractionResult(:final value) =>
        value ? 'confirmed' : 'declined',
      SceneSelectionSubmittedInteractionResult() => 'completed',
      SceneCancelledInteractionResult() => throw StateError(
          'The preSession interaction was cancelled.',
        ),
      _ => throw StateError(
          'The preSession interaction returned an unsupported result.',
        ),
    };
    final binding = spec.resultBinding;
    if (binding == null) return (draft: draft, outputPortId: outputPortId);
    final selectedIdentity = switch (response) {
      SceneChoiceSelectedInteractionResult(:final selectedOptionId) =>
        selectedOptionId,
      SceneSelectionSubmittedInteractionResult(:final selectedOptionIds) =>
        selectedOptionIds.single,
      _ => null,
    };
    final command = switch (binding.field) {
      ScenePreSessionDraftField.playerName => NewGameDraftCommand.setPlayerName(
          expectedRevision: draft.revision,
          playerName: (response as SceneTextSubmittedInteractionResult).value,
        ),
      ScenePreSessionDraftField.avatarCharacterId =>
        NewGameDraftCommand.selectAvatar(
          expectedRevision: draft.revision,
          avatarCharacterId: selectedIdentity,
        ),
      ScenePreSessionDraftField.starterOptionId =>
        NewGameDraftCommand.selectStarter(
          expectedRevision: draft.revision,
          starterOptionId: selectedIdentity,
        ),
    };
    final result = draft.apply(command);
    if (result.status != NewGameDraftCommandStatus.applied) {
      throw StateError(
        'The preSession interaction result could not update the New Game draft.',
      );
    }
    return (draft: result.draft, outputPortId: outputPortId);
  }

  PresentationInterpolationScope _interpolationScopeFor(NewGameDraft draft) {
    final avatarName = project.characters
        .where((character) => character.id == draft.avatarCharacterId)
        .map((character) => character.name)
        .firstOrNull;
    final starterName = project.newGame.starterOptions
        .where((option) => option.id == draft.starterOptionId)
        .map((option) => option.label)
        .firstOrNull;
    return PresentationInterpolationScope(
      revision: draft.revision,
      draftValues: {
        if (draft.playerName.trim().isNotEmpty)
          PresentationDraftInterpolationField.playerName: draft.playerName,
        if (avatarName != null)
          PresentationDraftInterpolationField.avatarName: avatarName,
        if (starterName != null)
          PresentationDraftInterpolationField.starterName: starterName,
      },
    );
  }

  Future<String> _runDialogue({
    required SceneRuntimePlanIntent intent,
    required String runId,
    required int dialogueSerial,
    required SceneStructuredInteractionPort interactions,
    required PresentationInterpolationScope Function() currentScope,
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
        case DialogueShowingLine(:final text, :final characterId):
          final scope = currentScope();
          final split = splitDialogueSpeakerLine(text);
          final speakerName = characterId == null
              ? split.speaker
              : project.characters
                      .where((character) => character.id == characterId)
                      .map((character) => character.name)
                      .firstOrNull ??
                  split.speaker;
          final response = await interactions.request(
            SceneInteractionRequest.message(
              requestId: requestId,
              revision: scope.revision,
              speakerName: speakerName,
              prompt: SceneInteractionPrompt(
                localizationKey: 'scene.pre_session.dialogue.line',
                fallbackText:
                    interpolatePresentationText(split.text, scope).text,
              ),
            ),
          );
          _rejectCancellation(response);
          selectedOutcomeId = session.selectedOutcomeId ?? selectedOutcomeId;
          session = session.advance();
        case DialogueWaitingForChoice(:final choices, :final selectedIndex):
          final scope = currentScope();
          final response = await interactions.request(
            SceneInteractionRequest.choice(
              requestId: requestId,
              revision: scope.revision,
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
                      fallbackText: interpolatePresentationText(
                        choices[index].text,
                        scope,
                      ).text,
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
  final fingerprintEntries = <NarrativeProjectFingerprintEntry>[
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: projectBytes,
    ),
    NarrativeProjectFingerprintEntry(
      relativePath: relativeMapPath,
      bytes: mapBytes,
    ),
  ];
  if (project.presentationCinematics.isNotEmpty) {
    for (final relativePath in const <String>[
      'assets/.pokemap-media.json',
      'assets/.pokemap-assets.json',
    ]) {
      final file = File(p.joinAll(<String>[
        projectRoot,
        ...relativePath.split('/'),
      ]));
      if (await file.exists()) {
        fingerprintEntries.add(
          NarrativeProjectFingerprintEntry(
            relativePath: relativePath,
            bytes: await file.readAsBytes(),
          ),
        );
      }
    }
    final mediaStore = Directory(
      p.join(projectRoot, 'assets', '.pokemap-store'),
    );
    if (await mediaStore.exists()) {
      final blobs = await mediaStore
          .list(followLinks: false)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      blobs.sort((left, right) => left.path.compareTo(right.path));
      for (final blob in blobs) {
        final relativePath = p.relative(blob.path, from: projectRoot);
        fingerprintEntries.add(
          NarrativeProjectFingerprintEntry(
            relativePath: relativePath.replaceAll(r'\', '/'),
            bytes: await blob.readAsBytes(),
          ),
        );
      }
    }
  }
  return _RuntimeNewGameProjectSnapshot(
    project: project,
    map: MapData.fromJson(mapJson),
    revision: computeNarrativeProjectFingerprint(fingerprintEntries),
  );
}
