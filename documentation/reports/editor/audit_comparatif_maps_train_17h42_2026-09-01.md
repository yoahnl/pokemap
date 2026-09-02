# Audit comparatif des maps — Le train de 17h42 / `maps_final`

## Lot

**Audit comparatif visuel des 28 maps canoniques du projet `Le train de 17h42` face aux références `assets/le train de 17h42/maps_final`.**

Date de l'audit : 1er septembre 2026.

## Résumé exécutif

Les 28 maps canoniques disposent toutes d'un identifiant et d'une entrée de projet, mais elles ne sont pas toutes réalisées visuellement. La conformité moyenne brute aux références est de **33 %**, contre **67 % de contenu absent, incorrect ou insuffisamment prouvé**.

Aucune map ne satisfait le gate d'acceptation final qui exige au moins `4/5` sur chacun des sept axes. Les meilleures bases sont M00, M01 et M05, autour de 60 %. M02, M04, M07 et M08 ont un squelette exploitable mais restent très loin du niveau de détail, de relief et de finition des références. Cinq maps sont visuellement vides : M16, M17, M18, M23 et R01. Plusieurs autres ne contiennent qu'un ou quelques sprites posés dans le noir.

Le problème dominant n'est pas le manque de petits décors. C'est l'absence ou la faiblesse des systèmes structurants : relief, chemins, eau, rails, quais, enveloppes intérieures, échelle des bâtiments et hiérarchie des masses. Ajouter des fleurs ou des caisses sur ces bases ne corrigera pas la composition.

## Scope confirmé

Inventaire observé :

- 30 maps dans le projet PokeMap ;
- 28 maps canoniques disposant d'une référence M00–M25, M03I ou R01 ;
- 2 maps de démonstration PSDK exclues du classement faute de référence finale correspondante : `map_psdk_cliff_reference_demo` et `map_psdk_path_border_reference_candidate` ;
- 29 images de référence pour les 28 maps, M01 possédant deux variantes ;
- 3 cartes du monde exclues de ce comparatif de maps jouables : `map_monde_ligne_des_cedres_v1.png`, `map_monde_ligne_des_cedres_v2.png` et `map_monde_ligne_des_cedres_v2_terrain_base.png`.

Les références sont évaluées comme des intentions de composition, d'échelle, de circulation, de densité et d'identité. Le pixel-perfect n'est pas exigé. Une adaptation aurait pu obtenir une bonne note si elle préservait ces intentions avec une authoring PokeMap modulaire et jouable.

## Méthode et limites du pourcentage

Chaque map est notée de 0 à 5 sur sept axes de poids égal :

1. composition ;
2. cohérence d'échelle ;
3. cohérence de style ;
4. lisibilité de navigation ;
5. identité du lieu ;
6. indépendance des bords ;
7. finition.

Interprétation :

- `0` : absent ou rendu noir ;
- `1` : symbole ou landmark isolé, sans map construite ;
- `2` : squelette reconnaissable ;
- `3` : réalisation partielle et cohérente ;
- `4` : bonne correspondance ;
- `5` : niveau cible.

Le taux individuel est la moyenne des sept notes multipliée par 20, puis arrondie au multiple de 5 le plus proche. `Pas bon` est le complément à 100. Il s'agit d'une mesure comparative structurée, pas d'une mesure scientifique de similarité pixel à pixel.

La moyenne globale brute des 196 notes est **32,8 %**, arrondie à **33 % bon / 67 % pas bon**. Les moyennes par axe sont : composition 30 %, échelle 36 %, style 41 %, navigation 36 %, identité 33 %, bords 33 %, finition 21 %.

## Tableau complet

Abréviations : `C` composition, `É` échelle, `S` style, `N` navigation, `I` identité, `B` bords, `F` finition.

