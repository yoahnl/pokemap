# Phase R1 — Mini-fix complémentaire au lot 9 — Bootstrap runtime host avec Pokémon seedé

## 1. Résumé exécutif honnête

Le mini-fix est livré dans le scope demandé.

Le host d’exemple `examples/playable_runtime_host` expose maintenant une option visible `Démarrer avec un Pokémon de démo` sur l’écran de lancement. Quand elle est active, le host construit un `SaveData` initial contenant un seul Pokémon jouable cohérent avec les données locales du projet chargé. Quand elle est inactive, le comportement précédent est conservé et le runtime démarre sans seed.

Le seed reste strictement local au host d’exemple :
- aucune logique de seed n’a été ajoutée dans `PlayableMapGame`
- aucune logique de seed n’a été ajoutée dans le mapper runtime -> battle
- aucune logique de seed n’a été ajoutée dans `map_battle`

Le point de vérité du besoin reste inchangé :
- lot 9 = vrai mapping battle depuis la vraie party runtime/save
- mini-fix host = créer facilement une vraie party de démo pour tester ce mapping
- futur lot produit = vrai flow starter / équipe initiale / sac / nouvelle partie

## 2. Cause réelle du besoin

Le lot 9 a rendu le handoff runtime -> battle réel. Le problème restant n’était donc plus le mapper, mais le host d’exemple : on pouvait encore démarrer une session sans Pokémon dans l’équipe du joueur, ce qui rendait le test manuel du lot 9 pénible ou incohérent.

Le besoin réel était donc :
- ne pas modifier le runtime core
- ne pas masquer le problème par un fallback magique
- ajouter un bootstrap purement local au host d’exemple pour pouvoir lancer rapidement une session avec une vraie party minimale

## 3. Périmètre exact

Inclus :
- ajout d’une option UI visible dans l’écran de lancement du host
- ajout d’un helper local de seed Pokémon côté host
- injection du `SaveData` seedé uniquement au moment du lancement si l’option est active
- ajout de tests ciblés utiles sur l’option UI et sur la construction du seed
- validation `format / analyze / tests` ciblée

Exclu :
- lot 10
- capture
- seen/caught
- sac complet
- starter produit final
- sélecteur de starter
- PC / boxes
- logique magique globale dans `map_runtime`
- logique magique globale dans `map_battle`

## 4. Liste exacte des fichiers modifiés / créés

Modifiés :
- `examples/playable_runtime_host/lib/main.dart`

Créés :
- `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- `examples/playable_runtime_host/lib/src/runtime_launch_options.dart`
- `examples/playable_runtime_host/test/project_loader_page_test.dart`
- `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

Aucun fichier supprimé.

## 5. Justification fichier par fichier

### `examples/playable_runtime_host/lib/main.dart`

Changements :
- import du helper local de seed
- import du widget UI local pour le switch
- ajout de l’état `_seedDemoPokemon`
- ajout du contrôle UI dans l’écran de lancement
- appel du helper de seed au moment du lancement
- conversion locale du seed en `SaveData` avant injection dans `PlayableMapGame`

Pourquoi ici :
- c’est le vrai point d’entrée du host
- c’est le bon endroit pour garder le comportement opt-in
- cela évite toute contamination du runtime core

### `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`

Changements :
- création d’un helper local qui lit `project.json`, les fichiers species et learnsets
- sélection d’une espèce locale utilisable
- dérivation de quelques attaques connues valides depuis `startingMoves`, `relearnMoves` et `levelUp <= niveau`
- retour d’un petit objet local `RuntimeDemoPartySeed`

Pourquoi ici :
- cette logique doit rester strictement locale au host
- elle doit être facilement retirable plus tard
- elle ne doit pas créer de responsabilité implicite dans le runtime core

### `examples/playable_runtime_host/lib/src/runtime_launch_options.dart`

Changements :
- extraction d’un petit widget local pour l’option de seed UI

Pourquoi ici :
- permet de tester la présence et le comportement du contrôle UI sans dépendre du runtime complet
- reste purement local au host

### `examples/playable_runtime_host/test/project_loader_page_test.dart`

