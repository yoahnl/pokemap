# NSC-12 — Shell, Design System, Accessibility and Localization — Evidence Pack

Date : 2026-07-19

Lot : **NSC-12**

Phase : **Phase 1 — Fondations produit**
Verdict proposé : **DONE**, sous réserve du commit isolé documenté à la fin de ce rapport.

## 1. Résumé exécutif

NSC-12 consolide le shell partagé du Narrative Studio sans modifier les contrats narratifs, le runtime, la persistance ni les données Selbrume. Le lot apporte une localisation Flutter générée avec repli français, une navigation responsive réellement utilisable de 800 à 1920 px, un mode rail compact accessible, une barre d’actions horizontalement défilable sans perdre son alignement desktop, une réduction de mouvement explicite, un focus renforcé et la migration du périmètre Overview/Cinematics legacy vers les primitives et tokens du design system.

Les preuves ciblées sont vertes, l’analyse Flutter est verte et le build macOS debug propre est produit et signé. Une première suite complète a terminé à **+3499 -2** : les deux seules défaillances étaient les goldens Event Builder dont le texte shell volontairement localisé passait de « Events par map » à « Événements par map ». Le diff isolé ne contenait aucun changement géométrique. Les deux références ont été mises à jour manuellement et leur fichier de test repasse à **+26** ; la relance complète finale termine à **+3501**, zéro échec.

## 2. Audit du prompt et continuité

La demande utilisateur était de commencer la Phase 1 et de committer chaque lot. La roadmap active identifie NSC-12 après NSC-10 et NSC-11. Le scope a été challengé sur trois points :

1. La formulation « aucun nouveau primitive design system » était correcte, mais le golden a révélé une troncature réelle des KPI. L’alternative la plus petite a été d’étendre de façon additive le primitive existant `PokeMapMetricCard` avec des limites de lignes et une taille de valeur configurables, sans nouveau widget.
2. Une mise à jour automatique globale des goldens aurait été dangereuse. Toutes les assertions visuelles ont d’abord été lancées sans `--update-goldens`, puis chaque delta a été inspecté. Seules quatre références directement justifiées ont été actualisées.
3. Une traduction complète du Narrative Studio aurait mélangé NSC-12 et NSC-73. Le lot garde donc une propriété stricte : seules les chaînes possédées par le shell partagé sont localisées ; les libellés de contenu et les segments propres aux routes enfants restent hors scope.

Aucun lot `FG-*` de la roadmap des mécaniques n’est revendiqué : NSC-12 est un lot de shell éditeur, pas un ajout de mécanique de jeu.

## 3. Audit initial

### Contrats existants identifiés

- `NarrativeStudioProductShell` : composition du rail, de l’en-tête et du workspace.
- `NarrativeStudioProductNavigation` : neuf destinations et deux enfants Event.
- `NarrativeStudioWorkspacePage` : surfaces contexte/contenu/inspecteur et actions.
- `PokeMapSidebarItem`, `PokeMapMetricCard`, `PokeMapPanel`, `PokeMapCard` : primitives design system à conserver.
- `PokeMapColorTokens`, `context.pokeMapColors`, `PokeMapTone` : seule source autorisée de couleur UI.
- `NarrativeStudioRoutePresentation` : labels dynamiques/enfant volontairement non traduits dans ce lot.
- Tests de routes spécialisées, shell Event Builder et goldens 1672×941 actifs.

### Constats initiaux

- quatre imports directs du chrome legacy subsistaient dans Overview/Cinematics ;
- 117 références `EditorChrome` restaient dans le périmètre autorisé ;
- les petites largeurs produisaient des overflows de navigation et d’actions ;
- aucune infrastructure `gen-l10n` n’existait dans `map_editor` ;
- le rail compact ne garantissait ni tooltip, ni sémantique, ni activation clavier ;
- le zoom texte pouvait tronquer les KPI Overview ;
- l’espace d’actions n’était pas prouvé comme scrollable en compact et aligné à droite en desktop.

### Risques principaux

