# NS-HOME-08 — Narrative Overview Empty States / Footer Metadata V0

## 1. Résumé exécutif

NS-HOME-08 harmonise les zones indisponibles de la page `Narrative Studio / Aperçu` sans inventer de données.

Le lot ajoute :

- une section `Données à venir` branchée sur `readModel.metrics.facts`, `readModel.recentActivity`, `readModel.notifications` et `readModel.footer` ;
- un footer metadata V0 affichant le projet réel et des états `non définie` pour locale/version ;
- des tests widget couvrant Facts, activité récente, notifications, footer, absence de faux historique, absence de `FR` / `v0.3.0` et absence de données Selbrume ;
- un screenshot Visual Gate à `1600 x 1800`.

Le lot ne modifie pas `NarrativeOverviewReadModel`, ne crée aucune donnée métier, ne touche pas `map_core`, `map_runtime`, `map_gameplay` ni `map_battle`.

## 2. Rappel du scope NS-HOME-08

Objectif retenu :

- remplacer le bloc textuel `V0 volontairement limitée` par une section d'empty states plus claire ;
- afficher Facts comme `Nécessite un modèle` ;
- afficher `Activité récente` et `Notifications` comme `Hors scope V0` ;
- afficher `Locale` et `Version` comme `Non définie` ;
- ajouter un footer sobre `Projet / Locale / Version`.

Non-objectifs respectés :

- pas d'activité récente réelle ;
- pas de notifications réelles ;
- pas de registre Facts ;
- pas de tags ou description globale inventés ;
- pas de top bar/sidebar finale ;
- pas de changement de read model ;
- pas de runtime, gameplay, battle ou `map_core`.

## 3. Fichiers créés / modifiés

Fichiers créés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart`
- `reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png`
- `reports/narrativeStudio/ui/ns_home_08_narrative_overview_empty_states_footer.md`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`

Fichiers explicitement non modifiés :

- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- `packages/map_core/**`
- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`

## 4. UI créée

La nouvelle UI ajoute deux blocs :

### Données à venir

Section de cartes compactes, sombre, avec accents par disponibilité :

- `Facts` : `Nécessite un modèle`
- `Activité récente` : `Hors scope V0`
- `Notifications` : `Hors scope V0`
- `Locale` : `Non définie`
- `Version` : `Non définie`

La section est volontairement informative et non alarmiste : elle clarifie le périmètre V0 sans ressembler à une erreur runtime.

### Footer metadata

Footer discret :

- `Projet : <projectName réel>`
- `Locale : non définie`
- `Version : non définie`

Il ne hardcode ni `FR`, ni `v0.3.0`, ni une version applicative arbitraire.

## 5. Mapping Empty States / Footer → read model

| Zone UI | Source read model | Rendu V0 |
|---|---|---|
| Facts | `readModel.metrics.facts` | `Nécessite un modèle` |
| Activité récente | `readModel.recentActivity` | `Hors scope V0` |
| Notifications | `readModel.notifications` | `Hors scope V0` |
| Locale | `readModel.footer.locale` | `Non définie` |
| Version | `readModel.footer.version` | `Non définie` |
| Projet footer | `readModel.projectName` + `readModel.footer.project.label` | nom projet réel |

Les widgets ne lisent pas le manifest directement et ne recalculent aucun compteur.

## 6. Gestion des états outOfScope / needsModel / unavailable

Décisions UI :

- `needsModel` devient `Nécessite un modèle` : utilisé pour `Facts`.
- `outOfScope` devient `Hors scope V0` : utilisé pour activité récente et notifications.
- `unavailable` côté locale/version devient `Non définie`, car le footer doit rester lisible et non anxiogène.
- aucune disponibilité absente n'est transformée en `0`.
- aucune zone indisponible n'est rendue comme une donnée réelle.

Le panneau `Structure narrative` garde ses empty states existants :

- `Description non disponible en V0.`
- `Tags non disponibles en V0.`
- `Facts` reste `Nécessite un modèle` dans les compteurs structurels.

## 7. Ce qui reste volontairement hors scope

Hors scope NS-HOME-08 :

- journal d'activité authoring réel ;
- centre de notifications ;
- registre de tags ;
- description narrative globale persistée ;
- modèle Facts ;
- locale projet persistée ;
- version projet/app fiable ;
- top bar finale ;
- sidebar finale ;
- édition de données ;
- provider, repository ou lecture disque.

## 8. Tests ajoutés / modifiés

Tests modifiés :

- `NarrativeOverviewWorkspace renders a minimal authoring overview from the read model`
- `NarrativeOverviewWorkspace does not present unavailable modules as real data`

Test ajouté :

- `NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata`

Test screenshot ajouté :

- `NarrativeOverviewWorkspace captures empty states and footer screenshot when requested`

Les tests vérifient :

- présence de `Données à venir` ;
- présence des états Facts / Activité / Notifications / Locale / Version ;
- absence de faux items d'activité ;
- absence de faux badge notification ;
- footer rendu ;
- footer alimenté par `test_project` ;
- absence de `FR` et `v0.3.0` ;
- absence de `Selbrume`, `Port Selbrume`, `Mystère` ;
- absence des chiffres de l'image `42`, `1 236`, `1236`, `24`, `12`.

## 9. Visual Gate

Screenshot produit :

```text
reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png
```

Méthode :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --dart-define=NS_HOME_08_CAPTURE_SCREENSHOT=true --update-goldens
```

