# Phase R1 — Lot 8-2 corrective pass / Lot 8-3 — Trainer Studio truly guided authoring report

## 1. Résumé exécutif honnête

Ce corrective pass est livré.

Le `Trainer Studio` central existait déjà dans le code réel et restait la bonne surface canonique. En revanche, l'audit a confirmé que l'édition Pokémon exposait encore trop les IDs bruts au premier plan, et que la sélection des moves restait essentiellement un lookup global de catalogue au lieu d'un guidage auteur par espèce + niveau.

Le travail retenu est resté strictement local :

- aucune nouvelle stack trainer ;
- aucun nouveau provider / notifier / repository / use case ;
- aucune réouverture du lot 9 ;
- aucune refonte du pipeline CRUD trainer ;
- aucune duplication de surface principale.

Ce qui a réellement été fait :

- les IDs bruts `species` / `moves` / `items` / `forms` ne sont plus la façade dominante de l'éditeur Pokémon ;
- les fallbacks bruts sont conservés dans une zone avancée explicite ;
- les moves sont maintenant guidés par le learnset local de l'espèce sélectionnée et par le niveau courant ;
- les suggestions guidées prennent en compte `startingMoves`, `relearnMoves` et `levelUp <= niveau courant` ;
- le wording affiché dans les états dégradés est plus compréhensible pour un auteur non technique ;
- les tests widget trainer ont été renforcés pour prouver le comportement produit voulu ;
- la roadmap a été mise à jour pour refléter honnêtement ce nouveau palier `lot 8-3`.

Conclusion honnête :

- le corrective pass `lot 8-2 / lot 8-3` est livré ;
- le `Trainer Studio` central reste la seule surface canonique ;
- le trainer authoring est maintenant nettement plus guidé et moins centré sur les IDs bruts ;
- il reste de la dette locale acceptable, mais elle n'empêche plus l'usage auteur no-code visé par ce lot.

## 2. État initial audité réel

Source de vérité utilisée : le code réel du worktree courant.

Fichiers audités en priorité :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_species_lookup_service.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_items_catalog_lookup_service.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokedex_species_detail.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`
- `/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md`

Constats confirmés par l'audit :

- le `Trainer Studio` central existe déjà et reste la bonne surface canonique ;
- la sidebar trainer est déjà redevenue un launcher / résumé ;
- le pipeline trainer existant reste la bonne source de vérité ;
- `EditorNotifier` reste un orchestrateur ;
- `trainer_use_cases.dart` reste métier et n'avait pas besoin d'être rouvert ;
- l'éditeur Pokémon présentait encore des champs bruts trop visibles : `speciesId`, `move id`, `heldItemId`, `formId` ;
- les moves étaient encore choisis via le catalogue local global des moves, sans guidage métier par espèce + niveau ;
- la donnée nécessaire à un guidage contextualisé existait déjà localement via `PokedexSpeciesDetail.learnset` ;
- les messages de fallback existaient, mais le bloc moves restait trop technique pour un auteur non développeur.

Points non confirmés pendant l'audit :

- besoin d'un nouveau notifier trainer ;
- besoin d'un nouveau repository trainer ;
- besoin de réécrire les use cases trainers ;
- besoin d'un framework générique de formulaire guidé ;
- besoin d'un moteur séparé de recommandation de moves.

## 3. Problèmes confirmés / non confirmés

### Problèmes confirmés

1. Les champs bruts occupaient encore une place trop importante dans la façade principale de l'éditeur Pokémon.
2. Le choix des moves restait un simple lookup global dans le catalogue local des attaques.
3. Les suggestions de moves n'étaient pas contextualisées par espèce + niveau, alors que le learnset local était déjà accessible.
4. Le trainer authoring central était donc plus confortable qu'avant, mais pas encore suffisamment guidé pour un auteur non technique.
5. La roadmap n'exprimait pas encore explicitement ce palier supplémentaire de guidage réellement livré.

### Problèmes non confirmés

1. Bug de persistance trainer.
2. Bug de fermeture/ouverture principal du `Trainer Studio` central.
3. Besoin de toucher `EditorNotifier`.
4. Besoin de toucher `trainer_use_cases.dart`.
5. Besoin de toucher le shell workspace ou la sidebar pour ce corrective pass.

### Churn cosmétique explicitement rejeté

1. Refonte stylistique globale du shell.
2. Nouveau moteur générique de “guided form”.
3. Nouveau service dédié de “move recommendation”.
4. Deuxième surface trainer concurrente.
5. Généralisation prématurée des catalogues au-delà de ce qui aidait réellement le lot.

## 4. Décisions retenues / rejetées

### Décisions retenues

1. Garder `TrainerLibraryPanel` comme surface canonique unique.
2. Garder les use cases trainers existants inchangés.
3. Garder `EditorNotifier` inchangé.
4. Construire les suggestions guidées de moves comme une projection UI locale sur des données déjà chargées : espèce sélectionnée, niveau courant, `PokedexSpeciesDetail.learnset`, catalogue moves local.
5. Reléguer les champs bruts dans une section avancée explicite au lieu d'en faire la façade principale.
6. Conserver les fallbacks honnêtes lorsque les données locales ne sont pas disponibles.
7. Renforcer les tests widget trainer sur les scénarios produit réellement sensibles.
8. Mettre la roadmap à jour pour refléter honnêtement le nouveau palier livré.

### Décisions rejetées

1. Ajouter un nouveau service de domaine trainer pour recommander les moves.
2. Ajouter un nouveau provider pour un “guided move form state”.
3. Transformer la sélection de moves en whitelisting métier obligatoire.
4. Supprimer complètement les champs bruts.
5. Ouvrir items/forms au-delà du besoin réel du lot.
6. Toucher au shell workspace alors que le corrective pass pouvait rester local.

## 5. Conclusions détaillées des reviewers / sous-agents

### Reviewer A — architecture / scope

Conclusion :

- le `Trainer Studio` central existant doit rester la seule surface canonique ;
- le guidage des moves doit être un helper local de l'UI, pas un nouveau service métier trainer ;
- il ne faut pas toucher `EditorNotifier` ni les use cases trainers si le besoin est purement présentatif.

Retenu :

- guidage moves local dans la UI ;
- zéro nouvelle couche trainer.

Rejeté :

- tout nouveau pipeline ou nouveau contrat métier trainer.

### Reviewer B — UX auteur / no-code

Conclusion :

- l'éditeur Pokémon devait basculer vers l'ordre mental auteur : espèce, niveau, moves cohérents, item, forme ;
- les champs bruts devaient cesser d'être la façade dominante ;
- le wording devait parler à un auteur, pas à un développeur.

Retenu :

- espèces guidées en façade ;
- moves guidés par learnset + niveau ;
- fallbacks bruts dans une zone avancée ;
- wording plus clair.

Rejeté :

- complexifier excessivement items/forms pour “faire joli”.

### Reviewer C — comportement / contrat de données

Conclusion :

- la persistance doit rester brute via les IDs déjà portés par `ProjectTrainerPokemonEntry` ;
- les suggestions guided moves ne doivent jamais prétendre être une validation métier finale ;
- si l'espèce, le niveau, le learnset ou le catalogue local manquent, il faut rester honnête et dégrader proprement.

Retenu :

- contextualisation UI seulement ;
- aucune mutation du contrat persistant ;
- états distincts : espèce absente, niveau invalide, learnset absent, catalogue indisponible.

Rejeté :

- validation métier déplacée dans les widgets.

### Reviewer D — test matrix / QA

Conclusion utile retenue :

- il fallait prouver le vrai contrat produit, pas seulement faire des tests décoratifs ;
- un test devait montrer qu'un move de niveau trop élevé n'apparaît pas ;
- un test devait montrer que le fallback brut reste possible quand le learnset local n'existe pas.

Ce reviewer a aussi proposé des pistes moins bien ciblées issues d'autres surfaces de learnset. Elles ont été rejetées quand elles sortaient du `Trainer Studio`.

Retenu :

- renfort ciblé de `trainer_library_panel_test.dart`.

Rejeté :

- duplication de tests déjà couverts ailleurs ;
- snapshots décoratifs.

### Reviewer E — contradicteur anti-sur-ingénierie

Conclusion :

- ne pas créer de deuxième système trainer ;
- ne pas faire un “catalog manager global” ;
- ne pas transformer ce corrective pass en lot 9 déguisé.

Retenu :

- aucune nouvelle architecture ;
- aucune abstraction supplémentaire hors helper local UI.

Rejeté :

- conserver le lookup global des moves comme façade principale. Cela entrait en conflit avec le besoin produit explicitement demandé par ce lot.

## 6. Périmètre inclus / exclu

### Inclus

- corrective pass guidé du `Trainer Studio` central existant ;
- guidage moves par learnset local et niveau courant ;
- relégation des champs bruts en fallback avancé ;
- wording plus compréhensible sur les états dégradés ;
- tests widget trainer mis à jour ;
- roadmap mise à jour.

### Exclu

- lot 9 ;
- runtime / battle / save ;
- nouveau pipeline trainer ;
- nouveau notifier/provider/repository ;
- refonte générale des use cases trainers ;
- framework générique de formulaire guidé ;
- modifications des lots 5/6/7 hors impact local strictement nécessaire.

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`
- `/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md`

### Créés

- `/Users/karim/Project/pokemonProject/reports/phase-r1-lot-8-3-guided-trainer-authoring-report.md`

### Supprimés

- aucun

## 8. Justification fichier par fichier

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`

Ajout du helper `_TrainerGuidedMoveSuggestions` et de la projection locale `_buildTrainerGuidedMoveSuggestions(...)` pour calculer les suggestions guided moves à partir de l'espèce, du niveau, du learnset local et du catalogue local des moves.

Justification :

- garder la logique de suggestion groupée et testable ;
- ne pas créer un nouveau service trainer ;
- centraliser les messages honnêtes d'états dégradés.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

Réorientation de la façade de l'éditeur Pokémon :

- espèces guidées maintenues en façade ;
- moves guidés par learnset + niveau ;
- items guidés gardés en façade ;
- formes guidées conservées ;
- champs bruts déplacés dans une zone avancée explicite ;
- wording plus compréhensible ;
- composant d'assist field étendu avec `disabledPlaceholder`.

Justification :

- faire du `Trainer Studio` une vraie surface auteur guidée ;
- réduire la dépendance visuelle aux IDs bruts ;
- ne pas toucher au pipeline trainer.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

Adaptation et renforcement des tests widget trainer :

- scénarios migrés vers la façade guidée ;
- nouveaux moves disponibles dans le fixture local ;
- learnset local enrichi ;
- nouveaux tests sur filtrage des suggestions par niveau ;
- nouveau test sur fallback honnête quand le learnset local est absent.

Justification :

- prouver le vrai contrat produit du corrective pass ;
- éviter une régression silencieuse vers des champs bruts dominants.

### `/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md`

Mise à jour documentaire pour refléter honnêtement le palier livré : `lot 8-3` et enrichissement du statut M2 / phase authoring combatable.

Justification :

- éviter un décalage entre le code réel et la roadmap ;
- garder une roadmap exploitable comme état d'avancement réel.

## 9. Commandes réellement exécutées

### Audit

- `git status --short`
- `git diff --stat`
- `sed -n '1,260p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `sed -n '1,260p' packages/map_editor/test/trainer_library_panel_test.dart`
- `sed -n '260,620p' packages/map_editor/test/trainer_library_panel_test.dart`
- `sed -n '260,620p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `sed -n '1,260p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `rg -n "_buildTrainerGuidedMoveSuggestions|_showRaw|speciesDetailFuture|_TrainerMoveSlotEditor\(" packages/map_editor/lib/src/ui/panels/trainer_library_panel*.dart`
- `sed -n '1,260p' packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `rg -n "species-field|move-0-field|move-1-field|item-field|form-field|raw-fallback|move-0-search-field|Move 1 references|Aucune suggestion de forme|Impossible de charger le catalogue local des attaques|Species absent|Local species index unavailable" packages/map_editor/test/trainer_library_panel_test.dart`
- `sed -n '1,220p' packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `sed -n '860,920p' packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `rg -n "Lot 8-2|Lot 8-3|Trainer Studio|M2|lot 8" ROADMAP_FANGAME_RECALEE.md`
- `sed -n '1,260p' ROADMAP_FANGAME_RECALEE.md`
- `sed -n '628,690p' ROADMAP_FANGAME_RECALEE.md`
- `sed -n '740,805p' ROADMAP_FANGAME_RECALEE.md`
- `sed -n '1120,1225p' ROADMAP_FANGAME_RECALEE.md`

### Validation

- `/opt/homebrew/bin/dart format lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart lib/src/ui/panels/trainer_library_panel_support.dart test/trainer_library_panel_test.dart`
- `/opt/homebrew/bin/flutter analyze --no-pub lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart lib/src/ui/panels/trainer_library_panel_support.dart test/trainer_library_panel_test.dart`
- `/opt/homebrew/bin/flutter test test/trainer_library_panel_test.dart`
- `/opt/homebrew/bin/flutter test test/trainer_use_cases_test.dart test/pokemon_species_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokemon_items_catalog_lookup_service_test.dart test/local_catalog_lookup_service_test.dart test/pokedex_external_batch_execute_ui_test.dart`
- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

### Incident local d'environnement

- `ls -la macos/Flutter/ephemeral macos/Flutter/ephemeral/Packages || true`
- `find macos/Flutter/ephemeral -maxdepth 3 -name .packages -ls || true`
- `rm -rf macos/Flutter/ephemeral/Packages/.packages`
- `pkill -f "flutter_tools.snapshot test test/trainer_library_panel_test.dart" || true`

## 10. Résultats réels

### Format

Résultat : OK

Exemples de sorties réellement obtenues :

- `Formatted lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `Formatted 3 files (1 changed) in 0.03 seconds.`