- dérive visuelle de l’Event Builder, qui constitue la référence produit ;
- rupture des neuf destinations ou des deux sous-routes Event ;
- introduction de couleurs locales ou de widgets ad hoc ;
- modification accidentelle des données Selbrume déjà présentes dans le working tree ;
- mise à jour de golden masquant un défaut géométrique ;
- génération l10n non reproductible après un `flutter clean`.

## 4. Scope confirmé

Inclus :

- shell, rail et actions responsives ;
- accessibilité clavier/sémantique/tooltip/focus ;
- réduction des animations selon les préférences système ;
- localisation FR/EN des chaînes possédées par le shell, avec FR par défaut ;
- migration design system strictement limitée à Overview et Cinematics legacy ;
- tests unitaires/widgets, matrice responsive, guardrails et goldens actifs.

Exclus et préservé :

- schéma, modèles narratifs, runtime et persistance ;
- contenu et seed Selbrume ;
- traduction des écrans enfants et des labels d’assets ;
- refonte visuelle de l’Event Builder ;
- ajout de primitive design system ;
- changement de mécanique de jeu.

## 5. État Git initial

État observé avant NSC-12, conservé comme travail utilisateur hors lot :

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

Le fichier lighthouse était déjà indexé avant le lot. Il ne fait pas partie du commit NSC-12.

## 6. Inventaire complet et zones modifiées

| Fichier | Zones/classes | Raison et impact |
|---|---|---|
| `packages/map_editor/l10n.yaml` | configuration gen-l10n | Définit ARB, classe, fichier de sortie et locale de repli. |
| `packages/map_editor/lib/l10n/app_fr.arb` | catalogue shell FR | Source canonique des chaînes possédées par le shell. |
| `packages/map_editor/lib/l10n/app_en.arb` | catalogue shell EN | Preuve de locale secondaire sans traduire le contenu dynamique. |
| `packages/map_editor/lib/l10n/app_localizations*.dart` | sources générées | Contrat Flutter reproductible via `flutter gen-l10n`. |
| `packages/map_editor/lib/l10n/l10n.dart` | extension `BuildContext` | Accès compact et repli FR explicite. |
| `packages/map_editor/lib/main.dart` | `MapEditorApp.build` | Branche les delegates/locales et retire le title hardcodé. |
| `packages/map_editor/pubspec.yaml` | dépendances Flutter, generate | Active `flutter_localizations` et la génération. |
| `packages/map_editor/pubspec.lock` | dépendances SDK l10n | Verrouille les dépendances induites. |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | header Narratif, `_NarrativeStudioSaveStatus` | Localise validation et état saved/dirty. |
| `.../narrative_studio_product_shell.dart` | `NarrativeStudioProductShell`, `_NarrativeStudioProductHeader` | Breakpoints exacts, titre/brand localisés, scrolling d’actions conservant l’alignement à droite. |
| `.../narrative_studio_product_navigation.dart` | `NarrativeStudioProductNavigation`, `_DestinationNavigationItem` | Rail compact à 72 px, labels localisés, navigation verticale scrollable, enfants Event accessibles. |
| `.../narrative_studio_workspace_page.dart` | `NarrativeStudioWorkspacePage.build` | Context/body/inspector restent lisibles à largeur compacte. |
| `.../pokemap_sidebar_item.dart` | `PokeMapSidebarItem`, état focus/hover | Variante collapsed additive, tooltip, Semantics, clavier Enter/Space, focus contraste élevé et mouvement réduit. |
| `.../pokemap_dashboard_primitives.dart` | `PokeMapMetricCard` | API additive `titleMaxLines`, `valueMaxLines`, `valueFontSize`; defaults rétrocompatibles. |
| `.../narrative_overview_workspace.dart` | cards résumé/module/story/KPI/sections | Remplacement du chrome legacy par tokens/primitives DS et correction de troncature KPI. |
| `.../narrative_overview_empty_states.dart` | états indisponibles/footer | Migration DS et couleurs sémantiques. |
| `.../narrative_overview_structure_inspector.dart` | identité, sections, chips, accents | Migration DS sans modifier le read model. |
| `.../narrative_workspace_canvas.dart` | `_CutsceneWorkspaceBody`, `_NarrativeListCard` | Derniers imports/références legacy du périmètre Cinematics. |
| `packages/map_editor/test/narrative_studio_localization_test.dart` | nouveaux tests l10n | FR par défaut, EN explicite, ownership des chaînes. |
| `.../pokemap_sidebar_item_test.dart` | tests collapsed/accessibilité | Positif, disabled, tooltip, clavier, Semantics, mouvement réduit. |
| `.../narrative_studio_responsive_accessibility_test.dart` | matrice 54 cas et assertions | 800–1920 px, trois hauteurs, échelles 1/1.5/2, scroll, focus, actions. |
| `.../narrative_overview_workspace_test.dart` | shell compact, KPI, alignement actions | Détecte overflows, ellipsis et régression d’alignement desktop. |
| `packages/map_editor/test/design_system_guardrail_test.dart` | ratchets chrome/couleur | Baselines du périmètre ramenées à zéro. |
| quatre PNG goldens listés ci-dessous | références 1672×941 | Deltas manuellement validés : migration DS ou chaîne shell localisée uniquement. |

