# PokeMap Hub Phase 4 — Shell joueur et session

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ouvrir un jeu installé depuis un écran titre produit, démarrer ou
reprendre une session isolée, router les inputs joueur, terminer la partie et
revenir au titre ou au Hub après un teardown déterministe.

**Architecture:** `map_runtime` possède le protocole, les snapshots et la
façade `GameSessionController`, sans connaître la bibliothèque ni les chemins
du Hub. `apps/pokemap_hub` résout une version installée, confine ses assets,
construit les descriptors, persiste les checkpoints via `HubSaveStore` et
pilote la machine titre/session/résultat/crédits. Le host développeur reste
inchangé. La surface Flutter et le design system joueur restent en Phase 5 ;
la Phase 4 livre les contrôleurs et snapshots canoniques que ces widgets
consommeront.

**Tech Stack:** Dart/Flutter, `map_core`, `map_distribution`, `map_runtime`,
`dart:io`, `path`, `flutter_test`.

---

## Inventaire des fichiers

- `packages/map_runtime/lib/src/session/game_session_contract.dart` : descriptor,
  états, checkpoints, diagnostics et événements publics.
- `packages/map_runtime/lib/src/session/game_session_controller.dart` : machine
  d’états, séquencement, completion, lifecycle et teardown.
- `packages/map_runtime/lib/src/session/in_process_game_session_adapter.dart` :
  adaptateur V0/mobile à graphe runtime jetable injecté.
- `packages/map_runtime/lib/src/session/playable_map_game_session_runtime.dart` :
  composition réelle de `PlayableMapGame`, save mémoire et teardown Flame.
- `packages/map_runtime/lib/src/session/player_input.dart` : actions communes,
  sources et routage focus/session.
- `packages/map_runtime/lib/src/presentation/flame/runtime_input_event.dart` et
  `runtime_input_key_bindings.dart` : action Menu/Start de bout en bout.
- `apps/pokemap_hub/lib/src/session/package_asset_resolver.dart` : résolution
  confinée aux fichiers inventoriés de la version installée.
- `apps/pokemap_hub/lib/src/session/installed_game_launch_resolver.dart` et
  `hub_in_process_session_factory.dart` : revalidation au lancement et
  composition des handles Hub vers le runtime.
- `apps/pokemap_hub/lib/pokemap_hub_player.dart` : API Flutter explicite,
  séparée du barrel pur Dart utilisé par les workers de recovery.
- `apps/pokemap_hub/lib/src/player/player_shell_controller.dart` : écran titre,
  New Game/Continue/Load, pause, résultat, crédits et sorties.
- `apps/pokemap_hub/lib/src/player/hub_session_checkpoint_committer.dart` :
  construction et commit atomique des `SaveEnvelope` actifs/complétés.
- `packages/map_runtime/test/session/` et `apps/pokemap_hub/test/player|session/`
  : preuves `HUB-040…044`.

## HUB-040 — `GameSessionController`

**Objectif :** garantir qu’une seule session existe et que son graphe est
entièrement détruit avant tout nouveau lancement.

**Périmètre :**

- descriptor v1 immuable sans path ni token journalisable ;
- transitions strictes `idle → … → disposed`, événements tardifs rejetés ;
- opérations sérialisées et activations idempotentes ;
- pause gameplay, pause lifecycle avec restauration de l’état précédent ;
- timeout de préparation/démarrage et arrêt gracieux bornés ;
- checkpoint fourni au Hub par port injecté ;
- adaptateur in-process jetable ; le processus enfant desktop reste derrière
  la même interface et sera certifié en Phase 8.

**Tests :**

- lancement nominal et progression ;
- double lancement et événement d’un autre `sessionId` refusés ;
- timeout/fatal puis teardown ;
- retour titre/Hub et lancement jeu B seulement après `disposed(A)` ;
- background depuis running/paused puis reprise exacte.

**DONE :** aucune session B ne démarre avant la destruction confirmée de A,
et toute sortie terminale publie une raison typée.

## HUB-041 — `PackageAssetResolver`

**Objectif :** ne remettre au runtime que des fichiers inventoriés sous la
version installée vérifiée.

**Périmètre :**

- paths package relatifs `/`, sans absolu, `..`, backslash ou NUL ;
- appartenance obligatoire à `content.files` ;
- rejet de chaque symlink dans la chaîne et du fichier non régulier ;
- revalidation canonique de la racine et de la cible ;
- références opaques : aucun path brut dans le descriptor public.

**Tests :**

- projet, branding et crédits valides ;
- traversal POSIX/Windows, fichier non inventorié et cible absente ;
- symlink intermédiaire/final et collision hors racine ;
- résolution stable de `project/project.json`.

**DONE :** aucun input contrôlé par le package ne permet de lire hors de la
version immuable ou un fichier absent de son inventaire.

