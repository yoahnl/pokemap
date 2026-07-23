# FG-079 — Selbrume Dynamic Shop Golden Slice V0

Date de clôture : 2026-07-23
Branche : `main`
HEAD initial : `c81d8d04c0` (`feat(editor): simulate and validate shop states`)
Verdict du lot : **DONE proposé**

## 1. Résumé exécutif

Le comptoir du Port des Brisants prouve désormais quatre états issus de la
progression canonique de Selbrume :

| État | Déclenchement | Ouverture | Catalogue |
|---|---|---:|---|
| `__default__` | aucun profil actif | oui | Potion 300, Poké Ball 200 |
| `after-lysa` | `fact_rival_port_defeated = true` | oui | Potion 250, Poké Ball 200, Antidote 100 |
| `lighthouse-alert` | phare atteint et histoire non terminée | non | aucun ; message authored |
| `story-finished` | `fact_main_story_completed = true` | oui | Potion 200, Super Potion 700, Poké Ball 150 |

Le parcours joueur vérifie, sur le runtime de production :

- le profil effectivement résolu ;
- le catalogue et les prix exacts ;
- l'argent débité ;
- la quantité ajoutée au sac ;
- la clé et la valeur de stock propres à l'état ;
- la fermeture authored pendant l'alerte ;
- la persistance du stock après sauvegarde et rechargement.

Le vérificateur séquentiel MVP-16 reprend explicitement ces preuves. Une QA
réelle du Shop Builder a aussi trouvé puis fermé une collision de `ValueKey`
quand plusieurs diagnostics partageaient le même code et le même état.

## 2. Périmètre et non-objectifs

### Inclus

- authoring des quatre états de `shop_port_supplies` ;
- preuve E2E avant/après Lysa, alerte du phare et épilogue ;
- preuve de sauvegarde/chargement ;
- enrichissement du host de test sans réimplémenter la transaction ;
- mise à jour du reçu MVP-16 ;
- QA visuelle réelle et test de non-régression du Shop Builder ;
- mise à jour de la roadmap FG-074 à FG-079.

### Non-objectifs

- corriger le budget global du validateur narratif Selbrume ;
- dédupliquer les sources Event V2 historiques de Lysa ;
- corriger le contrat historique Core d'une condition Story Step ;
- modifier, déplacer ou intégrer les captures de walkthrough appartenant à
  l'utilisateur ;
- produire un package de release depuis un arbre de travail non propre.

## 3. État Git initial

La commande initiale était :

```bash
git status --short --untracked-files=all
```

Elle ne montrait aucune modification suivie. Elle montrait seulement des
artefacts utilisateur non suivis :

- 53 fichiers sous
  `reports/gameplay/evidence/selbrume_mvp_walkthrough_2026-07-23/` ;
- `reports/gameplay/selbrume_mvp_walkthrough_protocol.md`.

Ces 54 fichiers préexistants sont restés hors du périmètre, n'ont été ni
modifiés, ni déplacés, ni ajoutés au commit.

## 4. Audit initial et passes de contrôle

La politique active ne permettait pas de déléguer ce lot à des sub-agents sans
demande explicite. Les vérifications exigées ont donc été conduites comme cinq
passes nommées et indépendantes.

| Passe | Verdict | Résultat |
|---|---|---|
| Audit / Architecture | PASS | FG-079 identifié dans le plan ; les Facts canoniques et le service physique existant sont réutilisés. |
| Implémentation | PASS | Un seul shop authored ; aucune marque de progression parallèle ; résolution et transactions de production conservées. |
| Tests ciblés | PASS | E2E, host de service, widget Shop Builder et vérificateur MVP-16 verts. |
| Build / Validation | PASS avec dettes externes | Tous les analyseurs sont verts ; trois familles de tests globaux historiques restent rouges et sont détaillées ci-dessous. |
| Critique finale | PASS | Le lot est démontré sans masquer la fermeture, le stock, le save/load ni les limites de l'environnement visuel. |

## 5. Fichiers modifiés

### `selbrume/project.json`

Zone : `shops[shop_port_supplies]`.

