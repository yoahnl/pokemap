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
  })  : _loadSheet = loadSheet,
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

  final Map<String, Image> _sheetImages = <String, Image>{};
  var _phaseIndex = 0;
  var _phaseElapsed = 0.0;
  var _blackHeldNotified = false;
  var _revealing = false;
  var _revealElapsed = 0.0;
  var _ready = false;

  Color _screenColor = const Color(0x00000000);
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
      if (phase is! TransitionSheetCellsPhase) continue;
      if (_sheetImages.containsKey(phase.sheetName)) continue;
      final image = await _resolveSheetImage(phase.sheetName);
      if (image != null) {
        _sheetImages[phase.sheetName] = image;
      }
    }
    _ready = true;
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
    if (_screenColor.a > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = _screenColor,
      );
    }
  }
}
