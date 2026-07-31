# PMCP-072 — Readiness, Golden Slice et package identique

## Résumé exécutif

Verdict proposé : `DONE` pour PMCP-072. L'Authoring API orchestre désormais
les diagnostics de readiness sans appliquer de correction, adapte les rapports
FG-180/FG-185 de `map_core`, et expose build/inspect/verify/release derrière un
port path-free. `GamePackageBuilder` publie l'identité SHA-256 des octets qu'il
a réellement construits. Une Golden Slice part d'un scaffold sans map, crée sa
map par `map.create` plan/apply, construit et inspecte le package, l'installe
avec le vrai Hub, puis charge la map avec `RuntimeMapGame` depuis l'installation.

Le roadmap `pokemap_roadmap_mecaniques_fangame.md` n'est pas modifié. `FG-180`
à `FG-184` restent `DONE`. `FG-185` reste `PARTIAL` : la Golden Slice technique
est prouvée, mais la signature/notarisation, l'installation froide de release,
le walkthrough humain et la dette de données Selbrume ne sont pas fermés.

## Scope confirmé

- Contrats et orchestration readiness/distribution : `map_authoring` pur Dart.
- Autorité des bytes et inspection : `map_distribution`.
- Adapter I/O, installation Hub et runtime de production : hôte d'exemple.
- Aucun transport MCP, aucune modification automatique du roadmap, aucune
  correction appliquée par la readiness.

## Audit initial

- Base Git : `2b5161ae feat(eval): add runtime jobs and artifacts`.
- `map_core` possédait déjà les agrégateurs fail-closed FG-180 et FG-185, mais
  ils n'étaient pas exposés comme diagnostics Authoring path-free.
- `GamePackageBuilder` produisait des bytes déterministes sans exposer leur
  digest dans son résultat; l'inspector et le receipt d'installation le
  recalculaient séparément.
- Le parcours Phase 7A existant prouvait export/install/runtime pour Selbrume,
  mais sa création de projet ne passait pas par l'Authoring API.
- Le workspace contenait déjà un lockfile hôte modifié, le prototype
  `.superpowers/...` et des changements `map_editor`; ils restent hors commit.

## Fichiers

Créés :

- `packages/map_authoring/lib/src/domains/project/readiness_actions.dart` —
  diagnostics cités, fix plans non exécutables, orchestrateur et adapters Core.
- `packages/map_authoring/lib/src/domains/distribution/package_actions.dart` —
  port build/inspect/install, preuves, mapping FG et release receipt.
- `packages/map_authoring/test/domains/project/readiness_actions_test.dart` —
  agrégation, citations obligatoires et absence d'auto-fix.
- `packages/map_authoring/test/domains/distribution/package_actions_test.dart`
  — séquence réelle du port et échec fermé sur digest divergent.
- `examples/playable_runtime_host/lib/src/evaluation/authoring/evaluation_distribution_package_service.dart`
  — adapter réel `map_distribution` avec artefacts en mémoire.
- `examples/playable_runtime_host/phase6_authoring_golden_slice/project.json`
  — scaffold valide et volontairement vide.
- `examples/playable_runtime_host/phase6_authoring_golden_slice/README.md` —
  contrat de fixture sans édition JSON directe.
- `examples/playable_runtime_host/test/evaluation/phase6_authoring_package_identity_test.dart`
  — authoring public, Hub installé, runtime et digest identique.
- `reports/analysis/pmcp_072_readiness_package_identity_evidence_appendix.md`
  — contenu complet des fichiers créés.

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart` — exports publics.
- `packages/map_distribution/lib/src/game_package_builder.dart` —
  `packageSha256` et `archiveBytes` calculés sur les octets finaux.
- `packages/map_distribution/test/game_package_builder_test.dart` — preuve de
  non-régression du digest ZIP historique.
- `examples/playable_runtime_host/pubspec.yaml` — dépendances de production
  explicites de l'adapter Authoring/Distribution.

## Passes séparées exigées par `codex_rule.md`

- **Audit / Architecture — PASS** : `map_authoring` conserve sa seule
  dépendance `map_core`; l'adapter concret et les chemins restent dans l'hôte.
- **Implémentation — PASS** : quatre actions publiques, receipts path-free,
  preuves citées, roadmap en lecture seule et digest issu des bytes finaux.
- **Tests — PASS pour le lot** : RED contrats/builder, puis suites complètes
  Authoring/Distribution et matrice runtime/host ciblée vertes.
- **Build / Validation — PASS pour le scope** : analyses Authoring,
  Distribution, Runtime et hôte sans issue; smokes Flutter compilants.
- **Critique finale — PASS avec blocages externes tracés** : la nouvelle Slice
  est installable, mais le parcours Selbrume large reste rouge sur ses données.

Les sub-agents n'ont pas été lancés : l'instruction développeur interdit la
délégation sans demande explicite. Les cinq passes sont locales et séparées.

## TDD, débogage et commandes exactes

RED observé :

```text
packages/map_authoring
dart test test/domains/project/readiness_actions_test.dart \
  test/domains/distribution/package_actions_test.dart
