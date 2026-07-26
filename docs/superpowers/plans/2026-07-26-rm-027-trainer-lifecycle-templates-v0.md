# RM-027 Trainer Lifecycle & Templates V0 Implementation Plan

**Goal:** fermer FG-140, FG-141, FG-144 et FG-145 avec une politique de
défaite persistante, des dialogues de cycle de vie réellement consommés et des
presets trainer/gym/rival authorables sans JSON.

**Architecture:** `map_core` porte les métadonnées sérialisées et leurs
invariants ; `map_editor` expose templates, rematch et pickers de dialogues ;
`map_runtime` résout un plan d’interaction pur puis l’applique dans
`PlayableMapGame` avant et après combat. Le flag canonique
`trainer_defeated:<id>` reste la vérité persistante.

**Non-goals:** IA de rematch évolutive, scaling d’équipe, calendrier de rematch,
warp/cutscene automatique hors scénario, génération automatique de fichiers
Yarn.

### Task 1: Contrat lifecycle core

- [x] Ajouter template, rematch et trois hooks dialogue optionnels.
- [x] Préserver les JSON historiques byte-for-byte.
- [x] Valider les références dialogue et les invariants gym/rival.

### Task 2: Policy runtime

- [x] Résoudre interaction initiale, déjà battue et rematch.
- [x] Ouvrir le dialogue pré-combat puis lancer exactement un battle.
- [x] Ouvrir le dialogue victoire/défaite après publication du résultat.
- [x] Conserver le flag defeated idempotent et le guard one-shot.

### Task 3: Authoring no-code et templates

- [x] Transporter tous les champs dans create/update/notifier.
- [x] Ajouter les presets Trainer, Gym Leader et Rival.
- [x] Ajouter le picker de politique rematch.
- [x] Ajouter trois pickers de dialogues issus du manifeste.
- [x] Valider inline les contrats gym/rival.

### Task 4: Selbrume et clôture

- [x] Promouvoir Lysa comme template rival sans saisie d’ID ou de script brut
      dans l’éditeur.
- [x] Tests core, use cases, widget, policy runtime et intégration ciblée.
- [x] Tests/analyzes package-scoped et smokes.
- [x] Evidence Pack FG-140/141/144/145.
- [x] Commit isolé et état Git final.
