import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// HUD de combattant pour la scène de combat.
///
/// Responsabilité volontairement bornée :
/// - afficher les informations déjà vraies dans `BattleSession` ;
/// - ne pas recalculer de logique ;
/// - ne pas devenir un modèle de présentation générique.
class BattleSceneHudComponent extends PositionComponent {
  BattleSceneHudComponent({
    required Vector2 position,
    required Vector2 size,
    required this.ownerLabel,
    required BattleCombatant combatant,
    required this.isPlayerSide,
  })  : _combatant = combatant,
        super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 20,
        );

  final String ownerLabel;
  final bool isPlayerSide;
  BattleCombatant _combatant;

  TextComponent? _ownerText;
  TextComponent? _speciesText;
  TextComponent? _hpText;
  TextComponent? _statusText;
  RectangleComponent? _hpBarFill;

  @override
  Future<void> onLoad() async {
    _ownerText = TextComponent(
      text: ownerLabel,
      position: Vector2(18, 12),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xB3D7DEEC),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
    await add(_ownerText!);

    _speciesText = TextComponent(
      text: _combatant.speciesId,
      position: Vector2(18, 28),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F7FB),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_speciesText!);

    final hpBarBackground = RectangleComponent(
      position: Vector2(18, size.y - 34),
      size: Vector2(size.x - 36, 10),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0x33222A3B),
      priority: 21,
    );
    await add(hpBarBackground);

    _hpBarFill = RectangleComponent(
      position: Vector2(18, size.y - 34),
      size: Vector2(size.x - 36, 10),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..color =
            isPlayerSide ? const Color(0xFF79D88E) : const Color(0xFFE1A95F),
      priority: 22,
    );
    await add(_hpBarFill!);

    _hpText = TextComponent(
      text: '',
      position: Vector2(18, size.y - 54),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE4EAF6),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    await add(_hpText!);

    _statusText = TextComponent(
      text: '',
      position: Vector2(size.x - 18, 14),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFD9E4F7),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    await add(_statusText!);

    sync(combatant: _combatant);
  }

  void sync({
    required BattleCombatant combatant,
  }) {
    _combatant = combatant;
    _speciesText?.text = combatant.speciesId;
    _hpText?.text = 'PV ${combatant.currentHp}/${combatant.maxHp}';
    _statusText?.text = _statusLabel(combatant);

    final safeMaxHp = combatant.maxHp <= 0 ? 1 : combatant.maxHp;
    final hpRatio = (combatant.currentHp / safeMaxHp).clamp(0.0, 1.0);
    _hpBarFill?.size = Vector2((size.x - 36) * hpRatio, 10);
    _hpBarFill?.paint.color = _hpColor(hpRatio);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final panelRect = Offset.zero & Size(size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
      Paint()
        ..color =
            isPlayerSide ? const Color(0xD818273D) : const Color(0xD8261E38),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        panelRect.deflate(1),
        const Radius.circular(19),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
    );
  }

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
      return const Color(0xFFEB5E55);
    }
    if (hpRatio <= 0.5) {
      return const Color(0xFFE5B95A);
    }
    return isPlayerSide ? const Color(0xFF79D88E) : const Color(0xFFE1A95F);
  }
}
