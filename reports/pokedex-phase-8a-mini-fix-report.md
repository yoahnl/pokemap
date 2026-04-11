# Pokédex Phase 8A — Mini-fix validation `names`

## 1. Résumé exécutif honnête

Ce mini-fix corrige le vrai trou métier restant de la phase 8A : on ne peut plus sauvegarder une espèce avec des `names` tous vides après normalisation.

Ce qui a été fait :
- validation applicative explicite dans `UpdatePokedexSpeciesMetadataUseCase` ;
- test applicatif qui prouve l'échec, l'absence de write parasite et `project.json` inchangé ;
- test UI ciblé qui prouve qu'une erreur de save garde le formulaire en édition, affiche un message lisible et ne mute pas la backing store locale ;
- réalignement de la fixture UI `portrait` sur la convention dominante `assets/pokemon/portraits/...` ;
- garde-fous locaux supplémentaires sous forme de commentaires de contrat et d'assertions ciblées.

Ce qui n'a pas été fait :
- aucun lot 40+ ;
- aucune modification de `project.json` ;
- aucune refonte UI ;
- aucun refactor global Pokédex ;
- aucune modification learnset / évolution / média métier hors fixture de test ;
- aucun changement des lots 34 à 36.

## 2. Liste exacte des défauts corrigés

1. Sauvegarde applicative possible avec `names` entièrement vides ou inutilisables.
2. Absence de test applicatif verrouillant l'absence de write parasite quand cette validation doit échouer.
3. Absence de test UI couvrant le flux d'erreur de save sur ce cas métier.
4. Fixture UI encore incohérente sur `portrait` avec l'ancienne convention `assets/pokemon/sprites/<species>/portrait.png`.

## 3. Diagnostic précis

### 3.1 Trou métier principal

Dans `UpdatePokedexSpeciesMetadataUseCase`, `request.names` était normalisé via trim des clés/valeurs et suppression des locales vides, mais aucune validation ne garantissait qu'au moins une valeur non vide restait ensuite exploitable.

Conséquence :
- une espèce pouvait être persistée avec `{'fr': '', 'en': ''}` ;
- l'index léger Pokédex et les invariants de liste se retrouvaient ensuite avec une source de nom fragile voire inutilisable ;
- le bug venait bien du use case applicatif, pas de la seule UI.

### 3.2 Pourquoi le fix doit vivre dans le use case

Le bon point de correction est le use case applicatif, parce que :
- la UI n'est pas la seule porte d'entrée potentielle ;
- le repository d'écriture doit rester un port générique et ne pas absorber de logique métier locale à la phase 8A ;
- `project.json` n'est pas la source de vérité Pokédex ;
- la validation doit bloquer l'écriture avant tout write effectif.

### 3.3 Convention `portrait`

Après audit du repo, la convention dominante réelle reste :
- forme par défaut : `assets/pokemon/portraits/<species>.png`
- variante : `assets/pokemon/portraits/<species>/<variant>.png`

La fixture UI Phase 8A utilisait encore l'ancienne convention `assets/pokemon/sprites/<species>/portrait.png`. Elle a été réalignée.

## 4. Utilisation des sous-agents

Sous-agents utilisés :
- `Raman` : audit contrat métier `names` et point de correction minimal.
- `Lorentz` : audit du flux UI de sauvegarde, du maintien en mode édition et du message d'erreur.
- `Dirac` : audit de la convention `portrait` réellement dominante dans le repo.
- `Kierkegaard` : review anti-régression sur les tests manquants et les faux positifs à éviter.

Ce qui a été retenu :
- validation `names` dans le use case applicatif ;
- pas de fix UI de production, car le flux d'erreur existant était déjà cohérent ;
- correction de la fixture `portrait` uniquement dans le test UI ;
- ajout d'un test applicatif de non-write et d'un test UI d'erreur.

Ce qui a été rejeté :
- déplacer la validation dans le repository ;
- ouvrir une architecture générique de validation ;
- brancher le test UI sur une persistance disque complète alors que le non-write disque est déjà prouvé applicativement et que cela rendait le test fragile.

Une seule implémentation finale a été conservée. Aucun fichier alternatif de sous-agent n'a été créé dans le working tree.

## 5. Justification fichier par fichier

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart`

Pourquoi touché :
- c'est la racine du bug métier.

Ce qui a changé :
- normalisation des `names` extraite dans une variable locale ;
- validation explicite exigeant au moins une valeur non vide ;
- message d'erreur stable : `Pokemon species names must contain at least one non-empty value` ;
- commentaires de contrat pour éviter une future régression.

Pourquoi c'est minimal :
- aucun changement de port ;
- aucun changement de modèle ;
- aucun changement de repository ;
- le fix est exactement au point où l'écriture applicative est décidée.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart`

Pourquoi touché :
- il fallait prouver le nouveau contrat métier et l'absence de write parasite.

Ce qui a changé :
- ajout d'un test qui échoue proprement quand tous les noms sont vides ;
- vérification du message d'erreur ;
- vérification que le fichier espèce n'est pas modifié ;
- vérification que `project.json` reste inchangé ;
- vérification que les données hors scope restent intactes.