- catalogue par défaut normalisé à Potion 300 et Poké Ball 200 ;
- ajout de `after-lysa`, priorité 10 ;
- ajout de `lighthouse-alert`, priorité 20, fermé avec le message exact
  `Le comptoir reste fermé pendant l’alerte du phare.` ;
- ajout de `story-finished`, priorité 30 ;
- références limitées aux Facts canoniques déjà produits par la campagne.

Impact : le même service physique et le même `shopId` changent intégralement
selon l'état courant du jeu.

### `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`

Zones : parcours principal, construction du contrôleur de services, helpers de
boutique.

- achat Poké Ball avant Lysa ;
- achat Potion au prix remisé après Lysa ;
- contrôle exact du profil, catalogue, argent, sac et stock ;
- sauvegarde/rechargement puis réouverture du même profil ;
- résolution du comptoir fermé pendant l'alerte ;
- achat final au prix d'épilogue ;
- injection du résolveur de Facts typées de production.

Impact : FG-079 est prouvé dans le parcours joueur, pas seulement par un test
unitaire du résolveur.

### `examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart`

Zone : réception des requêtes shop.

- conservation en lecture seule des `PlayerServiceShopRequest` exactes ;
- catégorie `medicine` étendue à `super-potion`.

Impact : les tests peuvent observer le profil réellement remis au host tout en
laissant `GameStateMutations.purchaseFromResolvedShop` exécuter la transaction.

### `examples/playable_runtime_host/test/selbrume_player_services_test.dart`

Zone : preuve d'achat après Lysa.

- assertion de l'état `after-lysa` ;
- assertion du prix 250 de la Potion.

Impact : couverture directe de la frontière contrôleur/host.

### `examples/playable_runtime_host/tool/src/selbrume_mvp_journey_verifier.dart`

Zone : résumé exécuté pour `MvpProductCriterion.mvp16Shop`.

- le reçu exige désormais la preuve avant Lysa, la mutation après Lysa, la
  fermeture du phare, l'achat final et la persistance du stock.

Impact : un simple achat statique ne suffit plus à valider MVP-16.

### `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_inspector.dart`

Zone : clé des cartes de diagnostic.

- la `ValueKey` inclut désormais `diagnostic.path` en plus du code et de
  l'état.

Impact : plusieurs erreurs identiques sur des champs différents n'entrent plus
en collision pendant un changement d'état.

### `packages/map_editor/test/shop_editor_panel_test.dart`

Zones : nouveau test de diagnostics répétés et clé du diagnostic existant.

- reproduction de plusieurs références d'objets inconnues ;
- sélection de `after-lysa` ;
- preuve qu'aucune exception de clé dupliquée n'est levée ;
- assertion de la clé complète incluant le chemin.

Impact : le défaut découvert en QA réelle est couvert en régression.

### `pokemap_roadmap_mecaniques_fangame.md`

Zone : Phase 4 — Bag, items, économie, soins.

- FG-074 à FG-079 ajoutés au tableau et proposés `DONE` ;
- DoD commun du Dynamic Shop State Builder documenté ;
- dettes externes du validateur et de Lysa explicitement séparées.

## 6. Fichiers créés

### `reports/gameplay/evidence/fg_079_dynamic_shop_builder/shop_builder_after_lysa_1920x920.png`

Capture binaire PNG :

- dimensions : 1920 × 920 ;
- SHA-256 :
  `1a7ba924a2e24d6ee8a2ceed9b289df6c3f0ecb45ef5b0027b21b97359ff1a12` ;
- contenu : Shop Builder réel, état `after-lysa` sélectionné, trois articles,
  conditions et inspecteur visibles.

### `reports/gameplay/fg_079_selbrume_dynamic_shop_golden_slice.md`

Le présent document constitue le contenu complet du fichier texte créé. Aucun
autre fichier texte n'a été créé par le lot.

## 7. Diffs et zones précises

Résumé avant ajout du présent rapport :

```text
8 files changed, 370 insertions(+), 14 deletions(-)
```

Principales zones :

