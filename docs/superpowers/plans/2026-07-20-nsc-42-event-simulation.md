# NSC-42 — Conditions, comportement, Scene liée et simulation Event

## Audit / frontières

- Conserver le wire V1 : liste AND-only de conditions Fact/EventConsumed.
- Réutiliser `NarrativeEventDispatchAuthority`; aucun moteur de simulation parallèle.
- Afficher la Scene et ses projections en lecture seule avec le deep link existant.
- Exposer one-shot/reusable, priorité et ordre sans inventer de reset policy.
- Ne pas commencer NSC-43 ni la phase 5.

## TDD

1. Ajouter des assertions rouges pour le contrat AND-only, le support runtime réel et la trace canonique.
2. Ajouter des cas autorité/gameplay : draft, disabled, source mismatch/absente, one-shot consommé, facts/EventConsumed et concurrence priorité/ordre.
3. Ajouter un test widget rouge pour les contrôles facts/progress/source, l’appel du simulateur et l’explication de décision.
4. Implémenter le read model de simulation et faire produire les traces par l’autorité elle-même.
5. Brancher un use case read-only et une side sheet Design System dans Event Builder.

## Validation

- Tests core et gameplay ciblés.
- Tests editor simulation, fidélité, workspace et use case.
- Analyses package/ciblée, build macOS debug, `git diff --check`, audit raw colors.
- Evidence Pack puis commit NSC-42 isolé.
