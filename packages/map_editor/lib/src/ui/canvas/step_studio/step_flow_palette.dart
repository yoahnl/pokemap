import 'package:flutter/cupertino.dart';

import '../../shared/cupertino_editor_widgets.dart';
import 'step_flow_focus.dart';

// -----------------------------------------------------------------------------
// Palette gauche — « briques métier » Step Studio
// -----------------------------------------------------------------------------
//
// IMPORTANT PRODUIT (à ne pas violer) :
// - Ici : entrée, objectif, validation, outcomes, liens cutscene, monde.
// - Pas ici : dialogue, déplacement PNJ, caméra, wait, pathfinding.
//   Ces derniers vivent exclusivement dans Cutscene Studio.
//
// La palette ne crée pas de nœuds d’exécution : elle oriente la créatrice
// vers les bons champs **ou** déclenche l’ajout d’éléments de données Step
// (ex. nouvelle cutscene liée = nouvelle entrée dans [StepStudioStep.cutscenes]).

/// Colonne gauche : raccourcis vers les zones du flux et actions d’ajout.
class StepFlowPalette extends StatelessWidget {
  const StepFlowPalette({
    super.key,
    required this.enabled,
    required this.onFocus,
    required this.onAddCutsceneLink,
    required this.onAddLocalOutcome,
    required this.onAddProgressionOutcome,
    required this.onAddWorldChange,
    required this.canAddCutscene,
    required this.canAddWorldChange,
  });

  final bool enabled;
  final ValueChanged<StepFlowFocus> onFocus;
  final VoidCallback onAddCutsceneLink;
  final VoidCallback onAddLocalOutcome;
  final VoidCallback onAddProgressionOutcome;
  final VoidCallback onAddWorldChange;
  final bool canAddCutscene;
  final bool canAddWorldChange;

  @override
  Widget build(BuildContext context) {
    return EditorPaneSurface(
      radius: 16,
      tint: EditorChrome.islandNeutralTint,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Blocs métier',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Progression de l’étape — pas la mise en scène.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _PaletteSectionLabel(context, 'Lire / structurer'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_right_circle,
                  label: 'Entrée dans l’étape',
                  subtitle: 'Quand ça commence (texte + activation)',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.flowEntry)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.gear_alt,
                  label: 'Moteur d’activation',
                  subtitle: 'Règle technique « step active »',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.activationEngine)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.scope,
                  label: 'Objectif joueur',
                  subtitle: 'Ce que le joueur doit accomplir',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.objective)),
                ),
                const SizedBox(height: 10),
                _PaletteSectionLabel(context, 'Scènes liées (références)'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_rectangle_on_rectangle,
                  label: 'Ajouter une cutscene liée',
                  subtitle: 'Référence seule — éditer dans Cutscene',
                  onTap: onAddCutsceneLink,
                  filled: true,
                  accent: EditorChrome.inspectorJoyPlum,
                  tileEnabled: canAddCutscene,
                ),
                const SizedBox(height: 10),
                _PaletteSectionLabel(context, 'Résultats & branches'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.tree,
                  label: 'Branches locales',
                  subtitle: 'Outcomes locaux (ex. choix starter)',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.localBranches)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_circle,
                  label: 'Résultat local',
                  subtitle: 'Nouvelle branche / choix',
                  onTap: onAddLocalOutcome,
                  filled: true,
                  accent: EditorChrome.inspectorJoyOrchid,
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_branch,
                  label: 'Résultat progression',
                  subtitle: 'Outcome qui fait avancer l’histoire',
                  onTap: onAddProgressionOutcome,
                  filled: true,
                  accent: EditorChrome.inspectorJoyMint,
                ),
                const SizedBox(height: 10),
                _PaletteSectionLabel(context, 'Fin d’étape'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.checkmark_seal,
                  label: 'Validation',
                  subtitle: 'Quand l’étape est terminée',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.validationEngine)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_right_circle,
                  label: 'Sortie & suite',
                  subtitle: 'Débloquer la step suivante (lisible)',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.exitNext)),
                ),
                const SizedBox(height: 10),
                _PaletteSectionLabel(context, 'Monde'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.map,
                  label: 'Changements persistants',
                  subtitle: 'Présence PNJ / entités',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.worldPersistence)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_circled,
                  label: 'Ajouter un changement monde',
                  subtitle: 'Nouvelle règle présence sur une carte',
                  onTap: onAddWorldChange,
                  filled: true,
                  accent: EditorChrome.inspectorJoyCyan,
                  tileEnabled: canAddWorldChange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool filled = false,
    Color? accent,
    bool tileEnabled = true,
  }) {
    final effective = enabled && tileEnabled;
    final ac = accent ?? EditorChrome.inspectorJoyCyan;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: effective ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: filled
                ? ac.withValues(alpha: effective ? 0.14 : 0.06)
                : EditorChrome.sidebarHoverFill(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ac.withValues(alpha: effective ? 0.45 : 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: ac.withValues(alpha: effective ? 1 : 0.45)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: EditorChrome.primaryLabel(context)
                            .withValues(alpha: effective ? 1 : 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: EditorChrome.subtleLabel(context)
                            .withValues(alpha: effective ? 1 : 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _PaletteSectionLabel(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 2),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: EditorChrome.subtleLabel(context),
      ),
    ),
  );
}
