import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_scene_hud_layout.dart';

/// HUD de combattant pour la scène de combat.
///
/// Le lot 4b rapproche ce HUD d'une lecture battle-like plus premium, tout en
/// restant honnête :
/// - on n'invente aucune donnée absente du moteur ;
/// - on n'ouvre pas de nouveau système d'UI générique ;
/// - on reformate seulement des informations déjà vraies dans `BattleSession`.
class BattleSceneHudComponent extends PositionComponent {
  BattleSceneHudComponent({
    required Vector2 position,
    required Vector2 size,
    required this.ownerLabel,
    required BattleCombatant combatant,
    required this.isPlayerSide,
    this.initialGenderSymbol,
  })  : _combatant = combatant,
        super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 20,
        );

  final String ownerLabel;
  final bool isPlayerSide;
  final String? initialGenderSymbol;
  BattleCombatant _combatant;
  String? _genderSymbol;
  RectangleComponent? _hpBarFill;
  BattleSceneHudLayout? _layout;

  @visibleForTesting
  bool get belongsToPlayerSide => isPlayerSide;

  @visibleForTesting
  String get currentSpeciesDisplayText => _speciesDisplayText;

  @visibleForTesting
  BattleSceneHudLayout get currentLayout =>
      _layout ??
      BattleSceneHudLayout.forBounds(
        hudRect: Offset.zero & Size(size.x, size.y),
        isPlayerSide: isPlayerSide,
        speciesText: _combatant.speciesId,
        genderSymbol: _genderSymbol,
        levelText: 'Lv.${_combatant.level}',
        hpValueText: _hpValueText,
        statusText: _statusLabel(_combatant),
      );

  @visibleForTesting
  Rect get currentNameRect => currentLayout.nameRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect? get currentGenderRect =>
      currentLayout.genderRect?.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect get currentLevelRect =>
      currentLayout.levelRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect get currentHpBarRect =>
      currentLayout.hpBarRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect? get currentHpValueRect =>
      currentLayout.hpValueRect?.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect? get currentStatusRect =>
      currentLayout.statusRect?.shift(Offset(position.x, position.y));

  @override
  Future<void> onLoad() async {
    final hpBarBackground = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2.zero(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFFABB5C1),
      priority: 21,
    );
    await add(hpBarBackground);

    _hpBarFill = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2.zero(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFF62C06E),
      priority: 22,
    );
    await add(_hpBarFill!);

    sync(
      combatant: _combatant,
      genderSymbol: initialGenderSymbol,
    );
  }

  void sync({
    required BattleCombatant combatant,
    String? genderSymbol,
  }) {
    _combatant = combatant;
    _genderSymbol = genderSymbol?.trim().isEmpty ?? true
        ? null
        : genderSymbol?.trim();
    _layout = BattleSceneHudLayout.forBounds(
      hudRect: Offset.zero & Size(size.x, size.y),
      isPlayerSide: isPlayerSide,
      speciesText: combatant.speciesId,
      genderSymbol: _genderSymbol,
      levelText: 'Lv.${combatant.level}',
      hpValueText: _hpValueText,
      statusText: _statusLabel(combatant),
    );

    final safeMaxHp = combatant.maxHp <= 0 ? 1 : combatant.maxHp;
    final hpRatio = (combatant.currentHp / safeMaxHp).clamp(0.0, 1.0);
    _hpBarFill?.position = Vector2(
      currentLayout.hpBarRect.left,
      currentLayout.hpBarRect.top,
    );
    _hpBarFill?.size = Vector2(
      currentLayout.hpBarRect.width * hpRatio,
      currentLayout.hpBarRect.height,
    );
    _hpBarFill?.paint.color = _hpColor(hpRatio);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final panelRect = Offset.zero & Size(size.x, size.y);

    canvas.drawShadow(
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
        ),
      const Color(0x55000000),
      10,
      true,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
      Paint()..color = const Color(0xFFF3F0E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF798394),
    );

    final accentRect = Rect.fromLTWH(12, 12, size.x - 24, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(accentRect, const Radius.circular(999)),
      Paint()
        ..color =
            isPlayerSide ? const Color(0xFF86B7F2) : const Color(0xFFB4C18D),
    );

    final layout = currentLayout;
    final hpBarBackgroundPaint = Paint()..color = const Color(0xFFABB5C1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(layout.hpBarRect, const Radius.circular(999)),
      hpBarBackgroundPaint,
    );

    _paintText(
      canvas,
      ownerLabel,
      layout.ownerRect,
      TextStyle(
        color: const Color(0xB34D5A6D),
        fontSize: layout.ownerFontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
      align: TextAlign.left,
    );
    _paintText(
      canvas,
      _combatant.speciesId,
      layout.nameRect,
      TextStyle(
        color: const Color(0xFF202738),
        fontSize: layout.nameFontSize,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.left,
    );
    if (_genderSymbol != null && layout.genderRect != null) {
      _paintText(
        canvas,
        _genderSymbol!,
        layout.genderRect!,
        TextStyle(
          color: const Color(0xFF2E3C52),
          fontSize: layout.nameFontSize * 0.9,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.left,
      );
    }
    _paintText(
      canvas,
      'Lv.${_combatant.level}',
      layout.levelRect,
      TextStyle(
        color: const Color(0xFF3C4758),
        fontSize: layout.levelFontSize,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.right,
    );
    final statusLabel = _statusLabel(_combatant);
    if (statusLabel.isNotEmpty && layout.statusRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(layout.statusRect!, const Radius.circular(999)),
        Paint()..color = const Color(0xFFE2E7F0),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(layout.statusRect!, const Radius.circular(999)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF90A0B6),
      );
      _paintText(
        canvas,
        statusLabel,
        layout.statusRect!,
        TextStyle(
          color: const Color(0xFF516178),
          fontSize: layout.statusFontSize,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.center,
      );
    }
    _paintText(
      canvas,
      'HP',
      layout.hpLabelRect,
      TextStyle(
        color: const Color(0xFFB87D2F),
        fontSize: layout.hpLabelFontSize,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.left,
    );
    if (layout.showsHpValue && layout.hpValueRect != null) {
      _paintText(
        canvas,
        _hpValueText,
        layout.hpValueRect!,
        TextStyle(
          color: const Color(0xFF364355),
          fontSize: layout.hpValueFontSize,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.right,
      );
    }
  }

  String get _speciesDisplayText => _genderSymbol == null
      ? _combatant.speciesId
      : '${_combatant.speciesId} $_genderSymbol';

  String get _hpValueText => isPlayerSide
      ? '${_combatant.currentHp}/${_combatant.maxHp}'
      : '${(((_combatant.currentHp) / (_combatant.maxHp <= 0 ? 1 : _combatant.maxHp)) * 100).round()}%';

  String _statusLabel(BattleCombatant combatant) {
    if (combatant.isFainted) {
      return 'K.O.';
    }
    final status = combatant.majorStatus;
    if (status == null) {
      return '';
    }
    return status.id.name.toUpperCase();
  }

  Color _hpColor(double hpRatio) {
    if (hpRatio <= 0.25) {
      return const Color(0xFFD35B49);
    }
    if (hpRatio <= 0.5) {
      return const Color(0xFFD9A84B);
    }
    return const Color(0xFF62C06E);
  }
}

void _paintText(
  Canvas canvas,
  String text,
  Rect rect,
  TextStyle style, {
  required TextAlign align,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    ellipsis: '…',
    textAlign: align,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: rect.width);

  final dx = switch (align) {
    TextAlign.right => rect.right - painter.width,
    TextAlign.center => rect.left + ((rect.width - painter.width) / 2),
    _ => rect.left,
  };
  final dy = rect.top + ((rect.height - painter.height) / 2);
  painter.paint(canvas, Offset(dx, dy));
}
