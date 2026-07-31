# PMCP-034 — Evidence Pack objets spatiaux et collision effective

Date : 2026-07-31

Lot : `PMCP-034`

Verdict proposé : `DONE`

## 1. Périmètre et critères de clôture

Le lot couvre l'authoring typé des éléments placés, entités/NPC, triggers,
zones de gameplay et couches de collision, ainsi que les requêtes pures de
collision effective, provenance, marchabilité et accessibilité.

Preuves attendues et obtenues :

- un payload incompatible avec le type d'entité est refusé avec un code stable ;
- un déplacement groupé hors limites est atomique et ne modifie pas la carte source ;
- la collision effective distingue couche manuelle, profil d'élément placé et entité bloquante ;
- une sortie isolée et deux composantes marchables distinctes sont détectées ;
- les actions sont publiées dans le barrel public et enregistrées dans le dispatcher canonique.

## 2. Audit initial

État Git initial : arbre propre sur `8f992e2b7` (`feat(authoring): add environment and border actions`).

Constats :

- `map_core` possédait déjà les modèles et opérations pures pour les éléments
  placés, entités, triggers, zones et couches de collision ;
- le dispatcher `map_authoring` ne proposait pas encore leur façade sémantique
  typée ni leurs descripteurs MCP ;
- aucune requête unique n'expliquait la collision réellement résultante des
  couches, profils d'éléments et footprints d'entités ;
- les conventions des lots PMCP-032/033 imposaient des mutations planifiées via
  `SemanticMapActionContext`, sans écriture directe ni dépendance Flutter/Flame.

## 3. Passes de travail et verdicts

Les passes ont été exécutées localement et nommées explicitement ; aucun
sub-agent n'a été lancé, conformément aux contraintes d'exécution actives.

| Passe | Objet | Verdict |
|---|---|---|
| `Audit contrats spatiaux` | Inventaire des primitives `map_core`, invariants de payload et bornes | Conforme |
| `TDD contrats/atomicité` | Tests rouges puis verts sur payload incompatible, déplacement groupé et catalogue | Conforme |
| `Collision effective` | Agrégation déterministe des sources, provenance, hitbox, marchabilité et BFS | Conforme |
| `Architecture/API` | Pure Dart, barrel public, dispatcher canonique, IDs uniques | Conforme |
| `Régression` | Tests complets `map_authoring`, tests ciblés `map_core`, analyses | Conforme |
| `Auto-review` | Relecture des changements, format et whitespace | Conforme avec limites documentées |

## 4. Implémentation livrée

### 4.1 Éléments placés

`placed_element_actions.dart:9-449` publie les actions de placement, batch,
mise à jour, clone, déplacement, rotation, suppression/remplacement par couche,
collision, opacité, ombre, animation, comportements, propriétés et détachement
de projection. Les footprints tournés sont validés avant planification et les
batches sont projetés entièrement en mémoire avant création du change set.

### 4.2 Entités et NPC

`entity_actions.dart:9-714` publie CRUD/upsert/clone/move/batch/resize, payloads
typés, visuel, blocage et propriétés, puis les commandes NPC de direction,
personnage, dresseur, dialogues, visibilité, mouvements et waypoints. La
validation stricte empêche la coercition silencieuse d'un payload étranger au
`MapEntityKind`.

### 4.3 Triggers et zones

`trigger_zone_actions.dart:9-457` publie CRUD/clone/patch des triggers et zones,
leurs déplacements/redimensionnements, leurs payloads typés et leur priorité.
Les opérations de remplacement passent par les opérations canoniques de
`map_core` afin de préserver l'ordre authoré.

### 4.4 Collision effective

`collision_actions.dart:1-661` fournit :

- les mutations paint/erase/fill/clear/invert/replace/generate/merge ;
- `queryAt`, `queryRegion` et `previewPlayerHitbox` ;
- la provenance stable par couche, profil ou masque d'élément et entité ;
- `validateWalkability` par composantes connexes déterministes ;
- `validateReachability` par BFS déterministe depuis un départ vers les sorties.

### 4.5 Exposition publique

- `map_authoring.dart:26-40` exporte les quatre domaines ;
- `map_mutation_dispatcher.dart:6-106` enregistre leurs descripteurs et builders
  dans le registre canonique, qui refuse déjà tout doublon d'ID.