```text
selbrume/project.json
  shops.shop_port_supplies.entries
  shops.shop_port_supplies.states[after-lysa]
  shops.shop_port_supplies.states[lighthouse-alert]
  shops.shop_port_supplies.states[story-finished]

examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
  parcours avant Lysa
  parcours après Lysa et save/load
  alerte du phare et épilogue
  _SelbrumeJourney.purchaseAtPort
  _SelbrumeJourney.inspectPortShop
  _SelbrumeJourney.expectResolvedPortShop

packages/map_editor/lib/src/features/gameplay/presentation/shop_state_inspector.dart
  ValueKey des diagnostics

packages/map_editor/test/shop_editor_panel_test.dart
  renders repeated diagnostics while switching shop states
```

`git diff --check` ne signale aucune erreur.

## 8. TDD et tests ciblés

La progression rouge/verte a observé successivement :

1. absence de `shopRequests` dans le host ;
2. catalogue statique Selbrume différent du contrat attendu ;
3. résolution systématique du profil par défaut sans contexte de Facts ;
4. fonds et chemin physique incompatibles avec certains achats/retours ;
5. collision de clés de diagnostics trouvée dans l'application réelle.

Corrections minimales :

- observation des requêtes de production ;
- authoring des profils ;
- contexte de Facts typées ;
- achat d'articles financièrement atteignables ;
- résolution directe de production pour l'état fermé, car le déclencheur
  d'épilogue consomme la fenêtre physique avant une nouvelle interaction ;
- clé de diagnostic enrichie par son chemin.

Commandes et résultats :

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_player_services_test.dart
```

Résultat : sortie 0, `+1: All tests passed!`

```bash
cd packages/map_editor
flutter test test/shop_editor_panel_test.dart
```

Résultat : sortie 0, `+5: All tests passed!`

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_player_journey_e2e_test.dart
```

Résultat : sortie 0, `03:59 +6: All tests passed!`

```bash
cd examples/playable_runtime_host
dart run tool/src/selbrume_mvp_journey_verifier.dart \
  --project-root ../../selbrume \
  --output build/mvp-release/selbrume-journey-receipt.json
```

Résultat : sortie 0 ; test séquentiel interne vert en 02:56 ; reçu généré.
MVP-16 rapporte :

```text
Catalogue et achat avant Lysa, catalogue et prix modifiés après Lysa,
comptoir fermé pendant l’alerte du phare, achat dans l’état final et stock
après sauvegarde et chargement observé.
```

## 9. Analyse statique

| Package | Commande | Résultat |
|---|---|---|
| `map_core` | `dart analyze` | sortie 0, `No issues found!` |
| `map_gameplay` | `dart analyze` | sortie 0, `No issues found!` |
| `map_runtime` | `flutter analyze` | sortie 0, `No issues found!` |
| `map_editor` | `flutter analyze` | sortie 0, `No issues found!` |
| `playable_runtime_host` | `flutter analyze` | sortie 0, `No issues found!` |

## 10. Suites globales

| Package | Résultat exact | Verdict |
|---|---|---|
| `map_core` | sortie 1, `+4411 -1` | Une dette hors lot |
| `map_gameplay` | sortie 0, `+400: All tests passed!` | Vert |
| `map_runtime` | sortie 1, `+2055 ~1 -2` | Deux dettes Selbrume historiques |
| `map_editor` | sortie 1, `+4122 -1` | Même dette de budget symbolique |
| `playable_runtime_host` | sortie 1, `+122 -1` | Même dette de source Lysa |

Échecs isolés :

1. `map_core/test/event_builder_authoring_operations_test.dart` :
   `does not apply unsupported story step condition as opaque flag` attend un
   `UnsupportedError`, mais reçoit une `MapEventDefinition`.
2. `map_runtime/test/selbrume_event_v2_three_source_integration_test.dart` :
   `canonical Selbrume: Lysa NPC dispatches its authored Scene once` échoue
   avec `Bad state: Too many elements`.
3. `map_runtime/test/selbrume_narrative_campaign_outcome_matrix_test.dart` :
   verdict attendu `pass`, obtenu `indeterminate` avec
   `Le budget symbolique global de 16384 états est dépassé`.