Caractéristiques du screenshot :

```text
PNG image data, 1600 x 1800, 8-bit/color RGBA, non-interlaced
Taille : 335279 octets
```

Ce qui correspond à l'image cible :

- page sombre, dense, orientée outil créateur ;
- KPI, Histoire principale, Modules narratifs et Structure narrative restent visibles ;
- zone basse plus propre qu'un simple texte provisoire ;
- footer discret `Projet / Locale / Version`.

Ce qui ne correspond pas encore :

- pas de top bar finale ;
- pas de sidebar finale ;
- pas d'activité récente réelle ;
- pas de tags ou description globale réels ;
- proportions encore V0, pas pixel-perfect.

Ce qui est volontairement hors scope :

- inventer des activités récentes ;
- inventer des notifications ;
- afficher `FR` ou `v0.3.0` sans source ;
- transformer Facts/tags en données réelles.

Inspection visuelle :

- les empty states sont lisibles ;
- Facts / Activité récente / Notifications ne sont pas présentés comme réels ;
- Locale / Version sont explicitement `Non définie` ;
- le footer est discret et ne ressemble pas à une sauvegarde runtime ;
- le screenshot initial à `1600 x 1400` ne montrait pas le footer ; la capture a été corrigée en `1600 x 1800`.

## 10. Commandes exécutées

### Git initial

```bash
git branch --show-current
```

Sortie :

```text
main
```

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

```bash
git diff --name-only
```

Sortie :

```text
Sortie : <vide>
```

### TDD RED

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie pertinente :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
Bad state: No element
00:01 +0 -1: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model [E]
00:01 +0 -2: NarrativeOverviewWorkspace does not present unavailable modules as real data [E]
00:01 +0 -3: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata [E]
00:03 +19 -3: Some tests failed.
```

### Formatage ciblé

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_empty_states.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
Formatted 3 files (0 changed) in 0.02 seconds.
```

### Tests ciblés workspace

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:01 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +5: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +6: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +7: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +8: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +9: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +10: NarrativeOverviewWorkspace module cards consume read model values
00:01 +11: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +12: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +13: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:02 +14: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +15: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +16: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +17: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +18: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +19: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +20: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +21: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +22: All tests passed!
```

### Tests ciblés workspace + navigation

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:01 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI cards consume read model values
00:01 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace module cards consume read model values
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:02 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:02 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +24: All tests passed!
```

### Screenshot

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --dart-define=NS_HOME_08_CAPTURE_SCREENSHOT=true --update-goldens
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:01 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +5: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +6: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +7: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +8: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +9: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +10: NarrativeOverviewWorkspace module cards consume read model values
00:01 +11: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +12: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +13: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:02 +14: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +15: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +16: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +17: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +18: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +19: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +20: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +21: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +22: All tests passed!
```

### Screenshot vérifié sans mise à jour

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --dart-define=NS_HOME_08_CAPTURE_SCREENSHOT=true
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:01 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:01 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +5: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +6: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +7: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +8: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +9: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +10: NarrativeOverviewWorkspace module cards consume read model values
00:01 +11: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +12: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:02 +13: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:02 +14: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +15: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +16: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +17: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +18: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +19: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +20: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +21: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +22: All tests passed!
```

