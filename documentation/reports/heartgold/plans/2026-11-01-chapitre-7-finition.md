# Chapitre 7 HGSS — Implementation Plan de finition

> **For agentic workers:** Use the repository `executing-plans` skill to implement this plan task by task. Independent specification and quality reviews apply to changed behavior. A planning request does not start implementation or authorize Git writes.

**Goal:** Finir le chapitre 7 et les annexes convenues dans le jeu principal, en produisant des capacités Avelune réutilisables et une livraison vérifiée préservant les sauvegardes.

**Architecture:** Les contrats appartiennent à `map_core`, les décisions pures à `map_gameplay` ou `map_battle`, leur exécution à `map_runtime`, et l'authoring canonique à `map_authoring`. Studio et MCP consomment ces contrats. Les règles et références propres à HeartGold restent dans le projet de jeu.

**Tech Stack:** Dart, Flutter, Flame existant, authoring JSONL/CLI et MCP, données et médias HGSS sourcés, carnet de suivi et export `.avelunegame`.

## Périmètre et point de départ

Demande de Yoahn : découper précisément le travail restant. Ce document planifie les lots ; il ne constitue pas leur implémentation. Aucune refonte graphique de Studio n'est incluse.

État relu le 1 novembre 2026 : scénario 3/3, annexes 2/7, soit 5/10 objectifs entièrement validés dans le carnet. Les lots ci-dessous ne remplacent pas ce dénominateur et ne mesurent pas un pourcentage de temps restant. Le téléchargement courant demeure 0.1.11.

Déjà acquis : scénario principal jusqu'à Hector/Silver, four à charbon, pêche ; huit Noigrumiers et leurs conditions plein/vide dans le jeu principal ; deux sous-sols de Centres Pokémon en solo ; socles de puzzle, fabrication différée, récompenses quotidiennes, Surf et Force. Leur présence ne vaut pas validation générale de Studio, du Player ou des appareils.

Preuve récente prioritaire sur les anciens résumés d'`etat.json` : `creation/ecorcia-chapitre7-annexes/revisites/qualification-runtime-puits.json`, SHA `866691e48e9f9253cc4580bf851c33ebdb9d2e89075f896bd04f4a2d819a6d92`. Le parcours Force → Surf → B2 → B1 avec deux écritures durables et trois boots passe dans le runtime de production sans affichage. Le runner 9366 sort 0, `00:16 +1: All tests passed!`, aucun descendant restant. L'intégration au jeu principal, la présentation Surf et l'acquisition narrative des CS restent distinctes.

Répertoires de référence :

- Moteur : `/Users/karim/Project/pokemonProject`.
- Jeu principal : `/Users/karim/Project/Pokemon HeartGold/jeu`.
- Préparations et reçus : `/Users/karim/Project/Pokemon HeartGold/creation/ecorcia-chapitre7-annexes`.
- Carnet : `/Users/karim/Project/Pokemon HeartGold/suivi`.
- QA existante à réutiliser : `/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/revisites-content`.

Audit initial : `main` partagé, HEAD `b207167e47ca4c0b9a304159f9e0068e180561eb`, 134 chemins modifiés ou non suivis avant cette planification. Aucun test de code ni build relancé pour produire ce plan. Aucun écrivain Puits/arbres, render host ou Studio identifié par les noms ciblés lors de l'observation ; ce constat doit être rafraîchi avant mutation et ne vaut pas verrou exclusif.

## Règles de fermeture communes

- Un lot doit avoir son delta exact, ses tests ciblés, sa relecture indépendante, son résultat et ses limites. Un PASS de fixture ne vaut pas intégration au jeu principal.
- Pour une nouvelle capacité : contrats, logique, consommation réelle runtime, configuration guidée minimale dans le design system, API/CLI/MCP et capability d'export si nécessaire. Ne pas ajouter un champ sans ses consommateurs.
- Les changements locaux restent incrémentaux : unités de stockage et dépendances nommées avant le code ; tests de nombres de lectures/écritures/décodages/invalidations avec contenu et historique non concernés. Feedback ≤100 ms et persistance ≤500 ms, première opération et répétitions séparées, build/machine documentés et réouverture vérifiée. L'exception utilisateur ≤1000 ms concerne seulement le réglage de visibilité des arbres de ce lot ; elle ne s'étend à aucun autre contrôle.
- Ne réimplémenter ni Force, ni pêche, ni puzzle générique, ni calendrier existant, ni fabrication différée, ni sauvegarde déjà disponibles. Compléter les frontières manquantes et démontrer leur usage.
- Surf et Force ne sont pas acquis à ce stade du scénario HGSS. Les accès futurs restent verrouillés dans une sauvegarde authentique de fin de chapitre 7. Les parcours autorisés peuvent utiliser une fixture déclarée ; ils certifient la revisite préparée, pas l'acquisition future dans l'histoire.
- Les données du jeu passent par l'API canonique avec préimages, opération durable, plan/apply et relecture. Aucun remplacement par les cartes QA dépouillées, aucun effacement de données concurrentes.
- Notion : rattacher les preuves au contexte existant du domaine concerné, sans créer de tickets de cartes ou de bugs isolés. Le contexte de cette planification est le ticket existant du domaine Monde & narration `403197a7bfa581698d45e152e7d0106a`. Les lots techniques gardent leurs contextes produit existants quand ils en ont un. Une implémentation vérifiée est proposée `TO REVIEW` ; `DONE` appartient à Yoahn.
- Les statuts FG ci-dessous sont des rattachements, sans modification de la roadmap : les états historiques `TODO`, `PARTIAL` ou `DEFERRED` ne sont pas promus par ce plan.

