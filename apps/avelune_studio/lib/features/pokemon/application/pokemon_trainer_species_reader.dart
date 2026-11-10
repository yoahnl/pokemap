import 'package:map_core/map_core_domain.dart';

import '../domain/pokemon_workspace_models.dart';
import '../domain/pokemon_workspace_port.dart';

Future<PokemonSpeciesFile?> loadPokemonTrainerSpecies({
  required PokemonWorkspacePort port,
  required PokemonWorkspaceIndex index,
  required String id,
}) async {
  final summary = index.entries.where((entry) => entry.id == id).firstOrNull;
  if (summary == null) return null;
  final bundle = await port.loadSpecies(summary);
  final document = bundle.species.document;
  if (document == null || bundle.species.problem != null) return null;
  return PokemonSpeciesFile.fromJson(document);
}