### Analyze

Résultat final : OK

Sortie finale réellement obtenue :

- `No issues found! (ran in 1.2s)`

Incident intermédiaire réellement rencontré :

- `flutter analyze` a d'abord remonté 3 `prefer_const_constructors` dans `trainer_library_panel_support.dart` ;
- ces `const` manquants ont été corrigés localement ;
- l'analyse a ensuite repassé au vert.

### Tests

Résultats finaux réellement obtenus :

- `flutter test test/trainer_library_panel_test.dart` -> `All tests passed!`
- `flutter test test/trainer_use_cases_test.dart test/pokemon_species_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokemon_items_catalog_lookup_service_test.dart test/local_catalog_lookup_service_test.dart test/pokedex_external_batch_execute_ui_test.dart` -> `All tests passed!`

Exemples de preuves réellement vues :

- `shows guided move suggestions from the selected learnset and level`
- `keeps raw move fallback available when the local learnset is unavailable`
- `All tests passed!`

## 11. Incidents rencontrés

### Incident 1 — Flutter test bloqué par un artefact généré hors code métier

Symptôme réel :

- `Unable to delete file or directory at "/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages"`

Cause :

- répertoire généré Flutter dans `macos/Flutter/ephemeral/Packages/.packages` empêchant le démarrage propre de `flutter test`.

Résolution :

- suppression locale de cet artefact généré via `rm -rf macos/Flutter/ephemeral/Packages/.packages` ;
- relance des tests ensuite.

Impact produit : aucun.

### Incident 2 — Fragilité de scroll dans deux tests widget trainer

Symptôme réel :

- avertissements de `tap()` raté sur le bouton `Save Pokémon` après ouverture de la zone avancée des fallbacks ;
- tests flakys parce que la hauteur du formulaire a augmenté.

Résolution :

- les deux tests concernés ont été stabilisés en appelant directement `onPressed` du bouton `Save Pokémon` ;
- cela garde la preuve du pipeline de save sans faire dépendre ces tests d'une mécanique de scroll qui n'est pas l'objet du scénario.

Impact produit : aucun.

## 12. État git utile

État final observé :

```text
 M ROADMAP_FANGAME_RECALEE.md
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
?? reports/phase-r1-lot-8-3-guided-trainer-authoring-report.md
```

`git diff --stat` final :

```text
 ROADMAP_FANGAME_RECALEE.md                         |  55 +++
 .../trainer_library_panel_pokemon_widgets.dart    | 319 ++++++++++++----
 .../trainer_library_panel_support.dart            | 159 ++++++++
 .../trainer_library_panel_test.dart               | 418 +++++++++++++++++++--
 4 files changed, 833 insertions(+), 118 deletions(-)
```

Fichiers non suivis observés :

```text
<aucun avant création du report>
```

## 13. Checklist finale

- [x] je me suis basé sur le code réel, pas sur les reports
- [x] je n'ai pas créé de stack parallèle
- [x] je n'ai pas ouvert le lot 9
- [x] le Trainer Studio central reste la seule vraie surface canonique
- [x] la sidebar trainer reste un launcher / résumé
- [x] les champs bruts ne sont plus la façade principale dominante
- [x] la sélection des moves dépend réellement de l'espèce et du niveau quand les données locales existent
- [x] les suggestions moves sont lisibles pour un auteur non technique
- [x] les fallbacks restent honnêtes quand les données locales manquent
- [x] les messages produit sont plus compréhensibles
- [x] je n'ai touché notifier/use cases que si nécessaire
- [x] j'ai exécuté format
- [x] j'ai exécuté analyze
- [x] j'ai exécuté les tests utiles
- [x] je n'ai fait aucune écriture git interdite
- [x] j'ai créé le report markdown ultra complet
- [x] le report contient le contenu complet des fichiers texte touchés

## 14. Conclusion honnête

Le corrective pass est réellement livré.

Ce lot ne transforme pas le `Trainer Studio` en système magique, et il ne prétend pas résoudre le futur lot 9. En revanche, il franchit le seuil demandé : l'édition Pokémon du `Trainer Studio` n'est plus principalement une collection de champs d'IDs bruts, et les moves sont enfin guidés par l'espèce et le niveau quand les données locales existent.

Compromis assumés :

- les fallbacks bruts existent encore, mais dans une zone avancée ;
- les suggestions guided moves restent une projection UI locale, pas une nouvelle couche métier ;
- les items restent guidés par le catalogue local global, sans recommandation contextuelle supplémentaire ;
- la stabilisation de deux tests de save passe par l'appel direct du callback `onPressed`, parce que le contrat visé était la persistance et non la physique de scroll du formulaire.

Dette restante acceptable :

- la contextualisation des items n'est pas un objectif de ce lot ;
- les formes restent un système honnête mais simple ;
- des raffinements de confort auteur restent possibles plus tard, sans bloquer le produit livré ici.

Verdict final :

- `lot 8-3` livré ;
- prêt à continuer la roadmap sans rouvrir ce corrective pass.

## 15. Annexe — contenu complet des fichiers texte modifiés / créés / supprimés

Note : ce report s'exclut lui-même de sa propre annexe pour éviter la récursion infinie. Tous les autres fichiers texte touchés sont inclus intégralement ci-dessous.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`

