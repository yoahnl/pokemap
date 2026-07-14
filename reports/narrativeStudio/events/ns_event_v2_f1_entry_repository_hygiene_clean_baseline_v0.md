# NS-EVENT-V2 — F1-ENTRY — Repository Hygiene & Clean Runtime Baseline Closure V0

## 1. Résumé exécutif

```text
F1-ENTRY : BLOCKED

Tracked .dart_tool files removed : BLOCKED
.dart_tool ignore rule : PASS
pubspec.lock preserved : PASS

Clean map_core : BLOCKED
Clean map_gameplay : BLOCKED
Clean map_runtime : BLOCKED
Clean runtime host : BLOCKED
macOS build : BLOCKED

Functional Event V2 code modified : NO
Selbrume data modified : NO
Dependencies intentionally changed : NO
Build runner executed : NO

Phase F1 : BLOCKED
Phase F2 : NOT READY
```

Le Gate 0 a invalidé l'hypothèse centrale du lot. Git ne suit pas deux mais
trois fichiers sous `packages/map_gameplay/.dart_tool/`. Le troisième est un
snapshot binaire de 25 421 840 octets, hors de l'allowlist de suppression.
Conformément au cas C, aucune suppression, archive, installation, suite de
tests, analyse ou build n'a été exécuté. Le contrat fonctionnel F1-PREREQ reste
`CLOSED`; seule la reprise de F1 est bloquée par ce gate d'entrée.

## 2. Baseline

```text
Branche : main
HEAD : 7ad2351c6892e8386c9f412cb340f11f3d732a51
Commit : feat(event-v2): close NS-EVENT-V2 F1-PREREQ
Blocker historique : a2ee6bbdb67389336452c5431e523f179a481335
Date : 2026-07-14
```

Les contrats Facts, dual-read, typed tombstones et outbox ratifiés par
F1-PREREQ ne sont pas remis en chantier.

## 3. Pourquoi F1-ENTRY était nécessaire

F1-PREREQ avait rafraîchi et versionné `package_config.json` et
`package_graph.json`, tous deux générés et dépendants de la machine. F1-ENTRY
devait les retirer puis prouver les bytes versionnés depuis une archive propre.

L'audit exhaustif demandé avant suppression a révélé un troisième artefact
`.dart_tool` déjà suivi. Supprimer seulement les deux JSON aurait produit un
faux PASS ; supprimer aussi le snapshot aurait violé le scope direct. La
stratégie plus petite et sûre est donc le STOP documenté.

## 4. Gate 0 exact

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock
 M selbrume/maps/map_bourg_selbrume.json
 M selbrume/project.json
?? selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
?? selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
?? selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
?? selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png

git diff --stat
 packages/map_editor/pubspec.lock       |  16 +-
 selbrume/maps/map_bourg_selbrume.json |  14 +-
 selbrume/project.json                 | 414 +++++++++++++++++++++++++++++++++-
 3 files changed, 434 insertions(+), 10 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
selbrume/maps/map_bourg_selbrume.json
selbrume/project.json

git diff --check
<empty>

git log --oneline -n 15
7ad2351c feat(event-v2): close NS-EVENT-V2 F1-PREREQ
a2ee6bbd docs(event-v2): report NS-EVENT-V2 Phase F1 blocker
5bf62901 feat(event-v2): close NS-EVENT-V2 Phase E-bis
5d920469 feat(event-v2): complete NS-EVENT-V2 Phase E
e932d9a2 feat(event-v2): enhance migration plan with context validation and strict JSON parsing
025bf9bc feat(event-v2): complete NS-EVENT-V2 Phase D
39a9f7bb ```text feat(selbrume): add forest layer to map bourg selbrume ```
56fd6342 feat(editor): use dropdown for layer creation type
85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
1fc32b4f feat(editor): allow confirmed bulk deletion of map layers and update selbrume project assets
e0e4876e test(editor): add smoke test for terrain preset dropdown menus
02de2ffe feat(editor): add design-system dropdown field
816671f7 feat: refine Port des Brisants visuals and editor controls
928cccae test(selbrume): add Port des Brisants visual refinement tests
9fae047b test
```

Les sept entrées editor/Selbrume sont préexistantes ou concurrentes. Hashes au
Gate 0 :

```text
a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc  packages/map_editor/pubspec.lock
696b131633ddcaaf0f0a06ee3f53d35493aa53e07cdc7659948e26570fbeb749  selbrume/maps/map_bourg_selbrume.json
f2318ad7032f1a38d90214d959d736fb52805a52cdb3946abe02ea6ab9cf9c39  selbrume/project.json
468029b382742d1c6cfb276f667da4a4bf1e8e2eca9e383621beae0cbf89fccd  selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
71fcc3cde140d57f2deb9f12cc6b062dbf0e865875d916b6834ce6abe54b72e7  selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
ce77996d337c5bafec86f765f8b1da5820ce09d37b79165d28e74fb6ed23cefd  selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
6e300994e6625089deee8a975b0da7e4761c0b1687dd8e8efbf34dd42fc16687  selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png
```

## 5. Métadonnées `.dart_tool` suivies

Commande :

```bash
git ls-files | rg '(^|/)\.dart_tool/'
```

Résultat exact :

```text
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

