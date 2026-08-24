import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

import 'battle_transition_manifest.dart';
import 'battle_transition_spec.dart';

/// La pré-transition de début de combat — BETA-BAT-016.
///
/// Remplace le bouchon « écran noir + texte » par la séquence de la
/// référence, jouée PAR-DESSUS la carte encore rendue : flash sinusoïdal,
/// planche de cellules, écran noir tenu. Pas de capture d'écran : la carte
/// est déjà gelée par le verrou d'input de la phase `battleTransition`, la
/// laisser vivre sous l'overlay est visuellement équivalent et esquive le
/// risque « gel Flame non vérifié » du ticket.
///
/// Cycle en trois temps, piloté par le jeu :
/// 1. les phases du [spec] se jouent, puis l'écran reste noir et
///    [onBlackHeld] est notifié une seule fois ;
/// 2. le jeu monte la scène de combat sous le noir ;
/// 3. [revealAndDismiss] fond le noir sur [revealSeconds] puis retire
///    l'overlay et notifie [onDismissed].
///
/// Une planche introuvable saute sa phase au lieu de casser l'entrée en
/// combat : l'écran va au noir et la séquence continue (critère 2).
class BattleTransitionOverlayComponent extends PositionComponent {
  BattleTransitionOverlayComponent({
    required this.spec,
    required Vector2 viewportSize,
    required this.onBlackHeld,
    this.onDismissed,
    this.revealSeconds = 0.25,
    @visibleForTesting Future<Image?> Function(String sheetName)? loadSheet,
    @visibleForTesting Future<FragmentProgram?> Function()? loadDissolveProgram,
  })  : _loadSheet = loadSheet,
        _loadDissolveProgram = loadDissolveProgram,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          // Recette 2026-08-23 (vidéo 19-51-35) : la scène de combat vit à 97
          // et se monte SOUS le noir pendant que la pré-transition joue — à
          // 96, flash, planche et noir jouaient intégralement DERRIÈRE elle.
          // 101 couvre le combat (97), le post-combat (99) et le dialogue
          // (100) : rien ne perce le rideau pendant l'entrée en combat.
          priority: 101,
        );

  final BattleTransitionSpec spec;
  final VoidCallback onBlackHeld;
  final VoidCallback? onDismissed;
  final double revealSeconds;
  final Future<Image?> Function(String sheetName)? _loadSheet;
  final Future<FragmentProgram?> Function()? _loadDissolveProgram;

  /// Le programme du threshold dissolve, charge une fois pour tout le
  /// process — BETA-BAT-019 lot shaders. Null tant qu'il n'est pas pret ou
  /// si la plateforme ne le compile pas : le rendu retombe alors sur un
  /// fondu noir simple, l'entree en combat ne casse jamais.
  static Future<FragmentProgram?>? _dissolveProgramFuture;
  FragmentProgram? _dissolveProgram;
  FragmentShader? _dissolveShader;

  final Map<String, Image> _sheetImages = <String, Image>{};
  var _phaseIndex = 0;
  var _phaseElapsed = 0.0;
  var _blackHeldNotified = false;
  var _revealing = false;
  var _revealElapsed = 0.0;
  var _ready = false;

  Color _screenColor = const Color(0x00000000);
  var _bandsActive = false;
  var _bandsProgress = 0.0;
  var _bandsBandHeight = 3.0;
  var _dissolveActive = false;
  var _dissolveT = 0.0;
  var _dissolveFine = false;
  Image? _dissolveTexture;
  Image? _visibleSheet;
  int _visibleColumns = 1;
  int _visibleRows = 1;
  int _visibleCellIndex = 0;
  double _sheetZoomFactor = 1;
  double _sheetAngleDegrees = 0;

  bool get isHoldingBlack => _blackHeldNotified && !_revealing;

  @visibleForTesting
  int get debugPhaseIndex => _phaseIndex;

  @visibleForTesting
  bool get debugReady => _ready;

  @visibleForTesting
  double get debugScreenAlpha => _screenColor.a;

  @override
  Future<void> onLoad() async {
    for (final phase in spec.phases) {
      final sheetName = switch (phase) {
        TransitionSheetCellsPhase(:final sheetName) => sheetName,
        TransitionThresholdDissolvePhase(:final textureName) => textureName,
        _ => null,
      };
      if (sheetName == null || _sheetImages.containsKey(sheetName)) continue;
      final image = await _resolveSheetImage(sheetName);
      if (image != null) {
        _sheetImages[sheetName] = image;
      }
    }
    if (spec.phases.any((p) => p is TransitionThresholdDissolvePhase)) {
      _dissolveProgram = await _resolveDissolveProgram();
      if (_dissolveProgram != null) {
        _dissolveShader = _dissolveProgram!.fragmentShader();
      }
    }
    _ready = true;
  }

  Future<FragmentProgram?> _resolveDissolveProgram() async {
    final loader = _loadDissolveProgram;
    if (loader != null) return loader();
    // Double essai comme les planches : la cle prefixee `packages/` vaut
    // quand map_runtime est une dependance, la cle nue quand il est le
    // paquet hote. Un echec rend null : le fondu simple prend le relais.
    return _dissolveProgramFuture ??= () async {
      const candidates = <String>[
        'packages/map_runtime/shaders/battle_transition_dissolve.frag',
        'shaders/battle_transition_dissolve.frag',
      ];
      for (final assetKey in candidates) {
        try {
          return await FragmentProgram.fromAsset(assetKey);
        } on Object {
          continue;
        }
      }
      debugPrint('[battle-transition] dissolve shader unavailable, '
          'falling back to a plain fade');
      return null;
    }();
  }

  Future<Image?> _resolveSheetImage(String sheetName) async {
    final loader = _loadSheet;
    if (loader != null) {
      return loader(sheetName);
    }
    final fileName = battleTransitionSheetManifest[sheetName];
    if (fileName == null) {
      debugPrint('[battle-transition] no embedded sheet for "$sheetName"');
      return null;
    }
    // Double essai comme le catalogue RMXP : la clé préfixée `packages/` vaut
    // quand map_runtime est une dépendance, la clé nue quand il est le
    // paquet hôte (ses propres tests notamment). rootBundle et pas
    // Flame.images : le cache Flame préfixe tout de `assets/images/`.
    ByteData? bytes;
    try {
      bytes = await rootBundle
          .load('packages/map_runtime/assets/transitions/$fileName');
    } on Object {
      try {
        bytes = await rootBundle.load('assets/transitions/$fileName');
      } on Object catch (error) {
        // Une planche illisible ne doit jamais casser l'entrée en combat :
        // la phase est sautée et l'écran ira au noir (critère 2 du ticket).
        debugPrint('[battle-transition] failed to load "$sheetName": $error');
        return null;
      }
    }
    try {
      final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } on Object catch (error) {
      debugPrint('[battle-transition] failed to decode "$sheetName": $error');
      return null;
    }
  }

  /// Saute directement à l'état « noir tenu » et notifie [onBlackHeld] —
  /// pour les tests qui doivent ouvrir la fenêtre de course entre le noir de
  /// la pré-transition et la fin du montage de la scène (recette du
  /// 2026-08-24 : le rideau tombait sur une scène pas encore chargée).
  @visibleForTesting
  void debugHoldBlackNowForTest() {
    if (_blackHeldNotified) return;
    _phaseIndex = spec.phases.length;
    _phaseElapsed = 0;
    _screenColor = const Color(0xFF000000);
    _visibleSheet = null;
    _blackHeldNotified = true;
    Future<void>.microtask(onBlackHeld);
  }

  /// Fond le noir et retire l'overlay. Appelé par le jeu quand la scène de
  /// combat est montée sous le noir. Ignoré tant que le noir n'est pas tenu.
  void revealAndDismiss() {
    if (!isHoldingBlack) return;
    _revealing = true;
    _revealElapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;
    if (_revealing) {
      _revealElapsed += dt;
      final progress = revealSeconds <= 0
          ? 1.0
          : (_revealElapsed / revealSeconds).clamp(0.0, 1.0);
      _screenColor = Color.fromARGB(
        (255 * (1 - progress)).round(),
        0,
        0,
        0,
      );
      if (progress >= 1) {
        _revealing = false;
        // Tout en microtask : retirer ou notifier en pleine itération
        // updateTree muterait l'arbre des composants pendant son parcours.
        Future<void>.microtask(() {
          removeFromParent();
          onDismissed?.call();
        });
      }
      return;
    }
    if (_blackHeldNotified) return;

    while (_phaseIndex < spec.phases.length) {
      final phase = spec.phases[_phaseIndex];
      if (phase is TransitionSheetCellsPhase &&
          !_sheetImages.containsKey(phase.sheetName)) {
        _phaseIndex += 1;
        _phaseElapsed = 0;
        continue;
      }
      final duration = phase.durationSeconds;
      _phaseElapsed += dt;
      final progress =
          duration <= 0 ? 1.0 : (_phaseElapsed / duration).clamp(0.0, 1.0);
      _applyPhase(phase, progress);
      if (_phaseElapsed < duration) {
        return;
      }
      dt = _phaseElapsed - duration;
      _phaseIndex += 1;
      _phaseElapsed = 0;
    }

    _screenColor = const Color(0xFF000000);
    _visibleSheet = null;
    if (!_blackHeldNotified) {
      _blackHeldNotified = true;
      // Différé pour la même raison : le jeu répond en montant/démarrant des
      // composants, ce qui ne doit jamais arriver au milieu d'updateTree.
      Future<void>.microtask(onBlackHeld);
    }
  }

  void _applyPhase(BattleTransitionPhase phase, double progress) {
    _bandsActive = false;
    _dissolveActive = false;
    switch (phase) {
      case TransitionFlashPhase(:final factor):
        // Parité `create_flash_animation` : x parcourt 0 → factor·π, l'écran
        // est blanc quand sin(x) > 0, l'alpha suit sin²(x) × 180.
        final x = progress * factor * math.pi;
        final sin = math.sin(x);
        final channel = sin.ceil().clamp(0, 1) * 255;
        final alpha = ((sin * sin * 100).roundToDouble() / 100 * 180).toInt();
        _screenColor = Color.fromARGB(alpha, channel, channel, channel);
      case TransitionSpriteZoomPhase(:final zoomFrom):
        _ensureFirstSheetVisible();
        _sheetZoomFactor = zoomFrom + (1 - zoomFrom) * progress;
        _screenColor = const Color(0x00000000);
      case TransitionSpriteAnglePhase(
          :final angleFromDegrees,
          :final angleToDegrees
        ):
        _ensureFirstSheetVisible();
        _sheetAngleDegrees =
            angleFromDegrees + (angleToDegrees - angleFromDegrees) * progress;
        _screenColor = const Color(0x00000000);
      case TransitionSheetCellsPhase(
          :final sheetName,
          :final columns,
          :final rows
        ):
        _visibleSheet = _sheetImages[sheetName];
        _visibleColumns = columns;
        _visibleRows = rows;
        final cellCount = columns * rows;
        _visibleCellIndex =
            (progress * cellCount).floor().clamp(0, cellCount - 1);
        _screenColor = const Color(0x00000000);
      case TransitionHoldBlackPhase():
        _visibleSheet = null;
        _screenColor = const Color(0xFF000000);
      case TransitionFadeToBlackPhase():
        _visibleSheet = null;
        _screenColor = Color.fromARGB((255 * progress).round(), 0, 0, 0);
      case TransitionThresholdDissolvePhase(
          :final textureName,
          :final tFrom,
          :final tTo,
          :final fineThreshold,
        ):
        _visibleSheet = null;
        _screenColor = const Color(0x00000000);
        _dissolveActive = true;
        _dissolveT = tFrom + (tTo - tFrom) * progress;
        _dissolveFine = fineThreshold;
        _dissolveTexture = _sheetImages[textureName];
      case TransitionInterleavedBandsPhase(:final bandHeight):
        // Parité RSWild/DPPWild adaptée : la référence fait glisser les
        // lignes de l'écran hors champ en révélant le noir ; ici les bandes
        // noires entrelacées entrent des deux côtés jusqu'au noir complet.
        _visibleSheet = null;
        _screenColor = const Color(0x00000000);
        _bandsActive = true;
        _bandsProgress = progress;
        _bandsBandHeight = bandHeight;
    }
  }

  /// La pokéball DPP est visible dès le zoom, cellule 0, avant le défilement.
  void _ensureFirstSheetVisible() {
    if (_visibleSheet != null) return;
    for (final phase in spec.phases) {
      if (phase is! TransitionSheetCellsPhase) continue;
      final image = _sheetImages[phase.sheetName];
      if (image == null) return;
      _visibleSheet = image;
      _visibleColumns = phase.columns;
      _visibleRows = phase.rows;
      _visibleCellIndex = 0;
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sheet = _visibleSheet;
    if (sheet != null) {
      final cellWidth = sheet.width / _visibleColumns;
      final cellHeight = sheet.height / _visibleRows;
      final column = _visibleCellIndex % _visibleColumns;
      final row = _visibleCellIndex ~/ _visibleColumns;
      final src = Rect.fromLTWH(
        column * cellWidth,
        row * cellHeight,
        cellWidth,
        cellHeight,
      );
      final fitZoom = size.x / cellWidth;
      final zoom = fitZoom * _sheetZoomFactor;
      final destWidth = cellWidth * zoom;
      final destHeight = cellHeight * zoom;
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      if (_sheetAngleDegrees != 0) {
        canvas.rotate(_sheetAngleDegrees * math.pi / 180);
      }
      final dest = Rect.fromCenter(
        center: Offset.zero,
        width: destWidth,
        height: destHeight,
      );
      canvas.drawImageRect(
        sheet,
        src,
        dest,
        Paint()..filterQuality = FilterQuality.none,
      );
      canvas.restore();
    }
    if (_dissolveActive) {
      final shader = _dissolveShader;
      final texture = _dissolveTexture;
      if (shader != null && texture != null) {
        shader
          ..setFloat(0, size.x)
          ..setFloat(1, size.y)
          ..setFloat(2, _dissolveT)
          ..setFloat(3, _dissolveFine ? 1.0 : 0.0)
          ..setImageSampler(0, texture);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..shader = shader,
        );
      } else {
        // Repli sans shader : un fondu noir simple qui suit la meme horloge.
        final alpha = (_dissolveT.clamp(0.0, 1.0) * 255).round();
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..color = Color.fromARGB(alpha, 0, 0, 0),
        );
      }
    }
    if (_bandsActive && _bandsProgress > 0) {
      final paint = Paint()..color = const Color(0xFF000000);
      final bandWidth = size.x * _bandsProgress.clamp(0.0, 1.0);
      final bandHeight = _bandsBandHeight <= 0 ? 3.0 : _bandsBandHeight;
      var index = 0;
      for (var y = 0.0; y < size.y; y += bandHeight, index += 1) {
        final left = index.isEven ? 0.0 : size.x - bandWidth;
        canvas.drawRect(
          Rect.fromLTWH(left, y, bandWidth, bandHeight),
          paint,
        );
      }
    }
    if (_screenColor.a > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = _screenColor,
      );
    }
  }
}
