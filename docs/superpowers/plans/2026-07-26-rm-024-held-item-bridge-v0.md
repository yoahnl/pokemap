# RM-024 Held Item Bridge V0 Implementation Plan

**Goal:** Faire traverser les objets tenus joueur/dresseur jusqu’au moteur PSDK,
activer uniquement les effets réellement portés et persister explicitement le
résultat consommé/retiré/volé côté party joueur.

**Architecture:** Le seed runtime normalise l’ID catalogue vers l’ID PSDK et
refuse les effets non portés. `map_battle` hydrate déjà les effets depuis
`ItemEffectRegistry`; le lot le prouve depuis le vrai bridge. Un helper runtime
réconcilie la party PSDK finale vers les slots save avant la transaction
post-combat. L’ID save original est préservé si l’objet n’a pas changé.

**Write-back V0:**

- objet encore tenu et inchangé : préserver l’ID save original ;
- objet consommé : vider `heldItemId` ;
- objet retiré/volé : persister l’absence ;
- objet reçu/volé à l’adversaire : persister l’ID PSDK final ;
- équipe adverse : aucun write-back persistant.

**Non-goals:** UI joueur pour équiper/retirer un objet, inventaire d’objets de
dresseur, restauration automatique des objets après certains modes de combat.

### Task 1: Injection fail-closed

- [x] Tests RED player/trainer → seed/setup.
- [x] Normaliser tirets/underscores sans perdre l’ID save.
- [x] Refuser un held item sans effet PSDK `ported`.
- [x] Injecter l’objet aux actifs et réserves.

### Task 2: Effet réel

- [x] Prouver un effet porté depuis un setup issu du bridge.
- [x] Prouver l’hydratation `ItemEffectRegistry`.

### Task 3: Write-back

- [x] Ajouter la transaction PSDK held-item vers party runtime.
- [x] Prouver inchangé, consommé, retiré et reçu/volé.
- [x] Brancher avant la transaction post-battle.
- [x] Préserver l’atomicité si le post-battle échoue.

### Task 4: Editor et validation

- [x] Caractériser le picker/validation held item trainer existant.
- [x] Ajouter une preuve ciblée si nécessaire.
- [x] Suites/analyzes core, battle, runtime et editor.
- [x] Smokes Golden.
- [x] Evidence Pack `FG-072`.
- [x] Commit isolé et état Git final.
