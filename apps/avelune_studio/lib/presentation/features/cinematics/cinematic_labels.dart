import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

String cinematicActionLabel(CinematicTimelineStepKind kind) => switch (kind) {
  CinematicTimelineStepKind.wait => 'Attendre',
  CinematicTimelineStepKind.camera => 'Déplacer la caméra',
  CinematicTimelineStepKind.actorMove => 'Déplacer un acteur',
  CinematicTimelineStepKind.actorFace => 'Orienter un acteur',
  CinematicTimelineStepKind.actorEmote => 'Afficher une émotion',
  CinematicTimelineStepKind.actorAnimation => 'Jouer une animation',
  CinematicTimelineStepKind.dialogueLine => 'Ouvrir un dialogue',
  CinematicTimelineStepKind.sound => 'Jouer un son',
  CinematicTimelineStepKind.music => 'Musique',
  CinematicTimelineStepKind.fade => 'Fondu écran',
  CinematicTimelineStepKind.shake => 'Secouer la caméra',
  CinematicTimelineStepKind.fx => 'Effet visuel',
  CinematicTimelineStepKind.marker => 'Repère éditorial',
};

IconData cinematicActionIcon(CinematicTimelineStepKind kind) => switch (kind) {
  CinematicTimelineStepKind.wait => Icons.hourglass_bottom,
  CinematicTimelineStepKind.camera => Icons.videocam_outlined,
  CinematicTimelineStepKind.actorMove => Icons.directions_walk,
  CinematicTimelineStepKind.actorFace => Icons.explore_outlined,
  CinematicTimelineStepKind.actorEmote => Icons.mood,
  CinematicTimelineStepKind.actorAnimation => Icons.animation,
  CinematicTimelineStepKind.dialogueLine => Icons.forum_outlined,
  CinematicTimelineStepKind.sound => Icons.volume_up_outlined,
  CinematicTimelineStepKind.music => Icons.music_note_outlined,
  CinematicTimelineStepKind.fade => Icons.gradient,
  CinematicTimelineStepKind.shake => Icons.vibration,
  CinematicTimelineStepKind.fx => Icons.auto_awesome,
  CinematicTimelineStepKind.marker => Icons.bookmark_outline,
};

Color cinematicActionColor(
  BuildContext context,
  CinematicTimelineStepKind kind,
) => switch (kind) {
  CinematicTimelineStepKind.camera ||
  CinematicTimelineStepKind.music => Theme.of(context).colorScheme.primary,
  CinematicTimelineStepKind.actorMove => StudioTone.success.color(context),
  CinematicTimelineStepKind.wait ||
  CinematicTimelineStepKind.actorFace => StudioTone.warning.color(context),
  CinematicTimelineStepKind.sound ||
  CinematicTimelineStepKind.fx => StudioTone.info.color(context),
  _ => StudioTone.feature.color(context),
};

String cinematicTime(int milliseconds) =>
    '${(milliseconds / 1000).toStringAsFixed(2)} s';

bool cinematicDurationEditable(CinematicTimelineStep step) =>
    switch (step.kind) {
      CinematicTimelineStepKind.actorFace ||
      CinematicTimelineStepKind.marker => false,
      _ => step.durationMs != null,
    };

CinematicTimelineStepKind cinematicLaneAction(CinematicTimelineLaneKind lane) =>
    switch (lane) {
      CinematicTimelineLaneKind.camera => CinematicTimelineStepKind.camera,
      CinematicTimelineLaneKind.actor => CinematicTimelineStepKind.actorMove,
      CinematicTimelineLaneKind.dialogue =>
        CinematicTimelineStepKind.dialogueLine,
      CinematicTimelineLaneKind.fx => CinematicTimelineStepKind.fx,
      CinematicTimelineLaneKind.audio => CinematicTimelineStepKind.music,
      CinematicTimelineLaneKind.transitions => CinematicTimelineStepKind.fade,
      CinematicTimelineLaneKind.timeGlobal => CinematicTimelineStepKind.wait,
      CinematicTimelineLaneKind.other => CinematicTimelineStepKind.marker,
    };
