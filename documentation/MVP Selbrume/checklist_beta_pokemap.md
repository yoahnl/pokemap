# Checklist bêta PokeMap

> Hypothèse de départ : le Narrative Studio est considéré comme terminé ou suffisamment stabilisé.  
> Objectif bêta : pouvoir créer/ouvrir un projet, lancer le runtime, jouer, progresser, sauvegarder, recharger, et vérifier que l’état reste cohérent.

## Légende

- ✅ Fait
- 🟡 Partiel / base existante
- ⬜ À faire
- 🔥 Bloquant bêta

---

## 1. Runtime / lancement du jeu

- 🟡 `playable_runtime_host` / runtime Flame existe
- 🟡 Battle handoff/runtime déjà présent en partie
- ⬜ 🔥 Charger un vrai projet disque créé par l’éditeur
- ⬜ 🔥 Lancer une New Game depuis ce projet
- ⬜ 🔥 Faire un smoke test complet : éditeur → disque → runtime → save/load

## 2. New Game / état initial

- 🟡 `GameState` existe avec plusieurs briques déjà prévues
- ⬜ 🔥 Écran ou flow New Game minimal
- ⬜ 🔥 Map de départ + spawn validés
- ⬜ 🔥 Donner un Pokémon initial / starter
- ⬜ Initialiser bag, argent, flags, steps, metadata

## 3. Exploration

- 🟡 Déplacement / collisions / warps existent déjà en grande partie
- 🟡 Interactions runtime probablement présentes en partie
- ⬜ 🔥 Interaction PNJ propre de bout en bout
- ⬜ Interaction objet / pickup
- ⬜ Transitions de map stables dans le projet bêta
- ⬜ Test Selbrume exploration complet

## 4. Narrative / events / scenes

- ✅ Modèle produit Narrative Studio bien cadré
- 🟡 Beaucoup de briques existent, mais tous les ponts runtime ne sont pas fermés
- ⬜ 🔥 Event → Scene → Dialogue → Outcome → Fact/Step
- ⬜ 🔥 World rules visibles en runtime
- ⬜ 🔥 Dialogue conditionnel après progression
- ⬜ 🔥 Persistance des events/scènes déjà consommés

## 5. Party / équipe

- 🟡 Party dans `GameState`
- ⬜ 🔥 Menu équipe runtime minimal
- ⬜ Afficher PV / niveau / statut
- ⬜ Gérer KO
- ⬜ Mettre à jour l’équipe après combat
- ⬜ Persister l’équipe au save/load

## 6. Bag / inventaire

- 🟡 Bag dans `GameState`
- ⬜ 🔥 Bag runtime minimal
- ⬜ Utiliser une potion
- ⬜ Utiliser une Poké Ball en combat
- ⬜ Ramasser un item sur la map
- ⬜ Persister les items au save/load

## 7. Soin équipe / Centre Pokémon

- ⬜ 🔥 `healParty`
- ⬜ Restaurer PV
- ⬜ Restaurer PP si gérés
- ⬜ Retirer les statuts
- ⬜ Réanimer les KO
- ⬜ Appel depuis dialogue infirmière / lit / point de soin
- ⬜ Feedback simple : “Votre équipe est soignée.”
- ⬜ Persistance après save/load

## 8. Rencontres sauvages

- 🟡 Rencontres wild walk/surf partielles d’après l’audit
- ⬜ 🔥 Zone de rencontre authorable
- ⬜ Table de rencontres utilisable en runtime
- ⬜ Déclenchement en hautes herbes / zone
- ⬜ Retour runtime propre après combat
- ⬜ Validation des espèces/niveaux/moves

## 9. Combat sauvage

- 🟡 Moteur battle déjà sérieux
- 🟡 Wild battle existe partiellement
- ⬜ 🔥 Combat sauvage branché dans le runtime final
- ⬜ Résultat combat exploitable
- ⬜ PV/statuts/PP écrits dans `GameState`
- ⬜ Fuite minimale ou comportement défini

## 10. Capture

- 🟡 Capture minimale déjà évoquée comme existante en partie
- ⬜ 🔥 Capture depuis combat sauvage dans le flow bêta
- ⬜ Ajouter à l’équipe si place disponible
- ⬜ Gérer le cas équipe pleine
- ⬜ PC/box minimal ou fallback propre
- ⬜ Persister le Pokémon capturé

## 11. Combat dresseur

