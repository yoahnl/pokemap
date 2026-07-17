# Event Builder V2 — Phase K Design QA

Date : 2026-07-17

Lot : `NS-EVENT-V2 Phase K — Pixel-Perfect Visual Closure`

Jalons : `V2-38`, `V2-39`, `V2-40`
Résultat technique : **PASSED pour le contrat produit supporté**

Statut mission K : **PLANNED — tableau maître `NOT STARTED`**

Décision visuelle : **acceptation utilisateur des écarts P2 requise**

## Résumé

La preuve finale ne repose plus sur le seul harnais visuel. Elle monte la vraie
`EditorShellPage`, traverse la route Narrative Studio → Events, recharge une
fixture V2-only sur disque et capture le produit complet au viewport normatif
1672 × 941. La liste projet, la bibliothèque, le flow Event, les conditions
détaillées, la Scene en lecture seule, les résultats, conséquences, règles du
monde et l’inspecteur sont alimentés par les projections de production.

Le défaut étroit réel `BOTTOM OVERFLOWED BY 70 PIXELS` est fermé : le gate
responsive intervient maintenant avant les notices et les watches coûteux. Le
nouveau test produit à 800 × 632 ne relève ni overflow, ni loader, ni notice
masquant l’état étroit.

Ce PASS technique ne signifie pas que le chrome global PokeMap est redessiné au pixel près
comme la maquette. Le shell existant du produit est conservé ; la composition et
la hiérarchie de l’Event Builder reprennent la north star à l’intérieur de ce
shell. Il ne signifie pas non plus que la Phase L est GO.

## Artefacts normatifs

| Artefact | Dimensions | SHA-256 |
|---|---:|---|
| North star fournie | 1672 × 941 | `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` |
| Produit final, shell réel | 1672 × 941 | `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673` |
| Côte-à-côte final | 3344 × 941 | `ba8f2d3e8f749ca5bb3da437f7ef0771452f74cb95f4a52d2753ecebac54199f` |
| Overlay final 50 % | 1672 × 941 | `7153dbd5ae3be7e256694b29e5718e69f4d85f424f0da1152c202804c8e1f589` |

Chemins :

- `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/product_after_1672x941.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_1672x941.png` ;
- `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_overlay_50.png`.

## Revue par zone

| Zone | Verdict | Preuve |
|---|---|---|
| Shell et navigation | PASS | vraie `EditorShellPage`, vraie route Events, explorer global replié |
| Liste projet | PASS | groupes Map/global/brouillons/références/legacy et statuts réels |
| Bibliothèque | PASS | déclencheurs, conditions et projections Scene séparés |
| Éditeur | PASS | source, deux conditions, Scene, trois résultats, deux conséquences, règle monde |
| Inspecteur | PASS | source dérivée, conditions ordonnées, impact Scene, réutilisation et priorité |
| Responsive | PASS | 800 étroit + matrice 1280/1440/1480/1672/1920 + texte 125 % |
| Ownership | PASS | `Event ≠ Scene`, aucune fausse poignée, drop zone ou branche authorable |

## Findings fermés

- P0 : preuve produit même shell/même état remplacée par le golden full-shell ;
- P0 : overflow étroit de 70 px fermé et couvert par régression ;
- P1 : conditions projetées individuellement avec labels humains, ordre et
  résolution, sans fuite d’ID brut ;
- P1 : priorité, ordre et nombre de concurrents actifs visibles ;
- P1 : résultats, conséquences et changements du monde visibles depuis la vraie
  Scene, en lecture seule ;
- P2 : densité de l’inspecteur et du flow resserrée pour conserver les données
  prioritaires dans le viewport cible.

## Écarts intentionnels soumis à acceptation utilisateur

- le shell global actuel de PokeMap reste celui du produit ;
- aucune `Réinitialisation` n’est affichée : le modèle/runtime ne porte pas ce
  contrat ;
- aucune branche résultat → réaction n’est inventée : la projection courante
  expose une liste déterministe, pas un mapping canonique par outcome ;
- les conséquences restent Scene-owned et s’ouvrent via `Ouvrir la Scene` ;
- la map est dérivée de la source physique et n’est pas un sélecteur indépendant.

## Validation fraîche

- read model core : `+16`, `All tests passed!` ;
- route produit/workspace/responsive/guards : `+66`, `All tests passed!` ;
- performance incrémentale : p50 `11624 µs`, p95 `13410 µs`, budget p95
  `36000 µs` ;
- analyse ciblée core : `No issues found!` ;
- analyse ciblée des fichiers de fermeture : aucune erreur ni warning après
  correction des six infos locales ;
- build editor macOS debug :
  `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## Auto-critique

L’overlay reste visiblement décalé dans le chrome global parce que la north star
et l’application courante n’utilisent pas la même barre d’outils. Le qualifier
de pixel-identique serait faux. En revanche, les blocs métier, leur ordre, leur
densité et leurs données correspondent désormais au contrat réalisable sans
inventer de sémantique. La QA technique K est passée pour la feature et son
shell produit réel. La preuve ne change pas le statut formel `PLANNED` tant que
la séquence S0→J et l’acceptation utilisateur des écarts P2 ne sont pas
fermées. La readiness globale reste gouvernée séparément par la Phase L.
