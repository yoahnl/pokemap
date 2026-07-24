# Clôture Phase 0 — PokeMap Hub

Date : 2026-07-25

HEAD de référence : `a3bc35104b558e2d8c27e1c81ac7c2a3fe1a43cc`

Verdict : **GO pour démarrer la Phase 1 documentairement ; aucun code Phase 1
n’est inclus dans cette clôture.**

## Audit initial

L’audit source conclut que le moteur est suffisamment solide, mais que le Hub
multijeu est NO-GO : absence de format installable, library, isolation saves,
shell joueur et distribution. Le code confirme notamment une save globale, un
import destructif, la présence possible de `mistralApiKey`, et l’absence de
`GamePackageManifest`, `SaveEnvelope`, `GameSessionController` et
`GameCompleted`.

Le host reste un outil interne. Les suites vertes citées par l’audit ne sont pas
additionnées et les trois échecs Selbrume historiques empêchent toujours toute
affirmation « dépôt globalement vert » sans preuve fraîche.

## Lots concrets

### HUB-000 — Architecture, ownership et ports

- Objectif : séparer Hub/player/host et fixer l’autorité des contrats.
- Périmètre : ADR-0001, ownership, registre, glossaire, port de session.
- Futurs fichiers : nouveaux packages/apps et gardes d’imports dans leurs tests.
- Tests : analyse des `pubspec`/imports, transitions du port, absence de cycle.
- DONE : D01-D03 acceptées, graphes et propriétaires exhaustifs.
- Risques : API runtime publique trop large, duplication des adaptateurs.
- Dépendances : `map_core`, snapshots publics `map_runtime`.

### HUB-001 — Distribution `.pokemapgame` v1

- Objectif : package déterministe, data-only, inspectable et reproductible.
- Périmètre : identité, manifest, ZIP, inventaire, JCS, tree hash, signature.
- Futurs fichiers : `packages/map_distribution/lib/src/{manifest,codec,
  canonicalization,builder,inspector}.dart` et tests/fixtures associés.
- Tests : schema/codec, SemVer, builds octet-identiques, vecteurs et conflicts.
- DONE : D04-D06 acceptées et exemples/vecteurs recalculables.
- Risques : coût disque STORED, divergence JCS/ZIP.
- Dépendances : HUB-000, `map_core`; aucune dépendance Flutter.

### HUB-002 — Sécurité, confiance et quotas

- Objectif : rejeter les archives hostiles avant exposition au filesystem.
- Périmètre : threat model, quotas numériques, data allowlist, secrets,
  sideload/signatures et corpus hostile.
- Futurs fichiers : validator hostile, extraction staging, scanner, diagnostics.
- Tests : HP-001 à HP-035, limites exactes, kill tests, non-régression.
- DONE : D07-D08 acceptées ; aucune extraction avant checks structurels.
- Risques : décodeurs natifs, faux positifs secrets, différences filesystem.
- Dépendances : HUB-001 et adaptateurs plateforme du Hub.

### HUB-003 — Compatibilité et saves multijeux

- Objectif : décider installation/launch/load et préserver toute save valide.
- Périmètre : six axes de compatibilité, `SaveEnvelope`, profiles/slots,
  atomicité, backup, migration, lifecycle et import legacy.
- Futurs fichiers : modèles/codec dans `map_core`, repository et migrations
  dans le Hub, adaptateur checkpoint runtime.
- Tests : matrice C-001 à C-020, checksum, crash à chaque étape, isolation A/B,
  migration/rollback et disque plein.
- DONE : D09-D11 acceptées ; résultat déterministe ; zéro perte de dernière save.
- Risques : fsync/rename par OS, save future, promesse `compatibilityId`.
- Dépendances : HUB-001/002 et versions côte à côte de la Phase 3.

### HUB-004 — Parcours et fin de jeu

- Objectif : normer Hub, titre, session, pause, fin, erreurs et accessibilité.
- Périmètre : IA, machine d’états, actions, 13 journeys, `GameCompleted`.
- Futurs fichiers : contrats runtime/core, surfaces `map_player_ui`, routes Hub.
- Tests : états/guards, focus/input, responsive, lifecycle, completion/crédits.
- DONE : D14-D15 acceptées ; chaque état a cancel/timeout/recovery.
- Risques : cohérence input/focus, checkpoint de fin, absence de lot FG dédié.
- Dépendances : HUB-000/003 et futurs snapshots de présentation.

### HUB-005 — Isolation de session

- Objectif : protéger le Hub et garantir le teardown jeu A → jeu B.
- Périmètre : même processus mobile/V0, child desktop du même binaire,
  protocole, timeouts, crash marker et recovery.
- Futurs fichiers : superviseur Hub, adaptateurs in-process/child-process et
  integration tests macOS/Windows/Linux.
- Tests : handshake, mauvais token, heartbeat, exit, OOM simulé, kill, double
  session et relaunch.
- DONE : D12-D13 acceptées ; prototype desktop satisfait le critère <12 s.
- Risques : OOM mobile, sandbox/signature/IPC desktop.
- Dépendances : HUB-000, save repository et release packaging.

