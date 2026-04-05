# Cutscene Studio — passe stabilisation / honnêteté runtime (2026-04)

Rapport d’ingénierie pour la **deuxième passe** demandée : garder le paradigme produit (palette / flow / inspecteur, branches guidées), **sans** élargir le scope hors Cutscene Studio, en réduisant la dette « graphe qui ment » et en clarifiant la source de vérité des données.

---

## 1. Ce qui était bien dans l’itération précédente

- **Paradigme produit** : gauche bibliothèque, centre flow vertical lisible, droite inspecteur contextuel — aligné no-code.
- **Modèle de flow** avec `CutsceneFlowEntry` (bloc + choix binaire + sous-listes Oui/Non) et persistance JSON sous `kCutsceneStudioFlowMetadataKey`.
- **Compilation** vers `ScenarioAsset` avec nœuds `choice` et reprise du graphe via métadonnées (meilleure fidélité que le seul parse linéaire).
- **Séparation authoring / runtime** conceptuelle (document studio vs graphe scénario).
- **Workbench** documenté (intentions UX, rôles des colonnes).

---

## 2. Ce qui n’allait pas

- **`cutscene_studio_authoring.dart` monolithique** (~2200 lignes) : modèles, codecs, parse, compile, mutations, templates — difficile à naviguer.
- **Faux signal runtime** : fusions de branches et stubs palette compilés en **`waitMs` + 0 ms**, ce qui suggère une « vraie » attente alors qu’il s’agissait de bricolage structurel ou d’absence d’implémentation.
- **`cutsceneStudioBlockRuntimeSupported` désaligné** : par ex. `moveCharacter` marqué « non supporté » alors que l’exécuteur MVP sait exécuter `moveCharacter`.
- **Visibilité limitée** pour l’auteur : pas de bandeau central expliquant ce que l’exécuteur MVP fera réellement (choix bloqués, placeholders, etc.).

---

## 3. Pourquoi le scope était trop large (rappel)

La consigne initiale de refonte avait tendance à entraîner des retouches **Global Story Studio**, shell global, layout général, suppressions de fichiers périphériques — hors besoin strict pour livrer un studio cutscene propre. Cette passe **ne reprend pas** ces chantiers : seuls Cutscene Studio + le minimum côté **runtime** pour honorer les nouveaux `actionKind` ont été touchés.

---

## 4. Ce qui a été retiré / recentré

- **Suppression du `wait 0 ms` factice** pour fusions et stubs (voir §9).
- **Démo template** : retrait d’un bloc « Attendre » purement décoratif dans le flow démo (réduit le bruit d’avertissements sans changer l’intention pédagogique).
- **Aucune modification** de Global Story Studio, shell éditeur global, ou tests narratifs hors `cutscene_studio_authoring_test.dart` dans cette passe.
- **Fichier dédié** `cutscene_studio_runtime_advisories.dart` pour les messages « honnêteté runtime », sans alourdir le cycle d’imports du monolithe.

---

## 5. Nouvelle architecture retenue (niveau packages)

| Zone | Rôle |
|------|------|
| `cutscene_studio_authoring.dart` | Toujours le **hub** : constantes, modèles, codecs, parse, compile, mutations, templates — avec **en-tête** structurant les « chapitres » du fichier. |
| `cutscene_studio_runtime_advisories.dart` | Analyse **lecture seule** du document → liste de messages pour le bandeau UI. |
| `map_runtime` — `scenario_runtime_executor.dart` | Deux `actionKind` explicites : `flowMerge`, `authoringPlaceholder`. |

> **Découpage physique complet** du monolithe (fichiers séparés pour compile / parse / codecs) reste une **prochaine étape** naturelle ; la logique est déjà segmentée par commentaires et par le fichier d’avis.

---

## 6. Répartition des responsabilités (par fichier / zone)

- **`cutscene_studio_authoring.dart`**  
  Schéma, blocs, document, flow, JSON flow, templates, `parseScenarioToCutsceneStudioDocument`, `buildScenarioFromCutsceneStudioDocument`, mutations de flow (`insertMainFlowEntryAt`, `moveMainFlowEntry`, `insertIntoChoiceBranch`, …), helpers d’outcome.
- **`cutscene_studio_runtime_advisories.dart`**  
  Parcours du flow effectif, classification des blocs « placeholder / wait / choice / autre » → textes pour l’UI.
- **`cutscene_studio_workspace.dart`**  
  Hydratation projet, synchro `cutsceneFlow` + `blocks`, bandeau compat parse + **bandeau honnêteté runtime**.
- **`cutscene_studio_workbench.dart`**  
  Présentation trois colonnes ; commentaires DnD pointant vers les **APIs de mutation** dans l’authoring.
- **`map_runtime` / `scenario_runtime_executor.dart`**  
  Sémantique d’exécution pour `flowMerge` (passage immédiat) et `authoringPlaceholder` (passage immédiat + message).

---

## 7. Source de vérité retenue