Les chemins abrégés `...` du tableau correspondent tous à `packages/map_editor/lib/src/ui/canvas/narrative_studio/`, `packages/map_editor/lib/src/ui/design_system/` ou `packages/map_editor/test/ui/` comme indiqué par le nom de fichier. La liste Git exacte du commit reste non abrégée dans la section 12.

## 7. Tests créés ou modifiés

Couverture positive :

- rendu FR par défaut et EN explicite ;
- toutes les destinations atteignables ;
- mode compact à 800×650 et texte 200 % ;
- alignement desktop des actions ;
- KPI lisibles sur deux lignes ;
- routes Overview/Cinematics/Event identiques aux références approuvées.

Couverture négative et garde-fous :

- item disabled non activable au clavier ;
- aucune animation lorsque `disableAnimations` est actif ;
- aucune couleur directe ni import chrome legacy dans le périmètre ;
- aucune troncature KPI via `RenderParagraph.didExceedMaxLines` ;
- aucune perte de destination sous overflow ;
- aucun changement de géométrie Event Builder lors de la localisation.

Non-régression :

- defaults de `PokeMapMetricCard` préservent les autres consommateurs ;
- Dialogues, Cinematics library, Facts, World Rules, builder et Event V2/legacy restent couverts par leurs tests/goldens actifs.

## 8. Preuves RED → GREEN

- RED : `PokeMapSidebarItem` n’acceptait pas `collapsed` ; GREEN : widget, clavier, tooltip, sémantique et disabled couverts.
- RED : infrastructure l10n absente ; GREEN : ARB FR/EN, delegates, locale FR par défaut et génération reproductible.
- RED : overflow navigation 22 px et actions 1511 px dans les scénarios compacts ; GREEN : matrice responsive complète sans exception Flutter.
- RED : actions desktop déplacées, bord droit réel 1178.5 au lieu de 1648 ; GREEN : `ConstrainedBox(minWidth: viewport)` + `Row(mainAxisAlignment: end)`, tout en gardant le scroll compact.
- RED : KPI `Problèmes ouverts`, puis `Hors scope V0`, signalés comme tronqués ; GREEN : configuration additive du metric card et assertion `didExceedMaxLines == false`.
- RED : quatre imports chrome legacy et 117 références dans le périmètre ; GREEN : ratchets stricts à zéro.

## 9. Commandes et résultats exacts

### Format

```text
dart format --output=none --set-exit-if-changed lib test
=> exit non-zéro ; 102 fichiers historiques hors lot sont déjà non formatés. La commande ne les a pas écrits.
```

Puis format ciblé sur les 20 fichiers Dart NSC-12 :

```text
Formatted 20 files (0 changed) in 0.07 seconds.
```

### Tests ciblés

Suite ciblée shell/localisation/design system/routes :

