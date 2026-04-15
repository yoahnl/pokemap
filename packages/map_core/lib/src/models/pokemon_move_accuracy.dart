import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokemon_move_accuracy.freezed.dart';
part 'pokemon_move_accuracy.g.dart';

/// Représentation canonique de la précision d'un move.
///
/// Le lot M2 tranche explicitement contre l'ancien duo ambigu
/// `accuracy` + `accuracyText` :
/// - un move touche soit toujours ;
/// - soit il utilise une précision en pourcentage.
///
/// On garde ce type très petit volontairement :
/// - il est sérialisable ;
/// - il est lisible ;
/// - il suffit pour le futur convertisseur, le seed et le runtime loader ;
/// - il n'embarque encore aucune logique moteur.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
class PokemonMoveAccuracy with _$PokemonMoveAccuracy {
  const PokemonMoveAccuracy._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveAccuracy.percent({
    required int value,
  }) = PokemonMoveAccuracyPercent;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveAccuracy.alwaysHits() =
      PokemonMoveAccuracyAlwaysHits;

  factory PokemonMoveAccuracy.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveAccuracyFromJson(json);
}
