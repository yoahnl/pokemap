import 'package:map_core/map_core.dart';

typedef CatalogNarrativeOwner = ({String kind, String id});

final class CatalogNarrativeOwnerReferences {
  CatalogNarrativeOwnerReferences(this.owner, this.facts, this.mapElements);

  final CatalogNarrativeOwner owner;
  final Set<({String factId, String role})> facts;
  final Set<({String mapId, String elementId, String sourceKind})> mapElements;
}

abstract final class CatalogNarrativeOwnerAnalysis {
  static const fields = {
    'scenes': 'scene',
    'worldRules': 'worldRule',
    'storylines': 'storyline',
    'cinematics': 'cinematic',
  };

  static final _writes = [
    RegExp(r'\.consequence\.factId$'),
    RegExp(r'\.consequence\.factIds\[\d+\]$'),
    RegExp(r'\.interactiveCommand\.factId$'),
    RegExp(r'\.effects\[\d+\]\.targetId$'),
  ];

  static CatalogNarrativeOwnerReferences ofDefinition(
      String field, Map definition) {
    final json = Map<String, dynamic>.from(definition);
    final empty =
        ProjectManifest(name: 'owner', maps: const [], tilesets: const []);
    final project = switch (field) {
      'scenes' => empty.copyWith(scenes: [SceneAsset.fromJson(json)]),
      'worldRules' =>
        empty.copyWith(worldRules: [WorldRuleDefinition.fromJson(json)]),
      'storylines' =>
        empty.copyWith(storylines: [StorylineAsset.fromJson(json)]),
      'cinematics' =>
        empty.copyWith(cinematics: [CinematicAsset.fromJson(json)]),
      _ => throw ArgumentError.value(field, 'field'),
    };
    return _analyse((kind: fields[field]!, id: json['id'] as String), project);
  }

  static CatalogNarrativeOwnerReferences ofEvent(NarrativeEventRecord record) {
    return _analyse(
        (kind: 'event', id: record.id),
        ProjectManifest(name: 'owner', maps: const [], tilesets: const [])
            .copyWith(
                eventRegistry: NarrativeEventRegistry(
                    schemaVersion: 1,
                    mode: EventSystemMode.v2Only,
                    records: [record],
                    legacyClaims: const [])));
  }

  static String role(String path) =>
      _writes.any((pattern) => pattern.hasMatch(path)) ? 'write' : 'read';

  static CatalogNarrativeOwnerReferences _analyse(
      CatalogNarrativeOwner owner, ProjectManifest project) {
    final facts = <({String factId, String role})>{};
    final elements = <({String mapId, String elementId, String sourceKind})>{};
    for (final usage
        in buildNarrativeDependencyIndex(project: project).usages) {
      final target = usage.target;
      if (target.kind == NarrativeDependencyTargetKind.fact) {
        facts.add((factId: target.id, role: role(usage.path)));
      } else if (target.physicalMapId case final mapId?
          when target.sourceKind != 'map') {
        elements.add((
          mapId: mapId,
          elementId: target.id,
          sourceKind: target.sourceKind!
        ));
      }
    }
    return CatalogNarrativeOwnerReferences(owner, facts, elements);
  }
}