```text
flutter test --concurrency=1 <12 fichiers ciblés NSC-12>
+255: All tests passed!
```

Revalidation visuelle après mise à jour contrôlée des quatre références :

```text
flutter test --concurrency=1   test/ui/canvas/event_builder_v2_product_route_test.dart   test/ui/canvas/narrative_studio_specialized_routes_test.dart   test/ui/canvas/narrative_studio_cinematics_route_test.dart
+115: All tests passed!
```

### Suite complète

Première exécution avant l’actualisation des deux références Event :

```text
flutter test --concurrency=1
+3499 -2: Some tests failed.
Failing tests:
  test/ui/canvas/event_builder_v2_product_route_test.dart:
    captures the full V2-only product shell at the north-star size
  test/ui/canvas/event_builder_v2_product_route_test.dart:
    captures the full legacy product shell at the north-star size
```

Qualification : liée au lot et exclusivement textuelle. Le diff isolé commun montre seulement « Events par map » → « Événements par map ». La première comparaison rapportait 0.03 %, 522 pixels ; le second pourcentage n’est pas repris car sa ligne a été tronquée dans le log, mais son image isolatedDiff avait le même SHA-256.

Relance complète finale :

```text
flutter test --concurrency=1
12:08 +3501: All tests passed!
```

### Analyse

```text
flutter analyze
Analyzing map_editor...
No issues found! (ran in 4.9s)
```

### Génération et build macOS

```text
flutter clean
=> exit 0

flutter pub get
Got dependencies!
37 packages have newer versions incompatible with dependency constraints.
=> exit 0

flutter gen-l10n
Because l10n.yaml exists, the options defined there will be used instead.
=> exit 0

flutter build macos --debug
=> artefact Debug produit ; avertissement actool préexistant :
The app icon set "AppIcon" has an unassigned child.
```

Validation de l’artefact :

```text
test -d build/macos/Build/Products/Debug/map_editor.app
=> BUILD_ARTIFACT_PRESENT

codesign --verify --deep --strict --verbose=2 build/macos/Build/Products/Debug/map_editor.app
=> valid on disk
=> satisfies its Designated Requirement

file build/macos/Build/Products/Debug/map_editor.app/Contents/MacOS/map_editor
=> Mach-O 64-bit executable arm64
```

### Hygiène

```text
git diff --check
=> exit 0, aucune sortie
```

## 10. Preuve golden

| Référence | Avant → après (octets) | SHA-256 après | Justification |
|---|---:|---|---|
| Event Builder V2 | 295086 → 295602 | `21686d23b0207a54e2760fbfb2ec1813f4c69c622cd9397055c28ab00ea5ee4d` | Accent français du seul label shell « Événements par map ». |
| Event Builder legacy | 241735 → 242255 | `88855044bdbc094fe6f94570e6f325e5d81488de40dbcc3e6e738535ece0baf8` | Même label shell, aucune géométrie modifiée. |
| Overview | 258515 → 247277 | `5fd46bda87c3a29ea65b15930dbac808a1a246f68525fb06ca938adcc7d0d4d2` | Migration DS, KPI non tronqués et actions réalignées. |
| Cinematics legacy | 189782 → 189222 | `e58891d566b5e46bd27db272c74727bb69e302b7e254e19cd8796b7ef4aaa4f8` | Migration du dernier chrome legacy autorisé. |

Avant toute mise à jour, Overview différait de 68.75 % (1 081 643 pixels) et Cinematics legacy de 15.20 % (239 217 pixels). Ces écarts correspondaient au remplacement attendu du chrome. L’examen initial a aussi détecté deux vraies régressions — actions desktop recentrées et KPI tronqués — qui ont été corrigées avant approbation des références.

## 11. Verdict des cinq passes obligatoires