## Inventaire complet des fichiers créés

Le contenu complet de chaque fichier créé constitue le Decision Pack ; les
liens ci-dessous pointent vers les sources normatives, sans extrait tronqué.

- [`README.md`](README.md), [`decision-register.md`](decision-register.md),
  [`glossary.md`](glossary.md)
- [`adr/0001-hub-player-host-boundaries.md`](adr/0001-hub-player-host-boundaries.md)
  et [`adr/0002-session-isolation-by-platform.md`](adr/0002-session-isolation-by-platform.md)
- [`contracts/ownership-and-dependencies.md`](contracts/ownership-and-dependencies.md),
  [`contracts/pokemapgame-v1.md`](contracts/pokemapgame-v1.md),
  [`contracts/game-manifest-v1.schema.json`](contracts/game-manifest-v1.schema.json),
  [`contracts/canonicalization-vectors.json`](contracts/canonicalization-vectors.json),
  [`contracts/game-session-port.md`](contracts/game-session-port.md),
  [`contracts/session-failure-and-exit-matrix.md`](contracts/session-failure-and-exit-matrix.md)
- [`contracts/examples/README.md`](contracts/examples/README.md)
- [`contracts/examples/minimal-valid/game-manifest.json`](contracts/examples/minimal-valid/game-manifest.json)
  et [`contracts/examples/minimal-valid/payload/project/project.json`](contracts/examples/minimal-valid/payload/project/project.json)
- [`contracts/examples/complete-valid/game-manifest.json`](contracts/examples/complete-valid/game-manifest.json),
  [`project.json`](contracts/examples/complete-valid/payload/project/project.json),
  [`CREDITS.txt`](contracts/examples/complete-valid/payload/legal/CREDITS.txt) et
  [`icon.png.base64`](contracts/examples/complete-valid/payload/presentation/icon.png.base64)
- manifests invalides :
  [`future-package-format.json`](contracts/examples/invalid/future-package-format.json),
  [`invalid-game-id.json`](contracts/examples/invalid/invalid-game-id.json),
  [`path-traversal.json`](contracts/examples/invalid/path-traversal.json),
  [`unknown-required-field.json`](contracts/examples/invalid/unknown-required-field.json)
- [`security/pokemapgame-v1-threat-model.md`](security/pokemapgame-v1-threat-model.md),
  [`security/package-trust-and-quota-policy.md`](security/package-trust-and-quota-policy.md),
  [`security/hostile-package-corpus.md`](security/hostile-package-corpus.md)
- [`compatibility/version-and-capability-policy.md`](compatibility/version-and-capability-policy.md)
  et [`compatibility/compatibility-matrix.json`](compatibility/compatibility-matrix.json)
- [`saves/save-envelope-v1.schema.json`](saves/save-envelope-v1.schema.json),
  [`saves/save-lifecycle-and-migration-policy.md`](saves/save-lifecycle-and-migration-policy.md)
  et [`saves/examples/minimal-valid-save-envelope.json`](saves/examples/minimal-valid-save-envelope.json)
- saves invalides :
  [`completed-without-date.json`](saves/examples/invalid/completed-without-date.json),
  [`future-schema-version.json`](saves/examples/invalid/future-schema-version.json),
  [`unsafe-profile-id.json`](saves/examples/invalid/unsafe-profile-id.json)
- [`product/information-architecture.md`](product/information-architecture.md),
  [`product/player-state-machine.md`](product/player-state-machine.md),
  [`product/action-availability-matrix.md`](product/action-availability-matrix.md),
  [`product/acceptance-journeys.md`](product/acceptance-journeys.md),
  [`product/game-completion-contract.md`](product/game-completion-contract.md)
- ce rapport de clôture : [`phase-0-exit-gate.md`](phase-0-exit-gate.md).

## Passes et preuves

### Audit / Architecture

La passe initiale a inventorié les contrats absents, vérifié les frontières
actuelles et confirmé le NO-GO produit. Les ADR répondent sans modifier le
moteur ni promouvoir le host.

### Implémentation

Implémentation strictement documentaire : nouveaux Markdown, JSON Schema,
fixtures et vecteurs sous `reports/product/pokemap_hub/phase_0/`. Aucun fichier
Dart/Flutter, pubspec, lockfile ou source suivie n’a été modifié.

### Tests

Validation locale sans ajout de dépendance au repository :

- parsing de tous les JSON ;
- `Draft202012Validator.check_schema` sur les deux schémas avec
  `jsonschema[format] 4.25.1` dans un venv temporaire ;
- validation Draft 2020-12 avec `FormatChecker` actif, y compris rejets
  synthétiques d’URI et de date-time invalides ;
- 2 manifests valides acceptés et 4 fixtures invalides rejetées ;
- 1 save valide acceptée et 3 fixtures invalides rejetées ;
- 1 vecteur JCS, 2 tree hashes et le checksum save recalculés ;
- payloads texte et PNG décodé confrontés à chaque taille/hash de manifest ;
- SemVer strict : `1.0.0-01` rejeté, `1.0.0-0` accepté ;
- matrice de compatibilité : 20 cas, quatre décisions couvertes ;
- registre : 15 décisions uniques et Accepted ;
- vérification des liens Markdown relatifs.

