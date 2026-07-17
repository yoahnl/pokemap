# Event Builder V2 — Phase K2-R Design QA

Date : 2026-07-17

Lot : `NS-EVENT-V2 Phase K2-R — route produit fidèle à la north star`

Statut de la roadmap : `K DONE / ACCEPTED`. Cette revue évalue le rendu
réellement monté par le produit ; la publication finale reste gouvernée par L.

## Cible comparée

- Source visuelle :
  `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png`
  — SHA-256 `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` ;
- Implémentation : vraie `EditorShellPage` → Narrative Studio → Events avec
  fixture V2-only et Event sélectionné `Rencontre rival au port` ;
- Viewport et état : desktop sombre, 1672 × 941, sans sidebars Map Editor ni
  sous-sidebar Narrative Studio imbriquée ;
- Capture normative :
  `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`
  — SHA-256 `8b45066cd7892479892668e09b8ffa02dc7cd21dc2a64e38ca7d2155b39778cf`.

## Preuves ouvertes et comparées

| Preuve | Dimensions | SHA-256 |
|---|---:|---|
| Capture produit | 1672 × 941 | `8b45066cd7892479892668e09b8ffa02dc7cd21dc2a64e38ca7d2155b39778cf` |
| Côte-à-côte référence / produit | 3344 × 941 | `92b4b077ddd45681d4bc6cea71fb7f5c64cb26593209a934c754e8ced2f48826` |
| Overlay 50 % | 1672 × 941 | `f13345c32a6966a76f5c56c0a47fc2a180311cfd7335f7ffd07ea63cc9dda5e5` |
| Focus header, navigation et liste | 702 × 941 | `2d6f0afaf7fcb57a26377a98caa3838a4acb14fd5dd0c58c7eff536f261b6c00` |
| Focus éditeur | 565 × 817 | `f4cc47afc2211d2ffe881f0393bc3fa9bf65630634b7ba0d4a431620de120ac1` |
| Focus inspecteur | 397 × 817 | `061ef6e06fe921cb5dacc46735e74ab8e83efa9a06ff5aea080de086ac3e0664` |

Chemins des preuves :

- `reports/narrativeStudio/events/phase_k_product_route_evidence/product_after_1672x941.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_1672x941.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_overlay_50.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/focus_header_navigation_list.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/focus_editor.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/focus_inspector.png`.

## Historique des corrections P0/P1/P2

- **P0 fermé — double chrome** : la vraie route Events V2 monte maintenant un
  shell dédié. L’explorer global, la toolbar Map Editor et la seconde navigation
  Narrative ne sont plus présents dans le viewport.
- **P0 fermé — largeur métier fausse** : la route teste maintenant le shell
  effectif et ses quatre panneaux au même viewport que la référence : navigation
  191, liste 266, bibliothèque 213, éditeur 565 et inspecteur 388 px.
- **P1 fermé — barre de contexte incomplète** : la barre affiche le projet,
  le fil `Narrative Studio / Event Builder`, les actions métier et trois
  boutons icônes bordés de 36 px. Ces trois fonctions futures sont désactivées
  plutôt que branchées sur des callbacks vides. Les actions vertes utilisent
  le traitement success outline du design system.
- **P1 fermé — ownership trompeur** : l’Event conserve seulement sa source,
  ses conditions et son comportement ; les résultats, conséquences et règles
  sont une projection explicitement en lecture seule de la Scene.
- **P2 fermé — densité/overflow** : le contenu critique reste dans le viewport
  normatif ; le gate étroit intervient avant les lectures et diagnostics à
  1280 px de zone Event.

## Revue des surfaces de fidélité