Changements :
- test widget ciblé qui prouve que l’option UI existe
- vérifie que le switch est activé par défaut
- vérifie qu’il peut être basculé

Pourquoi ce test :
- c’est la preuve automatisée minimale utile pour la présence de l’option UI

### `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

Changements :
- test du helper local de seed sur un workspace temporaire minimal
- prouve que l’option inactive ne seed rien
- prouve que l’option active construit bien un Pokémon jouable cohérent

Pourquoi ce test :
- couvre la vraie valeur du mini-fix
- reste local au host
- évite de dépendre d’un bootstrap runtime global

## 6. Commandes réellement exécutées

Audit :

```bash
find . -path '*/AGENTS.md' -print
git status --short
git diff --stat
git ls-files --others --exclude-standard
rg -n "launch|loadRuntimeMapBundle|PlayableMapGame|saveData|SaveData|PlayerPokemon|PlayerParty" examples/playable_runtime_host packages/map_runtime -g'*.dart'
sed -n '1,260p' examples/playable_runtime_host/lib/main.dart
sed -n '1,240p' examples/playable_runtime_host/test/in_game_menu_test.dart
sed -n '1,260p' examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart
sed -n '1,220p' examples/playable_runtime_host/pubspec.yaml
```

Validation :

```bash
/opt/homebrew/bin/dart format examples/playable_runtime_host/lib/main.dart examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart examples/playable_runtime_host/lib/src/runtime_launch_options.dart examples/playable_runtime_host/test/project_loader_page_test.dart examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart

/opt/homebrew/bin/flutter analyze --no-pub lib/main.dart lib/src/runtime_demo_party_seed.dart lib/src/runtime_launch_options.dart test/project_loader_page_test.dart test/runtime_demo_party_seed_test.dart

/opt/homebrew/bin/flutter test test/project_loader_page_test.dart test/runtime_demo_party_seed_test.dart
```

Commande tentée puis abandonnée comme non pertinente pour ce mini-fix local :

```bash
/opt/homebrew/bin/flutter test test/project_loader_page_test.dart test/runtime_demo_party_seed_test.dart test/runtime_pokedex_loader_test.dart test/in_game_menu_test.dart
```

## 7. Résultats réels de format / analyze / tests

### `dart format`

Résultat :

```text
Formatted examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
Formatted 5 files (1 changed) in 0.02 seconds.
```

### `flutter analyze --no-pub`

Résultat :

```text
No issues found! (ran in 1.6s)
```

### `flutter test` ciblé utile

Résultat :

```text
00:01 +3: All tests passed!
```

### Incident sur une commande de tests plus large

J’ai d’abord tenté d’exécuter une suite plus large sur le package d’exemple, incluant :
- `test/runtime_pokedex_loader_test.dart`
- `test/in_game_menu_test.dart`

Cette commande a échoué sur des erreurs de compilation plus larges provenant de `packages/map_core` / `packages/map_runtime` hors périmètre de ce mini-fix, notamment autour de `element_collision_profile.g.dart` et de méthodes `GameplayWorldState` absentes côté compile.

Je n’ai pas rouvert ces sujets, car :
- ils ne sont pas causés par ce mini-fix
- ils dépassent le périmètre demandé
- les deux preuves utiles demandées pour ce mini-fix restent disponibles et passent

## 8. État git utile

```text
 M examples/playable_runtime_host/lib/main.dart
?? examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
?? examples/playable_runtime_host/lib/src/runtime_launch_options.dart
?? examples/playable_runtime_host/test/project_loader_page_test.dart
?? examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
```

`git diff --stat` :

```text
 examples/playable_runtime_host/lib/main.dart | 33 ++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)
```

`git ls-files --others --exclude-standard` :

```text
examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
examples/playable_runtime_host/lib/src/runtime_launch_options.dart
examples/playable_runtime_host/test/project_loader_page_test.dart
examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
```

## 9. Checklist finale

- [x] je n’ai pas touché au lot 10
- [x] je n’ai pas introduit de logique magique de seed dans le runtime core
- [x] le seed est strictement opt-in via le host/menu de démarrage
- [x] l’exemple peut démarrer avec un Pokémon de démo
- [x] le comportement sans seed reste possible
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai pas rouvert capture / sac / starter complet
- [x] je n’ai fait aucune écriture git interdite
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] mon report contient le contenu complet des fichiers touchés