## Ordre des lots

| Lot | Résultat | Nature | Dépendances de fermeture |
|---|---|---|---|
| C7-01 | Dépendances Pokémon et attaques réellement exploitables | Données + raccord moteur | Audit du propriétaire Pokémon/combat concurrent |
| C7-02 | Présentation Surf complète | Médias + runtime si un raccord manque | C7-01 pour le parcours réel |
| C7-03 | Revisite du Puits intégrée au jeu principal | Contenu + validation | C7-01, C7-02 |
| C7-04 | Élixir tous-PP configurable et utilisable | Code réutilisable | Contrat actuel des objets/combat |
| C7-05 | Nord du premier sous-sol des Caves complet | Contenu | Fermeture utile de C7-01, C7-02 |
| C7-06 | Second sous-sol des Caves complet hors Lokhlass | Contenu | C7-05 ; C7-04 pour l'Élixir seulement |
| C7-07 | Rencontre périodique à résultat durable | Code réutilisable | Frontière Pokémon/combat stabilisée avec C7-01 |
| C7-08 | Lokhlass et événements calendaires/contacts | Contenu | C7-06, C7-07 |
| C7-09 | Corde Sortie 3D et usage contextuel avant consommation | Code réutilisable | Contrats d'objets existants |
| C7-10 | Raccords et parcours physiques d'Alpha | Contenu | État courant d'Alpha et son propriétaire |
| C7-11 | Kabuto, secret et récompenses d'Alpha | Contenu | C7-01, C7-09, C7-10 |
| C7-12 | Parcours intégrés et présentation du chapitre | Validation + corrections ciblées | C7-01 à C7-11 |
| C7-13 | Mise à jour, export, publication et fermeture QA | Livraison | C7-12 |
| C7-D1 | Recettes Fargas, sept Balls et capture | Différé explicitement | Refonte Pokémon/combat |

L'ordre numéroté est l'ordre de livraison lisible ; les prérequis exacts priment. Il n'impose pas de bloquer un travail indépendant, mais une seule intégration de contenu est écrite à la fois.

C7-01 se ferme progressivement par ensemble de dépendances réellement utilisé : Puits, Caves, Lokhlass, Alpha. Chaque ensemble est une fermeture transitive cohérente : ne pas supprimer des évolutions, échanges ou conditions source pour réduire artificiellement l'admission. L'admission de toutes les espèces préparées n'est pas un préalable à chaque lot. De même, C7-04 ne bloque que l'objet Élixir, et C7-07 ne bloque que les rencontres périodiques, pas l'exploration ordinaire des Caves.

## C7-01 — Admettre les dépendances Pokémon et attaques

**Point de départ :** préparation source de 25 espèces, 100 documents, 125 médias, 49 attaques et 7 talents ; elle n'est pas une admission au jeu principal. Les effets réels et quatre dépendances d'objets restent à qualifier. Les PP/compatibilités de CS d'une fixture ne remplacent pas le catalogue de jeu.

**Fichiers et frontières :** `revisites_donnees.py`, `revisites_pack.dart`, `revisites_assets_test.py`, `revisites_contract_test.dart` dans le chantier ; `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart` ; catalogues Pokémon/attaques/objets/trainer du jeu via `map_authoring`. `map_battle` uniquement pour un effet manquant établi et coordonné avec son propriétaire.

- [x] Revalider les préimages et le plus petit inventaire des espèces, équipes, attaques dont Surf/Force/Coupe, métadonnées HM, talents et quatre objets référencés (`fire-stone`, `kings-rock`, `thunderstone`, `water-stone`) ; vérifier ce qui a déjà été livré par le chantier Pokémon concurrent. Examiner les effets des talents réellement utilisés, notamment Adaptability, Scrappy et Volt Absorb, et les évolutions référencées, sans créer de définitions de remplacement.
- [x] Admettre seulement les dépendances nécessaires, avec identités existantes et médias protégés intacts ; ne pas fabriquer d'effet de combat de remplacement.
- [x] Vérifier chargement, usage des attaques et équipes réellement concernées, enseignement/compatibilité des CS sur fixture déclarée, conservation après Continue. Un effet non implémenté reste un blocage explicite.

**Fermé quand :** chaque référence utilisée par les lots suivants se résout et son comportement nécessaire fonctionne ; les combats utilisent les vraies définitions. Aucune activation des règles de capture Fargas. Rattachements : FG-073, FG-086, FG-108, FG-120, FG-129 selon les consommateurs touchés.

### Exécution C7-01 — 2 novembre 2026

**Verdict : implémenté et vérifié sur le jeu principal, proposé TO REVIEW.** Les autres lots ne sont pas commencés par cette livraison. Le téléchargement reste 0.1.11 ; aucun export supplémentaire. La présentation Surf et les parcours graphiques/appareils restent C7-02/C7-12.

Audit initial de cette exécution : HEAD `6bc630faaf2167773879a40b22ebfea896fd35b9`, onze chemins étrangers déjà modifiés. Main a ensuite avancé à `d966cb0c85ea636abe7028ae6e607576bcb9c19a` par un autre chantier. Les changements de recettes audio, présentation et sprites Gen5 sont exclus du commit C7 ; le resolver sprites est sélectionné par son seul hunk C7.

