import '../errors/application_errors.dart';
import '../models/pokedex_species_detail.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

/// Charge la fiche détail locale d'une espèce Pokédex.
///
/// On reste volontairement sobre :
/// - l'espèce elle-même est obligatoire ;
/// - learnset, évolution et média restent optionnels si leurs fichiers ne sont
///   pas encore présents dans le projet ;
/// - toute autre erreur remonte telle quelle pour ne pas masquer un vrai souci
///   de lecture JSON.
class LoadPokedexSpeciesDetailUseCase {
  const LoadPokedexSpeciesDetailUseCase(this.repository);

  final PokemonReadRepository repository;

  Future<PokedexSpeciesDetail> execute(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final species = await repository.readSpeciesById(workspace, speciesId);

    return PokedexSpeciesDetail(
      species: species,
      // Les annexes sont réellement optionnelles dans cette phase :
      // - une ref vide/blanche signifie "pas de fichier branché" ;
      // - un fichier absent reste toléré ;
      // - toute autre erreur doit continuer à remonter.
      learnset: await _readOptionalByRef(
        species.refs.learnset,
        (ref) => repository.readLearnsetById(workspace, ref),
      ),
      evolution: await _readOptionalByRef(
        species.refs.evolution,
        (ref) => repository.readEvolutionById(workspace, ref),
      ),
      media: await _readOptionalByRef(
        species.refs.media,
        (ref) => repository.readMediaById(workspace, ref),
      ),
    );
  }

  Future<T?> _readOptionalByRef<T>(
    String rawRef,
    Future<T> Function(String ref) loader,
  ) async {
    final ref = rawRef.trim();
    if (ref.isEmpty) {
      return null;
    }

    try {
      return await loader(ref);
    } on EditorNotFoundException {
      return null;
    }
  }
}
