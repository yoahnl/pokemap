# Le train de 17h42 — audit comparatif des maps et de la chasse

Date : 13 septembre 2026. Lot : **POST-WLD-FIDELITY-001 — Monde et narration / Post Bêta**. Statut proposé : **TO REVIEW**.

Projet canonique : `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42`. 39 maps relues : les 38 références numérotées, plus l’étage de la pension. Aucun export mobile ni validation artistique globale ne sont annoncés.

## Résultat et ordre de reprise

Les intérieurs Hanazuki récents tiennent bien la comparaison ; Aohara 15–18, la maison du garde 22, le train 23, le tunnel 31 et le dépôt 35 demandent une reconstruction importante. Les extérieurs souffrent surtout de chemins surdimensionnés, forêts trop régulières, rivières rigides et détails fonctionnels absents. Iwaori 30 et Kisaragi 37 doivent conserver leurs compositions approuvées.

Chasse : **103 nouvelles cases accessibles** sur cinq maps. La liaison native sur dix maps porte la capacité réellement accessible et active de **394 à 704 cases**. Le reste du gain vient d’herbes déjà peintes qui n’étaient pas correctement reliées aux rencontres.

Je reprendrais visuellement le village de Hanazuki 01 en premier pour suivre le parcours demandé, puis la route 03 et le sanctuaire 04 ; je garderais les intérieurs 05–11. Le prochain gros bloc serait Aohara, particulièrement ses quatre intérieurs. Ne pas refaire toutes les références avant de reconstruire : leur direction reste généralement bonne.

## Audit initial et méthode

Le projet démarre réellement dans la pension à l’étage, et non dans la map 01 du carnet. Le train est utilisé dès le premier départ, puis revient entre les régions. Les intérieurs d’une même ville sont des visites libres : leur ordre ci-dessous est un ordre de revue cohérent, pas une séquence obligatoire inventée.

Trois axes ont été examinés séparément : rendu natif contre référence, topologie/collisions/arrivées, et résolution réelle des rencontres par cellule. L’image panoramique fournie sert à observer l’alternance des lieux sûrs, routes sauvages, détours et boucles. Elle ne permet pas de mesurer une densité officielle de rencontres ou le temps de leveling de notre campagne.

Les 39 rendus initiaux proviennent du moteur natif à 32 pixels par case, sur une même révision. Les six maps travaillées sont rendues à nouveau ; Kodama retrouve finalement sa géométrie initiale après critique, tout en gardant la liaison native corrigée. Les propositions approuvées de la pension, des rizières, d’Iwaori et du sommet priment sur leurs références historiques. Les fichiers JSON de référence de la revue conservent les chemins et empreintes des images comparées.

Révision initiale : `sha256:27254bfe1e8731458ca93d983a9954ce49eb8330b14bb854ece149bce85a1f32`. Révision finale : `sha256:2cf2d717d94d73addfde73f695181071908028343ae4fe003939b06e58bf3be5`.

Avant mutation : sauvegarde du manifeste, des 39 maps et du carnet. Git initial propre. Aucune écriture Git autorisée ou effectuée. Aucun changement au moteur, aux catalogues, aux niveaux, aux collisions, aux connexions, aux warps, aux PNJ ni aux scènes.

## État des lieux dans le parcours

Les numéros restent ceux des références, pour retrouver chaque map. « Adapter » désigne un complément de plan ou une mise à jour des choix validés ; cela ne signifie pas jeter son style. Les défauts de décor cités restent à corriger : ce lot a modifié la chasse et actualisé des références ; les reconstructions de décor restent à faire.

### Prologue — la pension

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 05 bis — Pension de Hanazuki — étage | Conforme à la proposition approuvée | Aucun défaut majeur identifié sur ce rendu statique. | garder : La dernière proposition pension-reference est la bonne référence pour cet étage ; ne pas utiliser une variante historique. |
| 5 — Pension de Hanazuki | proche de la direction approuvée | Le centre reste assez dégagé, mais aucune rupture majeure de style observée ; comparaison littérale trompeuse car les lits ont été déplacés à l’étage sur demande. | adapter : Mettre la référence à jour avec alcôve, salon au rez-de-chaussée et dortoir séparé approuvés ; ne pas remettre les lits au rez-de-chaussée. |