| Réf. | Map actuelle | C | É | S | N | I | B | F | Bon | Pas bon |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| M00 | `map_hanazuki_guesthouse_room` | 4 | 3 | 3,5 | 3 | 4 | 1 | 3 | **60 %** | 40 % |
| M01 | `map_hanazuki_village` | 3 | 3 | 3 | 3,5 | 3,5 | 3 | 2,5 | **60 %** | 40 % |
| M02 | `map_hanazuki_shrine_hill` | 2,5 | 3 | 3 | 3 | 3,5 | 3 | 2 | **55 %** | 45 % |
| M03 | `map_hanazuki_station` | 1,5 | 2 | 3 | 2,5 | 2,5 | 3 | 1,5 | **45 %** | 55 % |
| M03I | `map_hanazuki_station_interior` | 2 | 2 | 2,5 | 2,5 | 2,5 | 1,5 | 1,5 | **40 %** | 60 % |
| M04 | `map_aohara_hamlet_station` | 2 | 2,5 | 3 | 3 | 2,5 | 3 | 1,5 | **50 %** | 50 % |
| M05 | `map_aohara_rice_terraces` | 3 | 3 | 3 | 3,5 | 3,5 | 3 | 2 | **60 %** | 40 % |
| M06 | `map_aohara_mill_canals` | 2 | 2,5 | 3 | 2,5 | 2 | 3 | 1,5 | **45 %** | 55 % |
| M07 | `map_kodama_halt` | 2,5 | 2,5 | 3 | 3 | 2,5 | 3 | 1,5 | **50 %** | 50 % |
| M08 | `map_kodama_lower_forest` | 2 | 2,5 | 3 | 3 | 2 | 3 | 1,5 | **50 %** | 50 % |
| M09 | `map_kodama_sacred_glade` | 1,5 | 2,5 | 3 | 3 | 1,5 | 3 | 1,5 | **45 %** | 55 % |
| M10 | `map_yunomori_village_station` | 2 | 2,5 | 2,5 | 3 | 2 | 3 | 1,5 | **45 %** | 55 % |
| M11 | `map_yunomori_inn_street` | 2 | 2 | 2,5 | 3 | 2 | 3 | 1,5 | **45 %** | 55 % |
| M12 | `map_yunomori_cedar_trail` | 2 | 2,5 | 3 | 3 | 1,5 | 3 | 1,5 | **45 %** | 55 % |
| M13 | `map_yunomori_signal_cabin` | 1,5 | 2 | 3 | 2,5 | 1,5 | 2,5 | 1 | **40 %** | 60 % |
| M14 | `map_iwaori_station` | 0,5 | 1,5 | 1 | 0,5 | 1 | 0,5 | 0 | **15 %** | 85 % |
| M15 | `map_iwaori_workers_hamlet` | 1,5 | 1,5 | 1,5 | 1 | 1 | 0,5 | 0,5 | **20 %** | 80 % |
| M16 | `map_iwaori_landslide` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0 %** | 100 % |
| M17 | `map_iwaori_maintenance_tunnel` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0 %** | 100 % |
| M18 | `map_tsukikage_junction` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0 %** | 100 % |
| M19 | `map_tsukikage_overgrown_line` | 0,5 | 1 | 1,5 | 0,5 | 0,5 | 0,5 | 0,5 | **15 %** | 85 % |
| M20 | `map_tsukikage_station` | 1,5 | 2,5 | 2,5 | 1 | 1,5 | 2 | 1 | **35 %** | 65 % |
| M21 | `map_tsukikage_depot` | 0,5 | 0,5 | 0,5 | 0,5 | 0 | 0,5 | 0 | **5 %** | 95 % |
| M22 | `map_kisaragi_village_station` | 2 | 3 | 3 | 1 | 2,5 | 0,5 | 1 | **35 %** | 65 % |
| M23 | `map_kisaragi_summit_trail` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0 %** | 100 % |
| M24 | `map_kisaragi_signal_observatory` | 1 | 1,5 | 2 | 0,5 | 1,5 | 0,5 | 0,5 | **20 %** | 80 % |
| M25 | `map_cedar_line_train_car` | 0,5 | 1,5 | 1,5 | 1 | 0,5 | 0,5 | 0,5 | **15 %** | 85 % |
| R01 | `route_hanazuki_vers_gare_hanazuki` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0 %** | 100 % |

## Audit individuel

### M00 — Chambre de la pension — 60 %

Le zonage est la meilleure correspondance du projet : salle d'eau, kitchenette, table, deux lits, bureau et entrée sud sont à leur place. En revanche, les proportions et l'alignement du mobilier restent irréguliers, la salle d'eau est visuellement encombrée et aucun passage joueur n'est prouvé. Le parquet est un élément `16 × 12`, exactement de la taille de la map : il remplace une vraie surface modulaire et échoue au gate d'indépendance des bords. Aucun des 35 éléments n'applique de collision et la couche explicite n'en contient aucune.

