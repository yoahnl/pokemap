import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_game_fixtures.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_player_service_host.dart';

void main() {
  test('serialized repository performs a real JSON round trip', () async {
    final repository = SerializedEvaluationSaveRepository();
    final original = gameStateFixture();

    await repository.save(original);
    final loaded = await repository.load();

    expect(loaded, original);
    expect(identical(loaded, original), isFalse);
  });

  test('service host keeps the production shop request unchanged', () async {
    final host = EvaluationPlayerServiceHost()..queueShopPurchase('potion');
    final request = shopRequestFixture();

    await host.openShop(request);

    expect(host.shopRequests.single, same(request));
    expect(host.shopRequests.single.shop.id, 'shop_port_supplies');
    expect(host.purchasedItemIds, <String>['potion']);
  });
}