### Hanazuki — visites libres, première route, départ

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 1 — Hanazuki — village | écart important | Forêt discontinue et très régulière ; grandes plages de sol nu ; relief sud largement aplati ; jardins et végétation bien moins riches. | garder : La référence donne déjà un village enveloppé par la forêt et des clairières hiérarchisées. |
| 6 — Maison au jardin | proche | Les tapis verts occupent davantage de surface ; composition plus orthogonale que la référence, sans défaut majeur qui justifie une refonte. | garder : La référence reste un guide valable de meubles et de proportions ; adaptation compacte acceptable. |
| 7 — Fleuriste de Hanazuki | proche | Quelques pots sont disposés très symétriquement et la pièce reste plus carrée ; polish éventuel seulement. | garder : Cette version récente respecte l’identité du fleuriste et les corrections approuvées. |
| 8 — Café de Hanazuki | proche | L’axe central paraît un peu nu ; alignement des tables très régulier ; pas de besoin de réintroduire l’escalier décoratif de la référence. | adapter : Retirer l’escalier de la référence si aucun étage n’existe ; garder son mobilier et sa chaleur. |
| 9 — Clinique de Hanazuki | proche | Tapis plus pâle et long ; espace à droite de l’accueil un peu vide ; aucune collision visuelle majeure des fauteuils avec le mur observée sur le rendu frais. | garder : Référence fonctionnelle et cohérente ; les corrections récentes ont rapproché le rendu. |
| 3 — Sentier des premières rencontres | écart modéré | La bande d’herbes est et la clairière sud-ouest sont sensiblement réduites ; rivière très rectiligne ; forêt en alignements ; pont latéral montré dans la référence absent du rendu. | garder : Bonne référence de première route avec chemin sûr, détour et poches de rencontres. |
| 4 — Colline du sanctuaire | écart important | Terrasses très vides, forêt dispersée, longs murs latéraux presque parallèles et rivière droite ; pont d’entrée étroit face au chemin ; impression moins enclavée et boisée. | garder : La référence explique bien le relief et l’ambiance sacrée ; enrichir le rendu plutôt que refaire cette direction. |
| 2 — Gare de Hanazuki | écart modéré | Lisières compactées en blocs et clairières plus nues ; relief riverain et jardins moins détaillés que la référence. | garder : Composition et rôle ferroviaire lisibles ; les raccords jouables peuvent rester adaptés. |
| 10 — Guichet d’Hanazuki | proche | Grande régularité des bancs et sol plus clair ; circulation plus généreuse, sans raison de refaire la map. | garder : Référence exploitable, adaptation actuelle convaincante. |
| 11 — Boutique générale d’Hanazuki | assez proche | Espace central entre comptoir et deux îlots plus vide que dans la référence ; les deux îlots ont le même assortiment et la même silhouette. | garder : La référence donne déjà une densité commerciale plus habitée ; un remplissage mesuré et une variation des rayons suffisent. |

### Train — dès le premier départ, puis entre les étapes

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 23 — À bord du Tsukikage | À reconstruire | Rendu lit comme deux grandes salles, sans caisse de wagon ni soufflet central lisible. Banquettes et petites tables trop peu nombreuses ; larges vides au sol. Fenêtres, portes et murs ne forment pas le même habillage ferroviaire compact que la référence. | adapter : Garder la direction artistique ; préciser quelles portes sont utilisables et le passage réel entre wagons. |

