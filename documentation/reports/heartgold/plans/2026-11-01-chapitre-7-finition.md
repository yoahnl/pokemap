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
- Notion : aucun suivi obligatoire depuis le 2026-11-08. Sur demande de Yoahn seulement, rattacher les preuves au contexte existant du domaine concerné, sans créer de tickets de cartes ou de bugs isolés. Le contexte de cette planification est le ticket existant du domaine Monde & narration `403197a7bfa581698d45e152e7d0106a`. Les lots techniques gardent leurs contextes produit existants quand ils en ont un. Une implémentation vérifiée est proposée `TO REVIEW` ; `DONE` appartient à Yoahn.
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

**Fichiers et frontières :** `c7_02_preparer.py`, `c7_02_publier.py` et `revisites/c7-02/` du chantier privé ; clips et médias par authoring canonique. Contrat de canvas dans Core, édition ciblée dans Authoring/Editor, consommateurs 2D/3D dans Runtime et capability dans Distribution. Les mécanismes Surf existants sont réutilisés ; aucune règle HGSS n'entre dans le moteur.

- [x] Préparer la monture native et sa composition avec le cavalier sans remplacer les anciens médias ni inventer de représentation.
- [x] Configurer les poses et transitions prises en charge : entrée dans l'eau, déplacement, arrêt et sortie ; conserver les identités et le mode de déplacement.
- [x] Observer le rendu natif puis vérifier le parcours rive → eau → seconde rive, sauvegarde en Surf et reprise, sans perte de collision ni avatar mal positionné.

**Fermé quand :** présentation et déplacement sont cohérents dans le Player sur le parcours concerné ; les avatars pris en charge ont une couverture explicite. Ce lot ne crée pas une nouvelle mécanique Surf. Rattachements : FG-120, FG-129.

### Exécution du 2 novembre 2026 — C7-02 implémenté et proposé TO REVIEW

Audit initial : les consentements, transitions, verrous, déplacements et la restauration Surf existaient déjà. `spatial_field_action_presentation.dart` appartient aux autres actions de terrain et n'a pas été modifié. Deux défauts de présentation restaient : animation au repos figée sur l'horloge du déplacement, et impossibilité de conserver l'échelle du cavalier dans un cadre contenant la monture complète. La matrice Studio n'exposait pas les quatre états Surf ; ses clés camelCase ne correspondaient pas aux états snake_case canoniques.

État Git initial : branche `main`, HEAD `dba2ecad46add1cb4facec631c616f90a1cdb72d`, index vide, 56 chemins étrangers modifiés/non suivis. Les chantiers concurrents ont ensuite avancé `main` ; le HEAD observé avant le gel est `29de4bedb`. Les changements étrangers `packages/map_editor/pubspec.lock` et `packages/map_authoring/test/domains/gameplay/avelune_gen5_move_source_test.dart` sont exclus du commit. La livraison C7-02 sélectionne uniquement les 43 fichiers moteur/tests ci-dessous et ce plan ; aucun push moteur.

Décision : `presentationReferenceHeightPx` est facultatif et omis des anciens JSON. Une valeur explicite conserve la densité des pixels, centre horizontalement le canvas et l'ancre par le bas. Le contrat accepte un entier 1..8192, une source dédiée et une référence ne dépassant aucune frame. API : absence = conserver, `null` = effacer, entier = définir. Capability conditionnelle `character.animation-canvas@1`. Les packages sans ce champ conservent leur contrat et leur géométrie historiques. Le contrôle Studio livré concerne les slots système ; l'édition des slots personnalisés dans les catalogues partitionnés reste hors de ce lot.

La monture entière `sea_ride` est issue du membre natif `a/1/0/3:86`, 48 triangles, sans recentrage, autofit ou redimensionnement du cavalier. Les quatre textures des deux avatars sont composées à échelle constante avec le bob natif. Le canvas final 32×48 retire huit lignes transparentes d'un raster 32×56 ; aucun pixel opaque n'est perdu. Les 24 phases totalisent 400 ms, dérivés de 60 mises à jour/s nominales, sans prétendre à une mesure matérielle DS. Entrée et sortie utilisent les transitions existantes et le cycle de pose préparé, sans nouvelle mécanique de saut.

Le premier candidat conservait à tort le baseline historique comme origine de présentation : l'eau coupait la monture. Cette observation native est conservée comme échec ; l'ancrage inférieur a été corrigé puis les deux avatars requalifiés. Recette finale gelée : `78849495eda4abb628a705c8fab647eef4aa4f3e91a0696ff52f9445072809e2` dans `revisites/c7-02/preparation-contact.json`.

**Intégration :** 33 opérations canoniques QA, puis 34 opérations LIVE : deux atlas, 32 slots, et configuration Surf auparavant absente exigeant progression et attaque connue, vitesse 4. Préimages et postimages vérifiées, relecture indépendante exacte et reprise du publisher avec `additionalApply: 0`. Les deux atlas utilisent de nouvelles identités et de nouveaux chemins. Les 178 165 fichiers stables préexistants, soit 2 640 857 492 octets, sont contrôlés ; seuls `catalog/HEAD.json` et `assets/.pokemap-assets.json` préexistants changent. Les 12 122 anciens records d'assets et les métadonnées du catalogue sont préservés. Cartes et sauvegarde authentique intactes ; le checkpoint conserve ses trois Pokémon et refuse toujours Surf. Le publisher gèle la recette, les 32 intentions et les hashes des sources observées, exige QA et preuve native avant LIVE et refuse une reprise incertaine.

**Preuve native :** macOS Metal Release, runtime `SpatialExplorationGameSessionRuntime` et vue `SpatialExplorationView` de production dans un hôte isolé. Pour chacun des deux avatars : consentement, entrée, quatre directions avec captures pendant déplacement, animation au repos sans déplacement, traversée rive/eau/seconde rive, checkpoint Surf, arrêt du processus, Continue à froid et sortie restaurant le cadre à pied. La fixture ajoute uniquement un Ramoloss issu de la recette source et l'autorisation Surf pour ce parcours ; les identités initiales, objets et faits sont conservés. Elle ne prouve pas l'acquisition narrative future. Le refus du consentement est aussi contrôlé. Le shell Hub, les overlays Player complets et l'appareil mobile ne sont pas certifiés par cet hôte.

**Localité Studio :** le gateway précédent invalidait et ouvrait un snapshot global avant/après chaque clip. Les upserts système passent désormais par le workshop canonique du personnage, préimage et CAS conservés, puis fusion du seul personnage dans le brouillon. Une session globale retenue est rafraîchie seulement à sa prochaine commande globale. Les projets plats préservent leurs données brutes et ne projettent que les définitions portrait/custom référencées. Les tests comptent les lectures avec 0/80 cartes et personnages étrangers, 12 mutations historiques et des données étrangères non décodables. Aucune carte ni définition étrangère n'est lue.

