# Audit 3D Avelune Studio et Player — 27 octobre 2026

Ce document existant est enrichi d'un audit courant consacré à la 3D. Le nom historique du fichier est conservé pour éviter un deuxième rapport ; l'audit du 8 août reste intégralement en archive à la fin et ne constitue pas une preuve de l'état actuel.

## Verdict et périmètre

**Des travaux CPU redondants, des coûts GPU cumulés et une rétention mémoire non bornée sont établis. La cible de 30 FPS stables, puis 60 FPS, n'est pas certifiée sur iPhone 15 Pro ou AYN Thor Max.** Cette tâche livre un audit et un ordre de correction ; elle ne modifie pas le moteur ou le jeu et ne revendique aucun gain FPS livré.

Demande de Yoahn : tour de tous les éléments de la 3D dans Studio et la runtime. Changements de carte et retour de combat sont des symptômes prioritaires, sans limiter le périmètre. Cas témoin fourni : `/Users/karim/Project/Pokemon HeartGold/jeu`. Version Player déclarée : « 708 je crois », non vérifiée. Console confirmée : **AYN Thor Max**. Ne pas confondre le checkout courant avec le binaire installé.

Couverture : rendu partagé, modèles/meshes/materials/textures, terrain/Borders/décorations, caméra/culling, animations, personnages/occlusion, soleil/lumières/ombres, eau/météo/halos/lucioles/brouillard/DOF, préparation/transition/voisinage, gameplay alimentant la 3D, combats/retours, persistance, édition/historique/préviews Studio, hôtes mobiles/deuxième écran, cadence et instrumentation. Le renderer overworld 2D historique n'est pas réaudité exhaustivement. La présentation de combat et les services communs sont examinés lorsqu'ils affectent la session 3D.