4. `map_editor/test/selbrume_narrative_validator_test.dart` : même diagnostic
   `narrativeSolvabilityIndeterminate`.
5. `playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart` :
   `SEL-FIN-00 canonical Selbrume loads and plays the Lysa Golden Slice`,
   rattaché au doublon de source Lysa.

Un premier lancement parallèle du test global du host a aussi échoué avant
exécution sur le verrou Flutter et la suppression de
`ios/Flutter/ephemeral/Packages/.packages`. Le relancement séquentiel ci-dessus
est la mesure retenue.

Ces échecs ne traversent aucun fichier modifié par FG-079, sauf qu'ils chargent
le fixture Selbrume partagé. Le solveur symbolique ne consulte pas les shops ;
les profils ajoutés ne peuvent donc pas créer ses branches. Ils ne remettent
pas en cause les contrôles ciblés du lot, mais empêchent honnêtement de déclarer
la totalité du monorepo verte.

## 11. QA visuelle

Procédure :

1. copie jetable du projet vers
   `/Users/karim/Library/Containers/com.example.mapEditor/Data/Documents/fg079-shop-qa-20260723` ;
2. lancement macOS instrumenté avec Marionette ;
3. navigation World Explorer → Narrative Studio → Boutiques ;
4. chargement du catalogue réel ;
5. sélections successives `after-lysa`, `lighthouse-alert`, puis
   `after-lysa` ;
6. capture et inspection visuelle.

Le SHA-256 de `project.json` est resté identique avant/après :

```text
d3a8d38e05fab52e8e10b2bc5538cf4bc2892cc0862f8cf17f6f275fb56e3258
```

La machine expose une surface applicative maximale de 1920 × 920 ; la capture
réelle ne peut donc pas atteindre 1920 × 1080. Le test widget ciblé valide
néanmoins la surface 1920 × 1080. La capture confirme :

- hiérarchie quatre zones ;
- état sélectionné lisible ;
- catalogue à trois produits ;
- conditions et priorité visibles ;
- inspecteur complet ;
- aucune exception Shop Builder après le correctif.

Limite observée hors lot : le World Explorer initial émet des `RenderFlex
overflow` de 29 et 26 pixels dans `map_workspace_empty_state.dart:206`. Aucun
overflow n'a été observé dans le Shop Builder.

## 12. Auto-critique et risques

### Points solides

- la preuve traverse le service physique et le contrôleur runtime réel ;
- elle observe le profil remis au host et la mutation finale du GameState ;
- elle couvre une sauvegarde/reprise réelle ;
- aucune marque de progression ad hoc n'a été ajoutée ;
- le bug visuel trouvé manuellement est couvert par un test reproductible.

### Limites

- l'état fermé est résolu avec le résolveur de production sur le GameState
  vivant plutôt que par une seconde interaction physique : l'épilogue démarre
  immédiatement au retour au port et ferme cette fenêtre d'interaction ;
- la capture réelle est 1920 × 920 à cause de l'écran disponible ;
- les suites globales ne sont pas entièrement vertes pour les dettes listées ;
- le reçu produit avant commit référence encore le HEAD initial
  `c81d8d04c0`, ce qui est attendu ; un release gate final devra être relancé
  depuis un arbre propre après commit.

### Risques

- les changements futurs des Facts de campagne peuvent rendre un profil
  inatteignable ; le parcours E2E doit rester le garde-fou ;
- toute nouvelle carte de diagnostic doit conserver une clé unique par chemin ;
- le packaging final ne doit pas intégrer par accident les 54 artefacts
  utilisateur non suivis.

## 13. État de clôture et suite recommandée

FG-074 à FG-079 peuvent être proposés `DONE`. FG-079 ne dépend plus d'un
catalogue statique et répond au besoin produit : tout le comptoir peut changer
avec l'état du jeu.

La prochaine action séparée est un lot de remise au vert :

1. corriger le doublon de source Lysa ;
2. revoir le budget/algorithme du validateur narratif ;
3. aligner le contrat Core de Story Step ;
4. obtenir un arbre propre sans absorber les fichiers utilisateur ;
5. relancer le vérificateur et le package release sur le commit final.
