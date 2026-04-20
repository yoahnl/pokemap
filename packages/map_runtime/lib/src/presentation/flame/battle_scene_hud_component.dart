import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

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

  TextComponent? _ownerText;
  TextComponent? _speciesText;
  TextComponent? _levelText;
  TextComponent? _hpLabelText;
  TextComponent? _hpText;
  TextComponent? _statusText;
  RectangleComponent? _hpBarFill;

  @visibleForTesting
  bool get belongsToPlayerSide => isPlayerSide;

  @visibleForTesting
  String get currentSpeciesDisplayText => _speciesText?.text ?? '';

  @override
  Future<void> onLoad() async {
    _ownerText = TextComponent(
      text: ownerLabel,
      position: Vector2(16, 10),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xB34D5A6D),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
    await add(_ownerText!);

    _speciesText = TextComponent(
      text: _combatant.speciesId,
      position: Vector2(16, 26),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF202738),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_speciesText!);

    _levelText = TextComponent(
      text: '',
      position: Vector2(size.x - 16, 30),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF3C4758),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_levelText!);

    _statusText = TextComponent(
      text: '',
      position: Vector2(size.x - 16, 14),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A6579),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
    await add(_statusText!);

    _hpLabelText = TextComponent(
      text: 'HP',
      position: Vector2(16, size.y - 40),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFB87D2F),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    await add(_hpLabelText!);

    final hpBarBackground = RectangleComponent(
      position: Vector2(42, size.y - 36),
      size: Vector2(size.x - 58, 10),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFFABB5C1),
      priority: 21,
    );
    await add(hpBarBackground);

    _hpBarFill = RectangleComponent(
      position: Vector2(42, size.y - 36),
      size: Vector2(size.x - 58, 10),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFF62C06E),
      priority: 22,
    );
    await add(_hpBarFill!);

    _hpText = TextComponent(
      text: '',
      position: Vector2(size.x - 16, size.y - 18),
      anchor: Anchor.bottomRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF364355),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_hpText!);

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
    _speciesText?.text = _genderSymbol == null
        ? combatant.speciesId
        : '${combatant.speciesId} $_genderSymbol';
    _levelText?.text = 'Lv.${combatant.level}';
    _statusText?.text = _statusLabel(combatant);
    _hpText?.text = isPlayerSide
        ? '${combatant.currentHp}/${combatant.maxHp}'
        : '${((combatant.currentHp / (combatant.maxHp <= 0 ? 1 : combatant.maxHp)) * 100).round()}%';

    final safeMaxHp = combatant.maxHp <= 0 ? 1 : combatant.maxHp;
    final hpRatio = (combatant.currentHp / safeMaxHp).clamp(0.0, 1.0);
    _hpBarFill?.size = Vector2((size.x - 58) * hpRatio, 10);
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
      return const Color(0xFFD35B49);
    }
    if (hpRatio <= 0.5) {
      return const Color(0xFFD9A84B);
    }
    return const Color(0xFF62C06E);
  }
}
