# NSC-43 — Expressions de conditions et politiques de réarmement Event

## Objectif

Remplacer la limite historique AND-only par un contrat borné `all/any/not/leaf`, puis partager trois politiques de réarmement déterministes entre le wire, l’authoring, la simulation, le runtime et la sauvegarde.

## Frontières

- Conserver uniquement les feuilles booléennes Fact et Event consommé ; les valeurs typées restent NSC-51.
- Conserver la lecture des anciens tableaux `conditions` comme `all(leaves)`.
- Autoriser le réarmement uniquement pour les Events one-shot.
- Compter comme réentrée uniquement une transition warp/connection vers une map déjà visitée après observation d’une autre map.
- Ne pas commencer NSC-44 ou NSC-45 dans ce commit.

## Plan d’implémentation

1. Ajouter le schema d’expression borné et les reset policies qualifiées au modèle Event.
2. Préserver expression/reset dans chaque opération de copie, publication, source et Scene.
3. Évaluer l’expression dans l’autorité de dispatch et appliquer le reset dans la transaction avant planification.
4. Persister historique de map et tokens d’idempotence dans `NarrativeEventProgress`.
5. Câbler map activation et outcome outbox réels sans double dispatch.
6. Indexer la dépendance du résultat qualifié et rejeter les combinaisons impossibles.
7. Exposer Toutes/Au moins une/NON et Réarmement dans les side sheets et l’inspecteur.
8. Prouver migration AND, OR/NOT, contraintes, vraie réentrée, restore, duplication, collision qualifiée et save/load.

## Gate

L’UI, l’autorité de dispatch, le progress save et le runtime consomment les mêmes objets `NarrativeEventConditionExpression` et `NarrativeEventResetPolicy`, avec tests ciblés verts et build macOS réussi.
