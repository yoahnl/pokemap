# NSC-40 — Cycle de vie Event complet

Date : 2026-07-20
Verdict : **DONE proposé pour NSC-40**
Roadmap : phase 4 Narrative Studio, premier lot sur six

## Résumé exécutif

Event Builder V2 dispose maintenant d’un cycle de vie complet et fidèle au wire canonique : renommage, duplication, publication, dépublication, activation/désactivation, suppression protégée et undo durable. L’interface distingue explicitement `Brouillon`, `Publié · inactif` et `Publié · actif`; aucun faux statut archive n’a été créé.

Une copie reçoit un nouvel ID et un nouvel ordre, conserve les références choisies, mais redevient toujours un brouillon non actif. Une dépublication convertit une définition configurée en draft complet sans perdre source, conditions, Scene, reuse policy, priorité ou ordre. Une suppression consulte le `NarrativeDependencyIndex` construit depuis le snapshot projet/maps attesté et affiche les consumers avant de proposer la confirmation destructive. Elle ne supprime jamais la source physique de map.

Toutes les mutations restent des transactions unitaires compare-and-swap via le writer Event V2 journalisé. Le chemin d’undo exact est désormais exposé par le résultat de persistence et l’UI peut restaurer la version précédente après reload. Aucune mutation ne passe par `MapEventDefinition`.

## Confirmation du scope

- Lot exact : `NSC-40 — Cycle de vie Event complet`.
- Dépendances consommées : NSC-01, NSC-02 et NSC-13.
- Inclus : rename existant rendu accessible dans le cycle, duplicate, unpublish, publish, enable/disable, delete protégé, persistence failure, recovery status, reload et undo.
- Exclus : statut archive absent du wire, création/suppression de PNJ/objet/zone, expressions all/any/not et reset policies, simulation runtime, Map Events View et migration finale. Ces sujets appartiennent respectivement à NSC-41 à NSC-45.
- Aucun statut de `pokemap_roadmap_mecaniques_fangame.md` n’est modifié.

## Audit initial

### Contrats trouvés

- `NarrativeEventAuthoringResult` décrivait déjà une mutation pure, sa révision conceptuelle, son caractère undoable et son replay de sécurité.
- `renameNarrativeEvent`, `publishNarrativeEvent`, `activateNarrativeEvent` et `deactivateNarrativeEvent` existaient déjà.
- `NarrativeEventRegistryPersistence` fournissait déjà journal, recovery, CAS et undo fichier, mais le chemin d’undo n’était pas exposé au coordinateur produit.
- `NarrativeDependencyIndex` indexait déjà les usages qualifiés d’un Event V2.
- `EventBuilderV2ProductRoute` adoptait déjà le registre committé dans l’état editor sans toucher les bytes de map.
- Il n’existait aucune opération V2 duplicate, unpublish ou delete, ni panneau UI regroupant les états réels du cycle.

### Risques identifiés

- inventer un statut archive impossible à sérialiser ;
- confondre publication et activation runtime ;
- cloner l’ID technique ou activer implicitement une copie ;
- perdre des champs lors du retour configured → draft ;
- supprimer un Event encore consommé ;
- supprimer par erreur sa source physique de map ;
- accepter une écriture non attestée après exception ou recovery journal ;
- créer un second mécanisme d’undo.

### Décisions

- Le clone est toujours un draft avec nouvel ID/ordre ; les références externes restent les choix explicites de l’auteur.
- `unpublish` est une transformation structurelle sans perte et implique naturellement l’absence d’activation, puisque le wire draft ne porte pas `enabled`.
- La suppression accepte les auto-usages appartenant au record supprimé mais bloque tout owner externe et toute legacy claim ciblant l’Event.
- La preview et la suppression reconstruisent le même index canonique depuis la même session attestée ; le commit refait ensuite toutes les validations.
- L’undo réutilise exclusivement l’artefact du writer Event existant.

## État Git initial

- Branche : `main`.
- HEAD : `d4c767aff feat(narrative): add lighthouse retry fix and Selbrume readiness reaudit report`.
- `git status --short --untracked-files=all` : aucune sortie ; worktree propre.
- Aucun worktree ni sous-agent n’a été utilisé, conformément au choix explicite antérieur de l’utilisateur. Les passes obligatoires sont exécutées localement et nommées séparément.

## Inventaire complet et zones modifiées

