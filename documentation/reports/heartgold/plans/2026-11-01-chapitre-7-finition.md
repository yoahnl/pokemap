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

- [x] Intégrer accès, dresseurs, objets et rencontres ordinaires manquants selon l'inventaire ; réserver l'emplacement/condition de Lokhlass sans activer une rencontre fictive.
- [x] Vérifier reliefs, berges, escaliers et retour depuis chaque branche avec les systèmes natifs existants ; preuve structurelle et contrôleur, revue graphique distincte ci-dessous.
- [x] Jouer les branches, combats et collectes, puis Continue et retour ; contrôler accès verrouillés, objets uniques et absence de blocage après reprise.

**Fermé quand :** le sous-sol est complet et parcourable pour son contenu ordinaire ; seule la rencontre périodique dépend encore des lots C7-07/C7-08. Rattachements : FG-083, FG-086, FG-101, FG-108, FG-120, FG-122.

**Implémentation fonctionnelle intégrée le 9 novembre 2026, proposée TO REVIEW.** Le périmètre inclut les accès sud nécessaires : Evan et Denis au B1, l'escalier réciproque B1/RDC et le bassin sud-ouest du RDC. Gurvan, Gerry et Emma, les quatre récompenses B2 (Élixir, Hyper Potion, Hyper Ball cachée, Calcium caché), les cinq tables ordinaires et leurs dépendances sont intégrés par 66 opérations canoniques, réparties en sept intentions figées. Les 9 nouvelles espèces disposent de 45 médias Pokémon ; cinq icônes d'objet complètent les 50 nouveaux assets. Les rencontres nocturnes Stari des deux meilleures cannes sont sourcées et leurs seuils 20 h/4 h vérifiés. Radio et invasions restent hors tables ordinaires ; le taux adapté au runtime ne certifie pas le RNG Gen4 exact. Aucun acteur ni combat Lokhlass activé.

Navigation : 568 cellules d'eau B2, 80 au sud B1 et 38 au RDC sont ouvertes sur les permissions natives. Les terrains, Paths, contours et décors sont conservés ; les caches des Borders sont rematérialisés. Les 30 interpolations de rive B2, 11 axes B1 et six axes RDC permettent le parcours. L'embarquement arbitraire sur deux coins B1 et un coin RDC omis pour éviter des rampes perpendiculaires superposées n'est pas certifié. Le contrôle structurel courant des trois cartes passe : 70 Borders frais, zéro erreur, avertissement, trou ou chevauchement signalé ; aucune preuve graphique n'en est déduite.

Vérifications exécutées depuis `packages/map_runtime`, via le superviseur maintenu `executer_tests.py` et le TMPDIR QA : `flutter test --no-pub --concurrency 1 .../c7_06_runtime_test.dart` sur QA, **3 PASS, 09:18** ; la même commande sur Source avec `HGSS_C706_SOURCE=1`, complétée de `.../parcours_caves_sud_test.dart`, **4 PASS, 12:57**. Les cinq victoires Source sont réelles, sans résultat injecté ; les trois cannes, Calcium consommé pour +10 EV Attaque Spéciale, les quatre objets uniques, nouveau contrôleur après sauvegarde disque, non-répétition d'Emma et retour RDC sont contrôlés. Les capacités futures, les cannes et le Pokémon de niveau 35 sont déclarés avant boot des fixtures C7-06. Le quatrième parcours repart de la sauvegarde authentique sans injection de position ni de progression. Les superviseurs sortent 0, aucun descendant restant. Les échecs QA antérieurs (ressources d'animation non copiées et accès au lac RDC fermé) sont conservés dans les logs ; ils ne sont pas présentés comme des réussites.

`c7_06_contract_test.py` : **3 PASS QA puis 3 PASS Source**. Les 99 autres cartes et les données antérieures des trois cartes touchées sont préservées. `c7_06_publier.py --verify` : **PASS**, 66 reçus appliqués sans opération en attente, 186 035 fichiers antérieurs et 12 134 anciens assets contrôlés ; sauvegarde authentique SHA-256 `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a` inchangée. Analyse Dart des deux helpers : **No issues found** avec les résolutions de packages explicites. Les revues indépendantes SPEC et QUALITY sont **PASS** sur la QA avant intégration ; les preuves Source sont vérifiées séparément ensuite. Reçus, intentions et logs conservés dans `creation/ecorcia-chapitre7-annexes/revisites/c7-06`.

Limites : contrôleur de production sans fenêtre et audio simulé. La tentative de capture native échoue pendant la compilation de son hôte : crash du générateur AOT Flutter sur `_window_macos.dart`, classe `_Rect`, sortie -6. Aucune nouvelle revue GPU, appareil ou acceptation visuelle. Les anciennes captures restent historiques ; poses autonomes simplifiées et décor de combat générique restent signalés. Aucun changement de code moteur ni format de sauvegarde. MCP parity: N/A — actions et contrats existants utilisés sans modification. FG-083/120 restent PARTIAL, FG-086/101/108 TODO, FG-122 DEFERRED ; aucune promotion globale.

Git moteur : 38 chemins sales préexistaient au début global du lot ; des commits concurrents `6f2990ef2` puis `4a849217c` ont ensuite rendu l'arbre propre, sans opération Git de C7-06. Ils sont préservés et ne sont pas attribués à ce lot. Le présent plan est le seul fichier moteur modifié par C7-06 ; aucun commit/push moteur autorisé ou exécuté. Carnet : contenu obligatoire 3/3, annexes 4/7 après qualification des Caves ordinaires ; Lokhlass reste C7-07/C7-08. Aucun nouvel export : téléchargement 0.1.12 antérieur à C7-03/C7-04/C7-05/C7-06.

Carnet régénéré, 29 tests PASS, vérificateur PASS, 262 fichiers publics contrôlés sans source du jeu, ROM ni sauvegarde. Version 119 publiée sur le Site existant, statut terminal `succeeded`, source `88738a5c373a3ad92b5092010c62ca0da71338c1`. Preuve publique expurgée : `suivi/preuves/chapitre7-caves-b2-c7-06-20261109.json`. Après les quatre tests Source, les 160 postimages et l'empreinte de la sauvegarde authentique sont encore vérifiées identiques. Les preuves utiles sont archivées, puis la seule QA C7-06 possédée est supprimée après contrôle des consommateurs : zéro processus actif, 1 384 292 Kio retirés, reçu `cleanup.json` conservé dans le chantier ; aucun original supprimé. Vérification Markdown finale : aucun nouveau fichier Markdown.

## C7-07 — Compléter les rencontres périodiques durables

