# Pack de test Pokédex — 10 Pokémon

Ce dossier est prêt pour tester l’import JSON du Pokédex dans `map_editor`.

## Structure

- `species/` : le fichier espèce à sélectionner dans l’UI
- `learnsets/` : détecté automatiquement à partir de la ref `learnset`
- `evolutions/` : détecté automatiquement à partir de la ref `evolution`
- `media/` : détecté automatiquement à partir de la ref `media`

## Comment tester

1. Ouvre le Pokédex dans l’éditeur.
2. Clique sur `Importer des Pokémon`.
3. Choisis `Fichier JSON`.
4. Sélectionne un fichier dans `species/`, par exemple :
   - `reports/pokedex-import-pack-10/species/0001-bulbasaur.json`
5. L’aperçu doit retrouver automatiquement les fichiers compagnons dans les dossiers frères.
6. Répète l’opération pour les autres espèces.

## Espèces incluses

- #001 Bulbizarre / Bulbasaur
- #004 Salamèche / Charmander
- #007 Carapuce / Squirtle
- #025 Pikachu
- #039 Rondoudou / Jigglypuff
- #052 Miaouss / Meowth
- #063 Abra
- #066 Machoc / Machop
- #092 Fantominus / Gastly
- #133 Évoli / Eevee
