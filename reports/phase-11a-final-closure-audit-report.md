# Phase 11A Final Closure Audit Report

## 1. Résumé exécutif honnête

La phase 11A est **clôturable après mini-fix**.

L’audit final contradictoire a trouvé **trois bugs réels** encore ouverts dans le scope 11A existant :
- un faux positif de reporting sur `hasWritesApplied` en cas de conflit partiel `failOnConflict` ;
- un risque réel d’assets média orphelins si la persistance finale de `media.json` échoue après les téléchargements binaires ;
- l’acceptation abusive d’un asset image sans `content-type` quand ses bytes ne prouvent pas un PNG compatible.

Ces bugs ont été **reproduits ou prouvés**, corrigés localement dans le use case, puis verrouillés par des tests ciblés. Aucun autre chantier 11B n’a été ouvert.

## 2. Verdict final

**Phase 11A clôturable après mini-fix**

## 3. État initial audité

Avant ce passage :
- le pipeline 11A existant chargeait bien PokeAPI + Showdown via le port externe déjà en place ;
- les tests 11A ciblés passaient dans leur état courant ;
- les mini-fix précédents avaient déjà verrouillé :
  - pas de ref média fantôme dans un `media.json` nouvellement écrit ;
  - pas de nouveaux assets orphelins quand `media.json` est `skipExisting` ;
  - refus des GIF par URL/header et refus des `content-type` incompatibles explicitement déclarés ;
- en revanche, certains coins n’étaient pas encore prouvés par test, ou révélaient des trous seulement quand on les poussait explicitement.

## 4. Liste des bugs réels trouvés

### Bug 1 — `hasWritesApplied` mentait sur un conflit partiel `failOnConflict`
- Symptôme : si un seul artefact entrait en conflit mais que d’autres restaient planifiés en `create`, `PokemonExternalImportResult.hasWritesApplied` retournait `true` alors que le use case sortait avant toute écriture réelle.
- Preuve : le nouveau test `fail_on_conflict stays atomic even when only one artefact already exists` échouait avant patch.
- Périmètre réel : reporting applicatif du use case unitaire 11A, pas une refonte d’architecture.
- Sévérité : moyenne.
- Décision prise : correction minimale dans le getter `hasWritesApplied` pour tenir compte de `hasConflicts`.

### Bug 2 — un échec tardif de `saveMedia()` laissait des assets média orphelins
- Symptôme : le pipeline téléchargeait et écrivait les assets binaires, puis persistait `media.json` ensuite. Si `saveMedia()` échouait, les nouveaux fichiers binaires restaient sur disque sans JSON local pour les référencer.
- Preuve : le nouveau test `cleans up newly written media assets if media.json persistence fails` échouait avant patch, avec des fichiers réellement présents sur disque après l’exception.
- Périmètre réel : cohérence média du use case 11A, sans création d’un second pipeline.
- Sévérité : haute.
- Décision prise : ajout d’un cleanup best effort des assets binaires **créés dans ce run uniquement** si la résolution/persistance finale média échoue, puis rethrow de l’erreur initiale.

### Bug 3 — un asset image sans `content-type` compatible pouvait être accepté à tort
- Symptôme : `_isCompatibleContentType(...)` acceptait silencieusement `null` / vide, ce qui permettait d’écrire un binaire non-PNG si le serveur omettait le header.
- Preuve : le nouveau test `rejects a headerless incompatible image payload without persisting a ref` échouait avant patch ; le portrait était écrit et référencé malgré des bytes de signature JPEG.
- Périmètre réel : validation média 11A, pas du cache ni du transport.
- Sévérité : moyenne.
- Décision prise : quand le `content-type` est absent, le use case exige maintenant une signature binaire compatible avec le format attendu (`PNG` pour les images, `OGG` pour le cri).

## 5. Liste des faux positifs / soupçons rejetés

- **`skipExisting` devrait “réparer” un vieux `media.json` déjà incohérent** : rejeté. Ce serait une migration rétroactive hors contrat `skipExisting`, déjà explicitement exclue des mini-fix précédents.
- **La preview externe “ment” sur la disponibilité logique** : rejeté comme bug. La preview 11A annonce une disponibilité source / pipeline, pas une garantie de persistance locale.
- **Les `content-type` incompatibles non-GIF n’étaient pas du tout gérés** : rejeté tel quel. La branche existait déjà pour les headers explicites (`image/jpeg`, `audio/mpeg`) ; le vrai trou restant portait sur l’absence de header compatible.
- **Le wizard/UI 11A devait être refactoré** : rejeté, hors scope.
- **Batch, moves catalog, cache disque, parser `abilities.js`, providers avancés** : rejetés, hors scope 11A.

