# FG-181 — Blueprint visuel du Port des Brisants

## Lot

`FG-181 / map_port_brisants / correction visuelle contrainte`

## Sources comparées

- Objectif original : `objective.png` (`1448 × 1086`).
- Objectif normalisé : `objective_normalized.png` (`1440 × 1088`, soit
  `45 × 34` cases à `32 px`).
- Rendu avant correction : `before_overview.png` (`1440 × 1088`).
- Détails avant correction : `before_C1.png` à `before_C6.png`.

L’image d’objectif reste une référence uniquement. Elle ne devient jamais un
underlay ou une texture runtime.

## Frontière absolue

Ce lot ne travaille sur aucune collision : aucune donnée, logique, validation,
capture ou correction de collision. Le propriétaire effectuera son passage
séparé après approbation visuelle.

Le lot ne crée aucun nouveau layer, `MapPlacedElement` ou `ProjectElement`.
Les nouveaux pixels sont des modules de tileset `tile-only` peints dans les
quatre `TileLayer` Port déjà présentes.

## Diagnostic avant correction

| Zone | Écart principal | Cause technique | Correction visuelle prévue |
|---|---|---|---|
| Maisons nord | portes visuellement enfermées, mêmes remparts répétés | cinq copies du jardin muré `7 × 5` | retirer les cinq composites et repeindre murs courts, embouts, ouvertures et fleurs |
| Capitainerie | parvis comprimé et murs doublés | deux jardins backdrop qui se chevauchent | conserver bâtiment et lampes, reconstruire uniquement le soutènement arrière et les ouvertures |
| Place centrale | grand rectangle d’herbe vide | pavement dessiné par bandes rectangulaires | étendre `pavement_path` et conserver un massif compact central |
| Marché ouest | décor isolé autour du commerce | props sans groupe fonctionnel | conserver le bâtiment, regrouper visuellement vente/filets/cordages |
| Accastillage est | façade chargée, props flottants | accessoires posés par coordonnées brutes | libérer la porte et organiser stockage/réparation sur les côtés |
| Quai horizontal | trois blocs identiques | un seul module `12 × 4` répété | différencier ouest, centre et est par ouvertures, raccords et accessoires |
| Marches centrales | pierre sur bois et chevauchements | composite `7 × 7` trop opaque | garder le canvas mais réduire l’alpha utile à un escalier compact |
| Pontons | silhouettes trop mécaniques | composites répétés | varier extrémités et raccords ; alléger visuellement le ponton est |
| Côte est | frontière incomplète et carrée | composite `9 × 5` trop court/translucide | repeindre une côte continue et un raccord quai–rocher dédié |
| Écume | longues bandes traversant les pieux | trois overlays `12 × 2` identiques | écume locale courte autour des pieux, coques et rochers |
| Lampadaires | lecture aléatoire | contexte de chemin/murs incohérent | conserver les quatre positions et construire le décor autour d’elles |

## Macro-composition retenue

### Bande nord — `y = 0..10`

- Conserver les six bâtiments, la forêt Environment, les quatre lampes et la
  sortie nord actuelle.
- Maison ouest : jardin ouvert devant le seuil, mur court uniquement sur les
  côtés et à l’arrière.
- Capitainerie : axe porte/parvis centré, soutènement en deux moitiés, aucune
  pierre devant la porte.
- Maisons est : privilégier clôtures et jardinières basses plutôt qu’un socle
  de pierre continu.
- Le nid narratif reste à sa position actuelle et hors de la composition
  principale.

### Place et commerces — `y = 9..18`

- Le pavement devient la masse principale.
- Conserver deux respirations végétales : un îlot central compact et un îlot
  près du marché.
- Garder un axe clair entre capitainerie, place et marches du quai.
- Libérer visuellement toutes les façades.
- Les cinq props visuels whitelistés peuvent être retirés puis repeints dans
  les layers visuels ; tous les autres restent inchangés.

### Front de quai — `y = 17..22`

- Conserver l’alignement général des trois sections horizontales.
- Ouest : fonction vente/déchargement.
- Centre : ouverture d’escalier nette et zone de travail.
- Est : raccord direct à la côte et à l’accastillage.
- Aucun bloc de pierre ne doit traverser une entrée de ponton.

### Bassin et pontons — `y = 21..33`

- Les bateaux restent inchangés.
- Ponton ouest : long ponton de service.
- Ponton central : grande plateforme de travail, silhouette en T.
- Ponton est : lecture visuellement plus légère que les deux autres.
- Les accessoires sont groupés par usage et restent entièrement posés sur le
  bois dans le rendu.

### Côte

- Ouest : conserver la grande côte continue et corriger seulement le raccord
  avec le quai.
- Est : repeindre le raccord complet du quai jusqu’au bord droit/bas, sans trou
  transparent in-bounds.
- L’écume doit réagir localement aux rochers, coques et pieux.

## Whitelist de données visuelles

Le refiner peut modifier uniquement :

1. `l_path_primary.cells` ;
2. les tableaux `tiles` de :
   - `l_tile_port_ref_ground` ;
   - `l_tile_port_ref_backdrop` ;
   - `l_tile_port_ref_overhead` ;
   - `l_tile_port_ref_structures` ;
3. la suppression/remplacement des placements suivants :
   - `pe_port_garden_backdrop_west` ;
   - `pe_port_garden_backdrop_captain_west` ;
   - `pe_port_garden_backdrop_captain_east` ;
   - `pe_port_garden_backdrop_east_blue` ;
   - `pe_port_garden_backdrop_east_orange` ;
   - `pe_port_flower_bed` ;
   - `pe_port_quay_5`, `pe_port_quay_17`, `pe_port_quay_29` ;
   - `pe_port_quay_steps` ;
   - `pe_port_pier_west`, `pe_port_pier_center`, `pe_port_pier_east` ;
   - `pe_port_coast_west`, `pe_port_coast_east` ;
   - les sept `pe_port_foam_*` ;
4. le retrait/repaint éventuel de :
   - `pe_port_net_rack_east` ;
   - `pe_port_fish_basket_west` ;
   - `pe_port_fish_basket_east` ;
   - `pe_port_lobster_pots_center` ;
   - `pe_port_barrel_buoy_center` ;
5. les métadonnées `visualRefiner*` ;
6. l’atlas Port v3 et son tableau de provenance `tileModules`.

Tout le résidu JSON avant/après doit être profondément identique.

## Répartition des modules dans les layers existants

| Layer | Familles de modules |
|---|---|
| `l_tile_port_ref_ground` | fleurs basses, massif compact, écume et wakes |
| `l_tile_port_ref_backdrop` | murs et clôtures derrière les façades |
| `l_tile_port_ref_structures` | côte, quais, pontons, marches et murs frontaux |
| `l_tile_port_ref_overhead` | parties hautes nécessaires à l’occlusion visuelle |

## Gate de comparaison

Le résultat ne passe pas sur un simple test technique. Les captures finales
doivent être comparées à `objective_normalized.png` avec la même taille et une
lumière neutre.

Minimum attendu :

- composition `≥ 4/5` ;
- cohérence de style `≥ 4/5` ;
- accès visuels `5/5` ;
- quais et raccords `5/5` ;
- côte est `5/5` ;
- finition générale `≥ 4/5` ;
- aucune grille, zone, trigger, sélection ou label dans les preuves.

## État initial

- Branche : `main`.
- État Git observé avant implémentation : propre.
- Le propriétaire a signalé une autre conversation active ; chaque écriture
  doit donc être précédée d’un contrôle du statut et les changements étrangers
  doivent être préservés.
