# 1. Résumé exécutif honnête

Le lot 5 a été implémenté en restant strictement local au learnset editor du Pokédex.

La trajectoire retenue a été la plus petite extension cohérente avec l’existant :
- conservation des textareas existantes comme source de vérité ;
- réutilisation du catalogue local `moves` déjà chargé dans l’onglet Learnset ;
- ajout d’une assistance locale de recherche/sélection de moves pour préparer les lignes du learnset ;
- ajout d’aperçus résolus / legacy / inconnus pour rendre la validation plus lisible ;
- aucun nouveau pipeline Pokédex, aucun second catalogue, aucun second éditeur learnset.

Concrètement, le learnset editor permet maintenant :
- de rechercher un move local par `id` ou `name` ;
- de l’ajouter explicitement dans les sections `startingMoves` et `relearnMoves` ;
- de préparer des lignes structurées assistées pour `levelUp`, `tm`, `tutor`, `egg`, `event` et `transfer` ;
- de garder les ids legacy/inconnus visibles avec un marquage explicite quand le catalogue local est disponible ;
- de rendre les erreurs de structure plus visibles avant la sauvegarde, sans déplacer la vraie validation métier hors du use case existant.

Le lot reste volontairement borné :
- pas de refonte complète du learnset editor ;
- pas de lot trainers ;
- pas de moteur générique de recherche catalogue ;
- pas de logique réseau ;
- pas de réécriture des lots 1 à 4.

# 2. État initial audité

Avant modification, l’audit du vrai code a montré :

- Le learnset editor vit principalement dans `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart` et `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`.
- L’édition reposait presque entièrement sur des `TextEditingController` et des `CupertinoTextField` multiline.
- La conversion UI -> modèles applicatifs passait déjà par les helpers de `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_formatters.dart` puis le use case `UpdatePokedexSpeciesLearnsetUseCase`.
- Le catalogue local des moves existait déjà via 11B et était déjà chargé / synchronisé dans `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`.
- Le use case `UpdatePokedexSpeciesLearnsetUseCase` validait déjà les move ids contre le catalogue local `moves` si ce catalogue était réellement disponible.
- Le learnset editor ne consommait pas encore réellement cette source locale pour assister la saisie.

Friction produit principale constatée :
- l’auteur devait encore taper ou copier des `moveId` à la main dans les différentes sections du learnset ;
- les ids inconnus n’étaient signalés clairement qu’au moment du save ou de la validation projet ;
- le catalogue local des moves existait dans le même onglet mais n’était pas exploité directement par le formulaire d’édition.

# 3. Périmètre inclus / exclu

## Inclus

- exploitation réelle du catalogue local `moves` dans le learnset editor ;
- recherche locale par `id` / `name` pour préparer des entrées de learnset ;
- assistance explicite pour `startingMoves`, `relearnMoves`, `levelUp`, `tm`, `tutor`, `egg`, `event`, `transfer` ;
- rendu honnête des ids legacy / inconnus quand le catalogue local est disponible ;
- amélioration de la lisibilité des erreurs de structure côté UI ;
- tests applicatifs et UI ciblés ;
- non-régressions ciblées sur le moves catalog et sur les lots 2 à 4.

## Exclu

- refonte complète du learnset editor ;
- refonte trainers / encounters ;
- nouveau moteur générique de recherche catalogue ;
- nouveau pipeline `moves` ;
- nouveau loader / repository de moves ;
- réouverture de la 11A ou de la 11B ;
- changements runtime / battle / save ;
- lot 6 ou généralisation aux trainers.

# 4. Décisions d’architecture

## 4.1. Garder les textareas comme source de vérité

Décision retenue :
- ne pas créer un deuxième éditeur learnset structuré ;
- garder le texte brut comme contrat d’édition local ;
- ajouter une couche d’assistance locale au-dessus, sans masquer ce texte.

Pourquoi :
- cela minimise le risque de casser le save existant ;
- cela respecte le contrat applicatif actuel ;
- cela permet de garder les ids legacy visibles au lieu de les réécrire silencieusement.

## 4.2. Réutiliser le catalogue `moves` déjà chargé

Décision retenue :
- utiliser la même projection `PokemonMovesCatalogView` issue du use case 11B ;
- ne pas créer un deuxième loader, ni un deuxième port, ni un deuxième provider réseau.

Pourquoi :
- le repo avait déjà la bonne source de vérité locale ;
- le lot 5 demandait d’exploiter l’existant, pas de recréer une stack.

## 4.3. Ajouter un helper de lookup ciblé sur `moves`

Décision retenue :
- création de `PokemonMovesCatalogLookupService` comme helper pur et spécifique au catalogue local des moves.

Pourquoi :
- éviter de mettre toute la logique de recherche/résolution dans les widgets ;
- ne pas inventer un moteur de recherche catalogue générique prématuré ;
- réutiliser la même logique de filtre dans la section catalogue et dans l’assistance learnset.

Rejeté explicitement :
- un nouveau use case/provider juste pour la recherche locale dans le learnset editor ;
- un service multi-catalogues “future-proof”.

## 4.4. Assistance explicite, pas sélection implicite

Décision retenue :
- pas d’auto-correction ni d’auto-normalisation cachée ;
- l’auteur cherche un move local et le sélectionne explicitement ;
- pour les sections structurées, la ligne reste explicitement complétée par les métadonnées attendues (`level`, `source`, `versionGroup`).

Pourquoi :
- éviter toute magie qui transformerait silencieusement la donnée saisie ;
- rester cohérent avec les avertissements du reviewer contradicteur.

## 4.5. Ne pas prétendre qu’un move est “absent” si le catalogue est indisponible

Décision retenue :
- distinction claire entre :
  - `Résolu localement`
  - `Absent du catalogue local`
  - `Résolution indisponible`

Pourquoi :
- sinon l’UI mentirait sur l’état réel du catalogue.

# 5. Liste exacte des fichiers modifiés / créés / supprimés

## Modifiés

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`

## Créés

- `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart`
- `packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart`
- `packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart`

## Supprimés

- aucun

# 6. Justification fichier par fichier

## `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`

Ajout d’un helper pur pour :
- chercher localement des moves dans le catalogue déjà synchronisé ;
- résoudre un `moveId` exact ;
- éviter de dupliquer la logique de recherche dans plusieurs widgets.

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`

Changement minimal de bibliothèque racine :
- import du helper de lookup ;
- ajout du nouveau `part` UI privé pour garder le learnset editor maintenable.

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`

Extension locale du tab Learnset :
- cache d’un `Future<PokemonMovesCatalogView>` pour que l’assistance et la section catalogue consomment la même source locale ;
- hook de refresh après sync du catalogue ;
- injection de ce futur dans la surface d’édition.

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`

Réécriture locale de la section édition learnset pour :
- garder le squelette existant ;
- remplacer la suite de textareas nues par des sous-sections assistées ;
- conserver les boutons save/cancel et le message d’erreur existants.

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`

Mini-extension locale :
- réutilisation du helper de lookup pour la recherche existante ;
- callback `onCatalogChanged` pour notifier le learnset editor qu’un sync a rafraîchi le catalogue.

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart`

Nouveau fichier privé UI du lot 5 :
- picker local de move ;
- composers assistés pour les sections simples et structurées ;
- previews résolus / legacy / indisponibles ;
- helpers d’insertion locale dans les textareas existantes.

## `packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart`

Tests applicatifs ciblés sur le helper de lookup local :
- recherche par id ;
- recherche par nom ;
- absence de résultat propre.

## `packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart`

Tests UI ciblés du lot 5 :
- ajout assisté dans `startingMoves` ;
- ajout assisté structuré dans `tm` ;
- visibilité honnête d’un id legacy / inconnu.

# 7. Sub-agents utilisés, conclusions, retenu / rejeté

Je n’ai pas pu créer de nouveaux threads : la limite de threads était déjà atteinte. J’ai donc réutilisé honnêtement des threads existants.

## Scope / architecture reviewer

Thread réutilisé : `019d81fd-7906-74c1-9005-b84399f7700e`

Conclusion principale :
- le plus petit point d’intégration honnête est directement dans le learnset editor existant ;
- pas de nouveau resolver/use case si la recherche reste un simple filtre local sur le catalogue déjà chargé.

Retenu :
- intégration dans le learnset editor ;
- helper pur local `moves` ;
- pas de nouveau provider.

Rejeté :
- nouveau pipeline de recherche moves ;
- nouvelle stack catalogue.

## UX / flow éditeur reviewer

Thread réutilisé : `019d81fd-7b05-7302-8681-e779fd0d6a36`

Conclusion principale :
- garder les textareas existantes ;
- ajouter une aide inline pour chercher/sélectionner un move ;
- ne pas transformer l’onglet en deuxième éditeur structuré.

Retenu :
- assistance inline ;
- sélection explicite ;
- ids legacy visibles et signalés.

Rejeté :
- modal ou sous-workspace “Move Library” ;
- auto-remplacement implicite du texte saisi.

## Test matrix reviewer

Thread réutilisé : `019d81fd-79ff-7213-9215-a788ac13b984`