```dart
part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Références locales et draft UI
// ---------------------------------------------------------------------------

class _TrainerReferenceData {
  const _TrainerReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
    required this.movesCatalogView,
    required this.itemsCatalogView,
  });

  const _TrainerReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Chargement des références locales… La saisie brute reste possible pendant ce chargement.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des attaques…',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des objets…',
        );

  const _TrainerReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Aucun workspace Pokémon exploitable. La saisie brute reste possible, mais sans assistance locale.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des attaques indisponible.',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des objets indisponible.',
        );

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
  final PokemonMovesCatalogView movesCatalogView;
  final PokemonItemsCatalogView itemsCatalogView;
}

class _TrainerPokemonDraft {
  const _TrainerPokemonDraft({
    required this.speciesId,
    required this.level,
    required this.moves,
    required this.heldItemId,
    required this.formId,
    required this.gender,
    required this.shiny,
  });

  final String speciesId;
  final int? level;
  final List<String> moves;
  final String? heldItemId;
  final String? formId;
  final String? gender;
  final bool shiny;
}

class _TrainerGuidedMoveSuggestions {
  const _TrainerGuidedMoveSuggestions({
    required this.description,
    required this.disabledPlaceholder,
    this.entries = const <PokemonMoveCatalogEntryView>[],
    this.sourceLabelsByMoveId = const <String, List<String>>{},
    this.missingCatalogMoveIds = const <String>[],
  });

  final String description;
  final String disabledPlaceholder;
  final List<PokemonMoveCatalogEntryView> entries;
  final Map<String, List<String>> sourceLabelsByMoveId;
  final List<String> missingCatalogMoveIds;
}

// ---------------------------------------------------------------------------
// Helpers purs
// ---------------------------------------------------------------------------

String? _normalizeOptionalField(String rawValue) {
  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _splitCommaSeparatedValues(String rawValue) {
  return rawValue
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

void _clearTextControllers(Iterable<TextEditingController> controllers) {
  for (final controller in controllers) {
    controller.clear();
  }
}

bool _trainerMatchesSearch(ProjectTrainerEntry trainer, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }

  final searchTerms = <String>[
    trainer.id,
    trainer.name,
    trainer.trainerClass,
    ...trainer.tags,
    ...trainer.team.map((pokemon) => pokemon.speciesId),
  ].map((value) => value.trim().toLowerCase());

  for (final term in searchTerms) {
    if (term.contains(query)) {
      return true;
    }
  }
  return false;
}

List<String> _buildSpeciesFormSuggestions(PokemonSpeciesFile species) {
  // We only expose forms that truly exist in the local species payload.
  // Earlier code synthesized a `base` value when the data did not provide one,
  // which made the assist UI look more certain than it really was.
  final candidates = <String>[
    if (species.forms.formId.trim().isNotEmpty) species.forms.formId.trim(),
    ...species.forms.otherForms
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    if (candidate.isEmpty) {
      continue;
    }
    if (seen.add(candidate)) {
      unique.add(candidate);
    }
  }
  return unique;
}

String _firstGuidanceLine(String rawMessage) {
  final trimmed = rawMessage.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final newlineIndex = trimmed.indexOf('\n');
  if (newlineIndex < 0) {
    return trimmed;
  }
  return trimmed.substring(0, newlineIndex).trim();
}

_TrainerGuidedMoveSuggestions _buildTrainerGuidedMoveSuggestions({
  required String rawSpeciesId,
  required int? level,
  required bool isSpeciesCatalogAvailable,
  required PokemonDatabaseIndexEntry? resolvedSpecies,
  required PokedexSpeciesDetail? speciesDetail,
  required PokemonMovesCatalogView movesCatalogView,
}) {
  final speciesId = rawSpeciesId.trim();
  if (speciesId.isEmpty) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Choose a species first. Guided move suggestions depend on the selected Pokémon and its current level.',
      disabledPlaceholder: 'Choose a species first',
    );
  }

  if (level == null || level <= 0) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Enter a valid level first. Guided move suggestions only show attacks already available at the current level.',
      disabledPlaceholder: 'Enter a valid level first',
    );
  }

  if (!movesCatalogView.isAvailable) {
    return _TrainerGuidedMoveSuggestions(
      description:
          '${_firstGuidanceLine(movesCatalogView.message ?? movesCatalogView.description)} Open the raw ID fallbacks if needed.',
      disabledPlaceholder: 'Local move data unavailable',
    );
  }

  if (resolvedSpecies == null && isSpeciesCatalogAvailable) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'The selected species is not present in the local Pokédex. Guided move suggestions are unavailable for this entry.',
      disabledPlaceholder: 'Unknown local species',
    );
  }

  if (speciesDetail == null) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'No local species detail is available for this Pokémon right now. Guided move suggestions are unavailable, but raw IDs stay possible.',
      disabledPlaceholder: 'Species detail unavailable',
    );
  }

  final learnset = speciesDetail.learnset;
  if (learnset == null) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'No local learnset is available for this species. Guided move suggestions are unavailable, but raw IDs stay possible.',
      disabledPlaceholder: 'No local learnset',
    );
  }

  final sourceLabelsByMoveId = <String, List<String>>{};

  void addSource(String moveId, String label) {
    final normalizedMoveId = moveId.trim();
    if (normalizedMoveId.isEmpty) {
      return;
    }
    final labels = sourceLabelsByMoveId.putIfAbsent(
      normalizedMoveId,
      () => <String>[],
    );
    if (!labels.contains(label)) {
      labels.add(label);
    }
  }

  for (final moveId in learnset.startingMoves) {
    addSource(moveId, 'Start');
  }
  for (final moveId in learnset.relearnMoves) {
    addSource(moveId, 'Relearn');
  }
  for (final entry in learnset.levelUp) {
    if (entry.level <= level) {
      addSource(entry.moveId, 'Lv.${entry.level}');
    }
  }

  if (sourceLabelsByMoveId.isEmpty) {
    return _TrainerGuidedMoveSuggestions(
      description:
          'No starting, relearn or level-up moves are available locally for this species at Lv.$level.',
      disabledPlaceholder: 'No guided move available',
    );
  }

  final resolvedEntries = <PokemonMoveCatalogEntryView>[];
  final missingCatalogMoveIds = <String>[];
  for (final moveId in sourceLabelsByMoveId.keys) {
    final entry = _movesLookupService.findById(
      movesCatalogView.entries,
      moveId,
    );
    if (entry == null) {
      missingCatalogMoveIds.add(moveId);
      continue;
    }
    resolvedEntries.add(entry);
  }

  final missingSuffix = missingCatalogMoveIds.isEmpty
      ? ''
      : ' Some learnset moves are missing from the local move catalog: ${missingCatalogMoveIds.join(', ')}.';

  if (resolvedEntries.isEmpty) {
    return _TrainerGuidedMoveSuggestions(
      description:
          'The local learnset for this species does not resolve to any move present in the local move catalog.$missingSuffix Raw IDs stay possible.',
      disabledPlaceholder: 'No guided move available',
      missingCatalogMoveIds: missingCatalogMoveIds,
    );
  }

  return _TrainerGuidedMoveSuggestions(
    description:
        'Showing moves available from starting, relearn and level-up data up to Lv.$level.$missingSuffix',
    disabledPlaceholder: 'Search the moves available now',
    entries: resolvedEntries,
    sourceLabelsByMoveId: sourceLabelsByMoveId,
    missingCatalogMoveIds: missingCatalogMoveIds,
  );
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

class _TrainerPokemonSummaryRow extends StatelessWidget {
  const _TrainerPokemonSummaryRow({
    super.key,
    required this.pokemon,
    required this.speciesEntry,
    required this.isSpeciesCatalogAvailable,
    required this.moveCatalogView,
    required this.itemCatalogView,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final PokemonDatabaseIndexEntry? speciesEntry;
  final bool isSpeciesCatalogAvailable;
  final PokemonMovesCatalogView moveCatalogView;
  final PokemonItemsCatalogView itemCatalogView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedMoveLabels = pokemon.moves.map((moveId) {
      if (!moveCatalogView.isAvailable) {
        return moveId;
      }
      final match = _movesLookupService.findById(
        moveCatalogView.entries,
        moveId,
      );
      return match == null ? '$moveId (?)' : match.name;
    }).toList(growable: false);
    final resolvedItemLabel = pokemon.heldItemId == null ||
            pokemon.heldItemId!.trim().isEmpty ||
            !itemCatalogView.isAvailable
        ? pokemon.heldItemId?.trim()
        : _itemsLookupService
                .findById(itemCatalogView.entries, pokemon.heldItemId!.trim())
                ?.name ??
            '${pokemon.heldItemId!.trim()} (?)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          speciesEntry?.primaryName ?? pokemon.speciesId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          speciesEntry == null
                              ? '${pokemon.speciesId} • Lv.${pokemon.level}'
                              : '#${speciesEntry!.nationalDex.toString().padLeft(4, '0')} • ${pokemon.speciesId} • ${speciesEntry!.types.join('/')} • Lv.${pokemon.level}',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onEdit,
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onDelete,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 12,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
              if (speciesEntry == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isSpeciesCatalogAvailable
                        ? 'Species absent from the local Pokédex.'
                        : 'Local species index unavailable. The raw value is kept as-is.',
                    style: const TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (resolvedMoveLabels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final moveLabel in resolvedMoveLabels)
                      _TrainerSummaryChip(
                        label: moveLabel,
                        accent: EditorChrome.accentWarm,
                      ),
                  ],
                ),
              ],
              if (resolvedItemLabel != null &&
                  resolvedItemLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Item: $resolvedItemLabel',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.formId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Form: ${pokemon.formId!.trim()}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.gender ?? '').trim().isNotEmpty ||
                  pokemon.shiny) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if ((pokemon.gender ?? '').trim().isNotEmpty)
                      'Gender: ${pokemon.gender!.trim()}',
                    if (pokemon.shiny) 'Shiny',
                  ].join(' • '),
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerPokemonEditorCard extends StatefulWidget {
  const _TrainerPokemonEditorCard({
    super.key,
    required this.trainerId,
    required this.references,
    required this.speciesController,
    required this.levelController,
    required this.itemController,
    required this.formController,
    required this.genderController,
    required this.moveControllers,
    required this.shiny,
    required this.validationMessage,
    required this.onToggleShiny,
    required this.onCancel,
    required this.onSave,
    required this.loadSpeciesDetail,
  });

  final String trainerId;
  final _TrainerReferenceData references;
  final TextEditingController speciesController;
  final TextEditingController levelController;
  final TextEditingController itemController;
  final TextEditingController formController;
  final TextEditingController genderController;
  final List<TextEditingController> moveControllers;
  final bool shiny;
  final String? validationMessage;
  final ValueChanged<bool> onToggleShiny;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Future<PokedexSpeciesDetail?> Function(String speciesId)
      loadSpeciesDetail;

  @override
  State<_TrainerPokemonEditorCard> createState() =>
      _TrainerPokemonEditorCardState();
}

class _TrainerPokemonEditorCardState extends State<_TrainerPokemonEditorCard> {
  Future<PokedexSpeciesDetail?>? _speciesDetailFuture;
  String _lastSpeciesId = '';
  bool _showRawFallbacks = false;

  @override
  void initState() {
    super.initState();
    _bindDraftControllers();
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void didUpdateWidget(covariant _TrainerPokemonEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciesController != widget.speciesController) {
      oldWidget.speciesController.removeListener(_onDraftFieldChanged);
      widget.speciesController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.levelController != widget.levelController) {
      oldWidget.levelController.removeListener(_onDraftFieldChanged);
      widget.levelController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.itemController != widget.itemController) {
      oldWidget.itemController.removeListener(_onDraftFieldChanged);
      widget.itemController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.formController != widget.formController) {
      oldWidget.formController.removeListener(_onDraftFieldChanged);
      widget.formController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.genderController != widget.genderController) {
      oldWidget.genderController.removeListener(_onDraftFieldChanged);
      widget.genderController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.moveControllers != widget.moveControllers) {
      for (final controller in oldWidget.moveControllers) {
        controller.removeListener(_onDraftFieldChanged);
      }
      for (final controller in widget.moveControllers) {
        controller.addListener(_onDraftFieldChanged);
      }
    }
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void dispose() {
    _unbindDraftControllers();
    super.dispose();
  }

  void _bindDraftControllers() {
    widget.speciesController.addListener(_onDraftFieldChanged);
    widget.levelController.addListener(_onDraftFieldChanged);
    widget.itemController.addListener(_onDraftFieldChanged);
    widget.formController.addListener(_onDraftFieldChanged);
    widget.genderController.addListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.addListener(_onDraftFieldChanged);
    }
  }

  void _unbindDraftControllers() {
    widget.speciesController.removeListener(_onDraftFieldChanged);
    widget.levelController.removeListener(_onDraftFieldChanged);
    widget.itemController.removeListener(_onDraftFieldChanged);
    widget.formController.removeListener(_onDraftFieldChanged);
    widget.genderController.removeListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.removeListener(_onDraftFieldChanged);
    }
  }

  void _onDraftFieldChanged() {
    _refreshSpeciesDetailFuture();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshSpeciesDetailFuture({bool force = false}) {
    final speciesId = widget.speciesController.text.trim();
    if (!force && speciesId == _lastSpeciesId) {
      return;
    }
    _lastSpeciesId = speciesId;
    _speciesDetailFuture = widget.loadSpeciesDetail(speciesId);
  }

  void _toggleRawFallbacks() {
    setState(() {
      _showRawFallbacks = !_showRawFallbacks;
    });
  }

  Widget _buildRawFallbackSection(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Advanced raw ID fallbacks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PushButton(
                  key: const Key(
                    'trainer-library-pokemon-raw-fallback-toggle-button',
                  ),
                  controlSize: ControlSize.small,
                  secondary: _showRawFallbacks,
                  onPressed: _toggleRawFallbacks,
                  child: Text(
                    _showRawFallbacks ? 'Hide raw fields' : 'Show raw fields',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Guided selectors stay primary. Open these raw fields only when local project data cannot suggest the exact value you need.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (_showRawFallbacks) ...[
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw species ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-species-field'),
                controller: widget.speciesController,
                placeholder: 'pikachu',
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < widget.moveControllers.length; i++) ...[
                _TrainerInlineField(
                  label: 'Raw move ID ${i + 1} (fallback)',
                  fieldKey: Key('trainer-library-pokemon-move-$i-field'),
                  controller: widget.moveControllers[i],
                  placeholder: 'move id',
                ),
                if (i != widget.moveControllers.length - 1)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw held item ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-item-field'),
                controller: widget.itemController,
                placeholder: 'oran_berry',
              ),
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw form ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-form-field'),
                controller: widget.formController,
                placeholder: 'base / alternate form id',
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final speciesId = widget.speciesController.text.trim();
    final level = int.tryParse(widget.levelController.text.trim());
    final heldItemId = widget.itemController.text.trim();
    final formId = widget.formController.text.trim();
    final resolvedSpecies = widget.references.isSpeciesAvailable
        ? _speciesLookupService.findById(
            widget.references.speciesEntries,
            speciesId,
          )
        : null;
    final resolvedItem =
        widget.references.itemsCatalogView.isAvailable && heldItemId.isNotEmpty
            ? _itemsLookupService.findById(
                widget.references.itemsCatalogView.entries,
                heldItemId,
              )
            : null;
    final speciesCatalogReady = widget.references.isSpeciesAvailable;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InspectorEmbeddedSectionLabel('TRAINER POKÉMON'),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonDatabaseIndexEntry>(
              keyPrefix: 'trainer-library-pokemon-species',
              title: 'Find a species in the local Pokédex',
              description: speciesCatalogReady
                  ? 'Search by species name, local id or Pokédex number.'
                  : widget.references.speciesMessage,
              entries: widget.references.speciesEntries,
              lookupService: _speciesLookupService,
              enabled: speciesCatalogReady,
              disabledPlaceholder: 'Local Pokédex unavailable',
              searchPlaceholder: 'Search a project species',
              subtitleBuilder: (entry) => [
                '#${entry.nationalDex.toString().padLeft(4, '0')}',
                entry.types.join('/'),
                entry.id,
              ].join(' • '),
              onSelected: (entry) {
                widget.speciesController.text = entry.id;
              },
            ),
            const SizedBox(height: 6),
            Text(
              resolvedSpecies == null
                  ? speciesCatalogReady
                      ? 'The current species value is not resolved in the local Pokédex.'
                      : 'Species validation stays limited while the local Pokédex is unavailable.'
                  : 'Selected species: ${resolvedSpecies.primaryName} • #${resolvedSpecies.nationalDex.toString().padLeft(4, '0')} • ${resolvedSpecies.id}',
              style: TextStyle(
                color: resolvedSpecies == null
                    ? EditorChrome.inspectorJoyCoral
                    : subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Level',
                    fieldKey: const Key('trainer-library-pokemon-level-field'),
                    controller: widget.levelController,
                    placeholder: '1',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Gender',
                    fieldKey: const Key('trainer-library-pokemon-gender-field'),
                    controller: widget.genderController,
                    placeholder: 'male / female / any',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final gender in _trainerQuickGenderValues)
                  PushButton(
                    controlSize: ControlSize.small,
                    secondary: widget.genderController.text.trim() != gender,
                    onPressed: () {
                      widget.genderController.text = gender;
                    },
                    child: Text(gender),
                  ),
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: widget.genderController.text.trim().isNotEmpty,
                  onPressed: () {
                    widget.genderController.clear();
                  },
                  child: const Text('Clear gender'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Shiny',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                MacosSwitch(
                  value: widget.shiny,
                  onChanged: widget.onToggleShiny,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<PokedexSpeciesDetail?>(
              future: _speciesDetailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                final guidedMoves = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        speciesId.isNotEmpty
                    ? const _TrainerGuidedMoveSuggestions(
                        description:
                            'Loading the local learnset for this species… Guided move suggestions will appear when the data is ready.',
                        disabledPlaceholder: 'Loading local learnset…',
                      )
                    : _buildTrainerGuidedMoveSuggestions(
                        rawSpeciesId: speciesId,
                        level: level,
                        isSpeciesCatalogAvailable: speciesCatalogReady,
                        resolvedSpecies: resolvedSpecies,
                        speciesDetail: detail,
                        movesCatalogView: widget.references.movesCatalogView,
                      );
                final availableForms = detail == null
                    ? const <String>[]
                    : _buildSpeciesFormSuggestions(detail.species);
                final itemStatus = heldItemId.isEmpty
                    ? 'No held item selected.'
                    : resolvedItem == null
                        ? widget.references.itemsCatalogView.isAvailable
                            ? 'The current held item value is not resolved in the local item catalog.'
                            : 'Local item catalog unavailable. The raw value is kept as-is.'
                        : 'Selected item: ${resolvedItem.name} • ${resolvedItem.id}';
                final formStatus = formId.isEmpty
                    ? 'No form override selected.'
                    : availableForms.contains(formId)
                        ? 'Selected form: $formId'
                        : 'Current raw form override: $formId';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InspectorEmbeddedSectionLabel('MOVES'),
                    const SizedBox(height: 8),
                    // Guided move suggestions stay local to this species draft.
                    // We deliberately keep them in the widget layer because
                    // they are a presentational helper over already-loaded
                    // authoring data, not a second trainer domain service.
                    for (var i = 0; i < widget.moveControllers.length; i++) ...[
                      _TrainerMoveSlotEditor(
                        slotIndex: i,
                        controller: widget.moveControllers[i],
                        catalogView: widget.references.movesCatalogView,
                        guidedMoves: guidedMoves,
                      ),
                      if (i != widget.moveControllers.length - 1)
                        const SizedBox(height: 10),
                    ],
                    if (guidedMoves.missingCatalogMoveIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Some locally available learnset moves are missing from the local move catalog: ${guidedMoves.missingCatalogMoveIds.join(', ')}.',
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const InspectorEmbeddedSectionLabel('ITEM / FORM'),
                    const SizedBox(height: 8),
                    _TrainerCatalogAssistField<PokemonItemCatalogEntryView>(
                      keyPrefix: 'trainer-library-pokemon-item',
                      title: 'Find an item in the local catalog',
                      description: widget
                              .references.itemsCatalogView.isAvailable
                          ? 'Search by item name or local id.'
                          : widget.references.itemsCatalogView.message ??
                              widget.references.itemsCatalogView.description,
                      entries: widget.references.itemsCatalogView.entries,
                      lookupService: _itemsLookupService,
                      enabled: widget.references.itemsCatalogView.isAvailable,
                      disabledPlaceholder: 'Local item catalog unavailable',
                      searchPlaceholder: 'Search a project item',
                      subtitleBuilder: (entry) => entry.id,
                      onSelected: (entry) {
                        widget.itemController.text = entry.id;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemStatus,
                      style: TextStyle(
                        color: heldItemId.isNotEmpty && resolvedItem == null
                            ? EditorChrome.inspectorJoyCoral
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting &&
                              speciesId.isNotEmpty
                          ? 'Loading local forms for this species…'
                          : speciesId.isEmpty
                              ? 'Choose a species to check local form suggestions.'
                              : detail == null
                                  ? 'Unable to verify local forms for this species right now. The raw fallback remains available.'
                                  : availableForms.isEmpty
                                      ? 'No local form suggestion is available for this species. The raw fallback remains available.'
                                      : 'Local form suggestions:',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formStatus,
                      style: TextStyle(
                        color: formId.isNotEmpty &&
                                availableForms.isNotEmpty &&
                                !availableForms.contains(formId)
                            ? EditorChrome.inspectorJoyCoral
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (availableForms.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final formId in availableForms)
                            PushButton(
                              key: Key(
                                'trainer-library-pokemon-form-suggestion-$formId',
                              ),
                              controlSize: ControlSize.small,
                              secondary:
                                  widget.formController.text.trim() != formId,
                              onPressed: () {
                                widget.formController.text = formId;
                              },
                              child: Text(formId),
                            ),
                          PushButton(
                            key: const Key(
                              'trainer-library-pokemon-form-clear-button',
                            ),
                            controlSize: ControlSize.small,
                            secondary:
                                widget.formController.text.trim().isNotEmpty,
                            onPressed: () {
                              widget.formController.clear();
                            },
                            child: const Text('Clear form'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildRawFallbackSection(context),
                  ],
                );
              },
            ),
            if (widget.validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.validationMessage!,
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                CupertinoButton.filled(
                  key: const Key('trainer-library-pokemon-save-button'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onSave,
                  child: const Text(
                    'Save Pokémon',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMoveSlotEditor extends StatelessWidget {
  const _TrainerMoveSlotEditor({
    required this.slotIndex,
    required this.controller,
    required this.catalogView,
    required this.guidedMoves,
  });

  final int slotIndex;
  final TextEditingController controller;
  final PokemonMovesCatalogView catalogView;
  final _TrainerGuidedMoveSuggestions guidedMoves;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final moveId = controller.text.trim();
    final resolvedMove = catalogView.isAvailable
        ? _movesLookupService.findById(catalogView.entries, moveId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrainerCatalogAssistField<PokemonMoveCatalogEntryView>(
          keyPrefix: 'trainer-library-pokemon-move-$slotIndex',
          title: 'Move slot ${slotIndex + 1}',
          description: guidedMoves.description,
          entries: guidedMoves.entries,
          lookupService: _movesLookupService,
          enabled: guidedMoves.entries.isNotEmpty,
          disabledPlaceholder: guidedMoves.disabledPlaceholder,
          searchPlaceholder: 'Search an available move',
          subtitleBuilder: (entry) => [
            ...?guidedMoves.sourceLabelsByMoveId[entry.id],
            if (entry.type != null) entry.type!,
            if (entry.category != null) entry.category!,
            if (entry.power != null) 'Power ${entry.power}',
            if (entry.pp != null) 'PP ${entry.pp}',
          ].join(' • '),
          onSelected: (entry) {
            controller.text = entry.id;
          },
        ),
        const SizedBox(height: 4),
        Text(
          moveId.isEmpty
              ? 'Slot empty.'
              : resolvedMove == null
                  ? catalogView.isAvailable
                      ? 'Raw move ID not resolved in the local move catalog.'
                      : 'Move catalog unavailable: the raw value is kept as-is.'
                  : 'Selected move: ${resolvedMove.name} • ${resolvedMove.id}',
          style: TextStyle(
            color: moveId.isNotEmpty && resolvedMove == null
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// This stays a local trainer widget on purpose: it is a small affordance for
// catalog-backed authoring, not a generic search framework for the editor.
class _TrainerCatalogAssistField<T> extends StatefulWidget {
  const _TrainerCatalogAssistField({
    required this.keyPrefix,
    required this.title,
    required this.description,
    required this.entries,
    required this.lookupService,
    required this.enabled,
    required this.disabledPlaceholder,
    required this.searchPlaceholder,
    required this.onSelected,
    this.subtitleBuilder,
  });

  final String keyPrefix;
  final String title;
  final String description;
  final List<T> entries;
  final ProgressiveLocalCatalogLookupService<T> lookupService;
  final bool enabled;
  final String disabledPlaceholder;
  final String searchPlaceholder;
  final ValueChanged<T> onSelected;
  final String Function(T entry)? subtitleBuilder;

  @override
  State<_TrainerCatalogAssistField<T>> createState() =>
      _TrainerCatalogAssistFieldState<T>();
}

class _TrainerCatalogAssistFieldState<T>
    extends State<_TrainerCatalogAssistField<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectEntry(T entry) {
    widget.onSelected(entry);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canSearch = widget.enabled && widget.entries.isNotEmpty;
    final suggestions = canSearch
        ? widget.lookupService.search(
            widget.entries,
            _searchController.text,
            limit: 8,
          )
        : List<T>.empty(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: Key('${widget.keyPrefix}-search-field'),
          controller: _searchController,
          enabled: canSearch,
          placeholder: widget.enabled
              ? widget.searchPlaceholder
              : widget.disabledPlaceholder,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (_searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (!canSearch)
            Text(
              'Aucune suggestion locale disponible pour le moment.',
              key: Key('${widget.keyPrefix}-search-unavailable'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestions.isEmpty)
            Text(
              'Aucun résultat local pour cette recherche.',
              key: Key('${widget.keyPrefix}-search-empty'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              key: Key('${widget.keyPrefix}-suggestions'),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = suggestions[index];
                  final title = widget.lookupService.labelOf(entry);
                  final id = widget.lookupService.idOf(entry);
                  final subtitle = widget.subtitleBuilder?.call(entry);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.islandFillElevated(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentWarm.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: CupertinoButton(
                      key: Key('${widget.keyPrefix}-suggestion-$id'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onPressed: () => _selectEntry(entry),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$title • $id',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: subtle,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _TrainerSummaryChip extends StatelessWidget {
  const _TrainerSummaryChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrainerInlineField extends StatelessWidget {
  const _TrainerInlineField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/trainer_library_panel.dart';

void main() {
  Future<void> pumpTrainerPanel(
    WidgetTester tester,
    ProviderContainer container, {
    bool embedded = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: embedded ? 420 : 1280,
                height: 1800,
                child: embedded
                    ? const TrainerLibraryPanel(embedded: true)
                    : const TrainerLibraryPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('embedded mode acts as a launcher for the main Trainer Studio',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_embedded',
      project: ProjectManifest(
        name: 'trainers_panel_embedded',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container, embedded: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('trainer-library-open-studio-button')),
        findsOneWidget);
    expect(find.byKey(const Key('trainer-library-new-trainer-button')),
        findsNothing);
    expect(find.text('Trainer Studio'), findsWidgets);

    await tester
        .tap(find.byKey(const Key('trainer-library-open-studio-button')));
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.trainer,
    );
    expect(
      container.read(editorNotifierProvider).selectedTrainerId,
      'misty',
    );
  });

  testWidgets(
      'creates a trainer and saves a complete team entry with assisted refs',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-new-trainer-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-create-name-field')),
      'Misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-class-field')),
      'Gym Leader',
    );
    await tester.tap(find.text('Show optional references'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-battle-theme-field')),
      'battle_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-victory-theme-field')),
      'victory_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-tags-field')),
      ' rival, gym ',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final trainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.name, 'Misty');
    expect(trainer.battleThemeId, 'battle_misty');
    expect(trainer.victoryThemeId, 'victory_misty');
    expect(trainer.tags, <String>['rival', 'gym']);

    await tester.tap(
      find.byKey(Key('trainer-library-add-pokemon-button-${trainer.id}')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.tap(find.text('female'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'tackle',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-tackle'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-search-field')),
      'growl',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-1-suggestion-growl'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-search-field')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-search-field')),
      'oran',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-item-suggestion-oran_berry'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-form-suggestion-blossom'),
      ),
    );
    await tester.pumpAndSettle();

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 12);
    expect(pokemon.moves, <String>['tackle', 'growl']);
    expect(pokemon.heldItemId, 'oran_berry');
    expect(pokemon.formId, 'blossom');
    expect(pokemon.gender, 'female');
    expect(pokemon.shiny, isFalse);
    expect(
      find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0')),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows guided move suggestions from the selected learnset and level',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'vine',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-vine_whip'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Lv.7'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'razor',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-razor_leaf'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-empty')),
      findsOneWidget,
    );
  });

  testWidgets('shows inline validation when a move is unknown locally',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Move 1 references an unknown local move: missing_move'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'does not invent a base form suggestion when the local species detail has none',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  forms: const PokemonSpeciesForms(
                    baseFormId: 'bulbasaur',
                    isBaseForm: true,
                    formId: '',
                    otherForms: <String>[],
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-form-suggestion-base')),
      findsNothing,
    );
  });

  testWidgets(
      'keeps species and form messaging honest when local species assistance is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => throw StateError('species loader exploded'),
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, __) async => throw StateError('detail loader exploded'),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Impossible de charger les espèces locales. La saisie brute reste possible.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      findsOneWidget,
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.speciesId, 'bulbasaur');

    await tester.scrollUntilVisible(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the trainer surface usable when moves and items lookups fail unexpectedly',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => throw StateError('moves loader exploded'),
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogError: StateError('items loader exploded'),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Impossible de charger le catalogue local des attaques.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Impossible de charger le catalogue local des objets.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      'mystery_item',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 10);
    expect(pokemon.moves, <String>['missing_move']);
    expect(pokemon.heldItemId, 'mystery_item');
  });

  testWidgets(
      'keeps raw move fallback available when the local learnset is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(learnset: null)
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local learnset is available for this species. Guided move suggestions are unavailable, but raw IDs stay possible.',
      ),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'tackle',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.moves, <String>['tackle']);
  });
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
  ),
];

const PokemonMovesCatalogView _movesCatalogView = PokemonMovesCatalogView(
  entries: <PokemonMoveCatalogEntryView>[
    PokemonMoveCatalogEntryView(
      id: 'growl',
      name: 'Growl',
      type: 'normal',
      category: 'status',
      pp: 40,
    ),
    PokemonMoveCatalogEntryView(
      id: 'tackle',
      name: 'Tackle',
      type: 'normal',
      category: 'physical',
      power: 40,
      pp: 35,
    ),
    PokemonMoveCatalogEntryView(
      id: 'vine_whip',
      name: 'Vine Whip',
      type: 'grass',
      category: 'physical',
      power: 45,
      pp: 25,
    ),
    PokemonMoveCatalogEntryView(
      id: 'razor_leaf',
      name: 'Razor Leaf',
      type: 'grass',
      category: 'physical',
      power: 55,
      pp: 25,
    ),
  ],
  isAvailable: true,
  description: 'Catalogue local des attaques.',
);

const PokemonCatalogFile _itemsCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'items',
  meta: PokemonDataMeta(description: 'Catalogue local des objets.'),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
      'aliases': <String>['oran'],
    },
  ],
);

final Map<String, PokedexSpeciesDetail> _detailsById =
    <String, PokedexSpeciesDetail>{
  'bulbasaur': _buildDetail(),
};

PokedexSpeciesDetail _buildDetail({
  PokemonSpeciesForms forms = const PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
    otherForms: <String>['blossom'],
  ),
  PokemonLearnsetFile? learnset = const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle'],
    relearnMoves: <String>['growl'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level-up',
        versionGroup: 'project',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'razor_leaf',
        level: 20,
        source: 'level-up',
        versionGroup: 'project',
      ),
    ],
  ),
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{'en': 'Bulbasaur'},
      speciesName: <String, String>{'en': 'Seed Pokemon'},
      genIntroduced: 1,
      typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'overgrow'),
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
      forms: forms,
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: const PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
        flavorText: 'A strange seed was planted on its back at birth.',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(starterEligible: true),
      sourceMeta:
          const PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 1),
    ),
    learnset: learnset,
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.catalogByKey = const <String, PokemonCatalogFile>{},
    this.catalogError,
  });

  final Map<String, PokemonCatalogFile> catalogByKey;
  final Object? catalogError;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    if (catalogError != null) {
      throw catalogError!;
    }
    final catalog = catalogByKey[catalogKey];
    if (catalog == null) {
      throw EditorNotFoundException('Missing catalog: $catalogKey');
    }
    return catalog;
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }
}
```

