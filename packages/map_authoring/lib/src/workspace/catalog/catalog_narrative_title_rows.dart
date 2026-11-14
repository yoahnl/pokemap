import 'dart:convert';

import 'package:map_core/map_core.dart';

abstract final class CatalogNarrativeTitleRows {
  static const pageSize = 128;
  static const eventKind = 'narrativeEvents';
  static const fieldKinds = {
    'scenes',
    'dialogues',
    'facts',
    'worldRules',
    'storylines',
    'cinematics',
    'presentationCinematics',
  };
  static const kinds = {...fieldKinds, eventKind};

  static final markerKey = CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, 'narrativeTitleIndex');

  static CatalogDefinitionKey pageKey(String kind, int page) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['narrativeTitles', kind, page]));

  static int pageCount(int count) => (count + pageSize - 1) ~/ pageSize;

  static List<CatalogDefinitionUnit> rows(
          Map<String, List<Map<String, Object?>>> entries) =>
      [
        markerUnit({
          for (final kind in kinds) kind: {'count': entries[kind]!.length}
        }),
        for (final kind in kinds)
          for (var page = 0; page < pageCount(entries[kind]!.length); page++)
            pageUnit(
                kind,
                page,
                entries[kind]!.sublist(
                    page * pageSize,
                    (page * pageSize +
                        pageLength(entries[kind]!.length, page)))),
      ];

  static CatalogDefinitionUnit markerUnit(
          Map<String, Map<String, Object?>> states) =>
      CatalogDefinitionUnit(key: markerKey, payload: {
        'id': markerKey.id,
        'schemaVersion': 1,
        'pageSize': pageSize,
        'kinds': {for (final kind in kinds) kind: states[kind]},
      });

  static CatalogDefinitionUnit pageUnit(
          String kind, int page, List<Map<String, Object?>> entries) =>
      CatalogDefinitionUnit(key: pageKey(kind, page), payload: {
        'id': pageKey(kind, page).id,
        'schemaVersion': 1,
        'kind': kind,
        'page': page,
        'entries': entries,
      });

  static Map<String, Map<String, Object?>>? kindStates(
      CatalogDefinitionUnit? marker) {
    if (marker == null) return null;
    final payload = marker.payload;
    final states = payload['kinds'];
    if (payload['schemaVersion'] != 1 ||
        payload['pageSize'] != pageSize ||
        states is! Map ||
        states.length != kinds.length ||
        !kinds.every((kind) => states[kind] is Map)) {
      return null;
    }
    return {
      for (final kind in kinds)
        kind: Map<String, Object?>.from(states[kind] as Map)
    };
  }

  static int storedPages(Map<String, Object?> state) {
    final count = state['count'];
    final pages = count is int ? pageCount(count) : state['pageCount'];
    return pages is int && pages >= 0 ? pages : 0;
  }

  static List<Map<String, Object?>> pageEntries(
      CatalogDefinitionUnit? unit, String kind, int page,
      {required int expectedLength}) {
    final payload = unit?.payload;
    final entries = payload?['entries'];
    if (payload == null ||
        unit!.key != pageKey(kind, page) ||
        payload['schemaVersion'] != 1 ||
        payload['kind'] != kind ||
        payload['page'] != page ||
        entries is! List ||
        entries.length != expectedLength) {
      _invalid('page_invalid');
    }
    return [
      for (final entry in entries)
        if (entry is Map &&
            entry['id'] is String &&
            entry['title'] is String &&
            entry['tags'] is List &&
            (entry['category'] == null || entry['category'] is String))
          Map<String, Object?>.from(entry)
        else
          _invalid('entry_invalid'),
    ];
  }

  static (String, int)? definitionLocation(CatalogDefinitionKey key) {
    if (key.kind != CatalogDefinitionKind.catalogMetadata ||
        !key.id.startsWith('["projectDefinition",')) {
      return null;
    }
    final parts = jsonDecode(key.id);
    if (parts is! List ||
        parts.length != 3 ||
        parts[1] is! String ||
        parts[2] is! int ||
        !fieldKinds.contains(parts[1])) {
      return null;
    }
    return (parts[1] as String, parts[2] as int);
  }

  static Map<String, Object?> definitionEntry(
      CatalogDefinitionUnit unit, String field, int position) {
    final value = unit.payload['value'];
    final definition = value is Map ? value['definition'] : null;
    if (unit.payload['position'] != position ||
        value is! Map ||
        value['field'] != field ||
        definition is! Map) {
      _invalid('definition_invalid');
    }
    return _entry(
        definition['id'],
        definition[switch (field) {
          'scenes' || 'dialogues' => 'name',
          'facts' || 'worldRules' => 'label',
          _ => 'title',
        }],
        definition['tags'],
        switch (field) {
          'facts' => definition['category'],
          'storylines' => definition['type'],
          _ => null,
        });
  }

  static List<Map<String, Object?>> eventEntries(
          Map<String, Object?>? registry) =>
      [
        for (final raw in registry?['records'] as List? ?? const [])
          switch (NarrativeEventRecord.fromJson(raw)) {
            final record => _entry(
                record.id,
                record.definitionOrNull?.name ?? record.draftOrNull?.name,
                null,
                null),
          },
      ];

  static Map<String, Object?> _entry(
      Object? id, Object? title, Object? tags, Object? category) {
    if (id is! String || id.isEmpty) _invalid('identity_invalid');
    return {
      'id': id,
      'title': title is String ? title : '',
      'tags': [
        if (tags is List)
          for (final tag in tags)
            if (tag is String) tag
      ],
      if (category is String && category.isNotEmpty) 'category': category,
    };
  }

  static int pageLength(int count, int page) =>
      count - page * pageSize < pageSize ? count - page * pageSize : pageSize;

  static Never _invalid(String code) =>
      throw FormatException('catalog.narrative_titles.$code');
}
