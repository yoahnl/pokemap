import 'package:flutter/material.dart';

import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';

class MapBuilderSpaceOutline {
  const MapBuilderSpaceOutline({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.rubrics,
    required this.note,
    required this.inspectorEyebrow,
    required this.inspectorTitle,
    required this.inspectorHint,
    this.addLabel,
    this.searchHint,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<MapBuilderRubric> rubrics;
  final String? addLabel;
  final String? searchHint;
  final (String, String) note;
  final String inspectorEyebrow;
  final String inspectorTitle;
  final String inspectorHint;
}

class MapBuilderRubric {
  const MapBuilderRubric(this.id, this.icon, this.label, this.detail);

  final String id;
  final IconData icon;
  final String label;
  final String detail;
}

MapBuilderSpaceOutline? mapBuilderSpaceOutline(
  MapBuilderSpace space,
  AppLocalizations l10n,
) => switch (space) {
  MapBuilderSpace.construction => null,
  MapBuilderSpace.gameplay => MapBuilderSpaceOutline(
    eyebrow: l10n.activeMapEyebrow,
    title: l10n.gameplayTitle,
    subtitle: l10n.gameplaySubtitle,
    rubrics: [
      MapBuilderRubric(
        'connections',
        Icons.link,
        l10n.gameplayConnections,
        l10n.gameplayConnectionsDetail,
      ),
      MapBuilderRubric(
        'movement',
        Icons.directions_walk,
        l10n.gameplayMovement,
        l10n.gameplayMovementDetail,
      ),
      MapBuilderRubric(
        'encounters',
        Icons.grass,
        l10n.gameplayEncounters,
        l10n.gameplayEncountersDetail,
      ),
      MapBuilderRubric(
        'spawns',
        Icons.flag_outlined,
        l10n.gameplaySpawns,
        l10n.gameplaySpawnsDetail,
      ),
      MapBuilderRubric(
        'fieldObjects',
        Icons.shield_outlined,
        l10n.gameplayFieldObjects,
        l10n.gameplayFieldObjectsDetail,
      ),
    ],
    addLabel: l10n.gameplayAdd,
    searchHint: l10n.gameplaySearch,
    note: (l10n.gameplayNoteTitle, l10n.gameplayNoteBody),
    inspectorEyebrow: l10n.gameplayInspectorEyebrow,
    inspectorTitle: l10n.gameplayInspectorTitle,
    inspectorHint: l10n.gameplayInspectorHint,
  ),
  MapBuilderSpace.story => MapBuilderSpaceOutline(
    eyebrow: l10n.storyEyebrow,
    title: l10n.storyTitle,
    subtitle: l10n.storySubtitle,
    rubrics: [
      MapBuilderRubric(
        'characters',
        Icons.person_outline,
        l10n.storyCharacters,
        l10n.storyCharactersDetail,
      ),
      MapBuilderRubric(
        'interactive',
        Icons.chat_bubble_outline,
        l10n.storyInteractive,
        l10n.storyInteractiveDetail,
      ),
      MapBuilderRubric(
        'zones',
        Icons.crop_square,
        l10n.storyZones,
        l10n.storyZonesDetail,
      ),
      MapBuilderRubric(
        'mapResults',
        Icons.outlined_flag,
        l10n.storyMapResults,
        l10n.storyMapResultsDetail,
      ),
    ],
    addLabel: l10n.storyAdd,
    searchHint: l10n.storySearch,
    note: (l10n.storyNoteTitle, l10n.storyNoteBody),
    inspectorEyebrow: l10n.storyInspectorEyebrow,
    inspectorTitle: l10n.storyInspectorTitle,
    inspectorHint: l10n.storyInspectorHint,
  ),
  MapBuilderSpace.ambiance => MapBuilderSpaceOutline(
    eyebrow: l10n.activeMapEyebrow,
    title: l10n.ambianceTitle,
    subtitle: l10n.ambianceSubtitle,
    rubrics: [
      MapBuilderRubric(
        'dayNight',
        Icons.wb_twilight,
        l10n.ambianceDayNight,
        l10n.ambianceDayNightDetail,
      ),
      MapBuilderRubric(
        'weather',
        Icons.cloud_outlined,
        l10n.ambianceWeather,
        l10n.ambianceWeatherDetail,
      ),
      MapBuilderRubric(
        'effects',
        Icons.auto_awesome_outlined,
        l10n.ambianceEffects,
        l10n.ambianceEffectsDetail,
      ),
      MapBuilderRubric(
        'music',
        Icons.music_note_outlined,
        l10n.ambianceMusic,
        l10n.ambianceMusicDetail,
      ),
    ],
    note: (l10n.ambianceNoteTitle, l10n.ambianceNoteBody),
    inspectorEyebrow: l10n.ambianceInspectorEyebrow,
    inspectorTitle: l10n.ambianceInspectorTitle,
    inspectorHint: l10n.ambianceInspectorHint,
  ),
};