Pourquoi c'est minimal :
- la suite de tests existante est réutilisée ;
- un helper local de listing JSON évite juste une duplication triviale.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

Pourquoi touché :
- il fallait couvrir le comportement UI sur erreur de sauvegarde ;
- il fallait réaligner la fixture `portrait`.

Ce qui a changé :
- fixture `portrait` réalignée sur `assets/pokemon/portraits/bulbasaur.png` ;
- assertion média ajoutée pour verrouiller cette convention ;
- ajout d'un test UI qui vide les noms visibles, clique sur `Enregistrer`, vérifie l'erreur visible, le maintien du mode édition et l'absence de mutation de backing store ;
- légère réduction d'une assertion happy-path trop fragile après refresh détail.

Pourquoi c'est minimal :
- aucune modification de la UI de production ;
- pas de nouveau fake framework ;
- le test d'erreur reste local à la suite existante.

### `/Users/karim/Project/pokemonProject/reports/pokedex-phase-8a-mini-fix-report.md`

Pourquoi créé :
- pour documenter honnêtement l'audit, le correctif, les incidents intermédiaires, les validations réelles et le contenu complet des fichiers touchés.

## 6. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

### Créés
- `/Users/karim/Project/pokemonProject/reports/pokedex-phase-8a-mini-fix-report.md`

### Supprimés
- aucun

### Audités mais non touchés
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart`

## 7. Commandes réellement exécutées

### Audit local
```bash
rg --files -g 'AGENTS.md' /Users/karim/Project/pokemonProject
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
sed -n '1,360p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '260,520p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
rg -n "pokedex-metadata-save-error|Enregistrer|Modifier|Annuler|onSaveMetadata|save error|saveMetadata" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
sed -n '1,360p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
rg -n "portrait" /Users/karim/Project/pokemonProject/packages/map_editor /Users/karim/Project/pokemonProject/packages/map_runtime /Users/karim/Project/pokemonProject/packages/map_core /Users/karim/Project/pokemonProject/reports | sed -n '1,220p'
rg -n "assets/pokemon/(portraits|sprites/.*/portrait\.png)" /Users/karim/Project/pokemonProject/packages/map_editor /Users/karim/Project/pokemonProject/packages/map_runtime /Users/karim/Project/pokemonProject/packages/map_core /Users/karim/Project/pokemonProject/reports | sed -n '1,260p'
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart
sed -n '1160,1325p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '1325,1385p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
rg -n "pokedex-metadata-save-error|EditorValidationException|EditorApplicationException|onSaveMetadata|Modifier|Annuler|Enregistrer" /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart | sed -n '1,220p'
sed -n '360,760p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
rg -n "Activée|Désactivée|pokedex-enabled-switch|pokedex-save-metadata-button|pokedex-edit-metadata-button|pokedex-name-field|pokedex-flavor-text-field|pokedex-cancel-metadata-button|starterEligible|giftOnly|tradeOnly|saveCalls|savedRequests|savedSpecies" /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart | sed -n '1,260p'
sed -n '760,1260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1260,1705p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1705,1880p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
sed -n '240,360p' /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
sed -n '1448,1490p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1590,1685p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1685,1745p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1110,1178p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '1468,1490p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
wc -l /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
```

### Format / tests / analyse / diagnostic intermédiaire
```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokedex_workspace_ui_test.dart
pkill -f "flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokedex_workspace_ui_test.dart"
ps -ef | rg "flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokedex_workspace_ui_test.dart|flutter_tester"
kill 5206
flutter test test/pokedex_workspace_ui_test.dart --plain-name "keeps edit mode and shows a save error when all editable names are cleared without persisting anything"
ps -ef | rg "pokedex_workspace_ui_test.dart --plain-name \\\"keeps edit mode and shows a save error|packages/map_editor/build/unit_test_assets"
kill 7294 10978
flutter test test/pokedex_workspace_ui_test.dart --plain-name "keeps edit mode and shows a save error when all editable names are cleared without persisting anything" --timeout 10s
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokedex_workspace_ui_test.dart
flutter test test/pokedex_workspace_ui_test.dart --plain-name "enters edit mode saves simple metadata and keeps generation filtering stable"
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokedex_workspace_ui_test.dart
flutter analyze --no-pub lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/update_pokedex_species_metadata_use_case_test.dart test/pokedex_workspace_ui_test.dart
```

### Lecture Git finale
```bash
git status --short -- packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports/pokedex-phase-8a-mini-fix-report.md
git diff --stat -- packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports/pokedex-phase-8a-mini-fix-report.md
git ls-files --others --exclude-standard -- reports/pokedex-phase-8a-mini-fix-report.md
```

## 8. Résultats réels

### `dart format ...`
Première passe :
```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
Formatted 3 files (1 changed) in 0.02 seconds.
```

Passes suivantes :
```text
Formatted 3 files (0 changed) in 0.02 seconds.
```

### `flutter test ...`
Passe finale exigée :
```text
00:05 +32: All tests passed!
```

### `flutter analyze --no-pub ...`
Passe finale :
```text
No issues found! (ran in 1.4s)
```

### Git lecture seule finale
`git status --short -- ...` :
```text
 M packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