## 6. Périmètre inclus

Inclus dans ce passage :
- audit contradictoire du pipeline 11A réellement présent dans le repo ;
- reproduction ciblée des vrais défauts restants ;
- patch minimal du use case externe ;
- ajout de tests ciblés à forte valeur ;
- report final de clôture avec preuves git réelles.

## 7. Périmètre exclu

Exclu explicitement :
- phase 11B ;
- batch produit UI ;
- move library ;
- import global des moves ;
- cache disque ;
- offline mode ;
- parser `abilities.js` complet ;
- refonte providers ;
- refonte wizard ;
- refonte modèle média ;
- migration rétroactive des vieux `media.json` ;
- modification de `project.json`.

## 8. Sub-agents utilisés

### Banach — audit contradictoire du pipeline
- Mission : chercher les vrais bugs restants sur le use case 11A et ses invariants.
- Conclusion brute : a pointé un risque d’assets orphelins sur échec tardif média et un trou MIME, plus un soupçon sur `skipExisting` + vieux `media.json` incohérent.
- Décision retenue :
  - **retenu** : orphelins sur échec tardif média ;
  - **retenu** : trou sur header MIME absent ;
  - **rejeté** : réécriture d’un `media.json` skippé existant, classée hors scope / contraire au contrat `skipExisting`.

### Kuhn — audit de matrice de tests
- Mission : challenger la couverture réelle des invariants 11A.
- Conclusion brute : a repéré un manque sur le conflit partiel `failOnConflict`, plus d’autres idées de couverture supplémentaires.
- Décision retenue :
  - **retenu** : ajout du test de conflit partiel, qui a révélé un vrai bug de reporting (`hasWritesApplied`) ;
  - **rejeté pour ce passage** : tests supplémentaires “nice to have” non nécessaires à la fermeture une fois les bugs réels corrigés.

### Boyle — audit strict de scope
- Mission : vérifier qu’on ne dérive pas vers 11B ou une refonte produit.
- Conclusion brute : a confirmé que le produit shippe surtout le chemin `failOnConflict` côté UI et que le scope devait rester local.
- Décision retenue : garder le fix strictement dans le use case + tests + report.
- Note honnête : sa conclusion “aucun bug confirmé” a été dépassée par les reproductions ajoutées ensuite ; seul son cadrage de scope a été conservé.

### Hypatia — audit du report et des preuves git
- Mission : verrouiller la conformité du report final et la preuve d’existence du fichier.
- Conclusion brute : a rappelé les preuves git indispensables pour un report non tracké et les pièges de récursion.
- Décision retenue : report non auto-recursif, preuve par `git status --short` + `git ls-files --others --exclude-standard`.

### Avicenna — relecture finale de cohérence
- Mission : challenger le scope final et la narration du fix.
- Conclusion brute : a confirmé que le scope devait rester local et a rappelé qu’il ne fallait pas raconter comme “bug corrigé” un comportement déjà couvert par le code.
- Décision retenue : ne pas présenter les MIME incompatibles explicites comme un bug nouveau ; le vrai fix porte uniquement sur l’absence de header compatible.

## 9. Justification fichier par fichier

### Fichier modifié — `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- Pourquoi touché : c’est le point minimal où vivent les trois bugs prouvés : reporting `hasWritesApplied`, persistance média tardive, validation binaire sans header.
- Pourquoi le changement est minimal et nécessaire :
  - aucune nouvelle couche ;
  - aucun nouveau port ;
  - aucun changement UI ;
  - uniquement des gardes locales, un cleanup best effort local et une validation de fallback par signature.

### Fichier modifié — `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- Pourquoi touché : c’est le seul test de haute valeur sur le use case unitaire 11A ; il devait reproduire les bugs réels et verrouiller les correctifs.
- Pourquoi le changement est minimal et nécessaire :
  - ajout de tests de repro / preuve ;
  - ajout d’un fake local minuscule pour simuler un échec `saveMedia()` ;
  - pas de refactor transversal de la suite de tests.

### Fichier créé — `reports/phase-11a-final-closure-audit-report.md`
- Pourquoi touché : livrable demandé par la mission.
- Pourquoi le changement est minimal et nécessaire : report de clôture avec preuves git et annexe complète.

