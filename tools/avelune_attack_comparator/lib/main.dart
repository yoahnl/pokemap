import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart' show PsdkBattleMoveCategory;
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart' show BattleCommandOverlaySnapshot;
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import 'preview_game.dart';

enum PhoneOrientation {
  portrait(Size(393, 852), 'Portrait', Icons.stay_current_portrait),
  landscape(Size(852, 393), 'Paysage', Icons.stay_current_landscape);

  const PhoneOrientation(this.size, this.label, this.icon);

  final Size size;
  final String label;
  final IconData icon;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final qaRoot = Platform.environment['AVELUNE_ATTACK_QA_ROOT'];
  final root = await extractPreviewResources(
    parent: qaRoot == null || qaRoot.isEmpty ? null : Directory(qaRoot),
  );
  final index = jsonDecode(
    await rootBundle.loadString('assets/bw2/batch/index.json'),
  ) as List;
  final batchMoves = [
    for (final item in index.cast<Map<String, dynamic>>())
      PreviewMove(
        item['id'] as String,
        item['label'] as String,
        item['referenceUrl'] as String?,
        item['type'] as String,
        switch (item['category']) {
          'special' => PsdkBattleMoveCategory.special,
          'status' => PsdkBattleMoveCategory.status,
          _ => PsdkBattleMoveCategory.physical,
        },
        particle: item['particle'] as int?,
        bundleAsset: item['bundleAsset'] as String,
        sourceVariant: item['sourceVariant'] as String?,
        approximations: (item['approximations'] as List? ?? const [])
            .cast<String>(),
      ),
  ];
  debugPrint('[compare] resource root ${root.path}');
  runApp(
    AttackComparator(root: root, moves: [...PreviewMove.values, ...batchMoves]),
  );
}

Future<Directory> extractPreviewResources({Directory? parent}) async {
  final tempParent = parent ?? Directory.systemTemp;
  if (parent != null) await tempParent.create(recursive: true);
  final root = await tempParent.createTemp('avelune-attack-preview-');
  try {
    final data = await rootBundle.load('assets/runtime_input.zip');
    final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
    for (final file in archive.files.where((file) => file.isFile)) {
      final name = p.posix.normalize(file.name);
      if (p.posix.isAbsolute(name) || name == '..' || name.startsWith('../')) {
        throw const FormatException('Chemin de ressource invalide');
      }
      final output = File(p.join(root.path, name));
      await output.parent.create(recursive: true);
      await output.writeAsBytes(file.content as List<int>);
    }
    for (final (species, facing) in [
      ('herdier', 'back'),
      ('trubbish', 'front'),
    ]) {
      final relative = 'assets/pokemon/comparator/$species-$facing.gif';
      final sprite = File(p.join(root.path, relative));
      await sprite.parent.create(recursive: true);
      final encoded = await rootBundle.loadString(
        'assets/bw2/$species-$facing.gif.b64',
      );
      await sprite.writeAsBytes(base64Decode(encoded.trim()));
      final media = File(p.join(root.path, 'data/pokemon/media/$species.json'));
      await media.parent.create(recursive: true);
      await media.writeAsString(
        jsonEncode({
          'schemaVersion': 2,
          'speciesId': species,
          'defaultFormId': 'base',
          'variants': {
            'base': {'${facing}Animated': relative},
          },
        }),
      );
    }
    return root;
  } catch (_) {
    await root.delete(recursive: true);
    rethrow;
  }
}

class AttackComparator extends StatelessWidget {
  const AttackComparator({super.key, required this.root, required this.moves});
  final Directory root;
  final List<PreviewMove> moves;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Atelier des attaques',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffaaa0ff),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff111522),
      useMaterial3: true,
    ),
    home: ComparePage(root: root, moves: moves),
  );
}

