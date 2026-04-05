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
// (ex. nouvelle cutscene liée = nouvelle entrée dans `cutscenes`).
//
// Chaque tuile correspond soit à un focus inspecteur (données réelles), soit à
// un ajout de liste (`cutscenes`, `outcomes`, `worldChanges`). Aucune tuile
// purement « décorative » : si une action n’existe pas dans le modèle, elle
// n’a pas sa place ici.

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
                _PaletteSectionLabel(context, 'Entrée & objectif'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_right_circle,
                  label: 'Entrée & activation',
                  subtitle:
                      'Note auteur + règles `activation` (même inspecteur)',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.flowEntry)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.scope,
                  label: 'Objectif & fiche step',
                  subtitle: 'Nom, description, ligne canvas optionnelle',
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
                _PaletteSectionLabel(context, 'Outcomes'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.tree,
                  label: 'Outcomes locaux (liste)',
                  subtitle:
                      'Variantes métier documentées ; exécution du choix = Cutscene',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.localBranches)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_circle,
                  label: 'Ajouter un outcome local',
                  subtitle: 'Nouvelle entrée dans `outcomes` (scope local)',
                  onTap: onAddLocalOutcome,
                  filled: true,
                  accent: EditorChrome.inspectorJoyOrchid,
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_branch,
                  label: 'Ajouter un outcome progression',
                  subtitle: 'Entrée `outcomes` (scope progression)',
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
                  subtitle: 'Note auteur + règle `completion` (technique)',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.validationEngine)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_right_circle,
                  label: 'Sortie narrative & mémo suite',
                  subtitle:
                      'Texte libre + id step optionnel (non branché moteur)',
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
