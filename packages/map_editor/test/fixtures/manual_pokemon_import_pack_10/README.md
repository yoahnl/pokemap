# Pack de test Pokédex — 10 Pokémon

Ce dossier contient un pack de 10 Pokémon prêt pour tester l'import manuel du Pokédex dans `packages/map_editor`.

## Structure

- `species/` : fichier à sélectionner dans le file picker
- `learnsets/` : companions auto-détectés
- `evolutions/` : companions auto-détectés
- `media/` : companions auto-détectés

## Comment tester

1. Ouvrir le Pokédex dans l'éditeur.
2. Cliquer sur `Importer des Pokémon`.
3. Choisir `Fichier JSON`.
4. Sélectionner n'importe quel fichier dans `species/`, par exemple :
   - `species/0001-bulbasaur.json`
   - `species/0025-pikachu.json`
   - `species/0447-riolu.json`
5. Le preview doit retrouver automatiquement les fichiers frères dans `learnsets/`, `evolutions/` et `media/`.
6. Refaire l'opération pour autant d'espèces que tu veux importer dans le projet de test.

## Pokémon inclus

- #001 Bulbasaur / Bulbizarre
- #004 Charmander / Salameche
- #007 Squirtle / Carapuce
- #025 Pikachu
- #039 Jigglypuff / Rondoudou
- #052 Meowth / Miaouss
- #092 Gastly / Fantominus
- #133 Eevee / Evoli
- #147 Dratini / Minidraco
- #447 Riolu

## Notes

- Le pack est conçu pour tester l'UI et le pipeline d'import actuel, pas pour servir de dex canonique complet.
- Les chemins média pointent vers des refs plausibles, mais l'existence disque réelle des assets n'est pas requise pour l'import.
- Quelques espèces sont marquées désactivées dans `classification.isEnabledInProject` pour permettre de tester les filtres de statut.