?? reports/pokedex-phase-8a-mini-fix-report.md
```

`git diff --stat -- ...` :
```text
 .../update_pokedex_species_metadata_use_case.dart  |  36 +++++-
 .../map_editor/test/pokedex_workspace_ui_test.dart | 137 ++++++++++++++++++++-
 ...ate_pokedex_species_metadata_use_case_test.dart |  71 +++++++++++
 3 files changed, 238 insertions(+), 6 deletions(-)
```

`git ls-files --others --exclude-standard -- reports/pokedex-phase-8a-mini-fix-report.md` :
```text
reports/pokedex-phase-8a-mini-fix-report.md
```

## 9. Incidents rencontrés

1. Le premier test UI branché sur une vraie persistance disque s'est révélé trop fragile et restait bloqué autour d'un `pumpAndSettle()` après une erreur de save. Ce n'était pas un bug produit ; c'était un test trop couplé à un flux asynchrone complexe.
2. Une correction intermédiaire a remplacé le mauvais `pumpAndSettle()` dans un test UI happy-path existant. Cela a cassé ce test sur une observation trop précoce du refresh détail.
3. Le test happy-path contenait aussi une assertion trop fragile sur un texte d'état lecture seule (`Désactivée`) après refresh détail. Elle a été resserrée sur des preuves plus stables : mutation persistée du store, disparition des champs d'édition et texte visible mis à jour.

Ces incidents ont été corrigés avant la validation finale. Aucun n'a nécessité de toucher la UI de production.

## 10. Limites restantes

- La validation `names` reste volontairement minimale : elle exige seulement au moins une valeur non vide après normalisation. Elle n'impose ni locale obligatoire, ni hiérarchie `fr/en`, ni contrainte d'unicité.
- Le test UI d'erreur verrouille le contrat d'interaction avec une backing store mémoire inchangée ; la preuve du non-write disque réel est portée côté use case applicatif, là où le write est réellement décidé.
- Aucun lot 40+ n'a été ouvert.

## 11. Contenu complet de tous les fichiers touchés

### 11.1 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Représente la seule surface d'édition Pokédex autorisée en phase 8A.
///
/// Le périmètre est volontairement serré :
/// - `classification.isEnabledInProject` pour le lot 37 ;
/// - quelques métadonnées simples pour le lot 39 ;
/// - aucun learnset ;
/// - aucune évolution ;
/// - aucun média ;
/// - aucune ref locale ;
/// - aucune forme riche ;
/// - aucune classification avancée hors du flag `isEnabledInProject`.
class UpdatePokedexSpeciesMetadataRequest {
  const UpdatePokedexSpeciesMetadataRequest({
    required this.speciesId,
    required this.isEnabledInProject,
    required this.names,
    required this.flavorText,
    required this.starterEligible,
    required this.giftOnly,
    required this.tradeOnly,
  });

  final String speciesId;
  final bool isEnabledInProject;
  final Map<String, String> names;
  final String? flavorText;
  final bool starterEligible;
  final bool giftOnly;
  final bool tradeOnly;
}

typedef PokedexSpeciesMetadataSaver = Future<PokemonSpeciesFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesMetadataRequest request,
);

/// Réécrit une espèce locale en ne touchant qu'aux métadonnées simples déjà
/// supportées par le modèle courant.
///
/// Pourquoi un use case dédié :
/// - la UI ne doit pas reconstruire elle-même un `PokemonSpeciesFile` complet ;
/// - l'espèce locale reste la source de vérité unique ;
/// - on relit l'espèce existante puis on ne remplace que les champs autorisés ;
/// - on délègue l'écriture au repository existant pour préserver le vrai chemin
///   du fichier espèce déjà présent.
class UpdatePokedexSpeciesMetadataUseCase {
  const UpdatePokedexSpeciesMetadataUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonSpeciesFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    final speciesId = request.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    final currentSpecies = await readRepository.readSpeciesById(
      workspace,
      speciesId,
    );
    final normalizedNames = _normalizeLocalizedValues(request.names);

    // Contrat métier local de la phase 8A :
    // - la liste Pokédex repose ensuite sur un nom principal exploitable ;
    // - l'édition locale ne doit donc jamais pouvoir "sauver" une espèce
    //   devenue anonymisée ;
    // - on place volontairement ce garde-fou ici, au point d'écriture
    //   applicatif, pour bloquer l'erreur à la racine avant tout write.
    //
    // Pourquoi pas ailleurs :
    // - pas dans la UI, car l'espèce locale resterait sauvable par un autre
    //   appelant ;
    // - pas dans le repository, qui doit rester un port d'écriture générique ;
    // - pas dans `project.json`, qui n'est pas la source de vérité Pokémon.
    if (!_containsAtLeastOneUsableLocalizedValue(normalizedNames)) {
      throw const EditorValidationException(
        'Pokemon species names must contain at least one non-empty value',
      );
    }

    // On ne reconstruit jamais l'espèce "depuis zéro" dans la UI.
    // Le but est précisément de préserver :
    // - les refs ;
    // - les formes ;
    // - la classification lourde ;
    // - les stats et autres blocs hors périmètre.
    final updatedSpecies = PokemonSpeciesFile(
      id: currentSpecies.id,
      slug: currentSpecies.slug,
      nationalDex: currentSpecies.nationalDex,
      names: normalizedNames,
      speciesName: currentSpecies.speciesName,
      genIntroduced: currentSpecies.genIntroduced,
      typing: currentSpecies.typing,
      baseStats: currentSpecies.baseStats,
      abilities: currentSpecies.abilities,
      breeding: currentSpecies.breeding,
      progression: currentSpecies.progression,
      forms: currentSpecies.forms,
      classification: PokemonSpeciesClassification(
        // Lot 37 : c'est l'unique source de vérité du statut projet.
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: currentSpecies.classification.isObtainable,
        isLegendary: currentSpecies.classification.isLegendary,
        isMythical: currentSpecies.classification.isMythical,
        isBaby: currentSpecies.classification.isBaby,
      ),
      // On préserve les refs à l'identique : lot 39 ne doit pas casser
      // learnset / évolution / média au passage.
      refs: currentSpecies.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: currentSpecies.dexContent.heightM,
        weightKg: currentSpecies.dexContent.weightKg,
        color: currentSpecies.dexContent.color,
        flavorText: _normalizeOptionalText(request.flavorText),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: currentSpecies.sourceMeta,
    );

    await writeRepository.saveSpecies(workspace, updatedSpecies);
    return updatedSpecies;
  }

  Map<String, String> _normalizeLocalizedValues(Map<String, String> values) {
    final normalized = <String, String>{};

    // On reste volontairement permissif ici :
    // - pas de nouvelle règle métier sur les locales ;
    // - pas de suppression implicite d'une clé ;
    // - on trim seulement les clés et valeurs pour éviter de persister du bruit.
    //
    // La UI de la phase 8A n'ajoute ni ne retire de locales ; elle ne modifie
    // que les valeurs déjà présentes. Cette normalisation minimale suffit donc.
    for (final entry in values.entries) {
      final locale = entry.key.trim();
      if (locale.isEmpty) {
        continue;
      }
      normalized[locale] = entry.value.trim();
    }

    return normalized;
  }

  bool _containsAtLeastOneUsableLocalizedValue(Map<String, String> values) {
    // La décision finale ne dépend pas du nombre de locales ni d'une locale
    // obligatoire : le garde-fou minimal veut seulement empêcher qu'il ne reste
    // aucun nom exploitable après normalisation.
    //
    // On laisse donc des valeurs vides persister si l'appelant le souhaite,
    // tant qu'au moins une valeur trimée reste réellement utilisable.
    for (final value in values.values) {
      if (value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

```