Index Git :

```text
100644 3424753b5da896eeb2200c6c094edd6b046aaa74 0 packages/map_gameplay/.dart_tool/package_config.json
100644 d475e0bf48e4a4126516ee6bb1913b68bd0a7945 0 packages/map_gameplay/.dart_tool/package_graph.json
100644 a71b31997bb1b6055a9c620afd942c099603283e 0 packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

Le snapshot pèse 25 421 840 octets, SHA-256
`9291e482842b3d7f995346c8efee360f51c4e62c7b6d106c1109d4680f13493f`.
Il a été ajouté par `365a2a9b` (`Add placed element animation logic and
associated unit tests.`). Les deux JSON remontent au commit initial du package
`4668097b`.

Verdict : Case C déclenché, car le résultat attendu exact contenait seulement
les deux JSON.

## 6. Audit `.gitignore`

`packages/map_gameplay/.gitignore:1` contient déjà :

```gitignore
.dart_tool/
```

La racine contient aussi `**/.dart_tool/`. Comme les chemins sont déjà suivis,
`git check-ignore -v <path>` retourne exit 1 et aucune sortie. La variante
d'audit `--no-index` prouve la règle applicable :

```text
packages/map_gameplay/.gitignore:1:.dart_tool/ packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.gitignore:1:.dart_tool/ packages/map_gameplay/.dart_tool/package_graph.json
packages/map_gameplay/.gitignore:1:.dart_tool/ packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

Verdict ignore : PASS. Aucune modification de `.gitignore` n'est nécessaire ni
autorisée par l'audit.

## 7. Cleanup effectué

Aucun cleanup n'a été exécuté. Les trois fichiers restent présents et suivis.
Les deux suppressions autorisées n'ont pas été appliquées isolément, car elles
auraient laissé le snapshot suivi et permis une conclusion d'hygiène fausse.

Recommandation : relancer un lot corrigé autorisant exactement la suppression
filesystem des trois chemins `.dart_tool` listés en section 5. Ne pas supprimer
le lockfile, les sorties `build/` ou d'autres fichiers ignorés dans ce mini-lot.

## 8. Lockfile conservé

```text
git ls-files packages/map_gameplay/pubspec.lock
packages/map_gameplay/pubspec.lock

SHA-256
ef1601ab55e8a3361fceb8c4d19071c752bccfc12f345190816f4afd4dbaaac5

git diff -- packages/map_gameplay/pubspec.lock
<empty>
```

Le lockfile est présent, suivi et inchangé. Verdict : PASS. La recommandation
élargie de l'agent A visant à le retirer a été rejetée, car elle contredit
l'instruction directe de le conserver.

## 9. Méthode archive propre

La méthode prévue était `mktemp -d`, puis `git archive` du SHA exact et
suppression de `.dart_tool` uniquement dans cette archive. Elle n'a pas été
exécutée : le STOP Case C intervient avant le cleanup et avant les validations.

L'agent B a été interrompu immédiatement. Il confirme qu'aucun dossier `mktemp`
n'avait été créé ; aucun nettoyage temporaire n'était donc requis.

## 10. MCP Dart

Le MCP Dart n'est pas disponible dans les outils de cette session. Aucun usage
MCP n'est revendiqué. Les preuves utilisent uniquement le filesystem et les
commandes Git en lecture autorisées.

## 11. Sous-agents et incidents

| Passe | Mission | Verdict |
|---|---|---|
| Agent A | Repository Hygiene | BLOCKED, troisième artefact confirmé |
| Agent B | Clean Baseline Execution | BLOCKED, interrompu avant archive |
| Agent C | Scope & Evidence | BLOCKED, faux PASS évité |
| Reviewer R1 | Truthfulness | PASS après correction documentaire |
| Orchestrateur | Gate, arbitrage et rapport | BLOCKED conforme au cas C |