| Surface | Verdict | Observation fondée sur les preuves |
|---|---|---|
| Typographie | PASS | Hiérarchie compacte à 1672 px : titre de shell, sections et données restent lisibles sans troncature critique. |
| Rythme / grille | PASS | En-tête 50 px, barre contextuelle 52 px, navigation 191 px et panneaux 266/213/565/388 px respectent le contrat de capture. |
| Couleurs / tokens | PASS | Surfaces sombres, contours bleus, traitements narratif/condition/Scene et succès proviennent du design system ; aucune couleur locale n’est ajoutée au shell. |
| Assets | PASS | La marque et la vignette projet sont des assets raster déclarés, pas des dessins CSS ou des glyphes de substitution. |
| Icônes / affordances | PASS | Les actions métier visibles sont fonctionnelles ; les trois fonctions futures sont explicitement désactivées ; les actions scène restent des liens explicites. |
| Contenu | PASS | Le jeu de données diffère volontairement de la maquette pour montrer le vrai modèle source-first et les projections Scene read-only, sans inventer de champs Event. |

## Écarts P3 conservés

- La fixture s’appelle `Selbrume Route Test` et non `Selbrume Demo` : c’est le
  nom réel de la fixture de test et il ne doit pas être maquillé pour le golden.
- Le compteur de notifications de la maquette n’est pas rendu : aucun modèle de
  notifications n’alimente cette route, donc afficher `2` serait un faux état.
- Les réactions ne sont pas dessinées comme des branches éditables par résultat :
  le runtime expose une liste ordonnée de conséquences Scene, pas ce mapping.

Ces écarts sont non bloquants : aucune différence P0, P1 ou P2 actionnable ne
reste dans le scope Event Builder V2.

## Validation K2-R fraîche

- golden produit et golden K mis à jour uniquement après revue visuelle des
  candidats, puis rejoués : le golden de route réelle et le golden canonique
  K passent chacun (`+1`, `All tests passed!`) ;
- `flutter test --no-pub test/ui/design_system/pokemap_button_test.dart` :
  `+8`, `All tests passed!` ;
- matrice K :
  `flutter test --no-pub --concurrency=1 test/ui/canvas/event_builder_v2_phase_k_visual_test.dart test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart test/ui/canvas/event_builder_v2_workspace_test.dart test/ui/canvas/event_builder_v2_flow_fidelity_test.dart test/ui/canvas/event_builder_v2_product_route_test.dart test/ui/canvas/event_builder_v2_accessibility_test.dart`
  : `+48`, `All tests passed!` ;
- clôture ciblée :
  `flutter test --no-pub test/project_scenario_use_cases_test.dart test/scenario_authoring_claim_guard_test.dart test/event_builder_draft_creation_notifier_test.dart test/status_bar_test.dart test/ui/shell/pokemap_bottom_bar_redesign_test.dart test/ui/canvas/event_builder_v2_product_route_test.dart`
  : `+61`, `All tests passed!` ;
- analyse ciblée : `flutter analyze --no-pub` sur les fichiers de shell,
  workspace, design-system et tests modifiés : `No issues found!` ;
- build produit : `flutter build macos --debug --no-pub` :
  `✓ Built build/macos/Build/Products/Debug/map_editor.app` ;
- vérification manuelle : source, capture, côte-à-côte, overlay et trois focus
  ouverts et examinés au même viewport/état.

## Limites et auto-critique

La capture est un contrat visuel reproductible, non une promesse de clone
pixel-identique de données fictives. La maquette mélangeait des actions de
Scene à l’Event ; l’implémentation montre leur propriété réelle plutôt que de
fabriquer des contrôles. La matrice globale est désormais verte ; la décision
de publication et le checkpoint final relèvent toujours de L, hors scope de
cette QA.

Échantillon de non-régression hors scope : les goldens existants Scene V1-39
et Storylines V1-12 restent légèrement dérivés (respectivement 1,09 % et
0,28–0,50 %). Les captures examinées ne présentent pas le shell Events V2 ou
son double-chrome ; aucune mise à jour massive de ces baselines n’a été faite.
Ils restent à trier dans une campagne visuelle globale, sans invalider ce
verdict K2-R centré sur la vraie route Events.

final result: passed