L'admission source couvre 35 nouvelles fiches espèces/formes dont Zarbi A–J, 53 attaques, sept talents, les quatre objets référencés et CS01/03/04, ainsi que 182 médias vérifiés. La recette comporte 174 documents : 156 écrits et 18 déjà identiques préservés sans réécriture. Les évolutions conditionnelles, échanges et objets sources sont conservés ; aucune évolution solo inventée. Les sept équipes préparées sont consommées par le test runtime mais leur placement appartient aux lots de contenu suivants.

Recette gelée : `7d7d8ff21ab0d68e1de7094d9f3c8261dd8db57b9be5031ed6452940577a6ea3`. Publication QA puis LIVE par six opérations canoniques, préimages et postimages relues, aucun pending. Les ajouts de catalogues utilisent `pokemon.catalog.write` avec préimage exacte et ajout sans remplacement : `pokemon.catalog.entries.add` n'est pas admis par le workshop partitionné courant. Les documents sémantiquement identiques restent protégés et sont exclus du batch qui refuse les no-op. Aucun contournement par écriture directe du jeu.

Audit/Architecture, revue SPEC du code, revue SPEC des données, QUALITY du code et du publisher, puis critique finale du hunk sprites : PASS sur leurs périmètres. Le contrôle des 24 954 fichiers existants (1 111 423 352 octets) confirme la préservation des cartes, des médias originaux, du projet et du profil d'export ; seuls 25 learnsets, quatre catalogues et l'index d'assets prévus changent parmi les fichiers préexistants. Les entrées anciennes des catalogues et la sauvegarde authentique restent intactes.

| Validation | Résultat exact |
|---|---|
| `packages/map_battle`: `dart test test/c7_required_abilities_test.dart test/tool/generate_psdk_move_flags_test.dart test/psdk_ability_registry_manifest_test.dart test/psdk_ability_effects_test.dart test/psdk_missing_ability_effects_test.dart test/psdk_accuracy_test.dart --reporter expanded` | `00:01 +281: All tests passed!`, exit 0 |
| `packages/map_battle`: `dart test --reporter expanded` | `01:13 +2186 -1: Some tests failed.` ; seul MindBlown `Studio s_recoil mind_blown crashes once after adjacent damage` échoue aussi sur HEAD isolé : 19 PASS/1 FAIL, attendu [8,8,8], observé [6,6,7] |
| `packages/map_battle`: `dart analyze` | `No issues found!`, exit 0 |
| Générateur `generate_psdk_move_flags.dart --source-directory <source Studio existante> --check` | `Verified 728 native Studio move flags`, exit 0 |
| `dart compile kernel test/c7_required_abilities_test.dart -o <QA C7>/battle-test.dill` | exit 0 ; sortie temporaire supprimée après contrôle des consommateurs |
| `packages/map_runtime`: `flutter test test/runtime_battle_combatant_seed_builder_test.dart --reporter expanded` | `00:00 +28: All tests passed!`, exit 0 |
| `packages/map_runtime`: `flutter test test/battle_pokemon_sprite_resolver_test.dart --reporter expanded` | `00:00 +15: All tests passed!`, exit 0 ; RED initial +9/-4 et RED défaut média +13/-1 avant correction |
| Test externe `c7_01_runtime_test.dart`, QA puis `C701_PROJECT=<jeu principal>` | QA `00:01 +5: All tests passed!`, LIVE `00:04 +5: All tests passed!`, exit 0 ; PP, six IV, compatibilité/refus/enseignement des CS, non-consommation, sauvegarde/relecture froide et invariants narratifs vérifiés |
| Analyse seed et test seed ; test sprites ; test externe | `No issues found!`, exit 0. Analyse resolver complet : deux diagnostics dans les ajouts Gen5 étrangers, laissés à leur propriétaire |
| Runtime `phase_a_golden_battle_slice_smoke_test.dart` | `00:00 +3: All tests passed!`, exit 0 |
| Host `phase_a_golden_slice_launch_test.dart` | `00:00 +14: All tests passed!`, exit 0 |
| Publisher `python3 -B c7_01_publication_test.py` | `Ran 8 tests`, `OK`, exit 0 |
| Authoring `dart test test/domains/gameplay/pokemon_catalog_authoring_test.dart test/domains/gameplay/pokemon_catalog_jsonl_test.dart --reporter expanded` | 14 PASS/1 FAIL : test de réparation d'évolution cherche `.pokemap/authoring/history.jsonl` absent après écriture réussie ; production Authoring inchangée par C7 |
| MCP `npm run check`, `npm run build` | exit 0 |
| MCP `node --import tsx --test --test-concurrency=1 test/pokemon_authoring.test.ts test/pokemon_document_query.test.ts` | 3 PASS/1 FAIL : ancien test attend `pokemon.ruleset.no_change`, reçoit `plan.stale` avant écriture espèce ; fichiers hors C7 |
| MCP connecté, nouveau workspace LIVE et `batch_get` ciblé | trois documents relus : Kangourex et ses trois HM, média partagé Zarbi A–J, espèce Zarbi B et sa référence `unown` |
| `git diff --check` | exit 0 |
| `bash tools/scripts/check_markdown_hygiene.sh` | exit 1 : deux Markdown ignorés étrangers préexistants, aucun nouveau Markdown C7 |