## 10. Conclusion honnête

Le mini-fix est livré dans son scope.

Ce qui est maintenant vrai :
- le host runtime d’exemple expose une option claire pour démarrer avec un Pokémon de démo
- si l’option est activée, une vraie party minimale est injectée localement au host
- si l’option est désactivée, le comportement sans seed est conservé
- le runtime core continue simplement à consommer l’état qu’on lui donne

Ce qui n’a volontairement pas été fait :
- aucun flow starter final
- aucun système d’équipe initiale produit
- aucune logique bag/capture
- aucune logique cachée dans le runtime ou le battle engine

## 11. Annexe — contenu complet des fichiers texte modifiés / créés

Note :
- ce report s’exclut lui-même de sa propre annexe pour éviter la récursion infinie
- tous les autres fichiers texte touchés sont inclus en entier ci-dessous

### `examples/playable_runtime_host/lib/main.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'src/in_game_menu.dart';
import 'src/runtime_demo_party_seed.dart';
import 'src/runtime_launch_options.dart';
import 'src/runtime_pokedex_loader.dart';

// Point d'entrée minimal du host runtime.
// On garde un MaterialApp très simple, puis toute la navigation se fait
// depuis la page de chargement et le menu in-game.
void main() {
  runApp(const MaterialApp(
    title: 'Playable Runtime Host',
    home: _ProjectLoaderPage(),
  ));
}

// Cette page joue deux rôles très ciblés :
// 1. charger un projet et une map runtime ;
// 2. exposer les surfaces minimales de debug/save/menu utiles aux phases 9-10.
class _ProjectLoaderPage extends StatefulWidget {
  const _ProjectLoaderPage();

  @override
  State<_ProjectLoaderPage> createState() => _ProjectLoaderPageState();
}

class _ProjectLoaderPageState extends State<_ProjectLoaderPage> {
  String _projectFilePath = '';
  List<ProjectMapEntry> _availableMaps = const [];
  String? _selectedMapId;
  PlayableMapGame? _game;
  String? _error;
  bool _loading = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showFpsOverlay = false;
  bool _surfingEnabled = false;
  bool _seedDemoPokemon = true;
  bool _saveLoadBusy = false;
  String? _saveLoadStatus;
  String? _saveLoadError;
  Timer? _runtimeInfoTicker;

  static const _prefsFileName = '.playable_runtime_host_prefs.json';

  @override
  void initState() {
    super.initState();
    _restoreLastSession();
  }

  @override
  void dispose() {
    // Le ticker d'overlay est strictement local au host et doit toujours être
    // arrêté quand la page sort, pour éviter toute fuite de rafraîchissement.
    _runtimeInfoTicker?.cancel();
    super.dispose();
  }

