# Diagnostic des limites et architecture des grands catalogues Avelune

Date : 18 octobre 2026. Auteur : Tom. Périmètre : diagnostic et solution proposée, sans implémentation du moteur ni reprise de la fabrication FRLG.

## 1. Verdict

Les limites sont des protections définies par Avelune, pas des limites Apple, Android ou Flutter exprimées en nombre d’assets. Leur rôle de sécurité est justifié. Leurs valeurs actuelles ne constituent pas une capacité produit démontrée sur appareil.

Trois sujets distincts se cumulent :

1. Le pack FRLG dépasse le nombre de supports techniques autorisés par `.aveluneassets`.
2. Un grand projet peut ouvrir dans Studio et dépasser ensuite les quotas JSON de `.avelunegame`.
3. Passer les quotas ne garantit ni un pic mémoire acceptable ni des transitions fluides.

La recommandation est une architecture commune de catalogues partitionnés, indexés et chargés à la demande, avec projection runtime des dépendances utiles, admission mémoire avant décodage et publication transactionnelle. La représentation FRLG doit également être corrigée : le générateur crée une matière et un groupe de connexion par contexte graphique, même lorsque le besoin est un motif visuel.

Une garantie sérieuse comporte des invariants vérifiables, des budgets d’exécution et une matrice de matériels certifiés. Il serait faux de garantir les performances de tout jeu arbitraire sur tout téléphone à partir de ce diagnostic.

## 2. Audit initial et traçabilité

La demande remplace explicitement l’objectif de terminer le pack. Aucun export ou import FRLG supplémentaire n’est lancé pour ce diagnostic.