Mesure réelle du contrôle DS rendu et de ses callbacks vers le vrai use case/gateway, application macOS Release AOT, Apple M1 Pro arm64, macOS 27.2, Flutter 3.47.5/Dart 3.13.4. Deux avatars HGSS complets : 30 slots et 428 frames chacun, slot édité de 24 frames, PNG réel 768×192 ; 80 cartes/personnages et 12 mutations historiques étrangers ajoutés. L'ouverture initiale, séparée, vaut 335,369 ms. Le driver déclenche les callbacks des contrôles rendus, sans dispatch physique clavier/souris ; le retour visible correspond au premier frame Saving/contrôles désactivés. Cette preuve ne certifie pas l'ensemble du Studio.

| Opération | Premier retour rendu | Persistance acquittée | Lectures |
| --- | ---: | ---: | ---: |
| Premier SET après ouverture | 12,362 ms | 339,087 ms | 100 |
| Boucle seule, référence préservée | 26,049 ms | 353,632 ms | 100 |
| CLEAR | 11,944 ms | 348,715 ms | 100 |
| SET répété | 9,975 ms | 371,965 ms | 100 |

Réouverture indépendante des personnages et cartes : PASS. Neuf fingerprints de sources compilées concordants. Les 1 025 fichiers/22 977 807 octets du gate QA d'origine sont strictement identiques avant/après ; les mutations de mesure n'ont touché qu'une copie possédée. Les cibles 100/500 ms passent sur ce projet documenté, sans utiliser la dérogation arbres.

### Inventaire moteur C7-02

Chaque chemin ci-dessous appartient au lot ; le diff Git est l'inventaire précis des zones modifiées. Les outils, médias, reçus et sauvegardes HeartGold restent hors du dépôt moteur.

| Fichier | Zone et effet |
| --- | --- |
| `packages/map_core/lib/map_core.dart` | Export du contrat de capability |
| `packages/map_core/lib/src/models/project_manifest.dart` | Champs facultatifs et validation des clips |
| `packages/map_core/lib/src/models/project_manifest.freezed.dart` | Génération limitée aux deux modèles modifiés |
| `packages/map_core/lib/src/models/project_manifest.g.dart` | Codecs des deux champs facultatifs |
| `packages/map_core/lib/src/read_models/character_animation_canvas_capabilities.dart` | Détection conditionnelle du besoin runtime |
| `packages/map_core/lib/src/validation/validators.dart` | Validation contextuelle des références |
| `packages/map_core/test/character_animation_canvas_test.dart` | Bornes, codecs et absence du champ historique |
| `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart` | Opt-in workshop système sur projet plat |
| `packages/map_authoring/lib/src/workspace/native_workshop_snapshot.dart` | Dépendances ciblées, portraits/custom référencés |
| `packages/map_authoring/lib/src/domains/gameplay/character_studio/character_studio_action_support.dart` | Projection fournie et catalogue brut préservé |
| `packages/map_authoring/lib/src/domains/gameplay/character_studio/character_studio_animation_clip_actions.dart` | Définir/conserver/effacer et contrat découvrable |
| `packages/map_authoring/lib/src/registry/resource_kind_registry.dart` | Métadonnées sémantiques du canvas |
| `packages/map_authoring/lib/src/domains/distribution/game_package_export_service.dart` | Capability d'export dérivée du contenu |
| `packages/map_authoring/test/domains/gameplay/character_studio_animation_clip_actions_test.dart` | Validation et non-régressions de mutation |
| `packages/map_authoring/test/parity/character_studio_full_parity_test.dart` | Transport JSONL du champ |
| `packages/map_authoring/test/domains/distribution/character_animation_canvas_export_test.dart` | Export conditionnel et octets source inchangés |
| `packages/map_distribution/lib/src/avelune_runtime_compatibility.dart` | Capacité du host actuel |
| `packages/map_distribution/lib/src/game_package_project_validator.dart` | Refus des packages sans déclaration nécessaire |
| `packages/map_distribution/test/character_animation_canvas_package_test.dart` | Packages plats/portables et historiques |
| `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` | Session locale et révision retenue |
| `packages/map_editor/lib/src/application/authoring_api/character_studio_authoring_gateway.dart` | Route système ciblée et fusion du brouillon |
| `packages/map_editor/lib/src/features/character_studio/application/character_animation_clip_use_cases.dart` | Transmission du champ sans effacement implicite |
| `packages/map_editor/lib/src/features/character_studio/application/character_animation_matrix_model.dart` | Quatre états Surf et clés canoniques |
| `packages/map_editor/lib/src/features/character_studio/application/character_animation_source_import_service.dart` | Préservation du découpage lors du remplacement |
| `packages/map_editor/lib/src/features/character_studio/presentation/animations/character_animation_source_editor.dart` | Contrôle DS système, erreurs et retour automatique |
| `packages/map_editor/lib/src/features/character_studio/presentation/animations/character_studio_animations_tab.dart` | Guidage de référence et callbacks |
| `packages/map_editor/lib/src/features/character_studio/presentation/character_studio_workspace.dart` | Raccord à la sauvegarde canonique |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | Valeur persistée et état de sauvegarde |
| `packages/map_editor/test/authoring_api/character_studio_local_clip_test.dart` | Comptages, préimages, projet plat et dépendances |
| `packages/map_editor/test/features/character_studio/character_animation_frame_timeline_test.dart` | Préservation de la référence sur édition de frames |
| `packages/map_editor/test/features/character_studio/character_animation_matrix_model_test.dart` | Couverture Surf et états transportés |
| `packages/map_editor/test/features/character_studio/character_animation_matrix_widget_test.dart` | Accessibilité de la matrice étendue |
| `packages/map_editor/test/features/character_studio/character_animation_source_slicing_test.dart` | Champ, validation, échec durable et périmètre système |
| `packages/map_editor/test/features/character_studio/character_studio_authoring_adapter_test.dart` | Persistance, conservation et effacement relus |
| `packages/map_runtime/lib/src/application/character_animation_source_resolver.dart` | Échelle et rectangle ancré en bas, défaut historique intact |
| `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart` | Rectangle consommé pour les clips 2D |
| `packages/map_runtime/lib/src/spatial/spatial_exploration_session.dart` | Géométrie 3D et horloge Surf indépendante |
| `packages/map_runtime/lib/src/session/playable_map_game_session_runtime.dart` | Gate capability sur bundle matérialisé |
| `packages/map_runtime/lib/src/session/spatial_exploration_game_session_runtime.dart` | Gate capability sur bundle 3D |
| `packages/map_runtime/test/character_animation_source_resolver_test.dart` | Densité des pixels et ancrage, héritage préservé |
| `packages/map_runtime/test/spatial_surf_water_test.dart` | Repos, phase, verrous, transitions et origine de mouvement |
| `packages/map_runtime/test/session/character_animation_canvas_capability_test.dart` | Catalogue partitionné 2D sans préchargement |
| `tools/pokemap_mcp/test/character_animation_canvas_stdio.test.ts` | MCP réel, valeurs invalides et relecture froide |

### Commandes et résultats C7-02

Les tests ont été lancés depuis chaque package via le wrapper privé `executer_tests.py`, avec TMPDIR dans le seul enfant QA du lot. Chaque runner et ses descendants sont suivis ; tous les reçus finaux indiquent `remaining=[]`. Les journaux exacts sont sous `revisites/c7-02/`.

