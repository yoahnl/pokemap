# Consolidation de la caméra de combat 3D

## Périmètre et état initial

Plan de référence : audit d’Astra du 31 octobre 2026, fourni par Yoahn dans `AUDIT_ET_TICKET_CAMERA_3D.md`, référence `ba6599ccdb367278d4667d6b62ddd48008364117`. Objectif autorisé : implémenter l’ensemble du plan A–F, avec compatibilité des futurs visuels composés. Le rigging lui-même reste hors périmètre.

Branche initiale : `main`. HEAD initial : `76d7e510c2823b4318fa1a197fd38e1314167f37`. Les sources caméra sont à réconcilier avec l’audit avant mutation. Les changements simultanés de visibilité conditionnelle dans map_core, map_authoring, map_distribution et l’exploration runtime sont préservés. Aucune opération Git d’écriture n’est autorisée par ce chantier.

Décision D4 de Yoahn : vitesse et réduction des mouvements séparées ; vitesse rapide conserve la caméra, réduction des mouvements ne modifie pas la vitesse. Préserver le comportement des anciens réglages tant qu’ils ne sont pas modifiés.

Invariants : composition et UI BW2 approuvées, grille paysage 2 × 2, caméra finie, HUD masqués pendant la séquence et retour avant PV, mouvements latéraux à l’attente, niveau du HUD synchronisé, aucune modification des règles métier ou sauvegardes. Les sprites statiques restent pris en charge. Les visuels composés doivent pouvoir fournir une enveloppe stable et des ancrages locaux sans imposer un squelette maintenant.

## Suivi des lots

| Lot | Périmètre | État / preuve |
| --- | --- | --- |
| A | Référence, caractérisation, backend effectif | Baseline239tests/captures initiales et baseline physique HEAD170 borné acquis ; versions, sources et backend consignés |
| B | Pose unique, courbes, commandes historiques, diagnostics | Implémenté ; RED courbes/diagnostics/cancel puis GREEN154 intégration ; SPEC/QUALITY conformes ; rendu GPU ponctuel acquis |
| C1 | Intention et reflow | Implémenté ; RED reflow/identité, GREEN185 dont40C1 puis390intégrés ; SPEC/QUALITY et contrôles natifs de rotation/FX acquis, limites de matrice explicites |
| C2 | Cadrage et enveloppes stables | Implémenté/revu ; halo puis overview doubles corrigés avec RED exact ; GREEN116 ciblés/390runtime ; GPU2/GPU4 et tailles lisibles confirmés sur iPhone portrait/paysage |
| C3 | Espaces et ancrages FX | Implémenté ; RMXP/Balls/familles SDK raccordés ; RED10/GREEN14 puis régression148 ; QUALITY approuvée ; rotation d’un projectile contrôlée en natif |
| D1 | Groupes imbriqués | RED +4/-12 puis GREEN 63 ; revues SPEC et QUALITY sans défaut bloquant |
| D2 | Domaine numérique et clipping | Implémenté ; RED7 + frontières + menus ; GREEN27 runtime /3 renderer /2 menus ; SPEC/QUALITY conformes |
| D3 | Horloge et reprise | Dette, invalidation et dispatch bornés ; GREEN33 runner/horloge ; SPEC/QUALITY approuvées ; preprocessing proportionnel au plan hors budget |
| D4 | Vitesse et confort séparés | Préférences/transport/hosts/UI branchés ; GREEN61UI/24reprise/390intégrés ; SPEC/QUALITY favorables ; contrôle natif vitesse/caméra et réduction distinctes acquis |
| D5 | Layout inatteignable | Bloc mort de325 lignes retiré ; suite combinée GREEN156 ; SPEC/QUALITY conformes |
| E1 | GPU, secours et cycle de vie | Implémenté ; tests de frame complète/repli atomique verts ; SPEC/QUALITY favorables ; vrai GPU et repli transitoire de rotation puis retour GPU acquis |
| E2 | Textures, ressources et mémoire | Implémenté ; swap pendant import et texture par défaut corrigés ; GREEN36 ciblés puis92renderer ; QUALITY approuvée ; mémoire GPU physique encore non certifiée |
| E3 | Ordre des couches | Implémenté ; masques doux, ordre explicite et fallback atomique ; SPEC/QUALITY favorables ; scènes natives singles/doubles relues, limites de déformation et futurs modèles déclarées |
| F | Régression, preuves natives et appareil | Livré pour revue :390runtime/92renderer ciblés/14host ; GPU2/GPU4 portrait/paysage et baseline/profile physiques ; suite renderer complète813PASS/1FAIL préexistant ; apps/environnements QA supprimés |

Lots FG concernés par proximité : FG-048 présentation post-combat, FG-052 remplacement et FG-053 parité. Aucun statut mécanique n’est modifié par ce rapport.

## Environnement de validation détenu

Root unique : `/Users/karim/Library/Caches/AveluneQA/battle-camera-consolidation`. Usage : logs, suivi des PIDs, hôte natif minimal, captures de référence et de correction. Les tests utilisent `run-owned.py`, qui relève l’identité exacte des descendants et ne termine que les harnais appartenant au run. Aucun projet source ni sauvegarde n’y est modifié. Les assets HeartGold éventuellement lus restent en lecture seule.

Condition de suppression : arrêter les processus détenus et connexions, conserver les reçus et captures sélectionnées utiles à ce rapport, vérifier les consommateurs puis supprimer les environnements/builds et vérifier leur absence. Aucun autre root temporaire n’est autorisé.

## Audit et validation

Les preuves de tests, builds, vues natives, profils et compatibilité sont distinctes. Aucun profil physique n’est acquis par une capture macOS.

### Baseline A

Depuis `packages/map_runtime` :

```text
python3 /Users/karim/Library/Caches/AveluneQA/battle-camera-consolidation/run-owned.py baseline flutter test test/battle_perspective_camera_test.dart test/battle_stage_camera_projection_test.dart test/battle_camera_sequence_test.dart test/battle_camera_rig_test.dart test/battle_scene_layout_test.dart test/battle_overlay_component_test.dart test/battle_turn_animation_planner_test.dart test/battle_animation_runner_test.dart --reporter expanded
00:02 +239: All tests passed!
exit 0 ; runner55207 ; neuf descendants suivis ; aucun harnais résiduel
```

Hôte QA : vraie interface `PlayerBattleOverlay`, scène `BattleOverlayComponent` et `BattleStage3DComponent`, sprites et fond HeartGold lus sans mutation. Build macOS debug réussi, Metal/Impeller annoncé, puis backend et prise en charge de l’acteur vérifiés dans la frame. Captures sélectionnées sous `evidence/camera-consolidation/` : `baseline-portrait-rest.png`, `baseline-portrait-focus-quarter.png`, `baseline-rotation-mid-focus.png`, `baseline-landscape-return.png`. Les JSON détaillés temporaires sont dans le root QA. Les animations du chrome Flutter seules sont réduites ; caméra/combatants à échelle1.

Le premier harness publiait `setState` pendant le build du GameWidget lors du resize. Correction du harness : publication différée par microtask, puis hot restart et reconnexion Marionette. Les captures sélectionnées ont `errors: []`. Ce défaut du harness n’est pas attribué au produit. L’application QA a ensuite été arrêtée et Marionette déconnecté.

Un iPhone15 Pro physique appairé est annoncé disponible par `xcrun devicectl list devices`. Cela ne prouve encore ni lancement ni profil.

### D1 — Groupes

Fichiers : `battle_turn_animation_planner.dart`, `battle_turn_animation_planner_camera_groups_test.dart`. Détection récursive de focus/move et résolution structurelle des focus non explicites ; scène conservée. Injection optionnelle de recette au constructeur, défaut inchangé. Aucun aplatissement du plan exécuté.

```text
flutter test test/battle_turn_animation_planner_camera_groups_test.dart --reporter expanded
RED comportemental : 00:00 +4 -12: Some tests failed. ; exit1
flutter test test/battle_turn_animation_planner_camera_groups_test.dart test/battle_turn_animation_planner_test.dart --reporter expanded
GREEN : 00:00 +63: All tests passed! ; exit0
dart analyze lib/src/presentation/flame/battle_turn_animation_planner.dart test/battle_turn_animation_planner_camera_groups_test.dart
No issues found! ; exit0
```

