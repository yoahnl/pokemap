import 'cinematic_transport_listenable.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../scenes/scene_linked_document.dart';
import 'cinematic_labels.dart';

class CinematicPreviewStatus extends StatefulWidget {
  const CinematicPreviewStatus({
    super.key,
    required this.controller,
    this.dialogues,
  });
  final CinematicWorkspaceController controller;
  final DialogueWorkspaceController? dialogues;
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
        final active = steps.where((s) => activeIds.contains(s.id)).firstOrNull;
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
              '${cinematicTime(transport.timeMs)} · ${active == null ? 'Fin de séquence' : cinematicActionLabel(active.kind)}',
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
            for (final diagnostic
                in plan?.diagnostics ?? <CinematicPreviewPlaybackDiagnostic>[])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: StudioNotice(
                  diagnostic.message,
                  isError: diagnostic.blocking,
                ),
              ),
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
}