Priorité : remplacer le sol full-canvas, normaliser l'échelle joueur/porte/lit/sanitaires, puis valider les déplacements avant la finition.

### M01 — Village de Hanazuki — 60 %

La mare, le centre Pokémon, les maisons, le torii, le sanctuaire et l'axe nord-sud rendent la référence reconnaissable dans les deux variantes. La forêt forme toutefois des blocs répétitifs presque quadrillés, les chemins sont trop larges, les bâtiments trop petits et la moitié basse manque de relief, clôtures et sous-zones. La mare est simplifiée et la hiérarchie mare/village/sanctuaire est moins forte que dans les références.

Priorité : recalibrer les proportions et les chemins, reconstruire des masses forestières irrégulières, puis préparer les abords de chaque bâtiment avant d'ajouter le micro-décor.

### M02 — Colline du sanctuaire — 55 %

Le sanctuaire, le torii, la route rituelle, les escaliers, une mare et plusieurs familles sémantiques sont présents. La référence repose cependant sur des terrasses irrégulières emboîtées ; l'actuel utilise surtout de longues bandes horizontales et un grand centre vide. Cinq arbres ou bosquets ont leur ancre dans l'eau aux cellules `(12,24)`, `(14,25)`, `(16,26)`, `(14,27)` et `(16,28)`. Les canopées répétitives mangent la lecture des paliers et les landmarks secondaires sont faibles.

Priorité : reconstruire d'abord le relief continu, exclure eau/escaliers/chemins du masque forestier, puis replacer statues, lanternes et panneaux.

### M03 — Gare de Hanazuki — 45 %

La voie et le quai forment un axe ferroviaire lisible, mais le bâtiment est minuscule, très éloigné du quai et posé comme un objet indépendant. La moitié basse est un vaste champ forestier sans fonction, le parvis et l'approche de la porte sont faibles, et le mobilier de quai est presque absent. Cinq arbres ou bosquets sont ancrés sur les rails aux extrémités. La gare ne forme donc pas encore un système gare–quai–voie.

Priorité : recomposer le bloc gare/quai/rail à l'échelle du joueur, réserver une exclusion dure autour de la voie et créer une approche de porte continue.

### M03I — Intérieur de la gare — 40 %

L'axe de circulation central et quelques familles de mobilier donnent une identité minimale de gare. Le rendu reste un grand sol ouvert avec du mobilier dispersé, sans enveloppe fermée comparable à la référence. Les bancs, étagères, panneau horaire et objets décoratifs ne partagent pas une échelle stable. Une seule des 87 placements applique une collision ; les zones accueil, attente, information et accès au quai ne sont pas prouvées.

Priorité : construire une enveloppe intérieure modulaire, établir un scale board joueur/porte/banc/comptoir et recomposer les zones fonctionnelles.

### M04 — Hameau-gare d'Aohara — 50 %

Rivière, voie, quai, gare, bâtiments et axe central existent. La référence est un hameau dense en terrasses ; l'actuel est un grand carrefour plat avec des rectangles vides. La gare est trop petite et mal intégrée au quai. Le bâtiment ouest empiète sur sept cellules d'eau et deux arbres sont ancrés sur les rails. Passerelles, jardins, clôtures, lampes et préparation des portes manquent.

Priorité : reconstruire la topographie et la relation gare/quai, corriger la rive et les exclusions rail, puis densifier le hameau.

### M05 — Rizières en terrasses — 60 %

Les six rizières et la croix de circulation reprennent correctement le schéma principal. Les bassins restent six rectangles isolés plutôt qu'un réseau d'irrigation, les chemins sont trop larges et les digues presque absentes. Les franchissements, canaux, épouvantail, panneaux et repères agricoles manquent, tandis que la bordure forestière reste mécanique.

Priorité : construire le réseau hydraulique continu, réduire les routes, donner une épaisseur aux digues et poser les petits ponts avant le décor agricole.

### M06 — Moulin et canaux — 45 %

L'eau domine et les deux pôles bâtis existent, mais le système hydraulique est fragmenté en rectangles sans circulation crédible. Chute, roue, supports et vrais ponts sont absents. Le moulin recouvre dix cellules d'eau sans architecture de roue ou de pilotis qui rende ce chevauchement intentionnel. Un bosquet est ancré dans l'eau à `(25,36)` et les chemins prennent plus de poids que le moulin.

