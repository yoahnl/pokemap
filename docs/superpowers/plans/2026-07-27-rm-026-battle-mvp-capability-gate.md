# RM-026 Battle MVP Capability Gate Implementation Plan

**Goal:** produire une matrice battle lisible par machine qui échoue fermée si
une capacité du cutline MVP perd son contrat, son consommateur, sa surface ou
ses preuves, et déclarer explicitement les extensions hors cutline.

**Architecture:** `map_core` étend la Capability Truth Gate RM-004 avec un
catalogue battle canonique. Un outil déterministe génère JSON et Markdown puis
vérifie leur fraîcheur en mode `--check`. L’éditeur signale l’objet tenu comme
fonction avancée hors cutline MVP, sans nier le bridge livré par RM-024.

**Non-goals:** promouvoir `FG-185`, réimplémenter les lots RM-021–RM-027,
inclure objets tenus/nature-IV-EV/Struggle dans le cutline MVP, modifier la
roadmap canonique.

### Task 1: Gate core fail-closed

- [x] Définir les capacités MVP et extensions attendues.
- [x] Relier chaque capacité promue aux six références RM-004.
- [x] Rejeter matrice partielle, référence vide et dérive du set canonique.

### Task 2: Génération déterministe

- [x] Générer un JSON machine-readable et un Markdown humain.
- [x] Ajouter `--check` pour détecter tout artefact stale.
- [x] Vérifier que toutes les références de fichiers promues existent.

### Task 3: Vérité des surfaces hors cutline

- [x] Marquer held items comme extension avancée hors cutline MVP.
- [x] Déclarer nature/IV/EV et Struggle différés jusqu’à RM-028/RM-029.
- [x] Conserver `noLegalChoice` honnête tant que Struggle n’est pas livré.

### Task 4: Validation et clôture

- [x] Tests ciblés core/editor et générateur `--check`.
- [x] Analyses package-scoped et smoke battle.
- [x] Evidence Pack FG-053/180/183.
- [x] Commit isolé et état Git final.