class ComparePage extends StatefulWidget {
  const ComparePage({super.key, required this.root, required this.moves});
  final Directory root;
  final List<PreviewMove> moves;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late final WebViewController _reference;
  late BattlePreviewGame _game;
  late ValueNotifier<String> _status;
  PreviewMove _move = PreviewMove.tackle;
  String _search = '';
  PhoneOrientation _orientation = PhoneOrientation.portrait;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _status = ValueNotifier('Préparation du combat…');
    _reference = WebViewController();
    _showReference();
    _newGame();
  }

  void _showReference() {
    final url = _move.referenceUrl;
    if (url == null) {
      _reference.loadHtmlString(
        '<html><body style="background:#0b0e16;color:white;font-family:sans-serif">Référence BW non disponible pour cette attaque.</body></html>',
      );
      return;
    }
    _reference.loadHtmlString(
      '''<!doctype html><html><head><meta name="referrer" content="no-referrer"><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body{height:100%;margin:0;background:#0b0e16}body{display:flex;align-items:center;justify-content:center}img{width:100%;height:100%;object-fit:contain;image-rendering:pixelated}</style></head><body><img alt="Référence Noir et Blanc 1 et 2" src="$url?replay=${_version++}"></body></html>''',
    );
  }

  void _newGame() {
    _game = BattlePreviewGame(
      projectRoot: widget.root.path,
      move: _move,
      status: _status,
    );
  }

  void _changeMove(PreviewMove move) {
    setState(() {
      _move = move;
      _status.value = 'Préparation du combat…';
      _newGame();
      _showReference();
    });
  }

  @override
  void dispose() {
    _status.dispose();
    unawaited(
      widget.root.delete(recursive: true).catchError((_) => widget.root),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AVELUNE · ATELIER COMBAT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xffbdb4ff),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Les attaques, en vrai.',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _move.unavailableReason != null
                  ? '${_move.label} : aperçu Avelune indisponible. ${_move.unavailableReason}'
                  : _move == PreviewMove.tackle
                  ? 'Charge : programme BW2 expérimental dans le moteur Avelune. Son enregistré si disponible, synchronisation approximative.'
                  : _move == PreviewMove.surf
                  ? 'Surf : programme BW2 expérimental. Son et rendu à vérifier.'
                  : '${_move.label} : programme BW2 expérimental. Caméra simplifiée ; son enregistré si disponible, synchronisation approximative.'
                        '${_move.approximations.contains('source-variant:first-only') ? ' Cet aperçu ne montre qu’une variante de l’attaque.' : ''}'
                        '${_move.approximations.contains('source-branch:player-side-only') ? ' Seul le côté joueur est disponible dans cet aperçu.' : ''}'
                        '${_move.approximations.contains('source-audio:cry-and-timing-unavailable') ? ' Le cri et sa synchronisation restent à intégrer.' : ''}'
                        '${_move.approximations.contains('background-palette-animation:missing-bank-base') ? ' Une palette manquante est remplacée par les couleurs de base.' : ''}'
                        '${_move.approximations.contains('projection:landscape-interrupts') ? ' En paysage, cette attaque s’interrompt actuellement.' : ''}'
                        '${_move.approximations.contains('source-emitter:orthographic-direction-approximation') ? ' Direction des particules approximative.' : ''}'
                        '${_move.approximations.contains('particle-motion:sinusoid-phase-assumed') ? ' Phase des ondulations à vérifier.' : ''}'
                        '${_move.approximations.contains('source-emitter:scaled-size-clamped') ? ' Taille d’une particule limitée dans cet aperçu.' : ''}'
                        '${_move.approximations.contains('source-actor:camera-mode-approximation') ? ' Orientation des Pokémon par rapport à la caméra approximative.' : ''}'
                        '${_move.approximations.contains('source-emitter:field-motion-calibration') ? ' Trajectoire sur le terrain à ajuster.' : ''}'
                        '${_move.approximations.contains('particle-projection:billboard-center-clipping') ? ' Les particules passant derrière la caméra sont masquées.' : ''}'
                        '${_move.approximations.isEmpty ? '' : ' ${_move.approximations.length} approximation(s) signalée(s).'}',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher une attaque',
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setState(() => _search = value.trim().toLowerCase()),
                  ),
                ),
                const Text('Attaque'),
                DropdownButton<PreviewMove>(
                  key: const ValueKey('attack-select'),
                  value: _move,
                  items: [
                    for (final move in widget.moves.where(
                      (move) =>
                          move == _move ||
                          _search.isEmpty ||
                          move.label.toLowerCase().contains(_search) ||
                          move.id.toLowerCase().contains(_search),
                    ))
                      DropdownMenuItem(value: move, child: Text(move.label)),
                  ],
                  onChanged: (move) {
                    if (move != null && move != _move) _changeMove(move);
                  },
                ),
                FilledButton.icon(
                  key: const ValueKey('play-attack'),
                  onPressed: _move.unavailableReason != null
                      ? null
                      : () async {
                          if (_game.played) {
                            setState(() {
                              _newGame();
                            });
                          }
                          await _game.play(onStart: _showReference);
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Lancer / rejouer'),
                ),
                const Text('Format iPhone 15 Pro'),
                SegmentedButton<PhoneOrientation>(
                  segments: [
                    for (final orientation in PhoneOrientation.values)
                      ButtonSegment(
                        value: orientation,
                        icon: Icon(orientation.icon),
                        label: Text(orientation.label),
                      ),
                  ],
                  selected: {_orientation},
                  onSelectionChanged: (selection) {
                    setState(() => _orientation = selection.single);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PreviewPanel(
                      eyebrow: 'LA RÉFÉRENCE',
                      title: 'Pokémon Noir & Blanc 1 et 2',
                      child: WebViewWidget(controller: _reference),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PreviewPanel(
                      eyebrow: 'LE MOTEUR EN DIRECT',
                      title: 'Avelune · aperçu macOS',
                      aspectRatio: _orientation.size.aspectRatio,
                      child: FittedBox(
                        child: SizedBox.fromSize(
                          size: _orientation.size,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: _orientation.size,
                              devicePixelRatio: 3,
                              padding: EdgeInsets.zero,
                              viewPadding: EdgeInsets.zero,
                              viewInsets: EdgeInsets.zero,
                              systemGestureInsets: EdgeInsets.zero,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GameWidget(key: ObjectKey(_game), game: _game),
                                ValueListenableBuilder<
                                  BattleCommandOverlaySnapshot?
                                >(
                                  valueListenable: _game.snapshot,
                                  builder: (context, snapshot, _) =>
                                      snapshot == null
                                      ? const SizedBox.shrink()
                                      : Theme(
                                          data: PokeMapPlayerTheme.dark()
                                              .copyWith(
                                                platform: TargetPlatform.iOS,
                                              ),
                                          child: IgnorePointer(
                                            child: PlayerBattleOverlay(
                                              snapshot: snapshot,
                                              onCommand: _game
                                                  .handlePresentationCommand,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String>(
              valueListenable: _status,
              builder: (context, status, _) => Text(
                status,
                key: const ValueKey('preview-status'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Référence APNG sans son : Bulbagarden, en ligne · '
              'Décor de test HGSS · Synchronisation non garantie',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: const Color(0xff9ca6c2)),
            ),
          ],
        ),
      ),
    ),
  );
}

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
    this.aspectRatio = 4 / 3,
  });
  final String eyebrow;
  final String title;
  final Widget child;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xff1a1f30),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xff343b52)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: const Color(0xffaab3cf), letterSpacing: 1.2),
          ),
          const SizedBox(height: 3),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: const Color(0xff0b0e16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: ClipRect(child: child),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