### Aohara

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 12 — Aohara — village des rizières | écart important | Façades répétées et moins variées ; jardins très nus ; forêt incomplète ; grande rivière angulaire ; ponts fins ; relief et petits équipements agricoles très simplifiés. | adapter : Conserver l’ambiance rurale, mais accorder alimentation des canaux et limites avec la nouvelle référence des rizières ; pas de refonte gratuite du style. |
| 15 — Guichet d’Aohara | très loin de la référence | Comptoir noir en L presque sans texture ; trois panneaux identiques ; banc peu lisible ; mobilier et décor trop rares ; grand tapis central et murs génériques ne reprennent pas le guichet rural. L’accès nord vers le quai montré dans la référence ne se lit pas dans le mur nord du rendu. | garder : La référence est riche, cohérente et suffisamment précise ; reconstruire le rendu à partir de ses objets. |
| 16 — Maison d’hôtes d’Aohara | très loin de la référence | Cloisons vertes isolées plutôt que chambres ; lits et table discordants ; réception noire rudimentaire ; décors muraux et objets de vie presque absents. | adapter : Conserver chambres, alcôves et palette bleue ; décider explicitement si l’escalier de la référence mène à un étage réel ou le supprimer du brief. |
| 17 — Coopérative d’Aohara | très loin de la référence | Grande salle presque vide ; comptoir noir non fini ; panneaux répétés ; absence de stockage dense, outils muraux, réserve et variété de fruits montrés dans la référence. | garder : Très bonne référence pour une boutique agricole distincte du magasin d’Hanazuki. |
| 13 — Rizières d’Aohara | composition proche, détails encore perfectibles | Rivière principale encore très droite ; arbres rangés par bandes ; clairières périphériques assez vides ; les herbes sauvages restent de petites touches à l’échelle de l’ensemble. | garder : Utiliser uniquement la référence irrigation-v3 actuelle ; l’ancienne référence incohérente doit rester abandonnée. |
| 14 — Moulin et épreuve des Rizières | écart important | Ponts très étroits, berges découpées anguleusement, forêt et talus clairsemés ; champs rectangulaires peu intégrés au relief ; moulin moins enclavé dans sa rive que la référence. La cascade nord apparaît comme un rectangle étroit posé au milieu d’une rivière plus large, sans front de falaise lisible à cet endroit. | refaite : Nouvelle référence moulin v2 : un circuit roue-rivière, un pont large, chemin sud continu et clairières ; l’ancienne reste archivée. La reconstruction jouable reste à faire. |
| 18 — Atelier et archives du moulin | très loin de la référence | Sol gris et murs verts génériques opposés au bois et à la pierre de la référence ; roue isolée sans mécanisme ; cloisons et mobilier clairsemés ; archives et outillage presque absents. | adapter : Garder l’atelier mécanique et les archives bois/pierre ; fixer le rôle de l’ouverture/escalier nord-est pour éviter un nouvel escalier sans destination. |

### Kodama

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 19 — Halte des cèdres de Kodama | Reprise importante | Quai gris beaucoup plus massif que le petit quai forestier de référence. Cabane isolée, manque de clôtures et de sous-bois ; sapins très régulièrement répétés. Rivière est segmentée en angles droits et moins encaissée. | garder : La composition forestière et les destinations de la référence sont cohérentes. |
| 22 — Maison de garde de Kodama | À reconstruire | Murs verts/crème et lit rose contredisent la cabane de bois chaleureuse et verte. Grand plateau central vide ; absence de poêle avec tuyau, bureau radio, rangements et patères de référence. Mobilier disparate et éléments proches des murs sans composition commune. | garder : La référence est compacte, meublée et cohérente ; problème de reconstruction, pas de référence. |
| 20 — Forêt de Kodama — boucle des bornes | Reprise importante | Pont réduit à une passerelle très étroite au milieu d’un sentier large. Chemin en anneau trop large et lisières peu variées ; bosquet central répétitif. Rivière aux angles carrés et berges pauvres en petits reliefs. | garder : Bonne boucle d’exploration et bons emplacements de chasse : le plan fonctionne. |
| 21 — Clairière sacrée et mémorial | Reprise importante | Arbre et petit temple sont séparés visuellement, alors que la référence les imbrique. Grande plage sableuse vide et forêt périphérique espacée. Lanternes et stèles perdent leur rôle de composition : très petites et dispersées. | garder : La référence donne déjà une bonne scène de recueillement compacte. |

### Yunomori

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 24 — Village et gare de Yunomori | Reprise importante | Source thermale remplacée par un bassin bleu de rivière ; vapeur et installation de bain absentes. Village trop étalé et routes pavées rectilignes ; bâtiments répétitifs et petits par rapport aux espaces ouverts. Pont rouge très fin et rivière presque parfaitement verticale. | garder : Le village thermal de référence a une identité forte et une bonne organisation. |
| 25 — Rue des auberges | Reprise importante | Bâtiments quasi identiques sans enseignes distinctives ; jardins et seuils peu détaillés. Bassin bleu sans vapeur ni clôture complète, donc identité onsen peu lisible. Grande chaussée grise uniforme, rivière verticale et pont rouge très mince. | garder : La référence donne déjà les bons détails de bains et d’accueil à reconstruire. |
| 26 — Sentier des cèdres | Reprise importante | Escaliers sans joues et raccords incomplets aux talus ; celui du milieu paraît posé sur le chemin. Rivière verticale étroite, bosquets uniformes ; longues franges vertes sans sous-bois. Plateforme de repos ressemble à un plateau posé, sans le relief et le mobilier de référence. | adapter : Conserver l’ambiance et le parcours, clarifier ou retirer la traversée de pierres dont la sortie ouest est ambiguë. |
| 27 — Cabine de signalisation | Reprise importante | Poste isolé dans une grande pelouse ; cour pauvre en accessoires et bois de service. Rivière droite bordée de peu de relief, viaduc plus mince que le ravin suggéré. Escalier sud et clôtures méritent un raccord précis au plateau. | garder : La référence explique bien la fonction technique du lieu et le relief. |