Result: compilation failed — actions, ports et receipts absents.

packages/map_distribution
dart test test/game_package_builder_test.dart
Result: compilation failed — packageSha256/archiveBytes absents.
```

Débogage systématique :

```text
flutter test test/evaluation/phase6_authoring_package_identity_test.dart
Premier résultat: identityInvalid après installation.
Cause: ProjectFormat.parse accepte actuellement v1/v2, scaffold initial v3.
Correction ciblée: package/scaffold v2, aucune validation contournée.
Second résultat: +1, all tests passed.
```

GREEN final :

```text
packages/map_authoring
dart test
Result: +292, all tests passed.
dart analyze
Result: No issues found.

packages/map_distribution
dart test
Result: +81, all tests passed.
dart analyze
Result: No issues found.

packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart --reporter compact
Result: +3, all tests passed.
flutter analyze
Result: No issues found.

examples/playable_runtime_host
flutter test test/evaluation/phase6_authoring_package_identity_test.dart \
  test/phase_a_golden_slice_launch_test.dart \
  test/mvp_release_command_matrix_test.dart \
  test/mvp_release_evidence_collector_test.dart \
  test/project_gameplay_readiness_collector_test.dart --reporter compact
Result: +12, all tests passed.
flutter analyze
Result: No issues found.
```

Une exécution Authoring parallèle au test de 12 000 entrées Distribution a
timé out le test CLI interne à 10 s (`+290 -1`). La relance Authoring seule a
terminé vert, puis la validation finale a terminé `+292`; il s'agit de
contention mesurée, pas d'un échec fonctionnel.

Gate large observée, non masquée :

```text
examples/playable_runtime_host
flutter test test/phase_7a_installed_golden_journey_test.dart --reporter compact
Result: +0 -1 après 04:29.
Cause: GamePackageExportException(gameplayReadinessFailed) sur le projet
Selbrume courant — cible d'évolution porygon-z absente, plusieurs duplications
de learnsets listées, puis « … 452 autre(s) erreur(s) ».
```

## Zones modifiées et invariants

- Un diagnostic readiness sans URI d'évidence non-file est rejeté.
- Une correction n'est qu'un `ReadinessPlannedFix`; aucun `apply` n'existe sur
  l'orchestrateur et le JSON annonce `fixesApplied: false`.
- L'adapter FG-185 conserve la distinction executed/declared; seule une preuve
  exécutée réussie devient `info`.
- La release exécute toujours build → inspect → install et ajoute ses trois
  gates techniques avant les gates de régression.
- Une inspection refusée produit un receipt bloquant sans jamais appeler
  l'installateur.
- Le receipt n'est prêt que si toutes les gates passent et si les digests
  exporté/inspecté/installé sont identiques.
- Le mapping FG publie toujours `updateApplied: false`.
- Le fixture source ne contient aucune map. La map packagée est produite par
  `LocalMapAuthoringMutationApi`, puis chargée depuis le répertoire Hub installé.
- Le nouveau digest builder ne modifie pas les octets : la valeur historique
  `17e0cedc…54c9b35` reste identique dans le test déterministe.

## Auto-critique, risques et non-objectifs

- `ProjectFormat` de l'identité de save ne reconnaît pas encore `v3`; la Slice
  utilise honnêtement `v2`. Étendre ce contrat est un lot de migration séparé.
- Le parcours Selbrume Phase 7A ne peut actuellement pas produire de package à
  cause d'un grand volume de diagnostics de données (la sortie abrégée indique
  « 452 autre(s) erreur(s) » après les exemples). Les corriger dépasse
  PMCP-072 et doit rester une gate visible pour FG-185.
- Aucun signing/notarization ni walkthrough humain n'est simulé.
- Le lockfile hôte était déjà modifié avant le lot et reste non stagé; un
  `flutter pub get` frais a néanmoins résolu les dépendances et validé le code.
- Aucun statut roadmap n'est écrit automatiquement.

## Git

État final attendu : commit isolé
`feat(authoring): prove runtime package identity`. Les changements externes
`map_editor`, le lockfile hôte et le prototype `.superpowers` restent non stagés.
