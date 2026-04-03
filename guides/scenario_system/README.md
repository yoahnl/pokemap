# Scenario System Reference

## But du dossier
Ce dossier est la reference officielle pour la conception du systeme de scenario.
Il fixe une direction unique, stable et reutilisable:

- Global Story
- Step
- Cutscene

Ce dossier ne contient pas de code, pas de spec UI implementee, pas de detail runtime de lot.
Il contient uniquement la spec produit/conception.

## Resume du modele cible

```text
Global Story  -> progression macro du jeu
Step          -> unite metier de progression
Cutscene      -> execution concrete de mise en scene
```

Regle centrale: ne pas melanger progression metier et mise en scene.

## Navigation

- [GLOBAL_STORY_STEP_CUTSCENE_ARCHITECTURE.md](./GLOBAL_STORY_STEP_CUTSCENE_ARCHITECTURE.md)
  Vision complete, roles, hierarchie, outcomes, branches, exemple starter.
- [CUTSCENE_RUNTIME_SPEC.md](./CUTSCENE_RUNTIME_SPEC.md)
  Spec du niveau Cutscene runtime: ce que Cutscene fait, ce que Cutscene ne fait pas.
- [EDITOR_VISION.md](./EDITOR_VISION.md)
  Vision UX cible de l editeur en 3 vues separees.

## Synthese courte
La progression globale se pilote dans Global Story.
Chaque Step exprime un objectif metier clair.
Chaque Cutscene execute la scene concrete.
Le pathfinding est un detail de mise en scene: il appartient a Cutscene.
