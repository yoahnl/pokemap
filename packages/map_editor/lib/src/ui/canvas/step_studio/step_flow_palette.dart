import 'package:flutter/cupertino.dart';

import '../../shared/cupertino_editor_widgets.dart';
import 'step_flow_focus.dart';

// -----------------------------------------------------------------------------
// Palette gauche — Step Studio (polish final, langage créateur)
// -----------------------------------------------------------------------------
//
// Chaque tuile doit avoir un sens **immédiat** pour quelqu’un qui ne code pas.
// En interne, une tuile ouvre l’inspecteur sur une vraie liste du modèle
// (`cutscenes`, `outcomes`, `worldChanges`, etc.) ou ajoute une ligne — jamais
// un gadget sans donnée derrière.
//
// INTERDIT ici (Cutscene Studio uniquement) : dialogue, déplacement PNJ,
// caméra, timing, pathfinding.

/// Colonne gauche : **parties de l’étape** (navigation) puis **ajouts** (lignes modèle).
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
            'Repères & ajouts',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'En haut : ouvrir une partie de l’étape. En bas : ajouter une ligne au modèle.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 10,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _PaletteSectionLabel(context, 'Parties de l’étape'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_right_circle,
                  label: 'Début',
                  subtitle: 'Disponibilité + texte au centre',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.flowEntry)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.scope,
                  label: 'Objectif',
                  subtitle: 'Nom, texte, texte au centre',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.objective)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.film,
                  label: 'Scènes',
                  subtitle: 'Plusieurs scènes possibles',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.cutscenesHub)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.tree,
                  label: 'Résultats',
                  subtitle: 'Résultats possibles pour cette étape',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.localBranches)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.checkmark_seal,
                  label: 'Fin',
                  subtitle: 'Texte au centre + condition de fin',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.validationEngine)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.doc_plaintext,
                  label: 'Transition',
                  subtitle: 'Mémo seulement — rien d’automatique',
                  onTap: () => onFocus(const StepFlowFocus(StepFlowSlot.exitNext)),
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.map,
                  label: 'Carte',
                  subtitle: 'Changements sur la carte',
                  onTap: () =>
                      onFocus(const StepFlowFocus(StepFlowSlot.worldPersistence)),
                ),
                const SizedBox(height: 12),
                _PaletteSectionLabel(context, 'Résultats possibles'),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_circle,
                  label: 'Ajouter un résultat',
                  subtitle: 'Pour cette étape (hors histoire globale)',
                  onTap: onAddLocalOutcome,
                  filled: true,
                  accent: EditorChrome.inspectorJoyOrchid,
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.arrow_branch,
                  label: 'Ajouter un résultat pour l’histoire',
                  subtitle: 'Fait avancer l’histoire globale',
                  onTap: onAddProgressionOutcome,
                  filled: true,
                  accent: EditorChrome.inspectorJoyMint,
                ),
                const SizedBox(height: 10),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_rectangle_on_rectangle,
                  label: 'Ajouter une scène',
                  subtitle: 'Référence seule — pas le dialogue ici',
                  onTap: onAddCutsceneLink,
                  filled: true,
                  accent: EditorChrome.inspectorJoyPlum,
                  tileEnabled: canAddCutscene,
                ),
                _paletteTile(
                  context,
                  icon: CupertinoIcons.plus_circled,
                  label: 'Ajouter un changement',
                  subtitle: 'Sur la carte, pour cette étape',
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
