# FG-185 — MVP Release Gate V0

> Date de vérification : 2026-07-18
> Branche : `main`
> HEAD de départ : `f93b70ad12a1930e332bef6c4eebcc10026690dc`
> Verdict global : **PARTIAL / NO-GO**
> Verdict distinct du démonstrateur Selbrume : **GO ciblé**

## 1. Résumé exécutif

Le lot livre une gate de release pure Dart et **fail-closed**. Elle ne peut
retourner `GO` que si les cinq preuves exigées par `FG-185` sont présentes une
seule fois et toutes au statut `passed`. Une preuve absente reste
`unverified`; des preuves dupliquées ou contradictoires deviennent `failed`.
Une prétendue réussite sans résumé ou provenance exploitable est également
normalisée en `failed`.

L'audit ne permet pas de déclarer PokeMap « outil fangame MVP » au sens global
de la roadmap. Le démonstrateur Selbrume est bien clôturé et jouable dans son
périmètre documenté, mais sa Golden Slice ne prouve pas encore le parcours
MVP générique complet (capture et PC avec équipe pleine, XP/level-up,
shop/heal, badge et field unlock). Le validateur narratif actuel ne couvre pas
non plus toutes ces capacités gameplay. La gate reste donc volontairement
**NO-GO** au lieu de transformer un succès ciblé en faux succès global.

## 2. Confirmation et limites du scope

Le scope retenu est le plus petit qui ferme honnêtement le dernier lot :

- agréger les cinq groupes de preuves définis par le DoD `FG-185`;
- échouer de façon conservatrice si une preuve manque ou se contredit;
- couvrir ce contrat par TDD;
- auditer les preuves fraîches disponibles;
- mettre à jour la roadmap sans déclarer `DONE` ce qui ne l'est pas;
- publier les limites et commandes de vérification.

Hors scope volontaire : implémenter dans ce même lot les mécaniques absentes,
élargir artificiellement le validateur narratif, ou modifier les critères du
DoD pour obtenir un `GO`.

Le commit intégré demandé par l'utilisateur contient également le chantier
Selbrume/Narrative Studio réalisé dans les lots précédents. Son inventaire et
ses preuves détaillées sont dans
`reports/gameplay/fg_000_selbrume_demonstrator_completion_evidence_pack.md`.
Le présent rapport ne réattribue pas ces changements antérieurs à `FG-185`.

## 3. Audit initial obligatoire

### 3.1 Sources et contrats inspectés

| Source | Utilité |
|---|---|
| `AGENTS.md` | Frontières de packages, règles Git, validation package-scoped et statut des lots. |
| `codex_rule.md` | Audit, TDD, build, sous-agents, critique et Evidence Pack. |
| `pokemap_roadmap_mecaniques_fangame.md` | DoD exact de `FG-185` et prérequis `FG-180` à `FG-184`. |
| `reports/gameplay/fg_000_selbrume_demonstrator_completion_evidence_pack.md` | Preuves fraîches et limites du GO ciblé Selbrume. |
| `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md` | Baseline initiale des capacités et lacunes. |
| `packages/map_core/lib/src/read_models/golden_slice_readiness.dart` | Read model existant, limité à une readiness legacy plus étroite. |
| `packages/map_core/lib/src/validation/beta_playability_validator.dart` | Validation beta existante, insuffisante comme gate MVP globale. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | Validateur narratif Selbrume, distinct d'un Gameplay Readiness Report exhaustif. |

### 3.2 Décision d'architecture

La gate est placée dans `map_core` car elle ne dépend ni de Flutter, ni de
Flame, ni de l'éditeur. Elle agrège des preuves produites ailleurs au lieu de
lancer des tests ou d'inspecter le filesystem. Ce découplage maintient la
frontière pure Dart et évite de faire passer l'absence de catalogue pour une
preuve valide.

`GoldenSliceReadinessReport` n'a pas été réutilisé comme vérité canonique : son
contrat historique ne représente pas les cinq critères globaux de `FG-185`.

