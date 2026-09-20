import 'package:map_core/map_core_domain.dart';
import 'event_labels.dart';

class EventLegacyEntry {
  const EventLegacyEntry({
    required this.key,
    required this.name,
    required this.mapId,
    required this.detail,
  });
  final String key, name;
  final String? mapId;
  final EventLegacyDetail Function() detail;
}

class EventLegacyDetail {
  const EventLegacyDetail({
    required this.source,
    required this.lines,
    required this.diagnostics,
  });
  final NarrativeEventSourceRef? source;
  final List<String> lines, diagnostics;
}

class EventLegacyCatalog {
  EventLegacyCatalog(this.project, List<MapData> maps) : maps = List.of(maps) {
    final registry =
        project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [],
          legacyClaims: [],
        );
    final claimIndex = buildValidatedLegacyClaimIndex(registry);
    bool represented(
      LegacySourceRef provenance,
      String Function() fingerprint,
    ) {
      final claim = claimIndex.validByProvenance[provenance];
      return claim != null &&
          claim.members.any(
            (member) =>
                member.provenance == provenance &&
                member.sourceFingerprint == fingerprint(),
          ) &&
          claim.targetEventIds.any(
            (id) => registry.records.any((r) => r.id == id),
          );
    }

    entries = [
      for (final map in maps)
        for (final event in map.events)
          if (!represented(
            LegacySourceRef.mapEvent(map.id, event.id),
            () => computeMapEventSourceFingerprint(mapId: map.id, event: event),
          ))
            EventLegacyEntry(
              key: 'map:${map.id}:${event.id}',
              name: event.title.isEmpty ? event.id : event.title,
              mapId: map.id,
              detail: () {
                final projection = projectLegacyMapEventReadOnly(
                  mapId: map.id,
                  map: map,
                  event: event,
                  claimIndex: claimIndex,
                );
                return EventLegacyDetail(
                  source: projection.confirmedSource,
                  lines: [
                    'Événement historique sur ${map.name}',
                    'Position : ${event.position.x}, ${event.position.y}',
                    '${projection.pages.length} pages conservées',
                    for (final page in projection.pages) ...[
                      'Page ${page.pageNumber + 1}${page.isDisabled ? ' · désactivée' : ''}${page.isHidden ? ' · masquée' : ''}',
                      if (page.message != null) page.message!,
                      if (page.sceneId != null)
                        'Scène liée : ${_sceneName(page.sceneId!)}',
                      if (page.condition != null)
                        'Cette page possède une condition historique.',
                      if (page.script != null)
                        'Cette page possède un script historique.',
                    ],
                  ],
                  diagnostics: projection.diagnostics
                      .map((d) => d.message)
                      .toList(),
                );
              },
            ),
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes.where(isLegacyScenarioSourceNode))
          if (!represented(
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id),
            () => computeScenarioSourceFingerprint(
              scenarioId: scenario.id,
              nodeId: node.id,
              scenario: scenario,
            ),
          ))
            EventLegacyEntry(
              key: 'scenario:${scenario.id}:${node.id}',
              name: '${scenario.name} · ${node.title}',
              mapId: node.binding.mapId,
              detail: () {
                final projection = projectLegacyScenarioSourceReadOnly(
                  scenario: scenario,
                  node: node,
                  scenes: project.scenes,
                  claimIndex: claimIndex,
                );
                return EventLegacyDetail(
                  source: projection.source,
                  lines: [
                    'Source de scénario historique : ${scenario.name}',
                    'Entrée : ${node.title}',
                    if (projection.source != null)
                      eventKindLabel(projection.source!.kind),
                    '${projection.actions.length} actions et ${projection.conditions.length} conditions conservées',
                    if (projection.sceneCandidateId != null)
                      'Scène référencée : ${_sceneName(projection.sceneCandidateId!)}',
                    'Le scénario complet conserve ses embranchements et ses effets.',
                  ],
                  diagnostics: projection.diagnostics
                      .map((d) => d.message)
                      .toList(),
                );
              },
            ),
    ];
  }
  final ProjectManifest project;
  final List<MapData> maps;
  late final List<EventLegacyEntry> entries;

  bool matches(ProjectManifest value, List<MapData> currentMaps) =>
      _sameMembers(project.scenarios, value.scenarios) &&
      _sameMembers(project.scenes, value.scenes) &&
      project.eventRegistry == value.eventRegistry &&
      maps.length == currentMaps.length &&
      Iterable<int>.generate(
        maps.length,
      ).every((i) => identical(maps[i], currentMaps[i]));

  String _sceneName(String id) =>
      project.scenes.where((scene) => scene.id == id).firstOrNull?.name ?? id;

  bool _sameMembers<T>(List<T> first, List<T> second) =>
      first.length == second.length &&
      Iterable<int>.generate(
        first.length,
      ).every((index) => identical(first[index], second[index]));
}