| Commande | Résultat exact |
| --- | --- |
| Core `dart test test/character_animation_canvas_test.dart --reporter expanded` | `00:00 +25: All tests passed!` |
| Authoring `dart test test/domains/gameplay/character_studio_animation_clip_actions_test.dart test/parity/character_studio_full_parity_test.dart --reporter expanded` | 56 PASS après correction de projection |
| Authoring `dart test test/domains/distribution/character_animation_canvas_export_test.dart --reporter expanded` | `00:00 +2: All tests passed!` ; export de fixture seulement |
| Editor `flutter test --no-pub test/features/character_studio/character_animation_frame_timeline_test.dart test/features/character_studio/character_animation_matrix_model_test.dart test/features/character_studio/character_animation_matrix_widget_test.dart test/features/character_studio/character_animation_source_slicing_test.dart test/features/character_studio/character_studio_authoring_adapter_test.dart test/authoring_api/character_studio_local_clip_test.dart --reporter expanded` | `00:24 +36: All tests passed!` |
| Runtime `flutter test --no-pub test/spatial_surf_water_test.dart test/character_animation_source_resolver_test.dart test/surf_character_2d_test.dart test/overworld_actor_custom_animation_test.dart test/session/character_animation_canvas_capability_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded` | `00:03 +37: All tests passed!` |
| Distribution `dart test test/character_animation_canvas_package_test.dart test/avelune_runtime_compatibility_test.dart test/avelune_compatibility_baseline_package_test.dart --reporter expanded` | `00:00 +18: All tests passed!`, dont exports gelés de la baseline |
| Host `flutter test --no-pub test/phase_a_golden_slice_launch_test.dart --reporter expanded` | `00:00 +14: All tests passed!` |
| MCP `npm run check` et `npm run build` | exit 0 |
| MCP `node --import tsx --test --test-concurrency=1 test/character_animation_canvas_stdio.test.ts` | 1 PASS, 0 FAIL ; clips système/custom, nouveaux processus stdio |
| Authoring `dart test test/parity/full_authoring_parity_test.dart` | 28 PASS |
| Publisher `python3 -B c7_02_publication_test.py` via wrapper | 8 PASS ; 14 mutations de scope et reprises invalides couvertes |
| Préparateur `PYTHONPATH=<QA>/python-deps python3.14 -B c7_02_preparer.py --check` | deux avatars, 32 clips, 32×48, cycle 400 ms, sources vérifiées |
| Publisher `python3 -B c7_02_publier.py --live` et répétition | 34 actions durables, relecture/préservation vérifiées ; `additionalApply: 0` |
| `dart --packages=packages/map_runtime/.dart_tool/package_config.json c7_02_verifier_live.dart` | `LIVE_PRESENTATION_READBACK_PASS`, 32 slots, deux atlas, checkpoint authentique refusé |
| `flutter build macos --release` dans chacun des deux hosts isolés | exit 0 ; `FLTEnableFlutterGPU=true` dans le host natif, Metal et AOT authoring réellement exécutés |
| Analyses ciblées Core, Authoring, Editor, Runtime et Distribution | Aucune erreur ni warning ; infos préexistantes conservées, détail dans les logs ; Distribution sans problème |
| `git diff --check` | exit 0 |
| `bash tools/scripts/check_markdown_hygiene.sh` | exit 1 sur les deux Markdown ignorés étrangers préexistants ; aucun nouveau Markdown C7-02 |

Le MCP connecté expose effectivement le champ dans l'action et la ressource `characterStudioCharacter` ; reçu `mcp-live-catalog.json`. Aucun serveur récent interrompu. Les cinq contrôles de sécurité ciblés passent. Limites élargies conservées : conformance MCP générale avec deux échecs d'outillage (liste des outils et golden receipt map.create) ; PMCP085 découvre 104 ressources/471 actions sans case manquante mais ne certifie pas tous les transports ; suite runtime session élargie 146 PASS/6 FAIL sur le nombre d'appels à l'horloge des rencontres, origine non tranchée par ce lot. Aucune annonce de suite globalement verte.

Revues : Audit/Architecture PASS pour la réutilisation de Surf ; SPEC Core/Authoring et composition native PASS ; Tests/Build PASS sur les gates ciblés ; critique finale QUALITY PASS après deux P2 réellement reproduits puis corrigés (dépendances portrait/custom du projet plat, gate 2D évalué trop tôt). Le parent a relu la dernière correction 2D et ses trois cas partitionnés avant sélection Git.

Autocritique et frontières : composition fixe 2,5D pour la caméra native, pas une monture GLB orientable librement ; durée dérivée et transitions existantes explicitement conservées. Le parcours QA ne certifie ni le Puits source complet avec ses vrais PNJ/events ni le shell/overlays/appareil. C7-03 reste le prochain lot ; Fargas/capture et Élixir restent séparés. FG-120 et FG-129 restent PARTIAL, sans modification de la roadmap ni promotion globale. Aucun nouvel export, téléchargement toujours 0.1.11 et annexes toujours 2/7.

Carnet actualisé : 29 tests PASS, `verify-site` PASS, 258 fichiers publics contrôlés ; version 109 déployée avec statut terminal `succeeded`, source `4fd094fab58a8deef9457a8c6f64db8a80e6adda`. Archive locale SHA-256 `98a3ba4be5fb80869c27d304ac3af553721bf3beb3d16c77bae78fcb93dd520d`, archive normalisée conservée par Sites SHA-256 `805e1995d5f4839ddb42a7194ea807c5acb8e174da1ce89268b0e69c695f6d20`. Pas de ROM, sauvegarde, projet source ou nouvel export inclus. Le suivi Notion utilise le contexte existant Monde & narration, proposé TO REVIEW après commit ; DONE reste une décision de Yoahn.

Nettoyage terminé avant sélection Git : hôtes, builds, copies de projets, dépendances Python, TMPDIR, checkout Site et archive locale C7-02 supprimés après suivi des processus, absence de consommateurs ouverts et égalité SHA des 258 fichiers publics. Le dernier enfant `AveluneQA/ecorcia-chapitre7-annexes/c7-02` occupait 311 975 936 octets alloués ; son absence et la lecture des preuves conservées sont vérifiées. Espace libre SSD mesuré séparément : 60 397 289 472 → 60 711 026 688 octets. Aucun environnement temporaire C7-02 retenu. La copie préexistante `AveluneQA/ecorcia-chapitre7-annexes/revisites-content`, 110 920 KiB, appartient à la qualification de navigation des revisites antérieure à ce lot : elle est conservée intacte comme source de C7-03 et pourra être retirée après admission des revisites et conservation de ses preuves. Les sources du vrai jeu, la sauvegarde authentique, les médias et les reçus privés restent présents.

## C7-03 — Intégrer la revisite du Puits sans casser l'histoire

**Fichiers et frontières :** `jeu/maps/puits-ramoloss-sous-sol1.json`, `puits-ramoloss-sous-sol2.json`, réglages et catalogues narratifs concernés, uniquement par authoring ; outils `revisites_navigation_publier.py`, `revisites_borders_publier.py`, `revisites_surf_configurer.py`, `revisites_runtime_test.dart` à adapter au vrai préimage source.