**Fichiers et frontières :** conditions et disponibilité dans `map_core` ; `packages/map_gameplay/lib/src/periodic_reward_checkpoint.dart`, `periodic_reward_operations.dart` et évaluateur de conditions existant ; `packages/map_runtime/lib/src/spatial/spatial_battle_runtime.dart` et services de session ; authoring des conditions et capability dans `map_authoring`/`map_distribution`. Coordination obligatoire avec le propriétaire Pokémon/combat.

- [x] Ajouter la condition typée de jour civil en réutilisant le calendrier existant, sans dépendre de l'heure visuelle ni d'un délai artificiel de 24 h.
- [x] Définir la consommation périodique d'une rencontre non-item : victoire, capture et fuite consomment ; défaite ne consomme pas. Rendre cette politique explicite et configurable au bon niveau.
- [x] Persister atomiquement le résultat complet du combat et le claim : capture/Party/PC, XP, état et calendrier. Le checkpoint de récompense limité au sac ne peut pas remplacer cette transaction. Ne confirmer la fin qu'après succès durable ; préserver les combats historiques et leur cadence de sauvegarde.
- [x] Vérifier vendredi/autres jours, changement de semaine, répétition, Continue, panne d'écriture et reprise sans double capture ni perte de progression ; prouver API/CLI/MCP, export et compatibilité sur les cas ciblés. La certification générale de tous les transports MCP reste partielle.

**Deux sous-lots fermables :** C7-07A ferme le prédicat civil typé et sa configuration ; C7-07B ferme la consommation périodique avec le checkpoint complet de combat, ses issues et ses erreurs. Le premier ne vaut pas livraison du second. Les cas d'interruption et de changement de jour pendant le combat ont une politique explicite, confrontée à la référence source avant activation.

**Fermé quand :** une rencontre périodique générique fonctionne de bout en bout sans règle Lokhlass codée dans le moteur. Rattachements : FG-087, FG-101, FG-102, FG-107, FG-108.

### Exécution du 9 novembre 2026 — C7-07 A+B, proposé TO REVIEW

**Moteur réutilisable implémenté et vérifié ; revues indépendantes SPEC puis QUALITY PASS.** Aucun contenu Lokhlass activé et aucun travail C7-08 commencé. Les statuts globaux historiques FG-087/101/102/107/108 ne sont pas promus par cette livraison locale.

C7-07A ajoute les sept valeurs ISO de `CivilWeekday` aux conditions Scene, Event et WorldRule, à leurs projections, diagnostics, authoring et contrôles de compatibilité. Le host fournit le calendrier civil existant ; l'heure visuelle ne décide pas du jour. Un calendrier absent ne valide ni la condition positive, ni sa négation. Le rafraîchissement ne provoque pas d'écriture cachée. La capability `gameplay.civil-weekday-condition@1` est détectée et refusée par un Player qui ne la prend pas en charge.

C7-07B ajoute `PeriodicEncounterDefinition` aux combats sauvages hors démonstration, avec identité stable et sous-ensemble non vide des issues victoire/capture/fuite ; les trois sont cochées à la création dans Studio. La défaite n'est jamais consommante. Les opérations pures figent l'occurrence au jour civil du lancement et gardent cette occurrence au passage de minuit. La référence HGSS de Lokhlass teste vendredi puis consomme après combat sans défaite ; la fixation du jour de lancement est un contrat Avelune explicite. Aucun traitement d'espèce propre à Lokhlass n'est codé dans le moteur.

Les hôtes 2D et 3D utilisent `NarrativeEventStateCheckpointOwner.checkpoint` avec le GameState final entier, avant publication en mémoire, confirmation de Scene et validation du reçu de capture. Le checkpoint de récompense limité au sac n'est pas utilisé. L'équipe ou le PC, les dépenses, HP/PP, XP, monde et claim restent cohérents. Le retour Scene périmé est refusé ; seul le delta de progression narrative du coordinateur est toléré. Une panne d'écriture restaure l'état antérieur puis permet un nouveau parcours, sans double capture. La défaite récupère sans claim ; le point spatial 3D est normalisé et validé avant sauvegarde. Une erreur Scene ultérieure rematérialise le dernier état durable complet. La fermeture attend l'écriture en vol. Les combats sans politique conservent leur cadence historique.

API, JSONL/CLI, Studio et tests MCP stdio frais utilisent le contrat canonique. `scene.graph.patch` reste borné à la scène et à ses dépendances, y compris le catalogue d'attaques lorsque les nœuds résultants le nécessitent ; les suppressions retirent cette dépendance. Le bridge de révision du lecteur natif historique conserve le refus des versions concurrentes périmées. Les références de disponibilité acceptent une rencontre sans faux objet. Les exports classiques et à catalogue transportent `gameplay.periodic-encounter@1` et les garde-fous de compatibilité. Un prérequis de chargement des objets périodiques sans catalogue Pokémon et le switch de prévisualisation Studio des animations de terrain sont corrigés de façon ciblée ; aucun changement des mécaniques `map_battle`.

Validations effectivement exécutées, sans somme artificielle des fichiers recouvrants : contrats Core finaux **11 PASS** ; opérations périodiques Gameplay **36 PASS** ; contrats runtime historiques **27 PASS** ; vrais hôtes durables **13 PASS** ; récupération finale après corrections **6 PASS**, récupération 2D isolée **1 PASS** et whiteout historique **1 PASS**. Les tests de prévisualisation Studio passent **15 cas**. Les preuves authoring incluent **147 régressions**, **16 cas de scope final**, **4 transports historiques**, **5 cas du panel**, les exports API/CLI 2D/3D et les deux nouveaux tests MCP stdio. `dart test test/parity/full_authoring_parity_test.dart` passe **28 cas**. Les smokes obligatoires passent : runtime **3 cas**, exemple Player **14 cas**. Pour l'exemple, les dépendances et deux fixtures sont copiées dans une QA isolée ; son lock source n'est pas modifié. Les exécutions Flutter sont supervisées et finissent avec `remaining=[]`.

Limites globales qualifiées : suite Core initiale **7120 PASS, 1 skip, 24 échecs** ; une attente exhaustive nouvelle a été corrigée puis rejouée, **19 échecs sont préexistants** et **4 non reproduits isolément** restent sans cause prouvée. Suite Gameplay **2217 PASS, 7 échecs**, les sept reproduits individuellement sur HEAD. Ces suites ne sont pas annoncées vertes. Les analyses de sources Core, Gameplay, Distribution, Authoring et Editor sortent 0 ; l'analyse source Runtime conserve deux warnings dans `player_service_runtime_controller.dart`, inchangé. L'analyse globale Runtime conserve aussi deux erreurs de test `starterJourney` préexistantes. L'analyse runtime ciblée sort 0 avec 25 informations, sans erreur ni warning. `npm run check` passe. PMCP-085 trouve **104 ressources, 472 actions, zéro contrat manquant**, mais `transportCertificationComplete=false` et `itemTransportCertificationComplete=false`. La conformité MCP générale échoue sur une liste d'outils exhaustive ancienne, dans des fichiers inchangés. MCP parity : **PASS ciblé C7-07 ; certification globale PARTIAL**. Aucun objectif de latence Studio 100/500 ms, rendu GPU, installation native ou appareil n'est déduit de ces tests.