Conclusion principale :
- un petit test applicatif sur la recherche locale est justifié si la logique sort du widget ;
- un fichier UI dédié pour le lot 5 est préférable à l’ajout de bruit dans le gros smoke test.

Retenu :
- `pokemon_moves_catalog_lookup_service_test.dart` ;
- `pokedex_learnset_moves_assist_ui_test.dart` ;
- non-régressions ciblées sur lots 2 à 4 ;
- non-régression ciblée sur le moves catalog sync.

Rejeté :
- duplication complète des suites des lots 1 à 4 ;
- tests décoratifs de rendu pixel-perfect.

## Contradicteur

Thread réutilisé : `019d821b-9941-71c1-9001-d32c767ea874`

Conclusion principale :
- ne pas durcir le learnset editor au point de rendre le catalogue moves obligatoire ;
- ne pas marquer “absent du catalogue” si le catalogue est en fait indisponible ;
- ne pas glisser vers un deuxième pipeline moves ;
- ne pas faire de fuzzy matching ni d’auto-normalisation opaque.

Retenu :
- le save use case reste l’autorité de validation métier ;
- l’assistance reste facultative et locale ;
- distinction `résolu / absent / résolution indisponible`.

Rejeté :
- auto-correction silencieuse ;
- “sync moves puis save learnset” en un seul flux ;
- nouvelle stack parallèle d’assistance.

# 8. Commandes réellement exécutées

## Audit

```bash
rg --files -g 'AGENTS.md'
rg -n "learnset|moves catalog|movesCatalog|Move" packages/map_editor/lib/src/ui/canvas/pokedex_workspace packages/map_editor/lib/src/application/use_cases packages/map_editor/lib/src/application/models packages/map_editor/lib/src/app/providers/pokedex packages/map_editor/test -g'*.dart'
sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart
sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart
sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart
sed -n '1,260p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,260p' packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart
sed -n '800,940p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '2640,2795p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
sed -n '300,420p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
sed -n '220,420p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart
sed -n '1,240p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_formatters.dart
sed -n '1,220p' packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart
sed -n '1,260p' packages/map_editor/test/provider_wiring_test.dart
sed -n '1,220p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '2980,3245p' packages/map_editor/test/pokedex_workspace_ui_test.dart
```

## Format

```bash
dart format packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart
```

## Analyse

```bash
flutter analyze --no-pub lib/src/application/services/pokemon_moves_catalog_lookup_service.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart
```

## Tests ciblés

```bash
flutter test test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart test/update_pokedex_species_learnset_use_case_test.dart
flutter test test/pokedex_external_autocomplete_ui_test.dart test/pokedex_external_batch_dry_run_ui_test.dart test/pokedex_external_batch_execute_ui_test.dart
flutter test test/pokedex_workspace_ui_test.dart --plain-name "shows the local moves catalog section in the learnset tab and allows preview + sync"
flutter test test/pokedex_workspace_ui_test.dart --plain-name "creates a learnset locally from the dedicated tab"
flutter test test/sync_pokemon_moves_catalog_use_case_test.dart
```

## Git / état

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

# 9. Résultats réels

## `dart format`

```text
Formatted packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart
Formatted packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
Formatted packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart
Formatted 8 files (3 changed) in 0.03 seconds.
```

## `flutter analyze --no-pub`

```text
Analyzing 8 items...
No issues found! (ran in 1.7s)
```

## `flutter test test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart test/update_pokedex_species_learnset_use_case_test.dart`

```text
00:04 +10: All tests passed!
```

## `flutter test test/pokedex_external_autocomplete_ui_test.dart test/pokedex_external_batch_dry_run_ui_test.dart test/pokedex_external_batch_execute_ui_test.dart`

```text
00:04 +12: All tests passed!
```

## `flutter test test/pokedex_workspace_ui_test.dart --plain-name "shows the local moves catalog section in the learnset tab and allows preview + sync"`

```text
00:03 +1: All tests passed!
```

## `flutter test test/pokedex_workspace_ui_test.dart --plain-name "creates a learnset locally from the dedicated tab"`

```text
00:04 +1: All tests passed!
```

## `flutter test test/sync_pokemon_moves_catalog_use_case_test.dart`

```text
00:02 +2: All tests passed!
```

# 10. Incidents rencontrés

## 10.1. Limite de threads sub-agents

Incident :
- tentative initiale de création de nouveaux sub-agents refusée par l’environnement (`agent thread limit reached (max 6)`).

Action :
- réutilisation honnête de threads existants pour les quatre rôles demandés.

## 10.2. Startup lock Flutter

Incident :
- lancement parallèle de plusieurs commandes `flutter test` qui a déclenché le startup lock Flutter.

Action :
- reprise des smokes en séquentiel.

## 10.3. Réactivité locale des champs du composer

Incident :
- les petits champs auxiliaires du composer (`level`, `source`, `versionGroup`) ne rebuiltaient pas encore honnêtement les boutons/erreurs.

Action :
- ajout de listeners locaux avec `setState()` dans les widgets stateful concernés.

## 10.4. Honnêteté du statut de résolution

Incident :
- première version du preview qui risquait de marquer “Absent du catalogue local” alors que le catalogue était simplement indisponible.

Action :
- séparation explicite des états `Résolu localement`, `Absent du catalogue local`, `Résolution indisponible`.

## 10.5. Deux widget tests initiaux incomplets

Incident :
- deux taps de tests touchaient des widgets hors écran.

Action :
- ajout de `ensureVisible(...)` avant l’interaction.

# 11. État git utile

## `git status --short`

```text
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
?? packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart
?? packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart
?? packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
```

## `git diff --stat`

```text
 .../pokedex_workspace/pokedex_learnset_panel.dart  |  13 +
 .../pokedex_learnset_sections.dart                 | 288 ++++++++++++---------
 .../pokedex_moves_catalog_section.dart             |  24 +-
 .../pokedex_workspace/pokedex_workspace_page.dart  |   2 +
 4 files changed, 187 insertions(+), 140 deletions(-)
```

## `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart
packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart
packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
```

# 12. Checklist finale

- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas réécrit 11A / 11B / lots 1 à 4
- [x] je n’ai pas déplacé de logique métier dans l’UI
- [x] j’ai bien exploité le catalogue moves existant au lieu d’en recréer un
- [x] le learnset editor est réellement plus assisté qu’avant
- [x] les ids inconnus/legacy restent visibles honnêtement
- [x] la validation est plus lisible
- [x] les tests prouvent les comportements importants
- [x] `dart format` a été exécuté
- [x] `flutter analyze --no-pub` a été exécuté
- [x] les tests ciblés ont été exécutés
- [x] aucun commit / merge / rebase / push / tag / stash / reset n’a été fait
- [x] le report final markdown a bien été créé
- [x] le report contient bien tous les fichiers texte modifiés/créés/supprimés en intégralité

# 13. Annexe — contenu complet des fichiers texte modifiés / créés / supprimés

Note explicite :
- cette annexe inclut le contenu complet de tous les fichiers texte modifiés ou créés pour ce lot ;
- le report lui-même n’est pas recopié intégralement dans sa propre annexe pour éviter une récursion infinie.


## `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`

```dart
import '../use_cases/sync_pokemon_moves_catalog_use_case.dart';

/// Recherche locale ciblée sur le catalogue `moves` déjà synchronisé.
///
/// Ce helper reste volontairement petit et spécifique :
/// - il ne recharge rien depuis le disque ;
/// - il ne crée pas une nouvelle stack "catalog search" générique ;
/// - il consomme simplement la projection 11B déjà utilisée par l'éditeur.
///
/// Le lot 5 en a besoin pour deux usages strictement locaux :
/// - retrouver rapidement un move connu par `id` exact ;
/// - filtrer des suggestions lisibles à partir du catalogue moves existant.
class PokemonMovesCatalogLookupService {
  const PokemonMovesCatalogLookupService();

