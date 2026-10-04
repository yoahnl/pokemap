import 'package:flutter/services.dart';

final class HubRecipeAssetBundle extends CachingAssetBundle {
  String _packageKey(String key) =>
      key.startsWith('assets/avelune/') ? 'packages/pokemap_hub/$key' : key;

  @override
  Future<ByteData> load(String key) => rootBundle.load(_packageKey(key));

  @override
  Future<ImmutableBuffer> loadBuffer(String key) =>
      rootBundle.loadBuffer(_packageKey(key));
}
