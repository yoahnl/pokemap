# Phase A Golden Battle Slice

Ce dossier versionne le **slice produit de référence** pour la Phase A de la
roadmap battle.

Objectif :
- fournir un vrai `project.json` lançable localement ;
- fournir une vraie save de lancement versionnée ;
- prouver qu'un combat sauvage et un combat dresseur démarrent honnêtement ;
- servir de base stable aux smoke tests et au rapport de couverture.

Contenu minimal assumé :
- 1 map : `golden_field`
- 1 zone de rencontre sauvage
- 1 NPC dresseur
- 2 espèces locales minimalement jouables
- 1 catalogue moves strictement limité aux moves utilisés par le slice
- 1 save de lancement : `runtime_host_launch_save.json`

Lancement manuel via le host :
1. `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host`
2. `/opt/homebrew/bin/flutter run -d macos`
3. Sélectionner :
   `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json`
4. Charger la map `golden_field`

Le host détecte automatiquement `runtime_host_launch_save.json` à côté du
`project.json` et démarre avec cette vraie party versionnée.
