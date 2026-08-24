import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Les moments de la séquence de capture que l'hôte doit accompagner —
/// sons et absorption/libération du Pokémon visé.
enum BattleBallCaptureCue {
  /// La Ball s'est ouverte au-dessus de la cible : le Pokémon rétrécit.
  absorb,

  /// La Ball se referme sur sa prise (le son d'ouverture de la référence).
  close,

  /// La Ball touche le sol pendant sa chute amortie (trois fois).
  bounce,

  /// Une secousse démarre.
  shake,

  /// Le verdict : le clic de verrouillage ou l'éclatement.
  verdict,

  /// L'échec libère le Pokémon : il réapparaît.
  release,
}

/// La Poké Ball d'une tentative de capture — BETA-BAT-025.
///
/// Parité `show_catch_animation` (206 Show_stuff.rb) et cellules de
/// `UI::ThrowingBallSprite` (700 ThrowingBallSprite.rb) : lancer en arc
/// 0,4 s (cellules 0-3), ouverture 0,2 s (4-5), absorption 0,2 s (la cible
/// rétrécit chez l'hôte), fermeture 0,5 s (6-14 puis 3), chute amortie 1 s
/// (rebonds |cos(2,5πx)·e^(-2x)|, trois sons), pause 0,5 s, puis [shakes]
/// secousses (cellules 17-16-15-16-17-18-19-18-17 sur 0,5 s + 0,5 s de
/// pause), et le verdict 0,5 s : verrouillage (27-31 puis 17, la Ball reste
/// posée) ou éclatement (20-26, la cible réapparaît et la Ball se retire).
///
/// Le composant est autonome : il ne pilote que la Ball et notifie [onCue]
/// aux instants exacts — l'hôte joue les sons et les motions du combattant.
class BattleBallCaptureComponent extends PositionComponent {
  BattleBallCaptureComponent({
    required this.sheet,
    required this.shakes,
    required this.caught,
    required Offset targetCenter,
    required double throwStartX,
    this.cellSize = 26,
    this.onCue,
    int priority = 50,
  })  : _targetCenter = targetCenter,
        _throwStartX = throwStartX,
        super(
          position: Vector2(throwStartX, targetCenter.dy),
          anchor: Anchor.center,
          priority: priority,
        );

  static const int _cellRows = 32;
  static const double _throwSeconds = 0.4;
  static const double _openSeconds = 0.2;
  static const double _absorbSeconds = 0.2;
  static const double _closeSeconds = 0.5;
  static const double _fallSeconds = 1.0;
  static const double _restSeconds = 0.5;
  static const double _shakeSeconds = 0.5;
  static const double _shakeRestSeconds = 0.5;
  static const double _verdictSeconds = 0.5;
  static const double _releaseSeconds = 0.2;

  /// Les cellules d'une secousse, dans l'ordre exact de la référence.
  static const List<int> _shakeCells = <int>[17, 16, 15, 16, 17, 18, 19, 18, 17];

  final Image sheet;
  final int shakes;
  final bool caught;
  final Offset _targetCenter;
  final double _throwStartX;

  /// La taille de rendu d'une cellule en pixels logiques de la scène.
  final double cellSize;

  final void Function(BattleBallCaptureCue cue)? onCue;

  var _elapsed = 0.0;
  var _cellIndex = 0;
  var _removalScheduled = false;
  final Set<Object> _firedCues = <Object>{};

  /// Le zoom de la référence : la cellule 64 dessinée à [cellSize].
  double get _scale => cellSize / 64;

  /// Le point de vol : la Ball plane au-dessus de la cible, l'offset
  /// dresseur de la référence (40 px à l'échelle de la cellule).
  Offset get _hoverCenter =>
      Offset(_targetCenter.dx, _targetCenter.dy - 40 * _scale);

  /// Le point de repos au sol, sous le centre de la cible.
  Offset get _restCenter =>
      Offset(_targetCenter.dx, _targetCenter.dy + 24 * _scale);