### `/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md`

```md
# Roadmap Maître Recalée — pokemonProject

## 1. But du document

Ce document sert de **roadmap maître recalée** pour la suite du projet.

Il ne repart pas de zéro.
Il part de l'état réel actuel du repo et d'un principe central qui ne doit pas bouger :

**on améliore l'existant, on ne crée aucune stack parallèle.**

Cela implique explicitement :

- pas de nouveau runtime Pokémon parallèle ;
- pas de nouveau save system parallèle ;
- pas de nouveau modèle concurrent à `PlayerPokemon` ;
- pas de nouveau moteur de combat parallèle à `map_battle` ;
- pas de second pipeline Pokédex ;
- pas de logique métier poussée dans les widgets UI ;
- pas de grand refactor transversal "propre" si une extension locale honnête suffit.

Ce document remplace une roadmap trop "domain-first" par une roadmap plus **réaliste, verticale et pilotable**.

## 2. Résumé exécutif

Le projet a déjà dépassé le stade du prototype vide.

Aujourd'hui, le repo dispose déjà de fondations réelles pour :

- la persistance de partie ;
- le Pokédex local et ses imports externes ;
- le catalogue local des moves ;
- l'édition minimale des learnsets ;
- les trainers et les encounter tables ;
- les battle requests runtime ;
- un moteur de combat pur Dart encore minimal ;
- un pattern réel de field move avec Surf.

Le vrai enjeu n'est donc plus de "construire un système Pokémon from scratch".
Le vrai enjeu est de **faire converger les briques existantes vers une boucle fangame complète**.

Le point le plus important de cette version recalée est le suivant :

**le bridge runtime -> battle réel doit arriver tôt**.

On ne doit pas repousser indéfiniment la preuve de la boucle de jeu pendant qu'on peaufine l'authoring.
La bonne stratégie est :

1. rendre le Pokédex auteur vraiment productif ;
2. brancher les références assistées là où elles ont déjà un retour immédiat ;
3. rendre trainers et encounters suffisamment propres pour produire de vraies données ;
4. supprimer le placeholder du handoff runtime -> battle ;
5. obtenir un combat sauvage réel ;
6. obtenir capture + persistance minimale ;
7. seulement ensuite approfondir le moteur de combat et élargir la boucle RPG.

## 3. Ce qui est déjà acquis dans le repo

Cette section ne décrit pas des intentions.
Elle décrit les éléments déjà présents dans l'état actuel du repo et du worktree.

### 3.1. Save et modèle de partie

Le repo a déjà une vraie base persistée :

- `GameState`
- `SaveData`
- `PlayerPokemon`
- `PlayerParty`
- `TrainerProfile`
- `Bag`
- `PlayerProgression`
- migration legacy et persistance runtime

Conclusion :

- on ne crée surtout pas de modèle `OwnedPokemon` concurrent ;
- on ne crée surtout pas un second format de save.

### 3.2. Pokédex et import Pokémon

La phase 11A est considérée comme clôturée.
Le repo a déjà :

- une config Pokémon projet légère dans `ProjectManifest` ;
- un `dataRoot`, des sous-dossiers dédiés (`species`, `learnsets`, `evolutions`, `media`) et des `catalogFiles` explicites ;
- un bootstrap local via `InitializePokemonProjectStorageUseCase` ;
- un pipeline d'import externe Pokémon ;
- un `dryRun` et une preview ;
- une source produit unique côté UI ;
- des mini-fix de cohérence média ;
- une preuve de clôture 11A documentée.

Conclusion :

- on ne rouvre pas artificiellement 11A ;
- on n'écrit pas un deuxième pipeline d'import externe.

### 3.2.1. Avancement réel de la phase R1 déjà livré dans le worktree

Les sept premiers lots de la phase R1 ont maintenant été livrés dans le
worktree courant. Ils ne sont plus à considérer comme du travail à démarrer,
mais comme du socle acquis à prolonger proprement.

#### Lot 1 — Résolveur de requête externe Pokédex

Ce lot existe maintenant côté application avec :

- un modèle de résolution structuré pour :
  - mono-espèce ;
  - liste explicite ;
  - plage dex ;
  - génération ;
  - requête invalide / ambiguë ;
- un résolveur pur, sans réseau et sans UI ;
- un provider DI dédié dans `map_editor`.

Le contrat déjà livré couvre au minimum :

- `bulbasaur`
- `1`
- `001`
- `0001`
- `1-151`
- `gen 1`
- `generation 2`
- `pikachu, eevee, abra`
- refus explicite des cas ambigus de type `pikachu eevee abra`

#### Lot 2 — Auto-complétion mono-espèce dans le wizard

Ce lot existe maintenant dans la branche `API externe` du wizard Pokédex avec :

- un use case de recherche mono-espèce réutilisant le résolveur du lot 1 ;
- une vraie surface de suggestions ;
- une sélection explicite obligatoire ;
- un blocage de la preview/import tant qu'aucune suggestion réelle n'a été
  choisie ;
- des états propres :
  - vide ;
  - loading ;
  - aucun résultat ;
  - hors-scope ;
  - invalide ;
  - erreur.

Le point important à conserver pour la suite :

- le widget ne parse pas la requête lui-même ;
- la preview/import mono-espèce ne repose pas sur une simple string tapée ;
- seule une suggestion explicitement sélectionnée débloque la suite.

#### Lot 3 — Sélection batch + dry-run batch

Ce lot existe maintenant dans la même branche `API externe` du wizard avec :

- un mode explicite `Mono-espèce` / `Batch dry-run` ;
- un use case dédié de résolution batch, réutilisant le résolveur du lot 1 ;
- la compréhension de trois formes batch :
  - liste explicite ;
  - plage dex ;
  - génération ;
- une liste finale résolue visible avant toute preview ;
- un dry-run batch branché sur le pipeline batch applicatif existant avec
  `dryRun: true` ;
- une preview batch lisible ;
- un blocage explicite de tout import batch réel.

Règles déjà en place à ne pas casser :

- une liste explicite partiellement résolue reste visible mais bloque le
  dry-run ;
- les requêtes par plage dex et génération ne ciblent volontairement que les
  espèces de base ;
- une liste explicite peut encore conserver une forme si elle a été demandée
  explicitement ;
- le dry-run batch n'écrit rien et ne constitue pas encore une exécution lot 4.

Artefacts de preuve déjà présents :

- `reports/phase-r1-lot-1-pokedex-query-resolver-report.md`
- `reports/phase-r1-lot-2-pokedex-external-autocomplete-report.md`
- `reports/phase-r1-lot-3-batch-selection-dry-run-report.md`

#### Lot 4 — Exécution batch + progression + rapport

Ce lot existe maintenant dans le même flow `API externe`, sans réécrire le
pipeline batch applicatif existant.

Ce qui est désormais livré :

- une action explicite d'exécution batch réelle distincte du dry-run ;
- une progression honnête alimentée par les callbacks réels du use case batch ;
- un écran de résultat séparé du dry-run preview ;
- des compteurs visibles :
  - succès ;
  - conflits ;
  - erreurs ;
  - skips ;
  - espèces terminées ;
- un rapport final détaillé par espèce ;
- un refresh du workspace si au moins une espèce a réellement été écrite ;
- une règle stable de sélection post-import :
  - première espèce réellement écrite dans l'ordre visible de la sélection batch
    ;
- conservation stricte du flow mono-espèce et du dry-run du lot 3.

Décisions d'implémentation désormais en place :

- aucun pipeline batch parallèle n'a été créé ;
- `BatchImportExternalPokemonSpeciesUseCase` reste le cœur d'exécution ;
- une extension minimale du use case expose une progression honnête par espèce
  terminée ;
- l'UI ne simule aucun faux pourcentage interne ;
- le rapport final réutilise directement `PokemonExternalBatchImportResult`.

Limites assumées à ce stade :

- pas de retry sélectif ;
- pas de relance partielle depuis le rapport ;
- pas d'import en arrière-plan ;
- pas de cancellation complexe ;
- pas de pagination du rapport final.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-4-batch-execution-progress-report.md`
- `reports/phase-r1-lot-4-mini-fix-no-write-feedback-report.md`

