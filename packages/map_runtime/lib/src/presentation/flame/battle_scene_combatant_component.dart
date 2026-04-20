import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/tile_image_loader.dart';
import 'battle_pokemon_sprite_resolver.dart';

class BattleSceneCombatantComponent extends PositionComponent {
  BattleSceneCombatantComponent({
    required Rect sceneSpriteRect,
    required Rect scenePlatformRect,
    required Offset sceneFootAnchor,
    required this.isPlayerSide,
    required String speciesLabel,
    BattleCombatantSpriteSpec initialSpriteSpec =
        const BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
    ),
  })  : _speciesLabel = speciesLabel,
        _spriteSpec = initialSpriteSpec,
        _spriteRect = _toLocalRect(
          sceneSpriteRect,
          _sceneBounds(sceneSpriteRect, scenePlatformRect),
        ),
        _platformRect = _toLocalRect(
          scenePlatformRect,
          _sceneBounds(sceneSpriteRect, scenePlatformRect),
        ),
        _footAnchor = _toLocalOffset(
          sceneFootAnchor,
          _sceneBounds(sceneSpriteRect, scenePlatformRect),
        ),
        super(
          position: Vector2(
            _sceneBounds(sceneSpriteRect, scenePlatformRect).left,
            _sceneBounds(sceneSpriteRect, scenePlatformRect).top,
          ),
          size: Vector2(
            _sceneBounds(sceneSpriteRect, scenePlatformRect).width,
            _sceneBounds(sceneSpriteRect, scenePlatformRect).height,
          ),
          anchor: Anchor.topLeft,
          priority: 10,
        );

  final bool isPlayerSide;

  String _speciesLabel;
  BattleCombatantSpriteSpec _spriteSpec;
  final Rect _spriteRect;
  final Rect _platformRect;
  final Offset _footAnchor;
  ui.Image? _spriteImage;
  Rect? _spriteOpaqueSourceRect;
  String? _spriteSourcePath;
  String? _pendingSpriteSourcePath;
  bool _didSpriteLoadFail = false;
  TextComponent? _speciesText;
  TextComponent? _monogramText;

  @visibleForTesting
  bool get hasResolvedExplicitSprite => _spriteImage != null;

  @visibleForTesting
  bool get didExplicitSpriteLoadFail => _didSpriteLoadFail;

  @visibleForTesting
  String? get currentSpriteSourcePath => _spriteSourcePath;

  @visibleForTesting
  bool get belongsToPlayerSide => isPlayerSide;

  @visibleForTesting
  String get currentSpeciesLabel => _speciesLabel;

  @visibleForTesting
  Rect get currentSpriteRect =>
      _spriteRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect get currentPlatformRect =>
      _platformRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Offset get currentFootAnchor => _footAnchor.translate(position.x, position.y);

  @override
  Future<void> onLoad() async {
    _speciesText = TextComponent(
      text: _speciesLabel,
      position: Vector2(_spriteRect.left + 8, size.y - 4),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF8FBFF),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 13,
    );
    await add(_speciesText!);

    _monogramText = TextComponent(
      text: _speciesMonogram(_speciesLabel),
      position: Vector2(_spriteRect.center.dx, _spriteRect.center.dy),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xF8FFFFFF),
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
      priority: 13,
    );
    await add(_monogramText!);
    await _syncSpriteImage();
  }

  Future<void> sync({
    required String speciesLabel,
    required BattleCombatantSpriteSpec spriteSpec,
  }) async {
    _speciesLabel = speciesLabel;
    _spriteSpec = spriteSpec;
    await _syncSpriteImage();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawOval(
      _platformRect,
      Paint()
        ..color =
            isPlayerSide ? const Color(0x4431261A) : const Color(0x8B5E4E34),
    );
    canvas.drawOval(
      _platformRect.deflate(isPlayerSide ? 4 : 5),
      Paint()
        ..color =
            isPlayerSide ? const Color(0x7A8E7B61) : const Color(0xFFD8C59E),
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(
        _platformRect.center.dx,
        _platformRect.center.dy - (_platformRect.height * 0.75),
      ),
      width: _platformRect.width * (isPlayerSide ? 0.6 : 0.48),
      height: _platformRect.height * 1.25,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = const Color(0x33000000),
    );

    final auraRect = Rect.fromCenter(
      center: Offset(
        _spriteRect.center.dx,
        _spriteRect.center.dy -
            (_spriteRect.height * (isPlayerSide ? 0.02 : 0.04)),
      ),
      width: _spriteRect.width * (isPlayerSide ? 0.78 : 0.72),
      height: _spriteRect.height * 0.6,
    );
    canvas.drawOval(
      auraRect,
      Paint()
        ..shader = RadialGradient(
          colors: isPlayerSide
              ? const <Color>[
                  Color(0x667AA9F4),
                  Color(0x00000000),
                ]
              : const <Color>[
                  Color(0x66B9D27A),
                  Color(0x00000000),
                ],
        ).createShader(auraRect),
    );

    if (_spriteImage != null) {
      _renderSprite(canvas);
      return;
    }

    _renderSilhouette(canvas);
  }

  Future<void> _syncSpriteImage() async {
    final explicitImagePath = _spriteSpec.explicitImageAbsolutePath?.trim();
    _pendingSpriteSourcePath = explicitImagePath;
    if (explicitImagePath == null || explicitImagePath.isEmpty) {
      _spriteImage = null;
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = null;
      _didSpriteLoadFail = false;
      _syncTextVisibility();
      return;
    }
    if (_spriteImage != null && _spriteSourcePath == explicitImagePath) {
      _syncTextVisibility();
      return;
    }

    try {
      final image = await loadImageFromFilePath(explicitImagePath);
      if (_pendingSpriteSourcePath != explicitImagePath) {
        return;
      }
      _spriteImage = image;
      _spriteOpaqueSourceRect = await _computeOpaqueSourceRect(image);
      _spriteSourcePath = explicitImagePath;
      _didSpriteLoadFail = false;
      _syncTextVisibility();
    } catch (_) {
      if (_pendingSpriteSourcePath != explicitImagePath) {
        return;
      }
      _spriteImage = null;
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = explicitImagePath;
      _didSpriteLoadFail = true;
      _syncTextVisibility();
    }
  }

  void _renderSprite(Canvas canvas) {
    final image = _spriteImage!;
    final inputSubrect = _spriteOpaqueSourceRect ??
        (Offset.zero &
            Size(
              image.width.toDouble(),
              image.height.toDouble(),
            ));
    final fitted =
        applyBoxFit(BoxFit.contain, inputSubrect.size, _spriteRect.size);
    final outputSubrect = Alignment.bottomCenter.inscribe(
      fitted.destination,
      _spriteRect,
    );
    canvas.drawImageRect(
      image,
      inputSubrect,
      outputSubrect,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  void _renderSilhouette(Canvas canvas) {
    final primaryColor =
        isPlayerSide ? const Color(0xFF3E4B7E) : const Color(0xFF6B87B7);
    final secondaryColor =
        isPlayerSide ? const Color(0xFF7DB4F7) : const Color(0xFFD7E8FF);

    final spriteRect = _spriteRect;
    final bodyRect = Rect.fromCenter(
      center: Offset(
        spriteRect.left + (spriteRect.width * (isPlayerSide ? 0.42 : 0.6)),
        spriteRect.top + (spriteRect.height * (isPlayerSide ? 0.46 : 0.44)),
      ),
      width: spriteRect.width * (isPlayerSide ? 0.42 : 0.28),
      height: spriteRect.height * (isPlayerSide ? 0.48 : 0.36),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(34)),
      Paint()..color = primaryColor,
    );

    final chestRect = Rect.fromCenter(
      center: Offset(
        size.x * (isPlayerSide ? 0.44 : 0.62),
        size.y * (isPlayerSide ? 0.48 : 0.46),
      ),
      width: bodyRect.width * 0.72,
      height: bodyRect.height * 0.68,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(28)),
      Paint()..color = secondaryColor.withValues(alpha: 0.88),
    );

    final headRect = Rect.fromCircle(
      center: Offset(
        spriteRect.left + (spriteRect.width * (isPlayerSide ? 0.36 : 0.56)),
        spriteRect.top + (spriteRect.height * (isPlayerSide ? 0.21 : 0.23)),
      ),
      radius: isPlayerSide ? spriteRect.width * 0.11 : spriteRect.width * 0.085,
    );
    canvas.drawOval(
      headRect,
      Paint()..color = secondaryColor,
    );

    final accentPath = Path();
    if (isPlayerSide) {
      accentPath
        ..moveTo(
          spriteRect.left + (spriteRect.width * 0.3),
          spriteRect.top + (spriteRect.height * 0.44),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.14),
          spriteRect.top + (spriteRect.height * 0.3),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.2),
          spriteRect.top + (spriteRect.height * 0.58),
        )
        ..close();
    } else {
      accentPath
        ..moveTo(
          spriteRect.left + (spriteRect.width * 0.6),
          spriteRect.top + (spriteRect.height * 0.34),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.8),
          spriteRect.top + (spriteRect.height * 0.2),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.74),
          spriteRect.top + (spriteRect.height * 0.5),
        )
        ..close();
    }
    canvas.drawPath(
        accentPath, Paint()..color = primaryColor.withValues(alpha: 0.92));
  }

  void _syncTextVisibility() {
    final showFallbackText = _spriteImage == null;
    _speciesText?.text = showFallbackText ? _speciesLabel : '';
    _monogramText?.text =
        showFallbackText ? _speciesMonogram(_speciesLabel) : '';
  }

  String _speciesMonogram(String speciesLabel) {
    final trimmed = speciesLabel.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}

Rect _sceneBounds(Rect sceneSpriteRect, Rect scenePlatformRect) {
  return sceneSpriteRect.expandToInclude(scenePlatformRect).inflate(12);
}

Rect _toLocalRect(Rect sceneRect, Rect boundsRect) {
  return sceneRect.shift(-boundsRect.topLeft);
}

Offset _toLocalOffset(Offset sceneOffset, Rect boundsRect) {
  return sceneOffset - boundsRect.topLeft;
}

Future<Rect?> _computeOpaqueSourceRect(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return null;
  }
  final rgba = byteData.buffer.asUint8List();
  final width = image.width;
  final height = image.height;
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = rgba[((y * width) + x) * 4 + 3];
      if (alpha == 0) {
        continue;
      }
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) {
    return null;
  }
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}
