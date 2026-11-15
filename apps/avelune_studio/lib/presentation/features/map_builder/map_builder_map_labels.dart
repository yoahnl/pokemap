import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

extension MapBuilderMapLabels on AppLocalizations {
  String mapLibraryProblem(MapLibraryOutcome outcome) {
    final detail = outcome.detail?.trim();
    return switch (outcome.problem) {
      null => '',
      MapLibraryProblem.nameRequired => mapLibraryNameRequired,
      MapLibraryProblem.sizeInvalid => mapLibrarySizeInvalid(mapLibraryMaxSide),
      MapLibraryProblem.folderNameTaken => mapLibraryFolderNameTaken,
      MapLibraryProblem.folderNotEmpty => mapLibraryFolderNotEmpty,
      MapLibraryProblem.missing => mapLibraryMissing,
      MapLibraryProblem.publishedNotIntegrated =>
        mapLibraryPublishedNotIntegrated(detail ?? ''),
      MapLibraryProblem.refused =>
        detail == null || detail.isEmpty ? mapLibraryRefused : detail,
    };
  }

  String mapLibraryUsage(MapLibraryUsage usage) {
    final name = usage.label;
    return switch (usage.kind) {
      MapLibraryUsageKind.map =>
        name == null ? mapLibraryUsageMapUnnamed : mapLibraryUsageMap(name),
      MapLibraryUsageKind.scene =>
        name == null ? mapLibraryUsageSceneUnnamed : mapLibraryUsageScene(name),
      MapLibraryUsageKind.storyline =>
        name == null
            ? mapLibraryUsageStorylineUnnamed
            : mapLibraryUsageStoryline(name),
      MapLibraryUsageKind.worldRule =>
        name == null
            ? mapLibraryUsageWorldRuleUnnamed
            : mapLibraryUsageWorldRule(name),
      MapLibraryUsageKind.cinematic =>
        name == null
            ? mapLibraryUsageCinematicUnnamed
            : mapLibraryUsageCinematic(name),
      MapLibraryUsageKind.event => mapLibraryUsageEvent,
      MapLibraryUsageKind.newGame => mapLibraryUsageNewGame,
      MapLibraryUsageKind.regionalMap => mapLibraryUsageRegionalMap,
      MapLibraryUsageKind.other => mapLibraryUsageOther,
    };
  }

  Map<String, String> mapLibraryFolderOptions(List<ProjectMapGroup> groups) {
    final byId = {for (final group in groups) group.id: group};
    String path(ProjectMapGroup group) {
      final names = <String>[group.name];
      final seen = {group.id};
      var parent = group.parentGroupId;
      while (parent != null && seen.add(parent)) {
        final next = byId[parent];
        if (next == null) break;
        names.insert(0, next.name);
        parent = next.parentGroupId;
      }
      return names.join(' / ');
    }

    final entries = [
      for (final group in groups) MapEntry(group.id, path(group)),
    ]..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return {
      '': mapLibraryNoFolder,
      for (final entry in entries) entry.key: entry.value,
    };
  }
}
