import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  PokemonCompanionOwnership resolve({
    String owner = 'bulbasaur',
    String reference = 'custom-learn',
    String declared = 'custom-learn',
    Set<String> known = const {'bulbasaur', 'ivysaur'},
    Set<String> owners = const {'bulbasaur'},
    bool media = false,
    String base = '',
    bool isBase = true,
  }) => resolvePokemonCompanionOwnership(
    ownerSpeciesId: owner,
    reference: reference,
    declaredSpeciesId: declared,
    knownSpeciesIds: known,
    referencingSpeciesIds: owners,
    media: media,
    ownerBaseFormId: base,
    ownerIsBaseForm: isBase,
  );

  test('standard identity and unique legacy alias belong to the owner', () {
    expect(resolve(declared: 'bulbasaur'), PokemonCompanionOwnership.owned);
    expect(resolve(), PokemonCompanionOwnership.owned);
  });

  test('legacy alias shared by two species stays ambiguous', () {
    expect(
      resolve(owners: {'bulbasaur', 'ivysaur'}),
      PokemonCompanionOwnership.ambiguous,
    );
    expect(resolve(declared: 'ivysaur'), PokemonCompanionOwnership.foreign);
    expect(
      resolve(known: {'bulbasaur', 'custom-learn'}),
      PokemonCompanionOwnership.foreign,
    );
  });

  test('media base and form may share one document', () {
    expect(
      resolve(
        owner: 'ivysaur',
        reference: 'shared-media',
        declared: 'bulbasaur',
        owners: {'bulbasaur', 'ivysaur'},
        media: true,
        base: 'bulbasaur',
        isBase: false,
      ),
      PokemonCompanionOwnership.owned,
    );
    expect(
      resolve(
        owner: 'ivysaur',
        reference: 'shared-media',
        declared: 'bulbasaur',
        owners: {'bulbasaur', 'ivysaur'},
        base: 'bulbasaur',
        isBase: false,
      ),
      PokemonCompanionOwnership.foreign,
    );
  });
}
