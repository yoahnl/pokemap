# Shadow-55 — Full Shadow System Audit / Recovery Roadmap

## 1. Résumé exécutif

Shadow-55 est un audit uniquement. Aucun code de production n'a été modifié.

Diagnostic principal :

```text
Le système Shadow est techniquement cohérent, testé, et partagé runtime/editor,
mais il poursuit une mauvaise stratégie visuelle pour la cible Pokémon-like.
```

Le problème n'est pas un seul mauvais coefficient. Le problème est une combinaison :

- runtime auto-apply silencieux ;
- policy automatique trop ambitieuse ;
- classification d'assets par dimensions ;
- `projectedPolygon` visible sur des props qui demandent une décision artistique ;
- tests numériques qui valident le moteur, pas le rendu final ;
- `selbrume` contient déjà des configs d'ombres source, donc le rendu actuel n'est pas seulement du preview editor.

Conclusion produit :

```text
Mieux vaut aucune ombre statique qu'une mauvaise ombre statique.
```

Le prochain mouvement doit être une simplification contrôlée :

```text
Shadow-56 — Disable Runtime Auto Apply / Runtime Uses Authored Manifest Only
```

## 2. État réel du worktree

Commande initiale :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Résultat initial :

```text
Aucun fichier modifié ou non suivi.
```

Fichier créé par Shadow-55 :

```text
reports/shadows/shadow_lot_55_full_shadow_system_audit_recovery_roadmap.md
```

Fichiers de production modifiés :

```text
Aucun.
```

## 3. Méthode d’audit

Passes exécutées :

1. Audit architecture Shadow actuelle.
2. Audit runtime / auto-apply.
3. Audit editor / authoring / preview.
4. Audit map_core / modèles / politiques automatiques.
5. Audit visuel `selbrume` en lecture seule.
6. Diagnostic racine.
7. Plan de récupération par lots.
8. Auto-critique finale du plan.

Sources inspectées :

- code réel `packages/map_core`;
- code réel `packages/map_runtime`;
- code réel `packages/map_editor`;
- `/Users/karim/Desktop/selbrume/project.json`;
- `/Users/karim/Desktop/selbrume/maps/Selbrume.json`;
- tests ciblés Shadow.

Les rapports Shadow précédents donnent le contexte, mais le code actuel reste la vérité.

## 4. Architecture Shadow actuelle

Le système actuel contient quatre couches :

```text
map_core
  modèles, profils, footprints, familles, projections, policy automatique

map_runtime
  chargement manifest, résolution instructions, renderer Canvas

map_editor
  preview canvas, UI de config élément/instance, suggestions auto

selbrume project data
  configs Shadow déjà persistées dans project.json
```

Briques saines :

- `ProjectShadowProfile`;
- `ProjectShadowCatalog`;
- `ProjectElementShadowConfig`;
- `MapPlacedElementShadowOverride`;
- `StaticShadowFootprintConfig`;
- `resolveStaticShadowGeometry`;
- actor contact shadows.

Briques problématiques :

- `element_auto_shadow_policy` quand appliquée automatiquement ;
- `projectedPolygon` comme rendu par défaut ;
- familles automatiques `compactProp` / `tallProp` / `genericProjection` pour props ;
- runtime auto-apply dans `load_runtime_map_bundle.dart`;
- tests trop orientés géométrie, pas rendu visuel.

## 5. Runtime auto-apply : état et risques

