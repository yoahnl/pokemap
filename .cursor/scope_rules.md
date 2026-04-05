# Discipline de scope

## Règle d’or

Une demande sur **Cutscene Studio** ne doit pas devenir une refonte du **shell**, de **Global Story**, ou du **layout global** sans justification **écrite** et **nécessité démontrable**.

## À éviter systématiquement

- « Tant qu’à faire » sur des fichiers voisins.
- Suppression de fichiers **hors périmètre** sans raison forte (git history, tests, features).
- Coupler une **passe locale** à un **redesign transversal** non demandé.
- Ajouter `.vscode/`, configs perso, ou artefacts temporaires dans le dépôt.

## À favoriser

- Changements **localisés** au package et au dossier concernés (`map_editor` + `cutscene_studio/` par exemple).
- **Refactor physique** du module demandé plutôt que dispersion de la dette ailleurs.
- **Tests** alignés sur le périmètre (pas toute la suite narrative « au cas où »).

## Quand élargir le scope

Uniquement si :

1. **Sans** ce changement, la feature est **cassée** ou **fausse** (ex. contrat runtime partagé).
2. La dépendance est **documentée** (commentaire + rapport si la passe est structurante).

## Git

- **Aucune** opération Git d’écriture demandée par les briefs produit (pas de commit/rebase/etc. par l’assistant sauf demande explicite humaine).

## Documentation post-passe

- Les passes structurantes produisent un **rapport** dans `packages/map_editor/reports/` (ou équivalent convenu), pas seulement du chat.