### 3.3 Risques identifiés avant implémentation

- confondre le GO Selbrume avec un GO moteur global;
- accepter une liste de preuves incomplète par défaut;
- écraser une preuve négative avec un doublon positif;
- faire dépendre `map_core` du runner de tests ou du filesystem;
- marquer la roadmap `DONE` sans preuve des cinq critères;
- publier des artéfacts locaux de tests goldens ou des locks projet.

### 3.4 État Git initial du lot

Le workspace principal était déjà volontairement sale à cause du chantier
intégré Narrative Studio/Selbrume :

| Mesure | Valeur |
|---|---|
| Branche | `main`, upstream `origin/main` |
| HEAD | `f93b70ad12a1930e332bef6c4eebcc10026690dc` |
| Entrées porcelain observées avant `FG-185` | `386` (`177 M`, `3 D`, `206 ??`) |
| SHA-256 du snapshot porcelain | `d385088e...` (capture de travail conservée dans le journal de passe) |

Aucun reset, stash, worktree ou nettoyage destructif n'a été effectué.
L'audit de publication a classé les changements présents comme appartenant au
chantier demandé. Les diagnostics golden temporaires et locks locaux sont
désormais ignorés, sans supprimer les goldens de référence ni les captures de
preuve sous `reports/gameplay/evidence/`.

## 4. Matrice de décision `FG-185`

| Critère DoD | Preuve fraîche | Statut gate | Motif |
|---|---|---:|---|
| Golden Slice passe | E2E Selbrume Host `+66`; Evidence Pack SEL-FIN | `FAILED` global | Le parcours ciblé atteint la fin, mais ne prouve pas capture→PC équipe pleine, XP/level-up, shop/heal, badge et field unlock exigés par `FG-182`. |
| Project Gameplay Readiness Report sans error | Validator narratif Selbrume à zéro erreur ciblée | `FAILED` global | La validation ferme le graphe narratif, pas l'ensemble shop/heal/badge/field/progression de la readiness gameplay `FG-180`. |
| Tests package critiques verts | Six suites complètes et analyses fraîches | `PASSED` | Core, Gameplay, Battle, Runtime, Editor et Host sont verts. |
| Limitations post-MVP listées | Evidence Pack SEL-FIN, sections limites/risques | `PASSED` | Les limites fonctionnelles, QA et packaging sont explicites. |
| Utilisateur valide le périmètre | Autorisation d'implémenter, commit et push | `UNVERIFIED` | L'autorisation de publier n'est pas une acceptation explicite du cutoff global et de toutes ses exclusions post-MVP. |

Décision agrégée : **NO-GO**, avec deux critères `failed`, deux `passed` et un
`unverified`.

## 5. Fichiers du lot et zones modifiées

| Fichier | Zone | Raison | Impact attendu |
|---|---|---|---|
| `.gitignore` | Bruit local OS/editor | Ignorer locks PokeMap, logs Flutter et diagnostics `failures/`. | Empêche la publication d'artéfacts locaux sans masquer les goldens de référence. |
| `packages/map_core/lib/map_core.dart` | Barrel des read models | Exporter `mvp_release_gate.dart`. | Rend la gate accessible via l'API publique de `map_core`. |
| `packages/map_core/lib/src/read_models/mvp_release_gate.dart` | Nouveau read model | Définir critères, statuts, preuves et agrégation fail-closed. | Un GO exige exactement une preuve passée par critère. |
| `packages/map_core/test/mvp_release_gate_test.dart` | Nouvelle suite ciblée | Couvrir positif, absence, échec explicite et contradiction. | Protège contre les faux GO. |
| `pokemap_roadmap_mecaniques_fangame.md` | Tableau Phase 10 et section FG-185 | Refléter les preuves fraîches. | `FG-185` devient `PARTIAL`, jamais `DONE` sans DoD complet. |
| `reports/gameplay/fg_185_mvp_release_gate_v0.md` | Nouveau rapport | Conserver audit, décision, preuves, validations et limites. | Evidence Pack traçable du lot. |