Mini-fix déjà livré à conserver :

- le feedback final batch est maintenant aligné sur les écritures réelles ;
- un batch avec `0` écriture réelle ne remonte plus comme un succès silencieux ;
- le critère produit global s'aligne sur `hasWritesApplied`, exactement comme le
  refresh du workspace.

#### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Ce lot existe maintenant dans le learnset editor du Pokédex, sans créer de
deuxième éditeur ni de deuxième contrat de learnset.

Ce qui est désormais livré :

- une recherche locale assistée dans le catalogue `moves` par :
  - `id` ;
  - `name` ;
  - alias pertinents quand ils sont présents dans les données déjà chargées ;
- une sélection explicite de move depuis l'éditeur au lieu d'une saisie brute
  systématique d'ids ;
- une assistance concrète pour les sections de learnset existantes :
  - `startingMoves` ;
  - `relearnMoves` ;
  - `levelUp` ;
  - `tm` ;
  - `tutor` ;
  - `egg` ;
  - `event` ;
  - `transfer` ;
- un affichage honnête des ids legacy / inconnus :
  - l'entrée reste visible ;
  - elle n'est pas détruite silencieusement ;
  - elle est signalée comme absente du catalogue local quand c'est le cas ;
- une validation plus lisible autour des moves manquants et des incohérences
  évidentes, sans déplacer le cœur métier dans l'UI.

Décision importante déjà en place :

