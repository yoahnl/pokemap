# NS-HOME-07 — Narrative Overview Structure Inspector Panel V0

## 1. Résumé exécutif

NS-HOME-07 ajoute le premier panneau V0 `Structure narrative` à la page `Narrative Studio / Aperçu`.

Le panneau est branché exclusivement sur le read model existant :

- `readModel.structureInspector`
- `readModel.editorialStatus`
- `readModel.projectHealth`

Le lot ne modifie pas `NarrativeOverviewReadModel`, ne crée pas de nouveau modèle métier, ne touche pas à `map_core`, `map_runtime`, `map_gameplay` ou `map_battle`, et n’invente ni tags, ni description, ni compteur Facts réel.

Le layout est volontairement interne au workspace : en largeur desktop, le contenu principal reste à gauche et `Structure narrative` s’affiche à droite ; en largeur plus étroite, le panneau s’empile sous les modules.

## 2. Rappel du scope NS-HOME-07

Objectif livré :

- ajouter un panneau `Structure narrative` V0 ;
- afficher les compteurs structurels exposés par le read model ;
- afficher description/tags en états indisponibles honnêtes ;
- afficher les chapitres du read model quand ils existent ;
- afficher le statut éditorial avec `Non évalué`, `À jour`, `À revoir`, `Bloquant` selon diagnostics fournis ;
- produire un screenshot Visual Gate.

Hors scope respecté :

- pas d’activité récente ;
- pas de notifications ;
- pas de top bar finale ;
- pas de sidebar finale ;
- pas de description Selbrume hardcodée ;
- pas de tags hardcodés ;
- pas de compteur Facts réel ;
- pas de progression joueur.

## 3. Fichiers créés / modifiés

Fichiers créés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- `reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png`
- `reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

## 4. Choix de placement du panneau

Décision : panneau interne au `NarrativeOverviewWorkspace`, pas réactivation du panneau droit global de `EditorShellPage`.

Raison :

- c’est le changement le plus petit pour NS-HOME-07 ;
- les blocs NS-HOME-04/05/06 restent dans le même écran ;
- le panneau peut être testé en widget test sans dépendre du shell global ;
- on évite de coupler prématurément l’overview au layout final App Shell.

Comportement responsive :

- `>= 1180 px` : colonne principale à gauche + panneau `Structure narrative` à droite ;
- `< 1180 px` : colonne principale puis panneau empilé.

## 5. UI créée

Le fichier `narrative_overview_structure_inspector.dart` contient un widget dédié :

```dart
class NarrativeOverviewStructureInspector extends StatelessWidget {
  const NarrativeOverviewStructureInspector({
    super.key,
    required this.inspector,
    required this.editorialStatus,
    required this.projectHealth,
  });