### Iwaori

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 28 — Gare d’Iwaori | Reprise importante | Grand quai gris très vide ; bâtiments et maisons sous-dimensionnés dans leurs places. Tunnel ouest posé devant un espace vert plutôt qu’encastré dans une vraie montagne. Rivière est droite et pont piéton très mince ; strates de roche trop peu profondes. | garder : Le bassin minier et le fret sont cohérents dans la référence. |
| 29 — Hameau des ouvriers | Reprise importante | Maisons espacées, cours vides et clôtures presque absentes : identité ouvrière peu racontée. Potager réduit à une grille de petites touffes ; manque cabanon, cultures variées, linge et réserves. Rivière très droite, falaise transversale et escalier sud à mieux raccorder. | garder : Bonne référence pour les usages domestiques et les terrasses, sans incohérence majeure à recréer. |
| 30 — Éboulis d’Iwaori | Retouches ciblées | Longue extension sud encore très régulière : deux masses d’arbres rangées de chaque côté des rails. Quelques grands aplats sablonneux et rocheux gagneraient de petites irrégularités de lisière. | adapter : Actualiser la référence de suivi avec les décisions approuvées : deux ponts, falaise basse, limite sud et tunnel accessible. Ne pas revenir à l’ancienne composition. |
| 31 — Tunnel de maintenance | À reconstruire | Relief en grandes bandes rectangulaires avec texture répétée, loin des parois irrégulières de la référence. Absence de charpentes, petits éboulis et vraies alcôves éclairées ; lampe isolée sans ambiance. Alcôve sud-est réduite à un petit objet bleu ; canal de drainage et grille non lisibles. | garder : La référence fournit un tunnel d’entretien clair, varié et fonctionnel. |

### Tsukikage

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 32 — Aiguillage de Tsukikage | Reprise importante | Aiguillage et rails très contrastés par rapport au terrain ; jonction à polir. Entrées de tunnel posées aux extrémités sans massif rocheux assez enveloppant. Grands aplats verts, herbes rectangulaires et bosquets uniformes remplacent les clairières sauvages de référence. | garder : Bon point de repère avec choix clair entre voie principale et dépôt. |
| 33 — Ligne envahie de Tsukikage | Reprise importante | Poches d’herbes en grands rectangles isolés, peu intégrées aux lisières. Rivière droite et mince ; pont du chemin paraît beaucoup plus étroit que la route. Forêt clairsemée et relief de bandes horizontales, sans les clairières et dénivelés irréguliers de référence. | garder : La référence est déjà un bon modèle de route avec chasse optionnelle et sentier sûr. |
| 34 — Gare abandonnée de Tsukikage | Reprise importante | Gare trop isolée derrière un grand quai nu ; peu de végétation sur les abords. Étang bleu uniforme aux bords anguleux, sans les reflets et roselières de la référence. Forêt organisée en blocs réguliers et grande route vide. | adapter : Préciser la voie de terminus et l’accès au quai ; conserver l’ambiance abandonnée et humide. |
| 35 — Dépôt de Tsukikage | À reconstruire | Grande salle presque vide : absence de rayonnages latéraux, roues, établis équipés, bidons et outillage. Portiques en bandes de murs pleines, sans poteaux en perspective ni structure d’atelier crédible. Sol clair uniforme et rails durs ; manque fosses de visite et marquages de sécurité. | garder : La référence explique bien l’atelier ; ses détails sont utiles, pas du remplissage. |

### Kisaragi

