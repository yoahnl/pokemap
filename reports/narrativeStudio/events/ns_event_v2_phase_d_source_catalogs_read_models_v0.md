# NS-EVENT-V2 — Phase D — Migration Integrity Closure, Source Catalogs & Unified Read Models V0

## 1. Résumé exécutif

```text
PHASE D : CLOSED / ACCEPTED

D0-A : PASS
D1 / V2-09 : PASS
D2 / V2-10 : PASS
D0-B : PASS
D3 / V2-11 : PASS
D4 / V2-12 : PASS

Migration planner ready integrity : PASS
Receipt closed-world : PASS
Spatial catalog : PASS
Outcome catalog : PASS
Unified read model : PASS
Navigation intents : PASS

Real project migrated : NO
Legacy data modified : NO
Phase E : READY
```

Phase D ferme le principal point resté ouvert après Phase C : un plan de
migration ne peut plus annoncer `ready/canApply` sur la seule forme de ses
données. Il doit être lié au snapshot projet exact et prouver l'existence et
l'unicité de sa source, de sa Scene, de ses Facts, de ses références Event et
de ses outcomes qualifiés.

Elle livre aussi trois couches editor-neutral consommables par la future UI :
catalogues spatiaux/outcomes, read model projet unifié et intentions de
navigation. Aucun type Flutter, aucune écriture filesystem, aucun runtime V2 et
aucune migration Selbrume n'ont été ajoutés.

Preuves finales : `2 842` tests `map_core`, analyse `map_core` sans diagnostic,
`189` tests editor V1 ciblés, build macOS editor réussi et `3` tests runtime
legacy réussis. L'analyse globale editor reste rouge sur une dette Pokémon SDK
préexistante et hors scope ; l'analyse ciblée Phase D est propre.

Blockers : aucun. Réserves : coût de construction du grand snapshot en JIT,
baseline AOT non produite, outcome benchmark isolé sur un producteur massif et
analyse globale editor historiquement rouge.

## 2. Baseline Phase C

- Commit canonique Phase C : `eb1b4998`.
- Rapport :
  `reports/narrativeStudio/events/ns_event_v2_phase_c_legacy_compatibility_migration_v0.md`.
- Evidence Pack :
  `reports/narrativeStudio/events/ns_event_v2_phase_c_evidence_pack.md`.
- Verdict conservé : C0 à C4 `PASS`, migration réelle `NO`, données legacy
  modifiées `NO`.
- Baseline Git effective de ce lot : `85008b90` sur `main`, arbre propre.

Phase D ne réécrit pas le rapport Phase C et ne change pas ses preuves
historiques.

## 3. Addendum de qualification C4

Le `PASS` C4 signifiait : dry-run déterministe, mappings/claims/receipt et
recovery protocol présents, sans écriture. Il ne prouvait pas encore qu'un plan
`ready` était applicable au projet courant complet.

Qualification ajoutée par D0 :

```text
V2-08 : PASS dry-run Phase C.
Applicability ready/canApply : closed by Phase D D0.
```

Un catalogue de validation est désormais obligatoire, lié au hash du manifeste
et aux hashes exacts des maps. Toute divergence de snapshot, référence absente,
ambiguïté ou proposition hors fermeture atomique bloque avant consommation d'ID
ou lecture de l'horloge.

## 4. Usage MCP Dart

MCP Dart n'était pas exposé parmi les outils de cette session. Aucun usage MCP
fictif n'est revendiqué. La compensation a utilisé `rg`, `sed`, lecture directe
des symboles, tests Dart/Flutter, `dart analyze`, `flutter analyze` et
`build_runner`.

## 5. Sous-agents et incidents

Passes spécialisées exécutées :

| Passe | Mission | Verdict |
|---|---|---|
| A | Audit architecture, frontières Phase C/D | PASS |
| B | Migration contextual integrity D0 | PASS |
| C | Catalogue spatial D1 | PASS |
| D | Catalogue outcomes D2 | PASS |
| E | Read model projet D3 | PASS |
| F | Navigation et diagnostics D4 | PASS |
| G | Tests, performance et compatibilité | BLOCKED initial, corrigé, puis PASS |
| R1 | Architecture et intégrité des données | PASS à chaque gate |
| R2 | Vérité produit et UX no-code | PASS à chaque gate |
| Orchestrateur | Séquence D0-A → D1 → D2 → D0-B → D3 → D4 | PASS |