  /// Retourne l'entrée exacte d'un move local à partir de son `moveId`.
  ///
  /// La résolution reste volontairement stricte :
  /// - elle compare uniquement l'id local canonique ;
  /// - elle n'essaie pas de normaliser, corriger ou réécrire un id legacy ;
  /// - elle permet donc à l'UI de signaler honnêtement les ids inconnus.
  PokemonMoveCatalogEntryView? findById(
    List<PokemonMoveCatalogEntryView> entries,
    String moveId,
  ) {
    final normalizedId = moveId.trim().toLowerCase();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (entry.id.toLowerCase() == normalizedId) {
        return entry;
      }
    }
    return null;
  }

  /// Filtre des suggestions locales stables pour l'éditeur.
  ///
  /// On garde une logique simple et déterministe :
  /// - priorité aux correspondances exactes sur `id` puis `name` ;
  /// - puis correspondances préfixe ;
  /// - puis correspondances partielles dans le même haystack local ;
  /// - ordre secondaire stable par nom puis id.
  ///
  /// Non-objectifs assumés :
  /// - pas de fuzzy matching ;
  /// - pas d'auto-correction ;
  /// - pas de résolution implicite d'alias non exposés par la donnée locale.
  List<PokemonMoveCatalogEntryView> search(
    List<PokemonMoveCatalogEntryView> entries,
    String rawQuery, {
    int limit = 8,
  }) {
    final normalizedQuery = rawQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return entries.take(limit).toList(growable: false);
    }

    final rankedEntries = entries
        .map(
          (entry) => (
            entry: entry,
            rank: _rankEntry(entry, normalizedQuery),
          ),
        )
        .where((candidate) => candidate.rank != null)
        .cast<({PokemonMoveCatalogEntryView entry, int rank})>()
        .toList(growable: false)
      ..sort((left, right) {
        final rankCompare = left.rank.compareTo(right.rank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        final nameCompare = left.entry.name.compareTo(right.entry.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.entry.id.compareTo(right.entry.id);
      });

    return rankedEntries
        .take(limit)
        .map((candidate) => candidate.entry)
        .toList(growable: false);
  }

  int? _rankEntry(
    PokemonMoveCatalogEntryView entry,
    String normalizedQuery,
  ) {
    final normalizedId = entry.id.toLowerCase();
    final normalizedName = entry.name.toLowerCase();
    final haystack = <String>[
      entry.id,
      entry.name,
      entry.type ?? '',
      entry.category ?? '',
      entry.shortDesc ?? '',
    ].join(' ').toLowerCase();

    if (normalizedId == normalizedQuery) {
      return 0;
    }
    if (normalizedName == normalizedQuery) {
      return 1;
    }
    if (normalizedId.startsWith(normalizedQuery)) {
      return 2;
    }
    if (normalizedName.startsWith(normalizedQuery)) {
      return 3;
    }
    if (haystack.contains(normalizedQuery)) {
      return 4;
    }
    return null;
  }
}

```

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:path/path.dart' as p;

import '../../../app/providers/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/pokedex_species_detail.dart';
import '../../../application/models/pokemon_database_index.dart';
import '../../../application/models/pokemon_external_batch_selection.dart';
import '../../../application/models/pokemon_external_species_search_result.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/services/pokemon_moves_catalog_lookup_service.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../pokedex_workspace_loader.dart';
import '../../shared/cupertino_editor_widgets.dart';

part 'pokedex_workspace_body.dart';
part 'pokedex_workspace_logic.dart';
part 'pokedex_empty_state.dart';
part 'pokedex_feedback_banner.dart';
part 'pokedex_list_panel.dart';
part 'pokedex_toolbar.dart';
part 'pokedex_filters_panel.dart';
part 'pokedex_list_row.dart';
part 'pokedex_import_flow.dart';
part 'pokedex_import_flow_steps.dart';
part 'pokedex_import_flow_support.dart';
part 'pokedex_external_batch_field.dart';
part 'pokedex_external_search_field.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_learnset_move_assist.dart';
part 'pokedex_moves_catalog_section.dart';
part 'pokedex_evolution_panel.dart';
part 'pokedex_media_panel.dart';
part 'pokedex_common_widgets.dart';
part 'pokedex_formatters.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';
const MethodChannel _macOsImportFileAccessChannel =
    MethodChannel('map_editor/file_access');

// Bibliothèque racine du workspace Pokédex.
//
// Toute la logique métier reste hors de l'UI :
// - les use cases et loaders sont injectés depuis les providers existants ;
// - cette couche orchestre uniquement l'affichage, la sélection locale et les
//   transitions utilisateur du workspace ;
// - le découpage en `part` garde les widgets privés déjà en place tout en
//   rendant l'écran maintenable et lisible pour l'équipe.
/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
    this.importPreviewer,
    this.importer,
    this.externalImportPreviewer,
    this.externalImporter,
    this.externalSpeciesSearcher,
    this.externalBatchSelectionResolver,
    this.externalBatchPreviewer,
    this.externalBatchImporter,
    this.pickJsonImportFile,
    this.deleteSpecies,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
    this.movesCatalogLoader,
    this.movesCatalogPreviewer,
    this.movesCatalogSyncer,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final PokedexExternalImportPreviewer? externalImportPreviewer;
  final PokedexExternalImporter? externalImporter;
  final PokedexExternalSpeciesSearcher? externalSpeciesSearcher;
  final PokedexExternalBatchSelectionResolver? externalBatchSelectionResolver;
  final PokedexExternalBatchPreviewer? externalBatchPreviewer;
  final PokedexExternalBatchImporter? externalBatchImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter? deleteSpecies;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;
  final PokedexMovesCatalogLoader? movesCatalogLoader;
  final PokedexMovesCatalogPreviewer? movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer? movesCatalogSyncer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexExternalImportPreviewer resolvedExternalImportPreviewer =
        externalImportPreviewer ??
            ref.watch(pokedexExternalImportPreviewerProvider);
    final PokedexExternalImporter resolvedExternalImporter =
        externalImporter ?? ref.watch(pokedexExternalImporterProvider);
    final PokedexExternalSpeciesSearcher resolvedExternalSpeciesSearcher =
        externalSpeciesSearcher ??
            ref.watch(pokedexExternalSpeciesSearcherProvider);
    final PokedexExternalBatchSelectionResolver
        resolvedExternalBatchSelectionResolver =
        externalBatchSelectionResolver ??
            ref.watch(pokedexExternalBatchSelectionResolverProvider);
    final PokedexExternalBatchPreviewer resolvedExternalBatchPreviewer =
        externalBatchPreviewer ??
            ref.watch(pokedexExternalBatchPreviewerProvider);
    final PokedexExternalBatchImporter resolvedExternalBatchImporter =
        externalBatchImporter ??
            ref.watch(pokedexExternalBatchImporterProvider);
    final PokedexSpeciesDeleter resolvedDeleteSpecies =
        deleteSpecies ?? ref.watch(pokedexSpeciesDeleterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);
    final PokedexMovesCatalogLoader resolvedMovesCatalogLoader =
        movesCatalogLoader ?? ref.watch(pokedexMovesCatalogLoaderProvider);
    final PokedexMovesCatalogPreviewer resolvedMovesCatalogPreviewer =
        movesCatalogPreviewer ??
            ref.watch(pokedexMovesCatalogPreviewerProvider);
    final PokedexMovesCatalogSyncer resolvedMovesCatalogSyncer =
        movesCatalogSyncer ?? ref.watch(pokedexMovesCatalogSyncerProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      externalImportPreviewer: resolvedExternalImportPreviewer,
      externalImporter: resolvedExternalImporter,
      externalSpeciesSearcher: resolvedExternalSpeciesSearcher,
      externalBatchSelectionResolver: resolvedExternalBatchSelectionResolver,
      externalBatchPreviewer: resolvedExternalBatchPreviewer,
      externalBatchImporter: resolvedExternalBatchImporter,
      pickJsonImportFile: pickJsonImportFile,
      deleteSpecies: resolvedDeleteSpecies,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
      movesCatalogLoader: resolvedMovesCatalogLoader,
      movesCatalogPreviewer: resolvedMovesCatalogPreviewer,
      movesCatalogSyncer: resolvedMovesCatalogSyncer,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.externalImportPreviewer,
    required this.externalImporter,
    required this.externalSpeciesSearcher,
    required this.externalBatchSelectionResolver,
    required this.externalBatchPreviewer,
    required this.externalBatchImporter,
    required this.pickJsonImportFile,
    required this.deleteSpecies,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
    required this.movesCatalogLoader,
    required this.movesCatalogPreviewer,
    required this.movesCatalogSyncer,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final PokedexExternalImportPreviewer externalImportPreviewer;
  final PokedexExternalImporter externalImporter;
  final PokedexExternalSpeciesSearcher externalSpeciesSearcher;
  final PokedexExternalBatchSelectionResolver externalBatchSelectionResolver;
  final PokedexExternalBatchPreviewer externalBatchPreviewer;
  final PokedexExternalBatchImporter externalBatchImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter deleteSpecies;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;
  final PokedexMovesCatalogLoader movesCatalogLoader;
  final PokedexMovesCatalogPreviewer movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer movesCatalogSyncer;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

```

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Onglet Learnset.
//
// Cette vue expose les sections déjà supportées par l'application sans modifier
// le contrat métier. L'objectif de ce réalignement est de rendre l'écran plus
// facile à relire et à maintenir, pas de changer la logique d'édition.

