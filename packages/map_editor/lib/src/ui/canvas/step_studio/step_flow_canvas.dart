import 'package:flutter/cupertino.dart';

import '../../../features/narrative/application/step_studio_authoring.dart';
import '../../shared/cupertino_editor_widgets.dart';
import 'step_flow_focus.dart';

// -----------------------------------------------------------------------------
// Canvas central — flux vertical « Scratch métier »
// -----------------------------------------------------------------------------
//
// Chaque carte résume une **responsabilité Step**. Les textes « flux »
// (`flow*Label`) sont des annotations auteur sur le canvas ; les phrases
// techniques viennent de `summarizeStepActivation` / `summarizeStepCompletion`.
// Les cutscenes n’affichent que id + rôle : la mise en scène reste dans
// Cutscene Studio.
//
// Ce layout est volontairement linéaire (peu de « spaghetti ») : la complexité
// des branches **métier** est portée par les outcomes locaux, pas par un graphe
// d’exécution comme en Cutscene.

typedef CutsceneNameResolver = String Function(String cutsceneId);

class StepFlowCanvas extends StatelessWidget {
  const StepFlowCanvas({
    super.key,
    required this.step,
    required this.selected,
    required this.onSelect,
    required this.resolveCutsceneName,
  });

  final StepStudioStep step;
  final StepFlowFocus? selected;
  final ValueChanged<StepFlowFocus> onSelect;
  final CutsceneNameResolver resolveCutsceneName;

  List<StepStudioOutcomeDefinition> _locals() =>
      step.outcomes.where((o) => o.scope == StepStudioOutcomeScope.local).toList();

  List<StepStudioOutcomeDefinition> _progressions() => step.outcomes
      .where((o) => o.scope == StepStudioOutcomeScope.progression)
      .toList();