  void _fireOnce(Object key, BattleBallCaptureCue cue) {
    if (!_firedCues.add(key)) return;
    onCue?.call(cue);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    var t = _elapsed;

    if (t < _throwSeconds) {
      final progress = (t / _throwSeconds).clamp(0.0, 1.0);
      // Parité `SQUARE010_DISTORTION` : 0 aux extrémités, 1 au sommet.
      final lift = 1 - math.pow(2 * progress - 1, 2).toDouble();
      position = Vector2(
        _throwStartX + (_hoverCenter.dx - _throwStartX) * progress,
        _hoverCenter.dy - 64 * _scale * lift,
      );
      _cellIndex = (progress * 4).floor().clamp(0, 3);
      return;
    }
    position = Vector2(_hoverCenter.dx, _hoverCenter.dy);
    t -= _throwSeconds;

    if (t < _openSeconds) {
      _cellIndex = (t / _openSeconds * 2).floor().clamp(0, 1) + 4;
      return;
    }
    t -= _openSeconds;

    if (t < _absorbSeconds) {
      _fireOnce(BattleBallCaptureCue.absorb, BattleBallCaptureCue.absorb);
      _cellIndex = 5;
      return;
    }
    t -= _absorbSeconds;

    if (t < _closeSeconds) {
      _fireOnce(BattleBallCaptureCue.close, BattleBallCaptureCue.close);
      final target = (t / _closeSeconds * 9).floor();
      _cellIndex = target >= 9 ? 3 : target + 6;
      return;
    }
    t -= _closeSeconds;

    if (t < _fallSeconds) {
      final progress = (t / _fallSeconds).clamp(0.0, 1.0);
      // Parité `fall_distortion` : |cos(2,5πx)·e^(-2x)| — 1 au départ
      // (la Ball plane), 0 à l'arrivée, et trois passages par zéro qui sont
      // les rebonds au sol (x = 0,2 ; 0,6 ; 1,0).
      final bounceEnvelope =
          (math.cos(2.5 * math.pi * progress) * math.exp(-2 * progress)).abs();
      position = Vector2(
        _restCenter.dx,
        _restCenter.dy + (_hoverCenter.dy - _restCenter.dy) * bounceEnvelope,
      );
      for (final bounceAt in const <double>[0.2, 0.6, 1.0]) {
        if (progress >= bounceAt) {
          _fireOnce('bounce-$bounceAt', BattleBallCaptureCue.bounce);
        }
      }
      _cellIndex = 3;
      return;
    }
    position = Vector2(_restCenter.dx, _restCenter.dy);
    t -= _fallSeconds;

    if (t < _restSeconds) {
      _fireOnce('bounce-1.0', BattleBallCaptureCue.bounce);
      _cellIndex = 3;
      return;
    }
    t -= _restSeconds;

    final shakesDuration = shakes * (_shakeSeconds + _shakeRestSeconds);
    if (t < shakesDuration) {
      final shakeIndex = t ~/ (_shakeSeconds + _shakeRestSeconds);
      final within = t - shakeIndex * (_shakeSeconds + _shakeRestSeconds);
      _fireOnce('shake-$shakeIndex', BattleBallCaptureCue.shake);
      if (within < _shakeSeconds) {
        final progress = (within / _shakeSeconds).clamp(0.0, 1.0);
        _cellIndex = _shakeCells[
            (progress * 8).floor().clamp(0, _shakeCells.length - 1)];
      } else {
        // La référence laisse la dernière cellule affichée entre deux
        // secousses.
        _cellIndex = _shakeCells.last;
      }
      return;
    }
    t -= shakesDuration;

    _fireOnce(BattleBallCaptureCue.verdict, BattleBallCaptureCue.verdict);
    if (t < _verdictSeconds) {
      final progress = (t / _verdictSeconds).clamp(0.0, 1.0);
      if (caught) {
        final target = (progress * 5).floor();
        _cellIndex = target >= 5 ? 17 : 27 + target;
      } else {
        _cellIndex = (progress * 7).floor().clamp(0, 6) + 20;
      }
      return;
    }

    if (caught) {
      // La Ball verrouillée reste posée à l'écran, comme la référence : le
      // message de capture s'affiche avec elle, et l'overlay l'emporte au
      // démontage du combat.
      _cellIndex = 17;
      return;
    }
    _fireOnce(BattleBallCaptureCue.release, BattleBallCaptureCue.release);
    if (!_removalScheduled &&
        t >= _verdictSeconds + _releaseSeconds) {
      _removalScheduled = true;
      // En microtask : se retirer en pleine itération updateTree muterait
      // l'arbre des composants pendant son parcours (le piège de BAT-016).
      Future<void>.microtask(removeFromParent);
    }
    _cellIndex = 26;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cellHeight = sheet.height / _cellRows;
    final cellWidth = sheet.width.toDouble();
    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH(0, _cellIndex * cellHeight, cellWidth, cellHeight),
      Rect.fromCenter(
        center: Offset.zero,
        width: cellSize,
        height: cellSize,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @visibleForTesting
  int get debugCellIndex => _cellIndex;
}
