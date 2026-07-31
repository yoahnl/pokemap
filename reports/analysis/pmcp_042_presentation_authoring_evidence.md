# PMCP-042 — Evidence Pack authoring de présentation

Date : 2026-07-31
Lot : `PMCP-042 — Présentation, médias et previews`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot transforme le profil de présentation canonique de `map_core` en une
surface d’authoring transactionnelle : mise à jour, suppression, validation
des images/vidéos/audio/polices/licences, previews liées à une révision et
jobs média asynchrones idempotents.

Le validateur, l’adaptateur destiné au flux éditeur et le service de preview
partagent le même gate. Les références sont résolues par chemin logique dans
le catalogue content-addressed PMCP-040 ; aucun chemin machine ni droit
d’exécution de processus ne traverse le contrat public.

## Audit initial et continuité

État Git initial : arbre propre à
`3d13b953 feat(authoring): add visual library authoring`.

L’audit initial a établi que les modèles, diagnostics de contraste, limites
vidéo, glyphes et licences existaient déjà dans `map_core`, et que l’éditeur
possédait un preflight local. La lacune n’était donc pas le modèle mais la
façade sécurisée : actions Phase 3, cohérence avec l’asset store, jobs longs
abstraits et previews stale-safe. Le lot réutilise les validateurs existants
et ne déplace aucune logique Flutter dans `map_authoring`.

## Passes et verdicts

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture — agent assets | Conforme | Réutilisation du profil canonique et ajout d’un port média au lieu d’un subprocess interne |
| Implémentation | Conforme | Deux mutations, gate unifié, adapter, preview et port de jobs |
| Tests | Conforme | RED initial sur contrats absents, puis 5 tests ciblés et 18 tests assets verts |
| Build / Validation | Conforme | 248 tests, analyse, format strict et smoke CLI verts |
| Critique finale | Conforme avec limites | Codecs réellement transcodés par un adapter hôte futur, pas par le noyau pur |

## Contrats et zones modifiées

- `presentation_actions.dart` : gate profil + catalogue, diagnostics
  déterministes, adapter de projection éditeur, preview content-addressed et
  mutations `presentation.update/delete`.
- `media_processing_port.dart` : requête path-free, états de job, résultat,
  idempotence, attente asynchrone et adapter mémoire testable.
- `map_mutation_dispatcher.dart` : enregistrement des deux mutations.
- `map_authoring.dart` : exports publics des actions et du port.
- `presentation_authoring_test.dart` : MIME/missing, parité adapter, stale
  preview, async/idempotence et visibilité registry.

## Inventaire complet

Créés :

- `packages/map_authoring/lib/src/domains/assets/presentation_actions.dart`
- `packages/map_authoring/lib/src/ports/media_processing_port.dart`
- `packages/map_authoring/test/domains/assets/presentation_authoring_test.dart`
- `reports/analysis/pmcp_042_presentation_authoring_evidence.md`
- `reports/analysis/pmcp_042_presentation_authoring_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`

Le contenu intégral des fichiers texte créés, hors rapports auto-référents,
est fourni dans l’annexe. Les zones modifiées correspondent au diff Git du
commit dédié.

## Tests et résultats exacts

TDD rouge initial :

```text
dart test test/domains/assets/presentation_authoring_test.dart
exit 1 — PresentationAuthoringGate, ProjectPresentationEditorAdapter,
PresentationPreviewService, MediaProcessingPort et mutations absents.
```

Tests après intégration :

```text
dart test test/domains/assets/presentation_authoring_test.dart
00:00 +5: All tests passed!

dart test test/domains/assets
00:00 +18: All tests passed!

dart test
00:15 +248: All tests passed!
```

Analyse, format et smoke :

```text
dart analyze
Analyzing map_authoring...
No issues found!

dart format --output=none --set-exit-if-changed lib test bin
Formatted 139 files (0 changed) in 0.22 seconds.

dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
exit 0, stdout/stderr vides.
```

## Preuves de fin de lot

- Média : un asset image utilisé comme musique de titre reçoit
  `presentationAssetMediaTypeMismatch` ; une licence absente reçoit
  `presentationAssetMissing` avec son chemin de profil précis.
- Adapter : le flux éditeur projeté et le gate de mutation renvoient exactement
  les mêmes diagnostics et le même `ProjectPresentationProfile` canonique.
- Preview : l’identité dépend du contenu + révision, ne contient que des
  handles d’assets et refuse une consommation sur une autre révision.
- Job : `submit` rend un état queued, une soumission idempotente retrouve le
  même job, puis `wait` observe le résultat validé après résolution asynchrone.
- Mutation : update/delete rejoignent le même pipeline plan/CAS/permission/
  audit/transaction/history/undo que les lots précédents.

## Limites, risques et non-objectifs

- `InMemoryMediaProcessingPort` orchestre et valide un processor injecté ; il
  ne prétend pas encoder lui-même H.264, AAC ou les polices. Un host pourra
  fournir FFmpeg ou un service isolé derrière le même port.
- L’adaptateur caractérise la projection attendue par l’éditeur, mais la
  migration des controllers Flutter existants reste volontairement PMCP-080.
- Les avertissements non bloquants du validateur canonique, notamment les
  captions recommandées, restent visibles sans interdire la publication.
- Aucun statut `FG-*` ou roadmap n’est modifié.

## Auto-critique finale

Le contrôle MIME s’appuie sur le type sniffé et persisté par PMCP-040 ; il ne
réanalyse pas les octets à chaque preview. C’est intentionnel pour préserver la
frontière pure, mais implique que les adapters d’import restent l’autorité de
sniffing. La parité avec le preflight Flutter est contractuelle au niveau du
profil et des diagnostics essentiels ; le test d’intégration direct avec
`map_editor` sera ajouté lors de sa migration, pour éviter une dépendance
inverse du noyau vers l’UI.

État Git final attendu après commit : arbre propre sur
`feat(authoring): add presentation authoring`.