Runs suivis73812/74765, aucun harnais restant. Une compilation intermédiaire du seam, avant RED comportemental, était incomplète ; ses appels ont été migrés avant la preuve RED utile. Le test partagé D3 et un hot restart ont croisé cet état intermédiaire ; ils ont été relancés après annonce du fichier compilable. Aucun succès n’est déduit de cet échec transitoire.

### D3 — Horloge

Fichiers : `battle_overlay_component.dart`, `battle_scene_clock_test.dart`. Une dette conserve le temps non consommé, avec au plus32 sous-pas par appel. Valeurs non finies/négatives refusées, dette vidée aux transitions. Une révision invalide aussi la boucle en cours lorsqu’un callback remplace ou retire la présentation ; aucune ancienne dette ne s’applique au nouveau plan.

```text
flutter test test/battle_scene_clock_test.dart --reporter expanded
RED : 300 updates enfants au lieu de1..32 ; plan déjà terminé au lieu de rester actif
flutter test test/battle_scene_clock_test.dart test/battle_camera_sequence_test.dart --reporter expanded
GREEN après correction réentrante : 00:00 +7: All tests passed! ; exit0
```

Couverture annulation/retrait ajoutée après ce GREEN, à relancer avec la validation combinée. Limite restante : le plafond de sous-pas ne plafonne pas encore le dispatch d’une suite arbitrairement longue d’accents instantanés du runner ; ce point ne sera pas déclaré clos par cette seule preuve.

### D5 — Layout

`effectivePlacement` vaut detached, end éligible, ou bottom. Le premier groupe end/detached retourne, puis la composition bottom retourne. Le bloc suivant est inatteignable. Retrait de325 lignes de calcul historique et remplacement du dernier test conditionnel par le bloc final inconditionnel. Helpers des chemins actifs conservés. Les tests de référence du layout sont ceux du baseline239 ; ils repassent dans la suite combinée ci-dessous.

### D2 — Domaine logique commun

Fichiers : `map_render_3d/lib/battle_projection_contract.dart`, `battle_stage_camera.dart`, `battle_stage_3d.dart` ; runtime `battle_perspective_camera.dart`, `battle_perspective_ground_component.dart`, `battle_stage_3d_component.dart` ; tests `battle_camera_numeric_contract_test.dart`, `battle_stage_camera_numeric_test.dart`, cas collections de `battle_camera_authority_test.dart`.

Une seule définition des profondeurs admissibles (`.01 < depth < 1000`) et du calcul en double depuis la pose originale. Les helpers GPU et CPU partagent cette classification ; la matrice/raster GPU reste en Float32 et ne prouve pas une identité de pixels infinitésimalement près des plans. Les gardes refusent les poses dégénérées avant mutation et conservent le viewport valide lors d’un resize transitoire. Les API `try*` propagent l’absence de projection/sol ; les wrappers stricts refusent explicitement le domaine invalide. Le renderer abandonne une frame refusée avant synchronisation.

Revues SPEC ont trouvé puis fait corriger : seuil GPU testé sur `clip.w` Float32 au lieu du domaine logique partagé ; booléen de frame ignoré par le renderer ; appel strict de l’overlay pour l’ennemi absent des menus paysage. Les deux menus ont donné `StateError` en RED puis passent après culling explicite par projection nullable et rectangle vide. La preuve du refus natif avant sync/raster reste à compléter dans E1/F.

```text
flutter test test/battle_camera_numeric_contract_test.dart
RED initial : sept échecs comportementaux
flutter test test/battle_camera_numeric_contract_test.dart --plain-name 'CPU and GPU classify adjacent double values at both depth planes equally'
RED frontière : GPU helper depth0.0100000001
flutter test test/battle_camera_numeric_contract_test.dart test/battle_perspective_camera_test.dart test/battle_stage_camera_projection_test.dart
GREEN : 00:00 +27: All tests passed! ; exit0
flutter test test/battle_stage_camera_numeric_test.dart
GREEN renderer : 00:00 +3: All tests passed! ; exit0
flutter test test/battle_camera_authority_test.dart --plain-name 'landscape collection' --reporter expanded
RED deux StateError ; GREEN deux réussites ; exit0
```

Analyses numériques runtime : `No issues found!`. Renderer, en incluant `battle_stage_3d.dart` : trois warnings `invalid_use_of_internal_member` préexistants sur load/mount/finalizeRemoval, vérifiés dans HEAD. Aucun ignore ajouté.

### B — Une autorité animée

`BattlePerspectiveCamera` porte seule la pose et la progression. `BattleCameraEasing` nomme la courbe `legacyTwoSlope`, conserve celle-ci pour focus/reset et permet linear/easeOut pour les commandes explicites. `BattleStageCamera` demeure adaptateur passif. Le remplacement de plan annule la caméra, y compris pendant un retour dont l’objectif était déjà home. Toute nouvelle commande explicite applique sa durée et sa courbe. Le rig historique et son test ont été supprimés après inventaire de tous les usages ; ses invariants utiles sont transférés vers la caméra effective.

Diagnostics : pose effective immutable, activité dès le départ du mouvement, projection du slot actif réellement rendu, y compris en doubles ; scale0 si l’acteur est masqué ou hors domaine. Deux revues SPEC successives ont trouvé les cas cancel-vers-home puis diagnostic doubles ; leurs RED dédiés ont été observés avant correction. SPEC et QUALITY finales conformes.

```text
flutter test test/battle_camera_authority_test.dart --reporter expanded
RED : quatre échecs sur courbes, ancien diagnostic et remplacement de plan
flutter test test/battle_camera_authority_test.dart --name 'cancel during a return|activity is true' --reporter expanded
RED : deux échecs attendus
flutter test test/runtime_doubles_overlay_test.dart --plain-name 'camera diagnostics use' --reporter expanded
RED : échelle diagnostic1.032211 vs projection effective1.026315
flutter test test/battle_camera_authority_test.dart test/runtime_doubles_overlay_test.dart test/battle_overlay_component_test.dart test/battle_scene_clock_test.dart test/battle_perspective_camera_test.dart test/battle_camera_numeric_contract_test.dart test/battle_stage_camera_projection_test.dart test/battle_camera_sequence_test.dart --reporter expanded
GREEN : 00:05 +154: All tests passed! ; exit0 ; runner25186 ; neuf descendants suivis ; aucun résiduel
```

Une tentative `--plain-name` contenant un `|` n’avait sélectionné aucun test (exit79) ; elle n’est pas comptée comme RED. La commande a été corrigée vers `--name` avant la preuve ci-dessus. Une tolérance1e-4 est utilisée pour les offsets Vector2 Float32, distincte de la pose en double. Un test existant avançant1.9s d’un coup draine désormais explicitement la dette D3 par quatre ticks0 ; la durée totale attendue reste inchangée.

Validation native : build macOS debug réussi ; hot reload réussi ; scène Metal/Impeller et acteur GPU confirmés ; repos portrait, focus, retour paysage avec `errors: []`. Captures `b-portrait-rest.png`, `b-portrait-focus.png`, `b-landscape-return.png`. Les captures initiales de baseline peuvent précéder la stabilisation de négociation du layout dans le harness ; ne pas les présenter comme une comparaison pixel-perfect au même layout sans vérifier ses paramètres. La validation de rotation reflow n’est pas encore acquise : C1 reste TODO. Application arrêtée et Marionette déconnecté après ces captures.

### D4 — Contrat indépendant

`battle_motion_policy.dart` et son test définissent `playbackSpeed`, `reducedMotion`, `effectIntensity` indépendants. Validation réelle en release par branches, vitesse positive finie, intensité finie0..1. Seul l’adaptateur nommé legacy conserve l’ancien motionScale. RED compilable6réussites/4échecs ; GREEN10tests ; analyse `No issues found!` ; SPEC puis QUALITY conformes. Matrice48combinaisons vérifiée par revue. Aucun raccordement préférences/overlay encore réalisé : D4 n’est pas clos.

### Validation combinée et état intermédiaire

```text
flutter test test/battle_scene_clock_test.dart test/battle_turn_animation_planner_camera_groups_test.dart test/battle_turn_animation_planner_test.dart test/battle_scene_layout_test.dart test/battle_camera_numeric_contract_test.dart test/battle_perspective_camera_test.dart test/battle_stage_camera_projection_test.dart test/battle_camera_sequence_test.dart --reporter expanded
00:03 +156: All tests passed! ; exit0 ; runner95301 ; neuf descendants ; aucun résiduel
```

Analyse des dix sources/tests B/D actuels : exit0, quatre infos `prefer_initializing_formals` préexistantes dans l’overlay, aucune erreur ni warning. Les suites plus larges et le profil physique de F restent à exécuter après C/E.