  final NarrativeStructureInspectorSummary inspector;
  final EditorialStatusSummary editorialStatus;
  final NarrativeProjectHealthSummary projectHealth;
}
```

Sections rendues :

- en-tête `STRUCTURE NARRATIVE` ;
- bloc identité avec `inspector.projectName` et `inspector.globalStatusLabel` ;
- compteurs structurels avec keys `narrative-overview-structure-counter-*` ;
- `DESCRIPTION` ;
- `TAGS` ;
- `CHAPITRES` ;
- `STATUT ÉDITORIAL`.

Le widget ne lit pas le manifest, ne parse pas de metadata, ne calcule pas lui-même les métriques.

## 6. Mapping Structure Inspector → readModel.structureInspector

| UI | Source |
|---|---|
| Nom projet / univers | `readModel.structureInspector.projectName` |
| Statut global | `readModel.structureInspector.globalStatusLabel` |
| Compteurs | `readModel.structureInspector.counters` |
| Description | `readModel.structureInspector.description` + `descriptionAvailability` |
| Tags | `readModel.structureInspector.tags` + `tagsAvailability` |
| Chapitres | `readModel.structureInspector.chapters` |
| Statut éditorial | `readModel.editorialStatus` |
| Project Health | `readModel.projectHealth` |

`Facts` reste affiché comme `Nécessite un modèle` quand le read model le déclare `needsModel`.

## 7. Gestion des états available / empty / unavailable / notEvaluated / needsModel

Rendu des compteurs :

- `available` / `empty` : valeur numérique réelle du read model ;
- `unavailable` : `Indisponible` ;
- `notEvaluated` : `Non évalué` ;
- `outOfScope` : `Hors scope V0` ;
- `needsModel` : `Nécessite un modèle`.

Description :

- `available` + texte non vide : affiche le texte ;
- sinon : `Description non disponible en V0.`

Tags :

- `available` + tags non vides : affiche les chips ;
- sinon : `Tags non disponibles en V0.`

Statut éditorial :

- sans validation : `Validation non lancée` et pas de `À jour` ;
- validation clean : `À jour` ;
- warning : `À revoir` ;
- error : `Bloquant`.

## 8. Ce qui reste volontairement hors scope

- vraie édition de description ;
- vraie édition de tags ;
- modèle Facts ;
- statut éditorial persisté manuellement ;
- activité récente ;
- notifications ;
- panneau droit global du shell final ;
- polish pixel-perfect de l’image cible.

## 9. Tests ajoutés / modifiés

Tests ajoutés dans `narrative_overview_workspace_test.dart` :

- rendu du panneau `Structure narrative` ;
- empty states description/tags/chapitres ;
- compteur Facts en `Nécessite un modèle` ;
- compteurs/chapitres issus du read model ;
- validation clean => `À jour` ;
- warning => `À revoir` ;
- error => `Bloquant` ;
- screenshot via `NS_HOME_07_CAPTURE_SCREENSHOT`.

Tests ajustés :

- les assertions `test_project` acceptent plusieurs occurrences, car le projet est maintenant visible dans le bloc `Projet` et dans le panneau `Structure narrative`.
- le test shell navigation accepte également plusieurs occurrences du nom projet.

## 10. Visual Gate

Screenshot produit :

```text
reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png
```

Méthode :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --update-goldens --dart-define=NS_HOME_07_CAPTURE_SCREENSHOT=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --dart-define=NS_HOME_07_CAPTURE_SCREENSHOT=true
```

Ce qui correspond à l’image cible :

- panneau à droite en largeur desktop ;
- titre `STRUCTURE NARRATIVE` ;
- bloc identité projet ;
- liste de compteurs structurels ;
- sections `DESCRIPTION`, `TAGS`, `CHAPITRES`, `STATUT ÉDITORIAL` ;
- cartes compactes de statut éditorial ;
- style sombre, bordures subtiles, densité outil.

Ce qui ne correspond pas encore :

- pas de top bar / sidebar finale ;
- pas de description/tags réels ;
- pas d’icônes finales premium ;
- pas de panneau shell global final ;
- modules partiellement visibles dans le viewport de capture, car le screenshot privilégie le panneau droit.

Observation visuelle :

- le panneau est lisible à droite ;
- les compteurs structurels sont compréhensibles ;
- `Description non disponible en V0.` et `Tags non disponibles en V0.` évitent toute donnée inventée ;
- `Facts` est bien affiché comme `Nécessite un modèle` ;
- `Validation non lancée` est lisible ;
- l’overflow détecté pendant les tests sur une stat secondaire de module a été corrigé en rendant les textes flexibles et ellipsés.

Limite visuelle :

- les pictogrammes `CupertinoIcons` apparaissent comme carrés dans les screenshots golden, comme déjà visible dans le screenshot NS-HOME-06. Le défaut est lié à la méthode de capture widget test et n’empêche pas de valider la structure/layout du lot.

## 11. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
flutter test test/ui/canvas/narrative_overview_workspace_test.dart
flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test test/ui/canvas/narrative_overview_workspace_test.dart --dart-define=NS_HOME_07_CAPTURE_SCREENSHOT=true
flutter test test/ui/canvas/narrative_overview_workspace_test.dart --update-goldens --dart-define=NS_HOME_07_CAPTURE_SCREENSHOT=true
flutter analyze
flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
dart format lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
git diff --check
```

## 12. Résultats des tests

Test ciblé workspace :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +3: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +4: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +5: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +6: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +7: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +8: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +9: NarrativeOverviewWorkspace module cards consume read model values
00:01 +10: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +11: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +12: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:01 +13: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:01 +14: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +15: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +16: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +17: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +18: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +19: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +20: All tests passed!
```

Tests workspace + navigation :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:01 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace module cards consume read model values
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +22: All tests passed!
```

Screenshot stable :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +3: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +4: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +5: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +6: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +7: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +8: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +9: NarrativeOverviewWorkspace module cards consume read model values
00:01 +10: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +11: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +12: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:01 +13: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:01 +14: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:01 +15: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:01 +16: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:01 +17: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:01 +18: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:01 +19: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +20: All tests passed!
```

