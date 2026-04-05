// Cutscene Studio — codecs JSON (persistance dans `ScenarioAsset.metadata`).
//
// Contrat : la clé [kCutsceneStudioFlowMetadataKey] stocke un JSON versionné
// (`v` + `seq`) produit par [encodeCutsceneFlowMetadata]. Aucune logique UI ni
// compilation ici : uniquement aller-retour typé ↔ JSON.

import 'dart:convert';

import 'cutscene_studio_models.dart';

Map<String, dynamic> cutsceneBlockToJson(CutsceneStudioBlock b) {
  return <String, dynamic>{
    'id': b.id,
    'kind': b.kind.name,
    'actorId': b.actorId,
    'dialogueId': b.dialogueId,
    'messageText': b.messageText,
    'scriptId': b.scriptId,
    'flagName': b.flagName,
    'outcomeId': b.outcomeId,
    'resultLabel': b.resultLabel,
    'resultScope': b.resultScope,
    'destinationTargetKind': b.destinationTargetKind,
    'destinationTargetId': b.destinationTargetId,
    'transitionMapId': b.transitionMapId,
    'transitionWarpId': b.transitionWarpId,
    'facingDirection': b.facingDirection,
    'durationMs': b.durationMs,
    'waitForCompletion': b.waitForCompletion,
    'choiceOptions': b.choiceOptions,
  };
}

CutsceneStudioBlock cutsceneBlockFromJson(Map<String, dynamic> m) {
  final kindName = m['kind'] as String? ?? 'wait';
  final kind = CutsceneStudioBlockKind.values.firstWhere(
    (k) => k.name == kindName,
    orElse: () => CutsceneStudioBlockKind.wait,
  );
  return CutsceneStudioBlock(
    id: m['id'] as String? ?? 'block',
    kind: kind,
    actorId: m['actorId'] as String?,
    dialogueId: m['dialogueId'] as String?,
    messageText: m['messageText'] as String?,
    scriptId: m['scriptId'] as String?,
    flagName: m['flagName'] as String?,
    outcomeId: m['outcomeId'] as String?,
    resultLabel: m['resultLabel'] as String?,
    resultScope: m['resultScope'] as String?,
    destinationTargetKind: m['destinationTargetKind'] as String?,
    destinationTargetId: m['destinationTargetId'] as String?,
    transitionMapId: m['transitionMapId'] as String?,
    transitionWarpId: m['transitionWarpId'] as String?,
    facingDirection: m['facingDirection'] as String?,
    durationMs: (m['durationMs'] as num?)?.toInt(),
    waitForCompletion: m['waitForCompletion'] as bool?,
    choiceOptions: (m['choiceOptions'] as List<dynamic>?)
            ?.map((e) => '$e')
            .toList(growable: false) ??
        const <String>[],
  );
}

Map<String, dynamic> cutsceneFlowEntryToJson(CutsceneFlowEntry e) {
  switch (e) {
    case CutsceneFlowBlockEntry(:final block):
      return <String, dynamic>{
        't': 'b',
        'b': cutsceneBlockToJson(block),
      };
    case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
      return <String, dynamic>{
        't': 'c',
        'q': cutsceneBlockToJson(question),
        'y': onYes.map(cutsceneFlowEntryToJson).toList(growable: false),
        'n': onNo.map(cutsceneFlowEntryToJson).toList(growable: false),
      };
  }
}

CutsceneFlowEntry cutsceneFlowEntryFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('flow entry: expected object');
  }
  final t = raw['t'] as String?;
  switch (t) {
    case 'b':
      final b = raw['b'];
      if (b is! Map<String, dynamic>) {
        throw const FormatException('flow block: missing b');
      }
      return CutsceneFlowBlockEntry(cutsceneBlockFromJson(b));
    case 'c':
      final q = raw['q'];
      if (q is! Map<String, dynamic>) {
        throw const FormatException('flow choice: missing q');
      }
      final y = (raw['y'] as List<dynamic>? ?? const <dynamic>[])
          .map(cutsceneFlowEntryFromJson)
          .toList(growable: false);
      final n = (raw['n'] as List<dynamic>? ?? const <dynamic>[])
          .map(cutsceneFlowEntryFromJson)
          .toList(growable: false);
      return CutsceneFlowChoiceEntry(
        question: cutsceneBlockFromJson(q),
        onYes: y,
        onNo: n,
      );
    default:
      throw FormatException('flow entry: unknown t=$t');
  }
}

/// Encode la séquence pour [kCutsceneStudioFlowMetadataKey].
String encodeCutsceneFlowMetadata(List<CutsceneFlowEntry> flow) {
  final payload = <String, dynamic>{
    'v': 1,
    'seq': flow.map(cutsceneFlowEntryToJson).toList(growable: false),
  };
  return jsonEncode(payload);
}

List<CutsceneFlowEntry> decodeCutsceneFlowMetadata(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('flow: root must be object');
  }
  final seq = decoded['seq'] as List<dynamic>? ?? const <dynamic>[];
  return seq.map(cutsceneFlowEntryFromJson).toList(growable: false);
}