Préservation : les **160 postimages** des 66 opérations C7-06 restent identiques ; la sauvegarde authentique conserve le SHA-256 `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a`. Aucune mutation du jeu source, aucun export, aucune opération Git du moteur. HEAD initial `4a849217c3c02d0264ffb215ef9f8cefaf7c8baa` ; le plan modifié par C7-06 préexistait et est préservé. Les autres changements de ce lot restent non commités. Obligatoire **3/3**, annexes **4/7**, téléchargement **0.1.12** inchangés. Les preuves compactes sont conservées dans le chantier `revisites/c7-07` ; la preuve publique expurgée est `suivi/preuves/chapitre7-rencontres-periodiques-c7-07-20261109.json`.

La commande générale `npm test` a été lancée puis interrompue proprement après constat de son périmètre de **220 fichiers** et du coût des cas étrangers à C7-07 : sortie **130**, aucune réussite globale revendiquée. Le superviseur a fermé ses **95 descendants**, `remaining=[]`. La conformité générale déjà exécutée échoue séparément sur l'ancienne liste exhaustive d'outils ; les deux cas stdio C7-07 et le check TypeScript restent les preuves ciblées acquises.

Carnet régénéré : **29 tests PASS**, `verify-site` PASS, **263 fichiers publics**, sans projet, ROM, sauvegarde ni paquet de jeu inclus. Version **120** publiée sur le Site existant, statut terminal **succeeded**, source `21621314a2e48e858bfbaec67997abcddd7347d5`. L'archive normalisée conservée par Sites a le SHA-256 `6b7baa225522e86add8abe657622f7d00107facc6ca22c27e0c47eeec36c46c0`. Le téléchargement annonce explicitement que 0.1.12 précède ce moteur et que Lokhlass reste C7-08.

Contrôle Git final : deux fichiers non suivis sont apparus pendant la clôture, `packages/map_authoring/test/domains/gameplay/gen5_workshop_recipe_batch_test.dart` et `packages/map_authoring/tool/gen5_workshop_recipe_batch.dart`. Ils relèvent du travail concurrent, sont préservés et ne sont ni modifiés ni attribués à C7-07.

## C7-08 — Intégrer Lokhlass, le calendrier et les contacts restants

**Fichiers et frontières :** contenu des Caves et Scenes/Events/worldRules/contacts réellement référencés dans le jeu ; `contenu.json`, `histoire_test.dart`, `preparer_histoire.py` et préparations de revisites du chantier.

- [x] Fermer un inventaire fini des événements calendaires et contacts du périmètre Route 32/Caves/Route 33/Écorcia/Puits/Alpha, avec témoin source et état déjà présent/manquant pour chaque entrée.
- [x] Configurer Lokhlass vendredi avec l'espèce, le niveau, la position et la politique C7-07 sourcés ; compléter uniquement les autres événements/contacts manquants de cet inventaire.
- [x] Jouer présence/absence selon le jour, dialogue, combat, consommation et semaine suivante ; vérifier sauvegarde/Continue et contacts sans doublon. Les changements de date utilisés dans les tests sont déclarés.

**Fermé quand :** chaque entrée de l'inventaire a une preuve ou une exclusion explicite, sans rubrique vague « autres événements » encore ouverte. Rattachements : FG-082, FG-088, FG-087, FG-101, FG-102, FG-107, FG-108.

### Point vérifié du 9 novembre 2026 — C7-08

**Intégré au jeu source et vérifié sur le périmètre logiciel convenu ; revues finales indépendantes SPEC puis QUALITY PASS.** La revue utilisateur reste `TO REVIEW` ; aucune acceptation artistique ou sur appareil n'est déduite de cette clôture locale. Prochain lot : C7-09.

L'inventaire fini contient **21 entrées sourcées**, chacune reliée à ses preuves ou à une exclusion explicite. **16 opérations canoniques** intègrent Lokhlass niveau 20 au second sous-sol des Caves, en `(19,89)` le vendredi, et Vanessa sur la Route 32, en `(31,122)`, vendredi sans badge requis. Les dialogues français 0752:16/17/18, le Pic Venin unique et le compteur de fratrie suivent la livraison réussie ; un sac plein ne consomme ni fait ni compteur. Victoire, capture et fuite consomment Lokhlass pour ce vendredi ; défaite exclue. Les atlas et icônes importés gardent leurs octets sources ; la cadence d'idle de 250 ms est une adaptation déclarée.

Les inscriptions et appels sortants existants d'Auffray, Elisabeth, Olwen et Fargas sont conservés et rejoués. Yoahn a explicitement différé les variantes d'appels d'ambiance et les appels entrants, y compris ceux déjà accessibles dans HGSS : aucun scheduler ajouté. Photos après Badge Plaine, ruban après sept membres de fratrie et contacts de progression future sont exclus ; la fabrication Fargas reste C7-D1. L'objectif calendaire complet du carnet reste ouvert : obligatoire **3/3**, annexes **4/7** maintenus.

Deux écarts ciblés sont corrigés : `poison_barb`, déjà consommé par PSDK, rejoint la vérité des effets tenus ; l'adapter singles conserve l'index des réserves du menu malgré une réserve K.O. intermédiaire. Deux tests RED puis **38 tests PASS** couvrent le mapping volontaire/forcé et ses consommateurs. Les contextes de Poké Ball, Super Ball et Honor Ball sont étendus à `special` par les commandes existantes, sans changement de ratios, animation ou autres champs. Le défaut préexistant de dépendances de `scene.upsert_batch` reste ouvert ; les deux scènes utilisent `scene.upsert` unitaire.

La preuve finale utilise un conducteur de capture unique et de vraies commandes de présentation : Bâillement, Charge seulement à PV adverses pleins, soins si nécessaire et Hyper Ball. Le Ramoloss de fixture est déclaré niveau 50, 125000 XP et 150 HP, avec Bâillement à la place de Rugissement ; les trois membres authentiques restent présents. Dates, position de revisite et accès Surf sont déclarés. Aucun état adverse, seed, taux ou résultat n'est injecté. Les anciens essais sans stratégie ont perdu, y compris après 18 lancers ; ils sont conservés et ne qualifient pas le conducteur final. Le hook nullable du harnais antérieur conserve son comportement par défaut ; son patch est versionné et son SHA est scellé avec les 13 fichiers du dépôt.

