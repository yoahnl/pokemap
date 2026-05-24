# P2-02 — Story Step Descriptor / Storyline Metadata Decision

## 1. Résumé exécutif

P2-02 décide la stratégie domaine pour Storyline / Chapter / Story Step après l'inventaire technique P2-01.

Décision recommandée :

- Option B est la trajectoire principale : préparer plus tard un adapter / read model non persistant dérivé des metadata existantes.
- Option C est acceptée uniquement comme forme conceptuelle : un StoryStepReadModel / StoryStepDescriptor non implémenté, utile pour aligner diagnostics et pickers futurs.
- Option A reste l'état actuel : les metadata Step Studio / Global Story Studio et `completedStepIds` continuent de porter la vérité disponible.
- Option D est refusée pour l'instant : pas de descriptor persistant, pas de migration `ProjectManifest`, pas de nouveau modèle `map_core`.
- Option E est refusée comme stratégie globale : tout reporter bloquerait P2-03, P2-09 et P2-10.

La complétion d'un Story Step doit rester lue depuis `completedStepIds`. Les metadata `ScenarioAsset.metadata`, `authoring.stepStudioDocument` et `authoring.globalStoryStudioDocument` restent la source authoring actuelle, mais elles doivent être encadrées par des diagnostics avant de devenir une base de workflows plus avancés.

Le prochain lot exact recommandé est :

```text
P2-03 — Event Authoring Source Contract
```

## 2. Scope du lot

Inclus :

- décision de stratégie Storyline / Chapter / Story Step ;
- comparaison metadata / adapter / descriptor / persistence / report ;
- analyse du risque de duplication de `completedStepIds` ;
- analyse de la frontière metadata `map_editor` vs domaine pur ;
- proposition de diagnostics possibles sans persistence ;
- préparation de P2-03 ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- aucun code ;
- aucun modèle `map_core` ;
- aucun descriptor implémenté ;
- aucun adapter implémenté ;
- aucun read model implémenté ;
- aucun diagnostic implémenté ;
- aucun JSON ;
- aucune migration ;
- aucun test ;
- aucun `build_runner` ;
- aucun `ProjectManifest` modifié ;
- aucun P2-03 démarré ;
- aucun contenu Selbrume final.

Fichiers créés :

```text
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_2.md
```

Fichiers explicitement non modifiés :

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
packages/map_core
packages/map_gameplay
packages/map_battle
packages/map_runtime
packages/map_editor
examples/playable_runtime_host
```

## 3. Sources lues

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md` : contexte global Phase 2, lu mais non modifié.
- `MVP Selbrume/road_map_phase_2.md` : roadmap active Phase 2 et état P2-02.
- `MVP Selbrume/road_map_phase_1.md` : vérification de la clôture Phase 1.
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md` : frontière P2-00 / P2-01 et risques de sur-modélisation.
- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` : inventaire technique détaillé servant de base principale à P2-02.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md` : décisions ouvertes au checkpoint Phase 1.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` : proposition initiale des contrats Phase 2.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` : besoins pickers / diagnostics / workflows no-code.
- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` : frontières Storyline / Chapter / Story Step.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` : distinction Fact / World Rule utile pour éviter de transformer Step en flag.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` : grammaire produit canonique.

Fichiers techniques lus en lecture seule :