Toutes les suites passent par `executer_tests.py` : PID et descendants suivis, aucun descendant restant. Les tests externes utilisent le package config runtime absolu ; la forme relative faisait échouer un hook native-assets avant test. Le package runtime compile par ces suites ; aucun build applicatif complet ni certification GPU/iPhone déclaré. Aucune nouvelle capacité d'authoring ajoutée : contrats, UI et transports existants réutilisés ; les lectures/écritures canoniques sont prouvées, les deux limites des suites élargies restent visibles.

Inventaire moteur du commit, préfixe commun `packages/` :

- `map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart` : trois talents enregistrés ; `psdk_move_flags.dart` : éligibilité native Roche Royale.
- `map_battle/lib/src/domain/ai/psdk_battle_ai.dart` : estimation STAB et immunités ; `effect/ability/ability_effect.dart`, `ability_effect_registry.dart`, `ability_immunity_effect.dart`, `type_modifier_ability_effect.dart` : Adaptabilité, Querelleur, Matinal et immunités pertinentes.
- `map_battle/lib/src/domain/effect/status/sleep_effect.dart`, `handler/battle_status_change_handler.dart` : progression du sommeil par talent.
- `map_battle/lib/src/domain/move/battle_accuracy_resolver.dart`, `battle_move_damage_calculator.dart`, `battle_move_immunity_resolver.dart`, `battle_move_type_processor.dart`, `behaviors/ohko_move_behavior.dart`, `behaviors/type_based_move_behavior.dart` : précision OHKO, STAB, immunités des ripostes et type/puissance de Puissance Cachée.
- `map_battle/lib/src/psdk/canonical_psdk_move_projector.dart` : transport des flags natifs et Voile Miroir.
- `map_battle/test/c7_required_abilities_test.dart`, `psdk_ability_registry_manifest_test.dart`, `tool/generate_psdk_move_flags_test.dart` ; `map_battle/tool/generate_psdk_move_flags.dart` : comportement, manifest et génération.
- `map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`, `map_runtime/test/runtime_battle_combatant_seed_builder_test.dart` : transport des six IV joueur/sauvage/dresseur.
- `map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart`, `map_runtime/test/battle_pokemon_sprite_resolver_test.dart` : référence média canonique, forme propre, défaut conservé et confinement des chemins. Seul le hunk `_readMedia` entre au commit ; les ajouts Gen5 concurrents restent dans le worktree.
- Ce plan existant : état et preuves C7-01, sans modification des statuts globaux de la roadmap.

Sources et preuves du jeu hors Git moteur : `c7_01_preparer.py`, `c7_01_fixture.dart`, `c7_01_publier.py`, `c7_01_publication_test.py`, `c7_01_runtime_test.dart`, `c7_01_preserver.py`, `revisites/c7-01-admission.json` et `revisites/c7-01/`. Les logs, préimages canoniques, reçus de publication et contrôles de préservation restent techniques ; le carnet public n'en reçoit que la projection éditoriale.

Limites et autocritique : le profil combat générique conserve ses règles actuelles ; ce lot ne certifie pas une équivalence intégrale Gen4/RNG. Les évolutions à condition ou échange restent des données sources, pas des fonctions solo promises. Les 40 résolutions de sprites Zarbi ne constituent pas une revue artistique. Fargas/capture et l'Élixir restent différés à leurs lots. FG-073 garde son état historique ; FG-086/108/120/129 ne sont pas promus globalement par cette preuve locale. Prochain lot : C7-02, présentation Surf.

## C7-02 — Terminer la présentation Surf

**Point de départ :** déplacement et consentement Surf opérationnels dans le test Puits ; quatre poses natives du cavalier préparées. Le modèle natif `sea_ride` est séparé et n'est pas encore composé avec le cavalier.

**Fichiers et frontières :** `revisites_surf_preparer.py`, `revisites/assets/surf/` du chantier ; configurations de personnage par authoring ; `packages/map_runtime/lib/src/application/runtime_player_avatar.dart` et `packages/map_runtime/lib/src/spatial/spatial_field_action_presentation.dart` si un raccord runtime manque.

- [ ] Préparer la monture native et sa composition avec le cavalier sans remplacer les anciens médias ni inventer de représentation.
- [ ] Configurer les poses et transitions prises en charge : entrée dans l'eau, déplacement, arrêt et sortie ; conserver les identités et le mode de déplacement.
- [ ] Observer le rendu natif puis vérifier le parcours rive → eau → seconde rive, sauvegarde en Surf et reprise, sans perte de collision ni avatar mal positionné.

**Fermé quand :** présentation et déplacement sont cohérents dans le Player sur le parcours concerné ; les avatars pris en charge ont une couverture explicite. Ce lot ne crée pas une nouvelle mécanique Surf. Rattachements : FG-120, FG-129.

## C7-03 — Intégrer la revisite du Puits sans casser l'histoire

**Fichiers et frontières :** `jeu/maps/puits-ramoloss-sous-sol1.json`, `puits-ramoloss-sous-sol2.json`, réglages et catalogues narratifs concernés, uniquement par authoring ; outils `revisites_navigation_publier.py`, `revisites_borders_publier.py`, `revisites_surf_configurer.py`, `revisites_runtime_test.dart` à adapter au vrai préimage source.