- [x] Calculer un delta sur les cartes source complètes : conserver les 7 PNJ, 3 objets, 8 zones, l'entrée, les 6 Events, 6 Scenes, 8 worldRules de présence, 2 Facts et leurs dépendances. Réutiliser les cinq zones Surf B1 existantes ; créer les sept zones B2 nécessaires et la liaison réciproque. Préserver les sorties vers l'entrée du Puits et la maison de Fargas.
- [x] Appliquer la navigation justifiée par les supports, les rampes et l'échelle ; recalculer les 13 Borders depuis la source. Ne pas recopier les postimages ou la réparation initiale QA. La position source du Border `border3d_d28f00c90564428d5ca956c97288703b` doit être examinée : le défaut observé n'est pas limité à QA.
- [x] Rejouer Force, Surf, les escaliers, l'habitant, Roche Royale unique, refus et échec d'écriture, retour et Continue ; vérifier les présences avant/après Rockets et les sorties existantes.

**Fermé quand :** parcours sur les données réellement intégrées, reprise conservée, récompense unique, reset de Force/rocher à la nouvelle instance correct, aucune régression narrative. La sauvegarde de fin de chapitre sans CS reste bloquée aux bons accès. Rattachements : FG-082, FG-083, FG-088, FG-120, FG-122, FG-129.

### Clôture technique C7-03 — 9 novembre 2026

Le contenu est intégré dans le vrai projet et son parcours fonctionnel est vérifié. Les trois critères ci-dessus sont acquis : delta complet conservant le récit et les sorties, navigation native recalculée, puis Force/Surf, récompenses uniques, disque, arrêt réel et Continue. La revue artistique de Yoahn et la qualification sur appareil restent distinctes. Aucun nouvel export : le téléchargement courant 0.1.12 précède C7-03.

La publication canonique compte 31 actions sans pending, avec réouverture et contrôle de conservation de 184 974 fichiers préexistants. Seules les deux cartes du Puits changent dans le contexte de 102 cartes ; les réglages Studio concurrents sont préservés. Les preuves privées canoniques sont `publication-live.json`, `native-live-proof.json` et `runtime-live-qualified-proof.json` sous `creation/ecorcia-chapitre7-annexes/revisites/c7-03/`.

Le parcours natif Metal a réellement traversé les cinq rives, les escaliers et les liaisons B1/B2, reçu Roche Royale et CT18 sans duplication, sauvegardé puis arrêté et relancé le processus, vérifié le reset de Force/rocher, réactivé Force et rejoint la sortie originale dans les deux sens. Les deux captures LIVE du raccord connu ont été inspectées. Les trois Pokémon authentiques et la sauvegarde originale sont préservés ; les capacités futures, le quatrième Ramoloss et la relocalisation initiale sont explicitement déclarés dans la fixture. Aucun accès Surf anticipé n'est accordé au vrai état de progression.

Le gel `37a6caa0…` conserve les dix cas runtime QA et les trois cas CT18 PASS, ainsi que le parcours natif QA puis LIVE. Il utilise le moteur `39314a39…` avec un seul overlay déclaré : sept lignes rappelant le compagnon pendant Surf. Le contrôle narratif LIVE a d'abord échoué : ce lecteur ancien ne reconnaît pas les nouvelles recettes BW2 de Charge. Cet échec reste conservé, sans présenter la suite ancienne comme PASS. Force et Roche Royale passent sur ce moteur ; le même test narratif est rejoué seul avec le moteur courant et passe (`02:07 +1`, exit 0, 27 descendants libérés). Ses 7 375 sources sont contrôlées avant/après dans `runtime-live-current-story-proof.json`. Ce sont deux qualifications de moteur explicites, pas un AOT commun.

À la demande de Yoahn, le compagnon disparaît dès l'entrée Surf valide, reste absent dans l'eau, les transitions et après Continue, puis revient sur terre. L'équipe n'est pas modifiée ; aucune animation nouvelle de Poké Ball n'est ajoutée. La régression Surf/compagnon et le smoke combat passent, respectivement 15 et 3 tests. L'analyse ciblée passe avec trois infos de style préexistantes ; l'analyse du package entier échoue sur deux types `int?` dans `source_converted_starter_journey_test.dart:275`, fichier inchangé, avec neuf warnings et 396 diagnostics au total. Le smoke du host exemple n'est pas exécuté avec succès : environnement de dépendances absent. MCP parity: N/A pour ce correctif de présentation ; le contenu utilise les actions canoniques existantes.

Le carnet est régénéré : obligatoire 3/3, annexes 3/7. Ses 29 tests et `verify-site` passent ; 259 fichiers publics sont contrôlés. Le générateur de galerie et son test musical ignorent désormais les fichiers auxiliaires `.editor.json`, qui ne sont pas des cartes. Site public existant publié en version 115, statut terminal `succeeded`, source `3758ae0e99122660df42287d2eaa51a00bf3ce1f`. Aucun commit du moteur. Les statuts globaux FG restent inchangés ; C7-04 n'est pas commencé. Aucun suivi Notion requis ou modifié.

### Exécution historique C7-03 — 2 novembre 2026

**État en cours : contenu publié sur la copie QA, dix scénarios Runtime et trois tests CT18 passés ; parcours natif, admission au jeu principal et clôture encore ouverts.** Aucun export supplémentaire, aucune opération Git du moteur autorisée pour ce lot. Le téléchargement public reste 0.1.11.

Audit initial : première observation `main/e539801de`, six chemins étrangers et index vide ; admission durable sur `59abe229584a34042e6ef566aa222b8bcff2238a`, quatre chemins étrangers. Les travaux concurrents Studio/Pokémon puis SPL/combat sont préservés. Le jeu HeartGold reste extérieur au dépôt moteur. La QA antérieure `revisites-content` reste en lecture seule et ne fournit aucune postimage au jeu.

Le périmètre conserve les sept PNJ, trois objets, huit zones, six Events, six Scenes, huit règles de présence et deux Facts du premier sous-sol, leurs dépendances et les sorties originales. La présence des deux Ramoloss après libération reste celle de la source. Les cinq zones Surf B1 sont réutilisées ; sept zones B2 et trois liaisons internes sont ajoutées. Le contenu nouveau comprend le rocher Force `ch7-force-177-0`, l'habitant `ch7-181-0`, la CT18 `ch7-objet-181-7042`, une récompense Roche Royale, un Fact, trois dialogues, une Scene et un Event.

La CT18 est admise comme machine native consommable vers `rain_dance`, dont l'effet existe déjà. La compatibilité HGSS utilise l'indice décodé **18**, pas 17 : 40 learnsets compatibles sur 69 espèces observées ; les entrées incompatibles, les autres CT/CS et les champs étrangers sont conservés. Aucun nouvel effet de combat ni nouvelle évolution solo n'est inventé. Fargas/Balls/capture et l'Élixir restent leurs lots distincts.

