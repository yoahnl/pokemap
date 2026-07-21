# Narrative Studio v1 — Checklist humaine reproductible

Version de preuve : 2026-07-21

Lot : `NSC-83`
Projet : `selbrume/`

Cette checklist permet à une autre personne de reproduire la gate sans
contexte oral et sans modifier manuellement un JSON. Toujours travailler sur
une copie du projet pour les étapes qui écrivent.

## 1. Prérequis

- macOS avec Flutter `3.46.0-0.3.pre` et Dart `3.13.0-167.1.beta`, ou une
  version compatible avec le dépôt ;
- dépôt positionné sur le commit de la gate ou un descendant ;
- accès en écriture à un dossier de test ;
- aucun éditeur JSON utilisé comme outil d'authoring.

Contrôles initiaux depuis la racine :

```bash
git status --short --untracked-files=all
shasum -a 256 selbrume/project.json
```

Fingerprint attendu pour le manifeste canonique :

```text
a1ab8c3646be969745767effcda9f00f26f677e3acc1535a36cdcac6d4e3d7a0
```

## 2. Préparer une copie jetable

Copier le dossier `selbrume/` dans un emplacement local, ouvrir le
`project.json` de cette copie depuis l'éditeur, puis conserver le projet source
fermé. Le SHA-256 source doit être identique après le parcours.

## 3. Parcours Map Editor → Narrative Studio

1. Lancer l'application macOS `map_editor.app`.
2. Ouvrir la copie du projet Selbrume.
3. Vérifier le bandeau : projet chargé, synchronisé, sauvegardé, état bon.
4. Ouvrir Narrative Studio → Aperçu.
5. Attendre les compteurs attendus : 4 chapitres, 31 Scenes, 16 Cinematics,
   3 quêtes secondaires, 22 Dialogues, 49 Facts et 34 World Rules.
6. Ouvrir Événements : 31 Events doivent être listés.
7. Sélectionner un Event actif. Vérifier qu'il référence une vraie source de
   map, une Scene, des Facts/conditions et des conséquences lisibles.
8. Ouvrir Validateur et lancer la validation.

Résultat attendu : `Jouable`, 0 erreur bloquante. Les avertissements de qualité
restent consultables et ne sont pas présentés comme des erreurs.

## 4. Sauvegarde, fermeture et reload

1. Ouvrir Nouveau jeu.
2. Modifier le nom du joueur avec une valeur reconnaissable.
3. Sauvegarder depuis l'UI.
4. Fermer complètement l'application.
5. Relancer l'éditeur et rouvrir la même copie.
6. Revenir dans Nouveau jeu.

Résultat attendu : le nom est toujours présent ; aucun JSON n'a été édité à la
main et aucune donnée narrative n'a disparu.

## 5. Runtime réel

1. Construire puis lancer `playable_runtime_host.app`.
2. Charger la copie Selbrume.
3. Vérifier l'affichage de `map_bourg_selbrume`.
4. Déplacer le joueur, sauvegarder depuis l'overlay, puis recharger.

Résultat attendu : le runtime restaure la même map, la même position et le
même état. La session NSC-83 a vérifié la position `(17,24)`.

## 6. Accessibilité et petites fenêtres

Exécuter les tests suivants depuis `packages/map_editor` :

```bash
/opt/homebrew/bin/flutter test \
  test/ui/canvas/narrative_studio_responsive_accessibility_test.dart \
  test/ui/canvas/narrative_studio_semantics_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart \
  test/ui/shell/project_explorer_handoff_test.dart
```

Résultat attendu : navigation clavier et labels sémantiques présents, aucun
overflow à 200 % ni dans les fenêtres basses, compactage du panneau projet
quand les deux panneaux latéraux écraseraient la scène centrale.

## 7. Pannes à injecter

Ces contrôles sont automatisés pour rester déterministes :

| Panne | Preuve attendue |
|---|---|
| Asset Cinematic absent | fallback/diagnostic explicite, pas de crash |
| Écriture refusée | état de recovery visible, aucune fausse sauvegarde |
| Révision/référence stale | action de reprise, aucune écriture aveugle |
| Commande runtime non supportée | rejet fail-closed, jamais ignorée |

Commande minimale :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test \
  test/cinematics_library_workspace_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart

cd ../map_runtime
/opt/homebrew/bin/flutter test \
  test/cinematic_runtime_playback_controller_test.dart
```

## 8. Gate technique complète

Exécuter, package par package :

```bash
cd packages/map_core && dart test && dart analyze
cd ../map_gameplay && dart test && dart analyze
cd ../map_battle && dart test && dart analyze
cd ../map_runtime && flutter test && flutter analyze
cd ../map_editor && flutter test && flutter analyze
cd ../../examples/playable_runtime_host && flutter test && flutter analyze
```

Puis :

```bash
cd packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart

cd ../../examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart

cd ../../packages/map_editor
flutter build macos --debug

cd ../../examples/playable_runtime_host
flutter build macos --debug
```

## 9. Critères GO / NO-GO

GO seulement si :

- aucune suite obligatoire n'échoue ;
- les deux applications macOS sont produites ;
- le Validator affiche 0 erreur bloquante ;
- save/close/reload et runtime save/load sont observés ;
- aucune commande publiée n'est silencieusement ignorée par le runtime ;
- aucune limitation P0/P1 n'est connue ;
- le projet source conserve son fingerprint.

Cette checklist ferme la gate Narrative Studio/Selbrume. Elle ne remplace pas
la release gate mécanique globale `FG-185`.
