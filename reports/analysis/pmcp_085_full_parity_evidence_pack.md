# PMCP-085 — Conformance, sécurité et gate « 100 % »

Date : 2026-07-31
Lot : `PMCP-085` — Conformance, sécurité et gate « 100 % »
Verdict proposé : **PARTIAL — gate de release BLOCKED**
Revendication produit « 100 % » : **NON AUTORISÉE**

## Résumé exécutif

Le lot matérialise une matrice machine-readable de 62 ressources sémantiques et
223 mutations canoniques, vérifie leurs contrats et leurs quatre transports,
ajoute la conformance MCP stricte, les limites de taille et de débit, un corpus
d'enveloppes invalides, un threat model, un parcours doré commun et un gate
cross-package reproductible.

Les preuves techniques sont vertes : 297 tests `map_authoring`, 12 tests éditeur,
22 tests MCP, 2 tests runtime et 6 tests host, plus toutes les analyses ciblées.
Le catalogue canonique contient zéro cellule `BLOCKED` ou `MISSING`, et chaque
`NOT_APPLICABLE` est justifié.

La revue finale interdit toutefois de confondre disponibilité du transport
générique et migration effective des gestes produit de l'éditeur. Le rapport
PMCP-081 conservait cinq chemins structurés hors API. Ils sont toujours présents
et explicitement inventoriés. Le script exécute donc toute la validation, puis
sort volontairement avec le code `1` et le message :

```text
PMCP-085 BLOCKED: PMCP-081 editor mutation debt is still explicit.
```

Le résultat honnête est `PARTIAL`; ni PMCP-085 ni la phase 8 ne doivent être
marqués `DONE` avant migration de cette dette et nouvelle preuve fraîche.

## Confirmation et remise en cause du scope

Le lot demandé est bien le prochain lot `PMCP-085` de
`pokemap_authoring_api_mcp_lot_roadmap.md`. Son périmètre a été conservé : matrice,
comparaison éditeur/runtime, contrats, conformance MCP, sécurité, fuzz déterministe,
Golden Journey, documentation et release gate.

Une hypothèse initiale a été remise en cause pendant la critique : supprimer le
nom `_legacyStructuredAuthoringDebt` et ne scanner que les écritures de bytes
aurait masqué des mutations derrière des repositories. Le repo prouve que
PMCP-081 était `PARTIAL`; cette approche aurait contredit le critère « aucun
`BLOCKED` ou `MISSING` caché par un outil générique ». Le garde-fou historique a
donc été restauré, les cinq chemins sont testés comme inventaire exact et le gate
strict reste fermé.

## Audit initial

- Base observée au début du lot : `74eb92b83` (`feat(mcp): complete authoring mutation runtime bridge`).
- Le worktree contenait déjà des modifications externes Smart Tiles dans
  `packages/map_core` et `packages/map_editor`, le lockfile du host et
  `.superpowers/brainstorm/...`; elles ont été laissées hors scope.
- Pendant le lot, des commits externes ont avancé `HEAD` jusqu'à `1973931d2`
  (`docs(map-editor): record Gate 6 evidence`). Ils n'appartiennent pas à PMCP-085.
- Contrat canonique : `AuthoringMutationDispatcher.canonical()` et ses 223
  descripteurs, la session directe Dart et le worker JSONL.
- Surface MCP héritée : 12 tools, resources opaques, mutations plan/apply,
  runtime render/playtest/job et recovery PMCP-082 à PMCP-084.
- Preuve éditeur héritée : `reports/analysis/pmcp_081_editor_mutation_migration_evidence.md`
  propose explicitement `PARTIAL` et liste cinq dettes.
- Risques principaux : fausse revendication « 100 % », dérive entre registres,
  schémas MCP permissifs, abus taille/débit, fuite de chemins, receipts divergents,
  et mélange avec le chantier Smart Tiles concurrent.
- Limite de scope préservée : aucune mécanique gameplay, aucun changement de
  roadmap, aucun transport réseau, aucune authentification distante et aucun
  accès arbitraire au filesystem.

## Matrice et preuves de parité

Sortie fraîche de `dart run tool/pmcp085_conformance.dart | jq '.summary'` :

```json
{
  "coverageScope": "canonicalAuthoringCatalog",
  "resourceCount": 62,
  "mutationActionCount": 223,
  "blockedOrMissingCount": 0,
  "notApplicableCount": 51,
  "catalogComplete": true
}
```