## 10. Commandes réellement exécutées

### Audit initial
```bash
find .. -name AGENTS.md -print
git status --short
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '1,260p' packages/map_editor/test/import_external_pokemon_use_cases_test.dart
sed -n '260,620p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '260,720p' packages/map_editor/test/import_external_pokemon_use_cases_test.dart
sed -n '1,260p' packages/map_editor/lib/src/application/services/pokeapi_pokemon_species_enricher.dart
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,220p' packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
sed -n '1,220p' packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
sed -n '1,260p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
sed -n '1,260p' packages/map_editor/test/pokeapi_live_source_test.dart
sed -n '1,260p' packages/map_editor/test/showdown_snapshot_source_test.dart
sed -n '1,260p' packages/map_editor/test/http_pokemon_external_source_repository_test.dart
sed -n '1,260p' packages/map_editor/test/provider_wiring_test.dart
sed -n '1,320p' packages/map_editor/test/pokedex_workspace_ui_test.dart
rg -n "dryRun|downloadedAssets|_downloadBestEffortAssets|_resolvePersistedMediaFromDisk|_resolveAssetCandidates|content-type|contentType|gif|preview|warning|skipExisting|overwriteExisting|failOnConflict|PokemonExternalImportPreview" packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '620,1220p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '1220,1460p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '720,1320p' packages/map_editor/test/import_external_pokemon_use_cases_test.dart
sed -n '1,220p' packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart
rg -n "saveBinaryAsset\(|class FilePokemonWriteRepository|saveMedia\(" packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '220,420p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,240p' packages/map_editor/lib/src/application/ports/project_workspace.dart
```

### Validation et reproduction
```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart test/pokeapi_live_source_test.dart test/showdown_snapshot_source_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_external_pokemon_use_cases.dart test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart test/pokeapi_live_source_test.dart test/showdown_snapshot_source_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_workspace_ui_test.dart
git status --short -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-final-closure-audit-report.md
git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-final-closure-audit-report.md
git ls-files --others --exclude-standard -- reports/phase-11a-final-closure-audit-report.md
sed -n '1,40p' reports/phase-11a-final-closure-audit-report.md
```

## 11. Résultats réels

### Audit / baseline
- `find .. -name AGENTS.md -print` a confirmé un seul fichier d’instructions repo : `../pokemonProject/AGENTS.md`.
- Le premier `flutter test` large avant repro passait : `All tests passed!`

### Reproduction avant correctif
- Après ajout des tests de repro, la première relance a échoué pour une raison mécanique réelle : import manquant de `ProjectWorkspace` dans le test.
- Après correction de cet import, la relance a reproduit deux vrais bugs :
  - `cleans up newly written media assets if media.json persistence fails` échouait car les fichiers existaient encore sur disque ;
  - `rejects a headerless incompatible image payload without persisting a ref` échouait car `portrait` était encore persisté.
- Le test de preuve `fail_on_conflict stays atomic even when only one artefact already exists` a révélé un troisième bug : `hasWritesApplied` retournait `true` alors qu’aucune écriture n’avait été appliquée sous conflit.

### Validation finale
- `dart format` :
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
  - `Formatted 2 files (1 changed) in 0.02 seconds.`
- `flutter analyze --no-pub ...` :
  - `No issues found! (ran in 1.1s)`
- `flutter test test/import_external_pokemon_use_cases_test.dart` :
  - `00:01 +24: All tests passed!`
- `flutter test` large 11A ciblé :
  - `00:07 +68: All tests passed!`

## 12. Incidents rencontrés

- Un premier run de `flutter test test/import_external_pokemon_use_cases_test.dart` a échoué à la compilation parce que le nouveau fake de test utilisait `ProjectWorkspace` sans import.
- Aucun lock Flutter, aucun timeout bloquant, aucun problème de format/analyze après correction.
- Le `git status --short` global initial ne renvoyait rien d’utile pour l’audit ciblé ; la preuve git finale a donc été faite sur le périmètre exact touché par cette clôture.

## 13. État git utile final

### `git status --short -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-final-closure-audit-report.md`
```text
 M packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
?? reports/phase-11a-final-closure-audit-report.md
```

### `git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/phase-11a-final-closure-audit-report.md`
```text
 .../import_external_pokemon_use_cases.dart         | 113 ++++++++--
 .../import_external_pokemon_use_cases_test.dart    | 241 +++++++++++++++++++++
 2 files changed, 340 insertions(+), 14 deletions(-)
```

