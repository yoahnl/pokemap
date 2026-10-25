import 'package:map_core/map_core.dart';

final class WorkingCatalogEntry {
  const WorkingCatalogEntry({
    required this.id,
    required this.kind,
    required this.name,
    this.description = '',
    this.tags = const [],
    this.placementContext = '',
    this.familyId = '',
    this.contactShadow,
  });

  final String id;
  final String kind;
  final String name;
  final String description;
  final List<String> tags;
  final String placementContext;
  final String familyId;
  final bool? contactShadow;
  String get identity => '$kind:$id';
  bool get supportsTags =>
      const {'element', 'character', 'smartTilePreset'}.contains(kind);
}

final class WorkingCatalogPage {
  WorkingCatalogPage({
    required this.revision,
    required Iterable<WorkingCatalogEntry> items,
    required this.total,
    this.nextCursor,
  }) : items = List.unmodifiable(items);

  final String revision;
  final List<WorkingCatalogEntry> items;
  final int total;
  final String? nextCursor;
}

final class WorkingCatalogDetail {
  const WorkingCatalogDetail({
    required this.entry,
    required this.revision,
    required this.definitions,
    this.contactShadowProjectDefault = false,
  });

  final WorkingCatalogEntry entry;
  final String revision;
  final ProjectManifest definitions;
  final bool contactShadowProjectDefault;
}

final class WorkingCatalogDraft {
  WorkingCatalogDraft({
    required this.name,
    required this.description,
    required Iterable<String> tags,
    required this.placementContext,
    this.contactShadow,
  }) : tags = List.unmodifiable(tags);

  factory WorkingCatalogDraft.fromEntry(WorkingCatalogEntry entry) =>
      WorkingCatalogDraft(
        name: entry.name,
        description: entry.description,
        tags: entry.tags,
        placementContext: entry.placementContext,
        contactShadow: entry.contactShadow,
      );

  final String name;
  final String description;
  final List<String> tags;
  final String placementContext;
  final bool? contactShadow;
  bool get valid => name.trim().isNotEmpty && description.length <= 2000;

  WorkingCatalogDraft copyWith({
    String? name,
    String? description,
    Iterable<String>? tags,
    String? placementContext,
    Object? contactShadow = _unchanged,
  }) => WorkingCatalogDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    tags: tags ?? this.tags,
    placementContext: placementContext ?? this.placementContext,
    contactShadow: identical(contactShadow, _unchanged)
        ? this.contactShadow
        : contactShadow as bool?,
  );

  bool sameValues(WorkingCatalogDraft other) =>
      contactShadow == other.contactShadow && sameMetadata(other);

  bool sameMetadata(WorkingCatalogDraft other) =>
      name == other.name &&
      description == other.description &&
      placementContext == other.placementContext &&
      tags.length == other.tags.length &&
      Iterable<int>.generate(tags.length)
          .every((index) => tags[index] == other.tags[index]);
}

const _unchanged = Object();

abstract interface class WorkingCatalogPort {
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  });

  Future<WorkingCatalogDetail> open(WorkingCatalogEntry entry);

  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry entry,
    WorkingCatalogDraft draft, {
    required String revision,
  });

  Future<void> close();
  Future<void> recover(String operationId);
}