`catalogComplete` ne concerne que le catalogue API. La matrice :

- porte un propriétaire canonique explicite pour chacune des 62 ressources ;
- exige `SUPPORTED` pour toute cellule applicable ;
- exige une justification non vide pour chaque cellule `NOT_APPLICABLE` ;
- associe les 223 mutations à un test de contrat existant ;
- vérifie les garanties `dryRun`, idempotence, CAS de révision et undo ;
- compare automatiquement les commandes runtime et les `actionId` explicites
  trouvés dans les sources éditeur au registre canonique ;
- annonce les transports API directe, JSONL CLI, éditeur et MCP pour chaque
  action canonique.

Les 51 `NOT_APPLICABLE` correspondent aux capacités visuelles de ressources
non visuelles et aux garanties de mutation qui ne s'appliquent pas au
`gameSave` sandboxé ou au `gamePackage` dérivé. Leur justification est incluse
dans la sortie JSON, cellule par cellule.

## Golden Journey

Le scénario commun crée `pmcp085_golden_map` (3 × 2) depuis un projet vide et
compare une projection stable du receipt : action, version, statut et changements
ressource/chemin. Les preuves couvrent :

- API directe Dart ;
- worker JSONL/CLI réel ;
- `AuthoringMutationAdapter` réel de l'éditeur ;
- serveur MCP réel avec `LocalAuthoringClient` et projet temporaire réel.

Les quatre surfaces produisent le contenu attendu de
`packages/map_authoring/test/fixtures/pmcp085_golden_receipt.json`.

## Conformance, sécurité et fuzz

- Les 12 tools publient des objets Zod stricts, leurs outputs et annotations.
- Les opérations query rejettent les combinaisons sémantiquement incohérentes.
- Le garde partagé refuse avant tout gateway une enveloppe UTF-8 de plus de
  64 KiB (`resource_limit`) ou plus de 512 requêtes par fenêtre locale de
  60 secondes (`rate_limited`).
- Les tests utilisent un budget réduit pour prouver que le gateway n'est jamais
  atteint après refus.
- Le corpus déterministe contient 7 cas manuels et 64 enveloppes générées.
- Les contrôles de chemin, permission, confirmation, recovery, identité projet,
  artefacts opaques et commandes runtime fixes restent couverts par les suites
  héritées.
- `tools/pokemap_mcp/THREAT_MODEL.md` documente actifs, frontières, contrôles et
  risques résiduels.

## Gate éditeur et dette explicite

Le transport générique éditeur produit bien le même receipt que les autres
surfaces. Cela ne prouve pas que tous les écrans produit l'utilisent. L'inventaire
PMCP-081 reste exactement :