Note honnête : `git diff --stat` ne liste pas le report car il est **untracked** ; sa preuve réelle est donnée par `git status --short` et `git ls-files --others --exclude-standard`.

### `git ls-files --others --exclude-standard -- reports/phase-11a-final-closure-audit-report.md`
```text
reports/phase-11a-final-closure-audit-report.md
```

## 14. Limites restantes

- Le mini-fix ne tente pas de rollback global des JSON déjà écrits si `saveMedia()` casse ; il se limite à empêcher les **assets binaires orphelins**, qui était le vrai défaut prouvé.
- Le mini-fix ne répare pas rétroactivement de vieux `media.json` déjà incohérents dans un workspace existant ; c’est volontairement hors scope.
- La validation binaire par signature fallback couvre désormais le cas **absence de header** pour les images/ cries attendus, mais ne transforme pas 11A en moteur antivirus ou en validateur de formats exhaustif.

## 15. Checklist finale

- [x] scope 11A strictement respecté
- [x] aucun chantier 11B rouvert
- [x] aucun nouveau port externe
- [x] aucun nouveau use case externe parallèle
- [x] aucun changement `project.json`
- [x] bugs corrigés uniquement après preuve
- [x] `species` reste bloquant
- [x] `learnset` et `evolution` restent best effort non bloquants côté sources optionnelles
- [x] `media/images/cries` restent best effort non bloquants côté disponibilité source
- [x] `dryRun` reste sans écriture
- [x] aucune URL distante persistée
- [x] aucun GIF accepté dans les cas couverts par le pipeline actuel
- [x] aucun nouvel asset orphelin créé dans les branches auditées/corrigées
- [x] aucun `media.json` nouvellement écrit ne référence un asset absent
- [x] tests ciblés ajoutés à forte valeur
- [x] analyze passe
- [x] tests passent
- [x] report créé
- [x] présence du report prouvée par git
- [x] fichiers manuels touchés abondamment commentés

## 16. Contenu complet de TOUS les fichiers texte modifiés / créés

Note explicite : ce report **n’est pas recopié intégralement dans lui-même** pour éviter une récursion infinie. Tous les autres fichiers texte modifiés sont reproduits intégralement ci-dessous.