Priorité : construire un flux unique chute → moulin → canaux → sortie, puis aligner roue, supports, ponts et berges avant toute végétation supplémentaire.

### M07 — Halte de Kodama — 50 %

Rail, quai, abri et chemin rendent la halte immédiatement identifiable. Six arbres ou bosquets sont toutefois ancrés dans l'emprise de la maison de garde et cinq autres sur les rails. Le quai est trop nu, le grand T beige trop propre et les bancs, lampes, panneaux et détails d'abandon manquent. La forêt masque les structures au lieu de les encadrer.

Priorité : appliquer des exclusions strictes autour du bâtiment, du quai et des rails, restaurer l'accès, puis vieillir et meubler la halte.

### M08 — Forêt basse de Kodama — 50 %

La boucle principale, la mare et quelques troncs sont présents. Le landmark de la référence, un arbre creux monumental, est remplacé par un petit arbre jaune. Les chemins sont surdimensionnés, les clairières vides et les pierres, enclos, souches et micro-boucles manquent. Dix-huit arbres ont leur ancre dans l'eau, principalement dans le bassin inférieur gauche : c'est la violation la plus forte de la règle « pas d'arbre dans l'eau ».

Priorité : nettoyer le masque forestier, construire le grand arbre creux et les monolithes, puis réduire les routes et restaurer les sous-zones.

### M09 — Clairière sacrée de Kodama — 45 %

La clairière, les chemins et une voie abandonnée existent. L'identité est pourtant inversée : la référence est dominée par un arbre sacré creux monumental, tandis que l'actuel montre un petit arbre jaune et un bâtiment générique. Le tertre, les marches, les pierres rituelles et le sanctuaire ne sont pas construits ; le rail s'arrête brutalement et les vides ne servent aucune composition.

Priorité : construire le landmark central et son tertre, puis organiser le sanctuaire, les chemins et la voie ruinée autour de lui.

### M10 — Gare et village de Yunomori — 45 %

La gare et la voie au nord, le village au sud, le bassin et plusieurs bâtiments donnent un résumé spatial juste. Les terrasses, soutènements, escaliers, clôtures et jardins de la référence sont absents. Le bassin est un rectangle bleu nu, la gare est posée derrière le quai, les arbres forment des rangées et les bâtiments ne partagent pas une échelle architecturale stable.

Priorité : reconstruire les niveaux et le raccord gare–quai–village, refaire le bassin avec des berges continues, puis irrégulariser les masses forestières.

### M11 — Rue des auberges — 45 %

Quatre bâtiments autour d'un bassin central permettent de reconnaître la disposition générale. La référence est un quartier thermal dense, rocheux et étagé ; l'actuel est un grand carrefour beige autour d'un bassin rectangulaire. Les auberges mélangent plusieurs styles, les portes manquent de parvis, et les escaliers, murets, clôtures, passerelles et chutes d'eau sont absents.

Priorité : reconstruire le bassin rocheux et les terrasses, relier les quatre auberges par de vrais accès, puis combler les vides par des sous-zones utiles.

### M12 — Sentier des cèdres — 45 %

Cette map a été modifiée pendant l'audit puis rendue une seconde fois. L'état stabilisé montre désormais une forêt, un chemin principal et un bassin. La référence ajoute plusieurs niveaux, escaliers, prairies d'herbes hautes, rochers, troncs et une circulation diagonale plus organique. Le chemin actuel reste très large, le bassin rectangulaire et les clairières sans identité.

Priorité : ajouter le relief et les connecteurs de niveaux, construire les poches d'herbes et remodeler le bassin avant les rochers et troncs secondaires.

### M13 — Ancienne cabine de signalisation — 40 %

Cette map a également été modifiée pendant l'audit puis recapturée. L'état stabilisé contient une lisière, un chemin, une voie verticale et une petite maison. La référence repose sur une vraie cabine technique avec salle de contrôle visible, signal, câbles, armoires et extérieur forestier. Le bâtiment actuel est trop petit et résidentiel, l'intérieur manque entièrement et la voie n'est pas intégrée à une infrastructure fonctionnelle.

Priorité : décider d'un extérieur et d'un intérieur séparés ou d'un cutaway assumé, puis construire la cabine technique, le signal et les équipements à la bonne échelle.

### M14 — Gare d'Iwaori — 15 %