| Passe | Verdict | Éléments vérifiés |
|---|---|---|
| Audit / Architecture | **PASS** | Scope NSC-12, frontières package, ownership l10n, géométrie Overview/Cinematics. Deux défauts réels ont été rejetés avant approbation des goldens. |
| Implémentation | **PASS** | Aucun contrat domain/runtime/persistence touché ; extension metric additive ; zéro primitive ad hoc. |
| Tests | **PASS** | Tests ciblés +255, visuels +115 et suite complète +3501 verts ; première suite complète expliquée et corrigée. |
| Build / Validation | **PASS avec warning connu** | Analyze vert, génération l10n, app macOS debug présente, codesign valide, arm64. |
| Critique finale | **PASS** | Aucun fichier Selbrume inclus, quatre goldens justifiés, pas de couleur locale ; suite complète et inventaire exact vérifiés. |

### Audit/Architecture détaillé

La passe Architecture a d’abord refusé l’état visuel où les actions Overview n’étaient plus alignées à droite et où deux libellés KPI étaient ellipsés. Après correction et relecture de l’extension `PokeMapMetricCard`, verdict **PASS / update-allowed** : API additive, defaults inchangés, autres consommateurs et goldens non concernés restés verts.

## 12. État Git final avant commit et isolement

Le working tree contient les 30 fichiers NSC-12 ci-dessus (rapport inclus) plus les changements Selbrume préexistants de la section 5. L’index préexistant du test lighthouse doit rester intact. Le commit est exécuté avec `git commit --only` et la liste exacte des seuls fichiers NSC-12, afin de ne pas capturer ce travail utilisateur.

Inventaire exact NSC-12 :

```text
packages/map_editor/l10n.yaml
packages/map_editor/lib/l10n/app_fr.arb
packages/map_editor/lib/l10n/app_en.arb
packages/map_editor/lib/l10n/app_localizations.dart
packages/map_editor/lib/l10n/app_localizations_fr.dart
packages/map_editor/lib/l10n/app_localizations_en.dart
packages/map_editor/lib/l10n/l10n.dart
packages/map_editor/pubspec.yaml
packages/map_editor/pubspec.lock
packages/map_editor/lib/main.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart
packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/narrative_studio_localization_test.dart
packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart
packages/map_editor/test/ui/canvas/narrative_studio_responsive_accessibility_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/design_system_guardrail_test.dart
packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png
packages/map_editor/test/goldens/narrative_studio/events/event_builder_legacy_full_product_route_1672x941.png
packages/map_editor/test/goldens/narrative_studio/overview/overview_full_product_route_1672x941.png
packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_legacy_full_product_route_1672x941.png
reports/narrativeStudio/completion/nsc_12_shell_design_system_accessibility_evidence_pack.md
```

État final attendu et contrôlé après le commit isolé : aucun fichier NSC-12 ne reste modifié. Les seuls changements encore présents sont ceux qui préexistaient au lot : les trois tests du host Selbrume, les deux tests runtime Selbrume, le test/outil de seed éditeur, `selbrume/project.json` et le rapport de réaudit gameplay. `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart` reste volontairement staged ; aucun de ces chemins n’appartient au commit NSC-12.

## 13. Limites et risques conservés

- La localisation couvre le shell partagé, pas tous les écrans enfants ; l’extension relève de NSC-73.
- Les labels dynamiques de projets/assets ne sont jamais traduits.
- Le warning actool de l’icône 1024×1024 reste hors scope.
- La suite complète du package dure environ douze minutes en séquentiel ; elle est néanmoins rejouée après stabilisation des goldens.
- Le mode compact privilégie l’accessibilité et le scroll explicite ; il ne redessine pas les workspaces spécialisés qui possèdent leur propre responsive.
- Aucun comportement runtime n’est revendiqué par ce lot UI.

## 14. Auto-critique finale

Points forts : tests RED utiles, goldens inspectés avant update, découverte de deux régressions que de simples snapshots auraient pu masquer, extension DS rétrocompatible et isolation Git stricte.

Points à surveiller : la surface de diff Overview est importante parce qu’elle retire un chrome historique dense ; les tests/goldens protègent le rendu mais une future extraction plus fine pourrait simplifier le fichier. La localisation partielle doit rester explicite pour éviter une interface artificiellement « moitié traduite » sans lot NSC-73. Le build prouve macOS arm64 uniquement ; les autres plateformes ne font pas partie du lot.

