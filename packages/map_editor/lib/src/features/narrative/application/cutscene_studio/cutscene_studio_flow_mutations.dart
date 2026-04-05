// Cutscene Studio — mutations pures du graphe d'authoring (DnD, inspecteur).

import 'cutscene_studio_models.dart';

CutsceneStudioBlock? findCutsceneBlockByIdInFlow(
  Iterable<CutsceneFlowEntry> flow,
  String id,
) {
  for (final entry in flow) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        if (block.id == id) return block;
      case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
        if (question.id == id) return question;
        final inYes = findCutsceneBlockByIdInFlow(onYes, id);
        if (inYes != null) return inYes;
        final inNo = findCutsceneBlockByIdInFlow(onNo, id);
        if (inNo != null) return inNo;
    }
  }
  return null;
}

/// Remplace un bloc (même id conservé côté données si [next] garde l’id).
List<CutsceneFlowEntry> replaceCutsceneBlockByIdInFlow(
  List<CutsceneFlowEntry> flow,
  String id,
  CutsceneStudioBlock next,
) {
  List<CutsceneFlowEntry> walk(List<CutsceneFlowEntry> list) {
    return list.map((entry) {
      switch (entry) {
        case CutsceneFlowBlockEntry(:final block):
          if (block.id == id) return CutsceneFlowBlockEntry(next);
          return entry;
        case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
          if (question.id == id) {
            return CutsceneFlowChoiceEntry(
              question: next,
              onYes: onYes,
              onNo: onNo,
            );
          }
          return CutsceneFlowChoiceEntry(
            question: question,
            onYes: walk(onYes),
            onNo: walk(onNo),
          );
      }
    }).toList(growable: false);
  }

  return walk(flow);
}

/// Supprime un bloc simple du flux (pas un bloc « question » d’un embranchement).
List<CutsceneFlowEntry> removeCutsceneFlowBlockEntryWithId(
  List<CutsceneFlowEntry> flow,
  String blockId,
) {
  List<CutsceneFlowEntry> walk(List<CutsceneFlowEntry> list) {
    final out = <CutsceneFlowEntry>[];
    for (final entry in list) {
      switch (entry) {
        case CutsceneFlowBlockEntry(:final block):
          if (block.id != blockId) out.add(entry);
        case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
          out.add(
            CutsceneFlowChoiceEntry(
              question: question,
              onYes: walk(onYes),
              onNo: walk(onNo),
            ),
          );
      }
    }
    return out;
  }

  return walk(flow);
}

/// Insère une entrée sur le tronc principal (index 0 = tout en haut après Start).
List<CutsceneFlowEntry> insertMainFlowEntryAt(
  List<CutsceneFlowEntry> flow,
  int insertIndex,
  CutsceneFlowEntry newEntry,
) {
  final list = List<CutsceneFlowEntry>.from(flow);
  final i = insertIndex.clamp(0, list.length);
  list.insert(i, newEntry);
  return list;
}

/// Déplace une entrée du tronc principal (réordonnancement drag interne).
List<CutsceneFlowEntry> moveMainFlowEntry(
  List<CutsceneFlowEntry> flow,
  int fromIndex,
  int toIndex,
) {
  final list = List<CutsceneFlowEntry>.from(flow);
  if (fromIndex < 0 || fromIndex >= list.length) return flow;
  final item = list.removeAt(fromIndex);
  var t = toIndex;
  if (t > fromIndex) t -= 1;
  list.insert(t.clamp(0, list.length), item);
  return list;
}

/// Insère un bloc dans la branche Oui / Non d’un embranchement du tronc.
List<CutsceneFlowEntry> insertIntoChoiceBranch(
  List<CutsceneFlowEntry> flow,
  int choiceMainIndex, {
  required bool yesBranch,
  required int branchInsertIndex,
  required CutsceneFlowEntry newEntry,
}) {
  final out = <CutsceneFlowEntry>[];
  for (var idx = 0; idx < flow.length; idx++) {
    final entry = flow[idx];
    if (idx != choiceMainIndex) {
      out.add(entry);
      continue;
    }
    switch (entry) {
      case CutsceneFlowBlockEntry():
        out.add(entry);
      case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
        if (yesBranch) {
          final nb = List<CutsceneFlowEntry>.from(onYes);
          nb.insert(branchInsertIndex.clamp(0, nb.length), newEntry);
          out.add(
            CutsceneFlowChoiceEntry(
              question: question,
              onYes: nb,
              onNo: onNo,
            ),
          );
        } else {
          final nb = List<CutsceneFlowEntry>.from(onNo);
          nb.insert(branchInsertIndex.clamp(0, nb.length), newEntry);
          out.add(
            CutsceneFlowChoiceEntry(
              question: question,
              onYes: onYes,
              onNo: nb,
            ),
          );
        }
    }
  }
  return out;
}
