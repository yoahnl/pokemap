import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/settings/studio_ai_preferences.dart';

final class SecureStudioAiKeyStore implements StudioAiKeyStore {
  const SecureStudioAiKeyStore([
    this.storage = const FlutterSecureStorage(
      mOptions: MacOsOptions(
        accountName: 'Avelune Studio AI',
        usesDataProtectionKeychain: false,
      ),
    ),
  ]);

  final FlutterSecureStorage storage;

  String _id(StudioAiProvider provider) => 'avelune.studio.ai.${provider.name}';

  @override
  Future<bool> contains(StudioAiProvider provider) =>
      storage.containsKey(key: _id(provider));

  @override
  Future<String?> read(StudioAiProvider provider) =>
      storage.read(key: _id(provider));

  @override
  Future<void> write(StudioAiProvider provider, String key) =>
      storage.write(key: _id(provider), value: key);

  @override
  Future<void> delete(StudioAiProvider provider) =>
      storage.delete(key: _id(provider));
}