### 5.1 Diff précis des fichiers modifiés

`packages/map_core/lib/map_core.dart` :

```diff
@@ read model exports
+export 'src/read_models/mvp_release_gate.dart';
```

`pokemap_roadmap_mecaniques_fangame.md` :

```diff
-| FG-185 | MVP Release Gate V0 | `⬜ TODO` | — |
+| FG-185 | MVP Release Gate V0 | `🟨 PARTIAL` | rapport FG-185 — gate fail-closed livrée, verdict global NO-GO |
+**État vérifié le 2026-07-18 : `PARTIAL / NO-GO`.**
```

`.gitignore` :

```diff
+**/.pokemap-project-*.lock
+**/flutter_*.log
+packages/map_editor/test/**/failures/
```

## 6. TDD et tests du contrat

### 6.1 Rouge attendu

Commande :

```bash
cd packages/map_core && dart test test/mvp_release_gate_test.dart
```

Résultat : exit `1`, erreurs attendues de symboles encore absents
(`MvpReleaseGateReport`, `MvpReleaseGateCriterion` et types associés). Cette
preuve confirme que les nouveaux tests échouaient avant l'implémentation.

### 6.2 Vert ciblé

```bash
cd packages/map_core && dart test test/mvp_release_gate_test.dart
```

Résultat final : exit `0`, `+6: All tests passed!`.

Cas couverts :

1. cinq preuves `passed` donnent `GO`;
2. un critère absent produit un blocker `unverified`;
3. un échec explicite reste blocker;
4. une réussite sans résumé exploitable est refusée;
5. une réussite sans source exploitable est refusée;
6. un doublon contradictoire devient `failed` au lieu de blanchir la preuve.

Après la critique indépendante, les deux nouveaux tests de provenance ont
d'abord échoué comme attendu : exit `1`, `+4 -2`. Après ajout de la
normalisation fail-closed, la suite ciblée termine à exit `0`,
`+6: All tests passed!`; l'analyse ciblée est propre.

### 6.3 Régressions Core ciblées

```bash
cd packages/map_core && dart test \
  test/mvp_release_gate_test.dart \
  test/beta_playability_validator_test.dart \
  test/golden_slice_readiness_test.dart \
  test/narrative_project_validator_test.dart
```

Résultat final : exit `0`, `+48: All tests passed!`.

## 7. Validation complète fraîche

Les commandes Flutter ont été exécutées séquentiellement pour éviter les
interférences de build.

| Package | Commande | Résultat exact utile |
|---|---|---|
| `map_core` | `dart test` | exit `0`, `+3064: All tests passed!` |
| `map_core` | `dart analyze` | exit `0`, `No issues found!` |
| `map_gameplay` | `dart test` | exit `0`, `+288: All tests passed!` |
| `map_gameplay` | `dart analyze` | exit `0`, `No issues found!` |
| `map_battle` | `dart test` | exit `0`, `+1722: All tests passed!` |
| `map_battle` | `dart analyze` | exit `0`, `No issues found!` |
| `map_runtime` | `flutter test --no-pub` | exit `0`, `+1827 ~1: All tests passed!` |
| `map_runtime` | `flutter analyze` | exit `0`, `No issues found! (ran in 3.9s)` |
| `map_editor` | `flutter test --no-pub` | exit `0`, `03:30 +3403: All tests passed!` |
| `map_editor` | `flutter analyze` | exit `0`, `No issues found! (ran in 4.6s)` |
| `playable_runtime_host` | `flutter test --no-pub` | exit `0`, `03:15 +66: All tests passed!` |
| `playable_runtime_host` | `flutter analyze` | exit `0`, `No issues found! (ran in 4.2s)` |

Vérification du contenu canonique :

```bash
cd packages/map_editor && \
  dart run tool/seed_selbrume_canonical_narrative_content.dart \
  --project-root ../../selbrume --check
```