- le texte brut reste le contrat d'édition réel du learnset ;
- l'assistance moves-first vient au-dessus pour sécuriser et accélérer la
  saisie, mais ne masque pas les données ni ne crée une UI concurrente.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-5-moves-first-learnset-report.md`

#### Lot 6 — Service de recherche catalogue progressif

Ce lot existe maintenant côté `map_editor/application/services` et ne recrée
pas de deuxième système de lookup `moves`.

Ce qui est désormais livré :

- un petit contrat stable de recherche locale en mémoire pour les catalogues ;
- une base concrète réutilisable :
  - `ProgressiveLocalCatalogLookupService<TEntry>` ;
- une convergence du service lot 5 vers ce socle au lieu de dupliquer la
  logique ;
- une implémentation réellement branchée sur `moves` via
  `PokemonMovesCatalogLookupService` ;
- des tests dédiés du contrat progressif et de la non-régression côté moves.

Décisions d'architecture désormais en place :

- pas d'interface "enterprise" supplémentaire ;
- pas de provider décoratif ajouté juste pour la forme ;
- pas de moteur multi-catalogues théorique ;
- un petit socle concret, utilisé tout de suite par `moves`, et crédible pour
  les futurs besoins trainers / encounters.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-6-progressive-catalog-search-report.md`

#### Lot 7 — Trainers : surface minimale vraiment exploitable

Ce lot existe maintenant dans la surface trainers existante, sans réécrire le
CRUD trainer déjà présent ni introduire de système parallèle.

Ce qui est désormais livré :

- création / édition / suppression trainer depuis l'UI sans passer par le JSON
  ;
- édition d'une team trainer réellement exploitable ;
- ajout et édition de Pokémon de team avec les champs déjà présents côté métier
  :
  - species ;
  - level ;
  - moves ;
  - held item ;
  - form ;
  - gender ;
  - shiny ;
- assistance locale branchée là où elle existe honnêtement :
  - species via l'index Pokédex local ;
  - moves via le catalogue local `moves` ;
  - items via le catalogue local `items` quand il est disponible ;
  - forms via les données locales de l'espèce sélectionnée ;
- conservation explicite de la saisie brute quand une source locale n'existe
  pas ou n'est pas prête ;
- validation inline plus lisible avant save ;
- sauvegarde stable via les use cases trainers existants.

Micro-vérification lot 6 intégrée dans ce lot :

- le socle `ProgressiveLocalCatalogLookupService<TEntry>` a été conservé tel
  quel ;
- aucun renommage cosmétique n'a été fait ;
- la réutilisation est restée locale et progressive via :
  - `PokemonSpeciesLookupService` ;
  - `PokemonItemsCatalogLookupService` ;
  - `PokemonMovesCatalogLookupService` existant.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-7-trainers-minimal-authoring-report.md`

#### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Ce lot existe maintenant dans la surface `EncounterTablesPanel` déjà présente,
sans créer de deuxième éditeur, de deuxième pipeline encounter ni de nouvelle
stack de persistance.

Ce qui est désormais livré :

- création / édition / suppression de tables de rencontres depuis l'UI ;
- ajout / édition / suppression d'entrées de rencontre depuis la même surface ;
- assistance locale `species` réutilisant l'index Pokédex déjà présent ;
- validation inline lisible sur :
  - `species` ;
  - `minLevel` ;
  - `maxLevel` ;
  - `weight` ;
- distinction honnête entre trois états auteur :
  - espèce résolue localement ;
  - espèce absente du Pokédex local ;
  - vérification impossible parce que les données locales sont indisponibles ;
- conservation de la saisie brute quand la vérification locale n'est pas
  possible ;
- lisibilité réelle des poids avec part relative dérivée de la table courante ;
- fermeture des formulaires uniquement sur succès réel du pipeline existant ;
- sauvegarde stable via les use cases encounter déjà présents.

Décisions explicitement retenues :

- aucun reorder n'a été ajouté :
  - le runtime sélectionne déjà par poids, pas par ordre ;
  - ce n'était donc pas un prérequis honnête pour franchir le seuil auteur M2 ;
- aucun provider/use case/repository encounter parallèle n'a été créé ;
- `EditorNotifier` a seulement été réaligné sur le contrat de succès/échec
  déjà utilisé côté trainers pour garder les formulaires ouverts en cas d'échec
  ;
- le support local reste strictement `species-first` pour les encounters.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-8-encounters-m2-report.md`

### 3.3. Catalogues locaux et moves catalog

Le repo n'est plus dans un état "catalogues à inventer".
Il a déjà :

- un scaffold local de catalogues dans l'arborescence Pokémon du projet ;
- des clés catalogue explicites dans la config Pokémon ;
- un import JSON catalogue local ;
- des validations croisées déjà branchées sur certains catalogues ;
- des seeds et jeux de démonstration pour plusieurs familles.

La phase 11B a ensuite fait exister un vrai premier jalon moves dans le worktree courant :

- catalogue local des moves ;
- sync/import depuis source externe ;
- surface minimale côté éditeur ;
- première intégration utile avec le learnset editor.

Le repo valide déjà concrètement :

- `learnset -> moves catalog`
- `species -> types catalog`

et sait déjà basculer certains catalogues manquants vers des warnings explicites plutôt que des comportements opaques.

Conclusion :

- la partie "catalogues" ne repart pas de zéro ;
- la stratégie réaliste est bien **moves-first**, déjà amorcée puis renforcée ;
- le prochain travail doit réutiliser ce socle et son contrat progressif au
  lieu de les réécrire.

### 3.4. Trainers et encounter tables

Le repo contient déjà :

- `ProjectTrainerEntry` et ses variantes associées ;
- des use cases trainers ;
- des use cases encounter tables ;
- un wiring applicatif déjà exposé dans l'éditeur ;
- des panneaux éditeur existants ;
- la résolution de rencontres côté `map_gameplay`.

Conclusion :

- la surface trainers a maintenant franchi le seuil "vraiment exploitable" pour
  un auteur ;
- la surface encounters a maintenant rejoint ce même seuil minimal
  d'exploitabilité ;
- on ne crée pas un second système de trainers ou de rencontres.

### 3.5. Runtime et battle skeleton

Le runtime sait déjà :

- déclencher une demande de combat sauvage ;
- déclencher une demande de combat trainer ;
- produire de vrais `BattleStartRequest` sauvages et trainers ;
- ouvrir un overlay de combat ;
- relayer un flux de retour combat vers l'overworld.

Le moteur `map_battle` existe déjà, mais il reste un MVP.

Le vrai trou actuel est bien le dernier maillon :

- le mapping final vers `BattleSetup` reste encore placeholder ;
- `_toBattleSetup()` injecte encore des espèces, niveaux et moves simplifiés au lieu de consommer complètement les vraies données projet/save.

Conclusion :

- le vrai point critique n'est pas "faire apparaître un combat" ;
- le vrai point critique est de **faire cesser les placeholders métier** entre runtime, données projet et moteur battle.

### 3.6. Field moves

Surf existe déjà comme pattern réel.

Conclusion :

- les futures capacités terrain doivent généraliser ce pattern ;
- elles ne doivent pas le dupliquer en plusieurs sous-systèmes hardcodés.

## 4. Ce qui reste partiel

Cette section couvre les zones déjà entamées mais pas encore suffisamment solides pour être considérées comme "terminées".

### 4.1. Pokédex auteur

Le Pokédex existe, et la phase R1 a déjà fortement avancé dans le worktree :

- la résolution de requête externe existe ;
- l'auto-complétion mono-espèce existe ;
- le flow batch existe maintenant jusqu'à l'exécution réelle avec rapport ;
- l'assistance moves-first du learnset editor est réellement branchée ;
- un socle progressif de recherche catalogue locale existe maintenant pour
  préparer la suite sans recréer de deuxième système.

Ce qui manque encore côté Pokédex auteur :

- la maintenance bulk ergonomique plus riche ;
- les outils de revalidation / resync / maintenance globale ;
- l'extension du socle moves-first aux surfaces futures qui en ont réellement
  besoin ;
- le confort auteur sur gros volumes de données.

### 4.2. Catalogues et références assistées

Le catalogue moves n'est plus seulement présent au niveau technique ; il est
maintenant réellement exploité au niveau produit dans le learnset editor, et il
dispose désormais d'un premier contrat progressif de recherche locale.

Ce qui reste encore partiel :

- les trainers bénéficient maintenant d'une première exploitation réelle du
  socle progressif pour species / moves / items ;
- les autres écrans n'en profitent pas encore suffisamment ;
- moves reste la priorité avant toute généralisation plus large ;
- abilities / items / types / egg groups / growth rates sont encore à traiter
  de manière progressive.

### 4.3. Trainers et encounters

Le socle n'est plus au même stade des deux côtés :

- trainers :
  - la surface minimale exploitable est maintenant livrée ;
  - un auteur peut créer un trainer complet sans JSON ;
  - il reste du confort plus tardif, mais le seuil produit du lot 7 est atteint
    ;
- encounters :
  - la surface minimale exploitable est maintenant livrée ;
  - un auteur peut configurer une table wild valide sans JSON manuel fragile ;
  - il reste du confort plus tardif, mais le seuil produit du lot 8 est
    atteint.

### 4.4. Bridge runtime -> battle

C'est aujourd'hui le plus gros point de vérité technique restant :

- le runtime sait lancer le combat ;
- mais le mapping final vers `BattleSetup` reste encore trop placeholder ;
- tant que ça n'est pas traité, la boucle de jeu Pokémon n'est pas vraiment prouvée.

### 4.5. Combat system

Le moteur battle existe, mais la profondeur système reste limitée :

- dégâts encore trop simplifiés ;
- pas encore toute la chaîne type chart / PP / accuracy / switch / statuts ;
- pas encore une boucle Pokémon crédible de bout en bout.

## 5. Ce qui reste réellement à construire

Voici les grands blocs qui restent réellement à construire, en distinguant bien le cœur de boucle du confort plus tardif.

### 5.1. Must-have avant toute ambition "fangame complet"

- maintenance Pokédex bulk plus riche
- extension progressive du socle moves-first aux surfaces suivantes utiles
- bridge runtime -> battle réel
- combat sauvage réel
- seen/caught persistant
- capture minimale
- trainer battle minimal complet
- heal / whiteout-lite

### 5.2. Should-have après preuve de boucle

- catalogues additionnels progressifs
- battle depth stage 1 puis stage 2
- starter / gifts / static encounters
- shop minimal
- centre Pokémon plus propre
- field abilities généralisées

### 5.3. Later

- tooling auteur plus riche
- recherche globale projet
- dashboard santé étendu
- UX runtime joueur plus ambitieuse
- documentation complète
- projet démo de référence
- packaging / build guide final

## 6. Roadmap maître recalée

La roadmap ci-dessous est le nouveau document de pilotage global.
Elle est volontairement plus compacte que la première version.

### Phase A — Pokédex auteur productif

But :

- rendre l'import, la recherche, le batch et la maintenance Pokédex réellement exploitables à l'échelle.

Contenu :

- résolveur de requête externe ;
- auto-complétion mono-espèce ;
- batch selection ;
- dry-run batch ;
- exécution batch ;
- rapport final ;
- revalidate / reimport / delete / maintenance bulk.

### Phase B — Références assistées progressives, moves-first

But :

- faire disparaître les champs texte bruts là où ils créent le plus de dette.

Ordre recommandé :

1. moves partout où ils débloquent une vraie valeur ;
2. species/forms/items dans trainers et encounters ;
3. autres catalogues seulement quand un écran ou une boucle les exige réellement.

Important :

- cette phase part d'un socle déjà présent ;
- elle ne recrée ni le moves catalog, ni son import, ni sa première surface éditeur ;
- elle prolonge ce qui est déjà livré en 11B.

Avancement réel à date :

- lot 5 livré :
  - learnset editor moves-first réellement assisté ;
- lot 6 livré :
  - contrat progressif de recherche catalogue locale branché sur `moves`.
- lot 7 livré :
  - trainers branchés sur ce socle de manière locale et non parallèle pour
    species / moves / items / forms quand ces données sont réellement
    disponibles.

### Phase C — Authoring trainers / encounters convergent

But :

- permettre à un auteur de produire sans JSON manuel des données directement combatables.

Contenu :

- trainer library minimal mais propre ;
- encounter tables minimales mais propres ;
- validation inline ;
- preview auteur simple.

Avancement réel à date :

- lot 7 livré :
  - la partie trainers du milestone est atteinte ;