Audit :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
line 42: applyElementAutoShadowPolicyToProject(manifest).project
```

État :

```text
Le runtime applique encore automatiquement la policy Shadow au chargement du manifest.
```

Cette application est :

- obligatoire ;
- non opt-in ;
- non visible utilisateur ;
- non sauvegardée dans le fichier source ;
- suffisante pour changer le rendu runtime par rapport au manifest authoré.

Risque :

```text
Très élevé.
```

Pourquoi :

- un rendu visuel ne doit pas être transformé silencieusement au runtime ;
- l'utilisateur ne peut pas distinguer ce qu'il a authoré de ce que le runtime injecte ;
- le debug devient confus ;
- la direction artistique devient une heuristique de chargement.

Décision recommandée :

```text
Disable par défaut.
Runtime doit utiliser le manifest tel qu'authoré.
Auto-shadow doit vivre côté editor, sur action explicite.
```

## 6. Editor authoring : état et risques

L'éditeur possède maintenant :

- preview statique ;
- UI élément ;
- UI instance ;
- footprint élément ;
- footprint instance ;
- presets rapides ;
- suggestion/backfill auto.

État :

```text
L'éditeur est le bon endroit pour proposer des ombres,
mais pas pour les appliquer sans validation claire.
```

Ce qui est récupérable :

- preview canvas ;
- champs d'édition ;
- reset ;
- overrides d'instance ;
- suggestions explicites.

Ce qui est dangereux :

- backfill massif sans audit visuel ;
- boutons auto trop faciles à appliquer sans comparaison avant/après ;
- UI devenue lourde pour un utilisateur non technique.

Décision recommandée :

```text
Transformer l'auto-shadow en workflow de suggestion :
preview -> liste de changements -> utilisateur valide -> sauvegarde explicite.
```

## 7. Renderer/runtime shapes : état et risques

Renderer actuel :

```text
ShadowRuntimeRenderer
- drawOval pour contactBlob / ellipse
- drawPath pour projectedPolygon
- bandes d'opacité pour certains projectedPolygon
```

Le renderer est techniquement sain :

- simple ;
- testable ;
- compatible Canvas ;
- partagé par instructions runtime.

Mais la shape `projectedPolygon` est visuellement dangereuse :

- forme géométrique visible ;
- peu Pokémon-like ;
- se voit fortement sur chemins texturés ;
- produit des plaques diagonales.

Décision recommandée :

```text
Garder le renderer.
Désactiver projectedPolygon comme défaut automatique.
Ne garder projectedPolygon que pour POC, debug, ou asset authoré explicitement.
```

## 8. map_core policy/projection : état et risques

`map_core` contient :

- profils Shadow ;
- footprints ;
- familles ;
- geometry core ;
- projection geometry ;
- contact ledge geometry ;
- auto policy.

Footprints :

```text
Utiles.
```

Ils permettent de définir une base d'ombre stable et restent récupérables.

Families :

```text
Utiles comme hint authoré.
Dangereuses comme classification automatique.
```

Projected polygons :

```text
Pas adaptés comme défaut Pokémon-like.
```

Ils peuvent servir :

- à un outil expérimental ;
- à un asset spécifique authoré ;
- à un debug overlay.

Ils ne doivent pas être appliqués massivement.

Auto policy :

```text
Trop agressive pour être runtime.
Acceptable seulement en suggestion editor.
```

Defaults actuels :

```text
Dangereux quand appliqués automatiquement.
Acceptables quand explicitement authorés et previewés.
```

## 9. Audit Selbrume lecture seule

Fichiers lus :

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Aucune modification effectuée.

Inventaire :

```text
totalElements: 63
withShadow: 25
withoutShadow: 38
withFamily: 21
familyNull: 42
withFootprint: 25
projectedPolygonPotential: 5
building: 16
tallProp: 2
compactProp: 3
foliage: 0
genericProjection: 0
placedTotal: 2105
placedWithShadowOverride: 0
placedWithoutShadowOverride: 2105
```

Familles :

```text
building: 16
compactProp: 3
tallProp: 2
null: 42
```

Conclusion importante :

```text
Selbrume n'a aucun shadowOverride d'instance.
Les ombres visibles viennent des configs élément et/ou du runtime auto-apply.
```

Éléments projetés potentiels :

| id | name | size | profile | family | opacity | footprint w/h | recommandation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `custom_cliff_selbrume` | custom cliff selbrume | 3x13 | default-ground-contact-blob | tallProp | 0.2 | 0.28 / 0.05 | disable/manual-review |
| `barri_re_pierre` | barrière pierre | 13x6 | default-ground-wide-ellipse | compactProp | 0.2 | 0.58 / 0.06 | disable/manual-review |
| `lampadaire` | lampadaire | 3x5 | default-ground-contact-blob | tallProp | 0.2 | 0.28 / 0.05 | disable/manual-review |
| `rock_cliff_2` | rock cliff 2 | 7x2 | default-ground-wide-ellipse | compactProp | 0.2 | 0.58 / 0.06 | disable/manual-review |
| `rock_cliff_3` | rock cliff 3 | 9x3 | default-ground-wide-ellipse | compactProp | 0.2 | 0.58 / 0.06 | disable/manual-review |

Éléments building à surveiller :

| id | name | size | opacity | scale | footprint w/h | recommandation |
| --- | --- | --- | --- | --- | --- | --- |
| `test_maison_pkm` | test maison pkm | 6x7 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `test` | test | 45x33 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | manual-review |
| `selbrum_maison_1` | selbrum maison 1 | 5x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `selbrum_maison_2` | selbrum maison 2 | 6x7 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `selbrum_maison_3` | selbrum maison 3 | 8x7 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `selbrum_maison_4` | selbrum maison 4 | 5x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `selbrum_maison_7` | selbrum maison 7 | 6x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `selbrum_maison_8` | selbrum maison 8 | 11x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `objectif` | objectif | 45x33 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | manual-review |
| `selbrume_centre_pok_mon` | selbrume centre pokémon | 8x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `selbrume_maison_6` | selbrume maison 6 | 6x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | keep contact ledge, retune |
| `le_puits` | le puits | 4x5 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | manual-review |
| `kiosque_l_gumes` | kiosque à légumes | 6x6 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | manual-review |
| `for_t_1` | forêt 1 | 25x11 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | redesign foliage/forest |
| `parasol` | parasol | 4x4 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | disable/manual-review |
| `rock_cliff_1` | rock cliff 1 | 3x4 | 0.2 | 0.72 / 0.48 | 0.6 / 0.06 | disable/manual-review |

Autres suspects :

| id | name | size | profile | family | opacity | scale | footprint w/h | recommandation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `selbrume_maison_5` | selbrume maison 5 | 7x6 | default-ground-soft-ellipse | null | 0.22 | null / null | 0.68 / 0.08 | convert building contact ledge or manual |
| `arbre_pixellab_1` | arbre pixelLab 1 | 7x7 | default-ground-soft-ellipse | null | 0.25 | null / null | 0.58 / 0.1 | foliage-specific only |
| `arbre_pixellab_2` | arbre pixelLab 2 | 5x8 | default-ground-soft-ellipse | null | 0.25 | null / null | 0.5 / 0.1 | foliage-specific only |
| `panneau` | panneau | 3x3 | default-ground-wide-ellipse | null | 0.27 | 0.92 / 0.75 | 0.72 / 0.1 | disable by default |

Conclusion visuelle Selbrume :

```text
D'après l'audit des configs, les ombres moches viennent probablement :
- des familles tallProp/compactProp sur lampadaire, barrière, rocks/cliffs ;
- de petits props classés building alors qu'ils ne devraient pas l'être ;
- de panneaux avec ellipse large et opacité 0.27 ;
- de buildings très nombreux avec contact ledge visible partout ;
- de l'auto-apply runtime qui peut réintroduire des configs non authorées.
```

Pour rendre Selbrume immédiatement plus propre :

1. Désactiver le runtime auto-apply.
2. Neutraliser les familles automatiques `compactProp` et `tallProp` par défaut.
3. Retirer les ombres automatiques de `panneau`, `lampadaire`, `barri_re_pierre`, `rock_cliff_*`, `parasol`.
4. Garder seulement player/NPC contact blob et building contact ledge très discret.

## 10. Diagnostic racine

Racine :

```text
Le système a tenté de résoudre une décision artistique avec des heuristiques globales.
```

Pourquoi les tests sont verts :

- ils vérifient les valeurs ;
- ils vérifient la stabilité JSON ;
- ils vérifient la parité runtime/editor ;
- ils vérifient le rendu Canvas de formes ;
- ils ne vérifient pas une image Pokémon-like.

Pourquoi le rendu est mauvais :

- la source de vérité visuelle n'est pas un asset/mask authoré ;
- `projectedPolygon` crée des formes géométriques visibles ;
- les familles sont attribuées trop automatiquement ;
- le runtime peut modifier le rendu au chargement ;
- `selbrume` contient des configs sur 25 éléments, avec 0 override d'instance.

## 11. Ce qui est récupérable

- Actor contact shadows.
- Profils et catalogue Shadow.
- Config élément et override instance.
- Footprint comme donnée d'authoring.
- Resolver `resolveStaticShadowGeometry`.
- Preview editor.
- Renderer Canvas simple.
- Building contact ledge, mais plus discret et uniquement pour vrais bâtiments.

## 12. Ce qui doit être désactivé

- Runtime auto-apply par défaut.
- Projected polygons automatiques.
- Auto shadows sur petits props.
- Auto shadows sur lampadaires.
- Auto shadows sur panneaux.
- Auto shadows sur rochers/cliffs décoratifs.
- Backfill massif sans validation visuelle.

## 13. Ce qui doit être supprimé ou redesigné

À supprimer ou geler :

- projected polygon comme stratégie produit principale ;
- familles automatiques comme décision finale ;
- runtime mutation du manifest.

À redesigner :

- workflow de suggestion editor ;
- audit visuel avec screenshots ;
- asset-driven shadows ;
- masks ou sprites dédiés pour assets importants.

## 14. Keep / Disable / Delete / Redesign

| Component | Decision | Why | Risk | Next action |
| --- | --- | --- | --- | --- |
| ProjectShadowProfile | Keep | modèle style partagé sain | faible | conserver |
| ProjectShadowCatalog | Keep | catalogue editor/runtime utile | faible | conserver |
| ProjectElementShadowConfig | Keep | source authoring nécessaire | moyen | conserver, usage plus strict |
| MapPlacedElementShadowOverride | Keep | exceptions utiles | faible | conserver |
| StaticShadowFootprintConfig | Keep | base au sol utile | faible | conserver |
| resolveStaticShadowGeometry | Keep | geometry pure utile | faible | conserver |
| static_shadow_projection_geometry | Redesign | produit des plaques | élevé | désactiver par défaut |
| static_shadow_family_projection | Disable | utile en debug, dangereux auto | élevé | opt-in uniquement |
| static_shadow_contact_ledge_geometry | Keep/Retune | meilleure option building | moyen | rendre très discret |
| element_auto_shadow_policy | Redesign | trop agressive runtime | élevé | editor suggestion only |
| runtime auto-apply | Disable | mutation visuelle silencieuse | très élevé | supprimer du chargement |
| editor auto-suggestion | Keep/Redesign | bon lieu de proposition | moyen | workflow avec validation |
| editor backfill use case | Disable by default | massif sans audit | élevé | manuel + preview |
| actor contact shadows | Keep | rendu acceptable joueur/PNJ | faible | conserver |
| projectedPolygon renderer | Keep for opt-in | renderer simple, pas défaut | moyen | garder pour debug/asset-specific |
| banded fill renderer | Keep for opt-in | améliore projection, ne sauve pas forme | moyen | ne pas utiliser par défaut |
| building contact ledge | Keep/Retune | discret au pied | moyen | seul défaut statique possible |
| ElementShadowSection footprint UI | Keep | authoring récupérable | moyen | simplifier plus tard |
| PlacedElementShadowOverrideSection footprint UI | Keep | exceptions utiles | moyen | simplifier plus tard |

## 15. Réponses aux questions obligatoires

1. Briques à conserver : profils, catalogues, configs, overrides, footprints, preview, actor contact, renderer simple.
2. Briques dangereuses : runtime auto-apply, auto policy runtime, projected polygons par défaut.
3. Runtime auto-apply : à supprimer du défaut, éventuellement opt-in debug plus tard.
4. Projected polygons : non, pas activés par défaut.
5. Projected polygons Pokémon-like : non, sauf asset authoré très contrôlé.
6. Bâtiments : oui, contact ledge uniquement en V0 de récupération.
7. Petits props : non, pas d'ombre automatique.
8. Lampadaires : non en auto ; éventuellement mask/asset-specific plus tard.
9. Panneaux : non en auto.
10. Arbres : éventuellement ombre légère dédiée, pas generic projection.
11. Presets/footprints : récupérables, mais doivent rester authoring, pas magie runtime.
12. Preview editor : utile, car elle doit devenir la vérité visuelle avant validation.
13. Renderer actuel : garder, mais limiter les shapes automatiques.
14. Rendre Selbrume moins moche : disable runtime auto-apply, neutraliser props, retune building contact ledge.
15. Plan : stabilisation d'abord, asset-driven ensuite.

## 16. Recommandation produit

Principe :

```text
Par défaut, seuls player/PNJ et vrais bâtiments peuvent avoir une ombre automatique.
Tout le reste doit être sans ombre, suggestion editor, ou asset-driven.
```

Les ombres Pokémon-like ne viennent pas d'une simulation globale. Elles viennent d'un compromis :

- très peu d'ombres ;
- formes simples ;
- opacité faible ;
- zones contrôlées ;
- masques/sprites dédiés pour les gros assets.

## 17. Roadmap par lots

### Shadow-56

Nom : Disable Runtime Auto Apply / Runtime Uses Authored Manifest Only

Objectif : retirer l'appel runtime à `applyElementAutoShadowPolicyToProject`.

Fichiers probablement touchés :

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- tests runtime de load bundle / host.

Interdit :

- modifier map_core models ;
- modifier Selbrume ;
- ajouter renderer.

Tests attendus :

- runtime charge manifest sans policy auto ;
- editor use case conserve l'application explicite.

Critère visuel :

- runtime ne crée plus d'ombres surprises.

Risque :

- certaines ombres disparaissent si elles n'étaient que runtime.

Pourquoi maintenant :

- c'est la source de confusion la plus grave.

### Shadow-57

Nom : Selbrume Shadow Inventory & Debug Report

Objectif : produire un outil/report lecture seule qui liste instructions runtime générées par élément.

Fichiers probablement touchés :

- outil test ou report sous `reports/shadows`;
- éventuellement test helper runtime sans production.

Interdit :

- modifier project.json ;
- modifier runtime behavior.

Tests attendus :

- audit script/test stable.

Critère visuel :

- savoir exactement quelle ombre vient de quel asset.

Risque :

- aucun visuel immédiat.

Pourquoi maintenant :

- il faut arrêter de deviner.

### Shadow-58

Nom : Disable Unsafe Static Auto Families

Objectif : policy auto ne suggère plus `compactProp`/`tallProp` par défaut pour petits props.

Fichiers probablement touchés :

- `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`
- tests policy.

Interdit :

- runtime auto mutation ;
- renderer.

Tests attendus :

- lampadaire/panneau/rock/barrière ne reçoivent pas d'ombre auto.

Critère visuel :

- moins de plaques parasites.

Risque :

- moins d'ombres visibles.

Pourquoi maintenant :

- mieux vaut absence que mauvais rendu.

### Shadow-59

Nom : Selbrume Screenshot Harness Before/After

Objectif : créer une validation screenshot ciblée pour juger le rendu réel.

Fichiers probablement touchés :

- tests host ou outil screenshot ;
- rapport visuel.

Interdit :

- changer ombres pour faire passer le test sans revue.

Tests attendus :

- génération screenshot stable ou smoke test documenté.

Critère visuel :

- chaque lot futur doit produire un avant/après.

Risque :

- stabilité CI/screenshot.

Pourquoi maintenant :

- les tests numériques ont échoué comme garde-fou produit.

### Shadow-60

Nom : Building Contact Ledge Minimal Retune

Objectif : rendre building contact ledge plus discret et attaché au pied.

Fichiers probablement touchés :

- `static_shadow_contact_ledge_geometry.dart`
- tests core/runtime/editor.

Interdit :

- projected long shadows.

Tests attendus :

- dimensions plus courtes/faibles ;
- buildings gardent une ombre minimale.

Critère visuel :

- maison ne projette plus une plaque sur le chemin.

Risque :

- ombre trop faible.

Pourquoi maintenant :

- bâtiments sont le cas dominant restant.

### Shadow-61

Nom : Asset-Driven Shadow POC for 3 Assets

Objectif : tester maison, lampadaire, panneau avec mask/sprite/shape authoré.

Fichiers probablement touchés :

- map_core authoring minimal ou fixture test ;
- renderer opt-in si nécessaire ;
- rapport visuel.

Interdit :

- généraliser avant preuve.

Tests attendus :

- 3 assets ont rendu stable.

Critère visuel :

- doit ressembler nettement plus à la cible.

Risque :

- nouveau pipeline asset.

Pourquoi maintenant :

- seule voie crédible pour rendu Pokémon-like.

### Shadow-62

Nom : Editor Shadow Suggestion Workflow, No Runtime Mutation

Objectif : déplacer l'auto-shadow dans un workflow editor explicite.

Fichiers probablement touchés :

- use case editor ;
- UI suggestion ;
- tests widget/application.

Interdit :

- runtime apply.

Tests attendus :

- suggestion visible ;
- application volontaire ;
- pas de mutation silencieuse.

Critère visuel :

- utilisateur contrôle les ombres.

Risque :

- UI plus longue.

Pourquoi maintenant :

- restaurer confiance authoring.

### Shadow-63

Nom : Manual Approval / Batch Apply UI

Objectif : liste des suggestions avec keep/disable/apply.

Fichiers probablement touchés :

- UI editor ;
- application use case.

Interdit :

- batch invisible.

Tests attendus :

- actions par élément.

Critère visuel :

- aucun asset ne reçoit une ombre sans validation.

Risque :

- complexité UI.

Pourquoi maintenant :

- nécessaire avant mass application.

### Shadow-64

Nom : Visual Golden Slice

Objectif : figer une capture `selbrume` acceptable.

Fichiers probablement touchés :

- test screenshot/golden ;
- reports.

Interdit :

- snapshots flous ou non déterministes.

Tests attendus :

- smoke/golden ciblé.

Critère visuel :

- capture approuvée par humain.

Risque :

- entretien golden.

Pourquoi maintenant :

- empêcher une nouvelle dérive.

## 18. Premier lot recommandé après audit

```text
Shadow-56 — Disable Runtime Auto Apply / Runtime Uses Authored Manifest Only
```

Prompt proposé :

```text
Exécuter Shadow-56.
Objectif : retirer l'application automatique de applyElementAutoShadowPolicyToProject dans map_runtime.
Le runtime doit charger le ProjectManifest authoré sans mutation Shadow.
Ne pas modifier map_core models, map_editor UI, renderer, Selbrume.
Ajouter/adapter les tests pour prouver :
- loadProjectManifestFromFile retourne le manifest décodé sans backfill Shadow ;
- applyElementAutoShadowSuggestionsToProject reste disponible côté editor ;
- aucun projected/static shadow n'est ajouté par le runtime si absent du manifest.
Créer un rapport reports/shadows/shadow_lot_56_disable_runtime_auto_apply.md.
Aucun commit.
```

## 19. Tests et commandes lancées

Commandes d'audit :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "applyElementAutoShadowPolicyToProject|applyElementAutoShadowSuggestionsToProject|buildElementAutoShadowSuggestion" packages
rg -n "projectedPolygon|ProjectedStaticShadow|resolveProjectedStaticShadowGeometry|createProjectedStaticShadowOpacityBands" packages/map_core packages/map_runtime packages/map_editor
rg -n "StaticShadowFamily|resolveStaticShadowFamily|resolveStaticShadowFamilyProjectionSpec" packages/map_core packages/map_runtime packages/map_editor
rg -n "resolveBuildingStaticShadowContactLedgeGeometry|contact ledge|ContactLedge|contactLedge" packages
rg -n "ShadowRuntimeShapeKind|ShadowRuntimeRenderInstruction|drawPath|drawOval|band|opacityBand" packages/map_runtime/lib/src/shadow
rg -n "EditorStaticShadowPreviewInstruction|paintEditorStaticShadowPreviewInstructions|drawPath|drawOval|opacityBand" packages/map_editor/lib/src
```