La navigation enlève uniquement les cellules d'eau non solides justifiées par la ROM : 81 sur B1, 439 sur B2 ; les quinze cellules d'eau solides B1 restent bloquées. La cellule d'échelle B1 est corrigée séparément. Cinq pieds de rampes passent de `.5` à `1`, cinq raccords de rive sont bornés à `.5 → 1`. Les 13 Borders B1 et six Borders B2 sont recalculés depuis la source. Le coin `border3d_d28f00c90564428d5ca956c97288703b` passe automatiquement de Y 1.75 à Y 2 avec la rampe corrigée, sans translation manuelle ni offset ajouté.

L'intention active `90e86110312b96ad949ebce67cea4f054ac936c4deafce9ad0ce1cb2ffa29c79` contient 31 opérations canoniques. Le rocher utilise successivement une entité custom, son modèle lié, puis `map3d.instance.configure_field_obstacle`. La version initiale de 30 opérations a été remplacée après preuve d'égalité du projet et des cinq postimages complètes ; les dix premiers reçus ont été conservés sans réapplication dans cet essai historique. Le premier accusé d'import a également été récupéré à partir de l'historique durable et de ses quatre postimages exactes, sans nouvel apply.

#### Contexte de validation et preuves

Le chargeur réel requiert les références globales et les états des cartes déjà visitées. La fixture finale conserve les 102 entrées de cartes, leurs 45 212 984 octets JSON, les 426 scènes et leurs dépendances : 99 personnages, 5 464 modèles et 491 tilesets avant les ajouts. Les médias physiques restent bornés aux cinq cartes parcourues et à leur fermeture effective. Les cinq cartes du parcours sont comparées intégralement ; les cent cartes non modifiées sont contrôlées par leurs octets et SHA. Le profil `project.visual.json` de 750 octets est identique à la source, SHA `90c9af7369193f56d54de8d5f4d5931fe3e5d70a87c070b8e89a324f86c33305` ; les quinze sidecars de carte absents restent absents.

La certification Runtime/native utilise une tranche isolée du commit `39314a39c4f551a9213e3a046003f586f24ca7e0`, créée par lecture Git, sans checkout ni worktree : dix packages et `third_party/flame_3d`, 2 726 fichiers, 67 410 474 octets de sources. Le package config des tests et du natif est commun. Les modifications concurrentes SPL restent dans le dépôt original. La frontière API/CLI authoring est enregistrée séparément ; elle n'est pas présentée comme le moteur compilé du Runtime.

Le build macOS Release passe : 108,3 Mo ; 5 321 inputs identiques avant/après, 4 840 entrées Dart du depfile couvertes, aucune classe du moteur original dans le graphe isolé. Le vrai AOT est `App.framework`, SHA `191425c485871cb8f2d8f67660a9840482b3838ade9fb826815a08cda5e79c2f`, et non le seul stub Cocoa. Les seuls assouplissements du scaffold sont propres à cette app QA : GPU activé et serveur loopback, App Sandbox désactivée après son refus d'écriture dans le cache. Aucun entitlement produit n'est modifié.

L'admission QA courante est `67fa7d38d94582f434fac291723248abf6851a87ad291f37baf0fa411a090bee`, le reçu de publication `9486b4779d574a03adbc576f181270451eca9ef875bccdb789637defeea77d07`, avec 31 reçus et `pending: null`. La reprise retourne `additionalApply: 0`. Les postimages B1 et B2 sont respectivement `dd31ff5b05d7aa70245242744d9b43aed270114ff5d91fa1baf808c2f65f1b8c` et `a7b8078fa1d8a3da121087e792940f37c54c987080a55748723b32097a7302bd`.

| Vérification exécutée | Résultat acquis à ce stade |
|---|---|
| Préflight indépendant des 102 cartes, métadonnées complètes, médias effectifs et sidecars | `01:18 +2: All tests passed!`, exit 0, descendants réapés |
| Deux sauvegardes authentiques, Continue, vraie écriture disque, reprise à froid et B2 | `02:20 +2: All tests passed!`, exit 0, descendants réapés |
| Vérificateur de delta : treize gardes positives/négatives | `All tests passed! Ran 13 verifier tests`, exit 0 |
| Recette CT18 | `--check` PASS, 40 learnsets / 69 espèces, cinq gardes de fusion |
| CT18 : apprentissage, incompatibilité, annulation, PP, consommation, Continue et Pluie cinq tours | `00:54 +3: All tests passed!`, exit 0, sous gel `15cd04f6…` |
| Dix scénarios Runtime complets | `08:26 +10: All tests passed!`, exit 0, deux descendants réapés, `remaining=[]`, sous gel `15cd04f6…` |
| Retour après reset, cinq vraies poussées Force et sortie originale aller/retour | Diagnostic ciblé `02:11 +1: All tests passed!`, exit 0, deux descendants réapés |
| Géométrie canonique fraîche | 19 Borders fresh, zéro erreur/avertissement de Border ; trous/exposé/non prouvé zéro ; AABB B1 neuf contacts existants, B2 zéro |
| Smoke Runtime combat | `00:00 +3: All tests passed!`, trois descendants réapés |
| Smoke host golden slice | `00:00 +14: All tests passed!`, 22 descendants réapés |
| MCP TypeScript | `npm run check` et `npm run build`, exit 0 ; seize contrats concernés découverts |
| MCP ciblé | Trois PASS : Event V2, zone movement, catalogue d'objets ; deux FAIL dans `border_spatial_stdio.test.ts`, détails ci-dessous |
| Parcours macOS Metal et inspection du contact d'escalier | En cours ; aucune qualification native complète revendiquée |
| Publication et relecture du jeu principal | Pas encore exécutées |

Le gel `15cd04f6…` conserve le PASS des dix scénarios et des trois tests CT18. Une correction d'attente du pilote natif, limitée à attendre effectivement `strengthActive`, est en cours de qualification sur un nouveau gel. Les anciens PASS restent immuables et historiques ; ils ne sont pas réétiquetés avec de nouveaux hashes. Après stabilisation native, les deux suites seront rejouées une fois sous le même gel final.

Le scénario futur Surf/Force utilise une fixture déclarée : relocalisation initiale, capacités futures et quatrième Ramoloss. Les trois Pokémon authentiques et leurs identités sont conservés ; la sauvegarde originale reste byte-identique, SHA `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a`. Les refus depuis le vrai état de progression sont testés séparément. Le cas sac plein projette en mémoire une limite d'un exemplaire dans la poche concernée ; le projet réel garde sa politique. Cette vue contient toutes les définitions nécessaires au contexte global, son owner détaché est explicite et toutes ses autres données sont comparées à la vue complète.

Le retour après reset exige de réutiliser Force : le rocher initial `(23,4)` ferme le couloir. Les cinq poussées jusqu'en `(28,4)` sont maintenant prouvées par de vrais inputs ; le personnage contourne ensuite le rocher au sud, rejoint les escaliers originaux et la sortie `(42,28)`. Aucun terrain ni collider n'a été changé pour faciliter le test. Le pilote médical hérité est désactivé dans ce lot ; aucune guérison, aucun PP ni résultat de combat n'est injecté par cette adaptation.

#### Fichiers et zones de changement