- `packages/map_core/lib/src/models/scenario_asset.dart` : structure persistante actuelle des scénarios et metadata.
- `packages/map_core/lib/src/models/game_state.dart` : état runtime en mémoire, story flags et progression.
- `packages/map_core/lib/src/models/save_data.dart` : `PlayerProgression`, `completedStepIds`, normalisation save/load.
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart` : extraction runtime des chapitres depuis metadata global story.
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart` : projection passive de présence depuis Step Studio metadata et `completedStepIds`.
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart` : metadata Step Studio, legacy `step.*`, authoring editor.
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart` : metadata Global Story Studio, chapters, diagnostics editor.
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` : projection read-only existante côté editor.

## 4. Rappel P2-01

P2-01 a observé que :

- `ScenarioAsset` est le graphe scénario persistant principal.
- `ScenarioAsset.metadata` porte déjà des documents authoring.
- Step Studio écrit `authoring.stepStudioDocument`.
- Global Story Studio écrit `authoring.globalStoryStudioDocument`.
- Les anciennes metadata `step.*` existent encore comme fallback / compatibilité.
- `completedStepIds` stocke déjà la complétion de steps dans la progression.
- Global Story runtime lit les metadata Global Story et `completedStepIds`.
- Step Studio world presence lit les metadata Step Studio et `completedStepIds`.
- `NarrativeWorkspaceProjection` produit déjà une vue read-only côté editor.
- `map_editor` contient déjà beaucoup de vocabulaire no-code.
- Aucun contrat pur `map_core` Storyline / Chapter / Story Step canonique n'existe encore.

Le point le plus important pour P2-02 est que l'existant contient déjà des sources techniques utiles, mais leur statut domaine n'est pas stabilisé.

## 5. Problème à résoudre

Le projet a déjà de la donnée narrative :

- scénarios persistés via `ScenarioAsset` ;
- metadata authoring Step Studio et Global Story Studio ;
- progression stockée via `completedStepIds` ;
- projections editor ;
- petits ponts runtime pour chapitres et présence conditionnelle.

Mais le domaine pur n'a pas encore répondu à ces questions :

- faut-il formaliser Storyline / Chapter / Story Step maintenant ?
- sous quelle forme ?
- faut-il créer un descriptor ?
- faut-il le persister ?
- comment éviter de dupliquer `completedStepIds` ?
- comment éviter que des metadata editor deviennent une source de vérité cachée ?
- comment fournir diagnostics et pickers sans migrer `ProjectManifest` trop tôt ?

Le risque central est double :

- créer trop tôt un modèle propre en apparence, mais sans consumer assez clair ;
- garder des metadata implicites qui fonctionnent localement, mais qui empêchent diagnostics, pickers et authoring no-code fiables.

## 6. Sources techniques existantes

| Source | Ce qu'elle porte | Statut | Consumer actuel | Risque |
|---|---|---|---|---|
| `ScenarioAsset.metadata` | Documents authoring libres et metadata legacy | Persisté dans l'asset scénario | Editor, runtime ciblé | Source trop générale, validation dispersée |
| `authoring.stepStudioDocument` | Steps, activation, completion, cutscenes, outcomes, world changes | Metadata editor persistée dans `ScenarioAsset` | Step Studio, projection editor, world presence runtime | Devient un contrat implicite sans garantie domaine |
| `authoring.globalStoryStudioDocument` | Nodes Global Story, entry step, chapters | Metadata editor persistée dans `ScenarioAsset` global story | Global Story Studio, runtime chapter index | Chapter peut sembler runtime alors qu'il organise surtout |
| Legacy `step.*` | `step.id`, `step.name`, `step.description`, `step.cutsceneIds` | Metadata legacy | Fallback Step Studio | Incohérence possible avec le document moderne |
| `completedStepIds` | Steps complétés | État progression / save | Runtime Global Story, world presence, conditions futures | Duplication si un descriptor persistant répète la completion |
| `NarrativeWorkspaceProjection` | Summaries scenario / step / outcome read-only | Dérivé côté editor | Workspace Narrative | Bon précédent mais pas domaine pur |
| `GlobalStoryChapterStepIndex` | Index runtime chapters / steps / completion | Dérivé runtime | Runtime chapter status | Cache dérivé, pas source de vérité |
| `step_studio_world_presence_runtime` | Présence passive d'entités selon step completion | Dérivé runtime | Runtime map entities | World Rule partiel, dépendant de metadata Step Studio |

Conclusion : les sources actuelles suffisent à dériver un read model, mais ne justifient pas encore une persistence dédiée Storyline / Chapter / Story Step.

## 7. Consumers potentiels

| Consumer | Besoin | Immédiat ou futur | Nécessite persistence ? |
|---|---|---|---|
| `NarrativeValidator` | Diagnostiquer steps, chapters, références cassées, metadata incohérentes | Phase 2 | Non, peut lire metadata + progression |
| `ProjectValidator` | Agréger diagnostics projet | Phase 2 | Non |
| P2-03 Event Authoring Source | Référencer un step dans une condition d'Event sans ID brut | Phase 2 | Non, picker/read model suffisant |
| P2-04 Scene / ScenarioAsset Adapter | Relier Scene produit et ScenarioAsset | Phase 2 | Non, adapter d'abord |
| P2-07 Fact Descriptor / Presentation | Distinguer Fact durable et Step completion | Phase 2 | Non pour décider, peut dériver |
| P2-08 World Rule Predicate Adapter | Lire une completion de step comme condition passive | Phase 2 | Non |
| P2-10 Reference Picker Read Models | Alimenter pickers de Story Step / Chapter / Storyline | Phase 2 | Non, read model recommandé |
| Phase 4 authoring minimal | Afficher et relier steps sans IDs bruts | Futur | Peut commencer sans migration |
| Phase 6 Selbrume Golden Slice | Décrire "Lysa au port" avec steps et side story | Futur | Persistence dédiée possible seulement si besoin prouvé |

Le consumer le plus fort à court terme est le Validator / picker read model, pas le runtime ni la persistence.

## 8. Option A — Metadata existantes seules

Description :

Storyline / Chapter / Story Step restent portés uniquement par `ScenarioAsset.metadata`, Step Studio metadata, Global Story metadata, legacy `step.*`, `completedStepIds` et projections editor.

Avantages :

- aucun nouveau modèle ;
- aucune migration ;
- aucun risque immédiat de casser `ProjectManifest` ;
- respecte l'existant ;
- maintient `completedStepIds` comme source unique de completion ;
- compatible avec le lot documentaire P2-02.

Inconvénients :

- les metadata deviennent une source de vérité implicite ;
- diagnostics cross-cutting plus difficiles ;
- pickers futurs risquent de réimplémenter chacun leur parser ;
- la frontière `map_editor` / `map_core` reste floue ;
- le vocabulaire produit Storyline / Chapter / Story Step n'a pas de forme domaine stable.

Risques :

- Step devient un paquet de metadata editor au lieu d'un jalon compréhensible ;
- les fallbacks legacy peuvent masquer des documents invalides ;
- runtime et editor peuvent diverger dans leur lecture.

Consumers servis :

- authoring editor existant ;
- runtime partiel Global Story / world presence ;
- projections editor existantes.

Diagnostics possibles :

- diagnostics locaux editor déjà partiels ;
- diagnostics de metadata invalides possibles si le Validator lit ces metadata.

Compatibilité Phase 2 :

- acceptable comme état de départ ;
- insuffisant comme stratégie cible de Phase 2.

Verdict :

Garder comme base technique actuelle, mais ne pas s'arrêter là.

## 9. Option B — Adapter / read model non persistant

Description :

Créer plus tard une vue pure / read model dérivée des metadata existantes, sans nouveau stockage persistant et sans migration `ProjectManifest`.

Avantages :

- centralise la lecture de Step Studio / Global Story metadata ;
- donne aux validators et pickers un langage stable ;
- évite de dupliquer `completedStepIds` ;
- évite de figer trop tôt les formats JSON ;
- peut vivre côté domaine pur si isolé de Flutter / UI ;
- peut être testé sans lancer le runtime Flame ;
- prépare P2-03, P2-09 et P2-10.

Inconvénients :

- demande un lot futur d'implémentation ciblé ;
- peut glisser vers un modèle persistant déguisé si les garde-fous sont faibles ;
- doit assumer des metadata encore partiellement editor-oriented.

Risques :

- duplication de parsers si l'adapter ne remplace pas les lectures ad hoc ;
- confusion entre "read model dérivé" et "source de vérité".

Consumers servis :

- Validator ;
- Reference Picker Read Models ;
- Event Authoring Source ;
- Fact / World Rule adapters ;
- authoring minimal futur.

Diagnostics possibles :

- step absent ;
- duplicate step id ;
- chapter référence step absent ;
- completed step sans metadata ;
- metadata illisible ;
- legacy metadata incohérente ;
- step jamais activable ou jamais complétable quand les références seront auditées.

Compatibilité Phase 2 :

- très bonne ;
- respecte "adapter avant de persister".

Verdict :

Option recommandée comme trajectoire principale.

## 10. Option C — Descriptor minimal non persistant

Description :

Définir un contrat conceptuel de descriptor, dérivé ou reconstruit depuis l'existant, mais sans persistence et sans migration.

Champs minimaux conceptuels possibles :

- `stepId` ;
- label ;
- description ;
- ordre ;
- source scenario/global story ;
- chapitre parent optionnel ;
- source metadata ;
- source de completion : `completedStepIds` ;
- résumé d'activation / availability ;
- résumé de completion ;
- scénarios / cutscenes / outcomes liés ;
- diagnostics associés.

Avantages :

- donne une forme commune aux discussions P2-03+ ;
- évite que chaque lot redéfinisse "step" ;
- prépare tests et diagnostics futurs ;
- ne modifie aucun stockage.

Inconvénients :

- peut être pris à tort comme un modèle à créer immédiatement ;
- peut encourager une sur-modélisation si les champs deviennent une liste de souhaits.

Risques :

- transformer une forme conceptuelle en contrat persistant sans preuve ;
- inclure trop de champs avant d'avoir les consumers.

Consumers servis :

- documentation Phase 2 ;
- Validator futur ;
- pickers futurs ;
- P2-03 comme vocabulaire stable.

Diagnostics possibles :

- mêmes diagnostics que l'Option B, si un adapter est implémenté plus tard.

Compatibilité Phase 2 :

- bonne si explicitement non implémentée par P2-02.

Verdict :

Acceptée comme forme conceptuelle, pas comme livrable codé ni persistant.

## 11. Option D — Descriptor persistant / ProjectManifest

Description :

Ajouter plus tard des modèles persistants pour Storyline / Chapter / Story Step, potentiellement référencés par `ProjectManifest`.

Bénéfices possibles :

- source de vérité dédiée ;
- validation JSON plus directe ;
- migration vers authoring avancé ;
- meilleures garanties pour un projet disque complet.

Risques :

- migration `ProjectManifest` prématurée ;
- duplication de `completedStepIds` ;
- duplication des metadata Step Studio / Global Story ;
- rupture de compatibilité avec scénarios existants ;
- création d'un modèle sans consumer runtime clair ;
- tendance à créer un Quest Engine indirectement.

Consumers qui pourraient justifier cette option plus tard :

- authoring Phase 4 exigeant une persistence indépendante ;
- Selbrume Phase 6 exigeant un projet disque robuste ;
- migration confirmée des metadata editor vers domaine pur ;
- Validator incapable d'être fiable avec un read model dérivé.

Pourquoi ne pas le faire maintenant :

- P2-02 est documentaire ;
- P2-01 n'a pas prouvé la nécessité d'une migration ;
- `completedStepIds` porte déjà la completion ;
- `ScenarioAsset.metadata` porte déjà les documents authoring ;
- aucun consumer ne demande encore un stockage indépendant.

Conditions de déclenchement futur :

- consumer explicite ;
- migration planifiée ;
- compatibilité `ProjectManifest` documentée ;
- tests pure Dart ;
- diagnostics de migration ;
- décision utilisateur.

Verdict :

Refuser pour l'instant.

## 12. Option E — Report complet

Description :

Reporter toute formalisation Storyline / Chapter / Step après d'autres contrats.

Avantages :

- zéro risque de migration ;
- évite toute sur-modélisation immédiate ;
- laisse P2-03 traiter Event source sans dépendance nouvelle.

Inconvénients :

- P2-03 aurait besoin de référencer des steps sans forme stable ;
- P2-09 manquerait d'une base pour diagnostics Step / Storyline ;
- P2-10 manquerait d'une source pour pickers ;
- les lots suivants réinventeraient chacun leur lecture des metadata.

Risques :

- dette documentaire déplacée vers plusieurs lots ;
- décisions répétées ;
- confusion durable entre step metadata, flag, fact et completion.

Consumers servis :

- aucun consumer futur n'est vraiment mieux servi.

Diagnostics possibles :

- limités aux diagnostics existants et dispersés.

Compatibilité Phase 2 :

- acceptable seulement si P2-03 n'a aucun besoin de step reference, ce qui est improbable.

Verdict :

Refuser comme stratégie principale. Reporter la persistence, pas la décision.

## 13. Matrice comparative

| Option | Complexité | Migration | Risque duplication | Support Validator | Support pickers | Support runtime | Recommandation |
|---|---:|---:|---:|---:|---:|---:|---|
| A — Metadata seules | Faible | Aucune | Faible court terme, moyen long terme | Moyen | Faible | Déjà partiel | Base actuelle seulement |
| B — Adapter/read model non persistant | Moyenne | Aucune | Faible si completion reste `completedStepIds` | Fort | Fort | Indirect | Recommandée |
| C — Descriptor conceptuel non persistant | Faible documentaire | Aucune | Faible | Moyen à fort après adapter | Moyen à fort après adapter | Indirect | Recommandée comme forme |
| D — Descriptor persistant | Élevée | Forte | Forte sans garde-fous | Fort | Fort | Possible plus tard | Refusée maintenant |
| E — Report complet | Faible immédiat | Aucune | Moyen par lectures dispersées | Faible | Faible | Aucun progrès | Refusée comme stratégie |

## 14. Décision recommandée

Décision P2-02 :

```text
Créer maintenant : non.
Préparer un read model / adapter : oui, dans un lot futur si nécessaire.
Créer un descriptor persistant : non pour l'instant.
Modifier ProjectManifest : non.
Utiliser completedStepIds comme source de completion : oui.
Utiliser ScenarioAsset.metadata Step/Global Story comme source authoring actuelle : oui, avec diagnostics.
Reporter Quest Engine / Quest Journal : oui.
```

La stratégie retenue est :

1. continuer à lire l'existant ;
2. expliciter une forme conceptuelle de Story Step read model ;
3. ne pas créer de stockage dédié ;
4. ne pas dupliquer la progression ;
5. ajouter plus tard des diagnostics sur metadata et références ;
6. alimenter les pickers futurs depuis une vue dérivée plutôt que depuis des IDs bruts.

Cette décision respecte la phrase de référence :

```text
Décider avant de créer.
Adapter avant de persister.
Ne jamais dupliquer completedStepIds sans raison prouvée.
```

## 15. Story Step — contrat conceptuel recommandé

Le contrat recommandé est conceptuel et non implémenté par P2-02.

Nom possible :

```text
StoryStepReadModel
```

ou :

```text
StoryStepDescriptor
```

Forme conceptuelle minimale :

| Champ conceptuel | Rôle | Source recommandée | Persistence dédiée ? |
|---|---|---|---|
| `stepId` | Identité stable du jalon | Step Studio metadata, legacy fallback si nécessaire | Non |
| `label` | Nom humain | Step Studio `name` | Non |
| `description` | Intention auteur | Step Studio `description` | Non |
| `order` | Tri auteur | Step Studio `order` | Non |
| `storylineId` ou `globalScenarioId` | Parent narratif | `ScenarioAsset.id` global story / metadata | Non |
| `chapterId` | Section optionnelle | Global Story metadata chapters | Non |
| `sourceMetadata` | Provenance | `stepStudioDocument`, legacy, fallback | Non |
| `completionSource` | Vérité de completion | `completedStepIds` | Non |
| `activationSummary` | Phrase lisible d'activation | Step Studio activation / future condition adapter | Non |
| `completionSummary` | Phrase lisible de completion | Step Studio completion / Scenario effects futurs | Non |
| `relatedScenarioIds` | Liens avec scénarios | Scenario metadata / graph futur | Non |
| `relatedCutsceneIds` | Cutscenes liées | Step Studio cutscenes / legacy metadata | Non |
| `expectedOutcomeIds` | Outcomes attendus | Step Studio outcomes / ScenarioAsset declared outcomes | Non |
| `worldChangeTargets` | Projections passives | Step Studio world changes | Non |
| `diagnostics` | Problèmes détectés | Validator futur | Non |

Garde-fou central :

```text
`completedStepIds` reste la source de vérité de completion.
Le read model ne stocke pas "completed" comme vérité persistante concurrente.
```

Ce contrat n'est pas créé par P2-02.

## 16. Storyline / Chapter — statut recommandé

Storyline :

- correspond en V0 à un `ScenarioAsset` de scope `globalStory` plus les metadata Global Story ;
- peut être présenté comme une ligne narrative côté produit ;
- ne doit pas devenir un Quest Engine ;
- ne nécessite pas de persistence dédiée immédiate.

Chapter :

- correspond en V0 aux chapters du `authoring.globalStoryStudioDocument` ;
- peut être indexé par `GlobalStoryChapterStepIndex` côté runtime ;
- reste une section organisée, pas un état runtime obligatoire ;
- ne nécessite pas de modèle persistant dédié immédiat.

Recommandation :

```text
Storyline / Chapter restent metadata + vues dérivées en Phase 2 initiale.
Un adapter/read model peut être préparé plus tard pour diagnostics et pickers.
Une persistence dédiée ne doit être envisagée qu'après preuve consumer + migration.
```

## 17. Diagnostics possibles sans persistence

Diagnostics possibles sans créer de modèle persistant :

- metadata Step Studio illisible ;
- metadata Global Story illisible ;
- `stepId` vide ;
- `stepId` dupliqué ;
- step sans label humain ;
- step référencé mais absent ;
- step présent dans `completedStepIds` mais absent des metadata authoring ;
- chapter vide ;
- chapter référence un step absent ;
- entry step Global Story absent ;
- node Global Story référence un step absent ;
- lien Global Story vers node absent ;
- branch conditionnelle incomplète ;
- orphan step non atteignable ;
- step dead-end non volontaire ;
- world presence référence un step inconnu ;
- world presence cible une map ou entité absente si les sources sont disponibles ;
- Event / source future lit un step inconnu ;
- legacy `step.*` incohérent avec `authoring.stepStudioDocument` ;
- fallback legacy utilisé alors qu'un document moderne est attendu ;
- step jamais complété par une Scene connue quand P2-04/P2-09 auront l'inventaire des effets.

Ces diagnostics peuvent être ajoutés plus tard au Validator ou à une couche de validation sans persistence dédiée.

## 18. Impacts sur P2-03 à P2-10

P2-03 — Event Authoring Source Contract :

- peut référencer un Story Step via metadata/read model dérivé ;
- doit éviter de dupliquer les runtime source events ;
- doit maintenir Event = déclencheur, pas mini-Scene.

P2-04 — Scene / ScenarioAsset Adapter Contract :

- devra clarifier si Scene est ScenarioAsset ou une projection ;
- pourra relier completion de step à des effets Scene sans changer `completedStepIds`.

P2-05 — Outcome Reference Contracts :

- pourra exposer outcomes attendus / émis depuis Step Studio et ScenarioAsset.

P2-06 — Battle Reference / Outcome Contract :

- pourra associer victory / defeat à une completion de step sans stocker une seconde progression.

P2-07 — Fact Descriptor / Presentation Layer :

- devra distinguer Step completion, Fact dérivé et Fact durable.

P2-08 — World Rule Predicate Adapter :

- pourra utiliser step completion comme condition passive via `completedStepIds`.

P2-09 — Narrative Validator Diagnostic Expansion :

- devra ajouter diagnostics Step / Storyline / Chapter sur metadata existantes.

P2-10 — Reference Picker Read Models :

- pourra réutiliser la trajectoire adapter/read model décidée ici.

## 19. Risques et garde-fous

| Risque | Effet | Garde-fou |
|---|---|---|
| Metadata editor comme source cachée | Runtime / Validator lisent des formats implicites | Centraliser la lecture dans un adapter/read model futur |
| Duplication de `completedStepIds` | Deux vérités de progression concurrentes | Interdire toute completion persistée dans un descriptor |
| Adapter qui devient modèle persistant déguisé | Migration non assumée | Documenter source, dérivation et non-persistence |
| Migration `ProjectManifest` trop tôt | Churn JSON, compatibilité cassée | Exiger consumer + plan de migration + tests avant tout champ |
| Diagnostics impossibles si metadata instables | Validator incomplet | Commencer par diagnostics de lisibilité / références |
| Chapter runtime trop implicite | Chapter devient état obligatoire | Maintenir Chapter comme section, completion dérivée seulement |
| Story Step exposé comme flag technique | Mauvaise UX no-code | Toujours afficher label, description, source et completion lisible |
| Quest Engine prématuré | Scope Phase 2 absorbé | Side quest reste Storyline secondaire / metadata, pas engine |

## 20. Ce que P2-02 décide

P2-02 décide :

- pas de descriptor persistant maintenant ;
- pas de migration `ProjectManifest` ;
- pas de modèle `map_core` Storyline / Chapter / Story Step maintenant ;
- source de completion = `completedStepIds` ;
- source authoring actuelle = `ScenarioAsset.metadata`, Step Studio metadata et Global Story metadata ;
- trajectoire recommandée = adapter / read model non persistant si nécessaire ;
- Option C sert de forme conceptuelle seulement ;
- diagnostics possibles sans persistence ;
- P2-03 peut s'appuyer sur cette décision.

## 21. Ce que P2-02 ne décide pas

P2-02 ne décide pas :

- la structure finale d'un modèle `map_core` ;
- un JSON final ;
- une migration `ProjectManifest` ;
- une UI picker ;
- un Scene adapter final ;
- un FactDescriptor final ;
- un WorldRule adapter final ;
- une registry persistante ;
- un Quest Engine ;
- un Quest Journal ;
- un Selbrume réel.

## 22. Recommandation pour P2-03

P2-03 devra traiter :

```text
P2-03 — Event Authoring Source Contract
```

Recommandation P2-03 :

- réutiliser `ScenarioRuntimeSourceEvent` autant que possible ;
- ne pas dupliquer les runtime source events ;
- formaliser Event côté auteur comme source + trigger + conditions + target Scene ;
- référencer Story Step via metadata / read model dérivé, pas par modèle persistant nouveau ;
- garder Event comme déclencheur, pas comme mini-Scene ;
- ne pas modifier `ProjectManifest` sans consumer prouvé.

## 23. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` est mise à jour pour indiquer :