Reviews finales identifiables : D3 R1 `019f5cce-9c6e-7090-9a27-33a7a716514c`,
D3 R2 `019f5cce-a7f2-75e1-8e12-c3c50cc31141`, D4 R1
`019f5d00-f668-7a81-b399-1cbd4f0ee309`, D4 R2
`019f5d00-ed58-7233-a60d-23748108c1db`, G
`019f5d18-2451-7082-ad83-98c10c4e4773`.

La review contradictoire finale `019f5d38-3c94-7940-99cd-177965259fce` a
d'abord rendu `BLOCKED` sur une Scene Outcome insuffisamment validée contre le
projet, puis `PASS` après fermeture des références manifeste et map-backed.
Sa dernière passe a signalé deux P3, tous deux fermés : wording roadmap précisé
et test navigation map-backed ajouté.

Incidents :

- un premier appel de création du reviewer G a été rejeté avant création du
  worker à cause d'options API incompatibles ; aucune modification ; relance
  immédiate réussie ;
- G a bloqué le premier benchmark pour volumes Outcome ambigus, déduplication
  inclusive non isolée et fixture spatiale incomplète ; les trois défauts ont
  été corrigés puis re-reviewés `PASS` ;
- deux tests C4 ont échoué au premier full gate : leurs fixtures déclaraient une
  Scene Yarn sans entrée Dialogue. La fixture a été fermée, les deux tests ont
  repassé isolément, le fichier complet a repassé, puis la suite complète a
  repassé ;