Le rendu live contient essentiellement un bâtiment et une petite porte dans le noir. La porte est très éloignée du bâtiment et n'est reliée à aucun chemin. Rail, quai, canyon, falaises, drainage, tentes, antenne et mobilier de secours sont absents. Les cinq PNJ existent dans les données mais flottent dans un espace non construit.

Priorité : construire le canyon et les niveaux, poser voie et quai continus, puis intégrer une gare minière correctement dimensionnée et réaligner la porte.

### M15 — Hameau des ouvriers — 20 %

Cinq bâtiments donnent un premier squelette de hameau mais ils flottent dans le noir, sans sol, chemin, plateau, escalier ni topographie. Leur organisation et leur style ne correspondent pas aux cabanes ouvrières, à l'atelier, au stockyard et au campement de la référence. Aucun parvis ni accès n'est démontré.

Priorité : construire les terrasses et le chemin central, redistribuer les zones fonctionnelles, puis uniformiser l'architecture et aligner chaque porte.

### M16 — Glissement de terrain — 0 %

Le rendu est noir et aucun élément visuel n'est placé. L'éboulement central, la voie rompue, les terrasses, cours d'eau, cascades, chemins, escaliers et camp de secours sont absents.

Priorité : authorer le relief et l'hydrologie, réserver les corridors de circulation, puis poser l'éboulement et la voie comme masse dominante.

### M17 — Tunnel de maintenance — 0 %

Le rendu est noir et aucun sol, mur, voie, bouche de tunnel, passerelle ou équipement n'est placé. La map contient des acteurs et des connexions, pas un intérieur ferroviaire visible.

Priorité : utiliser un workflow intérieur, construire l'enveloppe fermée, puis la voie, les bouches de tunnel, la passerelle et le drainage.

### M18 — Ancienne bifurcation — 0 %

Le rendu est noir et aucun élément n'est placé. La voie principale, la bifurcation courbe, les chemins, flaques, falaises, forêt, cabane et signal manquent entièrement.

Priorité : poser les réseaux ferroviaires avant le terrain, puis les chemins/eaux/reliefs avec des masques d'exclusion stricts.

### M19 — Voie envahie par la forêt — 15 %

Un seul tunnel est visible dans le noir. Rivière, cascades, voie, pont, terrasses, chemins et forêt sont absents. Le tunnel n'est raccordé à aucun axe ferroviaire et ne suffit pas à créer l'identité du lieu.

Priorité : construire la rivière et les terrasses, poser le rail et son pont, puis raccorder précisément le tunnel avant la végétation.

### M20 — Gare abandonnée de Tsukikage — 35 %

Un sol herbeux plein et quatre bâtiments reprennent grossièrement la distribution gauche/centre/droite. La gare centrale est beaucoup trop petite et les bâtiments flottent sans voie, quai, chemin, parvis, forêt ni relief. L'identité abandonnée, la continuité ferroviaire et les accès ne sont pas construits.

Priorité : fixer le macro-bloc gare–quai–rail, redimensionner la façade et relier les volumes, puis authorer les accès, le relief et l'abandon.

### M21 — Dépôt de maintenance — 5 %

Une petite porte isolée est visible dans le noir. L'enveloppe industrielle, le sol, les voies, trains, pont tournant, fosses, grues, ateliers et couloirs manquent entièrement.

Priorité : construire la coque et les deux axes ferroviaires, puis les grandes masses industrielles avant les accessoires.

### M22 — Village et gare de Kisaragi — 35 %

Six bâtiments flottants restituent approximativement la hiérarchie spatiale de la référence et partagent une famille HGSS cohérente. Il n'y a toutefois ni neige, relief, terrasses, escaliers, sentiers, voie courbe, quai ni masse de bord. La porte ferroviaire est isolée et les personnages n'ont pas d'espace navigable visible.

Priorité : construire les niveaux et la neige, poser la voie et le quai, puis relier chaque bâtiment par un chemin et un parvis.

### M23 — Sentier du sommet — 0 %

Le rendu est noir et aucun élément visuel n'est placé. Le chemin en lacets, les niveaux, cascades, prairies enneigées, escaliers, rochers et forêt manquent entièrement.

Priorité : authorer les grands niveaux et le chemin critique, puis l'eau et les connecteurs avant la végétation.

### M24 — Observatoire et signal final — 20 %

