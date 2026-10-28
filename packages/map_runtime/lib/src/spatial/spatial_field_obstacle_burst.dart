import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

final class SpatialFieldObstacleBurst {
  SpatialFieldObstacleBurst(this.budget);

  final RuntimeResourceBudget budget;
  final _textures = <FieldAbility, SpatialActorTexture>{};
  final _reservations = <RuntimeResourceReservation>[];
  FieldAbility? _ability;
  double _x = 0, _y = 0, _z = 0, _elapsed = 0;
  String? _mapId;
  bool _disposed = false;

  Future<void> prepare() async {
    for (final ability in [FieldAbility.cut, FieldAbility.rockSmash]) {
      if (_textures.containsKey(ability)) continue;
      final lease = await budget.acquire(
        residentBytes: 256,
        isCurrent: () => !_disposed,
      );
      try {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final leaf = ability == FieldAbility.cut;
        final path = ui.Path()
          ..moveTo(1, 4)
          ..lineTo(4, 0)
          ..lineTo(7, 3)
          ..lineTo(5, 8)
          ..close();
        canvas.drawPath(
          path,
          ui.Paint()..color = ui.Color(leaf ? 0xff84a748 : 0xff928477),
        );
        canvas.drawLine(
          const ui.Offset(2, 5),
          const ui.Offset(6, 2),
          ui.Paint()
            ..color = ui.Color(leaf ? 0xff486332 : 0xff534b43)
            ..strokeWidth = 1,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(8, 8);
        picture.dispose();
        try {
          final texture = await SpatialActorTexture.fromImage(image);
          lease.ensureCurrent();
          _textures[ability] = texture;
          lease.commit();
          _reservations.add(lease);
        } finally {
          image.dispose();
        }
      } on Object {
        lease.release();
        rethrow;
      }
    }
  }

  void start(
    FieldAbility ability, {
    required String mapId,
    required double x,
    required double y,
    required double z,
  }) {
    if (_disposed || !_textures.containsKey(ability)) return;
    _ability = ability;
    _mapId = mapId;
    _x = x;
    _y = y;
    _z = z;
    _elapsed = 0;
  }

  Map<String, SpatialActorVisual> frames(
    double dt, {
    required String mapId,
    bool paused = false,
  }) {
    if (_disposed || _ability == null) return const {};
    if (mapId != _mapId) {
      _ability = null;
      return const {};
    }
    if (!paused && dt.isFinite && dt > 0) _elapsed += dt;
    if (_elapsed >= .55) {
      _ability = null;
      return const {};
    }
    final t = _elapsed;
    return {
      for (var i = 0; i < 8; i++)
        'field-obstacle-debris:$i': SpatialActorVisual(
          x: _x + math.cos(i * 2.39996) * t * 1.1,
          z: _z + math.sin(i * 2.39996) * t * 1.1,
          y: _y + .3 + (1.4 + (i % 3) * .2) * t - 3 * t * t,
          texture: _textures[_ability]!,
          frame: const ui.Rect.fromLTWH(0, 0, 8, 8),
          width: .12 * (1 - t),
          height: .16 * (1 - t),
        ),
    };
  }

  void dispose() {
    _disposed = true;
    _ability = null;
    _textures.clear();
    for (final reservation in _reservations) {
      reservation.release();
    }
    _reservations.clear();
  }
}
