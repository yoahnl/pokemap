import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';

typedef PokemonExternalMediaSelection = ({
  Gen5BattleSourceBundle? gen5Bundle,
  PokemonBattleGifSelection? gifSelection,
  AvelunePokemonCry? cry,
  PokemonPngSelection? pngSelection,
});

final class PokemonExternalMediaFetch {
  const PokemonExternalMediaFetch({
    required this.session,
    this.gen5Source,
    this.gifSource,
    this.crySource,
    this.pngSource,
  });

  final ProjectSession session;
  final AveluneGen5BattleSource? gen5Source;
  final AveluneBattleGifSource? gifSource;
  final AvelunePokemonCrySource? crySource;
  final AvelunePokemonPngSource? pngSource;

  Future<PokemonExternalMediaSelection> fetch({
    required PokemonSpeciesFile species,
    required String canonicalId,
    required Map<String, dynamic>? pokemon,
    required List<String> warnings,
  }) async {
    Gen5BattleSourceBundle? gen5Bundle;
    final gen5 = gen5Source;
    if (session.storage != ProjectSessionStorage.workingCatalog) {
      warnings.add(
        'L’animation Noir/Blanc 2 nécessite un catalogue de travail.',
      );
    } else if (gen5 == null ||
        species.nationalDex < 1 ||
        species.nationalDex > 649 ||
        !species.forms.isBaseForm) {
      warnings.add(
        'L’animation Noir/Blanc 2 n’est pas disponible pour cette espèce.',
      );
    } else {
      try {
        final snapshot = await gen5.fetch(
          species: canonicalId,
          nationalDex: species.nationalDex,
        );
        if (snapshot == null) {
          warnings.add('L’animation Noir/Blanc 2 est absente de la source.');
        } else {
          gen5Bundle = gen5BattleSourceBundleFromSnapshot(snapshot);
        }
      } on Object {
        warnings.add('L’animation Noir/Blanc 2 est indisponible ou invalide.');
      }
    }
    PokemonBattleGifSelection? gifSelection;
    if (species.nationalDex >= 1 &&
        species.nationalDex <= 649 &&
        species.forms.isBaseForm &&
        gifSource == null) {
      warnings.add(
        'Les GIF de secours ne sont pas disponibles pour ce projet.',
      );
    } else if (gifSource != null &&
        species.nationalDex >= 1 &&
        species.nationalDex <= 649 &&
        species.forms.isBaseForm) {
      try {
        gifSelection = await gifSource!.fetch(
          speciesId: canonicalId,
          nationalDex: species.nationalDex,
        );
        if (gifSelection.missing.isNotEmpty) {
          warnings.add('Certains GIF de secours ne sont pas disponibles.');
        }
      } on Object {
        warnings.add('Les GIF de secours sont indisponibles ou invalides.');
      }
    }
    AvelunePokemonCry? cry;
    final cryForm = pokemon?['name'];
    if (session.storage != ProjectSessionStorage.workingCatalog ||
        crySource == null ||
        !species.forms.isBaseForm ||
        cryForm is! String) {
      warnings.add('Le cri compatible n’est pas disponible pour cet import.');
    } else {
      try {
        cry = await crySource!.fetch(speciesId: canonicalId, formId: cryForm);
        if (cry == null) warnings.add('Aucun cri WAV ou MP3 disponible.');
      } on Object {
        warnings.add('Le cri est indisponible ou invalide.');
      }
    }
    PokemonPngSelection? pngSelection;
    if (session.storage == ProjectSessionStorage.workingCatalog &&
        pngSource != null &&
        species.forms.isBaseForm &&
        cryForm is String) {
      try {
        pngSelection = await pngSource!.fetch(
          speciesId: canonicalId,
          formId: cryForm,
        );
        if (pngSelection.media.isEmpty) {
          warnings.add('Aucune image PNG disponible pour cette espèce.');
        }
      } on Object {
        warnings.add('Les images PNG sont indisponibles ou invalides.');
      }
    }
    return (
      gen5Bundle: gen5Bundle,
      gifSelection: gifSelection,
      cry: cry,
      pngSelection: pngSelection,
    );
  }
}