- [ ] Calculer un delta sur les cartes source complètes : conserver les 7 PNJ, 3 objets, 8 zones, l'entrée, les 6 Events, 6 Scenes, 8 worldRules de présence, 2 Facts et leurs dépendances. Réutiliser les cinq zones Surf B1 existantes ; créer les sept zones B2 nécessaires et la liaison réciproque. Préserver les sorties vers l'entrée du Puits et la maison de Fargas.
- [ ] Appliquer la navigation justifiée par les supports, les rampes et l'échelle ; recalculer les 13 Borders depuis la source. Ne pas recopier les postimages ou la réparation initiale QA. La position source du Border `border3d_d28f00c90564428d5ca956c97288703b` doit être examinée : le défaut observé n'est pas limité à QA.
- [ ] Rejouer Force, Surf, les escaliers, l'habitant, Roche Royale unique, refus et échec d'écriture, retour et Continue ; vérifier les présences avant/après Rockets et les sorties existantes.

**Fermé quand :** parcours sur les données réellement intégrées, reprise conservée, récompense unique, reset de Force/rocher à la nouvelle instance correct, aucune régression narrative. La sauvegarde de fin de chapitre sans CS reste bloquée aux bons accès. Rattachements : FG-082, FG-083, FG-088, FG-120, FG-122, FG-129.

## C7-04 — Ajouter l'Élixir tous-PP

**Fichiers et frontières :** `packages/map_core/lib/src/models/items/project_item_effect_definition.dart`, `packages/map_core/lib/src/serialization/project_item_catalog_codec.dart`, `packages/map_core/lib/src/validation/project_item_catalog_validator.dart`, `packages/map_core/lib/src/read_models/item_capability_truth.dart` ; `packages/map_gameplay/lib/src/player_item_effects.dart` et `items/player_item_use_service.dart` ; `packages/map_authoring/lib/src/domains/gameplay/item_catalog_actions.dart` ; consommateurs runtime/menus de PP et tests correspondants. Les fichiers générés sont régénérés dans le seul package touché.

- [ ] Ajouter une portée explicite attaque choisie/toutes les attaques avec comportement et encodage legacy inchangés pour la portée par défaut ; garder cohérents codec strict, validation, capability et export/Player. Un Player qui ne connaît pas la capability tous-PP refuse clairement le nouveau jeu, sans toucher aux données, plutôt que d'appliquer une portée erronée ; les anciens jeux restent pris en charge.
- [ ] Appliquer à tous les emplacements valides en une opération, plafonner chaque PP, consommer une seule unité si l'effet s'applique ; refuser sans consommation si aucun effet n'est possible. L'Élixir HGSS utilise +10 PP pour chaque attaque, configuré par les données.
- [ ] Raccorder les sélecteurs de cible et l'authoring guidé. Respecter le support réel par contexte : aucun usage en combat affiché comme disponible sans exécution et write-back prouvés.
- [ ] Vérifier ancien Éther, Élixir partiel/complet, emplacements absents, annulation, sauvegarde/Continue et échec de persistance ; prouver la parité API/CLI/MCP et les coûts locaux du contrôle ajouté.

**Fermé quand :** l'objet HGSS utilise un effet générique réellement consommé par les contextes annoncés, avec une consommation exacte et compatibilité des anciens objets. Rattachements : FG-050, FG-060, FG-062.

## C7-05 — Terminer le nord du premier sous-sol des Caves

**Fichiers et frontières :** `jeu/maps/caves-jumelles-sous-sol1.json`, ses dresseurs/objets/rencontres et raccords RDC ; `revisites_preparer.py`, `revisites_pack.dart`, `objets-caves.json`, `revisites_runtime_test.dart` du chantier.

- [ ] Confronter la branche nord, les accès et chaque dresseur/objet à l'inventaire sourcé ; conserver la branche sud déjà parcourue.
- [ ] Intégrer les seuls éléments manquants, passages et conditions Surf/Force ; conserver Terrain, Paths et Borders natifs.
- [ ] Parcourir les accès autorisés, mener les combats nécessaires, ramasser les objets, sauvegarder/reprendre et revenir au RDC ; tester les accès refusés et la non-duplication.

**Fermé quand :** inventaire de la branche couvert par des preuves intégrées, retour praticable et branche sud intacte. Rattachements : FG-083, FG-086, FG-108, FG-120, FG-122.

## C7-06 — Terminer le second sous-sol des Caves hors Lokhlass

**Fichiers et frontières :** `jeu/maps/caves-jumelles-sous-sol2.json`, liens B1/B2, équipes, objets et tables d'eau ; outils de revisites du chantier.

- [ ] Intégrer accès, dresseurs, objets et rencontres ordinaires manquants selon l'inventaire ; réserver l'emplacement/condition de Lokhlass sans activer une rencontre fictive.
- [ ] Vérifier reliefs, berges, escaliers et retour depuis chaque branche avec les systèmes natifs existants.
- [ ] Jouer les branches, combats et collectes, puis Continue et retour ; contrôler accès verrouillés, objets uniques et absence de blocage après reprise.

**Fermé quand :** le sous-sol est complet et parcourable pour son contenu ordinaire ; seule la rencontre périodique dépend encore des lots C7-07/C7-08. Rattachements : FG-083, FG-086, FG-101, FG-108, FG-120, FG-122.

## C7-07 — Compléter les rencontres périodiques durables

**Fichiers et frontières :** conditions et disponibilité dans `map_core` ; `packages/map_gameplay/lib/src/periodic_reward_checkpoint.dart`, `periodic_reward_operations.dart` et évaluateur de conditions existant ; `packages/map_runtime/lib/src/spatial/spatial_battle_runtime.dart` et services de session ; authoring des conditions et capability dans `map_authoring`/`map_distribution`. Coordination obligatoire avec le propriétaire Pokémon/combat.