class _PokedexLearnsetTab extends StatefulWidget {
  const _PokedexLearnsetTab({
    required this.detail,
    required this.onSave,
    required this.loadMovesCatalog,
    required this.previewMovesCatalogSync,
    required this.syncMovesCatalog,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSave;
  final Future<PokemonMovesCatalogView> Function() loadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      previewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() syncMovesCatalog;

  @override
  State<_PokedexLearnsetTab> createState() => _PokedexLearnsetTabState();
}

class _PokedexLearnsetTabState extends State<_PokedexLearnsetTab> {
  late final TextEditingController _startingMovesController;
  late final TextEditingController _relearnMovesController;
  late final TextEditingController _levelUpController;
  late final TextEditingController _tmController;
  late final TextEditingController _tutorController;
  late final TextEditingController _eggController;
  late final TextEditingController _eventController;
  late final TextEditingController _transferController;
  late Future<PokemonMovesCatalogView> _movesCatalogFuture;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _startingMovesController = TextEditingController();
    _relearnMovesController = TextEditingController();
    _levelUpController = TextEditingController();
    _tmController = TextEditingController();
    _tutorController = TextEditingController();
    _eggController = TextEditingController();
    _eventController = TextEditingController();
    _transferController = TextEditingController();
    _movesCatalogFuture = widget.loadMovesCatalog();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexLearnsetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadMovesCatalog != widget.loadMovesCatalog) {
      _movesCatalogFuture = widget.loadMovesCatalog();
    }
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _startingMovesController.dispose();
    _relearnMovesController.dispose();
    _levelUpController.dispose();
    _tmController.dispose();
    _tutorController.dispose();
    _eggController.dispose();
    _eventController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final learnset = detail.learnset;
    _startingMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.startingMoves);
    _relearnMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.relearnMoves);
    _levelUpController.text =
        learnset == null ? '' : _formatLearnsetLevelUpEntries(learnset.levelUp);
    _tmController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tm);
    _tutorController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tutor);
    _eggController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.egg);
    _eventController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.event);
    _transferController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.transfer);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesLearnsetRequest(
          speciesId: widget.detail.species.id,
          startingMoves: _splitNonEmptyLines(_startingMovesController.text),
          relearnMoves: _splitNonEmptyLines(_relearnMovesController.text),
          levelUp: _parseLearnsetLevelUpEntries(_levelUpController.text),
          tm: _parseLearnsetMoveEntries(_tmController.text, label: 'tm'),
          tutor: _parseLearnsetMoveEntries(
            _tutorController.text,
            label: 'tutor',
          ),
          egg: _parseLearnsetMoveEntries(_eggController.text, label: 'egg'),
          event: _parseLearnsetMoveEntries(
            _eventController.text,
            label: 'event',
          ),
          transfer: _parseLearnsetMoveEntries(
            _transferController.text,
            label: 'transfer',
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  void _reloadMovesCatalog() {
    setState(() {
      _movesCatalogFuture = widget.loadMovesCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnset = widget.detail.learnset;
    final learnsetRef = widget.detail.species.refs.learnset.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexMovesCatalogSection(
            loadCatalog: widget.loadMovesCatalog,
            previewSync: widget.previewMovesCatalogSync,
            syncCatalog: widget.syncMovesCatalog,
            onCatalogChanged: _reloadMovesCatalog,
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            _PokedexLearnsetEditSection(
              learnsetRef: learnsetRef,
              movesCatalogFuture: _movesCatalogFuture,
              isSaving: _isSaving,
              saveErrorMessage: _saveErrorMessage,
              startingMovesController: _startingMovesController,
              relearnMovesController: _relearnMovesController,
              levelUpController: _levelUpController,
              tmController: _tmController,
              tutorController: _tutorController,
              eggController: _eggController,
              eventController: _eventController,
              transferController: _transferController,
              onSave: _saveDraft,
              onCancel: _cancelEditing,
            ),
          ] else ...[
            _PokedexLearnsetReadOnlySection(
              learnset: learnset,
              learnsetRef: learnsetRef,
              onEditRequested: learnsetRef.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _replaceDraftFromDetail(widget.detail);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
            ),
          ],
        ],
      ),
    );
  }
}

```

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Sous-sections de l'onglet Learnset.
//
// On extrait le rendu lecture/édition pour garder l'onglet principal léger.
// Cela permet de conserver le même comportement applicatif tout en rendant le
// code UI plus facile à relire, à tester et à faire évoluer.

class _PokedexLearnsetEditSection extends StatelessWidget {
  const _PokedexLearnsetEditSection({
    required this.learnsetRef,
    required this.movesCatalogFuture,
    required this.isSaving,
    required this.saveErrorMessage,
    required this.startingMovesController,
    required this.relearnMovesController,
    required this.levelUpController,
    required this.tmController,
    required this.tutorController,
    required this.eggController,
    required this.eventController,
    required this.transferController,
    required this.onSave,
    required this.onCancel,
  });

  final String learnsetRef;
  final Future<PokemonMovesCatalogView> movesCatalogFuture;
  final bool isSaving;
  final String? saveErrorMessage;
  final TextEditingController startingMovesController;
  final TextEditingController relearnMovesController;
  final TextEditingController levelUpController;
  final TextEditingController tmController;
  final TextEditingController tutorController;
  final TextEditingController eggController;
  final TextEditingController eventController;
  final TextEditingController transferController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: 'Édition learnset locale',
      child: FutureBuilder<PokemonMovesCatalogView>(
        future: movesCatalogFuture,
        builder: (context, snapshot) {
          final catalogView = snapshot.data;
          final isCatalogLoading =
              snapshot.connectionState != ConnectionState.done;
          final catalogLoadError = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            final Object error => error.toString(),
            null => null,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PokedexPropertyLine(
                label: 'Ref learnset',
                value: learnsetRef.isEmpty ? 'Ref absente' : learnsetRef,
              ),
              const SizedBox(height: 10),
              _PokedexLearnsetMovesAssistBanner(
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
                catalogLoadError: catalogLoadError,
              ),
              const SizedBox(height: 10),
              _PokedexSimpleMoveAssistEditor(
                title: 'Moves de départ',
                description:
                    'Un move id par ligne. Les doublons exacts sont ignorés à la sauvegarde.',
                fieldKey: const Key('pokedex-learnset-starting-field'),
                controller: startingMovesController,
                enabled: !isSaving,
                placeholder: 'tackle\ngrowl',
                sectionKeyPrefix: 'pokedex-learnset-starting',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexSimpleMoveAssistEditor(
                title: 'Moves à réapprendre',
                description: 'Un move id par ligne.',
                fieldKey: const Key('pokedex-learnset-relearn-field'),
                controller: relearnMovesController,
                enabled: !isSaving,
                placeholder: 'vine_whip',
                sectionKeyPrefix: 'pokedex-learnset-relearn',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexLevelUpAssistEditor(
                title: 'Level-up',
                description:
                    'Une entrée par ligne au format moveId|level|source|versionGroup.',
                fieldKey: const Key('pokedex-learnset-level-up-field'),
                controller: levelUpController,
                enabled: !isSaving,
                placeholder: 'vine_whip|7|level_up|scarlet-violet',
                sectionKeyPrefix: 'pokedex-learnset-level-up',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexMoveEntryAssistEditor(
                title: 'TM',
                description:
                    'Une entrée par ligne au format moveId|versionGroup.',
                fieldKey: const Key('pokedex-learnset-tm-field'),
                controller: tmController,
                enabled: !isSaving,
                placeholder: 'protect|scarlet-violet',
                sectionKeyPrefix: 'pokedex-learnset-tm',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexMoveEntryAssistEditor(
                title: 'Tutor',
                description:
                    'Une entrée par ligne au format moveId|versionGroup.',
                fieldKey: const Key('pokedex-learnset-tutor-field'),
                controller: tutorController,
                enabled: !isSaving,
                placeholder: 'seed_bomb|scarlet-violet',
                sectionKeyPrefix: 'pokedex-learnset-tutor',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexMoveEntryAssistEditor(
                title: 'Egg',
                description:
                    'Une entrée par ligne au format moveId|versionGroup.',
                fieldKey: const Key('pokedex-learnset-egg-field'),
                controller: eggController,
                enabled: !isSaving,
                placeholder: 'petal_dance|scarlet-violet',
                sectionKeyPrefix: 'pokedex-learnset-egg',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexMoveEntryAssistEditor(
                title: 'Event',
                description:
                    'Une entrée par ligne au format moveId|versionGroup.',
                fieldKey: const Key('pokedex-learnset-event-field'),
                controller: eventController,
                enabled: !isSaving,
                placeholder: 'celebrate|scarlet-violet',
                sectionKeyPrefix: 'pokedex-learnset-event',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 10),
              _PokedexMoveEntryAssistEditor(
                title: 'Transfer',
                description:
                    'Une entrée par ligne au format moveId|versionGroup.',
                fieldKey: const Key('pokedex-learnset-transfer-field'),
                controller: transferController,
                enabled: !isSaving,
                placeholder: 'toxic|scarlet-violet',
                sectionKeyPrefix: 'pokedex-learnset-transfer',
                catalogView: catalogView,
                isCatalogLoading: isCatalogLoading,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CupertinoButton.filled(
                    key: const Key('pokedex-save-learnset-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    onPressed: isSaving ? null : onSave,
                    child: Text(isSaving ? 'Enregistrement…' : 'Enregistrer'),
                  ),
                  const SizedBox(width: 10),
                  CupertinoButton(
                    key: const Key('pokedex-cancel-learnset-button'),
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Annuler'),
                  ),
                ],
              ),
              if (saveErrorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  saveErrorMessage!,
                  key: const Key('pokedex-learnset-save-error'),
                  style: const TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PokedexLearnsetReadOnlySection extends StatelessWidget {
  const _PokedexLearnsetReadOnlySection({
    required this.learnset,
    required this.learnsetRef,
    required this.onEditRequested,
  });

  final PokemonLearnsetFile? learnset;
  final String learnsetRef;
  final VoidCallback? onEditRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (learnset == null)
          _PokedexMissingSection(
            key: const Key('pokedex-learnset-missing'),
            title: 'Learnset',
            message: learnsetRef.isEmpty
                ? 'La ref learnset est vide dans l’espèce locale ; aucun learnset ne peut être édité depuis cette fiche.'
                : 'Aucun learnset local trouvé pour cette espèce. Vous pouvez en créer un depuis cet onglet.',
          )
        else ...[
          _PokedexDetailSectionCard(
            title: 'Moves de départ',
            child: Text(
              learnset!.startingMoves.isEmpty
                  ? 'Aucun move de départ déclaré.'
                  : learnset!.startingMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Moves à réapprendre',
            child: Text(
              learnset!.relearnMoves.isEmpty
                  ? 'Aucun move à réapprendre déclaré.'
                  : learnset!.relearnMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Level-up',
            child: learnset!.levelUp.isEmpty
                ? const Text('Aucune entrée level-up.')
                : Column(
                    children: learnset!.levelUp
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: '${entry.moveId} • niveau ${entry.level}',
                            value:
                                '${entry.versionGroup} • source ${entry.source}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'TM', entries: learnset!.tm),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Tutor', entries: learnset!.tutor),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Egg', entries: learnset!.egg),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Event', entries: learnset!.event),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Transfer', entries: learnset!.transfer),
        ],
        const SizedBox(height: 12),
        _PokedexDetailSectionCard(
          title: 'Édition locale',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                learnsetRef.isEmpty
                    ? 'Impossible d’éditer ce learnset tant que la ref locale est vide.'
                    : 'Le learnset édité réécrit uniquement le JSON local déjà relié par les refs de l’espèce.',
              ),
              if (onEditRequested != null) ...[
                const SizedBox(height: 14),
                CupertinoButton(
                  key: const Key('pokedex-edit-learnset-button'),
                  padding: EdgeInsets.zero,
                  onPressed: onEditRequested,
                  child:
                      Text(learnset == null ? 'Créer localement' : 'Modifier'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

```

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Bloc minimal "catalogue local des attaques" pour l'onglet Learnset.
//
// Décision UI de la 11B :
// - on n'ouvre pas un nouveau workspace "Move Library" autonome ;
// - on ajoute la plus petite surface honnête là où le besoin produit existe
//   déjà : l'édition et la lecture du learnset ;
// - le bloc reste purement consommateur d'état applicatif injecté.
//
// Ce composant permet donc :
// - de voir si le catalogue local existe et combien d'entrées il contient ;
// - de prévisualiser un sync externe avant écriture ;
// - de lancer réellement le sync ;
// - de rechercher rapidement des ids/noms/types déjà importés.
class _PokedexMovesCatalogSection extends StatefulWidget {
  const _PokedexMovesCatalogSection({
    required this.loadCatalog,
    required this.previewSync,
    required this.syncCatalog,
    this.onCatalogChanged,
  });

