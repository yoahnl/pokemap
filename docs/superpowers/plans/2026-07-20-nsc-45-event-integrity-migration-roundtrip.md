# NSC-45 — Intégrité, migration et round-trip Events

## Objectif

Fermer la phase 4 avec une migration explicable et fail-closed, une preuve disque/runtime des quatre sources Event et un critère mesurable de retrait du chemin legacy, sans supprimer ce chemin prématurément.

## Frontières

- Conserver la lecture `legacyOnly` et `dualRead` tant que le critère de retrait n'est pas satisfait.
- Ne jamais présenter un risque de perte ou une collision comme automatiquement résolu.
- Réutiliser l'autorité de dispatch, les claims et les transactions existants ; aucun second dispatcher de test ou d'éditeur.
- Le round-trip écrit le wire canonique compatible editor puis le recharge par le loader runtime.
- Ne pas commencer la phase 5.

## Plan TDD

1. Ajouter les tests rouges d'impact migration : claims, collisions, références, risques de perte, choix et diagnostic legacy actif.
2. Ajouter un assessment de retrait legacy mesurable au planner et le projeter dans la preview Editor.
3. Étendre la sheet no-code avec ces impacts, les blockers et les critères restants.
4. Renforcer les preuves d'idempotence/recovery sur la migration/promotion Selbrume.
5. Créer le round-trip disque/runtime des sources `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived`.
6. Prouver sur le projet promu qu'un Event V2 gère l'occurrence une seule fois en `dualRead`, après reload, puis en `v2Only`, sans fallback legacy.
7. Rejouer caractérisation legacy, outbox save/load, suites ciblées, analyses et builds macOS.

## Critère de retrait legacy

Le chemin legacy ne pourra être retiré que lorsque chaque projet livré est en `v2Only`, ne contient plus aucun MapEvent/Scenario source historique ni claim de compatibilité, n'a aucun blocker de migration, et que la matrice runtime quatre-sources/no-double-dispatch reste verte. NSC-45 mesure ce critère mais ne supprime pas encore le lecteur.

## Gate

Un projet historique peut être prévisualisé et migré sans perte silencieuse, les quatre sources survivent au disque et s'exécutent via l'autorité runtime, et le dual-read ne double jamais l'exécution.
