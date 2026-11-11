import '../domain/pokemon_workspace_models.dart';

final class PokemonFormLinkProjection {
  PokemonFormLinkProjection({
    required this.formId,
    required Iterable<PokemonSpeciesSummary> matches,
  }) : matches = List.unmodifiable(matches);

  final String formId;
  final List<PokemonSpeciesSummary> matches;
  PokemonSpeciesSummary? get resolved =>
      matches.length == 1 ? matches.single : null;
}

class PokemonDocumentEditing {
  static List<String> parseFormLinks(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  static List<PokemonFormLinkProjection> formLinks({
    required Iterable<PokemonSpeciesSummary> entries,
    required Map<String, dynamic> forms,
    required String? ownerId,
  }) {
    final related = siblings(entries: entries, forms: forms, ownerId: ownerId);
    return List.unmodifiable([
      for (final formId in List<String>.from(
        forms['otherForms'] as List? ?? [],
      ))
        PokemonFormLinkProjection(
          formId: formId,
          matches: related.where((entry) => entry.formId == formId),
        ),
    ]);
  }

  static List<PokemonSpeciesSummary> formCandidates({
    required Iterable<PokemonSpeciesSummary> entries,
    required Map<String, dynamic> forms,
    required String? ownerId,
    required String query,
  }) {
    final linked = List<String>.from(forms['otherForms'] as List? ?? []);
    final needle = query.trim().toLowerCase();
    return [
      for (final entry in siblings(
        entries: entries,
        forms: forms,
        ownerId: ownerId,
      ))
        if (!linked.contains(entry.formId) && matchesForm(entry, needle)) entry,
    ];
  }

  static Object? read(Map<String, dynamic> data, List<String> path) {
    Object? value = data;
    for (final segment in path) {
      if (value is! Map) return null;
      value = value[segment];
    }
    return value;
  }

  static void write(
    Map<String, dynamic> json,
    List<String> path,
    Object? value,
  ) {
    var current = json;
    for (final segment in path.take(path.length - 1)) {
      final next = current[segment];
      if (next is Map<String, dynamic>) {
        current = next;
      } else {
        final created = <String, dynamic>{};
        current[segment] = created;
        current = created;
      }
    }
    current[path.last] = value;
  }

  static void setType(Map<String, dynamic> json, int position, String value) {
    final typing = Map<String, dynamic>.from(json['typing'] as Map? ?? {});
    final types = List<String>.from(typing['types'] as List? ?? []);
    if (position == 0) {
      if (types.isEmpty) {
        types.add(value);
      } else {
        types[0] = value;
      }
    } else if (value.isEmpty) {
      if (types.length > 1) types.removeAt(1);
    } else if (types.length > 1) {
      types[1] = value;
    } else {
      types.add(value);
    }
    typing['types'] = types.where((type) => type.isNotEmpty).toSet().toList();
    json['typing'] = typing;
  }

  static List<PokemonSpeciesSummary> siblings({
    required Iterable<PokemonSpeciesSummary> entries,
    required Map<String, dynamic> forms,
    required String? ownerId,
  }) {
    final currentFormId = '${forms['formId'] ?? ''}'.trim();
    final group = forms['isBaseForm'] == true
        ? ownerId
        : '${forms['baseFormId'] ?? ''}'.trim();
    if (group == null || group.isEmpty) return const [];
    return [
      for (final entry in entries)
        if (entry.id != ownerId &&
            entry.formId.isNotEmpty &&
            entry.formId != currentFormId &&
            (entry.isBaseForm ? entry.id : entry.baseFormId.trim()) == group)
          entry,
    ];
  }

  static bool matchesForm(PokemonSpeciesSummary entry, String needle) =>
      needle.isEmpty ||
      entry.name.toLowerCase().contains(needle) ||
      entry.id.toLowerCase().contains(needle) ||
      entry.formId.toLowerCase().contains(needle);

  static List<String> addForm(Map<String, dynamic> forms, String formId) {
    final current = List<String>.from(forms['otherForms'] as List? ?? []);
    return current.contains(formId) ? current : [...current, formId];
  }

  static List<String> removeForm(Map<String, dynamic> forms, int index) {
    final current = List<String>.from(forms['otherForms'] as List? ?? []);
    if (index >= current.length) return current;
    current.removeAt(index);
    return current;
  }

  static void setForms(Map<String, dynamic> json, List<String> otherForms) {
    final forms = Map<String, dynamic>.from(json['forms'] as Map? ?? {});
    forms['otherForms'] = otherForms;
    json['forms'] = forms;
  }

  static void removeEvolution(Map<String, dynamic> json, int index) {
    final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
    entries.removeAt(index);
    json['evolutions'] = entries;
  }

  static void addEvolution(Map<String, dynamic> json, String target) {
    final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
    entries.add(<String, dynamic>{
      'targetSpeciesId': target,
      'method': 'level',
      'conditionText': <String, String>{},
    });
    json['evolutions'] = entries;
  }

  static void editEvolution(
    Map<String, dynamic> json,
    int index,
    String key,
    Object? change,
  ) {
    final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
    final current = Map<String, dynamic>.from(entries[index] as Map);
    current[key] = change;
    entries[index] = current;
    json['evolutions'] = entries;
  }

  static void editEvolutionCondition(
    Map<String, dynamic> json,
    int index,
    String language,
    String text,
  ) {
    final entries = json['evolutions'] as List;
    final entry = entries[index] as Map;
    final conditions = Map<String, dynamic>.from(
      entry['conditionText'] as Map? ?? {},
    );
    conditions[language] = text;
    editEvolution(json, index, 'conditionText', conditions);
  }
}

String? pokemonOptionalChoice(String value) => value.isEmpty ? null : value;

Object? pokemonDocumentNumberInput(String text) =>
    text.isEmpty ? null : int.tryParse(text) ?? text;