- deux erreurs de commande locale (`status` réservé par zsh et expansion zsh
  d'une liste de fichiers) n'ont modifié aucun fichier et ont été relancées avec
  la syntaxe correcte.
- les deux nouvelles fixtures map-backed ont d'abord utilisé à tort une liste
  `const` de `SceneEdge`; le chargement des tests a échoué, l'annotation a été
  retirée et les gates ont été relancés intégralement ;
- le nouveau helper navigation a d'abord transmis un titre nullable à
  `MapEventDefinition`; fallback déterministe ajouté, puis test isolé, gate D4,
  suite complète et analyse relancés avec succès.

## 6. Gate 0

```text
$ pwd
/Users/karim/Project/pokemonProject
$ git branch --show-current
main
$ git status --short --untracked-files=all
<empty>
$ git diff --stat
<empty>
$ git diff --name-only
<empty>
$ git log --oneline -n 3
85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
1fc32b4f feat(editor): allow confirmed bulk deletion of map layers and update selbrume project assets
e0e4876e test(editor): add smoke test for terrain preset dropdown menus
```

Versions : Dart `3.12.1 stable macos_arm64`; Flutter editor
`3.46.0-0.3.pre beta` (Dart tool `3.13.0 beta`). Les deux drifts annoncés par le
prompt n'étaient pas modifiés au Gate 0.

Deux commits externes sont apparus pendant le lot, sans action de cet agent :
`56fd6342` (layers panel editor) et `39a9f7bb` (map Bourg Selbrume). Ils ne
touchent aucun fichier Phase D. Les hashes surveillés sont restés identiques :

```text
packages/map_editor/pubspec.lock
78c3a9fee5b8cb0949c518c93fd4fae70b18fe5567334957c581d59c3ede37da

selbrume/assets/GENERATED_ASSET_PROMPTS.md
f5c518079a279906bd7d587d756192957587396c77c6908fda56ebd8a8eb1eef
```

## 7. D0-A Receipt & Choice Closure

`NarrativeEventMigrationSourceChoice` distingue maintenant par construction :

- `confirmCandidate` : confirme exactement un candidat projeté ;
- `explicitReassignment` : choisit une autre source avec raison humaine non
  vide ;
- targets immuables et signatures stables ;
- round-trip fermé sur les kinds connus.

Le decoder receipt travaille sur les bytes bruts, rejette les clés dupliquées
littérales ou échappées et distingue : decoded, unsupported, invalid. Les
champs inconnus, enums futurs et versions futures ne sont jamais absorbés
silencieusement. Les bytes initiaux restent disponibles en failure.

## 8. Review D0-A

```text
D0-A REVIEW R1 : PASS
D0-A REVIEW R2 : PASS
D0-A gate : 78 tests passed
```

## 9. D1 Spatial Source Catalog

`buildNarrativeSpatialEventSourceCatalog` indexe toutes les maps du manifeste,
les `MapEntity` éligibles et les `MapTrigger` event/custom. L'identité de source
reste uniquement structurelle ; position et taille vivent dans un résumé de
géométrie read-only.

Les options conservent labels humains, disponibilité, raison d'indisponibilité,
origine canonique/compatibilité, propriétaire exact et provenance legacy. Les
lookups sont indexés par source et retournent found/unavailable/missing/ambiguous.

## 10. Matrice d'éligibilité spatiale

| Élément | Présent | Sélectionnable | Géométrie | Décision |
|---|---:|---:|---|---|
| map valide | oui | oui | map-wide | `mapEnter` |
| map manifeste sans data | oui | non | unavailable | visible + diagnostic |
| NPC / sign / item / custom | oui | oui | bounds exacts | `entityInteract` |
| spawn | oui | non | bounds | réservé système |
| entity disabled par contrat | oui | non si source non utilisable | bounds | raison humaine |
| trigger event/custom valide | oui | oui | area exacte | `triggerEnter` |
| trigger système | oui | non | area | visible, indisponible |
| trigger sans aire valide | oui | non | unavailable | incompatible |
| MapPlacedElement interactif | secondaire | non comme Entity | read-only | aucune fausse identité |
| MapEvent legacy | compatibilité | jamais canonique seul | position legacy secondaire | assistance explicite |

## 11. Review D1

```text
D1 REVIEW R1 : PASS
D1 REVIEW R2 : PASS
D1 gate : 30 tests passed
```

## 12. D2 Outcome Source Catalog

`buildNarrativeOutcomeEventSourceCatalog` qualifie chaque outcome par
`producerKind + producerId + outcomeId`. Scene, Battle et legacy Scenario sont
des producteurs distincts. Yarn n'est jamais un producteur autonome : son
outcome reste qualifié par la Scene qui l'orchestre.

Le catalogue expose declared/reachable/emitted/unreachable/missing/duplicate et
legacy compatibility, sans fusion globale par `outcomeId`.

Une Scene n'est sélectionnable comme producer que si son plan est construisible,
ses références manifeste sont valides et toute conséquence map-backed peut être
vérifiée contre un snapshot de maps exact. Sans ces données, l'option reste
visible mais `producerInvalid`.

## 13. Matrice producers/reachability

| Producer | Cas | Sélectionnable | Preuve |
|---|---|---:|---|
| Scene | déclaré + fin atteignable | oui | graphe Scene |
| Scene | déclaré non émis | non | raison humaine |
| Scene | émis non déclaré | non | diagnostic |
| Scene | dupliquée / non buildable / référence projet invalide | non | ambiguous/unavailable |
| Scene | cible map non chargée ou event absent | non | fail-closed map snapshot |
| Yarn | expected outcome | via Scene seulement | pas de producer Yarn |
| Battle | référence publique stable | oui | producer `battle` |
| Battle | identité stable absente | non | pas d'identité inventée |
| Scenario legacy | outcome qualifié | compatibilité | provenance conservée |
| producer manquant | référence visible | non | missing |
| même outcomeId cross-producer | options distinctes | oui selon chaque preuve | aucune collision globale |

## 14. Review D2

```text
D2 REVIEW R1 : PASS
D2 REVIEW R2 : PASS
D2 gate : 21 tests passed
```

## 15. D0-B Contextual Integrity

`NarrativeEventProjectCatalog` agrège les catalogues, Scenes buildables, Facts,
Events existants/proposés et diagnostics. Le planner refuse désormais un
catalogue absent, forgé, stale ou non lié au snapshot. Il valide les choices
avant allocation et atteste le contexte dans le plan prêt.

`ready` et `canApply` sont des invariants forts du type : aucune construction
publique ne peut produire cet état avec diagnostics bloquants, mappings
incomplets, unknown data ou contexte non attesté.

## 16. Matrice ready/assistance/blocked

| Cas | Verdict |
|---|---|
| source unique et sélectionnable | accepté |
| source absente/disabled/ambiguë | blocked |
| `confirmCandidate` exact | accepté |
| confirmation qui change la source | blocked |
| réassignation explicite validée + raison | accepté |
| réassignation inventée/hors catalogue | blocked |
| Scene unique et buildable | accepté |
| Scene absente/dupliquée/non buildable | blocked |
| Fact unique | accepté |
| Fact absent/dupliqué | blocked |
| Event condition vers Event valide | accepté |
| Event absent/invalide/cyclique | blocked |
| outcome qualifié avec producer valide | accepté |
| producer/outcome absent ou ambigu | blocked |
| catalogue absent ou snapshot différent | blocked avant IDs/clock |
| receipt unknown | unsupported |
| receipt duplicate key | invalid |

## 17. Review D0-B

```text
D0-B REVIEW R1 : PASS
D0-B REVIEW R2 : PASS
D0-B gate : 105 tests passed
D0 GLOBAL : PASS
```

## 18. D3 Unified Project Read Model

`buildNarrativeEventBuilderProjectReadModel` relit le snapshot courant : records
V2, MapEvents legacy et nodes source Scenario. Il ne reçoit pas de projections
caller potentiellement stale. Les index partagés évitent les scans répétés des
sources, Scenes, outcomes, Facts et diagnostics Events.

Les conséquences Scene et World Rules restent des projections read-only. Le
read model ne crée ni outcome, ni réaction, ni règle monde.

## 19. Status matrix

| État réel | Statut affiché |
|---|---|
| draft incomplet | `draftIncomplete` |
| configured disabled valide | `configuredDisabledReady` |
| configured enabled valide | `configuredEnabledReady` |
| source manquante | `sourceMissing` |
| Scene/Fact/Event invalide | `referenceInvalid` |
| assistance migration | `migrationAssistanceRequired` |
| migration bloquée | `migrationBlocked` |
| legacy non revendiqué | `legacyOnly` |
| claim invalide/tombstone | `claimInvalid` |
| forme non supportée | `unsupported` |

## 20. Claim and legacy deduplication

Un claim n'est dédupliqué que si : fingerprint exact, cohorte complète, receipt
compatible, membres présents et target Events valides. Dans ce cas l'Event V2
porte les origines legacy et la source legacy n'apparaît pas comme un second
Event. Un claim stale, partiel ou conflictuel reste visible comme problème ; un
tombstone ne disparaît jamais.

La déduplication des diagnostics conserve la première valeur, trie de façon
déterministe et retourne une liste immuable. Son helper interne n'est pas
exporté dans `map_core.dart`.

## 21. Human source sentences

Exemples produits :

```text
Interaction avec Lysa, au Port des Brisants.
Entrée dans Quai nord, au Port des Brisants.
Entrée sur la map Port des Brisants.
Après le résultat Victoire de la Scene Rencontre rival.
Source non choisie.
```

Les mots `MapEventDefinition`, `layerId`, `metadata`, `claim` et `runtime` sont
réservés aux champs debug, jamais au texte principal auteur.

## 22. Review D3

```text
D3 REVIEW R1 : PASS
D3 REVIEW R2 : PASS
D3 gate : 50 tests passed
```

## 23. D4 Navigation & Destinations

Les intentions sont des valeurs `map_core` pures. Une destination spatiale
exige un focus exact et cohérent. Les destinations non spatiales ouvrent Scene,
Fact, Event, producer outcome, Scenario legacy ou revue migration. Aucune
callback Flutter n'entre dans le contrat.

Chaque diagnostic de référence porte exactement une destination ou une
`absenceReason`, avec action recommandée humaine. Aucune action ne prétend
réparer automatiquement une donnée absente.

Pour un outcome de Scene map-backed, le diagnostic reste indisponible sans
snapshot exact ou si l'Event de map manque, puis devient disponible lorsque la
référence exacte est vérifiable.

## 24. Destination matrix

| Référence | Destination | Focus | Absence |
|---|---|---|---|
| entity | map + entity | bounds exacts | entity manquante/ambiguë |
| trigger | map + trigger | area exacte | zone manquante/ambiguë |
| mapEnter | map | map-wide | map manquante/dupliquée |
| Scene | open Scene | aucun | Scene manquante/dupliquée |
| Fact | open Fact | aucun | Fact manquant/dupliqué |
| Event | open Event | aucun | Event manquant/dupliqué |
| outcome Scene/Battle | open producer | aucun | producer manquant/dupliqué |
| Scenario legacy | open Scenario/node | aucun | parcours absent/non unique |
| migration | open review | aucun | provenance absente/non unique |

## 25. Review D4

```text
D4 REVIEW R1 : PASS
D4 REVIEW R2 : PASS
D4 gate : 45 tests passed
```

## 26. Public API finale

Exports ajoutés au barrel :

- catalogues spatial, outcome et projet ;
- builders correspondants ;
- migration choices et receipt decoder strict ;
- read model projet unifié ;
- destinations, focus, navigation index et diagnostics.

API structurante : `NarrativeSpatialEventSourceCatalog`,
`NarrativeOutcomeEventSourceCatalog`, `NarrativeEventProjectCatalog`,
`NarrativeEventMigrationSourceChoice`,
`NarrativeEventMigrationReceiptDecodeResult`,
`NarrativeEventBuilderProjectReadModel`, `NarrativeEventNavigationIndex`.

Le planner public reste dans son fichier historique ; son implémentation a été
extraite pour garder le point d'import compatible. Le helper générique de
déduplication reste interne à `src/`.

## 27. Compatibility V1

- Event Builder V1 : aucun fichier de production editor modifié.
- Garde-fou authoring Scenario claimé : conservé.
- Runtime legacy : aucun fichier de production runtime modifié.
- MapEvent/Scenario source data : lecture seule.
- Les deux échecs initiaux C4 ont révélé une fixture incomplète, pas une
  régression de contrat ; la Scene Yarn référence maintenant un Dialogue déclaré.

## 28. Tests ciblés

```text
D0-A : 78 passed
D1   : 30 passed
D2   : 21 passed
D0-B : 105 passed
D3   : 50 passed
D4   : 45 passed
Performance/refactor ciblé : 32 passed
Planner C4 complet après correction : 50 passed
```

## 29. Tests cumulés

```text
packages/map_core: dart test --reporter=compact
2 842 passed — All tests passed

packages/map_editor: scenario guard + workspace + draft notifier
189 passed — All tests passed

packages/map_runtime: narrative_event_legacy_runtime_characterization_test.dart
3 passed — All tests passed
```

## 30. Analyze/build

```text
dart format --output=none --set-exit-if-changed <28 fichiers Dart Phase D>
Formatted 28 files (0 changed)

dart analyze
No issues found!

dart run build_runner build --delete-conflicting-outputs
Built successfully; wrote 0 outputs (passages répétés stables)

flutter analyze ciblé sur 3 tests editor dépendants
No issues found!

flutter build macos --debug
Built build/macos/Build/Products/Debug/map_editor.app
```

Analyse globale editor : exit `1`, `451` diagnostics (`81` errors, `10`
warnings, `360` infos). Les errors sont limitées aux quatre fichiers Pokémon SDK
converter/sync et leurs tests. Aucune occurrence Phase D. Cette dette n'est pas
présentée comme verte.

## 31. Performance

Machine : `MacBookPro18,3`, Apple M1 Pro, 32 GiB, macOS 27.0 build 26A5378j,
Dart 3.12.1, mode JIT. Une chauffe non enregistrée sur le petit dataset ;
itérations 5/3/2. Temps en millisecondes, moyenne / médiane :

| Opération | 10 maps / 100 sources / 50 Events | 100 / 2 000 / 1 000 | 500 / 20 000 / 10 000 |
|---|---:|---:|---:|
| Spatial catalog build | 9.283 / 8.235 | 457.676 / 457.832 | 6 613.600 / 6 613.600 |
| Outcome catalog build | 8.798 / 8.241 | 306.680 / 303.783 | 4 254.341 / 4 254.341 |
| Unified read model build | 13.200 / 12.801 | 537.126 / 540.041 | 7 233.437 / 7 233.437 |
| Navigation lookup | 0.039 / 0.039 | 0.836 / 0.856 | 5.839 / 5.839 |
| Diagnostic deduplication | 0.162 / 0.108 | 1.491 / 1.428 | 16.099 / 16.099 |

Le spatial large contient 500 mapEnter (dont une map data absente), 9 750
entities, 9 750 triggers et 1 950 sources locales multi-cellules. Outcome isole
20 000 outcomes, zéro map et zéro Event, explicitement. La déduplication passe
de 30 000 entrées contrôlées à 10 000 uniques.

Complexité attendue : collecte O(M+S+E), index O(S), tris O(S log S) et O(E log
E), lookup moyen O(1), déduplication O(D + U log U). Allocations principales :
options/summaries immuables, index par source/outcome/ID et JSON de fingerprint.

Cache futur possible : réutiliser catalogue/read model/navigation index par
snapshot `(manifestHash, mapHashes)`, invalidé à toute mutation du manifeste,
des maps, des Scenes/Facts/Events/trainers/scenarios. Aucun cache mutable global
n'est introduit en Phase D.

## 32. Generated files

Les passages `build_runner` ont écrit `0 output`. Aucun generated file n'est
présent dans le diff. Le warning de version analyzer 3.9 face au langage SDK
3.12 est un warning toolchain existant, sans diagnostic de code.

## 33. Scope final

Fichiers de production modifiés/créés : uniquement `packages/map_core`.
Roadmap et deux rapports sont les seuls documents hors package.

Commande anti-scope :

```text
git diff --name-only -- packages/map_editor/lib packages/map_runtime/lib \
  packages/map_gameplay packages/map_battle examples assets selbrume \
  "MVP Selbrume/selbrume.md" "MVP Selbrume/narrative_studio.md"
<empty>
```

## 34. Risques résiduels

- construction large JIT à environ 7.2 s : cache immuable à concevoir en Phase E
  ou G, sans global mutable ;
- benchmark Outcome mono-Scene massive, pas multi-producer avec 10 000 Events ;
- lookup mesuré après construction de l'index ;
- deux itérations large donnent une baseline informative, non statistique ;
- AOT non mesuré ;
- analyse globale editor bloquée par la dette Pokémon SDK hors scope ;
- la navigation reste un intent : son exécution Flutter appartient à Phase G.

## 35. Entry Gate Phase E

```text
D0 global : PASS
receipt closed-world / duplicate keys : PASS
confirmation vs reassignment : PASS
source / Scene / Fact / Event / outcome validation : PASS
ready réellement applicable : PASS
spatial catalog : PASS
outcome catalog : PASS
truthful unified read model : PASS
valid claims deduplicated / tombstones visible : PASS
editor-neutral navigation : PASS
diagnostic destination XOR absenceReason : PASS
full map_core tests/analyze/build_runner : PASS
real migration : NO

PHASE E : READY
```

## 36. Auto-review

La portée est large en nombre de lignes mais cohérente avec les six gates du
prompt. L'extraction du planner en façade + implémentation évite un fichier
public de 3 600 lignes sans changer son import. Les index ajoutés suppriment des
rescans mesurables. Le helper de déduplication n'est pas exporté.

La première baseline performance était insuffisante ; son refus par G était
justifié. La version finale ne prétend ni prouver une limite temporelle ni une
complexité strictement linéaire. Les tests de scale ont été renommés en ce sens.

## 37. Review contradictoire

R1 a recherché faux ready, références inventées, receipts permissifs, claims
dupliqués et position dans l'identité : aucun blocker final.

R2 a recherché labels techniques, options indisponibles présentées comme
sélectionnables, producer Yarn autonome, destination fictive et diagnostic sans
action/raison : aucun blocker final.

G a d'abord rendu `BLOCKED`, puis `PASS` après correction. Risques qu'il conserve
: outcome benchmark isolé, lookup hors coût de construction d'index, samples
diagnostic légers, deux itérations large et JIT uniquement.

La review finale a ensuite bloqué un faux positif D2 : une Scene au Dialogue
absent pouvait encore exposer un outcome reachable. La correction combine plan
runtime, diagnostics projet et snapshot de maps ; elle couvre Dialogue absent,
map non chargée, event de map absent et le blocage D0-B correspondant. Sa
re-review finale est `PASS`. Les deux P3 restants ont également été fermés : le
critère roadmap distingue désormais map active et snapshot projet, et D4 prouve
directement la propagation map-backed jusque dans le diagnostic navigation.
Le reviewer a recontrôlé ce delta et rendu `PASS` sans finding résiduel.

## 38. Critique du prompt

Le séquencement et le stop-on-false-ready sont excellents. Deux tensions ont été
résolues explicitement :

1. le placeholder `<tests Event Builder V1 ciblés pertinents>` n'est pas
   exécutable tel quel ; les trois suites réellement dépendantes ont été choisies
   et documentées ;
2. `codex_rule.md` demande le contenu complet de chaque fichier créé, tandis que
   le §23 interdit de recopier quinze mille lignes. La règle spécifique du lot a
   été suivie : chemins, SHA-256, lignes, API, matrices et extraits précis ; les
   sources restent l'autorité.

La baseline performance gagnerait à prescrire séparément volumes spatiaux,
outcomes, diagnostic input et index build/lookup. Le reviewer G a justement
forcé cette clarification.

## 39. Verdict Phase D

```text
PHASE D : CLOSED / ACCEPTED
V2-09 : PASS
V2-10 : PASS
V2-11 : PASS
V2-12 : PASS
Phase E : READY

Migration réelle effectuée : NO
Commit effectué : NO
```