Commandes Selbrume :

```bash
jq -c '{...}' /Users/karim/Desktop/selbrume/project.json
jq -c '[.. | objects | select(has("shadowOverride"))] ...' /Users/karim/Desktop/selbrume/maps/Selbrume.json
jq -r '.elements[] | select(.shadow!=null) | ...' /Users/karim/Desktop/selbrume/project.json
```

Tests :

```bash
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_runtime && flutter test test/shadow
```

## 20. Résultats des tests

`map_core` :

```text
00:01 +283: All tests passed!
```

`map_editor` :

```text
00:01 +96: All tests passed!
```

`map_runtime` :

```text
00:02 +233: All tests passed!
```

Interprétation :

```text
Les tests Shadow sont verts.
Ils ne contredisent pas le mauvais rendu visuel.
Ils prouvent surtout que le système actuel fonctionne comme codé.
```

## 21. git status initial/final

Initial :

```text
Aucun fichier modifié ou non suivi.
```

Final attendu après création du rapport :

```text
?? reports/shadows/shadow_lot_55_full_shadow_system_audit_recovery_roadmap.md
```

## 22. Risques / réserves

- L'audit Selbrume est config-based, pas screenshot-based.
- Les instructions runtime finales n'ont pas été dumpées instance par instance dans ce lot.
- Le rapport recommande une simplification, pas une solution finale.
- Les screenshots restent indispensables pour juger Shadow-56+.

