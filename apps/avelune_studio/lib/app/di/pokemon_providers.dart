import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

final pokemonPortProvider = Provider.autoDispose
    .family<PokemonWorkspacePort, ProjectSession>(
      (ref, session) => throw StateError('Pokemon port must be configured'),
    );

final pokemonJsonPickerProvider = Provider<Future<String?> Function()>(
  (ref) => throw StateError('Pokemon JSON picker must be configured'),
);

final pokemonPngPickerProvider = Provider<Future<String?> Function()>(
  (ref) => throw StateError('Pokemon PNG picker must be configured'),
);
