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

## 19. Evidence Pack bis — audit complet du panneau Structure narrative

### 19.1 Contexte du bis

Au début de NS-HOME-07-bis, le dépôt était propre et le lot NS-HOME-07 était déjà intégré dans le commit courant :

```text
68f969fa feat(narrative-studio): add narrative overview structure inspector
```

Sortie `git status --short --untracked-files=all` au début du bis :

```text
Sortie : <vide>
```

Ce bis ne modifie que ce rapport :

```text
reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
```

### 19.2 Git final réellement capturé

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 ...me_07_narrative_overview_structure_inspector.md | 1337 ++++++++++++++++++++
 1 file changed, 1337 insertions(+)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
```

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

### 19.3 Contenu complet du nouveau widget

Fichier :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
```

Contenu complet :

```dart
import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Panneau V0 de synthèse "Structure narrative" pour l'aperçu auteur.
///
/// Le widget affiche uniquement des données déjà normalisées par
/// [NarrativeOverviewReadModel] afin d'éviter les compteurs ou statuts inventés.
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

  @override
  Widget build(BuildContext context) {
    final accent = _editorialAccent(context, editorialStatus.validationState);
    return Container(
      key: const ValueKey('narrative-overview-structure-inspector'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'STRUCTURE NARRATIVE',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.pin_fill,
                color: EditorChrome.subtleLabel(context),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InspectorIdentity(
            projectName: inspector.projectName,
            statusLabel: inspector.globalStatusLabel,
            accent: accent,
          ),
          const SizedBox(height: 14),
          _InspectorDivider(),
          const SizedBox(height: 12),
          _InspectorCounters(counters: inspector.counters),
          const SizedBox(height: 14),
          _InspectorSection(
            title: 'DESCRIPTION',
            child: _DescriptionBlock(inspector: inspector),
          ),
          const SizedBox(height: 14),
          _InspectorSection(
            title: 'TAGS',
            child: _TagsBlock(inspector: inspector),
          ),
          const SizedBox(height: 14),
          _InspectorSection(
            title: 'CHAPITRES (${inspector.chapters.length})',
            child: _ChaptersBlock(chapters: inspector.chapters),
          ),
          const SizedBox(height: 14),
          _InspectorSection(
            title: 'STATUT ÉDITORIAL',
            child: _EditorialStatusBlock(
              editorialStatus: editorialStatus,
              projectHealth: projectHealth,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorIdentity extends StatelessWidget {
  const _InspectorIdentity({
    required this.projectName,
    required this.statusLabel,
    required this.accent,
  });

  final String projectName;
  final String statusLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.24)),
          ),
          alignment: Alignment.center,
          child: Icon(
            CupertinoIcons.compass_fill,
            color: accent,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                projectName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _InspectorPill(label: statusLabel, accent: accent),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorCounters extends StatelessWidget {
  const _InspectorCounters({required this.counters});

  final List<NarrativeMetricSummary> counters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final counter in counters) _StructureCounterRow(counter: counter),
      ],
    );
  }
}

class _StructureCounterRow extends StatelessWidget {
  const _StructureCounterRow({required this.counter});

  final NarrativeMetricSummary counter;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, counter.availability);
    return Container(
      key: ValueKey('narrative-overview-structure-counter-${counter.id}'),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(_counterIcon(counter.id), color: accent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              counter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _metricValue(counter),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: _metricValue(counter).length > 12 ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorDivider(),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 9),
        child,
      ],
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.inspector});

  final NarrativeStructureInspectorSummary inspector;

  @override
  Widget build(BuildContext context) {
    final description = inspector.description?.trim();
    if (inspector.descriptionAvailability ==
            NarrativeOverviewAvailability.available &&
        description != null &&
        description.isNotEmpty) {
      return _BodyText(description);
    }
    return const _UnavailableCopy(
      message: 'Description non disponible en V0.',
      detail: 'Aucun synopsis global fiable n’est encore exposé.',
    );
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock({required this.inspector});

  final NarrativeStructureInspectorSummary inspector;

  @override
  Widget build(BuildContext context) {
    if (inspector.tagsAvailability == NarrativeOverviewAvailability.available &&
        inspector.tags.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in inspector.tags) _TagChip(label: tag),
        ],
      );
    }
    return const _UnavailableCopy(
      message: 'Tags non disponibles en V0.',
      detail: 'Registre de tags à définir avant affichage.',
    );
  }
}

class _ChaptersBlock extends StatelessWidget {
  const _ChaptersBlock({required this.chapters});

  final List<NarrativeChapterOverviewSummary> chapters;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Text(
        'Aucun chapitre authoré.',
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Column(
      children: [
        for (final chapter in chapters) _ChapterRow(chapter: chapter),
      ],
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter});

  final NarrativeChapterOverviewSummary chapter;

  @override
  Widget build(BuildContext context) {
    final accent = _chapterAccent(chapter.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: EditorChrome.islandCoolTint.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              '${chapter.order + 1}',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              chapter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _chapterStatusLabel(chapter.status),
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialStatusBlock extends StatelessWidget {
  const _EditorialStatusBlock({
    required this.editorialStatus,
    required this.projectHealth,
  });

  final EditorialStatusSummary editorialStatus;
  final NarrativeProjectHealthSummary projectHealth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _EditorialStatusTile(
              slot: 'validation',
              label: 'Validation',
              value: _validationValue(editorialStatus),
              accent: _editorialAccent(
                context,
                editorialStatus.validationState,
              ),
            ),
            _EditorialStatusTile(
              slot: 'review',
              label: 'À revoir',
              value: '${editorialStatus.toReview}',
              accent: editorialStatus.toReview > 0
                  ? EditorChrome.accentWarm
                  : EditorChrome.subtleLabel(context),
            ),
            _EditorialStatusTile(
              slot: 'blocking',
              label: 'Bloquants',
              value: '${editorialStatus.blocking}',
              accent: editorialStatus.blocking > 0
                  ? EditorChrome.accentCoral
                  : EditorChrome.subtleLabel(context),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _BodyText(editorialStatus.diagnosticSourceSummary),
        const SizedBox(height: 5),
        _BodyText(
          'Project Health : ${_projectHealthLabel(projectHealth.healthKind)}',
        ),
      ],
    );
  }
}

class _EditorialStatusTile extends StatelessWidget {
  const _EditorialStatusTile({
    required this.slot,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String slot;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('narrative-overview-structure-editorial-$slot'),
      constraints: const BoxConstraints(minWidth: 96),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: value.length > 14 ? 12 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCopy extends StatelessWidget {
  const _UnavailableCopy({
    required this.message,
    required this.detail,
  });

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        _BodyText(detail),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentPrimary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: EditorChrome.accentPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InspectorPill extends StatelessWidget {
  const _InspectorPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InspectorDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.14),
    );
  }
}

String _metricValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}

String _validationValue(EditorialStatusSummary editorialStatus) {
  if (editorialStatus.notEvaluated) {
    return 'Validation non lancée';
  }
  return switch (editorialStatus.validationState) {
    NarrativeEditorialValidationState.notEvaluated => 'Validation non lancée',
    NarrativeEditorialValidationState.upToDate => 'À jour',
    NarrativeEditorialValidationState.toReview => 'À revoir',
    NarrativeEditorialValidationState.blocking => 'Bloquant',
  };
}

String _chapterStatusLabel(NarrativeChapterEditorialStatus status) {
  return switch (status) {
    NarrativeChapterEditorialStatus.defined => 'Défini',
    NarrativeChapterEditorialStatus.inProgress => 'En cours',
    NarrativeChapterEditorialStatus.draft => 'Brouillon',
    NarrativeChapterEditorialStatus.notEvaluated => 'Non évalué',
  };
}

String _projectHealthLabel(NarrativeProjectHealthKind healthKind) {
  return switch (healthKind) {
    NarrativeProjectHealthKind.notEvaluated => 'Non évalué',
    NarrativeProjectHealthKind.healthy => 'Sain',
    NarrativeProjectHealthKind.reviewNeeded => 'À revoir',
    NarrativeProjectHealthKind.blocked => 'Bloqué',
  };
}

Color _availabilityAccent(
  BuildContext context,
  NarrativeOverviewAvailability availability,
) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => EditorChrome.accentJade,
    NarrativeOverviewAvailability.empty => EditorChrome.accentPrimary,
    NarrativeOverviewAvailability.unavailable => EditorChrome.accentCoral,
    NarrativeOverviewAvailability.notEvaluated => EditorChrome.accentWarm,
    NarrativeOverviewAvailability.outOfScope =>
      EditorChrome.subtleLabel(context),
    NarrativeOverviewAvailability.needsModel => EditorChrome.inspectorJoyPlum,
  };
}

Color _editorialAccent(
  BuildContext context,
  NarrativeEditorialValidationState state,
) {
  return switch (state) {
    NarrativeEditorialValidationState.notEvaluated => EditorChrome.accentWarm,
    NarrativeEditorialValidationState.upToDate => EditorChrome.accentJade,
    NarrativeEditorialValidationState.toReview => EditorChrome.accentWarm,
    NarrativeEditorialValidationState.blocking => EditorChrome.accentCoral,
  };
}

Color _chapterAccent(NarrativeChapterEditorialStatus status) {
  return switch (status) {
    NarrativeChapterEditorialStatus.defined => EditorChrome.accentJade,
    NarrativeChapterEditorialStatus.inProgress => EditorChrome.accentPrimary,
    NarrativeChapterEditorialStatus.draft => EditorChrome.accentLilac,
    NarrativeChapterEditorialStatus.notEvaluated => EditorChrome.accentWarm,
  };
}

IconData _counterIcon(String metricId) {
  return switch (metricId) {
    'chapters' => CupertinoIcons.book_fill,
    'scenes' => CupertinoIcons.rectangle_stack_fill,
    'cutscenes' => CupertinoIcons.film_fill,
    'dialogues' => CupertinoIcons.chat_bubble_2_fill,
    'facts' => CupertinoIcons.doc_text_fill,
    _ => CupertinoIcons.chart_bar_fill,
  };
}
```