Aucun comportement mensonger n’a été identifié : les actions restent les actions existantes, les états disabled le restent, et aucune capacité narrative ou runtime fictive n’a été ajoutée.

## 15. Prochaine étape proposée

Après le commit isolé NSC-12, poursuivre la Phase 1 avec **NSC-13**, selon la roadmap active, dans un commit séparé. Cette proposition n’est pas implémentée dans le présent Evidence Pack.

## Annexe A — Contenu complet des fichiers créés


### `packages/map_editor/l10n.yaml`

```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
preferred-supported-locales:
  - fr
nullable-getter: true
format: true
```

### `packages/map_editor/lib/l10n/app_fr.arb`

```json
{
  "@@locale": "fr",
  "appTitle": "Éditeur de cartes RPG",
  "@appTitle": {"description": "Application window title."},
  "brandName": "PokeMap",
  "@brandName": {"description": "Product brand name."},
  "narrativeStudio": "Narrative Studio",
  "@narrativeStudio": {"description": "Narrative authoring studio name."},
  "beta": "beta",
  "@beta": {"description": "Beta release badge."},
  "back": "Retour",
  "@back": {"description": "Return navigation action."},
  "maps": "Maps",
  "@maps": {"description": "Map editor navigation destination."},
  "overview": "Aperçu",
  "@overview": {"description": "Narrative overview destination."},
  "storylines": "Storylines",
  "@storylines": {"description": "Storylines navigation destination."},
  "scenes": "Scènes",
  "@scenes": {"description": "Scenes navigation destination."},
  "events": "Événements",
  "@events": {"description": "Events navigation destination."},
  "cinematics": "Cinématiques",
  "@cinematics": {"description": "Cinematics navigation destination."},
  "dialogues": "Dialogues",
  "@dialogues": {"description": "Dialogues navigation destination."},
  "facts": "Facts",
  "@facts": {"description": "Facts navigation destination."},
  "worldRules": "Règles du monde",
  "@worldRules": {"description": "World rules navigation destination."},
  "validator": "Validateur",
  "@validator": {"description": "Narrative validator destination."},
  "eventBuilder": "Event Builder",
  "@eventBuilder": {"description": "Event Builder child destination."},
  "mapEvents": "Événements par map",
  "@mapEvents": {"description": "Map events child destination."},
  "shellSemantics": "PokeMap, Narrative Studio",
  "@shellSemantics": {"description": "Accessible product shell label."},
  "validate": "Valider",
  "@validate": {"description": "Project validation action."},
  "allChangesSaved": "Tous les changements enregistrés",
  "@allChangesSaved": {"description": "Saved project status."},
  "unsavedChanges": "Modifications non enregistrées",
  "@unsavedChanges": {"description": "Dirty project status."}
}
```