Commandes effectivement exécutées : `flutter test --no-pub` sur les six fichiers C708/durabilité 2D/3D/checkpoint/doubles/smoke donne **37 PASS en 5 min 43 s** ; le rejeu avec `HGSS_C708_SOURCE=1` donne **10 PASS en 4 min 52 s**, soit **9 cas source et 1 cas sac plein sur clone QA déclaré**. Les traces assertées montrent Bâillement ×1, Charge ×1 et Hyper Ball ×3 en QA / ×1 sur source. Le bag-full libère une unité par équipement réel avant le don. Les trois contacts utilisent une fixture post-victoire explicite puis refus, inscription, répétition, sauvegarde/Continue et appel ; Fargas garde son inscription authentique. Les tests d'exemple standalone donnent **14 PASS** sur copie QA avec dépendances et deux fixtures complètes, sans modifier le lock source.

Les contrôles complémentaires donnent **21 PASS** pour le catalogue, **1 PASS** pour l'effet Pic Venin en combat et sa persistance, **48 PASS** pour l'authoring d'objets, **15 PASS** pour Core civil/périodique, **7 PASS** pour Gameplay et **6 tests Python PASS**, avec trois RED de gardes de publication. Le publisher refuse une intention de revue différente, un code ou un harnais externe modifié avant toute écriture de reçu ou création du worker. Les deux cas stdio MCP et le check TypeScript passent. Analyse ciblée des quatre fichiers Dart C708 : `No issues found`; analyse Core complète sortie 0, 179 informations. Les anciens échecs globaux Core/Gameplay et deux erreurs de test historiques Runtime restent signalés, sans certification globale. MCP parity : **N/A pour C7-08**, commandes et contrats canoniques existants consommés ; parité ciblée C7-07 préservée, certification globale PARTIAL.

Les exécutions Flutter supervisées terminent avec `remaining=[]`. Une tentative parallèle partageant le build Runtime a échoué sur `objective_c.dylib` ; la matrice finale utilise le consumer QA et son build isolé, tandis que le source garde son propre build. **12 postimages source** sont vérifiées ; **187260 anciens fichiers**, **12184 enregistrements d'assets**, **100 cartes non concernées** et la sauvegarde authentique sont préservés, sans changement inattendu. Les preuves privées compactes restent dans `revisites/c7-08` ; la preuve publique expurgée est `suivi/preuves/chapitre7-calendrier-c7-08-20261109.json`.

Limites : contrôleurs sans fenêtre, audio simulé, aucun nouveau rendu GPU ou appareil, aucune mesure Studio 100/500 ms ni équilibrage depuis l'équipe authentique. Le hot reload du Studio actif a été refusé par le service VM ; cette application n'est pas certifiée rechargée par les tests. Aucun nouvel export : le téléchargement reste **0.1.12**, antérieur à C7-03 jusqu'à C7-08. FG-082 reste PARTIAL ; FG-087/088/101/102/107/108 restent TODO, sans modification de la roadmap globale. Le prérequis C7-07 est commité séparément sous `06fd484d3fbe762f33380e05a21629cb6dee23fc` ; les sprites, `.gitignore` et captures Studio concurrents restent exclus du commit C7-08.

Carnet : **29 tests PASS**, `verify-site` PASS, **264 fichiers publics** expurgés et aucun paquet de jeu inclus. Version **121** publiée sur le Site existant, statut terminal `succeeded`, source `0aaa6d213cbb23ebef565e6bad8f38d6a21e11bc`. Archive normalisée conservée par Sites : SHA-256 `4b10613091aa2eeaf6805f3cd3dd8684ec3b54e2e8ef70da86a59adff88e9223`. Le téléchargement reste 0.1.12 et annonce explicitement qu'il précède C7-08.

Le contrôle Markdown global a été exécuté et échoue sur le nouveau `README.md` du chantier Studio concurrent `documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes`, supérieur à 256 KiB. Ce fichier reste inchangé par C7-08 et exclu du commit ; aucune dérogation n'est appliquée. C7-08 ne crée aucun Markdown et modifie seulement ce plan déjà suivi. Les caches Flutter partagés du dépôt restent conservés ; seuls les clones et artefacts QA possédés sont nettoyés.

## C7-09 — Compléter l'usage contextuel des objets et la Corde Sortie 3D

**Point de départ :** la Corde Sortie existe en 2D ; `escape_rope_action.dart` refuse explicitement les cartes spatiales. L'effet d'action sémantique existe déjà : examiner ses consommateurs avant d'ajouter une autre commande.

**Fichiers et frontières :** `packages/map_gameplay/lib/src/escape_rope_action.dart`, `packages/map_gameplay/lib/src/items/player_item_use_service.dart`, `packages/map_runtime/lib/src/presentation/flame/playable_map_game_escape_rope.dart` et leur équivalent spatial existant ; métadonnées canoniques et `apps/avelune_studio/lib/presentation/features/map_workspace/map_escape_rope_settings.dart` si nécessaire ; tests `escape_rope_action_test.dart`, `playable_map_game_escape_rope_test.dart`, `map_metadata_escape_rope_test.dart`.

- [x] Définir un retour spatial sûr : destination, hauteur et arrivée navigable, conservation après Continue ; refus propre sur carte interdite, cible absente ou arrivée bloquée.
- [x] Raccorder l'usage contextuel avant l'effet normal et sa consommation, avec annulation, priorité et absence de correspondance explicites ; refuser une ambiguïté plutôt que choisir silencieusement une interception. Conserver les usages 2D existants.
- [x] Vérifier le cas Alpha, salle 312, position `(6,3)`, face nord : déclencher le secret sans téléportation ordinaire ni consommation indue, puis tester l'usage normal ailleurs et l'échec de sauvegarde. Preuve sur fixture du moteur ; intégration du secret au jeu source réservée à C7-11.

**Fermé quand :** comportement spatial et interception sont prouvés dans le runtime et configurables sans branche HGSS dans le moteur. Rattachements : FG-060, FG-062, FG-080, FG-082 ; compléter le rattachement de la capacité spatiale dans le contexte produit existant à l'exécution, sans inventer un ID FG.

### Exécution C7-09 — 10 novembre 2026

Périmètre fonctionnel vérifié : ancre spatiale fractionnaire, orientation et hauteur dérivée du terrain ; vraies entrées natives et Scene, changement d'étage, arrivée navigable et Continue. Sélection contextuelle générique avant les effets normaux, priorité unique et refus des ambiguïtés, annulation sans repli, conditions et quantité revérifiées, transaction complète et compensation après panne disque. Une Potion dont la condition contextuelle est fausse conserve sa cible Pokémon et soigne normalement. Une fermeture de session avant le writer n'écrit rien ; après succès disque, le reçu durable subsiste sans réactivation du runtime fermé.