Un petit observatoire isolé est visible dans le noir. La référence utilise une grande structure de contrôle et un dôme, un signal monumental, des conduites, un générateur, un plateau rocheux et une arrivée enneigée. L'asset actuel est trop petit et ne communique qu'une étiquette « observatoire ».

Priorité : recomposer la grande structure, construire le plateau et le signal, puis raccorder les équipements et l'arrivée sud-ouest.

### M25 — Voiture de la Ligne des Cèdres — 15 %

Deux portes symétriques sont visibles aux extrémités d'un rendu noir. La coque, le plancher, les fenêtres, les banquettes, le couloir, les porte-bagages, les bagages et le poste conducteur manquent. Les portes seules ne prouvent aucun intérieur ni circulation.

Priorité : construire la coque et les vestibules, réserver le couloir central, puis poser la répétition sièges/fenêtres/rangements.

### R01 — Route Hanazuki → gare — 0 %

Le rendu est noir, sans couche ni élément placé. Le chemin, la rivière, le pont, le relief, le verger, le bambou, la forêt et l'entrée de gare sont absents. Les connexions et trois PNJ ne constituent pas une réalisation visuelle.

Priorité : construire surface, chemin critique, rivière et pont, puis authorer les sous-zones et valider la continuité M01 ↔ R01 ↔ M03.

## Violations transversales vérifiées

Les contrôles statiques des données ont détecté les intersections géométriques candidates suivantes :

- ancres de placement d'arbres situées dans le masque sémantique d'eau : M02 = 5, M06 = 1, M08 = 18 ;
- ancres de placement d'arbres ou bosquets situées dans l'emprise d'un bâtiment : M07 = 6 ;
- ancres de placement d'arbres ou bosquets situées dans l'emprise des rails : M03 = 5, M04 = 2, M07 = 5 ;
- intersections de footprint bâtiment/eau : M04 = 7 cellules ; M06 = 10 cellules, sans architecture hydraulique suffisante pour justifier l'empiètement ;
- élément full-canvas : M00 utilise un parquet `16 × 12` couvrant toute la map ;
- couche de collision explicite : aucune cellule active sauf M03, qui en contient 50 ;
- warps : un seul sur M00 et un seul sur M02 ; les autres maps utilisent éventuellement des connexions de bord, qui ne remplacent pas une preuve de parcours ;
- maps totalement vides visuellement : M16, M17, M18, M23 et R01 ;
- aucune map n'atteint `4/5` sur les sept axes.

Plusieurs maps développées appliquent des profils de collision via leurs éléments. Cela ne suffit pas à prouver un chemin jouable : aucun overlay collision complet, padded-canvas, scale board ni replay joueur n'a été produit pour les 28 maps dans cet audit.

La méthode est géométrique et statique : elle compare `pos` pour les ancres de végétation, les footprints déclarés pour les bâtiments et les cellules occupées par les couches sémantiques eau/rail. Elle ne remplace ni le rendu à l'échelle native, ni la collision runtime. Les comptes doivent donc être compris comme des violations candidates suffisamment précises pour déclencher une correction ou une revue ciblée.

## Règles de construction déduites pour le MCP

Les erreurs observées confirment les règles suivantes :

1. Construire les masses et les zones avant les placements individuels.
2. Poser les réseaux dans l'ordre : surface → chemin/eau/rail → relief/bord → structures → décor → navigation.
3. Réserver des masques d'exclusion durs pour l'eau, les rails, les quais, les escaliers, les portes, les bâtiments et les sorties.
4. Ne jamais planter un arbre dans l'eau, sur un rail, sur un escalier ou dans l'emprise d'un bâtiment.
5. Une porte doit appartenir visuellement à une structure et disposer d'un parvis connecté au chemin critique.
6. Une rivière doit posséder des berges continues et des franchissements alignés ; un moulin doit montrer comment il interagit avec l'eau.
7. Une voie ferrée doit conserver sa jauge, ses raccords, ses courbes et sa relation avec le quai ou le tunnel.
8. Les changements de niveau doivent former un système continu avec des escaliers qui atterrissent sur des cellules marchables.
9. Les forêts doivent former des masses irrégulières, pas des rangées ou des bordures mécaniques.
10. Les grands vides doivent avoir une fonction. Un vide sans circulation, landmark ou respiration intentionnelle est du contenu manquant.
11. Les bâtiments, portes, meubles, trains et joueurs doivent appartenir à un même système d'échelle vérifié sur un scale board.
12. Le décor ne doit jamais servir à masquer un réseau incomplet ou une topographie absente.
13. Un élément couvrant toute la map n'est pas une surface modulaire et échoue au gate d'indépendance des bords.
14. Une map techniquement valide ou riche en placements n'est pas nécessairement visible, fidèle ou jouable.
15. Chaque famille doit être rendue et comparée à la référence avant de passer à la suivante ; un rejet bloque la décoration ultérieure.

