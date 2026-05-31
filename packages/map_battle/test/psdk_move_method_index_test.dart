import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move method index', () {
    test('resolves PSDK Studio move ids to battle engine methods', () {
      expect(psdkBattleEngineMethodForMoveId('wrap'), equals('s_bind'));
      expect(psdkBattleEngineMethodForMoveId('bite'), equals('s_basic'));
      expect(psdkBattleEngineMethodForMoveId('haze'), equals('s_haze'));
      expect(psdkBattleEngineMethodForMoveId('spit_up'), equals('s_split_up'));
      expect(
          psdkBattleEngineMethodForMoveId('stockpile'), equals('s_stockpile'));
      expect(psdkBattleEngineMethodForMoveId('swallow'), equals('s_swallow'));
      expect(psdkBattleEngineMethodForMoveId('mud_bomb'), equals('s_basic'));
      expect(
        psdkBattleEngineMethodForMoveId('gastro_acid'),
        equals('s_gastro_acid'),
      );
      expect(psdkBattleEngineMethodForMoveId('coil'), equals('s_self_stat'));
    });

    test('accepts compact ids used by some external catalogs', () {
      expect(psdkBattleEngineMethodForMoveId('spitup'), equals('s_split_up'));
      expect(psdkBattleEngineMethodForMoveId('mudbomb'), equals('s_basic'));
      expect(
        psdkBattleEngineMethodForMoveId('gastroacid'),
        equals('s_gastro_acid'),
      );
    });
  });
}
