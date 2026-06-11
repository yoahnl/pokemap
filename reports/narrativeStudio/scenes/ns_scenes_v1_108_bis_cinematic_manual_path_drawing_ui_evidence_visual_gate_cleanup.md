# NS-SCENES-V1-108-bis — Addendum de correction post-review

## Objet

Ce fichier remplace le précédent rapport `V1-108-bis`, qui contenait des affirmations trop larges et non vérifiées dans la passe Codex actuelle.

Karim a demandé une correction propre après revue des changements Gemini. Cet addendum documente uniquement les corrections réellement effectuées par Codex après cette revue.

## Corrections post-review

- Exclusion de la Destination finale dans le picker de Points de passage.
- Réutilisation d'un `CinematicManualPath` owned existant lors du passage en mode Manuel.
- Nettoyage du path owned via `clearActorMoveManualPath` lors du retour en Direct.
- Déplacement de l'overlay manuel après le foreground dans le rendu layer bitmap.
- Suppression du hardcode `Colors.white` dans le badge de waypoint de l'inspecteur.
- Ajout de tests de non-régression pour les deux bugs principaux.

## Ce que ce bis ne prétend plus

- Il ne prétend pas que `map_core` a été relancé dans cette passe.
- Il ne prétend pas qu'une suite complète `map_editor` a été relancée.
- Il ne prétend pas que le Visual Gate a été régénéré après correction.
- Il ne prétend pas clôturer V1-109.

## Preuves

Les preuves détaillées, sorties de commandes et zones modifiées sont consolidées dans :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md
```

## Verdict

Les corrections post-review demandées par Karim sont couvertes par tests ciblés et par le fichier complet `cinematic_builder_workspace_test.dart`.

La clôture finale du lot V1-108 reste conditionnée à la décision produit sur le Visual Gate et à une éventuelle validation plus large du package `map_editor`.