### Flutter analyze global

```bash
cd packages/map_editor && flutter analyze
```

Résultat : échec global dû à dette préexistante hors lot.

Extrait pertinent :

```text
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
348 issues found. (ran in 3.4s)
```

Ces erreurs ne concernent pas les fichiers NS-HOME-08.

### Flutter analyze ciblé

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_empty_states.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
No issues found! (ran in 1.2s)
```

### Git diff check

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 11. Résultats des tests

Résultat principal :

```text
flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:02 +24: All tests passed!
```

Résultat screenshot :

```text
flutter test test/ui/canvas/narrative_overview_workspace_test.dart --dart-define=NS_HOME_08_CAPTURE_SCREENSHOT=true
00:02 +22: All tests passed!
```

## 12. Résultats analyze

`flutter analyze` global échoue sur dette hors lot déjà présente autour de Pokémon SDK / Pokédex.

Analyse ciblée des fichiers NS-HOME-08 :

```text
No issues found! (ran in 1.2s)
```

Conclusion : NS-HOME-08 n'introduit pas d'erreur d'analyse sur les fichiers créés ou modifiés.

## 13. Limites

Limites assumées :

- locale/version restent affichées comme `non définie` faute de source métier fiable ;
- l'activité récente reste une zone indisponible, pas un feed ;
- les notifications restent indisponibles, sans badge ;
- Facts reste une promesse de modèle futur ;
- le screenshot est un screenshot widget, pas encore le shell complet top bar/sidebar.

## 14. Prochain lot recommandé

Prochain lot exact recommandé :

```text
NS-HOME-09 — Narrative Overview Responsive Polish / Full Shell Visual Gate V0
```

Justification :

La page contient maintenant les briques principales fiables : KPI, Histoire principale, Modules narratifs, Structure narrative, Empty states, Footer. Le prochain lot devrait vérifier et polir l'ensemble comme écran complet : densité, scroll, responsive, overflow, cohérence avec le shell existant et screenshot plus proche de l'écran final.

## 15. Evidence Pack

### Contenu complet du fichier créé `narrative_overview_empty_states.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Section V0 qui rend explicites les zones encore indisponibles.
///
/// Les messages viennent des états du read model afin d'éviter toute activité,
/// notification ou donnée de lore inventée par l'UI.
class NarrativeOverviewUnavailableDataSection extends StatelessWidget {
  const NarrativeOverviewUnavailableDataSection({
    super.key,
    required this.facts,
    required this.recentActivity,
    required this.notifications,
    required this.footer,
  });

  final NarrativeMetricSummary facts;
  final NarrativeOverviewFeatureSummary recentActivity;
  final NarrativeOverviewFeatureSummary notifications;
  final NarrativeOverviewFooterSummary footer;