- 🟡 Battle from Scene / trainer battle déjà en partie acquis
- 🟡 Pipeline `startTrainerBattle` déjà décrit comme présent dans le Golden Slice
- ⬜ 🔥 Créer un dresseur sans code
- ⬜ Placer le dresseur sur une map
- ⬜ Déclencher le combat
- ⬜ Gérer victoire/défaite
- ⬜ Marquer le dresseur comme battu
- ⬜ Dialogue différent après combat

## 12. Récompenses / progression

- ⬜ 🔥 Récompense après combat
- ⬜ Argent ou item minimal
- ⬜ XP minimale
- ⬜ Level-up minimal
- ⬜ Persistance niveau / XP
- ⬜ Feedback simple après combat

## 13. Audio

- ⬜ 🔥 Catalogue audio minimal
- ⬜ Musique de map
- ⬜ Musique de combat
- ⬜ SFX menu / validation
- ⬜ SFX dialogue / interaction
- ⬜ SFX combat basique
- ⬜ SFX capture
- ⬜ SFX soin équipe
- ⬜ Volume musique / effets / mute
- ⬜ Validator fichiers audio manquants

## 14. Save / Load

- 🟡 Save/load existe partiellement
- ⬜ 🔥 Sauvegarder position + map courante
- ⬜ Sauvegarder party
- ⬜ Sauvegarder bag
- ⬜ Sauvegarder story flags / facts / steps
- ⬜ Sauvegarder trainers battus
- ⬜ Sauvegarder cutscenes/events consommés
- ⬜ Recharger et retrouver un état cohérent

## 15. Validator de jouabilité

- 🟡 Diagnostics techniques déjà nombreux côté projet
- ⬜ 🔥 Validator “projet jouable”
- ⬜ Vérifier start map / spawn
- ⬜ Vérifier warps
- ⬜ Vérifier PNJ référencés
- ⬜ Vérifier dialogues/scènes/outcomes
- ⬜ Vérifier battles/trainers
- ⬜ Vérifier species/moves/items
- ⬜ Vérifier assets manquants
- ⬜ Vérifier audio manquant
- ⬜ Vérifier save/load compatible

## 16. Golden Slice Selbrume

- ✅ Concept Selbrume défini
- ✅ Slice cible défini
- 🟡 Roadmap Narrative / Golden Slice cadrée
- ⬜ 🔥 Projet exemple jouable 10–20 minutes
- ⬜ Bourg / Port jouables
- ⬜ Maël fonctionnel
- ⬜ Lysa fonctionnelle
- ⬜ Combat rival
- ⬜ Victory/defeat branch
- ⬜ Fact + step + world rule
- ⬜ Soin équipe quelque part
- ⬜ Audio minimal
- ⬜ Save/reload final
- ⬜ Validator vert

---

# Version ultra courte

```text
🟡 Runtime existe, mais end-to-end disque → jeu pas prouvé
⬜ New Game
⬜ Starter
🟡 Exploration existe en partie
⬜ Party menu
⬜ Bag runtime
⬜ Soin équipe / Centre Pokémon
🟡 Battles existent en partie
⬜ Rencontres sauvages finalisées
⬜ Capture finalisée
⬜ Récompenses / XP minimale
⬜ Audio minimal
🟡 Save/load partiel
⬜ Validator de jouabilité
⬜ Golden Slice Selbrume jouable de bout en bout
```

---

# Définition simple de “bêta fonctionnelle”

PokeMap peut être considéré comme bêta lorsque l’on peut faire, sans tricher, le parcours suivant :

1. Ouvrir PokeMap.
2. Créer ou ouvrir un projet exemple.
3. Vérifier le projet avec le Validator.
4. Lancer le runtime.
5. Commencer une nouvelle partie.
6. Recevoir ou avoir un Pokémon initial.
7. Explorer une map.
8. Parler à un PNJ.
9. Déclencher une scène.
10. Faire un choix de dialogue.
11. Lancer un combat.
12. Gagner ou perdre.
13. Obtenir une conséquence persistante.
14. Ramasser / utiliser un objet simple.
15. Faire une rencontre sauvage.
16. Capturer un Pokémon.
17. Soigner l’équipe.
18. Entendre musique et sons minimaux.
19. Sauvegarder.
20. Fermer.
21. Recharger.
22. Constater que l’état est cohérent.

---

# Verdict

PokeMap a déjà beaucoup de fondations.  
Mais pour une bêta, il manque encore le **jeu complet minimal** :

```text
runtime disque
new game
starter
exploration
party
bag
soin équipe
rencontres
combat
capture
récompenses
XP minimale
audio
save/load
validator
golden slice Selbrume
```