### `packages/map_editor/lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "appTitle": "RPG Map Editor",
  "@appTitle": {"description": "Application window title."},
  "brandName": "PokeMap",
  "@brandName": {"description": "Product brand name."},
  "narrativeStudio": "Narrative Studio",
  "@narrativeStudio": {"description": "Narrative authoring studio name."},
  "beta": "beta",
  "@beta": {"description": "Beta release badge."},
  "back": "Back",
  "@back": {"description": "Return navigation action."},
  "maps": "Maps",
  "@maps": {"description": "Map editor navigation destination."},
  "overview": "Overview",
  "@overview": {"description": "Narrative overview destination."},
  "storylines": "Storylines",
  "@storylines": {"description": "Storylines navigation destination."},
  "scenes": "Scenes",
  "@scenes": {"description": "Scenes navigation destination."},
  "events": "Events",
  "@events": {"description": "Events navigation destination."},
  "cinematics": "Cinematics",
  "@cinematics": {"description": "Cinematics navigation destination."},
  "dialogues": "Dialogues",
  "@dialogues": {"description": "Dialogues navigation destination."},
  "facts": "Facts",
  "@facts": {"description": "Facts navigation destination."},
  "worldRules": "World Rules",
  "@worldRules": {"description": "World rules navigation destination."},
  "validator": "Validator",
  "@validator": {"description": "Narrative validator destination."},
  "eventBuilder": "Event Builder",
  "@eventBuilder": {"description": "Event Builder child destination."},
  "mapEvents": "Map events",
  "@mapEvents": {"description": "Map events child destination."},
  "shellSemantics": "PokeMap, Narrative Studio",
  "@shellSemantics": {"description": "Accessible product shell label."},
  "validate": "Validate",
  "@validate": {"description": "Project validation action."},
  "allChangesSaved": "All changes saved",
  "@allChangesSaved": {"description": "Saved project status."},
  "unsavedChanges": "Unsaved changes",
  "@unsavedChanges": {"description": "Dirty project status."}
}
```

### `packages/map_editor/lib/l10n/app_localizations.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en')
  ];

  /// Application window title.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur de cartes RPG'**
  String get appTitle;

  /// Product brand name.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap'**
  String get brandName;

  /// Narrative authoring studio name.
  ///
  /// In fr, this message translates to:
  /// **'Narrative Studio'**
  String get narrativeStudio;

  /// Beta release badge.
  ///
  /// In fr, this message translates to:
  /// **'beta'**
  String get beta;

  /// Return navigation action.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// Map editor navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Maps'**
  String get maps;

  /// Narrative overview destination.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get overview;

  /// Storylines navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Storylines'**
  String get storylines;

  /// Scenes navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Scènes'**
  String get scenes;

  /// Events navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get events;

  /// Cinematics navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Cinématiques'**
  String get cinematics;

  /// Dialogues navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Dialogues'**
  String get dialogues;

  /// Facts navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Facts'**
  String get facts;

  /// World rules navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Règles du monde'**
  String get worldRules;

  /// Narrative validator destination.
  ///
  /// In fr, this message translates to:
  /// **'Validateur'**
  String get validator;

  /// Event Builder child destination.
  ///
  /// In fr, this message translates to:
  /// **'Event Builder'**
  String get eventBuilder;

  /// Map events child destination.
  ///
  /// In fr, this message translates to:
  /// **'Événements par map'**
  String get mapEvents;

  /// Accessible product shell label.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap, Narrative Studio'**
  String get shellSemantics;

  /// Project validation action.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Saved project status.
  ///
  /// In fr, this message translates to:
  /// **'Tous les changements enregistrés'**
  String get allChangesSaved;

  /// Dirty project status.
  ///
  /// In fr, this message translates to:
  /// **'Modifications non enregistrées'**
  String get unsavedChanges;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
