import 'dart:io';

import 'package:map_authoring/map_authoring.dart'
    show GamePackageExportProfileStore;

Future<({String locale, String? diagnostic})> readPokemonProjectLocale(
  String projectRoot,
) async {
  try {
    final profile = await GamePackageExportProfileStore(
      projectRoot: Directory(projectRoot),
    ).load();
    return (locale: profile?.defaultLocale ?? 'fr', diagnostic: null);
  } on Object {
    return (
      locale: 'fr',
      diagnostic:
          'Langue principale illisible dans le profil du jeu : '
          'noms affichés avec le repli français.',
    );
  }
}
