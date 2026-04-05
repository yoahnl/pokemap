# Step Studio — consolidation passe 2 (ingénierie conservatrice)

**Date :** 2026-04-05  
**Objectif :** resserrer le statut des données, supprimer le flou « système riche vs réalité branchée », sans refonte UI ni nouveaux concepts.

---

## 1. Pourquoi cette passe était nécessaire

La passe 1 a correctement posé la structure (palette / canvas / inspecteur) et la séparation Step ≠ Cutscene. En contrepartie, plusieurs éléments laissaient entendre une **couche de vérité** là où il n’y avait que de l’**annotation auteur** ou de la **persistance JSON** :

- Les champs `flow*Label` et `flowUnlocksStepId` n’avaient pas de statut contractuel explicite (risque de les brancher un jour au runtime par erreur).
- La palette dupliquait l’accès à l’activation (« Entrée » vs « Moteur d’activation ») sans valeur additive réelle.
- Les libellés « branche locale », « sortie », « step suivante » pouvaient être lus comme des mécanismes exécutables plutôt que comme de la documentation ou du modèle structuré honnête.

Cette passe **ne change pas le schéma JSON** ni la forme générale de l’UI : elle clarifie la **sémantique** et supprime les **signaux trompeurs**.

---

## 2. Flous de la passe précédente (ciblés)

| Flou | Risque |
|------|--------|
| `flow*` présentés comme enrichissement « métier » sans dire *non runtime* | Interprétation comme règles jouables. |
| `flowUnlocksStepId` + libellés type « step suivante » / « débloquer » | Croyance en un moteur de déblocage parallèle. |
| « Branches locales » | Confusion avec branches d’exécution Cutscene ou graphe Global Story. |
| Deux entrées palette pour l’activation | Suggestion de deux sources de vérité distinctes. |
| `step_studio_workspace.dart` qui grossit | Responsabilités implicites ; tentation de « tout mettre ici ». |

---

## 3. Vraie source de vérité dans le modèle (telle qu’exposée aujourd’hui)

Dans **ce dépôt**, le document Step Studio v1 est stocké dans les métadonnées du scénario global (`authoring.stepStudioDocument`).  

**Famille A — champs structurés à sémantique technique explicite** (modes, IDs, listes typées) :

- `id`, `name`, `description`, `order`
- `activation`, `completion`
- `cutscenes` (références par id + rôle)
- `outcomes` (`outcomeId`, `scope`, `label`)
- `worldChanges`

C’est ce qui décrit **l’intention** d’authoring la plus proche d’un futur branchement moteur. Rien n’indique ici que le gameplay consomme déjà tout ce schéma de bout en bout ; en revanche, **la projection narrative** (`buildNarrativeWorkspaceProjection`) dérive des résumés et des IDs d’outcomes à partir de ces champs — **pas** à partir des `flow*`.

**Famille B — annotations auteur / canvas** :

- `flowEntryLabel`, `flowObjectiveLabel`, `flowValidationLabel`, `flowExitLabel`
- `flowUnlocksStepId`

Elles sont **sérialisées** et **affichées** dans Step Studio uniquement. Elles **n’apparaissent pas** dans `NarrativeStepSummary` et **ne sont pas référencées** par `map_gameplay` / `map_runtime` dans ce monorepo (recherche exhaustive au moment de la passe).

---

## 4. Statut exact des champs `flow*Label` et `flowUnlocksStepId`

| Champ | Nature | Consommateurs (repo actuel) |
|--------|--------|-----------------------------|
| `flowEntryLabel` | Texte libre, aide lecture / canvas | Step Studio UI |
| `flowObjectiveLabel` | Texte libre optionnel ; peut recouper `description` | Step Studio UI |
| `flowValidationLabel` | Texte libre ; parallèle **non substitut** à `completion` | Step Studio UI |
| `flowExitLabel` | Texte libre, conséquence narrative / design | Step Studio UI |
| `flowUnlocksStepId` | Id d’une autre step du **même** document | Step Studio UI (dropdown + canvas) |

**Verdict :** ni « donnée canonique runtime », ni « logique métier exécutable » — **annotations d’authoring persistées**, utiles au **no-code lisible**, à ne **pas** utiliser comme déclencheur tant qu’aucun pipeline explicite ne les lit.

---

## 5. Ce qui a été conservé

- Architecture en trois zones (palette, canvas, inspecteur).
- Modèle `StepStudioStep` inchangé au niveau des **noms** de champs et de la **forme** JSON.
- Rôles Cutscene comme **références** ; pas d’édition de scène dans Step Studio.
- Slots d’inspecteur existants (cutscene link, outcome local/progression, monde, etc.).