  // Les préférences locales du host ne font pas partie de la save gameplay.
  // Elles servent seulement à rouvrir rapidement le dernier projet dans l'outil
  // d'hébergement runtime.
  String _prefsFilePath() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return _prefsFileName;
    }
    return '$home/$_prefsFileName';
  }

  // La restauration des préférences est volontairement best-effort :
  // on veut retrouver vite le dernier projet, sans jamais bloquer le chargement
  // si le fichier local est absent ou invalide.
  Future<void> _restoreLastSession() async {
    try {
      final file = File(_prefsFilePath());
      if (!await file.exists()) {
        return;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final savedProjectPath = (decoded['projectFilePath'] as String?)?.trim();
      final savedMapId = (decoded['mapId'] as String?)?.trim();
      if (savedProjectPath == null || savedProjectPath.isEmpty) {
        return;
      }
      if (!await File(savedProjectPath).exists()) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _projectFilePath = savedProjectPath;
        _selectedMapId = savedMapId != null && savedMapId.isNotEmpty
            ? savedMapId
            : _selectedMapId;
      });
      await _loadProjectMapsFromManifest(
        savedProjectPath,
        preferredMapId: savedMapId,
      );
    } catch (_) {
      // Restauration best-effort: on ignore silencieusement les prefs invalides.
    }
  }

  // On persiste seulement le chemin du projet et la map choisie, pas l'état
  // gameplay. La vraie sauvegarde gameplay reste dans le pipeline phase 9.
  Future<void> _persistLastSession() async {
    try {
      final file = File(_prefsFilePath());
      final payload = <String, dynamic>{
        'projectFilePath': _projectFilePath,
        'mapId': _selectedMapId,
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Persistance best-effort: ne bloque jamais le flux utilisateur.
    }
  }

  // Cette lecture du manifest sert uniquement à alimenter le host :
  // on récupère la liste des maps disponibles sans toucher au save system.
  Future<void> _loadProjectMapsFromManifest(
    String projectFilePath, {
    String? preferredMapId,
  }) async {
    try {
      final raw = await File(projectFilePath).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _availableMaps = const [];
        });
        return;
      }
      final manifest = ProjectManifest.fromJson(decoded);
      final maps = List<ProjectMapEntry>.of(manifest.maps)
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          if (byOrder != 0) return byOrder;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      String? nextSelected = _selectedMapId;
      final preferred = preferredMapId?.trim();
      if (preferred != null &&
          preferred.isNotEmpty &&
          maps.any((m) => m.id == preferred)) {
        nextSelected = preferred;
      } else if (nextSelected == null ||
          nextSelected.isEmpty ||
          !maps.any((m) => m.id == nextSelected)) {
        nextSelected = maps.isEmpty ? null : maps.first.id;
      }
      if (!mounted) return;
      setState(() {
        _availableMaps = maps;
        _selectedMapId = nextSelected;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableMaps = const [];
      });
    }
  }

  // Le ticker force un refresh léger de l'overlay runtime pour afficher
  // les informations de debug et de save qui évoluent pendant la session.
  void _startRuntimeInfoTicker() {
    _runtimeInfoTicker?.cancel();
    _runtimeInfoTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (!mounted || _game == null) {
          return;
        }
        setState(() {});
      },
    );
  }

  void _stopRuntimeInfoTicker() {
    _runtimeInfoTicker?.cancel();
    _runtimeInfoTicker = null;
  }

  // Le host laisse l'utilisateur choisir explicitement un project.json.
  // Cela reste séparé de toute logique de menu in-game ou de save gameplay.
  Future<void> _pickProjectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      dialogTitle: 'Sélectionner project.json',
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _projectFilePath = path;
      _error = null;
    });
    await _loadProjectMapsFromManifest(path);
    await _persistLastSession();
  }

  // Ce chargement construit uniquement le bundle runtime et l'instance de jeu.
  // Il ne modifie pas la structure métier des saves.
  Future<void> _load() async {
    final projectFilePath = _projectFilePath;
    final mapId = (_selectedMapId ?? '').trim();

    if (projectFilePath.isEmpty) {
      setState(() => _error = 'Sélectionnez un fichier project.json.');
      return;
    }
    if (mapId.isEmpty) {
      setState(() => _error = 'Saisissez un identifiant de map.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _game = null;
    });

    try {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      final launchDemoSeed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: _seedDemoPokemon,
        projectFilePath: projectFilePath,
      );
      if (!mounted) return;
      final nextGame = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: launchDemoSeed == null
            ? null
            : SaveData(
                saveId: kRuntimeDemoSeedSaveId,
                currentMapId: mapId,
                party: PlayerParty(
                  members: <PlayerPokemon>[
                    PlayerPokemon(
                      speciesId: launchDemoSeed.speciesId,
                      natureId: 'hardy',
                      abilityId: launchDemoSeed.abilityId,
                      level: launchDemoSeed.level,
                      knownMoveIds: launchDemoSeed.knownMoveIds,
                      currentHp: launchDemoSeed.currentHp,
                    ),
                  ],
                ),
                trainerProfile: const TrainerProfile(name: 'Demo'),
              ),
      );
      setState(() {
        _game = nextGame;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });
      nextGame.setCollisionOverlayVisible(_showCollisionOverlay);
      nextGame
          .setNpcCollisionDebugOverlayVisible(_showNpcCollisionDebugOverlay);
      nextGame.setFpsOverlayVisible(_showFpsOverlay);
      nextGame.setSurfingEnabled(_surfingEnabled);
      _startRuntimeInfoTicker();
      await _persistLastSession();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Retour au chargeur de projet.
  // On ne détruit pas de données persistées, on ferme juste la session runtime.
  void _reset() => setState(() {
        _stopRuntimeInfoTicker();
        _game = null;
        _error = null;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });

  // Les boutons historiques du host réutilisent désormais le même flux que
  // l'écran "Sauvegarde" du menu in-game, pour garder une seule source de
  // vérité côté runtime.
  Future<void> _saveGame() async {
    await _performSaveRequest();
  }

  Future<void> _loadGame() async {
    await _performLoadRequest();
  }

  // Ce helper centralise la sauvegarde gameplay existante.
  // Il renvoie un résultat structuré pour que le menu in-game et l'overlay
  // historique affichent exactement le même statut utilisateur.
  Future<InGameMenuActionResult> _performSaveRequest() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return const InGameMenuActionResult(
        error: 'Sauvegarde indisponible',
      );
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final saved = await game.saveGame();
      if (!mounted) {
        return const InGameMenuActionResult();
      }
      final info = game.saveLoadInfo;
      final status = saved
          ? 'Sauvegarde OK · ${info.mapId} (${info.playerX}, ${info.playerY})'
          : 'Sauvegarde impossible';
      setState(() {
        _saveLoadStatus = status;
      });
      return InGameMenuActionResult(status: status);
    } catch (e) {
      if (!mounted) {
        return const InGameMenuActionResult();
      }
      final error = 'Erreur sauvegarde: $e';
      setState(() {
        _saveLoadError = error;
      });
      return InGameMenuActionResult(error: error);
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  // Même principe pour le chargement :
  // on garde un seul chemin d'exécution pour l'overlay runtime et le menu.
  Future<InGameMenuActionResult> _performLoadRequest() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return const InGameMenuActionResult(
        error: 'Chargement indisponible',
      );
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final loaded = await game.loadGame();
      if (!mounted) return const InGameMenuActionResult();
      if (!loaded) {
        const error = 'Aucune sauvegarde trouvée ou chargement impossible';
        setState(() {
          _saveLoadError = error;
        });
        return const InGameMenuActionResult(error: error);
      }
      final info = game.saveLoadInfo;
      final status =
          'Chargement OK · ${info.mapId} (${info.playerX}, ${info.playerY})';
      setState(() {
        _surfingEnabled = info.movementMode == MovementMode.surf.name;
        _saveLoadStatus = status;
      });
      return InGameMenuActionResult(status: status);
    } catch (e) {
      if (!mounted) return const InGameMenuActionResult();
      final error = 'Erreur chargement: $e';
      setState(() {
        _saveLoadError = error;
      });
      return InGameMenuActionResult(error: error);
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  // Le menu phase 10 vit dans le host runtime existant, sans nouveau framework.
  // On pousse simplement une route Flutter classique au-dessus du GameWidget.
  Future<void> _openInGameMenu() async {
    final game = _game;
    if (game == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return InGameMenuPage(
            gameStateSnapshotBuilder: () => game.gameStateSnapshot,
            pokedexLoader: () => loadRuntimePokedexEntries(
              projectFilePath: _projectFilePath,
            ),
            onSaveRequested: _performSaveRequest,
            onLoadRequested: _performLoadRequest,
            onCloseRequested: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deux états d'interface seulement :
    // 1. soit une session runtime est active et on affiche le jeu ;
    // 2. soit on reste sur le chargeur de projet.
    final game = _game;
    if (game != null) {
      final info = game.saveLoadInfo;
      return Scaffold(
        appBar: AppBar(
          title: Text((_selectedMapId ?? '').trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _reset,
          ),
          actions: [
            // Le menu in-game est volontairement minimal :
            // un seul bouton ouvre les écrans lecture seule de la phase 10.
            IconButton(
              key: const Key('runtime-menu-button'),
              icon: const Icon(Icons.menu),
              onPressed: _openInGameMenu,
            ),
          ],
        ),
        body: Stack(
          children: [
            GameWidget(game: game),
            Positioned(
              top: 12,
              right: 12,
              child: Card(
                color: Colors.black.withValues(alpha: 0.55),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Collisions',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showCollisionOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _showCollisionOverlay = v);
                                    game.setCollisionOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'FPS',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showFpsOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _showFpsOverlay = v);
                                    game.setFpsOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Surf',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _surfingEnabled,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _surfingEnabled = v);
                                    game.setSurfingEnabled(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NPC hitbox',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showNpcCollisionDebugOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(
                                      () => _showNpcCollisionDebugOverlay = v,
                                    );
                                    game.setNpcCollisionDebugOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Map: ${info.mapId}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Pos: (${info.playerX}, ${info.playerY})  Face: ${info.facing}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Mode: ${info.movementMode}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'FPS: ${game.currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.lightGreenAccent),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: _saveLoadBusy ? null : _saveGame,
                            child: const Text('Sauvegarder'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saveLoadBusy ? null : _loadGame,
                            child: const Text('Charger'),
                          ),
                        ],
                      ),
                      if (_saveLoadStatus != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveLoadStatus!,
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                      if (_saveLoadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveLoadError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Playable Runtime Host')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Projet', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ProjectFileField(
              path: _projectFilePath,
              onPick: _loading ? null : _pickProjectFile,
            ),
            const SizedBox(height: 20),
            if (_availableMaps.isEmpty)
              const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Map',
                  hintText:
                      'Chargez un project.json valide pour lister les maps',
                  border: OutlineInputBorder(),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedMapId,
                decoration: const InputDecoration(
                  labelText: 'Map',
                  border: OutlineInputBorder(),
                ),
                items: _availableMaps
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.id,
                        child: Text('${entry.name} (${entry.id})'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedMapId = value);
                        _persistLastSession();
                      },
              ),
            const SizedBox(height: 16),
            RuntimeDemoSeedToggle(
              value: _seedDemoPokemon,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _seedDemoPokemon = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _load,
              child: Text(_loading ? 'Chargement…' : 'Lancer'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectFileField extends StatelessWidget {
  const _ProjectFileField({required this.path, required this.onPick});

  final String path;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                path.isEmpty ? 'Aucun fichier sélectionné' : path,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: path.isEmpty ? Theme.of(context).hintColor : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: onPick,
              child: const Text('Parcourir…'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
```

### `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`

```dart
import 'dart:convert';
import 'dart:io';

const kRuntimeDemoSeedLevel = 5;
const kRuntimeDemoSeedCurrentHp = 12;
const kRuntimeDemoSeedSaveId = 'runtime-host-demo-save';

class RuntimeDemoPartySeed {
  const RuntimeDemoPartySeed({
    required this.speciesId,
    required this.abilityId,
    required this.level,
    required this.currentHp,
    required this.knownMoveIds,
  });

  final String speciesId;
  final String abilityId;
  final int level;
  final int currentHp;
  final List<String> knownMoveIds;
}

Future<RuntimeDemoPartySeed?> buildRuntimeHostLaunchDemoPartySeed({
  required bool seedDemoPokemon,
  required String projectFilePath,
}) async {
  if (!seedDemoPokemon) {
    return null;
  }

  final projectFile = File(projectFilePath);
  final projectJson =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  final projectRootUri = projectFile.parent.uri;
  final pokemonConfig = _readPokemonConfig(projectJson);

  final speciesJsonEntries = await _readSpeciesEntries(
    projectRootUri: projectRootUri,
    speciesDir: pokemonConfig.speciesDir,
  );
  if (speciesJsonEntries.isEmpty) {
    throw StateError(
      'Impossible de preparer un Pokemon de demo: aucune espece locale disponible.',
    );
  }

  final selectedSpecies = speciesJsonEntries.firstWhere(
    (entry) => entry.isEnabledInProject,
    orElse: () => speciesJsonEntries.first,
  );
  final speciesJson = selectedSpecies.json;
  final learnsetId = _readLearnsetId(speciesJson, selectedSpecies.id);
  final learnsetJson = await _readJsonMap(
    projectRootUri.resolve('${pokemonConfig.learnsetsDir}/$learnsetId.json'),
  );

  final abilityId = _readPrimaryAbilityId(speciesJson) ?? 'unknown';
  final knownMoveIds = _deriveKnownMoveIds(
    learnsetJson,
    level: kRuntimeDemoSeedLevel,
  );

  if (knownMoveIds.isEmpty) {
    throw StateError(
      'Impossible de preparer un Pokemon de demo utilisable: aucune attaque locale exploitable.',
    );
  }

  return RuntimeDemoPartySeed(
    speciesId: selectedSpecies.id,
    abilityId: abilityId,
    level: kRuntimeDemoSeedLevel,
    currentHp: kRuntimeDemoSeedCurrentHp,
    knownMoveIds: knownMoveIds,
  );
}

class _RuntimeHostPokemonConfig {
  const _RuntimeHostPokemonConfig({
    required this.speciesDir,
    required this.learnsetsDir,
  });

  final String speciesDir;
  final String learnsetsDir;
}

class _RuntimeHostSpeciesJsonEntry {
  const _RuntimeHostSpeciesJsonEntry({
    required this.id,
    required this.isEnabledInProject,
    required this.json,
  });

  final String id;
  final bool isEnabledInProject;
  final Map<String, dynamic> json;
}

_RuntimeHostPokemonConfig _readPokemonConfig(Map<String, dynamic> projectJson) {
  final pokemon = projectJson['pokemon'];
  if (pokemon is! Map<String, dynamic>) {
    return const _RuntimeHostPokemonConfig(
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
    );
  }

  final speciesDir =
      (pokemon['speciesDir'] as String?)?.trim() ?? 'data/pokemon/species';
  final learnsetsDir =
      (pokemon['learnsetsDir'] as String?)?.trim() ?? 'data/pokemon/learnsets';

  return _RuntimeHostPokemonConfig(
    speciesDir: speciesDir,
    learnsetsDir: learnsetsDir,
  );
}

Future<List<_RuntimeHostSpeciesJsonEntry>> _readSpeciesEntries({
  required Uri projectRootUri,
  required String speciesDir,
}) async {
  final speciesDirectory = Directory.fromUri(
    projectRootUri.resolve('$speciesDir/'),
  );
  if (!await speciesDirectory.exists()) {
    throw StateError(
      'Impossible de preparer un Pokemon de demo: dossier species introuvable.',
    );
  }

  final entries = <_RuntimeHostSpeciesJsonEntry>[];
  await for (final entity in speciesDirectory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) {
      continue;
    }
    final json = await _readJsonMap(entity.uri);
    final declaredId = (json['id'] as String?)?.trim();
    if (declaredId == null || declaredId.isEmpty) {
      continue;
    }
    final classification = (json['classification'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    entries.add(
      _RuntimeHostSpeciesJsonEntry(
        id: declaredId,
        isEnabledInProject:
            (classification['isEnabledInProject'] as bool?) ?? true,
        json: json,
      ),
    );
  }
  entries.sort((left, right) => left.id.compareTo(right.id));
  return List<_RuntimeHostSpeciesJsonEntry>.unmodifiable(entries);
}

Future<Map<String, dynamic>> _readJsonMap(Uri fileUri) async {
  final file = File.fromUri(fileUri);
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('JSON project Pokemon invalide.');
  }
  return decoded;
}

String _readLearnsetId(
  Map<String, dynamic> speciesJson,
  String fallbackSpeciesId,
) {
  final refs = speciesJson['refs'];
  if (refs is Map<String, dynamic>) {
    final learnset = (refs['learnset'] as String?)?.trim();
    if (learnset != null && learnset.isNotEmpty) {
      return learnset;
    }
  }
  final legacy = (speciesJson['learnsetRef'] as String?)?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    return legacy;
  }
  return fallbackSpeciesId;
}

String? _readPrimaryAbilityId(Map<String, dynamic> speciesJson) {
  final abilities = speciesJson['abilities'];
  if (abilities is! Map<String, dynamic>) {
    return null;
  }
  final primary = (abilities['primary'] as String?)?.trim();
  if (primary == null || primary.isEmpty) {
    return null;
  }
  return primary;
}

List<String> _deriveKnownMoveIds(
  Map<String, dynamic> learnsetJson, {
  required int level,
}) {
  final ordered = <String>[
    ..._readStringList(learnsetJson['startingMoves']),
    ..._readStringList(learnsetJson['relearnMoves']),
    ..._readLevelUpMoveIds(learnsetJson['levelUp'], level: level),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final moveId in ordered) {
    final trimmed = moveId.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    unique.add(trimmed);
  }

  if (unique.length <= 4) {
    return List<String>.unmodifiable(unique);
  }
  return List<String>.unmodifiable(unique.sublist(unique.length - 4));
}

List<String> _readStringList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
}

List<String> _readLevelUpMoveIds(
  Object? raw, {
  required int level,
}) {
  if (raw is! List) {
    return const <String>[];
  }
  final moveIds = <String>[];
  for (final entry in raw.whereType<Map>()) {
    final levelUpEntry = entry.cast<String, dynamic>();
    final requiredLevel = (levelUpEntry['level'] as num?)?.toInt() ?? 0;
    final moveId = (levelUpEntry['moveId'] as String?)?.trim() ?? '';
    if (requiredLevel <= level && moveId.isNotEmpty) {
      moveIds.add(moveId);
    }
  }
  return List<String>.unmodifiable(moveIds);
}
```

### `examples/playable_runtime_host/lib/src/runtime_launch_options.dart`

```dart
import 'package:flutter/material.dart';

class RuntimeDemoSeedToggle extends StatelessWidget {
  const RuntimeDemoSeedToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: const Key('seed-demo-pokemon-switch'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Démarrer avec un Pokémon de démo'),
      subtitle: const Text(
        'Ajoute un Pokémon jouable dans l’équipe initiale.',
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
```

### `examples/playable_runtime_host/test/project_loader_page_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_launch_options.dart';

void main() {
  testWidgets('shows the demo pokemon launch option enabled by default',
      (tester) async {
    var value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RuntimeDemoSeedToggle(
                value: value,
                onChanged: (nextValue) {
                  setState(() => value = nextValue);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('seed-demo-pokemon-switch')), findsOneWidget);
    expect(find.text('Démarrer avec un Pokémon de démo'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('seed-demo-pokemon-switch')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('seed-demo-pokemon-switch')));
    await tester.pump();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('seed-demo-pokemon-switch')),
          )
          .value,
      isFalse,
    );
  });
}
```

### `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_demo_party_seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildRuntimeHostLaunchDemoPartySeed', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('runtime_host_seed_');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('returns null when demo seed is disabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: false,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNull);
    });

    test('builds a seeded save with one usable pokemon when enabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      expect(seed!.speciesId, equals('bulbasaur'));
      expect(seed.level, equals(kRuntimeDemoSeedLevel));
      expect(seed.currentHp, equals(kRuntimeDemoSeedCurrentHp));
      expect(seed.abilityId, equals('overgrow'));
      expect(
        seed.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });
  });
}

Future<void> _writeProjectFixture(Directory root) async {
  await File('${root.path}/project.json').writeAsString(
    jsonEncode(<String, dynamic>{
      'name': 'Runtime Host Seed Test',
      'maps': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'lab',
          'name': 'Lab',
          'relativePath': 'maps/lab.json',
        },
      ],
      'tilesets': const <Map<String, dynamic>>[],
      'pokemon': <String, dynamic>{
        'enabled': true,
        'speciesDir': 'data/pokemon/species',
        'learnsetsDir': 'data/pokemon/learnsets',
      },
    }),
  );

  await _writeJson(
    root,
    'data/pokemon/species/0001-bulbasaur.json',
    <String, dynamic>{
      'id': 'bulbasaur',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Bulbasaur'},
      'typing': <String, Object>{
        'types': <String>['grass', 'poison'],
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{
        'learnset': 'bulbasaur',
        'evolution': 'bulbasaur',
        'media': 'bulbasaur',
      },
      'classification': <String, bool>{'isEnabledInProject': true},
    },
  );

  await _writeJson(
    root,
    'data/pokemon/learnsets/bulbasaur.json',
    <String, dynamic>{
      'speciesId': 'bulbasaur',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 5,
          'source': 'level_up',
          'versionGroup': 'demo',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'demo',
        },
      ],
    },
  );
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File.fromUri(root.uri.resolve(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
```
