# Phase 11A Mini-Fix Report

## 1. Résumé exécutif honnête

Le mini-fix corrige un défaut réel du pipeline externe 11A : `media.json` pouvait référencer des assets locaux absents, parce que le stub média était écrit avant la résolution réelle des téléchargements.

Le pipeline conserve son contrat fonctionnel :
- `species` bloquant ;
- `learnset` best effort non bloquant ;
- `evolution` best effort non bloquant ;
- `media/images/cries` best effort non bloquant.

Mais après ce mini-fix, le `PokemonMediaFile` persisté est reconstruit depuis l’état réel du disque à la fin de l’import. Toute ref locale absente est supprimée avant écriture.

Le report du mini-fix a aussi été créé réellement et sa présence est prouvée par `git status --short` et `git ls-files --others --exclude-standard`.

## 2. Bugs corrigés exactement

### BUG A — Références média fantômes

Corrigé. Le `media.json` final n’est plus écrit à partir du stub optimiste.

Règle finale implémentée :
- un chemin local est gardé seulement si le fichier existe réellement à la fin de l’import ;
- cela vaut pour `portrait`, `frontStatic`, `backStatic`, `frontShinyStatic`, `backShinyStatic`, `icon`, `party`, `overworld`, `cry` ;
- la même règle a été appliquée aussi aux sheets d’animation pour éviter d’autres refs fantômes du même type.

### BUG B — Preuve réelle du report

Corrigé. Le report `reports/phase-11a-mini-fix-report.md` existe réellement et sa présence est montrée dans les preuves git finales.

## 3. Périmètre inclus

- correction chirurgicale du pipeline externe 11A dans le use case existant ;
- renforcement des tests ciblés de cohérence média ;
- génération du report mini-fix avec preuves git réelles.

## 4. Périmètre exclu

- aucune ouverture de la phase 11B ;
- aucun batch produit ;
- aucun cache disque ;
- aucun nouveau port externe ;
- aucun nouveau use case externe parallèle ;
- aucune refonte UI ;
- aucune modification de `project.json` ;
- aucun chantier moves catalog ;
- aucun parseur `abilities.js` ;
- aucun GIF autorisé ;
- aucune URL distante persistée dans les JSON locaux.

## 5. Sub-agents utilisés et décisions retenues

- Audit contradictoire cohérence média : a confirmé que le stub média était écrit trop tôt et que `icon`, `party`, `overworld` et les animations devenaient des refs fantômes garanties dans le flux 11A actuel. Décision retenue : conserver le stub seulement comme plan de destinations, puis reconstruire le `PokemonMediaFile` final depuis l’état réel du disque.
- Matrice de tests : a confirmé que la couverture existante ne prouvait pas le mini-fix. Décision retenue : ajouter les cas d’échec partiel, tout échec média, skipExisting asset binaire, overwriteExisting avec redownload raté, GIF refusé, cry cohérent, et `project.json` inchangé.
- Audit intégrité du report / preuve git : a confirmé que le report n’existait pas au départ et que la preuve minimale fiable devait inclure `git status --short` et `git ls-files --others --exclude-standard`. Décision retenue : capturer explicitement ces deux sorties dans ce report.

## 6. Design retenu

Le design retenu est volontairement minimal et reste dans le pipeline 11A existant.

1. Le stub média est encore généré, mais il ne sert plus qu’à :
   - fournir les chemins locaux canoniques ;
   - produire les candidats de téléchargement ;
   - garder la preview stable.

2. Les artefacts JSON non média (`species`, `learnset`, `evolution`) sont écrits avant la résolution des assets.

3. Les assets média / cries sont résolus en best effort.

4. Le `PokemonMediaFile` final est reconstruit depuis le disque avec une seule règle :
   - si le fichier n’existe pas à la fin, la ref n’est pas persistée.

5. Le `media.json` n’est écrit qu’après cette résolution finale, et uniquement si la merge policy prévoit réellement un write (`create` / `overwrite`).

Cette approche évite :
- un second pipeline ;
- une refonte des modèles ;
- une logique métier dans l’UI ;
- une dépendance à un validateur ultérieur pour nettoyer les ghosts.

## 7. Liste exacte des fichiers touchés

### Modifiés

- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

### Créés

- `reports/phase-11a-mini-fix-report.md`

### Supprimés

- aucun

## 8. Justification fichier par fichier

- `import_external_pokemon_use_cases.dart` : correction de l’orchestration pour supprimer les refs fantômes, ajout d’une reconstruction finale du `PokemonMediaFile` depuis le disque, renforcement des warnings sur source absente / GIF / type incompatible / download raté.
- `import_external_pokemon_use_cases_test.dart` : ajout de la matrice de cas limites qui prouve la cohérence `media.json` ↔ disque réel et la non-régression de `project.json`.
- `reports/phase-11a-mini-fix-report.md` : report du mini-fix, avec preuve git explicite de son existence.

## 9. Commandes réellement exécutées

Audit lecture :

```bash
find packages/map_editor -name AGENTS.md -print
git status --short -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-mini-fix-report.md
sed -n "1,260p" packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n "260,620p" packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n "620,980p" packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n "980,1180p" packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n "1,620p" packages/map_editor/test/import_external_pokemon_use_cases_test.dart
sed -n "620,980p" packages/map_editor/test/import_external_pokemon_use_cases_test.dart
sed -n "702,860p" packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n "1,220p" packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart
```

Validation :

```bash
dart format packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_external_pokemon_use_cases.dart test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart
git status --short -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-mini-fix-report.md
git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-mini-fix-report.md
git ls-files --others --exclude-standard -- reports/phase-11a-mini-fix-report.md
```

## 10. Résultats réels

- `dart format` : `Formatted 2 files (2 changed) in 0.02 seconds.`
- `flutter analyze --no-pub ...` : `No issues found! (ran in 1.6s)`
- `flutter test test/import_external_pokemon_use_cases_test.dart` : `00:04 +17: All tests passed!`

## 11. Incidents rencontrés

- Aucun incident bloquant pendant ce mini-fix.
- Le point important confirmé par l’audit était un vrai défaut d’orchestration, pas un simple manque de tests.

## 12. État git utile final

### `git status --short`

```text
 M packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
?? reports/phase-11a-mini-fix-report.md
```

### `git diff --stat`

```text
 .../import_external_pokemon_use_cases.dart         | 251 ++++++++++++++++++++-
 .../import_external_pokemon_use_cases_test.dart    | 192 ++++++++++++++++
 2 files changed, 431 insertions(+), 12 deletions(-)
```

