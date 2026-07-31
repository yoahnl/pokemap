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

## Profil performance macOS — VAL-04

Ce profil reste une certification physique distincte des budgets déterministes
du test Flutter. Aucun chiffre CPU, GPU, frame timing ou mémoire ne doit être
recopié depuis une exécution debug ni estimé : les cellules restent `—` tant
qu'une session `--profile` réelle n'a pas été enregistrée.

Préparation :

1. Depuis `packages/map_editor`, lancer `flutter run -d macos --profile` et
   ouvrir Flutter DevTools Performance et Memory.
2. Ouvrir Selbrume ou une copie réaliste équivalente comportant une carte
   128 × 128 ou plus, plusieurs calques visibles, des collisions et des assets
   PokeMap multi-tuiles.
3. Noter le modèle du Mac, la version de macOS, le commit testé, le moniteur,
   sa définition, son DPR et la version Flutter. Ne pas mélanger deux machines
   ou deux configurations d'écran dans une même ligne.
4. Après deux minutes de chauffe, remettre à zéro les enregistrements DevTools.

Parcours mesuré, à exécuter une fois sur écran Retina puis une fois sur écran
non-Retina ou externe à DPR 1 :

1. Pendant dix minutes, alterner pan molette/trackpad, pan bouton milieu,
   zoom ancré sous le pointeur et survol continu des quatre quadrants.
2. Pendant dix minutes supplémentaires, alterner sélection, drag d'un objet
   défini, rotation, peinture/effacement d'une cellule, undo/redo, puis revenir
   à la navigation. Vérifier que la navigation seule ne crée aucune entrée
   d'historique et ne salit pas le document.
3. Capturer séparément les timelines UI/raster, le résumé CPU/GPU fourni par
   les outils, et les valeurs mémoire au début, au pic et après deux minutes
   d'inactivité. Joindre les captures ou leur chemin d'artefact.
4. Relever tout jank visible, image manquante, ordre de couche incorrect,
   saut mémoire non résorbé ou dégradation progressive. Ne pas convertir une
   observation subjective en mesure chiffrée.

| ID | Affichage | Statut | Date | Machine / OS / Flutter | CPU | GPU / frames UI-raster | Mémoire début / pic / fin | Artefacts / observations |
|---|---|---|---|---|---|---|---|---|
| G6-PERF-01 | Retina, DPR 2 | NOT_RUN | — | — | — | — | — | Profil physique requis |
| G6-PERF-02 | Non-Retina / externe, DPR 1 | NOT_RUN | — | — | — | — | — | Profil physique requis |

## Formats d’écran à couvrir

Répéter au minimum le parcours sur :

- 800 × 600, DPR 2, thème clair ;
- 800 × 600, DPR 2, thème sombre ;
- 1280 × 800, DPR 2, thème clair ;
- 1280 × 800, DPR 2, thème sombre.

## Règle de clôture

Gate 6 ne peut être déclaré entièrement validé que lorsque les sept lignes
`G6-PHY-01` à `G6-PHY-05` et `G6-PERF-01` à `G6-PERF-02` portent un résultat
humain daté. Les tests automatisés peuvent certifier les invariants
reproductibles, mais ne remplacent ni le ressenti d’un périphérique physique,
ni la restitution réelle de VoiceOver, ni un profil macOS en mode profile.
