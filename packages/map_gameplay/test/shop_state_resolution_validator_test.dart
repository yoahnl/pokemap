import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('reports only simulated equal-priority winning matches', () {
    const shop = ShopDefinition(
      id: 'port',
      label: 'Boutique du Port',
      states: <ShopStateDefinition>[
        ShopStateDefinition(
          id: 'lysa',
          label: 'Après Lysa',
          priority: 20,
          activation: ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: <String, String>{
              ScriptConditionParams.flagName: 'lysa',
            },
          ),
        ),
        ShopStateDefinition(
          id: 'badge',
          label: 'Avec le badge',
          priority: 20,
          activation: ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: <String, String>{
              ScriptConditionParams.flagName: 'badge',
            },
          ),
        ),
      ],
    );
    const validator = ShopStateResolutionValidator();

    final diagnostics = validator.validate(
      shop: shop,
      scenarios: <ShopStateResolutionScenario>[
        _scenario('none'),
        _scenario('lysa', flags: <String>{'lysa'}),
        _scenario('tie', flags: <String>{'lysa', 'badge'}),
      ],
    );

    expect(diagnostics, hasLength(1));
    expect(
      diagnostics.single.code,
      'SHOP_STATE_EQUAL_PRIORITY_ACTIVE_MATCH',
    );
    expect(diagnostics.single.shopId, 'port');
    expect(diagnostics.single.stateId, 'lysa');
    expect(diagnostics.single.contextId, 'tie');
    expect(diagnostics.single.path, 'shops.port.states');
    expect(
      diagnostics.single.severity,
      ShopStateDiagnosticSeverity.error,
    );
  });
}

ShopStateResolutionScenario _scenario(
  String id, {
  Set<String> flags = const <String>{},
}) =>
    ShopStateResolutionScenario(
      id: id,
      label: id,
      gameState: GameState(
        saveId: id,
        storyFlags: StoryFlags(activeFlags: flags),
      ),
    );