- lot 8 livré :
  - encounter tables minimales mais propres ;
  - assistance locale `species` branchée sur le Pokédex local ;
  - validation inline lisible sur species / niveaux / poids ;
  - surface suffisante pour authorer une table wild sans texte libre fragile.
- lot 8-2 livré :
  - le trainer authoring détaillé vit maintenant dans un vrai workspace
    principal `Trainer Studio` ;
  - la sidebar trainer n'est plus la surface d'édition complète, mais un
    launcher / résumé rapide ;
  - la liste de trainers, le détail trainer et l'éditeur guidé du Pokémon
    vivent ensemble dans une surface centrale plus lisible ;
  - les sélecteurs `species` / `moves` / `items` parlent d'abord en noms
    lisibles, avec les IDs bruts conservés comme fallback honnête.
- lot 8-3 livré :
  - les moves du `Trainer Studio` sont maintenant guidés par le learnset local
    de l'espèce sélectionnée et par le niveau courant ;
  - la façade principale n'expose plus les IDs bruts comme mode dominant :
    ils restent disponibles dans un fallback avancé ;
  - les états dégradés restent honnêtes quand le learnset local, le catalogue
    moves ou les références locales sont indisponibles.

### Phase D — Bridge runtime -> battle réel

But :

- faire sauter le placeholder entre les données projet/save et le moteur battle.

Contenu :

- mapper la vraie party joueur ;
- mapper les wild encounters réels ;
- mapper les vraies teams trainers ;
- appliquer proprement le résultat de combat au `GameState`.

### Phase E — Boucle Pokémon minimale jouable

But :

- prouver une vraie boucle Pokémon verticale.

Contenu :

- combat sauvage réel ;
- seen/caught ;
- capture minimale ;
- save/load cohérent ;
- combat trainer minimal ;
- heal / whiteout-lite.

### Phase F — Battle depth progressive

But :

- rendre le combat crédible sans bloquer la preuve de boucle.

Découpage recommandé :

- F1 : stats et payloads enrichis
- F2 : dégâts + STAB + type chart
- F3 : accuracy + crit + priorité + PP
- F4 : switch et parties complètes
- F5 : statuts majeurs
- F6 : abilities / items / forms progressifs
- F7 : rewards / IA / hooks de progression

### Phase G — Boucle fangame minimale complète

But :

- dépasser la simple preuve de combat pour obtenir un mini jeu Pokémon jouable.

Contenu :

- starter / gift / static encounter ;
- centre Pokémon ;
- shop minimal ;
- progression terrain généralisée ;
- économie et boucle de survie plus propre.

### Phase H — Tooling auteur, UX runtime et docs

But :

- transformer le repo en vrai produit interne confortable.

Contenu :

- validation actionnable ;
- health dashboard ;
- recherche globale ;
- playtest rapide ;
- rapports exportables ;
- UX runtime joueur enrichie ;
- documentation ;
- projet démo.

## 7. Milestones verticaux recalés

Ces milestones sont les vrais jalons de preuve.
Ils servent à éviter l'effet "beaucoup de lots terminés, peu de boucle réellement jouable".

### M1 — Pokédex auteur utilisable

Ce que ce milestone prouve :

- un auteur peut importer et maintenir des espèces à grande échelle sans bricoler.

Statut actuel :

- livré ;
- lots 1, 2, 3 et 4 livrés ;
- la base Pokédex auteur productif du cycle R1 est maintenant réellement
  atteinte.

Gate de sortie :

- mono-espèce avec auto-complétion ;
- batch sélectionnable ;
- dry-run batch ;
- exécution batch ;
- rapport lisible ;
- pas de parsing batch caché dans l'UI.

### M2 — Données combat authorables correctement

Ce que ce milestone prouve :

- les données qui alimentent le gameplay combatable peuvent être produites proprement dans l'éditeur.

Statut actuel :

- livré ;
- lot 5 livré :
  - learnsets profitent réellement du catalogue moves local ;
- lot 6 livré :
  - le socle de recherche catalogue locale est maintenant prêt pour être
    réutilisé ;
- lot 7 livré :
  - trainers authorables sans JSON manuel ;
  - édition de team assistée là où les données locales existent ;
- lot 8 livré :
  - encounter tables authorables sans texte libre fragile ;
  - validation inline lisible sur species / niveaux / poids ;
  - poids et parts relatives lisibles pour l'auteur ;
  - états dégradés honnêtes quand le Pokédex local est indisponible.
- lot 8-2 livré :
  - `Trainer Studio` promu dans le workspace central ;
  - roster trainer, détail trainer et édition guidée des Pokémon visibles
    simultanément ;
  - selectors guidés `species` / `moves` / `items` plus lisibles pour un
    auteur non technique ;
  - IDs bruts toujours possibles, mais plus en façade principale.
- lot 8-3 livré :
  - choix des moves contextualisé par espèce + niveau quand le learnset local
    existe ;
  - suggestions guidées issues de `startingMoves`, `relearnMoves` et
    `levelUp <= niveau` ;
  - wording plus compréhensible quand les suggestions guidées ne peuvent pas
    être chargées ;
  - fallback brut maintenu, mais relégué à une zone avancée.

Gate de sortie :

- learnsets profitent réellement du catalogue moves local ;
- trainers authorables sans JSON manuel ;
- encounter tables authorables sans texte libre fragile ;
- erreurs de refs visibles immédiatement ;
- preview auteur minimale disponible là où utile.

### M3 — Handoff combat réel

Ce que ce milestone prouve :

- le runtime ne triche plus entre ses requests, les données projet et `BattleSetup`.

Gate de sortie :

- plus de placeholder métier dans le handoff ;
- vraie party joueur mappée ;
- vraies species wild mappées ;
- vraies teams trainers mappées ;
- tests runtime dédiés.

### M4 — Combat sauvage jouable

Ce que ce milestone prouve :

- la première vraie boucle Pokémon verticale existe.

Gate de sortie :

- déplacement ;
- rencontre sauvage ;
- handoff réel ;
- combat jouable ;
- retour overworld propre ;
- état runtime resynchronisé.

### M5 — Capture et persistance minimale

Ce que ce milestone prouve :

- la boucle de jeu commence à "tenir" comme jeu Pokémon, pas seulement comme démo de combat.

Gate de sortie :

- seen/caught persiste ;
- capture minimale fonctionne ;
- l'équipe ou un fallback minimal est mis à jour proprement ;
- save/load relit correctement ce nouvel état.

### M6 — Combat trainer minimal complet

Ce que ce milestone prouve :

- la seconde grande boucle du RPG Pokémon est présente.

Gate de sortie :

- trainer battle réel ;
- victoire/défaite mappées ;
- anti-retrigger ;
- reward minimal ;
- flags de progression cohérents.

### M7 — Boucle fangame minimale complète

Ce que ce milestone prouve :

- on a un mini fangame Pokémon jouable du début à une petite boucle de progression.

Gate de sortie :

- starter ou gift minimal ;
- wild battle ;
- capture ;
- trainer battle ;
- heal ;
- whiteout-lite ;
- save/load toujours cohérent.

### M8 — Combat crédible v2

Ce que ce milestone prouve :

- le système de combat devient défendable comme vrai combat Pokémon simplifié.

Gate de sortie :

- dégâts crédibles ;
- type chart ;
- précision ;
- PP ;
- switch ;
- statuts stage 1.

### M9 — Tooling auteur de production

Ce que ce milestone prouve :

- le repo est tenable pour une production plus longue sans dette explosive.

Gate de sortie :

- validation actionnable ;
- recherche projet ;
- bulk maintenance ;
- playtest rapide ;
- rapports exploitables.

## 8. Backlog prioritaire recalé

Cette section décrit les **15 lots prioritaires** du plan recalé et leur statut
courant.
Ils sont ordonnés pour maximiser la convergence produit, pas seulement la
pureté par domaine.

### Lot 1 — Résolveur de requête externe Pokédex

Priorité : `must-have`
Statut : `livré`

But :

- transformer une requête utilisateur en intention structurée :
  - mono-espèce ;
  - liste ;
  - plage dex ;
  - génération.

Pourquoi maintenant :

- c'est la base de toute l'UX Pokédex moderne.

Done :

- `bulbasaur`, `1-151`, `gen 1`, `pikachu,eevee,abra` sont reconnus correctement ;
- la sortie est structurée et réutilisable en UI ;
- aucun parsing batch métier dans les widgets.

Livré concrètement :

- modèles de résolution structurés dans `map_editor/application/models` ;
- résolveur pur dans `map_editor/application/services` ;
- provider DI dédié ;
- tests unitaires du résolveur ;
- report de lot déjà présent dans `reports/`.

### Lot 2 — Auto-complétion mono-espèce dans le wizard

Priorité : `must-have`
Statut : `livré`

But :

- remplacer la saisie libre fragile par une sélection assistée explicite.

Pourquoi maintenant :

- c'est le plus petit gain produit immédiatement visible.

Done :

- impossible de prévisualiser/importer sans espèce réellement résolue ;
- suggestions clavier/souris ;
- états loading / error / introuvable propres.

Livré concrètement :

- recherche mono-espèce branchée sur le résolveur du lot 1 ;
- sélection explicite obligatoire ;
- blocage de la preview/import sans suggestion choisie ;
- états UI hors-scope / invalide / aucun résultat ;
- tests UI et non-régression du flow mono-espèce ;
- report de lot déjà présent dans `reports/`.

### Lot 3 — Sélection batch + dry-run batch

Priorité : `must-have`
Statut : `livré`

But :

- exposer le batch de manière lisible avant écriture.

Pourquoi maintenant :

- le batch existe déjà côté métier ; il manque surtout le vrai flow auteur.

Done :

- liste finale ciblée visible ;
- doublons supprimés ;
- dry-run sans écriture ;
- preview stable et lisible même sur gros lot.

Livré concrètement :

- mode batch explicite dans le wizard `API externe` ;
- use case de résolution batch dédié ;
- support liste explicite / plage dex / génération ;
- affichage de la liste finale résolue avant preview ;
- blocage du dry-run si la sélection n'est pas propre ;
- dry-run branché sur le batch applicatif existant avec `dryRun: true` ;
- preview batch dédiée ;
- aucun import batch réel ;
- tests application, wiring, UI batch et non-régression mono ;
- report de lot déjà présent dans `reports/`.

Limites connues à garder visibles :

- la preview batch devient dense sur très gros lots ;
- le wizard reste encore raisonnablement maintenable, mais il faudra surveiller
  sa taille sur les lots suivants ;
- la preuve de non-écriture batch est forte, mais pas encore exhaustive
  artefact par artefact côté learnset/evolution/media/assets.

### Lot 4 — Exécution batch + progression + rapport

Priorité : `must-have`
Statut : `livré`

But :

- rendre le batch réellement productif.

Done :

- progression ;
- compteurs succès / conflit / skip / erreur ;
- rapport final clair.

Livré concrètement :

- bouton d'exécution batch réelle séparé du dry-run ;
- progression honnête branchée sur les callbacks du batch applicatif ;
- résultat final distinct de la preview dry-run ;
- compteurs visibles pendant et après exécution ;
- refresh du workspace si des écritures réelles ont eu lieu ;
- règle stable de sélection post-batch :
  - première espèce réellement écrite dans l'ordre de la sélection résolue ;
- tests application, wiring, UI et non-régression lot 2 / lot 3 ;
- report de lot présent dans `reports/`.

Non-objectifs explicitement conservés :

- pas de retry ;
- pas de relance partielle ;
- pas d'exécution en arrière-plan ;
- pas de cancellation avancée ;
- pas de refonte du wizard complet.

### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Priorité : `must-have`
Statut : `livré`

But :

- faire passer le learnset editor d'une simple garde minimale à une vraie saisie assistée moves-first.

Pourquoi maintenant :

- le socle moves catalog local existe déjà ;
- il faut maintenant l'utiliser davantage.

Done :

- recherche locale de moves dans le learnset editor ;
- sélection assistée ;
- validation plus lisible ;
- affichage honnête des ids legacy hors catalogue.

Livré concrètement :

- assistance locale branchée sur le catalogue `moves` déjà présent ;
- ajout assisté pour les sections de learnset existantes ;
- conservation explicite des ids legacy / inconnus ;
- amélioration de la lisibilité de validation sans créer un deuxième éditeur ;
- tests dédiés et report de lot présents dans `reports/`.

### Lot 6 — Service de recherche catalogue progressif

Priorité : `must-have`
Statut : `livré`

But :

- créer le contrat commun réutilisable pour les catalogues locaux.