Le seul document moteur prévu est ce plan existant. Les quinze helpers maintenus sont dans `creation/ecorcia-chapitre7-annexes/`, hors Git moteur :

| Fichier | Zone et responsabilité |
|---|---|
| `c7_03_fixture.dart` | Sélection par le vrai Runtime, corpus 102 cartes, métadonnées et médias nécessaires, readback et witnesses |
| `c7_03_fixture_test.dart` | Préflight indépendant avant publication : contexte, fichiers et loaders effectifs |
| `c7_03_boot_preflight_test.dart` | Deux vrais Continue, état durable complet, normalisations du writer, états étrangers et scripts préservés |
| `c7_03_navigation.py` | Recalcul ROM, eau non solide, rampes et raccords |
| `c7_03_preparer.py` | Intention canonique de 31 actions, préimages et témoins gelés |
| `c7_03_expected.dart` | Postimages typées complètes et résolution native des 19 Borders |
| `c7_03_verifier.py` | Comparaison de toutes les sections de projet et de chaque champ des cinq cartes détaillées |
| `c7_03_verifier_test.py` | Treize refus de dérive, dont bool/nombre, PNJ, ancienne zone, instance et Border |
| `c7_03_publier.py` | Staging, preview/apply, pending durable, reprise, conservation et gates QA/LIVE |
| `c7_03_tm18_preparer.py` | Fusion gardée du catalogue et des 40 compatibilités natives |
| `c7_03_tm18_test.dart` | Services de machine, état durable et moteur Pluie réels |
| `c7_03_runtime_test.dart` | Refus, récit Rocket/Fargas, Force/Surf, cinq rives, récompenses, reset, disque et Continue |
| `c7_03_native.dart` | Vraie session et vue 3D, dialogue Player et SaveGameUseCase dans un host QA |
| `c7_03_native_driver.py` | Inputs et frames GPU, captures, redémarrages réels et preuves de parcours |
| `c7_03_sources.py` | Graphes de provenance séparés, vrai AOT, gel et vérification des inputs effectifs |

Les reçus canoniques sont sous `creation/ecorcia-chapitre7-annexes/revisites/c7-03/`. Les essais invalidés, leurs logs et leur code exact sont conservés dans une archive unique de preuves `bootstrap-incomplete-closure`, sans copie complète de projet. Le détail des unités physiques admises est dans `publication-qa.json.expectedFiles` ; l'inventaire du jeu principal sera ajouté à la clôture LIVE.

#### Commandes et limites

Depuis le chantier privé : `python3 -B c7_03_preparer.py --check`, `python3 -B c7_03_tm18_preparer.py --check`, `python3 -B c7_03_verifier_test.py`, puis `python3 -B c7_03_publier.py --qa`. Les tests sont exécutés avec le wrapper `executer_tests.py`, `TMPDIR` dans l'unique root QA, et le package config du host isolé. Les actions du driver sont `runtime`, `native` et `review-contact`. Les commandes LIVE ne seront exécutées qu'après les preuves native/runtime qualifiées.

Les deux échecs MCP ciblés restent visibles : premier test Border, `idempotency.preparation_required` à `border_spatial_stdio.test.ts:132` ; second, compteur attendu 11 contre 13 à la ligne 521. Aucun de ces tests ni leur moteur n'a été modifié pour ce lot. Les 19 Borders du Puits sont en revanche testés via le chemin canonique API/CLI et le contexte Runtime. Aucun nouveau contrat ou contrôle UI n'est créé ; l'Editor n'est pas globalement certifié par cette authoring de contenu.

Les deux warnings `visible_for_testing` du helper audio importé hors `test/` restent limités au harnais privé. L'hygiène Markdown garde son échec préexistant sur deux documents ignorés étrangers : le plan iOS du 31 octobre et l'audit des cartes Johto du 31 octobre. Aucun nouveau Markdown C7-03 n'est créé. Les contrôles de rendu macOS ne certifient ni l'iPhone/Android, ni l'acceptation visuelle de Yoahn, ni le shell complet de Player. Le téléchargement 0.1.11 reste antérieur au lot.

Auto-critique : le coût du lot a été augmenté par une fixture initialement trop réduite et par des oracles qui comparaient des données brutes à leur normalisation de sauvegarde. La fixture finale garde le contexte réellement consommé, le writer est vérifié sans supprimer les sept variables de script, et les preuves erronées restent identifiées comme telles. Les conditions de sécurité des Borders ne sont pas désactivées. Le contact connu de l'escalier ne sera accepté en LIVE qu'avec sa paire exacte, sa traversée bidirectionnelle et deux captures inspectées.

Statuts de roadmap inchangés : FG-082/083/120/129 `PARTIAL`, FG-088 `TODO`, FG-122 `DEFERRED` historique MVP ; Force est explicitement autorisé dans C7-03, sans promotion globale de FG-122. La clôture locale doit rester `TO REVIEW`, jamais `DONE` sans décision de Yoahn. C7-04 demeure le prochain lot ; il n'est pas commencé.

## C7-04 — Ajouter l'Élixir tous-PP

**Fichiers et frontières :** `packages/map_core/lib/src/models/items/project_item_effect_definition.dart`, `packages/map_core/lib/src/serialization/project_item_catalog_codec.dart`, `packages/map_core/lib/src/validation/project_item_catalog_validator.dart`, `packages/map_core/lib/src/read_models/item_capability_truth.dart` ; `packages/map_gameplay/lib/src/player_item_effects.dart` et `items/player_item_use_service.dart` ; `packages/map_authoring/lib/src/domains/gameplay/item_catalog_actions.dart` ; consommateurs runtime/menus de PP et tests correspondants. Les fichiers générés sont régénérés dans le seul package touché.

- [x] Ajouter une portée explicite attaque choisie/toutes les attaques avec comportement et encodage legacy inchangés pour la portée par défaut ; garder cohérents codec strict, validation, capability et export/Player. Un Player qui ne connaît pas la capability tous-PP refuse clairement le nouveau jeu, sans toucher aux données, plutôt que d'appliquer une portée erronée ; les anciens jeux restent pris en charge.
- [x] Appliquer à tous les emplacements valides en une opération, plafonner chaque PP, consommer une seule unité si l'effet s'applique ; refuser sans consommation si aucun effet n'est possible. L'Élixir HGSS utilise +10 PP pour chaque attaque, configuré par les données.
- [x] Raccorder les sélecteurs de cible et l'authoring guidé. Respecter le support réel par contexte : aucun usage en combat affiché comme disponible sans exécution et write-back prouvés.
- [x] Vérifier ancien Éther, Élixir partiel/complet, emplacements absents, annulation, sauvegarde/Continue et échec de persistance ; prouver la parité API/CLI/MCP et les coûts locaux du contrôle ajouté.

**Fermé quand :** l'objet HGSS utilise un effet générique réellement consommé par les contextes annoncés, avec une consommation exacte et compatibilité des anciens objets. Rattachements : FG-050, FG-060, FG-062.

### Clôture technique C7-04 — 9 novembre 2026