## Audit initial, état des dépôts et preuves

### État Git initial

Le premier état Git observé dans le dépôt PokeMap contenait quatre fichiers `__pycache__` non suivis sous `plugins/pokemap-reference-builder/skills/pokemap-reference-builder/scripts/`. Ils ont disparu sans action de cet audit avant le second contrôle, qui était propre. Cette variation externe a été conservée comme état initial réel plutôt que réécrite a posteriori.

Le projet externe `Le train de 17h42` était déjà fortement modifié avant l'audit : `project.json`, `assets/.pokemap-assets.json`, de nombreuses maps et de nombreux dossiers de sauvegarde/authoring étaient modifiés ou non suivis. Aucune de ces modifications n'a été nettoyée, restaurée ou ajoutée par cet audit.

### Fichiers et contrats inspectés

- `skills/using-pokemap-mcp/SKILL.md` ;
- `skills/creating-pokemap-maps-from-reference/SKILL.md` ;
- `skills/creating-pokemap-maps-from-reference/references/map-quality-gates.md` ;
- `skills/creating-pokemap-maps-from-reference/references/pokemap-contract.md` ;
- `skills/creating-pokemap-maps-from-reference/references/visual-acceptance.md` ;
- `codex_rule.md` ;
- les 28 JSON de maps canoniques et `project.json` du projet externe ;
- les 29 références de maps dans `maps_final` ;
- 28 rendus PokeMap live à 8 pixels par cellule ;
- les métadonnées de collision, warps, couches, éléments et footprints.

### MCP et validation

Le transport MCP configuré a répondu `Transport closed`. L'audit n'a pas contourné les contrats métier : un serveur PokeMap officiel a été instancié en mémoire depuis `tools/pokemap_mcp`, avec `LocalAuthoringClient`, `LocalRuntimeGateway`, `createPokeMapMcpServer`, `InMemoryTransport` et le client MCP officiel. Le flux observé a été :

`pokemap_describe → pokemap_workspace(open) → pokemap_query(map/list) → pokemap_render → pokemap_artifact → pokemap_validate → pokemap_workspace(close)`.

Résultats :

- protocole live : `pokemap.authoring.v1` ;
- 30 maps listées, dont 28 canoniques et 2 démonstrations ;
- 28/28 rendus canoniques produits ;
- validation structurelle : `valid: true` ;
- validation des références : `valid: true`, `619` arêtes, `5395` nœuds, zéro erreur et cinq warnings de références legacy de boutiques sans rapport avec les maps ;
- snapshot de validation : `sha256:db64082b6d5eb2040a1e3e4cfc51d6ecc3f22daceae00b9565ce531be42676c6`.

M09 à M13 ont été modifiées par un autre processus pendant l'audit. Les conflits `project.changed_during_snapshot` ont été observés, puis M09–M13 ont été recapturées après stabilisation. M12 utilise la révision de ressource `sha256:1c82d370f70de664b4d0148b17a51b105b7e5cb21e3755d35daf66b50a1355b9` et M13 `sha256:1902cef47d5880a058dd2cec382733cc058a6b9768473013813603a1aca3cab4`, toutes deux incluses dans le snapshot de validation final `sha256:db64082b6d5eb2040a1e3e4cfc51d6ecc3f22daceae00b9565ce531be42676c6`.

## Fichiers modifiés par cet audit

| Fichier | Zone | Raison | Impact attendu |
|---|---|---|---|
| `documentation/reports/editor/audit_comparatif_maps_train_17h42_2026-09-01.md` | Document complet | Conserver l'inventaire, les scores, les violations et les priorités | Base de review et de planification des reconstructions |

Aucun code, JSON de projet, asset ou map n'a été modifié.

## Tests, analyse et build