## HUB-042 — Routeur d’input commun

**Objectif :** router clavier, manette et tactile vers une autorité unique sans
faire bouger le monde derrière une surface joueur.

**Périmètre :**

- actions directionnelles, confirmer, retour et `menu` ;
- `Escape`/B = retour, `Enter`/A = confirmer, `Tab`/Start = menu ;
- répétition autorisée seulement pour la navigation directionnelle ;
- route surface titre/pause/résultat/crédits ou runtime selon le snapshot ;
- Menu bascule running/paused et ne traverse jamais vers Flame ;
- libération des directions avant changement de propriétaire.

**Tests :**

- mapping clavier/manette Start ;
- navigation titre/pause et input gameplay ;
- Menu idempotent, répétition ignorée et focus verrouillé ;
- aucun mouvement quand une surface produit possède l’input.

**DONE :** Menu/Start ouvre et ferme la pause depuis le même seam que les
autres inputs, et aucun overlay ne laisse fuiter une commande vers le monde.

## HUB-043 — Titre New Game / Continue / Load / Options

**Objectif :** rendre le premier lancement et la reprise réellement pilotables
depuis les jeux/saves Phase 2–3.

**Périmètre :**

- snapshot titre avec branding/métadonnées et actions disponibles ;
- Continue sur la save compatible la plus récente ;
- New Game avec profil/slot et confirmation d’écrasement sans supprimer
  préventivement l’ancienne save ;
- Load sur un slot explicitement compatible ;
- Options et À propos comme sous-états stables ;
- descriptor construit depuis manifest/receipt courant, jamais depuis le titre.

**Tests :**

- première ouverture sans save : New Game actif, Continue inactif ;
- Continue charge la bonne adresse et le bon mode ;
- overwrite non confirmé refusé, ancien fichier conservé ;
- double activation ne crée qu’une session ;
- retour titre/Hub respecte les mutations save en vol.

**DONE :** le shell produit peut lancer une nouvelle partie ou une save isolée
sans seed ni fichier de lancement du host développeur.

## HUB-044 — `GameCompleted`, crédits et retour Hub

**Objectif :** fermer la boucle joueur sans perdre la dernière sauvegarde
valide.

**Périmètre :**

- événement runtime v1 typé et idempotent `(sessionId, endingId)` ;
- gameplay verrouillé avant proposition du checkpoint final ;
- commit `SaveEnvelope(status=completed, completedAt=…)` par le Hub ;
- échec/retry explicite sans publication mensongère du résultat ;
- snapshots résultat puis crédits déclaratifs ;
- destination `title`, `hub` ou choix joueur ;
- teardown avant retour et relance avec nouveau `sessionId`.

La commande auteur no-code « Terminer le jeu » n’est pas ajoutée silencieusement
à la roadmap mécanique : le contrat Phase 0 exige un lot FG dédié, tandis que
ce lot livre le récepteur runtime/Hub et son parcours testable.

**Tests :**

- completion nominale, save completed et ordre commit → résultat ;
- double événement ignoré, mauvais game/session fatal ;
- stockage en échec puis retry ;
- crédits vers titre et Hub ;
- aucun gameplay actif derrière résultat/crédits.

**DONE :** après un `GameCompleted` valide, le résultat n’apparaît qu’après le
commit atomique de la save finale et la sortie choisie détruit la session.

## Risques et dépendances

- Le prototype desktop enfant partage ce protocole mais sa supervision OS et
  ses kill-tests multi-plateformes relèvent du gate de certification Phase 8.
- La surface Flutter player et ses semantics/focus visuels seront branchés sur
  ces snapshots en Phase 5 ; aucun widget provisoire n’est ajouté au runtime.
- L’ancien `FileGameSaveRepository` reste pour le host développeur. Le shell Hub
  passe exclusivement par le checkpoint committer scoppé.
- Le modèle auteur de fin exige un lot mécanique explicite avant modification
  de `map_core`/`map_editor`.

## Vérification finale

```bash
cd packages/map_runtime
dart format --output=none --set-exit-if-changed \
  lib/src/session lib/src/presentation/flame/runtime_input_event.dart \
  lib/src/presentation/flame/runtime_input_key_bindings.dart test/session \
  test/runtime_input_key_bindings_test.dart
flutter test test/session test/runtime_input_key_bindings_test.dart
flutter analyze

cd apps/pokemap_hub
dart format --output=none --set-exit-if-changed \
  lib/pokemap_hub.dart lib/pokemap_hub_player.dart lib/src/player \
  lib/src/session test/player test/session test/support/dart_subprocess.dart
flutter test
flutter analyze

git diff --check
git status --short --untracked-files=all
```

Le commit final ne contient que les fichiers de Phase 4 et ce plan. Les 73
fichiers non suivis préexistants restent hors index. Aucun push n’est autorisé.