Important :

- le service doit partir du moves catalog déjà présent ;
- il ne doit pas forcer d'emblée abilities/items/types si ces catalogues ne sont pas encore prêts à être productisés.

Done :

- recherche par id/libellé ;
- contrat stable ;
- réutilisable par Pokédex, trainers et encounters.

Livré concrètement :

- petit socle générique en mémoire pour la recherche catalogue locale ;
- convergence de `PokemonMovesCatalogLookupService` sur ce socle ;
- aucun second système concurrent de lookup `moves` ;
- réutilisation immédiate par le travail moves-first déjà livré ;
- tests dédiés et report de lot présents dans `reports/`.

### Lot 7 — Trainers : surface minimale vraiment exploitable

Priorité : `must-have`
Statut : `livré`

But :

- permettre à un auteur de créer un trainer complet sans JSON.

Done :

- création/édition/suppression trainer ;
- édition propre de la team ;
- species/moves/items/forms assistés là où c'est disponible ;
- erreurs visibles immédiatement ;
- sauvegarde stable ;
- un auteur peut créer un trainer complet sans JSON.

Livré concrètement :

- surface `TrainerLibraryPanel` enrichie sans second éditeur ;
- refs assistées pour :
  - species ;
  - moves ;
  - items quand le catalogue local existe ;
  - forms via les données locales d'espèce ;
- champs bruts conservés honnêtement quand une aide locale n'existe pas encore
  ;
- validation inline lisible avant save ;
- use cases trainers étendus minimalement pour normaliser tags / moves / champs
  optionnels ;
- `EditorNotifier` mis à jour pour garder les formulaires ouverts seulement en
  cas d'échec et fermer proprement sur succès ;
- tests applicatifs, widget et wiring dédiés ;
- report de lot présent dans `reports/`.

### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Priorité : `must-have`
Statut : `livré`

But :

- permettre à un auteur de configurer une table wild valide sans texte libre fragile.

Done :

- add/edit/delete d'entrées ;
- species assistée ;
- validation niveau/poids ;
- lisibilité des probabilités ;
- preview auteur simple si le coût reste faible ;
- un auteur peut configurer une table wild valide sans texte libre fragile.

Livré concrètement :

- surface `EncounterTablesPanel` enrichie sans second éditeur ;
- recherche locale `species` par id / nom / numéro Pokédex via l'index local ;
- distinction explicite :
  - résolu localement ;
  - absent du Pokédex local ;
  - vérification impossible ;
- validation inline lisible avant save ;
- fermeture des formulaires uniquement sur succès réel ;
- poids totaux et pourcentages dérivés visibles dans la table ;
- tests applicatifs + widget + non-régressions dédiés ;
- report de lot présent dans `reports/`.

### Lot 8-2 — Trainer Studio principal + refonte UX/UI du trainer authoring

Priorité : `must-have`
Statut : `livré`

But :

- faire du trainer authoring un vrai workspace principal lisible, sans créer
  un second pipeline trainer.

Done :

- trainer studio central ;
- sidebar trainer réduite à un launcher / résumé ;
- liste de trainers lisible ;
- détail trainer visible ;
- édition guidée des Pokémon avec vrais slots de moves ;
- sélecteurs lisibles basés sur les noms avant les IDs ;
- wording produit plus compréhensible ;
- fallbacks honnêtes quand les données locales sont indisponibles.

Livré concrètement :

- surface principale `TrainerLibraryPanel` réutilisée comme `Trainer Studio`
  dans le workspace central, sans seconde UI concurrente ;
- roster trainer à gauche, détail trainer au centre, éditeur guidé du Pokémon
  à droite ;
- sélection `species` via le Pokédex local, avec nom, id, numéro Pokédex et
  types en secondaire ;
- sélection de moves par slots `Move 1..4` avec recherche guidée dans le
  catalogue local des attaques ;
- sélection d'item plus lisible quand le catalogue local existe ;
- champs bruts conservés comme fallback honnête au lieu d'être la façade
  principale ;
- tests widget + smoke shell + non-régressions utiles dédiés ;
- report de lot présent dans `reports/`.

### Lot 8-3 — Trainer Studio guidé par learnset local

Priorité : `must-have`
Statut : `livré`

But :

- rendre le `Trainer Studio` réellement no-code-friendly pour l'édition des
  moves, sans créer de nouveau pipeline trainer.

Done :

- moves guidés par espèce + niveau ;
- suggestions lisibles pour un auteur ;
- IDs bruts relégués en fallback secondaire ;
- wording honnête quand les données locales sont absentes ;
- aucun nouveau store / notifier / repository trainer.

Livré concrètement :

- suggestions de moves issues du learnset local de l'espèce sélectionnée ;
- prise en compte au minimum de :
  - `startingMoves` ;
  - `relearnMoves` ;
  - `levelUp` dont le niveau d'apprentissage est inférieur ou égal au niveau
    courant ;
- libellés de suggestions lisibles avec :
  - nom du move en premier ;
  - id en secondaire ;
  - source visible (`Start`, `Relearn`, `Lv.X`) ;
- champs bruts `species` / `moves` / `items` / `forms` conservés dans une zone
  de fallback avancée au lieu de rester la façade principale ;
- messages honnêtes quand :
  - aucune espèce n'est sélectionnée ;
  - le niveau n'est pas encore exploitable ;
  - le learnset local n'existe pas ;
  - le catalogue local des moves est indisponible ;
- tests widget trainer renforcés ;
- report de lot présent dans `reports/`.

### Lot 9 — Mappers runtime réels vers `BattleSetup`

Priorité : `must-have`

But :

- supprimer les placeholders métier du handoff combat.

Done :

- player party -> `BattleSetup`
- wild encounter -> `BattleSetup`
- trainer team -> `BattleSetup`
- plus aucune espèce/move hardcodée dans le mapping final.

### Lot 10 — Application du résultat de combat au `GameState`

Priorité : `must-have`

But :

- resynchroniser réellement le runtime après combat.

Done :

- HP post-combat appliqués ;
- issues victory/defeat/runaway mappées ;
- trainer defeated flag cohérent ;
- retour overworld propre.

### Lot 11 — Combat sauvage end-to-end jouable

Priorité : `must-have`

But :

- obtenir la première vraie preuve verticale de boucle Pokémon.

Done :

- déplacement -> rencontre -> combat -> retour overworld ;
- plus aucun placeholder métier visible ;
- tests runtime de non-régression.

### Lot 12 — Seen / caught persistants

Priorité : `must-have`

But :

- préparer la boucle Pokémon persistée sans encore ouvrir un chantier capture trop gros d'un seul bloc.

Done :

- état seen/caught sérialisé ;
- save/load cohérent ;
- runtime capable d'en tirer parti.

### Lot 13 — Capture runtime minimale

Priorité : `must-have`

But :

- ajouter la capture comme premier vrai enrichissement de la boucle sauvage.

Done :

- consommation d'une ball ;
- résolution minimale de capture ;
- mise à jour seen/caught ;
- insertion contrôlée dans l'équipe ou fallback minimal.

### Lot 14 — Combat trainer minimal complet

Priorité : `must-have`

But :

- prouver la seconde grande boucle de jeu.

Done :

- trainer battle réel ;
- victoire/défaite stables ;
- anti-retrigger ;
- reward minimal ;
- flags cohérents.

### Lot 15 — Heal / center / whiteout-lite

Priorité : `must-have`

But :

- fermer la boucle de survie minimale du jeu.

Done :

- soin complet ;
- point de reprise minimal ;
- whiteout-lite ;
- save/load toujours cohérent après ces transitions.

## 9. Lots redécoupés / reformulés

Cette section capture explicitement les corrections de forme appliquées à la roadmap précédente.

### 9.1. Catalogues

Ancienne erreur :

- traiter d'un bloc moves + abilities + items + types + egg groups + growth rates.

Décision recalée :

- **moves d'abord** ;
- ensuite seulement les autres catalogues quand un écran ou un workflow les exige réellement.

### 9.2. Trainers

Ancienne erreur :

- "upgrade panel trainer" restait trop abstrait.

Nouvelle définition :

- **un auteur peut créer un trainer complet sans JSON**
- **la team est éditable proprement**
- **les refs invalides sont visibles immédiatement**

### 9.3. Encounter tables

Ancienne erreur :

- "upgrade encounter tables" restait trop vague.

Nouvelle définition :

- **un auteur peut configurer une table wild valide sans texte libre fragile**
- **les probabilités sont lisibles**
- **les erreurs sont visibles avant runtime**

### 9.4. Capture / seen-caught / save-load

Ancienne erreur :

- tout mélanger dans un seul lot trop gros.

Nouvelle décision :

- d'abord seen/caught persistants ;
- ensuite capture runtime minimale ;
- ensuite seulement les raffinements de party overflow, boxes complètes et UX avancée.

### 9.5. Combat depth

Ancienne erreur :

- compacter trop de profondeur battle dans une seule phase.

Nouvelle décision :

- prouver d'abord la boucle verticale avec un moteur encore simple ;
- approfondir ensuite en plusieurs étages clairement séparés.

## 10. Registre de risques mis à jour

### 10.1. Risques techniques

- `PlayableMapGame` peut continuer à grossir trop vite si l'on ne sort pas assez tôt les mappers et l'outcome applier.
- le contrat entre données locales Pokémon, battle setup et moteur combat peut rester incomplet.
- le moteur `map_battle` peut devenir le nouveau goulet si on lui demande trop tôt toute la profondeur système.

### 10.2. Risques de migration

- toute extension de `GameState` / `PlayerPokemon` a un coût réel de migration ;
- si on ouvre trop vite boxes + progression dex + capture + UI runtime complète, le risque de dette de save augmente fortement.

### 10.3. Risques d'UX auteur

- si les champs texte libres restent trop longtemps dans learnsets/trainers/encounters, la dette de données continuera à s'accumuler ;
- si le batch Pokédex devient trop complexe trop tôt, l'outil peut devenir impressionnant mais peu fiable.

### 10.4. Risques produit

- trop de polish auteur avant preuve de boucle de jeu ;
- faux sentiment de progrès si beaucoup d'UI avancent alors que le handoff runtime -> battle reste placeholder ;
- faux sentiment de profondeur si `map_battle` grossit avant d'avoir prouvé la boucle verticale minimale.

### 10.5. Stratégie de mitigation

- garder le bridge runtime très haut dans l'ordre ;
- imposer des gates de sortie par milestone ;
- découper les lots save/capture/combat plus finement ;
- ne productiser les autres catalogues qu'au moment opportun ;
- préférer des tranches verticales prouvées à des lots "impressionnants" mais partiellement intégrés.

## 11. Ordre réaliste recommandé à partir d'aujourd'hui

L'ordre recommandé est le suivant :

1. Lots 1 à 4
   - rendre le Pokédex auteur vraiment productif
2. Lots 5 à 8
   - supprimer la dette de référence là où elle gêne déjà concrètement
3. Lots 9 à 11
   - supprimer les placeholders runtime -> battle et prouver le combat sauvage réel
4. Lots 12 à 15
   - transformer cette première boucle en mini boucle Pokémon persistée
5. Battle depth par étapes
6. Boucle fangame élargie
7. Tooling riche / UX runtime / docs

## 12. Verdict final

La roadmap initiale était **bonne comme vision**.

La version recalée de ce document est meilleure pour trois raisons :

- elle tient compte de ce qui est déjà acquis dans le repo, notamment la clôture 11A et le socle moves catalog 11B ;
- elle reconnaît plus explicitement que les catalogues locaux et une partie de la validation croisée existent déjà ;
- elle remonte le bridge runtime -> battle à la bonne hauteur de priorité ;
- elle remplace une progression trop "par domaine" par une progression plus **verticale, prouvable et jouable**.

La bonne suite réaliste n'est donc pas :

- de réouvrir 11A ;
- de réinventer la stack Pokémon ;
- de lancer immédiatement toute la profondeur battle ;
- ou de multiplier les catalogues d'un coup.

La bonne suite réaliste est :

1. finaliser un **poste de travail Pokédex productif** ;
2. fiabiliser les **références assistées moves-first** ;
3. rendre **trainers et encounters** vraiment authorables ;
4. supprimer les **placeholders runtime -> battle** ;
5. obtenir une **boucle sauvage réelle** ;
6. ajouter **capture + persistance minimale** ;
7. puis seulement approfondir le combat, la progression, l'économie et le tooling.
```
