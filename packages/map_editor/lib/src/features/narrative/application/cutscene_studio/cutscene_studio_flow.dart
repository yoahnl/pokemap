// Cutscene Studio — projection et dérivation du flow d'authoring.
// Voir cutscene_studio_models.dart pour les types ([CutsceneFlowEntry], document).

import 'cutscene_studio_models.dart';

List<CutsceneStudioBlock> flattenMainTrunkFlowToBlocks(
  List<CutsceneFlowEntry> flow,
) {
  final out = <CutsceneStudioBlock>[];
  for (final entry in flow) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        out.add(block);
      case CutsceneFlowChoiceEntry(:final question):
        out.add(question);
    }
  }
  return out;
}

/// Représentation linéaire pour l’authoring quand il n’y a pas encore d’arbre.
List<CutsceneFlowEntry> cutsceneLinearFlowFromBlocks(
  List<CutsceneStudioBlock> blocks,
) {
  return blocks.map(CutsceneFlowBlockEntry.new).toList(growable: false);
}

List<CutsceneFlowEntry> effectiveCutsceneFlowForDocument(
  CutsceneStudioDocument document,
) {
  if (document.cutsceneFlow != null && document.cutsceneFlow!.isNotEmpty) {
    return document.cutsceneFlow!;
  }
  return cutsceneLinearFlowFromBlocks(document.blocks);
}
