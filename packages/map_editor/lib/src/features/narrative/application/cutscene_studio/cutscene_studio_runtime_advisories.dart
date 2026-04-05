import 'cutscene_studio_flow.dart';
import 'cutscene_studio_models.dart';

/// Avis runtime / honnêteté produit pour le document courant.
///
/// Ces messages alimentent un bandeau Cutscene Studio (distinct des avertissements
/// « graphe non reproductible » du parse legacy). Ils ne bloquent pas la sauvegarde :
/// le graphe compilé reste explicite (`flowMerge`, `authoringPlaceholder`, etc.).
List<String> cutsceneStudioRuntimeAdvisories(CutsceneStudioDocument document) {
  final flow = effectiveCutsceneFlowForDocument(document);
  final out = <String>[];
  void walk(List<CutsceneFlowEntry> entries, String path) {
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      switch (e) {
        case CutsceneFlowBlockEntry(:final block):
          final here = '$path > ${i + 1} (${block.id})';
          if (!cutsceneStudioBlockRuntimeSupported(block)) {
            if (_isAuthoringPlaceholderKind(block.kind)) {
              out.add(
                '$here : ${cutsceneStudioBlockKindLabel(block.kind)} — compilé en '
                'placeholder (aucun effet gameplay MVP ; message explicite au runtime).',
              );
            } else if (block.kind == CutsceneStudioBlockKind.wait) {
              out.add(
                '$here : pause « Attendre » — compilée en waitMs mais non exécutée '
                'par l’exécuteur scénario MVP (bloquée tant que non branchée).',
              );
            } else if (block.kind == CutsceneStudioBlockKind.starterChoice) {
              out.add(
                '$here : choix du starter — action non gérée par l’exécuteur MVP.',
              );
            } else if (block.kind == CutsceneStudioBlockKind.playerQuestion) {
              out.add(
                '$here : question joueur — produit un nœud « choice » ; '
                'l’exécuteur MVP bloque encore les choix interactifs.',
              );
            } else {
              out.add(
                '$here : ${cutsceneStudioBlockKindLabel(block.kind)} — hors support '
                'exécuteur MVP (vérifier la compilation / le runtime).',
              );
            }
          }
        case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
          walk(
            <CutsceneFlowEntry>[CutsceneFlowBlockEntry(question)],
            '$path > embranchement',
          );
          walk(onYes, '$path > Oui');
          walk(onNo, '$path > Non');
      }
    }
  }

  walk(flow, 'Tronc');
  return out;
}

bool _isAuthoringPlaceholderKind(CutsceneStudioBlockKind kind) {
  return switch (kind) {
    CutsceneStudioBlockKind.characterAppear ||
    CutsceneStudioBlockKind.characterDisappear ||
    CutsceneStudioBlockKind.cameraCenter ||
    CutsceneStudioBlockKind.cameraTransition ||
    CutsceneStudioBlockKind.callCutscene =>
      true,
    _ => false,
  };
}
