import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_badge.dart';

export '../../../features/cinematics/application/cinematic_timeline_rules.dart'
    show cinematicDurationEditable, cinematicLaneAction;

String cinematicActionLabel(CinematicTimelineStepKind kind) => switch (kind) {
  CinematicTimelineStepKind.atmosphere => 'Ambiance 3D',
  CinematicTimelineStepKind.wait => 'Attendre',
  CinematicTimelineStepKind.camera => 'Déplacer la caméra',
  CinematicTimelineStepKind.actorMove => 'Déplacer un acteur',
  CinematicTimelineStepKind.actorJump => 'Faire sauter un acteur',
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
  CinematicTimelineStepKind.atmosphere => Icons.wb_twilight,
  CinematicTimelineStepKind.wait => Icons.hourglass_bottom,
  CinematicTimelineStepKind.camera => Icons.videocam_outlined,
  CinematicTimelineStepKind.actorMove => Icons.directions_walk,
  CinematicTimelineStepKind.actorJump => Icons.arrow_upward,
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
  CinematicTimelineStepKind.actorMove ||
  CinematicTimelineStepKind.actorJump => StudioTone.success.color(context),
  CinematicTimelineStepKind.wait ||
  CinematicTimelineStepKind.actorFace => StudioTone.warning.color(context),
  CinematicTimelineStepKind.sound ||
  CinematicTimelineStepKind.fx => StudioTone.info.color(context),
  _ => StudioTone.feature.color(context),
};

String cinematicTime(int milliseconds) =>
    '${(milliseconds / 1000).toStringAsFixed(2)} s';
