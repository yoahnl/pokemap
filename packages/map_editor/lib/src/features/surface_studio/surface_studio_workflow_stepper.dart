import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);

/// Stepper de lecture produit pour Surface Studio.
///
/// Il ne pilote aucune logique métier : il transforme seulement le catalogue
/// courant en progression no-code atlas -> grille -> animations -> surfaces
/// peignables. Les générateurs existants restent propriétaires des écritures.
class SurfaceStudioWorkflowStepper extends StatelessWidget {
  const SurfaceStudioWorkflowStepper({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(readModel.summary);
    return Container(
      key: const ValueKey('surface_studio_workflow_steps'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _WorkflowStepTile(step: steps[i]),
                  if (i != steps.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(child: _WorkflowStepTile(step: steps[i])),
                if (i != steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Container(
                      width: 28,
                      height: 1,
                      color: steps[i].completed
                          ? _accent.withValues(alpha: 0.8)
                          : EditorChrome.editorIslandRim(context),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

List<_WorkflowStep> _stepsFor(SurfaceStudioCatalogSummaryReadModel summary) {
  final hasAtlas = summary.atlasCount > 0;
  final hasAnimations = summary.animationCount > 0;
  final hasSurfaces = summary.presetCount > 0;

  final activeIndex = !hasAtlas ? 0 : (!hasAnimations ? 1 : 3);

  return [
    _WorkflowStep(
      index: 1,
      title: 'Atlas',
      subtitle: 'Importer l’atlas source',
      active: activeIndex == 0,
      completed: hasAtlas,
    ),
    _WorkflowStep(
      index: 2,
      title: 'Grille',
      subtitle: 'Vérifier le découpage',
      active: activeIndex == 1,
      completed: hasAtlas,
    ),
    _WorkflowStep(
      index: 3,
      title: 'Animations',
      subtitle: 'Détecter les animations',
      active: activeIndex == 2,
      completed: hasAnimations,
    ),
    _WorkflowStep(
      index: 4,
      title: 'Surfaces prêtes à peindre',
      subtitle: 'Créer les surfaces finales',
      active: activeIndex == 3,
      completed: hasSurfaces,
    ),
  ];
}

final class _WorkflowStep {
  const _WorkflowStep({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.completed,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool active;
  final bool completed;
}

class _WorkflowStepTile extends StatelessWidget {
  const _WorkflowStepTile({required this.step});

  final _WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final circleFill = step.completed || step.active
        ? _accent.withValues(alpha: step.completed ? 0.34 : 0.22)
        : EditorChrome.islandFillElevated(context);
    final circleBorder = step.completed || step.active
        ? _accent.withValues(alpha: 0.9)
        : EditorChrome.editorIslandRim(context);
    final titleColor = step.active || step.completed ? _accent : label;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleFill,
            shape: BoxShape.circle,
            border: Border.all(color: circleBorder),
          ),
          child: Text(
            '${step.index}',
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${step.index}. ${step.title}',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.subtitle,
                style: TextStyle(
                  color: subtle.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
