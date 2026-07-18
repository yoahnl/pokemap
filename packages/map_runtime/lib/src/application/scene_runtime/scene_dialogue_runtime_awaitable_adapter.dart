import 'package:map_core/map_core.dart';

import 'scene_dialogue_runtime_awaitable_result.dart';

abstract interface class SceneDialogueRuntimeLauncher {
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  );
}

final class SceneDialogueRuntimeDialogueRequest {
  const SceneDialogueRuntimeDialogueRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.dialogueId,
    this.yarnNodeName,
    this.expectedOutcomes = const <String>[],
  });

  final String requestId;
  final int createdAtEpochMs;
  final String dialogueId;
  final String? yarnNodeName;
  final List<String> expectedOutcomes;
}

final class SceneDialogueRuntimeAwaitableAdapter {
  const SceneDialogueRuntimeAwaitableAdapter({
    required this.runtimeSourceId,
    required this.launcher,
    this.createdAtEpochMs = _systemNowMs,
  });

  final String runtimeSourceId;
  final SceneDialogueRuntimeLauncher launcher;
  final int Function() createdAtEpochMs;

  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneRuntimePlanIntent intent,
  ) async {
    final dialogueId = intent.dialogueId?.trim();
    if (dialogueId == null || dialogueId.isEmpty) {
      return const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.missingDialogueId,
        message: 'Scene dialogue intent is missing dialogueId.',
      );
    }

    final now = createdAtEpochMs();
    final request = SceneDialogueRuntimeDialogueRequest(
      requestId: '$runtimeSourceId:$dialogueId:$now',
      createdAtEpochMs: now,
      dialogueId: dialogueId,
      yarnNodeName: intent.yarnNodeName,
      expectedOutcomes: intent.expectedOutcomes,
    );

    try {
      final result = await launcher.showDialogue(request);
      if (!result.success || result.outcomeId == null) {
        return result;
      }
      if (!intent.expectedOutcomes.contains(result.outcomeId)) {
        return SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.unsupportedOutcome,
          message: 'Scene dialogue returned unsupported outcome '
              '"${result.outcomeId}" for dialogue "$dialogueId".',
        );
      }
      return result;
    } catch (error) {
      return SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
        message: 'Scene dialogue launcher failed: $error',
      );
    }
  }
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;
