import 'package:map_core/map_core.dart';

PokemonLearnsetFile projectNativeFieldMachineLearnset(
    PokemonLearnsetFile source) {
  final fieldMoves =
      FieldAbility.values.map((ability) => ability.moveId).toSet();
  final existing = source.hm.map((entry) => entry.moveId).toSet();
  final extra = source.tm
      .where((entry) =>
          fieldMoves.contains(entry.moveId) && existing.add(entry.moveId))
      .toList();
  if (extra.isEmpty) return source;
  return PokemonLearnsetFile.fromJson({
    ...source.toJson(),
    'hm': [
      ...source.hm.map((entry) => entry.toJson()),
      ...extra.map((entry) => entry.toJson())
    ]
  });
}
