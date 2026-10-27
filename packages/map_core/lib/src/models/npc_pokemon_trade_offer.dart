import 'save_data.dart';

final class NpcPokemonTradeOffer {
  NpcPokemonTradeOffer({
    required this.id,
    required this.requestedSpeciesId,
    required this.offeredPokemon,
    this.matchSelectedLevel = true,
  }) {
    if (id.trim().isEmpty ||
        requestedSpeciesId.trim().isEmpty ||
        offeredPokemon.speciesId.trim().isEmpty ||
        offeredPokemon.level < 1 ||
        offeredPokemon.level > 100) {
      throw const FormatException('Invalid NPC trade offer.');
    }
  }
  final String id;
  final String requestedSpeciesId;
  final PlayerPokemon offeredPokemon;
  final bool matchSelectedLevel;
  String get operationId => 'npc-trade:$id';

  factory NpcPokemonTradeOffer.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
      (key) => !const {
        'id',
        'requestedSpeciesId',
        'offeredPokemon',
        'matchSelectedLevel',
      }.contains(key),
    )) {
      throw const FormatException('Unknown NPC trade offer option.');
    }
    return NpcPokemonTradeOffer(
      id: json['id'] as String,
      requestedSpeciesId: json['requestedSpeciesId'] as String,
      offeredPokemon: PlayerPokemon.fromJson(
        Map<String, dynamic>.from(json['offeredPokemon'] as Map),
      ),
      matchSelectedLevel: json['matchSelectedLevel'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'requestedSpeciesId': requestedSpeciesId,
    'offeredPokemon': offeredPokemon.toJson(),
    'matchSelectedLevel': matchSelectedLevel,
  };
  @override
  bool operator ==(Object other) =>
      other is NpcPokemonTradeOffer &&
      other.id == id &&
      other.requestedSpeciesId == requestedSpeciesId &&
      other.offeredPokemon == offeredPokemon &&
      other.matchSelectedLevel == matchSelectedLevel;
  @override
  int get hashCode =>
      Object.hash(id, requestedSpeciesId, offeredPokemon, matchSelectedLevel);
}