  final Future<PokemonMovesCatalogView> Function() loadCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function() previewSync;
  final Future<PokemonMovesCatalogSyncResult> Function() syncCatalog;
  final VoidCallback? onCatalogChanged;

  @override
  State<_PokedexMovesCatalogSection> createState() =>
      _PokedexMovesCatalogSectionState();
}

class _PokedexMovesCatalogSectionState
    extends State<_PokedexMovesCatalogSection> {
  static const PokemonMovesCatalogLookupService _catalogLookupService =
      PokemonMovesCatalogLookupService();
  late final TextEditingController _searchController;
  late Future<PokemonMovesCatalogView> _catalogFuture;
  PokemonMovesCatalogSyncResult? _lastSyncReport;
  String? _operationError;
  bool _isPreviewing = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
    _catalogFuture = widget.loadCatalog();
  }

  @override
  void didUpdateWidget(covariant _PokedexMovesCatalogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadCatalog != widget.loadCatalog ||
        oldWidget.previewSync != widget.previewSync ||
        oldWidget.syncCatalog != widget.syncCatalog) {
      _catalogFuture = widget.loadCatalog();
      _lastSyncReport = null;
      _operationError = null;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _runPreview() async {
    if (_isPreviewing || _isSyncing) {
      return;
    }

    setState(() {
      _isPreviewing = true;
      _operationError = null;
    });

    try {
      final report = await widget.previewSync();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSyncReport = report;
        _isPreviewing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreviewing = false;
        _operationError = _formatOperationError(error);
      });
    }
  }

  Future<void> _runSync() async {
    if (_isPreviewing || _isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
      _operationError = null;
    });

    try {
      final report = await widget.syncCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSyncReport = report;
        _catalogFuture = widget.loadCatalog();
        _isSyncing = false;
      });
      widget.onCatalogChanged?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncing = false;
        _operationError = _formatOperationError(error);
      });
    }
  }

  String _formatOperationError(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: 'Catalogue local des attaques',
      key: const Key('pokedex-moves-catalog-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cette surface 11B reste volontairement minimale : elle synchronise '
            'le catalogue local des moves, le rend consultable, puis laisse '
            'le learnset consommer cette source de vérité locale.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CupertinoButton.filled(
                key: const Key('pokedex-moves-catalog-preview-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: (_isPreviewing || _isSyncing) ? null : _runPreview,
                child: Text(
                  _isPreviewing ? 'Prévisualisation…' : 'Prévisualiser sync',
                ),
              ),
              CupertinoButton(
                key: const Key('pokedex-moves-catalog-sync-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: (_isPreviewing || _isSyncing) ? null : _runSync,
                child: Text(_isSyncing ? 'Synchronisation…' : 'Synchroniser'),
              ),
            ],
          ),
          if (_lastSyncReport != null) ...[
            const SizedBox(height: 12),
            _PokedexMoveCatalogSyncSummary(report: _lastSyncReport!),
          ],
          if (_operationError != null) ...[
            const SizedBox(height: 12),
            Text(
              _operationError!,
              key: const Key('pokedex-moves-catalog-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FutureBuilder<PokemonMovesCatalogView>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text(
                    'Chargement du catalogue local des attaques…');
              }

              if (snapshot.hasError) {
                final message = _formatOperationError(
                  snapshot.error ?? 'Erreur inconnue',
                );
                return Text(
                  message,
                  key: const Key('pokedex-moves-catalog-load-error'),
                  style: const TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }

              final view = snapshot.data ??
                  const PokemonMovesCatalogView(
                    entries: <PokemonMoveCatalogEntryView>[],
                    isAvailable: false,
                    description: 'Catalogue local indisponible.',
                  );
              final filteredEntries = _filterEntries(view.entries);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.description,
                    key: const Key('pokedex-moves-catalog-description'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    view.isAvailable
                        ? 'Attaques locales : ${view.entries.length}'
                        : 'Catalogue indisponible',
                    key: const Key('pokedex-moves-catalog-count'),
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (view.message != null) ...[
                    const SizedBox(height: 6),
                    Text(view.message!),
                  ],
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    key: const Key('pokedex-moves-catalog-search-field'),
                    controller: _searchController,
                    placeholder: 'Rechercher une attaque locale',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (view.entries.isEmpty)
                    const Text(
                      'Aucune attaque locale importée pour le moment. '
                      'Utilisez la synchronisation externe pour alimenter le catalogue.',
                    )
                  else if (filteredEntries.isEmpty)
                    const Text(
                      'Aucune attaque ne correspond à la recherche actuelle.',
                    )
                  else
                    Container(
                      key: const Key('pokedex-moves-catalog-list'),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _PokedexMoveCatalogRow(entry: entry);
                        },
                      ),
                    ),
                  if (view.entries.length > filteredEntries.length &&
                      filteredEntries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Affichage limité à ${filteredEntries.length} résultats pour garder l’onglet lisible.',
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<PokemonMoveCatalogEntryView> _filterEntries(
    List<PokemonMoveCatalogEntryView> entries,
  ) {
    return _catalogLookupService.search(
      entries,
      _searchController.text,
      limit: 12,
    );
  }
}

class _PokedexMoveCatalogSyncSummary extends StatelessWidget {
  const _PokedexMoveCatalogSyncSummary({
    required this.report,
  });

  final PokemonMovesCatalogSyncResult report;

  @override
  Widget build(BuildContext context) {
    final label =
        report.dryRun ? 'Prévisualisation' : 'Dernière synchronisation';
    final lines = <String>[
      '$label : ${report.externalEntryCount} moves externes analysés.',
      'Créées : ${report.createdCount}.',
      'Mises à jour : ${report.updatedCount}.',
      'Inchangées : ${report.unchangedCount}.',
      'Locales conservées : ${report.preservedLocalOnlyCount}.',
      'Catalogue résultant : ${report.resultingEntryCount}.',
      if (report.createdIds.isNotEmpty)
        'Exemples créés : ${report.createdIds.take(5).join(', ')}.',
      if (report.updatedIds.isNotEmpty)
        'Exemples mis à jour : ${report.updatedIds.take(5).join(', ')}.',
      ...report.warnings,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          lines.join('\n'),
          key: const Key('pokedex-moves-catalog-preview-summary'),
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _PokedexMoveCatalogRow extends StatelessWidget {
  const _PokedexMoveCatalogRow({
    required this.entry,
  });

  final PokemonMoveCatalogEntryView entry;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.name} • ${entry.id}',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (entry.type != null) entry.type!,
                if (entry.category != null) entry.category!,
                if (entry.pp != null) 'PP ${entry.pp}',
                if (entry.power != null) 'Puissance ${entry.power}',
                'Précision ${entry.accuracyLabel}',
              ].join(' • '),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entry.shortDesc != null && entry.shortDesc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.shortDesc!,
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

```

## `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart`

```dart
part of 'pokedex_workspace_page.dart';

const PokemonMovesCatalogLookupService _movesCatalogLookupService =
    PokemonMovesCatalogLookupService();

// Assistance "moves-first" du lot 5.
//
// Choix assumé :
// - on garde les textareas existantes comme source de vérité du learnset ;
// - on ajoute une aide locale pour chercher un move du catalogue et générer des
//   lignes valides plus facilement ;
// - on n'introduit donc ni second éditeur learnset, ni pipeline parallèle.

class _PokedexLearnsetMovesAssistBanner extends StatelessWidget {
  const _PokedexLearnsetMovesAssistBanner({
    required this.catalogView,
    required this.isCatalogLoading,
    required this.catalogLoadError,
  });

  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;
  final String? catalogLoadError;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final accent = catalogLoadError != null ||
            (catalogView != null && !catalogView!.isAvailable)
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.accentJade;

    final message = switch ((isCatalogLoading, catalogView?.isAvailable)) {
      (true, _) =>
        'Chargement du catalogue local des attaques… La saisie brute reste possible pendant ce chargement.',
      (_, true) =>
        'Recherche locale active sur ${catalogView!.entries.length} moves. Les ids inconnus restent visibles et sont signalés comme absents du catalogue.',
      _ when catalogLoadError != null =>
        'Impossible de lire le catalogue local des attaques. Vous pouvez encore éditer les ids bruts, mais sans assistance locale.\n$catalogLoadError',
      _ when catalogView?.message != null =>
        'Catalogue local indisponible. Vous pouvez encore éditer les ids bruts, mais sans assistance locale.\n${catalogView!.message}',
      _ =>
        'Catalogue local indisponible. Vous pouvez encore éditer les ids bruts, mais sans assistance locale.',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: 'Assistance moves-first',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '\n'),
              TextSpan(text: message),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexMoveCatalogPicker extends StatefulWidget {
  const _PokedexMoveCatalogPicker({
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
    required this.enabled,
    required this.onMoveSelected,
    this.searchPlaceholder = 'Chercher un move local',
  });

  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;
  final bool enabled;
  final ValueChanged<PokemonMoveCatalogEntryView> onMoveSelected;
  final String searchPlaceholder;

  @override
  State<_PokedexMoveCatalogPicker> createState() =>
      _PokedexMoveCatalogPickerState();
}

class _PokedexMoveCatalogPickerState extends State<_PokedexMoveCatalogPicker> {
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
    setState(() {});
  }

  void _selectMove(PokemonMoveCatalogEntryView entry) {
    widget.onMoveSelected(entry);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final view = widget.catalogView;
    final canSearch = widget.enabled &&
        !widget.isCatalogLoading &&
        view != null &&
        view.isAvailable &&
        view.entries.isNotEmpty;
    final suggestions = canSearch
        ? _movesCatalogLookupService.search(
            view.entries,
            _searchController.text,
            limit: 8,
          )
        : const <PokemonMoveCatalogEntryView>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          key: Key('${widget.sectionKeyPrefix}-search-field'),
          controller: _searchController,
          enabled: canSearch,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          placeholder: widget.isCatalogLoading
              ? 'Chargement du catalogue local…'
              : widget.searchPlaceholder,
          onSubmitted: (_) {
            if (suggestions.isNotEmpty) {
              _selectMove(suggestions.first);
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          canSearch
              ? 'Recherche locale par id ou nom. Entrée sur le premier résultat, clic pour sélectionner.'
              : 'La recherche assistée reste indisponible tant que le catalogue local ne peut pas être lu.',
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
              key: Key('${widget.sectionKeyPrefix}-search-unavailable'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestions.isEmpty)
            Text(
              'Aucun move local ne correspond à cette recherche.',
              key: Key('${widget.sectionKeyPrefix}-search-empty'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              key: Key('${widget.sectionKeyPrefix}-suggestions'),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = suggestions[index];
                  return _PokedexMoveSuggestionTile(
                    key: Key(
                        '${widget.sectionKeyPrefix}-suggestion-${entry.id}'),
                    entry: entry,
                    onTap: widget.enabled ? () => _selectMove(entry) : null,
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _PokedexMoveSuggestionTile extends StatelessWidget {
  const _PokedexMoveSuggestionTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final PokemonMoveCatalogEntryView entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onPressed: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.name} • ${entry.id}',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (entry.type != null) entry.type!,
                      if (entry.category != null) entry.category!,
                      if (entry.pp != null) 'PP ${entry.pp}',
                    ].join(' • '),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sélectionner',
              style: TextStyle(
                color: label,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexSimpleMoveAssistEditor extends StatelessWidget {
  const _PokedexSimpleMoveAssistEditor({
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 10),
          _PokedexMoveCatalogPicker(
            sectionKeyPrefix: sectionKeyPrefix,
            catalogView: catalogView,
            isCatalogLoading: isCatalogLoading,
            enabled: enabled,
            onMoveSelected: (entry) {
              _appendLearnsetLine(
                controller,
                entry.id,
                deduplicateExact: true,
              );
            },
            searchPlaceholder: 'Chercher un move pour cette section',
          ),
          const SizedBox(height: 10),
          _PokedexSimpleMovePreview(
            key: Key('$sectionKeyPrefix-preview'),
            controller: controller,
            catalogView: catalogView,
            emptyLabel: 'Aucun move saisi pour cette section.',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Saisie brute',
            description:
                'Les ids legacy restent visibles. L’assistance ajoute simplement des move ids existants sans masquer le texte brut.',
            fieldKey: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: 2,
            maxLines: 5,
            placeholder: placeholder,
          ),
        ],
      ),
    );
  }
}

class _PokedexMoveEntryAssistEditor extends StatefulWidget {
  const _PokedexMoveEntryAssistEditor({
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;

  @override
  State<_PokedexMoveEntryAssistEditor> createState() =>
      _PokedexMoveEntryAssistEditorState();
}

class _PokedexMoveEntryAssistEditorState
    extends State<_PokedexMoveEntryAssistEditor> {
  late final TextEditingController _versionGroupController;
  PokemonMoveCatalogEntryView? _selectedMove;

  @override
  void initState() {
    super.initState();
    _versionGroupController = TextEditingController()
      ..addListener(_onComposerFieldChanged);
  }

  @override
  void dispose() {
    _versionGroupController
      ..removeListener(_onComposerFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onComposerFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _canAdd {
    return widget.enabled &&
        _selectedMove != null &&
        _versionGroupController.text.trim().isNotEmpty;
  }

  void _addSelectedMove() {
    final selectedMove = _selectedMove;
    if (selectedMove == null) {
      return;
    }

    final versionGroup = _versionGroupController.text.trim();
    if (versionGroup.isEmpty) {
      return;
    }

    _appendLearnsetLine(
      widget.controller,
      '${selectedMove.id}|$versionGroup',
    );

    setState(() {
      _selectedMove = null;
      _versionGroupController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 10),
          _PokedexMoveCatalogPicker(
            sectionKeyPrefix: widget.sectionKeyPrefix,
            catalogView: widget.catalogView,
            isCatalogLoading: widget.isCatalogLoading,
            enabled: widget.enabled,
            onMoveSelected: (entry) {
              setState(() {
                _selectedMove = entry;
              });
            },
            searchPlaceholder: 'Chercher un move à insérer',
          ),
          const SizedBox(height: 10),
          _PokedexSelectedMoveComposer(
            title: 'Ajout assisté',
            selectedMove: _selectedMove,
            enabled: widget.enabled,
            children: [
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Version group',
                  fieldKey: Key('${widget.sectionKeyPrefix}-version-group'),
                  controller: _versionGroupController,
                  enabled: widget.enabled,
                  placeholder: 'scarlet-violet',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton.filled(
                key: Key('${widget.sectionKeyPrefix}-add-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: _canAdd ? _addSelectedMove : null,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PokedexStructuredMovePreview(
            key: Key('${widget.sectionKeyPrefix}-preview'),
            controller: widget.controller,
            catalogView: widget.catalogView,
            emptyLabel: 'Aucune entrée déclarée pour cette section.',
            parser: (raw) => _parseLearnsetMoveEntries(raw,
                label: widget.title.toLowerCase()),
            lineBuilder: (entry, resolvedMove) => _ResolvedLearnsetMoveLine(
              moveId: entry.moveId,
              catalogAvailable: widget.catalogView?.isAvailable == true,
              resolvedMove: resolvedMove,
              subtitle: entry.versionGroup,
            ),
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Saisie brute',
            description:
                'Le texte reste la source de vérité. L’ajout assisté prépare simplement des lignes valides.',
            fieldKey: widget.fieldKey,
            controller: widget.controller,
            enabled: widget.enabled,
            minLines: 2,
            maxLines: 6,
            placeholder: widget.placeholder,
          ),
        ],
      ),
    );
  }
}

class _PokedexLevelUpAssistEditor extends StatefulWidget {
  const _PokedexLevelUpAssistEditor({
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;

  @override
  State<_PokedexLevelUpAssistEditor> createState() =>
      _PokedexLevelUpAssistEditorState();
}

class _PokedexLevelUpAssistEditorState
    extends State<_PokedexLevelUpAssistEditor> {
  late final TextEditingController _levelController;
  late final TextEditingController _sourceController;
  late final TextEditingController _versionGroupController;
  PokemonMoveCatalogEntryView? _selectedMove;

  @override
  void initState() {
    super.initState();
    _levelController = TextEditingController()..addListener(_onFieldChanged);
    _sourceController = TextEditingController(text: 'level_up')
      ..addListener(_onFieldChanged);
    _versionGroupController = TextEditingController()
      ..addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _levelController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _sourceController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _versionGroupController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasValidLevel {
    final level = int.tryParse(_levelController.text.trim());
    return level != null && level >= 1;
  }

  bool get _canAdd {
    return widget.enabled &&
        _selectedMove != null &&
        _hasValidLevel &&
        _sourceController.text.trim().isNotEmpty &&
        _versionGroupController.text.trim().isNotEmpty;
  }

  void _addSelectedMove() {
    final selectedMove = _selectedMove;
    final level = int.tryParse(_levelController.text.trim());
    final source = _sourceController.text.trim();
    final versionGroup = _versionGroupController.text.trim();
    if (selectedMove == null ||
        level == null ||
        level < 1 ||
        source.isEmpty ||
        versionGroup.isEmpty) {
      return;
    }

    _appendLearnsetLine(
      widget.controller,
      '${selectedMove.id}|$level|$source|$versionGroup',
    );

    setState(() {
      _selectedMove = null;
      _levelController.clear();
      _versionGroupController.clear();
      _sourceController.text = 'level_up';
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return _PokedexDetailSectionCard(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 10),
          _PokedexMoveCatalogPicker(
            sectionKeyPrefix: widget.sectionKeyPrefix,
            catalogView: widget.catalogView,
            isCatalogLoading: widget.isCatalogLoading,
            enabled: widget.enabled,
            onMoveSelected: (entry) {
              setState(() {
                _selectedMove = entry;
              });
            },
            searchPlaceholder: 'Chercher un move level-up',
          ),
          const SizedBox(height: 10),
          _PokedexSelectedMoveComposer(
            title: 'Ajout assisté',
            selectedMove: _selectedMove,
            enabled: widget.enabled,
            children: [
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Niveau',
                  fieldKey: Key('${widget.sectionKeyPrefix}-level'),
                  controller: _levelController,
                  enabled: widget.enabled,
                  placeholder: '7',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Source',
                  fieldKey: Key('${widget.sectionKeyPrefix}-source'),
                  controller: _sourceController,
                  enabled: widget.enabled,
                  placeholder: 'level_up',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Version group',
                  fieldKey: Key('${widget.sectionKeyPrefix}-version-group'),
                  controller: _versionGroupController,
                  enabled: widget.enabled,
                  placeholder: 'scarlet-violet',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton.filled(
                key: Key('${widget.sectionKeyPrefix}-add-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: _canAdd ? _addSelectedMove : null,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (_levelController.text.trim().isNotEmpty && !_hasValidLevel) ...[
            const SizedBox(height: 6),
            Text(
              'Le niveau doit être un entier supérieur ou égal à 1.',
              key: Key('${widget.sectionKeyPrefix}-level-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Le picker ajoute une ligne complète, mais la saisie brute reste disponible pour les cas plus atypiques.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _PokedexStructuredMovePreview(
            key: Key('${widget.sectionKeyPrefix}-preview'),
            controller: widget.controller,
            catalogView: widget.catalogView,
            emptyLabel: 'Aucune entrée level-up déclarée.',
            parser: _parseLearnsetLevelUpEntries,
            lineBuilder: (entry, resolvedMove) => _ResolvedLearnsetMoveLine(
              moveId: entry.moveId,
              catalogAvailable: widget.catalogView?.isAvailable == true,
              resolvedMove: resolvedMove,
              subtitle:
                  'Niveau ${entry.level} • ${entry.source} • ${entry.versionGroup}',
            ),
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Saisie brute',
            description:
                'Le texte reste la source de vérité. L’ajout assisté génère une ligne valide sans masquer les ids legacy déjà présents.',
            fieldKey: widget.fieldKey,
            controller: widget.controller,
            enabled: widget.enabled,
            minLines: 3,
            maxLines: 8,
            placeholder: widget.placeholder,
          ),
        ],
      ),
    );
  }
}

class _PokedexSelectedMoveComposer extends StatelessWidget {
  const _PokedexSelectedMoveComposer({
    required this.title,
    required this.selectedMove,
    required this.enabled,
    required this.children,
  });

  final String title;
  final PokemonMoveCatalogEntryView? selectedMove;
  final bool enabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedMove == null
                  ? 'Sélectionnez d’abord un move du catalogue local pour préparer une nouvelle ligne.'
                  : 'Move sélectionné : ${selectedMove!.name} • ${selectedMove!.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            IgnorePointer(
              ignoring: !enabled,
              child: Row(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexCompactEditorField extends StatelessWidget {
  const _PokedexCompactEditorField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.placeholder,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          placeholder: placeholder,
          placeholderStyle: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PokedexSimpleMovePreview extends StatelessWidget {
  const _PokedexSimpleMovePreview({
    super.key,
    required this.controller,
    required this.catalogView,
    required this.emptyLabel,
  });

  final TextEditingController controller;
  final PokemonMovesCatalogView? catalogView;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final moveIds = _splitNonEmptyLines(value.text);
        if (moveIds.isEmpty) {
          return Text(emptyLabel);
        }

        return _PokedexResolvedMoveList(
          rows: moveIds
              .map(
                (moveId) => _ResolvedLearnsetMoveLine(
                  moveId: moveId,
                  catalogAvailable: catalogView?.isAvailable == true,
                  resolvedMove: _resolveMove(catalogView, moveId),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PokedexStructuredMovePreview<T> extends StatelessWidget {
  const _PokedexStructuredMovePreview({
    super.key,
    required this.controller,
    required this.catalogView,
    required this.emptyLabel,
    required this.parser,
    required this.lineBuilder,
  });

  final TextEditingController controller;
  final PokemonMovesCatalogView? catalogView;
  final String emptyLabel;
  final List<T> Function(String raw) parser;
  final _ResolvedLearnsetMoveLine Function(
    T entry,
    PokemonMoveCatalogEntryView? resolvedMove,
  ) lineBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final rawText = value.text.trimRight();
        if (rawText.trim().isEmpty) {
          return Text(emptyLabel);
        }

        try {
          final entries = parser(rawText);
          if (entries.isEmpty) {
            return Text(emptyLabel);
          }

          return _PokedexResolvedMoveList(
            rows: entries
                .map(
                  (entry) => lineBuilder(
                    entry,
                    _resolveMove(
                      catalogView,
                      _extractLearnsetMoveId(entry as Object),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        } on EditorApplicationException catch (error) {
          return Text(
            error.message,
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          );
        }
      },
    );
  }
}

class _PokedexResolvedMoveList extends StatelessWidget {
  const _PokedexResolvedMoveList({
    required this.rows,
  });

  final List<_ResolvedLearnsetMoveLine> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: row,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ResolvedLearnsetMoveLine extends StatelessWidget {
  const _ResolvedLearnsetMoveLine({
    required this.moveId,
    required this.catalogAvailable,
    this.resolvedMove,
    this.subtitle,
  });

  final String moveId;
  final bool catalogAvailable;
  final PokemonMoveCatalogEntryView? resolvedMove;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final isUnknown = catalogAvailable && resolvedMove == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedMove == null
                    ? moveId
                    : '${resolvedMove!.name} • ${resolvedMove!.id}',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
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
        const SizedBox(width: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: !catalogAvailable
                ? EditorChrome.accentWarm.withValues(alpha: 0.12)
                : isUnknown
                    ? EditorChrome.inspectorJoyCoral.withValues(alpha: 0.12)
                    : EditorChrome.accentJade.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (!catalogAvailable
                      ? EditorChrome.accentWarm
                      : isUnknown
                          ? EditorChrome.inspectorJoyCoral
                          : EditorChrome.accentJade)
                  .withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              !catalogAvailable
                  ? 'Résolution indisponible'
                  : isUnknown
                      ? 'Absent du catalogue local'
                      : 'Résolu localement',
              style: TextStyle(
                color: !catalogAvailable
                    ? EditorChrome.accentWarm
                    : isUnknown
                        ? EditorChrome.inspectorJoyCoral
                        : EditorChrome.accentJade,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

PokemonMoveCatalogEntryView? _resolveMove(
  PokemonMovesCatalogView? catalogView,
  String moveId,
) {
  if (catalogView == null || !catalogView.isAvailable) {
    return null;
  }
  return _movesCatalogLookupService.findById(catalogView.entries, moveId);
}

String _extractLearnsetMoveId(Object entry) {
  return switch (entry) {
    final PokemonLearnsetLevelUpEntry levelUpEntry => levelUpEntry.moveId,
    final PokemonLearnsetMoveEntry moveEntry => moveEntry.moveId,
    _ => throw StateError('Unsupported learnset preview entry type: $entry'),
  };
}

void _appendLearnsetLine(
  TextEditingController controller,
  String line, {
  bool deduplicateExact = false,
}) {
  final trimmedLine = line.trim();
  if (trimmedLine.isEmpty) {
    return;
  }

  final currentLines = LineSplitter.split(controller.text)
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: true);

  if (deduplicateExact && currentLines.contains(trimmedLine)) {
    return;
  }

  currentLines.add(trimmedLine);
  final nextText = currentLines.join('\n');
  controller.value = TextEditingValue(
    text: nextText,
    selection: TextSelection.collapsed(offset: nextText.length),
  );
}

```

## `packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

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
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
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
              child: SizedBox(width: 1280, height: 900, child: child),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('adds a starting move through explicit local catalog selection',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final store = _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        'bulbasaur': _buildDetail(
          id: 'bulbasaur',
          learnset: const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            startingMoves: <String>['tackle'],
          ),
        ),
      },
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        learnsetSaver: store.saveLearnset,
        metadataSaver: store.saveMetadata,
        formsClassificationSaver: store.saveFormsClassification,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
        movesCatalogLoader: (_) async => _movesCatalogView(),
        movesCatalogPreviewer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: true,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
        movesCatalogSyncer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: false,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-starting-search-field')),
      'vine',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pokedex-learnset-starting-suggestion-vine_whip')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('pokedex-learnset-starting-suggestion-vine_whip')),
    );
    await tester.pumpAndSettle();

    final startingField = tester.widget<CupertinoTextField>(
      find.byKey(const Key('pokedex-learnset-starting-field')),
    );
    expect(startingField.controller!.text, 'tackle\nvine_whip');
    expect(find.text('Vine Whip • vine_whip'), findsWidgets);
  });

  testWidgets(
      'adds a structured TM entry through assisted move selection and save',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final store = _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        'bulbasaur': _buildDetail(
          id: 'bulbasaur',
          learnset: const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            startingMoves: <String>['tackle'],
          ),
        ),
      },
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        learnsetSaver: store.saveLearnset,
        metadataSaver: store.saveMetadata,
        formsClassificationSaver: store.saveFormsClassification,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
        movesCatalogLoader: (_) async => _movesCatalogView(),
        movesCatalogPreviewer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: true,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
        movesCatalogSyncer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: false,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-search-field')),
      'protect',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-learnset-tm-suggestion-protect')),
    );
    await tester.tap(
      find.byKey(const Key('pokedex-learnset-tm-suggestion-protect')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-version-group')),
      'scarlet-violet',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-learnset-tm-add-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-learnset-button')));
    await tester.pumpAndSettle();

    expect(store.learnsetSaveCallCount, 1);
    expect(store.learnsetById('bulbasaur')?.tm.single.moveId, 'protect');
    expect(
      store.learnsetById('bulbasaur')?.tm.single.versionGroup,
      'scarlet-violet',
    );
  });

  testWidgets('keeps legacy moves visible and flags them as missing locally',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final store = _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        'bulbasaur': _buildDetail(
          id: 'bulbasaur',
          learnset: const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            startingMoves: <String>['legacy_move'],
          ),
        ),
      },
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        learnsetSaver: store.saveLearnset,
        metadataSaver: store.saveMetadata,
        formsClassificationSaver: store.saveFormsClassification,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
        movesCatalogLoader: (_) async => _movesCatalogView(),
        movesCatalogPreviewer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: true,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
        movesCatalogSyncer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: false,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    expect(find.text('legacy_move'), findsWidgets);
    expect(find.text('Absent du catalogue local'), findsWidgets);
  });
}

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;

  int learnsetSaveCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    return _detailsById.values
        .map(
          (detail) => PokemonDatabaseIndexEntry(
            id: detail.species.id,
            nationalDex: detail.species.nationalDex,
            primaryName: detail.species.names['en'] ?? detail.species.id,
            genIntroduced: detail.species.genIntroduced,
            types: detail.species.typing.types,
            isEnabledInProject:
                detail.species.classification.isEnabledInProject,
            refs: PokemonDatabaseIndexRefs(
              learnset: detail.species.refs.learnset,
              evolution: detail.species.refs.evolution,
              media: detail.species.refs.media,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> saveMetadata(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    return _detailsById[request.speciesId]!.species;
  }

  Future<PokemonSpeciesFile> saveFormsClassification(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    return _detailsById[request.speciesId]!.species;
  }

  Future<PokemonLearnsetFile> saveLearnset(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    learnsetSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updated = PokemonLearnsetFile(
      speciesId: current.species.refs.learnset,
      startingMoves: request.startingMoves,
      relearnMoves: request.relearnMoves,
      levelUp: request.levelUp,
      tm: request.tm,
      tutor: request.tutor,
      egg: request.egg,
      event: request.event,
      transfer: request.transfer,
    );
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: updated,
      evolution: current.evolution,
      media: current.media,
    );
    return updated;
  }

  Future<PokemonEvolutionFile> saveEvolution(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    return _detailsById[request.speciesId]!.evolution!;
  }

  Future<PokemonMediaFile> saveMedia(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    return _detailsById[request.speciesId]!.media!;
  }

  PokemonLearnsetFile? learnsetById(String speciesId) {
    return _detailsById[speciesId]?.learnset;
  }
}

PokedexSpeciesDetail _buildDetail({
  required String id,
  required PokemonLearnsetFile learnset,
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: 1,
      names: const <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
      speciesName: const <String, String>{
        'fr': 'Pokémon Graine',
        'en': 'Seed Pokemon',
      },
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
      forms: PokemonSpeciesForms(
        baseFormId: id,
        isBaseForm: true,
        formId: 'base',
      ),
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: PokemonSpeciesRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(
        starterEligible: true,
      ),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'ui-test',
        seedVersion: 1,
      ),
    ),
    learnset: learnset,
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
    ),
  );
}

PokemonMovesCatalogView _movesCatalogView() {
  return const PokemonMovesCatalogView(
    isAvailable: true,
    description: 'Catalogue local des attaques pour les tests UI.',
    entries: <PokemonMoveCatalogEntryView>[
      PokemonMoveCatalogEntryView(
        id: 'growl',
        name: 'Growl',
        type: 'normal',
        category: 'status',
        pp: 40,
      ),
      PokemonMoveCatalogEntryView(
        id: 'protect',
        name: 'Protect',
        type: 'normal',
        category: 'status',
        pp: 10,
      ),
      PokemonMoveCatalogEntryView(
        id: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: 'physical',
        power: 40,
        accuracy: 100,
        pp: 35,
      ),
      PokemonMoveCatalogEntryView(
        id: 'vine_whip',
        name: 'Vine Whip',
        type: 'grass',
        category: 'physical',
        power: 45,
        accuracy: 100,
        pp: 25,
      ),
    ],
  );
}

```

## `packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/pokemon_moves_catalog_lookup_service.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';

void main() {
  const service = PokemonMovesCatalogLookupService();

  group('PokemonMovesCatalogLookupService', () {
    test('finds a move by its exact local id', () {
      final entry = service.findById(_entries, 'vine_whip');

      expect(entry, isNotNull);
      expect(entry!.name, 'Vine Whip');
    });

    test('searches by move id and name with stable local results', () {
      final idResults = service.search(_entries, 'vine');
      final nameResults = service.search(_entries, 'tackle');

      expect(
        idResults.map((entry) => entry.id).toList(growable: false),
        contains('vine_whip'),
      );
      expect(nameResults.first.id, 'tackle');
    });

    test('returns no result for an unknown local move query', () {
      final results = service.search(_entries, 'missing_move');

      expect(results, isEmpty);
    });
  });
}

const List<PokemonMoveCatalogEntryView> _entries =
    <PokemonMoveCatalogEntryView>[
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
    accuracy: 100,
    pp: 35,
  ),
  PokemonMoveCatalogEntryView(
    id: 'vine_whip',
    name: 'Vine Whip',
    type: 'grass',
    category: 'physical',
    power: 45,
    accuracy: 100,
    pp: 25,
  ),
];

```