### `git ls-files --others --exclude-standard` pour le report

```text
reports/phase-11a-mini-fix-report.md
```

## 13. Limites restantes

- Le mini-fix ne nettoie pas rétroactivement d’anciens `media.json` déjà présents et potentiellement incohérents si la merge policy sur le fichier média est `skipExisting`. Ce point a été volontairement laissé hors scope pour rester chirurgical et ne pas rouvrir une logique de migration plus large.
- Aucun travail n’a été fait sur le batch produit, le cache disque, les catalogues moves ou une UI supplémentaire.

## 14. Checklist finale

- [x] aucun `PokemonMediaFile` écrit par l’import externe ne peut référencer un asset local absent à la fin
- [x] la cohérence vaut aussi pour le cry
- [x] les tests ciblés prouvent les cas de succès, d’échec, de skip et d’overwrite utiles
- [x] `project.json` reste inchangé
- [x] aucune nouvelle architecture parallèle n’a été créée
- [x] le report existe réellement et sa présence est prouvée par les commandes git finales
- [x] les fichiers manuels touchés sont massivement commentés

## 15. Contenu complet de TOUS les fichiers texte modifiés/créés

### `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

```dart
import 'dart:async';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokeapi_pokemon_evolution_converter.dart';
import '../services/pokeapi_pokemon_learnset_converter.dart';
import '../services/pokeapi_pokemon_species_enricher.dart';
import '../services/pokemon_media_stub_generator.dart';
import '../services/pokemon_project_data_reader.dart';
import '../services/showdown_pokemon_species_converter.dart';

/// Politique minimale de gestion des fichiers déjà présents dans le workspace.
///
/// On garde exactement trois comportements, parce que c'est le minimum
/// raisonnable demandé pour rendre l'import exploitable sans le transformer en
/// framework de synchronisation :
/// - `failOnConflict` : aucun artefact n'est écrit si au moins une cible existe ;
/// - `skipExisting` : les cibles existantes sont laissées intactes ;
/// - `overwriteExisting` : les cibles existantes sont remplacées explicitement.
enum PokemonExternalImportMergePolicy {
  failOnConflict,
  skipExisting,
  overwriteExisting,
}

/// Type d'artefact local produit par un import externe d'espèce.
///
/// L'ordre de déclaration est aussi l'ordre de reporting utilisé par les
/// résultats, pour garder des sorties lisibles et stables.
enum PokemonExternalImportArtifactKind {
  species,
  learnset,
  evolution,
  media,
}

/// Action retenue pour un artefact donné.
///
/// On reste volontairement sur les quatre états réellement utiles au lot :
/// - créer ;
/// - skip ;
/// - overwrite ;
/// - signaler un conflit.
enum PokemonExternalImportArtifactAction {
  create,
  skip,
  overwrite,
  conflict,
}

/// Résultat détaillé pour un artefact local.
///
/// Chaque artefact expose :
/// - son type ;
/// - le chemin relatif ciblé ;
/// - l'action retenue par la merge policy ;
/// - si un fichier existait déjà ;
/// - un message optionnel si une explication locale aide la review.
class PokemonExternalImportArtifactResult {
  const PokemonExternalImportArtifactResult({
    required this.kind,
    required this.relativePath,
    required this.action,
    required this.existedBefore,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final PokemonExternalImportArtifactAction action;
  final bool existedBefore;
  final String? message;
}

/// Disponibilité d'un bloc de données avant import.
///
/// Ce modèle sert à la preview applicative :
/// - il reste volontairement lisible pour le wizard ;
/// - il ne confond pas "artefact source trouvé" et "fichier local écrit" ;
/// - il permet de montrer honnêtement les morceaux best-effort.
class PokemonExternalImportPreviewArtifact {
  const PokemonExternalImportPreviewArtifact({
    required this.label,
    required this.isAvailable,
    this.message,
  });

  final String label;
  final bool isAvailable;
  final String? message;
}

/// Preview applicative d'un import externe.
///
/// Cette preview est produite par le `dryRun` du use case existant.
/// On évite ainsi une seconde logique d'aperçu parallèle dans les providers ou
/// dans l'UI.
class PokemonExternalImportPreview {
  const PokemonExternalImportPreview({
    required this.speciesId,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.learnset,
    required this.evolution,
    required this.media,
    required this.cries,
  });

  final String speciesId;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final PokemonExternalImportPreviewArtifact learnset;
  final PokemonExternalImportPreviewArtifact evolution;
  final PokemonExternalImportPreviewArtifact media;
  final PokemonExternalImportPreviewArtifact cries;
}

/// Rapport d'un asset best-effort téléchargé ou tenté.
///
/// Les images et cries n'entrent pas dans la mécanique de conflit bloquante des
/// quatre JSON métier. On les suit donc séparément, avec un résultat plus
/// explicite pour la QA et le report final.
class PokemonExternalAssetDownloadResult {
  const PokemonExternalAssetDownloadResult({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
    required this.wasWritten,
    this.existedBefore = false,
    this.contentType,
    this.message,
  });

  final String label;
  final String relativePath;
  final String sourceUrl;
  final bool wasWritten;
  final bool existedBefore;
  final String? contentType;
  final String? message;
}

/// Résultat détaillé d'un import externe unitaire.
///
/// Le résultat est pensé pour être lisible directement en logs, tests ou futur
/// rapport d'import :
/// - l'espèce réellement produite ;
/// - la merge policy appliquée ;
/// - l'information dry-run ;
/// - les artefacts concernés ;
/// - d'éventuels warnings non bloquants.
class PokemonExternalImportResult {
  const PokemonExternalImportResult({
    required this.requestedSpeciesId,
    required this.importedSpeciesId,
    required this.preview,
    required this.dryRun,
    required this.mergePolicy,
    required this.artifacts,
    this.downloadedAssets = const <PokemonExternalAssetDownloadResult>[],
    this.warnings = const <String>[],
  });

  final String requestedSpeciesId;
  final String importedSpeciesId;
  final PokemonExternalImportPreview preview;
  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalImportArtifactResult> artifacts;
  final List<PokemonExternalAssetDownloadResult> downloadedAssets;
  final List<String> warnings;

  bool get hasConflicts => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.conflict,
      );

  bool get hasSkips => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );

  bool get hasWritesApplied =>
      !dryRun &&
      artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.create ||
            artifact.action == PokemonExternalImportArtifactAction.overwrite,
      );

  bool get isFullySkipped =>
      artifacts.isNotEmpty &&
      artifacts.every(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );

  bool get importedSpecies => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.species,
      );

  bool get importedLearnset => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.learnset,
      );

  bool get importedEvolution => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.evolution,
      );

  bool get importedMedia => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.media,
      );

  int get downloadedAssetCount =>
      downloadedAssets.where((asset) => asset.wasWritten).length;

  bool _hasAppliedArtifact(PokemonExternalImportArtifactKind kind) {
    return artifacts.any(
      (artifact) =>
          artifact.kind == kind &&
          (artifact.action == PokemonExternalImportArtifactAction.create ||
              artifact.action == PokemonExternalImportArtifactAction.overwrite),
    );
  }
}

/// Résultat unitaire ou erreur pour une espèce dans un batch.
///
/// On ne masque pas les erreurs : chaque entrée porte soit un résultat détaillé
/// d'import, soit un message d'erreur lisible. Le batch peut ainsi continuer
/// sans perdre la granularité par espèce.
class PokemonExternalBatchImportEntryResult {
  const PokemonExternalBatchImportEntryResult({
    required this.speciesId,
    this.result,
    this.errorMessage,
  });

  final String speciesId;
  final PokemonExternalImportResult? result;
  final String? errorMessage;

  bool get isFailed => errorMessage != null;

  bool get isConflict => !isFailed && (result?.hasConflicts ?? false);

  bool get isSkipped => !isFailed && (result?.isFullySkipped ?? false);

  bool get isSuccessful => !isFailed && !isConflict;
}

/// Résultat global d'un import batch.
///
/// Le résultat reste volontairement compact :
/// - paramètres communs du batch ;
/// - résultats détaillés par espèce ;
/// - compteurs résumés.
class PokemonExternalBatchImportResult {
  const PokemonExternalBatchImportResult({
    required this.dryRun,
    required this.mergePolicy,
    required this.entries,
  });

  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalBatchImportEntryResult> entries;

  int get successfulCount =>
      entries.where((entry) => entry.isSuccessful && !entry.isSkipped).length;

  int get skippedCount => entries.where((entry) => entry.isSkipped).length;

  int get conflictCount => entries.where((entry) => entry.isConflict).length;

  int get failedCount => entries.where((entry) => entry.isFailed).length;
}

/// Use case d'orchestration pour importer une seule espèce depuis les sources
/// externes déjà convertibles.
///
/// Ce use case est la couche applicative des lots 34 et 36 :
/// - il récupère les payloads externes via un port minimal ;
/// - il réutilise strictement les convertisseurs 28 à 33 ;
/// - il applique une merge policy simple ;
/// - il supporte un vrai dry-run sans écrire quoi que ce soit ;
/// - il délègue toute écriture réelle au repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de réseau concret ;
/// - pas de lot 37+ ;
/// - pas de stratégie de fusion "intelligente" par champ ;
/// - pas de validation croisée globale du Pokédex.
class ImportExternalPokemonSpeciesUseCase {
  ImportExternalPokemonSpeciesUseCase({
    required this.externalSourceRepository,
    required this.writeRepository,
    this.speciesConverter = const ShowdownPokemonSpeciesConverter(),
    this.speciesEnricher = const PokeApiPokemonSpeciesEnricher(),
    this.learnsetConverter = const PokeApiPokemonLearnsetConverter(),
    this.evolutionConverter = const PokeApiPokemonEvolutionConverter(),
    this.mediaStubGenerator = const PokemonMediaStubGenerator(),
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownPokemonSpeciesConverter speciesConverter;
  final PokeApiPokemonSpeciesEnricher speciesEnricher;
  final PokeApiPokemonLearnsetConverter learnsetConverter;
  final PokeApiPokemonEvolutionConverter evolutionConverter;
  final PokemonMediaStubGenerator mediaStubGenerator;
  final PokemonProjectDataReader dataReader;

  Future<PokemonExternalImportResult> execute(
    ProjectWorkspace workspace, {
    required String speciesId,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final requestedSpeciesId = speciesId.trim();
    if (requestedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external import speciesId cannot be empty',
      );
    }

    // La stratégie source de la phase 11A est explicite :
    // - `pokemon-species` sert d'abord à résoudre l'identité canonique ;
    // - Showdown complète ensuite le core species structuré ;
    // - `/pokemon` et `evolution-chain` restent best-effort pour le learnset,
    //   les médias et les évolutions locales.
    final pokeApiSpeciesPayload = await externalSourceRepository
        .fetchPokeApiPokemonSpeciesPayload(requestedSpeciesId);
    final canonicalSpeciesId =
        _resolveCanonicalSpeciesIdFromSpeciesPayload(pokeApiSpeciesPayload);
    final fallbackGeneration =
        _readGenerationNumberFromSpeciesPayload(pokeApiSpeciesPayload);
    final showdownPayload = await externalSourceRepository
        .fetchShowdownSpeciesPayload(canonicalSpeciesId);
    final pokemonPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiPokemonPayload(
        canonicalSpeciesId,
      ),
      warningContext:
          'Learnset and media payload unavailable for "$canonicalSpeciesId"',
    );
    final evolutionPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiEvolutionChainPayload(
        canonicalSpeciesId,
      ),
      warningContext: 'Evolution chain unavailable for "$canonicalSpeciesId"',
    );

    final species = speciesEnricher.enrich(
      species: speciesConverter.convert(
        showdownPayload,
        fallbackGeneration: fallbackGeneration,
      ),
      pokemonSpeciesPayload: pokeApiSpeciesPayload,
      pokemonPayload: pokemonPayloadRead.payload,
    );
    final learnset = await _tryConvertOptional<PokemonLearnsetFile>(
      () => learnsetConverter.convert(
        speciesId: species.id,
        payload: pokemonPayloadRead.payload!,
      ),
      isEnabled: pokemonPayloadRead.payload != null,
      warningContext: 'Learnset conversion skipped for "${species.id}"',
    );
    final evolution = await _tryConvertOptional<PokemonEvolutionFile>(
      () => evolutionConverter.convert(
        speciesId: species.id,
        payload: evolutionPayloadRead.payload!,
      ),
      isEnabled: evolutionPayloadRead.payload != null,
      warningContext: 'Evolution conversion skipped for "${species.id}"',
    );
    // Le stub média reste utile comme plan de destination locale :
    // - il fournit les chemins cibles canoniques ;
    // - il ne doit surtout pas être persisté tel quel ;
    // - il sert uniquement de plan "optimiste" pour résoudre ensuite un
    //   `PokemonMediaFile` final cohérent avec le disque réel.
    final media = mediaStubGenerator.createStub(species);
    final assetCandidates = _resolveAssetCandidates(
      species: species,
      media: media,
      pokemonPayload: pokemonPayloadRead.payload,
    );

    final artifactPlans = await _planArtifacts(
      workspace,
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      mergePolicy: mergePolicy,
    );

    final warnings = <String>[
      ...pokemonPayloadRead.warnings,
      ...evolutionPayloadRead.warnings,
      ...learnset.warnings,
      ...evolution.warnings,
    ];
    if (species.id != requestedSpeciesId.trim().toLowerCase()) {
      warnings.add(
        'Requested species "$requestedSpeciesId" resolved to '
        '"${species.id}" from source payload.',
      );
    }
    final result = _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: warnings,
      assetCandidates: assetCandidates,
    );

    // Dry-run : tout a été converti et planifié, mais aucune écriture locale
    // n'est autorisée. Le résultat sert alors de rapport d'actions prévues.
    if (dryRun) {
      return result;
    }

    // La politique fail-on-conflict est volontairement atomique au niveau
    // d'une espèce : si un artefact est en conflit, on n'écrit rien pour
    // éviter une importation partielle ambiguë.
    if (result.hasConflicts) {
      return result;
    }

    final mediaPlan = artifactPlans.firstWhere(
      (plan) => plan.kind == PokemonExternalImportArtifactKind.media,
    );

    // On écrit d'abord les artefacts JSON bloquants / best-effort qui ne
    // dépendent pas de la présence effective d'assets binaires.
    for (final plan in artifactPlans) {
      if (plan.kind == PokemonExternalImportArtifactKind.media) {
        continue;
      }
      switch (plan.action) {
        case PokemonExternalImportArtifactAction.create:
        case PokemonExternalImportArtifactAction.overwrite:
          await plan.write(workspace, writeRepository);
          break;
        case PokemonExternalImportArtifactAction.skip:
        case PokemonExternalImportArtifactAction.conflict:
          break;
      }
    }

    final assetBatch = await _downloadBestEffortAssets(
      workspace,
      mergePolicy: mergePolicy,
      candidates: assetCandidates,
    );

    // Mini-fix post-review 11A :
    // le `media.json` final ne doit jamais refléter le plan optimiste des
    // assets, mais uniquement les fichiers garantis présents à la fin :
    // - déjà présents localement et conservés ;
    // - déjà présents localement et toujours là après overwrite raté ;
    // - téléchargés puis écrits avec succès.
    //
    // Toute référence absente sur disque est effacée avant la sérialisation.
    final resolvedMedia = await _resolvePersistedMediaFromDisk(
      workspace,
      media,
    );

    if (mediaPlan.action == PokemonExternalImportArtifactAction.create ||
        mediaPlan.action == PokemonExternalImportArtifactAction.overwrite) {
      await writeRepository.saveMedia(workspace, resolvedMedia);
    }

    return _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: false,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: <String>[
        ...warnings,
        ...assetBatch.warnings,
      ],
      assetCandidates: assetCandidates,
      downloadedAssets: assetBatch.results,
    );
  }

  Future<List<_PlannedArtifactWrite>> _planArtifacts(
    ProjectWorkspace workspace, {
    required PokemonSpeciesFile species,
    required _OptionalValue<PokemonLearnsetFile> learnset,
    required _OptionalValue<PokemonEvolutionFile> evolution,
    required PokemonMediaFile media,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) async {
    final speciesRelativePath = await _resolveSpeciesRelativePath(
      workspace,
      species,
    );

    return <_PlannedArtifactWrite>[
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.species,
        relativePath: speciesRelativePath,
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveSpecies(workspace, species),
      ),
      if (learnset.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.learnset,
          relativePath:
              'data/pokemon/learnsets/${learnset.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveLearnset(workspace, learnset.value!),
        ),
      if (evolution.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.evolution,
          relativePath:
              'data/pokemon/evolutions/${evolution.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveEvolution(workspace, evolution.value!),
        ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.media,
        relativePath: 'data/pokemon/media/${media.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveMedia(workspace, media),
      ),
    ];
  }

  Future<_PlannedArtifactWrite> _planArtifact(
    ProjectWorkspace workspace, {
    required PokemonExternalImportArtifactKind kind,
    required String relativePath,
    required PokemonExternalImportMergePolicy mergePolicy,
    required Future<void> Function(
      ProjectWorkspace workspace,
      PokemonWriteRepository repository,
    ) write,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final existedBefore = await workspace.fileExists(absolutePath);
    final action = _resolveAction(
      existedBefore: existedBefore,
      mergePolicy: mergePolicy,
    );

    final message = switch (action) {
      PokemonExternalImportArtifactAction.conflict =>
        'Target already exists and merge policy is fail_on_conflict.',
      PokemonExternalImportArtifactAction.skip =>
        'Target already exists and merge policy is skip_existing.',
      PokemonExternalImportArtifactAction.overwrite =>
        'Target already exists and will be overwritten.',
      PokemonExternalImportArtifactAction.create => null,
    };

    return _PlannedArtifactWrite(
      kind: kind,
      relativePath: relativePath,
      existedBefore: existedBefore,
      action: action,
      message: message,
      writeDelegate: write,
    );
  }

  PokemonExternalImportArtifactAction _resolveAction({
    required bool existedBefore,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) {
    if (!existedBefore) {
      return PokemonExternalImportArtifactAction.create;
    }

    return switch (mergePolicy) {
      PokemonExternalImportMergePolicy.failOnConflict =>
        PokemonExternalImportArtifactAction.conflict,
      PokemonExternalImportMergePolicy.skipExisting =>
        PokemonExternalImportArtifactAction.skip,
      PokemonExternalImportMergePolicy.overwriteExisting =>
        PokemonExternalImportArtifactAction.overwrite,
    };
  }

  Future<String> _resolveSpeciesRelativePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    // On reste aligné sur le repository d'écriture existant :
    // - si l'espèce existe déjà, on réutilise son vrai chemin courant ;
    // - sinon on génère le nom canonique `<dex>-<slug>.json`.
    final existingRelativePath =
        await dataReader.resolveSpeciesRelativePathById(workspace, species.id);
    if (existingRelativePath != null) {
      return existingRelativePath;
    }

    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(
      species.slug.isNotEmpty ? species.slug : species.id,
    );
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : trimmed;
  }

  String _resolveCanonicalSpeciesIdFromSpeciesPayload(
    Map<String, dynamic> payload,
  ) {
    final name = payload['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must expose a non-empty name',
      );
    }
    return name.trim().toLowerCase();
  }

  int? _readGenerationNumberFromSpeciesPayload(Map<String, dynamic> payload) {
    final rawGeneration = payload['generation'];
    if (rawGeneration is! Map) {
      return null;
    }

    final generationName =
        (rawGeneration['name'] as String?)?.trim().toLowerCase();
    return switch (generationName) {
      'generation-i' => 1,
      'generation-ii' => 2,
      'generation-iii' => 3,
      'generation-iv' => 4,
      'generation-v' => 5,
      'generation-vi' => 6,
      'generation-vii' => 7,
      'generation-viii' => 8,
      'generation-ix' => 9,
      _ => null,
    };
  }

  Future<_OptionalPayload<Map<String, dynamic>>> _tryReadOptionalPayload(
    Future<Map<String, dynamic>> Function() action, {
    required String warningContext,
  }) async {
    try {
      return _OptionalPayload<Map<String, dynamic>>(payload: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  Future<_OptionalValue<T>> _tryConvertOptional<T>(
    FutureOr<T> Function() action, {
    required bool isEnabled,
    required String warningContext,
  }) async {
    if (!isEnabled) {
      return _OptionalValue<T>();
    }

    try {
      return _OptionalValue<T>(value: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  PokemonExternalImportResult _buildResult({
    required String requestedSpeciesId,
    required PokemonSpeciesFile species,
    required bool dryRun,
    required PokemonExternalImportMergePolicy mergePolicy,
    required List<_PlannedArtifactWrite> artifactPlans,
    required List<String> warnings,
    required _PokemonExternalAssetCandidateBundle assetCandidates,
    List<PokemonExternalAssetDownloadResult> downloadedAssets =
        const <PokemonExternalAssetDownloadResult>[],
  }) {
    return PokemonExternalImportResult(
      requestedSpeciesId: requestedSpeciesId,
      importedSpeciesId: species.id,
      preview: PokemonExternalImportPreview(
        speciesId: species.id,
        nationalDex: species.nationalDex,
        primaryName: _resolvePrimaryName(species),
        types: _normalizeTypes(species.typing.types),
        learnset: PokemonExternalImportPreviewArtifact(
          label: 'Learnset',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.learnset,
          ),
        ),
        evolution: PokemonExternalImportPreviewArtifact(
          label: 'Évolutions',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.evolution,
          ),
        ),
        media: PokemonExternalImportPreviewArtifact(
          label: 'Médias',
          isAvailable: assetCandidates.hasMediaSource,
        ),
        cries: PokemonExternalImportPreviewArtifact(
          label: 'Cri',
          isAvailable: assetCandidates.hasCrySource,
        ),
      ),
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifacts: artifactPlans
          .map(
            (plan) => PokemonExternalImportArtifactResult(
              kind: plan.kind,
              relativePath: plan.relativePath,
              action: plan.action,
              existedBefore: plan.existedBefore,
              message: plan.message,
            ),
          )
          .toList(growable: false),
      downloadedAssets: downloadedAssets,
      warnings: warnings,
    );
  }

  String _resolvePrimaryName(PokemonSpeciesFile species) {
    final english = species.names['en']?.trim();
    if (english != null && english.isNotEmpty) {
      return english;
    }
    final french = species.names['fr']?.trim();
    if (french != null && french.isNotEmpty) {
      return french;
    }
    for (final value in species.names.values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return species.id;
  }

  List<String> _normalizeTypes(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  _PokemonExternalAssetCandidateBundle _resolveAssetCandidates({
    required PokemonSpeciesFile species,
    required PokemonMediaFile media,
    required Map<String, dynamic>? pokemonPayload,
  }) {
    final defaultVariant = media.variants[media.defaultFormId];
    if (defaultVariant == null || pokemonPayload == null) {
      return const _PokemonExternalAssetCandidateBundle();
    }

    final portraitUrl = _readNestedString(
          pokemonPayload,
          const <String>[
            'sprites',
            'other',
            'official-artwork',
            'front_default'
          ],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'other', 'home', 'front_default'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'front_default'],
        );
    final frontUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_default'],
    );
    final backUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_default'],
    );
    final frontShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_shiny'],
    );
    final backShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_shiny'],
    );
    final cryUrl = _readNestedString(
          pokemonPayload,
          const <String>['cries', 'latest'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['cries', 'legacy'],
        );

    return _PokemonExternalAssetCandidateBundle(
      candidates: <_PokemonExternalAssetCandidate>[
        if (defaultVariant.portrait?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Portrait',
            relativePath: defaultVariant.portrait!.trim(),
            sourceUrl: portraitUrl,
          ),
        if (defaultVariant.frontStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite face',
            relativePath: defaultVariant.frontStatic!.trim(),
            sourceUrl: frontUrl,
          ),
        if (defaultVariant.backStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite dos',
            relativePath: defaultVariant.backStatic!.trim(),
            sourceUrl: backUrl,
          ),
        if (defaultVariant.frontShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny face',
            relativePath: defaultVariant.frontShinyStatic!.trim(),
            sourceUrl: frontShinyUrl,
          ),
        if (defaultVariant.backShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny dos',
            relativePath: defaultVariant.backShinyStatic!.trim(),
            sourceUrl: backShinyUrl,
          ),
        if (defaultVariant.cry?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Cri',
            relativePath: defaultVariant.cry!.trim(),
            sourceUrl: cryUrl,
          ),
      ],
      speciesId: species.id,
    );
  }

  Future<_DownloadedAssetBatch> _downloadBestEffortAssets(
    ProjectWorkspace workspace, {
    required PokemonExternalImportMergePolicy mergePolicy,
    required _PokemonExternalAssetCandidateBundle candidates,
  }) async {
    final warnings = <String>[];
    final results = <PokemonExternalAssetDownloadResult>[];

    for (final candidate in candidates.candidates) {
      final absolutePath =
          workspace.resolveProjectRelativePath(candidate.relativePath);
      final existedBefore = await workspace.fileExists(absolutePath);
      final sourceUrl = candidate.sourceUrl?.trim();
      if (sourceUrl == null || sourceUrl.isEmpty) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} has no external source; the existing local asset was kept.'
            : '${candidate.label} has no external source and no local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: '',
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
        continue;
      }
      if (_looksLikeGif(sourceUrl)) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} ignored because GIF assets are explicitly excluded; the existing local asset was kept.'
            : '${candidate.label} ignored because GIF assets are explicitly excluded and no local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
        continue;
      }
      if (existedBefore &&
          mergePolicy != PokemonExternalImportMergePolicy.overwriteExisting) {
        final message =
            '${candidate.label} left untouched because the local asset already exists.';
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: true,
            message: message,
          ),
        );
        warnings.add(message);
        continue;
      }

      try {
        final asset =
            await externalSourceRepository.fetchBinaryAsset(sourceUrl);
        if (asset.bytes.isEmpty) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} download returned no bytes; the existing local asset was kept.'
              : '${candidate.label} download returned no bytes and no local asset exists; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        if (_looksLikeGif(asset.sourceUrl) ||
            _isGifContentType(asset.contentType)) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} ignored because GIF assets are not allowed in local media; the existing local asset was kept.'
              : '${candidate.label} ignored because GIF assets are not allowed in local media and no local asset exists; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        if (!_isCompatibleContentType(candidate, asset.contentType)) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} download used an incompatible content-type (${asset.contentType ?? 'unknown'}); the existing local asset was kept.'
              : '${candidate.label} download used an incompatible content-type (${asset.contentType ?? 'unknown'}) and no local asset exists; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }

        await writeRepository.saveBinaryAsset(
          workspace,
          relativePath: candidate.relativePath,
          bytes: asset.bytes,
        );
        final existsAfterWrite = await workspace.fileExists(absolutePath);
        if (!existsAfterWrite) {
          final message =
              '${candidate.label} download completed but no local file was found afterwards; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: true,
            existedBefore: existedBefore,
            contentType: asset.contentType,
          ),
        );
      } on EditorApplicationException catch (error) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} download failed: ${error.message}. The existing local asset was kept.'
            : '${candidate.label} download failed: ${error.message}. No local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      } catch (error) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} download failed: $error. The existing local asset was kept.'
            : '${candidate.label} download failed: $error. No local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      }
    }

    return _DownloadedAssetBatch(
      results: results,
      warnings: warnings,
    );
  }

  // Construit le `PokemonMediaFile` effectivement persistant à partir du disque.
  //
  // Invariant du mini-fix :
  // - un chemin n'est gardé que si le fichier existe réellement à la fin ;
  // - le stub média ne sert que de plan de destinations potentielles ;
  // - les animations suivent la même règle que les images et le cry, pour
  //   éviter des refs fantômes de sheets.
  Future<PokemonMediaFile> _resolvePersistedMediaFromDisk(
    ProjectWorkspace workspace,
    PokemonMediaFile plannedMedia,
  ) async {
    final resolvedVariants = <String, PokemonMediaVariant>{};

    for (final entry in plannedMedia.variants.entries) {
      resolvedVariants[entry.key] = await _resolvePersistedMediaVariantFromDisk(
        workspace,
        entry.value,
      );
    }

    return PokemonMediaFile(
      speciesId: plannedMedia.speciesId,
      defaultFormId: plannedMedia.defaultFormId,
      variants: resolvedVariants,
    );
  }

  Future<PokemonMediaVariant> _resolvePersistedMediaVariantFromDisk(
    ProjectWorkspace workspace,
    PokemonMediaVariant plannedVariant,
  ) async {
    return PokemonMediaVariant(
      frontStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.frontStatic,
      ),
      backStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.backStatic,
      ),
      frontShinyStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.frontShinyStatic,
      ),
      backShinyStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.backShinyStatic,
      ),
      icon: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.icon,
      ),
      party: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.party,
      ),
      overworld: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.overworld,
      ),
      portrait: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.portrait,
      ),
      cry: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.cry,
      ),
      animations: await _resolvePersistedAnimationsFromDisk(
        workspace,
        plannedVariant.animations,
      ),
    );
  }

  Future<Map<String, PokemonMediaAnimationRef>>
      _resolvePersistedAnimationsFromDisk(
    ProjectWorkspace workspace,
    Map<String, PokemonMediaAnimationRef> animations,
  ) async {
    final resolved = <String, PokemonMediaAnimationRef>{};

    for (final entry in animations.entries) {
      final sheet = await _resolveGuaranteedLocalAssetPath(
        workspace,
        entry.value.sheet,
      );
      if (sheet == null) {
        continue;
      }
      resolved[entry.key] = PokemonMediaAnimationRef(
        sheet: sheet,
        animationId: entry.value.animationId,
      );
    }

    return resolved;
  }

  Future<String?> _resolveGuaranteedLocalAssetPath(
    ProjectWorkspace workspace,
    String? relativePath,
  ) async {
    final trimmed = relativePath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final exists = await workspace.fileExists(
      workspace.resolveProjectRelativePath(trimmed),
    );
    return exists ? trimmed : null;
  }

  String? _readNestedString(
    Map<String, dynamic> payload,
    List<String> path,
  ) {
    Object? current = payload;
    for (final segment in path) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    final value = current as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _looksLikeGif(String url) {
    return url.toLowerCase().contains('.gif');
  }

  bool _isGifContentType(String? contentType) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return normalized.contains('image/gif');
  }

  bool _isCompatibleContentType(
    _PokemonExternalAssetCandidate candidate,
    String? contentType,
  ) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return true;
    }

    if (candidate.label == 'Cri') {
      return normalized.contains('audio/ogg') ||
          normalized.contains('application/ogg');
    }

    return normalized.contains('image/png');
  }
}

/// Use case batch pour importer plusieurs espèces.
///
/// Ce lot 35 se contente d'enchaîner proprement l'import unitaire :
/// - l'ordre d'exécution est stabilisé ;
/// - chaque espèce garde son résultat détaillé ;
/// - les erreurs par espèce ne cassent pas le reste du batch.
class BatchImportExternalPokemonSpeciesUseCase {
  const BatchImportExternalPokemonSpeciesUseCase(this.singleImportUseCase);

  final ImportExternalPokemonSpeciesUseCase singleImportUseCase;

  Future<PokemonExternalBatchImportResult> execute(
    ProjectWorkspace workspace, {
    required List<String> speciesIds,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final normalizedSpeciesIds = speciesIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    if (normalizedSpeciesIds.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external batch speciesIds cannot be empty',
      );
    }

    final entryResults = <PokemonExternalBatchImportEntryResult>[];
    for (final speciesId in normalizedSpeciesIds) {
      try {
        final result = await singleImportUseCase.execute(
          workspace,
          speciesId: speciesId,
          mergePolicy: mergePolicy,
          dryRun: dryRun,
        );
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            result: result,
          ),
        );
      } on EditorApplicationException catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: error.message,
          ),
        );
      } catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: 'Unexpected batch import error: $error',
          ),
        );
      }
    }

    return PokemonExternalBatchImportResult(
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      entries: entryResults,
    );
  }
}

class _OptionalPayload<T> {
  const _OptionalPayload({
    this.payload,
    this.warnings = const <String>[],
  });

  final T? payload;
  final List<String> warnings;
}

class _OptionalValue<T> {
  const _OptionalValue({
    this.value,
    this.warnings = const <String>[],
  });

  final T? value;
  final List<String> warnings;
}

class _PokemonExternalAssetCandidate {
  const _PokemonExternalAssetCandidate({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
  });

  final String label;
  final String relativePath;
  final String? sourceUrl;
}

class _PokemonExternalAssetCandidateBundle {
  const _PokemonExternalAssetCandidateBundle({
    this.candidates = const <_PokemonExternalAssetCandidate>[],
    this.speciesId,
  });

  final List<_PokemonExternalAssetCandidate> candidates;
  final String? speciesId;

  bool get hasMediaSource => candidates.any(
        (candidate) =>
            candidate.label != 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );

  bool get hasCrySource => candidates.any(
        (candidate) =>
            candidate.label == 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );
}

class _DownloadedAssetBatch {
  const _DownloadedAssetBatch({
    required this.results,
    required this.warnings,
  });

  final List<PokemonExternalAssetDownloadResult> results;
  final List<String> warnings;
}

class _PlannedArtifactWrite {
  const _PlannedArtifactWrite({
    required this.kind,
    required this.relativePath,
    required this.existedBefore,
    required this.action,
    required this.writeDelegate,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final bool existedBefore;
  final PokemonExternalImportArtifactAction action;
  final String? message;
  final Future<void> Function(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) writeDelegate;

  Future<void> write(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) {
    return writeDelegate(workspace, repository);
  }
}

```