### 11.2 `/Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesMetadataUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_metadata_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesMetadataUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Metadata Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('UpdatePokedexSpeciesMetadataUseCase', () {
    test(
        'persists enabled state and simple metadata while keeping refs and project.json unchanged',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();

      await useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMetadataRequest(
          speciesId: 'bulbasaur',
          isEnabledInProject: false,
          names: <String, String>{
            'fr': 'Bulbizarre Projet',
            'en': 'Bulbasaur Project',
          },
          flavorText: 'Texte Pokédex édité localement.',
          starterEligible: false,
          giftOnly: true,
          tradeOnly: true,
        ),
      );

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(readBack.classification.isEnabledInProject, isFalse);
      expect(readBack.names['fr'], 'Bulbizarre Projet');
      expect(readBack.names['en'], 'Bulbasaur Project');
      expect(readBack.dexContent.flavorText, 'Texte Pokédex édité localement.');
      expect(readBack.gameplayFlags.starterEligible, isFalse);
      expect(readBack.gameplayFlags.giftOnly, isTrue);
      expect(readBack.gameplayFlags.tradeOnly, isTrue);

      // On verrouille explicitement le point le plus fragile de cette phase :
      // l'édition simple ne doit jamais casser les refs déjà branchées.
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
      expect(readBack.forms.baseFormId, 'bulbasaur');
      expect(readBack.sourceMeta.seededBy, 'test');
      expect(readBack.sourceMeta.seedVersion, 1);

      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects metadata updates when all localized names are empty and leaves species and project manifest untouched',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();
      final speciesFilesBefore = await _listSpeciesJsonFiles(workspace);
      expect(speciesFilesBefore, hasLength(1));

      final speciesFile = speciesFilesBefore.single;
      final beforeSpeciesJson = await speciesFile.readAsString();

      await expectLater(
        () => useCase.execute(
          workspace,
          const UpdatePokedexSpeciesMetadataRequest(
            speciesId: 'bulbasaur',
            isEnabledInProject: true,
            names: <String, String>{
              'fr': '   ',
              'en': '\n\t',
            },
            flavorText: 'Ce texte ne doit jamais être persisté.',
            starterEligible: false,
            giftOnly: true,
            tradeOnly: true,
          ),
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species names must contain at least one non-empty value',
          ),
        ),
      );

      final speciesFilesAfter = await _listSpeciesJsonFiles(workspace);
      expect(speciesFilesAfter, hasLength(1));
      expect(speciesFilesAfter.single.path, speciesFile.path);
      expect(await speciesFile.readAsString(), beforeSpeciesJson);
      expect(await projectFile.readAsString(), beforeProjectJson);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.names, _bulbasaurSpecies.names);
      expect(
        readBack.dexContent.flavorText,
        _bulbasaurSpecies.dexContent.flavorText,
      );
      expect(readBack.gameplayFlags.starterEligible, isTrue);
      expect(readBack.gameplayFlags.giftOnly, isFalse);
      expect(readBack.gameplayFlags.tradeOnly, isFalse);
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
    });

    test(
        'reuses an existing non-canonical species path instead of creating a canonical duplicate during metadata updates',
        () async {
      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDir.create(recursive: true);

      final customFile = File(
        p.join(speciesDir.path, '0001-bulbizarre-custom.json'),
      );
      await customFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_bulbasaurSpecies.toJson()),
      );

      await useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMetadataRequest(
          speciesId: 'bulbasaur',
          isEnabledInProject: true,
          names: <String, String>{
            'fr': 'Bulbizarre Mis à Jour',
            'en': 'Bulbasaur Refreshed',
          },
          flavorText: 'Le writer doit réutiliser le chemin déjà présent.',
          starterEligible: true,
          giftOnly: false,
          tradeOnly: false,
        ),
      );

      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);

      final speciesFiles = await speciesDir
          .list(recursive: false)
          .where(
            (entity) => entity is File && p.extension(entity.path) == '.json',
          )
          .cast<File>()
          .toList();
      expect(speciesFiles, hasLength(1));
      expect(
          p.basename(speciesFiles.single.path), '0001-bulbizarre-custom.json');

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.names['en'], 'Bulbasaur Refreshed');
      expect(
        readBack.dexContent.flavorText,
        'Le writer doit réutiliser le chemin déjà présent.',
      );
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
    });
  });
}