- [ ] Ajouter la condition typée de jour civil en réutilisant le calendrier existant, sans dépendre de l'heure visuelle ni d'un délai artificiel de 24 h.
- [ ] Définir la consommation périodique d'une rencontre non-item : victoire, capture et fuite consomment ; défaite ne consomme pas. Rendre cette politique explicite et configurable au bon niveau.
- [ ] Persister atomiquement le résultat complet du combat et le claim : capture/Party/PC, XP, état et calendrier. Le checkpoint de récompense limité au sac ne peut pas remplacer cette transaction. Ne confirmer la fin qu'après succès durable ; préserver les combats historiques et leur cadence de sauvegarde.
- [ ] Vérifier vendredi/autres jours, changement de semaine, répétition, Continue, panne d'écriture et reprise sans double capture ni perte de progression ; prouver API/CLI/MCP, export et compatibilité.

**Deux sous-lots fermables :** C7-07A ferme le prédicat civil typé et sa configuration ; C7-07B ferme la consommation périodique avec le checkpoint complet de combat, ses issues et ses erreurs. Le premier ne vaut pas livraison du second. Les cas d'interruption et de changement de jour pendant le combat ont une politique explicite, confrontée à la référence source avant activation.

**Fermé quand :** une rencontre périodique générique fonctionne de bout en bout sans règle Lokhlass codée dans le moteur. Rattachements : FG-087, FG-101, FG-102, FG-107, FG-108.

## C7-08 — Intégrer Lokhlass, le calendrier et les contacts restants

**Fichiers et frontières :** contenu des Caves et Scenes/Events/worldRules/contacts réellement référencés dans le jeu ; `contenu.json`, `histoire_test.dart`, `preparer_histoire.py` et préparations de revisites du chantier.

- [ ] Fermer un inventaire fini des événements calendaires et contacts du périmètre Route 32/Caves/Route 33/Écorcia/Puits/Alpha, avec témoin source et état déjà présent/manquant pour chaque entrée.
- [ ] Configurer Lokhlass vendredi avec l'espèce, le niveau, la position et la politique C7-07 sourcés ; compléter uniquement les autres événements/contacts manquants de cet inventaire.
- [ ] Jouer présence/absence selon le jour, dialogue, combat, consommation et semaine suivante ; vérifier sauvegarde/Continue et contacts sans doublon. Les changements de date utilisés dans les tests sont déclarés.

**Fermé quand :** chaque entrée de l'inventaire a une preuve ou une exclusion explicite, sans rubrique vague « autres événements » encore ouverte. Rattachements : FG-082, FG-088, FG-087, FG-101, FG-102, FG-107, FG-108.

## C7-09 — Compléter l'usage contextuel des objets et la Corde Sortie 3D

**Point de départ :** la Corde Sortie existe en 2D ; `escape_rope_action.dart` refuse explicitement les cartes spatiales. L'effet d'action sémantique existe déjà : examiner ses consommateurs avant d'ajouter une autre commande.

**Fichiers et frontières :** `packages/map_gameplay/lib/src/escape_rope_action.dart`, `packages/map_gameplay/lib/src/items/player_item_use_service.dart`, `packages/map_runtime/lib/src/presentation/flame/playable_map_game_escape_rope.dart` et leur équivalent spatial existant ; métadonnées canoniques et `apps/avelune_studio/lib/presentation/features/map_workspace/map_escape_rope_settings.dart` si nécessaire ; tests `escape_rope_action_test.dart`, `playable_map_game_escape_rope_test.dart`, `map_metadata_escape_rope_test.dart`.

- [ ] Définir un retour spatial sûr : destination, hauteur et arrivée navigable, conservation après Continue ; refus propre sur carte interdite, cible absente ou arrivée bloquée.
- [ ] Raccorder l'usage contextuel avant l'effet normal et sa consommation, avec annulation, priorité et absence de correspondance explicites ; refuser une ambiguïté plutôt que choisir silencieusement une interception. Conserver les usages 2D existants.
- [ ] Vérifier le cas Alpha, salle 312, position `(6,3)`, face nord : déclencher le secret sans téléportation ordinaire ni consommation indue, puis tester l'usage normal ailleurs et l'échec de sauvegarde.

**Fermé quand :** comportement spatial et interception sont prouvés dans le runtime et configurables sans branche HGSS dans le moteur. Rattachements : FG-060, FG-062, FG-080, FG-082 ; compléter le rattachement de la capacité spatiale dans le contexte produit existant à l'exécution, sans inventer un ID FG.

## C7-10 — Raccorder les cartes d'Alpha

**Fichiers et frontières :** cartes actuelles `ruines-alpha`, `passage-route32-ruines-alpha`, salles 113/315/323 et connexions existantes selon leurs vrais IDs ; outils `alpha_fin_preparer.py`, `alpha_fin_qualifier.py`, `alpha_fin_fixture.dart`, `alpha_fin_gameplay_test.dart` du chantier.

- [ ] Repartir de la carte principale actuelle 32×64 et de ses warps ; réconcilier les IDs/raccords avec le propriétaire Alpha. Ne pas rejouer les anciennes recettes de création 35×67.
- [ ] Raccorder le passage Route 32, l'extérieur et les salles nécessaires au parcours convenu, y compris la salle de récompenses 324 ; conserver les sorties futures et leurs restrictions, les objets complets et les supports fractionnaires natifs. Les warps 323-2/3 concernent Sinjoh et restent fermés ; ils ne sont pas l'accès aux récompenses Kabuto.
- [ ] Parcourir aller/retour, escaliers, seuils et fosse réellement utilisés, puis sauvegarde/Continue. Requalifier les avertissements Border existants : corriger les défauts confirmés ou conserver leur diagnostic explicite, sans annoncer un contrôle formel PASS s'il reste FAIL.

