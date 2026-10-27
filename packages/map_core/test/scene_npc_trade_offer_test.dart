import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final value = <String, dynamic>{
    'kind': 'openPartyTrade',
    'npcOffer': {
      'id': 'village-trade',
      'requestedSpeciesId': 'bellsprout',
      'offeredPokemon': {
        'speciesId': 'onix',
        'natureId': 'hasty',
        'abilityId': 'rock_head',
        'nickname': 'ROCKY',
      },
      'matchSelectedLevel': true,
    },
  };
  test('NPC offer survives the canonical interactive command boundary', () {
    final command = SceneInteractiveCommand.fromJson(value);
    final encoded = command.toJson();
    expect(encoded['npcOffer'], isNotNull);
    expect(SceneInteractiveCommand.fromJson(encoded), command);
    expect(command.outputPortIds, ['completed', 'cancelled']);
  });
  test('existing party trade bytes and outcomes remain unchanged', () {
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'openPartyTrade',
    });
    expect(command.toJson(), {'kind': 'openPartyTrade'});
  });
  test('guided NPC factory owns a distinct authoring contract on the shared trade wire', () {
    final command = SceneInteractiveCommand.openNpcTrade(
      npcOffer: NpcPokemonTradeOffer.fromJson(Map<String, dynamic>.from(value['npcOffer'] as Map)),
    );
    expect(NarrativeCommandIds.forInteractiveCommand(command), NarrativeCommandIds.openNpcTrade);
    expect(NarrativeCommandCatalog.canonical().byId(NarrativeCommandIds.openNpcTrade)!.wireId,
      'SceneInteractiveCommand.openNpcTrade');
    expect(command.toJson()['kind'], 'openPartyTrade');
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
  });
  for (final key in ['id', 'requestedSpeciesId']) {
    test('invalid NPC offer $key fails before execution', () {
      final offer = Map<String, dynamic>.from(value['npcOffer'] as Map);
      offer[key] = '';
      expect(
        () => SceneInteractiveCommand.fromJson({...value, 'npcOffer': offer}),
        throwsFormatException,
      );
    });
  }
}
