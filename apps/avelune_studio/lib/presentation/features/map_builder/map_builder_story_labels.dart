import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

IconData mapBuilderStoryIcon(MapStoryElementKind kind) => switch (kind) {
  MapStoryElementKind.character => Icons.person_outline,
  MapStoryElementKind.interactive => Icons.chat_bubble_outline,
  MapStoryElementKind.zone => Icons.crop_square,
  MapStoryElementKind.map => Icons.outlined_flag,
};

String mapBuilderStoryKind(MapStoryElementKind kind, AppLocalizations l10n) =>
    switch (kind) {
      MapStoryElementKind.character => l10n.storyCharacters,
      MapStoryElementKind.interactive => l10n.storyInteractive,
      MapStoryElementKind.zone => l10n.storyZones,
      MapStoryElementKind.map => l10n.storyMapResults,
    };

String mapBuilderStoryName(MapStoryElement element, AppLocalizations l10n) =>
    element.kind == MapStoryElementKind.map
    ? l10n.storyMapArrival(element.name)
    : element.name;

String mapBuilderStoryState(MapStoryElement element, AppLocalizations l10n) =>
    element.behaviours.isNotEmpty
    ? l10n.storyBehaviours(element.behaviours.length)
    : element.configured
    ? l10n.storyConfigured
    : l10n.storyToConfigure;
