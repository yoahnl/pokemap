part of 'scene_linked_document.dart';

extension _SceneLinkedCinematic on SceneLinkedDocuments {
  Widget _cinematic(SceneNode node, ProjectManifest project) {
    final payload = node.payload;
    if (payload is SceneCinematicPayload) {
      final cinematic = project.cinematics
          .where((asset) => asset.id == payload.cinematicId)
          .firstOrNull;
      if (cinematic == null) {
        return const StudioNotice(
          'Cinématique introuvable. Sa référence est conservée.',
          isError: true,
        );
      }
      final map = project.maps
          .where((map) => map.id == cinematic.mapId)
          .firstOrNull;
      final steps = cinematic.timeline.steps;
      final duration = steps.fold<int>(
        0,
        (sum, step) => sum + (step.durationMs ?? 0),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cinematic.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('Cinématique sur carte · lecture seule'),
          Text(
            'Carte : ${map?.name ?? cinematic.mapId ?? 'contexte de la scène'}',
          ),
          Text(
            '${steps.length} étapes · durées explicites ${(duration / 1000).toStringAsFixed(1)} s',
          ),
          const SizedBox(height: 12),
          for (final entry in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.$1 + 1}. ${entry.$2.label ?? _stepLabel(entry.$2.kind)}',
                  ),
                  if (entry.$2.durationMs != null)
                    Text('${entry.$2.durationMs} ms'),
                  if (entry.$2.actorId case final actorId?)
                    Text(
                      'Acteur : ${cinematic.requiredActors.where((actor) => actor.actorId == actorId).firstOrNull?.label ?? actorId}',
                    ),
                  if (entry.$2.targetId case final target?)
                    Text(
                      'Destination : ${cinematic.movementTargets.where((point) => point.targetId == target).firstOrNull?.label ?? target}',
                    ),
                  if (entry.$2.dialogueText case final text?) Text(text),
                  if (entry.$2.assetRef case final asset?)
                    Text('Ressource : $asset'),
                ],
              ),
            ),
          const StudioNotice(
            'Aperçu du document exact. L’éditeur de timeline reste dans son parcours existant.',
          ),
        ],
      );
    }
    if (payload is ScenePresentationCinematicPayload) {
      final cinematic = presentationFor != null
          ? presentationFor!(payload.presentationCinematicId)
          : project.presentationCinematics
                .where((asset) => asset.id == payload.presentationCinematicId)
                .firstOrNull;
      if (cinematic == null) {
        return const StudioNotice(
          'Présentation introuvable. Sa référence est conservée.',
          isError: true,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cinematic.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Présentation · ${(cinematic.durationUs / 1000000).toStringAsFixed(1)} s · ${cinematic.tracks.length} pistes',
          ),
          for (final track in cinematic.tracks) ...[
            const SizedBox(height: 12),
            Text('${track.label} · ${track.clips.length} clips'),
            for (final clip in track.clips)
              Text(
                '${(clip.startUs / 1000000).toStringAsFixed(1)}–${(clip.endUs / 1000000).toStringAsFixed(1)} s${clip is PresentationTextClip ? ' · ${clip.text}' : ''}',
              ),
          ],
          const SizedBox(height: 16),
          const StudioNotice(
            'Document exact en lecture seule. Aucune modification de timeline depuis cet aperçu.',
          ),
        ],
      );
    }
    return const StudioNotice('Ce bloc ne référence pas de document lié.');
  }
}

String _stepLabel(CinematicTimelineStepKind kind) => switch (kind) {
  CinematicTimelineStepKind.wait => 'Attendre',
  CinematicTimelineStepKind.camera => 'Déplacer la caméra',
  CinematicTimelineStepKind.actorMove => 'Déplacer un acteur',
  CinematicTimelineStepKind.actorFace => 'Orienter un acteur',
  CinematicTimelineStepKind.actorEmote => 'Émotion',
  CinematicTimelineStepKind.actorAnimation => 'Animation de personnage',
  CinematicTimelineStepKind.dialogueLine => 'Dialogue',
  CinematicTimelineStepKind.sound => 'Effet sonore',
  CinematicTimelineStepKind.music => 'Musique',
  CinematicTimelineStepKind.fade => 'Fondu',
  CinematicTimelineStepKind.shake => 'Secousse',
  CinematicTimelineStepKind.fx => 'Effet visuel',
  CinematicTimelineStepKind.marker => 'Repère',
};
