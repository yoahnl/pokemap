import '../models/pokemon_sdk_studio_project_payload.dart';

abstract interface class PokemonSdkStudioProjectSource {
  Future<PokemonSdkStudioProjectPayload> loadProject(String projectRootPath);
}
