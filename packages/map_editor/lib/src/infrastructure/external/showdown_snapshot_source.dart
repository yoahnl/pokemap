import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart' as authoring;

import 'http_pokemon_external_transport.dart';

class ShowdownSnapshotSource extends authoring.ShowdownSnapshotSource {
  ShowdownSnapshotSource({
    required http.Client client,
    super.baseUri,
    super.requestTimeout,
    super.userAgent,
  }) : super(client: HttpPokemonExternalTransport(client));
}