Le venv de validation est hors dépôt et jetable. La Phase 1 DOIT aussi faire
exécuter ces schemas par le codec/validateur Dart et conserver ces fixtures
comme tests contractuels.

### Build / Validation

Aucun build ou test Dart/Flutter n’est pertinent pour un lot documentaire qui
n’a changé aucun code. Cette clôture ne prétend donc ni valider le runtime, ni
rendre le dépôt globalement vert.

### Critique finale

La première revue indépendante a rendu NO-GO sur : absence de validator Draft
2020-12, états `preparing/prepared/title` ambigus, SemVer prerelease non strict,
sens contradictoire de `saveFormat`, `projectFormat` numérique divergent du
code, token IPC dans argv et payloads non vérifiables. Les contrats ont été
corrigés puis les schémas et payloads revalidés. Les risques non exécutables
(ZIP hostiles, kill tests, filesystem et child process) restent explicitement
reportés aux phases d’implémentation.

La seconde passe indépendante a rendu **GO** : 39/39 artefacts inventoriés,
aucun bloquant/important, 16 JSON parsés, schémas/fixtures/hashes/checksum
validés, liens et Markdown propres, HEAD et sources suivies inchangés.

## Commandes et résultats exacts

Baseline :

```text
git rev-parse HEAD
→ a3bc35104b558e2d8c27e1c81ac7c2a3fe1a43cc

git status --short --untracked-files=all | wc -l
→ 74
```

Validation standard isolée :

```text
python3 -m venv <tmp>/venv
<tmp>/venv/bin/pip install 'jsonschema[format]==4.25.1'
<tmp>/venv/bin/python <validateur Phase 0 sur stdin>

→ JSON_PARSE_OK 16
→ DRAFT202012_OK game-manifest-v1.schema.json valid=2 invalid=4
→ DRAFT202012_OK save-envelope-v1.schema.json valid=1 invalid=3
→ FORMAT_CHECKER_OK uri=date-time
→ PAYLOAD_TREE_OK minimal-valid files=1
→ PAYLOAD_TREE_OK complete-valid files=3
→ CANONICAL_HASHES_OK jcs=1 trees=2 saves=1
→ COMPATIBILITY_OK cases=20
→ DOC_CONTRACT_OK links=21 decisions=15 artifacts=39
```

Hygiène documentaire :

```text
rg -n '[[:blank:]]+$' reports/product/pokemap_hub/phase_0
→ aucun résultat

contrôle des fences Markdown
→ MARKDOWN_FENCES_OK

rg -n -- '--session-token|TODO|TBD|PLACEHOLDER|XXX' \
  reports/product/pokemap_hub/phase_0
→ aucun résultat
```

État Git final :

```text
git diff --name-only | wc -l
→ 0

find reports/product/pokemap_hub/phase_0 -type f | wc -l
→ 39

git status --short --untracked-files=all | wc -l
→ 113
```

Les 39 entrées supplémentaires sont exactement le nouveau dossier Phase 0.
Les 74 entrées initiales de l’utilisateur sont préservées. Aucun stage, commit,
stash, changement de branche ou push n’a été effectué.

## Checklist de sortie

- [x] extension, layout et schéma package v1 ;
- [x] identité stable et versioning ;
- [x] canonicalisation, inventaire, hashes et signature ;
- [x] threat model, quotas, hostile corpus et secrets ;
- [x] compatibilité package/Hub/runtime/capability/projet/save ;
- [x] SaveEnvelope, isolation, atomicité, backup, migration et legacy ;
- [x] dépendances et ownership ;
- [x] session isolation par plateforme et protocole ;
- [x] Hub, titre, pause, fin, erreurs, lifecycle et recovery ;
- [x] décisions P0-D01 à P0-D15 ratifiées ;
- [x] aucun code produit créé avant fermeture de la Phase 0.

## Auto-critique et risques résiduels

- STORED maximise le déterminisme et la sûreté, mais doit être benchmarké sur
  les assets réels ; changer de méthode exigera un format v2.
- Les JSON Schema ne peuvent exprimer seules les bijections, sommes, ordre,
  tree hash et références ; le validator Dart doit rester l’autorité combinée.
- La politique d’extensions peut devoir évoluer pour les assets PokeMap réels,
  uniquement par décision versionnée et tests hostiles.
- `compatibilityId` est une promesse éditeur ; backups et versions côte à côte
  sont indispensables.
- l’atomicité filesystem et le child process doivent être prouvés par kill tests
  sur chaque OS.
- un lot roadmap fangame dédié à `GameCompleted` manque encore ; la Phase 4 ne
  doit pas l’implémenter sans rattachement explicite.

## Prochaine action autorisée

Démarrer la Phase 1 par le squelette Dart pur `packages/map_distribution`, puis
implémenter le codec/schema/canonicalisation avec les exemples présents comme
premiers tests. Le Hub visuel reste hors scope jusqu’à la fermeture des Phases
1 à 4.
