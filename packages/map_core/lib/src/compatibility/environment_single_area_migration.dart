/// Repairs maps authored before an Environment layer was limited to one zone.
///
/// Extra zones that were never drawn on carry no authored work, so they are
/// dropped. Zones that do carry work become one layer each: the invariant is
/// one zone per layer, and a map is allowed as many layers as it needs.
///
/// Runs on raw JSON, before [EnvironmentLayerContent] is built, because that
/// constructor is where the invariant is enforced and would otherwise refuse
/// every map written under the old rule.
Map<String, dynamic> migrateEnvironmentSingleAreaMapJson(
  Map<String, dynamic> json,
) {
  final rawLayers = json['layers'];
  if (rawLayers is! List) return json;
  var changed = false;
  final layers = <Object?>[];
  for (final rawLayer in rawLayers) {
    if (rawLayer is! Map || rawLayer['runtimeType'] != 'environment') {
      layers.add(rawLayer);
      continue;
    }
    final layer = Map<String, dynamic>.from(rawLayer);
    final content = layer['content'];
    if (content is! Map) {
      layers.add(rawLayer);
      continue;
    }
    final rawAreas = content['areas'];
    if (rawAreas is! List || rawAreas.length <= 1) {
      layers.add(rawLayer);
      continue;
    }
    final authored = <Map<String, dynamic>>[];
    for (final rawArea in rawAreas) {
      if (rawArea is! Map) continue;
      final area = Map<String, dynamic>.from(rawArea);
      if (_environmentAreaCarriesWork(area)) authored.add(area);
    }
    if (authored.isEmpty) {
      // Every zone was empty: keep the first so the layer stays authorable.
      final first = rawAreas.first;
      if (first is Map) authored.add(Map<String, dynamic>.from(first));
    }
    changed = true;
    for (var index = 0; index < authored.length; index += 1) {
      final area = authored[index];
      final suffix = index == 0 ? '' : '__${area['id']}';
      layers.add(<String, dynamic>{
        ...layer,
        'id': '${layer['id']}$suffix',
        if (index > 0) 'name': '${layer['name']} — ${area['name']}',
        'content': <String, dynamic>{
          ...Map<String, dynamic>.from(content),
          'areas': <Object?>[area],
        },
      });
    }
  }
  if (!changed) return json;
  return <String, dynamic>{...json, 'layers': layers};
}

bool _environmentAreaCarriesWork(Map<String, dynamic> area) {
  final generated = area['generatedPlacementIds'];
  if (generated is List && generated.isNotEmpty) return true;
  final mask = area['mask'];
  if (mask is! Map) return false;
  final cells = mask['cells'];
  if (cells is! List) return false;
  return cells.any((cell) => cell == true);
}