1. `lib/src/application/services/map_lifecycle_transaction_service.dart`
2. `lib/src/application/use_cases/map_use_cases.dart`
3. `lib/src/features/editor/state/editor_notifier.dart`
4. `lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
5. `lib/src/ui/canvas/storylines_workspace.dart`

Le nouveau test garantit que cette liste ne peut être supprimée, renommée ou
élargie silencieusement. Le release gate refuse la revendication tant que la
constante existe. Cette dette n'est donc ni masquée par la matrice, ni convertie
artificiellement en `SUPPORTED`.

## Passes séparées obligatoires

Les instructions système interdisaient de lancer des sub-agents sans demande
explicite de l'utilisateur. Conformément au fallback de `codex_rule.md`, cinq
passes locales séparées ont été réalisées :

1. **Audit / Architecture — PASS avec dépendance bloquante** : frontières Dart
   pur/Flutter/TypeScript respectées, aucun import Flutter/Flame dans
   `map_authoring`, mais PMCP-081 reste `PARTIAL`.
2. **Implémentation — PASS** : matrice, admission guard, schémas stricts,
   documentation et gate sont minimaux et ne réimplémentent aucune règle métier
   en TypeScript.
3. **Tests — PASS** : cas positifs, négatifs, garde-fous, non-régression,
   fuzz déterministe et quatre transports couverts.
4. **Build / Validation — PASS technique** : format, syntaxe shell, TypeScript,
   compilation Dart, tests et analyses réussissent.
5. **Critique finale — BLOCKED pour la revendication globale** : la première
   version du garde-fou pouvait cacher la dette éditeur ; elle a été corrigée.
   Aucun statut `DONE` global n'est proposé.

## Fichiers créés

Le contenu intégral des fichiers créés est reproduit dans
`reports/analysis/pmcp_085_full_parity_evidence_pack_appendix.md`.

- `packages/map_authoring/lib/src/parity/full_authoring_parity.dart` — modèles,
  catalogue canonique, propriétaires et matrice capacité × ressource.
- `packages/map_authoring/test/fixtures/pmcp085_golden_receipt.json` — receipt
  stable partagé par quatre transports.
- `packages/map_authoring/test/parity/full_authoring_parity_test.dart` — parité
  catalogue/contrats/inventaires et Golden Journey API/CLI.
- `packages/map_authoring/tool/pmcp085_conformance.dart` — sortie JSON
  machine-readable et inventaire d'actions.
- `packages/map_editor/test/authoring_api/no_bypass_guardrail_test.dart` — dette
  éditeur exacte, absence de nouveaux raw writes et receipt éditeur.
- `tools/pokemap_mcp/THREAT_MODEL.md` — modèle de menace local stdio.
- `tools/pokemap_mcp/scripts/pmcp085_release_gate.sh` — gate cross-package strict.
- `tools/pokemap_mcp/src/request_guard.ts` — budget taille/débit partagé.
- `tools/pokemap_mcp/test/conformance_security.test.ts` — conformance, sécurité,
  corpus invalide et Golden Journey MCP.

## Fichiers modifiés et zones précises

- `packages/map_authoring/lib/map_authoring.dart`
  - zone : exports publics ;
  - changement : export du catalogue de parité ;
  - impact : inspection officielle sans import interne.
- `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`
  - zone : payload `describe()` ;
  - changement : ajout de `fullParity` ;
  - impact : même matrice exposée par l'API directe.
- `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`
  - zone : commande describe du worker ;
  - changement : propagation de `fullParity` ;
  - impact : CLI et MCP lisent la même preuve.
- `pokemap_authoring_api_mcp_action_catalog.md`
  - zone : section 30.1 ;
  - changement : chiffres frais, portée `canonicalAuthoringCatalog` et blocage
    éditeur explicite ;
  - impact : le catalogue ne peut pas être cité comme preuve produit globale.
- `tools/pokemap_mcp/README.md`
  - zone : workflow et section conformance/sécurité ;
  - changement : matrice, commandes, limites et état bloqué du gate ;
  - impact : documentation utilisateur/développeur honnête.
- `tools/pokemap_mcp/src/server.ts`
  - zone : composition des dépendances ;
  - changement : wrapper commun `McpRequestGuard` autour des quatre familles de
    gateways ;
  - impact : admission appliquée avant I/O ou logique métier.
- `tools/pokemap_mcp/src/tools/read_only.ts`
  - zone : schéma `pokemap_query` ;
  - changement : raffinements croisés des opérations et identifiants ;
  - impact : refus protocolaire des enveloppes ambiguës avant le worker.

Le test historique `editor_write_boundary_test.dart` a été temporairement
modifié pendant l'exploration puis restauré byte-for-byte avant le rapport ; il
ne fait pas partie du diff final.

## Tests ajoutés ou modifiés

- 4 tests Dart de parité exhaustive et receipts API/CLI.
- 3 tests Flutter de dette explicite, raw-write guard et receipt éditeur.
- 4 tests Node de schémas/annotations, taille/débit, corpus invalide et receipt MCP.
- Raffinement du test historique de frontière uniquement durant TDD, sans diff final.

### Preuves RED initiales

- Dart : `AuthoringFullParityCatalog` absent.
- Flutter : présence de `_legacyStructuredAuthoringDebt` détectée.
- TypeScript : module `request_guard` absent.
- Une passe intermédiaire a détecté deux faux positifs (`transactionId` pris
  pour `actionId`) ; le motif exige désormais un vrai identifiant de champ.

## Commandes et résultats exacts

### Validation ciblée

```text
cd packages/map_authoring
dart test test/parity/full_authoring_parity_test.dart --reporter expanded
Résultat exact : 00:00 +4: All tests passed!

cd packages/map_editor
flutter test test/authoring_api/editor_mutation_parity_test.dart test/authoring_api/editor_write_boundary_test.dart test/authoring_api/no_bypass_guardrail_test.dart --reporter expanded
Résultat exact : 00:00 +12: All tests passed!

cd tools/pokemap_mcp
npm run check
Résultat exact : tsc -p tsconfig.json --noEmit, exit 0

cd tools/pokemap_mcp
npm run build
Résultat exact : tsc -p tsconfig.json, exit 0