Arbitrages : l'agent A a proposé un cleanup de `build/` et du lockfile ; ces
extensions ont été refusées. L'agent C a proposé un autre nom de rapport ; le
chemin normatif du prompt a été conservé.

Incidents sans effet : une première tentative de spawn combinait un fork
d'historique avec un type d'agent incompatible, puis a été relancée sans fork.
Une première inspection profonde utilisait une variable shell non exportée ;
les commandes read-only ont échoué puis ont été relancées avec le chemin
littéral. Aucun fichier n'a été touché par ces incidents.

`codex_rule.md` demande des passes Implémentation, Tests, Build et Critique. Les
agents A, B, C et R1 couvrent ces responsabilités. L'obligation générique de
tests/commentaires ne peut pas outrepasser le STOP et l'interdiction directe de
modifier du code ou des tests.

## 12. map_core complet

BLOCKED / NOT RUN. Aucun `dart pub get`, test ou analyze n'a été lancé dans le
worktree ou une archive. Aucun résultat historique n'est réutilisé comme preuve
fraîche.

## 13. map_gameplay complet

BLOCKED / NOT RUN. Aucun `dart pub get`, `dart pub deps`, test ou analyze n'a
été lancé. Il n'existe donc aucune nouvelle preuve `uuid`/`fixnum` pour ce gate.

## 14. map_runtime complet

BLOCKED / NOT RUN. La suite Flutter complète obligatoire n'a pas été lancée,
car le gate préalable a ordonné STOP.

## 15. Runtime host smoke

BLOCKED / NOT RUN. Les tests host n'ont pas été inventoriés ni exécutés dans
une archive propre.

## 16. Build macOS

BLOCKED / NOT RUN. Aucun build n'a été lancé. Build runner n'a pas été exécuté.

## 17. Comparaison worktree partagé / archive propre

Aucune archive n'existe, donc aucune comparaison de résultats de tests n'est
possible. Les seuls bytes audités sont ceux de HEAD et du worktree principal.
Avant création de ce rapport, le statut principal était identique au Gate 0.

## 18. Résolution des 45 échecs précédents

NON RÉSOLUE. Les 45 échecs runtime observés pendant F1-PREREQ ne peuvent être
ni attribués au worktree Selbrume concurrent, ni reproduits depuis le commit
propre dans ce lot. Toute requalification serait un faux résultat.

## 19. Fichiers créés/modifiés/supprimés

Créé par F1-ENTRY :

```text
reports/narrativeStudio/events/ns_event_v2_f1_entry_repository_hygiene_clean_baseline_v0.md
```

Modifiés par F1-ENTRY : aucun. Supprimés par F1-ENTRY : aucun.

Ce rapport est l'unique fichier créé et constitue lui-même son contenu complet.
Le reproduire intégralement à l'intérieur de lui-même créerait une récursion
infinie ; aucune autre annexe de contenu n'est nécessaire.

Drifts exclus et non touchés :

```text
packages/map_editor/pubspec.lock
selbrume/maps/map_bourg_selbrume.json
selbrume/project.json
selbrume/assets/borders/snapshots/*/frame_0000.png (4 fichiers)
```

## 20. Gate Git final

```text
git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock
 M selbrume/maps/map_bourg_selbrume.json
 M selbrume/project.json
?? reports/narrativeStudio/events/ns_event_v2_f1_entry_repository_hygiene_clean_baseline_v0.md
?? selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
?? selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
?? selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
?? selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png

git diff --stat
 packages/map_editor/pubspec.lock       |  16 +-
 selbrume/maps/map_bourg_selbrume.json |  14 +-
 selbrume/project.json                 | 414 +++++++++++++++++++++++++++++++++-
 3 files changed, 434 insertions(+), 10 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
selbrume/maps/map_bourg_selbrume.json
selbrume/project.json

git diff --check
<empty>

git ls-files | rg '(^|/)\.dart_tool/'
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot

git diff -- packages/map_gameplay/pubspec.lock
<empty>

git ls-files --deleted -- 'packages/map_gameplay/.dart_tool/**'
<empty>

git diff -- .gitignore packages/map_gameplay/.gitignore
<empty>

git diff --name-only -- packages/map_core/lib packages/map_core/test packages/map_gameplay/lib packages/map_gameplay/test packages/map_runtime/lib packages/map_runtime/test packages/map_editor packages/map_battle examples/playable_runtime_host/lib selbrume assets
packages/map_editor/pubspec.lock
selbrume/maps/map_bourg_selbrume.json
selbrume/project.json
```