- **Canonique** : `CutsceneStudioDocument.cutsceneFlow` lorsqu’elle est non `null` (tronc + branches).
- **Dérivé** : `blocks` = tronc principal = `flattenMainTrunkFlowToBlocks(effectiveCutsceneFlowForDocument(doc))`.
- **Legacy** : `cutsceneFlow == null` → le studio dérive un flow linéaire via `cutsceneLinearFlowFromBlocks(blocks)` à la volée ; toute édition via le workspace **matérialise** `cutsceneFlow` et resynchronise `blocks`.

Documentation ajoutée directement sur la classe `CutsceneStudioDocument`.

---

## 8. Stratégie legacy

- Graphes **sans** JSON de flow mais **linéaires** : parse historique conservé.
- Graphes **branchus sans** JSON : toujours **lecture seule** avec avertissements (on ne reconstruit pas l’arbre depuis le seul graphe).
- Nœuds **`flowMerge`** issus d’anciennes compilations : ignorés lors du **walk linéaire** du parseur (purement structurels).

---

## 9. Stratégie runtime pour blocs non supportés

| Cas | Comportement |
|-----|----------------|
| **Fusion après `choice`** | Nœud action `flowMerge` — **pas** de `waitMs`. L’exécuteur **avance tout de suite** au nœud suivant (effet gameplay nul, intention explicite). |
| **Stubs palette** (caméra, apparition, call cutscene, …) | Nœud action `authoringPlaceholder` + `metadata['studio.placeholderKind']` + message lisible dans `payload.message`. L’exécuteur **avance** sans effet, avec message explicite (plus de `wait 0`). |
| **`wait` / `starterChoice` / `playerQuestion`** | Compilation inchangée vers les kinds existants ; **avis UI** rappellent que le MVP bloque ou ne gère pas encore ces nœuds comme souhaité en jeu. |

Constantes authoring **`kCutsceneStudioActionFlowMerge`** / **`kCutsceneStudioActionAuthoringPlaceholder`** doivent rester **alignées** sur `kScenarioActionFlowMerge` / `kScenarioActionAuthoringPlaceholder` dans `map_runtime`.

---

## 10. Fonctionnement du flow et des branches

- Le **tronc** est une `List<CutsceneFlowEntry>`.
- Un **`CutsceneFlowChoiceEntry`** porte le bloc « question » + listes `onYes` / `onNo` (récursion).
- La **compilation** insère un nœud `choice`, compile chaque branche, puis un nœud **`flowMerge`** pour rejoindre la suite du tronc.

---

## 11. Drag and drop

- Les **gestes** vivent dans `cutscene_studio_workbench.dart` (payloads, `DragTarget`).
- Les **mutations** sont des fonctions **pures** dans `cutscene_studio_authoring.dart` (voir en-tête du workbench pour les noms exacts), ce qui garde la logique **testable** et évite de disperser l’état dans les widgets.

---

## 12. Composants UI principaux

- **`CutsceneStudioWorkbench`** : shell trois colonnes + bandeaux optionnels (`compatibilityBanner`, `runtimeHonestyBanner`).
- **`CutsceneStudioWorkspace`** : pont données projet, `_commitFlowEntries` (source de vérité flow + projection `blocks`), inspecteur, sauvegarde compilée.

---

## 13. Tests ajoutés / modifiés

Fichier : `packages/map_editor/test/cutscene_studio_authoring_test.dart`

- Compilation d’un flow avec **choix** : présence de nœuds **`flowMerge`**, absence de **`waitMs` à 0** utilisé comme triche.
- Stub **cameraCenter** : `actionKind == authoringPlaceholder` + métadonnée de kind.
- **Advisories** : au moins un message lié aux **choix** MVP sur la démo flow.

`map_runtime` : tests existants repassent après ajout des branches `switch` (aucun test nouveau requis pour cette passe minimale).

---

## 14. Compromis restants

- ~~**`cutscene_studio_authoring.dart`** monolithique~~ — **réalisé en passe 3** : découpage sous `application/cutscene_studio/` + barrel léger ; voir `reports/cutscene_studio_pass3_architecture.md`.
- **`authoringPlaceholder`** fait **avancer** le scénario (permet de playtester la suite) plutôt que de **bloquer** : choix produit assumé pour l’outillage ; le bandeau UI rappelle l’absence d’effet réel.
- **`playerQuestion` / nœuds `choice`** : toujours **bloqués** dans l’exécuteur MVP — connu ; l’UI le signale via les advisories.
- Dépendance **justifiée** editor → runtime : uniquement par **contrat de chaînes** documenté (pas d’import `map_editor` → `map_runtime` pour ces constantes, pour ne pas coupler les packages).

---

## 15. Prochaines étapes possibles

1. ~~**Éclater physiquement** le monolithe~~ — fait (passe 3, avril 2026).
2. **Tests d’intégration** map_runtime : scénario minimal `source → dialogue → flowMerge → end` et `source → placeholder → end`.
3. **Brancher** l’exécuteur MVP sur les **choix** (ou pipeline cutscene dédié) pour fermer l’écart signalé dans les advisories.
4. **Valider** `waitMs` au runtime si le produit doit supporter les pauses studio sans surprise.

---

*Aucune opération Git d’écriture n’a été effectuée dans le cadre de cette passe.*