---

## 6. Ce qui a été clarifié (code + UI)

- **Documentation de classe** sur `StepStudioStep` : distinction explicite familles A / B, mention que la projection narrative n’expose pas les `flow*`.
- **Commentaires** sur chaque champ `flow*` et `flowUnlocksStepId` : statut « note auteur » ou « mémo », limites volontaires.
- **Palette** : fusion conceptuelle « Entrée & activation » (une seule tuile) ; libellés d’**outcomes** qui disent qu’il s’agit d’entrées dans `outcomes` avec un `scope`.
- **Canvas** : pied de carte « Validation » et « Sortie » rappelant la source technique vs annotation ; texte explicite pour `flowUnlocksStepId`.
- **Inspecteur** : titres / sous-titres / libellés de champs alignés sur la réalité (annotation vs `activation` / `completion`).
- **Footnote** du workspace : rappel court que les textes flux sont des notes auteur.
- **En-tête de fichier** `step_studio_workspace.dart` : périmètre volontaire du monolithe et critère de non-découpage prématuré.

---

## 7. Ce qui a été retiré

- **`StepFlowSlot.activationEngine`** et la tuile palette associée : redondante avec l’inspecteur « Entrée & activation », qui inclut déjà `_buildActivationSection`.
- **Illusion** d’une double porte d’entrée « égale » pour l’activation (une seule entrée utilisateur reste).

---

## 8. Ce qui a été volontairement laissé inchangé

- Aucun nouveau fichier module « pour faire propre » sans second consommateur.
- Pas de modification de Global Story Studio, Cutscene Studio, ni shell narratif.
- Pas d’évolution du schéma `StepStudioDocument` ni des clés metadata.
- Tests : aucun changement de comportement attendu côté assertions existantes (l’enum en moins n’était pas sérialisé).

---

## 9. Ce qui n’a PAS été ajouté (et pourquoi)

- **Aucun** champ « future-proof » pour du runtime dérivé des `flow*`.
- **Aucun** lien automatique `flowUnlocksStepId` → activation de la step cible (ce serait un **nouveau** moteur, non demandé et non spécifié).
- **Aucune** projection des `flow*` vers `NarrativeStepSummary` sans besoin produit explicite (éviter de donner une fausse centralité).
- **Aucun** graphe de branches locales au-delà de la liste d’outcomes `local` (reste la vérité structurelle actuelle).

---

## 10. Comment éviter les abstractions non branchées à l’avenir

1. **Toute nouvelle clé JSON** : exiger en revue « qui lit ? » (fichier + couche). Si la réponse est « personne », refuser ou marquer `experimental` avec garde-fou.
2. **Toute nouvelle tuile palette** : doit soit **muter** une liste / objet du modèle, soit **focus** un champ déjà défini — pas de « focus décoratif ».
3. **Vocabulaire UI** : éviter « débloque », « active », « branche runtime » pour des champs qui ne font qu’annoter.
4. **Duplication texte** (`description` vs `flowObjectiveLabel`) : acceptée tant qu’elle est **étiquetée** comme redondance optionnelle, pas comme deux vérités contradictoires obligatoires.

---

## 11. Risques restants

- **Dette cognitive** : malgré les textes, un utilisateur peut encore croire que remplir `flowUnlocksStepId` « fait quelque chose » dans le jeu — seul un **runtime** qui documente ses entrées levera l’ambiguïté définitivement.
- **`step_studio_workspace.dart` reste long** : le commentaire de périmètre aide, mais la densité du fichier peut encore décourager la revue ; le risque est maîtrisé tant qu’on n’y ajoute pas de logique hors Step Studio.
- **Tests** : en environnement où `flutter test` échoue pour des raisons d’I/O (éphemeral), la validation automatique peut être absente localement — à rejouer sur une machine saine.

---

## 12. Prochaines étapes légitimes (hors scope de cette passe)

- Décider **côté produit / moteur** si les `flow*` doivent **rester** editor-only ou devenir une **vue dérivée** de champs techniques (génération one-way, jamais l’inverse sans spec).
- Si le runtime consomme le document Step : documenter **le mapping exact** (quels champs, quelles transitions) dans un module partagé — pas dans Step Studio seul.
- Extraire des widgets d’inspecteur **seulement** quand un second écran les réutilise.

---

*Fin du rapport — passe 2 consolidation, sans élargissement de scope.*
