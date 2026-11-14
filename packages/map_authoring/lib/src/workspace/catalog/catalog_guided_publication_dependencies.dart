part of 'catalog_workshop_selection.dart';

List<Map<String, Object?>> _guidedRuleDependencies(
    Map<String, Object?> parameters) {
  final rules = parameters['worldRules'];
  if (rules is! List) return const [];
  return [
    for (final rule in rules.whereType<Map>())
      if (rule['source'] case {'sourceId': final String id})
        {'eventId': id, 'factId': id},
  ];
}
