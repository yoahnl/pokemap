# Gate 6 — Protocole manuel périphériques et VoiceOver

Ce protocole complète les tests Flutter automatisés. Il ne constitue pas une preuve d’exécution : chaque ligne reste `NOT_RUN` tant qu’une personne n’a pas réalisé le parcours sur le matériel indiqué et renseigné la date, la machine et le résultat.

## Projet et parcours de référence

- Projet : Selbrume, ou un projet réaliste équivalent comportant au moins un calque de tuiles, un calque de collisions et un calque d’objets.
- Parcours : ouvrir une carte, changer de calque, peindre une cellule, l’effacer, placer un asset PokeMap défini dans un tileset, le sélectionner, le déplacer d’une cellule, le tourner de 90°, annuler, rétablir, enregistrer, fermer puis rouvrir.
- Critère ergonomique : les outils principaux restent accessibles sans défilement ; chaque changement de contexte demande au plus un défilement local dans l’inspecteur.
- Critère de sécurité : un geste de navigation ne doit jamais peindre, effacer, déplacer ou placer un contenu.

## Matrice d’exécution physique

| ID | Matériel / aide | Scénario spécifique | Statut | Date | Machine / OS | Observations |
|---|---|---|---|---|---|---|
| G6-PHY-01 | Magic Mouse | Défilement vertical/horizontal, zoom avec modificateur, clic secondaire et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-02 | Trackpad | Pan à deux doigts, pincement, clic secondaire et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-03 | Souris 3 boutons | Molette, bouton milieu pour pan, clic droit et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-04 | Clavier seul | Tab, flèches du canvas, Entrée/Espace, Shift+flèches, R, Menu/Shift+F10, Échap et parcours complet | NOT_RUN | — | — | À exécuter physiquement |
| G6-PHY-05 | VoiceOver macOS | Lecture de l’outil/calque actifs, curseur cellule, presets lumière, menu contextuel modal, erreurs et parcours complet | NOT_RUN | — | — | À exécuter physiquement |

## Formats d’écran à couvrir

Répéter au minimum le parcours sur :

- 800 × 600, DPR 2, thème clair ;
- 800 × 600, DPR 2, thème sombre ;
- 1280 × 800, DPR 2, thème clair ;
- 1280 × 800, DPR 2, thème sombre.

## Règle de clôture

Gate 6 ne peut être déclaré entièrement validé que lorsque les cinq lignes `G6-PHY-*` portent un résultat humain daté. Les tests automatisés peuvent certifier les invariants reproductibles, mais ne remplacent ni le ressenti d’un périphérique physique ni la restitution réelle de VoiceOver.