### `map_core`

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/authoring/narrative_event_authoring_contract.dart` | enum des mutations, `NarrativeEventDeletionPreview`, résultat nullable après delete | Représente duplicate/delete/unpublish et permet à une suppression appliquée d’avoir `nextRecord == null` tout en conservant l’ID précédent. |
| `packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart` | replay des nouvelles mutations | Empêche le writer d’accepter un résultat lifecycle forgé ; delete est rejoué avec un index vide uniquement après une preview appliquée sans consumer. |
| `packages/map_core/lib/src/operations/narrative_event_record_operations.dart` | `duplicateNarrativeEvent`, `unpublishNarrativeEvent`, `deleteNarrativeEvent` | Porte les transformations pures, préserve mode/claims/ordre et bloque les consumers qualifiés. |
| `packages/map_core/test/narrative_event_record_operations_test.dart` | nouveau contrat NSC-40 | Prouve clone actif→draft, unpublish sans perte, suppression bloquée/libre et cibles absentes. |
| `packages/map_core/test/narrative_event_draft_authoring_test.dart` | duplication d’un draft incomplet | Prouve qu’une copie ne publie jamais implicitement un brouillon incomplet. |
| `packages/map_core/test/narrative_event_publication_test.dart` | round-trip unpublish→publish | Prouve l’identité complète de la définition et la réactivation non implicite. |
| `packages/map_core/test/narrative_event_authoring_verification_test.dart` | replay delete avec index attesté | Refuse un résultat de suppression construit sans consumer lorsque l’index du writer en contient un. |

### `map_editor` — application et persistence

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/application/models/narrative_event_registry_persistence_models.dart` | `NarrativeEventRegistryPersistenceResult.undoPath` | Transporte l’emplacement exact de l’artefact undo sans reconstruire un chemin dans l’UI. |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart` | résultat de `_writeTransition` | Expose le path réellement écrit après succès du journal. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart` | `duplicate`, `unpublish`, `delete`, `previewDelete`, `undo` | Coordonne une mutation pure par transaction, construit l’index depuis le snapshot attesté et mappe honnêtement stale/recovery/IO. |
| `packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart` | scénarios lifecycle durables | Prouve duplicate/unpublish/delete/undo/reload, exception sans adoption et consumer réel Event→Event. |

### `map_editor` — état et UI Design System

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart` | `NarrativeEventLifecyclePresentation` | Donne un libellé et une explication uniques aux trois états réels du wire/runtime. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart` | action lifecycle de la ligne sélectionnée | Rend le cycle découvrable sans encombrer toutes les lignes ni exposer le legacy. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` | transport du callback lifecycle | Préserve la séparation entre layout et mutation produit. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | side sheet, confirmations, preview consumers, adoption et undo | Branche toutes les actions sur le use case transactionnel avec composants PokeMap et messages honnêtes. |
| `packages/map_editor/test/narrative_event_lifecycle_authoring_test.dart` | parcours widget des trois états | Prouve labels, descriptions, actions disponibles et absence d’archive. |

### Plan d’exécution

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-20-nsc-40-event-lifecycle.md` | Micro-plan TDD obligatoire pour ce lot L ; le chemin est ignoré globalement par `.gitignore` et sera ajouté explicitement au commit. |

## Contenu des fichiers créés

Le contenu intégral canonique est enregistré dans le même commit que ce rapport et reste consultable par `git show <commit-nsc-40>:<chemin>`. Empreintes et tailles avant commit :

| Fichier | Lignes | SHA-256 avant commit |
|---|---:|---|
| `docs/superpowers/plans/2026-07-20-nsc-40-event-lifecycle.md` | 230 | `bda81dc19e77644e2fccb6a3986849c5fcd954e473d16b10e9dc4efd98b36d02` |
| `packages/map_core/test/narrative_event_record_operations_test.dart` | 168 | `e4453f897b3d6cffa5a3624d875076712cb68b654b5c584136c15210d6478bfc` |
| `packages/map_editor/test/narrative_event_lifecycle_authoring_test.dart` | 73 | `d833c41a4ff0cd2b41605c946d94356740d5d913afb2fff967c98e808631dc68` |

Le présent Evidence Pack est le quatrième fichier créé et contient son propre contenu intégral.

## Tests créés ou modifiés

- Positif : clone configuré, unpublish complet, delete libre, undo après delete, reopen durable, trois états UI.
- Négatif : cible absente, consumer canonique, exception FileSystem, Event référencé par une condition réelle.
- Garde-fous : clone non actif, publication non activante, delete sans map mutation, no archive, source physique explicitement conservée.
- Non-régression : draft incomplet reste draft ; unpublish→publish retrouve exactement la définition ; recovery/undo historiques continuent à passer.

## Commandes et résultats exacts

### Rouge TDD

```text
cd packages/map_core
dart test test/narrative_event_record_operations_test.dart
-1: FAIL attendu — duplicateNarrativeEvent, unpublishNarrativeEvent et deleteNarrativeEvent absents.

cd packages/map_editor
flutter test test/narrative_event_builder_v2_use_case_test.dart
-1: FAIL attendu — méthodes duplicate/unpublish/delete/undo absentes.

flutter test test/narrative_event_lifecycle_authoring_test.dart
-1: FAIL attendu — launcher lifecycle absent.
```

### Tests core ciblés finaux

```text
cd packages/map_core
dart test test/narrative_event_record_operations_test.dart test/narrative_event_draft_authoring_test.dart test/narrative_event_publication_test.dart test/narrative_event_authoring_verification_test.dart
+29: All tests passed!
```