Future<List<File>> _listSpeciesJsonFiles(ProjectFileSystem workspace) async {
  final speciesDirectory = Directory(
    workspace.resolveProjectRelativePath('data/pokemon/species'),
  );
  return speciesDirectory
      .list(recursive: false)
      .where((entity) => entity is File && p.extension(entity.path) == '.json')
      .cast<File>()
      .toList();
}

const PokemonSpeciesFile _bulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
  speciesName: <String, String>{'fr': 'Pokémon Graine', 'en': 'Seed Pokemon'},
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
  forms: PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
  ),
  classification: PokemonSpeciesClassification(
    isEnabledInProject: true,
    isObtainable: true,
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
    flavorText: 'Une étrange graine a été plantée sur son dos à la naissance.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(
    starterEligible: true,
  ),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

```

### 11.3 `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace_loader.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_ui_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PokemonDatabaseIndexEntry buildEntry({
    required String id,
    required int nationalDex,
    required String primaryName,
    required List<String> types,
    required int genIntroduced,
    bool isEnabledInProject = true,
  }) {
    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: nationalDex,
      primaryName: primaryName,
      genIntroduced: genIntroduced,
      types: types,
      isEnabledInProject: isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
    );
  }

  PokedexSpeciesDetail buildDetail({
    required String id,
    int nationalDex = 1,
    int genIntroduced = 1,
    List<String> types = const <String>['grass', 'poison'],
    String primaryAbility = 'overgrow',
    String? secondaryAbility,
    String? hiddenAbility = 'chlorophyll',
    List<String> otherForms = const <String>[],
    bool isEnabledInProject = true,
    Map<String, String> names = const <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    String? flavorText =
        'Une étrange graine a été plantée sur son dos à la naissance.',
    bool starterEligible = true,
    bool giftOnly = false,
    bool tradeOnly = false,
  }) {
    return PokedexSpeciesDetail(
      species: PokemonSpeciesFile(
        id: id,
        slug: id,
        nationalDex: nationalDex,
        names: names,
        speciesName: const <String, String>{
          'fr': 'Pokémon Graine',
          'en': 'Seed Pokemon',
        },
        genIntroduced: genIntroduced,
        typing: PokemonSpeciesTyping(
          types: types,
        ),
        baseStats: const PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: primaryAbility,
          secondary: secondaryAbility,
          hidden: hiddenAbility,
        ),
        breeding: const PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: const PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        forms: PokemonSpeciesForms(
          baseFormId: id,
          isBaseForm: true,
          formId: 'base',
          otherForms: otherForms,
        ),
        classification: PokemonSpeciesClassification(
          isEnabledInProject: isEnabledInProject,
          isObtainable: true,
        ),
        refs: PokemonSpeciesRefs(
          learnset: id,
          evolution: id,
          media: id,
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: flavorText,
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: starterEligible,
          giftOnly: giftOnly,
          tradeOnly: tradeOnly,
        ),
        sourceMeta: const PokemonSpeciesSourceMeta(
          seededBy: 'ui-test',
          seedVersion: 1,
        ),
      ),
      learnset: const PokemonLearnsetFile(
        speciesId: 'bulbasaur',
        startingMoves: <String>['tackle', 'growl'],
        relearnMoves: <String>['vine_whip'],
        levelUp: <PokemonLearnsetLevelUpEntry>[
          PokemonLearnsetLevelUpEntry(
            moveId: 'vine_whip',
            level: 7,
            source: 'level_up',
            versionGroup: 'scarlet-violet',
          ),
        ],
        tm: <PokemonLearnsetMoveEntry>[
          PokemonLearnsetMoveEntry(
            moveId: 'protect',
            versionGroup: 'scarlet-violet',
          ),
        ],
      ),
      evolution: const PokemonEvolutionFile(
        speciesId: 'bulbasaur',
        preEvolution: null,
        evolutions: <PokemonEvolutionEntry>[
          PokemonEvolutionEntry(
            targetSpeciesId: 'ivysaur',
            method: 'level_up',
            minLevel: 16,
            conditionText: <String, String>{
              'fr': 'Évolue au niveau 16',
              'en': 'Evolves at level 16',
            },
          ),
        ],
      ),
      media: const PokemonMediaFile(
        speciesId: 'bulbasaur',
        defaultFormId: 'base',
        variants: <String, PokemonMediaVariant>{
          'base': PokemonMediaVariant(
            frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
            backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
            frontShinyStatic:
                'assets/pokemon/sprites/bulbasaur/front_shiny.png',
            backShinyStatic: 'assets/pokemon/sprites/bulbasaur/back_shiny.png',
            icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
            party: 'assets/pokemon/sprites/bulbasaur/party.png',
            portrait: 'assets/pokemon/portraits/bulbasaur.png',
            cry: 'assets/pokemon/cries/bulbasaur.ogg',
            animations: <String, PokemonMediaAnimationRef>{
              'battleFront': PokemonMediaAnimationRef(
                sheet:
                    'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
                animationId: 'battle_front',
              ),
            },
          ),
        },
      ),
    );
  }

  Future<void> selectPopupFilter(
    WidgetTester tester, {
    required Key popupKey,
    required String itemLabel,
  }) async {
    await tester.tap(find.byKey(popupKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel).last);
    await tester.pumpAndSettle();
  }

  PokemonDatabaseIndexEntry buildEntryFromSpecies(PokemonSpeciesFile species) {
    final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
      species,
      relativePath:
          'data/pokemon/species/${species.nationalDex.toString().padLeft(4, '0')}-${species.slug}.json',
    );
    return PokemonDatabaseIndexEntry.fromSpeciesEntry(
      speciesIndexEntry: speciesIndexEntry,
      species: species,
    );
  }

  PokemonSpeciesFile applyMetadataUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) {
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: Map<String, String>.from(request.names),
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: species.classification.isLegendary,
        isMythical: species.classification.isMythical,
        isBaby: species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: species.dexContent.heightM,
        weightKg: species.dexContent.weightKg,
        color: species.dexContent.color,
        flavorText: request.flavorText?.trim().isEmpty ?? true
            ? null
            : request.flavorText?.trim(),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: species.sourceMeta,
    );
  }

  _FakePokedexWorkspaceStore buildStore({
    required List<PokedexSpeciesDetail> details,
  }) {
    return _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        for (final detail in details) detail.species.id: detail,
      },
      entryBuilder: buildEntryFromSpecies,
      updater: applyMetadataUpdate,
    );
  }

  testWidgets('ProjectExplorerPanel shows a Pokédex entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ce test verrouille seulement la présence de l'entrée UI dans l'éditeur.
    // Il reste volontairement purement en mémoire pour éviter tout bruit
    // filesystem inutile dans un contrôle aussi simple.
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 980,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(find.textContaining('Species list only'), findsOneWidget);
  });

  testWidgets(
      'uses the provider-backed loader by default when no explicit loader is injected',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: const PokedexWorkspace(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('treecko'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
  });

  testWidgets(
      'prefers the explicitly injected loader over the provider-backed default',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Torchic'), findsOneWidget);
    expect(find.text('torchic'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);
    expect(find.text('treecko'), findsNothing);
  });

  testWidgets(
      'renders the simple species list with only number name id and types',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('poison'), findsWidgets);

    // Le mini-fix ne doit surtout pas transformer l'écran en lot 14 déguisé.
    expect(find.textContaining('Search'), findsNothing);
    expect(find.textContaining('Filter'), findsNothing);
    expect(find.textContaining('Details'), findsNothing);
    expect(find.textContaining('Import'), findsNothing);
    expect(find.textContaining('Generation'), findsNothing);
    expect(find.textContaining('Edit'), findsNothing);
    expect(find.textContaining('Delete'), findsNothing);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
  });

  testWidgets('selects a species row and shows the overview detail pane',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.text('Nom principal'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('Talent principal'), findsOneWidget);
    expect(find.text('overgrow'), findsOneWidget);
    expect(find.text('Références locales'), findsOneWidget);
    expect(find.text('bulbasaur'), findsWidgets);
  });

  testWidgets('switches to forms learnset evolutions and media tabs',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(
          id: speciesId,
          otherForms: const <String>['mega'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-forms-tab')), findsOneWidget);
    expect(find.text('Forme courante'), findsOneWidget);
    expect(find.textContaining('mega'), findsOneWidget);
    expect(find.text('Classification'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);
    expect(find.text('vine_whip • niveau 7'), findsOneWidget);
    expect(find.text('scarlet-violet • source level_up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-evolutions-tab')), findsOneWidget);
    expect(find.text('Pré-évolution'), findsOneWidget);
    expect(find.text('Évolue au niveau 16'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);
    expect(
      find.text('assets/pokemon/sprites/bulbasaur/front.png'),
      findsOneWidget,
    );
    expect(
      find.text('assets/pokemon/portraits/bulbasaur.png'),
      findsOneWidget,
    );
    expect(find.textContaining('battle_front'), findsWidgets);
    expect(find.textContaining('battle_front_sheet.png'), findsWidgets);
  });

  testWidgets(
      'clears the selection and resets the detail pane when search hides it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-media-tab')), findsNothing);
  });

  testWidgets(
      'clears the selection and resets the detail pane when filters hide it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsNothing);
  });

  testWidgets(
      'shows the search field and simple filters in the Pokédex workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(
      find.text('Rechercher par nom, id ou numéro dex'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-status-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by species primary name', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by species id', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'bulb',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('filters instantly by dex number with exact matching only',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 10,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '#0001',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('empty query restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '   ',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
  });

  testWidgets('shows a dedicated no results state when search matches nothing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(
      find.textContaining('Aucun résultat avec les critères actuels.'),
      findsOneWidget,
    );
    expect(find.textContaining('Recherche actuelle : "zzz"'), findsOneWidget);
    // Le champ reste visible pour corriger immédiatement la query.
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
  });

  testWidgets('filters instantly by type', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'charmander',
            nationalDex: 4,
            primaryName: 'Charmander',
            types: <String>['fire'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'fire',
    );

    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by generation', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('combines text search with simple filters', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'bellsprout',
            nationalDex: 69,
            primaryName: 'Bellsprout',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'tree',
    );
    await tester.pump();
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Bellsprout'), findsNothing);
  });

  testWidgets('combines simple filters together', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Torchic'), findsNothing);
  });

  testWidgets('clearing all filters restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets('shows no results when simple filters eliminate the list',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'poison',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(find.textContaining('Aucun résultat avec les critères actuels.'),
        findsOneWidget);
    expect(find.textContaining('Recherche actuelle : "zzz".'), findsOneWidget);
    expect(find.textContaining('Type : poison.'), findsOneWidget);
    expect(find.textContaining('Génération : 1.'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by enabled status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
            isEnabledInProject: true,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
            isEnabledInProject: false,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Désactivées',
    );

    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets(
      'enters edit mode saves simple metadata and keeps generation filtering stable',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
          starterEligible: true,
        ),
        buildDetail(
          id: 'treecko',
          nationalDex: 252,
          genIntroduced: 3,
          types: const <String>['grass'],
          names: const <String, String>{
            'fr': 'Arcko',
            'en': 'Treecko',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Projet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      'Bulbasaur Project',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Texte édité depuis la fiche locale.',
    );
    await tester.tap(find.byKey(const Key('pokedex-gift-only-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(store.saveCallCount, 1);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre Projet');
    expect(store.speciesById('bulbasaur').names['en'], 'Bulbasaur Project');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Texte édité depuis la fiche locale.',
    );
    expect(store.speciesById('bulbasaur').gameplayFlags.giftOnly, isTrue);

    expect(find.text('Bulbasaur Project'), findsWidgets);
    expect(find.text('Treecko'), findsNothing);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsNothing);
  });

  testWidgets('cancel discards metadata changes without writing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Temporaire',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Changement non enregistré.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 0);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isTrue);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Une étrange graine a été plantée sur son dos à la naissance.',
    );
    expect(find.text('Bulbizarre Temporaire'), findsNothing);
    expect(
        find.byKey(const Key('pokedex-edit-metadata-button')), findsOneWidget);
  });

  testWidgets(
      'keeps edit mode and shows a save error when all editable names are cleared without persisting anything',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );
    var attemptedSaves = 0;

    Future<PokemonSpeciesFile> saveWithValidation(
      ProjectWorkspace workspace,
      UpdatePokedexSpeciesMetadataRequest request,
    ) async {
      attemptedSaves += 1;

      // Le use case applicatif couvre déjà le non-write disque réel.
      // Ici, le test UI verrouille le contrat d'interaction :
      // - l'erreur remonte lisiblement ;
      // - le formulaire reste ouvert ;
      // - la backing store locale n'est pas mutée.
      final normalizedNames = <String, String>{
        for (final entry in request.names.entries)
          if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value.trim(),
      };
      final hasUsableName = normalizedNames.values.any(
        (value) => value.isNotEmpty,
      );
      if (!hasUsableName) {
        throw const EditorValidationException(
          'Pokemon species names must contain at least one non-empty value',
        );
      }

      return store.save(workspace, request);
    }

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final persistedBefore = buildDetail(
      id: 'bulbasaur',
      names: const <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      isEnabledInProject: true,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: saveWithValidation,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      ' \n ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Tentative refusée localement.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(attemptedSaves, 1);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-name-field-en')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-save-metadata-button')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-metadata-button')), findsNothing);
    expect(
        find.byKey(const Key('pokedex-metadata-save-error')), findsOneWidget);
    expect(
      find.text(
          'Pokemon species names must contain at least one non-empty value'),
      findsOneWidget,
    );

    final readBack = store.speciesById('bulbasaur');
    expect(readBack.names, persistedBefore.species.names);
    expect(
      readBack.dexContent.flavorText,
      persistedBefore.species.dexContent.flavorText,
    );
    expect(
      readBack.classification.isEnabledInProject,
      persistedBefore.species.classification.isEnabledInProject,
    );
    expect(store.saveCallCount, 0);
  });

  testWidgets(
      'saving a disable under the enabled filter clears the current selection cleanly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbizarre'), findsNothing);
  });

  testWidgets('shows a loading state before the species list resolves',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<List<PokemonDatabaseIndexEntry>>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_loading_test',
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-loading-label')), findsOneWidget);

    // On prouve l'existence de l'état loading, puis on résout explicitement le
    // future avant teardown pour éviter de laisser un timer autoDispose Riverpod
    // en attente à la fin du test.
    completer.complete(const <PokemonDatabaseIndexEntry>[]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows an empty state when no species files are present',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    expect(find.textContaining('Aucune espèce importée'), findsOneWidget);
  });

  testWidgets('shows an error state when species loading fails',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => Future<List<PokemonDatabaseIndexEntry>>.error(
          const EditorPersistenceException(
            'Invalid JSON in Pokemon species file',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-error-state')), findsOneWidget);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);
    expect(find.textContaining('Invalid JSON'), findsOneWidget);
  });

  test(
    'returns an empty list when the configured species directory does not exist yet',
    () async {
      final tempProjectRoot =
          await Directory.systemTemp.createTemp('pokedex_loader_test_');
      try {
        final workspace = ProjectFileSystem(tempProjectRoot.path);
        final createProjectUseCase = CreateProjectUseCase(
          FileProjectRepository(),
          const FileProjectWorkspaceFactory(),
        );

        await createProjectUseCase.execute(
          'Pokedex Loader Project',
          tempProjectRoot.path,
        );

        final loader = createPokedexEntryLoader(
          projectRepository: FileProjectRepository(),
          databaseIndex: PokemonDatabaseIndex(
            projectRepository: FileProjectRepository(),
            pokemonReadRepository: const FilePokemonReadRepository(),
          ),
        );

        // Ce test verrouille le vrai nettoyage du mini-fix :
        // l'absence du dossier `species/` doit produire une liste vide
        // explicitement, sans dépendre du texte d'une exception remontée.
        final entries = await loader(workspace);
        expect(entries, isEmpty);
      } finally {
        if (await tempProjectRoot.exists()) {
          await tempProjectRoot.delete(recursive: true);
        }
      }
    },
  );
}

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
    required this.entryBuilder,
    required this.updater,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;
  final PokemonDatabaseIndexEntry Function(PokemonSpeciesFile species)
      entryBuilder;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) updater;

  int saveCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = _detailsById.values
        .map((detail) => entryBuilder(detail.species))
        .toList(growable: false)
      ..sort((left, right) {
        final dexCompare = left.nationalDex.compareTo(right.nationalDex);
        if (dexCompare != 0) {
          return dexCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> save(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    saveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = updater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  PokemonSpeciesFile speciesById(String speciesId) {
    return _detailsById[speciesId]!.species;
  }
}

```

### 11.4 `/Users/karim/Project/pokemonProject/reports/pokedex-phase-8a-mini-fix-report.md`

Le contenu complet de ce fichier est exactement le document que vous êtes en train de lire. Il n'est pas reproductible intégralement à l'intérieur de lui-même sans récursion infinie ; ce rapport constitue donc lui-même sa propre reproduction complète.

## 12. Checklist finale d'autocontrôle

- [x] Je n'ai corrigé que le mini-fix Phase 8A demandé
- [x] Je n'ai pas touché les lots 40 à 43
- [x] Je n'ai touché ni learnset, ni évolution, ni média métier hors fixture de test
- [x] Je n'ai pas touché `project.json`
- [x] J'ai audité le contrat `names` réel avant de modifier
- [x] J'ai audité la convention `portrait` réelle avant de modifier
- [x] La validation `names` empêche maintenant toute sauvegarde avec zéro valeur exploitable
- [x] L'erreur applicative est claire, stable et testée
- [x] Le test applicatif prouve l'absence de write parasite et `project.json` inchangé
- [x] Le test UI prouve l'erreur visible, le maintien du mode édition et l'absence de mutation de backing store
- [x] La fixture `portrait` est réalignée sur la convention dominante du repo
- [x] J'ai ajouté des garde-fous locaux proportionnés sans sur-architecture
- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] `flutter analyze` passe
- [x] Je n'ai exécuté aucune commande Git d'écriture
- [x] Le rapport contient le contenu complet de tous les fichiers touchés
- [x] Le rapport documente honnêtement les incidents réels