**Fermé quand :** le circuit spatial convenu est connecté dans le jeu principal et praticable, sans régression des cartes source ni confusion entre rendu candidat et jeu intégré.

## C7-11 — Intégrer Kabuto, son secret et les récompenses

**Fichiers et frontières :** `puzzles-alpha.json`, `preparer_puzzles_alpha.py`, `puzzles_alpha_test.dart`, `alpha_fin_test.py` et tests de parcours du chantier ; définitions de puzzle/Scenes et cartes concernées via authoring. Réutiliser `runtime_image_puzzle_service.dart` et l'overlay existant.

- [ ] Intégrer le puzzle Kabuto avec les pièces/orientations sourcées, les branches résoudre/quitter et la reprise persistée ; ne pas activer les quatre puzzles uniquement parce que leurs médias sont préparés.
- [ ] Distinguer résolution du puzzle, ouverture du mur par Corde Sortie, quatre récompenses et les deux chutes. La salle 324 porte les quatre objets (scripts 7013–7016, flags 1128–1131) : lien natif 312 warp 1 `(6,2)` ↔ 324 warp 0 `(6,17)`, puis séquence de chute de 324 vers 313 à `(11,7)`. La salle 313 n'est pas la salle contenant les quatre objets. Confronter cette topologie à la recette historique qui nommait directement 313 comme secret. Garder distincts les flags du secret `0x21B`, du puzzle `0x977` et de la chute `0x111`, ainsi que la chute du puzzle vers 315.
- [ ] Raccorder les rencontres Zarbi à la résolution effective ; aucune rencontre avant résolution et aucune ouverture des trois autres puzzles par commodité.
- [ ] Tester puzzle incomplet, mauvaise orientation, résolution, abandon/reprise, secret avant consommation, sac plein, collecte unique et Continue. Respecter les restrictions des chambres futures.

**Fermé quand :** accès → puzzle → chute/secret → récompense → sortie fonctionne sur les vraies cartes ; aucune récompense ou rencontre n'est ouverte prématurément. Rattachements : FG-082, FG-083, FG-088, FG-101, FG-108.

## C7-12 — Valider le chapitre intégré et ses présentations

**Fichiers et frontières :** harnais maintenus du chantier, vrais projets/fixtures déclarés, preuves existantes dans `suivi/preuves/chapitre7-*.json` ; pas de nouvelle campagne de redesign Studio.

- [ ] Rejouer le trajet principal et les annexes accessibles depuis une sauvegarde authentique, sans injection de progression. Séparer les revisites futures sur fixture explicitement préparée et vérifier leur refus dans la sauvegarde du chapitre 7.
- [ ] Observer les huit arbres plein/vide, secousse et réapparition quotidienne ; vérifier la présentation des PNJ des deux sous-sols des Centres, Surf, puzzle, récompenses et transitions. Réutiliser les preuves acquises ; refaire les parcours affectés par les nouvelles intégrations.
- [ ] Vérifier sauvegarde, Continue, sac plein, répétition et panne d'écriture aux frontières touchées. Examiner le rendu natif, l'audio et les plateformes disponibles en séparant chaque niveau de preuve ; une preuve macOS ne vaut pas iPhone.
- [ ] Lister précisément les écarts conservés, dont animations d'araignées/escalator non reproduites et Fargas différé. Déclarer les critères non vérifiés sur appareil sans les transformer en acquis.

**Fermé quand :** les critères des lots précédents sont couverts sur l'intégration réelle et les écarts restants sont explicitement présentés à la revue. Aucune certification de l'ensemble de Studio n'est annoncée. Rattachements : FG-014, FG-082, FG-093, FG-180, FG-182 selon les parcours.

## C7-13 — Livrer et vérifier la mise à jour

**Fichiers et frontières :** export final `.avelunegame`, copie Bureau et Release `yoahnl/heartgold-avelune-demo`, carnet `suivi/data/` et reçus existants. Ne choisir la version suivante qu'après contrôle des versions déjà utilisées.

- [ ] Vérifier le jeu et les capabilities, conserver `gameId`, `compatibilityId` et les formats protégés ; identifier exactement les changements moteur à livrer, sans embarquer le travail concurrent.
- [ ] Pour les opérations Git, relire l'autorisation explicite de livraison antérieure et sa portée ; si elle ne couvre pas l'opération envisagée, ne pas la déduire du présent plan. Avec autorisation applicable, vérifications ciblées puis commit/push strictement limité aux fichiers du lot.
- [ ] Produire un export unique, vérifier installation/mise à jour et Continue depuis 0.1.11 avec sauvegarde préservée ; tester aussi des fixtures de jeux/sauvegardes protégés représentatives de la baseline 0.3.31 et ultérieures, ainsi que l'échec/futur format sans modification des originaux. Une seule mise à jour actuelle ne certifie pas tout l'historique.
- [ ] Publier exactement les mêmes octets Bureau/Release et vérifier leurs SHA-256 ; actualiser carnet et Notion sans déclarer les annexes différées terminées.
- [ ] Arrêter les seuls processus QA possédés, conserver les preuves utiles, supprimer les environnements et exports temporaires du lot après contrôle des consommateurs ; mesurer et signaler toute rétention justifiée.