### 19.4 Hunks complets des sections modifiées

Commande :

```bash
git show --format= -- packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart b/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
index d6610246..4e5b00d7 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
@@ -2,6 +2,7 @@ import 'package:flutter/cupertino.dart';

 import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
 import '../shared/cupertino_editor_widgets.dart';
+import 'narrative_overview_structure_inspector.dart';

 /// Shell V0 de la page "Aperçu" du Narrative Studio.
 ///
@@ -38,6 +39,60 @@ class NarrativeOverviewWorkspace extends StatelessWidget {
           ),
         ),
         const SizedBox(height: 18),
+        _OverviewResponsiveBody(readModel: readModel),
+      ],
+    );
+  }
+}
+
+class _OverviewResponsiveBody extends StatelessWidget {
+  const _OverviewResponsiveBody({required this.readModel});
+
+  final NarrativeOverviewReadModel readModel;
+
+  @override
+  Widget build(BuildContext context) {
+    return LayoutBuilder(
+      builder: (context, constraints) {
+        final mainColumn = _OverviewMainColumn(readModel: readModel);
+        final structureInspector = NarrativeOverviewStructureInspector(
+          inspector: readModel.structureInspector,
+          editorialStatus: readModel.editorialStatus,
+          projectHealth: readModel.projectHealth,
+        );
+        if (constraints.maxWidth >= 1180) {
+          return Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              Expanded(child: mainColumn),
+              const SizedBox(width: 14),
+              SizedBox(width: 360, child: structureInspector),
+            ],
+          );
+        }
+        return Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            mainColumn,
+            const SizedBox(height: 12),
+            structureInspector,
+          ],
+        );
+      },
+    );
+  }
+}
+
+class _OverviewMainColumn extends StatelessWidget {
+  const _OverviewMainColumn({required this.readModel});
+
+  final NarrativeOverviewReadModel readModel;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
         _OverviewSection(
           title: 'Projet',
           children: [
@@ -274,21 +329,29 @@ class _ModuleSecondaryStat extends StatelessWidget {
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
-          Text(
-            stat.label,
-            style: TextStyle(
-              color: EditorChrome.subtleLabel(context),
-              fontSize: 11,
-              fontWeight: FontWeight.w800,
+          Flexible(
+            child: Text(
+              stat.label,
+              maxLines: 1,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: EditorChrome.subtleLabel(context),
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+              ),
             ),
           ),
           const SizedBox(width: 6),
-          Text(
-            _metricCardValue(stat),
-            style: TextStyle(
-              color: accent,
-              fontSize: 11,
-              fontWeight: FontWeight.w900,
+          Flexible(
+            child: Text(
+              _metricCardValue(stat),
+              maxLines: 1,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: accent,
+                fontSize: 11,
+                fontWeight: FontWeight.w900,
+              ),
             ),
           ),
         ],
diff --git a/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart b/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
index ca7084c3..1d3e17ba 100644
--- a/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
+++ b/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
@@ -42,7 +42,7 @@ void main() {
       await tester.pump();

       expect(find.text('Aperçu'), findsWidgets);
-      expect(find.textContaining('test_project'), findsOneWidget);
+      expect(find.textContaining('test_project'), findsWidgets);
       expect(find.textContaining('Non évalué'), findsWidgets);
       expect(find.textContaining('Selbrume'), findsNothing);
       expect(find.text('42'), findsNothing);
diff --git a/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart b/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
index 65bba8ab..2725c683 100644
--- a/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
+++ b/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
@@ -26,7 +26,7 @@ void main() {
         find.text('Vue d’ensemble auteur du Narrative Studio.'),
         findsOneWidget,
       );
-      expect(find.textContaining('test_project'), findsOneWidget);
+      expect(find.textContaining('test_project'), findsWidgets);
       expect(find.textContaining('Non évalué'), findsWidgets);
       expect(find.text('Indicateurs auteur'), findsOneWidget);
       for (final label in <String>[
@@ -160,7 +160,7 @@ void main() {
       expect(find.text('Aperçu'), findsOneWidget);
       expect(find.text('Vue d’ensemble auteur du Narrative Studio.'),
           findsOneWidget);
-      expect(find.textContaining('test_project'), findsOneWidget);
+      expect(find.textContaining('test_project'), findsWidgets);
       expect(find.byKey(const ValueKey('narrative-overview-kpi-grid')),
           findsOneWidget);
       expect(_textInKpi('cutscenes', '0'), findsOneWidget);
@@ -219,8 +219,8 @@ void main() {
       expect(_textInMainStory('1'), findsNWidgets(2));
       expect(_textInMainStory('Problèmes ouverts'), findsOneWidget);
       expect(_textInMainStory('Non évalué'), findsWidgets);
-      expect(find.text('Test Chapter One'), findsOneWidget);
-      expect(find.text('Test Chapter Two'), findsOneWidget);
+      expect(find.text('Test Chapter One'), findsWidgets);
+      expect(find.text('Test Chapter Two'), findsWidgets);
       expect(find.textContaining('Fallback'), findsNothing);
       expect(find.textContaining('Selbrume'), findsNothing);
       expect(find.textContaining('La brume du phare'), findsNothing);
@@ -462,6 +462,178 @@ void main() {
     },
   );

+  testWidgets(
+    'NarrativeOverviewWorkspace renders an honest structure inspector panel',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject('test_project'),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 980);
+
+      expect(
+        find.byKey(
+          const ValueKey('narrative-overview-structure-inspector'),
+        ),
+        findsOneWidget,
+      );
+      expect(_textInStructureInspector('STRUCTURE NARRATIVE'), findsOneWidget);
+      expect(_textInStructureInspector('test_project'), findsOneWidget);
+      expect(_textInStructureInspector('Non évalué'), findsWidgets);
+      expect(_textInStructureInspector('À jour'), findsNothing);
+      expect(
+        _textInStructureInspector('Description non disponible en V0.'),
+        findsOneWidget,
+      );
+      expect(
+        _textInStructureInspector('Tags non disponibles en V0.'),
+        findsOneWidget,
+      );
+      expect(
+        _textInStructureInspector('Aucun chapitre authoré.'),
+        findsOneWidget,
+      );
+      expect(
+        _textInStructureInspector('Validation non lancée'),
+        findsOneWidget,
+      );
+      expect(_textInStructureCounter('facts', 'Facts'), findsOneWidget);
+      expect(
+        _textInStructureCounter('facts', 'Nécessite un modèle'),
+        findsOneWidget,
+      );
+
+      for (final forbidden in <String>[
+        'Selbrume',
+        'Port Selbrume',
+        'Phare',
+        'Mystère',
+        'Exploration',
+        'Fantastique',
+        'Côtiers',
+      ]) {
+        expect(find.textContaining(forbidden), findsNothing);
+      }
+      expect(find.text('42'), findsNothing);
+      expect(find.text('24'), findsNothing);
+      expect(find.text('12'), findsNothing);
+      expect(find.text('312'), findsNothing);
+    },
+  );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject(
+          'test_project',
+          scenarios: <ScenarioAsset>[
+            _globalStoryWithDocuments(),
+            _cutsceneScenario(
+              id: 'test_cutscene_1',
+              dialogueId: 'test_dialogue_1',
+            ),
+          ],
+          dialogues: const <ProjectDialogueEntry>[
+            ProjectDialogueEntry(
+              id: 'test_dialogue_1',
+              name: 'Test Dialogue',
+              relativePath: 'dialogues/test_dialogue_1.yarn',
+            ),
+          ],
+        ),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 980);
+
+      expect(_textInStructureCounter('chapters', '2'), findsOneWidget);
+      expect(_textInStructureCounter('scenes', '1'), findsOneWidget);
+      expect(_textInStructureCounter('cutscenes', '1'), findsOneWidget);
+      expect(_textInStructureCounter('dialogues', '1'), findsOneWidget);
+      expect(
+        _textInStructureCounter('facts', 'Nécessite un modèle'),
+        findsOneWidget,
+      );
+      expect(_textInStructureInspector('Test Chapter One'), findsOneWidget);
+      expect(_textInStructureInspector('Test Chapter Two'), findsOneWidget);
+      expect(_textInStructureInspector('KPI cards'), findsNothing);
+      expect(find.textContaining('Selbrume'), findsNothing);
+      expect(find.textContaining('La brume du phare'), findsNothing);
+      expect(find.text('42'), findsNothing);
+      expect(find.text('27'), findsNothing);
+      expect(find.text('412'), findsNothing);
+      expect(find.text('312'), findsNothing);
+    },
+  );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace structure inspector shows clean validation as up to date',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject('test_project'),
+        narrativeValidationReport: NarrativeValidationReport(
+          diagnostics: const <NarrativeValidationDiagnostic>[],
+        ),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 980);
+
+      expect(_textInStructureInspector('À jour'), findsWidgets);
+      expect(
+        _textInStructureInspector('0 diagnostic(s) narratif(s)'),
+        findsOneWidget,
+      );
+      expect(_textInStructureEditorial('validation', 'À jour'), findsOneWidget);
+      expect(_textInStructureEditorial('review', '0'), findsOneWidget);
+      expect(_textInStructureEditorial('blocking', '0'), findsOneWidget);
+    },
+  );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace structure inspector maps warnings to review state',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject('test_project'),
+        narrativeValidationReport: NarrativeValidationReport(
+          diagnostics: <NarrativeValidationDiagnostic>[
+            _diagnostic(NarrativeValidationSeverity.warning),
+          ],
+        ),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 980);
+
+      expect(_textInStructureInspector('À revoir'), findsWidgets);
+      expect(
+          _textInStructureEditorial('validation', 'À revoir'), findsOneWidget);
+      expect(_textInStructureEditorial('review', '1'), findsOneWidget);
+      expect(_textInStructureEditorial('blocking', '0'), findsOneWidget);
+    },
+  );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace structure inspector maps errors to blocking state',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject('test_project'),
+        narrativeValidationReport: NarrativeValidationReport(
+          diagnostics: <NarrativeValidationDiagnostic>[
+            _diagnostic(NarrativeValidationSeverity.error),
+          ],
+        ),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 980);
+
+      expect(_textInStructureInspector('Bloquant'), findsWidgets);
+      expect(
+          _textInStructureEditorial('validation', 'Bloquant'), findsOneWidget);
+      expect(_textInStructureEditorial('review', '0'), findsOneWidget);
+      expect(_textInStructureEditorial('blocking', '1'), findsOneWidget);
+      expect(_textInStructureInspector('À jour'), findsNothing);
+    },
+  );
+
   testWidgets(
     'NarrativeOverviewWorkspace captures KPI cards screenshot when requested',
     (tester) async {
@@ -676,6 +848,80 @@ void main() {
       expect(screenshotFile.existsSync(), isTrue);
     },
   );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace captures structure inspector screenshot when requested',
+    (tester) async {
+      if (!const bool.fromEnvironment('NS_HOME_07_CAPTURE_SCREENSHOT')) {
+        return;
+      }
+
+      await _loadScreenshotFont();
+      tester.view.physicalSize = const Size(1440, 980);
+      tester.view.devicePixelRatio = 1;
+      addTearDown(() {
+        tester.view.resetPhysicalSize();
+        tester.view.resetDevicePixelRatio();
+      });
+
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject(
+          'test_project',
+          scenarios: <ScenarioAsset>[
+            _globalStoryWithDocuments(),
+            _cutsceneScenario(
+              id: 'test_cutscene_1',
+              dialogueId: 'test_dialogue_1',
+            ),
+          ],
+          dialogues: const <ProjectDialogueEntry>[
+            ProjectDialogueEntry(
+              id: 'test_dialogue_1',
+              name: 'Test Dialogue',
+              relativePath: 'dialogues/test_dialogue_1.yarn',
+            ),
+          ],
+        ),
+      );
+
+      await tester.pumpWidget(
+        MacosTheme(
+          data: MacosThemeData.dark(),
+          child: CupertinoApp(
+            home: CupertinoPageScaffold(
+              child: ColoredBox(
+                key: const ValueKey('ns-home-07-screenshot-root'),
+                color: const Color(0xFF07111F),
+                child: DefaultTextStyle.merge(
+                  style: const TextStyle(fontFamily: _screenshotFontFamily),
+                  child: Center(
+                    child: SizedBox(
+                      width: 1440,
+                      height: 980,
+                      child: NarrativeOverviewWorkspace(readModel: readModel),
+                    ),
+                  ),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pump(const Duration(milliseconds: 100));
+
+      final screenshotFile = File(
+        '../../reports/narrativeStudio/ui/screenshots/'
+        'ns_home_07_overview_structure_inspector.png',
+      );
+      screenshotFile.parent.createSync(recursive: true);
+      await expectLater(
+        find.byKey(const ValueKey('ns-home-07-screenshot-root')),
+        matchesGoldenFile(screenshotFile.absolute.path),
+      );
+
+      expect(screenshotFile.existsSync(), isTrue);
+    },
+  );
 }

 const _screenshotFontFamily = 'NsHome04ScreenshotFont';
@@ -709,6 +955,41 @@ Finder _textInModule(String moduleId, String text) {
   );
 }

+Finder _textInStructureInspector(String text) {
+  return find.descendant(
+    of: find.byKey(
+      const ValueKey('narrative-overview-structure-inspector'),
+    ),
+    matching: find.text(text),
+  );
+}
+
+Finder _textInStructureCounter(String metricId, String text) {
+  return find.descendant(
+    of: find.byKey(ValueKey('narrative-overview-structure-counter-$metricId')),
+    matching: find.text(text),
+  );
+}
+
+Finder _textInStructureEditorial(String slot, String text) {
+  return find.descendant(
+    of: find.byKey(ValueKey('narrative-overview-structure-editorial-$slot')),
+    matching: find.text(text),
+  );
+}
+
+NarrativeValidationDiagnostic _diagnostic(
+  NarrativeValidationSeverity severity,
+) {
+  return NarrativeValidationDiagnostic(
+    severity: severity,
+    kind: NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource,
+    message: 'Test diagnostic',
+    path: 'scenarios/test_global_story',
+    scenarioId: 'test_global_story',
+  );
+}
+
 Future<void> _pumpOverview(
   WidgetTester tester,
   NarrativeOverviewReadModel readModel, {
```

### 19.5 Vérifications relancées

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
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
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +22: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
Analyzing 4 items...

No issues found! (ran in 2.2s)
```

### 19.6 Confirmation screenshot

Commande :

```bash
file reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png
```

Sortie :

```text
reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png: PNG image data, 1440 x 980, 8-bit/color RGBA, non-interlaced
```

Commande :

```bash
stat -f '%Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_07_overview_structure_inspector.png
```

Sortie :

```text
May 27 02:46:03 2026 182709
```

### 19.7 Confirmation de non-modification code/test pendant le bis

Pendant NS-HOME-07-bis, aucun fichier `packages/` n’a été modifié.

Le seul fichier modifié par le bis est :

```text
reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
```
