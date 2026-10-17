import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../dialogue/dialogue_line_text_edit.dart';
import 'dialogue_authoring_service.dart';
import 'dialogue_source_guards.dart';
import 'narrative_authoring_exception.dart';

ProjectManifest reconcileDialogueLineTextEdits({
  required ProjectManifest project,
  required String dialogueId,
  required DialogueAuthoringCompileResult before,
  required DialogueAuthoringCompileResult after,
  required List<DialogueLineTextEdit> edits,
}) {
  if (edits.isEmpty) _invalid('At least one changed line is required.');
  if (jsonEncode(_withoutLineText(before.document!.toJson())) !=
      jsonEncode(_withoutLineText(after.document!.toJson()))) {
    throw NarrativeAuthoringException(
      'dialogue.line_text_edits_structure_changed',
      'Line text edits must preserve the compiled dialogue structure and commands.',
    );
  }
  final oldScopes = {
    for (final scope in sceneDialogueLineScopes(before.document!))
      (scope.nodeName, scope.lineIndex): scope.text,
  };
  final newScopes = {
    for (final scope in sceneDialogueLineScopes(after.document!))
      (scope.nodeName, scope.lineIndex): scope.text,
  };
  final byScope = <(String, int), DialogueLineTextEdit>{};
  for (final edit in edits) {
    final scope = (edit.nodeName, edit.lineIndex);
    if (byScope.containsKey(scope) ||
        oldScopes[scope] != edit.beforeText ||
        newScopes[scope] != edit.afterText) {
      _invalid('Each line text edit must identify one exact old and new line.');
    }
    byScope[scope] = edit;
  }
  final changedScopes = {
    for (final scope in oldScopes.keys)
      if (oldScopes[scope] != newScopes[scope]) scope,
  };
  if (changedScopes.length != byScope.length ||
      !changedScopes.containsAll(byScope.keys)) {
    _invalid('Line text edits must cover every compiled text change exactly.');
  }
  validateDialogueSceneStarts(
    project: project,
    dialogueId: dialogueId,
    compiled: before,
  );
  final scenes = [
    for (final scene in project.scenes)
      if (!scene.graph.nodes.any((node) {
        final payload = node.payload;
        return payload is SceneYarnDialoguePayload &&
            payload.dialogueId == dialogueId &&
            payload.linePolicies.any((policy) =>
                byScope.containsKey((policy.nodeName, policy.lineIndex)) &&
                policy.feedback.segments.isNotEmpty);
      }))
        scene
      else
        SceneAsset.fromJson({
          ...scene.toJson(),
          'graph': {
            ...scene.graph.toJson(),
            'nodes': [
              for (final node in scene.graph.nodes)
                if (node.payload case SceneYarnDialoguePayload payload
                    when payload.dialogueId == dialogueId)
                  {
                    ...node.toJson(),
                    'payload': {
                      ...payload.toJson(),
                      'linePolicies': [
                        for (final policy in payload.linePolicies)
                          _replacePolicy(policy, byScope, scene.id, node.id)
                              .toJson(),
                      ],
                    },
                  }
                else
                  node.toJson(),
            ],
          },
        }),
  ];
  final projected = project.copyWith(scenes: scenes);
  validateDialogueSceneStarts(
    project: projected,
    dialogueId: dialogueId,
    compiled: after,
  );
  return projected;
}

SceneDialogueLinePolicy _replacePolicy(
  SceneDialogueLinePolicy policy,
  Map<(String, int), DialogueLineTextEdit> edits,
  String sceneId,
  String nodeId,
) {
  final edit = edits[(policy.nodeName, policy.lineIndex)];
  if (edit == null || policy.feedback.segments.isEmpty) return policy;
  if (policy.feedback.segments.length != 1 ||
      policy.feedback.segments.single is! DialogueTextSegment) {
    throw NarrativeAuthoringException(
      'dialogue.line_text_edits_rich_feedback_unsupported',
      'Editing a rich line requires explicit segment-aware authoring.',
      details: {
        'references': ['scenes[$sceneId].nodes[$nodeId].linePolicies'],
        'nodeName': policy.nodeName,
        'lineIndex': policy.lineIndex,
      },
    );
  }
  return SceneDialogueLinePolicy(
    nodeName: policy.nodeName,
    lineIndex: policy.lineIndex,
    feedback: policy.feedback.mapText((text) => edit.afterText),
  );
}

Object? _withoutLineText(Object? value) {
  if (value is List) return value.map(_withoutLineText).toList(growable: false);
  if (value is Map<String, Object?>) {
    return {
      for (final entry in value.entries)
        entry.key: value['kind'] == 'line' && entry.key == 'text'
            ? null
            : _withoutLineText(entry.value),
    };
  }
  return value;
}

Never _invalid(String message) => throw NarrativeAuthoringException(
      'dialogue.line_text_edits_invalid',
      message,
    );