```text
P2-02 : ✅ terminé
P2-03 : 🔜 prochain lot exact
```

Résumé ajouté :

```text
P2-02 recommande une trajectoire adapter/read model non persistant pour Storyline / Chapter / Story Step, garde completedStepIds comme source de completion, refuse la migration ProjectManifest et prépare P2-03.
```

## 24. Evidence Pack

### 24.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 24.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
skills/README.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
```

### 24.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
```

### 24.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 24.5 Commandes exécutées

```text
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,220p' skills/README.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
sed -n '260,620p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '261,620p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '621,1040p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '1041,1380p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '1,240p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
rg -n "Storyline|Chapter|Story Step|Descriptor|metadata|adapter|read model|completedStepIds|ProjectManifest|P2-02|Fact|World Rule|Validator|picker|persistence|migration" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '221,520p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,180p' packages/map_core/lib/src/models/game_state.dart
rg -n "storyFlags|completedStepIds|completedCutsceneIds|normalizeLoadedGameState|gameStateFromSaveData|saveDataFromGameState|PlayerProgression|StoryFlags" packages/map_core/lib/src/models/save_data.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '261,520p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '261,620p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '1,320p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '320,700p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '180,240p' packages/map_core/lib/src/models/save_data.dart
sed -n '700,1040p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '620,1020p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
rg -n "kStepStudioDocumentMetadataKey|parseStepStudioDocumentFromGlobalScenario|applyStepStudioDocumentToGlobalScenario|validateStepStudioDocumentForPersistence|legacy|step\\.id|step\\.name|step\\.description|step\\.cutsceneIds|normalize" packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
rg -n "computeGlobalStoryStudioDiagnostics|chapter|chapters|invalid|unreachable|dead end|orphan|duplicate|default" packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short
rg -n "À REMPLACER|P2-02 : 🔜|Prochain lot exact : P2-02|Lot courant : P2-02" reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md "MVP Selbrume/road_map_phase_2.md"
sed -n '560,760p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
sed -n '760,920p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
```