Extension fonctionnelle intégrée et prête pour revue. `restore_pp.scope` accepte `selected_move` et `all_moves` ; la portée par défaut conserve l'encodage historique sans champ supplémentaire. Les anciens Éthers restent ciblés sur une attaque. Les portées tous-PP ciblent un Pokémon et appliquent une seule consommation, avec plafonds propres à chaque emplacement, refus sans effet et sans création de PP manquants.

Les consommateurs hors combat et combat sont raccordés, y compris les emplacements numériques dupliqués, Morphing/Copie et les réservations d'objets du combat duo. Studio propose les restaurations partielles/complètes de toutes les attaques ; les previews refusent les mauvaises cibles et l'annulation ne lance pas d'utilisation. L'effet passe par les services, les codecs et les commandes canoniques existants : aucun chemin de sauvegarde, stockage ou invalidation n'est ajouté ou remplacé, aucun parcours global n'est ajouté au contrôle, aucun budget de latence n'est revendiqué.

Le contrat `items.restore-all-pp@1` est dérivé du contenu par l'exporteur et exigé à l'admission du paquet. Les tests couvrent projets classiques/partitionnés, refus d'un host sans cette capability, conservation des octets et ancien effet accepté sans nouvelle exigence. Les deux exports canoniques de fixture passent. Aucun nouvel export HeartGold n'est livré.

Preuves ciblées : 28 tests modèle/validation, 17 tests gameplay, 27 tests PP combat, 34 tests API/JSONL, 2 exports canoniques, 40 tests runtime dont smoke combat, 1 preview du sac, 3 tests Studio ciblés, 17 tests admission/baseline de paquets et 1 serveur MCP stdio frais avec quatre écritures puis réouverture à froid. Le host Studio existant a accepté le hot reload ; aucune erreur runtime remontée. Ce n'est pas une qualification artistique ou sur appareil. Le serveur MCP déjà connecté avant les changements conserve son ancien catalogue en mémoire ; le contrat nouveau est prouvé sur le serveur stdio fraîchement lancé, sans arrêter les processus d'autres sessions.

Deux opérations canoniques ont intégré l'icône et l'Élixir dans le vrai projet. Les 54 anciens objets, les fichiers des cartes et leurs documents auxiliaires, les réglages du projet et la sauvegarde authentique sont préservés. Un test supplémentaire utilise le vrai catalogue, une fixture déclarée de la sauvegarde authentique avec deux Élixirs et deux PP diminués, puis le contrôleur pause réel et une sauvegarde/reprise sur disque au format courant. Ce test passe sans toucher à l'original ; il ne prétend pas être un redémarrage natif. Les collectes dans les Caves restent C7-05/C7-06. Obligatoire 3/3 et annexes 3/7 restent inchangés.

Les suites globales ne sont pas déclarées vertes : core 7 117 PASS, 20 échecs et 1 skip ; gameplay 2 207 PASS, 10 échecs ; distribution 802 PASS, 10 échecs ; parité globale 27 PASS et 1 échec. Les tests ciblés du lot passent. Les fichiers en échec ont été rejoués isolément ; la revue conserve les problèmes de fixtures, de documentation absente et de contrats plus anciens. L'analyse globale conserve les deux erreurs du test de départ converti du runtime, sept erreurs Editor et deux warnings d'un test d'import Gen5 dans authoring ; aucun de ces fichiers n'est modifié par C7-04. Le helper de test Editor lit désormais l'historique canonique au lieu du seul ancien JSONL ; les tests PP vérifient bien l'undo et la réouverture. L'ancien test générique d'ensemble reste en échec sur une révision nullable hors du flux PP.

La génération filtrée a supprimé temporairement d'autres outputs ; la régénération complète du seul package `map_core` les a rétablis. Les deux fichiers générés sans rapport sont revenus byte-identiques ; seuls les outputs du modèle PP conservent un delta. Aucun Git write, aucun suivi Notion et aucune modification de la roadmap globale. FG-050/060/062 gardent leurs statuts historiques DONE ; le présent lot prouve une extension locale. Prochain lot : C7-05.

Carnet régénéré et vérifié : 29 tests PASS, `verify-site` PASS, 260 fichiers publics contrôlés. Version finale 117 du Site existant publiée avec statut terminal `succeeded`, source `eaf4d22a11b8a83a7e677aa5afef6353931c71b9`. Cette dernière version conserve les résultats initiaux et précise que le cas de parité en échec est PASS lorsqu'il est rejoué seul ; les autres échecs des suites globales restent distincts. Le téléchargement 0.1.12 conserve ses octets et indique explicitement qu'il précède C7-03/C7-04. Les preuves privées sont sous `creation/ecorcia-chapitre7-annexes/revisites/c7-04/` ; la synthèse publique expurgée est `suivi/preuves/chapitre7-elixir-c7-04-20261109.json`.

## C7-05 — Terminer le nord du premier sous-sol des Caves

**Fichiers et frontières :** `jeu/maps/caves-jumelles-sous-sol1.json`, ses dresseurs/objets/rencontres et raccords RDC ; `revisites_preparer.py`, `revisites_pack.dart`, `objets-caves.json`, `revisites_runtime_test.dart` du chantier.

- [x] Confronter la branche nord, les accès et chaque dresseur/objet à l'inventaire sourcé ; conserver la branche sud déjà parcourue.
- [x] Intégrer les seuls éléments manquants, passages et conditions Surf/Force ; conserver Terrain, Paths et Borders natifs.
- [x] Parcourir les accès autorisés, mener les combats nécessaires, ramasser les objets, sauvegarder/reprendre et revenir au RDC ; tester les accès refusés et la non-duplication.

**Fermé quand :** inventaire de la branche couvert par des preuves intégrées, retour praticable et branche sud intacte. Rattachements : FG-083, FG-086, FG-108, FG-120, FG-122.

### Exécution du 9 novembre 2026 — C7-05 intégré et qualifié fonctionnellement

37 opérations canoniques dans le principal : Gérard et Michel, leurs quatre Pokémon et natures natives, six dialogues et deux scènes/événements, Rappel caché avec sa définition et son icône natives, rocher Force entier réutilisé, huit liaisons d'escaliers réciproques, ouverture des 96 cases d'eau du nord B1 et des 33 cases du seul transit nord B2. Dix-sept interpolations de navigation raccordent les rives sans modifier les terrains ; les 38 Borders ont été rematérialisés. L'audit final a ajouté les rencontres Surf B1 manquantes : table/zone, Maraiste avec quatre documents et cinq images ROM natives. Axoloto/Maraiste, cinq poids 60/30/5/4/1 et niveaux 10–20, 15–25 puis 10–20 sont sourcés ; le taux adapté de 0,15 par pas ne certifie pas le RNG Gen4 exact. Le contenu ordinaire du B2 et Lokhlass restent C7-06/C7-07.