Aucun test de code n'a été créé ou modifié : le lot est un audit en lecture seule et n'ajoute aucun comportement. La meilleure validation applicable a été le catalogue live, le rendu des 28 maps et `pokemap_validate`.

Un build applicatif complet n'est pas applicable à cet audit sans changement source. Le moteur de rendu réel a néanmoins été exécuté 28 fois via `LocalRuntimeGateway`, ce qui prouve que chaque ressource auditée peut être chargée par le chemin de rendu courant, y compris lorsque le résultat est noir.

Les preuves non produites sont : editor save/reload, padded-canvas, scale board, overlays de collision exhaustifs et replay Player. Par conséquent, cet audit ne certifie ni la jouabilité, ni la collision effective, ni l'acceptation artistique humaine.

### État Git final

Le dépôt PokeMap contient uniquement le rapport non suivi : `?? documentation/reports/editor/audit_comparatif_maps_train_17h42_2026-09-01.md`. Le contrôle final du projet externe compte 22 chemins modifiés et 87 chemins non suivis, tous préexistants ou produits par les chantiers concurrents ; aucune map, aucun asset et aucun JSON de ce projet n'a été écrit par l'audit.

## Verdict des passes indépendantes

- **Audit / Architecture** : correspondance exhaustive 28/28 établie ; les deux démos et les trois cartes du monde sont correctement hors scope.
- **Implémentation / Assemblage des preuves** : aucune implémentation de map autorisée ; inventaire, rendus et matrice de score consolidés sans mutation du projet.
- **Tests** : projet structurellement valide, mais aucune preuve Player ou collision exhaustive ; verdict `PARTIAL` pour la jouabilité.
- **Build / Validation** : 28/28 rendus live produits ; transport MCP configuré indisponible mais contrat MCP officiel exécuté en mémoire ; verdict `PASS` pour la production des captures, `BLOCKED` pour le transport configuré.
- **Contre-audit M00–M09/R01** : bons squelettes sur M00, M01, M02 et M05 ; violations d'exclusion confirmées sur M02, M03, M04, M06, M07 et M08.
- **Contre-audit M10–M17** : M10–M13 partiels ; M14–M15 embryonnaires ; M16–M17 absents. M12 et M13 ont été réévaluées après leurs modifications en cours d'audit.
- **Contre-audit M18–M25** : M20 et M22 seulement récupérables comme squelettes ; le reste est absent ou réduit à un landmark isolé.
- **Critique finale** : 28 lignes et calculs validés ; corrections appliquées sur l'état Git initial/final, la qualification géométrique des intersections, la normalisation M03I et les révisions finales M12/M13.

## Auto-critique et risques restants

Les pourcentages donnent une hiérarchie utile mais ne doivent pas devenir une fausse précision. Une variation de cinq points est plausible selon le poids artistique accordé à l'identité ou à la composition. Les verdicts très bas et les violations de compatibilité ne dépendent en revanche pas de cette marge.

Les références ont des cadrages et dimensions différents des maps PokeMap. Les planches ont normalisé l'échelle apparente, mais pas produit un même-crop cellule par cellule pour chaque paire. L'indépendance des bords est donc notée prudemment et reste à confirmer par padded-canvas.

Les rendus live ont été produits à 8 pixels par cellule pour comparer les vues complètes. Cette résolution peut sous-estimer les défauts d'échelle, de finition et les chevauchements d'une seule cellule. Une revue native 32 px/cellule reste obligatoire avant acceptation.

Le projet a changé pendant l'audit. Les recaptures M09–M13 réduisent le risque, mais une nouvelle mutation après le snapshot de validation peut rendre ce rapport partiellement obsolète. La prochaine phase devrait geler un snapshot, reconstruire une seule map à la fois et joindre les six preuves obligatoires avant toute comparaison finale.

## Ordre de reprise recommandé

1. Contrat intérieur : M00 → M03I → M17.
2. Contrat gare/quai/rail : M03 → M04 → M10.
3. Contrat eau et berges : M05 → M06 → M12.
4. Contrat forêt et exclusions : M01 → M07 → M08 → M09.
5. Contrat relief/terrasses : M02, puis M14–M16 et M22–M24.
6. M18–M21, M25 et R01 comme reconstructions complètes, pas comme passes de décoration.

Statut proposé : **TO REVIEW**. Aucune map ne peut être déclarée visuellement acceptée sur la base de cet audit.