Contrat Core, projection narrative, dépendances de ressources/Scenes, export et capabilities `gameplay.contextual-item-use@1` et `map3d.escape-rope@1` raccordés. Les anciens JSON sans règles gardent leur forme ; les anciens exports spatiaux avec métadonnées Corde restent lisibles sans leur attribuer la nouvelle capability. FG-014 complète les rattachements pour le retour spatial ; aucun statut global FG n'est promu.

Interface auteur : objet, Scene, case, orientation et priorité configurables dans les paramètres Déplacements/Corde. Les conditions déjà présentes sont conservées. Action `map.update_metadata`, sélection de catalogue bornée et protection des références Scene ; ajout explicite de groupes par `map.library.reorganize` avec `workshopScope:true`, sans déplacement/retrait ni chargement global des cartes étrangères. MCP parity : schémas et scénario réel du worker vérifiés ; PMCP085 recense 104 ressources et 472 actions, sans manque ni blocage, mais la certification transport de tout le catalogue reste incomplète.

Source réelle : trois groupes de donjon créés, sept cartes relues après mutation canonique. Caves 99/153/154 et Puits 114/177/181 autorisent la Corde ; salle Alpha 312 l'interdit conformément aux sources. Les autres données des sept cartes sont préservées. Mesures AOT des seules sauvegardes de métadonnées : 188333 à 405740 µs ; aucune certification UI/GPU ou générale Studio. Recette Alpha corrigée : case `(6,3)`, nord, flag secret `0x21B`, bloqueur natif en `(6,2)`. Le scénario moteur contrôle disparition, absence de téléportation/débit, Continue et compensation complète, y compris avatar. Le puzzle, la Scene du secret et les récompenses restent à intégrer en C7-11.

Preuves canoniques hors Git moteur : `creation/ecorcia-chapitre7-annexes/revisites/c7-09/source-metadata.json`, `verification.json` et `verification-evidence/`. Helpers maintenus : `c7_09_integrer.dart`, `c7_09_cloturer.py`, recette et tests Alpha existants. Revues indépendantes SPEC et QUALITY : PASS ; dernier défaut de ciblage du sac corrigé et six cas de non-régression passés.

Contrôles ciblés : Core 10 PASS (`contextual_item_use_rule_test.dart`, `escape_return_point_test.dart`), Gameplay 14 PASS, Authoring 68 PASS, Runtime 201 PASS avec smoke combat, contrôles complémentaires 2D/annulation/entrées/Alpha/fermeture et Potion PASS, Studio 2 PASS, host Player 14 PASS, scénario MCP réel 1 PASS et recette Python Alpha 4 PASS. `npm run check` PASS. Analyses Core/Gameplay/Distribution sans erreur ; Authoring conserve deux avertissements historiques. Analyse des trois fichiers UI concernés sans problème. Pas de hot reload d'une application appartenant à une autre session.

Limites conservées : Core complet 7132 PASS, 1 ignoré et 19 FAIL, tous les échecs reproduits dans une copie avec les fichiers Core modifiés remplacés par HEAD. Six tests de calendrier spatial observent 92 appels au lieu de 17, échec identique avec le runtime original de HEAD ; la campagne ciblée de 201 cas les exclut explicitement. Analyse Runtime globale : deux erreurs de coordonnées optionnelles dans `source_converted_starter_journey_test.dart` ; ce fichier et son modèle sont identiques à HEAD. Analyse Studio globale non verte sur les fichiers dev/tests concurrents ; seule l'erreur de présentation `civilWeekday` a été corrigée dans le fichier concerné. Suite MCP globale interrompue, non certifiée. `git diff --check` signale des espaces produits dans `map_data.freezed.dart` ; le formateur Dart laisse les trois fichiers générés inchangés. Aucun nouveau rendu GPU, parcours natif complet ou test appareil.

Sauvegarde authentique préservée, SHA-256 `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a`. Aucun commit ni export dans ce lot ; téléchargement toujours 0.1.12. Obligatoire 3/3, annexes 4/7 déclarées ; le carnet ne crédite automatiquement que 3/7, car les empreintes de revue C7-05/C7-06 des Caves manquent. Aucun crédit forcé par C7-09 ; le mécanisme d'Alpha ne clôt pas son objectif. Prochaine étape C7-10, puis C7-11.

Carnet : 29 tests PASS, `verify-site` PASS, 265 fichiers publics expurgés. Version 122 publiée, statut terminal `succeeded`, source `0b125629998d86fa79b0a3f92d5d8192502aff9e`, archive normalisée SHA-256 `7b0a63606e996b358e69d287bbee5672659a7200f92877f1e1bfa13ef2aa2cf7`. Seuls `assets/data.js` et la nouvelle preuve publique diffèrent de la source du Site 121 ; pas de paquet de jeu envoyé. Le contrôle des empreintes du Puits suit les deltas de métadonnées C7-09 sans modifier ses preuves C7-03. Publication et vérifications conservées dans `revisites/c7-09/`.

Clôture QA : aucun consommateur restant, 549985225 octets possédés retirés sans suivre les liens symboliques des copies de référence ; répertoire QA C7-09 absent, sauvegarde authentique et HEAD moteur inchangés. Les modifications concurrentes du Studio et des sprites restent en place. Hygiène Markdown globale en échec sur un nouveau Markdown du chantier Studio concurrent ; C7-09 ne crée aucun Markdown et la modification du présent plan passe `git diff --check`.

## C7-10 — Raccorder les cartes d'Alpha

**Fichiers et frontières :** cartes actuelles `ruines-alpha`, `passage-route32-ruines-alpha`, salles 113/315/323 et connexions existantes selon leurs vrais IDs ; outils `alpha_fin_preparer.py`, `alpha_fin_qualifier.py`, `alpha_fin_fixture.dart`, `alpha_fin_gameplay_test.dart` du chantier.

- [x] Repartir de la carte principale actuelle 32×64 et de ses warps ; réconcilier les IDs/raccords avec le propriétaire Alpha. Ne pas rejouer les anciennes recettes de création 35×67.
- [x] Raccorder le passage Route 32, l'extérieur et les salles nécessaires au parcours convenu, y compris la préparation native de la salle de récompenses 324 ; conserver les sorties futures et leurs restrictions, les objets complets et les supports fractionnaires natifs. L'accès secret 312↔324 reste réservé à C7-11 : ses marqueurs `scene_only` sont passifs et ciblent leur propre carte. Les warps 323-2/3 concernent Sinjoh et restent fermés ; ils ne sont pas l'accès aux récompenses Kabuto.
- [x] Parcourir aller/retour, escaliers, seuils et fosse réellement utilisés, puis sauvegarde/Continue. Requalifier les avertissements Border existants : conserver les diagnostics explicites ci-dessous, sans annoncer un contrôle formel PASS. Les chutes scénarisées et la boucle des récompenses restent C7-11.