Résultat : exit `0`,
`Selbrume canonical narrative content is up to date.` Le SHA-256 final de
`selbrume/project.json` est
`b62423b77b97f2d10bfb9ee5be8cef006607bf5a4aa60e00b341608462c48e26`.

## 8. Build obligatoire

```bash
cd packages/map_editor && \
  FLUTTER_XCODE_ARCHS=arm64 flutter build macos --release
```

Résultat : exit `0`,
`Built build/macos/Build/Products/Release/map_editor.app (37.4MB)`.

Le build validé est arm64. Le build macOS universel reste une limitation de
toolchain déjà documentée (Flutter beta/Xcode 27); aucune compatibilité
universelle n'est revendiquée par ce lot.

## 9. Verdicts des sous-agents et passes obligatoires

| Passe | Mission | Verdict |
|---|---|---:|
| Audit / Architecture | Comparer le DoD `FG-185` aux preuves réelles et proposer une API pure. | `NO-GO / PARTIAL`; gate fail-closed dans `map_core`. |
| Implémentation | TDD du read model et mise à jour du statut. | `PASS`; rouges observés puis `+6` vert final. |
| Tests Core | Suite et analyse complètes `map_core`. | `GO`; `+3064`, analyse propre. |
| Tests packages purs | `map_gameplay` et `map_battle`. | `GO`; `+288` et `+1722`, analyses propres. |
| Build / Validation | Runtime, Editor, Host, seed check et build arm64. | `GO` technique sur toutes les commandes exécutées. |
| Audit de publication | Classer le worktree partagé et exclure le bruit local. | `GO`; périmètre intégré cohérent, locks/failures ignorés. |
| Critique finale | Revue indépendante du contrat, du rapport et du scope publié. | `GO` après corrections : aucun blocker Critical ou Important restant. Métadonnées `passed` fail-closed, rapport finalisé, état Git clarifié et formulation Marionette historisée. |

## 10. État Git final avant publication

Après implémentation et avant staging :

| Mesure | Valeur |
|---|---|
| Branche / upstream | `main` / `origin/main` |
| Entrées porcelain `--untracked-files=all` | `390` (`179 M`, `3 D`, `208 ??`) au moment de la critique |
| `git diff --check` | exit `0`, aucune erreur |

Cet état inclut le chantier intégré antérieur. Le hash porcelain est
volontairement omis de cette section : modifier le rapport qui contient ce hash
le rendrait immédiatement périmé. Le statut propre après commit et push est
vérifié séparément dans le compte rendu de publication, car le hash du commit
ne peut pas être inscrit dans le commit qui le calcule lui-même.

## 11. Limites conservées et prochaines étapes proposées

Pour faire passer `FG-185` à `DONE`, sans les implémenter dans ce lot :

1. fermer `FG-180` avec un Gameplay Readiness Report couvrant aussi capture,
   PC, progression, shop/heal, badge et field unlock;
2. produire `FG-182` avec un parcours global incluant chacun de ces systèmes;
3. fermer la matrice de régression `FG-183` et le dashboard `FG-184` si retenu;
4. faire accepter explicitement par l'utilisateur le cutoff MVP et les
   limitations post-MVP;
5. réévaluer les cinq preuves dans `MvpReleaseGateReport`.

## 12. Auto-critique et risques restants

- La gate agrège des preuves mais ne vérifie pas leur fraîcheur elle-même. Le
  champ `source` non vide reste une convention documentaire; une couche CI
  pourra plus tard signer ou dater ces preuves.
- L'agrégateur n'est pas encore branché à un runner CI ou à une route produit.
  Il fournit le contrat fail-closed, tandis que la matrice de décision de ce
  rapport reste l'évaluation manuelle des preuves fraîches. C'est pourquoi le
  lot demeure `PARTIAL`.
- Le contrat rejette tous les doublons, même deux preuves concordantes. Cette
  sévérité est volontaire pour V0 et évite une priorité implicite entre
  sources, mais un modèle de provenance explicite pourra être nécessaire.
- Le GO Selbrume repose sur un parcours E2E ciblé et non sur plusieurs heures
  de playtest humain mesuré.