### Tests editor ciblés finaux

```text
cd packages/map_editor
flutter test test/narrative_event_builder_v2_use_case_test.dart test/narrative_event_lifecycle_authoring_test.dart test/event_registry_recovery_test.dart test/event_registry_undo_test.dart test/ui/canvas/event_builder_v2_flow_fidelity_test.dart test/ui/canvas/event_builder_v2_workspace_test.dart
+48: All tests passed!

flutter test test/narrative_event_builder_v2_use_case_test.dart
+12: All tests passed!

flutter test test/narrative_event_builder_v2_use_case_test.dart test/event_registry_recovery_test.dart test/event_registry_undo_test.dart
+31: All tests passed!
```

### Analyse

```text
cd packages/map_core && dart analyze
No issues found!

cd packages/map_editor
flutter analyze <9 fichiers NSC-40>
No issues found! (ran in 4.2s)
```

L’analyse complète editor n’est pas verte :

```text
flutter analyze
11 issues found. (ran in 16.2s)
```

Les 11 diagnostics sont tous dans `lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart` : un `unused_element` et dix usages protected/visibleForTesting. Ce fichier n’est pas modifié par NSC-40 et ces avertissements existaient au HEAD initial. Aucun diagnostic ne vise un fichier du lot ; l’analyse ciblée est verte. Ils ne sont pas corrigés ici pour ne pas mélanger le chantier Dialogue à Event lifecycle.

### Build

```text
cd packages/map_editor
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Audit statique

```text
git diff --check
<aucune sortie>

rg -n "Color\\(0x|Colors\\." <fichiers UI NSC-40>
<aucune sortie>
```

## Passes locales nommées exigées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : le registre V2, l’index de dépendances et le writer journalisé existants restent les seules autorités. |
| Implémentation | PASS : trois opérations pures manquantes et leur composition produit sont ajoutées sans toucher aux sources physiques. |
| Tests | PASS ciblé : 29 tests core puis 48 tests editor ; cas positifs, négatifs, garde-fous et non-régression couverts. |
| Build / Validation | PASS avec baseline documentée : analyses core/ciblée editor vertes et build macOS réussi ; analyse editor globale conserve 11 warnings Dialogue hors lot. |
| Critique finale | PASS avec limites : aucun archive, aucune activation implicite, aucun raw color, aucun `MapEventDefinition` ajouté au chemin lifecycle. |

## Auto-critique finale

- Le premier passage avait branché par erreur la mémorisation d’undo dans le workflow multi-step `create`; la revue de diff l’a replacée dans `_runWrite`, qui possède réellement un `persistenceResult` unitaire.
- La preview de suppression pouvait se contenter d’un test d’index synthétique. Un test supplémentaire avec le fixture produit prouve désormais qu’une condition EventConsumed réelle bloque la suppression.
- Le replay initial de delete utilisait un index vide. La passe Critique l’a durci : `NarrativeEventRegistryWriteRequest` et le writer reconstruisent maintenant l’index depuis leur session attestée, et un test refuse un delete forgé face à un consumer.
- Une suppression appliquée exige `nextRecord == null`; le contrat et le replay ont été adaptés explicitement plutôt que de mentir avec l’ancien record comme “next”.
- Le clone conserve volontairement les références externes choisies, y compris une condition vers un autre Event. Il ne réécrit que son identité interne et son ordre. Les cycles restent contrôlés à la publication.
- L’undo de l’UI conserve le nouvel artefact produit par l’undo, ce qui permet un inverse ultérieur ; ce comportement reste limité à la session UI courante et ne constitue pas encore un historique multi-niveaux.

## Limites et risques conservés

- Pas d’archive Event : le wire n’en possède pas.
- Pas de reset policy ni all/any/not : NSC-43.
- Le panneau de suppression montre les owners et paths canoniques ; des libellés humains plus riches dépendront de la navigation/source work de NSC-41/44.
- Une copie reçoit le suffixe `— copie`; l’utilisateur peut immédiatement la renommer dans le même panneau.
- Le package editor complet conserve 11 warnings Dialogue hors scope malgré un build réussi.
- La suite complète de plusieurs milliers de tests editor n’a pas été relancée pour ce lot ; les suites Event, persistence, recovery, undo, workspace et fidelity ciblées ont été exécutées.

## État Git final attendu

- Un seul commit NSC-40 contient exclusivement les fichiers de cet inventaire, le micro-plan forcé et ce rapport.
- Le worktree était propre avant le lot ; aucun changement concurrent n’a été adopté.
- Aucun push n’est effectué : l’utilisateur a demandé un commit par lot, pas une publication distante.

## Prochaine étape proposée, non implémentée dans ce commit

`NSC-41 — Workflow Source et Trigger fondé sur les éléments réels de map` : enrichir le catalogue par map, limiter les combinaisons compatibles et rendre explicite l’aller-retour Map Editor lorsqu’une source manque.