## 5. Inventaire des fichiers

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`

Créés :

- `packages/map_authoring/lib/src/domains/maps/collision_actions.dart`
- `packages/map_authoring/lib/src/domains/maps/entity_actions.dart`
- `packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart`
- `packages/map_authoring/lib/src/domains/maps/trigger_zone_actions.dart`
- `packages/map_authoring/test/domains/maps/effective_collision_test.dart`
- `packages/map_authoring/test/domains/maps/spatial_object_contract_test.dart`
- `reports/analysis/pmcp_034_spatial_collision_evidence.md`
- `reports/analysis/pmcp_034_spatial_collision_evidence_appendix.md`

Le contenu intégral des six fichiers source/test créés est reproduit dans
`pmcp_034_spatial_collision_evidence_appendix.md`. Les deux fichiers d'Evidence
Pack ne se recopient pas eux-mêmes afin d'éviter une récursion documentaire.

## 6. Zones de diff précises

- barrel : quatre exports de domaine ajoutés ;
- dispatcher : quatre imports, quatre instances et quatre boucles d'enregistrement ;
- `collision_actions.dart:1-372` : contrats de résultat et inspecteur ;
- `collision_actions.dart:373-661` : actions de mutation de collision ;
- `entity_actions.dart:9-86` : catalogue, création stricte, batch et preview ;
- `entity_actions.dart:87-714` : parsing et mutations typées ;
- `placed_element_actions.dart:9-449` : catalogue et mutations spatiales ;
- `trigger_zone_actions.dart:9-457` : triggers et zones typés ;
- `effective_collision_test.dart:1-166` : provenance et connexité ;
- `spatial_object_contract_test.dart:1-92` : compatibilité, atomicité et exposition.

## 7. Commandes et résultats exacts

Depuis `packages/map_authoring` :

```text
dart format lib/map_authoring.dart lib/src/domains/maps/map_mutation_dispatcher.dart lib/src/domains/maps/collision_actions.dart lib/src/domains/maps/entity_actions.dart lib/src/domains/maps/placed_element_actions.dart lib/src/domains/maps/trigger_zone_actions.dart test/domains/maps/effective_collision_test.dart test/domains/maps/spatial_object_contract_test.dart
Formatted 8 files (0 changed) in 0.02 seconds.

dart test test/domains/maps/spatial_object_contract_test.dart test/domains/maps/effective_collision_test.dart
00:00 +5: All tests passed!

dart analyze
Analyzing map_authoring...
No issues found!

dart test
00:13 +220: All tests passed!
```

Depuis `packages/map_core` :

```text
dart test test/placed_elements_test.dart test/map_placed_element_rotation_test.dart test/map_entity_collision_footprint_test.dart test/map_entity_npc_movement_config_test.dart test/map_gameplay_zone_validation_test.dart test/map_gameplay_zone_movement_effect_payload_test.dart
00:00 +58: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

Depuis la racine :

```text
git diff --check
(aucune sortie, code 0)
```

## 8. Décisions et non-objectifs

- Les requêtes de collision restent des méthodes pures de l'inspecteur ; elles
  ne sont pas enregistrées comme mutations dans le dispatcher.
- La collision d'une entité conditionnellement visible est présentée comme une
  contribution authorée potentielle : l'évaluation d'état runtime n'appartient
  pas à ce lot pur.
- PMCP-034 consomme les profils et masques de collision des éléments ; leur
  authoring dans le catalogue d'assets reste au lot PMCP-041.
- Aucun état global de monde, rendu Flutter/Flame ou écriture disque directe
  n'a été introduit.

## 9. Auto-critique et risques

- Les quatre façades concentrent un grand catalogue d'actions ; une future
  factorisation ne sera justifiée que par des usages réels, pas dans ce lot.
- Le calcul de collision reconstruit un index à chaque requête publique. Il est
  déterministe et adéquat pour plan/validation ; une mise en cache révisionnée
  pourra être ajoutée si un profilage démontre un besoin interactif.
- L'inspecteur ne résout pas les conditions runtime de visibilité des NPC ; le
  résultat est volontairement conservateur et doit être présenté comme tel.
- Les preuves couvrent les invariants critiques du lot mais pas chaque action
  individuelle du catalogue ; les opérations sous-jacentes restent couvertes
  par les suites `map_core` et le registre complet par les tests de package.

## 10. État de clôture

Le lot satisfait ses critères fonctionnels, transactionnels, architecturaux et
de régression. Le statut `DONE` est proposé après commit dédié. L'état Git final
et l'identifiant du commit sont consignés après création du commit dans le
compte rendu de phase.
