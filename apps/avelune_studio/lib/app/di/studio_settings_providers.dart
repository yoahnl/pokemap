import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/studio_ai_preferences.dart';

final studioAiKeyStoreProvider = Provider<StudioAiKeyStore>(
  (ref) => throw StateError('Studio secure key storage is not configured.'),
);

final studioAiConnectionProvider = Provider<StudioAiConnection>(
  (ref) => throw StateError('Studio AI connection is not configured.'),
);
