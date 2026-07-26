# RM-014 — Story-to-Credits Golden E2E V0

Date : 2026-07-26
Phase : 1 — Fin de partie jouable
Lot : `RM-014`
Liens canoniques : `FG-147`, `FG-182`
Verdict du lot : **DONE proposé**
Verdict de Phase 1 : **en attente de la gate complète**

## 1. Résultat

La preuve desktop installée couvre désormais, dans un seul parcours :

1. construction et installation d'un paquet data-only ;
2. découverte du jeu dans le Hub ;
3. ouverture du player installé ;
4. lancement d'une Nouvelle partie ;
5. déplacement physique jusqu'au milestone terminal ;
6. persistance de `fact_mist_source_resolved` ;
7. sauvegarde manuelle ;
8. retour au titre et Continue ;
9. rechargement de la position et du fait ;
10. déplacement physique jusqu'au trigger terminal ;
11. completion avec checkpoint `SaveStatus.completed` ;
12. affichage du résultat localisé ;
13. affichage des crédits canoniques Selbrume ;
14. retour au Hub ;
15. réouverture du player ;
16. refus de Continue conformément à `returnToHub`.

Le test ne modifie jamais directement le `GameState`. Les seules actions de
jeu sont des taps, des commandes clavier et les APIs publiques du Hub. Les
snapshots et fichiers de sauvegarde ne sont utilisés qu'en observation.

## 2. Audit initial

### Couverture existante

`integration_test/runtime_owned_player_flow_test.dart` prouvait déjà :

- installation d'un paquet ;
- ouverture du Hub et du player ;
- Nouvelle partie ;
- boutique et soin ;
- menu pause ;
- sauvegarde ;
- retour au titre ;
- Continue et restauration ;
- retour manuel au Hub.

### Manques RM-014

- aucune scène `Finish Game` dans la fixture ;
- aucun événement terminal ;
- aucun résultat ;
- aucun écran de crédits ;
- aucun checkpoint `completed` ;
- aucune preuve de la politique postgame après réouverture ;
- aucune parité entre la fixture compilée et le contrat terminal de Selbrume.

### Contraintes découvertes

L'application d'intégration macOS est sandboxée et ne peut pas lire le dépôt
après son lancement. La fixture reste donc une projection data-only compilée
dans le test. Un test de parité lit le dépôt avant packaging et compare le
`SceneFinishGameConsequence.toJson()` de la projection à celui de
`selbrume/project.json / scene_ending_port`.

## 3. Décisions et non-objectifs

### Décisions

- Deux triggers physiques composent la tranche terminale :
  `trigger_selbrume_milestone`, puis `trigger_selbrume_terminal`.
- Le milestone pose `fact_mist_source_resolved`.
- L'événement terminal exige ce fait et reste `oneShot`.
- La conséquence terminale est strictement identique à celle authorée dans
  Selbrume : ending, outcome, ordre de commit, résultat, crédits et policy.
- La preuve de non-continue postgame passe par
  `HubPlayerSaveGateway.readSummary`, qui porte la sémantique joueur, et non
  par le simple statut d'intégrité de `SaveSlotRead`.
- Le viewport d'intégration est fixé à `1280×800`, taille desktop explicite et
  reproductible.

### Non-objectifs

- La fixture compacte ne remplace pas le parcours campagne complet Selbrume
  de `examples/playable_runtime_host`.
- Aucun raccourci de progression, seed forgé ou mutation directe de save
  n'est ajouté.
- Aucun fichier produit du Hub ou du player UI n'est modifié.
- Les changements utilisateur préexistants sur le lancement automatique et
  les préférences ne font pas partie du lot et ne sont pas stagés.
- `FG-185` n'est pas promu.

## 4. TDD et diagnostic

### Rouge contractuel attendu

Après extension du test et avant extension de la fixture :

```text
Timed out waiting for narrative fact fact_mist_source_resolved.
```

Ce rouge prouvait que le paquet installé ne contenait aucune route narrative
terminale.

### Fragilités historiques corrigées dans le test

Les premiers replays ont aussi exposé :

- un tap Hub sur « Nouvelle partie » évalué hors écran ;
- une attente ambiguë sur le libellé « Équipe », présent avant le chargement
  du détail ;
- le bouton pause « Retour au titre » sans zone cliquable à `800×600` ;
- une tentative de retrouver la carte du jeu alors que sa fiche était déjà
  ouverte après le retour Hub.

Les corrections restent dans le harness :

- `ensureVisible` et scroll explicite ;
- attente du texte spécifique « Aucun Pokémon dans l’équipe. » ;
- viewport desktop `1280×800` ;
- tap borné à la zone réellement visible ;
- réutilisation directe de la fiche ouverte.

### Clarification de contrat

`SaveSlotRead.canContinue` décrit l'intégrité du slot et reste donc vrai pour
un checkpoint valide terminé. La décision postgame est portée par
`HubPlayerSaveGateway`, qui renvoie correctement `canContinue == false` pour
`returnToHub`.

## 5. Inventaire et zones modifiées