| Réf. / map | État du rendu | Prochaine correction | Référence |
|---|---|---|---|
| 36 — Village et gare de Kisaragi | Reprise importante | Maisons trop petites et isolées, place et chemins trop larges. Faible impression de village encaissé : falaises basses et régulières, arbres en blocs. Pont sud très mince, fleuve sans relief ; tunnel ferroviaire peu encastré. | garder : La référence définit déjà un village montagnard compact, différent des précédents. |
| 37 — Sentier du sommet | Retouches ciblées | Longues bordures latérales très verticales et arbres encore alignés par endroits. Quelques plateformes vertes et le belvédère restent plus nus que la référence. | adapter : La référence montre un observatoire en haut alors qu’une map38 existe pour cette destination : clarifier une connexion vers38, préserver l’ascension validée. |
| 38 — Observatoire du signal | Reprise importante | Parvis gris sans motif central et annexe détachée du dôme. Falaises en bandes grises rectilignes et rivières verticales ; relief monumental de référence perdu. Bancs et petits équipements du belvédère dispersés, composition de place peu finie. | garder : Bonne destination finale et silhouette forte ; reconstruction plus fidèle nécessaire. |

## Références : ce qu’il faut réellement refaire

Après autorisation supplémentaire de l’utilisateur, la référence du moulin 14 a été refaite avec imagegen : circuit bief/roue/restitution plus lisible, pont large, sortie sud et deux poches de chasse. Les rizières secondaires ont été retirées de ce plan pour éviter de dupliquer la map13 et son réseau d’irrigation. La nouvelle référence est la cible de reconstruction, pas une map jouable intégrée. Les autres adaptations restent ciblées :

- Pension 05 : deux niveaux, lits à l’étage, accueil en alcôve. La proposition approuvée de l’étage sert de référence complémentaire ; son escalier est conservé.
- Café 08 et intérieurs Aohara 16/18 : préciser un étage réel ou retirer toute suggestion d’escalier sans destination.
- Aohara 12/14 : revoir ensemble les niveaux d’eau, les canaux et les raccords ; une chute doit correspondre à une dénivellation lisible. Ne pas remplacer la référence logique déjà approuvée des rizières 13 par sa première version.
- Train 23 : préciser les portes actives et les passages entre wagons avant de refaire les meubles.
- Cèdres 26 : clarifier la destination de la traversée de pierres ; la supprimer si elle ne dessert rien.
- Iwaori 30 : actualiser le document avec deux ponts, falaise basse et accès tunnel validés.
- Gare abandonnée 34 : préciser le terminus et l’accès quai.
- Sommet 37 : montrer la connexion vers l’observatoire 38, sans dupliquer sa destination.

La nouvelle référence moulin v2 est active dans le carnet ; l’ancienne image est conservée et accessible en archive. Pour pension05, Iwaori30 et sommet37, les plans retenus sont maintenant accessibles séparément des références de style, sans comparer le rendu contre lui-même comme preuve de fidélité. Les autres adaptations listées restent des recommandations. Fichiers dans Assets/Audit-parcours-chasse/references ; recette imagegen et prompt exact dans reference-generation.json. La v1 avec deux rizières est une étude écartée, seule v2 est retenue.

## Chasse, leveling et comparaison avec le panorama fourni

Le panorama montre une structure utile pour notre projet : des villages sûrs, des routes boisées entre eux, des poches de rencontres assez larges pour y circuler, et des détours facultatifs à côté d’un itinéraire lisible. Il ne faut pas transformer chaque place ou chaque quai en zone sauvage, ni étendre une map simplement pour remplir sa bordure.

Le manque principal était autant fonctionnel que spatial : dix couches de hautes herbes sans comportement natif, encore accompagnées de 64 rectangles de rencontres. Plusieurs rectangles ne couvraient qu’une partie de l’herbe ; à Kodama, les dix cases de rencontres étaient hors des hautes herbes. Les rectangles d’herbes ont été supprimés après liaison native. Les rencontres sur ballast du tunnel sont préservées.

| Map | Niveaux sauvages | Herbes accessibles avant | Chasse active accessible avant → après | Nouvelles cases finales |
|---|---|---:|---:|---:|
| Sentier des premières rencontres | 3–6 | 102 | 95 → 114 | +12 |
| Colline du sanctuaire | 3–6 | 20 | 20 → 20 | +0 |
| Rizières d’Aohara | 8–12 | 36 | 36 → 96 | +60 |
| Forêt de Kodama — boucle des bornes | 12–17 | 68 | 0 → 68 | +0 |
| Sentier des cèdres | 17–22 | 36 | 36 → 46 | +10 |
| Éboulis d’Iwaori | 22–28 | 65 | 27 → 77 | +12 |
| Aiguillage de Tsukikage | 28–33 | 78 | 78 → 78 | +0 |
| Ligne envahie de Tsukikage | 29–34 | 148 | 54 → 148 | +0 |
| Gare abandonnée de Tsukikage | 29–34 | 12 | 12 → 12 | +0 |
| Sentier du sommet | 34–38 | 36 | 36 → 45 | +9 |