### 24.6 git diff --check

```text
```

### 24.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 68 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 61 insertions(+), 7 deletions(-)
```

### 24.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 24.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
```

### 24.10 Tests / analyze

```text
Non exécutés — P2-02 est décision documentaire et ne modifie aucun code.
```

### 24.11 git diff --no-index --check du rapport créé

Commande :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md || true
```

Sortie :

```text
```

### 24.12 Contrôle hors scope

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host
```

Sortie :

```text
```

## 25. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

- Oui. Les modifications prévues concernent seulement le rapport P2-02 et `MVP Selbrume/road_map_phase_2.md`.

Le rapport P2-02 existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`.

`road_map_phase_2.md` a-t-elle été mise à jour ?

- Oui, avec P2-02 terminé et P2-03 comme prochain lot exact.

`road_map_global.md` est-elle restée intacte ?

- Oui, elle a été lue mais non modifiée.

Aucun code n'a-t-il été modifié ?

- Oui. Aucun fichier dans `packages/` ou `examples/playable_runtime_host` n'a été modifié.

Aucun test/analyze Dart/Flutter n'a-t-il été lancé ?

- Oui. Aucun `dart test`, `flutter test`, `dart analyze`, `flutter analyze` ou `build_runner` n'a été lancé.

P2-03 n'a-t-il pas été commencé ?

- Oui. P2-03 est seulement recommandé comme prochain lot exact.

La décision est-elle claire ?

- Oui : adapter/read model non persistant recommandé, descriptor persistant refusé pour l'instant, `completedStepIds` reste la source de completion.

Les options ont-elles été comparées honnêtement ?

- Oui. Les cinq options demandées sont analysées avec avantages, risques, consumers et verdict.

La recommandation évite-t-elle une migration prématurée ?

- Oui. Aucune migration `ProjectManifest` n'est recommandée maintenant.

Le prochain lot exact est-il clair ?

- Oui : `P2-03 — Event Authoring Source Contract`.

### Regard critique sur le prompt

Le prompt est très strict et utile : il empêche P2-02 de devenir une implémentation déguisée. Sa seule tension est qu'il demande une décision de contrat tout en interdisant toute formalisation codée ; la réponse la plus saine est donc de décider la trajectoire, pas d'écrire le modèle. Le point le plus important à maintenir en P2-03 sera de ne pas transformer le read model futur en storage persistant implicite.
