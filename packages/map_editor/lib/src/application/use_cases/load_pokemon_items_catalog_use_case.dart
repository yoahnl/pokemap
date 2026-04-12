import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

/// Projection légère d'une entrée du catalogue local des objets.
///
/// Le lot 7 n'a pas besoin d'un système items complet. Il a seulement besoin
/// d'une vue locale lisible pour assister un champ `heldItemId` quand le
/// catalogue `items` existe déjà dans le projet.
class PokemonItemCatalogEntryView {
  const PokemonItemCatalogEntryView({
    required this.id,
    required this.name,
    this.shortDesc,
    this.aliases = const <String>[],
  });

  final String id;
  final String name;
  final String? shortDesc;
  final List<String> aliases;
}

/// État lisible du catalogue local `items` pour les surfaces auteur.
///
/// On reprend la même philosophie que pour `moves` :
/// - l'UI doit savoir si le catalogue est réellement disponible ;
/// - les entrées projetées restent simples ;
/// - une absence de catalogue ne bloque pas la saisie brute.
class PokemonItemsCatalogView {
  const PokemonItemsCatalogView({
    required this.entries,
    required this.isAvailable,
    required this.description,
    this.message,
  });

  final List<PokemonItemCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
}

/// Charge le catalogue local `items` sans créer de nouvelle stack parallèle.
///
/// Choix volontairement sobres :
/// - lecture via le repository Pokémon local déjà existant ;
/// - projection minimale `id` / `name` ;
/// - aucun enrichissement externe ;
/// - la surface auteur garde le droit de retomber honnêtement sur la saisie
///   brute si le catalogue n'est pas prêt.
class LoadPokemonItemsCatalogUseCase {
  const LoadPokemonItemsCatalogUseCase({
    required this.readRepository,
  });

  final PokemonReadRepository readRepository;

  Future<PokemonItemsCatalogView> execute(ProjectWorkspace workspace) async {
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'items');
      return PokemonItemsCatalogView(
        entries: _projectEntries(catalog),
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des objets.'
            : catalog.meta.description.trim(),
      );
    } on EditorNotFoundException catch (error) {
      return PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message: error.message,
      );
    } on EditorApplicationException catch (error) {
      return PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets illisible.',
        message: error.message,
      );
    }
  }

  List<PokemonItemCatalogEntryView> _projectEntries(
      PokemonCatalogFile catalog) {
    final entries = catalog.entries
        .map(_projectEntry)
        .whereType<PokemonItemCatalogEntryView>()
        .toList(growable: false)
      ..sort((left, right) {
        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  PokemonItemCatalogEntryView? _projectEntry(Map<String, dynamic> entry) {
    final id = (entry['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final explicitName = (entry['name'] as String?)?.trim();
    final localizedNames = (entry['names'] as Map?)?.cast<String, dynamic>();
    final fallbackName = (localizedNames?['en'] as String?)?.trim();
    final aliases = <String>{
      for (final value in localizedNames?.values ?? const <Object?>[])
        if (value is String && value.trim().isNotEmpty) value.trim(),
      for (final value in (entry['aliases'] as List?) ?? const <Object?>[])
        if (value is String && value.trim().isNotEmpty) value.trim(),
    }.toList(growable: false);

    final shortDesc = (entry['shortDesc'] as String?)?.trim() ??
        (entry['description'] as String?)?.trim();

    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;

    return PokemonItemCatalogEntryView(
      id: id,
      name: name?.isNotEmpty == true ? name! : id,
      shortDesc: shortDesc?.isEmpty == true ? null : shortDesc,
      aliases: aliases,
    );
  }
}