cd packages/map_authoring
dart compile exe tool/pmcp085_conformance.dart -o /tmp/pokemap-pmcp085-conformance
Résultat exact : Generated: /tmp/pokemap-pmcp085-conformance
```

### Release gate complet

Commande exacte :

```bash
cd tools/pokemap_mcp
./scripts/pmcp085_release_gate.sh
```

Résultats exacts utiles :

```text
map_authoring : 00:15 +297: All tests passed!
map_authoring analyze : No issues found!
map_editor ciblé : 00:02 +12: All tests passed!
map_editor analyze : No issues found! (ran in 5.7s)
MCP : tests 22, pass 22, fail 0, cancelled 0, skipped 0, todo 0
map_runtime ciblé : 00:01 +2: All tests passed!
map_runtime analyze : No issues found! (ran in 5.0s)
playable_runtime_host ciblé : 01:01 +6: All tests passed!
playable_runtime_host analyze : No issues found! (ran in 4.9s)
PMCP-085 BLOCKED: PMCP-081 editor mutation debt is still explicit.
exit code : 1 (refus attendu du claim global)
```

### Format, syntaxe et hygiène

```text
dart format --output=none --set-exit-if-changed <5 fichiers Dart>
Résultat exact : Formatted 5 files (0 changed) in 0.02 seconds.

bash -n tools/pokemap_mcp/scripts/pmcp085_release_gate.sh
Résultat exact : exit 0

git diff --check
Résultat exact : exit 0
```

Le build Flutter complet n'est pas relancé : aucune source Flutter produit n'est
modifiée par PMCP-085. Les tests ciblés et `flutter analyze` des packages éditeur,
runtime et host sont la validation proportionnée. Le serveur MCP est réellement
buildé et l'outil Dart est compilé en exécutable.

## État Git

État initial pertinent : `74eb92b83`, avec changements externes Smart Tiles,
`examples/playable_runtime_host/pubspec.lock` et `.superpowers/brainstorm/...`.

État avant commit : `HEAD` externe `1973931d2`; seuls les fichiers PMCP-085
listés dans ce rapport et les deux rapports associés doivent être indexés. Les
changements externes restent hors index et ne sont ni restaurés ni modifiés par
ce lot.

L'état Git final exact et le hash du commit sont ajoutés au message de livraison
après le commit atomique.

## Limites conservées et risques restants

- Cinq chemins éditeur structurés restent hors API ; c'est le blocker principal.
- Le rate limit est process-local et se réinitialise au redémarrage.
- Le serveur reste local stdio ; un transport distant exige un threat model
  d'authentification, autorisation, tenancy et réseau séparé.
- Le playtest interactif conserve les permissions du processus local lancé.
- La matrice prouve le catalogue et les transports génériques ; elle ne remplace
  jamais une preuve de consommation produit ou runtime par ressource.
- Le chantier Smart Tiles concurrent n'est pas inclus dans les résultats ni le commit.

## Auto-critique finale

La première implémentation aurait produit un gate techniquement vert mais
sémantiquement trompeur : le scan ne voyait plus les opérations repository et
la présence de l'adaptateur générique était assimilée à une migration UI. La
relecture du rapport PMCP-081 a invalidé cette conclusion. Restaurer la dette et
faire échouer le gate rend la livraison moins spectaculaire, mais conforme au
but réel du lot : ne jamais autoriser « 100 % » sans preuve.

La couverture de sécurité reste déterministe plutôt que probabiliste : le corpus
généré est stable pour éviter les flakes, mais ne remplace pas un fuzzing long en
CI. Les limites de débit protègent contre les erreurs locales, pas contre un
adversaire distant authentifié.

## Statuts proposés et prochaines étapes

- `PMCP-082` : conserver le statut précédemment prouvé.
- `PMCP-083` : conserver le statut précédemment prouvé.
- `PMCP-084` : conserver le statut précédemment prouvé.
- `PMCP-085` : proposer `PARTIAL` avec release gate `BLOCKED`.
- Phase 8 : proposer `PARTIAL`, revendication « 100 % » interdite.

Prochain lot recommandé, sans l'implémenter ici : fermer réellement PMCP-081 en
migrant les cinq chemins inventoriés vers les actions spécialisées de
`map_authoring`, supprimer ensuite la constante de dette, relancer le gate exact,
et seulement alors proposer PMCP-085/phase 8 `DONE`. Aucun fichier roadmap n'est
modifié automatiquement.