**Fermé quand :** le circuit spatial convenu est connecté dans le jeu principal et praticable, sans régression des cartes source ni confusion entre rendu candidat et jeu intégré.

**État vérifié le 10 novembre 2026 : C7-10 fonctionnel intégré, avec limites formelles et graphiques conservées.** Rattachements FG-014 et FG-082 limités au parcours concerné. C7-09 a été commité avant ce lot : `3a05582fe0490507d4ce3a813e258a93683f89f6`. Les changements concurrents Studio et sprites sont préservés ; le commit C7-10 porte seulement sur le sélecteur Authoring, ses tests et ce plan.

Jeu principal : 27 opérations canoniques plan/apply, recette gelée SHA-256 `93a52cba7b48aa32b2d987245ae2d6f62de0f8be13029e8117694017a5e0885b`. Circuit Route 32 ↔ passage ↔ extérieur ↔ Kabuto312 et entrée323 ↔ souterrain315, avec trois warps d'escalier natifs configurés. Salle324 `ruines-alpha-nord-est-salle2` ajoutée : neuf décors entiers, trois Borders frais et sol Smart Tile natif ; aucune nouvelle ressource importée. Ses marqueurs et ceux du secret312 ne déclenchent pas de transition automatique. Puzzle, secret, quatre récompenses, Zarbi et chutes restent C7-11 ; Sinjoh reste fermé.

Préservation : 113 documents de maps avant, 114 après ; cinq documents existants modifiés uniquement pour les raccords, 108 documents existants inchangés, une salle ajoutée. Les six cartes sélectionnées normalisées hors warps sont identiques avant/après. Route32, descripteur, profil visuel et sauvegarde authentique inchangés ; SHA de cette dernière `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a`. Inventaire canonique paginé : 103 cartes. Les opérations durables mesurées de 257066 à 1233775 µs sont des opérations de construction/raccordement ; aucune certification de latence UI ou générale Studio.

Correctif Authoring : charger uniquement le groupe `escapeRopeDungeonId` de la carte sélectionnée pour valider ses propriétés. La modification de caméra échouait auparavant faute de cette définition. Le défaut a été reproduit avec le sélecteur original ; les tests couvrent première édition, répétition, réouverture, transport JSONL, groupe absent sans altération et 80 cartes/groupes étrangers volontairement illisibles. Aucune nouvelle action ou modification de contrat. MCP parity : scénario réel ciblé PASS, 28 tests de parité PASS ; catalogue de 104 ressources et 472 actions complet sans manque, certification transport globale toujours non acquise. Le worker MCP connecté refuse l'ouverture du projet (`worker.request_invalid`) ; la cause reste non prouvée, le worker frais et l'API canonique courante passent.

Contrôles : 8 tests Authoring ciblés PASS, 28 de parité PASS, un scénario MCP réel PASS, `npm run check` PASS. Trois scénarios Runtime QA et trois source PASS avec le même SHA de test : contrôleur de production, vraies entrées, aller/retour, seuils, escaliers et Continue. Fixture déclarée de navigation au spawn auteur, sans progression future ni injection après boot ; ce n'est pas un trajet depuis une sauvegarde narrative authentique. Continue utilise une vraie enveloppe sur disque puis recrée le runtime dans le même processus. Salle324 contrôlée séparément depuis une fixture future explicite, sans activation du secret ni récompenses.

Suite Authoring élargie : 93 PASS, un FAIL dans `catalog_spatial_map_mutation_test.dart`, cas `encounter background payload stays targeted with 90 foreign maps` (73 lectures pour un maximum de 71). Même échec rejoué seul et avec le sélecteur original ; non corrigé hors périmètre. Analyse Authoring complète sans erreur et deux avertissements historiques dans `gen5_battle_source_import_test.dart`. Analyse ciblée finale sans erreur, informations de style préexistantes conservées.

Huit captures natives source et huit QA réussies, images correspondantes byte-identiques. Les salles sont observées en 3D ; l'extérieur conserve des coupures/noirs de sol visibles, géométrie existante inchangée. MapHealth PASS structurel pour passage, extérieur et souterrain315 ; FAIL pour hall323 (50 `border.spatial.face_base_mismatch` identiques avant/après), INCOMPLETE pour312 et324 (une cellule `unproven` sous chaque décor de fosse, respectivement `(6,7)` et `(6,3)`). Les Borders de324 restent frais sans erreur ni avertissement. Aucun contrôle formel global PASS, aucune acceptation graphique globale, aucun parcours natif interactif complet ni preuve iPhone.

Reçus et helpers maintenus hors Git moteur : `creation/ecorcia-chapitre7-annexes/revisites/c7-10/`, `c7_10_preparer.py`, `c7_10_authoring.dart`, `c7_10_fixture_test.dart`, `c7_10_runtime_test.dart`, `c7_10_capturer.py`, `c7_10_cloturer.py`. La revue indépendante a conduit au durcissement de reprise : intention lue une seule fois, SHA gelé, empreintes des cartes et du catalogue revérifiées avant reprise. Les preuves visuelles, fonctionnelles et de préservation restent distinctes. Prochaine étape C7-11, sans nouveau crédit d'annexe Alpha ni nouvel export ; téléchargement toujours 0.1.12.

Carnet : 29 tests PASS, `verify-site` PASS ; inventaire et galerie à 103 cartes, absence de musique de324 explicitement enregistrée. Distribution de269 fichiers expurgés, sans jeu source ni sauvegarde. Site public version123 publié avec statut terminal `succeeded`, source `7fc7397925f3744061a588a9ca23302551e1c848`, archive normalisée SHA-256 `8332980b3357ee96e6c9e3d27ed3f71dd377b452ec8f3b19bd2bcdc7ea6d2a92`. Le delta public comprend les données, la galerie, la preuve C7-10 et trois captures. Aucun paquet de jeu envoyé.

Clôture QA : aucun consommateur restant, 2490345261 octets possédés retirés sans suivre les liens symboliques ; racine QA C7-10 absente. Logs et huit captures uniques conservés dans `revisites/c7-10/verification-evidence/`. Source et sauvegarde revérifiées intactes hors raccords attendus. Hygiène Markdown globale FAIL : un nouveau Markdown concurrent dépasse le budget zéro ; ce lot ne crée aucun Markdown, son diff ciblé passe `git diff --check`. Aucun processus d'une autre session arrêté. Le commit final ne contient que les trois chemins C7-10 annoncés ; aucun push moteur.

## C7-11 — Intégrer Kabuto, son secret et les récompenses

**Fichiers et frontières :** `puzzles-alpha.json`, `preparer_puzzles_alpha.py`, `puzzles_alpha_test.dart`, `alpha_fin_test.py` et tests de parcours du chantier ; définitions de puzzle/Scenes et cartes concernées via authoring. Réutiliser `runtime_image_puzzle_service.dart` et l'overlay existant.

