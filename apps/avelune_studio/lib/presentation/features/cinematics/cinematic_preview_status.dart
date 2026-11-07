import 'cinematic_transport_listenable.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../scenes/scene_linked_document.dart';
import 'cinematic_inspector.dart' show cinematicActorChoiceLabel;
import 'cinematic_labels.dart';

class CinematicPreviewStatus extends StatefulWidget {
  const CinematicPreviewStatus({
    super.key,
    required this.controller,
    this.dialogues,
    this.onStep,
    this.onActor,
  });
  final CinematicWorkspaceController controller;
  final DialogueWorkspaceController? dialogues;
  final ValueChanged<String>? onStep, onActor;
  @override
  State<CinematicPreviewStatus> createState() => _CinematicPreviewStatusState();
}

class _CinematicPreviewStatusState extends State<CinematicPreviewStatus> {
  final linked = SceneLinkedDocuments();
  @override
  Widget build(BuildContext context) {
    linked.dialogues = widget.dialogues;
    final transport = widget.controller.transport;
    return AnimatedBuilder(
      animation: CinematicTransportListenable(transport),
      builder: (context, _) {
        final plan = transport.plan;
        final activeIds = transport.frame?.activeStepIds ?? const <String>[];
        final steps =
            widget.controller.active?.asset.timeline.steps ??
            <CinematicTimelineStep>[];
        final activeSteps = steps
            .where((s) => activeIds.contains(s.id))
            .toList();
        final active =
            activeSteps
                .where((s) => s.kind == CinematicTimelineStepKind.dialogueLine)
                .firstOrNull ??
            activeSteps.firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aperçu isolé',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (transport.mediaError case final problem?)
              StudioNotice(problem, isError: true),
            Text(
              '${cinematicTime(transport.timeMs)} · ${activeSteps.length > 1
                  ? '${activeSteps.length} actions simultanées · ${activeSteps.map((step) => cinematicActionLabel(step.kind)).join(' + ')}'
                  : active == null
                  ? 'Fin de séquence'
                  : cinematicActionLabel(active.kind)}',
            ),
            const SizedBox(height: 8),
            const StudioNotice(
              'Les dialogues et médias ont une durée d’aperçu indicative. La lecture réelle attend leurs contrats propres.',
            ),
            const SizedBox(height: 8),
            if (active?.kind == CinematicTimelineStepKind.dialogueLine)
              if (active!.assetRef != null)
                linked.dialoguePreview(
                  SceneYarnDialoguePayload(dialogueId: active.assetRef!),
                  widget.controller.project,
                  widget.controller.narrative,
                )
              else
                Text(active.dialogueText ?? 'Réplique sans texte'),
            if (active?.kind == CinematicTimelineStepKind.fx)
              const StudioNotice(
                'Cette commande est conservée pour le runtime. Son effet n’est pas joué dans cet aperçu de montage.',
              ),
            if (active != null &&
                {
                  CinematicTimelineStepKind.sound,
                  CinematicTimelineStepKind.music,
                }.contains(active.kind))
              const Text(
                'Lecture audio via l’adaptateur runtime · scrub muet. La reprise redémarre le fichier, sans recherche audio précise.',
              ),
            if (transport.frame?.activeEmotes case final emotes?)
              for (final e in emotes)
                Text(
                  '${e.actorLabel ?? e.actorId} : ${e.emoteLabel ?? e.emoteId}',
                ),
            if (groupCinematicDiagnostics(plan?.diagnostics ?? const [])
                case final groups when groups.isNotEmpty) ...[
              Text(
                cinematicDiagnosticSummary(groups),
                key: const ValueKey('cinematic-preview-diagnostics-summary'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final group in groups)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StudioNotice(
                        group.count > 1
                            ? '${group.message} · ${group.count} occurrences'
                            : group.message,
                        isError: group.blocking,
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (widget.onStep case final onStep?)
                            for (final id in group.stepIds.take(6))
                              StudioTool(
                                label:
                                    'Aller à l’action · ${_stepLabel(steps, id)}',
                                icon: Icons.ads_click,
                                onPressed: () => onStep(id),
                              ),
                          if (widget.onActor case final onActor?)
                            for (final id in group.actorIds.take(6))
                              StudioTool(
                                label: 'Aller à l’acteur · ${_actorLabel(id)}',
                                icon: Icons.person_search_outlined,
                                onPressed: () => onActor(id),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            StudioButton(
              label: 'Revenir au début',
              secondary: true,
              onPressed: transport.stop,
            ),
          ],
        );
      },
    );
  }

  String _stepLabel(List<CinematicTimelineStep> steps, String id) {
    final index = steps.indexWhere((step) => step.id == id);
    return index < 0
        ? 'action absente'
        : '${index + 1}. ${cinematicActionLabel(steps[index].kind)}';
  }

  String _actorLabel(String id) {
    final actor = widget.controller.active?.asset.requiredActors
        .where((value) => value.actorId == id)
        .firstOrNull;
    return cinematicActorChoiceLabel(actor?.label, id);
  }
}

final class CinematicDiagnosticGroup {
  CinematicDiagnosticGroup(this.message, this.blocking);
  final String message;
  final bool blocking;
  int count = 0;
  final stepIds = <String>[];
  final actorIds = <String>[];
}

List<CinematicDiagnosticGroup> groupCinematicDiagnostics(
  Iterable<CinematicPreviewPlaybackDiagnostic> diagnostics,
) {
  final groups = <(bool, String), CinematicDiagnosticGroup>{};
  for (final diagnostic in diagnostics) {
    final group = groups.putIfAbsent(
      (diagnostic.blocking, diagnostic.message),
      () => CinematicDiagnosticGroup(diagnostic.message, diagnostic.blocking),
    )..count += 1;
    if (diagnostic.stepId case final id? when !group.stepIds.contains(id)) {
      group.stepIds.add(id);
    }
    if (diagnostic.actorId case final id? when !group.actorIds.contains(id)) {
      group.actorIds.add(id);
    }
  }
  return [
    ...groups.values.where((group) => group.blocking),
    ...groups.values.where((group) => !group.blocking),
  ];
}

String cinematicDiagnosticSummary(List<CinematicDiagnosticGroup> groups) {
  final problems = groups.where((group) => group.blocking).length;
  final warnings = groups.length - problems;
  String count(int value, String one, String many) =>
      '$value ${value > 1 ? many : one}';
  if (problems == 0) {
    return 'Lecture possible : ${count(warnings, 'avertissement', 'avertissements')} sans effet bloquant.';
  }
  final parts = [
    'Lecture possible mais incomplète : ${count(problems, 'problème à corriger', 'problèmes à corriger')}',
    if (warnings > 0) count(warnings, 'avertissement', 'avertissements'),
  ];
  return '${parts.join(', ')}.';
}