## 23. Auto-critique du rapport

Points forts :

- code réel inspecté ;
- runtime auto-apply identifié ;
- Selbrume audité en lecture seule ;
- roadmap orientée stabilisation ;
- tests lancés sans correction.

Limites :

- pas de visual golden ;
- pas de dump complet des instructions runtime par instance ;
- pas de comparaison image avant/après ;
- pas de POC asset-driven dans ce lot, volontairement.

## 24. Regard critique sur les lots Shadow précédents

Les lots précédents ont posé des fondations réutilisables :

- modèles ;
- JSON ;
- preview ;
- runtime/editor parity ;
- tests.

Mais ils ont aussi créé une dérive :

- trop de lots ont ajouté une couche plutôt que supprimer une mauvaise hypothèse ;
- le système a été validé par tests unitaires plutôt que par screenshot réel ;
- l'auto runtime a brouillé la frontière entre authoring et rendu ;
- les projections polygonales ont été améliorées au lieu d'être questionnées assez tôt.

Synthèse :

```text
Architecture récupérable.
Politique visuelle à simplifier fortement.
```

## 25. Proposition de prompt pour le lot suivant

```text
# Shadow-56 — Disable Runtime Auto Apply / Runtime Uses Authored Manifest Only

Lot audit-followup / stabilization.

Objectif :
- retirer l'application automatique de applyElementAutoShadowPolicyToProject dans map_runtime ;
- le runtime doit charger le manifest tel qu'il est authoré ;
- l'auto-shadow reste disponible côté editor uniquement, sur action explicite.

Autorisé :
- packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
- tests runtime liés au chargement manifest / bundle
- rapport reports/shadows/shadow_lot_56_disable_runtime_auto_apply.md

Interdit :
- map_core models/codecs
- map_editor UI
- renderer shadow
- Selbrume project.json/maps
- nouveaux profils Shadow
- nouvelle projection
- commit

Tests :
- prouver que loadProjectManifestFromFile ne backfill plus les shadows ;
- prouver qu'un manifest sans shadow reste sans shadow côté runtime load ;
- prouver que applyElementAutoShadowSuggestionsToProject reste un use case editor séparé ;
- flutter test ciblé map_runtime shadow/load ;
- dart test map_core test/shadow si nécessaire.

Critère produit :
- plus aucune ombre statique ne doit apparaître seulement parce que le runtime a décidé de l'ajouter.
```
