# Cutscene Studio — règles métier et techniques

## Paradigme produit (figé)

- **Gauche** : palette / bibliothèque de blocs (vocabulaire no-code).
- **Centre** : **flow vertical** guidé (pas de graphe libre, pas de pile de formulaires centrale).
- **Droite** : **inspecteur contextuel** (détail du bloc ou méta scène).
- **Branches** : modèle **Oui / Non** (ou libellés custom) — pas de spaghetti.

## Authoring vs runtime

- **Document studio** (`CutsceneStudioDocument`) : ce que l’éditeur manipule.
- **`ScenarioAsset`** : format runtime / persistance projet ; produit par le **compiler**, relu par le **parser** + metadata flow.

## Source de vérité

- **`cutsceneFlow`** non null → **canonique** (tronc + branches).
- **`blocks`** → projection **tronc principal** (`flattenMainTrunkFlowToBlocks`), tenue alignée par le workspace à chaque commit de flow.
- **Legacy** : sans `cutsceneFlow`, le flow effectif est dérivé linéairement depuis `blocks`.

## Blocs non supportés / MVP

- **Placeholder** : kinds caméra / apparition / call cutscene → `authoringPlaceholder` + métadonnée `studio.placeholderKind` ; runtime MVP avance sans effet avec message explicite.
- **Fusion de branches** : `flowMerge` — **pas** un `waitMs` à 0.
- **Advisories** (`cutsceneStudioRuntimeAdvisories`) : bandeau distinct du parse « graphe incompatible » ; informe sur choix bloqués, wait, starter, etc.

## Où vivent les choses (après passe 3)

| Fichier | Rôle |
|---------|------|
| `cutscene_studio_models.dart` | Enums, blocs, source, entrées de flow, document, parse result, trim/outcome. |
| `cutscene_studio_flow.dart` | Flow effectif, flatten, linéarisation. |
| `cutscene_studio_flow_codec.dart` | JSON flow + blocs. |
| `cutscene_studio_flow_mutations.dart` | Mutations pures (insert, move, replace, remove, branches). |
| `cutscene_studio_parser.dart` | `ScenarioAsset` → document. |
| `cutscene_studio_compiler.dart` | Document → `ScenarioAsset`. |
| `cutscene_studio_templates.dart` | Templates et démo. |
| `cutscene_studio_runtime_advisories.dart` | Messages honnêteté MVP. |
| `cutscene_studio_authoring.dart` | Barrel uniquement. |

## Évolution

- Ajouter un kind : **enum** + label + catégorie + support runtime + branche compile + test ciblé.
- Ne pas étendre le studio en modifiant **Global Story** ou le shell « parce que c’est plus vite ».

## UI (rappel)

- Le **workbench** orchestre le drag-and-drop ; les **mutations** sont dans `flow_mutations.dart` (commentaires croisés dans le workbench).