`.gitignore` : exception limitée à ce rapport et à son dossier de preuves, pour qu’ils restent versionnables conformément à AGENTS. Aucun autre domaine débloqué. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` échoue encore à cause de deux Markdown ignorés de chantiers parallèles (`avelune_player/plans/...install-library-launch-perf.md`, `heartgold/audit-cartes-johto-2026-10-31.md`) ; trois nouveaux Markdown vus globalement pour budget1. Aucun override élargi ni modification de ces documents.

Root QA retenu pendant le chantier actif : environ1.2G au point de contrôle, hôte arrêté, aucun harnais détecté restant. Il appartient exclusivement à ce chantier et sera réutilisé pour C/E/F puis supprimé après conservation des preuves utiles. SSD mesuré séparément : environ78GiB libres ; ces chiffres incluent les écritures parallèles et ne sont pas des gains revendiqués.

Prochaine étape concrète : tests RED de C1, intention de focus slot/occupant et reflow sans remise à zéro de la progression ; ensuite enveloppes et ancrages FX. E1/E2/E3, intégration D4, dispatch instantané D3, compatibilité et profil physique restent ouverts. Objectif global non terminé.

## Deuxième point de contrôle — C1, D3 et intégration D4

Ce point remplace les prochaines étapes du point intermédiaire précédent. L’objectif complet A–F reste actif, aucune clôture globale ni écriture Git.

C1 : intention conservée par slot, lineup et identité du Pokémon réellement affiché. La destination est recalculée sur reflow ; le temps, la durée et le reste de la courbe sont conservés. KO, swap et disparition invalident l’intention. La revue SPEC a trouvé une identité mixte ancien affiché/nouvel entrant ; RED39réussites/1échec sur `player_1` attendu contre `player_2`, puis correction current/previous selon lineup affichée. QUALITY approuvée. Quarante tests C1 incluent remplacement réel, disparition, safe area, panneaux, singles/doubles et retours.

```text
flutter test test/battle_camera_reflow_test.dart test/battle_camera_authority_test.dart test/battle_camera_numeric_contract_test.dart test/battle_stage_camera_projection_test.dart test/battle_perspective_camera_test.dart test/battle_overlay_component_test.dart test/runtime_doubles_overlay_test.dart
00:04 +185: All tests passed! ; exit0 ; runner83721 ; huit descendants ; reaped[]
```

D3 : le runner admet au plus256 unités par appel, partagées sur l’appel complet de l’overlay. Une admission de phase inclut au plus son callback direct ; notification ordinaire séparée, notification finale incluse dans l’admission terminale. Trente-deux sous-pas enfants maximum. La normalisation du plan, la construction et le tri stable du calendrier restent proportionnels au contenu et hors du budget de dispatch ; aucune certification de latence totale ne découle de ce plafond. Le curseur conserve les cues et la dette se draine avec `update(0)`.

RED du runner : dispatch1024 au lieu de256 maximum, zéro-attentes non bornées et ConcurrentModificationError lors d’annulation/remplacement. GREEN129 runner/overlay avant intégration complète. SPEC a ensuite trouvé le contournement par remplacement depuis un enfant après200cues déjà dispatchés. Le scope `withWorkBudget()` englobe désormais enfants et `start()` réentrant. Test concret :200 anciens sons puis1024nouveaux, au plus256 dans le premier appel, ordre exact sans doublon et aucune ancienne dette réinjectée. SPEC puis QUALITY approuvées.

```text
flutter test test/battle_scene_clock_test.dart test/battle_animation_runner_budget_test.dart test/battle_animation_runner_test.dart --reporter expanded
00:00 +33: All tests passed! ; exit0 ; runner236 ; quatre descendants ; reaped[]
```

D4 : champ optionnel `battleMotion` dans PlayerPreferences et snapshot runtime, codecs persisté/compagnon, comparateur du coordinateur, hôtes2D/spatial et contrôle live raccordés. Champ absent omis à la réécriture d’anciennes préférences. Ancien hôte2D conserve son couplage vitesse/caméra ; ancien hôte spatial reste à vitesse1. Les nouveaux contrôles vitesse, intensité et réduction n’altèrent pas ce comportement avant édition explicite. Réduction système appliquée au rendu sans modifier les valeurs sauvegardées. Les effets décoratifs en cours peuvent être neutralisés sans supprimer le délai du runner ; transitions sémantiques KO/switch/materialize conservées.

La première revue D4 a trouvé : nouveaux guards effets appliqués à tort aux anciens callers, toggle affichant la valeur globale plutôt que la policy explicite, reset comparant une policy explicite à null. Corrections ciblées et tests ajoutés ; nouvelle revue attendue. L’hypothèse de crash du slider hors plage reste à requalifier : la primitive clampait déjà sa valeur affichée ; les tests .25 et4 vérifient l’ouverture sans réécriture. Le hitflash reçoit une intensité interpolée avec défaut1 conservé. La preuve native et la revue finale D4 restent ouvertes.

```text
flutter test test/player/battle_motion_preferences_test.dart test/player_localizations_test.dart --reporter expanded
00:01 +12: All tests passed! ; exit0 ; runner82658 ; trois descendants ; reaped[]
flutter test test/battle_motion_overlay_test.dart test/battle_motion_policy_test.dart test/battle_camera_sequence_test.dart --reporter expanded
00:01 +15: All tests passed! ; exit0 ; runner82659 ; quatre descendants ; reaped[]
flutter test test/player/menu8_options_test.dart test/player/battle_motion_preferences_test.dart --reporter expanded
00:24 +58: All tests passed! ; exit0 ; runner85369 ; trois descendants ; reaped[]
```

Les suites élargies D4 et C2 sont en cours ; leurs commandes ne sont pas présentées comme vertes avant résultat terminal. Un défaut de compilation transitoire provenant du chantier concurrent `map_authoring/event_actions.dart` a empêché une passe ; aucune correction hors scope effectuée. Après disparition de l’appel concurrent incomplet, les suites ciblées repassent. Aucun résultat compilant un état intermédiaire n’est assimilé au résultat final.

Sources supplémentaires : `battle_animation_runner.dart`, `battle_motion_overlay_test.dart`, `battle_motion_preferences_test.dart`, `runtime_player_host.dart`, `runtime_companion_presentation_codec.dart`, `runtime_player_coordinator.dart`, `playable_map_game.dart`, `spatial_battle_runtime.dart`, `spatial_exploration_game_session_runtime.dart`, `player_preferences.dart`, `runtime_player_options.dart`, `player_options_strings.dart`, tests existants `menu8_options_test.dart`, `runtime_player_preferences_apply_test.dart`, `spatial_battle_runtime_test.dart`. Les zones concernent uniquement préférences et présentation, aucune modification de sauvegarde/projet.

### D4 — Revue finale et corrections de rendu

SPEC puis QUALITY ont trouvé et fait corriger des régressions que les premiers tests verts ne couvraient pas : teinte à intensité0 rendant le Pokémon transparent (alpha0 au lieu1), compression réduite passant delta1 au lieu0 (échelle1.7071067811865475 au lieu1). RED réel dans `d4-quality-red2`, puis correction du facteur de mélange décoratif séparé de la couleur et neutralisation du delta. L’intensité live actualise les teintes et flashes actifs sans redémarrer leurs durées ; les silhouettes et matérialisations sémantiques restent conservées. Le glissement d’introduction déjà lancé poursuit volontairement sa révélation ; ses étapes ne sont pas annulées.

```text
flutter test test/battle_motion_overlay_test.dart test/battle_motion_policy_test.dart test/player/runtime_player_preferences_apply_test.dart test/spatial_battle_runtime_test.dart test/battle_scene_clock_test.dart --reporter expanded
06:31 +59 ~1: All tests passed! ; exit0 ; runner9051 ; six descendants ; reaped[]
flutter test test/player/menu8_options_test.dart test/player/battle_motion_preferences_test.dart --reporter expanded
00:10 +61: All tests passed! ; exit0 ; runner30167 ; trois descendants ; reaped[]
flutter test test/battle_motion_overlay_test.dart test/battle_scene_combatant_component_animation_test.dart test/battle_motion_policy_test.dart test/player/runtime_player_preferences_apply_test.dart --reporter expanded
00:01 +30: All tests passed! ; exit0 ; runner51525 ; cinq descendants ; reaped[]
flutter test test/battle_motion_overlay_test.dart test/battle_scene_combatant_component_animation_test.dart test/player/runtime_player_preferences_apply_test.dart --reporter expanded
00:01 +21: All tests passed! ; exit0 ; runner56097 ; quatre descendants ; reaped[]
```

Le dernier run couvre aussi teinte sémantique à intensité0 et rollback de sauvegarde des préférences de combat. Raster alpha testé0/.35/1 sur vraie image, horloge de l’effet inchangée. Analyse ciblée six sources/tests D4 avec `flutter analyze --no-pub --no-fatal-infos` : exit0, six infos constructeur préexistantes, aucune erreur ni warning. Analyse player UI ciblée : `No issues found!`. SPEC et QUALITY favorables après relecture des correctifs ; ces verdicts ne remplacent pas la preuve native et physique F.

### C2 — Cadrage final et contrôle natif

Contrats nouveaux : `battle_camera_subject_geometry.dart`, `battle_camera_framing.dart`. Géométrie opaque stable sans idle/lunge/squash/caméra ; union d’animation optionnelle, ancre visuelle consommée en fallback. Résolveur fini overview/focus/groupe avec obstacles visibles, marges, diagnostic et maintien de l’idéal1.08 quand il tient. Les retours partent de la pose réelle. Invalidation bornée sur layout, au plusquatre sujets, enveloppes et HUD ; aucun recalcul provoqué par la seule pose animée ou60frames d’idle.

SPEC a trouvé puis fait corriger le retour testé depuis une caméra neutre artificielle et les invalidations manquantes après chargement d’image/révélation HUD. QUALITY a trouvé un rayon fini un pixel sous l’horizon produisant une profondeur4014.07 au-delàfar1000 : RED StateError, puis contrôle du billboard neutre avant focus idéal, sans catch général. GREEN97 C1/C2 ; SPEC et QUALITY approuvées. Contrôle numérique de96intervalles avec garde2px, pas de preuve continue universelle ; départ déjà occulté et offsets arbitraires non enveloppés restent explicitement diagnostiqués/limités.

Les six anciennes assertions d’overlay demandaient exactement les coordonnées neutres ou un offsetnul au retour. Elles ont été adaptées au nouveau contrat : pied source/layout stable, viewport négocié, rectangles projetés par la caméra effective, retour au repos résolu et commandes inchangées. Les assertions HUD/PV et délais sont conservées. Un état compilatoire de helper sans préfixeui puis une égalitéOffset trop stricte ont été corrigés ; aucune réussite déduite de ces échecs. Commande finale :

```text
flutter test test/battle_overlay_component_test.dart test/battle_stage_fallback_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded
00:03 +116: All tests passed! ; exit0 ; runner18734 ; quatre descendants ; reaped[]
```

Vrai hôte macOS compilé puis hot reload réussi. Metal/Impeller, stage et joueur GPU confirmés, erreursFlutter vides. Captures retenues : `c2-portrait-rest.png`, `c2-rotation-focus.png`, `c2-landscape-final-rest.png`, `d4-native-fast-camera.png`, `d4-native-reduced.png`. Passage390×844 vers844×390 pendantfocus, retour etHUD visibles. Vitesse2.5 conserve le mouvement natif ; réduction live le stoppe sans réécrire la vitesse. Ce contrôle avance le moteur de façon déterministe et ne mesure niFPS ni performance physique. Il précède la nouvelle implémentation E1 ; celle-ci doit encore être contrôlée nativement.

Le repos paysage se translate réellement : la pose neutre fait chevaucher l’ennemi (x537.7..622.5, bas181.7) et le HUDjoueur (x610..820, haut179.75), avant marges. Le nouveau cadrage résout ce conflit ; le changement est justifié par la géométrie et non présenté comme une égalitépixelparpixel. Fenêtre QA arrêtéePID81200 après vérification d’identité ; Marionette déconnecté. Wrappernativerunner79431,44descendants suivis, exit0, reaped[].

### E1 — Décision de secours du frame courant

`BattleStageRenderer`/`BattleStageFrameResult` distinguent disponibilité et présentation avec IDs soumis. Le compteur device augmente après presenter réussi. Flags effacés avant toute sortie ; PictureRecorder atomique, tentative refusée/exception jetée. SolCPU priorité7 après stage6, visibilité fondée sur `currentFramePresented`. Chargement tardif protégé par génération/parent/game/retrait ; disposal du renderer orphelin.

```text
flutter test test/battle_stage_fallback_test.dart
RED : +0/-2 ; GREEN final : 00:00 +10: All tests passed! ; exit0
flutter test test/flutter_frame_presentation_test.dart test/flutter_frame_graphics_device_test.dart test/battle_stage_camera_numeric_test.dart
00:00 +13: All tests passed! ; exit0
```

Fichiers : `map_render_3d/lib/src/battle_stage_3d.dart`, `flutter_frame_graphics_device.dart`, runtime `battle_stage_3d_component.dart`, `battle_perspective_ground_component.dart`, gate dans l’overlay, nouveau `battle_stage_fallback_test.dart`, assertions `flutter_frame_presentation_test.dart`. Analyse runtime ciblée sans issue ; trois warningsFlame internes préexistants côté renderer. SPEC/QUALITY approuvées par lectures indépendantes. Tests avec vraiContext/images/pixels et renderer contrôlé, pas une nouvelle preuveMetal. Cas parent/game changés et générations concurrentes gardés en code mais non testés séparément.

### Chantier encore actif

C3 a produit RED3 sur coordonnées figées puis GREEN6 sprite/SDK/spritesheet ; annulation de chargements asynchrones a produit RED2 puis passe verte. Une collision de runsFlutter sur `native_assets.json` a empêché un run : wrapper désormais verrouillé par cwd pour sérialiser les tests d’un même package, sans flutterclean ni arrêt de sessiontierce. Les composants RMXP/Balls et l’intégration des familles restent en cours ; aucun lot C3 clos à partir du seul playFx.

E2 implémenté en revue SPEC avec42testsrenderer et11runtime verts ; ressources, compteurs et limites VRAM à documenter après revue. E3 etF restent ouverts. HEAD partagé observé1706473626bd5402ad81cfe320f5ec0c4ca91239 ; aucune écritureGit de ce chantier. Les changements concurrents restent préservés. L’iPhone15Pro physique demeure annoncé appairé/disponible, sans profil lancé. Rapport et Notion maintiennent DOING, objectifA–F non terminé.

## Reprise du 1er novembre — C3, E2, E3 et vérifications croisées

Ce point remplace les indications de chantier encore actif ci-dessus. L'objectif A–F reste incomplet et le ticket Notion reste DOING. Branche `main`, HEAD partagé `1706473626bd5402ad81cfe320f5ec0c4ca91239` ; aucun add/commit/push ni autre écriture Git. Les travaux concurrents hors combat restent préservés.

### C3 — Dépendances RMXP et invalidation immédiate

L'audit SPEC a identifié deux défauts supplémentaires : tous les placements RMXP exigeaient des acteurs inutilisés, y compris les animations purement écran ; une cellule pouvait encore être peinte entre invalidation et retrait en microtask. Dans `battle_fx_layer_component.dart`, les dépendances obligatoires suivent désormais la policy et les callbacks réellement présents dans les données. Dans `battle_rmxp_animation_component.dart`, l'invalidation cache immédiatement les cellules tout en préservant la dernière frame d'une complétion naturelle legacy. Douze nouveaux cas dans `battle_fx_live_attachment_test.dart` couvrent ces distinctions. Les projectiles existants suivent des endpoints vivants à progression constante ; aucun nouvel espace monde arbitraire n'est revendiqué.

```text
flutter test test/battle_fx_live_attachment_test.dart --plain-name RMXP --reporter expanded
RED : +4 -10, exit1 ; GREEN : +14 All tests passed!, exit0
flutter test test/battle_fx_live_attachment_test.dart test/battle_rmxp_animation_component_test.dart test/battle_overlay_component_test.dart --reporter expanded
00:01 +148: All tests passed! ; exit0
flutter analyze --no-pub lib/src/presentation/flame/battle_fx_layer_component.dart lib/src/presentation/flame/battle_rmxp_animation_component.dart test/battle_fx_live_attachment_test.dart
No issues found! ; exit0
```

Verdicts distincts : SPEC a reproduit les deux écarts ; implémentation/tests les ont corrigés ; QUALITY a relu les trois fichiers et n'a trouvé aucun blocage. Les familles sprite, spritesheet, SDK, RMXP, Balls, flash et capture disposent de leurs contrôles dédiés. Une première commande root contenait par erreur le chemin inexistant `battle_ball_animation_catalog_test.dart` : exit1, aucun résultat vert attribué à cette commande. La commande corrigée sur huit fichiers existants a terminé avec61 tests réussis.

### E2/E3 — Propriété et composition des ressources

Une revue E2 a reproduit le remplacement d'un import encore en cours sous budget36 : l'ancienne réservation refusait la suivante, puis l'erreur restait mémorisée. `BattleStageTextureCache` attend maintenant la fin réelle des imports devenus obsolètes avant l'admission suivante, avec revérification du token. Tests : changement en cours d'import et fermeture pendant cette attente, sans conversion supplémentaire ni destruction du budget partagé.

La matière d'un slot retenait également sa première texture via `_defaultAlbedoTexture`, après remplacement de `albedoTexture`. Le nouveau propriétaire interne `battle_stage_textured_quad.dart` renouvelle uniquement la matière lorsque l'identité de texture change, en conservant mesh et surface. Acteurs et underlays utilisent le même propriétaire. `battle_stage_textured_quad_test.dart` prouve le reset vers la nouvelle texture et l'absence de renouvellement pendant120 frames stables. `battle_stage_resource_lifecycle_test.dart` couvre le budget et les conversions annulées. Aucun changement global de `SpatialPixelMaterial.resetAnimation`.

E3 introduit `battle_stage_underlays.dart` et les tests correspondants : véritables masques d'ombres floutés, admission et retraite de leurs sources, ordre sol → ombres → ensembles traînées/acteur triés par profondeur. `spatial_render_context.dart` offre un comparateur optionnel ; son absence conserve le tri overworld antérieur. Le depth buffer désactivé reste local à cette scène de billboards. Le bridge runtime et `battle_scene_combatant_component.dart` refusent une frame GPU partielle et suppriment toute peinture Canvas d'un acteur entièrement pris en charge. Les tests `spatial_transparency_render_test.dart`, `battle_stage_fallback_test.dart` et `battle_scene_combatant_ground_render_test.dart` couvrent l'alpha, le rejet atomique et l'absence de doublon.

```text
flutter test test/battle_stage_resource_lifecycle_test.dart test/battle_stage_underlays_test.dart test/battle_stage_textured_quad_test.dart test/flutter_frame_presentation_test.dart test/spatial_transparency_render_test.dart --reporter expanded
00:00 +36: All tests passed! ; exit0
flutter test test/battle_stage_underlays_test.dart test/battle_stage_textured_quad_test.dart test/spatial_transparency_render_test.dart test/battle_stage_resource_lifecycle_test.dart test/flutter_frame_presentation_test.dart test/flutter_frame_graphics_device_test.dart test/battle_stage_camera_numeric_test.dart test/spatial_pixel_material_test.dart --reporter expanded
00:01 +92: All tests passed! ; exit0 ; runner57359,9descendants,reaped[]
```

SPEC et QUALITY E3 favorables ; QUALITY complémentaire E2/E3 favorable après correction des deux défauts. Les réservations et compteurs prouvent la propriété logique ; `importedTextureUploadCount/Bytes` comptent des allocations cumulées, pas la VRAM résidente ni le succès de chaque écriture. Aucun moment de libération physique par Impeller n'est certifié.

### Vérifications intégrées et limites constatées

`final-runtime-regression` exécute19 fichiers caméra/cadrage/reflow/numérique/horloge/runner/planner/FX/confort/fallback/ombres/doubles/smoke : `00:08 +269: All tests passed!`, exit0, runner49302,20descendants,reaped[]. Deux tests C2 utilisent désormais le HOME de la machine sur macOS, avec repli temporaire sur les autres plateformes : aucun chemin utilisateur fixé dans le code des tests. La matrice de pixels de ces tests reste distincte du rendu GPU natif.

Depuis `examples/playable_runtime_host`, `flutter test test/phase_a_golden_slice_launch_test.dart --reporter expanded` : `00:00 +14: All tests passed!`, exit0, runner56076,2descendants,reaped[]. Analyse ciblée11 sources/tests runtime avec `--no-pub --no-fatal-infos` : exit0,6infos constructeur préexistantes, aucune erreur/warning. Analyse renderer : trois warnings Flame internes préexistants, sans nouvelle issue rapportée par la passe ciblée.

Parité : aucun nouveau contrat de projet ni commande d'authoring n'est créé par ces corrections de présentation. `npm run build` dans `tools/pokemap_mcp` : exit0 ; `node --import tsx --test test/battle_transition_catalogue_stdio.test.ts` avec TMPDIR dans le root QA :1test réussi,0échec, exit0. Le live `pokemap_describe(domain:battle,view:compact)` répond ok avec44actions. Cela ne certifie pas la totalité de la conformance authoring ni tous les anciens exports/sauvegardes.

Build macOS debug réussi et vrai stage Metal/Impeller vérifié. Parcours singles : repos portrait, attaque ennemie avec HUD masqués, rotation844×390 pendant l'attaque, retour avec HUD restaurés ; puis projectile natif pendant déplacement caméra et rotation, même effet actif, disparition à échéance et retour des HUD. La frame de rotation peut utiliser le Canvas pendant le chargement du nouveau masque ; la frame suivante acquise revient au GPU. `framePresented`, prise en charge joueur et liste d'erreurs sont vérifiés, sans déduire le backend d'une simple image. Après changement de forme de classe E2, le premier hot reload a conservé l'ancien type de Map et déclenché le fallback ; un hot restart a recréé le stage et confirmé frameGPU=true, joueurGPU=true, erreurs=[]. Le reload insuffisant n'est pas présenté comme une validation native réussie.

La passe native a aussi révélé une régression de cadrage C2 : l'enveloppe synthétique ±100px+20% rejetait le focus1.08 et déclenchait le recul1.25. Pour un sprite122px, elle représentait370.8px avant projection. Cette marge artificielle a été remplacée par une enveloppe compilée depuis les mouvements réellement présents dans le plan, incluant les cellules15 RMXP. Le détail et les preuves finales suivent ; aucun verdict global DONE.

Le contrôle Markdown échoue sur trois documents nouveaux préexistants et deux chemins ignorés hors de cette reprise. Aucun nouveau Markdown ajouté ici ; seul ce rapport canonique est complété. Aucun contournement du contrôle ni suppression de travail concurrent.

### C2 — Correction de la régression de dézoom

Trois chemins concernés : nouveau `battle_camera_motion_envelope.dart`, `_installActiveAnimationPlan` et consommation dans `battle_overlay_component.dart`, tests ajoutés à `battle_camera_framing_invalidation_test.dart`. Une seule compilation des métadonnées par installation de plan ; le reflow matérialise l'enveloppe avec la géométrie stable et le `stageRect` courants, sans relire les frames RMXP. Les réglages d'effets réduits neutralisent les mêmes amplitudes que les handlers réels. Les marges8 et la garde2 existantes restent actives.

L'enveloppe combine l'union des offsets déclarés et le maximum des échelles par axe. Les offsets RMXP sont convertis avec l'échelle réelle de leur scène. Cette combinaison couvre notamment RMXP puis lunge : RMXP remplace les champs d'animation, mais le lunge peut ensuite garder son échelle. Ni somme des offsets, ni produit des échelles. L'union porte sur le plan courant entier par slot ; ce n'est pas une preuve de trajectoires arbitraires non déclarées.

Preuves : focus immobile RED avec distance à l'œil idéal5.940813577890569 puis idéal1.08 exact ; lunge30 dirigé(+30,-4.8) ; vraies animations33/440 de Charge confrontées aux rectangles de l'acteur après rotation ; vrai tour de combat avec focus cible entre.95 et1.15 ; compteur de compilation stable pendant60frames/reflows/réglages. Le cas de champs conservés a produit un RED223.72 rendu contre201.8 enveloppé, puis passe avec le calcul corrigé. Comme le catalogue ne contient aucune cellule15 zoom>100, ce test utilise explicitement une fixture150%, sans lui attribuer une provenance réelle.

Une première passe élargie a échoué sur deux tests qui cherchaient à tort une cellule15 dans l'animation33 au lieu440 : `+385 -2`, exit1. Ce résultat n'est pas présenté comme vert. Les tests ont été corrigés et la couverture des champs conservés ajoutée avant la passe finale.

```text
flutter test test/battle_camera_framing_invalidation_test.dart test/battle_camera_framing_test.dart test/battle_camera_framing_resolver_test.dart test/battle_camera_reflow_test.dart test/battle_perspective_camera_test.dart test/battle_camera_numeric_contract_test.dart test/battle_motion_overlay_test.dart --reporter expanded
00:01 +114: All tests passed! ; exit0 ; runner81927,8descendants,reaped[]
```

Analyse des trois chemins : exit0 avec `--no-fatal-infos`, quatre infos constructeur overlay préexistantes, aucune nouvelle issue helper/test. QUALITY finale indépendante approuve le delta maxscale/unionoffsets et son test à150%.

La dernière passe root `final-runtime-delivery` ajoute l'overlay complet et la progression post-combat aux19 fichiers intégrés précédents : `00:07 +388: All tests passed!`, exit0, runner84189,22descendants,reaped[]. Le host a été relancé après le dernier helper, TMPDIR sous le root QA : `00:01 +14: All tests passed!`, exit0, runner84264,11descendants,reaped[]. Renderer92 et MCP restent les résultats frais de leurs chemins inchangés depuis leurs passes respectives.

Le premier build iOS profile signé a réussi (Runner.app63.4MB, Xcode53.4s, teamAH4CK9Z798), avec exactement cinq assets de fixture dont les hashes correspondent aux sources HeartGold lues sans mutation. Il précède toutefois le dernier delta C2 et ne constitue pas sa preuve finale ; un rebuild final est lancé. Les premières tentatives wireless n'ont pas démarré l'app : flag de publication requis, puis chemin d'automation Xcode trop lent. Le diagnostic et le lancement CoreDevice sont suivis sans modifier de configuration Flutter globale ni interrompre une autre app. Aucun chiffre de performance physique n'est encore acquis.

### F — Première preuve physique et défaut doubles détecté

Le binaire incluant l'enveloppe finale C2 est réellement lancé sur iPhone15Pro, iOS27, en profile. Contrôle singles : deux images résolues, frame présentée, deux acteurs GPU, aucune erreur Flutter. Les métriques exactes et le SHA AOT correspondant sont conservés dans `evidence/camera-consolidation/ios-profile-measurements.json` :3446échantillons après120frames de warmup,29.749s de moteur naturel, UIp50/p95=1.269/1.727ms, raster=.622/.886ms, aucun timing non-live ni échantillon perdu. Une mesure distincte sur393×852 donne2785échantillons/24.305s, UI1.059/1.384ms, raster.512/.662ms. Ces valeurs ne certifient pas tous les combats ni un gain avant/après. Une collecte intermédiaire interrompue par déconnexion VM n'a pas été récupérée ; aucun chiffre ne lui est attribué. L'app et la console étaient encore vivantes sans crash observé, cause de déconnexion non déterminée.

Une adaptation QA isolée demande maintenant l'orientation via UIKit et observe les dimensions réelles de FlutterView. Paysage matched852×393points/2556×1179pixels, puis portrait393×852points/1179×2556pixels, DPR3. Le projectile reste actif pendant la rotation et le mouvement de caméra ; le retour termine avec FX0, HUD visibles, GPU2, erreurs[]. Les premières captures par simple changement de SizedBox ne sont pas assimilées à cette preuve native.

Le binaire doubles compilé avec `QA_DOUBLES=true` a ensuite démontré quatre acteurs GPU et images résolues dans les deux orientations. Les tentatives par variable d'environnement n'avaient conservé que deux acteurs : elles ne sont pas présentées comme des validations doubles. Le contrôle visuel a refusé le portrait, malgré les flags verts : joueurs31.36×25.74 et22.27×18.28points, trop petits. Le vecteur eye−aim correspond au recul2.2. Le défaut est dans la génération des candidats : le fallback force l'union des quatre acteurs à entrer dans un seul rectangle sans HUD, alors que la validation réelle exige seulement que chaque acteur évite les HUD. Les vides entre acteurs étaient traités comme occupés. Recherche bornée de translations à zoom constant avant recul en cours ; aucune modification de l'UI ni des mécaniques.

La fixture doubles avant correction est préservée sous les noms `ios-final-doubles-portrait` et `ios-final-doubles-landscape-before`, PNG/JSON. L'app current a été arrêtée après vérification d'identité pour libérer le device. F et C2 restent incomplets tant que ce défaut n'a pas ses preuves finales.

Pour la comparaison de performance demandée, un baseline borné a été préparé sans worktree ni Git write : libs/pubspec des trois paquets de présentation au HEAD170647362,571fichiers/7 771 058octets vérifiés contre leurs blobs Git, assets/shaders partagés en lecture et105versions externes identiques. Les autres dépendances restent communes au worktree : ce n'est pas un checkout historique intégral. Le collecteur FrameTiming et l'orientation sont identiques, le harness adapte seulement les diagnostics absents ; aucun moteur baseline modifié. Build profile signé réussi dès la première tentative,46.6s,63.8MB, bundle distinct `com.example.battleCameraQaBaseline`. Installation et mesure physique attendent leur reçu ; aucune performance de baseline n'est inventée.

Coordination autorisée par Yoahn vérifiée directement dans le fil `01a19436-75c7-70f1-8dcd-5fcf09ca975e` puis contrats de présentation transmis aux fils API et animations : une seule horloge/caméra, groupes/barrières, secondes natives avec éventuelle conversion ms à l'import, ancrages sémantiques projetés, identités/générations, enveloppes stables et responsabilités de fichiers. Lance-Flammes reste un pilote futur, sans nouvelle intégration dans ce lot. La refonte des règles mécaniques reste reportée ; aucun format de recette API ou lecteur articulé n'est annoncé comme livré ici.

### F — Résultat final des corrections et comparaison physique

La correction overview ne force plus l'union des acteurs dans un rectangle unique. Elle cherche des translations caméra bornées à partir des séparations de chaque acteur avec les HUD et les bords. Une petite récession est calculée depuis les contraintes lorsque le viewport l'exige ; l'ancien fallback reste disponible. Grille au plus(3+2NM)² candidats/facteur avant déduplication, soit1849 pour4acteurs/5obstacles. Filtre endpoint algébrique avant les95positions intermédiaires du contrôle de trajectoire. Tri déterministe norme²/x/y. Aucune UI déplacée, aucune échelle de sprite fabriquée, focus individuel1.08 inchangé.

La fixture géométrique reprend exactement les dimensions des PNG lus sans mutation (80×80, opaque67×55 et37×39) sans copier leurs illustrations. Elle reproduit l'ancienne pose native, puis vérifie les échelles.99322/.95408/.92616/.97210, les HUD et le viewport. Le minimum passe de.26852 à.92616. Sources concernées par ce dernier delta : `battle_camera_framing.dart`, `battle_camera_framing_invalidation_test.dart`, `battle_camera_framing_resolver_test.dart`. QUALITY indépendante favorable et analyse des trois chemins : `No issues found!`, exit0.

```text
cd packages/map_runtime
flutter test test/battle_overlay_component_test.dart test/battle_camera_authority_test.dart test/battle_camera_framing_test.dart test/battle_camera_framing_resolver_test.dart test/battle_camera_framing_invalidation_test.dart test/battle_camera_reflow_test.dart test/battle_camera_numeric_contract_test.dart test/battle_camera_sequence_test.dart test/battle_scene_clock_test.dart test/battle_animation_runner_budget_test.dart test/battle_animation_runner_test.dart test/battle_turn_animation_planner_camera_groups_test.dart test/battle_turn_animation_planner_test.dart test/battle_fx_live_attachment_test.dart test/battle_motion_overlay_test.dart test/battle_motion_policy_test.dart test/battle_stage_fallback_test.dart test/battle_scene_combatant_ground_render_test.dart test/runtime_doubles_overlay_test.dart test/post_battle_progression_overlay_component_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter expanded
00:10 +390: All tests passed! ; exit0 ; runner60853,22descendants,reaped[]
cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart --reporter expanded
00:00 +14: All tests passed! ; exit0 ; runner62905,2descendants,reaped[]
```

Le dernier binaire doubles inclut le résolveur corrigé, QA_DOUBLES=true vérifié, SHA AOTa5586d3225f897389eb3fd74c6c0980e935b6ad7dfca79e026d2bbfc49b6754a. Sur iPhone15Pro en profile : portrait393×852, joueurs79.13×64.96 et76.82×63.06points au lieu31.36×25.74/22.27×18.28 ;4images et4acteursGPU, frameprésentée, erreurs[]. Capture relue et lisibilité acceptée techniquement. Paysage UIKit852×393 également relu. Caméra+projectile actif puis FX0/HUDvisibles/GPU4 au retour. L'appréciation artistique de Yoahn reste une revue utilisateur, pas un verdict automatisé.

Le dernier binaire singles, mêmes sources de production et QA_DOUBLES=false, SHA AOTf26f95971f67737f0064cebf90d5470a5468ffaedbc46c1e8c604217d2bb07ed, confirme le vrai tour de Charge : joueur125px au repos puis134.462px pendant le mouvement(~1.076), HUDmasqués, retour à la pose de repos/HUDvisibles/GPU2. Le dernier contrôle paysage reprend caméra et projectile puis leur retour, avec2acteursGPU et aucune erreur.

| Scène physique profile | Échantillons / durée | Warmup | UI p50/p95 ms | Raster p50/p95 ms |
| --- | --- | --- | --- | --- |
| Baseline présentation HEAD170, singles393×852 |8292 /70.143s|120frames|.962 /1.260|.515 /.673|
| Sources finales, singles393×852 |4557 /38.998s|120frames|1.184 /1.448|.556 /.727|
| Sources finales, doubles852×393 |5441 /46.437s|120frames|1.563 /1.923|.812 /1.000|

Collecteur `SchedulerBinding.addTimingsCallback` identique, moteur naturel sans stepEngine pendant les mesures, aucun timing nonlive ni échantillon rejeté par le collecteur. Le p95 UI singles observé est supérieur de.188ms au baseline, raster de.054ms ; aucun gain de performance n'est revendiqué. Les intervalles ont des durées différentes et ne constituent pas une campagne statistique ou thermique, une certification FPS universelle, une mesure froide ni une mesure directe de VRAM. Les tests de budgets/plateaux logiques et les profils physiques restent des preuves distinctes. Les résultats complets, hashes et limites sont dans `ios-profile-measurements.json`.

### Vérification élargie renderer : échec préexistant requalifié

```text
cd packages/map_render_3d
flutter test --reporter expanded
00:29 +813 -1: Some tests failed. ; exit1 ; runner69063,101descendants,reaped[]
flutter test test/spatial_presentation_shader_test.dart --reporter expanded
Échec isolé identique : cutout modes reject before lighting with their original alpha ; exit1
```

L'assertion du test attend exactement2instructions`discard;`, alors que le shader en contient3. Shader ET test sont strictement identiques au HEAD170, donc hors modifications de consolidation : SHA shader101a29d7c53ddce474be7e70e37bc32093d2a1f125a724658e4c48d0bcc456d6 ; SHA testc34d1121fea7afec42c95e31afd69c44041d54b609c0701d003ac9f7007c7c9b. Aucun correctif hors périmètre appliqué. La suite renderer complète n'est pas présentée comme verte ; les92tests ciblés pertinents restent verts et le rendu physique est acquis.

## Revues et limites

Verdicts de clôture technique, dans le périmètre du plan de consolidation :

| Passe | Verdict et preuve |
| --- | --- |
| Audit / Architecture | Les constats CAM ont été réconciliés au code partagé ; deux défauts de propriété de texture, deux défauts RMXP et deux défauts de cadrage révélés en revue/native ont été corrigés. Aucune nouvelle mécanique ni lecteur BW2/articulé intégré. |
| Implémentation | Autorité caméra unique, enveloppes stables compilées par plan, FX liés aux bons occupants, vitesse/confort séparés, budget de rattrapage, frame GPU atomique et ressources bornées implémentés. Anciens réglages conservés jusqu'à édition explicite. |
| Tests |390runtime et14host finaux verts ;92renderer ciblés verts ; suite renderer complète813PASS/1FAIL, échec shader/test identique au HEAD de référence et reproduit isolément. Les suites se recouvrent : ces chiffres ne doivent pas être additionnés comme un total de tests uniques. |
| Build / Validation | Builds macOS debug et iOS profile signés acquis, vraies frames GPU2/GPU4 et rotations UIKit portrait/paysage vérifiées ; profils physiques baseline/singles/doubles mesurés et liés à leur AOT exact. Aucun FPS global ni gain non mesuré annoncé. |
| Critique finale indépendante | Revues SPEC/QUALITY favorables sur les correctifs ; le défaut doubles a été refusé malgré GPU4 puis corrigé et contrôlé visuellement. La preuve CPU, la preuve GPU et l'avis artistique utilisateur restent distincts. |

Les recommandations de création de worktree/commit des skills ne remplacent pas les limites Git du dépôt. Aucun commentaire de code ajouté conformément à la consigne directe de Yoahn. Aucun nouveau Markdown de travail : seul ce rapport canonique est complété, avec captures/reçus et les trois petites sources du harness conservées comme preuve.

Limites conservées : baseline limité aux trois paquets de présentation avec dépendances communes ; mesures de scènes chaudes représentatives, pas de campagne froide/thermique ni de VRAM physique directe ; test shader préexistant en échec ; contrôle Markdown bloqué par les documents concurrents déjà signalés. Les captures du harness ne certifient pas la distribution Player complète, toutes les SafeAreas/tailles de texte sur appareil ni la fidélité pixel-perfect au moteur BW2. Le Z-buffer désactivé convient aux billboards actuels ; les futurs vrais modèles 3D nécessiteront leur profondeur interne. Aucun statut FG ni roadmap mécanique modifié.

Les sources et reçus retenus sont sous `documentation/reports/battle/evidence/camera-consolidation/`, les trois fichiers du harness sous `native-fixture/`. Les chemins QA mentionnés plus haut sont historiques et ont été supprimés ; ils ne désignent plus un environnement retenu. Les endpoints VM éphémères ont été omis des reçus canoniques.

## Inventaire final des zones du chantier

Inventaire au HEAD partagé170647362, sans inclure les autres travaux du worktree. Les chemins mixtes conservent leurs zones concurrentes ; cette liste n’en revendique pas l’intégralité. Les diffs source restent la preuve canonique des changements.

| Fichier source | Zone et raison / impact |
| --- | --- |
| `packages/map_player_ui/lib/src/player/player_options_strings.dart` | Libellés localisés vitesse/confort (D4). |
| `packages/map_player_ui/lib/src/player/runtime_player_options.dart` | Contrôles indépendants et reset des préférences de combat, sans réécriture avant édition (D4). |
| `packages/map_player_ui/lib/src/preferences/player_preferences.dart` | Champ optionnel battleMotion, codecs et copie des préférences legacy (D4). |
| `packages/map_render_3d/lib/src/battle_stage_3d.dart` | Frame présentée, cache de textures, imports obsolètes, quad/material, ordre des acteurs/ombres/traînées (E1–E3). |
| `packages/map_render_3d/lib/src/battle_stage_camera.dart` | Adaptation de la pose et domaine numérique CPU/GPU commun (B/D2). |
| `packages/map_render_3d/lib/src/flutter_frame_graphics_device.dart` | Reçu de présentation et compteurs réels d’allocations (E1/E2). |
| `packages/map_render_3d/lib/src/spatial_actor_visual.dart` | Handle d’image possédé pendant conversion et abandon des résultats obsolètes (E2). |
| `packages/map_render_3d/lib/src/spatial_render_context.dart` | Comparateur optionnel des surfaces transparentes ; défaut overworld préservé (E3). |
| `packages/map_runtime/lib/map_runtime.dart` | Export public de la politique de mouvement ; autres changements partagés hors scope préservés (D4). |
| `packages/map_runtime/lib/src/player/runtime_companion_presentation_codec.dart` | Transport optionnel battleMotion dans le snapshot compagnon (D4). |
| `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart` | Prise en compte des préférences battle dans la comparaison/application (D4). |
| `packages/map_runtime/lib/src/player/runtime_player_host.dart` | Transmission initiale et live de la politique à l’hôte runtime (D4). |
| `packages/map_runtime/lib/src/presentation/flame/battle_animation_runner.dart` | Horloge, dette de dispatch, budget partagé, callbacks et annulation réentrante (D3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_ball_capture_component.dart` | Placement live, progression/cues de capture conservés après reflow (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_ball_flash_component.dart` | Centre/rayon live et intensité décorative sans redémarrage (C3/D4). |
| `packages/map_runtime/lib/src/presentation/flame/battle_ball_throw_component.dart` | Trajectoire recalculée à progression constante et ownership de la cible (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_camera_rig.dart` | Ancien contrôleur autonome supprimé après migration des consommateurs (B). |
| `packages/map_runtime/lib/src/presentation/flame/battle_fx_layer_component.dart` | Bindings d’occupants, dépendances RMXP par policy et invalidation des loads tardifs (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_fx_sprite_component.dart` | Endpoints vivants, progression et état de rendu conservés (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_fx_sprite_sheet_component.dart` | Ancrage vivant sans remise à zéro de la frame source (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` | Autorité caméra, intentions/reflow, cadrage, enveloppes du plan, horloge, FX et confort (B/C/D). |
| `packages/map_runtime/lib/src/presentation/flame/battle_perspective_camera.dart` | Pose unique, courbes, contrôles numériques et reflow sans redémarrage temporel (B/C1/D2). |
| `packages/map_runtime/lib/src/presentation/flame/battle_perspective_ground_component.dart` | Sol Canvas conditionné par la frame GPU courante et priorité correcte (E1). |
| `packages/map_runtime/lib/src/presentation/flame/battle_rmxp_animation_component.dart` | Placement live, transform possédé et arrêt immédiat de la peinture invalidée (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart` | Géométrie stable, ownership RMXP, intensité et suppression complète du doublon Canvas (C2/C3/D4/E3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart` | Retrait du bloc inatteignable ; profils actifs conservés (D5). |
| `packages/map_runtime/lib/src/presentation/flame/battle_sdk_particle_component.dart` | Ancre live, délai/progression et offsets locaux préservés (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_stage_3d_component.dart` | Pont de projection, soumission complète et fallback atomique de la frame (E1/E3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart` | Inspection/réassociation récursives des commandes caméra, groupes conservés (D1). |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Application de battleMotion à l’hôte 2D sans changer le legacy avant édition (D4). |
| `packages/map_runtime/lib/src/session/spatial_exploration_game_session_runtime.dart` | Deux zones battleMotion initial/live ; zones de visibilité concurrentes préservées (D4). |
| `packages/map_runtime/lib/src/spatial/spatial_battle_runtime.dart` | Politique initiale/live de la scène de combat spatiale (D4). |
| `packages/map_render_3d/lib/battle_projection_contract.dart` | Bornes de profondeur et validation de direction partagées (D2). |
| `packages/map_render_3d/lib/src/battle_stage_textured_quad.dart` | Propriétaire du mesh/matériau évitant de retenir la première texture après remplacement (E2). |
| `packages/map_render_3d/lib/src/battle_stage_underlays.dart` | Masques doux possédés, budget/retraite et clé de tri des couches (E3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_camera_framing.dart` | Résolution et diagnostic ; grille déterministe par acteur avant fallback global (C2). |
| `packages/map_runtime/lib/src/presentation/flame/battle_camera_motion_envelope.dart` | Compilation par plan des amplitudes/échelles natives et RMXP, matérialisation au reflow (C2). |
| `packages/map_runtime/lib/src/presentation/flame/battle_camera_subject_geometry.dart` | Contrat foot/bounds/focusAnchor/enveloppe stable pour visuels actuels/futurs (C2). |
| `packages/map_runtime/lib/src/presentation/flame/battle_live_attachment.dart` | Contrats live de points/rectangles/Balls et retrait sûr des attachements invalidés (C3). |
| `packages/map_runtime/lib/src/presentation/flame/battle_motion_policy.dart` | Validation/equality/codec des trois réglages indépendants et adaptateur legacy (D4). |

Tests créés/modifiés/supprimés : leurs comportements, RED/GREEN et limites sont détaillés dans les lots correspondants. Le test du rig supprimé est remplacé par ceux de l’autorité effective ; les assertions métier/PV/délais restent conservées.

```text
M packages/map_player_ui/test/player/menu8_options_test.dart
M packages/map_render_3d/test/flutter_frame_presentation_test.dart
M packages/map_render_3d/test/spatial_transparency_render_test.dart
D packages/map_runtime/test/battle_camera_rig_test.dart
M packages/map_runtime/test/battle_overlay_component_test.dart
M packages/map_runtime/test/battle_scene_combatant_ground_render_test.dart
M packages/map_runtime/test/player/runtime_player_preferences_apply_test.dart
M packages/map_runtime/test/runtime_doubles_overlay_test.dart
M packages/map_runtime/test/spatial_battle_runtime_test.dart
?? packages/map_player_ui/test/player/battle_motion_preferences_test.dart
?? packages/map_render_3d/test/battle_stage_camera_numeric_test.dart
?? packages/map_render_3d/test/battle_stage_resource_lifecycle_test.dart
?? packages/map_render_3d/test/battle_stage_textured_quad_test.dart
?? packages/map_render_3d/test/battle_stage_underlays_test.dart
?? packages/map_runtime/test/battle_animation_runner_budget_test.dart
?? packages/map_runtime/test/battle_camera_authority_test.dart
?? packages/map_runtime/test/battle_camera_framing_invalidation_test.dart
?? packages/map_runtime/test/battle_camera_framing_resolver_test.dart
?? packages/map_runtime/test/battle_camera_framing_test.dart
?? packages/map_runtime/test/battle_camera_numeric_contract_test.dart
?? packages/map_runtime/test/battle_camera_reflow_test.dart
?? packages/map_runtime/test/battle_fx_live_attachment_test.dart
?? packages/map_runtime/test/battle_motion_overlay_test.dart
?? packages/map_runtime/test/battle_motion_policy_test.dart
?? packages/map_runtime/test/battle_scene_clock_test.dart
?? packages/map_runtime/test/battle_stage_fallback_test.dart
?? packages/map_runtime/test/battle_turn_animation_planner_camera_groups_test.dart
```

Le rapport lui-même et `evidence/camera-consolidation/` complètent cet inventaire : captures avant/après, contextes JSON, mesures/provenance, deux reçus AOT finaux et trois petites sources de fixture. Aucun dump des fichiers produit, environnement compilé ou archive du workspace n’est conservé.

## Clôture technique et nettoyage

Implémentation du plan A–F livrée pour revue, dans les limites documentées ; Notion doit passer à TO REVIEW, jamais DONE sans décision de Yoahn. La comparaison et les contrôles natifs ont été réalisés sur les binaires finaux et les sources C2 épinglées : framing SHA256cc38be62549fa3e515e61851b32a68e3a04d737ac9228750ab4d416fc1b53f3b ; overlay522e74173fa6baf3ecf16528bc180ae2cb44b8f8e7d350aa3fc6ef719b4ecef6. Aucun autre lot ni intégration de nouvelles recettes démarré.

Apps `com.example.battleCameraQaBaseline` et `com.example.battleCameraQa` arrêtées par leurs consoles vérifiées, puis désinstallées avec comparaison exacte des identifiants confirmant leur absence. Les contextes/captures nécessaires ont été récupérés avant cette suppression. Une vérification globale de1296identités PID enregistrées (naissance+commande) ne trouve aucun survivant owned ; aucun consommateur `lsof` du root QA avant sa suppression. Aucune autre app/session n'a été arrêtée.

Suppressions vérifiées : baseline313536Kio, native1718080Kio puis reste du root6944Kio. Root `/Users/karim/Library/Caches/AveluneQA/battle-camera-consolidation` absent ; aucun environnement temporaire retenu. Les trois sources de fixture22 632octets et les preuves choisies résident désormais dans le dossier canonique du rapport, pas dans un environnement compilé. Avant suppression, les cinq ressources originales HeartGold ont été recontrôlées inchangées et les sources de baseline correspondaient encore aux blobs Git. La dernière suppression du root a mesuré séparément6944Kio de répertoire et une variation SSD libre de6 021 120octets ; APFS/écritures concurrentes empêchent de confondre ces mesures.

État Git final observé : branche `main`, HEAD1706473626bd5402ad81cfe320f5ec0c4ca91239,207chemins modifiés/non suivis dans le worktree partagé, dont67chemins source/tests du périmètre inventorié. Les autres travaux sont préservés. Aucun add, commit, push ou autre écriture Git réalisé. Le rapport et les preuves font partie de l'inventaire, pas d'une livraison publiée ni d'un export de jeu.

Contrôles de clôture : `git diff --check` propre ; JSON/PNG canoniques lisibles ; root QA absent. `bash tools/scripts/check_markdown_hygiene.sh` reste en échec sur les trois Markdown nouveaux du worktree et les deux documents ignorés déjà listés ; aucun override ni suppression de travail concurrent. Cette limite et l'échec renderer préexistant sont transmis à la revue, sans prétendre que toutes les suites globales sont vertes.
