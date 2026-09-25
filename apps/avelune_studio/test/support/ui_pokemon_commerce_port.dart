import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';
import 'm3_story_fixture.dart';

final class UiPokemonCommercePort implements PokemonCommercePort {
  const UiPokemonCommercePort(this.source, this.tester);

  factory UiPokemonCommercePort.forFixture(
    M3StoryFixture fixture,
    WidgetTester tester,
  ) => UiPokemonCommercePort(
    LocalPokemonCommerceAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ),
    tester,
  );

  final PokemonCommercePort source;
  final WidgetTester tester;

  @override
  Future<PokemonCommerceImportPreview> previewJson(
    String path, {
    required bool item,
  }) async => (await WidgetResourcePort.serial(
    tester,
    () => source.previewJson(path, item: item),
  ))!;

  @override
  Future<PokemonCommerceSnapshot> load() async =>
      (await WidgetResourcePort.serial(tester, source.load))!;

  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) => _serialWrite(() => source.saveItem(before, after));

  @override
  Future<void> saveShop(ShopDefinition? before, ShopDefinition after) =>
      _serialWrite(() => source.saveShop(before, after));

  Future<void> _serialWrite(Future<void> Function() operation) async {
    final outcome = (await WidgetResourcePort.serial<Object?>(tester, () async {
      try {
        await operation();
        return null;
      } on Object catch (failure) {
        return failure;
      }
    }));
    if (outcome != null) throw outcome;
  }
}
