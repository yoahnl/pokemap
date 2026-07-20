# NSC-53 — Simulateur d’état du monde

## Objectif

Prévisualiser, depuis un snapshot isolé et sérialisable, les effets combinés des Facts, Steps et World Rules sans lancer le runtime ni modifier le projet.

## Frontières

- La simulation pure et ses explications appartiennent à `map_core`.
- Le panneau editor ne conserve qu’un snapshot local éphémère.
- Les Events legacy et V2 restent des namespaces distincts.
- Les presets d’issue enregistrent une hypothèse reproductible ; ils ne prétendent pas produire un effet World Rule lorsqu’aucune source de règle ne consomme les outcomes.
- La parité porte sur la projection effectivement supportée par le hook runtime.

## Plan TDD

1. Prouver le round-trip et l’immutabilité du snapshot.
2. Tester règles applicables, ordre, gagnants et contributeurs.
3. Tester Fact absent, priorité concurrente et cible supprimée.
4. Comparer le rapport pur au hook runtime sur la même fixture.
5. Ajouter le panneau no-code Facts/Steps/issues et ses états expliqués.
6. Intégrer la troisième colonne au workspace World Rules.
7. Régénérer, inspecter puis verrouiller le golden et le gate multi-package.

## Gate

Le même snapshot produit un résultat explicable dans `map_core`, le panneau editor et la projection runtime, sans aucune écriture sur le projet.