- [x] Intégrer le puzzle Kabuto avec les pièces/orientations sourcées, les branches résoudre/quitter et la reprise persistée ; ne pas activer les quatre puzzles uniquement parce que leurs médias sont préparés.
- [x] Distinguer résolution du puzzle, ouverture du mur par Corde Sortie, quatre récompenses et les deux chutes. La salle 324 porte les quatre objets (scripts 7013–7016, flags 1128–1131) : lien natif 312 warp 1 `(6,2)` ↔ 324 warp 0 `(6,17)`, puis séquence de chute de 324 vers 313 à `(11,7)`. La salle 313 n'est pas la salle contenant les quatre objets. Recette historique corrigée. Flags distincts du secret `0x21B`, du puzzle `0x977` et de la chute `0x111` ; deux chutes indépendantes vers 315 `(27,6)`, soit `(25,6)` natif avec padding `[2,0]`.
- [x] Raccorder les rencontres Zarbi à la résolution effective ; aucune rencontre avant résolution et aucune ouverture des trois autres puzzles par commodité. Seulement A à J au niveau 5 ; refus `conditionsNotMet` avant résolution, couverture des dix formes après résolution et génération réelle des combattants avec Puissance Cachée.
- [x] Tester puzzle incomplet, grille complète mais mauvaise orientation, résolution, abandon/reprise, secret avant consommation, sac plein, collecte unique et Continue. Respecter les restrictions des chambres futures.

**Fermé quand :** accès → puzzle → chute/secret → récompense → sortie fonctionne sur les vraies cartes ; aucune récompense ou rencontre n'est ouverte prématurément. Rattachements : FG-082, FG-083, FG-088, FG-101, FG-108.

**État vérifié le 10 novembre 2026 : C7-11 fonctionnel intégré dans son périmètre, qualification globale du chapitre réservée à C7-12.** Les statuts globaux de la roadmap ne sont pas promus : FG-082/083 restent PARTIAL, FG-088/101/108 restent TODO. Aucun commit, push ou export du dépôt moteur effectué pour ce lot ; travail concurrent Studio/UI/combat préservé.

Jeu principal : 48 opérations canoniques plan/apply toutes `applied`, intention gelée SHA-256 `2ccc4677c4f1cc4b8b394322a256817b22a7c0076481b6d6c2f2d1c81c6c64e6`. Trois cartes existantes modifiées (312, 324, 315), chambre des inscriptions 313 ajoutée ; 111 des 114 documents de cartes existants identiques. Descripteur, profil visuel et sauvegarde authentique inchangés ; SHA-256 de cette dernière `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a`. Supports physiques natifs ciblés sous la tablette et les trous ; blocage du mur lié à une entité propriétaire conditionnelle pour désactiver ensemble rendu et collision après le secret. Aucune collision moteur affaiblie.

Secret : Corde Sortie utilisée en 312 `(6,3)`, face nord ; ouverture sans débit ni téléportation, compensation complète à la panne et reprise persistée. Boucle 312↔324, quatre collectes uniques puis 324→313→315 vérifiées séparément de la résolution Kabuto→315. Objets : Poudre Soin, Poudrénergie, Baie Oran et Baie Pêcha, quantité 1 chacun. La collecte est qualifiée ; les poudres restent sans usage activé faute de coût amer en amitié, les deux baies sont utilisables manuellement mais leurs effets automatiques tenus ne sont pas activés. Les autres puzzles, formes futures et Sinjoh restent fermés.

Correctif moteur limité à `spatial_gameplay_events.dart` et au test de session existant : synchroniser la base transactionnelle à la position courante avant l'usage contextuel. Avant correction, une panne après marche au mur remettait le joueur au spawn ; RED 3 PASS/1 FAIL, puis GREEN 4 PASS avec/sans marche et avec/sans panne. Aucun changement de format ni de règle de consommation. MCP parity: N/A pour ce correctif Runtime ; contenu créé par les actions canoniques existantes. Le MCP connecté a rouvert la source et relu les quatre cartes avec leurs révisions, puis fermé son workspace.

Vérifications : `c7_11_contract_test.dart` 3 PASS sur QA puis 3 PASS sur source ; `c7_11_runtime_test.dart` 4 PASS sur QA puis 4 PASS sur source via le superviseur, descendants restants `[]`. Tests Runtime de fumée et interception contextuelle 9 PASS ; host golden slice 14 PASS. Ces parcours utilisent une fixture de navigation déclarée et le contrôleur de production ; Continue écrit puis recharge le disque après recréation du runtime dans le même processus. Le cas sac plein déclare une capacité médecine de 1 occupée par une Potion. La préparation des dix combattants Zarbi n'est pas une preuve de combat rendu ou de capture. Analyse des deux fichiers moteur : zéro erreur, 22 informations historiques. Analyse Runtime globale : deux erreurs préexistantes `int?` dans `test/source_converted_starter_journey_test.dart:275`, fichier identique à HEAD ; 409 diagnostics au total. `git diff --check` ciblé PASS.

Cinq captures statiques du moteur natif, identiques entre QA et source ; chambre 313, récompenses et tablette observées. Coupures/noirs du sol conservés, aucune acceptation graphique globale ni preuve iPhone. Contrôle formel : 312/324/313 `incomplete` pour `map.ground.unproven`, hall 323 `fail` avec ses 50 diagnostics Border préexistants ; aucun PASS global annoncé. Musique de 313 non configurée et enregistrée dans le carnet. Revue indépendante sans P1/P2 prouvé sur le correctif, la topologie, les preuves et les garde-fous de clôture.

Helpers et reçus maintenus hors Git moteur dans `creation/ecorcia-chapitre7-annexes/` : `c7_11_preparer.py`, `c7_11_authoring.dart`, `c7_11_contract_test.dart`, `c7_11_fixture_test.dart`, `c7_11_runtime_test.dart`, `c7_11_capturer.py`, `c7_11_cloturer.py` et `revisites/c7-11/`. Le carnet conserve Alpha `pending`, obligatoire 3/3, annexes 4/7 déclarées mais 3/7 créditées automatiquement ; aucune preuve des Caves réparée hors périmètre. Téléchargement toujours 0.1.12 antérieur à ce lot. Prochaine étape C7-12, puis livraison C7-13.

Carnet : 29 tests PASS, `verify-site` PASS ; inventaire canonique à 104 cartes, distribution expurgée de 273 fichiers. Site public version 124 publié, statut terminal `succeeded`, source `c13406267ced74fa696a29777c5385c1cf4725bd`, archive normalisée SHA-256 `fd09cd0b107ef71209b6c1aba38993ddf2c84a294dd972263e4fbddb28dd0876`. Delta public limité aux données, à la galerie, à la preuve C7-11 et à trois captures. Aucun paquet de jeu envoyé. Hygiène Markdown PASS sans nouveau Markdown.