L'anti-scope tracked retourne uniquement les trois drifts déjà présents au
Gate 0 : editor lock, map Bourg Selbrume et projet Selbrume. Les quatre PNG non
suivis restent visibles dans `git status`. Hashes au Gate final :

```text
a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc  packages/map_editor/pubspec.lock
696b131633ddcaaf0f0a06ee3f53d35493aa53e07cdc7659948e26570fbeb749  selbrume/maps/map_bourg_selbrume.json
f2318ad7032f1a38d90214d959d736fb52805a52cdb3946abe02ea6ab9cf9c39  selbrume/project.json
468029b382742d1c6cfb276f667da4a4bf1e8e2eca9e383621beae0cbf89fccd  selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
71fcc3cde140d57f2deb9f12cc6b062dbf0e865875d916b6834ce6abe54b72e7  selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
ce77996d337c5bafec86f765f8b1da5820ce09d37b79165d28e74fb6ed23cefd  selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
6e300994e6625089deee8a975b0da7e4761c0b1687dd8e8efbf34dd42fc16687  selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png
```

Les deux listes sont identiques ; aucun changement concurrent n'a été altéré.

## 21. Scope final

Les frontières fonctionnelles sont respectées : aucun fichier sous `lib/`,
`test/`, `map_editor`, `map_battle`, host, Selbrume ou assets n'a été modifié
par F1-ENTRY. Aucun contrat Event V2, dépendance ou fichier généré n'a changé.

Le prompt direct interdit tout code et tout test, alors que `codex_rule.md`
demande génériquement tests et commentaires. L'instruction directe et le STOP
sont prioritaires ; aucun test artificiel ni commentaire de code n'a été ajouté.

## 22. Review contradictoire

Première passe R1 : BLOCKED documentaire. Deux findings ont été acceptés : les
hashes initial/final n'étaient pas reproduits et la conclusion Selbrume était
trop absolue. Les hashes, l'anti-scope exact et le qualificatif de propriété ont
été ajoutés. Re-review finale : PASS, aucun finding restant. Le reviewer confirme
que le verdict du lot reste honnêtement BLOCKED par le Case C.

## 23. Risques résiduels

1. Le repository suit toujours trois artefacts `.dart_tool`, dont un binaire de
   24 MiB lié à une version locale du runner de tests.
2. La baseline complète map_core/gameplay/runtime/host reste non prouvée depuis
   une archive propre.
3. Les 45 échecs runtime antérieurs restent non reclassifiés.
4. Commencer F1 maintenant contournerait explicitement son gate d'entrée.

Observations hors scope de l'agent A sur d'autres fichiers suivis mais ignorés :
elles peuvent motiver un audit repository séparé, mais ne doivent pas être
agrégées au cleanup `.dart_tool` ou utilisées pour retirer le lockfile.

## 24. Gate de reprise F1

```text
exactement trois fichiers .dart_tool autorisés à la suppression : REQUIRED
aucun fichier .dart_tool encore suivi après cleanup              : REQUIRED
.dart_tool ignoré                                                 : PASS
pubspec.lock conservé                                             : PASS
archive du commit nettoyé                                         : BLOCKED
map_core complet                                                   : BLOCKED
map_gameplay complet                                               : BLOCKED
map_runtime complet                                                : BLOCKED
host smoke et build                                                : BLOCKED
reviewer sans blocker                                              : PASS
```

Prochain lot recommandé : `NS-EVENT-V2 — F1-ENTRY-BIS — Complete Tracked
.dart_tool Cleanup & Clean Baseline Validation V0`, avec allowlist explicite
des trois fichiers et le même protocole d'archive propre. Ne pas commencer F1
avant sa clôture.

## 25. Verdict

```text
F1-ENTRY : BLOCKED

Generated Dart metadata removed : BLOCKED
Ignore rule effective : PASS
Clean map_core baseline : BLOCKED
Clean map_gameplay baseline : BLOCKED
Clean map_runtime baseline : BLOCKED
Clean runtime host smoke : BLOCKED

F1-PREREQ : CLOSED
Phase F1 : BLOCKED AT ENTRY
Phase F2 : NOT READY
```

Aucun code fonctionnel, projet Selbrume ou dépendance n'a été modifié par
F1-ENTRY. Aucun commit Git n'a été créé.
