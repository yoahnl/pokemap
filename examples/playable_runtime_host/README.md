# playable_runtime_host

Host Flutter desktop minimal pour charger un `project.json` PokeMap et lancer
le runtime Flame localement.

## PokeMap Eval headless

Le host fournit aussi un pilote headless pour exécuter des scénarios Selbrume,
inspecter des checkpoints et produire les preuves de certification du MVP.
Les commandes, politiques, codes de sortie et artefacts sont documentés dans
[`evaluation/README.md`](evaluation/README.md).

Exemple :

```bash
dart run tool/pokemap_eval.dart run selbrume.mvp --policy certify
```

## Package macOS autonome Selbrume

Le host résout en priorité le projet livré dans
`PokeMap Selbrume.app/Contents/Resources/selbrume/project.json`. Le fallback
vers `../../selbrume` existe uniquement pour `flutter run`; le package publié
ne dépend donc ni du checkout ni d'un chemin absolu propre à la machine.

Depuis `examples/playable_runtime_host` :

```bash
dart run tool/package_selbrume_macos.dart \
  --project ../../selbrume \
  --release
```

La commande :

1. construit le host en release ;
2. copie le tree Selbrume dans les ressources de l'application ;
3. vérifie l'inventaire, New Game et le round-trip save/reload ;
4. refait une signature ad hoc puis lance
   `codesign --verify --deep --strict` ;
5. produit sous `build/mvp-release/` l'archive
   `selbrume-macos.zip`, son fichier `.sha256` et son manifest JSON.

Le package MVP cible Apple Silicon (`arm64`). Le binaire universel, la
signature Developer ID et la notarisation sont volontairement post-MVP.

## Phase A golden slice

Le repo versionne maintenant un slice produit de référence ici :

- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json`

Ce slice contient :
- une map `golden_field`
- une zone de rencontre sauvage
- un dresseur
- un petit catalogue Pokémon minimal mais réellement battleable
- une vraie save de lancement `runtime_host_launch_save.json`

### Lancer le golden slice

1. `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host`
2. `/opt/homebrew/bin/flutter run -d macos`
3. Sélectionner le dossier `golden_battle_slice`
4. Charger la map `golden_field`

Le host charge automatiquement `runtime_host_launch_save.json` s’il existe à
côté du `project.json`. Sinon, il retombe sur le seed de démo historique.

## iOS

Sur iOS, le bouton `Parcourir…` ouvre désormais le picker Fichiers pour choisir
un dossier projet complet. Le host importe ensuite ce dossier dans son espace
Documents interne pour garder `project.json`, `maps/` et les assets ensemble.

## Validation locale utile

- smoke test runtime :
  `cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/phase_a_golden_battle_slice_smoke_test.dart`
- tests host liés au lancement :
  `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/project_loader_page_test.dart test/runtime_launch_save_test.dart test/runtime_demo_party_seed_test.dart test/phase_a_golden_slice_launch_test.dart`