### Fichier complet — `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

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
      // En `failOnConflict`, l'orchestration retourne avant toute écriture
      // réelle dès qu'au moins un artefact est en conflit. Le résultat peut
      // donc encore contenir des actions planifiées `create/overwrite` sur les
      // autres artefacts, mais elles ne représentent pas des écritures
      // effectivement appliquées. Sans cette garde, `hasWritesApplied`
      // raconterait une fausse histoire dans les tests, les warnings ou un
      // éventuel reporting opérateur.
      !hasConflicts &&
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

    // Mini-fix 11A-2 :
    // si `media.json` est skippé, aucun nouvel asset binaire média ne doit
    // être écrit. Sinon on créerait des fichiers orphelins que ce run ne peut
    // pas référencer honnêtement, puisque le JSON média conservé n'est pas
    // réécrit.
    //
    // On garde volontairement cette garde ici, au point où l'on connaît à la
    // fois :
    // - la décision de merge sur l'artefact `media.json` ;
    // - la liste des assets candidats à télécharger.
    //
    // Non-objectif explicite :
    // - on ne corrige pas rétroactivement un vieux `media.json` existant ;
    // - on évite seulement d'ajouter du nouveau bruit disque quand le JSON
    //   média reste inchangé.
    final assetBatch =
        mediaPlan.action == PokemonExternalImportArtifactAction.skip
            ? _buildSkippedMediaAssetBatch(
                species: species,
                candidates: assetCandidates,
              )
            : await _downloadBestEffortAssets(
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
    try {
      final resolvedMedia = await _resolvePersistedMediaFromDisk(
        workspace,
        media,
      );

      if (mediaPlan.action == PokemonExternalImportArtifactAction.create ||
          mediaPlan.action == PokemonExternalImportArtifactAction.overwrite) {
        await writeRepository.saveMedia(workspace, resolvedMedia);
      }
    } on Object catch (error, stackTrace) {
      // Audit de clôture 11A :
      // si la phase finale de persistance média casse, on ne veut pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun `media.json`.
      //
      // On nettoie donc uniquement les fichiers :
      // - écrits dans ce run (`wasWritten`) ;
      // - inexistants avant le run (`!existedBefore`).
      //
      // Non-objectifs assumés de ce mini-fix :
      // - on ne tente pas de rollback les JSON déjà écrits plus tôt ;
      // - on ne restaure pas le contenu d'un asset préexistant écrasé avec
      //   succès, car ce cas ne crée pas de ref fantôme ni d'asset orphelin ;
      // - on ne crée pas de transaction globale artificielle pour la 11A.
      await _cleanupNewMediaAssetsAfterPersistenceFailure(
        workspace,
        assetBatch.results,
      );
      Error.throwWithStackTrace(error, stackTrace);
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
        if (!_isCompatibleBinaryAsset(candidate, asset)) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} download used a missing or incompatible content-type (${asset.contentType ?? 'unknown'}); the existing local asset was kept.'
              : '${candidate.label} download used a missing or incompatible content-type (${asset.contentType ?? 'unknown'}) and no local asset exists; the media ref will be omitted.';
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

  // Nettoie uniquement les binaires créés par ce run si la persistance finale
  // du `media.json` échoue.
  //
  // Cette garde reste volontairement petite et locale :
  // - elle évite les assets orphelins ;
  // - elle ne change pas la sémantique des autres artefacts ;
  // - elle ne transforme pas le use case en moteur transactionnel global.
  Future<void> _cleanupNewMediaAssetsAfterPersistenceFailure(
    ProjectWorkspace workspace,
    List<PokemonExternalAssetDownloadResult> results,
  ) async {
    for (final result in results) {
      if (!result.wasWritten || result.existedBefore) {
        continue;
      }

      try {
        await workspace.deleteRelativeFile(result.relativePath);
      } catch (_) {
        // Best effort uniquement : on ne masque jamais l'erreur initiale de
        // persistance média avec une erreur secondaire de cleanup.
      }
    }
  }

  _DownloadedAssetBatch _buildSkippedMediaAssetBatch({
    required PokemonSpeciesFile species,
    required _PokemonExternalAssetCandidateBundle candidates,
  }) {
    if (candidates.candidates.isEmpty) {
      return const _DownloadedAssetBatch(
        results: <PokemonExternalAssetDownloadResult>[],
        warnings: <String>[],
      );
    }

    // Ce warning global est volontairement plus utile qu'une pseudo-liste de
    // téléchargements "non tentés" :
    // - il explique pourquoi rien n'a été écrit ;
    // - il rappelle l'invariant anti-assets-orphelins ;
    // - il évite de faire croire que chaque asset a été validé puis refusé.
    final message =
        'Existing media.json for "${species.id}" was kept because merge policy is skip_existing; no new binary media assets were downloaded in this run to avoid orphan files.';
    return _DownloadedAssetBatch(
      results: const <PokemonExternalAssetDownloadResult>[],
      warnings: <String>[message],
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

  bool _looksLikePngBytes(List<int> bytes) {
    if (bytes.length < 8) {
      return false;
    }
    const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var index = 0; index < pngSignature.length; index++) {
      if (bytes[index] != pngSignature[index]) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeOggBytes(List<int> bytes) {
    if (bytes.length < 4) {
      return false;
    }
    return bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53;
  }

  bool _isGifContentType(String? contentType) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return normalized.contains('image/gif');
  }

  bool _isCompatibleBinaryAsset(
    _PokemonExternalAssetCandidate candidate,
    PokemonExternalBinaryAsset asset,
  ) {
    final normalized = asset.contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      // On n'accepte plus silencieusement un binaire "sans identité".
      // Quand le serveur oublie le `content-type`, on exige au minimum une
      // signature binaire compatible avec le format attendu :
      // - PNG pour les images ;
      // - OGG pour les cries.
      return candidate.label == 'Cri'
          ? _looksLikeOggBytes(asset.bytes)
          : _looksLikePngBytes(asset.bytes);
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

### Fichier complet — `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/ports/pokemon_write_repository.dart';
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
        'fail_on_conflict stays atomic even when only one artefact already exists',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // On provoque ici le cas le plus intéressant du point de vue produit :
      // un conflit partiel. Si l'atomicité promise par le use case casse,
      // l'import pourrait écrire learnset/evolution/media alors que l'espèce
      // principale est en conflit, ce qui rendrait le résultat trompeur.
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.species,
            )
            .action,
        PokemonExternalImportArtifactAction.conflict,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
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
        'skip_existing does not download new assets when media.json is already skipped',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // Ce cas verrouille précisément le coin restant du mini-fix 2 :
      // - `media.json` existe déjà, donc l'artefact media doit être `skip` ;
      // - aucun asset local n'existe encore ;
      // - si le pipeline continue malgré tout à télécharger les binaires,
      //   ils deviennent orphelins parce que le `media.json` conservé ne sera
      //   jamais réécrit dans ce run.
      //
      // On prépare donc volontairement un `media.json` minimal qui ne référence
      // aucun asset. Si l'import écrit ensuite des portraits/sprites/cries alors
      // que le JSON média est skippé, le bug est réel et reproductible.
      await writeRepository.saveMedia(
        workspace,
        const PokemonMediaFile(
          speciesId: 'bulbasaur',
          defaultFormId: 'base',
          variants: <String, PokemonMediaVariant>{
            'base': PokemonMediaVariant(),
          },
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.media,
            )
            .action,
        PokemonExternalImportArtifactAction.skip,
      );
      expect(result.downloadedAssetCount, 0);
      expect(result.downloadedAssets, isEmpty);
      expect(media.variants['base']?.portrait, isNull);
      expect(media.variants['base']?.frontStatic, isNull);
      expect(media.variants['base']?.backStatic, isNull);
      expect(media.variants['base']?.cry, isNull);
      expect(
        result.warnings.join('\n'),
        contains('media.json'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
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

    test('rejects incompatible image content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[9, 9, 9, 9]),
        contentType: 'image/jpeg',
      );

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
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps a local image when redownload content-type is incompatible',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[17, 18, 19]);
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[17, 18, 19]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible cry content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository
              .binaryAssets['https://assets.example.test/bulbasaur/cry.ogg'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
        bytes: Uint8List.fromList(<int>[4, 4, 4, 4]),
        contentType: 'audio/mpeg',
      );

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
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (audio/mpeg)'),
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

    test('cleans up newly written media assets if media.json persistence fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final useCase = ImportExternalPokemonSpeciesUseCase(
        externalSourceRepository: externalSourceRepository,
        writeRepository: _ThrowingMediaWriteRepository(
          delegate: writeRepository,
        ),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Simulated media write failure'),
          ),
        ),
      );

      // Ce test verrouille un invariant subtil de clôture 11A :
      // si le `media.json` final ne peut pas être écrit, on ne doit pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun JSON local.
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );

      // Le mini-fix ne touche pas à `project.json`. On le reverrouille ici
      // même sur un échec tardif du pipeline.
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects a headerless incompatible image payload without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        // Signature JPEG volontairement incompatible.
        bytes: Uint8List.fromList(
          <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46],
        ),
        contentType: null,
      );

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
        contains('missing or incompatible content-type'),
      );
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