```

### `packages/map_editor/lib/l10n/app_localizations_fr.dart`

```dart
// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Éditeur de cartes RPG';

  @override
  String get brandName => 'PokeMap';

  @override
  String get narrativeStudio => 'Narrative Studio';

  @override
  String get beta => 'beta';

  @override
  String get back => 'Retour';

  @override
  String get maps => 'Maps';

  @override
  String get overview => 'Aperçu';

  @override
  String get storylines => 'Storylines';

  @override
  String get scenes => 'Scènes';

  @override
  String get events => 'Événements';

  @override
  String get cinematics => 'Cinématiques';

  @override
  String get dialogues => 'Dialogues';

  @override
  String get facts => 'Facts';

  @override
  String get worldRules => 'Règles du monde';

  @override
  String get validator => 'Validateur';

  @override
  String get eventBuilder => 'Event Builder';

  @override
  String get mapEvents => 'Événements par map';

  @override
  String get shellSemantics => 'PokeMap, Narrative Studio';

  @override
  String get validate => 'Valider';

  @override
  String get allChangesSaved => 'Tous les changements enregistrés';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';
}
```

### `packages/map_editor/lib/l10n/app_localizations_en.dart`

```dart
// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RPG Map Editor';

  @override
  String get brandName => 'PokeMap';

  @override
  String get narrativeStudio => 'Narrative Studio';

  @override
  String get beta => 'beta';

  @override
  String get back => 'Back';

  @override
  String get maps => 'Maps';

  @override
  String get overview => 'Overview';

  @override
  String get storylines => 'Storylines';

  @override
  String get scenes => 'Scenes';

  @override
  String get events => 'Events';

  @override
  String get cinematics => 'Cinematics';

  @override
  String get dialogues => 'Dialogues';

  @override
  String get facts => 'Facts';

  @override
  String get worldRules => 'World Rules';

  @override
  String get validator => 'Validator';

  @override
  String get eventBuilder => 'Event Builder';

  @override
  String get mapEvents => 'Map events';

  @override
  String get shellSemantics => 'PokeMap, Narrative Studio';

  @override
  String get validate => 'Validate';

  @override
  String get allChangesSaved => 'All changes saved';

  @override
  String get unsavedChanges => 'Unsaved changes';
}
```

### `packages/map_editor/lib/l10n/l10n.dart`

```dart
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Resolves the generated shell translations without forcing legacy widget
/// harnesses to install localization delegates immediately.
///
/// French is the deterministic fallback because it is the existing product
/// language. Child-route and authored asset labels remain outside NSC-12.
extension PokeMapLocalizationsContext on BuildContext {
  AppLocalizations get pokeMapL10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('fr'));
}
```

### `packages/map_editor/test/narrative_studio_localization_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/l10n/l10n.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';

const _shellKeys = <String>{
  'appTitle',
  'brandName',
  'narrativeStudio',
  'beta',
  'back',
  'maps',
  'overview',
  'storylines',
  'scenes',
  'events',
  'cinematics',
  'dialogues',
  'facts',
  'worldRules',
  'validator',
  'eventBuilder',
  'mapEvents',
  'shellSemantics',
  'validate',
  'allChangesSaved',
  'unsavedChanges',
};

void main() {
  test('FR and EN ARB expose the same complete shell key set', () {
    final french = _messageKeys(File('lib/l10n/app_fr.arb'));
    final english = _messageKeys(File('lib/l10n/app_en.arb'));

    expect(french, _shellKeys);
    expect(english, _shellKeys);
    expect(
        AppLocalizations.supportedLocales, const [Locale('fr'), Locale('en')]);
  });

  testWidgets('shell resolves French and English rail labels', (tester) async {
    await _pumpLocalizedShell(tester, const Locale('fr'));
    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Événements'), findsOneWidget);
    expect(find.text('Événements par map'), findsOneWidget);

    await _pumpLocalizedShell(tester, const Locale('en'));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Map events'), findsOneWidget);
  });

  testWidgets('unsupported locale falls back to French', (tester) async {
    late String resolvedOverview;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            resolvedOverview = context.pokeMapL10n.overview;
            return Text(resolvedOverview);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(resolvedOverview, 'Aperçu');
    expect(find.text('Aperçu'), findsOneWidget);
  });

  test('shared shell source contains no product UI string literal', () {
    const paths = <String>[
      'lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart',
      'lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart',
    ];
    final patterns = <RegExp>[
      RegExp(r'''Text\(\s*['"]'''),
      RegExp(r'''\blabel:\s*['"]'''),
      RegExp(r'''\btooltip:\s*['"]'''),
      RegExp(r'''Semantics\([^)]*\blabel:\s*['"]''', dotAll: true),
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final pattern in patterns) {
        expect(
          pattern.hasMatch(source),
          isFalse,
          reason: '$path still owns a product literal matched by $pattern',
        );
      }
    }
  });
}

Set<String> _messageKeys(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json.keys
      .where((key) => key != '@@locale' && !key.startsWith('@'))
      .toSet();
}

Future<void> _pumpLocalizedShell(WidgetTester tester, Locale locale) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 941);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.events,
          selectedLocation: NarrativeStudioRouteLocation.events(),
          onSelectDestination: (_) {},
          onSelectLocation: (_) {},
          onOpenMaps: () {},
          workspace: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```