- Le solveur de reachability narratif reste borné à 4096 états et échoue de
  façon conservatrice au-delà.
- Le build universel macOS n'est pas prouvé dans la toolchain actuelle.
- Le worktree publié est volumineux parce que l'utilisateur a demandé un
  commit intégré de tous les lots précédents; cela augmente le coût d'une
  future revue par commit malgré l'audit de scope.

Le principal garde-fou du lot est donc l'honnêteté : l'implémentation de la
gate est terminée et testée, mais son verdict global reste **NO-GO** tant que
les preuves produit manquantes ne sont pas livrées.

## Annexe A — contenu complet du fichier créé
`packages/map_core/lib/src/read_models/mvp_release_gate.dart`

```dart
/// The five independent evidence groups required by FG-185.
enum MvpReleaseGateCriterion {
  goldenSlice,
  projectGameplayReadiness,
  criticalPackageTests,
  postMvpLimitationsDocumented,
  userScopeApproved,
}

/// State of one externally produced release-gate proof.
enum MvpReleaseGateEvidenceStatus {
  passed,
  failed,
  unverified,
}

/// Evidence supplied to the FG-185 release-gate aggregator.
///
/// This object records an external proof. It does not run tests or validators
/// itself, so callers must keep [source] and [summary] tied to fresh evidence.
final class MvpReleaseGateEvidence {
  const MvpReleaseGateEvidence({
    required this.criterion,
    required this.status,
    required this.summary,
    this.source,
  });

  final MvpReleaseGateCriterion criterion;
  final MvpReleaseGateEvidenceStatus status;
  final String summary;
  final String? source;
}

/// Fail-closed decision for `FG-185 — MVP Release Gate V0`.
///
/// Every criterion must have exactly one passing proof. Missing or duplicate
/// evidence remains a blocker. Passing claims must also carry a non-empty
/// summary and source so a status flag alone cannot accidentally promote a
/// partial demonstrator to a global MVP release.
final class MvpReleaseGateReport {
  MvpReleaseGateReport._(
      Map<MvpReleaseGateCriterion, MvpReleaseGateEvidence> evidence)
      : evidenceByCriterion = Map.unmodifiable(evidence);

  factory MvpReleaseGateReport.evaluate(
    Iterable<MvpReleaseGateEvidence> evidence,
  ) {
    final suppliedByCriterion =
        <MvpReleaseGateCriterion, List<MvpReleaseGateEvidence>>{};
    for (final item in evidence) {
      suppliedByCriterion.putIfAbsent(item.criterion, () => []).add(item);
    }

    final normalized = <MvpReleaseGateCriterion, MvpReleaseGateEvidence>{};
    for (final criterion in MvpReleaseGateCriterion.values) {
      final supplied = suppliedByCriterion[criterion] ?? const [];
      normalized[criterion] = switch (supplied.length) {
        0 => MvpReleaseGateEvidence(
            criterion: criterion,
            status: MvpReleaseGateEvidenceStatus.unverified,
            summary: 'Aucune preuve fournie pour ${criterion.name}.',
          ),
        1 => _normalizeSingleEvidence(supplied.single),
        _ => MvpReleaseGateEvidence(
            criterion: criterion,
            status: MvpReleaseGateEvidenceStatus.failed,
            summary:
                'Preuves dupliquees ou contradictoires pour ${criterion.name}.',
          ),
      };
    }

    return MvpReleaseGateReport._(normalized);
  }

  final Map<MvpReleaseGateCriterion, MvpReleaseGateEvidence>
      evidenceByCriterion;

  bool get isGo => evidenceByCriterion.values.every(
        (item) => item.status == MvpReleaseGateEvidenceStatus.passed,
      );

  List<MvpReleaseGateEvidence> get blockers => List.unmodifiable(
        evidenceByCriterion.values.where(
          (item) => item.status != MvpReleaseGateEvidenceStatus.passed,
        ),
      );
}

MvpReleaseGateEvidence _normalizeSingleEvidence(
  MvpReleaseGateEvidence evidence,
) {
  // Failed and unverified proofs are already conservative. Metadata is
  // mandatory only for a claim that would otherwise contribute to a GO.
  if (evidence.status != MvpReleaseGateEvidenceStatus.passed) {
    return evidence;
  }

  if (evidence.summary.trim().isEmpty) {
    return MvpReleaseGateEvidence(
      criterion: evidence.criterion,
      status: MvpReleaseGateEvidenceStatus.failed,
      summary: 'La preuve passed ne fournit aucun resume exploitable.',
      source: evidence.source,
    );
  }

  if (evidence.source?.trim().isEmpty ?? true) {
    return MvpReleaseGateEvidence(
      criterion: evidence.criterion,
      status: MvpReleaseGateEvidenceStatus.failed,
      summary: 'La preuve passed ne fournit aucune source exploitable.',
    );
  }

  return evidence;
}
```

