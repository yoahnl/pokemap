# NSC-70 — Recherche globale, palette de commandes et reprise de contexte

Date : 2026-07-21

Statut proposé : **DONE**

## Audit initial et verdict

Le Narrative Studio possédait déjà des routes typées, une résolution canonique
des dépendances et un contrat de retour sélection/scroll/focus. Il ne possédait
cependant aucun index de recherche projet, aucune palette clavier globale et le
contrat de retour ne transportait pas le zoom. Les diagnostics étaient
consultables uniquement dans le Validateur.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
manuelles Audit/Architecture, Core, UI Design System, Navigation, Tests et
Critique sont **GO**. La passe Build est **INCONCLUSIVE ENVIRONNEMENT** : le seul
SDK visible est Flutter 3.41.6 alors que la branche contient déjà deux API
Flutter 3.44 (`ScrollCacheExtent.pixels` et `onReorderItem`). Aucun lockfile n'a
été modifié ou rétrogradé pour contourner cette différence.

## Critères et preuves

| Critère NSC-70 | Preuve | Verdict |
|---|---|---|
| Recherche labels, IDs, tags et scopes | index Core immuable, normalisation des accents, filtres kind/map/storyline | GO |
| Recherche par consommateur | l'index de dépendances alimente `consumerLabels` | GO |
| Diagnostics ouvrables | rapport du Validateur injecté dans l'index et résolution typée existante réutilisée | GO |
| Fuzzy déterministe | scoring borné et tri stable kind/label/ID ; égalités testées | GO |
| Projet volumineux | fixture synthétique de 10 000 entrées, limite de résultats et révision obsolète testées | GO |
| Palette clavier | `⌘K`/`Ctrl+K`, flèches, Entrée, Échap et restauration du focus testés | GO |
| Commandes produit | navigation de tous les espaces, validation et sauvegarde lorsque disponibles | GO |
| Deep-link sûr | garde des changements, route interne exacte ou activation map non destructive | GO |
| Reprise de contexte | sélection et sous-route déjà typées ; scroll, focus et désormais zoom dans le snapshot | GO |
| Design system | panneau, recherche, cartes, badges, boutons et couleurs exclusivement DS/tokens | GO |

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_navigation_test.dart`

## Fichiers créés

- `packages/map_core/lib/src/read_models/narrative_global_search_index.dart`
- `packages/map_core/test/narrative_global_search_index_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart`
- `packages/map_editor/test/ui/canvas/narrative_command_palette_test.dart`
- `reports/narrativeStudio/completion/nsc_70_global_search_command_palette_evidence_pack.md`

Le contenu complet de chaque fichier créé est versionné dans le commit du lot.
Aucun artefact `build/`, `.dart_tool/`, cache ou fichier machine n'est inclus.

## Zones précises modifiées

### Core

- Nouveau read model indépendant de Flutter couvrant Maps, Storylines,
  Chapters, Steps, Scenes, Events, Cinematics, Dialogues, Facts, World Rules,
  médias et diagnostics.
- Réutilisation de `NarrativeDependencyIndex` pour les consommateurs et des
  `NarrativeDependencyNavigationIntent` pour éviter toute reconstruction d'ID
  depuis du texte UI.
- Réponse versionnée : une palette peut rejeter proprement un résultat calculé
  sur un index remplacé.

### Shell et palette

- Le shell produit expose la palette avec un bouton DS et `⌘K`/`Ctrl+K`.
- La palette consomme un index préconstruit, filtre sans I/O et délègue toutes
  les mutations/navigation au shell.
- L'Editor Shell met l'index en cache par snapshot projet/map/diagnostics,
  inclut le rapport du Validateur dès résolution et conserve les gardes de
  document/map déjà en place.
- Une cible interne ouvre la sélection exacte ; une cible map charge une
  snapshot, refuse un changement de map sale, active la map par le bridge
  existant et mémorise la route Narrative de retour.

### Reprise de contexte

- `NarrativeStudioReturnExpectation` transporte un zoom strictement positif
  et fini en plus du scroll et du focus.
- Un snapshot contenant uniquement un zoom déclenche bien une demande de
  restauration consommable ; les routes sans viewport n'en créent toujours
  pas.

## TDD, commandes et résultats exacts

### Rouge observé

```text
flutter test --no-pub test/ui/canvas/narrative_studio_navigation_test.dart
Compilation failed — No named parameter with the name 'zoom'.

flutter test --no-pub test/ui/canvas/narrative_command_palette_test.dart
Échec initial — API palette absente, puis défaut `entry!` sur une commande sans description.
```

### Vert final Core

```text
cd packages/map_core
/Users/karim/develop/flutter/bin/cache/dart-sdk/bin/dart test \
  test/narrative_global_search_index_test.dart
+3: All tests passed!

/Users/karim/develop/flutter/bin/cache/dart-sdk/bin/dart analyze \
  lib/src/read_models/narrative_global_search_index.dart lib/map_core.dart \
  test/narrative_global_search_index_test.dart
No issues found!
```

### Vert final Editor

```text
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter test --no-pub \
  test/ui/canvas/narrative_command_palette_test.dart \
  test/ui/canvas/narrative_studio_navigation_test.dart \
  test/ui/canvas/narrative_studio_shell_contract_test.dart
+19: All tests passed!

/Users/karim/develop/flutter/bin/flutter analyze --no-pub \
  lib/src/ui/editor_shell_page.dart \
  lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart \
  lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart \
  lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart \
  test/ui/canvas/narrative_command_palette_test.dart \
  test/ui/canvas/narrative_studio_navigation_test.dart
No issues found! (ran in 17.5s)
```

Une tentative groupée incluant
`narrative_overview_shell_navigation_test.dart` a compilé 19 tests du lot puis
a échoué au chargement de ce test large sur les deux API Flutter 3.44
préexistantes. La suite ciblée valide a été relancée séparément et passe.

## Build

```text
cd packages/map_editor
/Users/karim/develop/flutter/bin/flutter build macos --debug --no-pub
BUILD FAILED
```

Cause exacte, étrangère au diff NSC-70 : SDK Flutter 3.41.6 incapable de
compiler `ScrollCacheExtent.pixels` dans
`cinematics_library_workspace.dart` et `onReorderItem` dans
`storylines_structure_view.dart`, deux API déjà présentes au commit initial.
Le prochain environnement Flutter 3.44 doit relancer la même commande.

## Décisions, non-objectifs, risques et auto-critique

- La palette n'invente pas de commandes « Créer » ou « Prévisualiser » : elles
  seront ajoutées uniquement quand le shell possédera un callback global sûr.
- L'index n'effectue aucune lecture disque. Il indexe la map active non
  enregistrée et le manifeste courant ; les sources physiques des autres maps
  restent décrites par le manifeste et l'index de dépendances disponible.
- Les diagnostics apparaissent après résolution asynchrone du rapport ; l'index
  change alors de révision et les anciennes réponses deviennent explicitement
  obsolètes.
- Le fuzzy V1 est volontairement simple et déterministe. NSC-74 mesurera ses
  budgets réels avant toute sophistication algorithmique.
- Le zoom est désormais transporté et validé ; chaque canvas spécialisé reste
  responsable de l'appliquer et d'acquitter sa restauration.
- Les libellés de la palette sont encore en français dans ce lot. Leur
  externalisation appartient explicitement à NSC-73.
- Aucun pourcentage de performance non mesuré n'est revendiqué.

État Git initial : propre après `9db0c6c34` (`feat(cinematics): complete preview
runtime parity`). État avant commit : uniquement les fichiers NSC-70 listés
ci-dessus. `git diff --check` ne signale aucune erreur.