**Fermé quand :** livrable accessible, SHA identiques, mise à jour et sauvegardes vérifiées dans le périmètre annoncé, carnet fidèle, QA nettoyée, implémentations prêtes pour revue. L'acceptation finale `DONE` reste à Yoahn.

## C7-D1 — Fargas et les Balls, différé à la refonte Pokémon/combat

Le moteur de fabrication différée existe. Préserver ses recettes préparées et ses tests sans le réécrire ni activer de récompenses factices.

- [ ] Après stabilisation de la refonte, admettre les sept Balls et leurs effets génériques validés, dont la Masse Ball, sans patch dans l'ancien pipeline.
- [ ] Brancher dépôt/quantité, disponibilité au prochain jour civil et retrait unique chez Fargas ; vérifier ingrédients, sac plein, refus, Continue et erreurs de persistance.
- [ ] Vérifier les Balls dans le vrai flux de capture et les sauvegardes protégées, puis activer le service.

**Fermé quand :** le service réel de Fargas produit des Balls utilisables avec les effets attendus et sans duplication. Ce différé accepté reste visible dans le carnet : finir le périmètre livrable actuel ne signifie pas 100 % des dix objectifs originaux si Fargas en reste exclu.

## Vérifications d'exécution

Ces commandes sont à exécuter lors des lots concernés, pas présentées comme déjà passées par la planification. Les chemins de tests supplémentaires seront fixés avant chaque implémentation après audit de son préimage.

| Frontière touchée | Commandes depuis le package concerné |
|---|---|
| Core | `dart test` puis `dart analyze` ; génération locale seulement si modèle généré changé |
| Gameplay | `dart test test/escape_rope_action_test.dart`, tests d'objets/calendrier du lot, puis `dart analyze` |
| Battle | `dart test` puis `dart analyze` si ce package est modifié ; pas de modifications de capture différée |
| Runtime | Tests ciblés du lot ; `flutter test test/phase_a_golden_battle_slice_smoke_test.dart` pour une frontière combat ; `flutter analyze` ciblé puis élargi selon le risque |
| Authoring | Tests du domaine et transport ; `dart run tool/pmcp085_conformance.dart` ; `dart test test/parity/full_authoring_parity_test.dart` ; `dart analyze` |
| MCP | Dans `tools/pokemap_mcp` : `npm run check`, tests ciblés puis conformance applicable, `npm run build`, rechargement et contrôle réel de `pokemap_describe` |
| Studio | Tests ciblés des contrôles touchés, build natif approprié et trajet réel UI → persistance avec mesures première/répétitions |
| Parcours jeu | Harnais maintenus du chantier via `executer_tests.py`, préimages/receipts et fixture explicitement documentés ; un ancien résultat ne qualifie pas une nouvelle admission |
| Host golden slice | Dans `examples/playable_runtime_host` : `flutter test test/phase_a_golden_slice_launch_test.dart` si intégration Player/combat touchée |
| Documentation | `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` pour l'unique plan demandé |

Pour chaque lancement Flutter, relever PID et descendants pendant le run, puis vérifier et arrêter seulement les restants de ce run. Réutiliser la QA existante ou le même enfant possédé ; aucune copie complète du workspace et aucun soak CI ajouté.

## Risques, revue et état de cette planification

Risques principaux : frontières Pokémon/combat concurrentes ; confusion QA/source ; états résumés périmés ; acquisition des CS plus tard dans l'histoire ; conservation des sauvegardes ; coût réel des nouveaux contrôles Studio ; acceptation graphique et appareil distinctes.

L'audit indépendant Architecture confirme le découpage après précision des dépendances, de la progression future et de la topologie Alpha. La critique indépendante ne trouve aucun bloqueur structurel ; ses précisions sur la fermeture transitive et la compatibilité de l'Élixir sont intégrées. Implémentation, tests de code et build : non applicables à cette demande de planification, donc aucun verdict d'exécution. Les autres lots restent à réaliser selon leurs preuves actuelles ; le tableau n'est pas une déclaration de livraison.

Modifications de cette demande : ce plan et une exception `.gitignore` limitée à son chemin, pour que le livrable ne soit pas un document ignoré. Aucun code moteur ni donnée du jeu modifiés. La roadmap n'est pas modifiée.

Le contrôle Markdown initial échoue déjà sur deux documents ignorés préexistants : `documentation/reports/avelune_player/plans/2026-10-31-avelune-ios-install-library-launch-perf.md` et `documentation/reports/heartgold/audit-cartes-johto-2026-10-31.md`. Ils appartiennent à d'autres travaux et ne doivent être ni supprimés ni admis globalement pour rendre ce contrôle vert.

Vérification documentaire : structure des 13 lots et du différé contrôlée ; `git diff --check` sort 0. Le contrôle d'hygiène avec budget 1 sort 1 : mêmes deux documents ignorés, total 3 nouveaux Markdown pour 1 autorisé, dont un seul créé par cette demande. État Git après plan : 136 chemins, soit les 134 préexistants plus `.gitignore` et ce plan ; aucun autre delta de statut observé. Aucun environnement QA créé et aucune opération Git d'écriture effectuée. Le plan et les limites sont rattachés au ticket Notion existant, qui reste DOING pour son implémentation encore ouverte.
