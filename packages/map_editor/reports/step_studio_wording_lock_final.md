# Step Studio — verrouillage wording final (créateur / honnêteté)

## 1. Résumé exécutif

Cette passe fige un **vocabulaire surface** cohérent pour Step Studio : lisible pour un créateur, aligné sur la logique d’étape (disponibilité, objectif, scènes liées, issues, fin, résultats d’histoire, note de transition, carte), sans prétendre que des champs mémo (`flow*`, `flowUnlocksStepId`) déclenchent quoi que ce soit automatiquement. **Aucun champ JSON nouveau**, **aucune logique runtime ajoutée**, **noms d’API et sérialisation inchangés** (enum `StepStudioOutcomeScope`, clés `flow*Label`, `scope` dans le JSON, préfixes d’`outcomeId`, etc.).

## 2. Wordings remplacés (précis)

| Zone | Avant (ou état intermédiaire) | Après |
|------|----------------------------------|--------|
| Canvas — entrée | Quand l’étape devient disponible | **Quand ça commence** |
| Canvas — objectif | Ce que le joueur doit faire | **Objectif** |
| Canvas — section scènes | Quelles scènes servent cette étape | **Scènes liées** |
| Canvas — section histoire | Ce que ça débloque pour l’histoire | **Résultats pour l’histoire** |
| Canvas — intro | « fil » | **parcours** (même honnêteté sur l’ordre de lecture) |
| Types résultat (UI) | Variante / Avancement… / Local… | **Issue de cette étape**, **Résultat pour l’histoire**, **État du monde** |
| Dropdown inspecteur outcome | Portée (historique) | **Type de résultat** (déjà en place ; options = trois libellés ci-dessus) |
| Activation — après résultat | Après un résultat d’avancement… | **Après un résultat pour l’histoire** (aligné type « résultat pour l’histoire ») |
| Résumés inspecteur | Règle appliquée | **Règle actuelle** |
| Bloc condition de fin | Règle appliquée / Règle enregistrée (redondant) | **Règle actuelle** + **Condition de fin enregistrée** (menu) |
| Note de transition | Sous-titre long + dropdown « Étape liée en mémo (…) » | **N’active rien automatiquement.** + **Étape associée (mémo uniquement)** |
| Champ transition | Texte … (visible au centre) | **Texte affiché dans le parcours** |
| Hub scènes inspecteur | Scènes pour cette étape | **Scènes liées** |
| Issues inspecteur | « Issues locales » | **Issues enregistrées pour cette étape** |
| Message mauvais type outcome | … issue locale | **… pas une issue de cette étape** (renvoie au parcours) |
| Palette — navigation issues | Issues possibles (libellé tuile) | **Issues** (sous-titre rappelle « Issues possibles ») |
| Palette — transition | Note de transition | **Transition** (sous-titre note de transition) |
| Carte — CTA | Ajouter un changement | **Ajouter un changement sur la carte** |
| Cutscene link row | Rôle | **Rôle de la scène** |
| Activation flag | État monde attendu | **État du monde attendu** |
| Erreur lien manquant | Référence de scène… | **Référence de la scène…** |
| Gabarit outcome progression | Nouveau résultat d’histoire | **Nouveau résultat pour l’histoire** |
| Empty monde | … après la step | **… après l’étape** |

Titres canvas **imposés** et présents : **Cette étape**, **Quand ça commence**, **Objectif**, **Scènes liées**, **Issues possibles**, **Quand l’étape se termine**, **Résultats pour l’histoire**, **Note de transition**, **Changements sur la carte**.

## 3. Raisons produit / UX

- **Titres courts et stables** : le parcours central lit comme une fiche d’étape, pas comme un formulaire moteur.
- **« Note de transition » + mémo** : le titre et le dropdown dissocient clairement **lecture / mémo** de toute idée de chaînage automatique ; `flowUnlocksStepId` n’est jamais décrit comme activation ou déblocage.
- **« Règle actuelle »** : décrit l’état enregistré sans la froideur de « réglage appliqué » ni l’ambiguïté de « validation » administrative.
- **Types de résultat** : « Issue de cette étape » / « Résultat pour l’histoire » / « État du monde » mappent 1:1 sur des intentions créateur sans afficher Local / Progression / Monde comme libellés UI.
- **Scène vs Cutscene Studio** : surface Step = « scène » ; l’outil de mise en scène reste nommé **Cutscene Studio** là où on renvoie l’édition dialogues / caméra.

## 4. Laissé volontairement technique dans le code

- Noms d’**enum** Dart : `StepFlowSlot.validationEngine`, `StepStudioOutcomeScope.local|progression|world`, `StepStudioCompletionMode`, etc.
- **JSON** : clés `flowEntryLabel`, `flowValidationLabel`, `flowUnlocksStepId`, `scope`, `outcomes`, `worldChanges`, ids techniques affichés quand utile (ex. référence scène, outcomeId).
- **Fonctions** : `summarizeStepActivation` / `summarizeStepCompletion` restent des chaînes de synthèse ; elles peuvent contenir des ids de données, pas des promesses runtime.
- **Préfixes `outcomeId`** (`local.` / `progression.` / `world.`) : inchangés (génération / parsing).

## 5. Explicitement NON branché comme automatique (ne pas lire comme runtime)

- Tous les champs **`flow*Label`** : texte affiché dans le **parcours** pour la lecture ; ils ne remplacent pas `activation` ni `completion`.
- **`flowUnlocksStepId`** : **mémo uniquement** dans l’inspecteur ; **absent du canvas** ; formulation **« N’active rien automatiquement »** ; aucun libellé ne dit « débloque », « enchaîne », « active la step suivante » au sens automatique.

## 6. Fichiers modifiés

- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_palette.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_focus.dart` (commentaires + honnêteté mémo)
- `packages/map_editor/test/step_flow_canvas_test.dart`
- `packages/map_editor/reports/step_studio_wording_lock_final.md` (ce fichier)

## 7. Tests exécutés

Commande :

`cd packages/map_editor && flutter test test/step_flow_canvas_test.dart`

Résultat : **OK** (titres verrouillés sur le canvas, absence de `flowUnlocksStepId` sur le canvas, garde-fous wording régressif ciblés).

## 8. Limites / risques restants

- **Couverture tests** : les interdits de wording sur **palette / inspecteur** ne sont pas tous assertés par tests widget ; seul le **canvas** est couvert finement.
- **Homonymes** : un titre comme « Objectif » peut théoriquement recouper un nom d’étape utilisateur ; acceptable pour verrouillage produit.
- **Chaînes de synthèse** (`summarizeStep*`) : affichées sur le canvas sous les cartes ; elles restent des **résumés** des règles enregistrées, pas une promesse d’exécution détaillée.

---

**Opérations Git** : aucune opération Git d’écriture effectuée dans le cadre de cette passe.  
**Données** : aucune nouvelle donnée ni schéma ; rien d’« inventé » côté runtime.