Preuves du chantier privé `revisites/c7-05/` : trois scénarios Runtime QA en 4 min 11 s, puis quatre tests sur le vrai projet en 7 min 55 s, dont le parcours sud naturel depuis la sauvegarde authentique, réussis après admission Surf. Les deux espèces sont effectivement rencontrées en Surf et les fuites sont jouées par le moteur sans erreur de combat ni résultat injecté. Le diagnostic d'escaliers est désactivé dans ces suites et a passé séparément avant l'ajout des rencontres. Combats remportés par le moteur, soins via le vrai sac, Rappel unique, écriture disque `SaveGameUseCase`/`FileGameSaveRepository`, nouveau contrôleur après Continue, huit nouvelles liaisons, reset du rocher, cinq poussées et retour par l'ancienne sortie RDC sont parcourus. Les refus Surf/Force ne débloquent rien. La fixture future ajoute explicitement un Macronium niveau 35 issu du catalogue, le porteur Surf déjà sourcé et des consommables avant le départ ; aucun résultat de combat, soin, fait ou téléportation n'est injecté pendant le parcours.

Le delta canonique conserve les 99 autres cartes, les 45 anciens dresseurs, 596 dialogues, 427 scènes et anciens événements. Contrôle physique de 185 460 fichiers préexistants, 2 718 505 317 octets, 12 128 records d'assets et 55 définitions d'objets ; seule la portée prévue change. Sauvegarde authentique `67ec65c4…dad0a` intacte. Les contrôles structurels frais des 16 + 22 Borders ne remontent ni erreur, avertissement, trou, cellule non prouvée ni chevauchement de boîtes.

Un défaut du chemin d'authoring à catalogue refusait la création d'une zone de rencontres. Correctif limité à `TriggerZoneActions` et `CatalogSpatialMapSelection` : fermeture des références ciblées existante, création strictement contrôlée, refus des tables absentes et protection du delta. Tests rouges avant correction, puis trois nouveaux cas PASS, avec travail propriétaire identique à 0/90 cartes étrangères, première création et répétition, annuler/rétablir et réouverture. Le vrai publisher JSONL reprend explicitement au huitième élément après vérification des sept reçus et de leurs dernières postimages ; aucune écriture réussie n'a été rejouée. La tentative de lecture globale en QA a été abandonnée : elle échouait sur le repli natif et ne respecte pas la borne locale. Aucune mutation du vrai projet n'a utilisé cette tentative.

Vérifications moteur : `dart test test/workspace/catalog_spatial_map_mutation_test.dart -r failures-only` donne 87 PASS et un échec sur l'ancienne assertion de lectures du changement de fond à 90 cartes, également en échec isolé ; ce chemin n'est pas modifié. `dart test test/parity/full_authoring_parity_test.dart -r failures-only` : 28 PASS. Analyse ciblée des deux sources et du test : aucune erreur/warning, quatre infos préexistantes ; `dart analyze` du package : 46 infos et deux warnings dans un test Gen5 non modifié. Test de l'adaptateur Studio sur catalogue : PASS ; le test historique sans catalogue échoue sur sa révision, hors du nouveau chemin. MCP frais : créations movement/encounter, réouverture et annulation PASS (2), `npm run check` et build PASS ; découverte/sécurité 7 PASS et une ancienne liste d'outils attendus en échec. `dart run tool/pmcp085_conformance.dart` reste exit 1 : catalogue complet mais certifications de transport globales et objets incomplètes. Suite MCP exhaustive non relancée. Les trois contrats Python du delta37 passent. Smokes Runtime 3 PASS et host isolé 14 PASS, exécutés dans ce lot avant le seul correctif d'authoring.

Cette fermeture est fonctionnelle : contrôleur de production sans fenêtre, audio simulé, aucun appareil ni shell Player complet certifié. L'appel de capture 3D a échoué à compiler son hôte (`render3d.host_build_failed`) ; sa première cause de compilation n'est pas établie et aucune nouvelle acceptation visuelle n'en est déduite. Les poses initiales des Montagnards sont sourcées, leurs rotations autonomes natives 7/9 restent simplifiées par `scriptedOnly`. Les contrôles structurels finaux passent après les 37 opérations. Le convertisseur ROM local a remplacé le CLI absent du skill de production d'assets, sans fournisseur ni dépendance du jeu ajoutée. Aucun nouvel export. Les 33 chemins Git préexistants C7-03/C7-04 sont conservés ; cinq chemins supplémentaires portent le correctif C7-05 et ses tests ; HEAD reste `d2186aea13afd85690e9906dc04511f50302eb60`, aucun commit/push moteur demandé ou exécuté. MCP parity: comportement ciblé API/JSONL/Studio/MCP prouvé ; matrice globale de certification toujours incomplète. FG-083/120 restent PARTIAL, FG-086/108 TODO, FG-122 DEFERRED ; aucune promotion globale ni changement de roadmap.

Carnet régénéré et vérifié : 29 tests PASS, `verify-site` PASS et 261 fichiers publics contrôlés, sans données privées ni paquet de jeu. Version 118 publiée sur le Site existant, statut terminal `succeeded`, source `5fec57a1cf0e414942397c6de5dd8681fcd9ebf9`. La preuve publique expurgée est `suivi/preuves/chapitre7-caves-nord-c7-05-20261109.json`. Le téléchargement reste 0.1.12 et annonce qu'il précède C7-03/C7-04/C7-05. Obligatoire 3/3 et annexes 3/7 inchangés ; l'objectif Caves ne ferme pas avant la suite. Aucun travail C7-06 commencé.

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
- [ ] Produire un export unique, vérifier installation/mise à jour, sauvegarde et Continue sur le format de sauvegarde courant ; tester aussi des fixtures de jeux exportés protégés représentatives de la baseline 0.3.31 et ultérieures, ainsi que l'échec/futur format de jeu ou de sauvegarde sans modification des originaux. Depuis le 2026-11-08, les sauvegardes de progression antérieures au format courant ne sont plus garanties (`AGENTS.md`) : toute rupture est annoncée aux testeurs. Une seule mise à jour actuelle ne certifie pas tout l'historique.
- [ ] Publier exactement les mêmes octets Bureau/Release et vérifier leurs SHA-256 ; actualiser le carnet (Notion seulement sur demande) sans déclarer les annexes différées terminées.
- [ ] Arrêter les seuls processus QA possédés, conserver les preuves utiles, supprimer les environnements et exports temporaires du lot après contrôle des consommateurs ; mesurer et signaler toute rétention justifiée.

**Fermé quand :** livrable accessible, SHA identiques, mise à jour et sauvegardes vérifiées dans le périmètre annoncé, carnet fidèle, QA nettoyée, implémentations prêtes pour revue. L'acceptation finale `DONE` reste à Yoahn.

## C7-D1 — Fargas et les Balls, différé à la refonte Pokémon/combat

Le moteur de fabrication différée existe. Préserver ses recettes préparées et ses tests sans le réécrire ni activer de récompenses factices.

- [ ] Après stabilisation de la refonte, admettre les sept Balls et leurs effets génériques validés, dont la Masse Ball, sans patch dans l'ancien pipeline.
- [ ] Brancher dépôt/quantité, disponibilité au prochain jour civil et retrait unique chez Fargas ; vérifier ingrédients, sac plein, refus, Continue et erreurs de persistance.
- [ ] Vérifier les Balls dans le vrai flux de capture ainsi que la sauvegarde et la reprise au format courant, puis activer le service.

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