| Fichier | Zone précise | Impact |
|---|---|---|
| `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart` | parcours après déplacement, save/reload, completion et helpers de visibilité | étend le Golden desktop jusqu'au résultat, aux crédits, au retour Hub et à la réouverture |
| `apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/project.json` | facts, deux scènes et Event Registry | ajoute milestone et contrat terminal Selbrume |
| `apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/maps/runtime_harbor.json` | `triggers` | ajoute les deux zones physiques du parcours |
| `apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart` | projection JSON compilée | maintient le payload sandboxé byte-for-byte avec la fixture disque |
| `apps/pokemap_hub/test/support/runtime_owned_player_package_fixture_test.dart` | validation fixture | ajoute la parité stricte avec `scene_ending_port` |
| `reports/gameplay/fg_147_182_story_to_credits_golden_e2e_v0.md` | nouveau rapport | preuve de clôture RM-014 |

Diff fonctionnel avant rapport :

```text
5 files changed, 720 insertions(+), 13 deletions(-)
```

## 6. Preuves traversantes

```text
Hub card
  -> installed player
  -> New Game
  -> physical move (2,2)
  -> trigger_selbrume_milestone
  -> fact_mist_source_resolved
  -> manual save
  -> title / Continue
  -> restored position + fact
  -> physical move (2,3)
  -> trigger_selbrume_terminal
  -> Finish Game
  -> completed checkpoint
  -> result
  -> credits
  -> Hub
  -> reopen player
  -> Continue disabled
```

La parité de données ajoute la relation :

```text
compiled fixture / scene_selbrume_terminal / FinishGame.toJson()
  ==
selbrume/project.json / scene_ending_port / FinishGame.toJson()
```

## 7. Validation fraîche

### Fixture et parité Selbrume

```bash
cd apps/pokemap_hub
flutter test \
  test/support/runtime_owned_player_package_fixture_test.dart \
  -r failures-only
```

Résultat exact :

```text
+3: All tests passed!
```

### Golden desktop installé

```bash
cd apps/pokemap_hub
flutter test \
  integration_test/runtime_owned_player_flow_test.dart \
  -d macos \
  -r failures-only
```

Résultat exact :

```text
+1: All tests passed!
```

### Régressions ciblées Hub

```bash
cd apps/pokemap_hub
flutter test \
  test/support/runtime_owned_player_package_fixture_test.dart \
  test/player/hub_player_save_gateway_test.dart \
  test/session/hub_session_checkpoint_committer_test.dart \
  test/session/hub_in_process_session_factory_test.dart \
  -r failures-only
flutter analyze
flutter build macos --debug
```

Résultat exact :

```text
+15: All tests passed!
No issues found! (ran in 3.2s)
✓ Built build/macos/Build/Products/Debug/PokeMap Hub.app
```

### Hygiène du diff

```bash
git diff --check -- \
  apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart \
  apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/project.json \
  apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/maps/runtime_harbor.json \
  apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart \
  apps/pokemap_hub/test/support/runtime_owned_player_package_fixture_test.dart
```

Résultat exact : aucune sortie, code `0`.

## 8. Verdicts des passes

- Audit initial : **GO**, le gap était précisément délimité à la moitié
  terminale du parcours.
- TDD : **GO**, rouge sur le fait absent puis vert après authoring de la
  fixture.
- Architecture : **GO**, aucun état n'est forgé et aucune règle Selbrume
  n'entre dans le produit.
- Parité : **GO**, le contrat de fin compact est égal au contrat canonique.
- Sauvegarde/postgame : **GO**, checkpoint terminé et Continue joueur refusé.
- UI desktop : **GO**, résultat, crédits, retour et réouverture sont observés.
- Build : **GO**, application macOS debug construite.
- Passe sub-agent : **N/A**, aucun sub-agent n'a été demandé pour ce lot.
- Critique finale : **GO RM-014**, sous réserve de la gate package complète
  encore à exécuter pour fermer la Phase 1.

## 9. État Git

### État initial du lot

Les sept modifications utilisateur préexistantes suivantes étaient présentes
et ont été laissées intactes :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

### État final attendu après le commit ciblé RM-014

Les mêmes sept modifications utilisateur restent dans le working tree. Aucun
fichier RM-014 ne doit rester non committé.

## 10. Auto-critique et risques

- La fixture est compacte : la campagne intégrale reste prouvée séparément par
  le host d'évaluation RM-013. La parité empêche néanmoins la divergence du
  contrat terminal.
- Le test desktop fixe son viewport ; il ne constitue pas un audit responsive
  du player à `800×600`.
- Le test emploie des snapshots debug uniquement pour observer position et
  fait. Il ne s'en sert pas pour progresser.
- La gate Phase 1 doit encore exécuter les suites complètes de `map_core`,
  `map_runtime`, `map_editor`, `map_player_ui`, du host et du Hub.
- Les modifications utilisateur non committées participent à la compilation
  locale mais restent explicitement hors du commit RM-014.

## 11. Statuts proposés

| Élément | Statut proposé | Motif |
|---|---|---|
| `RM-014` | `DONE` | Golden desktop installé vert de New Game au retour Hub |
| `FG-147` | `DONE proposé après gate Phase 1` | résultat/crédits et politique postgame traversés |
| critère MVP 19 | `DONE proposé après gate Phase 1` | histoire terminale réellement finissable |
| `FG-182` | `PARTIAL` | RM-014 vert, mais preuve des 19 critères réservée à RM-069 |
| `FG-185` | inchangé | aucune promotion autorisée |

Étape suivante : gate complète de Phase 1 et Evidence Pack de clôture.