  @override
  Widget build(BuildContext context) {
    final items = <_UnavailableDataItem>[
      _UnavailableDataItem(
        slot: 'facts',
        label: facts.label,
        value: _availabilityTitle(facts.availability),
        detail: 'Registre de connaissances à définir avant affichage.',
        availability: facts.availability,
        icon: CupertinoIcons.book_fill,
      ),
      _UnavailableDataItem(
        slot: recentActivity.id,
        label: recentActivity.label,
        value: _availabilityTitle(recentActivity.availability),
        detail: recentActivity.message,
        availability: recentActivity.availability,
        icon: CupertinoIcons.clock,
      ),
      _UnavailableDataItem(
        slot: notifications.id,
        label: notifications.label,
        value: _availabilityTitle(notifications.availability),
        detail: notifications.message,
        availability: notifications.availability,
        icon: CupertinoIcons.bell,
      ),
      _UnavailableDataItem(
        slot: footer.locale.id,
        label: footer.locale.label,
        value: 'Non définie',
        detail: footer.locale.unavailableMessage,
        availability: footer.locale.availability,
        icon: CupertinoIcons.globe,
      ),
      _UnavailableDataItem(
        slot: footer.version.id,
        label: footer.version.label,
        value: 'Non définie',
        detail: footer.version.unavailableMessage,
        availability: footer.version.availability,
        icon: CupertinoIcons.info_circle,
      ),
    ];

    return Container(
      key: const ValueKey('narrative-overview-empty-states-section'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.accentPrimary.withValues(alpha: 0.18),
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données à venir',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ces zones restent visibles pour clarifier le périmètre V0, sans inventer de données.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final maxWidth = constraints.maxWidth;
              final columns = switch (maxWidth) {
                >= 960 => 3,
                >= 620 => 2,
                _ => 1,
              };
              final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: cardWidth,
                      child: _UnavailableDataTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Footer metadata sobre pour l'overview V0.
class NarrativeOverviewFooter extends StatelessWidget {
  const NarrativeOverviewFooter({
    super.key,
    required this.projectName,
    required this.footer,
  });

  final String projectName;
  final NarrativeOverviewFooterSummary footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('narrative-overview-footer'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.subtleSeparator(context).withValues(alpha: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FooterMetadataItem(
            slot: 'project',
            label: footer.project.label,
            value: projectName,
          ),
          _FooterMetadataItem(
            slot: 'locale',
            label: footer.locale.label,
            value: 'non définie',
          ),
          _FooterMetadataItem(
            slot: 'version',
            label: footer.version.label,
            value: 'non définie',
          ),
        ],
      ),
    );
  }
}

class _UnavailableDataTile extends StatelessWidget {
  const _UnavailableDataTile({required this.item});

  final _UnavailableDataItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, item.availability);
    return Container(
      key: ValueKey('narrative-overview-empty-state-${item.slot}'),
      constraints: const BoxConstraints(minHeight: 126),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: accent, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _UnavailableDataPill(label: item.value, accent: accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableDataPill extends StatelessWidget {
  const _UnavailableDataPill({
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
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FooterMetadataItem extends StatelessWidget {
  const _FooterMetadataItem({
    required this.slot,
    required this.label,
    required this.value,
  });

  final String slot;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('narrative-overview-footer-$slot'),
      constraints: const BoxConstraints(minHeight: 24),
      child: Text(
        '$label : $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _UnavailableDataItem {
  const _UnavailableDataItem({
    required this.slot,
    required this.label,
    required this.value,
    required this.detail,
    required this.availability,
    required this.icon,
  });

  final String slot;
  final String label;
  final String value;
  final String detail;
  final NarrativeOverviewAvailability availability;
  final IconData icon;
}

String _availabilityTitle(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => 'Disponible',
    NarrativeOverviewAvailability.empty => 'Vide',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
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
```

### Hunks complets `narrative_overview_workspace.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart b/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
index 4e5b00d7..72b1b0b8 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
@@ -2,6 +2,7 @@ import 'package:flutter/cupertino.dart';
 
 import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
 import '../shared/cupertino_editor_widgets.dart';
+import 'narrative_overview_empty_states.dart';
 import 'narrative_overview_structure_inspector.dart';
 
 /// Shell V0 de la page "Aperçu" du Narrative Studio.
@@ -125,21 +126,16 @@ class _OverviewMainColumn extends StatelessWidget {
         const SizedBox(height: 12),
         _ModuleCardsSection(modules: readModel.modules),
         const SizedBox(height: 12),
-        _OverviewSection(
-          title: 'V0 volontairement limitée',
-          children: [
-            const Text(
-              'Les sections détaillées seront construites dans les lots suivants.',
-            ),
-            const SizedBox(height: 6),
-            const Text(
-              'Aucun compteur fake, aucune activité récente inventée, aucune notification simulée.',
-            ),
-            const SizedBox(height: 6),
-            _MetricLine(metric: readModel.metrics.facts),
-            _FeatureLine(feature: readModel.recentActivity),
-            _FeatureLine(feature: readModel.notifications),
-          ],
+        NarrativeOverviewUnavailableDataSection(
+          facts: readModel.metrics.facts,
+          recentActivity: readModel.recentActivity,
+          notifications: readModel.notifications,
+          footer: readModel.footer,
+        ),
+        const SizedBox(height: 12),
+        NarrativeOverviewFooter(
+          projectName: readModel.projectName,
+          footer: readModel.footer,
         ),
       ],
     );
@@ -1046,29 +1042,6 @@ class _OverviewSection extends StatelessWidget {
   }
 }
 
-class _MetricLine extends StatelessWidget {
-  const _MetricLine({required this.metric});
-
-  final NarrativeMetricSummary metric;
-
-  @override
-  Widget build(BuildContext context) {
-    return Text('${metric.label} : ${_metricValue(metric)}');
-  }
-}
-
-class _FeatureLine extends StatelessWidget {
-  const _FeatureLine({required this.feature});
-
-  final NarrativeOverviewFeatureSummary feature;
-
-  @override
-  Widget build(BuildContext context) {
-    return Text(
-        '${feature.label} : ${_availabilityValue(feature.availability)}');
-  }
-}
-
 class _OverviewLine extends StatelessWidget {
   const _OverviewLine({
     required this.label,
@@ -1096,15 +1069,6 @@ String _metricCardValue(NarrativeMetricSummary metric) {
   };
 }
 
-String _metricValue(NarrativeMetricSummary metric) {
-  return switch (metric.availability) {
-    NarrativeOverviewAvailability.available ||
-    NarrativeOverviewAvailability.empty =>
-      '${metric.count ?? 0}',
-    _ => _availabilityValue(metric.availability),
-  };
-}
-
 String _metricSupportLabel(NarrativeMetricSummary metric) {
   return switch (metric.availability) {
     NarrativeOverviewAvailability.available => 'Disponible',
@@ -1140,17 +1104,6 @@ String _moduleSupportLabel(NarrativeModuleSummary module) {
   };
 }
 
-String _availabilityValue(NarrativeOverviewAvailability availability) {
-  return switch (availability) {
-    NarrativeOverviewAvailability.available => 'disponible',
-    NarrativeOverviewAvailability.empty => '0',
-    NarrativeOverviewAvailability.unavailable => 'indisponible',
-    NarrativeOverviewAvailability.notEvaluated => 'non évalué',
-    NarrativeOverviewAvailability.outOfScope => 'hors scope V0',
-    NarrativeOverviewAvailability.needsModel => 'nécessite un modèle',
-  };
-}
-
 Color _availabilityAccent(
   BuildContext context,
   NarrativeOverviewAvailability availability,
```

### Hunks complets `narrative_overview_workspace_test.dart`

```diff
diff --git a/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart b/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
index 2725c683..0e383685 100644
--- a/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
+++ b/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
@@ -53,18 +53,15 @@ void main() {
         );
       }
       await tester.scrollUntilVisible(
-        find.textContaining(
-          'Les sections détaillées seront construites dans les lots suivants.',
+        find.byKey(
+          const ValueKey('narrative-overview-empty-states-section'),
           skipOffstage: false,
         ),
         320,
       );
       await tester.pump();
       expect(
-        find.textContaining(
-          'Les sections détaillées seront construites dans les lots suivants.',
-          skipOffstage: false,
-        ),
+        find.text('Données à venir', skipOffstage: false),
         findsOneWidget,
       );
     },
@@ -89,32 +86,117 @@ void main() {
         findsOneWidget,
       );
       await tester.scrollUntilVisible(
-        find.textContaining('Activité récente : hors scope V0',
-            skipOffstage: false),
+        find.byKey(
+          const ValueKey('narrative-overview-empty-states-section'),
+          skipOffstage: false,
+        ),
         320,
       );
       await tester.pump();
       expect(
-        find.textContaining('Facts : nécessite un modèle', skipOffstage: false),
+        _textInEmptyState('facts', 'Nécessite un modèle'),
+        findsOneWidget,
+      );
+      expect(
+        _textInEmptyState('recent_activity', 'Hors scope V0'),
         findsOneWidget,
       );
       expect(
-        find.textContaining(
-          'Activité récente : hors scope V0',
+        _textInEmptyState('notifications', 'Hors scope V0'),
+        findsOneWidget,
+      );
+
+      expect(find.textContaining('Selbrume'), findsNothing);
+      expect(find.textContaining('La brume du phare'), findsNothing);
+      expect(find.text('42'), findsNothing);
+      expect(find.text('1 236'), findsNothing);
+      expect(find.text('1236'), findsNothing);
+      expect(find.text('24'), findsNothing);
+      expect(find.text('12'), findsNothing);
+    },
+  );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject('test_project'),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 1180);
+
+      await tester.scrollUntilVisible(
+        find.byKey(
+          const ValueKey('narrative-overview-empty-states-section'),
           skipOffstage: false,
         ),
+        360,
+      );
+      await tester.pump();
+
+      expect(find.text('Données à venir', skipOffstage: false), findsOneWidget);
+      expect(_textInEmptyState('facts', 'Facts'), findsOneWidget);
+      expect(_textInEmptyState('facts', 'Nécessite un modèle'), findsOneWidget);
+      expect(
+        _textInEmptyState(
+          'facts',
+          'Registre de connaissances à définir avant affichage.',
+        ),
+        findsOneWidget,
+      );
+      expect(
+        _textInEmptyState('recent_activity', 'Activité récente'),
         findsOneWidget,
       );
       expect(
-        find.textContaining(
-          'Notifications : hors scope V0',
+        _textInEmptyState('recent_activity', 'Hors scope V0'),
+        findsOneWidget,
+      );
+      expect(
+        _textInEmptyState('notifications', 'Notifications'),
+        findsOneWidget,
+      );
+      expect(
+        _textInEmptyState('notifications', 'Hors scope V0'),
+        findsOneWidget,
+      );
+      expect(_textInEmptyState('footer_locale', 'Locale'), findsOneWidget);
+      expect(_textInEmptyState('footer_locale', 'Non définie'), findsOneWidget);
+      expect(_textInEmptyState('footer_version', 'Version'), findsOneWidget);
+      expect(
+        _textInEmptyState('footer_version', 'Non définie'),
+        findsOneWidget,
+      );
+
+      await tester.scrollUntilVisible(
+        find.byKey(
+          const ValueKey('narrative-overview-footer'),
           skipOffstage: false,
         ),
-        findsOneWidget,
+        320,
       );
+      await tester.pump();
 
+      expect(_textInFooter('project', 'Projet : test_project'), findsOneWidget);
+      expect(_textInFooter('locale', 'Locale : non définie'), findsOneWidget);
+      expect(_textInFooter('version', 'Version : non définie'), findsOneWidget);
+
+      for (final fakeActivity in <String>[
+        'Cinématique modifiée',
+        'Dialogue ajouté',
+        'Chapitre édité',
+        'Problème résolu',
+        'Fact créé',
+        'Il y a 15 min',
+        'il y a 15 min',
+      ]) {
+        expect(find.textContaining(fakeActivity), findsNothing);
+      }
+      expect(find.text('FR'), findsNothing);
+      expect(find.text('v0.3.0'), findsNothing);
       expect(find.textContaining('Selbrume'), findsNothing);
-      expect(find.textContaining('La brume du phare'), findsNothing);
+      expect(find.textContaining('Port Selbrume'), findsNothing);
+      expect(find.textContaining('Mystère'), findsNothing);
       expect(find.text('42'), findsNothing);
       expect(find.text('1 236'), findsNothing);
       expect(find.text('1236'), findsNothing);
@@ -922,6 +1004,80 @@ void main() {
       expect(screenshotFile.existsSync(), isTrue);
     },
   );
+
+  testWidgets(
+    'NarrativeOverviewWorkspace captures empty states and footer screenshot when requested',
+    (tester) async {
+      if (!const bool.fromEnvironment('NS_HOME_08_CAPTURE_SCREENSHOT')) {
+        return;
+      }
+
+      await _loadScreenshotFont();
+      tester.view.physicalSize = const Size(1600, 1800);
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
+                key: const ValueKey('ns-home-08-screenshot-root'),
+                color: const Color(0xFF07111F),
+                child: DefaultTextStyle.merge(
+                  style: const TextStyle(fontFamily: _screenshotFontFamily),
+                  child: Center(
+                    child: SizedBox(
+                      width: 1600,
+                      height: 1800,
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
+        'ns_home_08_overview_empty_states_footer.png',
+      );
+      screenshotFile.parent.createSync(recursive: true);
+      await expectLater(
+        find.byKey(const ValueKey('ns-home-08-screenshot-root')),
+        matchesGoldenFile(screenshotFile.absolute.path),
+      );
+
+      expect(screenshotFile.existsSync(), isTrue);
+    },
+  );
 }
 
 const _screenshotFontFamily = 'NsHome04ScreenshotFont';
@@ -978,6 +1134,20 @@ Finder _textInStructureEditorial(String slot, String text) {
   );
 }
 
+Finder _textInEmptyState(String slot, String text) {
+  return find.descendant(
+    of: find.byKey(ValueKey('narrative-overview-empty-state-$slot')),
+    matching: find.text(text),
+  );
+}
+
+Finder _textInFooter(String slot, String text) {
+  return find.descendant(
+    of: find.byKey(ValueKey('narrative-overview-footer-$slot')),
+    matching: find.text(text),
+  );
+}
+
 NarrativeValidationDiagnostic _diagnostic(
   NarrativeValidationSeverity severity,
 ) {
```

### Screenshot

```bash
file reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png
stat -f '%Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png
```

Sortie :

```text
reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png: PNG image data, 1600 x 1800, 8-bit/color RGBA, non-interlaced
May 27 03:13:27 2026 335279
```

### Git observé avant insertion de cette section de rapport

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
?? reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png
```

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/narrative_overview_workspace.dart    |  69 ++-----
 .../canvas/narrative_overview_workspace_test.dart  | 200 +++++++++++++++++++--
 2 files changed, 196 insertions(+), 73 deletions(-)
```

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Note : les fichiers non trackés ne sont pas listés par `git diff --name-only`; leur contenu est donc inclus dans ce rapport.

### Git final réellement capturé après création du rapport

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
?? reports/narrativeStudio/ui/ns_home_08_narrative_overview_empty_states_footer.md
?? reports/narrativeStudio/ui/screenshots/ns_home_08_overview_empty_states_footer.png
```

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/narrative_overview_workspace.dart    |  69 ++-----
 .../canvas/narrative_overview_workspace_test.dart  | 200 +++++++++++++++++++--
 2 files changed, 196 insertions(+), 73 deletions(-)
```

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 16. Auto-review critique

- Ai-je harmonisé les empty states visibles ? Oui.
- Ai-je ajouté un footer metadata honnête ? Oui.
- Ai-je évité d'inventer Facts ? Oui.
- Ai-je évité d'inventer activité récente ? Oui.
- Ai-je évité d'inventer notifications ? Oui.
- Ai-je évité `FR` hardcodé ? Oui.
- Ai-je évité `v0.3.0` hardcodé ? Oui.
- Ai-je évité Selbrume / tags de l'image / chiffres de l'image ? Oui.
- Ai-je préservé KPI cards, Histoire principale, Modules narratifs et Structure narrative ? Oui.
- Ai-je évité de modifier `NarrativeOverviewReadModel` ? Oui.
- Ai-je évité runtime/gameplay/battle/map_core ? Oui.
- Ai-je produit un screenshot Visual Gate ? Oui.
- Ai-je corrigé un défaut visible du screenshot ? Oui, hauteur passée à `1600 x 1800` pour inclure le footer.
- Ai-je lancé les tests ciblés ? Oui.
- Ai-je lancé `flutter analyze` global et ciblé ? Oui.

## 17. Regard critique sur le prompt

Le prompt est bien borné : il empêche de transformer des absences de modèle en fausses données et force le Visual Gate. Le point le plus utile est la séparation nette entre "donnée indisponible" et "fonctionnalité oubliée" : cela oriente l'UI vers un dashboard auteur honnête.

Le seul point structurel à surveiller pour les prochains lots : le workspace commence à contenir beaucoup de blocs visuels. NS-HOME-08 extrait déjà les empty states/footer dans un fichier dédié ; le prochain lot de polish devrait continuer cette consolidation plutôt que tout remettre dans `narrative_overview_workspace.dart`.
