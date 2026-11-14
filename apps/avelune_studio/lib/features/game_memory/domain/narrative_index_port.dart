import 'package:map_core/map_core_domain.dart';

enum NarrativeTitleKind {
  facts('facts'),
  worldRules('worldRules'),
  scenes('scenes'),
  storylines('storylines'),
  cinematics('cinematics'),
  events('narrativeEvents');

  const NarrativeTitleKind(this.wireName);

  final String wireName;
}

enum NarrativeOwnerKind {
  scene(NarrativeTitleKind.scenes),
  worldRule(NarrativeTitleKind.worldRules),
  storyline(NarrativeTitleKind.storylines),
  cinematic(NarrativeTitleKind.cinematics),
  event(NarrativeTitleKind.events);

  const NarrativeOwnerKind(this.titles);

  final NarrativeTitleKind titles;

  static NarrativeOwnerKind? fromWireName(String value) =>
      values.where((kind) => kind.name == value).firstOrNull;
}

final class NarrativeTitle {
  const NarrativeTitle({required this.id, required this.title, this.category});

  final String id;
  final String title;
  final String? category;
}

enum NarrativeFactRole { read, write }

final class NarrativeOwner {
  const NarrativeOwner({required this.kind, required this.id, this.role});

  final NarrativeOwnerKind kind;
  final String id;
  final NarrativeFactRole? role;

  @override
  bool operator ==(Object other) =>
      other is NarrativeOwner &&
      other.kind == kind &&
      other.id == id &&
      other.role == role;

  @override
  int get hashCode => Object.hash(kind, id, role);
}

final class NarrativeUsages {
  NarrativeUsages({
    required List<NarrativeOwner> owners,
    required List<String> notCovered,
  }) : owners = List.unmodifiable(owners),
       notCovered = List.unmodifiable(notCovered);

  final List<NarrativeOwner> owners;
  final List<String> notCovered;

  Iterable<NarrativeOwner> withRole(NarrativeFactRole role) =>
      owners.where((owner) => owner.role == role);
}

final class NarrativeIndexPreparationRequired implements Exception {
  const NarrativeIndexPreparationRequired(this.scope);

  final String scope;

  @override
  String toString() => 'NarrativeIndexPreparationRequired($scope)';
}

final class NarrativeIndexUnavailable implements Exception {
  const NarrativeIndexUnavailable();

  @override
  String toString() => 'NarrativeIndexUnavailable';
}

abstract interface class NarrativeIndexPort {
  Future<List<NarrativeTitle>> titles(NarrativeTitleKind kind);

  Future<List<NarrativeFactDefinition>> facts(List<String> ids);

  Future<Map<String, NarrativeUsages>> factUsers(List<String> factIds);

  Future<NarrativeUsages> elementOwners(String mapId, String elementId);

  Future<List<WorldRuleDefinition>> worldRules();
}