Au total : 839 cases peintes, dont **704 accessibles** et actives. Ne pas confondre volume décoratif et capacité jouable. Sur la Ligne envahie, 91 cases anciennes restent dans une composante isolée sans arrivée, plus une case bloquée ; elles sont exclues du total accessible. Les autres exclusions correspondent notamment aux obstacles et aux arbres.

Le moulin reste à zéro : ses dégagements actuels ne permettent pas une poche propre sans empiéter sur les chemins ou les équipements. Les rizières renforcées offrent une zone de chasse à cette étape. Une clairière au moulin sera pertinente après sa reprise hydraulique. Je n’ajoute pas de nouvelle map de chasse avant d’avoir testé le rythme réel de la campagne.

Sept entraînements régionaux existent déjà et sont configurés comme réaffrontables, avec un choix de combattre, soins avant/après et événements réutilisables sans condition de victoire : équipes niveaux 6, 12, 17, 22, 27, 34 et 38. Vérification issue des PNJ, registres et scènes ; ces combats n’ont pas tous été rejoués manuellement.

Les niveaux sauvages suivent déjà les régions, de 3–6 à Hanazuki à 34–38 au sommet. Tables, espèces, poids et probabilités sont inchangés. La génération de rencontres a été testée avec probabilité forcée uniquement en mémoire : cela prouve les espèces/niveaux autorisés, pas une vitesse de leveling. Un parcours avec une équipe de plusieurs Pokémon reste nécessaire pour mesurer les niveaux d’arrivée et le temps d’entraînement.

## Implémentation et fichiers concernés

Actions existantes de l’API canonique : `smart_tile.cell.paint`, `smart_tile.layer.set_encounter_behavior`, `gameplay_zone.delete`, puis `smart_tile.cell.erase` pour le polissage. Chaque mutation passe par plan, révision attendue et apply ; aucune édition brute des maps JSON. Les rencontres suivent désormais les cellules de la couche d’herbe. Supprimer une cellule d’herbe supprime donc sa source de rencontre.

Dans chacun des dix fichiers ci-dessous : seule la couche Smart Tile d’herbes reçoit `encounterBehavior`, et les anciens rectangles de rencontres en herbe sont retirés de `gameplayZones`. Dans cinq fichiers, le champ sémantique de cette couche est aussi étendu. Le manifeste qui contient le catalogue d’animation et d’occlusion est identique octet pour octet.

- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/route-hanazuki.json` : liaison native, retrait de 16 rectangles, +12 cellules.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/hanazuki-sanctuaire.json` : liaison native, retrait de 3 rectangles.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/aohara-rizieres.json` : liaison native, retrait de 4 rectangles, +60 cellules.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/kodama-foret.json` : liaison native, retrait de 4 rectangles.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/yunomori-cedres.json` : liaison native, retrait de 3 rectangles, +10 cellules.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/iwaori-eboulis.json` : liaison native, retrait de 3 rectangles, +12 cellules.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/tsukikage-aiguillage.json` : liaison native, retrait de 11 rectangles.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/tsukikage-ligne.json` : liaison native, retrait de 5 rectangles.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/tsukikage-gare.json` : liaison native, retrait de 12 rectangles.
- `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/maps/kisaragi-sommet.json` : liaison native, retrait de 3 rectangles, +9 cellules.

- `/Users/karim/Desktop/assets/le train de 17h42 V2/Suivi des maps/donnees.json` : 39 entrées, ordre du parcours, verdicts, recommandations de référence, capacité de chasse et empreintes fraîches.
- `/Users/karim/Desktop/assets/le train de 17h42 V2/Suivi des maps/index.html` : mêmes données embarquées ; lecture des écarts, références et chasse ; ajout de l’étage au carnet. Les anciennes pages d’étude restent indiquées comme historiques.
- `/Users/karim/Desktop/assets/le train de 17h42 V2/Suivi des maps/rendus/` : les 38 PNG du carnet actualisés depuis les rendus natifs et ajout de `hanazuki-pension-etage.png`. Les noms exacts sont listés dans `site-refresh.json` et correspondent aux IDs du carnet.
- `/Users/karim/Project/pokemonProject/documentation/reports/editor/audit_comparatif_maps_train_17h42_2026-09-13.md` : présent audit consolidé. Seul nouveau document du dépôt ; aucun fichier source moteur modifié.

Artifacts locaux de cette tâche sous `/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse` : `preflight.py`, `prepare_hunts.py`, `apply_hunts.py`, `polish_hunts.py`, `polish_last.py`, `polish_finish.py`, `publish_audit.py`, `navigation.dart`, `verify-encounters.dart`, `render_test.dart`, `render_after_test.dart`, `render_last_test.dart`, `runtime_test.dart`; leurs JSON de plans, opérations, sauvegardes, tests, revues, images et journaux. L’inventaire exhaustif est dans `artifact-inventory.json`. Ce sont des outils et preuves locaux, pas des fichiers runtime supplémentaires du jeu.

## Vérifications et limites

- API projet : `valid=true`, structure et références sans diagnostic. Révision finale `sha256:2cf2d717d94d73addfde73f695181071908028343ae4fe003939b06e58bf3be5`.
- Le catalogue Pokémon autorise le playtest ; ses avertissements préexistants sur les méthodes d’évolution restent présents. `capabilityTruth` signale l’absence de capacités promues ; la certification de capacités n’a pas été demandée. Ce lot ne certifie pas toutes les fonctionnalités du moteur.
- Résolveur public `map_core` et génération `map_gameplay` : 141 vérifications, 0 échec. 839 sources natives et autant de rencontres générées contrôlées ; 35009 cellules hors herbes sans source de rencontre sur les onze maps auditées.
- Navigation : calcul des composantes atteignables depuis les arrivées et les passages de connexion libres, puis contrôle des destinations. 17 arrivées warp/spawn libres et 20 routes accessibles (14 warps, 6 connexions). Aucune arrivée bloquée ni sortie devenue inaccessible ; collisions, connexions et routes de contrôle identiques. Les cellules de bord boisées ne sont pas présentées comme des points de passage.
- 28 autres maps préservées, et moulin conservé via les invariants de la onzième map auditée : 29 maps au total restent inchangées, dont tous les intérieurs et leur escalier.
- Rendus : 39 rendus initiaux, six maps recapturées, puis trois recapturées après les dernières coupes. Les autres images proviennent de captures antérieures de contenu visuel inchangé ; chaque entrée du carnet conserve sa révision de provenance. Le harness Flutter compile et utilise le véritable adaptateur natif ; une révision stable est vérifiée pendant le rendu.
- Player automatisé : entrée/sortie d’une poche à Aohara, froissement local et retour au repos ; occlusion des pieds rendue réellement. Pour isoler ce test visuel, rencontres désactivées seulement dans la copie en mémoire. Les rencontres sont vérifiées séparément par le résolveur et la génération gameplay.

Commandes exécutées (chemins complets des harnesses sous le dossier d’artefacts ci-dessus) :

```sh
python3 "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/preflight.py"
python3 "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/apply_hunts.py"
python3 "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/polish_hunts.py"
dart --packages=/Users/karim/Project/pokemonProject/packages/map_gameplay/.dart_tool/package_config.json "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/navigation.dart" after
dart "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/verify-encounters.dill"
flutter test "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/render_test.dart" --reporter expanded
flutter test "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/render_after_test.dart" "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/runtime_test.dart" --reporter expanded --concurrency=1
npm run check  # tools/pokemap_mcp
npm test       # tools/pokemap_mcp ; inclut npm run build
bash tools/scripts/check_markdown_hygiene.sh
```

Résultats exacts : rendu initial `All tests passed!` (+1) ; capture des six maps et Player `01:52 +3: All tests passed!` ; dernier rendu des trois maps retouchées et Player `01:14 +3: All tests passed!`. `npm run check` exit 0 ; `npm test` : tests 80, pass 80, fail 0, skipped 0, build TypeScript réussi. Catalogue MCP stdio vivant : les quatre actions sémantiques requises sont présentes. Vérifications navigation et rencontres : exit 0, 141/141. Le test Player mesure 276 pixels du personnage masqués sur une bande de 12 pixels et vérifie entrée, sortie et retour de l’animation au repos. Harnais Flutter réapés après les suites. Aucune analyse Dart globale nécessaire : aucun code produit Dart modifié ; les harnesses ont compilé et été exécutés. Aucun build/export complet du jeu demandé : le build pertinent est la compilation du harness runtime et du serveur MCP, sans modification du moteur.

## Passes et critique finale

- Audit / architecture : deux revues visuelles indépendantes, 01–18 plus étage et 19–38 ; inspection séparée de la navigation/chasse. Verdict : écarts artistiques réels, tables existantes exploitables, liaison native absente.
- Implémentation : portée volontairement réduite à cinq agrandissements et dix liaisons natives. Les ouvertures de nouvelles clairières impliquant terrain, eau ou forêt sont reportées dans les recommandations.
- Tests : résolution de chaque case, espèces/niveaux, invariants du projet et navigation. Les contrôles ne mesurent pas le temps de progression XP.
- Build / validation : vrai rendu runtime Flutter, Player automatisé et serveur MCP compilé. Aucune nouvelle sémantique d’auteur à exposer ; les actions existantes sont utilisées et leur présence est contrôlée dans le catalogue MCP vivant. Pas de clic d’édition manuel dans l’éditeur : transport manuel N/A pour cet audit de données, aucune nouvelle commande UI.
- Critique finale : le premier essai techniquement valide créait des filaments, cornes et débordements visuels près des falaises. 58 cases nouvelles ont été retirées après revue à l’échelle des tuiles ; aucune ancienne herbe supprimée. Nouveaux rendus et contrôles après cette correction. Les tests de collision seuls auraient laissé passer ce défaut.

Auto-critique : cette intervention répare et renforce la chasse, mais ne rend pas à elle seule les 39 maps fidèles aux références. L’équilibre XP, le parcours complet et l’acceptation artistique restent à revoir avec le joueur. Le moulin a une référence refaite, les plans validés ont été ajoutés ; les autres recommandations ne sont pas des images refaites. Les lots globaux FG-100 / FG-108 ne sont pas clos ni modifiés par ces preuves locales.

Suivi : ticket existant POST-WLD-FIDELITY-001, domaine Monde et narration / Post Bêta. Aucun ticket ni périmètre bêta ajouté. Statut à laisser TO REVIEW après dépôt des preuves, jamais DONE sans décision utilisateur.


## Livraison contrôlée

- Carnet : 39 maps, 82 liens d’images existants, deux blocs JavaScript parsés par `node --check`, JSON externe identique au JSON embarqué. Pas de test interactif du navigateur dans cette passe.
- Référence du moulin : génération intégrée **image_gen**, v2 retenue dans `/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/references/aohara-moulin-reference-v2.png`. Prompt exact et itération écartée archivés dans `reference-generation.json`. La critique indépendante valide la composition ; le raccord du bief à la roue, masqué par le toit, doit être explicité lors de la reconstruction. Le concept est plus lissé que le raster natif : réutiliser sa composition et reconstruire à l’échelle HGSS, ne pas importer le fond comme map.
- Pension, Iwaori, sommet : trois plans retenus ajoutés aux liens du carnet ; les références historiques de style restent visibles. Étage de la pension ajouté comme 39e entrée ; aucune régression de son escalier.
- Critique après coupes : Cèdres et Iwaori relus par le réviseur 19–38 ; dernière passe parent sur Aohara, Kodama et Kisaragi dans `parent-final-critique.json` et `final-grass-crops.png`. Les contours restants sont compacts ; aucune nouvelle zone ne recouvre un chemin dans ces vues.
- `git diff --check` : exit 0. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` Le budget d’un document correspond à l’audit demandé.
- Git final : uniquement `?? documentation/reports/editor/audit_comparatif_maps_train_17h42_2026-09-13.md`. Aucun commit, push, branche, rebase, export ou changement moteur.

Dernières commandes complémentaires :

```sh
python3 "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/polish_last.py"
python3 "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/polish_finish.py"
flutter test "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/render_last_test.dart" "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/runtime_test.dart" --reporter expanded --concurrency=1
python3 "/Users/karim/Desktop/assets/le train de 17h42 V2/Assets/Audit-parcours-chasse/publish_audit.py"
```

Les preuves et empreintes finales sont dans `gameplay-final-receipt.json`, `encounter-validation.json`, `render-last-proof.json`, `runtime/runtime-proof.json`, `site-verification.json` et `artifact-inventory.json`. Le carnet garde les trois états distincts : rendu actuel, référence de style/cible, plan retenu.
