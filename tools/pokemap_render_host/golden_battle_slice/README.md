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

Pour jouer manuellement, ouvrir `project.json` dans Avelune Studio et lancer
le playtest depuis la carte `golden_field`. La sauvegarde adjacente
`runtime_host_launch_save.json` sert au smoke test automatisé du lancement.

Depuis la racine du dépôt :

```bash
cd tools/pokemap_render_host
flutter test test/phase_a_golden_slice_launch_test.dart
```