### `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late ImportExternalPokemonSpeciesUseCase singleUseCase;
  late BatchImportExternalPokemonSpeciesUseCase batchUseCase;
  late _FakePokemonExternalSourceRepository externalSourceRepository;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_external_import_project_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    externalSourceRepository = _FakePokemonExternalSourceRepository(
      showdownSpeciesPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurShowdownPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonSpeciesPayloads: <String, Map<String, dynamic>>{
        '1':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        '2': jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurPokemonPayload) as Map<String, dynamic>,
      },
      pokeApiEvolutionChainPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
      },
      binaryAssets: <String, PokemonExternalBinaryAsset>{
        'https://assets.example.test/bulbasaur/portrait.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front.png',
          bytes: Uint8List.fromList(<int>[5, 6, 7, 8]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back.png',
          bytes: Uint8List.fromList(<int>[9, 10, 11, 12]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front_shiny.png',
          bytes: Uint8List.fromList(<int>[13, 14, 15, 16]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back_shiny.png',
          bytes: Uint8List.fromList(<int>[17, 18, 19, 20]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/cry.ogg':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
          bytes: Uint8List.fromList(<int>[21, 22, 23, 24]),
          contentType: 'audio/ogg',
        ),
      },
    );
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
    singleUseCase = ImportExternalPokemonSpeciesUseCase(
      externalSourceRepository: externalSourceRepository,
      writeRepository: writeRepository,
    );
    batchUseCase = BatchImportExternalPokemonSpeciesUseCase(singleUseCase);

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon External Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ImportExternalPokemonSpeciesUseCase', () {
    test('imports one species from external payloads into local storage',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(workspace, speciesId: '1');

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
      expect(result.preview.primaryName, 'Bulbasaur');
      expect(result.preview.cries.isAvailable, isTrue);
      expect(result.downloadedAssetCount, 6);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );

      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(species.typing.types, <String>['grass', 'poison']);
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(species.names['fr'], 'Bulbizarre');
      expect(species.progression.growthRateId, 'medium_slow');
      expect(species.progression.baseFriendship, 50);
      expect(species.dexContent.color, 'green');
      expect(species.dexContent.flavorText,
          'A strange seed was planted on its back at birth.');
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isTrue,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves everything but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(result.downloadedAssetCount, 0);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fail_on_conflict reports conflicts and writes nothing', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing skips files already present and still writes missing ones',
        () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        dryRun: true,
      );
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.skip,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('overwrite_existing replaces an existing artefact', () async {
      await writeRepository.saveLearnset(
        workspace,
        const PokeApiPokemonLearnsetConverter().convert(
          speciesId: 'bulbasaur',
          payload: jsonDecode(_legacyBulbasaurPokemonPayload)
              as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.learnset,
            )
            .action,
        PokemonExternalImportArtifactAction.overwrite,
      );
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing reuses an existing non-canonical species path '
        'without creating a duplicate canonical file', () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing ignores a misleading basename with another json id',
        () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );

      final misleadingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await misleadingFile.parent.create(recursive: true);
      final misleadingJson = _customSlugBulbasaurSpecies.toJson()
        ..['id'] = 'something_else'
        ..['slug'] = 'something-else';
      await misleadingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(misleadingJson),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(await misleadingFile.exists(), isTrue);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('surfaces external source errors clearly', () async {
      externalSourceRepository.pokeApiPokemonSpeciesPayloads
          .remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon-species payload not found for species "bulbasaur"',
          ),
        ),
      );
    });

    test('continues when optional pokemon payload is unavailable', () async {
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.hasConflicts, isFalse);
      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isFalse);
      expect(result.importedEvolution, isTrue);
      expect(result.importedMedia, isTrue);
      expect(result.preview.learnset.isAvailable, isFalse);
      expect(result.preview.media.isAvailable, isFalse);
      expect(result.preview.cries.isAvailable, isFalse);
      expect(
        result.warnings.join('\n'),
        contains('Learnset and media payload unavailable for "bulbasaur"'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });

    test(
        'omits a missing media asset ref from media.json while keeping the rest coherent',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic,
          'assets/pokemon/sprites/bulbasaur/front.png');
      expect(baseVariant.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('Portrait download failed'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'keeps species learnset and evolution when all media downloads fail and writes no ghost refs',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets.clear();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isTrue);
      expect(result.importedEvolution, isTrue);
      expect(result.downloadedAssetCount, 0);
      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic, isNull);
      expect(baseVariant.backStatic, isNull);
      expect(baseVariant.frontShinyStatic, isNull);
      expect(baseVariant.backShinyStatic, isNull);
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.cry, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(result.warnings.join('\n'), contains('download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing keeps a pre-existing local asset ref without re-downloading it',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[200, 201, 202]);

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final portraitResult = result.downloadedAssets.firstWhere(
        (asset) => asset.label == 'Portrait',
      );

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[200, 201, 202]);
      expect(portraitResult.wasWritten, isFalse);
      expect(portraitResult.existedBefore, isTrue);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps an existing local asset ref when redownload fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[77, 88, 99]);
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[77, 88, 99]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('refuses GIF assets without persisting a ghost media ref', () async {
      final beforeProjectJson = await projectFile.readAsString();
      final payload =
          jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>;
      final sprites = payload['sprites'] as Map<String, dynamic>;
      final other = sprites['other'] as Map<String, dynamic>;
      final officialArtwork = other['official-artwork'] as Map<String, dynamic>;
      officialArtwork['front_default'] =
          'https://assets.example.test/bulbasaur/portrait.gif';
      externalSourceRepository.pokeApiPokemonPayloads['bulbasaur'] = payload;

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('GIF assets are explicitly excluded'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('applies the same no-ghost rule to cries', () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/cry.ogg');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(result.warnings.join('\n'), contains('Cri download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });
  });

  group('BatchImportExternalPokemonSpeciesUseCase', () {
    test('imports a batch successfully with deterministic ordering', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur', 'ivysaur'],
      );

      expect(
        result.entries.map((entry) => entry.speciesId).toList(),
        <String>['bulbasaur', 'ivysaur'],
      );
      expect(result.successfulCount, 2);
      expect(result.failedCount, 0);
      expect(result.conflictCount, 0);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('continues on partial failures and reports them by species', () async {
      externalSourceRepository.showdownSpeciesPayloads.remove('ivysaur');

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
      );

      expect(result.successfulCount, 1);
      expect(result.failedCount, 1);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'ivysaur')
            .errorMessage,
        'External Showdown species payload not found for species "ivysaur"',
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    required this.showdownSpeciesPayloads,
    required this.pokeApiPokemonSpeciesPayloads,
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
    required this.binaryAssets,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;
  final Map<String, PokemonExternalBinaryAsset> binaryAssets;

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) async {
    final payload = pokeApiEvolutionChainPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI evolution chain payload not found for species '
        '"$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) async {
    final payload = showdownSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final asset = binaryAssets[sourceUrl];
    if (asset == null) {
      throw EditorNotFoundException('External asset not found: $sourceUrl');
    }
    return PokemonExternalBinaryAsset(
      sourceUrl: asset.sourceUrl,
      bytes: Uint8List.fromList(asset.bytes),
      contentType: asset.contentType,
    );
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

const String _bulbasaurShowdownPayload = '''
{
  "name": "Bulbasaur",
  "num": 1,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 0.7,
  "weightkg": 6.9
}
''';

const String _bulbasaurPokemonSpeciesPayload = '''
{
  "name": "bulbasaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Bulbasaur"},
    {"language": {"name": "fr"}, "name": "Bulbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "A strange seed was planted on its back at birth."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurPokemonSpeciesPayload = '''
{
  "name": "ivysaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Ivysaur"},
    {"language": {"name": "fr"}, "name": "Herbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "When the bulb on its back grows large, it appears to lose the ability to stand."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurShowdownPayload = '''
{
  "name": "Ivysaur",
  "num": 2,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 60,
    "atk": 62,
    "def": 63,
    "spa": 80,
    "spd": 80,
    "spe": 60
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 142,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 1.0,
  "weightkg": 13.0
}
''';

const PokemonSpeciesFile _customSlugBulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbizarre-custom',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur Custom'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 45,
    atk: 49,
    def: 49,
    spa: 65,
    spd: 65,
    spe: 45,
    bst: 318,
  ),
  abilities: PokemonSpeciesAbilities(
    primary: 'overgrow',
    hidden: 'chlorophyll',
  ),
  breeding: PokemonSpeciesBreeding(
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    eggGroups: <String>['monster', 'grass'],
    hatchCycles: 20,
  ),
  progression: PokemonSpeciesProgression(
    growthRateId: 'medium_slow',
    baseExp: 64,
    catchRate: 45,
    baseFriendship: 50,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur',
    evolution: 'bulbasaur',
    media: 'bulbasaur',
  ),
  dexContent: PokemonSpeciesDexContent(
    heightM: 0.7,
    weightKg: 6.9,
    color: 'green',
    flavorText: 'Custom slug seed for overwrite proof.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

const String _bulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "base_experience": 64,
  "height": 7,
  "weight": 69,
  "sprites": {
    "front_default": "https://assets.example.test/bulbasaur/front.png",
    "back_default": "https://assets.example.test/bulbasaur/back.png",
    "front_shiny": "https://assets.example.test/bulbasaur/front_shiny.png",
    "back_shiny": "https://assets.example.test/bulbasaur/back_shiny.png",
    "other": {
      "official-artwork": {
        "front_default": "https://assets.example.test/bulbasaur/portrait.png"
      }
    }
  },
  "cries": {
    "latest": "https://assets.example.test/bulbasaur/cry.ogg"
  },
  "moves": [
    {
      "move": {"name": "vine-whip"},
      "version_group_details": [
        {
          "level_learned_at": 7,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "tackle"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "growl"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "solar-beam"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _legacyBulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _ivysaurPokemonPayload = '''
{
  "name": "ivysaur",
  "base_experience": 142,
  "height": 10,
  "weight": 130,
  "sprites": {
    "front_default": null,
    "back_default": null,
    "front_shiny": null,
    "back_shiny": null,
    "other": {
      "official-artwork": {
        "front_default": null
      }
    }
  },
  "cries": {
    "latest": null
  },
  "moves": [
    {
      "move": {"name": "razor-leaf"},
      "version_group_details": [
        {
          "level_learned_at": 20,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _bulbasaurEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "bulbasaur"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "ivysaur"},
        "evolution_details": [
          {
            "trigger": {"name": "level-up"},
            "min_level": 16
          }
        ],
        "evolves_to": [
          {
            "species": {"name": "venusaur"},
            "evolution_details": [
              {
                "trigger": {"name": "use-item"},
                "item": {"name": "leaf-stone"},
                "known_move": {"name": "solar-beam"},
                "location": {"name": "special-garden"}
              }
            ],
            "evolves_to": []
          }
        ]
      }
    ]
  }
}
''';

```

### `reports/phase-11a-mini-fix-report.md`

Le report principal n’est pas recopié intégralement dans lui-même pour éviter une récursion infinie. Tous les autres fichiers texte modifiés/créés sont reproduits intégralement ci-dessus.

## 16. Manifest des assets binaires si applicable

Aucun asset binaire n’a été ajouté au repo pendant ce mini-fix. Les scénarios binaires sont couverts par les tests dans des workspaces temporaires.