Rattachement unique : **AS-PERF-001 — Fixtures, instrumentation et budgets de performance**, domaine existant **02 — Performance, mémoire et session projet**, [ticket Notion](https://app.notion.com/p/3e0197a7bfa581419531c1cd12fa351d). Aucun nouveau ticket ni grand domaine. Sous-périmètre audit soumis à revue ; le ticket global reste DOING tant que les critères de qualification ne sont pas satisfaits. Aucun DONE attribué à Yoahn.

## Audit initial, sources et niveau de preuve

- Git initial : branche `main`, HEAD `ddadd09a96a975a5ead983ef1078f3b57ffe3469`, **202 entrées** modifiées/ajoutées/non suivies. Nombreuses modifications staged et unstaged préexistantes dans Studio, authoring, core, renderer, runtime et MCP. Elles ne sont pas produites par cet audit.
- Sources auditées : fichiers courants, y compris modifications locales ; dépendances réellement résolues dans `.dart_tool/package_config.json`, pas uniquement leurs noms dans pubspec.
- Poste de vérification : MacBook Pro Apple M1 Pro, 10 cœurs, 32 Go, macOS 27.2 ; Flutter **3.47.5**, framework `6a19cca564`, engine `af7e796e16`, Dart **3.13.4** ; Flame **2.0.0-dev.1**, Flame 3D **0.4.0-dev.1**.
- Flame docs MCP interrogé : aucune réponse pertinente aux requêtes lifecycle/performance. APIs confirmées dans le code installé et les usages locaux. Les chemins de dépendance ci-dessous sont sous `~/.pub-cache/hosted/pub.dev/flame_3d-0.4.0-dev.1/lib/src/`.
- `xcrun xctrace list devices` : Mac disponible, iPhone hors ligne. `/Users/karim/Library/Android/sdk/platform-tools/adb devices -l` : aucun appareil. **Aucune mesure GPU ou de présentation écran sur iPhone/Thor.**
- Le contrôle `patch_flutter_gpu.py --check` confirme que le SDK local est patché. Les preuves de performance historiques du ticket Griotte, ainsi que l'audit d'août, servent à éviter les faux positifs ; leurs FPS ne sont pas réutilisés comme mesures fraîches.
- Roadmap mécanique lue. FG-014, FG-024/025, FG-040/048 sont des frontières de non-régression pour les recommandations de sauvegarde/capture/post-combat ; aucun statut fonctionnel n'est modifié. La qualification performance de ces chemins reste PARTIAL.
- Instructions appliquées : diagnostic systématique, relectures indépendantes, vérification avant conclusion, règles de parité MCP. Les exigences de tests/build ont été adaptées à un audit sans modification produit : caractérisations jetables, suites existantes, analyse et contrôle SDK ; aucune refonte ni commentaire ajouté au code produit.

**Lecture des preuves :** « établi » signifie chemin et travail vérifiés dans les sources, parfois caractérisés par test. Une complexité ou un compte de surfaces ne donne pas un temps GPU. Les microprobes Flutter test sont JIT, sans GPU ; ils ne sont pas des benchmarks de la partie HGSS. P1/P2 ci-dessous sont des priorités proposées, pas des gains chiffrés.

## Témoin HGSS : inventaire réellement lu

Catalogue actif figé au root SHA-256 `f14987282cf95b5dd6514724d489533e32a13f057a1637432be0370a423c1376`. HEAD catalogue stable avant/après la lecture. L'inspection parcourt les références actives, sans rejouer les 16 000 objets historiques ni modifier le catalogue.

**19 maps**, **864 définitions de modèle**, 710 modèles distincts explicitement instanciés dans les scènes ; 710 GLB correspondants, **6 092 248 octets** au total. Catalogue : 1 502 tilesets, 1 478 atlas, 457 animations smart tile, 1 822 matériaux smart tile, 143 presets, 43 patterns, 39 personnages, 11 bordures. Ce sont des définitions disponibles, pas autant de ressources simultanément résidentes. Le répertoire Pokémon témoin contient seulement **11 fichiers espèces** : la répétition des chargements de catalogue est réelle, mais son coût ne doit pas être extrapolé à un Pokédex complet dans ce jeu.

| Carte | Dimensions | Instances explicites | Modèles distincts | Surfaces GLB instanciées potentielles | Triangles des inspections |
|---|---:|---:|---:|---:|---:|
| Route 30 | 32 × 96 | 627 | 119 | 1 132 | 15 702 |
| Route 29 | 96 × 32 | 390 | 9 | 788 | 4 424 |
| Ville Griotte | 64 × 32 | 357 | 100 | 678 | 7 997 |
| Maison du joueur RDC | 19 × 14 | 213 | 209 | 224 | 1 432 |
| Maison de Célesta/Luth RDC | 19 × 14 | 213 | 209 | 224 | 1 432 |
| Bourg Geon | 35 × 35 | 197 | 60 | 338 | 5 062 |
| Maison du joueur étage | 14 × 12 | 137 | 137 | 144 | 1 103 |

Le compte de surfaces est obtenu dans les en-têtes JSON des GLB, multiplié par les instances. Les triangles viennent des métadonnées d'inspection, sans recomptage des index binaires. **Ces chiffres excluent terrain généré, PNJ, effets, frontières matérialisées et décorations externes ; ils ne sont pas un nombre de draw calls visibles.** Le voisinage chargé et le culling doivent être capturés pour connaître le coût d'une frame.

Les 1 126 images PNG embarquées dans ces GLB représentent **172 contenus encodés uniques**. Somme nominale RGBA : **2 897 440 octets**, contre **613 408 octets** après déduplication par hash des octets PNG. Sur Route 30 : 225 images / 23 contenus uniques ; Griotte : 193 / 29 ; maison RDC : 200 / 14. Ce n'est pas une mesure de mémoire native, et le gain de pixels seul est modeste ici. La répétition des codecs, objets et uploads est plus intéressante à mesurer que de promettre des gigaoctets économisés. Les textures de terrain et de personnages sont hors de cet inventaire GLB.

Le profil `project.visual.json` active DOF (force 0,65, plage 5), halos, brouillard, eau animée, fenêtres et lucioles, avec heure d'auteur 1230 et cycle jour/nuit. Les fichiers d'ambiance locaux portent parfois `depthOfFieldEnabled:false`, mais **le profil projet les surcharge** : `RuntimeMapBundle.visualProfile` puis `SpatialVisualPatch.applyAtmosphere` (`runtime_map_bundle.dart:38`, `spatial_visual_profile.dart:294`). Les overrides monde/cinématique/session restent prioritaires ; ces fichiers ne prouvent donc pas les réglages effectifs du Player 708. Les extérieurs déclarent 17 à 24 lucioles de base par carte, avant densité et visibilité.

**Interprétation :** ce contenu ne justifie pas de commencer par massacrer les modèles ou retirer les effets. Le nombre de surfaces et la répétition des traitements d'objets méritent la priorité, avec une mesure séparée du fill-rate et des passes GPU.

## Constats : renderer partagé et mémoire

### R01 — P1 : travail statique répété dans chaque update

`spatial_scene_view.dart:2689` réduit toute la liste `heightLevels` (width × depth) lors de `syncCamera`, appelé depuis `syncActors` (`:2928–3053`). En vue jeu, une partie du cadrage calculé est ensuite remplacée. Les frames immobiles paient encore ce parcours.

Le même `update` déclenche trois prunes des textures de sol (`:2776,2799,2803`, premier chemin via `_requestGroundAnimationTextures:1623`). Chaque prune reconstruit `_wantedGroundImages` et les `renderedImageIds` en parcourant les visuels de tous les sols chargés (`:1604–1609,3618–3622`). Les plans d'occlusion sont également résolus dans plusieurs chemins (`:3066–3087,3593–3614`).

**Action :** maxima/dimensions par révision de scène ; ensembles de textures modifiés uniquement quand leur dépendance change ; une seule prune nécessaire ; résolution d'occlusion partagée. **Preuve d'acceptation :** compteurs de cellules/visuels visités sur frames immobiles et contenu hors écran ajouté. Ne pas remplacer le maximum de heightLevels par un autre maximum de contrat différent sans vérifier le cadrage.

### R02 — P1 : modèles répétés partagés en mémoire, mais dessins individuels

`spatial_scene_materialization.dart:188–267` crée un composant par instance ; `model_playback.dart:324–334` dessine chaque node/mesh ; Flame `resources/mesh/mesh.dart:26–30` et `graphics/graphics_device.dart:105–123` soumettent les surfaces individuellement. Le contrat GPU utilisé ne propose pas d'instanceCount (`graphics/backend/gpu_backend.dart:100–128`).

Route 29, avec 390 instances issues de 9 modèles, est un témoin approprié. Le cache par source fonctionne : **ce n'est pas 390 relectures du fichier**. Restent transforms, culling, traitement des nodes, snapshots et commandes de rendu par instance.

**Action :** batches runtime par secteur et géométrie/matériau/pose compatibles, puis instancing si son coût architectural est justifié. Préserver instances natives éditables, IDs, picking, sélection, visibilité, animation et collisions. Ne pas fusionner les données du jeu. Mesurer draws, changements de matériau et travail de reconstruction locale, pas seulement les FPS.

### R03 — P1 : topologie et poses de modèles retraitées à chaque dessin

`model_playback.dart:314–338` appelle `Model.processNodes`. Flame `model/model.dart:51–90` recrée maps, sets, queue et ordre topologique même sans animation. Le chemin d'ombres peut rappeler `caster.draw`, donc refaire le travail d'un même modèle dans la même frame.

**Caractérisation fraîche :** 100 appels du vrai processNodes sur 32 nodes statiques produisent **3 200 lectures des dépendances**, malgré l'absence d'animation. Le test vérifie les poses finales. Il n'attribue pas de durée à HGSS.

**Action :** topologie précalculée à l'admission ; pose statique partagée ; pose animée une fois par instance/frame, réutilisée par les passes. Garde-fous squelettes, animation absolue et matériaux partagés.

### R04 — P2 pour HGSS, risque de croissance : tri insertion sur tous les objets visibles

Flame `graphics/render_context_3d.dart:43–79` remplit un pool puis applique un tri insertion back-to-front à tous les objets, y compris opaques. Le pool est réutilisé, mais son ordre est réécrit au prochain submit. Les surfaces transparentes sont ensuite retriées dans `spatial_render_context.dart:357–365`.

Le microprobe appelle la vraie classe installée, avec draw minimal sans GPU. 30 passages de chauffe puis 21 mesures par cas :

| Objets | Médiane déjà trié | Médiane ordre inverse | Médiane mélangé |
|---:|---:|---:|---:|
| 128 | 1 µs | 31 µs | 16 µs |
| 512 | 5 µs | 502 µs | 268 µs |
| 2 048 | 23 µs | 7 741 µs | 3 905 µs |
| 4 096 | 42 µs | 32 554 µs | 17 583 µs |

Ce sont des mesures **Flutter test JIT / M1 Pro / sans GPU / distribution synthétique**. Le cas 4 096 n'est pas la Route 30. La croissance quadratique défavorable est confirmée ; la part actuelle dans HGSS n'est pas mesurée.

**Action :** tri O(V log V) stable ou séparation opaques/masqués/transparents ; conserver règles alpha/coplanaires. Correction versionnée de dépendance ou adaptation canonique, jamais patch invisible de pub-cache.

### R05 — P1/P2 : snapshots de surfaces et éclairage refaits par frame

`SpatialRenderContext._snapshot` (`:141–160`) clone matrice, joints, AABB et pose ; `_MaterialPose` (`:455–497`) clone des vecteurs et `_withPose` (`:407–435`) sauvegarde à nouveau une partie de l'état. Ombres ou DOF activent cette collecte à grande échelle.

`syncLighting` (`spatial_scene_view.dart:1251–1338,2845`) rassemble à nouveau les coins monde déjà calculés des casters, puis recalcule leurs projections et les bornes de l'éclairage (`spatial_authored_shadows.dart:83,122–186`). Les lumières sont toutes classées avant de conserver quatre candidates (`spatial_environment_lighting.dart:131–143`). De nouveaux profils équivalents invalident les caches CPU basés sur identité (`spatial_pixel_material.dart:408–412,492–497`).

**Action :** commandes/poses réutilisables ; bornes statiques séparées du soleil et des valeurs animées ; profil stable lorsque valeurs inchangées ; sélection locale/top-4. Conserver restauration de matériau et ombres projetées depuis hors champ. Stabiliser les profils économise du packing CPU ; cela ne supprime pas tous les uploads, car `Shader.bind` rebinde encore les uniforms par draw.

### R06 — P1 : préparation des casters avant culling, ombres recalculées

`spatial_render_context.dart:204–216` appelle draw sur tous les casters avant les rejets par surface (`:242–252,303–310`). Un modèle hors caméra peut éviter la couleur mais payer les nodes et snapshots d'ombre.

`spatial_shadow_map.dart:79–100` traite six faces par lumière, jusqu'à quatre lumières : **24 parcours de faces dans un atlas partagé**, pas 24 render targets indépendants. Les allocations sont réutilisées, mais le contenu est régénéré lorsque ces passes sont actives.

**Action :** rejet conservateur des casters avant traitement des nodes ; cache de shadow map quand lumière, casters et projection restent identiques ; mise à jour seulement des faces affectées. Le mouvement continu du soleil peut invalider ce cache : ne pas promettre une ombre statique dans toutes les scènes.

### R07 — P1 à profiler GPU : résolution physique complète et DOF

Flame `camera/world_3d.dart:40–41` utilise taille logique × DPR. `spatial_depth_of_field.dart:71–87` alloue profondeur et sortie à cette résolution ; `spatial_render_context.dart:184–202` ajoute un passage de géométrie profondeur. `shaders/depth_of_field.frag:24–45` effectue jusqu'à **74 lectures de textures par pixel réellement flouté** (sinon sortie anticipée après les deux lectures initiales).

La présentation native ajoute une copie pleine image (`flutter_image_presenter_native.dart:25–32`). Son rôle d'ownership GPU doit être préservé. Le DOF intérieur est déjà inhibé.

Les budgets des modèles/images importés ne constituent pas un budget GPU global. Les cibles couleur, profondeur, DOF et ombres doivent aussi être comptées avec dimensions, formats, samples et durée de vie. Le chemin MSAA des ombres utilise notamment une texture résolue RGBA float32 et des attachments transitoires (`spatial_shadow_target_native.dart:33`). Leurs allocations nominales ne sont pas une mesure de mémoire physique résidente ; aucune fuite GPU n'est établie ici.

**Action :** mesurer DOF seul à qualité constante, puis filtre à résolution réduite et reconstruction tenant compte de la profondeur, nombre de taps/budget de pixels explicites. Un facteur linéaire de résolution 0,75 représente 56,25 % des pixels, mais pas une prédiction de gain FPS. Conserver une comparaison visuelle et le choix de qualité ; ne pas dégrader silencieusement le projet pour faire passer un seuil.

### R08 — P2 GPU : cutout éliminé tard et filtrage des ombres

Le shader `pixel_material.frag` prélève l'albedo vers `:180` mais élimine l'alpha aux lignes `:266–273`, après éclairage, ombres, eau, fenêtres, impacts et brouillard. Les zones transparentes de feuillage peuvent payer une partie de ces calculs.

Avec le rayon 2,5 du profil construit actuellement (`spatial_authored_shadows.dart:182`), le filtre soleil peut atteindre 36 lectures d'ombre par fragment concerné, voire 144 avec repli supersampling ; chaque lumière ponctuelle peut ajouter 9/36 lectures. **Ce sont des bornes du chemin shader avec ce profil**, réduites par coverage, sorties anticipées, poids et compilation ; aucun compteur matériel n'a été capturé.

**Action :** tester un discard alpha plus précoce en respectant dérivées et modes alpha ; profiler PCF/MSAA/supersampling séparément. Préserver transparence, contours, couverture des ombres et matériaux PSDK.

### R09 — P1 : cache global de couleurs animées non borné

Flame `resources/shader/shader.dart:90–91,162` conserve un `static Map<Color, Float32List>` via putIfAbsent sans éviction. `UnlitMaterial.apply:57–59` l'alimente à chaque draw. Les lucioles (`spatial_atmosphere.dart:224–226,336–338`) et halos (`spatial_presentation_effects.dart:190–201`) fabriquent des alpha continus. Flutter compare les composantes double de Color, pas seulement une couleur quantifiée 8 bits (`sky_engine/lib/ui/painting.dart:510–526`).

**La rétention de nouvelles couleurs jusqu'à la fin du processus est établie.** Ni son débit en Mo/minute, ni sa contribution aux FPS après combat, ni une fuite GPU ne sont mesurés. Changer de map ne vide pas cette map statique. Les ombres de contact disposent déjà d'une palette bornée de 257 couleurs : exclues de ce constat.

**Action :** buffer de quatre floats réutilisable ou cache borné, dans une dépendance versionnée. `Shader._set` copie les données dans les uniforms, ce qui permet d'éviter une conservation globale. Test : valeurs exactes conservées, stockage borné après milliers de couleurs et destruction de scène ; mesure longue sans forcer le GC pour embellir le résultat.

### R10 — P2 : textures identiques redécodées entre GLB distincts

`model_byte_loader.dart:164–181,351–371` crée un root/image propriétaire par source, décode et construit une ImageTexture. Flame `parser/gltf/image.dart:68–69` partage dans cette source, pas entre deux GLB de même contenu PNG. L'inventaire HGSS confirme la présence de ces doublons.

**Action :** cache de pixels/texture par hash de contenu et format avec compteurs de références et admission commune. Séparer sampler/wrap/matériau. Préserver source.replace, annulation et dernier consommateur. Gain mémoire des seuls PNG GLB témoin limité à quelques Mo théoriques ; priorité après les coûts par frame.

### R11 — P2 : culling visuel présent, granularité trop fine

`SpatialSceneComponents` groupe les maps dans un Component sans volume 3D de secteur (`spatial_scene_components.dart:156–182`). Tous les composants restent visités avant culling objet. Flame `Object3D.renderTree:42–49` fait bien le rejet de frustum ; il ne manque donc pas complètement. Les accès au frustum/projection recalculent des matrices (`camera_component_3d.dart:60–90`, `adaptive_camera.dart:33–46`). `syncRuntimeModels` parcourt aussi les modèles chargés et voisins (`spatial_scene_view.dart:2897–2925`).

**Action :** matrices/frustum figés par frame, secteurs bornés, updates visuels sur demande. Distinguer animation visuelle et progression logique hors écran ; aucune animation gameplay ne doit être arrêtée par erreur.

## Constats : sessions, cartes, combats et sauvegardes

### S01 — P1 : la préparation de destination ne prépare pas tout le premier rendu

`spatial_scene_preparation.dart:62–162` chauffe modèles et images, mais ne conserve pas une scène entièrement matérialisée. À l'activation, `spatial_scene_materialization.dart:69–76,131–267` reconstruit plans de sol, meshes, composants et parfois clipping. Normalisation GLB, layout et conversion restent synchrones dans `model_byte_loader.dart:154–199`. Un Future async ne les déporte pas.

Les voisins sont préparés séquentiellement puis publiés ensemble (`spatial_exploration_view.dart:281–307`). Les images d'acteurs le sont aussi (`spatial_exploration_session.dart:892`). La préparation peut donc cumuler I/O et travail UI avant la première image.

**Action :** préchauffer un résultat matérialisable réutilisable, progression annulable et budgétée, priorité au voisin probable, concurrence limitée par budget mémoire. Mesurer lecture, parse, plan, clipping, mesh, upload, première frame correcte et durée du rideau séparément. Préserver génération, ancien affichage et atomicité de bascule.

### S02 — P1 : overworld actif sous le combat

Le Hub empile exploration et combat (`hub_installed_game_player.dart:1512–1544`), comme Studio (`studio_spatial_playtest_view.dart:98–123`). Le mouvement est suspendu, mais `dialoguePaused` n'inclut pas battling (`spatial_exploration_game_session_runtime.dart:1257–1288`) ; `presentationPaused` ne couvre que dialogue/lifecycle (`spatial_exploration_session.dart:415`). `SpatialSceneGame.update:2761–2857` continue donc plusieurs mises à jour, et les PNJ font encore une projection avant le test de pause.

**CPU superflu établi ; double coût GPU effectif à mesurer**, car l'occlusion/composition peut réduire ce qui atteint l'écran. Conserver la scène est la bonne base pour un retour fluide.

**Action :** suspendre explicitement la mise à jour et les soumissions overworld pendant la phase opaque, garder ressources et identité, réactiver pour les transitions et garantir une frame prête avant révélation. Tester 300 frames de combat, identité avant/après, absence de rattrapage temporel brutal. Ne pas démonter/remonter l'overworld.

### S03 — P1 de croissance : catalogues et PC réhydratés pour les combats

`spatial_battle_runtime.dart:263–313` recrée des loaders/mapper. `runtime_player_pokemon_progression_hydrator.dart:67–101` collecte équipe + toutes les boîtes. Le loader espèces cache par instance (`runtime_pokemon_species_loader.dart:131,210`), mais sa première lecture liste et parse tout le répertoire (`:239–280,579`). Le seed builder crée un autre loader (`runtime_battle_combatant_seed_builder.dart:480`). Le catalogue moves passe par plusieurs instances.

**Après capture seulement pour cette branche**, `runtime_post_battle_decision_coordinator.dart:228–240` réhydrate à nouveau les Pokémon possédés. Ne pas généraliser à toutes les victoires. HGSS contient 11 espèces actuellement ; volume du PC utilisateur inconnu.

**Action :** catalogues immuables partagés par session/révision, mêmes loaders injectés partout ; hydratation ciblée des nouvelles créatures/modifications. Préserver validations d'espèces, migrations et progression. Compter lectures/parse sur combat 1, combat 2, capture, avec espèces/boîtes étrangères ajoutées.

### S04 — P1 pour scènes denses : collision par pixel avec scans globaux

`spatial_movement_controller.dart:617–640,1009–1043` appelle le solveur pixel, puis scanne zones, entités et modèles ; recherche de l'entité propriétaire encore linéaire. `pixel_movement_resolver.dart:27–40` multiplie les appels par la distance en pixels et les essais d'axes. Les PNJ mobiles ajoutent deux validations de trajet (`spatial_npc_fixed_route_runtime.dart:178,215–230`).

**Action :** broad-phase spatiale et index entités par ID, puis conserver le solveur exact sur les candidats. Ne pas supprimer l'échantillonnage qui protège les obstacles fins. Mesurer candidats visités, avec 10 puis 10 000 obstacles éloignés ; tester portes, pivots, rotations, pentes, réservations PNJ et changements de présence.

### S05 — P1/P2 : interactions et règles narratives recalculées avant comparaison

`spatial_exploration_game_session_runtime.dart:352–375` publie interactions/repérage par frame. `spatial_gameplay_events.dart:451–488` reconstruit les IDs interactifs depuis tout le registre d'événements puis scanne les instances. Les présentations d'entités sont projetées dans plusieurs consommateurs. `RuntimeWorldRuleProjectionCache:15–18` et le résolveur visuel sont invalidés par identité globale GameState, qui change lors des déplacements.

Les notifications comparent déjà leurs snapshots : **pas de preuve d'un rebuild Flutter inconditionnel chaque frame**. Le gaspillage précède cette garde.

**Action :** index par map et cache sur les vraies dépendances ; rafraîchir aux changements de position/facing/poses proches/faits/heure pertinents. Test d'immobilité et de déplacement avec beaucoup d'événements étrangers, sans figer une condition temporelle légitime.

### S06 — P2 : dépendances compagnon trop larges

`load_runtime_map_bundle.dart:360` ajoute tous les personnages des mappings du compagnon aux dépendances de map. `spatial_exploration_session.dart:815,880–897` parcourt leurs animations/images même quand un seul compagnon est actif. Le partage d'images évite certains décodages chauds, mais n'enlève pas ce périmètre.

**Action :** compagnon actif et prochain compagnon utile préparés avec admission avant apparition ; conserver les garanties de changement d'équipe. Pas de parallélisation sans borne mémoire.

### S07 — P2 : sauvegarde encore partiellement CPU sur isolate UI

La capture 3D appelle `strictGameStateSaveJson` synchroniquement (`spatial_exploration_game_session_runtime.dart:1356`, `game_state_persistence.dart:9`). Le committer utilise **déjà un worker** (`hub_session_checkpoint_committer.dart:68`). Mais `HubSaveRepositoryImpl.writeVerified:105` refait decode(toJson), puis encode et vérifications temporaire/finale (`:548,554,610`) hors worker.

Pas d'autosave identifiée à chaque frame ni à chaque warp ordinaire : ce risque concerne sauvegarde, pause/lifecycle, sortie et mutations persistantes.

**Action :** déporter le travail pur restant tout en gardant verrou de slot, flush, contrôle d'intégrité, backup et activation atomique. Ne jamais annoncer la sauvegarde durable avant succès. Les exports protégés et sauvegardes de la baseline 0.3.31+331 restent des critères bloquants.

## Constats : Studio 3D et authoring incrémental

### E01 — P1 architecture : petite configuration de modèle, snapshot projet

Le toggle ombres et les paramètres nom/échelle/pivot/lumière/collision appellent `model3d.configure` (`model_resource_library.dart:324–425`). Le fast path de `local_resource_mutation.dart:39–44` ne couvre que source.replace/source.replace_batch ; configure arrive à `snapshots.load(editorReadProjection):143–152`.

Au premier passage, `project_snapshot_loader.dart:624–713` matérialise catalogue et cartes ; `:1048–1071` parcourt les ressources, avec hashes selon les descripteurs disponibles. Le cache chaud vérifie encore des ressources globales (`project_snapshot_cache.dart:139,388–444`). Après mutation, `StudioMapResources.updateCatalog:314` reconstruit index et chemins.

**Action :** mutation sémantique ciblée dans map_authoring, dépendances réellement affectées, notification de définition ciblée. Une opération locale ne doit dépendre ni des maps étrangères ni du premier cache froid. Préserver crash safety, concurrence et compatibilité ; aucun writer spécifique UI.

### E02 — P1 architecture : historique spatial entier pour une seule rotation

`map_history_delta.dart:59,231,831` traite spatialScene comme une valeur et sérialise avant/après pour retainedBytes. `MapHistoryCoordinator.pushEntry:313` en demande systématiquement la taille. Toutes les 25 opérations, un checkpoint sérialise aussi deux maps complètes (`map_history_coordinator.dart:212`, `map_history_entry.dart:45`).

**Caractérisation fraîche avec vraies API**, carte 32 × 32 inchangée, une seule rotation :

| Instances | Valeurs modifiées | delta.retainedBytes |
|---:|---:|---:|
| 10 | 1 | 8 876 octets |
| 100 | 1 | 44 288 octets |
| 1 000 | 1 | 401 480 octets |

À la 25e rotation sur 1 000 instances : buffers checkpoint avant/après **201 210 octets chacun**, entrée **804 034 octets**, pile **10 441 983 octets selon la comptabilité interne**. Les tests vérifient valeurs inchangées ailleurs, undo/redo et no-op. **retainedBytes n'est pas le heap réel** ; les deux buffers checkpoint sont bien des JSON UTF-8 réels.

**Action :** deltas spatiaux par IDs/cellules/propriétés et comptabilité incrémentale ; stratégie de checkpoints sans snapshot imposé sur une interaction locale. Vérifier opérations 24/25/26 avec contenu étranger ajouté, récupération et budget d'historique.

### E03 — P1 : mutation non liée aux PNJ, sprites PNJ rechargés

`SpatialMapEditor.build:1438` appelle updatePreview. L'identité de MapData change pour terrain/modèles ; le filtre ne conserve que le cas ordre visuel seul (`:689–709`). `StudioMapResources.spatialPreview:94–153` recharge un bundle puis redécode/transfère les sprites PNJ. Les générations empêchent l'installation d'un résultat obsolète, mais n'annulent pas son travail. `StudioSpatialMapPreview:62` a une granularité similaire.

**Action :** distinguer apparence/source et pose ; cache par source/révision ; hauteur recalculée sans codec pour une modification de relief ; déduplication/cancellation avant le travail. Étendre le test existant spatial_preview_order_resources aux rotations/relief et rafales de mutations.

### E04 — P1 : relief et peinture retraitent le trait et toute la scène

`SpatialTerrainStroke.paint:109–113` repart du source avec toutes les cellules accumulées. `SpatialMapOperations.setLevels:90–120` copie heightLevels ; `_reanchor:320–390` parcourt les modèles ; le constructeur MapSpatialScene recopie/valide les collections (`:357–443`). L'upsert de modèle passe aussi par des scans globaux.

La peinture 3D `map_canvas_stroke.dart:365,513–536` rematérialise le geste accumulé et valide la map à la fin. L'overlay environnement scanne toute la surface du masque (`spatial_environment_gesture.dart:134`).

**Action :** draft incrémental, nouvelles cellules seulement, propagation limitée aux raccords et supports touchés, overlay persistant par zone. Conserver validation complète explicite des imports et invariants rampes/attaches, sans les refaire globalement à chaque point du geste.

### E05 — P2 : cache de voisins keyed par manifeste profond et versions conservées

`map_workspace_editor_pane.dart:81` conserve les futures voisins ; la clé contient project (`map_workspace_spatial_neighbors.dart:90`). Le hash généré de ProjectManifest parcourt profondément ses collections (`project_manifest.freezed.dart:574`). Les anciennes projections restent dans la map jusqu'à dispose.

**Action :** clé session/map/révisions utiles, remplacement des versions précédentes, plafond de rétention. Profil mémoire requis avant de chiffrer l'impact. Tester A/B/A et dizaines de petites mutations de catalogue avec lectures et taille du cache.

### E06 — P2 à mesurer : preview cinématique, ressources et horloges

`CinematicSpatialMapScene.didUpdateWidget:63` relance la préparation quand son model change. `studio_cinematic_spatial_preview.dart:23,53–139` fabrique les textures et recherche étapes/items/animations par scans. Le transport Timer.periodic(16 ms) (`cinematic_preview_transport.dart:93`) coexiste avec le ticker renderer.

**Action :** index temporels, textures stables et une horloge de présentation synchronisée ; mesurer longue timeline, seek et pause. La présence de deux horloges n'est pas, à elle seule, une preuve de frames perdues.

## Hôtes, métriques et reproductibilité

### H01 — Thor Max : mesurer aussi le second écran

Le primaire utilise FlutterEngineGroup (`RuntimeSession.kt:38`) ; `RuntimeCompanionSession.kt:303` démarre un second moteur quand un display secondaire admissible est actif. `avelune_gameplay_companion_app.dart:24` héberge une UI distante, son budget/cache et sa présentation de combat. **Ce n'est pas un second overworld 3D complet.** Relais d'état, isolate, textures/UI et surface ajoutent un coût à isoler. La destruction du moteur est présente (`RuntimeCompanionSession.kt:460`) ; aucune fuite d'engine établie. iOS réutilise un moteur principal.

La Thor Max est annoncée Snapdragon 8 Gen 2 / 16 Go par [AYN](https://www.ayntec.com/products/ayn-thor). Ne pas confondre avec la Lite. Le SKU/OS/fréquences de l'appareil réellement exécuté doivent encore être relevés.

### H02 — Cadence existante, métriques insuffisantes pour « fixe »

`AveluneFrameRateBinding` est branché et saute begin/draw avant travail selon le cap ; défaut 60, options 30/45/60/90/120. Android appelle Surface.setFrameRate (`RuntimeActivity.kt:174`), une demande à l'OS. Les 49 tests ciblés du pacer/binding/options passent. **Ajouter seulement un bouton 30 FPS ne réparera pas une frame qui coûte 50 ms.**

Le HUD (`avelune_runtime_diagnostics.dart:23–74`) donne FPS sur timestamps vsyncStart sur 2 secondes, p95 de totalSpan, moyennes UI/raster, process metrics à 1 Hz. Ce n'est ni la présentation écran réelle ni le temps GPU matériel. Il manque intervalles p99/max, dépassements, marqueurs de scénario et export durable. Sur Thor, métriques processus agrègent les deux moteurs.

### H03 — Binaire et moteur à figer avant comparaison

Le patch Dart flutter_gpu (HostBuffer + comptabilité de pression mémoire native) est installé localement. iOS le vérifie/applique dans `apps/Avelune iOS/tool/build_runtime.sh:23`. Le build Android accepte un SDK configurable mais ne vérifie pas ce patch (`apps/avelune_android/tool/build_runtime.sh:14`). Défaut de reproductibilité établi ; **absence dans le Player Thor non prouvée**.

La CI iOS pinne 3.48.0-0.4.pre avec fallback beta (`ci_post_clone.sh:18`), tandis que le SDK audité est 3.47.5. Le build 708 doit donc être relié à son SHA/framework/engine/shaderbundle avant d'attribuer tous ces constats à son binaire.

La fence waitUntilCompleted du dépôt cible uniquement **FlutterSurfaceManager.mm macOS** (`tools/flutter_engine_patches/macos_gpu_frame_completion.patch`). Elle ne constitue pas une preuve de blocage iOS/Android. Ne pas retirer la copie GPU ou les garanties de synchronisation qui ont réparé les artefacts visuels.

## Ce qui fonctionne déjà et doit rester protégé

- Cache modèles par source, admission/budget des ressources importées et annulations ; cache clipping borné ; cache maps avec vérification d'intégrité.
- Terrain natif : plans/ranges/maillages réutilisés, UV uniformes et buffers immuables pour animations hétérogènes. L'ancienne reconstruction de géométrie à chaque animation a été corrigée.
- Culling frustum par objet, pool de targets, partage des images courantes/suivantes.
- Météo batchée en deux surfaces réutilisées avec déplacement des particules au shader ; pas un composant par goutte. Audio météo dédupliqué.
- Réutilisation des composants de voisins et préparation/adoption des destinations ; portes attendant une frame couverte.
- Retour de victoire même map/position/facing : garde `_restoreSpatialState:839–842`. **Aucune preuve d'un rechargement complet normal après chaque victoire.**
- Mode statique à la demande/TickerMode ; GPU ownership protégé ; aucune fuite GPU chiffrée.
- Commits de sauvegarde partiellement offloadés, écritures vérifiées et atomiques.
- Préview de drag distincte du commit, invalidation source.replace ciblée et budgets images Studio.

Ces protections expliquent pourquoi une refonte générale ou une simple augmentation de caches serait une mauvaise première réponse.

## Plan de correction proposé, sans implémentation dans cet audit

| Ordre | Lot borné | Résultat à prouver avant livraison |
|---|---|---|
| 0 | Identifier binaire 708, source/engine/shaders et collecteur par scénario | Mesures comparables sur iPhone 15 Pro et Thor Max, qualité/double écran/thermique enregistrés |
| 1 | R01/R05 : travail statique par frame ; R09 : cache couleurs | Zéro scan/packing redondant sur scène immobile ; stockage couleurs borné ; rendu identique |
| 2 | S02 : pause réelle sous combat ; S03 : catalogues partagés | Pas d'updates/soumissions inutiles pendant opacité ; pas de reread/rehydratation globale au second combat |
| 3 | S01 : préparation complète utile ; S04/S05 : index spatiaux/narratifs | Première frame de destination mesurée ; coût de déplacement indépendant des objets/événements éloignés |
| 4 | R02/R03/R04 : batches modèles et poses ; tri approprié | Réduction mesurée de draws/poses/comparaisons, IDs/visibilité/picking préservés |
| 5 | R06/R07/R08 : ombres et DOF | Coût GPU isolé ; qualité comparée ; budgets de pixels/ombres explicites, pas de dégradation cachée |
| parallèle produit distinct | E01–E05 : Studio local et incrémental | Premier et répété : feedback ≤100 ms, durable ≤500 ms sur projet représentatif ; travail compté/relecture après réouverture |
| final | Qualification thermique/lifecycle/mémoire | 30 FPS stables dans le périmètre convenu ; 60 FPS évalués sans changer silencieusement qualité/scénario |

R10 et E06 viennent ensuite selon les mesures. Éviter de remplacer tous les chargements par Future.wait : concurrence non bornée et pics d'admission peuvent aggraver les transitions. Un isolate/débounce/cache chaud ne rend pas acceptable un geste Studio global.

## Protocole concret pour 30 puis 60 FPS

Budget cible : **33,33 ms par frame à 30**, **16,67 ms à 60**. UI et raster peuvent se recouvrir ; ne pas additionner arbitrairement leurs durées. Un p95 ou FPS moyen bon ne suffit pas pour « fixe ». Publier cadence d'images présentées si disponible, intervalles p50/p95/p99/max, nombre et proportion de dépassements, séquences de dépassements, durée de chargement et première frame correcte. Toute tolérance d'horodatage doit être explicite ; ne pas masquer des stalls dans les percentiles.

Sur chaque appareil physique : version OS/build, hashes jeu/engine/shaders, qualité effective, résolution logique et physique, fréquence réelle, cap, batterie/charge/économie d'énergie, état thermique, nombre d'écrans. Profile pour attribution CPU/GPU, Release pour confirmation. [Flutter recommande un appareil physique et le mode profile pour diagnostiquer les performances](https://docs.flutter.dev/perf/ui-performance).

Scénarios HGSS :
1. Bourg Geon, Griotte, Route 29 et Route 30 : fixe, marche/course/caméra, bord de map avec voisins, PNJ.
2. Jour, crépuscule/nuit avec lumières/lucioles ; météo claire puis pluie/orage/neige autorisée par les réglages. Relever paramètres effectifs, pas seulement project.visual.json.
3. Porte intérieur→extérieur, extérieur→intérieur, connexion chaude/froide et A→B→A répété ; première opération séparée.
4. Entrée combat, phase opaque, victoire même map, capture avec PC, défaite/recovery, dialogue/scène de sortie. Ne pas filtrer les transitions du relevé général.
5. Sauvegarde/pause/reprise puis fermeture/réouverture ; mémoire après 10 cycles map/combat, handles/caches après retour au même état.
6. Thor Max écran unique puis double écran avec actions identiques ; iPhone dans les conditions de jeu habituelles.
7. Chauffe 30 s, 3 séquences de 60 s par scénario nominal ; session prolongée 20 min pour dérive thermique/mémoire. Les premières frames froides restent une série distincte, jamais effacée.

Trace minimale : spans lecture/JSON/GLB/codec/plan/mesh/upload/first-ready, update monde/pose/ombres/DOF, catalogue combat/outcome/hydratation, save normalize/encode/verify ; compteurs octets/reads/décodages/cache, objets visibles/résidents, surfaces/draws, acteurs/candidats collision. A/B à qualité et état identiques, sans enregistrement PNG par frame pendant le relevé principal.

Sur iOS : Instruments CPU/allocations et outils Metal ; Android : Perfetto/FrameTimeline et outils GPU compatibles Adreno. Ces outils complètent FrameTiming ; aucune valeur GPU n'est déduite du seul raster Flutter. Tests de longue durée locaux, aucune CI macOS coûteuse ajoutée.

## Vérifications exécutées, limites et état final

Les commandes ci-dessous ont été exécutées sur les fichiers courants. Les suites Dart/Flutter ont été suivies par le wrapper temporaire `run_owned.py` : PID du runner, descendants, heure de naissance et commande enregistrés, puis vérification des survivants. Tous les reçus indiquent `reaped: []`, `unresolved: []` : les processus suivis ont terminé naturellement. Aucun kill par nom de processus.

### Résultats des tests et outils

| Vérification | Résultat exact | Limite |
|---|---|---|
| Renderer, 11 fichiers ciblés | `00:14 +81: All tests passed!`, exit 0 | Tests Flutter sans GPU matériel |
| Microprobe renderer, vraie dépendance installée | `00:03 +2: All tests passed!`, exit 0 | JIT synthétique, pas des FPS HGSS |
| Runtime, 10 fichiers ciblés | `04:18 +142 -5: Some tests failed.`, exit 1 | Cinq scénarios non validés, détaillés ci-dessous |
| Historique Studio, vraies API | `00:00 +2: All tests passed!`, exit 0 | Tailles JSON/comptabilité interne, pas mesure du heap ou latence UI |
| Cadence / binding / options | `00:01 +49: All tests passed!`, exit 0 | Ne prouve pas le respect du budget GPU |
| Transition configurée, replay isolé | `+0 -1`, exit 1 | Même `FormatException` |
| Deux dialogues, replay isolé | `00:07 +0 -2: Some tests failed.`, exit 1 | Même attente de postBattleOverlay non satisfaite |
| Diagnostics/bridge, premier lancement | exit 1 avant exécution | Déclaration d'asset inter-package rejetée |
| Diagnostics/bridge avec `--no-test-assets` | `00:01 +11: All tests passed!`, exit 0 | Logique testée ; bundling d'assets non validé |
| Analyse map_render_3d | `No issues found! (ran in 5.5s)`, exit 0 | Analyse limitée au package renderer |
| Patch HostBuffer/GPU | `Ran 14 tests in 2.408s`, `OK`, exit 0 | Tests du patch, pas profiling GPU |
| SDK local, contrôle du patch | `Flutter GPU memory patch already applied`, exit 0 | Pas une preuve du SDK employé par le build 708 |
| Hygiène Markdown | `Markdown hygiene: no new Markdown files.`, exit 0 | Rapport existant enrichi |
| Diff du rapport | `git diff --check`, exit 0 | Aucun whitespace error dans notre fichier |

Commandes exactes, avec leur répertoire de travail :

```bash
# packages/map_render_3d
flutter test --no-pub --concurrency=1 -r expanded test/spatial_game_activity_test.dart test/spatial_scene_components_test.dart test/spatial_scene_refresh_resource_ownership_test.dart test/spatial_scene_preparation_test.dart test/spatial_ground_mesh_batches_test.dart test/spatial_raster_height_test.dart test/spatial_transparency_render_test.dart test/spatial_depth_of_field_test.dart test/spatial_point_shadow_test.dart test/spatial_shadow_map_test.dart test/spatial_weather_effects_test.dart
flutter test --no-pub --concurrency=1 -r expanded /Users/karim/Library/Caches/AveluneQA/3d-performance-audit/renderer_cost_probe_test.dart
flutter analyze --no-pub

# packages/map_runtime
flutter test --no-pub --concurrency=1 -r expanded test/spatial_battle_runtime_test.dart test/session/spatial_battle_outcome_dialogue_test.dart test/spatial_connection_session_test.dart test/spatial_connection_view_test.dart test/spatial_resource_loader_ownership_test.dart test/spatial_native_door_traversal_test.dart test/spatial_model_presence_index_test.dart test/spatial_npc_autonomy_collision_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_project_catalog_map_cache_test.dart
flutter test --no-pub --concurrency=1 -r expanded test/spatial_battle_runtime_test.dart --plain-name 'spatial entry resolves the authored wild and trainer configurations'
flutter test --no-pub --concurrency=1 -r expanded test/session/spatial_battle_outcome_dialogue_test.dart

# packages/map_authoring
dart test /Users/karim/Library/Caches/AveluneQA/3d-performance-audit/studio_history_probe_test.dart --reporter expanded

# packages/avelune_rendering
flutter test --no-pub --concurrency=1 -r expanded test/frame_pacer_test.dart test/frame_rate_binding_test.dart test/frame_rate_test.dart

# apps/pokemap_hub
flutter test --no-pub --concurrency=1 -r expanded test/embedding/avelune_runtime_diagnostics_test.dart test/embedding/avelune_frame_rate_bridge_test.dart
flutter test --no-pub --no-test-assets --concurrency=1 -r expanded test/embedding/avelune_runtime_diagnostics_test.dart test/embedding/avelune_frame_rate_bridge_test.dart

# Racine du dépôt
python3 -B -m unittest discover -s 'apps/Avelune iOS/tool' -p 'test_flutter_gpu_host_buffer.py' -q
python3 'apps/Avelune iOS/tool/patch_flutter_gpu.py' --flutter-root /opt/homebrew/share/flutter-3.47.5 --check
bash tools/scripts/check_markdown_hygiene.sh
git diff --check -- packages/map_runtime/reports/map_runtime_performance_audit_2026-08-08.md
```

Les deux probes et leur wrapper sont conservés dans l'archive de preuves, sans les installer dans la suite CI. Pour les rejouer, extraire ces trois fichiers dans le même répertoire QA canonique et utiliser les commandes indiquées. Le test HostBuffer emploie ses répertoires temporaires système gérés et supprimés par le test lui-même ; aucune copie d'application n'a été créée.

### Qualification des échecs, sans les effacer du bilan

1. `battle entry renders its authored curtain over the overworld before commands` et `spatial entry resolves the authored wild and trainer configurations` : les fixtures construisent `ProjectBattleTransitionConfig` avec IDs mais sans définitions (`test/spatial_battle_runtime_test.dart:274,463`). Le validateur exige l'appartenance au catalogue et l'usage correspondant (`map_core/lib/src/models/project_battle_transitions.dart:15,33`), avant rendu (`battle_transition_spec.dart:288`). Exception : `The default battle transition must belong to the project and match its usage.` Le second cas échoue également isolément. Cela ne certifie ni ne réfute la compatibilité des anciens exports : il faudrait leurs vrais fixtures protégés et le lecteur de compatibilité.
2. `entry curtain follows a resize while its assets are still loading` : la fixture utilise le fade par défaut et injecte un loader suspendu, mais aucune phase ne demande de planche (`spatial_battle_runtime_test.dart:406–420`, `battle_transition_spec.dart:317`, `battle_transition_overlay_component.dart:112`). `isLoading` n'est donc pas maintenu à true. Le scénario ne teste plus sa précondition de chargement ; il faut une spec avec asset et preuve d'appel du loader avant le resize.
3. `trainer Scene battle delivers its outcome dialogue with live host input` et `static Scene battle delivers its outcome dialogue with live host input` : tests sans `SpatialBattleView`, avec `mountSession` vide (`session/spatial_battle_outcome_dialogue_test.dart:15–47`). Le runtime attend maintenant `overlay.loaded` et `overlay.mounted` (`spatial_battle_runtime.dart:458–464`) et consomme les inputs tant que la présentation n'est pas montée (`:926–935`). Les assertions échouent avant le dialogue, à `postBattleOverlay == null`. Replay isolé : deux échecs identiques. Monter et avancer la vraie présentation est nécessaire avant de rejouer ces scénarios.

La lecture du code rattache donc les cinq échecs à trois incompatibilités des tests avec le contrat courant. **Ces scénarios restent non validés tant que les harnais ne sont pas adaptés et rejoués.** Les tests n'ont pas été modifiés pour blanchir le relevé. Aucun verdict vert global ni verdict de performance mobile n'en est déduit.

Le premier lancement diagnostics échoue avant les tests : `Asset path "../../packages/map_authoring/assets/project_templates.v1.json" of package "avelune_studio" resolves to a location outside the package directory. Package asset paths must stay within the package.` Le replay sans assets vérifie les deux modules de diagnostic mais ne répare ni ne valide cette déclaration.

**Build :** aucun nouveau build natif Release, ni installation mobile. Livraison documentaire, sans code produit modifié ; compilation des suites existantes, analyse renderer et tests/contrôle du patch constituent la validation alternative. Le bundling d'assets ci-dessus et les cinq scénarios rouges restent des limites visibles. La qualification physique demeure à réaliser.

### Fichiers livrés, état Git et nettoyage

Le seul fichier suivi modifié par cet audit est `packages/map_runtime/reports/map_runtime_performance_audit_2026-08-08.md` : préfixe courant, inventaire HGSS, 27 constats R01–R11/S01–S07/E01–E06/H01–H03, priorités, protocole et preuves. Le contenu historique du 8 août est conservé octet pour octet, avec hash vérifié. Aucun fichier produit, projet, asset ou save n'a été modifié par cette tâche.

Une petite archive `packages/map_runtime/reports/avelune_3d_performance_audit_2026-10-27.evidence.zip` conserve les probes, reçus de processus, logs pertinents et états Git. Aucun snapshot des sources produit, catalogue complet, GLB ou copie du jeu. Elle constitue une preuve durable de l'audit, pas un environnement de test conservé.

Dernier relevé Git de clôture (checkout partagé actif) : branche `main`, HEAD inchangé `ddadd09a96a975a5ead983ef1078f3b57ffe3469`, **207 entrées**, contre 202 initialement. Les deux ajouts au statut appartenant à cette tâche sont le rapport modifié et l'archive nouvelle. Trois autres fichiers sont devenus modifiés pendant l'audit, sans intervention de cette tâche : `packages/map_authoring/lib/src/transactions/authoring_payload.dart`, `packages/map_authoring/test/transactions/file_backed_payload_test.dart`, `packages/map_authoring/test/transactions/stored_payload_source_verification_test.dart`. Quatre fichiers déjà présents dans le statut initial ont aussi évolué simultanément : `apps/avelune_studio/dev/exterior_decoration_native_main.dart`, `apps/avelune_studio/dev/model_source_replacement_native.dart`, `packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart`, puis `packages/map_render_3d/lib/src/spatial_scene_decoration.dart` au dernier contrôle. Les états complets sont dans l'archive. **Aucun add, commit, checkout, rebase ou push.**

Nettoyage vérifié : le répertoire possédé `/Users/karim/Library/Caches/AveluneQA/3d-performance-audit/` occupait **5 844 Kio alloués** avant suppression ; aucun fichier ouvert ni processus suivi survivant, puis répertoire absent. Aucun environnement, application ou copie de jeu conservé. Les caches Flutter partagés préexistants des packages ont été réutilisés et ne sont pas supprimés, leur propriété exclusive par cette tâche n'étant pas établie. L'espace libre du volume a été mesuré séparément : 141 889 196 032 puis 141 895 077 888 octets ; sa variation n'est pas utilisée comme mesure du nettoyage en présence d'écritures concurrentes.

Archive finale : **43 821 octets**, SHA-256 `b248b253c86edfda434cf86812564e107224a60a7ed986db8757e993bdf07f2b`. Intégrité ZIP, hashes des preuves et lecture du reçu de nettoyage vérifiés. Seules les preuves durables décrites ci-dessus sont retenues. L'archive historique du rapport compte toujours 33 245 octets, hash identique à l'original avant édition.

## Contrelecture du PDF externe fourni par Yoahn

Source : `audit-avelune-performances-2026-10-27.pdf`, 24 pages, SHA-256 du PDF `259afe54dd409bc4153f765b689e2367978e257d5040935304bb731816d88c68`. Audit du même commit `ddadd09a96a975a5ead983ef1078f3b57ffe3469` sur copie Linux propre, sans HGSS ni appareils. Cette contrelecture porte sur les apports et leur applicabilité à la 3D ; elle ne réexécute pas les 46 tests annoncés dans le PDF. Les contrôles frais ci-dessous sont distincts des vérifications de la section précédente.

**Verdict : audit sérieux et complémentaire, à reprioriser pour le contenu 3D fourni.** Il distingue les nombres d'opérations des FPS, fournit une sonde reproductible et écarte plusieurs faux positifs. Son tableau p.4 reconnaît lui-même la différence entre moteurs 2D et spatial. F01/F02 (substeps et interaction 2D) et le chemin F10 cité (préchargement PlayableMapGame) ne constituent pas des explications directes du ralentissement HGSS 3D.

### Confirmation exécutée de F04 et pertinence de F03

Le code complet de la sonde des pages 20–21 a été extrait, inspecté puis exécuté sans modification de logique sur les packages locaux. Depuis `packages/map_gameplay` :

```bash
dart --packages=.dart_tool/package_config.json /Users/karim/Library/Caches/AveluneQA/3d-performance-audit/external_collision_probe.dart
```

**Exit 0, 24 sorties JSON ; assertions de comparaison : 24 cas conformes.** Après exclusion de l'initialisation, 120 updates de 1/60 s avec 1 000 entités éloignées donnent zéro projection au repos, 120 000 à la marche sur 96 pixels, 192 000 à la course sur 192 pixels. Les cas 0/10/100 entités et bloquant/non bloquant concordent aussi. Dart local 3.13.4, JIT ; aucune mesure de temps de frame. Le runner PID 3106 termine naturellement, `reaped: []`, `unresolved: []`. La sonde reste reproductible depuis l'annexe du PDF après nettoyage du fichier temporaire.

Inspection fraîche des 19 JSON de cartes HGSS : **97 entités au total, aucune déclaration `presentation` de variantes** ; Route 30 contient 17 entités, Route 29 en contient 13. Le retour rapide de `projectMapEntityPresentation` (`map_entity_presentation_projection.dart:104`) évite alors la validation et la construction du resolver de F03. F03 est un défaut conditionnel réel du moteur, mais le chemin lourd n'est pas activé par ces définitions auteur. Les scènes synthétiques à 1 000 PNJ prouvent F04 à l'échelle, pas sa part dans les FPS actuels ; les modèles 3D et voisins restent à compter séparément. Aucune affirmation sur le contenu exact du package installé n'en découle.

### Apports nouveaux retenus

- **F12 — menus/compagnon Android :** le caller spatial omet `itemCatalog` alors que `_bagItemCatalog` est chargé (`spatial_exploration_game_session_runtime.dart:1045,1610`). Le builder recharge donc les items et crée un loader moves (`runtime_player_pause_data_builder.dart:49,66`). Les règles d'évolution sont relues pour chaque espèce admissible distincte de l'équipe × ID d'objet possédé, pas tout le Pokédex (`:735`, `runtime_pokemon_evolution_loader.dart:78,354`). Le cache espèces existe mais vérifie une signature de fichiers. Le transport Android démarre avant playGame sans condition de second écran (`RuntimeSession.kt:153`) ; sa lecture ne dépend pas de `companionAttached` (`avelune_gameplay_companion.dart:242`). Le port spatial lit le menu en overworld (`hub_installed_game_player.dart:148`). Les invalidations peuvent donc provoquer ce travail même sans second moteur visible ; **pas de preuve d'une lecture à chaque frame**. Complète H01 et S03 : consommateur réel, catalogues par session et projections par révision à examiner.
- **M01 — parcours Flutter Profile iOS :** `build_runtime.sh:14–35` et `build_ios.sh:5` acceptent Debug/Release et le schéma natif Profile utilise Release (`project.yml:24`). La lacune porte sur le mode Flutter Profile intégré au host, pas sur l'impossibilité d'utiliser Instruments sur Release. Les tests de pipeline couvrant le rejet de Profile ont été consultés, non relancés. Le protocole de mesure ci-dessus exige donc soit de rendre ce parcours cohérent avec le moteur utilisé, soit de commencer avec les outils natifs sur Release représentatif. Ne pas remplacer silencieusement le moteur patché pour profiler.
- **S04 — sauvegarde Studio partagée 2D/3D :** `local_map_workspace_adapter.dart:407` encode les octets avant de choisir workingCatalog, où ils ne sont pas utilisés ; la branche refait `current.toJson()` (`local_map_workspace_working_catalog.dart:89`). Après persistance, la sélection vérifiée est relue puis seule la révision remonte (`:128–135`), et le contrôleur relit la sélection lorsque `!hasCompleteProject && source is MapWorkspaceScopedPort` (`map_workspace_controller.dart:637`). Travail redondant confirmé, sans mesure de dépassement des 500 ms. Conserver le premier contrôle de cohérence et transmettre son résultat ; ne pas généraliser la seconde lecture au mode projet complet.

### F11 : cache de combat réel, scénario de retour à recadrer

La purge de scope est commune (`battle_overlay_component.dart:1179`, `battle_visual_asset_cache.dart:39`), mais `trimUnused(maximumEntries: 0)` conserve les images encore retenues par d'autres scopes. Le préchauffage équipe/rencontres/trainers/fonds au retour décrit p.9 appartient à `PlayableMapGame` (`:11619,18569`), le moteur 2D. Son chevauchement possible avec la suppression différée n'a pas été reproduit.

En 3D, `spatial_battle_runtime.dart:360` crée un cache pour chaque combat et `:1040` le détruit en sortie. Il faut examiner les redécodages au combat suivant et leur budget ; aucun préchauffage global équivalent au retour spatial n'a été retrouvé. **Ne pas attribuer le ralentissement au retour HGSS à la course 2D décrite dans F11.**

Le PDF confirme aussi les scans sols/occlusions, les sauvegardes partiellement déportées, les checkpoints et previews trop larges. Il ne remplace pas les investigations 3D R02–R09 (draws/poses, tri, rétention Color, ombres et DOF). CPU et GPU doivent être profilés dès le départ ; le facteur limitant ne peut pas être décidé avant les traces.

Cette passe n'a modifié que cette section du rapport ; aucun code produit, projet ou save, aucun build natif et aucune écriture Git. Deux relectures indépendantes ont confirmé F11/F12 et S04/M01 ; la troisième critique est favorable après vérification des nuances de portée, de contenu HGSS et de niveau de preuve. Comparaison enregistrée dans le même AS-PERF-001, statut global DOING, sous-périmètre prêt pour revue. Git initial/final de cette passe : 208 entrées préexistantes, main, même HEAD ; chantier concurrent préservé.

Nettoyage de cette contrelecture : 332 Kio de probes/rendu PDF possédés supprimés, aucun fichier ouvert ni processus restant, racine QA de nouveau absente. Espace libre du volume mesuré séparément : 137 434 611 712 puis 137 434 914 816 octets, sans attribution exclusive de la variation. PDF source et archive de preuves précédente conservés inchangés ; aucune nouvelle archive nécessaire, le PDF contient déjà la sonde exacte. `git diff --check` ciblé et `bash tools/scripts/check_markdown_hygiene.sh` : exit 0.

## Auto-critique et verdict des passes

- **Audit / Architecture renderer :** coûts structurels établis, garde-fous existants identifiés ; pas d'attribution matérielle. Le tri quadratique ne doit pas être présenté comme cause dominante de HGSS sans distribution réelle.
- **Implémentation existante / Runtime :** entrées/captures, collisions, projections et suspension partielle établies ; victoire simple même map conserve la scène. Aucune correction implémentée.
- **Studio :** défauts de granularité identifiés ; historique caractérisé par vraies API. Budgets 100/500 ms non mesurés, donc PARTIAL.
- **Tests :** caractérisations utiles et suites ciblées ; échecs runtime visibles. Un test vert n'est pas une preuve de FPS.
- **Build / Validation :** SDK/pacing/patch/hôtes examinés ; différences CI et build utilisateur non résolues. Pas de build natif nouveau ou de certification mobile.
- **Critique finale indépendante :** verdict favorable pour livrer l'audit après trois précisions intégrées : coins monde déjà précalculés, rayon exact du filtre d'ombre et budget des cibles GPU distinct des ressources importées. Les relectures précédentes ont aussi corrigé les affirmations trop larges sur les uniforms, le retour de combat et la fence macOS. Réserve maintenue sur les 30/60 FPS et la chauffe des appareils.

Limites : audit statique étendu et vérifications CPU ciblées ; aucun traçage du Player installé, aucune mesure FPS fraîche native, aucun profil thermique ou GPU. La lecture ne garantit pas l'absence d'autres défauts. Le classement doit être ajusté aux traces des deux appareils ; un gain en ms/FPS n'est pas promis avant comparaison.

Parité API/CLI/editor/MCP : **N/A pour cette livraison documentaire sans modification de comportement ni de données**. Pas de rebuild MCP ni de mutation du jeu. Pour E01/E04, une future correction doit passer par la frontière canonique et prouver tous les transports. Pour les changements renderer internes, préserver les tests de transport et documenter l'absence de nouvelle sémantique. Les garanties de compatibilité et les données natives restent inchangées.

---

# Archive technique — audit du 8 août 2026

**La section qui suit est historique. Ses constats et résultats ne décrivent pas nécessairement le checkout du 27 octobre et ne remplacent pas la vérification ci-dessus.**

# Audit de performance — `map_runtime` (2026-08-08)

Audit statique complet du package (201 fichiers, ~372k lignes), mené en parallèle sur 5 sous-systèmes : boucle de rendu, battle/catalogues, couche application, chargement/persistance/session, border/shadow. Les constats sont référencés `fichier:ligne` et classés P0 → P3.

## Résumé exécutif

Le package a de **bonnes fondations** (culling viewport des tuiles, index spatiaux, cache tileset single-flight, `ui.Picture` pour les patchs d'occlusion, garde de changement sur les ombres d'acteurs) — mais plusieurs consommateurs **ignorent ces mécanismes** et recalculent des données statiques à 60 Hz. Quatre problèmes dominent :

1. **Rendu** : la résolution Smart Tile, les instructions de bordure et la fusion des collections d'ombres sont **reconstruites à chaque frame** alors que la carte est immuable (viewer read-only) — plusieurs milliers d'allocations/frame.
2. **Battle** : `TextPainter` reconstruit + `layout()` ~20-30×/frame dans les HUD, gradients/shaders recréés chaque frame, backdrop statique re-rasterisé, et **aucune `ui.Image` décodée n'est jamais `dispose()`** (cache non borné + cache FX recréé par combat → croissance mémoire native sur la session).
3. **Compilation/binaire** : `battle_sdk_rmxp_animation_catalog.dart` (283k lignes, 36 903 constructeurs const) coûte ~**2,5 Mo de snapshot AOT** et domine le temps de build/analyse ; tout est importé eagerly même sans combat.
4. **Sauvegarde** : chaque checkpoint fait **~8-10 traversées/sérialisations complètes de l'état + 3-4 SHA-256, tout sur l'isolate UI**. Le benchmark `game_save_codec_offload_profile_test.dart` profile `GameSaveCodecExecutor`… qui **n'est pas sur le chemin de prod** (`captureCheckpoint` → `HubSessionCheckpointCommitter` → `HubSaveRepositoryImpl`).

Transversal : **312 `debugPrint` non gardés** (non strippés en release, dont plusieurs dans `update()` et sur le chemin de sauvegarde, avec interpolation de collections).

---

## A. Boucle de rendu overworld (par frame)

### A1 (P0) — Smart Tile : résolution complète re-exécutée chaque frame
`map_layers_component.dart:509` → `smart_tile_layer_visual_resolver.dart:219-470` (map_core). Chaque `render()` :
- rescanne linéairement `catalog.presets` ;
- **reconstruit 3 `Map` depuis tout le catalogue** (atlases, animations, patterns) ;
- alloue contexte + règles + visuels par cellule visible ;
- construit et hashe **une chaîne par cellule de pattern** (`smart_tile_layer_visual_resolver.dart:442`).

~3-10k allocations/frame pour un viewport 20×15, × 2 composants (bg/fg) × cartes résidentes.
**Fix** : préparer une fois (étendre `SmartTilePatternOwnerIndex` déjà présent à `map_layers_component.dart:131`), mémoïser la résolution par cellule, ne re-choisir que la frame d'animation via `elapsedMs`.

### A2 (P0) — Bordure : instructions reconstruites chaque frame, sans index spatial
`map_layers_component.dart:438-443` → `border_runtime_draw_instruction.dart:86-143`. Deux passes sur toutes les features × cellules × placements, 1 `BorderRuntimeGroundInstruction` + 1 `BorderPixelRect` par cellule, + `List.unmodifiable` — par frame, par carte résidente (~240k objets/s pour 2 000 cellules). Puis `border_runtime_renderer.dart:17-68` : scan linéaire sans bucketing, `_animationFrame` (`:73-96`) re-somme **toutes** les durées de frames par instruction, 1-2 `Rect` alloués par instruction (`:163`, `:182`, `:56`).
**Fix** : construire une fois au mount (ou au prepare, partagé entre instances), pré-scaler les rects, précalculer la durée totale par snapshot, résoudre la frame active une fois par snapshot et par frame.

### A3 (P0) — `RuntimeTilesetImage.drawImageRect` : allocations sur *chaque* draw de tuile
`runtime_tileset_image.dart:150-172`. Le call le plus interne du renderer (tuiles, smart tiles, objets, placed elements, acteurs, bordures) alloue une liste de slices + 3 `Rect` par tuile, alors que le cas mono-chunk (< 4096 px) est l'écrasante majorité.
**Fix** : fast path mono-chunk → `canvas.drawImageRect` direct, zéro allocation. Gain transversal immédiat, changement quasi-une-ligne.

### A4 (P0) — Ombres : fusion + re-partition par frame, sans culling
`map_layers_component.dart:484-499` → `playable_map_game.dart:4020-4044` → `runtime_shadow_collection_merge.dart:4`. ~5 copies de liste + 3 traversées par frame, par carte résidente (`shadow_runtime_instruction_collection.dart:48-68`). Et `_paintShadows` dessine **toutes** les ombres statiques de la carte : l'API de culling (`shadowRuntimeInstructionIntersectsBounds`, `collectShadowRuntimeInstructions`) existe mais est **du code mort** (aucun call site).
**Fix** : cacher la fusion par `mapId`, invalider sur les événements de refresh existants ; passer `_visibleLocalRect` ; partitionner en une seule passe.

### A5 (P0) — Ombres projetées : bandes, paths, paints et instructions reconstruits par bâtiment par frame
`shadow_runtime_renderer.dart:50-57` : par bâtiment et par frame, 7 bandes → 7 `Path` + 7 `Paint` + 7 instructions complètes (avec re-validation `RegExp` + aire du polygone, `shadow_runtime_render_instruction.dart:52-61`) + **`int.parse` du hex couleur par ombre par frame** (`:85`). ~1 500 allocations/frame pour 20 bâtiments.
**Fix** : cuire les paires `(Path, Color)` à la construction de la collection (`runtime_projected_building_shadow_collection.dart:77`) ; résoudre la couleur une fois dans le constructeur d'instruction ; le render se réduit à 7 `drawPath` cachés.

### A6 (P1) — Classification foreground des calques : ~58 allocations de chaînes par appel, par frame
`map_layers_component.dart:1140-1188`, appelé de `:741` et `:1007`. Résultat constant pour la vie du composant.
**Fix** : `Map<String,bool>` calculée au constructeur ; variantes de markers en `const`.

### A7 (P1) — `_visibleTileCellRange` rescanne toute la palette par calque par frame
`map_layers_component.dart:227-278`. Les marges ne dépendent que de données immuables.
**Fix** : cacher les marges par layer id.

### A8 (P1) — Index spatial des placed elements : requêté une fois *par calque*, avec Set+sort+copies par requête
`map_layers_component.dart:1027`, `:1697-1715`. Récupère tous les éléments visibles puis jette ceux des autres calques (`instance.layerId.trim() != layerId`).
**Fix** : un index par layer id ; `query` sans allocation (buffer scratch + visit-stamp) ; clé de bucket `int` plate au lieu d'un record `(x,y)`.

### A9 (P1) — Tri complet des enfants du monde à chaque frame de mouvement
`playable_map_game.dart:3999-4004` : les setters `priority` déclenchent `rebalanceAll()` de Flame → re-tri O(n log n) de **tous** les enfants (dont des centaines de patchs d'occlusion statiques). `footPoint` (`player_component.dart:110`) alloue un `Vector2` par accès.
**Fix** : n'assigner `priority` que si la valeur arrondie change ; isoler les acteurs dans un parent dédié depth-sorted.

### A10 (P2) — Divers par frame
- `PlayerComponent.syncState` : re-layout complet (3 `Vector2`) à chaque frame idle (`player_component.dart:231-247`) → early-return si état identique.
- `OverworldActorComponent.render` : re-résolution d'animation + re-somme des durées + `Paint` par acteur par frame (`overworld_actor_component.dart:236-380`) → mémoïser dans `setMotion`.
- Patchs d'occlusion : `toAbsoluteRect().inflate(1)` par patch par frame (`placed_element_occlusion_patch_component.dart:136-141`) → cacher le rect absolu (statique).
- `.trim()` + `QuarterTurnGridTransform` + `Set<int>` de collisions reconstruits par instance par frame (`map_layers_component.dart:1029-1099`).
- Objets : `Paint()` **dans** la boucle par tuile (`map_layers_component.dart:918`) — alors que `:1022` fait déjà la bonne chose.
- Dialogue : `state.text.runes.length` (O(n)) réévalué par frame (`dialogue_overlay_component.dart:75-77, 114`).
- `scripted_entity_movement_controller.dart:353-354, 505` : `keys.toList()..sort()` par frame même à vide → guard `isEmpty` + liste triée maintenue.
- `placed_behavior_runtime_cooldown.dart:115-123` : `prune` par frame → `removeWhere` ou suppression (le chemin lazy `canTrigger:74-77` suffit).

---

## B. Battle & catalogues

### B1 (P0, build/binaire) — `battle_sdk_rmxp_animation_catalog.dart` : 8,4 Mo / 283k lignes de graphe const
874 animations, 36 903 constructeurs const (22 076 cells, 11 702 frames, 2 250 timings). Tout `static const`, importé non-deferred jusqu'à `playable_map_game.dart` → dans le snapshot même sans combat. Coûts : temps de compile/analyse dominant du repo, ~**2,4-2,9 Mo** de `libapp.so`, graphe désérialisé en heap en debug/tests (~30 fichiers de tests battle le paient).
**Fix (ordonné)** :
1. `byAnimationId` → asset binaire packé (`~500 Ko` vs ~2,5 Mo ; header index `animationId → offset`, cell = 15 octets), chargé lazily et décodé **seulement** pour les `requiredFxIds` du plan (`battle_animation_plan.dart:106`). Généré par le même `tool/import_pokemon_sdk_rmxp_animations.py`.
2. Garder les 3 petites maps int/string en const Dart (~60 Ko) pour que le resolver reste synchrone.
3. Alternative sans changement d'API : structure-of-arrays (`Int16List`/`Uint8List` + vue accesseur) → ~5× moins de mémoire, ~200k pointeurs GC en moins.
4. Ne **pas** splitter en 875 part files (inutile).
⚠️ `test/battle_sdk_rmxp_animation_catalog_test.dart:8` asserte `hasLength(874)` — porter l'assertion sur l'asset décodé.

### B2 (P0, frame time) — `TextPainter` reconstruit + `layout()` ~20-30×/frame
`battle_scene_hud_component.dart:409-425` (×6-7 par HUD, ×2 HUDs) et `battle_command_panel_component.dart:2805-2836` (16-20 de plus menu ouvert). ~1 800 shaping HarfBuzz/s pour du texte qui change quelques fois par seconde ; `ui.Paragraph` jamais `dispose()`.
**Fix** : cache `(text, style, maxWidth) → TextPainter` sur le composant, invalidé dans `sync()` ; dispose à l'invalidation.

### B3 (P0, frame time) — Layout HUD complet recalculé dans `update()` à chaque frame de tween HP
`battle_scene_hud_component.dart:184, 189` → `_buildLayout()` → 4 `TextPainter.layout()` de plus (`battle_scene_hud_layout.dart:235`). Le drain de HP est l'animation la plus fréquente d'un combat : ~20 shaping/frame ×2 HUDs en pointe.
**Fix** : séparer géométrie (recalcul sur `sync()`/resize) et texte de valeur HP (recalcul quand l'entier affiché change).

### B4 (P0, mémoire) — `ui.Image` jamais disposées ; cache FX recréé par combat
Un seul `dispose()` dans tout le sous-système (`battle_fx_bundle_cache.dart:91`, le codec). `BattleVisualAssetCache` (`battle_visual_asset_cache.dart:15-18`) : map non bornée, vécue toute la session (`playable_map_game.dart:521-522`). `BattleFxBundleCache` construit **par combat** (`battle_overlay_component.dart:454`) : re-décodage des mêmes PNG à chaque combat + images orphelines du combat précédent (14 Mo d'assets sur disque, RGBA décodé = plusieurs fois plus).
**Fix** : hisser le cache FX au scope jeu ; `dispose()` sur les deux caches (appelé de `BattleOverlayComponent.onRemove()` pour le battle-scoped) ; borne LRU (~64 images) sur le cache sprites.

### B5 (P1) — Shaders de gradient recréés chaque frame (8 sites) + backdrop statique re-rasterisé
`battle_scene_combatant_component.dart:445-457`, `battle_command_panel_component.dart:876-2958` (6 sites), `battle_scene_backdrop_component.dart:81-289` (6 gradients + 2 `Path` + ~13 draws/frame pour un contenu qui ne dépend que de `(size, palette, image)`).
**Fix** : cacher les `Paint` à `sync()`/resize ; enregistrer le backdrop dans un `ui.Picture` (gain le moins cher du fichier).

### B6 (P1) — Churn `TextPaint`/`Vector2` par frame de caméra/animation
`battle_scene_combatant_component.dart:925-955` : nouveau `TextPaint` assigné à `textRenderer` chaque frame (invalide le cache texte de Flame). `battle_camera_rig.dart:88-112` : 3 `Vector2` + `math.pow` boxé/frame, getter `offset` qui clone ; +5 `Vector2`/frame en aval (`battle_overlay_component.dart:2612-2628`).
**Fix** : garde d'égalité sur l'opacité ; mutation in place (`setFrom`/`lerp`), `x*x` au lieu de `pow`.

### B7 (P2) — Divers battle
- `battle_fx_layer_component.dart:85-127` : 6 `whereType().toList()` + 2 `size.clone()` par frame → une traversée, buffer réutilisable.
- `battle_rmxp_animation_component.dart:158-190` : ~80 allocations/frame/composant (cells, `Rect`, `ColorFilter` 20 éléments, `Paint` par cell) → mémoïser `colorFilterForHue` (360 valeurs), `Paint` réutilisé, recalcul des cells seulement au changement de frame.
- `battle_scene_hud_component.dart:199-207` : `drawShadow` avec `Path` neuf par frame → path caché ou ombre dans le Picture du backdrop.
- Chaînes par frame dans `render()` (`battle_command_panel_component.dart:2432, 2153, 2163`) → précomputer dans les snapshots existants.
- `battle_visual_asset_cache.dart:117-160` : readback RGBA + scan O(W·H) sur l'isolate UI à l'entrée en combat → `Isolate.run` ou métadonnées précalculées.
- `battle_move_visual_recipe_library.dart` (12,8k lignes, 276 cases) : pas un problème mémoire (stateless) ; ~300-600 Ko de code AOT. Basse priorité — collapsible en ~20 templates paramétrés si on y touche.
- Non-problèmes : `BattleFxCatalog`/`BattleMoveVisualCatalog` (const, petits) — à laisser tels quels.

---

## C. Couche application (logique)

### C1 (P0) — Callback de passabilité du pathfinding : O(entités) + 4 allocations **par nœud A\***
`scripted_npc_anchor_passability.dart:50-68`, branché comme `isPassable` (`playable_map_game.dart:12742, 12788`). Par nœud expansé : scan linéaire de `world.map.entities`, `copyWith` freezed, `toList`, `toSet` d'un générateur `sync*` re-piloté. ~900 × tout ça pour une région 30×30, à chaque re-path de patrouille.
**Fix** : hisser les invariants hors du callback — entité résolue une fois, `dynamicBlocked` précalculé en `Set<GridPos>` par appel à `findPath`, offsets de collision précalculés et translatés par nœud.

### C2 (P0) — Présence PNJ : JSON de scénarios re-parsé par entité, projection recalculée par entité
- `npc_runtime_presence.dart:36` : `buildGlobalStoryChapterStepIndex` → `jsonDecode` du blob authoring de **chaque** scénario globalStory, appelé par entité, ×4 par refresh (monde reconstruit 2×, 2 index par monde), et `_refreshWorldNpcPresence` a 15 call sites (flags, dialogues, combats, warps…). Idem `playable_map_game.dart:2729` par résolution de dialogue.
- `runtime_world_rule_projection_hook.dart:11-44` : projection complète + 9 copies `unmodifiable` **par PNJ** (`playable_map_game.dart:2746` dans la closure par entité).
- `map_entity_runtime_predicate_evaluator.dart:30-34` : getters `.toSet()` → Set complet réalloué par évaluation de prédicat.
- `step_studio_world_presence_runtime.dart:164-183` : Set normalisé reconstruit par PNJ + scan linéaire de toutes les règles + `trim()` redondants (déjà trimmées à la construction `:116-129`).

**Fix** : cacher `chapterIndex` à côté de `_cachedStepStudioWorldRules` (`playable_map_game.dart:1406-1417`) ; mémoïser la projection par `(mapId, gameState, manifest)` ; `late final` sur les getters ; règles indexées `Map<'mapId|entityId', List<Rule>>`.

### C3 (P1) — Decode JSON cartes/manifest/validation sur l'isolate UI à chaque warp
`load_runtime_map_bundle.dart:111, 127-134, 175-190` : seul le read est async ; `jsonDecode` + `fromJson` + validateurs + composition visuelle sont synchrones → stall de plusieurs centaines de ms par warp sur une grosse carte. Un seul `Isolate.run` dans tout le package (`game_save_codec_executor.dart:88`).
**Fix** : `Isolate.run` autour de decode+fromJson (objets freezed → sendables).

### C4 (P1) — Dialogues relus du disque et re-parsés à chaque interaction PNJ, puis clonage profond intégral
`load_dialogue_content.dart:15-32` (aucun cache — le caller loggue déjà `elapsedMs`, `playable_map_game.dart:10136`) + `dialogue_runtime_models.dart:70-102` : `mapText` clone **tous** les nœuds/steps/choix et passe la regex `{{var}}` sur chaque ligne, y compris les nœuds jamais visités.
**Fix** : cache LRU `(path, mtime) → List<YarnNode>` ; interpolation lazy à l'affichage dans `_resolveStep`.

### C5 (P1) — Caches de loaders neutralisés : instances reconstruites à chaque appel
Chaque loader a un cache correct (dédup in-flight incluse) mais **par instance**, et les consommateurs construisent la leur :
`runtime_player_pokemon_progression_hydrator.dart:111`, `player_service_runtime_controller.dart:1831`, `runtime_battle_reward_resolver.dart:91-95`, `runtime_pokemon_learnset_loader.dart:25`, `runtime_battle_setup_mapper.dart:43`, `runtime_psdk_battle_setup_mapper.dart:19`, `runtime_battle_combatant_seed_builder.dart:404-405`, `runtime_pokemon_evolution_loader.dart:18`, `runtime_move_machine_loader.dart:31`. Le catalogue de moves (gros JSON) est parsé jusqu'à 3× **par début de combat**.
**Fix** : holder `RuntimePokemonDataLoaders` longue durée possédé par `PlayableMapGame` (ou `_cache` en `static`, 2 lignes, les clés incluent déjà le project root), injecté via les paramètres `?? Default()` existants.

### C6 (P1) — Menu pause : catalogue d'espèces relu séquentiellement à chaque ouverture ET après chaque usage d'objet
`runtime_player_pause_data_builder.dart:455-541` : `readAsString` + `jsonDecode` **séquentiels** par fichier d'espèce (~900 pour un dex complet), builder `const` sans état, reconstruit par appel (`playable_map_game_session_runtime.dart:263`) ; appelé 2× par interaction sac (`runtime_player_coordinator.dart:291, 336`). `_loadMoveMachineAvailability` (`:289-317`) : jusqu'à ~120 reads séquentiels de plus (sac × équipe).
**Fix** : cache du catalogue parsé par project root pour la session (données immuables), `Future.wait`, mise à jour in place de la section sac.

### C7 (P2) — Divers application
- `runtime_player_pokemon_progression_hydrator.dart:164-213` : fallback qui décode **tout** le répertoire species au load d'une save, avec `keys.toSet()` par itération → index `Map<basename, File>` + compteur ; ou réutiliser le species loader caché.
- `player_service_runtime_controller.dart:1457/1605` : `_shopEntries` calculé 2× par frappe dans le shop (re-normalise le sac en mode vente) → passer la liste en paramètre.
- `dialogue_runtime_models.dart:150, 212` : `indexWhere` par titre à chaque jump Yarn → `Map<String, YarnNode>`.
- `script_runtime_controller.dart:151-156` : `firstWhere` + exception derrière un type nullable → index + `null` honnête.
- `runtime_manifest_tilesets.dart:81, 101` : index `elementById` construit 2× par load.
- `runtime_playtest_port.dart:79-108` : historique d'événements non borné (dev-only) → ring buffer.
- `runtime_battle_move_bridge.dart:1545-1549` : scan linéaire du registre PSDK → const map (mineur).

---

## D. Chargement, persistance, session

### D1 (P0) — Pipeline de checkpoint : ~8-10 passes de sérialisation + 3-4 SHA-256, isolate UI
Chemin réel : `playable_map_game_session_runtime.dart:311-319` → `hub_session_checkpoint_committer.dart:59-72` (app) → `save_envelope_codec.dart` (map_core) → `hub_save_repository_impl.dart:100-126, 546-558` (app). Par checkpoint : `toJson` complet ; canonicalisation + sha256 ; `create()` qui **re-décode et re-checksum ce qu'il vient d'écrire** (`save_envelope_codec.dart:61→245`) ; pretty-print `withIndent('  ')` (+30-40 % de payload) ; `utf8.encode(source).length` **juste pour lire `.length`** (`:78`) ; re-decode de vérification ; ré-encode UTF-8 ; relecture du fichier temp + 4e checksum. `_writeCanonical` (`:484-550`) fait un `jsonEncode` **par chaîne** + tri des clés par objet.
Déclencheurs : pause, lifecycle, exit, manual, completion, defeatRecovery (pas par pas de déplacement) — mais c'est le hitch UI dominant à chacun de ces moments.
**Fix** : supprimer le self-verify redondant de `create` ; supprimer le round-trip `decode(encode(...))` de `writeVerified` ; encodage compact sur disque ; déplacer canonicalisation+sha256+encode dans `Isolate.run` — **en réutilisant `GameSaveCodecExecutor` pour que l'offload s'applique enfin au chemin de prod** (le benchmark existant mesure aujourd'hui un chemin mort).

### D2 (P1) — Tilesets décodés deux fois, dont une en pur Dart sur l'isolate UI
`tile_image_loader.dart:273-335` : `img.decodeImage` (package:image, 10-50× plus lent que le codec moteur) puis re-décodage des **mêmes octets** via `ui.instantiateImageCodec` ; dans le cas courant le décodage pur Dart ne sert qu'à lire width/height. Branche multi-chunk : `copyCrop` + **ré-encodage PNG** par chunk. `_applyTransparentColor` (`:337-362`) : boucle par pixel avec accesseurs boxés (~1M itérations pour un atlas 1024²).
**Fix** : sauter `img.decodeImage` dans le cas courant (dimensions via la `ui.Image` ou peek IHDR 24 octets) ; multi-chunk via `srcRect` au draw (le mapping existe déjà, `runtime_tileset_image.dart:156-178`) ; couleur transparente sur `Uint8List` plat + `Isolate.run`. Bonus : `loadTilesetImagesById` (`:369-392`) séquentiel → `Future.wait`.

### D3 (P1) — Préparation bordure : re-décodage PNG complet + fingerprint par pixel à chaque mount/warp
`border_runtime_readiness.dart:43, 131-175` : `readAsBytes` + `img.decodeImage` + boucle par pixel (`getPixel` = 1 objet boxé/pixel), synchrone sur l'isolate UI, exécuté à chaque prepare — y compris avec un bundle **déjà en cache** (`playable_map_game.dart:2952` et 6 autres sites). Hitch de plusieurs centaines de ms par warp.
**Fix** : mémoïser l'intégrité par `(path, mtime, length, sourceRect, transparentColor)` ; sinon a minima `compute()` + `getBytes()` au lieu de `getPixel`. Bonus : `border_runtime_asset_cache.dart:117-141` charge séquentiellement → `Future.wait` (le cache single-flight dédupe déjà, `:86-115`).

### D4 (P2) — `GameSaveCodecExecutor` : estimateur plus cher que ce qu'il évite
`game_save_codec_executor.dart:56-116` : traversée récursive complète avec `toString()` par nombre/bool avant chaque encode ; sous le seuil 1 Mio on paie l'estimation **et** l'encode local ; l'estimation ignore l'échappement et l'indentation ; `Isolate.run` copie structurellement le JSON capturé à l'envoi.
**Fix** : supprimer l'estimateur — proxy bon marché (taille du save précédent, cachée) ou offload systématique.

### D5 (P2) — `file_game_save_repository.dart` : platform channel + exists/create à chaque opération, écriture non atomique
`:29-36` : `getApplicationSupportDirectory()` + `exists()`/`create()` à chaque save/load/exists/delete. `:65` : `writeAsString` sans flush ni temp+rename → un crash mi-écriture tronque la save (le repo Hub le fait correctement, ce fallback non).
**Fix** : mémoïser le path ; temp + flush + rename.

### D6 (P2) — 312 `debugPrint` non gardés, 0 `kDebugMode`
Non strippés en release ; les arguments interpolés sont évalués quoi qu'il arrive. Points chauds : `file_game_save_repository.dart:62-68` (interpole `completedStepIds` 2× par save), `playable_map_game.dart:10628-10630` (idem + cutscenes par save), `:3808, 3872, 3892` (dans `update()`), `load_runtime_map_bundle.dart:44` (par tileset au load), `scripted_entity_movement_controller.dart:159-199` et `playable_map_game.dart:12753` (par nœud bloqué du pathfinder, avec `map().join()`).
**Fix** : garde `kDebugMode` ou helper à argument lazy `_trace(String Function())`.

### D7 (P3) — `RuntimePlayerSnapshot` : 2 copies de collections + re-validation par publication
`runtime_player_models.dart:201-236` : `List.unmodifiable` + `Map.from` + 2 boucles de validation à chaque `next()` (~25 sites), y compris par tick de progression de chargement (`runtime_player_coordinator.dart:823-830`).
**Fix** : constructeur interne non vérifié réutilisant par identité les collections déjà validées.

---

## Déjà bien optimisé (à ne pas casser)

- Culling viewport des tuiles/objets/entités/placed elements (`map_layers_component.dart:13099`, `_visibleLocalRect`) — le design est bon, ce sont les **consommateurs** ombres/bordures/smart-tiles qui l'ignorent.
- Index construits au constructeur de `MapLayersComponent` (`:110-138`).
- `PlacedElementOcclusionPatchComponent` : pattern `ui.Picture` exemplaire (`quarter_turn_pixel_renderer.dart:40-120`) — c'est le modèle à répliquer (backdrop battle, bordures).
- Fast paths de `drawQuarterTurnPixels` (`:151-238`).
- `RuntimeTilesetImageSingleFlightCache` (`tile_image_loader.dart:23-199`) : dédup, coalescing, disposal corrects.
- Garde de changement des ombres de contact acteurs (`playable_map_game.dart:4062-4070`) — nuance : la liste de sources est allouée *avant* la garde (`:4055`), et `enableActorContactShadows: false` dans le chemin session shippé (`playable_map_game_session_runtime.dart:194`) court-circuite le tout.
- Collections statiques d'ombres construites une fois par mount (`:11995-11996`, `:10037-10038`).
- Pas de fuite de streams/timers dans `application/` ; pas de churn freezed par tick (hors C1).
- Profiling de rendu à coût nul quand désactivé (`map_layers_component.dart:316-330`).

---

## Plan de chantier proposé (par lots)

| Lot | Contenu | Effort | Gain attendu |
|---|---|---|---|
| **1. Quick wins rendu** | A3 (fast path drawImageRect), A6, A7, gardes `isEmpty` (A10), Paint hors boucle (A10), D6 (debugPrint chauds) | Faible | Milliers d'allocations/frame en moins, immédiat |
| **2. Caches statiques rendu** | A2 (bordures construites au mount + rects pré-scalés), A4+A5 (fusion ombres cachée + bandes cuites + couleur pré-résolue + culling) | Moyen | Supprime le gros du coût par frame hors smart tiles |
| **3. Smart Tile préparé** | A1 (résolution mémoïsée par cellule, frame d'animation seule par frame) | Élevé | Le plus gros poste de la passe sol |
| **4. Battle frame time** | B2, B3 (caches TextPainter + layout scindé), B5 (gradients + Picture backdrop), B6, B7 | Moyen | Combats fluides, surtout pendant les drains de HP |
| **5. Mémoire battle** | B4 (dispose + LRU + cache FX au scope jeu) | Moyen | Stoppe la croissance mémoire native par session |
| **6. Sauvegarde** | D1 (dé-duplication des passes + offload isolate sur le vrai chemin), D4, D5 — et rebrancher le benchmark sur le chemin de prod | Moyen | Supprime le hitch UI à chaque checkpoint |
| **7. Chargement/warp** | C3 (decode en isolate), D2 (double décodage tilesets), D3 (readiness bordure mémoïsée), C4 (cache dialogues) | Moyen | Warps et entrées de carte sans stall |
| **8. Logique PNJ/pathfinding** | C1, C2 (caches chapterIndex/projection/règles), C5 (loaders partagés), C6 (catalogue pause caché) | Moyen | Refresh de présence et re-paths indolores |
| **9. Catalogue RMXP** | B1 (asset binaire lazy + maps const résiduelles) | Élevé | −2,5 Mo binaire, temps de build/analyse, mémoire debug/tests |

Les lots 1-2 sont sans risque (mémoïsation pure de données immuables, comportement identique). Le lot 9 est le plus structurant et mérite son propre chantier avec l'outil Python de génération.

---

# Addendum de clôture (2026-08-08)

Les 9 lots ont été livrés le jour même, un commit par lot, poussés sur `main` :

| Lot | Commit | Contenu livré |
|---|---|---|
| 1 | `4797a6bf2` | Quick wins rendu (fast path `drawImageRect`, caches foreground/marges, gardes `isEmpty`, `debugPrint` chauds) |
| 2 | `d13311318` | Bordures construites au mount, ombres cuites par instruction, fusion mémoïsée, culling branché |
| 3 | `fe9ab5b5d` | `SmartTileLayerVisualPlan` (map_core) : préparation par calque, cellules lazy, variantes d'animation pré-construites, test de parité plan ↔ batch |
| 4 | `4226964cb` | Battle frame time : cache `TextPainter` LRU, layout HUD scindé, caches de gradients, backdrop en `ui.Picture`, churn `TextPaint`/`Vector2` éliminé |
| 5 | `6320c1c2a` | Mémoire battle : cache FX au scope jeu, `dispose()` au teardown, borne LRU sur le cache de sprites, scan de pixels en isolate |
| 6 | `c88c08b24` | Sauvegarde : passes redondantes supprimées (self-verify de `create`, round-trip de `writeVerified`), création d'enveloppe en `Isolate.run`, estimateur borné, écriture atomique du repo fallback |
| 7 | `710b98d35` | Chargement/warp : tilesets décodés une fois (codec moteur), parse cartes/manifest en isolate, readiness bordure mémoïsée (clé stat) + isolate, dialogues cachés par (chemin, mtime, taille) |
| 8 | `87b80740d` | PNJ/pathfinding : sonde A* préparée + prédicat de blocage vivant, index de chapitres et projection World Rules cachés, loaders partagés, catalogue pause signé |
| 9 | `90d2539de` | Catalogue RMXP : 282 843 → 1 730 lignes, asset binaire 480 Ko décodé au premier combat (round-trip validé champ par champ avant suppression du const) |

**Vérification** : `dart analyze` propre à chaque lot ; suites complètes vertes à chaque lot (map_runtime 2128, map_core 3968, éditeur smart tiles 219, hub session+saves 61 — y compris les tests de crash-recovery à injection de pannes du store de sauvegarde). Les seuls échecs restants préexistaient à l'audit et ont été vérifiés par stash sur HEAD : `border_map_layers_component_ordering_test` (ne compile plus contre l'API map_core actuelle), ROT-01 (fixture désalignée), `save_envelope_codec_test` (fixture Phase 0), 16 tests d'artefacts/gates map_core, 1 test de flux de gestes smart tiles éditeur.

## Constats traités hors périmètre initial des lots

- Bug attrapé en route (lot 7) : le nouveau chemin de transparence des tilesets gardait le RGB des pixels keyés avec alpha 0 — invalide en convention prémultipliée (teinte au blending). Détecté par le test de rendu réel des bordures, corrigé en zéroant le pixel entier.
- Piège de sur-capture des closures `Isolate.run` (lot 6) : un closure créé dans une méthode capture `this` (donc le store et ses hooks de test non envoyables). Convention adoptée : construire les closures d'offload dans des portées statiques/top-level ne contenant que des valeurs envoyables — appliquée aux lots 6, 7 et à la readiness bordure.

## Constats délibérément non traités

Écarts de design assumés (le fix de l'audit a été remplacé par mieux) :
- **A4/A5 invalidation** : validation par identité à la lecture plutôt que hooks d'invalidation disséminés.
- **C1 (blocage dynamique)** : prédicat sur l'état vivant plutôt que `Set` caché — les réservations mutent au milieu d'un tick via 12 sites, un cache aurait pu faire traverser un PNJ.
- **C5 (loaders)** : partage des instances du jeu plutôt que caches `static` — un cache process-level servirait des données périmées après édition + relancement de playtest dans le même process.
- **D4 (estimateur)** : borné par le seuil plutôt que supprimé — préserve les décisions d'offload et les tests existants.
- **F15 partiel (RMXP)** : la liste des cellules visibles n'est pas mémoïsée par index de frame — leur position dépend d'ancres de combattants vivantes entre ticks (projectiles).

Reliquat classé par intérêt décroissant, pour un éventuel lot 10 :
- **C4 (suite)** : interpolation lazy des dialogues — `mapText` clone encore tous les nœuds/choix du fichier à l'ouverture et passe la regex `{{var}}` sur des nœuds jamais visités.
- **C6 (suite)** : `_loadMoveMachineAvailability` garde sa boucle sac × équipe séquentielle et le pause builder construit encore ses loaders machine/évolution par appel ; la section sac est toujours entièrement reconstruite après usage d'objet.
- **A8/A9** : index spatial des placed elements par calque (requête + Set + tri par calque par frame) et tri complet des enfants du monde sur changement de `priority` (isoler les acteurs dans un parent depth-sorted).
- **A10 reliquat** : `PlayerComponent.syncState` par frame idle, re-résolution d'animation des acteurs, rect absolu des patchs d'occlusion, `.trim()`/transforms par instance par frame, `runes.length` du dialogue.
- **D6 reliquat** : ~290 `debugPrint` non gardés restants (les points chauds — save, pathfinding, update, loaders — sont faits).
- **D7** : constructeur non vérifié pour `RuntimePlayerSnapshot.next()`.
- **C7 reliquat** : shop entries calculées 2× par frappe, lookup de nœuds Yarn linéaire, historique playtest non borné, etc.
- **B7 reliquat** : `battle_move_visual_recipe_library.dart` (12,8k lignes) collapsible en ~20 templates — uniquement si on y retouche.

## Limite de la validation

Tout a été vérifié par analyse statique et par les suites de tests (y compris les tests pixel-level des renderers modifiés et le benchmark d'offload du codec). **Aucune session de jeu réelle n'a été jouée** : le scénario qui exerce le plus de chemins modifiés — warp vers une carte à bordures animées et bâtiments à ombres projetées, ouverture du menu pause, combat complet avec animations RMXP, sauvegarde — reste à faire tourner une fois en conditions réelles.