## 13. Résultats analyze

`flutter analyze` global :

```text
Analyzing map_editor...

  error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
  error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
  error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
348 issues found. (ran in 3.5s)
```

Conclusion : échec global dû à une dette préexistante hors NS-HOME-07, côté Pokémon SDK / Pokédex. Les fichiers NS-HOME-07 ne sont pas cités dans les erreurs globales.

Analyse ciblée :

```text
Analyzing 4 items...

No issues found! (ran in 1.9s)
```

## 14. Limites

- Le panneau est interne au workspace, pas encore intégré à un App Shell final.
- Description et tags restent des empty states honnêtes, car le read model les expose comme indisponibles / needsModel.
- La vraie gestion éditoriale persistée n’existe pas encore.
- Le screenshot widget ne montre pas la top bar/sidebar finale.

## 15. Prochain lot recommandé

Prochain lot exact recommandé :

```text
NS-HOME-08 — Narrative Overview Empty States / Footer Metadata V0
```

Justification :

- les blocs principaux du dashboard central existent maintenant : KPI, Histoire principale, Modules, Structure narrative ;
- il reste à harmoniser les empty states visibles (`description`, `tags`, `activité récente`, `notifications`, `locale/version/footer`) avant d’attaquer la top bar/sidebar finale ;
- ce lot permettrait de renforcer l’honnêteté produit sans créer de fausses données.

## 16. Evidence Pack

Branche initiale :

```text
main
```

Statut initial :

```text
Sortie : <vide>
```

Diff stat initial :

```text
Sortie : <vide>
```

Diff name-only initial :

```text
Sortie : <vide>
```

Statut final attendu après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
?? reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png
?? reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
```

Diff stat avant ajout du rapport :

```text
 .../ui/canvas/narrative_overview_workspace.dart    |  87 ++++++-
 .../narrative_overview_shell_navigation_test.dart  |   2 +-
 .../canvas/narrative_overview_workspace_test.dart  | 289 ++++++++++++++++++++-
 3 files changed, 361 insertions(+), 17 deletions(-)
```

Diff name-only avant ajout du rapport :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Note : les fichiers non trackés ne sont pas listés par `git diff --stat` / `git diff --name-only`.

Fichiers créés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png
reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
```

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Extraits structurants modifiés :

```dart
final structureInspector = NarrativeOverviewStructureInspector(
  inspector: readModel.structureInspector,
  editorialStatus: readModel.editorialStatus,
  projectHealth: readModel.projectHealth,
);
```

```dart
if (constraints.maxWidth >= 1180) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: mainColumn),
      const SizedBox(width: 14),
      SizedBox(width: 360, child: structureInspector),
    ],
  );
}
return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    mainColumn,
    const SizedBox(height: 12),
    structureInspector,
  ],
);
```

`git diff --check` :

```text
Sortie : <vide>
```

Confirmations :

- aucun runtime modifié ;
- aucun gameplay modifié ;
- aucun battle modifié ;
- aucun `map_core` modifié ;
- aucun `NarrativeOverviewReadModel` modifié ;
- aucun provider créé ;
- aucun repository créé ;
- aucune donnée Selbrume hardcodée ;
- aucun tag de l’image hardcodé ;
- aucun chiffre de l’image hardcodé.

## 17. Auto-review critique

- Ai-je créé le panneau Structure narrative ? Oui.
- Le panneau consomme-t-il uniquement le read model ? Oui, il reçoit seulement `structureInspector`, `editorialStatus`, `projectHealth`.
- Ai-je inventé une description ? Non, empty state V0.
- Ai-je inventé des tags ? Non, empty state V0.
- Ai-je affiché Facts comme donnée réelle ? Non, `Nécessite un modèle`.
- Ai-je affiché `À jour` sans validation ? Non, sans validation le panneau affiche `Validation non lancée`.
- Ai-je couvert warning/error ? Oui, tests `À revoir` et `Bloquant`.
- Ai-je touché runtime/gameplay/battle/map_core ? Non.
- Les blocs précédents restent-ils visibles ? Oui, tests.
- Le Visual Gate est-il produit ? Oui.

## 18. Regard critique sur le prompt

Le prompt est bien borné : il empêche de transformer le panneau en maquette finale trop tôt et force les empty states honnêtes. La seule tension est la demande d’un panneau droit proche de l’image tout en gardant un shell V0 ; le choix d’un panneau interne responsive est le compromis le plus sûr pour préserver le scope.