## Annexe B — contenu complet du fichier créé
`packages/map_core/test/mvp_release_gate_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpReleaseGateReport', () {
    test('returns GO only when every required criterion has passed evidence',
        () {
      final report = MvpReleaseGateReport.evaluate(_passedEvidence());

      expect(report.isGo, isTrue);
      expect(report.blockers, isEmpty);
      expect(
        report.evidenceByCriterion.keys,
        containsAll(MvpReleaseGateCriterion.values),
      );
    });

    test('fails closed when a required criterion has no evidence', () {
      final evidence = _passedEvidence()
          .where(
            (item) =>
                item.criterion !=
                MvpReleaseGateCriterion.projectGameplayReadiness,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(1));
      expect(
        report.blockers.single.criterion,
        MvpReleaseGateCriterion.projectGameplayReadiness,
      );
      expect(
        report.blockers.single.status,
        MvpReleaseGateEvidenceStatus.unverified,
      );
    });

    test('keeps an explicit failed criterion as a release blocker', () {
      final evidence = _passedEvidence()
          .map(
            (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.goldenSlice,
                    status: MvpReleaseGateEvidenceStatus.failed,
                    summary: 'Le parcours MVP global est incomplet.',
                    source: 'reports/gameplay/fg_185_mvp_release_gate_v0.md',
                  )
                : item,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(1));
      expect(
        report.blockers.single.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects passed evidence without a usable summary', () {
      final evidence = _passedEvidence()
          .map(
            (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.goldenSlice,
                    status: MvpReleaseGateEvidenceStatus.passed,
                    summary: '   ',
                    source: 'fresh-evidence',
                  )
                : item,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects passed evidence without a usable source', () {
      final evidence = _passedEvidence()
          .map(
            (item) =>
                item.criterion == MvpReleaseGateCriterion.criticalPackageTests
                    ? const MvpReleaseGateEvidence(
                        criterion: MvpReleaseGateCriterion.criticalPackageTests,
                        status: MvpReleaseGateEvidenceStatus.passed,
                        summary: 'Les suites critiques sont vertes.',
                      )
                    : item,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.criticalPackageTests]
            ?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects contradictory duplicate evidence instead of laundering it',
        () {
      final evidence = <MvpReleaseGateEvidence>[
        ..._passedEvidence(),
        const MvpReleaseGateEvidence(
          criterion: MvpReleaseGateCriterion.goldenSlice,
          status: MvpReleaseGateEvidenceStatus.failed,
          summary: 'Une seconde source contredit le GO.',
        ),
      ];

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
      expect(
        report
            .evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.summary,
        contains('contradictoires'),
      );
    });
  });
}

List<MvpReleaseGateEvidence> _passedEvidence() => MvpReleaseGateCriterion.values
    .map(
      (criterion) => MvpReleaseGateEvidence(
        criterion: criterion,
        status: MvpReleaseGateEvidenceStatus.passed,
        summary: '${criterion.name} est prouve.',
        source: 'fresh-evidence',
      ),
    )
    .toList(growable: false);
```