Clôture QA : aucun consommateur restant ; cinq captures uniques et journaux utiles conservés dans `revisites/c7-11/verification-evidence/`, puis 2 256 346 565 octets temporaires supprimés sans suivre les symlinks. Racine QA absente ; empreintes source et sauvegarde authentique revérifiées avant suppression. État Git relevé : 162 chemins modifiés ou non suivis, dont les deux fichiers Runtime et ce plan pour C7-11 ; les autres changements ne sont pas attribués au lot et sont préservés.

### Compléments C7-11 — Poudres, baies tenues et défauts d’Alpha

État du 10 novembre 2026 : les compléments demandés sont implémentés et intégrés au jeu source. L’état courant des objets et des cartes est décrit ici ; le dossier graphique complet et la qualification du chapitre restent C7-12. Rattachements limités : FG-050, FG-060, FG-062, FG-063 et FG-072 ; aucun statut global de la roadmap n’est promu.

Poudrénergie restaure 50 PV ; Poudre Soin soigne les statuts majeurs et la confusion. Les deux retirent 5/5/10 points d’amitié selon les paliers HGSS, après application effective du soin. Les refus ne débitent rien. Les mêmes définitions sont activées hors combat et en combat, avec persistance et traitement de l’identité du Pokémon dans les combats doubles. Le formulaire Studio configure ces champs sans JSON. Oran tenue soigne automatiquement 10 PV à la moitié des PV ou moins ; Pêcha tenue soigne poison et toxicité, avec consommation unique et retour dans la sauvegarde de l’équipe.

Les contrats d’objet restent optionnels et les anciens JSON restent lisibles. L’export déduit deux capabilities : `items.friendship-loss@1` et `items.held-oran-pecha@1`. Le Player les annonce ; un ancien host refuse proprement un paquet qui les demande. Vérifications ciblées : Core 57 PASS, Gameplay 39 PASS, Battle 62 PASS puis six cas de statut/confusion, Runtime 46 PASS, Studio trois PASS, Authoring 16 PASS et transport API/JSONL 45 PASS, Distribution 12 PASS, host 14 PASS. Un processus MCP neuf contrôle les trois actions sémantiques d’objet et la réouverture à froid : un PASS ; vérification et build TypeScript réussis. La parité globale n’est pas certifiée : une preuve Studio supprimée dans le travail concurrent fait échouer son contrôle ; le timeout distinct a passé seul. Analyse Runtime globale : les deux erreurs `int?` historiques du test du starter restent signalées.

Alpha : trois décors de fosse retrouvent leur pose native à Y `.0625`, après un réancrage automatique antérieur erroné. Les supports physiques Y 2 restent présents. Des franges de sol Smart Tile natives ferment les débords des couronnes ; cinq profils locaux utilisent 95 variantes de modules complets, soit 124 placements, avec les faces intérieures manquantes et des normales vérifiées. Les modèles et profils partagés d’origine restent intacts ; géométrie, semences, ouvertures, hauteurs et positions des placements sont conservées.

L’extérieur retrouve 42 Borders source, 517 placements et six appuis de fond de caniveau. La berge générique partielle de dix modules est remplacée par ses deux profils source complémentaires. Les fragments hors carte sont exclus avec leurs phases de séquence originales, sans raccorder artificiellement les deux spans de la rive ouest. Les parois procédurales noires sont désactivées sur cette carte désormais dotée de ses reliefs natifs. Un appui supplémentaire couvre les 14 unités carrées de sol forestier peint mais auparavant sans support ; chaque empreinte de terrain existante est soustraite et les cellules d’eau sont exclues. Aucun arbre, décor, blocage, warp ou élément narratif n’est déplacé.

196 opérations canoniques `applied` sur la source, réparties en recettes gelées et reçus de reprise. Contrôle sémantique strict des cartes après normalisation de l’ordre des instances : seuls les ajouts et remplacements déclarés diffèrent. Les 115 documents de cartes sont conservés ; 111 sont identiques. Descripteur, profil visuel et sauvegarde authentique `67ec65c4ce3e15d8e3cf1e41a97d1c74cab085fda319d0a14028a057e48dad0a` restent inchangés. Huit contrats intégrés passent sur la source.

Rendus natifs statiques : 18 vues finales, complétées par 38 vues de scan sur quatre cartes. Les scans QA/source ont les mêmes ratios. Les trois salles ne présentent aucune ouverture détectée ; les deux ouvertures internes sous les arbres disparaissent après l’appui forestier. Le scanner conserve cinq pixels enfermés par la silhouette des arbres, projetés au-delà du bord nord : ils ne sont pas crédités comme un résultat numérique nul. Les trois fosses restent formellement `unproven`, avec un fond GLB opaque vérifié à neuf points. Le hall passe de 50 diagnostics de Border à zéro, après correction des sondes de bord inclusif et prise en compte du sol Smart Tile réellement dessiné. Cinq contacts AABB de l’extérieur restent `unknown` : la revue des boîtes de tous les triangles établit une séparation strictement positive, sans intersection réelle ; les cinq vues ont été inspectées.

Limites : aucun parcours natif interactif complet, aucune validation iPhone, aucune acceptation graphique globale ni dossier complet d’échelle, de collisions et de canevas agrandi. Le renderer release rencontre une erreur AOT Flutter `_Rect` ; les preuves utilisent le host debug isolé. Aucune certification de performance Studio ou appareil. Le carnet conserve Alpha `pending` et le téléchargement 0.1.12 ; aucun nouvel export, commit ou push du dépôt moteur. Les reçus et helpers sont maintenus dans `creation/ecorcia-chapitre7-annexes/revisites/c7-11-complements/` et ses scripts associés. Publication du carnet et fermeture QA consignées dans le reçu de vérification de ce complément.

Parcours finaux sur source : accès Route 32 ↔ passage ↔ extérieur ↔ hall ↔ souterrain ↔ Kabuto, avec trois sauvegardes/Continue, un PASS ; puzzle/secret/récompenses/chutes, quatre PASS. Le helper d’accès attend explicitement la disponibilité des entrées pendant le chargement asynchrone ; son ancienne attente trop courte a été conservée comme échec de harnais, sans correctif moteur ajouté. Descendants des deux harnais : `[]`. Carnet : 29 PASS, vérification PASS, distribution publique de 280 fichiers sans projet ni paquet de jeu ; Site public version 125, statut `succeeded`, source `46e1c7883d0f7a4b4393eb4619271fe82d68acfe`, archive normalisée SHA-256 `181fc8572f42b8e8cc392b115da6413d55d0d623cb65fdb25252b7b4d19d6e59`.

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