/// Repository décorateur volontairement minuscule pour reproduire un échec
/// tardif sur `saveMedia`.
///
/// Ce fake sert uniquement à prouver un invariant de clôture 11A :
/// si l'écriture finale du `media.json` casse, le pipeline ne doit pas laisser
/// d'assets binaires nouvellement créés sans référence locale persistée.
///
/// Non-objectifs explicites :
/// - ne pas changer la sémantique des autres écritures ;
/// - ne pas simuler un filesystem complet ;
/// - ne pas introduire une nouvelle abstraction de prod.
class _ThrowingMediaWriteRepository implements PokemonWriteRepository {
  const _ThrowingMediaWriteRepository({
    required this.delegate,
  });

  final PokemonWriteRepository delegate;

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) {
    return delegate.saveBinaryAsset(
      workspace,
      relativePath: relativePath,
      bytes: bytes,
    );
  }

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) {
    return delegate.saveCatalogByKey(workspace, catalogKey, catalog);
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) {
    return delegate.saveEvolution(workspace, evolution);
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) {
    return delegate.saveLearnset(workspace, learnset);
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) {
    throw const EditorPersistenceException(
      'Simulated media write failure',
    );
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) {
    return delegate.saveSpecies(workspace, species);
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

## 17. Manifest des assets binaires si applicable

Aucun asset binaire n’a été ajouté au repo pendant cette clôture 11A.

Les seuls assets binaires manipulés pendant les tests ont vécu dans des workspaces temporaires sous `Directory.systemTemp`, puis ont été nettoyés par `tearDown()` ou supprimés par le mini-fix sous test.