- Dépôt : `/Users/karim/Project/pokemonProject`.
- HEAD initial observé : `56486456749b7ef0c7978ebdd914bbc21cccd8ae`.
- État initial : 336 chemins modifiés ou non suivis, issus des travaux antérieurs ou concurrents. Cet état ne constitue pas une base propre ni figée.
- Aucune écriture Git autorisée ou effectuée.
- Suivi : domaine existant [14. Monde, exploration et narration — Post-bêta](https://app.notion.com/p/3bf197a7bfa581bbb13adf367721992f), contexte existant [POST-WLD-ASSET-PACK-001](https://app.notion.com/p/3fb197a7bfa581379199ceec8afe5486).
- Conversation de référence lue : « Évaluer l’import des maps via MCP », `01a10312-8010-7fc2-8084-d29355efb66b`.
- Skills lus : `systematic-debugging`, `using-pokemap-mcp`, `verification-before-completion`, index `skills/README.md`. Règles de rapport : `codex_rule.md`.

Les sources actuelles du dépôt et les preuves locales ont été confrontées à la conversation et aux pages Notion. Les anciennes observations de performance restent identifiées comme historiques.

## 3. Pourquoi les limites existent

Le commit `280e24c64b231784646172d7d2c39e4e5d3826ac`, du 16 octobre 2026, introduit la politique des packs d’assets dans le lot P04.

Le plan canonique l’annonce sans ambiguïté : « Ces chiffres sont des plafonds proposés et testables, pas des performances mesurées ».

Sources :

- `documentation/reports/avelune_studio/plans/2026-10-16_asset_context_and_asset_packs_implementation_plan.md:307–328`.
- `packages/map_distribution/lib/src/resource_pack_security_policy.dart:52–74`.
- `packages/map_distribution/lib/src/game_package_security_policy.dart:36–51` ; historique initial `ab72e015f`, 25 juillet 2026.

Les protections couvrent des risques différents : saturation disque et cache de staging, nombre de fichiers, consommation mémoire de parsing, JSON ambigu ou profond, cycles et références invalides, images à énorme surface décodée, réponses MCP trop lourdes, concurrence et transactions interrompues. Elles doivent rester actives.

Le nombre de ressources est une approximation de coût, insuffisante à elle seule : une ressource peut être une petite tuile ou un atlas de plusieurs centaines de Mio une fois décodé. Une petite archive compressée ne mesure pas le coût de ses textures.

Les constructeurs permettent de **réduire**, pas d’augmenter, les plafonds normatifs V1. Les getters bornent la valeur par le maximum du format. Passer `maxSupports: 50000` ne contourne donc pas la limite.

## 4. Les enveloppes réellement appliquées

| Dimension | `.aveluneassets` V1 | `.avelunegame` actuel |
| --- | ---: | ---: |
| Archive | 512 Mio | 1 Gio |
| Somme des contenus utiles | 500 Mio | 1 Gio |
| Entrées de contenu ZIP | 20 000 | 20 000 |
| Manifeste d’archive | 4 Mio | 4 Mio |
| Catalogue JSON du pack / chaque JSON du jeu | 32 Mio | 32 Mio |
| Valeurs JSON par document | 1 000 000 | 1 000 000 |
| Profondeur JSON | 128 | 128 |
| Ressources logiques avec dépendances | 10 000 | Pas le même compteur |
| Supports techniques cumulés | 10 000 | Pas le même compteur |
| Entrées des collections projet sélectionnées | Sans équivalent direct | 100 000 |
| Hiérarchie contrôlée | 1 024 entrées ; profondeur 32 | 1 024 entrées ; profondeur 32 |
| Fichier individuel | 256 Mio | 256 Mio |
| Image | 8 192 par côté ; 67 108 864 pixels | Même plafond |
| Stage de pack | 2 Gio | Politique distincte |

Les supports comprennent les matières, groupes de connexion, atlas, animations, motifs, catégories, familles, dossiers/groupes de tilesets, snapshots de bordures et définitions de personnages. Ils se partagent **une seule enveloppe de 10 000**, pas une enveloppe par famille.

Sources : `resource_pack_installation_catalog.dart:8–21`, `resource_pack_dependency_graph.dart:84–104`, `resource_pack_inspector.dart:214–232`.

Les plafonds d’interface et de transport sont encore distincts : pages publiques 200 lignes/256 Kio, patches de sélection de 200 identités, une opération longue simultanée par projet. Augmenter ces valeurs ne résout pas le catalogue.

### Diagnostic insuffisamment précis

`resource_pack_projection.dart:390–400` regroupe trois dépassements sous `resource_limit_exceeded` : ressources, supports et fichiers. Le message ne fournit ni dimension ni valeur observée.

Le builder possède des erreurs plus précises : `resource_limit`, `support_limit`, `catalog_too_large` (`resource_pack_builder.dart:95–115`). La première erreur de projection masque les suivantes.

La formulation précédente « ce n’est pas la taille du JSON » était donc trop catégorique. Le premier refus observé FRLG est un compteur de supports ; d’autres quotas peuvent être atteints ensuite.

## 5. Mesures FRLG actuelles

Source de préparation : `/Users/karim/Project/Avelune Packs/FRLG-2026-10-17/pack-spec-final-candidate-16.json`.

SHA-256 : `3e951b895541d7ff42ddca426708e440fb127371c1fcb37e9c598e9e1732fe5c`.

| Mesure | Valeur |
| --- | ---: |
| Ressources principales préparées | 9 867 |
| Matières | 11 571 |
| Motifs | 9 791 |
| Animations | 1 273 |
| Atlas Smart Tile | 717 |
| Catégories Smart Tile | 346 |
| Catégories de décors | 578 |
| Familles | 962 |
| Somme de ces sept tableaux de supports | 25 238 |
| JSON préparatoire indenté | 65 624 419 octets |
| Même document minifié UTF-8 par Python | 33 734 316 octets |
| Valeurs JSON du document préparatoire | 1 666 641 |
| Valeurs du seul `smartTileCatalog` | 1 351 313 |
| Taille minifiée de ce seul catalogue | 25 483 129 octets |

La somme de tableaux n’est pas la fermeture publiée exacte : certains supports inutilisés sont exclus, et d’autres types sont ajoutés. En particulier, la projection indexe les groupes de connexion distincts des matières (`resource_pack_projection.dart:303–309`). Ils ne sont pas inclus dans la somme de sept tableaux ci-dessus.

Le document préparatoire n’est ni le `catalog.json` projeté ni le `project.json` final. La projection remappe les identifiants et omet certains champs. Aucun poids d’une archive16 valide n’est inventé : son export s’est arrêté sur `resource_pack.resource_limit_exceeded`.

### Origine de la multiplication des matières

`completion-work/t00-native-bank-completion-16/prepare.py:422–429` crée, pour chaque contexte :

1. Une matière avec son propre ID et groupe de connexion.
2. Une règle ciblant cette matière.
3. Un motif portant les mêmes parties visuelles.

La déduplication des motifs à `:433–449` partage les visuels identiques mais ne réduit pas les matières et règles. Il reste 11 283 règles natives et 11 285 matières préfixées `frlg-native16-`, dont deux matières de support pour les fonds.

Cela n’est pas une propriété intrinsèque des graphismes FRLG. C’est un choix de représentation du générateur. Les matières ayant une vraie sémantique de raccordement, collision, activation ou gameplay doivent rester distinctes.

### Piste vérifiée au niveau des contrats

Un motif peut porter ses parties visuelles sans matière unique par contexte :

- `smart_tile.dart:615–625` : cellule de motif avec parties visuelles, effacement et collision ; pas de `materialId`.
- `smart_tile_catalog_validation.dart:679–687` : parties seules valides.
- `smart_tile_pattern_operations.dart:86–95,182–207` : matière optionnelle à l’application.
- `smart_tile_layer_visual_resolver.dart:253–261,409–440` : rendu autonome des parties, avec preset support compatible requis.

Pour les banques uniformes purement graphiques, des motifs fidèles et dédupliqués avec un preset support minimal peuvent remplacer la duplication matière/règle par contexte. Cela reste une option à implémenter et prouver ; aucun catalogue n’a été modifié pendant cet audit.

Fusionner toutes les matières puis conserver les règles actuelles serait incorrect : les centres deviendraient identiques, avec ambiguïté de résolution (`smart_tile_resolver.dart:321–325`). Les IDs influencent aussi le déterminisme. `eraseMaterial` peut effacer le sol sous-jacent ; `collision: inherit` ne crée pas une collision.

Les preuves exigées incluent les 325 matrices natives, pixels/couches, animations, peinture, recouvrement, effacement, mélanges entre banques, collisions et identité des variantes. La couverture des graphismes ne doit pas être réduite pour passer un quota.

### Une version précédente passe déjà près du plafond de nœuds

Lecture ZIP en mémoire de `completion-work/FRLG-prequalification-14.aveluneassets` :

- `catalog.json` réel : 20 952 093 octets, **992 582 valeurs JSON**, CRC ZIP sans défaut détecté par `ZipFile.testzip()`.
- SHA du catalogue : `4626e4fbc6bb03e3686595b14ef448c8bf4e1ca3d5ef2445d959d8798eccc116`.
- Cette lecture est un contrôle de contenu, pas une réinspection complète du format par le code actuel.

Le `project.json` local importé14 mesure 26 098 073 octets et 1 190 018 valeurs. Son SHA est `e5d940fd037ed0ca07da54239a5998785983cb1bf0ce67dde6ba3bbc4c305dfe`. S’il était embarqué tel quel, il dépasserait le quota structurel du jeu. Cela ne mesure pas la sortie d’une projection runtime qui peut retirer des données.

## 6. Ce que l’autre conversation avait trouvé

La conversation « Évaluer l’import des maps via MCP » a rencontré le problème sur Johto et `.avelunegame`.

La page Notion du domaine14 contient déjà : « Johto — justification des quotas et mesure complémentaire v2603 » et « Exigence utilisateur — découper les données des grands jeux ».

Preuves locales relues sous `/Users/karim/Desktop/pokeMap Project/Remastered Kanto Johto/conversion/johto-essential-interiors-20261008/proof/` :

| Sonde historique | Taille résultante | Valeurs JSON |
| --- | ---: | ---: |
| v2603 : brouillons publiés allégés et valeurs par défaut omises | 24 396 989 octets | 1 104 407 |
| v2605 : sérialisation sparse seule | 28 972 209 octets | 1 310 973 |

Les deux sondes partent de 1 474 415 valeurs. Elles déclarent `diagnosticOnly=true`, `nativeWrites=0`, `productionCompilerChanged=false`, `standardPackageBuilt=false`, `actualPlayerTested=false`. Les runs sont terminaux avec `exitCode=0` et sources protégées inchangées.

Elles démontrent qu’être sous 32 Mio ne suffit pas. Elles ne prouvent pas un paquet standard valide ni des performances sur téléphone.

L’exigence déjà enregistrée est cohérente avec ce diagnostic : un seul fichier de jeu transférable, petit index versionné, catalogues internes bornés, dépendances partagées, chargement par carte, cache borné et sauvegardes indépendantes des blocs chargés. Le découpage ne doit pas être suivi d’une concaténation intégrale au démarrage.

Une ancienne mesure Notion rapporte 725,403 s pour qualifier 15 brouillons sur un manifeste de 40 799 599 octets. Elle signale le coût des inspections répétées Studio/MCP ; ce n’est pas un benchmark reproduit aujourd’hui.

## 7. Où les contrats actuels divergent

| Frontière | Comportement observé | Conséquence |
| --- | --- | --- |
| Ouverture authoring locale | Lecture entière ; isolate au-delà de 1 Mio ; `jsonDecode` puis modèle complet | Pas les mêmes quotas que l’inspection d’un jeu |
| Import d’un pack | Fermeture typée puis fusion avec les catalogues cible | Un pack valide isolément ne suffit pas à prouver le budget après fusion |
| Export jeu | Certaines projections de ressources et règles existent déjà | Optimisation partielle, pas fermeture exhaustive de tous les catalogues |
| Inspection jeu | Quotas JSON et validation globale | Projet ouvrable localement mais non distribuable possible |
| Démarrage mobile | Parse hors UI mais manifeste complet | Isolate protège la réactivité, pas la taille résidente du modèle |

Sources principales :

- `map_authoring/lib/src/workspace/project_open_service.dart:61–72,135–142`.
- `map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart:517,1175–1194`.
- `map_authoring/lib/src/domains/distribution/runtime_smart_tile_rule_projection.dart:10–15,35–78,105–128`.
- `map_authoring/lib/src/domains/distribution/runtime_unused_model_projection.dart:33–72`.
- `map_distribution/lib/src/game_package_content_validator.dart:139–157`.
- `apps/pokemap_hub/lib/features/session/application/services/hub_runtime_startup_bootstrap.dart:213–219,354–359`.

Le compteur des 100 000 entrées projet sélectionne des collections de premier niveau, mais omet `smartTileCatalog` et `resourceLibraryCatalog`. Ses contrôles de hiérarchie ne reflètent pas non plus toutes les hiérarchies du pack. Sources : `game_package_project_validator.dart:126–189`.

Il faut un contrat commun d’admission, avec des profils adaptés à l’auteur, à la publication et à la carte active. Un contrat commun ne signifie pas forcer les trois usages à garder le même ensemble de données en mémoire.

## 8. Mémoire et rendu : points solides et risques réels

### Ne pas confondre PNG et mémoire

Les 429 entrées d’assets16 correspondent à 393 PNG physiques distincts. Leurs octets encodés totalisent **3 619 229**. La somme théorique de leurs surfaces RGBA8 est **257 765 376 octets**, soit **245,82 Mio**.

Ce n’est pas une mesure RSS, GPU ou du jeu actif ; toutes ces images ne sont pas nécessairement chargées simultanément.

Le PNG `frlg-t05-cut-leaves-eight-particles.png` mesure 4096×2048 : **32 Mio** de surface RGBA pour **50 803 octets** encodés. `native-support-00.png` mesure 4096×896 : **14 Mio** de surface RGBA.

Le plafond d’image8192² autorise **256 Mio RGBA pour une seule image**, avant codecs, copies, textures et autres données. Ce garde-fou de format n’est pas un budget mobile acceptable démontré.

### Ce qui existe déjà

- Runtime : sélection d’atlas référencés, single-flight, récence, caches et plans de rendu préparés. Il serait faux d’affirmer que tous les assets sont décodés à chaque frame.
- `PreparedSmartTileResolver` indexe les règles par matière (`smart_tile_resolver.dart:151–187`). Le rendu conserve des plans par calque (`map_layers_component.dart:789–821`).
- Studio : leases, LRU, chargement sérialisé et admission **avant décodage** ; budget résident par défaut256 Mio et budget de travail distinct. Sources : `studio_map_resources.dart:245–278`, `studio_image_store.dart:24–57,181–184,240–275`.
- Studio estime un transitoire à partir des octets encodés et des surfaces avant le décodage (`studio_resource_decoder.dart:95–117`).
- Export runtime : projections de règles et modèles déjà présentes. Elles conservent encore notamment des ensembles de matières, atlas et animations plus larges que la fermeture utile.

### Ce qui reste à corriger

1. Le runtime peut lancer les décodages de toutes les entrées d’un lot via `Future.wait`, sans concurrence bornée (`tile_image_loader.dart:527–559`).
2. Les trims64 Mio atlas/64 Mio bordures arrivent après chargement ; les ressources retenues et transitions peuvent dépasser ces budgets (`playable_map_game.dart:17295–17344`).
3. Un grand atlas est décodé entier, lu en RGBA puis découpé en images. L’image initiale, le buffer et des chunks peuvent coexister (`tile_image_loader.dart:337–415`).
4. La sélection d’une carte ajoute aussi des ressources de toutes les scènes du projet (`runtime_manifest_tilesets.dart:163–190`).
5. L’inspector de packs lit et décode intégralement chaque PNG pour vérifier sa validité (`resource_pack_inspector.dart:188–201,649–669`). Il ne retient pas toutes les images ici ; son CPU cumulé et son pic par image restent à maîtriser.
6. Certains chemins de persistance/projection reconstruisent encore un manifeste global (`atomic_project_manifest_persistence.dart:235`, `project_snapshot_map_projector.dart:137–162`).

Un découpage après décodage ne garantit pas un faible pic initial. Une pagination physique des atlas à la préparation peut aider, à condition de préserver chaque frame complète, ancrage, transformation, durée et collision avec comparaison des pixels. Aucun crop arbitraire ne fait partie de la solution.

## 9. Architecture recommandée

### 9.1 Un seul fichier visible, plusieurs unités internes

L’utilisateur continue d’installer **un `.aveluneassets` par univers** ou **un `.avelunegame` par jeu**. La partition est interne au format et au stockage installé.

Le manifeste d’entrée devient un index compact et versionné contenant l’identité de publication, les capacités, les cartes d’entrée, les références de catalogues et leurs empreintes. Il ne contient plus toutes les définitions développées.

Les catalogues sont des unités bornées de définitions typées. Les gros index doivent eux-mêmes être paginés ou organisés à plusieurs niveaux : déplacer tout le volume dans un énorme index ne résout rien. Les cartes sont déjà séparées ; il faut compléter les catalogues et les consommateurs.

Le stockage canonique peut rester en fichiers de données natifs. Un index disque dérivé et reconstructible peut servir la recherche et la résolution ; choisir SQLite ou un index fichier ne doit pas précéder le benchmark. Aucun éditeur ou moteur externe ne devient une dépendance runtime.

Les limites de chaque unité, le total global, les dépendances traversées, les images et les opérations simultanées restent contrôlés. Beaucoup de petits morceaux ne doivent pas contourner un quota global.

### 9.2 Résolution commune et identifiants stables

Les références restent typées par nature de ressource et identifiant, indépendantes du numéro de fichier. Le découpage ne change ni les IDs ni les choix déterministes des variantes.

Un index permet de localiser une définition sans charger toutes les autres. Les cycles interdits de hiérarchie et de dépendances, doublons d’identité, références manquantes, incompatibilités de versions et empreintes incorrectes sont refusés avant publication. Les boucles de navigation entre cartes et les cycles narratifs autorisés restent valides ; leur parcours utilise un ensemble visité et un budget de travail. La validation globale ne doit pas reconstruire tout le modèle avec toutes les images.

Les modèles et graphes restent dans `map_core`, le stockage dans les ports/adaptateurs existants, les transactions dans `map_authoring`, la validation de distribution dans `map_distribution` et le chargement de carte dans `map_runtime`. Studio, Hub, API et MCP utilisent ces contrats communs.

### 9.3 Bibliothèque d’auteur complète, jeu fermé sur ses besoins

Studio conserve tous les décors et variantes de la bibliothèque, même inutilisés. La consultation utilise des pages, filtres/index et aperçus à la demande.

La publication du jeu calcule une fermeture typée de **toutes** ses cartes, scènes et ressources globales nécessaires. Les ressources choisies dynamiquement doivent avoir un contrat déclaratif de dépendances ; sans ce contrat, le compilateur conserve le domaine concerné ou refuse de certifier sa réduction. Une recherche de chaînes n’est pas une preuve de fermeture.

Le Player charge une fermeture plus petite : carte active, état/scènes concernés et ressources globales nécessaires. Il précharge des voisines dans le budget restant ; la prélecture reste annulable. Les définitions non utilisées ne sont pas réhydratées en un `ProjectManifest` géant au démarrage.

La projection de publication ne modifie jamais le projet d’auteur. Les descriptions, brouillons, outils et presets d’édition n’ont pas à être résidents pendant toute partie mobile.

### 9.4 Publication atomique et sauvegardes indépendantes

Préparer une génération de fichiers immuables, vérifier leurs empreintes et références, puis publier un seul pointeur de génération/révision dans la transaction canonique. Une opération en cours n’est pas visible partiellement.

Réutiliser le CAS, les contrôles de révision, staging possédé, réservations et mécanismes crash/recovery/undo/redo existants. Le journal porte les changements et références nécessaires sans réécrire le catalogue complet à chaque geste. Les lectures d’une génération utilisent des leases ; aucun bloc encore utilisé ne peut être supprimé.

Les sauvegardes portent l’identité du jeu et de sa publication, la version du contrat de sauvegarde, les identités stables des ressources et l’état du jeu. Elles ne dépendent ni de l’adresse mémoire d’un objet ni du numéro physique d’un chunk. Les IDs stables seuls ne suffisent pas si leur sens change entre publications : après remplacement d’un package, le contrat doit établir la compatibilité de la sauvegarde ou la refuser explicitement. Aucune migration pré-1.0 implicite n’est ajoutée. Décharger/recharger une carte conserve inventaire, faits, états d’objets et progression dans une même publication compatible.

### 9.5 Admission mémoire commune, profils distincts

Réutiliser le principe Studio : réserver le coût résident et transitoire **avant** le décodage, évincer ce qui n’est plus retenu, borner la concurrence et refuser proprement si l’ensemble actif ne tient pas.

Le budget tient compte séparément du catalogue, buffers encodés, décodeurs, RGBA, textures, bordures et effets. Il faut mesurer aussi les allocations natives et la mémoire partagée ; un compteur Dart ne constitue pas tout le RSS.

Les profils Studio, iOS et Android peuvent avoir des budgets différents. Le budget256 Mio de Studio ne doit pas être copié aveuglément sur mobile. Les alertes mémoire doivent réduire la prélecture et les caches évincables. Les ressources actives ne sont pas supprimées au hasard pour satisfaire un compteur.

### 9.6 Limites normatives et capacité produit

Conserver les limites de défense par unité et ajouter un budget global adapté au format partitionné. Les valeurs globales doivent être choisies après mesure sur les matériels cibles et des jeux représentatifs.

Le projet est pré-1.0 : une rupture de version claire est préférable à des doubles lecteurs, migrations et fallbacks permanents ajoutés uniquement pour les formats anciens. Un format incompatible doit être refusé explicitement.

Ne pas supprimer la validation des PNG pour gagner du temps : un en-tête correct et un SHA authentique ne prouvent pas un contenu décodable. La validation peut être sérialisée et budgétée dans un worker, avec progression et annulation.

## 10. Lots précis pour réaliser la solution

Ces lots sont proposés, non implémentés. Ils ne changent aucune gate bêta.

| Lot | Modification ciblée | Preuve de sortie |
| --- | --- | --- |
| L0 — Mesure et admission | Calculateur commun : octets canoniques, valeurs, supports par type, graphes, pixels, résultat après fusion ; diagnostics `scope/dimension/observed/allowed` | Limite exacte et +1 ; plusieurs violations rapportées ; mêmes faits via Studio/API/MCP ; sources intactes |
| L1 — Représentation FRLG | Motifs et support minimal pour banques purement visuelles ; préserver matières de chemins/terrains sémantiques | Identité325 matrices, couches/animations ; peinture/effacement/mélange ; aucune perte de variante ou collision |
| L2 — Stockage partitionné | Contrat versionné, index paginé, définitions par unités, résolution par ID et snapshot immuable | Chargement d’une définition sans lecture intégrale ; références inter-unités ; corruption/cycles ; snapshot atomique |
| L3 — Transactions d’édition | Mutations et historique sur unités concernées ; leases et collecte des générations inutilisées | Même petite mutation sur catalogue1×/2×/4× sans réécriture globale ; crash/recovery/undo/redo ; projets concurrents isolés |
| L4 — Packs et publication jeu | Un conteneur visible ; quotas locaux/globaux ; fermeture typée avec dépendances dynamiques déclarées | Export/import/réexport ; multi-packs ; hash/modèle/rendu identiques ; aucun bloc partiellement installé |
| L5 — Player et mémoire | Résolution par carte, prélecture budgétée, admission avant décodage, concurrence bornée, catalogue session par identité/version | Aucun atlas non demandé décodé ; pics sous budget ; annulation/nettoyage ; états identiques après déchargement |
| L6 — Studio et transports | Recherche/index/pagination, ouvertures ciblées, persistance partielle, mêmes sémantiques API/CLI/MCP | Édition visible + sauvegarde/réouverture ; catalogue MCP vivant ; parité directe, JSONL, Studio, MCP |
| L7 — Certification | FRLG, Johto et charges1×/2×/4× ; Studio et appareils physiques cibles ; profil/release | Reçus de latence, frames, mémoire et disque ; capacités publiées ; aucun résultat déduit seulement d’un test Dart |

L0 et la preuve de L1 précèdent les décisions de dimensionnement. L2 est justifié par le besoin explicite des grands jeux Johto, indépendamment du fait qu’une optimisation FRLG puisse déjà résoudre son premier dépassement.

L5 peut réutiliser les mécanismes d’admission Studio dès que les contrats sont isolés proprement ; aucune dépendance du runtime à des classes UI Studio ne doit être créée.

## 11. Contrat de cohérence et de performances à certifier

### Invariants bloquants

- Toute identité demandée se résout dans la même génération ; aucune référence manquante, mélange de versions ou variation d’ID selon le découpage.
- Pixels complets, ancrages, ordre de rendu, collisions, activation et durées restent identiques.
- Une mutation/import/export est atomique ; fermeture ou crash ne laisse pas de publication partielle.
- Annulation, undo/redo et réouverture conservent les données et libèrent les ressources possédées.
- Sauvegardes identiques après éviction et rechargement des blocs ; identité de publication et contrat vérifiés lors d’un remplacement de package, avec refus explicite d’une sauvegarde incompatible.
- Les petits morceaux ne permettent pas de contourner les enveloppes globales.
- Requêtes et gestes sur une carte inchangée ne décodent pas les images supplémentaires d’une bibliothèque plus grande.
- Aucun import valide isolément ne contourne le contrôle du résultat fusionné.

### Mesures obligatoires

Tester un Mac Studio cible, le plus petit iPhone officiellement pris en charge et le plus petit Android officiellement pris en charge, puis un matériel intermédiaire. Documenter modèle, OS, RAM, fréquence écran, build, SHA, corpus, état froid/chaud et outils. Les modèles minimaux restent à fixer ; ce diagnostic ne les invente pas.

Mesurer ouverture/import/export, recherche et défilement, dessin et effacement, sauvegarde et réouverture, première carte, transitions, animations, pression mémoire, arrière-plan/reprise et longue session. Inclure des jeux avec de nombreuses petites définitions et des jeux avec peu de grosses textures.

Relever p50/p95/p99 des latences et frame times, frames hors budget, stalls, heap, RSS/empreinte native, textures et transitoires, pausesGC, octets lus/écrits et espace temporaire. À60 Hz, le budget de frame visé est16,67 ms ; à120 Hz,8,33 ms. Ce sont des objectifs de certification, pas des résultats mesurés ici.

Pour isoler la scalabilité, conserver la même carte et augmenter seulement la bibliothèque installée1×/2×/4×. L’ensemble des images décodées et le coût des gestes doivent rester liés au travail utile. L’installation et l’indexation globale peuvent croître avec le corpus, mais doivent être progressives et annulables.

Les plafonds mémoire en Mio et délais contractuels d’ouverture/transition doivent être figés à partir de la baseline réelle et de la marge sur les appareils minimaux. Aucun chiffre arbitraire n’est présenté comme garanti.

Sources externes officielles consultées :

- [Flutter — Performance profiling](https://docs.flutter.dev/perf/ui-performance) : profilage sur matériel physique en mode profile, limites des mesures debug/simulateur.
- [Flutter — Parse JSON in the background](https://docs.flutter.dev/cookbook/networking/background-parsing) : déporter le CPU ; ne remplace pas une stratégie de mémoire.
- [Flutter — ImageCache](https://api.flutter.dev/flutter/painting/ImageCache-class.html) : cache et références vivantes ; ne couvre pas automatiquement les caches d’images propriétaires du runtime.
- [Android — Games memory overview](https://developer.android.com/games/optimize/memory-overview) et [Android memory](https://developer.android.com/topic/performance/memory) : mémoire graphique/native, budgets et outils d’analyse.

## 12. Vérifications exécutées et limites

### Lectures et calculs

Recherches ciblées `rg`, inspection des politiques/projections/caches, historique `git log`, lectures Notion et conversation de référence ; calculs Python en mémoire des tailles UTF-8, valeurs JSON, inventaires et dimensionsPNG. Les valeurs JSON comptent chaque valeur/objet/liste, pas chaque clef, comme `_parseValue` dans `strict_json_structure_validator.dart:70+`.

Contrôle ZIP14 : `zipfile.ZipFile(...).testzip()` retourne `None`. Les mesures ne remplacent pas une inspection complète par le code de format actuel.

### Tests frais du package map_distribution

Depuis `packages/map_distribution` :

```text
dart test test/resource_pack_manifest_codec_test.dart test/resource_pack_inspector_test.dart --reporter expanded
→ exit1 ; 11 tests réussis, 39 échoués.

dart test test/resource_pack_manifest_codec_test.dart --plain-name 'every signed policy ceiling is immutable and may be lowered' --reporter expanded
→ exit0 ; 1 test réussi.

dart test test/game_package_inspector_test.dart --name 'never raises the normative Phase 0 security ceilings|rejects the exact normative byte and entry overflows' --reporter expanded
→ exit0 ; 2 tests réussis.

dart test test/resource_pack_manifest_codec_test.dart --plain-name 'encodes deterministically and accepts harmless JSON whitespace' --reporter expanded
→ exit1 ; échec isolé reproduit.
```

Le checkout actuel expose SmartTile9 et Border12, tandis que les fixtures des deux fichiers de packs restent sur SmartTile7 et Border10 (`resource_pack_manifest_codec_test.dart:25–28`, `resource_pack_inspector_test.dart:970+`). `ResourcePackCompatibility` exige les versions courantes (`resource_pack.dart:144–151`). L’échec isolé est `resource_pack.manifest_invalid`, et les fixtures d’inspector lèvent `Unsupported native resource codec version`.

Cette dérive préexistante/concurrente ne doit pas être masquée comme un résultat vert. Elle doit être résolue dans son chantier avant certification du nouveau format. Aucun correctif hors scope n’est appliqué ici.

Pas de test Flutter lancé, pas de build applicatif ni d’analyse Dart supplémentaire : aucun code produit modifié, objectif de cette tâche limité au diagnostic. Aucune performance mobile n’a été mesurée. Les anciens tests de mémoire Studio et baselines M1Pro/JIT ne certifient pas FRLG sur iOS/Android.

### Passes indépendantes

| Passe | Verdict |
| --- | --- |
| Audit architecture/sécurité — `limit_security_audit` | Fonction de sécurité légitime ; plafonds non calibrés comme capacité produit ; divergence ouverture/pack/jeu confirmée |
| Chargement/performance — `catalog_runtime_performance_audit` | Bases lazy/index/cache existantes ; pics runtime insuffisamment bornés ; motifs sans matière par contexte possibles sous preuves |
| Historique/Notion — `related_limits_history` | Autre blocage retrouvé ; exigences de partition déjà consignées ; sondes historiques ne valent pas certification mobile |
| Synthèse/solution — Tom | Partition commune et budgets d’exécution recommandés ; pas de hausse globale seule ni de suppression de variantes |
| Critique finale — `related_limits_history` | Aucun P0/P1 ; deux précisions P2 intégrées : sauvegardes liées à la publication et cycles autorisés distingués des cycles interdits ; mesures reproduites indépendamment |

## 13. Livrables, risques et clôture du diagnostic

Fichier créé pour ce diagnostic : ce rapport uniquement. Aucun code produit, projet, atlas, package ou fichier de tests modifié. Les suites peuvent produire leurs artefacts de compilation habituels ; aucune suppression de cache ou de source effectuée.

Risques conservés : calibrage matériel absent, versions de codecs en évolution concurrente, coût exact d’une fermeture16 non produit après refus de quota, dépendances dynamiques à recenser, coût mémoire natif/GPU non mesuré, calendrier de réalisation non estimé sans décomposition technique validée.

Auto-critique : l’architecture proposée répond au problème de scalabilité et protège la cohérence, mais n’est pas une implémentation ni une preuve de performances. Elle exige des ruptures de contrat, une couverture de dépendances exhaustive et une certification sur appareils. Un découpage de fichiers sans changement du chargement et des transactions serait insuffisant. Une optimisation de la représentation FRLG seule ne satisfait pas le besoin déjà exprimé des très grands jeux Johto.

État final observé : HEAD `6d0134cd920f35e00268e6361e28192a70d7143d`, 314 chemins modifiés/non suivis. HEAD et travaux tiers ont évolué pendant la lecture ; aucune opération Git d’écriture de notre part. Notre seul nouveau chemin suivi par le statut est ce rapport, non suivi. `git diff --check` : exit0.

Hygiène Markdown : commande obligatoire par défaut exit1, deux nouveaux documents pour un budget0. Contrôle avec budget borné1 pour ce rapport explicitement demandé : exit1, deux documents observés. Le second est le rapport tiers préexistant `documentation/reports/gameplay/johto_capability_audit_lots_20261018.md`. Aucun fichier tiers supprimé, aucun relèvement du budget à2. Il s’agit d’un échec global de garde documenté, pas d’une validation verte.

Suivi Notion : section « Diagnostic des limites et solution grands catalogues — 18 octobre 2026 » ajoutée au contexte existant `POST-WLD-ASSET-PACK-001`, rattaché au seul domaine14 Post-bêta. Le diagnostic est proposé TO REVIEW ; le ticket global demeure DOING et l’implémentation reste non réalisée. Aucun nouveau ticket, grand domaine ou changement de gate bêta.