  @override
  Widget build(BuildContext context) {
    final locals = _locals();
    final progs = _progressions();

    return EditorPaneSurface(
      radius: 18,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Flux de l’étape',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Logique de progression — les scènes s’éditent ailleurs.',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            _flowCard(
              context,
              focus: const StepFlowFocus(StepFlowSlot.flowEntry),
              accent: EditorChrome.inspectorJoyMint,
              icon: CupertinoIcons.arrow_right_circle,
              title: 'Entrée dans l’étape',
              body: step.flowEntryLabel.trim().isEmpty
                  ? Text(
                      summarizeStepActivation(step),
                      style: _bodyStyle(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.flowEntryLabel,
                          style: _emphasisStyle(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summarizeStepActivation(step),
                          style: _bodyStyle(context),
                        ),
                      ],
                    ),
            ),
            _connector(context),
            _flowCard(
              context,
              focus: const StepFlowFocus(StepFlowSlot.objective),
              accent: EditorChrome.inspectorJoyAmber,
              icon: CupertinoIcons.scope,
              title: 'Objectif',
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.name,
                    style: _emphasisStyle(context),
                  ),
                  if (step.flowObjectiveLabel.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      step.flowObjectiveLabel,
                      style: _bodyStyle(context),
                    ),
                  ] else if (step.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      step.description,
                      style: _bodyStyle(context),
                    ),
                  ],
                ],
              ),
            ),
            _connector(context),
            _sectionTitle(context, 'Cutscenes liées (références)'),
            const SizedBox(height: 8),
            if (step.cutscenes.isEmpty)
              _emptyHint(
                context,
                'Aucune cutscene. Utilisez la palette pour en lier une — '
                'vous éditerez le contenu dans Cutscene Studio.',
              )
            else
              for (var i = 0; i < step.cutscenes.length; i++) ...[
                _flowCard(
                  context,
                  focus: StepFlowFocus(StepFlowSlot.cutsceneLink, i),
                  accent: EditorChrome.inspectorJoyPlum,
                  icon: CupertinoIcons.film,
                  title: stepStudioCutsceneRoleLabel(step.cutscenes[i].role),
                  body: Text(
                    resolveCutsceneName(step.cutscenes[i].cutsceneId),
                    style: _emphasisStyle(context),
                  ),
                  foot: Text(
                    'id: ${step.cutscenes[i].cutsceneId}',
                    style: _captionStyle(context),
                  ),
                ),
                if (i < step.cutscenes.length - 1) _connector(context),
              ],
            _connector(context),
            _flowCard(
              context,
              focus: const StepFlowFocus(StepFlowSlot.localBranches),
              accent: EditorChrome.inspectorJoyOrchid,
              icon: CupertinoIcons.tree,
              title: 'Outcomes locaux',
              body: locals.isEmpty
                  ? _emptyHint(
                      context,
                      'Chaque outcome « Local » documente une variante métier '
                      '(ex. starter feu / eau / plante). Le choix joueur '
                      's’exécute dans la cutscene, pas ici.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < locals.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () {
                                final idx = step.outcomes.indexOf(locals[i]);
                                if (idx >= 0) {
                                  onSelect(StepFlowFocus(
                                    StepFlowSlot.localOutcome,
                                    idx,
                                  ));
                                }
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '• ${locals[i].label} → ${locals[i].outcomeId}',
                                  style: _bodyStyle(context),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            _connector(context),
            _flowCard(
              context,
              focus: const StepFlowFocus(StepFlowSlot.validationEngine),
              accent: EditorChrome.inspectorJoyBlue,
              icon: CupertinoIcons.checkmark_seal,
              title: 'Validation',
              body: step.flowValidationLabel.trim().isEmpty
                  ? Text(
                      summarizeStepCompletion(step),
                      style: _bodyStyle(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.flowValidationLabel,
                          style: _emphasisStyle(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summarizeStepCompletion(step),
                          style: _bodyStyle(context),
                        ),
                      ],
                    ),
              foot: Text(
                'Source technique : `completion` (ci-dessus ou seul si pas de note auteur). '
                '`flowValidationLabel` est une aide lecture, pas la règle exécutable seule.',
                style: _captionStyle(context),
              ),
            ),
            _connector(context),
            _sectionTitle(context, 'Outcomes de progression'),
            const SizedBox(height: 8),
            if (progs.isEmpty)
              _emptyHint(
                context,
                'Ajoutez un résultat « Progression » pour l’histoire globale '
                '(ex. chapter_1.starter_chosen).',
              )
            else
              for (var i = 0; i < progs.length; i++) ...[
                _flowCard(
                  context,
                  focus: StepFlowFocus(
                    StepFlowSlot.progressionOutcome,
                    step.outcomes.indexOf(progs[i]),
                  ),
                  accent: EditorChrome.inspectorJoyMint,
                  icon: CupertinoIcons.arrow_branch,
                  title: progs[i].label,
                  body: Text(
                    progs[i].outcomeId,
                    style: _monoStyle(context),
                  ),
                ),
                if (i < progs.length - 1) _connector(context),
              ],
            _connector(context),
            _flowCard(
              context,
              focus: const StepFlowFocus(StepFlowSlot.exitNext),
              accent: EditorChrome.inspectorJoyCyan,
              icon: CupertinoIcons.arrow_right_circle,
              title: 'Sortie de l’étape',
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.flowExitLabel.trim().isNotEmpty)
                    Text(
                      step.flowExitLabel,
                      style: _emphasisStyle(context),
                    )
                  else
                    Text(
                      'Texte libre : conséquence narrative / design (annotation auteur).',
                      style: _bodyStyle(context),
                    ),
                  if (step.flowUnlocksStepId != null &&
                      step.flowUnlocksStepId!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mémo : step id « ${step.flowUnlocksStepId} » '
                      '(rappel dans le document — ne déclenche pas le déblocage).',
                      style: _captionStyle(context),
                    ),
                  ],
                ],
              ),
              foot: Text(
                'À ne pas confondre : le déblocage réel d’une step = ses règles '
                '`activation`, pas ce bloc ni `flowUnlocksStepId`.',
                style: _captionStyle(context),
              ),
            ),
            _connector(context),
            _flowCard(
              context,
              focus: const StepFlowFocus(StepFlowSlot.worldPersistence),
              accent: EditorChrome.inspectorJoyCyan,
              icon: CupertinoIcons.map,
              title: 'Monde persistant',
              body: step.worldChanges.isEmpty
                  ? _emptyHint(
                      context,
                      'Aucun changement de présence d’entité. '
                      'C’est ici que vit la cohérence « Emma dehors / Emma labo », '
                      'pas dans une cutscene.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < step.worldChanges.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () => onSelect(
                                StepFlowFocus(
                                  StepFlowSlot.worldChangeItem,
                                  i,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '• ${step.worldChanges[i].mapId} → ${step.worldChanges[i].entityId}',
                                  style: _bodyStyle(context),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) => TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
      );

  TextStyle _emphasisStyle(BuildContext context) => TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w800,
      );

  TextStyle _captionStyle(BuildContext context) => TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 11,
      );

  TextStyle _monoStyle(BuildContext context) => TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 11,
        fontFamily: 'Menlo',
        fontWeight: FontWeight.w600,
      );

  Widget _sectionTitle(BuildContext context, String t) {
    return Text(
      t,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 12,
        height: 1.35,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _connector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: EditorChrome.subtleLabel(context).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _flowCard(
    BuildContext context, {
    required StepFlowFocus focus,
    required Color accent,
    required IconData icon,
    required String title,
    required Widget body,
    Widget? foot,
  }) {
    final isSel = selected == focus;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => onSelect(focus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(alpha: isSel ? 0.14 : 0.06),
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: isSel ? 0.85 : 0.35),
            width: isSel ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            body,
            if (foot != null) ...[
              const SizedBox(height: 6),
              foot,
            ],
          ],
        ),
      ),
    );
  }
}
